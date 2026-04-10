codeunit 136307 "Job Consumption - Planning"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Job]
    end;

    var
        LibraryJob: Codeunit "Library - Job";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Initialized: Boolean;
        ItemNo: Code[20];
        PlanningLineQuantity: Decimal;
        TotalQuantity: Decimal;
        LineTypeRef: Option " ",Budget,Billable,"Both Budget and Billable";
        WrongQtyOnPlanningLineMsg: Label 'Qty. is not transfer to right field on Project Planning Line.';

    [Test]
    [Scope('OnPrem')]
    procedure TransferScheduledItem()
    begin
        // Transfer a scheduled item line to job journal
        Transfer2Journal(LibraryJob.PlanningLineTypeSchedule(), LibraryJob.ItemType(), 1)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferScheduledResource()
    begin
        // Transfer a scheduled resource line to job journal
        Transfer2Journal(LibraryJob.PlanningLineTypeSchedule(), LibraryJob.ResourceType(), 1)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferScheduledGL()
    begin
        // Transfer a scheduled GL line to job journal
        Transfer2Journal(LibraryJob.PlanningLineTypeSchedule(), LibraryJob.GLAccountType(), 1)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferBothItem()
    begin
        // Transfer a both scheduled and contracted item line to job journal
        Transfer2Journal(LibraryJob.PlanningLineTypeBoth(), LibraryJob.ItemType(), 1)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferBothResource()
    begin
        // Transfer a both scheduled and contracted resource line to job journal
        Transfer2Journal(LibraryJob.PlanningLineTypeBoth(), LibraryJob.ResourceType(), 1)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferBothGL()
    begin
        // Transfer a both scheduled and contracted GL line to job journal
        Transfer2Journal(LibraryJob.PlanningLineTypeBoth(), LibraryJob.GLAccountType(), 1)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferContractItem()
    begin
        // Transfer a contracted planning line to job journal
        Transfer2Journal(LibraryJob.PlanningLineTypeContract(), LibraryJob.ItemType(), 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PTransferScheduledItem()
    begin
        // Partially transfer a scheduled item line to job journal
        Transfer2Journal(LibraryJob.PlanningLineTypeSchedule(), LibraryJob.ItemType(), LibraryRandom.RandInt(99) / 100)
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure ReservationForJobWithSalesReturnOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        JobPlanningLine: Record "Job Planning Line";
    begin
        // Check Reservation for Jobs with Sales Return Order.

        // Setup: Create and post Sales Return Order.
        Initialize();
        CreateSalesReturnOrder(SalesLine);
        CreateReservationOnJobPlanningLine(
          JobPlanningLine, SalesLine."No.", SalesLine."Location Code", SalesLine."Variant Code", JobPlanningLine.Reserve::Always);
        SalesHeader.Get(SalesLine."Document Type"::"Return Order", SalesLine."Document No.");
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        ItemNo := JobPlanningLine."No.";  // Assign in global variable.
        PlanningLineQuantity := JobPlanningLine.Quantity;  // Assign in global variable.
        TotalQuantity := SalesLine.Quantity;  // Assign in global variable.

        // Exercise.
        OpenPlanningLinePage(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.");

        // Verify: Verify Reservation page values. Verification done in 'ReserveForSalesReturnOrderHandler'.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeUOMOnJobPlanningLineForItem()
    var
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        ItemNo: Code[20];
        ItemUnitOfMeasureCode: Code[10];
    begin
        // Test Unit Cost, Unit Price, Total Price and Unit of Measure Code on Job Planning Line after changing Unit of Measure Code.

        // 1. Setup: Create Job with Job Task, Item and Create Item Unit Of Measure.
        Initialize();
        CreateJobWithJobTask(JobTask);
        ItemNo := LibraryJob.CreateConsumable("Job Planning Line Type"::Item);
        ItemUnitOfMeasureCode := CreateItemUOM(ItemNo);

        // 2. Exercise: Create Job Planning Line with created Item and Change Unit of Measure on Job Planning Line.
        CreateReservationOnJobPlanningLine(JobPlanningLine, ItemNo, '', '', JobPlanningLine.Reserve::Optional);
        JobPlanningLine.Validate("Unit of Measure Code", ItemUnitOfMeasureCode);
        JobPlanningLine.Modify(true);

        // 3. Verify: Verify values on Job Planning Lines.
        VerifyJobPlanningLineForItemUOM(JobPlanningLine, ItemNo, ItemUnitOfMeasureCode);
    end;

    [Test]
    [HandlerFunctions('JobTransferToSalesInvoiceRequestPageHandler,MessageHandler,JobCalculateWIPRequestPageHandler,ConfirmHandlerFalse')]
    [Scope('OnPrem')]
    procedure CheckCalcRecogCostAmount()
    var
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        Job: Record Job;
        JobCreateInvoice: Codeunit "Job Create-Invoice";
    begin
        // Verify the Calc. Recog. Costs Amount on Job after running the Calculate WIP with Job Task Lines.

        // Setup: Create Job with multiple Job Task and Create Job Planning Line.
        Initialize();
        CreateJobWithMultipleJobTask(Job, JobTask);
        CreateJobPlanningLine(JobPlanningLine, JobTask);
        UpdateCustomerWithGenBusPostingGroup(Job."Bill-to Customer No.", JobPlanningLine."Gen. Bus. Posting Group");
        Commit();
        JobCreateInvoice.CreateSalesInvoice(JobPlanningLine, false);
        FindAndPostSalesInvoice(Job."Bill-to Customer No.");

        // Exercise: Calculate WIP.
        Job.SetRange("No.", Job."No.");
        REPORT.Run(REPORT::"Job Calculate WIP", true, false, Job);

        // Verify: Verifying Calc. Recog. Costs Amount on Job.
        VerifyCalcRecogCostsAmount(JobPlanningLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerMultipleResponses,MessageHandler,JobCalculateWIPRequestPageHandler')]
    [Scope('OnPrem')]
    procedure WIPEntryAmountInJobWIPEntry()
    var
        Job: Record Job;
    begin
        // Verify WIP Entry Amount on Job after running the Calculate WIP on Job.

        // Setup: Create Job, Job Task, Create Job Planning Line and posting Job Journal after creating Job Journal Line.
        Initialize();
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(true);
        CreateJobWithWIPMethod(Job, CreateJobWIPMethod(), Job."WIP Posting Method"::"Per Job Ledger Entry", true);
        CreateAndPostJobJournal(Job);

        // Exercise: Calculate WIP.
        Job.SetRange("No.", Job."No.");
        Job.SetFilter(
          "Posting Date Filter", '%1..%2', WorkDate(), CalcDate(StrSubstNo('<%1M>', LibraryRandom.RandInt(3)), WorkDate()));
        LibraryVariableStorage.Enqueue(false);
        REPORT.Run(REPORT::"Job Calculate WIP", true, false, Job);

        // Verify: Verifying WIP Amount in Job WIP Entry.
        VerifyWIPEntryAmountInJobWIPEntry(Job, WorkDate(), CalcDate(StrSubstNo('<%1M>', LibraryRandom.RandInt(3)), WorkDate()));
    end;

    [Test]
    [HandlerFunctions('JobJournalCofirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TransferToJobPlanningLineBudget()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        JobUsageLink: Record "Job Usage Link";
    begin
        // [SCENARIO 380443] Check Transfer Job Lenger Entry to Job Planning Line procedure
        Initialize();

        // [GIVEN] Posted Job Journal Line
        CreatePostJobJournalLine(Job, JobTask, true, false);

        // [WHEN] Transfer Job Lenger Entry to Job Planning Line with "Budget" option
        TransferToPlanngLine(Job, LineTypeRef::Budget);

        // [THEN] Job Planning Line with type "Budget" is linked to Job Ledger Entry
        JobUsageLinkApplied(JobUsageLink, Job, JobPlanningLine."Line Type"::Budget);
        Assert.RecordIsNotEmpty(JobUsageLink);

        // [THEN] "Qty. to Transfer to Journal" is zero
        VerifyQtyToTransferToJournal(Job);
    end;

    [Test]
    [HandlerFunctions('JobJournalCofirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TransferToJobPlanningLineBillable()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        JobUsageLink: Record "Job Usage Link";
    begin
        // [SCENARIO 380443] Check Transfer Job Lenger Entry to Job Planning Line procedure
        Initialize();

        // [GIVEN] Posted Job Journal Line,
        CreatePostJobJournalLine(Job, JobTask, true, false);

        // [WHEN] Transfer Job Lenger Entry to Job Planning Line with "Billable" option
        TransferToPlanngLine(Job, LineTypeRef::Billable);

        // [THEN] Job Planning Line with type "Billable" has no link to Job Ledger Entry
        JobUsageLinkApplied(JobUsageLink, Job, JobPlanningLine."Line Type"::Billable);
        Assert.RecordIsEmpty(JobUsageLink);

        // [THEN] "Qty. to Transfer to Journal" is zero
        VerifyQtyToTransferToJournal(Job);
    end;

    [Test]
    [HandlerFunctions('JobJournalCofirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TransferToJobPlanningLineBothOff()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        JobUsageLink: Record "Job Usage Link";
    begin
        // [SCENARIO 380443] Check Transfer Job Lenger Entry to Job Planning Line procedure
        Initialize();

        // [GIVEN] Job option "Allow Schedule/Contract Lines" is swiched off
        // [GIVEN] Posted Job Journal Line
        CreatePostJobJournalLine(Job, JobTask, true, false);

        // [WHEN] Transfer Job Lenger Entry to Job Planning Line with "Both Budget and Billable" option
        TransferToPlanngLine(Job, LineTypeRef::"Both Budget and Billable");

        // [THEN] Job Planning Line with type "Budget" is linked to Job Ledger Entry
        JobUsageLinkApplied(JobUsageLink, Job, JobPlanningLine."Line Type"::Budget);
        Assert.RecordIsNotEmpty(JobUsageLink);

        // [THEN] Job Planning Line with type "Billable" has no link to Job Ledger Entry
        JobUsageLinkApplied(JobUsageLink, Job, JobPlanningLine."Line Type"::Billable);
        Assert.RecordIsEmpty(JobUsageLink);

        // [THEN] "Qty. to Transfer to Journal" is zero
        VerifyQtyToTransferToJournal(Job);
    end;

    [Test]
    [HandlerFunctions('JobJournalCofirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TransferToJobPlanningLineBothOn()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobUsageLink: Record "Job Usage Link";
        JobPlanningLine: Record "Job Planning Line";
    begin
        // [SCENARIO 380443] Check Transfer Job Lenger Entry to Job Planning Line procedure
        Initialize();

        // [GIVEN] Job option "Allow Schedule/Contract Lines" is swiched on
        // [GIVEN] Posted Job Journal Line
        CreatePostJobJournalLine(Job, JobTask, true, true);

        // [WHEN] Transfer Job Lenger Entry to Job Planning Line with "Both Budget and Billable" option
        TransferToPlanngLine(Job, LineTypeRef::"Both Budget and Billable");

        // [THEN] Job Planning Line with type "Both Budget and Billable" is linked to Job Ledger Entry
        JobUsageLinkApplied(JobUsageLink, Job, JobPlanningLine."Line Type"::"Both Budget and Billable");
        Assert.RecordIsNotEmpty(JobUsageLink);

        // [THEN] "Qty. to Transfer to Journal" is zero
        VerifyQtyToTransferToJournal(Job);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestBlockedJobPlanningLinesNotEditable()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        JobCard: TestPage "Job Card";
        JobPlanningLines: TestPage "Job Planning Lines";
    begin
        // [SCENARIO] Job Planning Lines are not editable for a blocked Job
        Initialize();
        // [GIVEN] A Job with Blocked::All and planning lines
        CreateJobWithJobTask(JobTask);
        CreateJobPlanningLine(JobPlanningLine, JobTask);
        Job.Get(JobTask."Job No.");
        BlockJobForAll(Job);

        // [WHEN] Opening the Job Planning Lines
        JobPlanningLines.Trap();
        JobCard.OpenView();
        JobCard.GotoRecord(Job);
        JobCard.JobPlanningLines.Invoke();

        // [THEN] The page is not editable
        Assert.IsFalse(JobPlanningLines.Editable(), 'Job Planning Lines page should not be editable');
    end;

    [Test]
    [HandlerFunctions('JobJournalCofirmHandler,MessageHandler')]
    procedure VerifyPostedAndRemainingQtyOnTransferToJobPlanningLineFromJobLedgerEntry()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
    begin
        // [SCENARIO 459777] Verify Qty. Posted and Remaining Qty. on Job Planning Line after Transfer to Job Planning Line action from Job Ledger Entry
        Initialize();

        // [GIVEN] Create Job, Job Task, Job Journal Line and Post Job Journal Line
        CreatePostJobJournalLineWithItem(Job, JobTask, true);

        // [WHEN] Transfer Job Lenger Entry to Job Planning Line with "Budget" option
        TransferToPlanngLine(Job, LineTypeRef::Budget);

        // [THEN] Verify Qty. on Job Planning Line        
        FindJobPlanningLine(JobTask, JobPlanningLine, true);
        Assert.IsTrue(JobPlanningLine."Qty. Posted" <> 0, WrongQtyOnPlanningLineMsg);
        Assert.IsTrue(JobPlanningLine."Remaining Qty." = 0, WrongQtyOnPlanningLineMsg);
        Assert.IsTrue(JobPlanningLine."Remaining Qty. (Base)" = 0, WrongQtyOnPlanningLineMsg);

        // [THEN] Verify Usage Link exist
        VerifyUsageLinkExist(JobPlanningLine, true);

        // [WHEN] Transfer Job Lenger Entry to Job Planning Line with "Budget" option second time
        TransferToPlanngLine(Job, LineTypeRef::Budget);

        // [THEN] Verify Qty. on Job Planning Line        
        FindJobPlanningLine(JobTask, JobPlanningLine, false);
        Assert.IsTrue(JobPlanningLine."Qty. Posted" = 0, WrongQtyOnPlanningLineMsg);
        Assert.IsTrue(JobPlanningLine."Remaining Qty." <> 0, WrongQtyOnPlanningLineMsg);
        Assert.IsTrue(JobPlanningLine."Remaining Qty. (Base)" <> 0, WrongQtyOnPlanningLineMsg);

        // [THEN] Verify Usage Link not exist
        VerifyUsageLinkExist(JobPlanningLine, false);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Job Consumption - Planning");
        Clear(ItemNo);
        Clear(PlanningLineQuantity);
        Clear(TotalQuantity);

        if Initialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Job Consumption - Planning");

        LibraryERMCountryData.UpdateVATPostingSetup();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibrarySales.SetStockoutWarning(false);

        Initialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Job Consumption - Planning");
    end;

    local procedure CreateUOM(ConsumableType: Enum "Job Planning Line Type"; No: Code[20]): Code[10]
    begin
        case ConsumableType of
            LibraryJob.ItemType():
                exit(CreateItemUOM(No));
            LibraryJob.ResourceType():
                exit(CreateResourceUOM(No));
            else
                Error('Unsupported consumable type: %1', ConsumableType);
        end
    end;

    local procedure CreateItemUOM(ItemNo: Code[20]): Code[10]
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, ItemNo, 1);
        exit(ItemUnitOfMeasure.Code);
    end;

    local procedure CreateAndPostJobJournal(var Job: Record Job)
    var
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        JobJournalLine: Record "Job Journal Line";
    begin
        CreateJobTask(JobTask, Job);
        LibraryJob.CreateJobPlanningLine(
          JobPlanningLine."Line Type"::Budget, JobPlanningLine.Type::"G/L Account", JobTask, JobPlanningLine);
        CreateJobJournalLine(JobJournalLine, JobTask, JobPlanningLine, WorkDate());
        CreateJobJournalLine(
          JobJournalLine, JobTask, JobPlanningLine, CalcDate(StrSubstNo('<%1Y>', LibraryRandom.RandInt(3)), WorkDate()));
        LibraryJob.PostJobJournal(JobJournalLine);
    end;

    local procedure CreateJobJournalLine(var JobJournalLine: Record "Job Journal Line"; JobTask: Record "Job Task"; JobPlanningLine: Record "Job Planning Line"; PostingDate: Date)
    begin
        LibraryJob.CreateJobJournalLineForType(
          JobPlanningLine."Line Type"::Budget, JobPlanningLine.Type::"G/L Account", JobTask, JobJournalLine);
        JobJournalLine.Validate("No.", JobPlanningLine."No.");
        JobJournalLine.Validate(Quantity, JobPlanningLine.Quantity);
        JobJournalLine.Validate("Unit Cost", LibraryRandom.RandDec(100, 2));
        JobJournalLine.Validate("Posting Date", PostingDate);
        JobJournalLine.Modify(true);
    end;

    local procedure CreateJobWithJobTask(var JobTask: Record "Job Task")
    var
        Job: Record Job;
    begin
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
    end;

    local procedure CreateJobWithMultipleJobTask(var Job: Record Job; var JobTask: Record "Job Task")
    begin
        CreateJobWithWIPMethod(Job, CreateJobWIPMethod(), Job."WIP Posting Method"::"Per Job Ledger Entry", true);
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryJob.CreateJobTask(Job, JobTask);
    end;

    local procedure CreateJobWIPMethod(): Code[20]
    var
        JobWIPMethod: Record "Job WIP Method";
    begin
        LibraryJob.CreateJobWIPMethod(JobWIPMethod);
        JobWIPMethod.Validate("Recognized Costs", JobWIPMethod."Recognized Costs"::"Cost of Sales");
        JobWIPMethod.Modify(true);
        exit(JobWIPMethod.Code);
    end;

    local procedure CreateJobWithWIPMethod(var Job: Record Job; JobWIPMethodCode: Code[20]; WIPPostingMethod: Option; ApplyUsageLink: Boolean)
    var
        JobPostingGroup: Record "Job Posting Group";
    begin
        LibraryJob.CreateJob(Job);
        JobPostingGroup.Get(Job."Job Posting Group");
        LibraryJob.UpdateJobPostingGroup(JobPostingGroup);
        Job.Validate("WIP Method", JobWIPMethodCode);
        Job.Validate("WIP Posting Method", WIPPostingMethod);
        Job.Validate("Apply Usage Link", ApplyUsageLink);
        Job.Modify(true);
    end;

    local procedure CreateJobPlanningLine(var JobPlanningLine: Record "Job Planning Line"; JobTask: Record "Job Task")
    begin
        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::"Both Budget and Billable", JobPlanningLine.Type::"G/L Account", JobTask, JobPlanningLine);
        JobPlanningLine.Validate(Quantity, LibraryRandom.RandInt(5));
        JobPlanningLine.Validate("Unit Cost", LibraryRandom.RandDec(100, 2));
        JobPlanningLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        JobPlanningLine.Modify(true);
    end;

    local procedure CreateJobTask(var JobTask: Record "Job Task"; Job: Record Job)
    begin
        LibraryJob.CreateJobTask(Job, JobTask);
        JobTask.Validate("WIP-Total", JobTask."WIP-Total"::Total);
        JobTask.Modify(true);
    end;

    local procedure CreateResourceUOM(ResourceNo: Code[20]): Code[10]
    var
        UnitOfMeasure: Record "Unit of Measure";
        ResourceUnitOfMeasure: Record "Resource Unit of Measure";
        LibraryResource: Codeunit "Library - Resource";
    begin
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryResource.CreateResourceUnitOfMeasure(ResourceUnitOfMeasure, ResourceNo, UnitOfMeasure.Code, 1);
        exit(ResourceUnitOfMeasure.Code);
    end;

    local procedure CreateSalesReturnOrder(var SalesLine: Record "Sales Line")
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        Location: Record Location;
        Customer: Record Customer;
        LibraryWarehouse: Codeunit "Library - Warehouse";
    begin
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateCustomer(Customer);
        CreateSalesDocument(
          SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", Customer."No.",
          LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location), Item."No.");
        SalesLine.Validate("Return Qty. to Receive", SalesLine.Quantity);
        SalesLine.Modify(true);
    end;

    local procedure CreateReservationOnJobPlanningLine(var JobPlanningLine: Record "Job Planning Line"; No: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; Reserve: Enum "Reserve Method")
    var
        Job: Record Job;
        JobTask: Record "Job Task";
    begin
        CreateJobWithJobTask(JobTask);
        Job.Get(JobTask."Job No.");
        Job.Validate("Apply Usage Link", true);
        Job.Modify(true);
        LibraryJob.CreateJobPlanningLine(LibraryJob.PlanningLineTypeSchedule(), LibraryJob.ItemType(), JobTask, JobPlanningLine);
        JobPlanningLine.Validate(Type, JobPlanningLine.Type::Item);
        JobPlanningLine.Validate("No.", No);
        JobPlanningLine.Validate("Usage Link", true);
        JobPlanningLine.Validate(Reserve, Reserve);
        JobPlanningLine.Validate("Variant Code", VariantCode);
        JobPlanningLine.Validate("Location Code", LocationCode);
        JobPlanningLine.Modify(true);
        Commit();
        ModifyJobPlanningLine(Job."No.");
        JobPlanningLine.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line No.");
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]; LocationCode: Code[10]; No: Code[20])
    var
        ItemVariant: Record "Item Variant";
    begin
        ItemVariant.FindFirst();
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, No, LibraryRandom.RandDec(10, 2) + 10);  // Taken 10 here because Sales Line needs greater value than Planning Line.
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(10, 2));
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Validate("Variant Code", LibraryInventory.CreateItemVariant(ItemVariant, No));
        SalesLine.Modify(true);
    end;

    local procedure BlockJobForAll(var Job: Record Job)
    begin
        Job.Blocked := Job.Blocked::All;
        Job.Modify();
    end;

    local procedure FindAndPostSalesInvoice(CustomerNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
        SalesHeader.SetRange("Sell-to Customer No.", CustomerNo);
        SalesHeader.FindFirst();
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure OpenPlanningLinePage(JobNo: Code[20]; JobTaskNo: Code[20])
    var
        JobPlanningLines: TestPage "Job Planning Lines";
    begin
        JobPlanningLines.OpenEdit();
        JobPlanningLines.FILTER.SetFilter("Job No.", JobNo);
        JobPlanningLines.FILTER.SetFilter("Job Task No.", JobTaskNo);
        JobPlanningLines.Reserve.Invoke();
        Commit();
    end;

    local procedure ModifyJobPlanningLine(No: Code[20])
    var
        JobPlanningLines: TestPage "Job Planning Lines";
    begin
        JobPlanningLines.OpenEdit();
        JobPlanningLines.FILTER.SetFilter("Job No.", No);
        JobPlanningLines.Quantity.SetValue(LibraryRandom.RandDec(10, 2));  // Used Random values for Quantity.
        JobPlanningLines."Unit Cost".SetValue(LibraryRandom.RandDec(10, 2));  // Used Random values for Unit Cost.
        JobPlanningLines.OK().Invoke();
    end;

    local procedure Transfer2Journal(LineType: Enum "Job Planning Line Line Type"; ConsumableType: Enum "Job Planning Line Type"; Fraction: Decimal)
    var
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        JobJournalLine: Record "Job Journal Line";
        JobJournalTemplate: Record "Job Journal Template";
        JobJournalBatch: Record "Job Journal Batch";
        Location: Record Location;
        ItemVariant: Record "Item Variant";
        JobTransferLine: Codeunit "Job Transfer Line";
        LibraryWarehouse: Codeunit "Library - Warehouse";
    begin
        // Create job, job task
        // Create job planning line with LineType and Type
        // Enable usage link
        // For Type = Item set location, variant
        // Set Qty. to Transfer to Journal
        // Transfer job planning line to journal
        // Verify journal line

        // Setup
        Initialize();
        CreateJobWithJobTask(JobTask);
        LibraryJob.CreateJobPlanningLine(LineType, ConsumableType, JobTask, JobPlanningLine);

        if JobPlanningLine."Schedule Line" then
            JobPlanningLine.Validate("Usage Link", true);
        if ConsumableType <> LibraryJob.GLAccountType() then
            JobPlanningLine.Validate("Unit of Measure Code", CreateUOM(JobPlanningLine.Type, JobPlanningLine."No."));
        if ConsumableType = LibraryJob.ItemType() then begin
            JobPlanningLine.Validate("Location Code", LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location));
            JobPlanningLine.Validate("Variant Code", LibraryInventory.CreateItemVariant(ItemVariant, JobPlanningLine."No."))
        end;
        JobPlanningLine.Validate("Qty. to Transfer to Journal", Fraction * JobPlanningLine.Quantity);
        JobPlanningLine.Modify(true);

        // Exercise
        JobTransferLine.FromPlanningLineToJnlLine(JobPlanningLine, WorkDate(), LibraryJob.GetJobJournalTemplate(JobJournalTemplate),
          LibraryJob.CreateJobJournalBatch(LibraryJob.GetJobJournalTemplate(JobJournalTemplate), JobJournalBatch), JobJournalLine);
        // Verify
        Assert.AreEqual(JobJournalLine."Job No.", JobPlanningLine."Job No.", JobJournalLine.FieldCaption("Job No."));
        Assert.AreEqual(JobJournalLine."Job Task No.", JobPlanningLine."Job Task No.", JobJournalLine.FieldCaption("Job Task No."));
        if JobPlanningLine."Schedule Line" then
            Assert.AreEqual(JobJournalLine."Job Planning Line No.", JobPlanningLine."Line No.", JobJournalLine.FieldCaption("Line No."))
        else
            Assert.AreEqual(JobJournalLine."Job Planning Line No.", 0, JobJournalLine.FieldCaption("Line No."));
        Assert.AreEqual(JobJournalLine."Posting Date", WorkDate(), JobJournalLine.FieldCaption("Posting Date"));
        Assert.AreEqual(JobJournalLine.Type, JobPlanningLine.Type, JobJournalLine.FieldCaption(Type));
        Assert.AreEqual(JobJournalLine."No.", JobPlanningLine."No.", JobJournalLine.FieldCaption("No."));
        Assert.AreEqual(JobJournalLine."Unit of Measure Code", JobPlanningLine."Unit of Measure Code", JobJournalLine.FieldCaption("Unit of Measure Code"));
        Assert.AreEqual(JobJournalLine."Location Code", JobPlanningLine."Location Code", JobJournalLine.FieldCaption("Location Code"));
        Assert.AreEqual(JobJournalLine."Variant Code", JobPlanningLine."Variant Code", JobJournalLine.FieldCaption("Variant Code"));
        Assert.AreEqual(JobJournalLine.Quantity, JobPlanningLine."Qty. to Transfer to Journal", JobJournalLine.FieldCaption(Quantity))
    end;

    local procedure UpdateCustomerWithGenBusPostingGroup(CustomerNo: Code[20]; GenBusinessPostingGroup: Code[20])
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustomerNo);
        Customer.Validate("Gen. Bus. Posting Group", GenBusinessPostingGroup);
        Customer.Modify(true);
    end;

    local procedure VerifyJobPlanningLineForItemUOM(JobPlanningLine: Record "Job Planning Line"; ItemNo: Code[20]; UnitOfMeasureCode: Code[10])
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        Assert.AreNearlyEqual(
          Item."Unit Price", JobPlanningLine."Unit Price", 0.01, 'Unit Price on the line matches unit price on job planning line');
        Assert.AreNearlyEqual(Item."Unit Cost", JobPlanningLine."Unit Cost", 0.01, 'Unit Cost matches item unit cost');
        Assert.AreNearlyEqual(Item."Unit Price" * JobPlanningLine.Quantity, JobPlanningLine."Total Price", 0.01, 'Total Price Matches');
        JobPlanningLine.TestField("Unit of Measure Code", UnitOfMeasureCode);
    end;

    local procedure VerifyCalcRecogCostsAmount(JobPlanningLine: Record "Job Planning Line")
    var
        Job: Record Job;
    begin
        Job.Get(JobPlanningLine."Job No.");
        Job.CalcFields("Calc. Recog. Costs Amount");
        Job.TestField("Calc. Recog. Costs Amount", JobPlanningLine.Quantity * JobPlanningLine."Unit Cost");
    end;

    local procedure VerifyWIPEntryAmountInJobWIPEntry(Job: Record Job; StartingDate: Date; EndingDate: Date)
    var
        JobLedgerEntry: Record "Job Ledger Entry";
        JobWIPEntry: Record "Job WIP Entry";
    begin
        JobLedgerEntry.SetRange("Job No.", Job."No.");
        JobLedgerEntry.SetFilter("Posting Date", '%1..%2', StartingDate, EndingDate);
        JobLedgerEntry.CalcSums("Total Cost");
        JobWIPEntry.SetRange("Job No.", Job."No.");
        JobWIPEntry.FindFirst();
        JobWIPEntry.TestField("WIP Entry Amount", -JobLedgerEntry."Total Cost");
    end;

    local procedure CreateJobJournal(var JobJournalLine: Record "Job Journal Line"; JobTask: Record "Job Task")
    var
        LibraryResource: Codeunit "Library - Resource";
    begin
        LibraryJob.CreateJobJournalLine(JobJournalLine."Line Type"::" ", JobTask, JobJournalLine);
        JobJournalLine.Validate(Type, JobJournalLine.Type::Resource);
        JobJournalLine.Validate("No.", LibraryResource.CreateResourceNo());
        JobJournalLine.Validate(Quantity, 1);
        JobJournalLine.Validate("Unit Cost", LibraryRandom.RandDec(100, 2));
        JobJournalLine.Modify(true);
    end;

    local procedure CreatePostJobJournalLine(var Job: Record Job; var JobTask: Record "Job Task"; ApplyUsageLink: Boolean; AllowScheduleContractLines: Boolean)
    var
        JobJournalLine: Record "Job Journal Line";
    begin
        LibraryJob.CreateJob(Job);
        Job.Validate("Apply Usage Link", ApplyUsageLink);
        Job.Validate("Allow Schedule/Contract Lines", AllowScheduleContractLines);
        Job.Modify(true);
        CreateJobTask(JobTask, Job);

        CreateJobJournal(JobJournalLine, JobTask);
        LibraryJob.PostJobJournal(JobJournalLine);
    end;

    local procedure TransferToPlanngLine(var Job: Record Job; LineType: Option)
    var
        JobLedgerEntry: Record "Job Ledger Entry";
        JobCalcBatches: Codeunit "Job Calculate Batches";
    begin
        FindJobLedgerEntry(JobLedgerEntry, Job);
        JobCalcBatches.TransferToPlanningLine(JobLedgerEntry, LineType);
    end;

    local procedure FindJobLedgerEntry(var JobLedgerEntry: Record "Job Ledger Entry"; Job: Record Job)
    begin
        JobLedgerEntry.SetRange("Job No.", Job."No.");
        JobLedgerEntry.FindFirst();
    end;

    local procedure JobUsageLinkApplied(var JobUsageLink: Record "Job Usage Link"; Job: Record Job; JobPlanningLineType: Enum "Job Planning Line Line Type")
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        JobPlanningLine.SetRange("Job No.", Job."No.");
        JobPlanningLine.SetRange("Line Type", JobPlanningLineType);
        JobPlanningLine.FindFirst();
        JobUsageLink.SetRange("Job No.", JobPlanningLine."Job No.");
        JobUsageLink.SetRange("Job Task No.", JobPlanningLine."Job Task No.");
        JobUsageLink.SetRange("Line No.", JobPlanningLine."Line No.");
    end;

    local procedure VerifyQtyToTransferToJournal(Job: Record Job)
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        JobPlanningLine.SetRange("Job No.", Job."No.");
        JobPlanningLine.FindSet();
        repeat
            JobPlanningLine.TestField("Qty. to Transfer to Journal", 0)
        until JobPlanningLine.Next() = 0;
    end;

    local procedure VerifyUsageLinkExist(JobPlanningLine: Record "Job Planning Line"; LinkExist: Boolean)
    var
        JobUsageLink: Record "Job Usage Link";
    begin
        JobUsageLink.SetRange("Job No.", JobPlanningLine."Job No.");
        JobUsageLink.SetRange("Job Task No.", JobPlanningLine."Job Task No.");
        JobUsageLink.SetRange("Line No.", JobPlanningLine."Line No.");
        if LinkExist then
            Assert.RecordIsNotEmpty(JobUsageLink)
        else
            Assert.RecordIsEmpty(JobUsageLink);
    end;

    local procedure FindJobPlanningLine(JobTask: Record "Job Task"; var JobPlanningLine: Record "Job Planning Line"; first: Boolean)
    begin
        JobPlanningLine.Reset();
        JobPlanningLine.SetRange("Job No.", JobTask."Job No.");
        JobPlanningLine.SetRange("Job Task No.", JobTask."Job Task No.");
        if first then
            JobPlanningLine.FindFirst()
        else
            JobPlanningLine.FindLast();
    end;

    local procedure CreatePostJobJournalLineWithItem(var Job: Record Job; var JobTask: Record "Job Task"; ApplyUsageLink: Boolean)
    var
        JobJournalLine: Record "Job Journal Line";
    begin
        LibraryJob.CreateJob(Job);
        Job.Validate("Apply Usage Link", ApplyUsageLink);
        Job.Modify(true);
        CreateJobTask(JobTask, Job);

        CreateJobJournalLineWithItem(JobJournalLine, JobTask);
        LibraryJob.PostJobJournal(JobJournalLine);
    end;

    local procedure CreateJobJournalLineWithItem(var JobJournalLine: Record "Job Journal Line"; JobTask: Record "Job Task")
    begin
        LibraryJob.CreateJobJournalLine(JobJournalLine."Line Type"::" ", JobTask, JobJournalLine);
        JobJournalLine.Validate(Type, JobJournalLine.Type::Item);
        JobJournalLine.Validate("No.", LibraryInventory.CreateItemNo());
        JobJournalLine.Validate(Quantity, 1);
        JobJournalLine.Validate("Unit Cost", LibraryRandom.RandDec(100, 2));
        JobJournalLine.Modify(true);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure JobCalculateWIPRequestPageHandler(var JobCalculateWIP: TestRequestPage "Job Calculate WIP")
    begin
        JobCalculateWIP.PostingDate.SetValue(WorkDate());
        JobCalculateWIP.DocumentNo.SetValue(LibraryUTUtility.GetNewCode());
        JobCalculateWIP.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure JobJournalCofirmHandler(ExpectedMessage: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure JobTransferToSalesInvoiceRequestPageHandler(var JobTransferToSalesInvoice: TestRequestPage "Job Transfer to Sales Invoice")
    begin
        JobTransferToSalesInvoice.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerFalse(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerMultipleResponses(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Message Handler.
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReservationPageHandler(var Reservation: TestPage Reservation)
    begin
        Reservation.ItemNo.AssertEquals(ItemNo);
        Reservation.QtyToReserveBase.AssertEquals(PlanningLineQuantity);
        Reservation.QtyReservedBase.AssertEquals(PlanningLineQuantity);
        Reservation."Total Quantity".AssertEquals(TotalQuantity);
        Reservation."Current Reserved Quantity".AssertEquals(PlanningLineQuantity);
        Reservation.TotalAvailableQuantity.AssertEquals(TotalQuantity - PlanningLineQuantity);
    end;
}

