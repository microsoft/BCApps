codeunit 144006 "UT REP Job"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Job] [Reports]
    end;

    var
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryRandom: Codeunit "Library - Random";
        LibraryInventory: Codeunit "Library - Inventory";
        Assert: Codeunit Assert;
        JobNoFilterTxt: Label '%1|%2';
        DialogErr: Label 'Dialog';
        BudgetOptionCap: Label 'BudgetOptionText';
        JobNoCap: Label 'Job_Task_Job_No_';
        JobTaskNoCap: Label 'Job_Task_Job_Task_No_';
        BudgetedTotalCostCap: Label 'JobDiffBuff__Budgeted_Total_Cost_';
        ItemDescriptionCap: Label 'JobDiffBuff_Description';
        ActualOptionCap: Label 'ActualOptionText';
        BudgetedLineAmountCap: Label 'JobDiffBuff__Budgeted_Line_Amount_';
        UsageCostCap: Label 'UsageCost';
        BudgetedPriceCap: Label 'BudgetedPrice';
        InvoicedPriceCap: Label 'InvoicedPrice';
        ScheduledPriceCap: Label 'ScheduledPrice';
        ProfitCap: Label 'Profit';
        VarianceCap: Label 'Variance';
        ContractPriceCap: Label 'ContractPrice';
        UsagePriceCap: Label 'UsagePrice';
        BudgetedScheduleTxt: Label 'Budgeted Amounts are per the Budget';
        BudgetedContractTxt: Label 'Budgeted Amounts are per the Contract';
        RowCountErr: Label 'Wrong number of rows in the Report';
        JobTaskNoTagNameTxt: Label 'Job_Task___Job_Task_No__';

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure GetItemDescriptionWithResourceJobActualToBudgetCost()
    var
        JobPlanningLine: Record "Job Planning Line";
        Resource: Record Resource;
        JobActualToBudgetCost: Report "Job Actual to Budget (Cost)";
        ResourceName: Text[50];
    begin
        // Purpose of the test is to validate GetItemDescription Function of Report 10210 - Job Actual to Budget (Cost).
        // Setup.
        Initialize();
        CreateResource(Resource);

        // Exercise: Function GetItemDescription of Report Job Actual to Budget (Cost) with Resource.
        ResourceName := JobActualToBudgetCost.GetItemDescription(JobPlanningLine.Type::Resource.AsInteger(), Resource."No.");

        // Verify: Verify Resource Name.
        Resource.TestField(Name, ResourceName);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure GetItemDescriptionWithGLAccountJobActualToBudgetCost()
    var
        JobPlanningLine: Record "Job Planning Line";
        GLAccount: Record "G/L Account";
        JobActualToBudgetCost: Report "Job Actual to Budget (Cost)";
        GLAccountName: Text[50];
    begin
        // Purpose of the test is to validate GetItemDescription Function of Report 10210 - Job Actual to Budget (Cost).
        // Setup.
        Initialize();
        CreateGLAccount(GLAccount);

        // Exercise: Function GetItemDescription of Report Job Actual to Budget (Cost) with GL Account.
        GLAccountName := JobActualToBudgetCost.GetItemDescription(JobPlanningLine.Type::"G/L Account".AsInteger(), GLAccount."No.");

        // Verify: Verify GL Account Name.
        GLAccount.TestField(Name, GLAccountName);
    end;

    [Test]
    [HandlerFunctions('JobActualToBudgetCostPrintToExcelRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemJobActualToBudgetCostError()
    var
        Job: Record Job;
        Job2: Record Job;
    begin
        // Purpose of the test is to validate Job - OnPreDataItem Trigger of Report 10210 - Job Actual to Budget (Cost).

        // Setup: Create multiple job.
        Initialize();
        CreateJob(Job);
        CreateJob(Job2);

        // Exercise.
        asserterror REPORT.Run(REPORT::"Job Actual to Budget (Cost)");  // Opens handler - JobActualToBudgetCostPrintToExcelRequestPageHandler.

        // Verify: Verify Error Code, Actual error - When printing to Excel, you must select only one Job.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [HandlerFunctions('JobActualToBudgetCostScheduleRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordLineTypeScheduleJobActualToBudgetCost()
    var
        JobPlanningLine: Record "Job Planning Line";
        JobTask: Record "Job Task";
        Item: Record Item;
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        // Purpose of the test is to validate Job Planning Line - OnAfterGetRecord Trigger of Report 10210 - Job Actual to Budget (Cost).

        // Setup: Create Item, Job Task, Job Planning Line and Job Ledger Entry.
        Initialize();
        CreateItem(Item);
        CreateJobTask(JobTask, JobTask."Job Task Type"::Posting);
        CreateJobPlanningLine(JobPlanningLine, JobTask, JobPlanningLine."Line Type"::Budget, Item."No.");
        CreateJobLedgerEntry(JobLedgerEntry, JobTask, Item."No.", JobLedgerEntry."Entry Type");

        // Exercise.
        REPORT.Run(REPORT::"Job Actual to Budget (Cost)");  // Opens handler - JobActualToBudgetCostScheduleRequestPageHandler.

        // Verify: Verify Total Cost (LCY), Budget Option, Job No and Job Task No on Report Job Actual to Budget (Cost).
        VerifyCostOnJobActualToBudgetCostReport(JobLedgerEntry."Total Cost (LCY)", JobPlanningLine."Total Cost (LCY)");
        LibraryReportDataset.AssertElementWithValueExists(BudgetOptionCap, Format(BudgetedScheduleTxt));
        LibraryReportDataset.AssertElementWithValueExists(JobNoCap, JobTask."Job No.");
        LibraryReportDataset.AssertElementWithValueExists(JobTaskNoCap, JobTask."Job Task No.");
    end;

    [Test]
    [HandlerFunctions('JobActualToBudgetCostScheduleRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordJobPlanningLineJobActualToBudgetCost()
    var
        JobPlanningLine: Record "Job Planning Line";
        JobTask: Record "Job Task";
        Item: Record Item;
        JobPlanningLine2: Record "Job Planning Line";
    begin
        // Purpose of the test is to validate Job Planning Line - OnAfterGetRecord Trigger of Report 10210 - Job Actual to Budget (Cost).

        // Setup: Create Item, Job Task and multiple Job Planning Lines.
        Initialize();
        CreateItem(Item);
        CreateJobTask(JobTask, JobTask."Job Task Type"::Posting);
        CreateJobPlanningLine(JobPlanningLine, JobTask, JobPlanningLine."Line Type"::Budget, Item."No.");
        CreateJobPlanningLine(JobPlanningLine2, JobTask, JobPlanningLine."Line Type"::Budget, Item."No.");

        // Exercise.
        REPORT.Run(REPORT::"Job Actual to Budget (Cost)");  // Opens handler - JobActualToBudgetCostScheduleRequestPageHandler.

        // Verify: Verify Total Cost (LCY) and Description on Report Job Actual to Budget (Cost).
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(
          BudgetedTotalCostCap, JobPlanningLine."Total Cost (LCY)" + JobPlanningLine2."Total Cost (LCY)");
        LibraryReportDataset.AssertElementWithValueExists(ItemDescriptionCap, Item.Description);
    end;

    [Test]
    [HandlerFunctions('JobActualToBudgetCostScheduleRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordJobLedgerEntryJobActualToBudgetCost()
    var
        JobTask: Record "Job Task";
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        // Purpose of the test is to validate Job Ledger Entry - OnAfterGetRecord Trigger of Report 10210 - Job Actual to Budget (Cost).

        // Setup: Create Job Task and Job Ledger Entry.
        Initialize();
        CreateJobTask(JobTask, JobTask."Job Task Type"::Posting);
        CreateJobLedgerEntry(JobLedgerEntry, JobTask, LibraryUTUtility.GetNewCode(), JobLedgerEntry."Entry Type");

        // Exercise.
        REPORT.Run(REPORT::"Job Actual to Budget (Cost)");  // Opens handler - JobActualToBudgetCostScheduleRequestPageHandler.

        // Verify: Verify Total Cost (LCY) on Report Job Actual to Budget (Cost).
        VerifyCostOnJobActualToBudgetCostReport(JobLedgerEntry."Total Cost (LCY)", 0);  // Zero for Job Planning Line - TotalCostLCY.
    end;

    [Test]
    [HandlerFunctions('JobActualToBudgetCostScheduleRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure JobPlanningLineAndJobLedgerEntryWithUOMJobActualToBudgetCost()
    var
        JobPlanningLine: Record "Job Planning Line";
        JobTask: Record "Job Task";
        Item: Record Item;
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        // [FEATURE] [Job Actual to Budget (Cost)] [Job Planning Line] [Job Ledger Entry]
        // [SCENARIO 225543] Linked Job Planning Line and Job Ledger Entry with different UOMs creates one line in Job Actual To Budget Cost Report

        // [GIVEN] Item, Job Task, Job Planning Line "JPL" with Unit of Measure "UOM1" and Job Ledger Entry "JLE" with Unit of Measure "UOM2".
        Initialize();
        CreateItem(Item);
        CreateJobTask(JobTask, JobTask."Job Task Type"::Posting);

        CreateJobPlanningLineWithUOM(JobPlanningLine, JobTask, JobPlanningLine."Line Type"::Budget, Item."No.");
        CreateJobLedgerEntryWithUOM(JobLedgerEntry, JobTask, Item."No.", JobLedgerEntry."Entry Type");

        // [WHEN] Job Actual to Budget (Cost) Report runs.
        REPORT.Run(REPORT::"Job Actual to Budget (Cost)");  // Opens handler - JobActualToBudgetCostScheduleRequestPageHandler.

        // [THEN] One row in output document containig both "JPL" and "JLE"
        VerifyCostOnJobActualToBudgetCostReport(JobLedgerEntry."Total Cost (LCY)", JobPlanningLine."Total Cost (LCY)");
        LibraryReportDataset.SetXmlNodeList(JobTaskNoTagNameTxt);
        Assert.AreEqual(1, LibraryReportDataset.RowCount(), RowCountErr);
    end;

    [Test]
    [HandlerFunctions('JobActualToBudgetCostContractRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordLineTypeContractJobActualToBudgetCost()
    var
        JobPlanningLine: Record "Job Planning Line";
        JobTask: Record "Job Task";
        Item: Record Item;
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        // Purpose of the test is to validate Job Ledger Entry - OnAfterGetRecord Trigger of Report 10210 - Job Actual to Budget (Cost).

        // Setup: Create Item, Job Task, Job Planning Line and Job Ledger Entry.
        Initialize();
        CreateItem(Item);
        CreateJobTask(JobTask, JobTask."Job Task Type"::"End-Total");
        UpdateTotalingJobTask(JobTask);
        CreateJobPlanningLine(JobPlanningLine, JobTask, JobPlanningLine."Line Type"::Billable, Item."No.");
        CreateJobLedgerEntry(JobLedgerEntry, JobTask, Item."No.", JobLedgerEntry."Entry Type");

        // Exercise.
        REPORT.Run(REPORT::"Job Actual to Budget (Cost)");  // Opens handler - JobActualToBudgetCostContractRequestPageHandler.

        // Verify: Verify Total Cost (LCY) and Budget Option on Report Job Actual to Budget (Cost).
        VerifyCostOnJobActualToBudgetCostReport(JobLedgerEntry."Total Cost (LCY)", JobPlanningLine."Total Cost (LCY)");
        LibraryReportDataset.AssertElementWithValueExists(BudgetOptionCap, Format(BudgetedContractTxt));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure GetItemDescriptionWithResourceJobActualToBudgetPrice()
    var
        JobPlanningLine: Record "Job Planning Line";
        Resource: Record Resource;
        JobActualToBudgetPrice: Report "Job Actual to Budget (Price)";
        ResourceName: Text[50];
    begin
        // Purpose of the test is to validate GetItemDescription Function of Report 10211 - Job Actual to Budget (Price).
        // Setup.
        Initialize();
        CreateResource(Resource);

        // Exercise: Function GetItemDescription of Report Job Actual to Budget (Price) with Resource.
        ResourceName := JobActualToBudgetPrice.GetItemDescription(JobPlanningLine.Type::Resource.AsInteger(), Resource."No.");

        // Verify: Verify Resource Name.
        Resource.TestField(Name, ResourceName);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure GetItemDescriptionWithGLAccountJobActualToBudgetPrice()
    var
        JobPlanningLine: Record "Job Planning Line";
        GLAccount: Record "G/L Account";
        JobActualToBudgetPrice: Report "Job Actual to Budget (Price)";
        GLAccountName: Text[50];
    begin
        // Purpose of the test is to validate GetItemDescription Function of Report 10211 - Job Actual to Budget (Price).
        // Setup.
        Initialize();
        CreateGLAccount(GLAccount);

        // Exercise: Function GetItemDescription of Report Job Actual to Budget (Price) with GL Account.
        GLAccountName := JobActualToBudgetPrice.GetItemDescription(JobPlanningLine.Type::"G/L Account".AsInteger(), GLAccount."No.");

        // Verify: Verify GL Account Name.
        GLAccount.TestField(Name, GLAccountName);
    end;

    [Test]
    [HandlerFunctions('JobActualToBudgetPricePrintToExcelRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemJobActualToBudgetPriceError()
    var
        Job: Record Job;
        Job2: Record Job;
    begin
        // Purpose of the test is to validate Job - OnPreDataItem Trigger of Report 10211 - Job Actual to Budget (Price).

        // Setup: Create multiple job.
        Initialize();
        CreateJob(Job);
        CreateJob(Job2);

        // Exercise.
        asserterror REPORT.Run(REPORT::"Job Actual to Budget (Price)");  // Opens handler - JobActualToBudgetPricePrintToExcelRequestPageHandler.

        // Verify: Verify Error Code, Actual error - When printing to Excel, you must select only one Job..
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [HandlerFunctions('JobActualToBudgetPriceScheduleRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordLineTypeScheduleJobActualToBudgetPrice()
    var
        JobPlanningLine: Record "Job Planning Line";
        JobTask: Record "Job Task";
        Item: Record Item;
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        // Purpose of the test is to validate Job Planning Line - OnAfterGetRecord Trigger of Report 10211 - Job Actual to Budget (Price).

        // Setup: Create Item, Job Task, Job Planning Line and Job Ledger Entry.
        Initialize();
        CreateItem(Item);
        CreateJobTask(JobTask, JobTask."Job Task Type"::Posting);
        CreateJobPlanningLine(JobPlanningLine, JobTask, JobPlanningLine."Line Type"::Budget, Item."No.");
        CreateJobLedgerEntry(JobLedgerEntry, JobTask, Item."No.", JobLedgerEntry."Entry Type");

        // Exercise.
        REPORT.Run(REPORT::"Job Actual to Budget (Price)");  // Opens handler - JobActualToBudgetPriceScheduleRequestPageHandler.

        // Verify: Verify Total Price (LCY), Budget Option, Actual Option, Job No and Job Task No on Report Job Actual to Budget (Price).
        VerifyPriceOnJobActualToBudgetPriceReport(JobLedgerEntry."Total Price (LCY)", JobPlanningLine."Total Price (LCY)");
        LibraryReportDataset.AssertElementWithValueExists(BudgetOptionCap, Format(BudgetedScheduleTxt));
        LibraryReportDataset.AssertElementWithValueExists(ActualOptionCap, 'Actual Amounts are per Project Usage');
        LibraryReportDataset.AssertElementWithValueExists(JobNoCap, JobTask."Job No.");
        LibraryReportDataset.AssertElementWithValueExists(JobTaskNoCap, JobTask."Job Task No.");
    end;

    [Test]
    [HandlerFunctions('JobActualToBudgetPriceScheduleRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordJobPlanningLineJobActualToBudgetPrice()
    var
        JobPlanningLine: Record "Job Planning Line";
        JobTask: Record "Job Task";
        Item: Record Item;
        JobPlanningLine2: Record "Job Planning Line";
    begin
        // Purpose of the test is to validate Job Planning Line - OnAfterGetRecord Trigger of Report 10211 - Job Actual to Budget (Price).

        // Setup: Create Item, Job Task and multiple Job Planning Lines.
        Initialize();
        CreateItem(Item);
        CreateJobTask(JobTask, JobTask."Job Task Type"::Posting);
        CreateJobPlanningLine(JobPlanningLine, JobTask, JobPlanningLine."Line Type"::Budget, Item."No.");
        CreateJobPlanningLine(JobPlanningLine2, JobTask, JobPlanningLine."Line Type"::Budget, Item."No.");

        // Exercise.
        REPORT.Run(REPORT::"Job Actual to Budget (Price)");  // Opens handler - JobActualToBudgetPriceScheduleRequestPageHandler.

        // Verify: Verify Total Price (LCY) and Description on Report Job Actual to Budget (Price).
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(
          BudgetedLineAmountCap, JobPlanningLine."Total Price (LCY)" + JobPlanningLine2."Total Price (LCY)");
        LibraryReportDataset.AssertElementWithValueExists(ItemDescriptionCap, Item.Description);
    end;

    [Test]
    [HandlerFunctions('JobActualToBudgetPriceScheduleRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordJobLedgerEntryJobActualToBudgetPrice()
    var
        JobTask: Record "Job Task";
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        // Purpose of the test is to validate Job Ledger Entry - OnAfterGetRecord Trigger of Report 10211 - Job Actual to Budget (Price).

        // Setup: Create Job Task and Job Ledger Entry.
        Initialize();
        CreateJobTask(JobTask, JobTask."Job Task Type"::Posting);
        CreateJobLedgerEntry(JobLedgerEntry, JobTask, LibraryUTUtility.GetNewCode(), JobLedgerEntry."Entry Type");

        // Exercise.
        REPORT.Run(REPORT::"Job Actual to Budget (Price)");  // Opens handler - JobActualToBudgetPriceScheduleRequestPageHandler.

        // Verify: Verify Total Price (LCY) on Report Job Actual to Budget (Price).
        VerifyPriceOnJobActualToBudgetPriceReport(JobLedgerEntry."Total Price (LCY)", 0);  // Zero for Job Planning Line - TotalPriceLCY
    end;

    [Test]
    [HandlerFunctions('JobActualToBudgetPriceContractRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordLineTypeContractJobActualToBudgetPrice()
    var
        JobPlanningLine: Record "Job Planning Line";
        JobTask: Record "Job Task";
        Item: Record Item;
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        // Purpose of the test is to validate Job Ledger Entry - OnAfterGetRecord Trigger of Report 10211 - Job Actual to Budget (Price).

        // Setup: Create Item, Job Task, Job Planning Line and Job Ledger Entry.
        Initialize();
        CreateItem(Item);
        CreateJobTask(JobTask, JobTask."Job Task Type"::"End-Total");
        UpdateTotalingJobTask(JobTask);
        CreateJobPlanningLine(JobPlanningLine, JobTask, JobPlanningLine."Line Type"::Billable, Item."No.");
        CreateJobLedgerEntry(JobLedgerEntry, JobTask, Item."No.", JobLedgerEntry."Entry Type"::Sale);

        // Exercise.
        REPORT.Run(REPORT::"Job Actual to Budget (Price)");  // Opens handler - JobActualToBudgetPriceContractRequestPageHandler.

        // Verify: Verify Total Price (LCY), Budget Option, Actual Option on Report Job Actual to Budget (Price).
        VerifyPriceOnJobActualToBudgetPriceReport(-JobLedgerEntry."Total Price (LCY)", JobPlanningLine."Total Price (LCY)");
        LibraryReportDataset.AssertElementWithValueExists(BudgetOptionCap, Format(BudgetedContractTxt));
        LibraryReportDataset.AssertElementWithValueExists(ActualOptionCap, 'Actual Amounts are per Sales Invoices');
    end;

    [Test]
    [HandlerFunctions('CompletedJobsRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure LineTypeContractCompletedJobs()
    var
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        JobLedgerEntry: Record "Job Ledger Entry";
        Job: Record Job;
    begin
        // Purpose of the test is to validate Job - OnAfterGetRecord Trigger of Report 10212 - Completed Jobs.

        // Setup: Create Job Task, Job Planning Line and Job Ledger Entry.
        Initialize();
        CreateJobTask(JobTask, JobTask."Job Task Type"::Posting);
        UpdateStatusJob(JobTask."Job No.", Job.Status::Completed);
        CreateJobPlanningLine(JobPlanningLine, JobTask, JobPlanningLine."Line Type"::Billable, LibraryUTUtility.GetNewCode());
        CreateJobLedgerEntry(JobLedgerEntry, JobTask, JobPlanningLine."No.", JobLedgerEntry."Entry Type");

        // Exercise.
        REPORT.Run(REPORT::"Completed Jobs");  // Opens handler - CompletedJobsRequestPageHandler.

        // Verify: Verify Usage Cost and Contract Price on Report Completed Jobs.
        VerifyCompletedJobsReport(JobLedgerEntry."Total Cost (LCY)", JobPlanningLine."Total Price (LCY)");
    end;

    [Test]
    [HandlerFunctions('CompletedJobsRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure LineTypeBothScheduleAndContractCompletedJobs()
    var
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        JobLedgerEntry: Record "Job Ledger Entry";
        Job: Record Job;
    begin
        // Purpose of the test is to validate Job - OnAfterGetRecord Trigger of Report 10212 - Completed Jobs.

        // Setup: Create Job Task, Job Planning Line and Job Ledger Entry.
        Initialize();
        CreateJobTask(JobTask, JobTask."Job Task Type"::Posting);
        UpdateStatusJob(JobTask."Job No.", Job.Status::Completed);
        CreateJobPlanningLine(
          JobPlanningLine, JobTask, JobPlanningLine."Line Type"::"Both Budget and Billable", LibraryUTUtility.GetNewCode());
        CreateJobLedgerEntry(JobLedgerEntry, JobTask, JobPlanningLine."No.", JobLedgerEntry."Entry Type");

        // Exercise.
        REPORT.Run(REPORT::"Completed Jobs");  // Opens handler - CompletedJobsRequestPageHandler.

        // Verify: Verify Usage Cost, Contract Price, Scheduled Price and Profit on Report Completed Jobs.
        VerifyCompletedJobsReport(JobLedgerEntry."Total Cost (LCY)", JobPlanningLine."Total Price (LCY)");
        LibraryReportDataset.AssertElementWithValueExists(ScheduledPriceCap, JobPlanningLine."Total Price (LCY)");
        LibraryReportDataset.AssertElementWithValueExists(ProfitCap, -JobLedgerEntry."Total Cost (LCY)");
    end;

    [Test]
    [HandlerFunctions('CompletedJobsRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure LineTypeScheduleCompletedJobs()
    var
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        JobLedgerEntry: Record "Job Ledger Entry";
        Job: Record Job;
    begin
        // Purpose of the test is to validate Job - OnAfterGetRecord Trigger of Report 10212 - Completed Jobs.

        // Setup: Create Job Task, Job Planning Line and Job Ledger Entry.
        Initialize();
        CreateJobTask(JobTask, JobTask."Job Task Type"::Posting);
        UpdateStatusJob(JobTask."Job No.", Job.Status::Completed);
        CreateJobPlanningLine(JobPlanningLine, JobTask, JobPlanningLine."Line Type"::Budget, LibraryUTUtility.GetNewCode());
        CreateJobLedgerEntry(JobLedgerEntry, JobTask, JobPlanningLine."No.", JobLedgerEntry."Entry Type"::Sale);

        // Exercise.
        REPORT.Run(REPORT::"Completed Jobs");  // Opens handler - CompletedJobsRequestPageHandler.

        // Verify: Verify Profit, Scheduled Cost and Invoiced Cost on Report Completed Jobs.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(ProfitCap, -JobLedgerEntry."Total Price (LCY)");
        LibraryReportDataset.AssertElementWithValueExists(ScheduledPriceCap, JobPlanningLine."Total Price (LCY)");
        LibraryReportDataset.AssertElementWithValueExists(InvoicedPriceCap, -JobLedgerEntry."Total Price (LCY)");
    end;

    [Test]
    [HandlerFunctions('CustomerJobsCostRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordCustomerJobsCost()
    var
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        JobLedgerEntry: Record "Job Ledger Entry";
        Job: Record Job;
    begin
        // Purpose of the test is to validate Job - OnAfterGetRecord Trigger of Report 10213 - Customer Jobs (Cost).

        // Setup: Create Job Task, Job Planning Line and Job Ledger Entry.
        Initialize();
        CreateJobTask(JobTask, JobTask."Job Task Type"::Posting);
        UpdateStatusJob(JobTask."Job No.", Job.Status::Open);
        CreateJobPlanningLine(JobPlanningLine, JobTask, JobPlanningLine."Line Type"::Budget, LibraryUTUtility.GetNewCode());
        CreateJobLedgerEntry(JobLedgerEntry, JobTask, JobPlanningLine."No.", JobLedgerEntry."Entry Type");

        // Exercise.
        REPORT.Run(REPORT::"Customer Jobs (Cost)");  // Opens handler - CustomerJobsCostRequestPageHandler.

        // Verify: Verify Job No, Scheduled Cost and Usage Cost on Report Customer Jobs (Cost).
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Job__No__', JobTask."Job No.");
        LibraryReportDataset.AssertElementWithValueExists('ScheduledCost', JobPlanningLine."Total Cost (LCY)");
        LibraryReportDataset.AssertElementWithValueExists(UsageCostCap, JobLedgerEntry."Total Cost (LCY)");
    end;

    [Test]
    [HandlerFunctions('CustomerJobsPriceContractRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordContractCustomerJobsPrice()
    var
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        JobLedgerEntry: Record "Job Ledger Entry";
        Job: Record Job;
    begin
        // Purpose of the test is to validate OnAfterGetRecord Trigger of Report 10214 - Customer Jobs (Price).

        // Setup: Create Job Task, Job Planning Line and Job Ledger Entry.
        Initialize();
        CreateJobTask(JobTask, JobTask."Job Task Type"::Posting);
        UpdateStatusJob(JobTask."Job No.", Job.Status::Open);
        CreateJobPlanningLine(JobPlanningLine, JobTask, JobPlanningLine."Line Type"::Budget, LibraryUTUtility.GetNewCode());
        UpdateJobPlanningLine(JobPlanningLine, true, false);  // Contract Line - True and Schedule Line - False.
        CreateJobLedgerEntry(JobLedgerEntry, JobTask, JobPlanningLine."No.", JobLedgerEntry."Entry Type"::Sale);

        // Exercise.
        REPORT.Run(REPORT::"Customer Jobs (Price)");  // Opens handler - CustomerJobsPriceContractRequestPageHandler.

        // Verify: Verify Budgeted Price and Invoiced Price on Report Customer Jobs (Price).
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(BudgetedPriceCap, JobPlanningLine."Total Price (LCY)");
        LibraryReportDataset.AssertElementWithValueExists(InvoicedPriceCap, -JobLedgerEntry."Total Price (LCY)");
    end;

    [Test]
    [HandlerFunctions('CustomerJobsPriceScheduleRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordScheduleCustomerJobsPrice()
    var
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        JobLedgerEntry: Record "Job Ledger Entry";
        Job: Record Job;
    begin
        // Purpose of the test is to validate OnAfterGetRecord Trigger of Report 10214 - Customer Jobs (Price).

        // Setup: Create Job Task, Job Planning Line and Job Ledger Entry.
        Initialize();
        CreateJobTask(JobTask, JobTask."Job Task Type"::Posting);
        UpdateStatusJob(JobTask."Job No.", Job.Status::Open);
        CreateJobPlanningLine(JobPlanningLine, JobTask, JobPlanningLine."Line Type"::Budget, LibraryUTUtility.GetNewCode());
        UpdateJobPlanningLine(JobPlanningLine, false, true);  // Contract Line - False and Schedule Line - True.
        CreateJobLedgerEntry(JobLedgerEntry, JobTask, JobPlanningLine."No.", JobLedgerEntry."Entry Type");

        // Exercise.
        REPORT.Run(REPORT::"Customer Jobs (Price)");  // Opens handler - CustomerJobsPriceScheduleRequestPageHandler.

        // Verify: Verify Budgeted Price and Usage Price on Report Customer Jobs (Price).
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(BudgetedPriceCap, JobPlanningLine."Total Price (LCY)");
        LibraryReportDataset.AssertElementWithValueExists(UsagePriceCap, JobLedgerEntry."Total Price (LCY)");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure GetItemDescriptionWithResourceJobCostBudget()
    var
        Resource: Record Resource;
        JobPlanningLine: Record "Job Planning Line";
        JobCostBudget: Report "Job Cost Budget";
        ResourceName: Text[50];
    begin
        // Purpose of the test is to validate GetItemDescription Function of Report 10215 - Job Cost Budget.
        // Setup.
        Initialize();
        CreateResource(Resource);

        // Exercise: Function GetItemDescription of Report Job Cost Budget with Resource
        ResourceName := JobCostBudget.GetItemDescription(JobPlanningLine.Type::Resource.AsInteger(), Resource."No.");

        // Verify: Verify Resource Name.
        Resource.TestField(Name, ResourceName);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure GetItemDescriptionWithGLAccountJobCostBudget()
    var
        GLAccount: Record "G/L Account";
        JobPlanningLine: Record "Job Planning Line";
        JobCostBudget: Report "Job Cost Budget";
        GLAccountName: Text[50];
    begin
        // Purpose of the test is to validate GetItemDescription Function of Report 10215 - Job Cost Budget.
        // Setup.
        Initialize();
        CreateGLAccount(GLAccount);

        // Exercise: Function GetItemDescription of Report Job Cost Budget with GL Account.
        GLAccountName := JobCostBudget.GetItemDescription(JobPlanningLine.Type::"G/L Account".AsInteger(), GLAccount."No.");

        // Verify: Verify GL Account Name.
        GLAccount.TestField(Name, GLAccountName);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure GetItemDescriptionJobCostBudget()
    var
        Item: Record Item;
        JobPlanningLine: Record "Job Planning Line";
        JobCostBudget: Report "Job Cost Budget";
        ItemDescription: Text[50];
    begin
        // Purpose of the test is to validate GetItemDescription Function of Report 10215 - Job Cost Budget.
        // Setup.
        Initialize();
        CreateItem(Item);

        // Exercise: Function GetItemDescription of Report Job Cost Budget with GL Account.
        ItemDescription := JobCostBudget.GetItemDescription(JobPlanningLine.Type::Item.AsInteger(), Item."No.");

        // Verify: Verify Item Description.
        Item.TestField(Description, ItemDescription);
    end;

    [Test]
    [HandlerFunctions('JobCostBudgetScheduleRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemJobPlanningLineTypeScheduleJobCostBudget()
    var
        JobPlanningLine: Record "Job Planning Line";
        JobTask: Record "Job Task";
    begin
        // Purpose of the test is to validate OnPreDataItem - JobPlanningLine Trigger of Report 10215 - Job Cost Budget.

        // Setup: Create Job Task and Job Planning Line.
        Initialize();
        CreateJobTask(JobTask, JobTask."Job Task Type"::Posting);
        CreateJobPlanningLine(JobPlanningLine, JobTask, JobPlanningLine."Line Type"::Budget, LibraryUTUtility.GetNewCode());

        // Exercise.
        REPORT.Run(REPORT::"Job Cost Budget");  // Opens JobCostBudgetScheduleRequestPageHandler.

        // Verify: Verify Total Cost (LCY), Total Price (LCY) and Budget Option as Schedule on Report Job Cost Budget.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Job_Planning_Line__Total_Cost__LCY__', JobPlanningLine."Total Cost (LCY)");
        LibraryReportDataset.AssertElementWithValueExists('Job_Planning_Line__Total_Price__LCY__', JobPlanningLine."Total Price (LCY)");
        LibraryReportDataset.AssertElementWithValueExists(BudgetOptionCap, Format(BudgetedScheduleTxt));
    end;

    [Test]
    [HandlerFunctions('JobCostBudgetContractRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemJobPlanningLineTypeContractJobCostBudget()
    var
        JobPlanningLine: Record "Job Planning Line";
        JobTask: Record "Job Task";
    begin
        // Purpose of the test is to validate OnPreDataItem - JobPlanningLine Trigger of Report 10215 - Job Cost Budget.

        // Setup: Create Job Task and Job Planning Line.
        Initialize();
        CreateJobTask(JobTask, JobTask."Job Task Type"::"End-Total");
        CreateJobPlanningLine(JobPlanningLine, JobTask, JobPlanningLine."Line Type"::Billable, LibraryUTUtility.GetNewCode());

        // Exercise.
        REPORT.Run(REPORT::"Job Cost Budget");  // Opens JobCostBudgetContractRequestPageHandler.

        // Verify: Verify Budget Option as Contract on Report Job Cost Budget.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(BudgetOptionCap, Format(BudgetedContractTxt));
    end;

    [Test]
    [HandlerFunctions('JobListScheduleRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordJobTypeScheduleJobList()
    var
        JobPlanningLine: Record "Job Planning Line";
        JobTask: Record "Job Task";
    begin
        // Purpose of the test is to validate OnAfterGetRecord - Job Trigger of Report 10216 - Job List.

        // Setup: Create Job Task and Job Planning Line.
        Initialize();
        CreateJobTask(JobTask, JobTask."Job Task Type"::Total);
        CreateJobPlanningLine(JobPlanningLine, JobTask, JobPlanningLine."Line Type"::Budget, LibraryUTUtility.GetNewCode());

        // Exercise.
        REPORT.Run(REPORT::"Job List");  // Opens JobListScheduleRequestPageHandler.

        // Verify: Verify Total Cost (LCY), Total Price (LCY) and Budget Option as Schedule on Report Job.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('JobPlanningLine__Total_Cost__LCY__', JobPlanningLine."Total Cost (LCY)");
        LibraryReportDataset.AssertElementWithValueExists('JobPlanningLine__Total_Price__LCY__', JobPlanningLine."Total Price (LCY)");
        LibraryReportDataset.AssertElementWithValueExists(BudgetOptionCap, Format(BudgetedScheduleTxt));
    end;

    [Test]
    [HandlerFunctions('JobListContractRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemJobTypeContractJobList()
    var
        JobPlanningLine: Record "Job Planning Line";
        JobTask: Record "Job Task";
    begin
        // Purpose of the test is to validate OnPreDataItem - Job Trigger of Report 10216 - Job List.

        // Setup: Create Job Task and Job Planning Line.
        Initialize();
        CreateJobTask(JobTask, JobTask."Job Task Type"::Total);
        CreateJobPlanningLine(JobPlanningLine, JobTask, JobPlanningLine."Line Type"::Billable, LibraryUTUtility.GetNewCode());

        // Exercise.
        REPORT.Run(REPORT::"Job List");  // Opens JobListContractRequestPageHandler.

        // Verify: Verify Budget Option as Contract on Report Job Cost Budget.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(BudgetOptionCap, Format(BudgetedContractTxt));
    end;

    [Test]
    [HandlerFunctions('JobRegisterRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordJobLedgerEntryJobRegister()
    var
        JobTask: Record "Job Task";
        Job: Record Job;
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        // Purpose of the test is to validate OnAfterGetRecord - JobLedgerEntry Trigger of Report 10217 - Job Register.

        // Setup: Create Job Task, Job Ledger Entry and Job Register.
        Initialize();
        CreateJobTask(JobTask, JobTask."Job Task Type"::Total);
        CreateJobLedgerEntry(JobLedgerEntry, JobTask, LibraryUTUtility.GetNewCode(), JobLedgerEntry."Entry Type");
        CreateJobRegister(JobLedgerEntry."Entry No.");

        // Exercise.
        REPORT.Run(REPORT::"Job Register");  // Opens JobRegisterRequestPageHandler

        // Verify: Verify Filter on Job Ledger Entry and Job Description on Report Job Register.
        Job.Get(JobTask."Job No.");
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(
          'JobEntryFilter', StrSubstNo('%1: %2', JobLedgerEntry.FieldCaption("Job No."), JobLedgerEntry."Job No."));
        LibraryReportDataset.AssertElementWithValueExists('JobDescription', Job.Description);
    end;

    [Test]
    [HandlerFunctions('JobCostSuggestedBillingRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordJobContractPriceCostSuggestedBilling()
    var
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        Job: Record Job;
    begin
        // Purpose of the test is to validate OnAfterGetRecord - Job Trigger of Report 10219 - Job Cost Suggested Billing.

        // Setup: Create Job Task and Job Planning Line.
        Initialize();
        CreateJobTask(JobTask, JobTask."Job Task Type"::Total);
        CreateJobPlanningLine(JobPlanningLine, JobTask, JobPlanningLine."Line Type"::Billable, LibraryUTUtility.GetNewCode());
        UpdateStatusJob(JobTask."Job No.", Job.Status::Open);
        UpdateJobPlanningLine(JobPlanningLine, true, false);  // Contract Line - True and Schedule Line - False.

        // Exercise.
        REPORT.Run(REPORT::"Job Cost Suggested Billing");  // Opens JobCostSuggestedBillingRequestPageHandler.

        // Verify: Verify Contract Price on Report Job Cost Suggested Billing.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(ContractPriceCap, JobPlanningLine."Total Price (LCY)");
    end;

    [Test]
    [HandlerFunctions('JobCostSuggestedBillingRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordJobInvoicedPriceCostSuggestedBilling()
    var
        Item: Record Item;
        JobTask: Record "Job Task";
        Job: Record Job;
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        // Purpose of the test is to validate OnAfterGetRecord - Job Trigger of Report 10219 - Job Cost Suggested Billing.

        // Setup: Create Job Task and Job Ledger Entry.
        Initialize();
        CreateJobTask(JobTask, JobTask."Job Task Type"::Total);
        UpdateStatusJob(JobTask."Job No.", Job.Status::Open);
        CreateJobLedgerEntry(JobLedgerEntry, JobTask, Item."No.", JobLedgerEntry."Entry Type"::Sale);

        // Exercise.
        REPORT.Run(REPORT::"Job Cost Suggested Billing");  // Opens JobCostSuggestedBillingRequestPageHandler.

        // Verify: Verify Invoiced Price on Report Job Cost Suggested Billing.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(InvoicedPriceCap, -JobLedgerEntry."Total Price (LCY)");
    end;

    [Test]
    [HandlerFunctions('JobCostSuggestedBillingRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordJobUsagePriceCostSuggestedBilling()
    var
        Item: Record Item;
        JobTask: Record "Job Task";
        Job: Record Job;
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        // Purpose of the test is to validate OnAfterGetRecord - Job Trigger of Report 10219 - Job Cost Suggested Billing.

        // Setup: Create Job Task and Job Ledger Entry.
        Initialize();
        CreateJobTask(JobTask, JobTask."Job Task Type"::Total);
        UpdateStatusJob(JobTask."Job No.", Job.Status::Open);
        CreateJobLedgerEntry(JobLedgerEntry, JobTask, Item."No.", JobLedgerEntry."Entry Type"::Usage);

        // Exercise.
        REPORT.Run(REPORT::"Job Cost Suggested Billing");  // Opens JobCostSuggestedBillingRequestPageHandler.

        // Verify: Verify Usage Price and Suggested Billing on Report Job Cost Suggested Billing.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(UsagePriceCap, JobLedgerEntry."Total Price (LCY)");
        LibraryReportDataset.AssertElementWithValueExists('SuggestedBilling', JobLedgerEntry."Total Price (LCY)");
    end;

    [Test]
    [HandlerFunctions('JobCostTransactionDetailRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordJobLedgerEntryPriceCostTransacDetail()
    var
        JobTask: Record "Job Task";
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        // Purpose of the test is to validate OnAfterGetRecord - JobLedgerEntry Trigger of Report 10220 - Job Cost Transaction Detail.

        // Setup: Create Job Task and Job Ledger Entry.
        Initialize();
        CreateJobTask(JobTask, JobTask."Job Task Type"::Total);
        CreateJobLedgerEntry(JobLedgerEntry, JobTask, LibraryUTUtility.GetNewCode(), JobLedgerEntry."Entry Type"::Usage);
        JobLedgerEntry."Amt. Posted to G/L" := LibraryRandom.RandDec(10, 2);
        JobLedgerEntry.Modify();

        // Exercise.
        REPORT.Run(REPORT::"Job Cost Transaction Detail");  // Opens JobCostTransactionDetailRequestPageHandler.

        // Verify: Verify Total Price (LCY), Total Cost (LCY) and Amount Posted To G/L on Report Job Cost Transaction Detail.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('TotalPrice_1_', JobLedgerEntry."Total Price (LCY)");
        LibraryReportDataset.AssertElementWithValueExists('TotalCost_1_', JobLedgerEntry."Total Cost (LCY)");
        LibraryReportDataset.AssertElementWithValueExists('AmtPostedToGL_1_', JobLedgerEntry."Amt. Posted to G/L");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure GetItemDescriptionWithGLAccountJobActualToBudgetCostLong()
    var
        JobPlanningLine: Record "Job Planning Line";
        GLAccount: Record "G/L Account";
        JobActualToBudgetCost: Report "Job Actual to Budget (Cost)";
        GLAccountName: Text[50];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 388422] Report 10210 GetItemDescription can handle description of size 100
        Initialize();

        // [GIVEN] G/L Account was created
        CreateGLAccount(GLAccount);

        // [GIVEN] G/L Account Name has length 100
        GLAccount.Validate(Name, LibraryRandom.RandText(100));
        GLAccount.Modify(true);

        // [WHEN] Run Function GetItemDescription of Report Job Actual to Budget (Cost) with GL Account.
        GLAccountName := JobActualToBudgetCost.GetItemDescription(JobPlanningLine.Type::"G/L Account".AsInteger(), GLAccount."No.");

        // [THEN] No error and the result is first 50 symbols of name
        Assert.AreEqual(CopyStr(GLAccount.Name, 1, 50), GLAccountName, 'Names must be equal.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure GetItemDescriptionWithGLAccountJobActualToBudgetPriceLong()
    var
        JobPlanningLine: Record "Job Planning Line";
        GLAccount: Record "G/L Account";
        JobActualToBudgetPrice: Report "Job Actual to Budget (Price)";
        GLAccountName: Text[50];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 388422] Report 10211 GetItemDescription can handle description of size 100
        Initialize();

        // [GIVEN] G/L Account was created
        CreateGLAccount(GLAccount);

        // [GIVEN] G/L Account Name has length 100
        GLAccount.Validate(Name, LibraryRandom.RandText(100));
        GLAccount.Modify(true);

        // [WHEN] Run Function GetItemDescription of Report Job Actual to Budget (Price) with GL Account.
        GLAccountName := JobActualToBudgetPrice.GetItemDescription(JobPlanningLine.Type::"G/L Account".AsInteger(), GLAccount."No.");

        // [THEN] No error and the result is first 50 symbols of name
        Assert.AreEqual(CopyStr(GLAccount.Name, 1, 50), GLAccountName, 'Names must be equal.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure GetItemDescriptionWithGLAccountJobCostBudgetLong()
    var
        GLAccount: Record "G/L Account";
        JobPlanningLine: Record "Job Planning Line";
        JobCostBudget: Report "Job Cost Budget";
        GLAccountName: Text[50];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 388422] Report 10215 GetItemDescription can handle description of size 100
        Initialize();

        // [GIVEN] G/L Account was created
        CreateGLAccount(GLAccount);

        // [GIVEN] G/L Account Name has length 100
        GLAccount.Validate(Name, LibraryRandom.RandText(100));
        GLAccount.Modify(true);

        // [WHEN] Run Function GetItemDescription of Report Job Cost Budget with GL Account.
        GLAccountName := JobCostBudget.GetItemDescription(JobPlanningLine.Type::"G/L Account".AsInteger(), GLAccount."No.");

        // [THEN] No error and the result is first 50 symbols of name
        Assert.AreEqual(CopyStr(GLAccount.Name, 1, 50), GLAccountName, 'Names must be equal.');
    end;

    [Test]
    [HandlerFunctions('CustomerJobsCostRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyPercentagesCompletedOnCustomerJobsCostReport()
    var
        JobTask: Record "Job Task";
        JobTask2: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        JobPlanningLine2: Record "Job Planning Line";
        Customer: Record Customer;
        Vendor: Record Vendor;
        Item: Record Item;
        LibrarySales: Codeunit "Library - Sales";
        UsageCost: Decimal;
        ScheduledCost: Decimal;
        VATProdPostingGroupCode: Code[20];
    begin
        // [SCENARIO 454702] Validate percentages on Report 10213 - Customer Jobs (Cost).

        // [GIVEN] Create Customer, Vendor, Item, 2 Jobs, Job Task, Job Planning Line
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CreateVendor(Vendor, VATProdPostingGroupCode);
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Cost", LibraryRandom.RandDec(10, 2));
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroupCode);
        Item.Modify(true);
        CreateJobAndJobTask(JobTask, Customer."No.");
        CreateJobPlanningLine(JobPlanningLine, Item, JobTask);
        CreateJobAndJobTask(JobTask2, Customer."No.");
        CreateJobPlanningLine(JobPlanningLine2, Item, JobTask2);

        // [GIVEN] Post purchase invoices for both jobs
        CreateAndPostPurchOrder(Vendor, Item, JobTask."Job No.", JobTask."Job Task No.", JobPlanningLine."Line No.");
        CreateAndPostPurchOrder(Vendor, Item, JobTask2."Job No.", JobTask2."Job Task No.", JobPlanningLine2."Line No.");

        // [GIVEN] Run Customer Job (Cost) report
        LibraryVariableStorage.Enqueue(JobTask."Job No." + '|' + JobTask2."Job No.");
        Report.Run(Report::"Customer Jobs (Cost)"); // Opens handler - CustomerJobsCostRequestPageHandler.

        // [VERIFY]: Verify Job No, Scheduled Cost and Usage Cost on Report Customer Jobs (Cost).
        LibraryReportDataset.LoadDataSetFile();
        ScheduledAndUsageCosts(JobTask, ScheduledCost, UsageCost);
        LibraryReportDataset.AssertElementWithValueExists('Percent_Completion__Control22', (UsageCost / ScheduledCost) * 100);
        ScheduledAndUsageCosts(JobTask2, ScheduledCost, UsageCost);
        LibraryReportDataset.AssertElementWithValueExists('Percent_Completion__Control22', (UsageCost / ScheduledCost) * 100);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateItem(var Item: Record Item)
    begin
        Item."No." := LibraryUTUtility.GetNewCode();
        Item.Description := LibraryUTUtility.GetNewCode();
        Item.Insert();
    end;

    local procedure CreateResource(var Resource: Record Resource)
    begin
        Resource."No." := LibraryUTUtility.GetNewCode();
        Resource.Name := LibraryUTUtility.GetNewCode();
        Resource.Insert();
    end;

    local procedure CreateGLAccount(var GLAccount: Record "G/L Account")
    begin
        GLAccount."No." := LibraryUTUtility.GetNewCode();
        GLAccount.Name := LibraryUTUtility.GetNewCode();
        GLAccount.Insert();
    end;

    local procedure CreateJob(var Job: Record Job)
    begin
        Job."No." := LibraryUTUtility.GetNewCode();
        Job.Description := LibraryUTUtility.GetNewCode();
        Job."Bill-to Customer No." := LibraryUTUtility.GetNewCode();
        Job.Insert();
        LibraryVariableStorage.Enqueue(Job."No.");  // Enqueue value for Request Page Handler.
    end;

    local procedure CreateJobTask(var JobTask: Record "Job Task"; JobTaskType: Enum "Job Task Type")
    var
        Job: Record Job;
    begin
        CreateJob(Job);
        JobTask."Job No." := Job."No.";
        JobTask."Job Task No." := LibraryUTUtility.GetNewCode();
        JobTask."Job Task Type" := JobTaskType;
        JobTask.Insert();
    end;

    local procedure CreateJobPlanningLine(var JobPlanningLine: Record "Job Planning Line"; JobTask: Record "Job Task"; LineType: Enum "Job Planning Line Line Type"; ItemNo: Code[20])
    begin
        FillJobPlanningLine(JobPlanningLine, JobTask, LineType, ItemNo);
        JobPlanningLine.Insert();
    end;

    local procedure CreateJobPlanningLineWithUOM(var JobPlanningLine: Record "Job Planning Line"; JobTask: Record "Job Task"; LineType: Enum "Job Planning Line Line Type"; ItemNo: Code[20])
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, ItemNo, 1);
        FillJobPlanningLine(JobPlanningLine, JobTask, LineType, ItemNo);
        JobPlanningLine."Unit of Measure Code" := ItemUnitOfMeasure.Code;
        JobPlanningLine.Insert();
    end;

    local procedure FillJobPlanningLine(var JobPlanningLine: Record "Job Planning Line"; JobTask: Record "Job Task"; LineType: Enum "Job Planning Line Line Type"; ItemNo: Code[20])
    begin
        JobPlanningLine."Job No." := JobTask."Job No.";
        JobPlanningLine."Job Task No." := JobTask."Job Task No.";
        JobPlanningLine."Line Type" := LineType;
        JobPlanningLine."Line No." := SelectJobPlanningLineNo(JobTask."Job No.");
        JobPlanningLine.Type := JobPlanningLine.Type::Item;
        JobPlanningLine."No." := ItemNo;
        JobPlanningLine.Quantity := LibraryRandom.RandDec(10, 2);
        JobPlanningLine."Total Cost (LCY)" := LibraryRandom.RandDec(10, 2);
        JobPlanningLine."Total Price (LCY)" := LibraryRandom.RandDec(10, 2);
    end;

    local procedure CreateJobLedgerEntry(var JobLedgerEntry: Record "Job Ledger Entry"; JobTask: Record "Job Task"; ItemNo: Code[20]; EntryType: Enum "Job Journal Line Entry Type")
    begin
        FillJobLedgerEntry(JobLedgerEntry, JobTask, ItemNo, EntryType);
        JobLedgerEntry.Insert();
    end;

    local procedure CreateJobLedgerEntryWithUOM(var JobLedgerEntry: Record "Job Ledger Entry"; JobTask: Record "Job Task"; ItemNo: Code[20]; EntryType: Enum "Job Journal Line Entry Type")
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, ItemNo, 1);
        FillJobLedgerEntry(JobLedgerEntry, JobTask, ItemNo, EntryType);
        JobLedgerEntry."Unit of Measure Code" := ItemUnitOfMeasure.Code;
        JobLedgerEntry.Insert();
    end;

    local procedure FillJobLedgerEntry(var JobLedgerEntry: Record "Job Ledger Entry"; JobTask: Record "Job Task"; ItemNo: Code[20]; EntryType: Enum "Job Journal Line Entry Type")
    begin
        JobLedgerEntry."Entry No." := SelectJobLedgerEntryNo();
        JobLedgerEntry."Job No." := JobTask."Job No.";
        JobLedgerEntry."Job Task No." := JobTask."Job Task No.";
        JobLedgerEntry.Type := JobLedgerEntry.Type::Item;
        JobLedgerEntry."No." := ItemNo;
        JobLedgerEntry."Entry Type" := EntryType;
        JobLedgerEntry.Quantity := LibraryRandom.RandDec(10, 2);
        JobLedgerEntry."Total Cost (LCY)" := LibraryRandom.RandDec(10, 2);
        JobLedgerEntry."Total Price (LCY)" := LibraryRandom.RandDec(10, 2);
    end;

    local procedure CreateJobRegister(JobLedgerEntryEntryNo: Integer)
    var
        JobRegister: Record "Job Register";
        JobRegister2: Record "Job Register";
    begin
        JobRegister2.FindLast();
        JobRegister."No." := JobRegister2."No." + 1;
        JobRegister."From Entry No." := JobLedgerEntryEntryNo;
        JobRegister."To Entry No." := JobLedgerEntryEntryNo;
        JobRegister.Insert();
    end;

    local procedure SelectJobPlanningLineNo(JobNo: Code[20]): Integer
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        JobPlanningLine.SetRange("Job No.", JobNo);
        if JobPlanningLine.FindLast() then
            exit(JobPlanningLine."Line No." + 1);
        exit(1)
    end;

    local procedure SelectJobLedgerEntryNo(): Integer
    var
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        if JobLedgerEntry.FindLast() then
            exit(JobLedgerEntry."Entry No." + 1);
        exit(1)
    end;

    local procedure UpdateTotalingJobTask(var JobTask: Record "Job Task")
    begin
        JobTask.Totaling := JobTask."Job Task No.";
        JobTask.Modify();
    end;

    local procedure UpdateStatusJob(JobNo: Code[20]; Status: Enum "Job Status")
    var
        Job: Record Job;
    begin
        Job.Get(JobNo);
        Job.Status := Status;
        Job.Modify();
    end;

    local procedure UpdateJobPlanningLine(JobPlanningLine: Record "Job Planning Line"; ContractLine: Boolean; ScheduleLine: Boolean)
    begin
        JobPlanningLine."Contract Line" := ContractLine;
        JobPlanningLine."Schedule Line" := ScheduleLine;
        JobPlanningLine.Modify();
    end;

    local procedure JobActualToBudgetCostRequestPage(var JobActualToBudgetCost: TestRequestPage "Job Actual to Budget (Cost)"; BudgetAmountsPer: Option)
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        JobActualToBudgetCost.Job.SetFilter("No.", No);
        JobActualToBudgetCost.BudgetAmountsPer.SetValue(BudgetAmountsPer);
        JobActualToBudgetCost.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    local procedure JobActualToBudgetPriceRequestPage(var JobActualToBudgetPrice: TestRequestPage "Job Actual to Budget (Price)"; BudgetAmountsPer: Option; ActualAmountsPer: Option)
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        JobActualToBudgetPrice.Job.SetFilter("No.", No);
        JobActualToBudgetPrice.BudgetAmountsPer.SetValue(BudgetAmountsPer);
        JobActualToBudgetPrice.ActualAmountsPer.SetValue(ActualAmountsPer);
        JobActualToBudgetPrice.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    local procedure CustomerJobsPriceRequestPage(var CustomerJobsPrice: TestRequestPage "Customer Jobs (Price)"; BudgetAmountsPer: Option)
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        CustomerJobsPrice.Job.SetFilter("No.", No);
        CustomerJobsPrice.BudgetAmountsPer.SetValue(BudgetAmountsPer);
        CustomerJobsPrice.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    local procedure JobCostBudgetRequestPage(var JobCostBudget: TestRequestPage "Job Cost Budget"; BudgetAmountsPer: Option)
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        JobCostBudget.Job.SetFilter("No.", No);
        JobCostBudget.BudgetAmountsPer.SetValue(BudgetAmountsPer);
        JobCostBudget.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    local procedure JobListRequestPage(var JobList: TestRequestPage "Job List"; BudgetAmountsPer: Option)
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        JobList.Job.SetFilter("No.", No);
        JobList.BudgetAmountsPer.SetValue(BudgetAmountsPer);
        JobList.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    local procedure VerifyCostOnJobActualToBudgetCostReport(JobLedgerEntryTotalCostLCY: Decimal; JobPlanningLineTotalCostLCY: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('JobDiffBuff__Total_Cost_', JobLedgerEntryTotalCostLCY);
        LibraryReportDataset.AssertElementWithValueExists(BudgetedTotalCostCap, JobPlanningLineTotalCostLCY);
        LibraryReportDataset.AssertElementWithValueExists(VarianceCap, JobLedgerEntryTotalCostLCY - JobPlanningLineTotalCostLCY);
    end;

    local procedure VerifyPriceOnJobActualToBudgetPriceReport(JobLedgerEntryTotalPriceLCY: Decimal; JobPlanningLineTotalPriceLCY: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('JobDiffBuff__Line_Amount_', JobLedgerEntryTotalPriceLCY);
        LibraryReportDataset.AssertElementWithValueExists(BudgetedLineAmountCap, JobPlanningLineTotalPriceLCY);
        LibraryReportDataset.AssertElementWithValueExists(VarianceCap, JobLedgerEntryTotalPriceLCY - JobPlanningLineTotalPriceLCY);
    end;

    local procedure VerifyCompletedJobsReport(TotalCostLCY: Decimal; TotalPriceLCY: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(UsageCostCap, TotalCostLCY);
        LibraryReportDataset.AssertElementWithValueExists(ContractPriceCap, TotalPriceLCY);
    end;

    local procedure CreateVendor(var Vendor: Record Vendor; var VATProdPostingGroupCode: Code[20])
    var
        VATPostingSetup: Record "VAT Posting Setup";
        LibraryPurchase: Codeunit "Library - Purchase";
    begin
        CreateVATPostingSetupForSalesTax(VATPostingSetup, VATProdPostingGroupCode);
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Vendor.Modify(true);
    end;

    local procedure CreateVATPostingSetupForSalesTax(var VATPostingSetup: Record "VAT Posting Setup"; var VATProdPostingGroupCode: Code[20])
    var
        VATBusPostingGroup: Record "VAT Business Posting Group";
        VATProdPostingGroup: Record "VAT Product Posting Group";
        LibraryERM: Codeunit "Library - ERM";
    begin
        LibraryERM.CreateVATBusinessPostingGroup(VATBusPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProdPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostingGroup.Code, VATProdPostingGroup.Code);
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Sales Tax");
        VATPostingSetup.Modify(true);
        VATProdPostingGroupCode := VATProdPostingGroup.Code;
    end;

    local procedure ScheduledAndUsageCosts(JobTask: Record "Job Task"; var ScheduledCost: Decimal; var UsageCost: Decimal)
    var
        JobPlanningLine: Record "Job Planning Line";
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        ScheduledCost := 0;
        UsageCost := 0;

        JobPlanningLine.Reset();
        JobPlanningLine.SetCurrentKey("Job No.", "Job Task No.", "Schedule Line", "Planning Date");
        JobPlanningLine.SetRange("Job No.", JobTask."Job No.");
        JobTask.CopyFilter("Planning Date Filter", JobPlanningLine."Planning Date");
        JobPlanningLine.SetRange("Schedule Line", true);
        JobPlanningLine.CalcSums("Total Cost (LCY)");
        ScheduledCost := JobPlanningLine."Total Cost (LCY)";

        JobLedgerEntry.Reset();
        JobLedgerEntry.SetCurrentKey("Job No.", "Job Task No.", "Entry Type", "Posting Date");
        JobLedgerEntry.SetRange("Job No.", JobTask."Job No.");
        JobTask.CopyFilter("Posting Date Filter", JobLedgerEntry."Posting Date");
        JobLedgerEntry.SetRange("Entry Type", JobLedgerEntry."Entry Type"::Usage);
        JobLedgerEntry.CalcSums("Total Cost (LCY)");
        UsageCost := JobLedgerEntry."Total Cost (LCY)";
    end;

    local procedure CreateJobAndJobTask(var JobTask: Record "Job Task"; CustomerNo: Code[20])
    var
        Job: Record Job;
        LibraryJob: Codeunit "Library - Job";
    begin
        LibraryJob.CreateJob(Job, CustomerNo);
        LibraryJob.CreateJobTask(Job, JobTask);
    end;

    local procedure CreateJobPlanningLine(var JobPlanningLine: Record "Job Planning Line"; Item: Record Item; JobTask: Record "Job Task")
    var
        LibraryJob: Codeunit "Library - Job";
    begin
        LibraryJob.CreateJobPlanningLine(LibraryJob.PlanningLineTypeBoth(), LibraryJob.ItemType(), JobTask, JobPlanningLine);
        JobPlanningLine.Validate("No.", Item."No.");
        JobPlanningLine.Validate(Quantity, LibraryRandom.RandDec(10, 2));  // Using Random value for Quantity because value is not important.
        JobPlanningLine.Validate("Unit Cost", Item."Unit Cost");
        JobPlanningLine.Modify(true);
    end;

    local procedure CreateAndPostPurchOrder(Vendor: Record Vendor; Item: Record Item; JobNo: Code[20]; JobTaskNo: Code[20]; JobPlanningLineNo: Integer): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LibraryPurchase: Codeunit "Library - Purchase";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandInt(3));
        PurchaseLine.Validate("Direct Unit Cost", Item."Unit Cost");
        PurchaseLine.Validate("Job No.", JobNo);
        PurchaseLine.Validate("Job Task No.", JobTaskNo);
        PurchaseLine.Validate("Job Line Type", PurchaseLine."Job Line Type"::Budget);
        PurchaseLine.Validate("Job Planning Line No.", JobPlanningLineNo);
        PurchaseLine.Modify(true);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure JobActualToBudgetCostPrintToExcelRequestPageHandler(var JobActualToBudgetCost: TestRequestPage "Job Actual to Budget (Cost)")
    var
        No: Variant;
        No2: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(No2);
        JobActualToBudgetCost.Job.SetFilter("No.", Format(StrSubstNo(JobNoFilterTxt, No, No2)));
        JobActualToBudgetCost.PrintToExcel.SetValue(true);
        JobActualToBudgetCost.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure JobActualToBudgetCostScheduleRequestPageHandler(var JobActualToBudgetCost: TestRequestPage "Job Actual to Budget (Cost)")
    var
        BudgetAmountsPer: Option Schedule,Contract;
    begin
        JobActualToBudgetCostRequestPage(JobActualToBudgetCost, BudgetAmountsPer::Schedule);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure JobActualToBudgetCostContractRequestPageHandler(var JobActualToBudgetCost: TestRequestPage "Job Actual to Budget (Cost)")
    var
        BudgetAmountsPer: Option Schedule,Contract;
    begin
        JobActualToBudgetCostRequestPage(JobActualToBudgetCost, BudgetAmountsPer::Contract);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure JobActualToBudgetPricePrintToExcelRequestPageHandler(var JobActualToBudgetPrice: TestRequestPage "Job Actual to Budget (Price)")
    var
        No: Variant;
        No2: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(No2);
        JobActualToBudgetPrice.Job.SetFilter("No.", Format(StrSubstNo(JobNoFilterTxt, No, No2)));
        JobActualToBudgetPrice.PrintToExcel.SetValue(true);
        JobActualToBudgetPrice.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure JobActualToBudgetPriceScheduleRequestPageHandler(var JobActualToBudgetPrice: TestRequestPage "Job Actual to Budget (Price)")
    var
        BudgetAmountsPer: Option Schedule,Contract;
        ActualAmountsPer: Option Usage,Invoices;
    begin
        JobActualToBudgetPriceRequestPage(JobActualToBudgetPrice, BudgetAmountsPer::Schedule, ActualAmountsPer::Usage);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure JobActualToBudgetPriceContractRequestPageHandler(var JobActualToBudgetPrice: TestRequestPage "Job Actual to Budget (Price)")
    var
        BudgetAmountsPer: Option Schedule,Contract;
        ActualAmountsPer: Option Usage,Invoices;
    begin
        JobActualToBudgetPriceRequestPage(JobActualToBudgetPrice, BudgetAmountsPer::Contract, ActualAmountsPer::Invoices);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CompletedJobsRequestPageHandler(var CompletedJobs: TestRequestPage "Completed Jobs")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        CompletedJobs.Job.SetFilter("No.", No);
        CompletedJobs.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerJobsCostRequestPageHandler(var CustomerJobsCost: TestRequestPage "Customer Jobs (Cost)")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        CustomerJobsCost.Job.SetFilter("No.", No);
        CustomerJobsCost.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerJobsPriceContractRequestPageHandler(var CustomerJobsPrice: TestRequestPage "Customer Jobs (Price)")
    var
        BudgetAmountsPer: Option Schedule,Contract;
    begin
        CustomerJobsPriceRequestPage(CustomerJobsPrice, BudgetAmountsPer::Contract);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerJobsPriceScheduleRequestPageHandler(var CustomerJobsPrice: TestRequestPage "Customer Jobs (Price)")
    var
        BudgetAmountsPer: Option Schedule,Contract;
    begin
        CustomerJobsPriceRequestPage(CustomerJobsPrice, BudgetAmountsPer::Schedule);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure JobCostBudgetScheduleRequestPageHandler(var JobCostBudget: TestRequestPage "Job Cost Budget")
    var
        BudgetAmountsPer: Option Schedule,Contract;
    begin
        JobCostBudgetRequestPage(JobCostBudget, BudgetAmountsPer::Schedule);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure JobCostBudgetContractRequestPageHandler(var JobCostBudget: TestRequestPage "Job Cost Budget")
    var
        BudgetAmountsPer: Option Schedule,Contract;
    begin
        JobCostBudgetRequestPage(JobCostBudget, BudgetAmountsPer::Contract);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure JobListScheduleRequestPageHandler(var JobList: TestRequestPage "Job List")
    var
        BudgetAmountsPer: Option Schedule,Contract;
    begin
        JobListRequestPage(JobList, BudgetAmountsPer::Schedule);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure JobListContractRequestPageHandler(var JobList: TestRequestPage "Job List")
    var
        BudgetAmountsPer: Option Schedule,Contract;
    begin
        JobListRequestPage(JobList, BudgetAmountsPer::Contract);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure JobRegisterRequestPageHandler(var JobRegister: TestRequestPage "Job Register")
    var
        JobNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(JobNo);
        JobRegister."Job Ledger Entry".SetFilter("Job No.", JobNo);
        JobRegister.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure JobCostSuggestedBillingRequestPageHandler(var JobCostSuggestedBilling: TestRequestPage "Job Cost Suggested Billing")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        JobCostSuggestedBilling.Job.SetFilter("No.", No);
        JobCostSuggestedBilling.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure JobCostTransactionDetailRequestPageHandler(var JobCostTransactionDetail: TestRequestPage "Job Cost Transaction Detail")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        JobCostTransactionDetail.Job.SetFilter("No.", No);
        JobCostTransactionDetail.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

