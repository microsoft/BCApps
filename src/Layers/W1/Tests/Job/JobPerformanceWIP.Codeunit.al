codeunit 136304 "Job Performance WIP"
{
    Permissions = TableData "Job Ledger Entry" = rimd;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Job] [Job WIP]
        Initialized := false;
    end;

    var
        JobsSetup: Record "Jobs Setup";
        NoSeries: Record "No. Series";
        LibraryJob: Codeunit "Library - Job";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        Prefix: Label 'XXX';
        DeltaAssert: Codeunit "Delta Assert";
        JobCreateInvoice: Codeunit "Job Create-Invoice";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryErrorMessage: Codeunit "Library - Error Message";
        Initialized: Boolean;
        EntryNotReversedErr: Label 'Project WIP entry has not been reversed.';
        TotalAmountErr: Label 'Total Amount should be 0 for account: %1';
        AccountType: Option "WIP Costs Account","WIP Invoiced Sales Account";
        TotalWIPCostAmountErr: Label 'Total WIP Cost Amount should be 0 because Project is in Completed status';
        QtyErr: Label 'Quantity is not correct in %1';
        JobWIPEntryGLAccountErr: Label 'Wrong Project WIP Entry record''s count';
        EndingDateNotEmptyErr: Label 'Ending Date is not empty.';

    [Test]
    [Scope('OnPrem')]
    procedure NoWIPMethodOnJob()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
    begin
        // WIP cannot be calculated if no WIP method is specified on the job.

        Initialize();
        CreateJobWithWIPMethod(Job, '', Job."WIP Posting Method"::"Per Job");

        // Setup: create job schedule
        LibraryJob.CreateJobTask(Job, JobTask);

        // Exercise, Verify: calculate WIP
        asserterror CalculateWIP(Job)
    end;

    [Test]
    [HandlerFunctions('WIPSucceededMessageHandler,ConfirmHandlerFalse')]
    [Scope('OnPrem')]
    procedure RecogCostOfSales()
    var
        JobWIPMethod: Record "Job WIP Method";
    begin
        // [SCENARIO] Job WIP and G/L Entry correctly calculated when using Job WIP Methods "Cost of Sales" for costs and "At Completion" for sales

        // Recog Cost = STC * CIP / CTP

        Initialize();
        CreateJobWIPMethod(
          JobWIPMethod."Recognized Costs"::"Cost of Sales", JobWIPMethod."Recognized Sales"::"At Completion", JobWIPMethod);
        WIPScenario(100, 10, 200, 10, JobWIPMethod);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecogCostOfSalesJournalTemplateNameMandatory()
    var
        JobWIPMethod: Record "Job WIP Method";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        // [SCENARIO] Job WIP and G/L Entry correctly calculated when using Job WIP Methods "Cost of Sales" for costs and "At Completion" for sales

        // Recog Cost = STC * CIP / CTP

        Initialize();
        LibraryERMCountryData.UpdateJournalTemplMandatory(true);
        CreateJobWIPMethod(
          JobWIPMethod."Recognized Costs"::"Cost of Sales", JobWIPMethod."Recognized Sales"::"At Completion", JobWIPMethod);
        asserterror WIPScenario(100, 10, 200, 10, JobWIPMethod);
    end;

    [Test]
    [HandlerFunctions('WIPSucceededMessageHandler,ConfirmHandlerFalse')]
    [Scope('OnPrem')]
    procedure RecogCostOfSalesAccrued()
    var
        JobWIPMethod: Record "Job WIP Method";
    begin
        // Invoicing ahead of usage (relatively)
        // Recognized Cost > Usage Total Cost
        // STC * CIP / CTP > UTC
        // CIP / CTP > UTC / STC

        Initialize();
        CreateJobWIPMethod(
          JobWIPMethod."Recognized Costs"::"Cost of Sales", JobWIPMethod."Recognized Sales"::"At Completion", JobWIPMethod);
        WIPScenario(100, 10, 200, 40, JobWIPMethod)
    end;

    [Test]
    [HandlerFunctions('WIPSucceededMessageHandler,ConfirmHandlerFalse')]
    [Scope('OnPrem')]
    procedure RecogCostValue()
    var
        JobWIPMethod: Record "Job WIP Method";
    begin
        // Recog Cost = UTC - UTC * CTP / STP + CIP * STC / STP

        Initialize();
        CreateJobWIPMethod(JobWIPMethod."Recognized Costs"::"Cost Value", JobWIPMethod."Recognized Sales"::"At Completion", JobWIPMethod);
        WIPScenario(100, 10, 200, 10, JobWIPMethod)
    end;

    [Test]
    [HandlerFunctions('WIPSucceededMessageHandler,ConfirmHandlerFalse')]
    [Scope('OnPrem')]
    procedure RecogCostValueAccrued()
    var
        JobWIPMethod: Record "Job WIP Method";
    begin
        // Invoicing ahead of usage (relatively)
        // Recognized Cost > Usage Total Cost
        // UTC * (1 - CTP / STP) + CIP * STC / STP > UTC
        // 1 - CTP / STP + CIP * STC / (STP * UTC) > 1
        // CIP * STC / (STP * UTC) > CTP / STP
        // CIP * STC / UTC > CTP
        // CIP / CTP > UTC / STC

        Initialize();
        CreateJobWIPMethod(JobWIPMethod."Recognized Costs"::"Cost Value", JobWIPMethod."Recognized Sales"::"At Completion", JobWIPMethod);
        WIPScenario(100, 10, 200, 40, JobWIPMethod)
    end;

    [Test]
    [HandlerFunctions('WIPSucceededMessageHandler,ConfirmHandlerFalse')]
    [Scope('OnPrem')]
    procedure RecogContractInvoicedCost()
    var
        JobWIPMethod: Record "Job WIP Method";
    begin
        Initialize();
        CreateJobWIPMethod(
          JobWIPMethod."Recognized Costs"::"Contract (Invoiced Cost)", JobWIPMethod."Recognized Sales"::"At Completion", JobWIPMethod);
        WIPScenario(100, 10, 200, 10, JobWIPMethod)
    end;

    [Test]
    [HandlerFunctions('WIPSucceededMessageHandler,ConfirmHandlerFalse')]
    [Scope('OnPrem')]
    procedure RecogContractInvoicedCostAccru()
    var
        JobWIPMethod: Record "Job WIP Method";
    begin
        // Invoicing ahead of usage (absolutely)
        // Recognized Costs > Usage Total Cost
        // CIC > UTC

        Initialize();
        CreateJobWIPMethod(
          JobWIPMethod."Recognized Costs"::"Contract (Invoiced Cost)", JobWIPMethod."Recognized Sales"::"At Completion", JobWIPMethod);
        WIPScenario(100, 10, 200, 40, JobWIPMethod)
    end;

    [Test]
    [HandlerFunctions('WIPSucceededMessageHandler,ConfirmHandlerFalse')]
    [Scope('OnPrem')]
    procedure RecogUsageTotalCostCosts()
    var
        JobWIPMethod: Record "Job WIP Method";
    begin
        Initialize();

        CreateJobWIPMethod(JobWIPMethod."Recognized Costs"::"Usage (Total Cost)", JobWIPMethod."Recognized Sales"::"At Completion",
          JobWIPMethod);
        WIPScenario(100, 10, 200, 10, JobWIPMethod)
    end;

    [Test]
    [HandlerFunctions('WIPSucceededMessageHandler,ConfirmHandlerFalse')]
    [Scope('OnPrem')]
    procedure RecogContractInvoicedPrice()
    var
        JobWIPMethod: Record "Job WIP Method";
    begin
        Initialize();
        CreateJobWIPMethod(
          JobWIPMethod."Recognized Costs"::"At Completion", JobWIPMethod."Recognized Sales"::"Contract (Invoiced Price)", JobWIPMethod);
        WIPScenario(100, 10, 200, 40, JobWIPMethod)
    end;

    [Test]
    [HandlerFunctions('WIPSucceededMessageHandler,ConfirmHandlerFalse')]
    [Scope('OnPrem')]
    procedure RecogUsageTotalCostSales()
    var
        JobWIPMethod: Record "Job WIP Method";
    begin
        Initialize();
        CreateJobWIPMethod(JobWIPMethod."Recognized Costs"::"At Completion", JobWIPMethod."Recognized Sales"::"Usage (Total Cost)",
          JobWIPMethod);
        WIPScenario(100, 10, 200, 40, JobWIPMethod)
    end;

    [Test]
    [HandlerFunctions('WIPSucceededMessageHandler,ConfirmHandlerFalse')]
    [Scope('OnPrem')]
    procedure RecogUsageTotalCostSalesAccrue()
    var
        JobWIPMethod: Record "Job WIP Method";
    begin
        // Recognized Sales > Contract Invoiced Price
        // UTC > CIP

        Initialize();
        CreateJobWIPMethod(JobWIPMethod."Recognized Costs"::"At Completion", JobWIPMethod."Recognized Sales"::"Usage (Total Cost)",
          JobWIPMethod);
        WIPScenario(100, 10, 200, 10, JobWIPMethod)
    end;

    [Test]
    [HandlerFunctions('WIPSucceededMessageHandler,ConfirmHandlerFalse')]
    [Scope('OnPrem')]
    procedure RecogUsageTotalPrice()
    var
        JobWIPMethod: Record "Job WIP Method";
    begin
        Initialize();
        CreateJobWIPMethod(JobWIPMethod."Recognized Costs"::"At Completion", JobWIPMethod."Recognized Sales"::"Usage (Total Price)",
          JobWIPMethod);
        WIPScenario(100, 10, 200, 40, JobWIPMethod)
    end;

    [Test]
    [HandlerFunctions('WIPSucceededMessageHandler,ConfirmHandlerFalse')]
    [Scope('OnPrem')]
    procedure RecogUsageTotalPriceAccrued()
    var
        JobWIPMethod: Record "Job WIP Method";
    begin
        // Recognized Sales > Contract Invoiced Price
        // UTP > CIP

        Initialize();
        CreateJobWIPMethod(JobWIPMethod."Recognized Costs"::"At Completion", JobWIPMethod."Recognized Sales"::"Usage (Total Price)",
          JobWIPMethod);
        WIPScenario(100, 10, 200, 10, JobWIPMethod)
    end;

    [Test]
    [HandlerFunctions('WIPSucceededMessageHandler,ConfirmHandlerFalse')]
    [Scope('OnPrem')]
    procedure RecogPoC()
    var
        JobWIPMethod: Record "Job WIP Method";
    begin
        // Recog Sales = CTP * UTC / STC

        Initialize();
        CreateJobWIPMethod(JobWIPMethod."Recognized Costs"::"At Completion", JobWIPMethod."Recognized Sales"::"Percentage of Completion",
          JobWIPMethod);
        WIPScenario(100, 10, 200, 40, JobWIPMethod)
    end;

    [Test]
    [HandlerFunctions('WIPSucceededMessageHandler,ConfirmHandlerFalse')]
    [Scope('OnPrem')]
    procedure RecogPoCAccrued()
    var
        JobWIPMethod: Record "Job WIP Method";
    begin
        // Usage ahead of invoicing (relatively)
        // Recognized Sales > Contract Invoiced Price
        // CTP * UTC / STC > CIP (iff UTC / STC < 1)
        // UTC / STC > CIP / CTP

        Initialize();
        CreateJobWIPMethod(JobWIPMethod."Recognized Costs"::"At Completion", JobWIPMethod."Recognized Sales"::"Percentage of Completion",
          JobWIPMethod);
        WIPScenario(100, 10, 200, 10, JobWIPMethod)
    end;

    [Test]
    [HandlerFunctions('WIPSucceededMessageHandler,ConfirmHandlerFalse')]
    [Scope('OnPrem')]
    procedure RecogPoCAccruedOverBudget()
    var
        JobWIPMethod: Record "Job WIP Method";
    begin
        // Usage ahead of invoicing (relatively)
        // Recognized Sales > Contract Invoiced Price
        // CTP > CIP (iff UTC / STC > 1)
        // UTC / STC > CIP / CTP

        Initialize();
        CreateJobWIPMethod(JobWIPMethod."Recognized Costs"::"At Completion", JobWIPMethod."Recognized Sales"::"Percentage of Completion",
          JobWIPMethod);
        WIPScenario(100, 110, 200, 10, JobWIPMethod)
    end;

    [Test]
    [HandlerFunctions('WIPSucceededMessageHandler,ConfirmHandlerFalse')]
    [Scope('OnPrem')]
    procedure RecogSalesValue()
    var
        JobWIPMethod: Record "Job WIP Method";
    begin
        // Recog Sales = UTP * CTP / STP

        Initialize();
        CreateJobWIPMethod(JobWIPMethod."Recognized Costs"::"At Completion", JobWIPMethod."Recognized Sales"::"Sales Value", JobWIPMethod);
        WIPScenario(100, 10, 200, 40, JobWIPMethod)
    end;

    [Test]
    [HandlerFunctions('WIPSucceededMessageHandler,ConfirmHandlerFalse')]
    [Scope('OnPrem')]
    procedure RecogSalesValueAccrued()
    var
        JobWIPMethod: Record "Job WIP Method";
    begin
        // Usage ahead of invoicing (relatively)
        // Recognized Sales > Contract Invoiced Price
        // UTP * CTP / STP > CIP
        // UTP / STP > CIP / CTP

        Initialize();
        CreateJobWIPMethod(JobWIPMethod."Recognized Costs"::"At Completion", JobWIPMethod."Recognized Sales"::"Sales Value", JobWIPMethod);
        WIPScenario(100, 10, 200, 10, JobWIPMethod)
    end;

    [Test]
    [HandlerFunctions('WIPSucceededMessageHandler,ConfirmHandlerFalse')]
    [Scope('OnPrem')]
    procedure SystemDefinedWIPMethods()
    var
        JobWIPMethod: Record "Job WIP Method";
    begin
        // Calculate and verify WIP for all system defined methods.

        Initialize();
        // REMOVE THIS FILTER AS SOON AS BUG 167961 HAD BEEN RESOLVED!
        JobWIPMethod.SetFilter("Recognized Costs", '<>%1', JobWIPMethod."Recognized Costs"::"Cost Value");
        JobWIPMethod.SetRange("System Defined", true);
        JobWIPMethod.FindSet();
        repeat
            // with accrued sales
            WIPScenario(100, 10, 200, 40, JobWIPMethod);
            // with accrued costs
            WIPScenario(100, 10, 200, 10, JobWIPMethod)
        until JobWIPMethod.Next() = 0
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NegativeUsage()
    var
        JobWIPMethod: Record "Job WIP Method";
    begin
        // Negative usage should be handled correctly (i.e., recognize 0 costs)

        Initialize();
        CreateJobWIPMethod(JobWIPMethod."Recognized Costs"::"Usage (Total Cost)", JobWIPMethod."Recognized Sales"::"At Completion",
          JobWIPMethod)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NegativeInvoicing()
    var
        JobWIPMethod: Record "Job WIP Method";
    begin
        // Negative invoicing should be handled correctly (i.e., recognize 0 sales)

        Initialize();
        CreateJobWIPMethod(JobWIPMethod."Recognized Costs"::"At Completion", JobWIPMethod."Recognized Sales"::"Contract (Invoiced Price)",
          JobWIPMethod)
    end;

    [Test]
    [HandlerFunctions('WIPFailedMessageHandler')]
    [Scope('OnPrem')]
    procedure NoWIPCosts()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobWIPMethod: Record "Job WIP Method";
        JobWIPEntry: Record "Job WIP Entry";
        ScheduleAmount: Decimal;
        UsageAmount: Decimal;
        ContractAmount: Decimal;
    begin
        // WIP Costs disabled on WIP Method should result prevent WIP cost entries being created.

        Initialize();

        ScheduleAmount := 100;
        UsageAmount := 10;
        ContractAmount := 200;

        // Setup: create job
        CreateJobWIPMethod(JobWIPMethod."Recognized Costs"::"Usage (Total Cost)", JobWIPMethod."Recognized Sales"::"At Completion",
          JobWIPMethod);
        JobWIPMethod.Validate("WIP Cost", false);
        JobWIPMethod.Modify(true);
        CreateJobWithWIPMethod(Job, JobWIPMethod.Code, Job."WIP Posting Method"::"Per Job");

        // Setup: create job schedule
        LibraryJob.CreateJobTask(Job, JobTask);
        PlanJobTask(JobTask, ScheduleAmount, ContractAmount, LibraryJob.ResourceType());

        // totaling task
        CreateJobTaskWIPTotal(JobTask, Job, JobTask."Job Task Type"::Total);

        // Setup: execute job
        FilterJobTaskByType(JobTask, Job."No.");
        UseJobTasks(JobTask, UsageAmount / ScheduleAmount);

        // Exercise: calculate WIP
        CalculateWIP(Job);

        // Verify: no Job WIP Entry is created
        JobWIPEntry.SetRange("Job No.", Job."No.");
        Assert.IsTrue(JobWIPEntry.IsEmpty, 'No WIP entries should have been created.')
    end;

    [Test]
    [HandlerFunctions('WIPFailedMessageHandler')]
    [Scope('OnPrem')]
    procedure NoWIPSales()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobWIPMethod: Record "Job WIP Method";
        JobWIPEntry: Record "Job WIP Entry";
        ScheduleAmount: Decimal;
        ContractAmount: Decimal;
        InvoicedAmount: Decimal;
    begin
        // WIP Sales disabled on WIP Method should result prevent WIP sales entries being created.

        Initialize();

        ScheduleAmount := 100;
        ContractAmount := 200;
        InvoicedAmount := 20;

        // Setup: create job
        CreateJobWIPMethod(
          JobWIPMethod."Recognized Costs"::"At Completion", JobWIPMethod."Recognized Sales"::"Contract (Invoiced Price)", JobWIPMethod);
        JobWIPMethod.Validate("WIP Sales", false);
        JobWIPMethod.Modify(true);
        CreateJobWithWIPMethod(Job, JobWIPMethod.Code, Job."WIP Posting Method"::"Per Job");

        // Setup: create job schedule
        LibraryJob.CreateJobTask(Job, JobTask);
        PlanJobTask(JobTask, ScheduleAmount, ContractAmount, LibraryJob.ResourceType());

        // totaling task
        CreateJobTaskWIPTotal(JobTask, Job, JobTask."Job Task Type"::Total);

        // Setup: execute job
        FilterJobTaskByType(JobTask, Job."No.");
        InvoiceJobTasks(JobTask, InvoicedAmount / ContractAmount);

        // Exercise: calculate WIP
        CalculateWIP(Job);

        // Verify: no Job WIP Entry is created
        JobWIPEntry.SetRange("Job No.", Job."No.");
        Assert.IsTrue(JobWIPEntry.IsEmpty, 'No WIP entries should have been created.')
    end;

    [Test]
    [HandlerFunctions('WIPSucceededMessageHandler,ConfirmHandlerFalse')]
    [Scope('OnPrem')]
    procedure MultipleWIPMethods()
    begin
        // Different WIP Methods may be used for the different WIP totals of a job.

        Initialize();
        WIPScenarioMultipleWIPMethods(100, 10, 200, 40)
    end;

    [HandlerFunctions('WIPSucceededMessageHandler')]
    local procedure WIPScenarioMultipleWIPMethods(ScheduleAmount: Decimal; UsageAmount: Decimal; ContractAmount: Decimal; InvoicedAmount: Decimal)
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobWIPMethod: Record "Job WIP Method";
    begin
        // Setup: create job
        // REMOVE THE COST VALUE FILTER AS SOON AS BUG 167961 HAS BEEN RESOLVED!
        // No Calculation cannot be used in scenarios where other job tasks do recognize costs since we are mocking the job ledger entries
        JobWIPMethod.SetFilter("Recognized Costs", '<>%1&<>%2', JobWIPMethod."Recognized Costs"::"Cost Value",
          JobWIPMethod."Recognized Costs"::"At Completion");
        JobWIPMethod.SetRange("System Defined", true);
        JobWIPMethod.FindSet();
        CreateJobWithWIPMethod(Job, JobWIPMethod.Code, Job."WIP Posting Method"::"Per Job");
        repeat
            // Setup: create schedule and contract for job task.
            LibraryJob.CreateJobTask(Job, JobTask);
            PlanJobTask(JobTask, ScheduleAmount, ContractAmount, LibraryJob.ResourceType());

            // totaling task
            CreateJobTaskWIPTotal(JobTask, Job, JobTask."Job Task Type"::Total);
            JobTask.Validate("WIP Method", JobWIPMethod.Code);
            JobTask.Modify(true);
        until JobWIPMethod.Next() = 0;

        // Setup: execute job
        FilterJobTaskByType(JobTask, Job."No.");
        UseJobTasks(JobTask, UsageAmount / ScheduleAmount);
        InvoiceJobTasks(JobTask, InvoicedAmount / ContractAmount);

        // Exercise: calculate WIP
        CalculateWIP(Job);

        // Verify: define expected impact of WIP on GL
        DefineWIPImpactOnGL(Job);

        // Exercise: post WIP to GL
        PostWIP2GL(Job);
        Job.Get(Job."No.");

        // Verify: WIP fields on job, job task
        VerifyJobWIP(Job, JobWIPMethod);

        // Verify: WIP impact on GL
        DeltaAssert.Assert();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse')]
    [Scope('OnPrem')]
    procedure ExcludeWIPCosts()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobWIPMethod: Record "Job WIP Method";
        GeneralLedgerSetup: Record "General Ledger Setup";
        ScheduleAmount: Decimal;
        UsageAmount: Decimal;
        ContractAmount: Decimal;
    begin
        // Usage for excluded job tasks should not affect cost recognition

        ScheduleAmount := LibraryRandom.RandInt(100);
        UsageAmount := LibraryRandom.RandInt(ScheduleAmount);
        ContractAmount := ScheduleAmount + LibraryRandom.RandInt(100);

        // Setup: create job
        CreateJobWIPMethod(
          JobWIPMethod."Recognized Costs"::"Usage (Total Cost)", JobWIPMethod."Recognized Sales"::"At Completion", JobWIPMethod);
        CreateJobWithWIPMethod(Job, JobWIPMethod.Code, Job."WIP Posting Method"::"Per Job");

        // Setup: create and plan first job task
        LibraryJob.CreateJobTask(Job, JobTask);
        PlanJobTask(JobTask, ScheduleAmount, ContractAmount, LibraryJob.ResourceType());

        // Setup: create and plan excluded job task
        LibraryJob.CreateJobTask(Job, JobTask);
        PlanJobTask(JobTask, ScheduleAmount, ContractAmount, LibraryJob.ResourceType());
        JobTask.Validate("WIP-Total", JobTask."WIP-Total"::Excluded);
        JobTask.Modify(true);

        // Setup: create and plan WIP total job task
        LibraryJob.CreateJobTask(Job, JobTask);
        JobTask.Validate("WIP-Total", JobTask."WIP-Total"::Total);
        JobTask.Modify(true);

        PlanJobTask(JobTask, ScheduleAmount, ContractAmount, LibraryJob.ResourceType());

        // Setup: execute job
        JobTask.Reset();
        JobTask.SetRange("Job No.", Job."No.");
        UseJobTasks(JobTask, UsageAmount / ScheduleAmount);

        // Exercise: calculate WIP
        CalculateWIP(Job);

        // Verify: only two job (out of three) tasks contribute to the recognized cost for the job
        Job.CalcFields("Recog. Costs Amount");
        GeneralLedgerSetup.Get();
        Assert.AreNearlyEqual(2 * UsageAmount, Job."Recog. Costs Amount",
          GeneralLedgerSetup."Amount Rounding Precision",
          Job.FieldCaption("Recog. Costs Amount"))
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse')]
    [Scope('OnPrem')]
    procedure ExcludeWIPSales()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobWIPMethod: Record "Job WIP Method";
        GeneralLedgerSetup: Record "General Ledger Setup";
        ScheduleAmount: Decimal;
        ContractAmount: Decimal;
        InvoicedAmount: Decimal;
    begin
        // Usage for excluded job tasks should not affect sales recognition

        ScheduleAmount := LibraryRandom.RandInt(100);
        ContractAmount := ScheduleAmount + LibraryRandom.RandInt(100);
        InvoicedAmount := LibraryRandom.RandInt(ContractAmount);

        // Setup: create job
        CreateJobWIPMethod(
          JobWIPMethod."Recognized Costs"::"At Completion", JobWIPMethod."Recognized Sales"::"Contract (Invoiced Price)", JobWIPMethod);
        CreateJobWithWIPMethod(Job, JobWIPMethod.Code, Job."WIP Posting Method"::"Per Job");

        // Setup: create and plan first job task
        LibraryJob.CreateJobTask(Job, JobTask);
        PlanJobTask(JobTask, ScheduleAmount, ContractAmount, LibraryJob.ResourceType());

        // Setup: create and plan excluded job task
        LibraryJob.CreateJobTask(Job, JobTask);
        PlanJobTask(JobTask, ScheduleAmount, ContractAmount, LibraryJob.ResourceType());
        JobTask.Validate("WIP-Total", JobTask."WIP-Total"::Excluded);
        JobTask.Modify(true);

        // Setup: create and plan WIP total job task
        LibraryJob.CreateJobTask(Job, JobTask);
        JobTask.Validate("WIP-Total", JobTask."WIP-Total"::Total);
        JobTask.Modify(true);
        PlanJobTask(JobTask, ScheduleAmount, ContractAmount, LibraryJob.ResourceType());

        // Setup: execute job
        JobTask.Reset();
        JobTask.SetRange("Job No.", Job."No.");
        InvoiceJobTasks(JobTask, InvoicedAmount / ContractAmount);

        // Exercise: calculate WIP
        CalculateWIP(Job);

        // Verify: only two job (out of three) tasks contribute to the recognized cost for the job
        Job.CalcFields("Recog. Sales Amount");
        GeneralLedgerSetup.Get();
        Assert.AreNearlyEqual(2 * InvoicedAmount, Job."Recog. Sales Amount",
          GeneralLedgerSetup."Amount Rounding Precision",
          Job.FieldCaption("Recog. Sales Amount"))
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse')]
    [Scope('OnPrem')]
    procedure PerJLE()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        JobWIPMethod: Record "Job WIP Method";
        JobLedgerEntry: Record "Job Ledger Entry";
        JobWIPEntry: Record "Job WIP Entry";
        ScheduleAmount: Decimal;
    begin
        // Calculating WIP per JLE would still compress all WIP entries for identical posting group and dimension

        ScheduleAmount := LibraryRandom.RandInt(100);

        // Setup: create job
        CreateJobWIPAndJobTask(Job, JobWIPMethod, JobPlanningLine, JobTask, ScheduleAmount, ScheduleAmount);

        // Setup: invoice (creating two job ledger entries)
        CreateMockJobLedgerEntry(JobPlanningLine, 1 / 5, JobLedgerEntry);
        CreateMockJobLedgerEntry(JobPlanningLine, 2 / 5, JobLedgerEntry);

        // Exercise
        CalculateWIP(Job);
        // Verify
        JobWIPEntry.SetRange("Job No.", Job."No.");
        JobWIPEntry.SetRange(Type, JobWIPEntry.Type::"Applied Sales");
        // WIP entries are compressed
        Assert.AreEqual(1, JobWIPEntry.Count, '# ' + JobWIPEntry.TableCaption);

        JobWIPEntry.FindFirst();
        Assert.AreEqual(JobWIPEntry."WIP Posting Method Used", JobWIPEntry."WIP Posting Method Used"::"Per Job Ledger Entry",
          JobWIPEntry.FieldCaption("WIP Posting Method Used"));
        Assert.AreEqual(JobWIPEntry.Reverse, true, JobWIPEntry.FieldCaption(Reverse))
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse')]
    [Scope('OnPrem')]
    procedure PerJLEDimension()
    var
        Job: Record Job;
        JobPlanningLine: Record "Job Planning Line";
        JobTask: Record "Job Task";
        JobWIPMethod: Record "Job WIP Method";
        JobLedgerEntry: Record "Job Ledger Entry";
        JobWIPEntry: Record "Job WIP Entry";
        ScheduleAmount: Decimal;
        ContractAmount: Decimal;
    begin
        // Job WIP Entries should be compressed per the dimension on the corresponding job ledger entries

        ScheduleAmount := LibraryRandom.RandInt(100);
        ContractAmount := ScheduleAmount + LibraryRandom.RandInt(100);

        // Setup: create job
        CreateJobWIPAndJobTask(Job, JobWIPMethod, JobPlanningLine, JobTask, ScheduleAmount, ContractAmount);

        // Setup: invoice (creating two job ledger entries with different dimensions)
        CreateMockJobLedgerEntry(JobPlanningLine, 1 / 5, JobLedgerEntry);
        AttachDimension2JobLedgerEntry(JobLedgerEntry, CreateDimensionSet());

        CreateMockJobLedgerEntry(JobPlanningLine, 2 / 5, JobLedgerEntry);
        AttachDimension2JobLedgerEntry(JobLedgerEntry, CreateDimensionSet());

        // Exercise
        CalculateWIP(Job);

        // Verify

        JobLedgerEntry.Init();
        JobWIPEntry.Init();
        JobLedgerEntry.SetRange("Job No.", Job."No.");
        JobLedgerEntry.SetRange("Job Task No.", JobTask."Job Task No.");
        JobWIPEntry.SetRange("Job No.", Job."No.");
        JobWIPEntry.SetRange(Type, JobWIPEntry.Type::"Applied Sales");

        Assert.RecordCount(JobWIPEntry, JobLedgerEntry.Count);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse')]
    [Scope('OnPrem')]
    procedure PerJLEPostingGroup()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        JobWIPMethod: Record "Job WIP Method";
        JobLedgerEntry: Record "Job Ledger Entry";
        JobWIPEntry: Record "Job WIP Entry";
        JobPostingGroup: Record "Job Posting Group";
        ScheduleAmount: Decimal;
        ContractAmount: Decimal;
    begin
        // Job WIP Entries should be compressed per the posting group on the corresponding job tasks

        ScheduleAmount := LibraryRandom.RandInt(100);
        ContractAmount := ScheduleAmount + LibraryRandom.RandInt(100);

        // Setup: create job
        CreateJobWIPMethod(
          JobWIPMethod."Recognized Costs"::"At Completion", JobWIPMethod."Recognized Sales"::"Contract (Invoiced Price)", JobWIPMethod);
        CreateJobWithWIPMethod(Job, JobWIPMethod.Code, Job."WIP Posting Method"::"Per Job Ledger Entry");

        // Setup: create and plan a job task
        LibraryJob.CreateJobTask(Job, JobTask);
        JobTask."Job Posting Group" := CreateJobPostingGroup(JobPostingGroup);
        JobTask.Modify(true);
        ScheduleJobTask(JobTask, ScheduleAmount, LibraryJob.ResourceType(), JobPlanningLine);
        ContractJobTask(JobTask, ContractAmount, LibraryJob.ResourceType(), JobPlanningLine);
        // invoice
        CreateMockJobLedgerEntry(JobPlanningLine, 0.2, JobLedgerEntry);

        // Setup: create and plan a job task with a different posting group
        LibraryJob.CreateJobTask(Job, JobTask);
        JobTask."Job Posting Group" := CreateJobPostingGroup(JobPostingGroup);
        JobTask.Modify(true);
        ScheduleJobTask(JobTask, ScheduleAmount, LibraryJob.ResourceType(), JobPlanningLine);
        ContractJobTask(JobTask, ContractAmount, LibraryJob.ResourceType(), JobPlanningLine);
        // invoice
        CreateMockJobLedgerEntry(JobPlanningLine, 0.2, JobLedgerEntry);

        // Exercise
        CalculateWIP(Job);
        // Verify
        JobLedgerEntry.SetRange("Job No.", Job."No.");
        JobWIPEntry.SetRange("Job No.", Job."No.");
        JobWIPEntry.SetRange(Type, JobWIPEntry.Type::"Applied Sales");
        // one WIP entry per ledger entry
        Assert.AreEqual(JobLedgerEntry.Count, JobWIPEntry.Count, '# ' + JobWIPEntry.TableCaption)
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse')]
    [Scope('OnPrem')]
    procedure PerJLEType()
    var
        Job: Record Job;
        JobWIPMethod: Record "Job WIP Method";
        JobTask: Record "Job Task";
        ItemJobPlanningLine: Record "Job Planning Line";
        GLJobPlanningLine: Record "Job Planning Line";
        ResourceJobPlanningLine: Record "Job Planning Line";
        JobPostingGroup: Record "Job Posting Group";
        JobWIPEntry: Record "Job WIP Entry";
        ItemScheduleAmount: Decimal;
        ResourceScheduleAmount: Decimal;
        GLScheduleAmount: Decimal;
        UsageFraction: Decimal;
    begin
        ItemScheduleAmount := LibraryRandom.RandInt(100);
        ResourceScheduleAmount := ItemScheduleAmount + LibraryRandom.RandInt(100);
        GLScheduleAmount := ResourceScheduleAmount + LibraryRandom.RandInt(100);
        UsageFraction := LibraryRandom.RandInt(99) / 100;

        // Setup: create job
        CreateJobWIPMethod(
          JobWIPMethod."Recognized Costs"::"Cost of Sales", JobWIPMethod."Recognized Sales"::"At Completion", JobWIPMethod);
        CreateJobWithWIPMethod(Job, JobWIPMethod.Code, Job."WIP Posting Method"::"Per Job Ledger Entry");

        // Setup: create and plan job task
        LibraryJob.CreateJobTask(Job, JobTask);

        // for item, resource, and gl
        ScheduleJobTask(JobTask, ItemScheduleAmount, LibraryJob.ItemType(), ItemJobPlanningLine);
        ScheduleJobTask(JobTask, ResourceScheduleAmount, LibraryJob.ResourceType(), ResourceJobPlanningLine);
        ScheduleJobTask(JobTask, GLScheduleAmount, LibraryJob.GLAccountType(), GLJobPlanningLine);

        // Setup: Use a fraction of each of them
        FilterJobTaskByType(JobTask, Job."No.");
        UseJobTasks(JobTask, UsageFraction);

        // Exercise
        CalculateWIP(Job);

        // Verify: corresponding amounts should go to the corresponding accounts
        JobPostingGroup.Get(JobTask."Job Posting Group");
        JobWIPEntry.SetRange("Job No.", Job."No.");
        JobWIPEntry.SetRange(Type, JobWIPEntry.Type::"Applied Costs");

        JobWIPEntry.SetRange("G/L Account No.", JobPostingGroup."Item Costs Applied Account");
        JobWIPEntry.FindFirst();
        Assert.AreEqual(-UsageFraction * ItemScheduleAmount, JobWIPEntry."WIP Entry Amount", JobWIPEntry.FieldCaption("WIP Entry Amount"));

        JobWIPEntry.SetRange("G/L Account No.", JobPostingGroup."Resource Costs Applied Account");
        JobWIPEntry.FindFirst();
        Assert.AreEqual(-UsageFraction * ResourceScheduleAmount, JobWIPEntry."WIP Entry Amount", JobWIPEntry.FieldCaption("WIP Entry Amount"));

        JobWIPEntry.SetRange("G/L Account No.", JobPostingGroup."G/L Costs Applied Account");
        JobWIPEntry.FindFirst();
        Assert.AreEqual(-UsageFraction * GLScheduleAmount, JobWIPEntry."WIP Entry Amount", JobWIPEntry.FieldCaption("WIP Entry Amount"))
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse')]
    [Scope('OnPrem')]
    procedure PerJLEAccruedApplied()
    var
        Job: Record Job;
        JobWIPMethod: Record "Job WIP Method";
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        JobLedgerEntry: Record "Job Ledger Entry";
        JobWIPEntry: Record "Job WIP Entry";
        ScheduleAmount: Decimal;
        UsageFraction: Decimal;
        ContractAmount: Decimal;
        InvoiceFraction: Decimal;
    begin
        // [SCENARIO] Job WIP Entry "Applied Costs" posted when using WIP Method "Cost of Sales" and WIP Posting Method "Per Job Ledger Entry"

        ScheduleAmount := LibraryRandom.RandInt(100);
        ContractAmount := ScheduleAmount + LibraryRandom.RandInt(100);
        UsageFraction := LibraryRandom.RandInt(99) / 100;
        InvoiceFraction := UsageFraction + LibraryRandom.RandInt(99) / 100;

        // Setup: create job
        CreateJobWIPMethod(
          JobWIPMethod."Recognized Costs"::"Cost of Sales", JobWIPMethod."Recognized Sales"::"At Completion", JobWIPMethod);
        CreateJobWithWIPMethod(Job, JobWIPMethod.Code, Job."WIP Posting Method"::"Per Job Ledger Entry");

        // Setup: create, schedule, invoice (InvoiceFraction), use (UsageFraction) job task
        LibraryJob.CreateJobTask(Job, JobTask);

        // invoice
        ContractJobTask(JobTask, ContractAmount, LibraryJob.ResourceType(), JobPlanningLine);
        CreateMockJobLedgerEntry(JobPlanningLine, InvoiceFraction, JobLedgerEntry);
        AttachDimension2JobLedgerEntry(JobLedgerEntry, CreateDimensionSet());

        // use
        ScheduleJobTask(JobTask, ScheduleAmount, LibraryJob.ResourceType(), JobPlanningLine);
        CreateMockJobLedgerEntry(JobPlanningLine, UsageFraction, JobLedgerEntry);
        AttachDimension2JobLedgerEntry(JobLedgerEntry, CreateDimensionSet());

        // Exercise
        CalculateWIP(Job);
        // Verify
        JobWIPEntry.SetRange("Job No.", Job."No.");
        JobWIPEntry.SetRange(Type, JobWIPEntry.Type::"Applied Costs");
        JobWIPEntry.SetRange(Reverse, true);
        Assert.AreEqual(2, JobWIPEntry.Count, StrSubstNo('# %1', JobWIPEntry.TableCaption));
        JobWIPEntry.FindLast();
        Assert.AreEqual(JobWIPEntry."WIP Entry Amount", -UsageFraction * ScheduleAmount, JobWIPEntry.FieldCaption("WIP Entry Amount"));
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerMultipleResponses')]
    [Scope('OnPrem')]
    procedure WIPEntryAfterJobCalculateWIP()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
    begin
        // Verify Program creates "WIP Entry" after executing the "Job Calculate WIP" batch when Recognized Cost is "At Completion".

        // 1. Setup: Create Job WIP Method, Job, Job Task, Job Journal Line and Post the Job Journal Line.
        Initialize();
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(true);
        CreateJobAndPostJobJournal(Job, JobTask, Job."WIP Posting Method"::"Per Job");

        // 2. Exercise: Run "Job Calculate WIP" batch job.
        LibraryVariableStorage.Enqueue(false);
        CalculateWIP(Job);

        // 3. Verify: Verify Job WIP Entry.
        VerifyJobWIPEntry(JobTask);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler,JobWipEntriesHandler,JobPostWIPtoGLRequestPageHandler')]
    [Scope('OnPrem')]
    procedure WIPGLEntryAfterJobPostWIPToGL()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
    begin
        // Verify Program creates "WIP GL Entry" when post the Job Journal and execute the "Post WIP To GL" batch where Recognized Cost is "At Completion".

        // 1. Setup: Create Job WIP Method, Job, Job Task and Job Journal Line. Post the Job Journal Line. Run "Job Calculate WIP" batch job.
        Initialize();
        CreateJobAndPostJobJournal(Job, JobTask, Job."WIP Posting Method"::"Per Job");
        CalculateWIP(Job);

        // 2. Exercise: Run "Job Post WIP to G/L" batch job.
        PostWIP2GL(Job);
        JobTask.CalcFields("Usage (Total Cost)");

        // 3. Verify: Verify corresponding amounts should go to the corresponding accounts in GL Entry and WIP GL Entry.
        VerifyJobWIPGLEntry(JobTask);
        VerifyGLEntry(JobTask, -JobTask."Usage (Total Cost)");
    end;

    [Test]
    [HandlerFunctions('WIPSucceededMessageHandler,ConfirmHandlerFalse')]
    [Scope('OnPrem')]
    procedure GLEntryAfterJobPostWIPToGLForPurchaseInvoicePost()
    var
        Job: Record Job;
        JobWIPMethod: Record "Job WIP Method";
        JobTask: Record "Job Task";
        PurchaseHeader: Record "Purchase Header";
    begin
        // Verify Program post correct GL Entries when Post the Job Purchase Invoice and execute the "Post WIP To GL" batch where Recognized Cost is "At Completion".

        // 1. Setup: Create Job WIP Method, Job, Job Task and Purchase Invoice with Job Task. Post the Purchase Invoice. Run "Job Calculate WIP" batch job.
        Initialize();
        CreateJobWIPMethod(
          JobWIPMethod."Recognized Costs"::"At Completion", JobWIPMethod."Recognized Sales"::"At Completion", JobWIPMethod);
        CreateJobWithWIPMethod(Job, JobWIPMethod.Code, Job."WIP Posting Method"::"Per Job");
        UpdateJobAdjustmentAccounts(Job."Job Posting Group");
        LibraryJob.CreateJobTask(Job, JobTask);
        CreatePurchaseInvoiceWithJobTask(PurchaseHeader, JobTask);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        CalculateWIP(Job);

        // 2. Exercise: Run "Job Post WIP to G/L" batch job.
        PostWIP2GL(Job);
        JobTask.CalcFields("Usage (Total Cost)");

        // 3. Verify: Verify GL Entry.
        VerifyGLEntry(JobTask, -JobTask."Usage (Total Cost)");
    end;

    [Test]
    [HandlerFunctions('WIPSucceededMessageHandler,ConfirmHandlerFalse')]
    [Scope('OnPrem')]
    procedure PostWIPToGLWithoutCalculateWIP()
    var
        Job: Record Job;
        JobWIPMethod: Record "Job WIP Method";
        JobTask: Record "Job Task";
        PurchaseHeader: Record "Purchase Header";
        CurrentWorkDate: Date;
    begin
        // Verify Program post correct GL Entries when Post the Job Purchase Invoice and execute the "Post WIP To GL" batch without "Job Calculate WIP where Recognized Cost is "At Completion".

        // 1. Setup: Create job, Job Task and Job Journal Line. Post the Job Journal Line. Run "Job Calculate WIP" and "Job Post WIP to G/L" batch job.
        Initialize();
        CreateJobWIPMethod(
          JobWIPMethod."Recognized Costs"::"At Completion", JobWIPMethod."Recognized Sales"::"At Completion", JobWIPMethod);
        CreateJobWithWIPMethod(Job, JobWIPMethod.Code, Job."WIP Posting Method"::"Per Job");
        UpdateJobAdjustmentAccounts(Job."Job Posting Group");
        LibraryJob.CreateJobTask(Job, JobTask);
        CreatePurchaseInvoiceWithJobTask(PurchaseHeader, JobTask);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        CalculateWIP(Job);
        PostWIP2GL(Job);

        // 2. Exercise: Run "Job Post WIP to G/L" batch job after changing the Workdate.
        CurrentWorkDate := WorkDate();
        WorkDate := CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'M>', CurrentWorkDate);
        PostWIP2GL(Job);

        // 3. Verify: Verify GL Entry.
        JobTask.CalcFields("Usage (Total Cost)");
        VerifyGLEntry(JobTask, JobTask."Usage (Total Cost)");

        // 4. Cleanup: Cleanup the WorkDate.
        WorkDate := CurrentWorkDate;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,JobWipEntriesHandler,JobPostWIPtoGLRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ReverseEntryPostedPerJLE()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        JobJournalLine: Record "Job Journal Line";
    begin
        // Verify that WIP entry posted per JLE can be reverted

        Initialize();
        CreateJobWithUsageLink(Job);

        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::Budget, JobPlanningLine.Type::Item, JobTask, JobPlanningLine);

        LibraryJob.CreateJobJournalLineForPlan(JobPlanningLine, JobJournalLine."Line Type"::Budget, 0.01, JobJournalLine);
        LibraryJob.PostJobJournal(JobJournalLine);

        CalculateWIP(Job);
        PostWIPToGLNoReverse(Job."No.");

        PostReverseWIPToGL(Job."No.");

        VerifyWIPGLEntryReversed(Job."No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler,JobWipEntriesHandler,JobPostWIPtoGLRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalculateAndPostWIPTwiceWithPerJobLedgerEntry()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobWIPMethod: Record "Job WIP Method";
        JobPlanningLine: Record "Job Planning Line";
    begin
        // Verify Total WIP Cost Account is 0 after running twice Calculate and Post WIP for Job with Completed Status.

        // Setup: Create Job with "WIP Posting Method" = "Per Job Ledger Entry".
        // Create Job, Job task and Job Planning, create Job Journal and post it.
        Initialize();
        CreateJobAndPostJobJournalWithJobTaskAndPlanning(
          Job, JobTask, JobPlanningLine, JobWIPMethod."Recognized Costs"::"Cost Value",
          JobWIPMethod."Recognized Sales"::"Contract (Invoiced Price)", Job."WIP Posting Method"::"Per Job Ledger Entry");

        // Exercise: Calculate and Post WIP, change Job Status to Completed, Calculate and Post WIP for Job again.
        // Verify: Total WIP Cost Account is 0.
        CalculateWIPAndVerifyGLEntriesForCompletedJob(Job, JobTask, AccountType::"WIP Costs Account");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler,JobTransferToSalesInvoiceRequestPageHandler,JobWipEntriesHandler,JobPostWIPtoGLRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalculateAndPostWIPTwiceWithPerJobLedgerEntryForSalesInvoice()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobWIPMethod: Record "Job WIP Method";
        JobPlanningLine: Record "Job Planning Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Verify Total WIP Invoiced Sales Account is 0 after running twice Calculate and Post WIP for Job with Completed Status for Sales Invoice.

        // Setup: Create Job with "WIP Posting Method" = "Per Job Ledger Entry".
        // Create Job, Job task and Job Planning, create Job Journal and post it.
        Initialize();
        CreateJobAndPostJobJournalWithJobTaskAndPlanning(
          Job, JobTask, JobPlanningLine, JobWIPMethod."Recognized Costs"::"Cost of Sales",
          JobWIPMethod."Recognized Sales"::"Contract (Invoiced Price)", Job."WIP Posting Method"::"Per Job Ledger Entry");

        // Create Job Planning Line and Post Sales Invoice created from Job Planning Line.
        JobCreateInvoice.CreateSalesInvoice(JobPlanningLine, false);
        FindSalesHeader(SalesHeader, SalesLine."Document Type"::Invoice, JobTask."Job No.", SalesLine.Type::Item);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Exercise: Calculate and Post WIP, change Job Status to Completed, Calculate and Post WIP for Job again.
        // Verify: Total WIP Invoiced Sales Account is 0.
        CalculateWIPAndVerifyGLEntriesForCompletedJob(Job, JobTask, AccountType::"WIP Invoiced Sales Account");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler,JobWipEntriesHandler,JobPostWIPtoGLRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalcWIPWithPerJobLedgerEntryPostingMethod()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobCard: TestPage "Job Card";
    begin
        // Verify "Total WIP Cost Amount" is 0 after running "Calculate WIP" for Job with Completed Status.

        // Setup: Create Job with "WIP Posting Method" = "Per Job Ledger Entry".
        // Create Job Journal and post it. Change Job Status to Completed.
        Initialize();
        CreateJobAndPostJobJournal(Job, JobTask, Job."WIP Posting Method"::"Per Job Ledger Entry");
        Job.Get(Job."No.");
        JobCard.OpenEdit();
        JobCard.GotoRecord(Job);
        JobCard.Status.SetValue(Job.Status::Completed);
        JobCard.Close();

        // Exercise: Calculate WIP for Job.
        CalculateWIP(Job);

        // Verify: Total WIP Cost Amount is 0 because Job is in Completed status.
        Job.CalcFields("Total WIP Cost Amount");
        Assert.AreEqual(0, Job."Total WIP Cost Amount", TotalWIPCostAmountErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler,JobTransferToSalesInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CopyPostedInvoiceInSalesCreditMemoWithJob()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobWIPMethod: Record "Job WIP Method";
        JobPlanningLine: Record "Job Planning Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        // Verify posted job sales invoice can be copied to sales credit memo by using the functionality

        // Setup: Create Job, Job task and Job Planning, create Job Journal and post it.
        Initialize();
        CreateJobAndPostJobJournalWithJobTaskAndPlanning(
          Job, JobTask, JobPlanningLine, JobWIPMethod."Recognized Costs"::"Cost of Sales",
          JobWIPMethod."Recognized Sales"::"Contract (Invoiced Price)", Job."WIP Posting Method"::"Per Job Ledger Entry");

        // Create Job Planning Line and Post Sales Invoice created from Job Planning Line.
        DocumentNo := CreateAndPostSalesInvoiceFromJobPlanningLine(SalesHeader, JobPlanningLine);

        // Exercise: Copy the posted invoice in the credit memo, by using the functionality - Copy Document
        // Verify: Verify no error pops up, copy document for Credit Memo successfully
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", SalesHeader."Sell-to Customer No.");
        LibrarySales.CopySalesDocument(SalesHeader, "Sales Document Type From"::"Posted Invoice", DocumentNo, true, false); // Set TRUE for Include Header and FALSE for Recalculate Lines.

        // Exercise: Post credit memo
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true); // Post as Receive and Invoice.

        // Verify: Verify Posted Credit Memo is correct
        VerifyPostedSalesCreditMemo(DocumentNo, SalesLine.Type::Item, JobPlanningLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,JobWipEntriesHandler,JobPostWIPtoGLRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalculateWIPForJobWithEmptyEndingDate()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
    begin
        // Verify that empty End Date remains with Job after Calculate WIP

        // 1. Setup: Create Job WIP Method, Job, Job Task, Job Journal Line and Post the Job Journal Line.
        Initialize();
        CreateJobAndPostJobJournal(Job, JobTask, Job."WIP Posting Method"::"Per Job");

        // 2. Exercise: Run "Job Calculate WIP" batch job.
        CalculateWIP(Job);

        // 3. Verify: Verify Job Ending Date is empty.
        Job.Get(Job."No.");
        Assert.AreEqual(0D, Job."Ending Date", EndingDateNotEmptyErr);
    end;

    local procedure CalculateWIPAndVerifyGLEntriesForCompletedJob(Job: Record Job; JobTask: Record "Job Task"; AccountType: Option)
    begin
        // Calculate and Post WIP for Job.
        CalculateWIP(Job);
        PostWIP2GL(Job);

        // Change Job Status to Completed.
        CompletedJob(Job."No.");

        // Exercise: Calculate and Post WIP for Job again.
        CalculateWIP(Job);
        PostWIP2GL(Job);

        // Verify: Total WIP Cost Account / WIP Invoiced Sales Account is 0.
        VerifyGLEntries(JobTask, AccountType);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerMultipleResponses,MessageHandler')]
    [Scope('OnPrem')]
    procedure CalcWIPUsingPOCMethod()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        JobWIPEntry: Record "Job WIP Entry";
        JobPostingGroup: Record "Job Posting Group";
    begin
        // Calculate WIP using Percentage of Completion method.

        Initialize();
        // [GIVEN] Job with WIP Method "Percentage Of Comletion"
        LibraryVariableStorage.Enqueue(true);
        CreateJobWithPOCMethod(JobTask, JobPostingGroup);
        LibraryJob.CreateJobPlanningLine(
          JobPlanningLine."Line Type"::Billable, JobPlanningLine.Type::"G/L Account", JobTask, JobPlanningLine);
        LibraryJob.CreateJobPlanningLine(
          JobPlanningLine."Line Type"::Budget, JobPlanningLine.Type::"G/L Account", JobTask, JobPlanningLine);
        // [GIVEN] Posted job ledger entries from Contract and Schedule job planning lines
        CreatePostJobJournalLineFromPlanningLine(JobPlanningLine);
        Job.Get(JobTask."Job No.");

        // [WHEN] Calculate WIP
        LibraryVariableStorage.Enqueue(false);
        CalculateWIP(Job);

        // [THEN] Appled Costs/sales and Recognized Costs/Sales Entries are generated
        JobWIPEntry.SetRange("Job No.", JobTask."Job No.");
        Assert.AreEqual(3, JobWIPEntry.Count, JobWIPEntryGLAccountErr);

        VerifyJobWIPEntryGLAccounts(
          JobTask."Job No.", JobWIPEntry.Type::"Applied Costs",
          JobPostingGroup."Job Costs Applied Account", JobPostingGroup."WIP Costs Account");
        VerifyJobWIPEntryGLAccounts(
          JobTask."Job No.", JobWIPEntry.Type::"Recognized Costs",
          JobPostingGroup."Recognized Costs Account", JobPostingGroup."WIP Costs Account");
        VerifyJobWIPEntryGLAccounts(
          JobTask."Job No.", JobWIPEntry.Type::"Recognized Sales",
          JobPostingGroup."Recognized Sales Account", JobPostingGroup."WIP Accrued Sales Account");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerMultipleResponses,MessageHandler')]
    [Scope('OnPrem')]
    procedure CalcWIPUsingPOCMethodWithInvoice()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        JobWIPEntry: Record "Job WIP Entry";
        JobPostingGroup: Record "Job Posting Group";
    begin
        // Calculate WIP using Percentage of Completion method with Sales Invoice

        Initialize();
        // [GIVEN] Job with WIP Method "Percentage Of Comletion"
        LibraryVariableStorage.Enqueue(true);
        CreateJobWithPOCMethod(JobTask, JobPostingGroup);
        LibraryJob.CreateJobPlanningLine(
          JobPlanningLine."Line Type"::Billable, JobPlanningLine.Type::"G/L Account", JobTask, JobPlanningLine);
        LibraryJob.CreateJobPlanningLine(
          JobPlanningLine."Line Type"::Budget, JobPlanningLine.Type::"G/L Account", JobTask, JobPlanningLine);
        // [GIVEN] Posted job ledger entries from Contract and Schedule job planning lines
        CreatePostJobJournalLineFromPlanningLine(JobPlanningLine);
        JobTask.SetRange("Job No.", JobTask."Job No.");
        // [GIVEN] Posted Job ledger entries with Usage and Sales
        InvoiceJobTasks(JobTask, 1);
        Job.Get(JobTask."Job No.");

        // [WHEN] Calculate WIP
        LibraryVariableStorage.Enqueue(false);
        CalculateWIP(Job);

        // [THEN] Applied Costs and Recognized Consts/Sales Entries are generated
        JobWIPEntry.SetRange("Job No.", JobTask."Job No.");
        Assert.AreEqual(4, JobWIPEntry.Count, JobWIPEntryGLAccountErr);

        VerifyJobWIPEntryGLAccounts(
          JobTask."Job No.", JobWIPEntry.Type::"Applied Costs",
          JobPostingGroup."Job Costs Applied Account", JobPostingGroup."WIP Costs Account");
        VerifyJobWIPEntryGLAccounts(
          JobTask."Job No.", JobWIPEntry.Type::"Applied Sales",
          JobPostingGroup."Job Sales Applied Account", JobPostingGroup."WIP Invoiced Sales Account");
        VerifyJobWIPEntryGLAccounts(
          JobTask."Job No.", JobWIPEntry.Type::"Recognized Costs",
          JobPostingGroup."Recognized Costs Account", JobPostingGroup."WIP Costs Account");
        VerifyJobWIPEntryGLAccounts(
          JobTask."Job No.", JobWIPEntry.Type::"Recognized Sales",
          JobPostingGroup."Recognized Sales Account", JobPostingGroup."WIP Accrued Sales Account");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse')]
    [Scope('OnPrem')]
    procedure UT_AppliedSalesAmountInvoicedLessThanRecognizedWithPOC()
    var
        Job: Record Job;
        JobWIPEntry: Record "Job WIP Entry";
        InvoicedAmount: Decimal;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 377533] Applied Sales Amount should be equal "Sales Invoiced Amount" if invoiced amount less than recognized amount when using Percentage of Completion

        // [GIVEN] Job with WIP Posting Method = Percentage of Completion
        // [GIVEN] "Recognized Sales" = 100, "Invoiced Amount" = 80
        Initialize();
        SalesAppliedWithPOCScenario(Job, InvoicedAmount, 1 / LibraryRandom.RandIntInRange(3, 10));

        // [WHEN] Calc WIP
        CalculateWIP(Job);

        // [THEN] Job Ledger Entry with "Applied Sales" has amount 80
        VerifyJobWIPEntryByType(Job."No.", JobWIPEntry.Type::"Applied Sales", InvoicedAmount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse')]
    [Scope('OnPrem')]
    procedure UT_AppliedSalesAmountInvoicedMoreThanRecognizedWithPOC()
    var
        Job: Record Job;
        JobWIPEntry: Record "Job WIP Entry";
        InvoicedAmount: Decimal;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 377533] Applied Sales Amount should be equal "Sales Invoiced Amount" if invoiced amount more than recognized amount when using Percentage of Completion

        // [GIVEN] Job with WIP Posting Method = Percentage of Completion
        // [GIVEN] "Recognized Sales" = 100, "Invoiced Amount" = 120
        Initialize();
        SalesAppliedWithPOCScenario(Job, InvoicedAmount, 1 * LibraryRandom.RandIntInRange(3, 10));

        // [WHEN] Calc WIP
        CalculateWIP(Job);

        // [THEN] Job Ledger Entry with "Applied Sales" has amount 120
        VerifyJobWIPEntryByType(Job."No.", JobWIPEntry.Type::"Applied Sales", InvoicedAmount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse')]
    [Scope('OnPrem')]
    procedure UT_AppliedSalesAmountInvoicedEqualRecognizedWithPOC()
    var
        Job: Record Job;
        JobWIPEntry: Record "Job WIP Entry";
        InvoicedAmount: Decimal;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 377533] Applied Sales Amount should be equal "Sales Invoiced Amount" if invoiced amount equal recognized amount when using Percentage of Completion

        // [GIVEN] Job with WIP Posting Method = Percentage of Completion
        // [GIVEN] "Recognized Sales" = 100, "Invoiced Amount" = 100
        Initialize();
        SalesAppliedWithPOCScenario(Job, InvoicedAmount, 1);

        // [WHEN] Calc WIP
        CalculateWIP(Job);

        // [THEN] Job Ledger Entry with "Applied Sales" has amount 100
        VerifyJobWIPEntryByType(Job."No.", JobWIPEntry.Type::"Applied Sales", InvoicedAmount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse')]
    [Scope('OnPrem')]
    procedure UT_AppliedSalesAmountZeroInvoicedWithPOC()
    var
        Job: Record Job;
        JobWIPEntry: Record "Job WIP Entry";
        InvoicedAmount: Decimal;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 377533] Applied Sales Amount should not be posted if invoiced amount zero when using Percentage of Completion

        // [GIVEN] Job with WIP Posting Method = Percentage of Completion
        // [GIVEN] "Recognized Sales" = 100, "Invoiced Amount" = 0
        Initialize();
        SalesAppliedWithPOCScenario(Job, InvoicedAmount, 0);

        // [WHEN] Calc WIP
        CalculateWIP(Job);

        // [THEN] Job Ledger Entry with "Applied Sales" does not exist
        VerifyJobWIPEntryDoesNotExist(Job."No.", JobWIPEntry.Type::"Applied Sales");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TargetCalcAmountsAfterCopyTask()
    var
        Job: Record Job;
        TargetJob: Record Job;
        JobTask: Record "Job Task";
        TargetJobTask: Record "Job Task";
        CopyJob: Codeunit "Copy Job";
    begin
        // [SCENARIO 379671] Recognized Sales/Costs fields are not copied to target Job Task when copy Job
        Initialize();

        // [GIVEN] Job "J1" with job task line where "Recognized Sales Amount" = 10, "Recognized Costs Amount" = 20,
        // [GIVEN] "Recognized Sales G/L Amount" = 30, "Recognized Costs G/L Amount" = 40
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        JobTask.Validate("Recognized Sales Amount", LibraryRandom.RandDec(10, 2));
        JobTask.Validate("Recognized Costs Amount", LibraryRandom.RandDec(10, 2));
        JobTask.Validate("Recognized Sales G/L Amount", LibraryRandom.RandDec(10, 2));
        JobTask.Validate("Recognized Costs G/L Amount", LibraryRandom.RandDec(10, 2));
        JobTask.Modify(true);

        // [WHEN] Copy job task line to newly created job "J2"
        LibraryJob.CreateJob(TargetJob);
        CopyJob.CopyJobTasks(Job, TargetJob);

        // [THEN] "Recognized Sales Amount" = 0, "Recognized Costs Amount" = 0, "Recognized Sales G/L Amount" = 0,
        // [THEN] "Recognized Costs G/L Amount" = 0 in job task line of "J2"
        TargetJobTask.Get(TargetJob."No.", JobTask."Job Task No.");
        TargetJobTask.TestField("Recognized Sales Amount", 0);
        TargetJobTask.TestField("Recognized Costs Amount", 0);
        TargetJobTask.TestField("Recognized Sales G/L Amount", 0);
        TargetJobTask.TestField("Recognized Costs G/L Amount", 0);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure NoWIPWhenPostSameAmountWithDiffSignAndSeparateJobTasks()
    var
        JobWIPMethod: Record "Job WIP Method";
        Job: Record Job;
        JobTask: array[2] of Record "Job Task";
        JobWIPEntry: Record "Job WIP Entry";
        CostAmount: Decimal;
    begin
        // [SCENARIO 380439] No WIP calculated if there are two Job Ledger Entries with different Job Tasks, same amount but different sign.

        Initialize();

        // [GIVEN] Job two job tasks and WIP Method = "Cost Value"
        CreateJobWIPMethod(
          JobWIPMethod."Recognized Costs"::"Cost Value", JobWIPMethod."Recognized Sales"::"At Completion", JobWIPMethod);
        CreateJobWithWIPMethod(Job, JobWIPMethod.Code, Job."WIP Posting Method"::"Per Job");
        LibraryJob.CreateJobTask(Job, JobTask[1]);
        LibraryJob.CreateJobTask(Job, JobTask[2]);

        // [GIVEN] Posted Job Ledger with Amount = 100 for Job Task "JT1"
        // [GIVEN] Posted Job Ledger with Amount = -100 for Job Task "JT2"
        CostAmount := LibraryRandom.RandDec(100, 2);
        PostJobJournallineWithCustomAmount(JobTask[1], CostAmount);
        PostJobJournallineWithCustomAmount(JobTask[2], -CostAmount);

        // [WHEN] Calculate WIP
        CalculateWIP(Job);

        // [THEN] No WIP entries generated
        VerifyJobWIPEntryDoesNotExist(Job."No.", JobWIPEntry.Type::"Applied Costs");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerMultipleResponses,MessageHandler')]
    [Scope('OnPrem')]
    procedure WIPCostValueForMultipleJobLedgerEntriesWithDiffSignAndSeparateJobTasks()
    var
        JobWIPMethod: Record "Job WIP Method";
        Job: Record Job;
        JobTask: array[3] of Record "Job Task";
        JobWIPEntry: Record "Job WIP Entry";
        CostAmount: Decimal;
        ResultedCostAmount: Decimal;
        i: Integer;
    begin
        // [SCENARIO 380613] WIP Amount of "Cost Value" type calculates correctly when multiple Job Ledger Entries with different sign and separate job tasks are posted

        Initialize();
        // [GIVEN] Job two job tasks and WIP Method = "Cost Value"
        CreateJobWIPMethod(
          JobWIPMethod."Recognized Costs"::"Cost Value", JobWIPMethod."Recognized Sales"::"At Completion", JobWIPMethod);
        CreateJobWithWIPMethod(Job, JobWIPMethod.Code, Job."WIP Posting Method"::"Per Job");
        LibraryJob.CreateJobTask(Job, JobTask[1]);
        LibraryJob.CreateJobTask(Job, JobTask[2]);
        LibraryJob.CreateJobTask(Job, JobTask[3]);

        // [GIVEN] Posted Job Ledger with Amount = 100 for Job Task "JT1"
        // [GIVEN] Posted Job Ledger with Amount = -100 for Job Task "JT2"
        // [GIVEN] Posted Job Ledger with Amount = 50 for Job Task "JT3"
        for i := 1 to 6 do // twice for each Job Journal Line
            LibraryVariableStorage.Enqueue(true); // Used for ConfirmHandlerMultipleResponses
        CostAmount := LibraryRandom.RandDec(100, 2);
        PostJobJournallineWithCustomAmount(JobTask[1], CostAmount);
        PostJobJournallineWithCustomAmount(JobTask[2], -CostAmount);
        ResultedCostAmount := LibraryRandom.RandDec(100, 2);
        PostJobJournallineWithCustomAmount(JobTask[3], ResultedCostAmount);
        LibraryVariableStorage.Enqueue(false);

        // [WHEN] Calculate WIP
        CalculateWIP(Job);

        // [THEN] WIP amount is -50
        VerifyJobWIPEntryByType(Job."No.", JobWIPEntry.Type::"Applied Costs", -ResultedCostAmount);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure EndingDateIsPopulatedOnStatusCompleted()
    var
        Job: Record Job;
    begin
        // [SCENARIO 213505] Job Ending Date is populated with a value when Job Status is set to Completed.
        Initialize();

        // [GIVEN] "Job" with WIP Method and Job Task.
        PrepareJobWithJobTaskWithWIP(Job);

        // [WHEN] "Job" Status changed to Completed
        Job.Validate(Status, Job.Status::Completed);
        Job.Modify(true);

        // [THEN] "Job" Ending Date is populated with WORKDATE
        Assert.AreEqual(WorkDate(), Job."Ending Date", 'Job Ending Date should not be empty.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobCalcWIPNotExecutedWhenJobWithoutWIPMethodIsCompleted()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobWIPEntry: Record "Job WIP Entry";
        JobWIPGLEntry: Record "Job WIP G/L Entry";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 218286] When Job has no WIP Method, "Job Calculate WIP" report is not called and no confirmations invoked.
        Initialize();

        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        Job.Validate("WIP Method", '');
        Job.Modify(true);

        Job.RecalculateJobWIP();

        JobWIPEntry.SetRange("Job No.", Job."No.");
        Assert.RecordIsEmpty(JobWIPEntry);

        JobWIPGLEntry.SetRange("Job No.", Job."No.");
        Assert.RecordIsEmpty(JobWIPGLEntry);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler,JobWipEntriesHandler,JobPostWIPtoGLRequestPageHandler')]
    [Scope('OnPrem')]
    procedure JobCalcWIPExecutedWhenJobWithWIPMethodIsCompleted()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobWIPMethod: Record "Job WIP Method";
        JobPlanningLine: Record "Job Planning Line";
        JobWIPGLEntry: Record "Job WIP G/L Entry";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 218286] When Job has WIP Method, Job WIP lines are calculated and posted.
        Initialize();

        CreateJobAndPostJobJournalWithJobTaskAndPlanning(
          Job, JobTask, JobPlanningLine, JobWIPMethod."Recognized Costs"::"Cost Value",
          JobWIPMethod."Recognized Sales"::"Percentage of Completion", Job."WIP Posting Method"::"Per Job");

        Job.RecalculateJobWIP();

        JobWIPGLEntry.SetRange("Job No.", Job."No.");
        Assert.RecordIsNotEmpty(JobWIPGLEntry);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse')]
    [Scope('OnPrem')]
    procedure CalcWIPWhenUsageAndSalesSplitBetweenJobTasks()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPostingGroup: Record "Job Posting Group";
        JobWIPMethod: Record "Job WIP Method";
        JobPlanningLine: Record "Job Planning Line";
        JobLedgerEntry: Record "Job Ledger Entry";
        JobWIPEntry: Record "Job WIP Entry";
    begin
        // [SCENARIO 368853] WIP Entries generate correctly when usage and sales are splitted between multiple job tasks

        Initialize();

        // [GIVEN] Job with "WIP Method" = "Cost of Sales" for recognized costs and "Contract (Invoiced Price)" for recognized sales
        CreateJobWIPMethod(
          JobWIPMethod."Recognized Costs"::"Cost of Sales", JobWIPMethod."Recognized Sales"::"Contract (Invoiced Price)", JobWIPMethod);
        CreateJobWithWIPMethod(Job, JobWIPMethod.Code, Job."WIP Posting Method"::"Per Job");
        CreateJobPostingGroup(JobPostingGroup);
        UpdateJobPostingGroup(JobPostingGroup);
        Job.Validate("Job Posting Group", JobPostingGroup.Code);
        Job.Modify(true);

        // [GIVEN] First job task has budget planning line with amount 100 and usage job ledger entry with amount 80
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::Budget, JobPlanningLine.Type::Item, JobTask, JobPlanningLine);
        JobPlanningLine.Validate(Quantity, 100);
        JobPlanningLine.Validate("Total Cost (LCY)", 100);
        JobPlanningLine.Modify(true);
        CreateMockJobLedgerEntry(JobPlanningLine, 0.8, JobLedgerEntry);

        // [GIVEN] Second job task has budget planning line with amount -3 and usage job ledger entry with the same amount
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::Budget, JobPlanningLine.Type::Item, JobTask, JobPlanningLine);
        JobPlanningLine.Validate(Quantity, -1);
        JobPlanningLine.Validate("Total Cost (LCY)", -3);
        JobPlanningLine.Modify(true);
        CreateMockJobLedgerEntry(JobPlanningLine, 1, JobLedgerEntry);

        // [GIVEN] Second job task has billable planning line with amount 200 and sales job ledger entry with the same amount
        LibraryJob.CreateJobTask(Job, JobTask);
        CreateJobTaskWIPTotal(JobTask, Job, JobTask."Job Task Type"::Posting);
        LibraryJob.CreateJobPlanningLine(
          JobPlanningLine."Line Type"::Billable, JobPlanningLine.Type::"G/L Account", JobTask, JobPlanningLine);
        JobPlanningLine.Validate(Quantity, 1);
        JobPlanningLine.Validate("Line Amount (LCY)", 200);
        JobPlanningLine.Validate("Total Price (LCY)", 200);
        JobPlanningLine.Modify(true);
        CreateMockJobLedgerEntry(JobPlanningLine, 1, JobLedgerEntry);

        // [WHEN] Calculate WIP
        CalculateWIP(Job);

        // [THEN] Five WIP Entries have been generated
        JobWIPEntry.SetRange("Job No.", Job."No.");
        Assert.RecordCount(JobWIPEntry, 5);

        // [THEN] A WIP Entry with type "Applied Costs" and Amount equals -97
        VerifyJobWIPEntryByType(Job."No.", JobWIPEntry.Type::"Applied Costs", -97);

        // [THEN] A WIP Entry with type "Applied Sales" and Amount equals 200
        VerifyJobWIPEntryByType(Job."No.", JobWIPEntry.Type::"Applied Sales", 200);

        // [THEN] A WIP Entry with type "Recognized Costs" and Amount equals 97
        VerifyJobWIPEntryByType(Job."No.", JobWIPEntry.Type::"Recognized Costs", 97);

        // [THEN] A WIP Entry with type "Recognized Sales" and Amount equals -200
        VerifyJobWIPEntryByType(Job."No.", JobWIPEntry.Type::"Recognized Sales", -200);

        // [THEN] A WIP Entry with type "Accrued Costs" and Amount equals 20
        VerifyJobWIPEntryByType(Job."No.", JobWIPEntry.Type::"Accrued Costs", 20);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse')]
    [Scope('OnPrem')]
    procedure CalcWIPWhenUsageAndSalesSplitBetweenJobTasksOnlyAppliedCosts()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPostingGroup: Record "Job Posting Group";
        JobWIPMethod: Record "Job WIP Method";
        JobPlanningLine: Record "Job Planning Line";
        JobLedgerEntry: Record "Job Ledger Entry";
        JobWIPEntry: Record "Job WIP Entry";
    begin
        // [SCENARIO 376235] WIP Entries generate correctly when usage and sales are splitted between multiple job tasks with only applied cost

        Initialize();

        // [GIVEN] Job with "WIP Method" = "Cost of Sales" for recognized costs and "Contract (Invoiced Price)" for recognized sales
        CreateJobWIPMethod(
          JobWIPMethod."Recognized Costs"::"Cost of Sales", JobWIPMethod."Recognized Sales"::"Contract (Invoiced Price)", JobWIPMethod);
        CreateJobWithWIPMethod(Job, JobWIPMethod.Code, Job."WIP Posting Method"::"Per Job");
        CreateJobPostingGroup(JobPostingGroup);
        UpdateJobPostingGroup(JobPostingGroup);
        Job.Validate("Job Posting Group", JobPostingGroup.Code);
        Job.Modify(true);

        // [GIVEN] First job task has budget planning line with amount "X"
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::Budget, JobPlanningLine.Type::Item, JobTask, JobPlanningLine);
        JobPlanningLine.Validate(Quantity, LibraryRandom.RandInt(100));
        JobPlanningLine.Validate("Total Cost (LCY)", LibraryRandom.RandInt(100));
        JobPlanningLine.Modify(true);

        // [GIVEN] Second job task has budget planning line with amount -"Y" and usage job ledger entry with the same amount
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::Budget, JobPlanningLine.Type::Item, JobTask, JobPlanningLine);
        JobPlanningLine.Validate(Quantity, -1);
        JobPlanningLine.Validate("Total Cost (LCY)", -LibraryRandom.RandInt(10));
        JobPlanningLine.Modify(true);
        CreateMockJobLedgerEntry(JobPlanningLine, 1, JobLedgerEntry);

        // [WHEN] Calculate WIP
        CalculateWIP(Job);

        // [THEN] One WIP Entry has been generated
        JobWIPEntry.SetRange("Job No.", Job."No.");
        Assert.RecordCount(JobWIPEntry, 1);
        JobWIPEntry.FindFirst();

        // [THEN] A WIP Entry with type "Applied Costs" and Amount equals "Y"
        VerifyJobWIPEntryByType(Job."No.", JobWIPEntry.Type::"Applied Costs", -JobPlanningLine."Total Cost (LCY)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalculateWIPWithErrorMessage()
    var
        Job: Record Job;
        JobWIPMethod: Record "Job WIP Method";
        JobTask: Record "Job Task";
        PurchaseHeader: Record "Purchase Header";
        JobPostingGroup: Record "Job Posting Group";
        TempErrorMessage: Record "Error Message" temporary;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 391482] Error messages page opened while calculating Job WIP if posting setup has empty accounts

        // [GIVEN] Create Job WIP Method, Job, Job Task and Purchase Invoice with Job Task. Post the Purchase Invoice. 
        Initialize();
        CreateJobWIPMethod(
          JobWIPMethod."Recognized Costs"::"At Completion", JobWIPMethod."Recognized Sales"::"At Completion", JobWIPMethod);
        CreateJobWithWIPMethod(Job, JobWIPMethod.Code, Job."WIP Posting Method"::"Per Job");
        CreateJobPostingGroupEmptyAccounts(JobPostingGroup);
        Job.Validate("Job Posting Group", JobPostingGroup.Code);
        Job.Modify();
        LibraryJob.CreateJobTask(Job, JobTask);
        CreatePurchaseInvoiceWithJobTask(PurchaseHeader, JobTask);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [WHEN] Run "Job Calculate WIP" batch job
        LibraryErrorMessage.TrapErrorMessages();
        asserterror CalculateWIP(Job);

        // [THEN] Error messages page opened with error "Job Cost Applied Account is missing in Job Posting Setup." 
        LibraryErrorMessage.GetErrorMessages(TempErrorMessage);
        TempErrorMessage.FindFirst();
        TempErrorMessage.TestField(
            "Message",
            LibraryErrorMessage.GetMissingAccountErrorMessage(
                JobPostingGroup.FieldCaption("Job Costs Applied Account"),
                JobPostingGroup));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse')]
    [Scope('OnPrem')]
    procedure CalcWIPWhenWIPTotalNotAssignedToLastTask()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPostingGroup: Record "Job Posting Group";
        JobWIPMethod: Record "Job WIP Method";
        JobPlanningLine: Record "Job Planning Line";
        JobLedgerEntry: Record "Job Ledger Entry";
        JobWIPEntry: Record "Job WIP Entry";
        TotalCost: Decimal;
    begin
        // [SCENARIO 368853] WIP Entries generate correctly when "WIP-Total" is not assigned to the last task

        Initialize();

        // [GIVEN] Job with "WIP Method" = "Cost Value" for recognized costs
        CreateJobWIPMethod(
          JobWIPMethod."Recognized Costs"::"Cost Value", JobWIPMethod."Recognized Sales"::"Contract (Invoiced Price)", JobWIPMethod);
        CreateJobWithWIPMethod(Job, JobWIPMethod.Code, Job."WIP Posting Method"::"Per Job");
        CreateJobPostingGroup(JobPostingGroup);
        UpdateJobPostingGroup(JobPostingGroup);
        Job.Validate("Job Posting Group", JobPostingGroup.Code);
        Job.Modify(true);

        // [GIVEN] First job task with "WIP-Total" = Total and amount 100
        LibraryJob.CreateJobTask(Job, JobTask);
        JobTask.Validate("WIP-Total", JobTask."WIP-Total"::Total);
        JobTask.Validate("WIP Method", Job."WIP Method");
        JobTask.Modify(true);
        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::Budget, JobPlanningLine.Type::Item, JobTask, JobPlanningLine);
        JobPlanningLine.Validate(Quantity, 1);
        JobPlanningLine.Validate("Total Cost (LCY)", LibraryRandom.RandDec(100, 2));
        JobPlanningLine.Modify(true);
        CreateMockJobLedgerEntry(JobPlanningLine, 1, JobLedgerEntry);
        TotalCost += JobPlanningLine."Total Cost (LCY)";

        // [GIVEN] Second job task with blank "WIP-Total" and amount 200
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::Budget, JobPlanningLine.Type::Item, JobTask, JobPlanningLine);
        JobPlanningLine.Validate(Quantity, 1);
        JobPlanningLine.Validate("Total Cost (LCY)", LibraryRandom.RandDec(100, 2));
        JobPlanningLine.Modify(true);
        CreateMockJobLedgerEntry(JobPlanningLine, 1, JobLedgerEntry);
        TotalCost += JobPlanningLine."Total Cost (LCY)";

        // [WHEN] Calculate WIP
        CalculateWIP(Job);

        // [THEN] A WIP Entry with type "Applied Costs" and Amount equals 300
        VerifyJobWIPEntryByType(Job."No.", JobWIPEntry.Type::"Applied Costs", -TotalCost);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        JobBatchJobs: Codeunit "Job Batch Jobs";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Job Performance WIP");
        LibraryVariableStorage.Clear();
        LibraryRandom.SetSeed(1);
        LibrarySetupStorage.Restore();
        if Initialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Job Performance WIP");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        JobBatchJobs.SetJobNoSeries(JobsSetup, NoSeries);

        Initialized := true;
        Commit();

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");

        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Job Performance WIP");
    end;

    local procedure WIPScenario(ScheduleAmount: Decimal; UsageAmount: Decimal; ContractAmount: Decimal; InvoicedAmount: Decimal; JobWIPMethod: Record "Job WIP Method")
    var
        Job: Record Job;
        JobTask: Record "Job Task";
    begin
        // Create and execute a job with ScheduleAmount, UsageAmount, ContractAmount, and InvoiceAmount.
        // Calculate and post WIP using JobWIPMethod.
        // Verify WIP specific fields on the job and job tasks.
        // Verify the change in balance of involved GL accounts.

        // Setup: create job
        CreateJobWithWIPMethod(Job, JobWIPMethod.Code, Job."WIP Posting Method"::"Per Job");
        UpdateJobAdjustmentAccounts(Job."Job Posting Group");

        // Setup: create job schedule
        LibraryJob.CreateJobTask(Job, JobTask);
        PlanJobTask(JobTask, ScheduleAmount, ContractAmount, LibraryJob.ResourceType());

        // totaling task
        CreateJobTaskWIPTotal(JobTask, Job, JobTask."Job Task Type"::Total);

        // Setup: execute job
        FilterJobTaskByType(JobTask, Job."No.");
        UseJobTasks(JobTask, UsageAmount / ScheduleAmount);
        InvoiceJobTasks(JobTask, InvoicedAmount / ContractAmount);

        // Exercise: calculate WIP
        CalculateWIP(Job);

        // Verify: define expected impact of WIP on GL
        DefineWIPImpactOnGL(Job);

        // Exercise: post WIP to GL
        PostWIP2GL(Job);
        Job.Get(Job."No.");
        // Verify: WIP fields on job, job task
        VerifyJobWIP(Job, JobWIPMethod);

        // Verify: WIP impact on GL
        DeltaAssert.Assert();
    end;

    local procedure SalesAppliedWithPOCScenario(var Job: Record Job; var InvoicedAmount: Decimal; Factor: Decimal)
    var
        JobWIPMethod: Record "Job WIP Method";
        JobTask: Record "Job Task";
        ScheduleCostAmount: Decimal;
        ContractPriceAmount: Decimal;
        UsedCostAmount: Decimal;
        CostFactor: Decimal;
    begin
        CreateJobWIPMethod(
          JobWIPMethod."Recognized Costs"::"Cost of Sales", JobWIPMethod."Recognized Sales"::"Percentage of Completion", JobWIPMethod);
        CreateJobWithWIPMethod(Job, JobWIPMethod.Code, Job."WIP Posting Method"::"Per Job");
        UpdateJobAdjustmentAccounts(Job."Job Posting Group");
        CreateJobTaskWIPTotal(JobTask, Job, JobTask."Job Task Type"::Posting);

        ScheduleCostAmount := LibraryRandom.RandDec(100, 2);
        ContractPriceAmount := LibraryRandom.RandDec(100, 2);
        UsedCostAmount := ScheduleCostAmount / LibraryRandom.RandIntInRange(3, 10);
        CostFactor := UsedCostAmount / ScheduleCostAmount;
        InvoicedAmount :=
          Round(CostFactor * ContractPriceAmount * Factor, LibraryERM.GetAmountRoundingPrecision());
        PlanJobTaskWithPrice(JobTask, ScheduleCostAmount, 0, 0, ContractPriceAmount, LibraryJob.ResourceType());

        FilterJobTaskByType(JobTask, Job."No.");
        UseJobTasks(JobTask, CostFactor);
        InvoiceJobTasks(JobTask, CostFactor * Factor);
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        exit(GLAccount."No.");
    end;

    local procedure CreateJobJournalLine(JobTask: Record "Job Task"; var JobJournalLine: Record "Job Journal Line")
    begin
        LibraryJob.CreateJobJournalLineForType(LibraryJob.PlanningLineTypeSchedule(), LibraryJob.ResourceType(), JobTask, JobJournalLine);
        JobJournalLine.Validate("Unit Cost", LibraryRandom.RandInt(10));  // Taking Radom as value is not important.
        JobJournalLine.Modify(true);
    end;

    local procedure CreateJobWIPMethod(CostsRecognition: Enum "Job WIP Recognized Costs Type"; SalesRecognition: Enum "Job WIP Recognized Sales Type"; var JobWIPMethod: Record "Job WIP Method")
    begin
        Clear(JobWIPMethod);
        JobWIPMethod.SetFilter(Code, Prefix + '*');
        if JobWIPMethod.FindLast() then
            JobWIPMethod.Code := IncStr(JobWIPMethod.Code)
        else
            JobWIPMethod.Validate(Code, Prefix + 'JWM001');

        JobWIPMethod.Validate("Recognized Costs", CostsRecognition);
        JobWIPMethod.Validate("Recognized Sales", SalesRecognition);
        JobWIPMethod.Insert(true)
    end;

    local procedure CreateJobWithPOCMethod(var JobTask: Record "Job Task"; var JobPostingGroup: Record "Job Posting Group")
    var
        Job: Record Job;
        JobWIPMethod: Record "Job WIP Method";
    begin
        CreateJobWIPMethod(
          JobWIPMethod."Recognized Costs"::"Usage (Total Cost)",
          JobWIPMethod."Recognized Sales"::"Percentage of Completion", JobWIPMethod);
        CreateJobWithWIPMethod(Job, JobWIPMethod.Code, Job."WIP Posting Method"::"Per Job");
        CreateJobPostingGroup(JobPostingGroup);
        UpdateJobPostingGroup(JobPostingGroup);
        Job.Validate("Job Posting Group", JobPostingGroup.Code);
        Job.Modify(true);
        LibraryJob.CreateJobTask(Job, JobTask);
    end;

    local procedure CreateJobWithWIPMethod(var Job: Record Job; WIPMethod: Code[20]; WIPPostingMethod: Option)
    begin
        LibraryJob.CreateJob(Job);
        Job.Validate("WIP Method", WIPMethod);
        Job.Validate("WIP Posting Method", WIPPostingMethod);
        Job.Modify(true);
    end;

    local procedure CreateJobWithUsageLink(var Job: Record Job)
    var
        JobWIPMethod: Record "Job WIP Method";
    begin
        CreateJobWIPMethod(
          JobWIPMethod."Recognized Costs"::"Cost of Sales", JobWIPMethod."Recognized Sales"::"Contract (Invoiced Price)", JobWIPMethod);
        CreateJobWithWIPMethod(Job, JobWIPMethod.Code, Job."WIP Posting Method"::"Per Job Ledger Entry");
        UpdateItemCostAccountInJobPostingGroup(Job."Job Posting Group");
        Job.Validate(Status, Job.Status::Open);
        Job.Validate("Apply Usage Link", true);
        Job.Modify(true);
    end;

    local procedure CreateJobTaskWIPTotal(var JobTask: Record "Job Task"; Job: Record Job; JobTaskType: Enum "Job Task Type")
    begin
        LibraryJob.CreateJobTask(Job, JobTask);
        JobTask.Validate("Job Task Type", JobTaskType);
        JobTask.Validate("WIP-Total", JobTask."WIP-Total"::Total);
        JobTask.Modify(true);
    end;

    local procedure CreatePurchaseInvoiceWithJobTask(var PurchaseHeader: Record "Purchase Header"; JobTask: Record "Job Task")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithPurchSetup(), LibraryRandom.RandInt(10));  // Used Random value for Quantity.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(100));  // Used Random value for Direct Unit Cost.
        PurchaseLine.Validate("Job No.", JobTask."Job No.");
        PurchaseLine.Validate("Job Task No.", JobTask."Job Task No.");
        PurchaseLine.Validate("Job Line Type", PurchaseLine."Job Line Type"::Billable);
        PurchaseLine.Modify(true)
    end;

    local procedure CreatePostJobJournalLineFromPlanningLine(JobPlanningLine: Record "Job Planning Line")
    var
        JobTask: Record "Job Task";
        JobJournalLine: Record "Job Journal Line";
    begin
        JobTask.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.");
        LibraryJob.CreateJobJournalLine(JobJournalLine."Line Type", JobTask, JobJournalLine);
        JobJournalLine.Validate(Type, JobJournalLine.Type::"G/L Account");
        JobJournalLine.Validate("No.", JobPlanningLine."No.");
        JobJournalLine.Validate(Quantity, JobPlanningLine.Quantity);
        JobJournalLine.Validate("Unit Cost", JobPlanningLine."Unit Cost");
        JobJournalLine.Modify(true);
        LibraryJob.PostJobJournal(JobJournalLine);
    end;

    local procedure CreateJobAndPostJobJournalWithJobTaskAndPlanning(var Job: Record Job; var JobTask: Record "Job Task"; var JobPlanningLine: Record "Job Planning Line"; CostsRecognition: Enum "Job WIP Recognized Costs Type"; SalesRecognition: Enum "Job WIP Recognized Sales Type"; WIPPostingMethod: Option)
    var
        JobJournalLine: Record "Job Journal Line";
        JobWIPMethod: Record "Job WIP Method";
        JobPostingGroup: Record "Job Posting Group";
    begin
        CreateJobWIPMethod(CostsRecognition, SalesRecognition, JobWIPMethod);
        CreateJobWithWIPMethod(Job, JobWIPMethod.Code, WIPPostingMethod);
        CreateJobPostingGroup(JobPostingGroup);
        UpdateJobPostingGroup(JobPostingGroup);
        Job.Validate("Job Posting Group", JobPostingGroup.Code);
        Job.Modify(true);
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::Billable, JobPlanningLine.Type::Item, JobTask, JobPlanningLine);
        CreateJobJournalLine(JobTask, JobJournalLine);
        LibraryJob.PostJobJournal(JobJournalLine);
    end;

    local procedure CreateJobAndPostJobJournal(var Job: Record Job; var JobTask: Record "Job Task"; WIPPostingMethod: Option)
    var
        JobJournalLine: Record "Job Journal Line";
        JobWIPMethod: Record "Job WIP Method";
    begin
        CreateJobWIPMethod(
          JobWIPMethod."Recognized Costs"::"At Completion", JobWIPMethod."Recognized Sales"::"At Completion", JobWIPMethod);
        CreateJobWithWIPMethod(Job, JobWIPMethod.Code, WIPPostingMethod);
        LibraryJob.CreateJobTask(Job, JobTask);
        CreateJobJournalLine(JobTask, JobJournalLine);
        LibraryJob.PostJobJournal(JobJournalLine);
    end;

    local procedure PostJobJournallineWithCustomAmount(JobTask: Record "Job Task"; Amount: Decimal)
    var
        JobJournalLine: Record "Job Journal Line";
    begin
        LibraryJob.CreateJobJournalLineForType(LibraryJob.PlanningLineTypeSchedule(), LibraryJob.ResourceType(), JobTask, JobJournalLine);
        JobJournalLine.Validate(Quantity, 1);
        JobJournalLine.Validate("Unit Cost", Amount);
        JobJournalLine.Modify(true);
        LibraryJob.PostJobJournal(JobJournalLine);
    end;

    local procedure CreateJobWIPAndJobTask(var Job: Record Job; var JobWIPMethod: Record "Job WIP Method"; var JobPlanningLine: Record "Job Planning Line"; var JobTask: Record "Job Task"; ScheduleAmount: Decimal; ContractAmount: Decimal)
    begin
        CreateJobWIPMethod(
          JobWIPMethod."Recognized Costs"::"At Completion", JobWIPMethod."Recognized Sales"::"Contract (Invoiced Price)", JobWIPMethod);
        CreateJobWithWIPMethod(Job, JobWIPMethod.Code, Job."WIP Posting Method"::"Per Job Ledger Entry");

        // Setup: plan job task
        LibraryJob.CreateJobTask(Job, JobTask);
        ScheduleJobTask(JobTask, ScheduleAmount, LibraryJob.ResourceType(), JobPlanningLine);
        ContractJobTask(JobTask, ContractAmount, LibraryJob.ResourceType(), JobPlanningLine);
    end;

    local procedure PlanJobTask(JobTask: Record "Job Task"; ScheduleAmount: Decimal; ContractAmount: Decimal; Type: Enum "Job Planning Line Type")
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        ScheduleJobTask(JobTask, ScheduleAmount, Type, JobPlanningLine);
        ContractJobTask(JobTask, ContractAmount, Type, JobPlanningLine)
    end;

    local procedure ScheduleJobTask(JobTask: Record "Job Task"; ScheduleAmount: Decimal; ConsumableType: Enum "Job Planning Line Type"; var JobPlanningLine: Record "Job Planning Line")
    begin
        // schedule
        LibraryJob.CreateJobPlanningLine(LibraryJob.PlanningLineTypeSchedule(), ConsumableType, JobTask, JobPlanningLine);
        JobPlanningLine."Total Cost (LCY)" := ScheduleAmount;
        JobPlanningLine."Line Amount (LCY)" := 1.1 * ScheduleAmount;
        JobPlanningLine.Modify();
    end;

    local procedure ContractJobTask(JobTask: Record "Job Task"; ContractAmount: Decimal; ConsumableType: Enum "Job Planning Line Type"; var JobPlanningLine: Record "Job Planning Line")
    begin
        // contract
        LibraryJob.CreateJobPlanningLine(LibraryJob.PlanningLineTypeContract(), ConsumableType, JobTask, JobPlanningLine);
        JobPlanningLine."Total Cost (LCY)" := 0.8 * ContractAmount;
        JobPlanningLine."Line Amount (LCY)" := ContractAmount;
        JobPlanningLine.Modify();
    end;

    local procedure PlanJobTaskWithPrice(JobTask: Record "Job Task"; ScheduleCostAmount: Decimal; SchedulePriceAmount: Decimal; ContractCostAmount: Decimal; ContractPriceAmount: Decimal; ConsumableType: Enum "Job Planning Line Type")
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        CreateJobPlanningLineWithPrice(
          JobPlanningLine, LibraryJob.PlanningLineTypeSchedule(), ConsumableType, JobTask, ScheduleCostAmount, SchedulePriceAmount, ScheduleCostAmount);
        CreateJobPlanningLineWithPrice(
          JobPlanningLine, LibraryJob.PlanningLineTypeContract(), ConsumableType, JobTask, ContractCostAmount, ContractPriceAmount, ContractPriceAmount)
    end;

    local procedure CreateJobPlanningLineWithPrice(var JobPlanningLine: Record "Job Planning Line"; LineType: Enum "Job Planning Line Line Type"; ConsumableType: Enum "Job Planning Line Type"; JobTask: Record "Job Task"; TotalCost: Decimal; TotalPrice: Decimal; LineAmount: Decimal)
    begin
        LibraryJob.CreateJobPlanningLine(LineType, ConsumableType, JobTask, JobPlanningLine);
        JobPlanningLine."Total Cost (LCY)" := TotalCost;
        JobPlanningLine."Total Price (LCY)" := TotalPrice;
        JobPlanningLine."Line Amount (LCY)" := LineAmount;
        JobPlanningLine.Modify();
    end;

    local procedure UseJobTasks(var JobTask: Record "Job Task"; Fraction: Decimal)
    var
        JobLedgerEntry: Record "Job Ledger Entry";
        JobPlanningLine: Record "Job Planning Line";
    begin
        // Register usage amount for each job task in the filter for Fraction of the scheduled usage.

        JobTask.FindSet();
        repeat
            JobPlanningLine.SetRange("Job No.", JobTask."Job No.");
            JobPlanningLine.SetRange("Job Task No.", JobTask."Job Task No.");
            JobPlanningLine.SetRange("Line Type", JobPlanningLine."Line Type"::Budget);
            JobPlanningLine.FindSet();
            repeat
                CreateMockJobLedgerEntry(JobPlanningLine, Fraction, JobLedgerEntry)
            until JobPlanningLine.Next() = 0
        until JobTask.Next() = 0
    end;

    local procedure InvoiceJobTasks(var JobTask: Record "Job Task"; Fraction: Decimal)
    var
        JobPlanningLine: Record "Job Planning Line";
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        // Register invoiced amount for each job task in the filter for Fraction of the contract.

        JobTask.FindSet();
        repeat
            JobPlanningLine.SetRange("Job No.", JobTask."Job No.");
            JobPlanningLine.SetRange("Job Task No.", JobTask."Job Task No.");
            JobPlanningLine.SetRange("Line Type", JobPlanningLine."Line Type"::Billable);
            JobPlanningLine.FindSet();
            repeat
                CreateMockJobLedgerEntry(JobPlanningLine, Fraction, JobLedgerEntry)
            until JobPlanningLine.Next() = 0
        until JobTask.Next() = 0
    end;

    local procedure CreateMockJobLedgerEntry(JobPlanningLine: Record "Job Planning Line"; Fraction: Decimal; var JobLedgerEntry: Record "Job Ledger Entry")
    begin
        // Create a mock job ledger entry to similate usage or invoicing.
        // Note, these are NOT "real" job ledger entries.
        if JobLedgerEntry.FindLast() then;
        JobLedgerEntry.Init();
        JobLedgerEntry."Entry No." += 1;
        JobLedgerEntry."Job No." := JobPlanningLine."Job No.";
        JobLedgerEntry."Job Task No." := JobPlanningLine."Job Task No.";
        JobLedgerEntry."Posting Date" := WorkDate();
        JobLedgerEntry.Type := JobPlanningLine.Type;
        JobLedgerEntry."No." := JobPlanningLine."No.";
        case JobPlanningLine."Line Type" of
            LibraryJob.PlanningLineTypeSchedule():
                begin
                    JobLedgerEntry."Entry Type" := JobLedgerEntry."Entry Type"::Usage;
                    JobLedgerEntry."Total Cost (LCY)" := Fraction * JobPlanningLine."Total Cost (LCY)";
                    JobLedgerEntry."Line Amount (LCY)" := Fraction * JobPlanningLine."Line Amount (LCY)"
                end;
            LibraryJob.PlanningLineTypeContract():
                begin
                    JobLedgerEntry."Entry Type" := JobLedgerEntry."Entry Type"::Sale;
                    JobLedgerEntry."Total Cost (LCY)" := -Fraction * JobPlanningLine."Total Cost (LCY)";
                    JobLedgerEntry."Total Price (LCY)" := -Fraction * JobPlanningLine."Total Price (LCY)";
                    JobLedgerEntry."Line Amount (LCY)" := -Fraction * JobPlanningLine."Line Amount (LCY)"
                end
            else
                Assert.Fail(StrSubstNo('Unsupported line type: %1', JobPlanningLine."Line Type"));
        end;
        JobLedgerEntry.Insert();
    end;

    local procedure CreateDimensionSet(): Integer
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        DimMgt: Codeunit DimensionManagement;
        DimensionSetID: Integer;
    begin
        // Create a new dimension value for some standard dimension

        // create the standard dimension
        if not Dimension.Get(Prefix + 'D') then begin
            Dimension.Init();
            Dimension.Validate(Code, Prefix + 'D');
            Dimension.Insert(true);
            Dimension.Get(Dimension.Code)
        end;

        // create a new value for it
        DimensionValue.Init();
        DimensionValue.SetRange("Dimension Code", Dimension.Code);
        if not DimensionValue.FindLast() then
            DimensionValue.Validate(Code, Prefix + 'DV000');
        DimensionValue.Validate("Dimension Code", Dimension.Code);
        DimensionValue.Validate(Code, IncStr(DimensionValue.Code));
        DimensionValue."Dimension Value ID" := 0;
        DimensionValue.Insert(true);

        // create a dimension set entry for it
        Clear(TempDimSetEntry);
        TempDimSetEntry."Dimension Code" := Dimension.Code;
        TempDimSetEntry."Dimension Value Code" := DimensionValue.Code;
        TempDimSetEntry."Dimension Value ID" := DimensionValue."Dimension Value ID";
        TempDimSetEntry.Insert();

        DimensionSetID := DimMgt.GetDimensionSetID(TempDimSetEntry);
        exit(DimensionSetID);
    end;

    local procedure CreateJobPostingGroup(var JobPostingGroup: Record "Job Posting Group") Name: Code[20]
    begin
        // Create a new job posting group based on an existing one

        Name := Prefix + 'JPG001';
        JobPostingGroup.SetFilter(Code, Prefix + '*');
        if JobPostingGroup.FindLast() then
            Name := IncStr(JobPostingGroup.Code);

        JobPostingGroup.SetRange(Code);
        JobPostingGroup.FindFirst();
        JobPostingGroup.Code := Name;
        JobPostingGroup.Insert(true)
    end;

    local procedure CreateAndPostSalesInvoiceFromJobPlanningLine(var SalesHeader: Record "Sales Header"; var JobPlanningLine: Record "Job Planning Line"): Code[20]
    var
        SalesLine: Record "Sales Line";
    begin
        JobCreateInvoice.CreateSalesInvoice(JobPlanningLine, false);
        FindSalesLine(SalesLine, SalesLine."Document Type"::Invoice, SalesLine.Type::Item, JobPlanningLine."Job No.");
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure PrepareJobWithJobTaskWithWIP(var Job: Record Job)
    var
        JobTask: Record "Job Task";
        JobWIPMethod: Record "Job WIP Method";
    begin
        CreateJobWIPMethod(
          JobWIPMethod."Recognized Costs"::"Usage (Total Cost)",
          JobWIPMethod."Recognized Sales"::"At Completion", JobWIPMethod);
        JobWIPMethod.Validate("WIP Cost", true);
        JobWIPMethod.Modify(true);
        CreateJobWithWIPMethod(Job, JobWIPMethod.Code, Job."WIP Posting Method"::"Per Job");
        LibraryJob.CreateJobTask(Job, JobTask);

        Job.Get(Job."No.");
        Job.Validate("Starting Date", WorkDate() - 1);
        Job.Validate("Ending Date", 0D);
        Job.Modify(true);
    end;

    local procedure UpdateJobPostingGroup(var JobPostingGroup: Record "Job Posting Group")
    begin
        JobPostingGroup.Validate("WIP Costs Account", CreateGLAccount());
        JobPostingGroup.Validate("WIP Invoiced Sales Account", CreateGLAccount());
        JobPostingGroup.Validate("WIP Accrued Sales Account", CreateGLAccount());
        JobPostingGroup.Validate("Job Costs Applied Account", CreateGLAccount());
        JobPostingGroup.Validate("Job Sales Applied Account", CreateGLAccount());
        JobPostingGroup.Validate("Resource Costs Applied Account", CreateGLAccount());
        JobPostingGroup.Validate("Recognized Costs Account", CreateGLAccount());
        JobPostingGroup.Validate("Recognized Sales Account", CreateGLAccount());
        JobPostingGroup.Modify(true);
    end;

    local procedure CompletedJob(JobNo: Code[20])
    var
        Job: Record Job;
        JobCard: TestPage "Job Card";
    begin
        Job.Get(JobNo);
        JobCard.OpenEdit();
        JobCard.GotoRecord(Job);
        JobCard.Status.SetValue(Job.Status::Completed);
        JobCard.Close();
    end;

    local procedure AttachDimension2JobLedgerEntry(var JobLedgerEntry: Record "Job Ledger Entry"; DimensionSetID: Integer)
    begin
        JobLedgerEntry."Dimension Set ID" := DimensionSetID;
        JobLedgerEntry.Modify();
    end;

    local procedure CalculateWIP(Job: Record Job)
    var
        JobCalculateWIP: Report "Job Calculate WIP";
    begin
        // Use the Job Calculate WIP report to create the WIP entries and update WIP related fields in Job and its job tasks

        Job.SetRange("No.", Job."No.");
        JobCalculateWIP.SetTableView(Job);
        JobCalculateWIP.InitializeRequest();
        JobCalculateWIP.UseRequestPage(false);
        JobCalculateWIP.RunModal();
    end;

    local procedure CreateJobPostingGroupEmptyAccounts(var JobPostingGroup: Record "Job Posting Group")
    begin
        JobPostingGroup.Init();
        JobPostingGroup.Validate(Code,
          LibraryUtility.GenerateRandomCode(JobPostingGroup.FieldNo(Code), DATABASE::"Job Posting Group"));
        JobPostingGroup.Insert(true);
    end;

    local procedure PostWIP2GL(Job: Record Job)
    var
        JobPostWIPToGL: Report "Job Post WIP to G/L";
    begin
        // Use the Job Post WIP to G/L report to post WIP to GL.

        Job.SetRange("No.", Job."No.");
        JobPostWIPToGL.SetTableView(Job);
        JobPostWIPToGL.InitializeRequest(Format(Time - 000000T));
        JobPostWIPToGL.UseRequestPage(false);
        JobPostWIPToGL.RunModal();
    end;

    local procedure PostWIPToGLNoReverse(JobNo: Code[20])
    begin
        CalcGLWIP(JobNo, false);
    end;

    local procedure PostReverseWIPToGL(JobNo: Code[20])
    begin
        CalcGLWIP(JobNo, true);
    end;

    local procedure CalcGLWIP(JobNo: Code[20]; JustReverse: Boolean)
    var
        JobCalculateWIP: Codeunit "Job Calculate WIP";
    begin
        JobCalculateWIP.CalcGLWIP(JobNo, JustReverse, Format(Time - 000000T), WorkDate(), false);
    end;

    local procedure UpdateJobAdjustmentAccounts(JobPostingGroupCode: Code[20])
    var
        JobPostingGroup: Record "Job Posting Group";
    begin
        JobPostingGroup.Get(JobPostingGroupCode);
        JobPostingGroup.Validate("Job Sales Adjustment Account", CreateGLAccount());
        JobPostingGroup.Validate("Job Sales Applied Account", CreateGLAccount());
        JobPostingGroup.Validate("Job Costs Applied Account", CreateGLAccount());
        JobPostingGroup.Validate("Recognized Costs Account", CreateGLAccount());
        JobPostingGroup.Validate("Item Costs Applied Account", CreateGLAccount());
        JobPostingGroup.Validate("Job Costs Adjustment Account", CreateGLAccount());
        JobPostingGroup.Validate("WIP Accrued Costs Account", CreateGLAccount());
        JobPostingGroup.Validate("WIP Accrued Sales Account", CreateGLAccount());
        JobPostingGroup.Validate("Recognized Sales Account", CreateGLAccount());
        JobPostingGroup.Validate("Resource Costs Applied Account", CreateGLAccount());
        JobPostingGroup.Validate("G/L Costs Applied Account", CreateGLAccount());
        JobPostingGroup.Validate("WIP Costs Account", CreateGLAccount());
        JobPostingGroup.Validate("WIP Invoiced Sales Account", CreateGLAccount());
        JobPostingGroup.Modify(true);
    end;

    local procedure VerifyJobWIP(Job: Record Job; JobWIPMethod: Record "Job WIP Method")
    var
        JobTask: Record "Job Task";
        JobWIPTotal: Record "Job WIP Total";
        RecogSales: Decimal;
        RecogCosts: Decimal;
    begin
        // Verify WIP related field on Job and its job tasks

        // only consider posting tasks
        JobTask.SetRange("Job No.", Job."No.");
        JobTask.SetRange("WIP-Total", JobTask."WIP-Total"::Total);
        JobTask.FindSet();
        repeat
            JobWIPTotal.SetRange("Job No.", Job."No.");
            JobWIPTotal.SetRange("Job Task No.", JobTask."Job Task No.");
            JobWIPTotal.FindLast();
            VerifyJobWIPTotal(JobWIPTotal, JobWIPMethod)
        until JobTask.Next() = 0;

        // verify cost and sales recognition for the WIP totals
        JobTask.SetRange("Job Task Type");
        JobTask.SetRange("WIP-Total", JobTask."WIP-Total"::Total);
        JobTask.FindSet();
        repeat
            Assert.AreNearlyEqual(UsageTotalCost(JobTask) - TotalRecogCostGL(JobTask), WIPCostAmount(JobTask),
              GetRoundingPrecision(), 'WIP cost amounts do not match');
            Assert.AreNearlyEqual(TotalRecogSalesGL(JobTask) - ContractInvoicedPrice(JobTask), WIPSalesAmount(JobTask),
              GetRoundingPrecision(), 'WIP sales amounts do not match')
        until JobTask.Next() = 0;

        // verify cost and sales recognition for the job
        Job.CalcFields("Recog. Costs Amount", "Recog. Sales Amount", "Recog. Costs G/L Amount", "Recog. Sales G/L Amount");
        RecogCosts := RecogCostsAmount(Job);
        RecogSales := RecogSalesAmount(Job);
        Assert.AreNearlyEqual(RecogCosts, Job."Recog. Costs G/L Amount", GetRoundingPrecision(), Job.FieldCaption("Recog. Costs G/L Amount"));
        Assert.AreNearlyEqual(RecogSales, Job."Recog. Sales G/L Amount", GetRoundingPrecision(), Job.FieldCaption("Recog. Sales G/L Amount"))
    end;

    local procedure VerifyJobWIPTotal(JobWIPTotal: Record "Job WIP Total"; JobWIPMethod: Record "Job WIP Method")
    var
        JobTask: Record "Job Task";
    begin
        // Verify "Invoiced %" and "Cost Completion %" for JobWIPTotal

        JobTask.Get(JobWIPTotal."Job No.", JobWIPTotal."Job Task No.");
        JobWIPTotal.TestField("WIP Method", GetWIPMethod(JobTask, JobWIPMethod));
        if (JobWIPMethod."Recognized Costs" in
            [JobWIPMethod."Recognized Costs"::"Cost Value", JobWIPMethod."Recognized Costs"::"Cost of Sales"]) or
           (JobWIPMethod."Recognized Sales" in
            [JobWIPMethod."Recognized Sales"::"Sales Value", JobWIPMethod."Recognized Sales"::"Percentage of Completion"])
        then begin
            JobWIPTotal.TestField("Invoiced %", Round(100 * JobWIPTotal."Contract (Invoiced Price)" / JobWIPTotal."Contract (Total Price)", 0.00001));
            JobWIPTotal.TestField("Cost Completion %", Round(100 * JobWIPTotal."Usage (Total Cost)" / JobWIPTotal."Schedule (Total Cost)", 0.00001));
        end
    end;

    local procedure DefineWIPImpactOnGL(Job: Record Job)
    var
        JobPostingGroup: Record "Job Posting Group";
        TotalJobTask: Record "Job Task";
        UsageTotalCost: Decimal;
        RecogCostsAmt: Decimal;
        CostsAppliedAmt: Decimal;
    begin
        // Use a delta assertion to define the expected impact of WIP to GL

        DeltaAssert.Run();
        DeltaAssert.Init();
        DeltaAssert.SetTolerance(GetRoundingPrecision());

        JobPostingGroup.Get(Job."Job Posting Group");
        GetTotalJobTaskForJob(Job, TotalJobTask);
        UsageTotalCost := TotalJobTask."Usage (Total Cost)";
        RecogCostsAmt := RecogCostsAmount(Job);
        CostsAppliedAmt := -Max(RecogCostsAmt, UsageTotalCost);

        SetupDeltaAssertion(JobPostingGroup."Recognized Costs Account", RecogCostsAmt);
        SetupDeltaAssertion(JobPostingGroup."Job Costs Applied Account", CostsAppliedAmt);
        // The WIP Cost account is the balance account for both Applied Cost and Recognized Cost
        SetupDeltaAssertion(JobPostingGroup."WIP Costs Account", -(CostsAppliedAmt + RecogCostsAmt));
        SetupDeltaAssertion(JobPostingGroup."Job Costs Adjustment Account", Max(RecogCostsAmt - UsageTotalCost, 0));
        SetupDeltaAssertion(JobPostingGroup."WIP Accrued Costs Account", -Max(RecogCostsAmt - UsageTotalCost, 0));

        SetupDeltaAssertion(JobPostingGroup."Recognized Sales Account", -RecogSalesAmount(Job));
        SetupDeltaAssertion(JobPostingGroup."Job Sales Applied Account", SalesAppliedAmount(Job));
        // The WIP Invoiced Sales account is the balance account for both Applied Sales and Recognized Sales
        SetupDeltaAssertion(JobPostingGroup."WIP Invoiced Sales Account", InvoicedSalesAmount(Job));
        SetupDeltaAssertion(JobPostingGroup."Job Sales Adjustment Account", SalesAdjAmount(Job));
        SetupDeltaAssertion(JobPostingGroup."WIP Accrued Sales Account", AccruedSalesAmount(Job))
    end;

    local procedure SetupDeltaAssertion(AccountNo: Code[20]; Delta: Decimal)
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Get(AccountNo);
        DeltaAssert.AddWatch(DATABASE::"G/L Account", GLAccount.GetPosition(), GLAccount.FieldNo(Balance), Delta)
    end;

    local procedure RecogCostsAmount(Job: Record Job) RecogCosts: Decimal
    var
        JobTask: Record "Job Task";
    begin
        // Use the Job's WIP Method to calculate the recognized costs amount based on WIP totals

        FindJobTask(JobTask, Job."No.");
        repeat
            RecogCosts += UsageTotalCost(JobTask) - WIPCostAmount(JobTask)
        until JobTask.Next() = 0;

        RecogCosts := max(RecogCosts, 0)
    end;

    local procedure WIPCostAmount(JobTask: Record "Job Task"): Decimal
    var
        TotalJobTask: Record "Job Task";
        JobWIPMethod: Record "Job WIP Method";
    begin
        // Calculate the WIPAmount for costs.
        // See NAV 5.0 training material for meaning of the formulas

        Assert.AreEqual(JobTask."WIP-Total"::Total, JobTask."WIP-Total", 'Precondition violation: WIP-Total');

        GetTotalJobTask(JobTask, TotalJobTask);
        JobWIPMethod.Get(TotalJobTask."WIP Method");

        case JobWIPMethod."Recognized Costs" of
            JobWIPMethod."Recognized Costs"::"Cost of Sales":
                exit(TotalJobTask."Usage (Total Cost)" - TotalJobTask."Schedule (Total Cost)" * TotalJobTask."Contract (Invoiced Price)" / TotalJobTask."Contract (Total Price)");
            JobWIPMethod."Recognized Costs"::"Cost Value":
                exit(TotalJobTask."Usage (Total Cost)" * TotalJobTask."Contract (Total Price)" / TotalJobTask."Schedule (Total Price)" -
                  TotalJobTask."Contract (Invoiced Price)" * TotalJobTask."Schedule (Total Cost)" / TotalJobTask."Schedule (Total Price)");
            JobWIPMethod."Recognized Costs"::"Contract (Invoiced Cost)":
                exit(TotalJobTask."Usage (Total Cost)" - TotalJobTask."Contract (Invoiced Cost)");
            JobWIPMethod."Recognized Costs"::"At Completion":
                exit(TotalJobTask."Usage (Total Cost)");
        end
    end;

    local procedure RecogSalesAmount(Job: Record Job) RecogSales: Decimal
    var
        JobTask: Record "Job Task";
    begin
        // Use the Job's WIP Method to calculate the recognized sales amount based on WIP totals

        FindJobTask(JobTask, Job."No.");
        repeat
            RecogSales += WIPSalesAmount(JobTask) + ContractInvoicedPrice(JobTask)
        until JobTask.Next() = 0;

        RecogSales := max(RecogSales, 0)
    end;

    local procedure AccruedSalesAmount(Job: Record Job) AccruedSales: Decimal
    var
        JobTask: Record "Job Task";
        JobWIPMethod: Record "Job WIP Method";
        ContractInvPriceAmt: Decimal;
        RecogSalesAmt: Decimal;
    begin
        // Use the Job's WIP Method to calculate the Accrued sales amount based on WIP totals

        FindJobTask(JobTask, Job."No.");
        repeat
            CalcRecogSalesAndContrInv(JobTask, RecogSalesAmt, ContractInvPriceAmt);

            JobWIPMethod.Get(JobTask."WIP Method");
            case JobWIPMethod."Recognized Sales" of
                JobWIPMethod."Recognized Sales"::"Sales Value",
              JobWIPMethod."Recognized Sales"::"Usage (Total Price)":
                    AccruedSales += max(RecogSalesAmt - ContractInvPriceAmt, 0);
                JobWIPMethod."Recognized Sales"::"Percentage of Completion":
                    AccruedSales += RecogSalesAmt;
            end;
        until JobTask.Next() = 0;
    end;

    local procedure InvoicedSalesAmount(Job: Record Job) InvoicedSales: Decimal
    var
        JobTask: Record "Job Task";
        JobWIPMethod: Record "Job WIP Method";
        ContractInvPriceAmt: Decimal;
        RecogSalesAmt: Decimal;
    begin
        // Use the Job's WIP Method to calculate the Invoiced sales amount based on WIP totals

        FindJobTask(JobTask, Job."No.");
        repeat
            CalcRecogSalesAndContrInv(JobTask, RecogSalesAmt, ContractInvPriceAmt);

            JobWIPMethod.Get(JobTask."WIP Method");
            if JobWIPMethod."Recognized Sales" = JobWIPMethod."Recognized Sales"::"Percentage of Completion" then
                InvoicedSales -= ContractInvPriceAmt
            else
                InvoicedSales += -(Max(RecogSalesAmt, ContractInvPriceAmt) - RecogSalesAmt)
        until JobTask.Next() = 0;
    end;

    local procedure SalesAdjAmount(Job: Record Job) SalesAdj: Decimal
    var
        JobTask: Record "Job Task";
        JobWIPMethod: Record "Job WIP Method";
    begin
        // Use the Job's WIP Method to calculate the Sales Adjustment Amount based on WIP totals

        FindJobTask(JobTask, Job."No.");
        repeat
            JobWIPMethod.Get(JobTask."WIP Method");
            if JobWIPMethod."Recognized Sales" <> JobWIPMethod."Recognized Sales"::"Percentage of Completion" then
                SalesAdj += -Max(WIPSalesAmount(JobTask), 0);
        until JobTask.Next() = 0;
    end;

    local procedure SalesAppliedAmount(Job: Record Job) SalesApplied: Decimal
    var
        JobTask: Record "Job Task";
        JobWIPMethod: Record "Job WIP Method";
        ContractInvPriceAmt: Decimal;
        RecogSalesAmt: Decimal;
    begin
        // Use the Job's WIP Method to calculate the Sales Applied Amount based on WIP totals

        FindJobTask(JobTask, Job."No.");
        repeat
            CalcRecogSalesAndContrInv(JobTask, RecogSalesAmt, ContractInvPriceAmt);

            JobWIPMethod.Get(JobTask."WIP Method");
            case JobWIPMethod."Recognized Sales" of
                JobWIPMethod."Recognized Sales"::"Percentage of Completion":
                    SalesApplied += ContractInvPriceAmt;
                JobWIPMethod."Recognized Sales"::"Sales Value", JobWIPMethod."Recognized Sales"::"Usage (Total Price)":
                    SalesApplied += max(RecogSalesAmt, ContractInvPriceAmt)
                else
                    SalesApplied += ContractInvPriceAmt;
            end;
        until JobTask.Next() = 0;
    end;

    local procedure WIPSalesAmount(var JobTask: Record "Job Task"): Decimal
    var
        TotalJobTask: Record "Job Task";
        JobWIPMethod: Record "Job WIP Method";
    begin
        // Calculate the WIPAmount for sales
        // See NAV 5.0 training material for meaning of the formulas

        Assert.AreEqual(JobTask."WIP-Total"::Total, JobTask."WIP-Total", 'Precondition violation: WIP-Total');

        GetTotalJobTask(JobTask, TotalJobTask);
        JobWIPMethod.Get(TotalJobTask."WIP Method");

        case JobWIPMethod."Recognized Sales" of
            JobWIPMethod."Recognized Sales"::"Percentage of Completion":
                exit(Min(TotalJobTask."Contract (Total Price)", TotalJobTask."Contract (Total Price)" * TotalJobTask."Usage (Total Cost)" / TotalJobTask."Schedule (Total Cost)") -
                  TotalJobTask."Contract (Invoiced Price)");
            JobWIPMethod."Recognized Sales"::"Sales Value":
                exit(TotalJobTask."Usage (Total Price)" * TotalJobTask."Contract (Total Price)" / TotalJobTask."Schedule (Total Price)" - TotalJobTask."Contract (Invoiced Price)");
            JobWIPMethod."Recognized Sales"::"Usage (Total Cost)":
                exit(TotalJobTask."Usage (Total Cost)" - TotalJobTask."Contract (Invoiced Price)");
            JobWIPMethod."Recognized Sales"::"Usage (Total Price)":
                exit(TotalJobTask."Usage (Total Price)" - TotalJobTask."Contract (Invoiced Price)");
            JobWIPMethod."Recognized Sales"::"At Completion":
                exit(-TotalJobTask."Contract (Invoiced Price)");
        end
    end;

    local procedure UsageTotalCost(JobTask: Record "Job Task"): Decimal
    var
        TotalJobTask: Record "Job Task";
    begin
        Assert.AreEqual(JobTask."WIP-Total"::Total, JobTask."WIP-Total", 'Precondition violation: WIP-Total');

        GetTotalJobTask(JobTask, TotalJobTask);
        exit(TotalJobTask."Usage (Total Cost)")
    end;

    local procedure ContractInvoicedPrice(JobTask: Record "Job Task"): Decimal
    var
        TotalJobTask: Record "Job Task";
    begin
        Assert.AreEqual(JobTask."WIP-Total"::Total, JobTask."WIP-Total", 'Precondition violation: WIP-Total');

        GetTotalJobTask(JobTask, TotalJobTask);
        exit(TotalJobTask."Contract (Invoiced Price)")
    end;

    local procedure CalcRecogSalesAndContrInv(JobTask: Record "Job Task"; var RecogSalesAmt: Decimal; var ContractInvPriceAmt: Decimal)
    begin
        ContractInvPriceAmt := ContractInvoicedPrice(JobTask);
        RecogSalesAmt := WIPSalesAmount(JobTask) + ContractInvPriceAmt;
    end;

    local procedure FindJobTask(var JobTask: Record "Job Task"; JobNo: Code[20])
    begin
        JobTask.SetRange("Job No.", JobNo);
        JobTask.SetRange("WIP-Total", JobTask."WIP-Total"::Total);
        JobTask.FindSet();
    end;

    local procedure FindSalesHeader(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; JobNo: Code[20]; Type: Enum "Sales Line Type")
    var
        SalesLine: Record "Sales Line";
    begin
        FindSalesLine(SalesLine, DocumentType, Type, JobNo);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; Type: Enum "Sales Line Type"; JobNo: Code[20])
    begin
        SalesLine.SetRange("Document Type", DocumentType);
        SalesLine.SetRange(Type, Type);
        SalesLine.SetRange("Job No.", JobNo);
        SalesLine.FindFirst();
    end;

    local procedure FilterJobTaskByType(var JobTask: Record "Job Task"; JobNo: Code[20])
    begin
        JobTask.Reset();
        JobTask.SetRange("Job No.", JobNo);
        JobTask.SetRange("Job Task Type", JobTask."Job Task Type"::Posting);
    end;

    local procedure TotalRecogCostGL(JobTask: Record "Job Task"): Decimal
    var
        TotalJobTask: Record "Job Task";
    begin
        Assert.AreEqual(JobTask."WIP-Total"::Total, JobTask."WIP-Total", 'Precondition violation: WIP-Total');

        GetTotalJobTask(JobTask, TotalJobTask);
        exit(TotalJobTask."Recognized Costs G/L Amount")
    end;

    local procedure TotalRecogSalesGL(JobTask: Record "Job Task"): Decimal
    var
        TotalJobTask: Record "Job Task";
    begin
        Assert.AreEqual(JobTask."WIP-Total"::Total, JobTask."WIP-Total", 'Precondition violation: WIP-Total');

        GetTotalJobTask(JobTask, TotalJobTask);
        exit(TotalJobTask."Recognized Sales G/L Amount")
    end;

    local procedure GetTotalJobTaskForJob(Job: Record Job; var TotalJobTask: Record "Job Task")
    var
        JobTask: Record "Job Task";
    begin
        // Return a job task containing the total for all amounts of the Job's posting tasks

        FilterJobTaskByType(JobTask, Job."No.");
        JobTask.FindSet();
        repeat
            AddJobTasks(JobTask, TotalJobTask);
        until JobTask.Next() = 0;
    end;

    local procedure GetTotalJobTask(JobTask: Record "Job Task"; var TotalJobTask: Record "Job Task")
    var
        JobWIPMethod: Record "Job WIP Method";
        EndJobTaskNo: Code[20];
    begin
        // Return a job task containing the total for all amounts of the WIP total in which JobTask is included

        Assert.AreEqual(JobTask."WIP-Total", JobTask."WIP-Total"::Total, 'Precondition violated');

        TotalJobTask.Init();

        EndJobTaskNo := JobTask."Job Task No.";

        // Find start of WIP total
        JobTask.SetFilter("Job No.", JobTask."Job No.");
        JobTask.SetFilter("Job Task No.", '<%1', EndJobTaskNo);
        JobTask.SetFilter("WIP-Total", '<>%1', JobTask."WIP-Total"::" ");
        if JobTask.FindLast() then begin
            JobTask.SetRange("WIP-Total");
            JobTask.Next();
        end else begin
            JobTask.SetRange("WIP-Total");
            JobTask.FindFirst();
        end;

        // Sum all posting task lines in the range.
        JobTask.SetRange("Job Task Type", JobTask."Job Task Type"::Posting);
        JobTask.SetRange("Job Task No.", JobTask."Job Task No.", EndJobTaskNo);
        JobTask.FindSet();
        repeat
            AddJobTasks(JobTask, TotalJobTask)
        until JobTask.Next() = 0;

        TotalJobTask."WIP Method" := GetWIPMethod(JobTask, JobWIPMethod)
    end;

    local procedure GetWIPMethod(JobTask: Record "Job Task"; var JobWIPMethod: Record "Job WIP Method") JobWIPMethodCode: Code[20]
    var
        Job: Record Job;
        Steps: Integer;
    begin
        // Return the WIP Method that applies for a job task (either from its WIP Total or Job)

        JobTask.SetRange("Job No.", JobTask."Job No.");
        if JobTask."WIP-Total" <> JobTask."WIP-Total"::Total then
            repeat
                Steps := JobTask.Next();
            until (JobTask."WIP-Total" <> JobTask."WIP-Total"::" ") or (Steps = 0);

        if JobTask."WIP-Total" = JobTask."WIP-Total"::" " then
            Assert.Fail('Precondition violation: last job task should be a WIP-Total.');

        if JobTask."WIP Method" = '' then begin
            Job.Get(JobTask."Job No.");
            JobWIPMethodCode := Job."WIP Method"
        end else
            JobWIPMethodCode := JobTask."WIP Method";

        JobWIPMethod.Get(JobWIPMethodCode)
    end;

    local procedure AddJobTasks(JobTask: Record "Job Task"; var TotalJobTask: Record "Job Task")
    begin
        JobTask.CalcFields("Schedule (Total Cost)", "Schedule (Total Price)", "Usage (Total Cost)", "Usage (Total Price)",
          "Contract (Invoiced Cost)", "Contract (Invoiced Price)", "Contract (Total Price)");
        TotalJobTask."Schedule (Total Cost)" += JobTask."Schedule (Total Cost)";
        TotalJobTask."Schedule (Total Price)" += JobTask."Schedule (Total Price)";
        TotalJobTask."Usage (Total Cost)" += JobTask."Usage (Total Cost)";
        TotalJobTask."Usage (Total Price)" += JobTask."Usage (Total Price)";
        TotalJobTask."Contract (Invoiced Price)" += JobTask."Contract (Invoiced Price)";
        TotalJobTask."Contract (Invoiced Cost)" += JobTask."Contract (Invoiced Cost)";
        TotalJobTask."Contract (Total Price)" += JobTask."Contract (Total Price)";

        TotalJobTask."Recognized Sales Amount" += JobTask."Recognized Sales Amount";
        TotalJobTask."Recognized Costs Amount" += JobTask."Recognized Costs Amount";
        TotalJobTask."Recognized Sales G/L Amount" += JobTask."Recognized Sales G/L Amount";
        TotalJobTask."Recognized Costs G/L Amount" += JobTask."Recognized Costs G/L Amount"
    end;

    local procedure GetRoundingPrecision(): Decimal
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        exit(GeneralLedgerSetup."Amount Rounding Precision")
    end;

    local procedure "Min"(Left: Decimal; Right: Decimal): Decimal
    begin
        if Left < Right then
            exit(Left);
        exit(Right)
    end;

    local procedure "Max"(Left: Decimal; Right: Decimal): Decimal
    begin
        if Left > Right then
            exit(Left);
        exit(Right)
    end;

    local procedure UpdateItemCostAccountInJobPostingGroup("Code": Code[20])
    var
        JobPostingGroup: Record "Job Posting Group";
    begin
        JobPostingGroup.Get(Code);
        JobPostingGroup.Validate("Item Costs Applied Account", CreateGLAccount());
        JobPostingGroup.Modify(true);
    end;

    local procedure VerifyGLEntry(JobTask: Record "Job Task"; CostAmount: Decimal)
    var
        JobPostingGroup: Record "Job Posting Group";
        GLEntry: Record "G/L Entry";
    begin
        JobPostingGroup.Get(JobTask."Job Posting Group");
        GLEntry.SetRange("Job No.", JobTask."Job No.");
        GLEntry.SetRange("G/L Account No.", JobPostingGroup."Job Costs Applied Account");
        GLEntry.SetRange("Posting Date", WorkDate());
        GLEntry.FindFirst();
        GLEntry.TestField("Bal. Account No.", JobPostingGroup."WIP Costs Account");
        GLEntry.TestField(Amount, CostAmount);
    end;

    local procedure VerifyGLEntries(JobTask: Record "Job Task"; AccountType: Option "WIP Costs Account","WIP Invoiced Sales Account")
    var
        JobPostingGroup: Record "Job Posting Group";
        GLEntry: Record "G/L Entry";
        TotalAmount: Decimal;
    begin
        JobPostingGroup.Get(JobTask."Job Posting Group");

        GLEntry.SetRange("Job No.", JobTask."Job No.");
        GLEntry.SetRange("Posting Date", WorkDate());

        case AccountType of
            AccountType::"WIP Costs Account":
                GLEntry.SetRange("Bal. Account No.", JobPostingGroup."WIP Costs Account");
            AccountType::"WIP Invoiced Sales Account":
                GLEntry.SetRange("Bal. Account No.", JobPostingGroup."WIP Invoiced Sales Account");
        end;
        GLEntry.FindSet();

        repeat
            TotalAmount += GLEntry.Amount;
        until GLEntry.Next() = 0;

        Assert.AreEqual(0, TotalAmount, StrSubstNo(TotalAmountErr, AccountType));
    end;

    local procedure VerifyJobWIPEntry(JobTask: Record "Job Task")
    var
        JobWIPEntry: Record "Job WIP Entry";
    begin
        JobTask.CalcFields("Usage (Total Cost)");
        JobWIPEntry.SetRange("Job No.", JobTask."Job No.");
        JobWIPEntry.FindFirst();
        JobWIPEntry.TestField("WIP Entry Amount", -JobTask."Usage (Total Cost)");
    end;

    local procedure VerifyJobWIPEntryByType(JobNo: Code[20]; Type: Enum "Job WIP Buffer Type"; ExpectedAmount: Decimal)
    var
        JobWIPEntry: Record "Job WIP Entry";
    begin
        JobWIPEntry.SetRange("Job No.", JobNo);
        JobWIPEntry.SetRange(Type, Type);
        JobWIPEntry.CalcSums("WIP Entry Amount");
        JobWIPEntry.TestField("WIP Entry Amount", ExpectedAmount);
    end;

    local procedure VerifyJobWIPEntryDoesNotExist(JobNo: Code[20]; Type: Enum "Job WIP Buffer Type")
    var
        JobWIPEntry: Record "Job WIP Entry";
    begin
        JobWIPEntry.Init();
        JobWIPEntry.SetRange("Job No.", JobNo);
        JobWIPEntry.SetRange(Type, Type);
        Assert.RecordIsEmpty(JobWIPEntry);
    end;

    local procedure VerifyJobWIPGLEntry(JobTask: Record "Job Task")
    var
        JobWIPGLEntry: Record "Job WIP G/L Entry";
    begin
        JobTask.CalcFields("Usage (Total Cost)");
        JobWIPGLEntry.SetRange("Job No.", JobTask."Job No.");
        JobWIPGLEntry.FindFirst();
        JobWIPGLEntry.TestField("WIP Entry Amount", -JobTask."Usage (Total Cost)");
    end;

    local procedure VerifyPostedSalesCreditMemo(DocumentNo: Code[20]; LineType: Enum "Sales Line Type"; Qty: Decimal)
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        SalesCrMemoLine.SetRange("Document No.", DocumentNo);
        SalesCrMemoLine.SetRange(Type, LineType);
        SalesCrMemoLine.FindFirst();
        Assert.AreEqual(Qty, SalesCrMemoLine.Quantity, StrSubstNo(QtyErr, SalesCrMemoLine.TableCaption));
    end;

    local procedure VerifyWIPGLEntryReversed(JobNo: Code[20])
    var
        JobWIPGLEntry: Record "Job WIP G/L Entry";
    begin
        JobWIPGLEntry.SetRange("Job No.", JobNo);
        JobWIPGLEntry.FindFirst();
        Assert.IsTrue(JobWIPGLEntry.Reversed, EntryNotReversedErr);
    end;

    local procedure VerifyJobWIPEntryGLAccounts(JobNo: Code[20]; JobWIPEntryType: Enum "Job WIP Buffer Type"; GLAccountNo: Code[20]; BalGLAccountNo: Code[20])
    var
        JobWIPEntry: Record "Job WIP Entry";
    begin
        JobWIPEntry.SetRange("Job No.", JobNo);
        JobWIPEntry.SetRange(Type, JobWIPEntryType);
        JobWIPEntry.FindFirst();
        Assert.AreEqual(GLAccountNo, JobWIPEntry."G/L Account No.", JobWIPEntryGLAccountErr);
        Assert.AreEqual(BalGLAccountNo, JobWIPEntry."G/L Bal. Account No.", JobWIPEntryGLAccountErr);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure JobTransferToSalesInvoiceRequestPageHandler(var JobTransferToSalesInvoice: TestRequestPage "Job Transfer to Sales Invoice")
    begin
        JobTransferToSalesInvoice.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure JobPostWIPtoGLRequestPageHandler(var JobPostWIPtoGL: TestRequestPage "Job Post WIP to G/L")
    begin
        JobPostWIPtoGL.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure WIPSucceededMessageHandler(Msg: Text[1024])
    begin
        Assert.IsTrue(
          (StrPos(Msg, 'WIP was successfully') = 1) or (StrPos(Msg, 'WIP was calculated with warnings') = 1),
          StrSubstNo('Unexpected message: %1', Msg))
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure WIPFailedMessageHandler(Msg: Text[1024])
    begin
        Assert.IsTrue(StrPos(Msg, 'There were no new WIP') = 1, StrSubstNo('Unexpected message: %1', Msg))
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Message Handler.
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerFalse(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure JobWipEntriesHandler(var JobWIPEntries: TestPage "Job WIP Entries")
    begin
        JobWIPEntries.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerMultipleResponses(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;
}

