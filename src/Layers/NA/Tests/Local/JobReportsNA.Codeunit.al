codeunit 142065 "Job Reports NA"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Job] [Reports]
    end;

    var
        JobsSetup: Record "Jobs Setup";
        NoSeries: Record "No. Series";
        Assert: Codeunit Assert;
        JobCreateInvoice: Codeunit "Job Create-Invoice";
        LibraryJob: Codeunit "Library - Job";
        LibraryERM: Codeunit "Library - ERM";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryResource: Codeunit "Library - Resource";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        AmountError: Label 'Amount must be Equal.';
        BillToCustomerNoCap: Label 'Project: Bill-to Customer No.: %1';
        PostingDateFilterCap: Label 'Project: Posting Date Filter: %1';
        JobNoAndPostingDateFilterCap: Label 'Project: No.: %1, Posting Date Filter: %2';
        DateFilter: Label 'Date Filter';
        ResDescriptionCap: Label 'ResDescription';
        ResourceNoCap: Label 'Resource__No__';
        ResourceBaseUnitofMeasure: Label 'Resource__Base_Unit_of_Measure_';
        ResLedgerEntryResourceNoCap: Label 'Res__Ledger_Entry__Resource_No__';
        ResourceTABLECAPTIONResFilterCap: Label 'Resource_TABLECAPTION__________ResFilter';
        ResourceCapacityCap: Label 'Resource_Capacity';
        ResourceUsageQtyCap: Label 'Resource__Usage__Qty___';
        CapacityUsageQtyCap: Label 'Capacity____Usage__Qty___';
        JobNoCap: Label 'Job_No_';
        JobTABLECAPTIONJobFiltercap: Label 'Job_TABLECAPTION__________JobFilter';
        TotalCost1Cap: Label 'TotalCost_1_';
        TotalPrice1Cap: Label 'TotalPrice_1_';
        JobLedgerEntryJobNo: Label 'Job_Ledger_Entry__Job_No__';
        JobLedgerEntryTotalCostLCYCap: Label 'Job_Ledger_Entry__Total_Cost__LCY__';
        JobLedgerEntryTotalPriceLCYCap: Label 'Job_Ledger_Entry__Total_Price__LCY__';
        JobLedgerEntryTypeCap: Label 'Job_Ledger_Entry_Type';
        JobDescriptionCap: Label 'JobDescription';
        PrintJobDescriptionsCap: Label 'PrintJobDescriptions';
        JobLedgerEntryNoCap: Label 'Job_Ledger_Entry__No__';
        RowMustNotExistErr: Label 'Row Must Not Exist.';
        LibraryRandom: Codeunit "Library - Random";
        ContractPriceCap: Label 'ContractPrice';
        JobNoCap1: Label 'Job__No__';
        JobBilltoCustomerNoCap: Label 'Job__Bill_to_Customer_No__';
        BudgetedAmountsArePerTheContractTxt: Label 'Budgeted Amounts are per the Contract';
        BudgetedAmountsArePerTheScheduleTxt: Label 'Budgeted Amounts are per the Budget';
        JobPlanningLineTypeCap: Label 'Job_Planning_Line_Type';
        BudgetOptionTextCap: Label 'BudgetOptionText';
        JobPlanningLineTotalCostLCYCap: Label 'Job_Planning_Line__Total_Cost__LCY__';
        JobPlanningLineTotalPriceLCYCap: Label 'Job_Planning_Line__Total_Price__LCY__';
        LibraryApplicationArea: Codeunit "Library - Application Area";
        isInitialized: Boolean;
        XJOBTxt: Label 'JOB';
        XJ10Txt: Label 'J10';
        XJ99990Txt: Label 'J99990';
        XJOBWIPTxt: Label 'JOB-WIP', Comment = 'Cashflow is a name of Cash Flow Forecast No. Series.';
        XDefaultJobWIPNoTxt: Label 'WIP0000001', Comment = 'CF stands for Cash Flow.';
        XDefaultJobWIPEndNoTxt: Label 'WIP9999999';
        XJobWIPDescriptionTxt: Label 'Job-WIP';

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler,ResourceRegisterReqPageHandler')]
    [Scope('OnPrem')]
    procedure ResRegisterReportWithBlankFilters()
    var
        ResourceNo: Code[20];
        ResourceNo2: Code[20];
    begin
        // Run and verify Resource Register Report with blank filters.
        // Setup.
        Initialize();
        ResourceNo2 := CreateAndPostMultipleResourceLine(ResourceNo);

        // Exercise.
        RunResourceRegisterReport('', '', '', false);  // Using blank values for register no, source code, source no and Print Resource Desc fields.

        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        VerifyValuesOnReport(ResLedgerEntryResourceNoCap, ResourceNo, ResourceNo2);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler,ResourceRegisterReqPageHandler')]
    [Scope('OnPrem')]
    procedure ResRegisterReportWithInvalidResRegisterNo()
    var
        ResourceRegister: Record "Resource Register";
    begin
        // Run and verify Resource Register Report with Invalid Resource Register No.
        // Setup: Create Resources and post journal.
        Initialize();
        CreateResourceSetup(CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'Y>', WorkDate()));  // Using random value for Posting Date.
        ResourceRegister.FindLast();

        // Exercise.
        RunResourceRegisterReport(Format(ResourceRegister."No." + 1), '', '', false);

        // Verify: Verify that blank report is generated.
        LibraryReportDataset.LoadDataSetFile();
        Assert.IsFalse(LibraryReportDataset.GetNextRow(), RowMustNotExistErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler,ResourceRegisterReqPageHandler')]
    [Scope('OnPrem')]
    procedure ResRegisterReportWithPrintResourceDescTrue()
    var
        ResourceNo: Code[20];
    begin
        // Run and verify Resource Register Report with filter Print Resource Des as True.
        // Setup: Create Resources and post journal.
        Initialize();
        ResourceNo := CreateResourceSetup(CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'Y>', WorkDate()));  // Using random value for Posting Date.

        // Exercise.
        RunResourceRegisterReport('', '', '', true);  // Using blank values for register no, source code, source no and Print Resource Desc fields.

        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(ResDescriptionCap, ResourceNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler,ResourceUsageReqPageHandler')]
    [Scope('OnPrem')]
    procedure ResourceUsageReportWithBlankFilters()
    var
        ResourceNo: Code[20];
        ResourceNo2: Code[20];
    begin
        // Run and verify Resource Usage Report with blank filters.
        // Setup.
        Initialize();
        ResourceNo2 := CreateAndPostMultipleResourceLine(ResourceNo);

        // Exercise.
        RunResourceUsageReport('', '', 0D);  // Using blank values for register no, source code, source no and Print Resource Desc fields.

        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        VerifyValuesOnReport(ResourceNoCap, ResourceNo, ResourceNo2);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler,ResourceUsageReqPageHandler')]
    [Scope('OnPrem')]
    procedure ResourceUsageReportWithResourceNoFilter()
    var
        Resource: Record Resource;
    begin
        // Run and veify Resource Usage Report with Resource No. filter.
        // Setup: Create Resources and post journal.
        Initialize();
        Resource.Get(CreateResourceSetup(WorkDate()));

        // Exercise.
        RunResourceUsageReport(Resource."No.", '', 0D);

        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        VerifyResourceUsage(Resource);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler,ResourceUsageReqPageHandler')]
    [Scope('OnPrem')]
    procedure ResourceUsageReportWithBaseUnitOfMeasureFilter()
    var
        Resource: Record Resource;
    begin
        // Run and verify Resource Usage Report with Base Unit Of Measure filter.
        // Setup: Create Resources and post journal.
        Initialize();
        Resource.Get(CreateResourceSetup(WorkDate()));

        // Exercise.
        RunResourceUsageReport('', Resource."Base Unit of Measure", 0D);

        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(ResourceBaseUnitofMeasure, Resource."Base Unit of Measure");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler,ResourceUsageReqPageHandler')]
    [Scope('OnPrem')]
    procedure ResourceUsageReportWithDateFilter()
    var
        Resource: Record Resource;
        CaptionValue: Text[50];
        PostingDate: Date;
    begin
        // Run and verify Resource Usage Report with Date Filter.
        // Setup: Create Resources and post journal.
        Initialize();
        PostingDate := LibraryRandom.RandDate(5);
        CreateResourceSetup(PostingDate); // Using random values Posting Date.

        // Exercise.
        RunResourceUsageReport('', '', PostingDate); // Using blank values for resource no and base unit of measure fields.

        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        CaptionValue := Resource.TableCaption + ': ' + DateFilter + ': ' + Format(PostingDate); // Using random value for Posting Date.
        LibraryReportDataset.AssertElementWithValueExists(ResourceTABLECAPTIONResFilterCap, CaptionValue);
    end;

    [Test]
    [HandlerFunctions('JobCostTransactionDetailReqPageHandler,ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure RunJobCostTransacDtlReportWithNoFilters()
    var
        Job: Record Job;
        Job2: Record Job;
        JobJournalLine: Record "Job Journal Line";
    begin
        // Run and verify Job Cost Transaction Detail report with blank filters.
        // Setup: Create two Jobs and post Job Journal for both.
        Initialize();
        CreateJobAndPostJobJournal(Job, JobJournalLine."Line Type"::" ", WorkDate());
        CreateJobAndPostJobJournal(Job2, JobJournalLine."Line Type"::" ", WorkDate());

        // Exercise.
        RunReportJobCostTransacDtl('', '', 0D);  // Using blank values for Job no, customer no, and Posting date fields.

        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        VerifyValuesOnReport(JobNoCap, Job."No.", Job2."No.");
    end;

    [Test]
    [HandlerFunctions('JobCostTransactionDetailReqPageHandler,ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure RunJobCostTransacDtlReportWithJobNo()
    var
        Job: Record Job;
        JobJournalLine: Record "Job Journal Line";
    begin
        // Run and verify Job Cost Transaction Detail report with Job No filter.
        // Setup.
        Initialize();
        CreateJobAndPostJobJournal(Job, JobJournalLine."Line Type"::" ", WorkDate());

        // Exercise & Verify.
        RunAndVerifyReportJobCostTransacDtl(JobNoCap, Job."No.", Job."No.", '', Job."No.", JobJournalLine.Type::Resource, 0D);
    end;

    [Test]
    [HandlerFunctions('JobCostTransactionDetailReqPageHandler,ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure RunJobCostTransacDtlReportWithBillToCustomerNo()
    var
        Job: Record Job;
        JobJournalLine: Record "Job Journal Line";
    begin
        // Run and verify Job Cost Transaction Detail report with Bill To Customer No filter.
        // Setup.
        Initialize();
        CreateJobAndPostJobJournal(Job, JobJournalLine."Line Type"::" ", WorkDate());

        // Exercise & Verify.
        RunAndVerifyReportJobCostTransacDtl(
          JobTABLECAPTIONJobFiltercap,
          StrSubstNo(BillToCustomerNoCap, Job."Bill-to Customer No."),
          '', Job."Bill-to Customer No.", Job."No.", JobJournalLine.Type::Resource, 0D);
    end;

    [Test]
    [HandlerFunctions('JobCostTransactionDetailReqPageHandler,ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure RunJobCostTransacDtlReportWithPostingDateFilter()
    var
        Job: Record Job;
        JobJournalLine: Record "Job Journal Line";
        PostingDate: Date;
    begin
        // Run and verify Job Cost Transaction Detail report with Posting Date filter.
        // Setup.
        Initialize();
        PostingDate := CalcDate('<1Y>', WorkDate());
        CreateJobAndPostJobJournal(Job, JobJournalLine."Line Type"::" ", PostingDate);

        // Exercise & Verify.
        RunAndVerifyReportJobCostTransacDtl(
          JobTABLECAPTIONJobFiltercap,
          StrSubstNo(PostingDateFilterCap, PostingDate), '', '', Job."No.", JobJournalLine.Type::Resource, PostingDate);
    end;

    [Test]
    [HandlerFunctions('JobCostTransactionDetailReqPageHandler,ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure RunJobCostTransacDtlRptWithPostingDateAndJobNoFilter()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobJournalLine: Record "Job Journal Line";
    begin
        // Run and verify Job Cost Transaction Detail report with Posting Date and Job No filters.
        // Setup: Create a Job and post two Journal Lines for it at different posting dates.
        Initialize();
        CreateJobAndPostJobJournal(Job, JobJournalLine."Line Type"::" ", CalcDate('<1Y>', WorkDate()));
        FindJobTask(JobTask, Job."No.");
        CreateAndPostJobJournalLine(JobTask, CreateItem(), JobJournalLine.Type::Item, JobJournalLine."Line Type"::" ", WorkDate());

        // Exercise & Verify.
        RunAndVerifyReportJobCostTransacDtl(JobTABLECAPTIONJobFiltercap,
          StrSubstNo(JobNoAndPostingDateFilterCap, Job."No.", WorkDate()), Job."No.", '', Job."No.", JobJournalLine.Type::Item, WorkDate());
    end;

    [Test]
    [HandlerFunctions('JobRegisterReqPageHandler,ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure RunJobRegisterReportWithPrintJobDescFilterAsFalse()
    begin
        // Run and verify Job Register report with Print Job Description filter as FALSE.
        RunJobRegisterReportWithPrintJobDescFilter(false, false);  // Using false for PrintJobDescriptionValue
    end;

    [Test]
    [HandlerFunctions('JobRegisterReqPageHandler,ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure RunJobRegisterReportWithPrintJobDescFilterAsTrue()
    begin
        // Run and verify Job Register report with Print Job Description filter as TRUE.
        RunJobRegisterReportWithPrintJobDescFilter(true, true);  // Using true for PrintJobDescriptionValue
    end;

    local procedure RunJobRegisterReportWithPrintJobDescFilter(PrintJobDescriptionValue: Boolean; PrintJobDescriptionFilter: Boolean)
    var
        Job: Record Job;
        JobLedgerEntry: Record "Job Ledger Entry";
        JobJournalLine: Record "Job Journal Line";
    begin
        // Setup: Create a Job and post Job Journal for it.
        Initialize();
        CreateJobAndPostJobJournal(Job, JobJournalLine."Line Type"::" ", WorkDate());
        FindJobLedgerEntry(JobLedgerEntry, Job."No.", JobJournalLine.Type::Resource);

        // Exercise: Run report Job Register with Print Job Description filter.
        RunJobRegisterReport('', '', PrintJobDescriptionFilter, "Job Journal Line Type"::Resource);

        // Verify: Verify Job Register report.
        LibraryReportDataset.LoadDataSetFile();
        VerifyJobRegisterReport(
          JobDescriptionCap, JobLedgerEntry.Description, PrintJobDescriptionsCap, PrintJobDescriptionValue, JobLedgerEntry."Job No.");
    end;

    [Test]
    [HandlerFunctions('JobRegisterReqPageHandler,ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure RunJobRegisterReportWithJobNoFilter()
    var
        Job: Record Job;
        Job2: Record Job;
        JobRegister: Record "Job Register";
        JobLedgerEntry: Record "Job Ledger Entry";
        JobJournalLine: Record "Job Journal Line";
    begin
        // Run and verify Job Register report with Job No. filter.
        // Setup.
        Initialize();
        CreateJobAndPostJobJournal(Job, JobJournalLine."Line Type"::" ", WorkDate());
        CreateJobAndPostJobJournal(Job2, JobJournalLine."Line Type"::" ", WorkDate());
        JobRegister.FindLast();
        FindJobLedgerEntry(JobLedgerEntry, Job."No.", JobJournalLine.Type::Resource);

        // Exercise.
        // Using '%1..%2' Apply filter for the created Job Registers.
        RunJobRegisterReport(StrSubstNo('%1..%2', JobRegister."No." - 1, JobRegister."No."), JobLedgerEntry."Job No.", false, "Job Journal Line Type"::Resource);

        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        VerifyJobRegisterReport(
          JobLedgerEntryTotalCostLCYCap,
          JobLedgerEntry."Total Cost (LCY)",
          JobLedgerEntryTotalPriceLCYCap, JobLedgerEntry."Total Price (LCY)", JobLedgerEntry."Job No.");
    end;

    [Test]
    [HandlerFunctions('JobRegisterReqPageHandler,ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure RunJobRegisterReportWithTypeFilter()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobLedgerEntry: Record "Job Ledger Entry";
        JobJournalLine: Record "Job Journal Line";
    begin
        // Run and verify Job Register report with Type filter.
        // Setup: Create a Job and post Job Journals for it with different types.
        Initialize();
        CreateJobAndPostJobJournal(Job, JobJournalLine."Line Type"::" ", WorkDate());
        FindJobTask(JobTask, Job."No.");
        CreateAndPostJobJournalLine(JobTask, CreateItem(), JobJournalLine.Type::Item, JobJournalLine."Line Type"::" ", WorkDate());
        FindJobLedgerEntry(JobLedgerEntry, Job."No.", JobJournalLine.Type::Item);

        // Exercise.
        RunJobRegisterReport('', Job."No.", false, JobJournalLine.Type::Item);

        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        VerifyJobRegisterReport(
          JobLedgerEntryTypeCap, Format(JobLedgerEntry.Type), JobLedgerEntryNoCap, JobLedgerEntry."No.", JobLedgerEntry."Job No.");
    end;

    [Test]
    [HandlerFunctions('JobTransferToSalesInvoiceRequestPageHandler,MessageHandler,JobCostSuggestedBillingReqPageHandler')]
    [Scope('OnPrem')]
    procedure RunJobCostSuggestedBillingReportWithFilter()
    var
        Job: Record Job;
        TotalPrice: Decimal;
    begin
        // Run and verify Job Cost Suggested Billing report with Bill to Customer No. filter.
        // Setup: Create Job Planning Line for a new Job, Create Sales Invoice from Job Planning Line and find the created Sales Invoice.
        Initialize();
        TotalPrice := CreateJobAndSalesInvoiceFromJobPlanningLine(Job);

        // Exercise: Post Sales Invoice created from Job Planning Line.
        RunJobCostSuggestedBillingReport(Job."Bill-to Customer No.");

        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        VerifyContractPriceOnJobReports(Job, ContractPriceCap, TotalPrice);
    end;

    [Test]
    [HandlerFunctions('JobTransferToSalesInvoiceRequestPageHandler,MessageHandler,CompletedJobReqPageHandler,ConfirmHandlerMultipleResponses')]
    [Scope('OnPrem')]
    procedure RunCompletedJobReportWithFilter()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        SalesHeader: Record "Sales Header";
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
    begin
        // Run and verify Completed Job report with Bill to Customer No. filter.
        // Setup: Create Job Planning Line for a new Job, Create Sales Invoice from Job Planning Line and find the created Sales Invoice.
        Initialize();
        CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        CreateSalesInvoiceFromJobPlaningLine(JobTask, JobPlanningLine);
        FindSalesHeader(SalesHeader, JobTask."Job No.");
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        CreateGeneralJournalLine(
          GenJournalLine, SalesHeader."Sell-to Customer No.", DocumentNo, -LibraryRandom.RandDec(1000, 2));  // Using random value for Posting Date.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(false);
        UpdateJobWithStatus(Job);

        // Exercise: Post Sales Invoice created from Job Planning Line.
        RunCompletedJobReport(Job."Bill-to Customer No.");

        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        VerifyContractPriceOnJobReports(Job, ContractPriceCap, JobPlanningLine."Total Price (LCY)");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure PurchInvoiceForJobWithUseTax()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
    begin
        // Verify Job Ledger Entry for posted purchase invoice with Use Tax.
        // Setup: Create Purch Invoice for Job with Sales Tax and a Tax Detail.
        Initialize();
        CreateAndPostPurchaseDocument(PurchaseLine, '');
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        // Exercise.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify.
        VerifyJobLedgerEntry(DocumentNo, PurchaseLine."Job No.", PurchaseLine."Direct Unit Cost");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure PurchInvoiceForJobWithUseTaxAndCurrency()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
    begin
        // Verify Job Ledger Entry for posted purchase invoice with Use Tax and Currency.
        // Setup: Create Purch Invoice for Job with Sales Tax and a Tax Detail.
        Initialize();
        CreateAndPostPurchaseDocument(PurchaseLine, CreateCurrency());
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        // Exercise.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify.
        VerifyJobLedgerEntry(DocumentNo,
          PurchaseLine."Job No.", LibraryERM.ConvertCurrency(PurchaseLine."Direct Unit Cost", PurchaseLine."Currency Code", '', WorkDate()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceOrderWithZeroInvoiceDiscount()
    begin
        // Verify Resource Ledger Entry after Posting Service Order with Invoice Discount % as 0 on Customer.
        PostServiceOrderWithInvoiceDiscount(0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceOrderWithMoreThanZeroInvoiceDiscount()
    begin
        // Verify Resource Ledger Entry after Posting Service Order with Invoice Discount % as 100 on Customer.
        PostServiceOrderWithInvoiceDiscount(100);
    end;

    [Test]
    [HandlerFunctions('JobCostBudgetReqPageHandler,ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure RunJobCostBudgetReportWithBudgetAmountsPerContract()
    var
        JobJournalLine: Record "Job Journal Line";
    begin
        // Run and verify the generated Job Cost Budget report with Budget Amounts Per filter as Billable.
        RunJobCostBudgetReportWithBudgetAmountsPerFilter(BudgetedAmountsArePerTheContractTxt, JobJournalLine."Line Type"::Billable, 2);  // 2 is used for option Billable of field Budget Amounts Per.
    end;

    [Test]
    [HandlerFunctions('JobCostBudgetReqPageHandler,ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure RunJobCostBudgetReportWithBudgetAmountsPerSchedule()
    var
        JobJournalLine: Record "Job Journal Line";
    begin
        // Run and verify the generated Job Cost Budget report with Budget Amounts Per filter as Schedule.
        RunJobCostBudgetReportWithBudgetAmountsPerFilter(BudgetedAmountsArePerTheScheduleTxt, JobJournalLine."Line Type"::Budget, 1);  // 1 is used for option Schedule of field Budget Amounts Per.
    end;

    [Test]
    [HandlerFunctions('SalesInvoiceReqPageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceReportAfterTaxJurisdictionUpdate()
    var
        SalesLine: Record "Sales Line";
        TaxDetail: Record "Tax Detail";
        DocumentNo: Code[20];
    begin
        // Run and verify Sales Invoice report with different Tax Jurisdiction.

        // Setup: Create and Post Sales Invoice and Create Tax Area Line.
        Initialize();
        DocumentNo := CreateAndPostSalesInvoice(SalesLine);
        LibraryVariableStorage.Enqueue(DocumentNo);
        CreateTaxAreaLine(TaxDetail, CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()));  // Using random value for Effective Date.
        Commit();  // Commit required.

        // Exercise.
        REPORT.Run(REPORT::"Sales Invoice NA");

        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('No_SalesInvHeader', DocumentNo);
        LibraryReportDataset.AssertElementWithValueExists('TempSalesInvoiceLineNo', SalesLine."No.");
        LibraryReportDataset.AssertElementWithValueExists('TempSalesInvoiceLineQty', SalesLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('PurchaseInvoiceReqPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceReportAfterTaxJurisdictionUpdate()
    var
        PurchaseLine: Record "Purchase Line";
        TaxDetail: Record "Tax Detail";
        DocumentNo: Code[20];
    begin
        // Run and verify Purchase Invoice report with different Tax Jurisdiction.

        // Setup: Create and Post Purchase Invoice and Create Tax Area Line.
        Initialize();
        DocumentNo := CreateAndPostPurchaseInvoice(PurchaseLine, PurchaseLine."Document Type"::Invoice);
        LibraryVariableStorage.Enqueue(DocumentNo);
        CreateTaxAreaLine(TaxDetail, CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'Y>', WorkDate()));  // Using random value for Effective Date.
        Commit();  // Commit required.

        // Exercise.
        REPORT.Run(REPORT::"Purchase Invoice NA");

        // Veirfy.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('No_PurchInvHeader', DocumentNo);
        LibraryReportDataset.AssertElementWithValueExists('ItemNumberToPrint', PurchaseLine."No.");
        LibraryReportDataset.AssertElementWithValueExists('Quantity_PurchInvLine', PurchaseLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('ServiceShipmentReqPageHandler')]
    [Scope('OnPrem')]
    procedure ServiceShipmentReportAfterTaxJurisdictionUpdate()
    var
        ServiceLine: Record "Service Line";
        TaxDetail: Record "Tax Detail";
        DocumentNo: Code[20];
    begin
        // Run and verify Service Shipment report with different Tax Jurisdiction.

        // Setup: Create and Post Service Shipment and Create Tax Area Line.
        Initialize();
        CreateAndPostServiceInvoice(ServiceLine);
        DocumentNo := FindServiceShipmentHeaderWithCustomer(ServiceLine."Customer No.");
        CreateTaxAreaLine(TaxDetail, CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'Y>', WorkDate()));  // Using random value for Effective Date.
        Commit();  // Commit required.

        // Exercise.
        REPORT.Run(REPORT::"Service - Shipment");

        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('No_ServiceShptHrd', DocumentNo);
        LibraryReportDataset.AssertElementWithValueExists('No_ServiceShptItemLn', ServiceLine."No.");
        LibraryReportDataset.AssertElementWithValueExists('QtyInvoiced_ServShptLine', ServiceLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('ConfirmationHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderReceiptWhenPurchaseLineWithJobPlanningLineItemWithoutJobPlanningLineNo()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        JobPlanningLine: Record "Job Planning Line";
    begin
        // [SCENARIO 454686] Purchase lines are not being tracked properly for Job Usage link, to the proper Job Line Type on the Job
        Initialize();

        // [GIVEN] Job with Planning Line - "Usage Link" and Item "X"
        CreateJobWithPlanningUsageLinkAndSpecificItem(JobPlanningLine, CreateItem());

        // [GIVEN] Purchase Order with Item "X", wiht Job Planning line and without "Job Planning Line No." on Purchase Line
        CreatePurchaseDocument(PurchLine, PurchHeader."Document Type"::Order, JobPlanningLine."No.");
        PurchLine.Validate("Job No.", JobPlanningLine."Job No.");
        PurchLine.Validate("Job Task No.", JobPlanningLine."Job Task No.");
        PurchLine.Validate("Job Line Type", JobPlanningLine."Line Type"::Budget);
        PurchLine.Modify(true);

        // [WHEN] Post Purchase Receipt
        PurchHeader.Get(PurchLine."Document Type", PurchLine."Document No.");
        asserterror LibraryPurchase.PostPurchaseDocument(PurchHeader, true, false);

        // [THEN] Posting Purchase Receipt is interrupted with Expected Empty Error
        Assert.ExpectedError('');
    end;

    [Test]
    [HandlerFunctions('ConfirmationHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderReceiptWhenPurchaseLineWithoutJobPlanningLineItemWithoutJobLineType()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        JobPlanningLine: Record "Job Planning Line";
    begin
        // [SCENARIO 454686] Purchase lines are not being tracked properly for Job Usage link, to the proper Job Line Type on the Job
        Initialize();

        // [GIVEN] Job with Planning Line - "Usage Link" and Item "X"
        CreateJobWithPlanningUsageLinkAndSpecificItem(JobPlanningLine, CreateItem());

        // [GIVEN] Purchase Order with Item "X", Job ("Job Planning Line No." is not defined to make strict link to Job)
        CreatePurchaseDocument(PurchLine, PurchHeader."Document Type"::Order, JobPlanningLine."No.");
        PurchLine.Validate("Job No.", JobPlanningLine."Job No.");
        PurchLine.Validate("Job Task No.", JobPlanningLine."Job Task No.");
        PurchLine.Modify(true);

        // [WHEN] Post Purchase Order
        PurchHeader.Get(PurchLine."Document Type", PurchLine."Document No.");
        asserterror LibraryPurchase.PostPurchaseDocument(PurchHeader, true, false);

        // [THEN] Posting Purchase Receipt is interrupted with Expected Empty Error
        Assert.ExpectedError('');
    end;

    local procedure Initialize()
    begin
        if isInitialized then
            exit;

        LibraryVariableStorage.Clear();
        LibraryERMCountryData.CreateVATData();
        LibraryApplicationArea.EnableEssentialSetup();

        SetJobNoSeries(JobsSetup, NoSeries);

        isInitialized := true;
        Commit();
    end;

    [Scope('OnPrem')]
    local procedure SetJobNoSeries(var JobsSetup: Record "Jobs Setup"; var NoSeries: Record "No. Series")
    begin
        JobsSetup.Get();
        if JobsSetup."Job Nos." = '' then
            if NoSeries.Get(XJOBTxt) then
                JobsSetup."Job Nos." := XJOBTxt
            else
                InsertSeries(JobsSetup."Job Nos.", XJOBTxt, XJOBTxt, XJ10Txt, XJ99990Txt, '', '', 10, true);

        if JobsSetup."Job WIP Nos." = '' then
            if NoSeries.Get(XJOBWIPTxt) then
                JobsSetup."Job WIP Nos." := XJOBWIPTxt
            else
                InsertSeries(JobsSetup."Job WIP Nos.", XJOBWIPTxt, XJobWIPDescriptionTxt, XDefaultJobWIPNoTxt, XDefaultJobWIPEndNoTxt, '', '', 1, true);

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
        NoSeries."Manual Nos." := ManualNos;
        NoSeries."Default Nos." := true;
        NoSeries.Insert();

        NoSeriesLine.Init();
        NoSeriesLine."Line No." := 10000;
        NoSeriesLine."Series Code" := NoSeries.Code;
        NoSeriesLine.Validate("Starting No.", StartingNo);
        NoSeriesLine.Validate("Ending No.", EndingNo);
        NoSeriesLine.Validate("Last No. Used", LastNumberUsed);
        if WarningNo <> '' then
            NoSeriesLine.Validate("Warning No.", WarningNo);
        NoSeriesLine.Validate("Increment-by No.", IncrementByNo);
        NoSeriesLine.Insert(true);

        SeriesCode := Code;
    end;

    local procedure CreateAndPostPurchaseInvoice(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"): Code[20]
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        TaxDetail: Record "Tax Detail";
        Vendor: Record Vendor;
        TaxAreaCode: Code[20];
    begin
        LibraryPurchase.CreateVendor(Vendor);
        TaxAreaCode := CreateTaxAreaLine(TaxDetail, WorkDate());
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, Vendor."No.");
        PurchaseHeader.Validate("Tax Area Code", TaxAreaCode);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));  // Take Random Quantity.
        PurchaseLine.Validate("Tax Group Code", TaxDetail."Tax Group Code");
        PurchaseLine.Modify(true);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateAndPostSalesInvoice(var SalesLine: Record "Sales Line"): Code[20]
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        TaxDetail: Record "Tax Detail";
        TaxAreaCode: Code[20];
    begin
        LibrarySales.CreateCustomer(Customer);
        TaxAreaCode := CreateTaxAreaLine(TaxDetail, WorkDate());
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesLine."Document Type"::Invoice, Customer."No.");
        SalesHeader.Validate("Tax Area Code", TaxAreaCode);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));  // Taken Random Quantity.
        SalesLine.Validate("Tax Group Code", TaxDetail."Tax Group Code");
        SalesLine.Modify(true);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateAndPostServiceInvoice(var ServiceLine: Record "Service Line")
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
        TaxDetail: Record "Tax Detail";
        TaxAreaCode: Code[20];
    begin
        TaxAreaCode := CreateTaxAreaLine(TaxDetail, WorkDate());
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, Customer."No.");
        ServiceHeader.Validate("Tax Area Code", TaxAreaCode);
        ServiceHeader.Validate("Tax Liable", true);
        ServiceHeader.Modify(true);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Resource, CreateResource());
        ServiceLine.Validate("Tax Group Code", TaxDetail."Tax Group Code");
        ServiceLine.Validate(Quantity, LibraryRandom.RandDec(10, 2));  // Take Random Quantity.
        ServiceLine.Modify(true);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
    end;

    local procedure CreateCurrency(): Code[20]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateCustomerInvoiceDiscount(CustomerNo: Code[20]; DiscountPct: Decimal; ServiceCharge: Decimal)
    var
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
    begin
        LibraryERM.CreateInvDiscForCustomer(CustInvoiceDisc, CustomerNo, '', 0);  // Take Blank for Currency Code And 0 for Minimum Amount.
        CustInvoiceDisc.Validate("Discount %", DiscountPct);
        CustInvoiceDisc.Validate("Service Charge", ServiceCharge);
        CustInvoiceDisc.Modify(true);
    end;

    local procedure CreateGLAccount(var GLAccount: Record "G/L Account"): Code[20]
    var
        TaxDetail: Record "Tax Detail";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
    begin
        CreateTaxAreaLine(TaxDetail, WorkDate());
        GenProductPostingGroup.SetFilter("Def. VAT Prod. Posting Group", '<>''''');
        LibraryERM.FindGenProductPostingGroup(GenProductPostingGroup);
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Prod. Posting Group", GenProductPostingGroup.Code);
        GLAccount.Validate("Tax Group Code", TaxDetail."Tax Group Code");
        GLAccount.Modify(true);
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AccountNo: Code[20]; AppliedToDocNo: Code[20]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name",
          GenJournalBatch.Name, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer, AccountNo, 0);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", AppliedToDocNo);
        GenJournalLine.Validate(Amount, Amount);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateJob(var Job: Record Job)
    var
        Customer: Record Customer;
        JobWIPMethod: Record "Job WIP Method";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryJob.CreateJob(Job, Customer."No.");
        LibraryJob.CreateJobWIPMethod(JobWIPMethod);
        Job.Validate("WIP Method", JobWIPMethod.Code);
        Job.Modify(true);
    end;

    local procedure CreateJobAndPostJobJournal(var Job: Record Job; LineType: Enum "Job Line Type"; PostingDate: Date)
    var
        JobTask: Record "Job Task";
        Customer: Record Customer;
        JobJournalLine: Record "Job Journal Line";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryJob.CreateJob(Job, Customer."No.");
        LibraryJob.CreateJobTask(Job, JobTask);
        CreateAndPostJobJournalLine(JobTask, CreateResource(), JobJournalLine.Type::Resource, LineType, PostingDate);
    end;

    local procedure CreateAndPostJobJournalLine(JobTask: Record "Job Task"; No: Code[20]; Type: Enum "Job Journal Line Type"; LineType: Enum "Job Line Type"; PostingDate: Date)
    var
        JobJournalLine: Record "Job Journal Line";
    begin
        LibraryJob.CreateJobJournalLine(LineType, JobTask, JobJournalLine);
        JobJournalLine.Validate("Posting Date", PostingDate);
        JobJournalLine.Validate(Type, Type);
        JobJournalLine.Validate("No.", No);
        JobJournalLine.Validate(Quantity, LibraryRandom.RandInt(10));  // Use random value for Quantity.
        JobJournalLine.Modify(true);
        LibraryJob.PostJobJournal(JobJournalLine);
    end;

    local procedure CreateJobAndSalesInvoiceFromJobPlanningLine(var Job: Record Job): Decimal
    var
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        SalesHeader: Record "Sales Header";
    begin
        CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        CreateSalesInvoiceFromJobPlaningLine(JobTask, JobPlanningLine);
        FindSalesHeader(SalesHeader, JobTask."Job No.");
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        exit(JobPlanningLine."Total Price (LCY)");
    end;

    local procedure CreateAndPostMultipleResourceLine(var ResourceNo: Code[20]) ResourceNo2: Code[20]
    var
        ResJournalBatch: Record "Res. Journal Batch";
        ResJournalLine: Record "Res. Journal Line";
    begin
        ResourceNo := CreateResource();
        ResourceNo2 := CreateResource();
        CreateResourceJournalBatch(ResJournalBatch);
        CreateResourceJournalLine(ResJournalLine, ResJournalBatch, ResourceNo, WorkDate());
        CreateResourceJournalLine(ResJournalLine, ResJournalBatch, ResourceNo2, WorkDate());
        LibraryResource.PostResourceJournalLine(ResJournalLine);
    end;

    local procedure CreateAndPostPurchaseDocument(var PurchaseLine: Record "Purchase Line"; CurrencyCode: Code[20])
    var
        GLAccount: Record "G/L Account";
        Job: Record Job;
        JobTask: Record "Job Task";
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
    begin
        CreateVendor(Vendor, true);
        CreateGLAccount(GLAccount);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        PurchaseHeader.Validate("Tax Liable", true);
        PurchaseHeader.Validate("Currency Code", CurrencyCode);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
          GLAccount."No.", LibraryRandom.RandInt(10));  // Using RANDOM value for Quantity.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));  // Take Random Unit Cost.
        PurchaseLine.Validate("Tax Liable", PurchaseHeader."Tax Liable");
        PurchaseLine.Validate("Tax Area Code", PurchaseHeader."Tax Area Code");
        PurchaseLine.Validate("Use Tax", true);
        LibraryJob.CreateJob(Job);
        PurchaseLine.Validate("Job No.", Job."No.");
        LibraryJob.CreateJobTask(Job, JobTask);
        PurchaseLine.Validate("Job Task No.", JobTask."Job Task No.");
        PurchaseLine.Modify(true);
    end;

    local procedure CreateAndUpdateServiceLine(ServiceHeader: Record "Service Header"; Quantity: Decimal; ServiceItemLineNo: Integer; LineDiscount: Decimal)
    var
        ServiceLine: Record "Service Line";
    begin
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Resource, CreateResource());
        ServiceLine.Validate("Service Item Line No.", ServiceItemLineNo);
        ServiceLine.Validate(Quantity, Quantity);
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));  // Using RANDOM value for Unit Price.
        ServiceLine.Validate("Line Discount %", LineDiscount);
        ServiceLine.Modify(true);
    end;

    local procedure CreateTaxAreaLine(var TaxDetail: Record "Tax Detail"; EffectiveDate: Date): Code[20]
    var
        TaxArea: Record "Tax Area";
        TaxAreaLine: Record "Tax Area Line";
    begin
        CreateSalesTaxDetail(TaxDetail, EffectiveDate);
        LibraryERM.CreateTaxArea(TaxArea);
        LibraryERM.CreateTaxAreaLine(TaxAreaLine, TaxArea.Code, TaxDetail."Tax Jurisdiction Code");
        exit(TaxArea.Code);
    end;

    local procedure CreateResource(): Code[20]
    var
        Resource: Record Resource;
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryResource.CreateResource(Resource, VATPostingSetup."VAT Bus. Posting Group");
        Resource.Validate(Capacity, LibraryRandom.RandDec(10, 2));  // Use random value for Capacity.
        Resource.Modify(true);
        exit(Resource."No.");
    end;

    local procedure CreateResourceSetup(PostingDate: Date) ResourceNo: Code[20]
    var
        ResJournalBatch: Record "Res. Journal Batch";
        ResJournalLine: Record "Res. Journal Line";
    begin
        ResourceNo := CreateResource();
        CreateResourceJournalBatch(ResJournalBatch);
        CreateResourceJournalLine(ResJournalLine, ResJournalBatch, ResourceNo, PostingDate);
        LibraryResource.PostResourceJournalLine(ResJournalLine);
    end;

    local procedure CreateResourceJournalBatch(var ResJournalBatch: Record "Res. Journal Batch")
    var
        ResJournalTemplate: Record "Res. Journal Template";
    begin
        ResJournalTemplate.SetRange(Recurring, false);
        LibraryResource.FindResJournalTemplate(ResJournalTemplate);
        LibraryResource.CreateResourceJournalBatch(ResJournalBatch, ResJournalTemplate.Name);
    end;

    local procedure CreateResourceJournalLine(var ResJournalLine: Record "Res. Journal Line"; ResJournalBatch: Record "Res. Journal Batch"; ResourceNo: Code[20]; PostingDate: Date)
    begin
        LibraryResource.CreateResJournalLine(ResJournalLine, ResJournalBatch."Journal Template Name", ResJournalBatch.Name);
        ResJournalLine.Validate("Posting Date", PostingDate);
        ResJournalLine.Validate("Entry Type", ResJournalLine."Entry Type"::Usage);
        ResJournalLine.Validate("Resource No.", ResourceNo);
        ResJournalLine.Validate("Document No.", ResourceNo);
        ResJournalLine.Validate("Work Type Code", '');
        ResJournalLine.Validate(Quantity, LibraryRandom.RandDec(10, 2));  // Use random value for Quantity.
        ResJournalLine.Modify(true);
    end;

    local procedure CreateSalesInvoiceFromJobPlaningLine(JobTask: Record "Job Task"; var JobPlanningLine: Record "Job Planning Line")
    begin
        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::Billable, JobPlanningLine.Type::Resource, JobTask, JobPlanningLine);
        Commit();  // Using Commit to prevent Test Failure.
        JobCreateInvoice.CreateSalesInvoice(JobPlanningLine, false);
    end;

    local procedure CreateSalesTaxDetail(var TaxDetail: Record "Tax Detail"; EffectiveDate: Date)
    var
        TaxGroup: Record "Tax Group";
    begin
        LibraryERM.CreateTaxGroup(TaxGroup);
        LibraryERM.CreateTaxDetail(
          TaxDetail, CreateSalesTaxJurisdiction(), TaxGroup.Code, TaxDetail."Tax Type"::"Sales and Use Tax", EffectiveDate);
        TaxDetail.Validate("Tax Below Maximum", LibraryRandom.RandInt(10));  // Using RANDOM value for Tax Below Maximum.
        TaxDetail.Validate("Expense/Capitalize", true);
        TaxDetail.Modify(true);
    end;

    local procedure CreateSalesTaxJurisdiction(): Code[20]
    var
        TaxJurisdiction: Record "Tax Jurisdiction";
    begin
        LibraryERM.CreateTaxJurisdiction(TaxJurisdiction);
        exit(TaxJurisdiction.Code);
    end;

    local procedure CreateServiceItem(var ServiceItem: Record "Service Item"; CustomerNo: Code[20]; ItemNo: Code[20])
    begin
        LibraryService.CreateServiceItem(ServiceItem, CustomerNo);
        ServiceItem.Validate("Item No.", ItemNo);
        ServiceItem.Modify(true);
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Price", LibraryRandom.RandDec(10, 2));  // Use random value for Unit Price.
        Item.Validate("Unit Cost", LibraryRandom.RandDec(10, 2));  // Use random value for Unit Cost.
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateVendor(var Vendor: Record Vendor; TaxLiable: Boolean)
    var
        TaxDetail: Record "Tax Detail";
        TaxAreaCode: Code[20];
    begin
        TaxAreaCode := CreateTaxAreaLine(TaxDetail, WorkDate());
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Tax Area Code", TaxAreaCode);
        Vendor.Validate("Tax Liable", TaxLiable);
        Vendor.Modify(true);
    end;

    local procedure FindJobLedgerEntry(var JobLedgerEntry: Record "Job Ledger Entry"; JobNo: Code[20]; Type: Enum "Job Journal Line Type")
    begin
        JobLedgerEntry.SetRange("Job No.", JobNo);
        JobLedgerEntry.SetRange(Type, Type);
        JobLedgerEntry.FindLast();  // To fetch last ledger entry created for the job.
    end;

    local procedure FindJobTask(var JobTask: Record "Job Task"; JobNo: Code[20])
    begin
        JobTask.SetRange("Job No.", JobNo);
        JobTask.FindFirst();
    end;

    local procedure FindSalesHeader(var SalesHeader: Record "Sales Header"; JobNo: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        FindSalesLine(SalesLine, JobNo);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; JobNo: Code[20])
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Invoice);
        SalesLine.SetRange(Type, SalesLine.Type::Resource);
        SalesLine.SetRange("Job No.", JobNo);
        SalesLine.FindFirst();
    end;

    local procedure FindServiceShipmentHeader(OrderNo: Code[20]): Code[20]
    var
        ServiceShipmentHeader: Record "Service Shipment Header";
    begin
        ServiceShipmentHeader.SetRange("Order No.", OrderNo);
        ServiceShipmentHeader.FindFirst();
        exit(ServiceShipmentHeader."No.");
    end;

    local procedure FindServiceShipmentHeaderWithCustomer(CustomerNo: Code[20]): Code[20]
    var
        ServiceShipmentHeader: Record "Service Shipment Header";
    begin
        ServiceShipmentHeader.SetRange("Customer No.", CustomerNo);
        ServiceShipmentHeader.FindFirst();
        LibraryVariableStorage.Enqueue(ServiceShipmentHeader."No.");
        exit(ServiceShipmentHeader."No.");
    end;

    local procedure FindServiceLine(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header")
    begin
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.FindSet();
    end;

    local procedure ModifySalesReceivablesSetup()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Calc. Inv. Discount", true);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure PostServiceOrderWithInvoiceDiscount(DiscountPct: Decimal)
    var
        Customer: Record Customer;
        Item: Record Item;
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        TotalPrice: Decimal;
    begin
        // Setup: Create Customer, Customer Invoice Discount, Update Sales & Receivable Setup with Calc. Inv. Discount as True, Service
        // Item, Service Header with Document Type as Order, Service Item Line and Service Line with Type Resource.
        Initialize();
        ModifySalesReceivablesSetup();
        LibrarySales.CreateCustomer(Customer);
        CreateCustomerInvoiceDiscount(Customer."No.", DiscountPct, 0);  // Using Zero for Service Charge.
        LibraryInventory.CreateItem(Item);
        CreateServiceItem(ServiceItem, Customer."No.", Item."No.");
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        CreateAndUpdateServiceLine(ServiceHeader, 1, ServiceItemLine."Line No.", 0);  // Use zero for Line Discount and 1 for Quantity.
        FindServiceLine(ServiceLine, ServiceHeader);
        TotalPrice := ServiceLine."Unit Price" - (ServiceLine."Unit Price" * DiscountPct / 100);

        // Exercise.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // Verify.
        VerifyResourceLedgerEntry(ServiceLine, TotalPrice);
    end;

    local procedure RunAndVerifyReportJobCostTransacDtl(RowCaption: Text[50]; RowValue: Text[100]; JobNoFilter: Code[20]; BillToCustomerNoFilter: Code[20]; JobNo: Code[20]; Type: Enum "Job Journal Line Type"; PostingDateFilter: Date)
    begin
        RunReportJobCostTransacDtl(JobNoFilter, BillToCustomerNoFilter, PostingDateFilter);
        LibraryReportDataset.LoadDataSetFile();
        VerifyJobCostTransactionDetail(RowCaption, RowValue, JobNo, Type);
    end;

    local procedure RunJobCostSuggestedBillingReport(BillToCustomerNo: Code[20])
    begin
        LibraryVariableStorage.Enqueue(BillToCustomerNo);  // Enqueue value for JobCostSuggestedBillingReqPageHandler.
        Commit();
        REPORT.Run(REPORT::"Job Cost Suggested Billing", true, false);
    end;

    local procedure RunReportJobCostTransacDtl(JobNo: Code[20]; CustomerNo: Code[20]; PostingDate: Date)
    begin
        LibraryVariableStorage.Enqueue(JobNo);  // Enqueue value for JobCostTransactionDetailReqPageHandler.
        LibraryVariableStorage.Enqueue(CustomerNo);  // Enqueue value for JobCostTransactionDetailReqPageHandler.
        LibraryVariableStorage.Enqueue(PostingDate);  // Enqueue value for JobCostTransactionDetailReqPageHandler.
        Commit();
        REPORT.Run(REPORT::"Job Cost Transaction Detail", true, false);
    end;

    local procedure RunReportJobCostBudget(JobNo: Code[20]; BudgetAmountsPer: Integer)
    var
        JobCostBudget: Report "Job Cost Budget";
    begin
        Clear(JobCostBudget);
        LibraryVariableStorage.Enqueue(JobNo);  // Enqueue value for JobCostBudgetReqPageHandler.
        LibraryVariableStorage.Enqueue(BudgetAmountsPer);  // Enqueue value for JobCostBudgetReqPageHandler.
        Commit();
        REPORT.Run(REPORT::"Job Cost Budget", true, false);
    end;

    local procedure RunResourceUsageReport(ResourceNo: Code[20]; BaseUnitofMeasure: Code[10]; DateFilter: Date)
    begin
        LibraryVariableStorage.Enqueue(ResourceNo);  // Enqueue value for ResourceUsageReqPageHandler.
        LibraryVariableStorage.Enqueue(BaseUnitofMeasure);  // Enqueue value for ResourceUsageReqPageHandler.
        LibraryVariableStorage.Enqueue(DateFilter);  // Enqueue value for ResourceUsageReqPageHandler.
        Commit();
        REPORT.Run(REPORT::"Resource Usage", true, false);
    end;

    local procedure RunResourceRegisterReport(No: Code[10]; SourceCode: Code[10]; SourceNo: Code[10]; PrintResourceDesc: Boolean)
    begin
        LibraryVariableStorage.Enqueue(PrintResourceDesc);  // Enqueue value for ResourceRegisterReqPageHandler.
        LibraryVariableStorage.Enqueue(No);  // Enqueue value for ResourceRegisterReqPageHandler.
        LibraryVariableStorage.Enqueue(0D);  // Enqueue value for ResourceRegisterReqPageHandler.
        LibraryVariableStorage.Enqueue(SourceCode);  // Enqueue value for ResourceRegisterReqPageHandler.
        LibraryVariableStorage.Enqueue(SourceNo);  // Enqueue value for ResourceRegisterReqPageHandler.
        Commit();
        REPORT.Run(REPORT::"Resource Register", true, false);
    end;

    local procedure RunJobRegisterReport(JobRegisterNo: Text; JobNo: Code[20]; PrintJobDescriptions: Boolean; Type: Enum "Job Journal Line Type")
    begin
        LibraryVariableStorage.Enqueue(JobNo);  // Enqueue value for ResourceRegisterReqPageHandler.
        LibraryVariableStorage.Enqueue(JobRegisterNo);  // Enqueue value for ResourceRegisterReqPageHandler.
        LibraryVariableStorage.Enqueue(PrintJobDescriptions);  // Enqueue value for ResourceRegisterReqPageHandler.
        LibraryVariableStorage.Enqueue(Type);  // Enqueue value for ResourceRegisterReqPageHandler.
        Commit();
        REPORT.Run(REPORT::"Job Register", true, false);
    end;

    local procedure RunCompletedJobReport(BillToCustomerNo: Code[20])
    begin
        LibraryVariableStorage.Enqueue(BillToCustomerNo);  // Enqueue value for CompletedJobReqPageHandler.
        Commit();
        REPORT.Run(REPORT::"Completed Jobs", true, false);
    end;

    local procedure RunJobCostBudgetReportWithBudgetAmountsPerFilter(BudgetOptionTextValue: Text; LineType: Enum "Job Line Type"; BudgetAmountsPerFilter: Option)
    var
        Job: Record Job;
        JobJournalLine: Record "Job Journal Line";
        JobTask: Record "Job Task";
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        // Setup: Create a job and post job journals for it with Line Type as Billable and Budget.
        Initialize();
        CreateJobAndPostJobJournal(Job, LineType, WorkDate());
        FindJobTask(JobTask, Job."No.");
        CreateAndPostJobJournalLine(JobTask, LibraryJob.FindItem(), JobJournalLine.Type::Item, JobJournalLine."Line Type"::Budget, WorkDate());
        FindJobLedgerEntry(JobLedgerEntry, Job."No.", JobJournalLine.Type::Resource);

        // Exercise: Run report Job Cost Budget.
        RunReportJobCostBudget(Job."No.", BudgetAmountsPerFilter);

        // Verify: Verify Job Cost Budget report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange(JobPlanningLineTypeCap, Format(JobJournalLine.Type::Resource));
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals(BudgetOptionTextCap, BudgetOptionTextValue);
        LibraryReportDataset.AssertCurrentRowValueEquals(JobPlanningLineTotalCostLCYCap, JobLedgerEntry."Total Cost (LCY)");
        LibraryReportDataset.AssertCurrentRowValueEquals(JobPlanningLineTotalPriceLCYCap, JobLedgerEntry."Total Price (LCY)");
    end;

    local procedure UpdateJobWithStatus(Job: Record Job)
    var
        JobCard: TestPage "Job Card";
    begin
        Job.Get(Job."No.");
        JobCard.OpenEdit();
        JobCard.GotoRecord(Job);
        JobCard.Status.SetValue(Job.Status::Completed);
        JobCard.Close();
    end;

    local procedure VerifyContractPriceOnJobReports(Job: Record Job; RowCaption: Text; RowcaptionValue: Variant)
    begin
        LibraryReportDataset.SetRange(JobNoCap1, Job."No.");
        LibraryReportDataset.SetRange(JobBilltoCustomerNoCap, Job."Bill-to Customer No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals(RowCaption, RowcaptionValue);
    end;

    local procedure VerifyJobCostTransactionDetail(RowCaption: Text[50]; RowValue: Text[100]; JobNo: Code[20]; Type: Enum "Job Journal Line Type")
    var
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        FindJobLedgerEntry(JobLedgerEntry, JobNo, Type);
        LibraryReportDataset.SetRange(RowCaption, RowValue);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals(TotalCost1Cap, JobLedgerEntry."Total Cost (LCY)");
        LibraryReportDataset.AssertCurrentRowValueEquals(TotalPrice1Cap, JobLedgerEntry."Total Price (LCY)");
    end;

    local procedure VerifyJobLedgerEntry(DocumentNo: Code[20]; JobNo: Code[20]; Amount: Decimal)
    var
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        JobLedgerEntry.SetFilter("Document No.", DocumentNo);
        JobLedgerEntry.SetFilter("Job No.", JobNo);
        JobLedgerEntry.FindFirst();
        JobLedgerEntry.TestField("Direct Unit Cost (LCY)", Amount);
    end;

    local procedure VerifyResourceUsage(Resource: Record Resource)
    begin
        Resource.CalcFields(Capacity, "Usage (Qty.)");
        LibraryReportDataset.SetRange(ResourceNoCap, Resource."No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals(ResourceCapacityCap, Resource.Capacity);
        LibraryReportDataset.AssertCurrentRowValueEquals(ResourceUsageQtyCap, Resource."Usage (Qty.)");
        LibraryReportDataset.AssertCurrentRowValueEquals(CapacityUsageQtyCap, Resource.Capacity - Resource."Usage (Qty.)");
    end;

    local procedure VerifyValuesOnReport(RowCaption: Text[50]; RowValue: Text[50]; RowValue2: Text[50])
    begin
        LibraryReportDataset.AssertElementWithValueExists(RowCaption, RowValue);
        LibraryReportDataset.AssertElementWithValueExists(RowCaption, RowValue2);
    end;

    local procedure VerifyJobRegisterReport(RowCaption: Text[250]; RowValue: Variant; RowCaption2: Text[250]; RowValue2: Variant; JobNo: Code[20])
    begin
        LibraryReportDataset.SetRange(JobLedgerEntryJobNo, JobNo);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals(RowCaption, RowValue);
        LibraryReportDataset.AssertCurrentRowValueEquals(RowCaption2, RowValue2);
    end;

    local procedure VerifyResourceLedgerEntry(ServiceLine: Record "Service Line"; TotalPrice: Decimal)
    var
        ResLedgerEntry: Record "Res. Ledger Entry";
    begin
        ResLedgerEntry.SetRange("Resource No.", ServiceLine."No.");
        ResLedgerEntry.SetRange("Document No.", FindServiceShipmentHeader(ServiceLine."Document No."));
        ResLedgerEntry.SetRange("Entry Type", ResLedgerEntry."Entry Type"::Usage);
        ResLedgerEntry.FindFirst();
        ResLedgerEntry.TestField(Quantity, ServiceLine.Quantity);
        Assert.AreNearlyEqual(TotalPrice, ResLedgerEntry."Total Price", LibraryERM.GetAmountRoundingPrecision(), AmountError);
    end;

    local procedure CreateJobWithPlanningUsageLinkAndSpecificItem(var JobPlanningLine: Record "Job Planning Line"; ItemNo: Code[20])
    var
        JobTask: Record "Job Task";
    begin
        CreateJobWithJobTask(JobTask);

        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::Budget, JobPlanningLine.Type::Item, JobTask, JobPlanningLine);
        JobPlanningLine.Validate("No.", ItemNo);
        JobPlanningLine.Validate(Quantity, LibraryRandom.RandInt(100));
        JobPlanningLine.Validate("Usage Link", true);
        JobPlanningLine.Modify(true);
    end;

    local procedure CreateCustomer(CurrencyCode: Code[10]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Currency Code", CurrencyCode);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreatePurchaseDocument(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; No: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, '');
        // Create Purchase Line with Random Quantity and Direct Unit Cost.
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, No, LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreateJobWithJobTask(var JobTask: Record "Job Task")
    var
        Job: Record Job;
    begin
        LibraryJob.CreateJob(Job, CreateCustomer(''));  // Blank value for Currency Code.
        LibraryJob.CreateJobTask(Job, JobTask);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceReqPageHandler(var PurchaseInvoice: TestRequestPage "Purchase Invoice NA")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        PurchaseInvoice."Purch. Inv. Header".SetFilter("No.", No);
        PurchaseInvoice.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesInvoiceReqPageHandler(var SalesInvoice: TestRequestPage "Sales Invoice NA")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        SalesInvoice."Sales Invoice Header".SetFilter("No.", No);
        SalesInvoice.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ServiceShipmentReqPageHandler(var ServiceShipment: TestRequestPage "Service - Shipment")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        ServiceShipment."Service Shipment Header".SetFilter("No.", No);
        ServiceShipment.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ResourceUsageReqPageHandler(var ResourceUsage: TestRequestPage "Resource Usage")
    var
        ResourceNo: Variant;
        BaseUnitofMeasure: Variant;
        DateFilter: Variant;
    begin
        LibraryVariableStorage.Dequeue(ResourceNo);  // Dequeue for Resource No.
        LibraryVariableStorage.Dequeue(BaseUnitofMeasure);  // Dequeue for Base Unit of Measure.
        LibraryVariableStorage.Dequeue(DateFilter);  // Dequeue for Date Filter.
        ResourceUsage.Resource.SetFilter("No.", ResourceNo);
        ResourceUsage.Resource.SetFilter("Base Unit of Measure", BaseUnitofMeasure);
        ResourceUsage.Resource.SetFilter("Date Filter", Format(DateFilter));
        ResourceUsage.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ResourceRegisterReqPageHandler(var ResourceRegister: TestRequestPage "Resource Register")
    var
        No: Variant;
        SourceCode: Variant;
        SourceNo: Variant;
        PrintResourceDesc: Variant;
        CreationDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(PrintResourceDesc);  // Dequeue for Print Resource Desc.
        LibraryVariableStorage.Dequeue(No);  // Dequeue for No.
        LibraryVariableStorage.Dequeue(CreationDate);  // Dequeue for Creation Date.
        LibraryVariableStorage.Dequeue(SourceCode);  // Dequeue for Source Code.
        LibraryVariableStorage.Dequeue(SourceNo);  // Dequeue for Source No.
        ResourceRegister.PrintResourceDescriptions.SetValue(PrintResourceDesc);
        ResourceRegister."Resource Register".SetFilter("No.", No);
        ResourceRegister."Resource Register".SetFilter("Creation Date", Format(CreationDate));
        ResourceRegister."Resource Register".SetFilter("Source Code", SourceCode);
        ResourceRegister."Res. Ledger Entry".SetFilter("Source No.", SourceNo);
        ResourceRegister.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure JobCostTransactionDetailReqPageHandler(var JobCostTransactionDetail: TestRequestPage "Job Cost Transaction Detail")
    var
        JobNo: Variant;
        CustomerNo: Variant;
        PostingDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(JobNo);  // Dequeue for Job No.
        LibraryVariableStorage.Dequeue(CustomerNo);  // Dequeue for Customer No.
        LibraryVariableStorage.Dequeue(PostingDate);  // Dequeue for Posting Date.
        JobCostTransactionDetail.Job.SetFilter("No.", JobNo);
        JobCostTransactionDetail.Job.SetFilter("Bill-to Customer No.", CustomerNo);
        JobCostTransactionDetail.Job.SetFilter("Posting Date Filter", Format(PostingDate));
        JobCostTransactionDetail.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure JobRegisterReqPageHandler(var JobRegister: TestRequestPage "Job Register")
    var
        JobNo: Variant;
        JobRegisterNo: Variant;
        PrintJobDescriptions: Variant;
        Type: Variant;
    begin
        LibraryVariableStorage.Dequeue(JobNo);  // Dequeue for Job No.
        LibraryVariableStorage.Dequeue(JobRegisterNo);  // Dequeue for Job Register No.
        LibraryVariableStorage.Dequeue(PrintJobDescriptions);  // Dequeue for Print Job Descriptions.
        LibraryVariableStorage.Dequeue(Type);  // Dequeue for Type.
        JobRegister.PrintJobDescriptions.SetValue(PrintJobDescriptions);
        JobRegister."Job Register".SetFilter("No.", JobRegisterNo);
        JobRegister."Job Ledger Entry".SetFilter("Job No.", JobNo);
        JobRegister."Job Ledger Entry".SetFilter(Type, Format(Type));
        JobRegister.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CompletedJobReqPageHandler(var CompletedJobs: TestRequestPage "Completed Jobs")
    var
        BillToCustomerNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(BillToCustomerNo);  // Dequeue for Bill To Customer No.
        CompletedJobs.Job.SetFilter("Bill-to Customer No.", BillToCustomerNo);
        CompletedJobs.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure JobCostSuggestedBillingReqPageHandler(var JobCostSuggestedBilling: TestRequestPage "Job Cost Suggested Billing")
    var
        BillToCustomerNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(BillToCustomerNo);  // Dequeue for Bill To Customer No.
        JobCostSuggestedBilling.Job.SetFilter("Bill-to Customer No.", BillToCustomerNo);
        JobCostSuggestedBilling.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure JobTransferToSalesInvoiceRequestPageHandler(var JobTransfertoSalesInvoice: TestRequestPage "Job Transfer to Sales Invoice")
    begin
        JobTransfertoSalesInvoice.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure JobCostBudgetReqPageHandler(var JobCostBudget: TestRequestPage "Job Cost Budget")
    var
        JobNo: Variant;
        BudgetAmountsPer: Variant;
    begin
        LibraryVariableStorage.Dequeue(JobNo);  // Dequeue for Job No.
        LibraryVariableStorage.Dequeue(BudgetAmountsPer);  // Dequeue for Budget Amounts Per.
        JobCostBudget.BudgetAmountsPer.SetValue(JobCostBudget.BudgetAmountsPer.GetOption(BudgetAmountsPer));
        JobCostBudget.Job.SetFilter("No.", JobNo);
        JobCostBudget.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
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
        // Dummy Message Handler.
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerMultipleResponses(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmationHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := false;
    end;
}

