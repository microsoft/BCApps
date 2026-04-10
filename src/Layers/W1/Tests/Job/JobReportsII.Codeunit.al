codeunit 136311 "Job Reports II"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Reports] [Job]
        IsInitialized := false;
    end;

    var
        DummyJobsSetup: Record "Jobs Setup";
        LibraryJob: Codeunit "Library - Job";
        LibraryResource: Codeunit "Library - Resource";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryService: Codeunit "Library - Service";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUtility: Codeunit "Library - Utility";
        IsInitialized: Boolean;
        AmountErr: Label 'Total amount must be equal.';
        CurrencyField: Option "Local Currency","Foreign Currency";
        AmountField: Option " ","Budget Price","Usage Price","Billable Price","Invoiced Price","Budget Cost","Usage Cost","Billable Cost","Invoiced Cost","Budget Profit","Usage Profit","Billable Profit","Invoiced Profit";
        ContractPriceTxt: Label 'Billable Price\%1';
        ContractCostTxt: Label 'Billable Cost\%1';
        ContractProfitTxt: Label 'Billable Profit\%1';
        JobJournalTemplateName: Code[10];
        JobJournalBatchName: Code[10];
        ContractLineAmountTxt: Label 'Billable Line Amount';
        DimensionTxt: Label '%1 - %2';
        InvoicedPriceTxt: Label 'Inv. Price\%1';
        InvoicedCostTxt: Label 'Inv. Cost\%1';
        InvoicedProfitTxt: Label 'Inv. Profit\%1';
        LineDiscountAmountTxt: Label 'Line Discount Amount (%1)';
        LineAmountTxt: Label 'Line Amount (%1)';
        SchedulePriceTxt: Label 'Budget Price\%1';
        ScheduleCostTxt: Label 'Budget Cost\%1';
        ScheduleProfitTxt: Label 'Budget Profit\%1';
        ScheduleLineAmountTxt: Label 'Budget Line Amount';
        TotalContractTxt: Label 'Total Billable';
        TotalCostTxt: Label 'Total Cost (%1)';
        UsagePriceTxt: Label 'Usage Price\%1';
        UsageCostTxt: Label 'Usage Cost\%1';
        UsageProfitTxt: Label 'Usage Profit\%1';
        UsageLineAmountTxt: Label 'Usage Line Amount';
        ValueNotFoundErr: Label 'Value must exist.';
        ValueFoundErr: Label 'Value must not exist.';
        ValueNotMatchErr: Label 'Value must match.';
        DocEntryTableNameTxt: Label 'DocEntryTableName';
        DocEntryNoofRecordsTxt: Label 'DocEntryNoofRecords';
        PostingDateTxt: Label 'PstDate_ResLedgEntry';
        UnitCostResLedgEntryTxt: Label 'UnitCost_ResLedgEntry';

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure JobPerCustomerReport()
    var
        Job: Record Job;
    begin
        // Verify Jobs Per Customer report.

        // 1. Setup.
        Initialize();
        CreateInitialSetupForJob(Job);

        // 2. Exercise: Run Jobs Per Customer Report.
        RunJobPerCustomerReport(Job."Bill-to Customer No.");

        // 3. Verify: Verify Jobs Per Customer report preview.
        VerifyJobPerCustomerReport(Job."No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure ItemPerJobReport()
    var
        JobJournalLine: Record "Job Journal Line";
        JobNo: Code[20];
    begin
        // Verify Item Per Job report.

        // 1. Setup: Create Job with Job Task and Resource.
        Initialize();
        JobNo := CreateAndPostJobJournalLine(JobJournalLine."Line Type"::" ", '');

        // 2. Exercise: Run Item Per Job Report.
        RunItemPerJobReport(JobNo);

        // 3. Verify: Verify Items PerJob report preview.
        VerifyItemPerJobReport(JobNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure JobPerItemReport()
    var
        JobJournalLine: Record "Job Journal Line";
        JobNo: Code[20];
    begin
        // Verify Job Per Item report.

        // 1. Setup: Create Job with Job Task.
        Initialize();
        JobNo := CreateAndPostJobJournalLine(JobJournalLine."Line Type"::" ", '');

        // 2. Exercise: Run Job Per Item Report.
        RunJobPerItemReport();

        // 3. Verify: Verify Job Per Item report preview.
        VerifyJobPerItemReport(JobNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure JobRegisterReport()
    var
        JobJournalLine: Record "Job Journal Line";
        JobNo: Code[20];
    begin
        // Verify Job Register report.

        // 1. Setup: Create Job with Job Task.
        Initialize();
        JobNo := CreateAndPostJobJournalLine(JobJournalLine."Line Type"::" ", '');

        // 2. Exercise: Run Job Register Report.
        RunJobRegisterReport();

        // 3. Verify: Verify Job Register report preview.
        VerifyJobRegisterReport(JobNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobPlanningLinesReportWithLCY()
    begin
        // Verify Job Planning Lines Report with Local Currency.
        Initialize();
        CurrencyField := CurrencyField::"Local Currency";  // Assign in Global variable.
        JobPlanningLinesReportWithCurrency('', GetLCYCode());  // Use blank for Currency.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobPlanningLinesReportWithFCY()
    var
        CurrencyCode: Code[10];
    begin
        // Verify Job Planning Lines Report with Foreign Currency.
        Initialize();
        CurrencyField := CurrencyField::"Foreign Currency";  // Assign in Global variable.
        CurrencyCode := CreateCurrencyWithExchangeRate();
        JobPlanningLinesReportWithCurrency(CurrencyCode, CurrencyCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyJobPlanningLinesReportDates()
    var
        JobPlanningLine: Record "Job Planning Line";
        ContractPrice: Decimal;
        ContractCost: Decimal;
    begin
        // Verify Job Planning Lines report with Planning Date Filter.

        // Setup.
        Initialize();
        CurrencyField := CurrencyField::"Local Currency";  // Assign in Global variable.
        PrepareJobPlanningLinesReportWithCurrency('', JobPlanningLine, ContractPrice, ContractCost);
        JobPlanningLine.Validate("Planning Date", CalcDate('<+1M>', WorkDate()));
        JobPlanningLine.Modify();

        // Exercise.
        RunJobPlanningLinesReportWorkdate(JobPlanningLine);

        // Verify.
        VerifyJobPlanningLinesReportWorkdate(
          JobPlanningLine."Line Amount", JobPlanningLine."Total Cost", ContractPrice, ContractCost);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobPlanningLineReportHeading()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
    begin
        // Verify printing of job no. header info in Job Planning Lines report.

        // Setup.
        Initialize();
        LibraryJob.CreateJob(Job);
        Job.Validate(Description, LibraryUtility.GenerateGUID());
        Job.Modify(true);
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::Billable, JobPlanningLine.Type::Resource, JobTask, JobPlanningLine);

        // Exercise.
        RunJobPlanningLinesReportWorkdate(JobPlanningLine);

        // Verify
        VerifyJobPlanningLinesReportHeading(Job);
    end;

    local procedure JobPlanningLinesReportWithCurrency(CurrencyCode: Code[10]; CurrencyOption: Code[10])
    var
        JobPlanningLine: Record "Job Planning Line";
        ContractPrice: Decimal;
        ContractCost: Decimal;
    begin
        // 1. Setup.
        PrepareJobPlanningLinesReportWithCurrency(CurrencyCode, JobPlanningLine, ContractPrice, ContractCost);

        // 2. Exercise: Save Job Planning Lines Report.
        RunJobPlanningLinesReport(JobPlanningLine);

        // 3. Verify: Verify Job Planning Lines Report.
        VerifyJobPlanningLinesReport(
          JobPlanningLine, CurrencyOption, JobPlanningLine."Line Amount", JobPlanningLine."Total Cost", ContractPrice, ContractCost);
    end;

    local procedure PrepareJobPlanningLinesReportWithCurrency(CurrencyCode: Code[10]; var JobPlanningLine: Record "Job Planning Line"; var ContractPrice: Decimal; var ContractCost: Decimal)
    var
        JobTask: Record "Job Task";
    begin
        // Create Job and Job Task with Currency and create Job Planning Lines for Schedule and Contract.
        CreateJobWithJobTask(JobTask, CurrencyCode);
        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::Billable, JobPlanningLine.Type::Resource, JobTask, JobPlanningLine);
        ContractPrice := JobPlanningLine."Line Amount";
        ContractCost := JobPlanningLine."Total Cost";
        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::Budget, JobPlanningLine.Type::Item, JobTask, JobPlanningLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobAnalysisReportForScheduleWithLCY()
    begin
        // Verify Job Analysis report for Schedule Price, Schedule Cost and Schedule Profit in Local Currency.
        Initialize();
        CurrencyField := CurrencyField::"Local Currency";  // Assign in Global variable.
        JobAnalysisReportForSchedule('', GetLCYCode());  // Use blank for Currency.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobAnalysisReportForScheduleWithFCY()
    var
        CurrencyCode: Code[10];
    begin
        // Verify Job Analysis report for Schedule Price, Schedule Cost and Schedule Profit in Foreign Currency.
        Initialize();
        CurrencyField := CurrencyField::"Foreign Currency";  // Assign in Global variable.
        CurrencyCode := CreateCurrencyWithExchangeRate();
        JobAnalysisReportForSchedule(CurrencyCode, CurrencyCode);
    end;

    local procedure JobAnalysisReportForSchedule(CurrencyCode: Code[10]; CurrencyOption: Code[10])
    var
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        NewAmountField: array[8] of Option;
        NewCurrencyField: array[8] of Option;
    begin
        // 1. Setup: Create Job and Job Task with Currency and create Job Planning Lines for Schedule.
        CreateJobWithJobTask(JobTask, CurrencyCode);
        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::Budget, JobPlanningLine.Type::Item, JobTask, JobPlanningLine);
        SetupAmountArray(NewAmountField, AmountField::"Budget Price", AmountField::"Budget Cost", AmountField::"Budget Profit");
        SetupCurrencyArray(NewCurrencyField);

        // 2. Exercise: Save Job Analysis Report.
        RunJobAnalysisReport(JobPlanningLine."Job No.", NewAmountField, NewCurrencyField, false);

        // 3. Verify: Verify Job Analysis Report.
        VerifyJobAnalysisReport(JobPlanningLine, StrSubstNo(SchedulePriceTxt, CurrencyOption),
          StrSubstNo(ScheduleCostTxt, CurrencyOption), StrSubstNo(ScheduleProfitTxt, CurrencyOption));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobAnalysisReportForContractWithLCY()
    begin
        // Verify Job Analysis report for Contract Price, Contract Cost and Contract Profit in Local Currency.
        Initialize();
        CurrencyField := CurrencyField::"Local Currency";  // Assign in Global variable.
        JobAnalysisReportForContract('', GetLCYCode());  // Use blank for Currency.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobAnalysisReportForContractWithFCY()
    var
        CurrencyCode: Code[10];
    begin
        // Verify Job Analysis report for Contract Price, Contract Cost and Contract Profit in Foreign Currency.
        Initialize();
        CurrencyField := CurrencyField::"Foreign Currency";  // Assign in Global variable.
        CurrencyCode := CreateCurrencyWithExchangeRate();
        JobAnalysisReportForContract(CurrencyCode, CurrencyCode);
    end;

    local procedure JobAnalysisReportForContract(CurrencyCode: Code[10]; CurrencyOption: Code[10])
    var
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        NewAmountField: array[8] of Option;
        NewCurrencyField: array[8] of Option;
    begin
        // 1. Setup: Create Job and Job Task with Currency and create Job Planning Lines for Contract.
        CreateJobWithJobTask(JobTask, CurrencyCode);
        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::Billable, JobPlanningLine.Type::Item, JobTask, JobPlanningLine);
        SetupAmountArray(NewAmountField, AmountField::"Billable Price", AmountField::"Billable Cost", AmountField::"Billable Profit");
        SetupCurrencyArray(NewCurrencyField);

        // 2. Exercise: Save Job Analysis Report.
        RunJobAnalysisReport(JobPlanningLine."Job No.", NewAmountField, NewCurrencyField, false);

        // 3. Verify: Verify Job Analysis Report.
        VerifyJobAnalysisReport(JobPlanningLine, StrSubstNo(ContractPriceTxt, CurrencyOption),
          StrSubstNo(ContractCostTxt, CurrencyOption), StrSubstNo(ContractProfitTxt, CurrencyOption));
    end;

    [Test]
    [HandlerFunctions('JobTransferJobPlanningLinePageHandler,ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure JobAnalysisReportForUsageWithLCY()
    begin
        // Verify Job Analysis report for Usage Price, Usage Cost and Usage Profit in Local Currency.
        Initialize();
        CurrencyField := CurrencyField::"Local Currency";  // Assign in Global variable.
        JobAnalysisReportForUsage('', GetLCYCode());  // Use blank for Currency.
    end;

    [Test]
    [HandlerFunctions('JobTransferJobPlanningLinePageHandler,ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure JobAnalysisReportForUsageWithFCY()
    var
        CurrencyCode: Code[10];
    begin
        // Verify Job Analysis report for Usage Price, Usage Cost and Usage Profit in Foreign Currency.
        Initialize();
        CurrencyField := CurrencyField::"Foreign Currency";  // Assign in Global variable.
        CurrencyCode := CreateCurrencyWithExchangeRate();
        JobAnalysisReportForUsage(CurrencyCode, CurrencyCode);
    end;

    local procedure JobAnalysisReportForUsage(CurrencyCode: Code[10]; CurrencyOption: Code[10])
    var
        JobPlanningLine: Record "Job Planning Line";
        NewAmountField: array[8] of Option;
        NewCurrencyField: array[8] of Option;
    begin
        // 1. Setup: Post Usage for Job with Currency.
        CreateAndPostJobJournalLineForUsage(JobPlanningLine, CurrencyCode);
        SetupAmountArray(NewAmountField, AmountField::"Usage Price", AmountField::"Usage Cost", AmountField::"Usage Profit");
        SetupCurrencyArray(NewCurrencyField);

        // 2. Exercise: Save Job Analysis Report.
        RunJobAnalysisReport(JobPlanningLine."Job No.", NewAmountField, NewCurrencyField, false);

        // 3. Verify: Verify Job Analysis Report.
        VerifyJobAnalysisReport(JobPlanningLine, StrSubstNo(UsagePriceTxt, CurrencyOption),
          StrSubstNo(UsageCostTxt, CurrencyOption), StrSubstNo(UsageProfitTxt, CurrencyOption));
    end;

    [Test]
    [HandlerFunctions('JobTransferToSalesInvoiceRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure JobAnalysisReportForInvoiceWithLCY()
    begin
        // Verify Job Analysis report for Invoiced Price, Invoiced Cost and Invoiced Profit in Local Currency.
        Initialize();
        CurrencyField := CurrencyField::"Local Currency";  // Assign in Global variable.
        JobAnalysisReportForInvoice('', GetLCYCode());  // Use blank for Currency.
    end;

    [Test]
    [HandlerFunctions('JobTransferToSalesInvoiceRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure JobAnalysisReportForInvoiceWithFCY()
    var
        CurrencyCode: Code[10];
    begin
        // Verify Job Analysis report for Invoiced Price, Invoiced Cost and Invoiced Profit in Foreign Currency.
        Initialize();
        CurrencyField := CurrencyField::"Foreign Currency";  // Assign in Global variable.
        CurrencyCode := CreateCurrencyWithExchangeRate();
        JobAnalysisReportForInvoice(CurrencyCode, CurrencyCode);
    end;

    local procedure JobAnalysisReportForInvoice(CurrencyCode: Code[10]; CurrencyOption: Code[10])
    var
        JobPlanningLine: Record "Job Planning Line";
        NewAmountField: array[8] of Option;
        NewCurrencyField: array[8] of Option;
    begin
        // 1. Setup: Post Sales Invoice for Job with Currency.
        CreateAndPostSalesInvoiceForJob(JobPlanningLine, CurrencyCode);
        SetupAmountArray(NewAmountField, AmountField::"Invoiced Price", AmountField::"Invoiced Cost", AmountField::"Invoiced Profit");
        SetupCurrencyArray(NewCurrencyField);

        // 2. Exercise: Save Job Analysis Report.
        RunJobAnalysisReport(JobPlanningLine."Job No.", NewAmountField, NewCurrencyField, false);

        // 3. Verify: Verify Job Analysis Report.
        VerifyJobAnalysisReport(JobPlanningLine, StrSubstNo(InvoicedPriceTxt, CurrencyOption),
          StrSubstNo(InvoicedCostTxt, CurrencyOption), StrSubstNo(InvoicedProfitTxt, CurrencyOption));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobAnalysisReportExcludeZeroLine()
    var
        JobTaskNo: Code[20];
    begin
        // Verify Job Task Line with zero amount does not exist on Job Analysis Report when Exclude Zero Lines boolean is True.
        Initialize();
        JobTaskNo := RunJobAnalysisReportWithMultipleJobTask(true);  // True is to Exclude Zero Lines.

        // 3. Verify: Verify Job Task Line with zero amount does not exist on Job Analysis Report.
        LibraryReportValidation.OpenFile();
        Assert.IsFalse(LibraryReportValidation.CheckIfValueExists(JobTaskNo), ValueFoundErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobAnalysisReportIncludeZeroLine()
    var
        JobTaskNo: Code[20];
    begin
        // Verify Job Task Line with zero amount exists on Job Analysis Report when Exclude Zero Lines boolean is False.
        Initialize();
        JobTaskNo := RunJobAnalysisReportWithMultipleJobTask(false);  // False is to Include Zero Lines.

        // 3. Verify: Verify Job Task Line with zero amount exists on Job Analysis Report.
        LibraryReportValidation.OpenFile();
        Assert.IsTrue(LibraryReportValidation.CheckIfValueExists(JobTaskNo), ValueNotFoundErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure JobActualToBudgetWithLCY()
    begin
        // Verify Job Actual To Budget Report.
        JobActualToBudget('', CurrencyField::"Local Currency");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure JobActualToBudgetWithFCY()
    begin
        // Verify Job Actual To Budget Report With Currency.
        JobActualToBudget(CreateCurrencyWithExchangeRate(), CurrencyField::"Foreign Currency");
    end;

    local procedure JobActualToBudget(CurrencyCode: Code[10]; NewCurrencyField: Option)
    var
        JobJournalLine: Record "Job Journal Line";
        JobLedgerEntry: Record "Job Ledger Entry";
        JobNo: Code[20];
    begin
        // 1. Setup.
        Initialize();
        CurrencyField := NewCurrencyField;  // Assign in Global variable.
        JobNo := CreateAndPostJobJournalLine(JobJournalLine."Line Type"::Billable, CurrencyCode);

        // 2. Exercise: Run Job Actual To Budget Report.
        RunJobActualToBudgetReport(JobNo);

        // 3. Verify: Verify Job Actual To Budget Report.
        FindJobLedgerEntry(JobLedgerEntry, JobNo);
        VerfiyJobActualToBudgetReport(JobLedgerEntry);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure JobSuggestedBillingWithLCY()
    begin
        // Verify Job Suggested Billing Report.

        // 1. Setup.
        Initialize();
        JobSuggestedBilling('', GetLCYCode(), CurrencyField::"Local Currency");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure JobSuggestedBillingWithFCY()
    var
        CurrencyCode: Code[10];
    begin
        // Verify Job Suggested Billing Report with Curreny.

        // 1. Setup.
        Initialize();
        CurrencyCode := CreateCurrencyWithExchangeRate();
        JobSuggestedBilling(CurrencyCode, CurrencyCode, CurrencyField::"Foreign Currency");
    end;

    local procedure JobSuggestedBilling(CurrencyCode: Code[10]; LCYCurrencyCode: Code[10]; NewCurrencyField: Option)
    var
        JobJournalLine: Record "Job Journal Line";
        JobLedgerEntry: Record "Job Ledger Entry";
        JobNo: Code[20];
    begin
        CurrencyField := NewCurrencyField;  // Assign in Global variable.
        JobNo := CreateAndPostJobJournalLine(JobJournalLine."Line Type"::Billable, CurrencyCode);

        // 2. Exercise: Run Job Suggested Billing Report.
        RunJobSuggestedBilling(JobNo);

        // 3. Verify: Verify Job Suggested Billing Report.
        FindJobLedgerEntry(JobLedgerEntry, JobNo);
        VerfiyJobSuggestedBillingReport(JobLedgerEntry);
        Assert.IsTrue(LibraryReportValidation.CheckIfValueExists(LCYCurrencyCode), ValueNotFoundErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobJournalTest()
    var
        JobTask: Record "Job Task";
        JobJournalLine: Record "Job Journal Line";
    begin
        // Verify Job Journal Test Report.

        // 1. Setup.
        Initialize();
        CreateJobWithJobTask(JobTask, '');
        LibraryJob.CreateJobJournalLineForType(JobJournalLine."Line Type"::Billable, JobJournalLine.Type::Item, JobTask, JobJournalLine);

        // 2. Exercise: Run Job Journal Test Report.
        RunJobJournalTestReport(JobJournalLine, false);

        // 3. Verify: Verify Job Journal Test Report preview.
        VerifyJobJournalTestReport(JobJournalLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobJournalTestWithDimension()
    var
        Dimension: Record Dimension;
        DefaultDimension: Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
        Item: Record Item;
        JobTask: Record "Job Task";
        JobJournalLine: Record "Job Journal Line";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        // Verify Job Journal Test Report with Dimension.

        // 1. Setup.
        Initialize();
        CreateJobWithJobTask(JobTask, '');
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDefaultDimensionItem(
          DefaultDimension, LibraryInventory.CreateItem(Item), Dimension.Code, DimensionValue.Code);
        LibraryJob.CreateJobJournalLineForType(JobJournalLine."Line Type"::Billable, JobJournalLine.Type::Item, JobTask, JobJournalLine);
        UpdateJobJournalLine(JobJournalLine, Item."No.", LibraryRandom.RandInt(100), LibraryRandom.RandInt(100));  // Using Random for Quantity and Unit Cost.

        // 2. Exercise: Run Job Journal Test Report.
        RunJobJournalTestReport(JobJournalLine, true);

        // 3. Verify: Verify Job Journal Test Report preview.
        VerifyJobJournalTestReport(JobJournalLine);
        Assert.IsTrue(
          LibraryReportValidation.CheckIfValueExists(StrSubstNo(DimensionTxt, Dimension.Code, DimensionValue.Code)), ValueNotMatchErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure JobTransactionDetailWithLCY()
    begin
        // Verify Job Transaction Detail Report.
        JobTransactionDetail('', CurrencyField::"Local Currency");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure JobTransactionDetailWithFCY()
    begin
        // Verify Job Transaction Detail Report with Curreny.
        JobTransactionDetail(CreateCurrencyWithExchangeRate(), CurrencyField::"Foreign Currency");
    end;

    local procedure JobTransactionDetail(CurrencyCode: Code[10]; NewCurrencyField: Option)
    var
        JobJournalLine: Record "Job Journal Line";
        JobLedgerEntry: Record "Job Ledger Entry";
        Job: Record Job;
        JobNo: Code[20];
    begin
        // 1. Setup.
        Initialize();
        CurrencyField := NewCurrencyField;
        JobNo := CreateAndPostJobJournalLine(JobJournalLine."Line Type"::Billable, CurrencyCode);

        // 2. Exercise: Run Job Journal Test Report.
        Job.Get(JobNo);
        Job.SetRecFilter();
        RunJobTransactionDetail(Job);

        // 3. Verify: Verify Job Transaction Detail Report.
        FindJobLedgerEntry(JobLedgerEntry, JobNo);
        VerfiyJobTransactionDetailReport(JobLedgerEntry);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure JobTransactionDetailsMultipleLineInJobTask()
    var
        JobToReport: Record Job;
        Job: array[2] of Record Job;
        JobTask: array[2, 2] of Record "Job Task";
        JobJournalLine: Record "Job Journal Line";
        JobIndex: Integer;
        JobTaskIndex: Integer;
        LineIndex: Integer;
        LineCost: array[2, 2, 2] of Decimal;
        LinePrice: array[2, 2, 2] of Decimal;
        LineAmount: array[2, 2, 2] of Decimal;
        LineDiscountAmount: array[2, 2, 2] of Decimal;
        CurrencyOption: Option;
    begin
        // [SCENARIO 322646] Calculation Total and SubTotal amounts in report "Job - Transaction Details" for job tasks having multiple job ledger entries
        Initialize();
        CurrencyOption := CurrencyField::"Local Currency";

        // [GIVEN] Two jobs "A" and "B" with two job tasks each: "A_T_1", "A_T_2", "B_T_1", "B_T_2"
        // [GIVEN] Job journal for "A"
        // [GIVEN] Item = "IA1", "Job Task" = "A_T_1", "Total Cost" = 100, "Total Price" = 1000 with lines
        // [GIVEN] Item = "IA2", "Job Task" = "A_T_2", "Total Cost" = 200, "Total Price" = 2000 with lines
        // [GIVEN] Item = "IA3", "Job Task" = "B_T_1", "Total Cost" = 300, "Total Price" = 3000 with lines
        // [GIVEN] Item = "IA4", "Job Task" = "B_T_2", "Total Cost" = 400, "Total Price" = 4000 with lines
        // [GIVEN] Them same job journal for "B"
        for JobIndex := 1 to ArrayLen(Job) do begin
            LibraryJob.CreateJob(Job[JobIndex]);
            for JobTaskIndex := 1 to ArrayLen(JobTask, 2) do begin
                Clear(JobJournalLine);
                LibraryJob.CreateJobTask(Job[JobIndex], JobTask[JobIndex, JobTaskIndex]);
                for LineIndex := 1 to ArrayLen(LineCost, 3) do begin
                    LibraryJob.CreateJobJournalLineForType(
                      JobJournalLine."Line Type"::Billable, JobJournalLine.Type::Item, JobTask[JobIndex, JobTaskIndex], JobJournalLine);
                    JobJournalLine.Validate("Total Cost (LCY)", 1 + 10 * LineIndex + 100 * JobTaskIndex + 1000 * JobIndex);
                    JobJournalLine.Validate("Total Price (LCY)", 2 + 10 * LineIndex + 100 * JobTaskIndex + 1000 * JobIndex);
                    JobJournalLine.Validate("Line Amount (LCY)", 3 + 10 * LineIndex + 100 * JobTaskIndex + 1000 * JobIndex);
                    JobJournalLine.Validate("Line Discount Amount (LCY)", ROUND(JobJournalLine."Line Amount" / 100));
                    JobJournalLine.Modify(true);
                    LineCost[JobIndex, JobTaskIndex, LineIndex] := JobJournalLine."Total Cost";
                    LinePrice[JobIndex, JobTaskIndex, LineIndex] := JobJournalLine."Total Price";
                    LineAmount[JobIndex, JobTaskIndex, LineIndex] := JobJournalLine."Line Amount";
                    LineDiscountAmount[JobIndex, JobTaskIndex, LineIndex] := JobJournalLine."Line Discount Amount";
                end;
                LibraryJob.PostJobJournal(JobJournalLine);
            end;
        end;

        // [WHEN] Run report "Job - Transaction Details" for "A" and "B"
        JobToReport.SetFilter("No.", '%1|%2', Job[1]."No.", Job[2]."No.");
        RunJobTransactionDetail(JobToReport);

        // [THEN] Run report output on two pages (job per page)
        // [THEN] Page "1" contains two groups "G1" and "G2" (two tasks)
        // [THEN] Each group has two lines: 2 items per task
        // [THEN] Total Cost for "G1" = 100 + 200 = 300
        // [THEN] Total Price for "G1" = 1000 + 2000 = 3000
        // [THEN] Total Cost for "G2" = 300 + 400 = 700
        // [THEN] Total Price for "G2" = 3000 + 4000 = 7000
        // [THEN] Job Total Cost = 300 + 700 = 1000
        // [THEN] Job Total Price = 3000 + 7000 = 10000
        // [THEN] the same totals on page 2
        LibraryReportValidation.OpenFile();

        VerifyJobTransactionDetaisReportTotals(Job, JobTask, LineCost, LinePrice, LineAmount, LineDiscountAmount, CurrencyOption);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler,DocumentEntriesReqPageHandler')]
    [Scope('OnPrem')]
    procedure DocumentEntriesForJobAndResource()
    var
        JobTask: Record "Job Task";
        JobJournalLine: Record "Job Journal Line";
        JobLedgerEntry: Record "Job Ledger Entry";
        ResLedgerEntry: Record "Res. Ledger Entry";
        TempDocumentEntry: Record "Document Entry" temporary;
        DocumentEntries: Report "Document Entries";
        JobLedgerEntries: TestPage "Job Ledger Entries";
    begin
        // [SCENARIO] Verify Document Entries Report with Job Ledger, Res. Ledger and Unit Cost.
        Initialize();

        // [GIVEN] Job Task, posted Job Journal Line.
        CreateJobWithJobTask(JobTask, CreateCurrencyWithExchangeRate());
        LibraryJob.CreateJobJournalLineForType(
            JobJournalLine."Line Type"::Billable, JobJournalLine.Type::Resource, JobTask, JobJournalLine);
        LibraryJob.PostJobJournal(JobJournalLine);
        LibraryVariableStorage.Enqueue(false);  // Enqueue for DocumentEntriesReqPageHandler.
        Commit();

        // [WHEN] Open Job Ledger Entries page, as if run Print from Navigate page
        JobLedgerEntries.OpenView();
        JobLedgerEntries.Filter.SetFilter("Job No.", JobTask."Job No.");
        JobLedgerEntry.SetRange("Job No.", JobTask."Job No.");
        JobLedgerEntry.FindFirst();
        CollectDocEntries(JobLedgerEntry, TempDocumentEntry);
        DocumentEntries.TransferDocEntries(TempDocumentEntry);
        DocumentEntries.TransferFilters(JobLedgerEntry."Document No.", Format(JobLedgerEntry."Posting Date"));
        DocumentEntries.Run(); // SaveAxXML in DocumentEntriesReqPageHandler

        // [THEN] Verify Document Entries Report with Job Ledger, Res. Ledger and Unit Cost.
        JobLedgerEntry.SetRange("Job No.", JobTask."Job No.");
        LibraryReportDataset.LoadDataSetFile();
        VerifyDocumentEntries(JobLedgerEntry.TableCaption(), JobLedgerEntry.Count);
        ResLedgerEntry.SetRange("Job No.", JobTask."Job No.");
        VerifyDocumentEntries(ResLedgerEntry.TableCaption(), ResLedgerEntry.Count);
        FindJobLedgerEntry(JobLedgerEntry, JobTask."Job No.");
        LibraryReportDataset.SetRange(PostingDateTxt, Format(JobLedgerEntry."Posting Date"));
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals(UnitCostResLedgEntryTxt, JobLedgerEntry."Unit Cost (LCY)");

        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Job Reports II");
        LibraryVariableStorage.Clear();
        // To clear all Global variables.
        ClearGlobals();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Job Reports II");

        LibraryService.SetupServiceMgtNoSeries();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        DummyJobsSetup."Allow Sched/Contract Lines Def" := false;
        DummyJobsSetup."Apply Usage Link by Default" := false;
        DummyJobsSetup.Modify();
        LibraryJob.SetJobNoSeriesCode();

        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Job Reports II");
    end;

    local procedure RunJobAnalysisReportWithMultipleJobTask(ExcludeZeroLines: Boolean): Code[20]
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        NewAmountField: array[8] of Option;
        NewCurrencyField: array[8] of Option;
    begin
        // 1. Setup: Create Job and Job Planning Lines with Multiple Job Tasks.
        CurrencyField := CurrencyField::"Local Currency";  // Assign in Global variable.
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::Billable, JobPlanningLine.Type::Item, JobTask, JobPlanningLine);
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryJob.CreateJobPlanningLine(
          JobPlanningLine."Line Type"::Billable, JobPlanningLine.Type::"G/L Account", JobTask, JobPlanningLine);
        JobPlanningLine.Validate(Quantity, 0); // Take zero Quantity to make the Amounts zero on the line.
        JobPlanningLine.Modify(true);
        SetupAmountArray(NewAmountField, AmountField::"Billable Price", AmountField::"Billable Cost", AmountField::"Billable Profit");
        SetupCurrencyArray(NewCurrencyField);

        // 2. Exercise: Save Job Analysis Report.
        RunJobAnalysisReport(JobPlanningLine."Job No.", NewAmountField, NewCurrencyField, ExcludeZeroLines);
        exit(JobPlanningLine."Job Task No.");
    end;

    local procedure ClearGlobals()
    begin
        Clear(LibraryReportValidation);
        Clear(CurrencyField);
        Clear(AmountField);
        JobJournalTemplateName := '';
        JobJournalBatchName := '';
    end;

    local procedure CollectDocEntries(JobLedgerEntry: Record "Job Ledger Entry"; var TempDocumentEntry: Record "Document Entry" temporary)
    var
        ResLedgerEntry: Record "Res. Ledger Entry";
    begin
        ResLedgerEntry.Reset();
        ResLedgerEntry.SetCurrentKey("Document No.", "Posting Date");
        ResLedgerEntry.SetFilter("Document No.", JobLedgerEntry."Document No.");
        ResLedgerEntry.SetRange("Posting Date", JobLedgerEntry."Posting Date");
        TempDocumentEntry.InsertIntoDocEntry(DATABASE::"Res. Ledger Entry", ResLedgerEntry.TableCaption(), ResLedgerEntry.Count);
        JobLedgerEntry.Reset();
        JobLedgerEntry.SetCurrentKey("Document No.", "Posting Date");
        JobLedgerEntry.SetFilter("Document No.", JobLedgerEntry."Document No.");
        JobLedgerEntry.SetRange("Posting Date", JobLedgerEntry."Posting Date");
        TempDocumentEntry.InsertIntoDocEntry(DATABASE::"Job Ledger Entry", JobLedgerEntry.TableCaption(), JobLedgerEntry.Count);
    end;

    local procedure CreateAndPostJobJournalLine(LineType: Enum "Job Line Type"; CurrencyCode: Code[10]): Code[20]
    var
        JobJournalLine: Record "Job Journal Line";
        JobTask: Record "Job Task";
    begin
        CreateJobWithJobTask(JobTask, CurrencyCode);
        LibraryJob.CreateJobJournalLineForType(LineType, JobJournalLine.Type::Item, JobTask, JobJournalLine);
        LibraryJob.PostJobJournal(JobJournalLine);
        exit(JobTask."Job No.");
    end;

    local procedure CreateCurrencyWithExchangeRate(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    [Scope('OnPrem')]
    procedure CreateInitialSetupForJob(var Job: Record Job)
    var
        JobWIPMethod: Record "Job WIP Method";
        JobPlanningLine: Record "Job Planning Line";
        JobTask: Record "Job Task";
        JobJournalLine: Record "Job Journal Line";
    begin
        LibraryJob.CreateJobWIPMethod(JobWIPMethod);
        CreateJobWithWIPMethod(Job, JobWIPMethod.Code);
        CreateJobTask(JobTask, Job, JobTask."Job Task Type"::Posting, JobTask."WIP-Total"::" ");
        CreateJobPlanningLine(JobPlanningLine, JobTask);
        LibraryJob.CreateJobJournalLineForType(LibraryJob.UsageLineTypeContract(), LibraryJob.ResourceType(), JobTask, JobJournalLine);
        UpdateJobJournalLine(JobJournalLine, JobPlanningLine."No.", JobPlanningLine.Quantity / 2, JobPlanningLine."Unit Cost");  // Use partial Quantity.
        LibraryJob.PostJobJournal(JobJournalLine);
    end;

    local procedure CreateJobPlanningLine(var JobPlanningLine: Record "Job Planning Line"; JobTask: Record "Job Task")
    begin
        // Use Random values for Quantity and Unit Cost because values are not important.
        LibraryJob.CreateJobPlanningLine(LibraryJob.PlanningLineTypeSchedule(), LibraryJob.ResourceType(), JobTask, JobPlanningLine);
        JobPlanningLine.Validate("No.", CreateResource());
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

    local procedure CreateJobWithWIPMethod(var Job: Record Job; WIPMethod: Code[20])
    begin
        LibraryJob.CreateJob(Job);
        Job.Validate("WIP Method", WIPMethod);
        Job.Modify(true);
    end;

    local procedure CreateResource(): Code[20]
    begin
        exit(LibraryResource.CreateResourceNo());
    end;

    [Scope('OnPrem')]
    procedure CreateJobWithJobTask(var JobTask: Record "Job Task"; CurrencyCode: Code[10])
    var
        Job: Record Job;
    begin
        LibraryJob.CreateJob(Job);
        Job.Validate("Currency Code", CurrencyCode);
        Job.Modify(true);
        LibraryJob.CreateJobTask(Job, JobTask);
    end;

    local procedure CreateAndPostSalesInvoiceForJob(var JobPlanningLine: Record "Job Planning Line"; CurrencyCode: Code[10])
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        SalesHeader: Record "Sales Header";
        LibrarySales: Codeunit "Library - Sales";
        JobCreateInvoice: Codeunit "Job Create-Invoice";
    begin
        // Create Job and Job Task with Currency and create and modify Job Planning Lines for Contract.
        CreateJobWithJobTask(JobTask, CurrencyCode);
        Job.Get(JobTask."Job No.");
        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::Billable, JobPlanningLine.Type::Item, JobTask, JobPlanningLine);
        UpdateJobPlanningLineForQuantity(JobPlanningLine, JobPlanningLine.Quantity, 0);  // Use zero for Qty. to Transfer to Journal.
        Commit();  // Commit is required before running the Job Transfer to Sales Invoice Report.

        // Create Sales Invoice from Job Planning Line.
        JobCreateInvoice.CreateSalesInvoice(JobPlanningLine, false);  // Use False To create Sales Invoice.

        // Post Sales Invoice.
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
        SalesHeader.SetRange("Currency Code", CurrencyCode);
        SalesHeader.SetRange("Sell-to Customer No.", Job."Bill-to Customer No.");
        SalesHeader.FindFirst();
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreateAndPostJobJournalLineForUsage(var JobPlanningLine: Record "Job Planning Line"; CurrencyCode: Code[10])
    var
        JobTask: Record "Job Task";
        JobJournalBatch: Record "Job Journal Batch";
        JobJournalLine: Record "Job Journal Line";
        JobJournalTemplate: Record "Job Journal Template";
        JobPlanningLines: TestPage "Job Planning Lines";
    begin
        // Create Job and Job Task with Currency and create and modify Job Planning Lines for Contract.
        CreateJobWithJobTask(JobTask, CurrencyCode);
        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::Billable, JobPlanningLine.Type::Item, JobTask, JobPlanningLine);
        UpdateJobPlanningLineForQuantity(JobPlanningLine, 0, JobPlanningLine.Quantity);  // Use zero for Qty. to Transfer to Invoice.

        // Create Job Journal Line through Job Planning Line. Here we are using Job Planning Lines page since the code is written on page to create Job Journal Line.
        JobJournalTemplateName := LibraryJob.GetJobJournalTemplate(JobJournalTemplate);  // Assign in Global variable.
        JobJournalBatchName := LibraryJob.CreateJobJournalBatch(JobJournalTemplateName, JobJournalBatch);  // Assign in Global variable.
        JobPlanningLines.OpenEdit();
        JobPlanningLines.FILTER.SetFilter("Job No.", JobPlanningLine."Job No.");
        JobPlanningLines.CreateJobJournalLines.Invoke();

        // Post Job Journal Line for Usage.
        JobJournalLine.SetRange("Job No.", JobPlanningLine."Job No.");
        JobJournalLine.FindFirst();
        LibraryJob.PostJobJournal(JobJournalLine);
    end;

    local procedure CropTo(String: Text[1024]; Length: Integer): Text[250]
    begin
        if StrLen(String) > Length then
            exit(PadStr(String, Length));
        exit(String)
    end;

    local procedure FindJobLedgerEntry(var JobLedgerEntry: Record "Job Ledger Entry"; JobNo: Code[20])
    begin
        JobLedgerEntry.SetRange("Job No.", JobNo);
        JobLedgerEntry.FindFirst();
    end;

    local procedure GetLCYCode(): Code[10]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        exit(GeneralLedgerSetup."LCY Code");
    end;

    local procedure RunJobActualToBudgetReport(No: Code[20])
    var
        Job: Record Job;
        JobActualToBudget: Report "Job Actual To Budget";
    begin
        Job.SetRange("No.", No);
        JobActualToBudget.SetTableView(Job);
        LibraryReportValidation.SetFileName(CreateGuid());
        JobActualToBudget.InitializeRequest(CurrencyField);
        JobActualToBudget.SaveAsExcel(LibraryReportValidation.GetFileName());
        LibraryReportValidation.DownloadFile();
    end;

    local procedure RunJobAnalysisReport(No: Code[20]; NewAmountField: array[8] of Option; NewCurrencyField: array[8] of Option; NewExcludeJobTask: Boolean)
    var
        Job: Record Job;
        JobAnalysis: Report "Job Analysis";
    begin
        Clear(JobAnalysis);
        Job.SetRange("No.", No);
        JobAnalysis.SetTableView(Job);
        JobAnalysis.InitializeRequest(NewAmountField, NewCurrencyField, NewExcludeJobTask);
        LibraryReportValidation.SetFileName(CreateGuid());
        JobAnalysis.SaveAsExcel(LibraryReportValidation.GetFileName());
        LibraryReportValidation.DownloadFile();
    end;

    local procedure RunJobJournalTestReport(JobJournalLine: Record "Job Journal Line"; NewShowDim: Boolean)
    var
        JobJournalBatch: Record "Job Journal Batch";
        JobJournalTest: Report "Job Journal - Test";
    begin
        Clear(JobJournalTest);
        JobJournalBatch.SetRange("Journal Template Name", JobJournalLine."Journal Template Name");
        JobJournalBatch.SetRange(Name, JobJournalLine."Journal Batch Name");
        JobJournalTest.SetTableView(JobJournalBatch);
        LibraryReportValidation.SetFileName(CreateGuid());
        JobJournalTest.InitializeRequest(NewShowDim);
        JobJournalTest.SaveAsExcel(LibraryReportValidation.GetFileName());
        LibraryReportValidation.DownloadFile();
    end;

    local procedure RunJobPerCustomerReport(No: Code[20])
    var
        Customer: Record Customer;
        JobsPerCustomer: Report "Jobs per Customer";
    begin
        Customer.SetRange("No.", No);
        Clear(JobsPerCustomer);
        JobsPerCustomer.SetTableView(Customer);
        LibraryReportValidation.SetFileName(CreateGuid());
        JobsPerCustomer.SaveAsExcel(LibraryReportValidation.GetFileName());
        LibraryReportValidation.DownloadFile();
    end;

    local procedure RunItemPerJobReport(No: Code[20])
    var
        Job: Record Job;
        ItemsPerJob: Report "Items per Job";
    begin
        Job.SetRange("No.", No);
        Clear(ItemsPerJob);
        ItemsPerJob.SetTableView(Job);
        LibraryReportValidation.SetFileName(CreateGuid());
        ItemsPerJob.SaveAsExcel(LibraryReportValidation.GetFileName());
        LibraryReportValidation.DownloadFile();
    end;

    local procedure RunJobPerItemReport()
    var
        JobsPerItem: Report "Jobs per Item";
    begin
        Clear(JobsPerItem);
        LibraryReportValidation.SetFileName(CreateGuid());
        JobsPerItem.SaveAsExcel(LibraryReportValidation.GetFileName());
        LibraryReportValidation.DownloadFile();
    end;

    local procedure RunJobPlanningLinesReport(JobPlanningLine: Record "Job Planning Line")
    var
        JobTask: Record "Job Task";
        JobPlanningLines: Report "Job - Planning Lines";
    begin
        Clear(JobPlanningLines);
        JobTask.SetRange("Job No.", JobPlanningLine."Job No.");
        JobTask.SetRange("Job Task No.", JobPlanningLine."Job Task No.");
        RunJobPlanningLinesReportWithJobTask(JobTask);
    end;

    local procedure RunJobPlanningLinesReportWorkdate(JobPlanningLine: Record "Job Planning Line")
    var
        JobTask: Record "Job Task";
        JobPlanningLines: Report "Job - Planning Lines";
    begin
        Clear(JobPlanningLines);
        JobTask.SetRange("Job No.", JobPlanningLine."Job No.");
        JobTask.SetRange("Job Task No.", JobPlanningLine."Job Task No.");
        JobTask.SetFilter("Planning Date Filter", Format(WorkDate()));
        JobTask.SetFilter("Posting Date Filter", Format(WorkDate()));
        RunJobPlanningLinesReportWithJobTask(JobTask);
    end;

    local procedure RunJobPlanningLinesReportWithJobTask(var JobTask: Record "Job Task")
    var
        JobPlanningLines: Report "Job - Planning Lines";
    begin
        JobPlanningLines.SetTableView(JobTask);
        JobPlanningLines.InitializeRequest(CurrencyField);
        LibraryReportValidation.SetFileName(CreateGuid());
        JobPlanningLines.SaveAsExcel(LibraryReportValidation.GetFileName());
        LibraryReportValidation.DownloadFile();
    end;

    local procedure RunJobRegisterReport()
    var
        JobRegisterReport: Report "Job Register";
    begin
        Clear(JobRegisterReport);
        LibraryReportValidation.SetFileName(CreateGuid());
        JobRegisterReport.SaveAsExcel(LibraryReportValidation.GetFileName());
        LibraryReportValidation.DownloadFile();
    end;

    local procedure RunJobSuggestedBilling(No: Code[20])
    var
        Job: Record Job;
        JobSuggestedBilling: Report "Job Suggested Billing";
    begin
        Clear(JobSuggestedBilling);
        Job.SetRange("No.", No);
        JobSuggestedBilling.SetTableView(Job);
        LibraryReportValidation.SetFileName(CreateGuid());
        JobSuggestedBilling.InitializeRequest(CurrencyField);
        JobSuggestedBilling.SaveAsExcel(LibraryReportValidation.GetFileName());
        LibraryReportValidation.DownloadFile();
    end;

    local procedure RunJobTransactionDetail(var Job: Record Job)
    var
        JobTransactionDetail: Report "Job - Transaction Detail";
    begin
        JobTransactionDetail.SetTableView(Job);
        LibraryReportValidation.SetFileName(CreateGuid());
        JobTransactionDetail.InitializeRequest(CurrencyField);
        JobTransactionDetail.SaveAsExcel(LibraryReportValidation.GetFileName());
        LibraryReportValidation.DownloadFile();
    end;

    local procedure SetupAmountArray(var NewAmountField: array[8] of Option " ","Budget Price","Usage Price","Billable Price","Invoiced Price","Budget Cost","Usage Cost","Billable Cost","Invoiced Cost","Budget Profit","Usage Profit","Billable Profit","Invoiced Profit"; AmountOption: Option; AmountOption2: Option; AmountOption3: Option)
    begin
        NewAmountField[1] := AmountOption;
        NewAmountField[2] := AmountOption2;
        NewAmountField[3] := AmountOption3;
        NewAmountField[4] := AmountField::" ";
        NewAmountField[5] := AmountField::" ";
        NewAmountField[6] := AmountField::" ";
        NewAmountField[7] := AmountField::" ";
        NewAmountField[8] := AmountField::" ";
    end;

    local procedure SetupCurrencyArray(var NewCurrencyField: array[8] of Option)
    var
        Counter: Integer;
    begin
        for Counter := 1 to 8 do
            NewCurrencyField[Counter] := CurrencyField;
    end;

    local procedure UpdateJobJournalLine(var JobJournalLine: Record "Job Journal Line"; No: Code[20]; Quantity: Decimal; UnitCost: Decimal)
    begin
        JobJournalLine.Validate("No.", No);
        JobJournalLine.Validate(Quantity, Quantity);
        JobJournalLine.Validate("Unit Cost", UnitCost);
        JobJournalLine.Modify(true);
    end;

    local procedure UpdateJobPlanningLineForQuantity(var JobPlanningLine: Record "Job Planning Line"; QtyToTransferToInvoice: Decimal; QtyToTransferToJournal: Decimal)
    begin
        JobPlanningLine.Validate("Qty. to Transfer to Invoice", QtyToTransferToInvoice);
        JobPlanningLine.Validate("Qty. to Transfer to Journal", QtyToTransferToJournal);
        JobPlanningLine.Modify(true);
    end;

    local procedure VerifyDocumentEntries(DocEntryTableName: Text[50]; RowValue: Decimal)
    begin
        LibraryReportDataset.SetRange(DocEntryTableNameTxt, DocEntryTableName);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals(DocEntryNoofRecordsTxt, RowValue)
    end;

    local procedure VerfiyJobActualToBudgetReport(JobLedgerEntry: Record "Job Ledger Entry")
    var
        Job: Record Job;
        JobCalculateBatches: Codeunit "Job Calculate Batches";
    begin
        Job.Get(JobLedgerEntry."Job No.");
        LibraryReportValidation.OpenFile();
        Assert.IsTrue(
          LibraryReportValidation.CheckIfDecimalValueExists(JobLedgerEntry."Total Cost"), ValueNotFoundErr);
        Assert.IsTrue(
          LibraryReportValidation.CheckIfDecimalValueExists(JobLedgerEntry."Line Amount"), ValueNotFoundErr);
        Assert.IsTrue(
          LibraryReportValidation.CheckIfValueExists(JobCalculateBatches.GetCurrencyCode(Job, 0, CurrencyField)), ValueNotFoundErr);
        Assert.IsTrue(
          LibraryReportValidation.CheckIfValueExists(JobCalculateBatches.GetCurrencyCode(Job, 3, CurrencyField)), ValueNotFoundErr);
    end;

    local procedure VerifyJobAnalysisReport(JobPlanningLine: Record "Job Planning Line"; Column: Text[250]; Column2: Text[250]; Column3: Text[250])
    begin
        LibraryReportValidation.OpenFile();
        LibraryReportValidation.SetRange(JobPlanningLine.FieldCaption("Job Task No."), Format(JobPlanningLine."Job Task No."));
        LibraryReportValidation.SetColumn(Column);
        Assert.IsTrue(LibraryReportValidation.CheckIfDecimalValueExists(JobPlanningLine."Line Amount"), ValueNotFoundErr);
        LibraryReportValidation.SetColumn(Column2);
        Assert.IsTrue(LibraryReportValidation.CheckIfDecimalValueExists(JobPlanningLine."Total Cost"), ValueNotFoundErr);
        LibraryReportValidation.SetColumn(Column3);
        Assert.IsTrue(
          LibraryReportValidation.CheckIfDecimalValueExists(
            JobPlanningLine."Line Amount" - JobPlanningLine."Total Cost"), ValueNotFoundErr);
    end;

    local procedure VerifyJobJournalTestReport(JobJournalLine: Record "Job Journal Line")
    begin
        LibraryReportValidation.OpenFile();
        LibraryReportValidation.SetRange(JobJournalLine.FieldCaption("Posting Date"), Format(JobJournalLine."Posting Date"));
        VerifyJobReports(JobJournalLine.FieldCaption(Quantity), JobJournalLine.Quantity);
        VerifyJobReports(JobJournalLine.FieldCaption("Unit Cost (LCY)"), JobJournalLine."Unit Cost (LCY)");
        VerifyJobReports(JobJournalLine.FieldCaption("Total Cost (LCY)"), JobJournalLine."Total Cost (LCY)");
        VerifyJobReportsNearlyEqual(JobJournalLine.FieldCaption("Unit Price"), JobJournalLine."Unit Price", 0.01);
        VerifyJobReports(JobJournalLine.FieldCaption("Line Amount"), JobJournalLine."Line Amount");
    end;

    local procedure VerifyJobReports(ColumnCaption: Text[250]; LineAmount: Decimal)
    begin
        VerifyJobReportsNearlyEqual(ColumnCaption, LineAmount, 0);
    end;

    local procedure VerifyJobReportsNearlyEqual(ColumnCaption: Text[250]; LineAmount: Decimal; Delta: Decimal)
    var
        Amount: Decimal;
    begin
        LibraryReportValidation.SetColumn(ColumnCaption);
        Evaluate(Amount, LibraryReportValidation.GetValue());
        Assert.AreNearlyEqual(LineAmount, Amount, Delta, AmountErr);
    end;

    local procedure VerifyJobPerCustomerReport(No: Code[20])
    var
        JobLedgerEntry: Record "Job Ledger Entry";
        LibraryUtility: Codeunit "Library - Utility";
        UsageAmount: Decimal;
    begin
        FindJobLedgerEntry(JobLedgerEntry, No);
        LibraryReportValidation.OpenFile();
        LibraryReportValidation.SetRange(JobLedgerEntry.FieldCaption("Job No."), No);
        UsageAmount := JobLedgerEntry.Quantity * JobLedgerEntry."Unit Price";

        VerifyJobReports(ScheduleLineAmountTxt, JobLedgerEntry."Line Amount" + UsageAmount);

        VerifyJobReports(CropTo(ConvertStr(UsageLineAmountTxt, ' ', LibraryUtility.LineBreak()), 250), UsageAmount);
        VerifyJobReports(CropTo(ConvertStr(ContractLineAmountTxt, ' ', LibraryUtility.LineBreak()), 250), JobLedgerEntry."Line Amount");
    end;

    local procedure VerifyItemPerJobReport(No: Code[20])
    var
        JobLedgerEntry: Record "Job Ledger Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        FindJobLedgerEntry(JobLedgerEntry, No);
        LibraryReportValidation.OpenFile();
        LibraryReportValidation.SetRange(ItemLedgerEntry.FieldCaption("Item No."), JobLedgerEntry."No.");
        VerifyJobReports(JobLedgerEntry.FieldCaption(Quantity), JobLedgerEntry.Quantity);
        VerifyJobReports(JobLedgerEntry.FieldCaption("Total Cost"), JobLedgerEntry."Total Cost");
        VerifyJobReports(JobLedgerEntry.FieldCaption("Line Amount"), JobLedgerEntry."Line Amount");
    end;

    local procedure VerifyJobPerItemReport(No: Code[20])
    var
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        FindJobLedgerEntry(JobLedgerEntry, No);
        LibraryReportValidation.OpenFile();
        LibraryReportValidation.SetRange(JobLedgerEntry.FieldCaption("Job No."), No);
        VerifyJobReports(JobLedgerEntry.FieldCaption(Quantity), JobLedgerEntry.Quantity);
        VerifyJobReports(JobLedgerEntry.FieldCaption("Total Cost"), JobLedgerEntry."Total Cost");
        VerifyJobReports(JobLedgerEntry.FieldCaption("Line Amount"), JobLedgerEntry."Line Amount");
    end;

    local procedure VerifyJobPlanningLinesReport(JobPlanningLine: Record "Job Planning Line"; CurrencyCode: Code[10]; SchedulePrice: Decimal; ScheduleCost: Decimal; ContractPrice: Decimal; ContractCost: Decimal)
    var
        QuantityInteger: Integer;
    begin
        LibraryReportValidation.OpenFile();
        Assert.IsTrue(LibraryReportValidation.CheckIfDecimalValueExists(SchedulePrice), ValueNotFoundErr);
        Assert.IsTrue(LibraryReportValidation.CheckIfDecimalValueExists(ScheduleCost), ValueNotFoundErr);
        Assert.IsTrue(LibraryReportValidation.CheckIfDecimalValueExists(ContractPrice), ValueNotFoundErr);
        Assert.IsTrue(LibraryReportValidation.CheckIfDecimalValueExists(ContractCost), ValueNotFoundErr);

        JobPlanningLine.SetRange("Job No.", JobPlanningLine."Job No.");
        JobPlanningLine.SetRange("Job Task No.", JobPlanningLine."Job Task No.");
        JobPlanningLine.FindSet();
        repeat
            LibraryReportValidation.SetRange(JobPlanningLine.FieldCaption("No."), Format(JobPlanningLine."No."));
            LibraryReportValidation.SetColumn(Format(JobPlanningLine.FieldCaption(Quantity)));
            Evaluate(QuantityInteger, LibraryReportValidation.GetValue(), 1);
            JobPlanningLine.TestField(Quantity, QuantityInteger);

            LibraryReportValidation.SetColumn(JobPlanningLine.FieldCaption("Unit of Measure Code"));
            JobPlanningLine.TestField("Unit of Measure Code", LibraryReportValidation.GetValue());

            LibraryReportValidation.SetColumn(StrSubstNo(TotalCostTxt, CurrencyCode));
            Assert.IsTrue(LibraryReportValidation.CheckIfDecimalValueExists(JobPlanningLine."Total Cost"), ValueNotFoundErr);

            LibraryReportValidation.SetColumn(StrSubstNo(LineDiscountAmountTxt, CurrencyCode));
            Assert.IsTrue(LibraryReportValidation.CheckIfDecimalValueExists(JobPlanningLine."Line Discount Amount"), ValueNotFoundErr);

            LibraryReportValidation.SetColumn(StrSubstNo(LineAmountTxt, CurrencyCode));
            Assert.IsTrue(LibraryReportValidation.CheckIfDecimalValueExists(JobPlanningLine."Line Amount"), ValueNotFoundErr);
        until JobPlanningLine.Next() = 0;
    end;

    local procedure VerifyJobPlanningLinesReportWorkdate(SchedulePrice: Decimal; ScheduleCost: Decimal; ContractPrice: Decimal; ContractCost: Decimal)
    begin
        LibraryReportValidation.OpenFile();
        Assert.IsFalse(LibraryReportValidation.CheckIfDecimalValueExists(SchedulePrice), ValueFoundErr);
        Assert.IsFalse(LibraryReportValidation.CheckIfDecimalValueExists(ScheduleCost), ValueFoundErr);
        Assert.IsTrue(LibraryReportValidation.CheckIfDecimalValueExists(ContractPrice), ValueNotFoundErr);
        Assert.IsTrue(LibraryReportValidation.CheckIfDecimalValueExists(ContractCost), ValueNotFoundErr);
    end;

    local procedure VerifyJobPlanningLinesReportHeading(Job: Record Job)
    begin
        LibraryReportValidation.OpenFile();
        Assert.IsTrue(
              LibraryReportValidation.CheckIfValueExists(StrSubstNo('%1 %2 %3 %4', Job.TableCaption(), Job.FieldCaption("No."), Job."No.", Job.Description)),
              ValueNotFoundErr);
    end;

    local procedure VerifyJobRegisterReport(No: Code[20])
    var
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        FindJobLedgerEntry(JobLedgerEntry, No);
        LibraryReportValidation.OpenFile();
        LibraryReportValidation.SetRange(JobLedgerEntry.FieldCaption("Job No."), No);
        VerifyJobReports(JobLedgerEntry.FieldCaption(Quantity), JobLedgerEntry.Quantity);
        VerifyJobReports(JobLedgerEntry.FieldCaption("Total Cost (LCY)"), JobLedgerEntry."Total Cost (LCY)");
        VerifyJobReports(JobLedgerEntry.FieldCaption("Line Amount (LCY)"), JobLedgerEntry."Line Amount (LCY)");
    end;

    local procedure VerfiyJobSuggestedBillingReport(JobLedgerEntry: Record "Job Ledger Entry")
    begin
        LibraryReportValidation.OpenFile();
        LibraryReportValidation.SetRange(JobLedgerEntry.FieldCaption("Job Task No."), JobLedgerEntry."Job Task No.");
        VerifyJobReports(TotalContractTxt, JobLedgerEntry."Total Cost");
    end;

    local procedure VerfiyJobTransactionDetailReport(JobLedgerEntry: Record "Job Ledger Entry")
    var
        Job: Record Job;
        JobCalculateBatches: Codeunit "Job Calculate Batches";
    begin
        Job.Get(JobLedgerEntry."Job No.");
        LibraryReportValidation.OpenFile();
        LibraryReportValidation.SetRange(JobLedgerEntry.FieldCaption("Posting Date"), Format(JobLedgerEntry."Posting Date"));
        VerifyJobReports(JobLedgerEntry.FieldCaption(Quantity), JobLedgerEntry.Quantity);
        VerifyJobReports(JobLedgerEntry.FieldCaption("Entry No."), JobLedgerEntry."Entry No.");
        VerifyJobReports(JobCalculateBatches.GetCurrencyCode(Job, 1, CurrencyField), JobLedgerEntry."Total Price");
        VerifyJobReports(JobCalculateBatches.GetCurrencyCode(Job, 0, CurrencyField), JobLedgerEntry."Total Cost");
        VerifyJobReports(JobCalculateBatches.GetCurrencyCode(Job, 3, CurrencyField), JobLedgerEntry."Line Amount");
    end;

    local procedure VerifyJobTransactionDetaisReportTotals(Job: array[2] of Record "Job"; JobTask: array[2, 2] of Record "Job Task"; LineCost: array[2, 2, 2] of Decimal; LinePrice: array[2, 2, 2] of Decimal; LineAmount: array[2, 2, 2] of Decimal; LineDiscountAmount: array[2, 2, 2] of Decimal; CurrencyOption: Option);
    var
        JobToReport: Record "Job";
        JobCalculateBatches: Codeunit "Job Calculate Batches";
        TotalCostColumnNo: Integer;
        TotalPriceColumnNo: Integer;
        TotalLineAmountColumnNo: Integer;
        TotalLineDiscountAmountColumnNo: Integer;
        JobIndex: Integer;
        JobTaskIndex: Integer;
        LineIndex: Integer;
        RowNo: Integer;
        ColumnNo: Integer;
        JobTotalCost: Decimal;
        JobTotalPrice: Decimal;
        JobTotalLineAmount: Decimal;
        JobTotalLineDiscountAmount: Decimal;
        JobTaskTotalCost: Decimal;
        JobTaskTotalPrice: Decimal;
        JobTaskTotalLineAmount: Decimal;
        JobTaskTotalLineDiscountAmount: Decimal;
    begin
        TotalCostColumnNo :=
          LibraryReportValidation.FindColumnNoFromColumnCaption(
            JobCalculateBatches.GetCurrencyCode(JobToReport, 0, CurrencyOption));
        TotalPriceColumnNo :=
          LibraryReportValidation.FindColumnNoFromColumnCaption(
            JobCalculateBatches.GetCurrencyCode(JobToReport, 1, CurrencyOption));
        TotalLineAmountColumnNo :=
          LibraryReportValidation.FindColumnNoFromColumnCaption(
            JobCalculateBatches.GetCurrencyCode(JobToReport, 3, CurrencyOption));
        TotalLineDiscountAmountColumnNo :=
          LibraryReportValidation.FindColumnNoFromColumnCaption(
            JobCalculateBatches.GetCurrencyCode(JobToReport, 2, CurrencyOption));

        for JobIndex := 1 to ArrayLen(Job) do begin
            JobTotalCost := 0;
            JobTotalPrice := 0;
            JobTotalLineAmount := 0;
            JobTotalLineDiscountAmount := 0;
            for JobTaskIndex := 1 to ArrayLen(JobTask, 2) do begin
                JobTaskTotalCost := 0;
                JobTaskTotalPrice := 0;
                JobTaskTotalLineAmount := 0;
                JobTaskTotalLineDiscountAmount := 0;
                LibraryReportValidation.FindRowNoColumnNoByValueOnWorksheet(
                  JobTask[JobIndex, JobTaskIndex]."Job Task No.", JobIndex, RowNo, ColumnNo);
                for LineIndex := 1 to ArrayLen(LineCost, 3) do begin
                    JobTaskTotalCost += LineCost[JobIndex, JobTaskIndex, LineIndex];
                    JobTaskTotalPrice += LinePrice[JobIndex, JobTaskIndex, LineIndex];
                    JobTaskTotalLineAmount += LineAmount[JobIndex, JobTaskIndex, LineIndex];
                    JobTaskTotalLineDiscountAmount += LineDiscountAmount[JobIndex, JobTaskIndex, LineIndex];
                end;
                LibraryReportValidation.VerifyCellValue(
                  RowNo + 3, TotalCostColumnNo, LibraryReportValidation.FormatDecimalValue(JobTaskTotalCost));
                LibraryReportValidation.VerifyCellValue(
                  RowNo + 3, TotalPriceColumnNo, LibraryReportValidation.FormatDecimalValue(JobTaskTotalPrice));
                LibraryReportValidation.VerifyCellValue(
                  RowNo + 3, TotalLineAmountColumnNo, LibraryReportValidation.FormatDecimalValue(JobTaskTotalLineAmount));
                LibraryReportValidation.VerifyCellValue(
                  RowNo + 3, TotalLineDiscountAmountColumnNo, LibraryReportValidation.FormatDecimalValue(JobTaskTotalLineDiscountAmount));
                JobTotalCost += JobTaskTotalCost;
                JobTotalPrice += JobTaskTotalPrice;
                JobTotalLineAmount += JobTaskTotalLineAmount;
                JobTotalLineDiscountAmount += JobTaskTotalLineDiscountAmount;
            end;

            LibraryReportValidation.FindRowNoColumnNoByValueOnWorksheet('Total Usage', JobIndex, RowNo, ColumnNo);
            LibraryReportValidation.VerifyCellValue(RowNo, TotalCostColumnNo, LibraryReportValidation.FormatDecimalValue(JobTotalCost));
            LibraryReportValidation.VerifyCellValue(RowNo, TotalPriceColumnNo, LibraryReportValidation.FormatDecimalValue(JobTotalPrice));
            LibraryReportValidation.VerifyCellValue(
              RowNo, TotalLineAmountColumnNo, LibraryReportValidation.FormatDecimalValue(JobTotalLineAmount));
            LibraryReportValidation.VerifyCellValue(
              RowNo, TotalLineDiscountAmountColumnNo, LibraryReportValidation.FormatDecimalValue(JobTotalLineDiscountAmount));
        end;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure DocumentEntriesReqPageHandler(var DocumentEntries: TestRequestPage "Document Entries")
    begin
        DocumentEntries.PrintAmountsInLCY.SetValue(LibraryVariableStorage.DequeueBoolean());  // Boolean Show Amount in LCY
        DocumentEntries.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure JobTransferJobPlanningLinePageHandler(var JobTransferJobPlanningLine: TestPage "Job Transfer Job Planning Line")
    begin
        JobTransferJobPlanningLine.JobJournalTemplateName.SetValue(JobJournalTemplateName);
        JobTransferJobPlanningLine.JobJournalBatchName.SetValue(JobJournalBatchName);
        JobTransferJobPlanningLine.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure JobTransferToSalesInvoiceRequestPageHandler(var JobTransferToSalesInvoice: TestRequestPage "Job Transfer to Sales Invoice")
    begin
        JobTransferToSalesInvoice.OK().Invoke();
    end;
}
