namespace Microsoft.Service.Test;

using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Journal;
using Microsoft.Projects.Project.Ledger;
using Microsoft.Projects.Project.Planning;
using Microsoft.Sales.Customer;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using Microsoft.Service.Posting;

codeunit 136301 "Job Consumption Service"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Service] [Job]
        Initialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryJob: Codeunit "Library - Job";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryUtility: Codeunit "Library - Utility";
        Initialized: Boolean;
        UndoConsumptionJobError: Label 'You cannot undo consumption on the line because it has been already posted to Projects.';
        JobBlockedError: Label '%1 %2 must not be blocked with type %3.';
        UnknownError: Label 'Unknown error.';

    local procedure Initialize()
    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Job Consumption Service");
        if Initialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Job Consumption Service");

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibrarySales.SetCreditWarningsToNoWarnings();

        Initialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Job Consumption Service");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure ServiceOrderFullJobConsumption()
    begin
        // Covers document number TC1.1 - refer to TFS ID 19910.
        // Test integration of Jobs with Service Management by validating entries after posting Service Order with Full Job consumption.

        ConsumeService(1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure ServiceOrderPartJobConsumption()
    begin
        // Covers document number TC1.2 - refer to TFS ID 19910.
        // Test integration of Jobs with Service Management by validating entries after posting Service Order with Partial Job consumption.

        ConsumeService(LibraryUtility.GenerateRandomFraction());
    end;

    local procedure ConsumeService(ConsumptionFactor: Decimal)
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        TempServiceLine: Record "Service Line" temporary;
    begin
        // 1. Setup: Create a new Service Order with Job attached on Service Lines.
        Initialize();
        CreateServiceOrderWithJob(ServiceHeader, ConsumptionFactor);

        // 2. Exercise: Save the Service Lines in temporary table and post the Service Order as Ship and Consume.
        GetServiceLines(ServiceHeader, ServiceLine);
        CopyServiceLines(ServiceLine, TempServiceLine);
        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);

        // 3. Verify: Check that the Job Ledger Entry, Job Planning Lines correspond to the relevant Service Line. Check that the field
        // Posted Service Shipment No. of the Job Ledger Entry is updated to show Service Shipment No.
        VerifyServiceDocPostingForJob(TempServiceLine)
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure UndoConsumptionErrorForJob()
    var
        ServiceHeader: Record "Service Header";
        ServiceShipmentHeader: Record "Service Shipment Header";
        ServiceShipmentLine: Record "Service Shipment Line";
    begin
        // Covers document number TC1.3 - refer to TFS ID 19910.
        // Test integration of Jobs with Service Management by validating that the system generates an error on performing Undo Consumption
        // for Service Lines that have been posted to Jobs.

        // 1. Setup: Create a new Service Order with Job attached on Service Lines. Post the Service Order as Ship and Consume.
        Initialize();
        CreateServiceOrderWithJob(ServiceHeader, 1);
        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);

        // 2. Exercise: Find Service Shipment Lines and Undo Consumption.
        ServiceShipmentHeader.SetRange("Order No.", ServiceHeader."No.");
        ServiceShipmentHeader.FindFirst();
        ServiceShipmentLine.SetRange("Document No.", ServiceShipmentHeader."No.");
        asserterror CODEUNIT.Run(CODEUNIT::"Undo Service Consumption Line", ServiceShipmentLine);

        // 3. Verify: Check that the application generates an error if Undo Consumption is performed for Service Lines that have been posted
        // to Jobs.
        Assert.AreEqual(StrSubstNo(UndoConsumptionJobError), GetLastErrorText, UnknownError);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure JobNoChangeAftrConsumption()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        Job: Record Job;
    begin
        // Covers document number TC1.4 - refer to TFS ID 19910.
        // Test integration of Jobs with Service Management by validating that the system generates an error on changing Job No. field
        // for Service Line that has been posted to Jobs.

        // 1. Setup: Setup and post the Service Order as Ship and Consume. Create a new Job.
        Initialize();
        CreateServiceOrderWithJob(ServiceHeader, LibraryUtility.GenerateRandomFraction());
        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);

        GetServiceLines(ServiceHeader, ServiceLine);

        LibraryJob.CreateJob(Job, ServiceLine."Bill-to Customer No.");

        // 2. Exercise: Change Job No. field.
        asserterror ServiceLine.Validate("Job No.", Job."No.");

        // 3. Verify: Check that the application generates an error if Job No. field is changed for Service Line that has been
        // posted to Jobs.
        VerifyJobConsumedError(ServiceLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure JobTaskNoChangeAftrConsumption()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        JobTask: Record "Job Task";
        Job: Record Job;
    begin
        // Covers document number TC1.4 - refer to TFS ID 19910.
        // Test integration of Jobs with Service Management by validating that the system generates an error on changing Job Task No. field
        // for Service Line that has been posted to Jobs.

        // 1. Setup: Setup and post the Service Order as Ship and Consume. Create a new Job Task.
        Initialize();
        CreateServiceOrderWithJob(ServiceHeader, LibraryUtility.GenerateRandomFraction());
        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);
        GetServiceLines(ServiceHeader, ServiceLine);
        Job.Get(ServiceLine."Job No.");
        LibraryJob.CreateJobTask(Job, JobTask);

        // 2. Exercise: Change Job Task No. field.
        asserterror ServiceLine.Validate("Job Task No.", JobTask."Job Task No.");

        // 3. Verify: Check that the application generates an error if Job Task No. field is changed for Service Line that has been
        // posted to Jobs.
        VerifyJobConsumedError(ServiceLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure LineTypeChangeAftrConsumption()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // Covers document number TC1.4 - refer to TFS ID 19910.
        // Test integration of Jobs with Service Management by validating that the system generates an error on changing Job Line Type field
        // for Service Line that has been posted to Jobs.

        // 1. Setup: Setup and post the Service Order as Ship and Consume.
        Initialize();
        CreateServiceOrderWithJob(ServiceHeader, LibraryUtility.GenerateRandomFraction());
        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);
        GetServiceLines(ServiceHeader, ServiceLine);

        // 2. Exercise: Change Job Line Type field.
        asserterror ServiceLine.Validate("Job Line Type", ServiceLine."Job Line Type"::" ");

        // 3. Verify: Check that the application generates an error if Job Line Type field is changed for Service Line that has been
        // posted to Jobs.
        VerifyJobConsumedError(ServiceLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlockedJobOnServiceLineError()
    var
        Job: Record Job;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // Covers document number TC-PP-JB-2 - refer to TFS ID 20892.
        // Test that it is impossible to specify Job No., assigned to a blocked job, on the Service Line.

        // 1. Setup: Create a new Job and set Blocked as All.
        Initialize();
        LibraryJob.CreateJob(Job);
        Job.Validate(Blocked, Job.Blocked::All);
        Job.Modify(true);

        // 2. Exercise: Create a new Service Order - Service Header, Service Line and try to assign the blocked Job on the Service Line.
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Job."Bill-to Customer No.");
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryJob.FindItem());
        asserterror ServiceLine.Validate("Job No.", Job."No.");

        // 3. Verify: Check that the application generates an error on assignment of blocked Job to Job No. field of Service Line.
        Assert.AreEqual(StrSubstNo(JobBlockedError, Job.TableCaption(), Job."No.", Job.Blocked), GetLastErrorText, UnknownError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlankJobFieldsAfterJobChange()
    var
        ServiceHeader: Record "Service Header";
        Job: Record Job;
    begin
        // Covers document number TC-PP-JB-3 - refer to TFS ID 20892.
        // Test that the Job Task No. field is validated correctly after the Job No. field value has been changed.

        // 1. Setup: Create a new Service Order with a new Job attached on Service Lines. Create Service Lines for G/L Account. Create one
        // more new Job.
        Initialize();
        CreateServiceOrderWithJob(ServiceHeader, 1);

        LibraryJob.CreateJob(Job, ServiceHeader."Bill-to Customer No.");

        // 2. Exercise: Change the Job No. on Service Lines as No. of new job created.
        ModifyJobNoOnServiceLines(ServiceHeader, Job."No.");

        // 3. Verify: Check that the Job Task No. and Job Line Type fields are blank after changing Job No. on Service Line.
        VerifyJobFieldsOnServiceLines(ServiceHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlankJobFieldsAfterJobDeletion()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Covers document number TC-PP-JB-3 - refer to TFS ID 20892.
        // Test that the Job Task No. field is validated correctly after the Job No. field value has been deleted.

        // 1. Setup: Create a new Service Order with Job attached on Service Lines. Create Service Lines for G/L Account.
        Initialize();
        CreateServiceOrderWithJob(ServiceHeader, 1);

        // 2. Exercise: Change the Job No. on Service Lines as blank.
        ModifyJobNoOnServiceLines(ServiceHeader, '');

        // 3. Verify: Check that the Job Task No. and Job Line Type fields are blank after deleting Job No. value on Service Line.
        VerifyJobFieldsOnServiceLines(ServiceHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LinkScheduledServiceItem()
    begin
        // [SCENARIO] Use a planning line (Type = Item, "Line Type" = Budget) with an explicit link, post execution via Service Document, verify that link created and Quantities and Amounts are correct.

        UseLinked(LibraryJob.ItemType(), LibraryJob.PlanningLineTypeSchedule(), false, ServiceConsumption())
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LinkBothServiceItem()
    begin
        // [SCENARIO] Use a planning line (Type = Item, "Line Type" = Budget & Billable) with an explicit link, post execution via Service Document, verify that link created and Quantities and Amounts are correct.

        UseLinked(LibraryJob.ItemType(), LibraryJob.PlanningLineTypeBoth(), false, ServiceConsumption())
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LinkScheduledServiceResource()
    begin
        // [SCENARIO] Use a planning line (Type = Resource, "Line Type" = Budget) with an explicit link, post execution via Service Document, verify that link created and Quantities and Amounts are correct.

        UseLinked(LibraryJob.ResourceType(), LibraryJob.PlanningLineTypeSchedule(), false, ServiceConsumption())
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LinkBothServiceResource()
    begin
        // [SCENARIO] Use a planning line (Type = Resource, "Line Type" = Budget & Billable) with an explicit link, post execution via Service Document, verify that link created and Quantities and Amounts are correct.

        UseLinked(LibraryJob.ResourceType(), LibraryJob.PlanningLineTypeBoth(), false, ServiceConsumption())
    end;

    local procedure UseLinked(ConsumableType: Enum "Job Planning Line Type"; LineTypeToMatch: Enum "Job Planning Line Line Type"; ApplyUsageLink: Boolean; Source: Option)
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        BeforeJobPlanningLine: Record "Job Planning Line";
        NewJobPlanningLine: Record "Job Planning Line";
        JobJournalLine: Record "Job Journal Line";
        JobLedgerEntry: Record "Job Ledger Entry";
        DateForm: DateFormula;
        LineCount: Integer;
    begin
        // Use a planning line with an explicit link
        // via job journal, gl journal, purchase, or service (Source).
        // Verify remaining quantity
        // Verify that the usage link is created.
        // Verify that the planning line's amounts and quantities are updated.

        // can only link to a planning line which type includes budget
        Assert.IsTrue(
          LineTypeToMatch in [LibraryJob.PlanningLineTypeSchedule(), LibraryJob.PlanningLineTypeBoth()],
          'Line type should include budget.');

        // Setup
        Initialize();
        CreateJob(ApplyUsageLink, true, Job);
        LibraryJob.CreateJobTask(Job, JobTask);

        // this is the planning line we want to match
        LibraryJob.CreateJobPlanningLine(LineTypeToMatch, ConsumableType, JobTask, JobPlanningLine);
        JobPlanningLine.Validate("Usage Link", true);
        JobPlanningLine.Modify(true);

        AssertNoDiscounts(JobPlanningLine);
        BeforeJobPlanningLine := JobPlanningLine;

        // to make it more difficult
        CreateSimilarJobPlanningLines(JobPlanningLine);

        // with an explicit link, we can even have earlier planning lines that are identical
        NewJobPlanningLine := JobPlanningLine;
        Evaluate(DateForm, '<-1W>');
        NewJobPlanningLine.Validate("Planning Date", CalcDate(DateForm, JobPlanningLine."Planning Date"));
        NewJobPlanningLine.Validate("Line No.", LibraryJob.GetNextLineNo(JobPlanningLine));
        NewJobPlanningLine.Insert(true);
        LineCount := JobPlanningLine.Count();

        // Exercise
        UseJobPlanningLineExplicit(JobPlanningLine, LibraryJob.UsageLineTypeBlank(), 1, Source, JobJournalLine);

        // refresh
        JobPlanningLine.Get(Job."No.", JobTask."Job Task No.", JobPlanningLine."Line No.");

        // Verify - the Remaining Qty. field on the journal line is correct
        JobJournalLine.TestField("Remaining Qty.", BeforeJobPlanningLine."Remaining Qty." - JobJournalLine.Quantity);

        // Verify - line type is taken from planning line
        Assert.AreEqual(
          LibraryJob.UsageLineType(JobPlanningLine."Line Type"),
          JobJournalLine."Line Type",
          'Journal line type should the same as planning line type.');

        // Verify - usage link has been created
        JobLedgerEntry.SetRange(Description, JobJournalLine.Description);
        JobLedgerEntry.FindFirst();
        VerifyUsageLink(JobPlanningLine, JobLedgerEntry);

        // Verify - no new planning lines are created
        Assert.AreEqual(LineCount, JobPlanningLine.Count, 'No planning lines should have been created.');

        // Verify - JobPlanningLine@Pre - JobJournalLine = JobPlanningLine@Post
        VerifyJobPlanningLine(BeforeJobPlanningLine, JobPlanningLine, JobJournalLine)
    end;

    local procedure UseJobPlanningLineExplicit(JobPlanningLine: Record "Job Planning Line"; UsageLineType: Enum "Job Line Type"; Fraction: Decimal; Source: Option; var JobJournalLine: Record "Job Journal Line")
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        TempServiceLine: Record "Service Line" temporary;
        ServicePost: Codeunit "Service-Post";
        Ship: Boolean;
        Consume: Boolean;
        Invoice: Boolean;
    begin
        case Source of
            ServiceConsumption():
                begin
                    Ship := true;
                    Consume := true;
                    Invoice := false;
                    LibraryService.CreateServiceLineForPlan(JobPlanningLine, UsageLineType, Fraction, ServiceLine);
                    ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
                    ServicePost.PostWithLines(ServiceHeader, TempServiceLine, Ship, Consume, Invoice);
                    JobJournalLine."Line Type" := ServiceLine."Job Line Type";
                    JobJournalLine."Remaining Qty." := ServiceLine."Job Remaining Qty.";
                    JobJournalLine.Quantity := ServiceLine."Qty. to Consume";
                    JobJournalLine.Description := ServiceLine.Description;
                    JobJournalLine."Total Cost" := Round(ServiceLine."Qty. to Consume" * ServiceLine."Unit Cost");
                    JobJournalLine."Total Cost (LCY)" := Round(ServiceLine."Qty. to Consume" * ServiceLine."Unit Cost (LCY)");
                    JobJournalLine."Line Amount" := ServiceLine."Qty. to Consume" * ServiceLine."Unit Price"
                end;
        end;
    end;

    local procedure ServiceConsumption(): Integer
    begin
        exit(1); // Service
    end;

    local procedure CreateJob(ApplyUsageLink: Boolean; BothAllowed: Boolean; var Job: Record Job)
    begin
        LibraryJob.CreateJob(Job);
        Job.Validate("Apply Usage Link", ApplyUsageLink);
        Job.Validate("Allow Schedule/Contract Lines", BothAllowed);
        Job.Modify(true)
    end;

    local procedure AssertNoDiscounts(JobPlanningLine: Record "Job Planning Line")
    var
        Precision: Decimal;
    begin
        Precision := LibraryJob.GetAmountRoundingPrecision(JobPlanningLine."Currency Code");
        JobPlanningLine.TestField("Total Cost", Round(JobPlanningLine.Quantity * JobPlanningLine."Unit Cost", Precision));
        JobPlanningLine.TestField("Total Price", Round(JobPlanningLine.Quantity * JobPlanningLine."Unit Price", Precision));
        JobPlanningLine.TestField("Line Discount %", 0);
        JobPlanningLine.TestField("Line Discount Amount", 0);
        JobPlanningLine.TestField("Line Amount", JobPlanningLine."Total Price");
        JobPlanningLine.TestField("Remaining Qty.", JobPlanningLine.Quantity);
        JobPlanningLine.TestField("Remaining Total Cost", JobPlanningLine."Total Cost");
        JobPlanningLine.TestField("Remaining Line Amount", JobPlanningLine."Line Amount")
    end;

    local procedure CreateSimilarJobPlanningLines(JobPlanningLine: Record "Job Planning Line")
    var
        NewJobPlanningLine: Record "Job Planning Line";
        Job: Record Job;
        DateForm: DateFormula;
    begin
        // Create planning lines similar to <JobPlanningLine>

        // same, but later
        NewJobPlanningLine := JobPlanningLine;
        Evaluate(DateForm, '<+1W>');
        NewJobPlanningLine.Validate("Planning Date", CalcDate(DateForm, JobPlanningLine."Planning Date"));
        NewJobPlanningLine.Validate("Line No.", LibraryJob.GetNextLineNo(JobPlanningLine));
        NewJobPlanningLine.Insert(true);

        // earlier, but contract line
        NewJobPlanningLine := JobPlanningLine;
        Evaluate(DateForm, '<-1W>');
        NewJobPlanningLine.Validate("Line Type", LibraryJob.PlanningLineTypeContract());
        NewJobPlanningLine.Validate("Planning Date", CalcDate(DateForm, JobPlanningLine."Planning Date"));
        NewJobPlanningLine.Validate("Line No.", LibraryJob.GetNextLineNo(JobPlanningLine));
        NewJobPlanningLine.Insert(true);

        // earlier, but usage link disabled
        Job.Get(JobPlanningLine."Job No.");
        if not Job."Apply Usage Link" then begin
            NewJobPlanningLine := JobPlanningLine;
            NewJobPlanningLine.Validate("Usage Link", false);
            NewJobPlanningLine.Validate("Planning Date", CalcDate(DateForm, JobPlanningLine."Planning Date"));
            NewJobPlanningLine.Validate("Line No.", LibraryJob.GetNextLineNo(JobPlanningLine));
            NewJobPlanningLine.Insert(true)
        end;

        // earlier, but opposite sign for quantity
        NewJobPlanningLine := JobPlanningLine;
        NewJobPlanningLine.Validate(Quantity, -JobPlanningLine.Quantity);
        NewJobPlanningLine.Validate("Planning Date", CalcDate('<-1W>', JobPlanningLine."Planning Date"));
        NewJobPlanningLine.Validate("Line No.", LibraryJob.GetNextLineNo(JobPlanningLine));
        NewJobPlanningLine.Insert(true);
    end;

    local procedure VerifyUsageLink(JobPlanningLine: Record "Job Planning Line"; JobLedgerEntry: Record "Job Ledger Entry")
    var
        JobUsageLink: Record "Job Usage Link";
    begin
        Assert.IsTrue(
          JobUsageLink.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line No.",
            JobLedgerEntry."Entry No."), 'Usage link should have been created');

        JobPlanningLine.TestField("Usage Link", true)
    end;

    local procedure VerifyJobPlanningLine(BeforeJobPlanningLine: Record "Job Planning Line"; AfterJobPlanningLine: Record "Job Planning Line"; JobJournalLine: Record "Job Journal Line")
    var
        Precision: Decimal;
        Sign: Integer;
    begin
        Assert.AreNotEqual(0, BeforeJobPlanningLine.Quantity, 'No planned quantity.');

        // Get the sign of the planned quantity
        Sign := BeforeJobPlanningLine.Quantity / Abs(BeforeJobPlanningLine.Quantity);

        AfterJobPlanningLine.TestField(
          Quantity,
          Sign * Max(Sign * BeforeJobPlanningLine.Quantity, Sign * (JobJournalLine.Quantity + BeforeJobPlanningLine."Qty. Posted")));
        AfterJobPlanningLine.TestField("Qty. Posted", BeforeJobPlanningLine."Qty. Posted" + JobJournalLine.Quantity);
        AfterJobPlanningLine.TestField("Qty. to Transfer to Journal", AfterJobPlanningLine.Quantity - (JobJournalLine.Quantity + BeforeJobPlanningLine."Qty. Posted"));
        AfterJobPlanningLine.TestField("Remaining Qty.", AfterJobPlanningLine.Quantity - AfterJobPlanningLine."Qty. Posted");

        AfterJobPlanningLine.TestField("Posted Total Cost", BeforeJobPlanningLine."Posted Total Cost" + Round(JobJournalLine."Total Cost"));
        AfterJobPlanningLine.TestField(
          "Posted Total Cost (LCY)", BeforeJobPlanningLine."Posted Total Cost (LCY)" + Round(JobJournalLine."Total Cost (LCY)"));
        Assert.AreNearlyEqual(
          BeforeJobPlanningLine."Posted Line Amount" + JobJournalLine."Line Amount", AfterJobPlanningLine."Posted Line Amount", 0.01,
          'Posted line Amoung on After Line Matches');

        Precision := LibraryJob.GetAmountRoundingPrecision(AfterJobPlanningLine."Currency Code");
        AfterJobPlanningLine.TestField("Remaining Total Cost", Round(AfterJobPlanningLine."Remaining Qty." * AfterJobPlanningLine."Unit Cost", Precision));
        AfterJobPlanningLine.TestField("Remaining Total Cost (LCY)", Round(AfterJobPlanningLine."Remaining Qty." * AfterJobPlanningLine."Unit Cost", Precision));
        AfterJobPlanningLine.TestField("Remaining Line Amount", Round(AfterJobPlanningLine."Remaining Qty." * AfterJobPlanningLine."Unit Price"));
        AfterJobPlanningLine.TestField("Remaining Line Amount (LCY)", Round(AfterJobPlanningLine."Remaining Qty." * AfterJobPlanningLine."Unit Price (LCY)"))
    end;

    local procedure AttachJobTaskToServiceDoc(JobTask: Record "Job Task"; var ServiceHeader: Record "Service Header")
    var
        ServiceLine: Record "Service Line";
        Counter: Integer;
    begin
        GetServiceLines(ServiceHeader, ServiceLine);
        repeat
            Counter += 1;
            ServiceLine.Validate("Job No.", JobTask."Job No.");
            ServiceLine.Validate("Job Task No.", JobTask."Job Task No.");
            ServiceLine.Validate("Job Line Type", Counter mod 4);  // Remainder of division by 4 ensures selection of each Job Line Type.
            ServiceLine.Modify(true)
        until ServiceLine.Next() = 0
    end;

    local procedure CopyServiceLines(var FromServiceLine: Record "Service Line"; var ToServiceLine: Record "Service Line")
    begin
        if FromServiceLine.FindSet() then
            repeat
                ToServiceLine.Init();
                ToServiceLine := FromServiceLine;
                ToServiceLine.Insert();
            until FromServiceLine.Next() = 0
    end;

    local procedure CreateServiceOrderWithJob(var ServiceHeader: Record "Service Header"; ConsumptionFactor: Decimal)
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        Job: Record Job;
        JobTask: Record "Job Task";
        Customer: Record Customer;
        Counter: Integer;
    begin
        // Create a new Job, Service Order - Service Header, Service Item Line and Service Lines of Job Line Type as blank,
        // Budget, Billable, Both Budget and Billable and Type as Item and Resource.


        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Shipping Advice", Customer."Shipping Advice"::Partial);
        Customer.Modify(true);
        LibraryJob.CreateJob(Job, Customer."No.");

        LibraryJob.CreateJobTask(Job, JobTask);

        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Job."Bill-to Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');

        for Counter := 1 to 4 do begin
            CreateServiceLine(ServiceItemLine, ServiceLine.Type::Item, ConsumptionFactor, ServiceLine);
            CreateServiceLine(ServiceItemLine, ServiceLine.Type::Resource, ConsumptionFactor, ServiceLine);
        end;

        AttachJobTaskToServiceDoc(JobTask, ServiceHeader)
    end;

    local procedure CreateServiceLine(ServiceItemLine: Record "Service Item Line"; Type: Enum "Service Line Type"; ConsumptionFactor: Decimal; var ServiceLine: Record "Service Line")
    var
        ServiceHeader: Record "Service Header";
        ConsumableNo: Code[20];
    begin
        ServiceHeader.Get(ServiceItemLine."Document Type", ServiceItemLine."Document No.");

        ConsumableNo := LibraryJob.FindConsumable(LibraryJob.Service2JobConsumableType(Type));
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, Type, ConsumableNo);

        ServiceLine.Validate(Description, Format(LibraryUtility.GenerateGUID()));
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10));
        ServiceLine.Validate("Location Code", '');

        // Multiply by ConsumptionFactor to determine Full/Partial Qty. to Ship and Qty. to Consume.
        ServiceLine.Validate("Qty. to Ship", ServiceLine.Quantity * ConsumptionFactor);
        ServiceLine.Validate("Qty. to Consume", ServiceLine."Qty. to Ship");
        ServiceLine.Modify(true)
    end;

    local procedure GetServiceLines(ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line")
    begin
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.FindSet();
    end;

    local procedure "Max"(x: Decimal; y: Decimal): Decimal
    begin
        if x > y then
            exit(x);
        exit(y)
    end;

    local procedure ModifyJobNoOnServiceLines(ServiceHeader: Record "Service Header"; JobNo: Code[20])
    var
        ServiceLine: Record "Service Line";
    begin
        GetServiceLines(ServiceHeader, ServiceLine);
        repeat
            ServiceLine.Validate("Job No.", JobNo);
            ServiceLine.Modify(true);
        until ServiceLine.Next() = 0;
    end;

    [Normal]
    local procedure VerifyServiceDocPostingForJob(ServiceLine: Record "Service Line")
    var
        ServiceShipmentHeader: Record "Service Shipment Header";
        TempJobJournalLine: Record "Job Journal Line" temporary;
    begin
        // Get the document number from the posted shipment.
        case ServiceLine."Document Type" of
            ServiceLine."Document Type"::Order:
                ServiceShipmentHeader.SetRange("Order No.", ServiceLine."Document No.");
            ServiceLine."Document Type"::Invoice:
                ServiceShipmentHeader.SetRange("Order No.", ServiceLine."Document No.");
            else
                Assert.Fail(StrSubstNo('Unsupported service document type: %1', ServiceLine."Document Type"))
        end;
        Assert.AreEqual(1, ServiceShipmentHeader.Count, '# service shipment headers.');
        ServiceShipmentHeader.FindFirst();
        // Use a job journal line to verify.
        TempJobJournalLine."Job No." := ServiceLine."Job No.";
        TempJobJournalLine."Job Task No." := ServiceLine."Job Task No.";
        TempJobJournalLine."Document No." := ServiceShipmentHeader."No.";
        TempJobJournalLine."Line Type" := ServiceLine."Job Line Type";
        TempJobJournalLine.Description := ServiceLine.Description;
        TempJobJournalLine.Quantity := ServiceLine."Qty. to Consume";
        TempJobJournalLine."Unit Cost (LCY)" := ServiceLine."Unit Cost (LCY)";
        TempJobJournalLine."Unit Price (LCY)" := ServiceLine."Unit Price";
        TempJobJournalLine.Insert();

        LibraryJob.VerifyJobJournalPosting(false, TempJobJournalLine)
    end;

    local procedure VerifyJobConsumedError(ServiceLine: Record "Service Line")
    begin
        Assert.ExpectedTestFieldError(ServiceLine.FieldCaption("Quantity Consumed"), Format(0));
    end;

    local procedure VerifyJobFieldsOnServiceLines(ServiceHeader: Record "Service Header")
    var
        ServiceLine: Record "Service Line";
    begin
        GetServiceLines(ServiceHeader, ServiceLine);
        repeat
            ServiceLine.TestField("Job Task No.", '');
            ServiceLine.TestField("Job Line Type", ServiceLine."Job Line Type"::" ");
        until ServiceLine.Next() = 0
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true
    end;
}

