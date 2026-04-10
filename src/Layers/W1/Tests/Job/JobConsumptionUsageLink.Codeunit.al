codeunit 136303 "Job Consumption - Usage Link"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Usage Link] [Job]
        Initialized := false
    end;

    var
        DummyJobsSetup: Record "Jobs Setup";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryResource: Codeunit "Library - Resource";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryJob: Codeunit "Library - Job";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        CopyFromToPriceListLine: Codeunit CopyFromToPriceListLine;
        Initialized: Boolean;
        UnitPriceErr: Label 'Unit Price is not correct, please refer setup in Project Resource Price.';
        ConfirmUsageWithBlankLineTypeQst: Label 'Usage will not be linked to the project planning line because the Line Type field is empty.\\Do you want to continue?';
        PostJournalLineQst: Label 'Do you want to post the journal lines?';
        JobPlanningLineRenameErr: Label 'You cannot change the %1 or %2 of this %3.', Comment = '%1 = Project Number field name; %2 = Project Task Number field name; %3 = Project Planning Line table name';

    [Test]
    [Scope('OnPrem')]
    procedure JobUsageLinking()
    var
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
    begin
        // Create planning lines for a job task with apply usage link enabled.
        // Verify that usage link is enabled for the created planning lines of type that include budget.
        // Verify that usage link cannot be disabled for the created planning lines of type that include budget.
        // Verify that usage link is disabled for the created planning lines of type that excludes budget.
        // Verify that usage link cannot be enabled for the created planning lines of type that exclude budget.

        // Setup
        Initialize();

        CreateJobWithTaskAndApplyUsageLink(JobTask);

        // Exercise
        CreateJobPlanningLinePerType(JobTask, JobPlanningLine);
        // Verify
        JobPlanningLine.SetRange("Schedule Line", true);
        JobPlanningLine.FindSet();
        repeat
            Assert.IsTrue(JobPlanningLine."Usage Link", JobPlanningLine.FieldCaption("Usage Link"));
            JobPlanningLine.Validate("Usage Link", false);
            // should still be true
            Assert.IsTrue(JobPlanningLine."Usage Link", JobPlanningLine.FieldCaption("Usage Link"));
        until JobPlanningLine.Next() = 0;

        JobPlanningLine.SetRange("Schedule Line", false);
        JobPlanningLine.FindFirst();
        Assert.IsFalse(JobPlanningLine."Usage Link", JobPlanningLine.FieldCaption("Usage Link"));
        asserterror JobPlanningLine.Validate("Usage Link", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobNoUsageLinking()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
    begin
        // Create planning lines for a job task with apply usage link disabled.
        // Verify that usage link is disabled for the created planning lines.
        // Verify that usage link can be enabled for planning lines of type that includes budget.
        // Verify that usage link cannot be enabled for planning lines of type that excludes budget.

        // Setup
        Initialize();

        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);

        // Exercise
        CreateJobPlanningLinePerType(JobTask, JobPlanningLine);
        // Verify
        JobPlanningLine.SetRange("Schedule Line", true);
        JobPlanningLine.FindSet();
        repeat
            Assert.IsFalse(JobPlanningLine."Usage Link", 'Usage link for line type that includes budget');
            JobPlanningLine.Validate("Usage Link", true);
            Assert.IsTrue(JobPlanningLine."Usage Link", 'Enabling usage link.');
        until JobPlanningLine.Next() = 0;

        JobPlanningLine.SetRange("Schedule Line", false);
        JobPlanningLine.FindFirst();
        Assert.IsFalse(JobPlanningLine."Usage Link", 'Usage link for line type that excludes budget');
        asserterror JobPlanningLine.Validate("Usage Link", true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure LinkScheduledItem()
    begin
        // [SCENARIO] Use a planning line (Type = Item, "Line Type" = Budget) with an explicit link (Job."Apply Usage Link" = FALSE), post execution, verify that link created and Quantities and Amounts are correct.

        UseLinked(LibraryJob.ItemType(), LibraryJob.PlanningLineTypeSchedule(), false, LibraryJob.JobConsumption())
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure LinkScheduledItemDefault()
    begin
        // [SCENARIO] Use a planning line (Type = Item, "Line Type" = Budget) with an explicit link (Job."Apply Usage Link" = TRUE), post execution, verify that link created and Quantities and Amounts are correct.

        UseLinked(LibraryJob.ItemType(), LibraryJob.PlanningLineTypeSchedule(), true, LibraryJob.JobConsumption())
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure LinkBothItem()
    begin
        // [SCENARIO] Use a planning line (Type = Item, "Line Type" = Budget & Billable) with an explicit link (Job."Apply Usage Link" = FALSE), post execution, verify that link created and Quantities and Amounts are correct.

        UseLinked(LibraryJob.ItemType(), LibraryJob.PlanningLineTypeBoth(), false, LibraryJob.JobConsumption())
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure LinkBothItemDefault()
    begin
        // [SCENARIO] Use a planning line (Type = Item, "Line Type" = Budget & Billable) with an explicit link (Job."Apply Usage Link" = TRUE), post execution, verify that link created and Quantities and Amounts are correct.

        UseLinked(LibraryJob.ItemType(), LibraryJob.PlanningLineTypeBoth(), true, LibraryJob.JobConsumption())
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure LinkScheduledResource()
    begin
        // [SCENARIO] Use a planning line (Type = Resource, "Line Type" = Budget) with an explicit link (Job."Apply Usage Link" = FALSE), post execution, verify that link created and Quantities and Amounts are correct.

        UseLinked(LibraryJob.ResourceType(), LibraryJob.PlanningLineTypeSchedule(), false, LibraryJob.JobConsumption())
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure LinkScheduledResourceDefault()
    begin
        // [SCENARIO] Use a planning line (Type = Resource, "Line Type" = Budget) with an explicit link (Job."Apply Usage Link" = TRUE), post execution, verify that link created and Quantities and Amounts are correct.

        UseLinked(LibraryJob.ResourceType(), LibraryJob.PlanningLineTypeSchedule(), true, LibraryJob.JobConsumption())
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure LinkBothResource()
    begin
        // [SCENARIO] Use a planning line (Type = Resource, "Line Type" = Budget & Billable) with an explicit link (Job."Apply Usage Link" = FALSE), post execution, verify that link created and Quantities and Amounts are correct.

        UseLinked(LibraryJob.ResourceType(), LibraryJob.PlanningLineTypeBoth(), false, LibraryJob.JobConsumption())
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure LinkBothResourceDefault()
    begin
        // [SCENARIO] Use a planning line (Type = Resource, "Line Type" = Budget & Billable) with an explicit link (Job."Apply Usage Link" = TRUE), post execution, verify that link created and Quantities and Amounts are correct.

        UseLinked(LibraryJob.ResourceType(), LibraryJob.PlanningLineTypeBoth(), true, LibraryJob.JobConsumption())
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure LinkScheduledGL()
    begin
        // [SCENARIO] Use a planning line (Type = G/L Account, "Line Type" = Budget) with an explicit link (Job."Apply Usage Link" = FALSE), post execution, verify that link created and Quantities and Amounts are correct.

        UseLinked(LibraryJob.GLAccountType(), LibraryJob.PlanningLineTypeSchedule(), false, LibraryJob.JobConsumption())
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure LinkScheduledGLDefault()
    begin
        // [SCENARIO] Use a planning line (Type = G/L Account, "Line Type" = Budget) with an explicit link (Job."Apply Usage Link" = TRUE), post execution, verify that link created and Quantities and Amounts are correct.

        UseLinked(LibraryJob.GLAccountType(), LibraryJob.PlanningLineTypeSchedule(), true, LibraryJob.JobConsumption())
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure LinkBothGL()
    begin
        // [SCENARIO] Use a planning line (Type = G/L Account, "Line Type" = Budget & Billable) with an explicit link (Job."Apply Usage Link" = FALSE), post execution, verify that link created and Quantities and Amounts are correct.

        UseLinked(LibraryJob.GLAccountType(), LibraryJob.PlanningLineTypeBoth(), false, LibraryJob.JobConsumption())
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure LinkBothGLDefault()
    begin
        // [SCENARIO] Use a planning line (Type = G/L Account, "Line Type" = Budget & Billable) with an explicit link (Job."Apply Usage Link" = TRUE), post execution, verify that link created and Quantities and Amounts are correct.

        UseLinked(LibraryJob.GLAccountType(), LibraryJob.PlanningLineTypeBoth(), true, LibraryJob.JobConsumption())
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure DeleteUsedPlanningLine()
    var
        JobLedgerEntry: Record "Job Ledger Entry";
        JobUsageLink: Record "Job Usage Link";
        JobPlanningLine: Record "Job Planning Line";
    begin
        // [SCENARIO] Check that Planning lines cannot be deleted if usage has been posted.

        UseLinked(LibraryJob.ItemType(), LibraryJob.PlanningLineTypeSchedule(), true, LibraryJob.JobConsumption());

        JobLedgerEntry.FindLast();
        JobUsageLink.SetRange("Entry No.", JobLedgerEntry."Entry No.");
        JobUsageLink.FindFirst();
        JobPlanningLine.Get(JobUsageLink."Job No.", JobUsageLink."Job Task No.", JobUsageLink."Line No.");
        asserterror JobPlanningLine.Delete(true)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LinkScheduledGenJournal()
    begin
        // [SCENARIO] Use a planning line (Type = G/L Account, "Line Type" = Budget) with an explicit link, post execution via Gen. Journal, verify that link created and Quantities and Amounts are correct.

        UseLinked(LibraryJob.GLAccountType(), LibraryJob.PlanningLineTypeSchedule(), false, LibraryJob.GenJournalConsumption())
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LinkBothGenJournal()
    begin
        // [SCENARIO] Use a planning line (Type = G/L Account, "Line Type" = Budget & Billable) with an explicit link, post execution via Gen. Journal, verify that link created and Quantities and Amounts are correct.

        UseLinked(LibraryJob.GLAccountType(), LibraryJob.PlanningLineTypeBoth(), false, LibraryJob.GenJournalConsumption())
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LinkScheduledPurchaseItem()
    begin
        // [SCENARIO] Use a planning line (Type = Item, "Line Type" = Budget) with an explicit link, post execution via Purchase Document, verify that link created and Quantities and Amounts are correct.

        UseLinked(LibraryJob.ItemType(), LibraryJob.PlanningLineTypeSchedule(), false, LibraryJob.PurchaseConsumption())
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LinkBothPurchaseItem()
    begin
        // [SCENARIO] Use a planning line (Type = Item, "Line Type" = Budget & Billable) with an explicit link, post execution via Purchase Document, verify that link created and Quantities and Amounts are correct.

        UseLinked(LibraryJob.ItemType(), LibraryJob.PlanningLineTypeBoth(), false, LibraryJob.PurchaseConsumption())
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LinkScheduledPurchaseGL()
    begin
        // [SCENARIO] Use a planning line (Type = G/L Account, "Line Type" = Budget) with an explicit link, post execution via Purchase Document, verify that link created and Quantities and Amounts are correct.

        UseLinked(LibraryJob.GLAccountType(), LibraryJob.PlanningLineTypeSchedule(), false, LibraryJob.PurchaseConsumption())
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LinkBothPurchaseGL()
    begin
        // [SCENARIO] Use a planning line (Type = G/L Account, "Line Type" = Budget & Billable) with an explicit link, post execution via Purchase Document, verify that link created and Quantities and Amounts are correct.

        UseLinked(LibraryJob.GLAccountType(), LibraryJob.PlanningLineTypeBoth(), false, LibraryJob.PurchaseConsumption())
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
        // via job journal, gl journal, or purchase
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
        LibraryJob.UseJobPlanningLineExplicit(JobPlanningLine, LibraryJob.UsageLineTypeBlank(), 1, Source, JobJournalLine);

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

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PLinkScheduledItem()
    begin
        // [SCENARIO] Verify that usage links created and Qtys and Amts are correct when planning line (Job."Apply Usage Link": FALSE, Type: Item, Line Type: Budget) used completely via job journal in two steps with an explicit link.

        PartialUseLinked(LibraryJob.ItemType(), LibraryJob.PlanningLineTypeSchedule(), false)
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PLinkUseScheduledItemDefault()
    begin
        // [SCENARIO] Verify that usage links created and Qtys and Amts are correct when planning line (Job."Apply Usage Link": TRUE, Type: Item, Line Type: Budget) used completely via job journal in two steps with an explicit link.

        PartialUseLinked(LibraryJob.ItemType(), LibraryJob.PlanningLineTypeSchedule(), true)
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PLinkUseBothItem()
    begin
        // [SCENARIO] Verify that usage links created and Qtys and Amts are correct when planning line (Job."Apply Usage Link": FALSE, Type: Item, Line Type: Budget & Billable) used completely via job journal in two steps with an explicit link.

        PartialUseLinked(LibraryJob.ItemType(), LibraryJob.PlanningLineTypeBoth(), false)
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PLinkBothItemDefault()
    begin
        // [SCENARIO] Verify that usage links created and Qtys and Amts are correct when planning line (Job."Apply Usage Link": TRUE, Type: Item, Line Type: Budget & Billable) used completely via job journal in two steps with an explicit link.

        PartialUseLinked(LibraryJob.ItemType(), LibraryJob.PlanningLineTypeBoth(), true)
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PLinkScheduledResource()
    begin
        // [SCENARIO] Verify that usage links created and Qtys and Amts are correct when planning line (Job."Apply Usage Link": FALSE, Type: Resource, Line Type: Budget) used completely via job journal in two steps with an explicit link.

        PartialUseLinked(LibraryJob.ResourceType(), LibraryJob.PlanningLineTypeSchedule(), false)
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PLinkScheduledResDefault()
    begin
        // [SCENARIO] Verify that usage links created and Qtys and Amts are correct when planning line (Job."Apply Usage Link": TRUE, Type: Resource, Line Type: Budget) used completely via job journal in two steps with an explicit link.

        PartialUseLinked(LibraryJob.ResourceType(), LibraryJob.PlanningLineTypeSchedule(), true)
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PLinkBothResource()
    begin
        // [SCENARIO] Verify that usage links created and Qtys and Amts are correct when planning line (Job."Apply Usage Link": FALSE, Type: Resource, Line Type: Budget & Billable) used completely via job journal in two steps with an explicit link.

        PartialUseLinked(LibraryJob.ResourceType(), LibraryJob.PlanningLineTypeBoth(), false)
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PLinkBothResourceDefault()
    begin
        // [SCENARIO] Verify that usage links created and Qtys and Amts are correct when planning line (Job."Apply Usage Link": TRUE, Type: Resource, Line Type: Budget & Billable) used completely via job journal in two steps with an explicit link.

        PartialUseLinked(LibraryJob.ResourceType(), LibraryJob.PlanningLineTypeBoth(), true)
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PLinkScheduledGL()
    begin
        // [SCENARIO] Verify that usage links created and Qtys and Amts are correct when planning line (Job."Apply Usage Link": FALSE, Type: G/L Account, Line Type: Budget) used completely via job journal in two steps with an explicit link.

        PartialUseLinked(LibraryJob.GLAccountType(), LibraryJob.PlanningLineTypeSchedule(), false)
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PLinkScheduledGLDefault()
    begin
        // [SCENARIO] Verify that usage links created and Qtys and Amts are correct when planning line (Job."Apply Usage Link": TRUE, Type: G/L Account, Line Type: Budget) used completely via job journal in two steps with an explicit link.

        PartialUseLinked(LibraryJob.GLAccountType(), LibraryJob.PlanningLineTypeSchedule(), true)
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PLinkBothGL()
    begin
        // [SCENARIO] Verify that usage links created and Qtys and Amts are correct when planning line (Job."Apply Usage Link": FALSE, Type: G/L Account, Line Type: Budget & Billable) used completely via job journal in two steps with an explicit link.

        PartialUseLinked(LibraryJob.GLAccountType(), LibraryJob.PlanningLineTypeBoth(), false)
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PLinkBothGLDefault()
    begin
        // [SCENARIO] Verify that usage links created and Qtys and Amts are correct when planning line (Job."Apply Usage Link": TRUE, Type: G/L Account, Line Type: Budget & Billable) used completely via job journal in two steps with an explicit link.

        PartialUseLinked(LibraryJob.GLAccountType(), LibraryJob.PlanningLineTypeBoth(), true)
    end;

    local procedure PartialUseLinked(ConsumableType: Enum "Job Planning Line Type"; LineTypeToMatch: Enum "Job Planning Line Line Type"; ApplyUsageLink: Boolean)
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
        // Use a planning line via job journal in two parts with an explicit link.
        // Verify that the usage links are created.
        // Verify that the planning line's amounts and quantities are updated.

        // Setup
        Initialize();
        CreateJob(ApplyUsageLink, true, Job);
        LibraryJob.CreateJobTask(Job, JobTask);

        // this is the planning line we want to link to
        LibraryJob.CreateJobPlanningLine(LineTypeToMatch, ConsumableType, JobTask, JobPlanningLine);
        JobPlanningLine.Validate("Usage Link", true);
        JobPlanningLine.Validate(Quantity, LibraryRandom.RandInt(100) + 100); // 100 < Quantity <= 200
        JobPlanningLine.Modify(true);
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

        // Exercise - use 1 to 99% of planning line
        LibraryJob.UseJobPlanningLineExplicit(
          JobPlanningLine, LibraryJob.UsageLineTypeBlank(), LibraryRandom.RandInt(99) / 100, LibraryJob.JobConsumption(),
          JobJournalLine);
        // refresh
        JobPlanningLine.Get(Job."No.", JobTask."Job Task No.", JobPlanningLine."Line No.");

        // Verify - Remaining Qty. field on the journal line
        JobJournalLine.TestField("Remaining Qty.", BeforeJobPlanningLine."Remaining Qty." - JobJournalLine.Quantity);

        // Verify - usage is linked
        JobLedgerEntry.SetRange(Description, JobJournalLine.Description);
        JobLedgerEntry.FindFirst();
        VerifyUsageLink(JobPlanningLine, JobLedgerEntry);

        // Verify - no new planning lines are created
        Assert.AreEqual(LineCount, JobPlanningLine.Count, 'No planning lines should have been created.');

        // Verify - JobPlanningLine@Pre - JobJournalLine = JobPlanningLine@Post
        VerifyJobPlanningLine(BeforeJobPlanningLine, JobPlanningLine, JobJournalLine);

        // Exercise - use the rest
        BeforeJobPlanningLine := JobPlanningLine;
        LibraryJob.UseJobPlanningLineExplicit(JobPlanningLine, LibraryJob.UsageLineTypeBlank(), 1, LibraryJob.JobConsumption(), JobJournalLine);
        // refresh
        JobPlanningLine.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line No.");

        // Verify - usage is linked
        JobLedgerEntry.SetRange(Description, JobJournalLine.Description);
        JobLedgerEntry.FindFirst();
        VerifyUsageLink(JobPlanningLine, JobLedgerEntry);

        // Verify - no new planning lines are created
        Assert.AreEqual(LineCount, JobPlanningLine.Count, 'No planning lines should have been created.');

        // Verify - JobPlanningLine@Pre - JobJournalLine = JobPlanningLine@Post
        VerifyJobPlanningLine(BeforeJobPlanningLine, JobPlanningLine, JobJournalLine)
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure BlankMatchScheduledItem()
    begin
        UseMatched(LibraryJob.ItemType(), LibraryJob.UsageLineTypeBlank(), LibraryJob.PlanningLineTypeSchedule(), false)
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ScheduleMatchScheduledItem()
    begin
        UseMatched(LibraryJob.ItemType(), LibraryJob.UsageLineTypeSchedule(), LibraryJob.PlanningLineTypeSchedule(), false)
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ContractMatchScheduledItem()
    begin
        asserterror UseMatched(LibraryJob.ItemType(), LibraryJob.UsageLineTypeContract(), LibraryJob.PlanningLineTypeSchedule(), false);
        Assert.AreEqual('Assert.IsTrue failed. Usage link should have been created', GetLastErrorText, 'Unexpected error')
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure BothMatchScheduledItem()
    begin
        asserterror UseMatched(LibraryJob.ItemType(), LibraryJob.UsageLineTypeBoth(), LibraryJob.PlanningLineTypeSchedule(), false);
        Assert.AreEqual('Assert.IsTrue failed. Usage link should have been created', GetLastErrorText, 'Unexpected error')
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure BlankMatchBothItem()
    begin
        UseMatched(LibraryJob.ItemType(), LibraryJob.UsageLineTypeBlank(), LibraryJob.PlanningLineTypeBoth(), false)
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ScheduleMatchBothItem()
    begin
        UseMatched(LibraryJob.ItemType(), LibraryJob.UsageLineTypeSchedule(), LibraryJob.PlanningLineTypeBoth(), false)
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ContractMatchBothItem()
    begin
        UseMatched(LibraryJob.ItemType(), LibraryJob.UsageLineTypeContract(), LibraryJob.PlanningLineTypeBoth(), false)
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure BothMatchBothItem()
    begin
        UseMatched(LibraryJob.ItemType(), LibraryJob.UsageLineTypeBoth(), LibraryJob.PlanningLineTypeBoth(), false)
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure BlankMatchScheduledResource()
    begin
        UseMatched(LibraryJob.ResourceType(), LibraryJob.UsageLineTypeBlank(), LibraryJob.PlanningLineTypeSchedule(), false)
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ScheduleMatchScheduledResource()
    begin
        UseMatched(LibraryJob.ResourceType(), LibraryJob.UsageLineTypeSchedule(), LibraryJob.PlanningLineTypeSchedule(), false)
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ContractMatchScheduledResource()
    begin
        asserterror UseMatched(LibraryJob.ResourceType(), LibraryJob.UsageLineTypeContract(), LibraryJob.PlanningLineTypeSchedule(), false);
        Assert.AreEqual('Assert.IsTrue failed. Usage link should have been created', GetLastErrorText, 'Unexpected error')
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure BothMatchScheduledResource()
    begin
        asserterror UseMatched(LibraryJob.ResourceType(), LibraryJob.UsageLineTypeBoth(), LibraryJob.PlanningLineTypeSchedule(), false);
        Assert.AreEqual('Assert.IsTrue failed. Usage link should have been created', GetLastErrorText, 'Unexpected error')
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure BlankMatchBothResource()
    begin
        UseMatched(LibraryJob.ResourceType(), LibraryJob.UsageLineTypeBlank(), LibraryJob.PlanningLineTypeBoth(), false)
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ScheduleMatchBothResource()
    begin
        UseMatched(LibraryJob.ResourceType(), LibraryJob.UsageLineTypeSchedule(), LibraryJob.PlanningLineTypeBoth(), false)
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ContractMatchBothResource()
    begin
        UseMatched(LibraryJob.ResourceType(), LibraryJob.UsageLineTypeContract(), LibraryJob.PlanningLineTypeBoth(), false)
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure BothMatchBothResource()
    begin
        UseMatched(LibraryJob.ResourceType(), LibraryJob.UsageLineTypeBoth(), LibraryJob.PlanningLineTypeBoth(), false)
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure BlankMatchScheduledGL()
    begin
        UseMatched(LibraryJob.GLAccountType(), LibraryJob.UsageLineTypeBlank(), LibraryJob.PlanningLineTypeSchedule(), false)
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ScheduleMatchScheduledGL()
    begin
        UseMatched(LibraryJob.GLAccountType(), LibraryJob.UsageLineTypeSchedule(), LibraryJob.PlanningLineTypeSchedule(), false)
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ContractMatchScheduledGL()
    begin
        asserterror UseMatched(LibraryJob.GLAccountType(), LibraryJob.UsageLineTypeContract(), LibraryJob.PlanningLineTypeSchedule(), false);
        Assert.AreEqual('Assert.IsTrue failed. Usage link should have been created', GetLastErrorText, 'Unexpected error')
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure BothMatchScheduledGL()
    begin
        asserterror UseMatched(LibraryJob.GLAccountType(), LibraryJob.UsageLineTypeBoth(), LibraryJob.PlanningLineTypeSchedule(), false);
        Assert.AreEqual('Assert.IsTrue failed. Usage link should have been created', GetLastErrorText, 'Unexpected error')
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure BlankMatchBothGL()
    begin
        UseMatched(LibraryJob.GLAccountType(), LibraryJob.UsageLineTypeBlank(), LibraryJob.PlanningLineTypeBoth(), false)
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ScheduleMatchBothGL()
    begin
        UseMatched(LibraryJob.GLAccountType(), LibraryJob.UsageLineTypeSchedule(), LibraryJob.PlanningLineTypeBoth(), false)
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ContractMatchBothGL()
    begin
        UseMatched(LibraryJob.GLAccountType(), LibraryJob.UsageLineTypeContract(), LibraryJob.PlanningLineTypeBoth(), false)
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure BothMatchBothGL()
    begin
        UseMatched(LibraryJob.ResourceType(), LibraryJob.UsageLineTypeBoth(), LibraryJob.PlanningLineTypeBoth(), false)
    end;

    local procedure UseMatched(ConsumableType: Enum "Job Planning Line Type"; UsageLineType: Enum "Job Line Type"; LineTypeToMatch: Enum "Job Line Type"; ApplyUsageLink: Boolean)
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        BeforeJobPlanningLine: Record "Job Planning Line";
        JobPlanningLine: Record "Job Planning Line";
        JobLedgerEntry: Record "Job Ledger Entry";
        JobJournalLine: Record "Job Journal Line";
        LineCount: Integer;
    begin
        // Use a planning line via job journal that by matching.
        // Verfiy that the line type is taken from the planning line and cannot be changed.
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
        LineCount := JobPlanningLine.Count();

        // Exercise
        LibraryJob.UseJobPlanningLine(JobPlanningLine, UsageLineType, 1, JobJournalLine);

        // refresh
        JobPlanningLine.Get(Job."No.", JobTask."Job Task No.", JobPlanningLine."Line No.");

        // Verify - usage is linked
        JobLedgerEntry.SetRange(Description, JobJournalLine.Description);
        JobLedgerEntry.FindFirst();
        VerifyUsageLink(JobPlanningLine, JobLedgerEntry);

        // Verify - no new planning line are created
        Assert.AreEqual(LineCount, JobPlanningLine.Count, 'No planning lines should have been created.');

        // Verify - JobPlanningLine@Pre - JobJournalLine = JobPlanningLine@Post
        VerifyJobPlanningLine(BeforeJobPlanningLine, JobPlanningLine, JobJournalLine)
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PBlankMatchScheduledItem()
    begin
        PartialUseMatched(LibraryJob.ItemType(), LibraryJob.UsageLineTypeBlank(), LibraryJob.PlanningLineTypeSchedule(), false)
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PScheduleMatchScheduledItem()
    begin
        PartialUseMatched(LibraryJob.ItemType(), LibraryJob.UsageLineTypeSchedule(), LibraryJob.PlanningLineTypeSchedule(), false)
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PContractMatchScheduledItem()
    begin
        asserterror
          PartialUseMatched(LibraryJob.ItemType(), LibraryJob.UsageLineTypeContract(), LibraryJob.PlanningLineTypeSchedule(), false);
        Assert.AreEqual('Assert.IsTrue failed. Usage link should have been created', GetLastErrorText, 'Unexpected error')
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PBothMatchScheduledItem()
    begin
        asserterror
          PartialUseMatched(LibraryJob.ItemType(), LibraryJob.UsageLineTypeBoth(), LibraryJob.PlanningLineTypeSchedule(), false);
        Assert.AreEqual('Assert.IsTrue failed. Usage link should have been created', GetLastErrorText, 'Unexpected error')
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PBlankMatchBothItem()
    begin
        PartialUseMatched(LibraryJob.ItemType(), LibraryJob.UsageLineTypeBlank(), LibraryJob.PlanningLineTypeBoth(), false)
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PScheduleMatchBothItem()
    begin
        PartialUseMatched(LibraryJob.ItemType(), LibraryJob.UsageLineTypeSchedule(), LibraryJob.PlanningLineTypeBoth(), false)
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PContractMatchBothItem()
    begin
        PartialUseMatched(LibraryJob.ItemType(), LibraryJob.UsageLineTypeContract(), LibraryJob.PlanningLineTypeBoth(), false)
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PBothMatchBothItem()
    begin
        PartialUseMatched(LibraryJob.ItemType(), LibraryJob.UsageLineTypeBoth(), LibraryJob.PlanningLineTypeBoth(), false)
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PBlankMatchScheduledResource()
    begin
        PartialUseMatched(LibraryJob.ResourceType(), LibraryJob.UsageLineTypeBlank(), LibraryJob.PlanningLineTypeSchedule(), false)
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PScheduleMatchScheduledRes()
    begin
        PartialUseMatched(LibraryJob.ResourceType(), LibraryJob.UsageLineTypeSchedule(), LibraryJob.PlanningLineTypeSchedule(), false)
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PContractMatchScheduledRes()
    begin
        asserterror
          PartialUseMatched(LibraryJob.ResourceType(), LibraryJob.UsageLineTypeContract(), LibraryJob.PlanningLineTypeSchedule(), false);
        Assert.AreEqual('Assert.IsTrue failed. Usage link should have been created', GetLastErrorText, 'Unexpected error')
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PBothMatchScheduledResource()
    begin
        asserterror
          PartialUseMatched(LibraryJob.ResourceType(), LibraryJob.UsageLineTypeBoth(), LibraryJob.PlanningLineTypeSchedule(), false);
        Assert.AreEqual('Assert.IsTrue failed. Usage link should have been created', GetLastErrorText, 'Unexpected error')
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PBlankMatchBothResource()
    begin
        PartialUseMatched(LibraryJob.ResourceType(), LibraryJob.UsageLineTypeBlank(), LibraryJob.PlanningLineTypeBoth(), false)
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PScheduleMatchBothResource()
    begin
        PartialUseMatched(LibraryJob.ResourceType(), LibraryJob.UsageLineTypeSchedule(), LibraryJob.PlanningLineTypeBoth(), false)
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PContractMatchBothResource()
    begin
        PartialUseMatched(LibraryJob.ResourceType(), LibraryJob.UsageLineTypeContract(), LibraryJob.PlanningLineTypeBoth(), false)
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PBothMatchBothResource()
    begin
        PartialUseMatched(LibraryJob.ResourceType(), LibraryJob.UsageLineTypeBoth(), LibraryJob.PlanningLineTypeBoth(), false)
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PBlankMatchScheduledGL()
    begin
        PartialUseMatched(LibraryJob.GLAccountType(), LibraryJob.UsageLineTypeBlank(), LibraryJob.PlanningLineTypeSchedule(), false)
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PScheduleMatchScheduledGL()
    begin
        PartialUseMatched(LibraryJob.GLAccountType(), LibraryJob.UsageLineTypeSchedule(), LibraryJob.PlanningLineTypeSchedule(), false)
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PContractMatchScheduledGL()
    begin
        asserterror
          PartialUseMatched(LibraryJob.GLAccountType(), LibraryJob.UsageLineTypeContract(), LibraryJob.PlanningLineTypeSchedule(), false);
        Assert.AreEqual('Assert.IsTrue failed. Usage link should have been created', GetLastErrorText, 'Unexpected error')
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PBothMatchScheduledGL()
    begin
        asserterror
          PartialUseMatched(LibraryJob.GLAccountType(), LibraryJob.UsageLineTypeBoth(), LibraryJob.PlanningLineTypeSchedule(), false);
        Assert.AreEqual('Assert.IsTrue failed. Usage link should have been created', GetLastErrorText, 'Unexpected error')
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PBlankMatchBothGL()
    begin
        PartialUseMatched(LibraryJob.GLAccountType(), LibraryJob.UsageLineTypeBlank(), LibraryJob.PlanningLineTypeBoth(), false)
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PScheduleMatchBothGL()
    begin
        PartialUseMatched(LibraryJob.GLAccountType(), LibraryJob.UsageLineTypeSchedule(), LibraryJob.PlanningLineTypeBoth(), false)
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PContractMatchBothGL()
    begin
        PartialUseMatched(LibraryJob.GLAccountType(), LibraryJob.UsageLineTypeContract(), LibraryJob.PlanningLineTypeBoth(), false)
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PBothMatchBothGL()
    begin
        PartialUseMatched(LibraryJob.GLAccountType(), LibraryJob.UsageLineTypeBoth(), LibraryJob.PlanningLineTypeBoth(), false)
    end;

    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    local procedure PartialUseMatched(ConsumableType: Enum "Job Planning Line Type"; UsageLineType: Enum "Job Planning Line Line Type"; LineTypeToMatch: Enum "Job Planning Line Line Type"; ApplyUsageLink: Boolean)
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        BeforeJobPlanningLine: Record "Job Planning Line";
        JobPlanningLine: Record "Job Planning Line";
        JobLedgerEntry: Record "Job Ledger Entry";
        JobJournalLine: Record "Job Journal Line";
        LineCount: Integer;
    begin
        // Use a planning line via job journal by matching in two steps.
        // Verify that the usage links are created.
        // Verffy that no new planning lines are created.
        // Verify that the planning line's amounts and quantities are updated.

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
        LineCount := JobPlanningLine.Count();

        // Exercise - use 1 - 99% of the planning line
        LibraryJob.UseJobPlanningLine(JobPlanningLine, UsageLineType, LibraryRandom.RandInt(99) / 100, JobJournalLine);

        // refresh
        JobPlanningLine.Get(Job."No.", JobTask."Job Task No.", JobPlanningLine."Line No.");

        // Verify - usage is linked
        JobLedgerEntry.SetRange(Description, JobJournalLine.Description);
        JobLedgerEntry.FindFirst();
        VerifyUsageLink(JobPlanningLine, JobLedgerEntry);

        // Verify - no new planning lines are created
        Assert.AreEqual(LineCount, JobPlanningLine.Count, 'No planning lines should have been created.');
        VerifyJobPlanningLine(BeforeJobPlanningLine, JobPlanningLine, JobJournalLine);

        // Exercise - use the rest
        BeforeJobPlanningLine := JobPlanningLine;
        LibraryJob.UseJobPlanningLine(JobPlanningLine, LibraryJob.UsageLineTypeSchedule(), 1, JobJournalLine);

        // refresh
        JobPlanningLine.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line No.");

        // Verify - usage is linked
        JobLedgerEntry.SetRange(Description, JobJournalLine.Description);
        JobLedgerEntry.FindFirst();
        VerifyUsageLink(JobPlanningLine, JobLedgerEntry);

        // Verfiy - no new planning lines are created
        Assert.AreEqual(LineCount, JobPlanningLine.Count, 'No planning lines should have been created.');

        // Verify - JobPlanningLine@Pre - JobJournalLine = JobPlanningLine@Post
        VerifyJobPlanningLine(BeforeJobPlanningLine, JobPlanningLine, JobJournalLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ExcessScheduledItem()
    begin
        ExcessUseMatched(LibraryJob.ItemType(), LibraryJob.PlanningLineTypeSchedule(), false)
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ExcessScheduledItemDefault()
    begin
        ExcessUseMatched(LibraryJob.ItemType(), LibraryJob.PlanningLineTypeSchedule(), true)
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ExcessBothItem()
    begin
        ExcessUseMatched(LibraryJob.ItemType(), LibraryJob.PlanningLineTypeBoth(), false)
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ExcessBothItemDefault()
    begin
        ExcessUseMatched(LibraryJob.ItemType(), LibraryJob.PlanningLineTypeBoth(), true)
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ExcessScheduledResource()
    begin
        ExcessUseMatched(LibraryJob.ResourceType(), LibraryJob.PlanningLineTypeSchedule(), false)
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ExcessScheduledResourceDefault()
    begin
        ExcessUseMatched(LibraryJob.ResourceType(), LibraryJob.PlanningLineTypeSchedule(), true)
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ExcessBothResource()
    begin
        ExcessUseMatched(LibraryJob.ResourceType(), LibraryJob.PlanningLineTypeBoth(), false)
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ExcessBothResourceDefault()
    begin
        ExcessUseMatched(LibraryJob.ResourceType(), LibraryJob.PlanningLineTypeBoth(), true)
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ExcessScheduledGL()
    begin
        ExcessUseMatched(LibraryJob.GLAccountType(), LibraryJob.PlanningLineTypeSchedule(), false)
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ExcessScheduledGLDefault()
    begin
        ExcessUseMatched(LibraryJob.GLAccountType(), LibraryJob.PlanningLineTypeSchedule(), true)
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ExcessBothGL()
    begin
        ExcessUseMatched(LibraryJob.GLAccountType(), LibraryJob.PlanningLineTypeBoth(), false)
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ExcessBothGLDefault()
    begin
        ExcessUseMatched(LibraryJob.GLAccountType(), LibraryJob.PlanningLineTypeBoth(), true)
    end;

    local procedure ExcessUseMatched(ConsumableType: Enum "Job Planning Line Type"; LineTypeToMatch: Enum "Job Planning Line Line Type"; ApplyUsageLink: Boolean)
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        BeforeJobPlanningLine: Record "Job Planning Line";
        JobJournalLine: Record "Job Journal Line";
        JobLedgerEntry: Record "Job Ledger Entry";
        LineCount: Integer;
    begin
        // Use more than planned by matching via job journal.
        // Verify that the usage links are created.
        // Verify that the planning line's amounts and quantities are updated.
        // Verfiy that correct planning line(s) is created for the remainder.

        // can only match a planning line which type includes budget
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
        LineCount := JobPlanningLine.Count();

        // Exercise - use three (random) times the planned quantity
        BeforeJobPlanningLine := JobPlanningLine;
        LibraryJob.UseJobPlanningLine(JobPlanningLine, LibraryJob.UsageLineTypeSchedule(), 3, JobJournalLine);

        // refresh
        JobPlanningLine.Get(Job."No.", JobTask."Job Task No.", JobPlanningLine."Line No.");

        // Verify - usage is linked
        JobLedgerEntry.SetRange(Description, JobJournalLine.Description);
        JobLedgerEntry.FindFirst();
        VerifyUsageLink(JobPlanningLine, JobLedgerEntry);

        // Verify - the original planning line is completed
        VerifyJobPlanningLineDone(JobPlanningLine);

        // Verify - an extra planning line is created
        Assert.AreEqual(LineCount + 1, JobPlanningLine.Count, 'One planning line should have been created.');

        // Verfiy - transaction correctly registered in ledger
        LibraryJob.VerifyJobLedger(JobJournalLine);

        // Verify - the correct planning line(s) are created
        UseFromPlan(JobJournalLine, BeforeJobPlanningLine);
        LibraryJob.VerifyPlanningLines(JobJournalLine, true)
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure MatchMultipleItemLines()
    begin
        MatchMultipleLines(LibraryJob.ItemType(), false)
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure MatchMultipleItemLinesDefault()
    begin
        MatchMultipleLines(LibraryJob.ItemType(), true)
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure MatchMultipleGLLines()
    begin
        MatchMultipleLines(LibraryJob.GLAccountType(), false)
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure MatchMultipleGLLinesDefault()
    begin
        MatchMultipleLines(LibraryJob.GLAccountType(), true)
    end;

    local procedure MatchMultipleLines(ConsumableType: Enum "Job Planning Line Type"; ApplyUsageLink: Boolean)
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        JobJournalLine: Record "Job Journal Line";
        JobLedgerEntry: Record "Job Ledger Entry";
        LineCount: Integer;
    begin
        // Use multiple planning lines at once via job journal by matching.
        // Verify that the usage links are created.
        // Verify that the planning line's amounts and quantities are updated.

        // Setup
        Initialize();
        CreateJob(ApplyUsageLink, true, Job);
        LibraryJob.CreateJobTask(Job, JobTask);

        // this is the planning line we want to match
        LibraryJob.CreateJobPlanningLine(LibraryJob.PlanningLineTypeSchedule(), ConsumableType, JobTask, JobPlanningLine);
        JobPlanningLine.Validate("Usage Link", true);
        JobPlanningLine.Modify(true);
        JobPlanningLine."Line No." := JobPlanningLine."Line No." + 10000;
        JobPlanningLine.Insert(true);

        AssertNoDiscounts(JobPlanningLine);
        LineCount := JobPlanningLine.Count();

        // Exercise - use both planning lines and more at once
        LibraryJob.UseJobPlanningLine(JobPlanningLine, LibraryJob.UsageLineTypeSchedule(), 3, JobJournalLine);

        // Verify - an extra planning line is created
        Assert.AreEqual(LineCount + 1, JobPlanningLine.Count, 'One extra planning line should have been created');

        // Verify - the original two planning lines are linked to the ledger entry, and completely used
        JobLedgerEntry.SetRange(Description, JobJournalLine.Description);
        JobLedgerEntry.FindFirst();
        JobPlanningLine.SetRange(Description, JobPlanningLine.Description);
        Assert.AreEqual(LineCount, JobPlanningLine.Count, 'The original planning lines should be in the filter');
        JobPlanningLine.FindSet();
        repeat
            VerifyUsageLink(JobPlanningLine, JobLedgerEntry);
            VerifyJobPlanningLineDone(JobPlanningLine)
        until JobPlanningLine.Next() = 0;

        // Verify - the newly created line is linked to the ledger entry
        JobPlanningLine.SetRange(Description, JobJournalLine.Description);
        JobPlanningLine.FindFirst();
        VerifyUsageLink(JobPlanningLine, JobLedgerEntry)
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ScheduleNoMatchItem()
    begin
        UsageLinkNoMatch(LibraryJob.ItemType(), LibraryJob.UsageLineTypeSchedule())
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ContractNoMatchItem()
    begin
        UsageLinkNoMatch(LibraryJob.ItemType(), LibraryJob.UsageLineTypeContract())
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure BothNoMatchItem()
    begin
        UsageLinkNoMatch(LibraryJob.ItemType(), LibraryJob.UsageLineTypeBoth())
    end;

    local procedure UsageLinkNoMatch(ConsumableType: Enum "Job Planning Line Type"; UsageLineType: Enum "Job Line Type")
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        JobJournalLine: Record "Job Journal Line";
        TempJobJournalLine: Record "Job Journal Line" temporary;
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        // Use something for a job that was not planned for.
        // Verify that the usage link is created.
        // Verify that usage link is enabled for the created planning line

        // Setup
        Initialize();
        CreateJob(true, false, Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryJob.CreateJobJournalLineForType(UsageLineType, ConsumableType, JobTask, JobJournalLine);

        // Exercise
        LibraryJob.CopyJobJournalLines(JobJournalLine, TempJobJournalLine);
        LibraryJob.PostJobJournal(JobJournalLine);

        // Verify - a new, linked line is created
        JobPlanningLine.SetRange(Description, TempJobJournalLine.Description);
        JobPlanningLine.SetFilter("Line Type", '%1|%2', LibraryJob.PlanningLineTypeSchedule(), LibraryJob.PlanningLineTypeBoth());
        Assert.AreEqual(1, JobPlanningLine.Count, 'Only one line of type that includes budget should have been created');
        JobPlanningLine.FindFirst();
        JobLedgerEntry.SetRange(Description, TempJobJournalLine.Description);
        JobLedgerEntry.FindFirst();
        VerifyUsageLink(JobPlanningLine, JobLedgerEntry);

        // Verify - the created line is correct
        LibraryJob.VerifyJobJournalPosting(true, TempJobJournalLine)
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure DeleteSelectedJobPlanningLine()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        JobJournalLine: Record "Job Journal Line";
    begin
        // Deleting the selected job planning line from the job journal line results in an error when posting.

        // trigger message handler
        Message('');

        // Setup
        Initialize();
        CreateJob(true, true, Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryJob.CreateJobPlanningLine(LibraryJob.PlanningLineTypeSchedule(), LibraryJob.ItemType(), JobTask, JobPlanningLine);

        // Exercise
        LibraryJob.CreateJobJournalLineForPlan(JobPlanningLine, LibraryJob.UsageLineTypeSchedule(), 1, JobJournalLine);
        JobJournalLine.Validate("Job Planning Line No.", JobPlanningLine."Line No.");
        JobJournalLine.Modify(true);
        JobPlanningLine.Delete(true);

        // Verfiy
        asserterror LibraryJob.PostJobJournal(JobJournalLine);
        Assert.ExpectedErrorCannotFind(Database::"Job Planning Line");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ResourceNegativeMatchNegative()
    var
        QtyToPost: Decimal;
    begin
        // [FEATURE] [Match]
        // [SCENARIO] Verify that pland and execution matched when executing plan (negative Quantity) for Job Planning Line (Type = Resource) with usage link flag (negative Quantity), do not set link to plan.

        QtyToPost := -LibraryRandom.RandInt(100);
        MatchQuantities(QtyToPost, QtyToPost / 3, LibraryJob.ResourceType())
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ItemNegativeMatchNegative()
    var
        QtyToPost: Decimal;
    begin
        // [FEATURE] [Match]
        // [SCENARIO] Verify that plan and execution matched when executing plan (negative Quantity) for Job Planning Line (Type = Item) with usage link flag (negative Quantity), do not set link to plan.

        QtyToPost := -LibraryRandom.RandInt(100);
        MatchQuantities(QtyToPost, QtyToPost / 3, LibraryJob.ItemType())
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure GLAccountNegativeMatchNegative()
    var
        QtyToPost: Decimal;
    begin
        // [FEATURE] [Match]
        // [SCENARIO] Verify that pland and execution matched when executing plan (negative Quantity) for Job Planning Line (Type = G/L Account) with usage link flag (negative Quantity), do not set link to plan.

        QtyToPost := -LibraryRandom.RandInt(100);
        MatchQuantities(QtyToPost, QtyToPost / 3, LibraryJob.GLAccountType())
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ResourcePositiveMatchNegative()
    var
        QtyToPost: Decimal;
    begin
        // [FEATURE] [Match]
        // [SCENARIO] Verify that plan and execution are not matched when executing plan (negative Quantity) for Job Planning Line (Type = Resource) with usage link flag (positive Quantity), do not set link to plan.

        QtyToPost := LibraryRandom.RandInt(100);
        // these should not match!
        asserterror MatchQuantities(QtyToPost, -QtyToPost / 3, LibraryJob.ResourceType());
        Assert.AreEqual('Assert.IsTrue failed. Usage link should have been created', GetLastErrorText, 'Unexpected error')
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ItemPositiveMatchNegative()
    var
        QtyToPost: Decimal;
    begin
        // [FEATURE] [Match]
        // [SCENARIO] Verify that plan and execution are not matched when executing plan (negative Quantity) for Job Planning Line (Type = Item) with usage link flag (positive Quantity), do not set link to plan.

        QtyToPost := LibraryRandom.RandInt(100);
        // these should not match!
        asserterror MatchQuantities(QtyToPost, -QtyToPost / 3, LibraryJob.ItemType());
        Assert.AreEqual('Assert.IsTrue failed. Usage link should have been created', GetLastErrorText, 'Unexpected error')
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure GLAccountPositiveMatchNegative()
    var
        QtyToPost: Decimal;
    begin
        // [FEATURE] [Match]
        // [SCENARIO] Verify that plan and execution are not matched when executing plan (negative Quantity) for Job Planning Line (Type = G/L Account) with usage link flag (positive Quantity), do not set link to plan.

        QtyToPost := LibraryRandom.RandInt(100);
        // these should not match!
        asserterror MatchQuantities(QtyToPost, -QtyToPost / 3, LibraryJob.GLAccountType());
        Assert.AreEqual('Assert.IsTrue failed. Usage link should have been created', GetLastErrorText, 'Unexpected error')
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ResourceNegativeMatchPositive()
    var
        QtyToPost: Decimal;
    begin
        // [FEATURE] [Match]
        // [SCENARIO] Verify that plan and execution are not matched when executing plan (positive Quantity) for Job Planning Line (Type = Resource) with usage link flag (negative Quantity), do not set link to plan.

        QtyToPost := -LibraryRandom.RandInt(100);
        // these should not match!
        asserterror MatchQuantities(QtyToPost, -QtyToPost / 3, LibraryJob.ResourceType());
        Assert.AreEqual('Assert.IsTrue failed. Usage link should have been created', GetLastErrorText, 'Unexpected error')
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ItemNegativeMatchPositive()
    var
        QtyToPost: Decimal;
    begin
        // [FEATURE] [Match]
        // [SCENARIO] Verify that plan and execution are not matched when executing plan (positive Quantity) for Job Planning Line (Type = Resource) with usage link flag (negative Quantity), do not set link to plan.

        QtyToPost := -LibraryRandom.RandInt(100);
        // these should not match!
        asserterror MatchQuantities(QtyToPost, -QtyToPost / 3, LibraryJob.ResourceType());
        Assert.AreEqual('Assert.IsTrue failed. Usage link should have been created', GetLastErrorText, 'Unexpected error')
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure GLAccountNegativeMatchPositive()
    var
        QtyToPost: Decimal;
    begin
        // [FEATURE] [Match]
        // [SCENARIO] Verify that plan and execution are not matched when executing plan (positive Quantity) for Job Planning Line (Type = Resource) with usage link flag (negative Quantity), do not set link to plan.

        QtyToPost := -LibraryRandom.RandInt(100);
        // these should not match!
        asserterror MatchQuantities(QtyToPost, -QtyToPost / 3, LibraryJob.ResourceType());
        Assert.AreEqual('Assert.IsTrue failed. Usage link should have been created', GetLastErrorText, 'Unexpected error')
    end;

    local procedure MatchQuantities(QtyToPost: Decimal; QtyToMatch: Decimal; ConsumableType: Enum "Job Planning Line Type")
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        BeforeJobPlanningLine: Record "Job Planning Line";
        JobJournalLine: Record "Job Journal Line";
        JobLedgerEntry: Record "Job Ledger Entry";
        LineCount: Integer;
    begin
        // Usage and plan should only match if their quantities have the same sign
        // Verify correct planning line is (not) created
        // Verify resulting amounts and quantities

        Assert.AreNotEqual(0, QtyToPost, 'Quantitiy to post should not be zero.');
        Assert.AreNotEqual(0, QtyToMatch, 'Quantitiy to post should not be zero.');

        // Users may use up to five decimal places
        QtyToPost := Round(QtyToPost, 0.00001);
        QtyToMatch := Round(QtyToMatch, 0.00001);

        // Setup
        Initialize();
        CreateJob(true, true, Job);
        LibraryJob.CreateJobTask(Job, JobTask);

        // this is the planning line we want to match
        LibraryJob.CreateJobPlanningLine(LibraryJob.PlanningLineTypeSchedule(), ConsumableType, JobTask, JobPlanningLine);
        JobPlanningLine.Validate(Quantity, QtyToMatch);
        JobPlanningLine.Validate("Usage Link", true);
        JobPlanningLine.Modify(true);

        AssertNoDiscounts(JobPlanningLine);
        BeforeJobPlanningLine := JobPlanningLine;

        LineCount := JobPlanningLine.Count();

        // Exercise
        if (QtyToPost < 0) and (ConsumableType = LibraryJob.ItemType()) then begin
            // Before crediting, use item first
            JobPlanningLine.Validate("Line No.", LibraryJob.GetNextLineNo(JobPlanningLine));
            JobPlanningLine.Validate(Quantity, Abs(QtyToPost));
            JobPlanningLine.Validate(Description, LibraryUtility.GenerateGUID());
            JobPlanningLine.Insert(true);
            LineCount += 1;
            LibraryJob.UseJobPlanningLineExplicit(
              JobPlanningLine, LibraryJob.UsageLineTypeSchedule(), 1, LibraryJob.JobConsumption(), JobJournalLine);
            JobPlanningLine := BeforeJobPlanningLine
        end;
        LibraryJob.UseJobPlanningLine(JobPlanningLine, LibraryJob.UsageLineTypeSchedule(), QtyToPost / QtyToMatch, JobJournalLine);

        // refresh
        JobPlanningLine.Get(Job."No.", JobTask."Job Task No.", JobPlanningLine."Line No.");

        // Verify - usage is linked
        JobLedgerEntry.SetRange(Description, JobJournalLine.Description);
        JobLedgerEntry.FindFirst();
        VerifyUsageLink(JobPlanningLine, JobLedgerEntry);

        if (QtyToPost > 0) <> (QtyToPost > 0) then begin
            // Different sign: no match => verify new line
            Assert.AreEqual(LineCount + 1, JobPlanningLine.Count, 'One planning line should have been created.');
            LibraryJob.VerifyPlanningLines(JobJournalLine, true)
        end else
            // Same sign: match => verify updated planning line
            if Abs(QtyToPost) > Abs(QtyToMatch) then begin
                // Excess posted: new line => verify
                Assert.AreEqual(LineCount + 1, JobPlanningLine.Count, 'One planning line should have been created.');
                VerifyJobPlanningLineDone(JobPlanningLine);
                // Calculate remaining usage (i.e, the "new" journal line)
                UseFromPlan(JobJournalLine, BeforeJobPlanningLine);
                LibraryJob.VerifyPlanningLines(JobJournalLine, true);
            end else begin
                // Partially posted
                Assert.AreEqual(LineCount, JobPlanningLine.Count, 'No planning lines should have been created.');
                VerifyJobPlanningLine(BeforeJobPlanningLine, JobPlanningLine, JobJournalLine)
            end;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ResourceNegativeLinkNegative()
    var
        QtyToPost: Decimal;
    begin
        // [SCENARIO] Verify that Quantities and Amounts are correct when executing plan (negative Quantity) for Job Planning Line (Type = Resource) with usage link (negative Quantity), set link to plan explicitly.

        QtyToPost := -LibraryRandom.RandInt(100);
        LinkQuantities(QtyToPost, QtyToPost / 3, LibraryJob.ResourceType())
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ItemNegativeLinkNegative()
    var
        QtyToPost: Decimal;
    begin
        // [SCENARIO] Verify that Quantities and Amounts are correct when executing plan (negative Quantity) for Job Planning Line (Type = Item) with usage link (negative Quantity), set link to plan explicitly.

        QtyToPost := -LibraryRandom.RandInt(100);
        LinkQuantities(QtyToPost, QtyToPost / 3, LibraryJob.ItemType())
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure GLAccountNegativeLinkNegative()
    var
        QtyToPost: Decimal;
    begin
        // [SCENARIO] Verify that Quantities and Amounts are correct when executing plan (negative Quantity) for Job Planning Line (Type = G/L Account) with usage link (negative Quantity), set link to plan explicitly.

        QtyToPost := -LibraryRandom.RandInt(100);
        LinkQuantities(QtyToPost, QtyToPost / 3, LibraryJob.GLAccountType())
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ResourcePositiveLinkNegative()
    var
        QtyToPost: Decimal;
    begin
        // [SCENARIO] Verify that Quantities and Amounts are correct when executing plan (negative Quantity) for Job Planning Line (Type = Resource) with usage link (positive Quantity), set link to plan explicitly.

        QtyToPost := LibraryRandom.RandInt(100);
        LinkQuantities(QtyToPost, -QtyToPost / 3, LibraryJob.ResourceType())
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ItemPositiveLinkNegative()
    var
        QtyToPost: Decimal;
    begin
        // [SCENARIO] Verify that Quantities and Amounts are correct when executing plan (negative Quantity) for Job Planning Line (Type = Item) with usage link (positive Quantity), set link to plan explicitly.

        QtyToPost := LibraryRandom.RandInt(100);
        LinkQuantities(QtyToPost, -QtyToPost / 3, LibraryJob.ItemType())
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure GLAccountPositiveLinkNegative()
    var
        QtyToPost: Decimal;
    begin
        // [SCENARIO] Verify that Quantities and Amounts are correct when executing plan (negative Quantity) for Job Planning Line (Type = G/L Account) with usage link (positive Quantity), set link to plan explicitly.

        QtyToPost := LibraryRandom.RandInt(100);
        LinkQuantities(QtyToPost, -QtyToPost / 3, LibraryJob.GLAccountType())
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ResourceNegativeLinkPositive()
    var
        QtyToPost: Decimal;
    begin
        // [SCENARIO] Verify that Quantities and Amounts are correct when executing plan (positive Quantity) for Job Planning Line (Type = Resource) with usage link (negative Quantity), set link to plan explicitly.

        QtyToPost := -LibraryRandom.RandInt(100);
        LinkQuantities(QtyToPost, -QtyToPost / 3, LibraryJob.ResourceType())
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ItemNegativeLinkPositive()
    var
        QtyToPost: Decimal;
    begin
        // [SCENARIO] Verify that Quantities and Amounts are correct when executing plan (positive Quantity) for Job Planning Line (Type = Item) with usage link (negative Quantity), set link to plan explicitly.

        QtyToPost := -LibraryRandom.RandInt(100);
        LinkQuantities(QtyToPost, -QtyToPost / 3, LibraryJob.ItemType())
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure GLAccountNegativeLinkPositive()
    var
        QtyToPost: Decimal;
    begin
        // [SCENARIO] Verify that Quantities and Amounts are correct when executing plan (positive Quantity) for Job Planning Line (Type = G/L Account) with usage link (negative Quantity), set link to plan explicitly.

        QtyToPost := -LibraryRandom.RandInt(100);
        LinkQuantities(QtyToPost, -QtyToPost / 3, LibraryJob.GLAccountType())
    end;

    [Test]
    procedure GLAccountLineViaPurchOrderSeveralLines()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        PurchaseHeader: Record "Purchase Header";
        PL_Qty: Decimal;
    begin
        // Setup
        Initialize();

        // [GIVEN] A job with job task
        PL_Qty := LibraryRandom.RandInt(100);
        CreateJob(true, true, Job);
        LibraryJob.CreateJobTask(Job, JobTask);

        // [GIVEN] Job planning line
        LibraryJob.CreateJobPlanningLine(LibraryJob.PlanningLineTypeSchedule(), LibraryJob.GLAccountType(), JobTask, JobPlanningLine);
        JobPlanningLine.Validate(Quantity, 2 * PL_Qty);
        JobPlanningLine.Validate("Usage Link", true);
        JobPlanningLine.Modify(true);

        // [GIVEN] Purchase orders with two lines for the job planning line, split the quantity
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        CreatePurchaseLineForJobPlanningLine(PurchaseHeader, JobPlanningLine, PL_Qty);
        CreatePurchaseLineForJobPlanningLine(PurchaseHeader, JobPlanningLine, PL_Qty);

        // [WHEN] Post the purchase order
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        // refresh
        JobPlanningLine.Get(Job."No.", JobTask."Job Task No.", JobPlanningLine."Line No.");

        // [THEN] Verify that the planning line is processed and quantity stays the same
        JobPlanningLine.TestField(Quantity, 2 * PL_Qty);
        JobPlanningLine.TestField("Qty. Posted", JobPlanningLine.Quantity);
        JobPlanningLine.TestField("Qty. to Transfer to Journal", 0);
        JobPlanningLine.TestField("Remaining Qty.", 0);
    end;

    local procedure Initialize()
    var
        PurchasePrice: Record "Purchase Price";
        SalesPrice: Record "Sales Price";
        SalesLineDiscount: Record "Sales Line Discount";
        LibrarySales: Codeunit "Library - Sales";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Job Consumption - Usage Link");
        LibraryVariableStorage.Clear();
        if Initialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Job Consumption - Usage Link");

        // Removing special prices, discounts
        PurchasePrice.DeleteAll(true);
        SalesPrice.DeleteAll(true);
        SalesLineDiscount.DeleteAll(true);

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibrarySales.SetCreditWarningsToNoWarnings();
        UpdateCustNoSeries(); // required for FI

        DummyJobsSetup."Allow Sched/Contract Lines Def" := false;
        DummyJobsSetup."Apply Usage Link by Default" := false;
        DummyJobsSetup.Modify();
        LibraryJob.SetJobNoSeriesCode();

        Initialized := true;

        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Job Consumption - Usage Link");
    end;

    local procedure LinkQuantities(QtyToPost: Decimal; QtyToMatch: Decimal; ConsumableType: Enum "Job Planning Line Type")
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        BeforeJobPlanningLine: Record "Job Planning Line";
        JobJournalLine: Record "Job Journal Line";
        JobLedgerEntry: Record "Job Ledger Entry";
        LineCount: Integer;
    begin
        Assert.AreNotEqual(0, QtyToPost, 'Quantitiy to post should not be zero.');
        Assert.AreNotEqual(0, QtyToMatch, 'Quantitiy to post should not be zero.');

        // Users may use up to five decimal places
        QtyToPost := Round(QtyToPost, 0.00001);
        QtyToMatch := Round(QtyToMatch, 0.00001);

        // Setup
        Initialize();
        CreateJob(true, true, Job);
        LibraryJob.CreateJobTask(Job, JobTask);

        // this is the planning line we want to match
        LibraryJob.CreateJobPlanningLine(LibraryJob.PlanningLineTypeSchedule(), ConsumableType, JobTask, JobPlanningLine);
        JobPlanningLine.Validate(Quantity, QtyToMatch);
        JobPlanningLine.Validate("Usage Link", true);
        JobPlanningLine.Modify(true);

        AssertNoDiscounts(JobPlanningLine);
        BeforeJobPlanningLine := JobPlanningLine;

        // to make it more difficult
        CreateSimilarJobPlanningLines(JobPlanningLine);
        LineCount := JobPlanningLine.Count();

        // Exercise
        if (QtyToPost < 0) and (ConsumableType = LibraryJob.ItemType()) then begin
            // Before crediting, use item first
            JobPlanningLine.Validate("Line No.", LibraryJob.GetNextLineNo(JobPlanningLine));
            JobPlanningLine.Validate(Quantity, Abs(QtyToPost));
            JobPlanningLine.Validate(Description, LibraryUtility.GenerateGUID());
            JobPlanningLine.Insert(true);
            LineCount += 1;
            LibraryJob.UseJobPlanningLineExplicit(
              JobPlanningLine, LibraryJob.UsageLineTypeBlank(), 1, LibraryJob.JobConsumption(), JobJournalLine);
            JobPlanningLine := BeforeJobPlanningLine
        end;

        LibraryJob.UseJobPlanningLineExplicit(
          JobPlanningLine, LibraryJob.UsageLineTypeBlank(), QtyToPost / QtyToMatch, LibraryJob.JobConsumption(), JobJournalLine);

        // refresh
        JobPlanningLine.Get(Job."No.", JobTask."Job Task No.", JobPlanningLine."Line No.");

        // Verify
        JobLedgerEntry.SetRange(Description, JobJournalLine.Description);
        JobLedgerEntry.FindFirst();
        VerifyUsageLink(JobPlanningLine, JobLedgerEntry);

        Assert.AreEqual(LineCount, JobPlanningLine.Count, 'No planning lines should have been created.');

        VerifyJobPlanningLine(BeforeJobPlanningLine, JobPlanningLine, JobJournalLine)
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure UseMoreSpecificItemLocation()
    begin
        Initialize();
        Assert.AreEqual(0, UseItemVariations('A', '', 'A', GetLocationA()), 'No planning lines should have been created.')
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure UseMoreSpecificItemVariant()
    begin
        Initialize();
        Assert.AreEqual(0, UseItemVariations('', GetLocationA(), 'A', GetLocationA()), 'No planning lines should have been created.')
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure UseLessSpecificItemLocation()
    begin
        Initialize();
        Assert.AreEqual(1, UseItemVariations('A', GetLocationA(), 'A', ''), 'One planning line should have been created.')
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure UseLessSpecificItemVariant()
    begin
        Initialize();
        Assert.AreEqual(1, UseItemVariations('A', GetLocationA(), '', GetLocationA()), 'One planning line should have been created.')
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure UseDifferentItemLocation()
    begin
        Initialize();
        Assert.AreEqual(1, UseItemVariations('A', GetLocationA(), 'A', GetLocationB()), 'One planning line should have been created.')
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure UseDifferentItemVariant()
    begin
        Initialize();
        Assert.AreEqual(1, UseItemVariations('A', GetLocationA(), 'B', GetLocationA()), 'One planning line should have been created.')
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure UseSameItemLocation()
    begin
        Initialize();
        Assert.AreEqual(0, UseItemVariations('', GetLocationA(), '', GetLocationA()), 'No planning lines should have been created.')
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure UseSameItemVariant()
    begin
        Initialize();
        Assert.AreEqual(0, UseItemVariations('A', '', 'A', ''), 'No planning lines should have been created.')
    end;

    local procedure UseItemVariations(VariantCodePlan: Code[10]; LocationCodePlan: Code[10]; VariantCodeUse: Code[10]; LocationCodeUse: Code[10]): Integer
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        JobJournalLine: Record "Job Journal Line";
        JobLedgerEntry: Record "Job Ledger Entry";
        LineCount: Integer;
    begin
        // Use an item with variant and location codes for a planning line with variant and location codes
        // Verify that a line is matched or a new line is created.

        // Setup
        Initialize();
        CreateJob(true, true, Job);
        LibraryJob.CreateJobTask(Job, JobTask);

        // this is the planning line we want to match
        LibraryJob.CreateJobPlanningLine(LibraryJob.PlanningLineTypeSchedule(), LibraryJob.ItemType(), JobTask, JobPlanningLine);
        JobPlanningLine.Validate("Variant Code", CreateItemVariant(JobPlanningLine."No.", VariantCodePlan));
        JobPlanningLine.Validate("Location Code", LocationCodePlan);
        JobPlanningLine.Modify(true);

        LineCount := JobPlanningLine.Count();

        // Exercise
        LibraryJob.CreateJobJournalLineForPlan(JobPlanningLine, LibraryJob.UsageLineTypeSchedule(), 1, JobJournalLine);
        JobJournalLine.Validate("Variant Code", CreateItemVariant(JobJournalLine."No.", VariantCodeUse));
        JobJournalLine.Validate("Location Code", LocationCodeUse);
        JobJournalLine.Validate(Description, LibraryUtility.GenerateGUID());
        JobJournalLine.Modify(true);
        LibraryJob.PostJobJournal(JobJournalLine);

        // get the original or the newly created line (if one was created)
        JobPlanningLine.FindLast();

        // verify
        JobLedgerEntry.SetRange(Description, JobJournalLine.Description);
        JobLedgerEntry.FindFirst();
        VerifyUsageLink(JobPlanningLine, JobLedgerEntry);

        exit(JobPlanningLine.Count - LineCount)
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure UseMoreSpecificResource()
    begin
        Assert.AreEqual(0, UseResourceVariations('', 'A'), 'No planning lines should have been created.')
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure UseLessSpecificResource()
    begin
        Assert.AreEqual(1, UseResourceVariations('A', ''), 'One planning line should have been created.')
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure UseDifferentResourceWorkType()
    begin
        Assert.AreEqual(1, UseResourceVariations('A', 'B'), 'One planning line should have been created.')
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure UseSameResourceWorkType()
    begin
        Assert.AreEqual(0, UseResourceVariations('A', 'A'), 'No planning lines should have been created.')
    end;

    local procedure UseResourceVariations(WorkTypeCodePlan: Code[10]; WorkTypeCodeUse: Code[10]): Integer
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        JobJournalLine: Record "Job Journal Line";
        JobLedgerEntry: Record "Job Ledger Entry";
        LineCount: Integer;
    begin
        // Use a resource work type code for a planning line with work type code
        // Verify that a usage link is created
        // Return the number of planning lines created

        // Setup
        Initialize();
        CreateJob(true, true, Job);
        LibraryJob.CreateJobTask(Job, JobTask);

        // this is the planning line we want to match
        LibraryJob.CreateJobPlanningLine(LibraryJob.PlanningLineTypeSchedule(), LibraryJob.ResourceType(), JobTask, JobPlanningLine);
        JobPlanningLine.Validate("Work Type Code", CreateWorkType(WorkTypeCodePlan));
        JobPlanningLine.Modify(true);

        LineCount := JobPlanningLine.Count();

        // Exercise
        LibraryJob.CreateJobJournalLineForPlan(JobPlanningLine, LibraryJob.UsageLineTypeSchedule(), 1, JobJournalLine);
        JobJournalLine.Validate("Work Type Code", CreateWorkType(WorkTypeCodeUse));
        JobJournalLine.Modify(true);
        LibraryJob.PostJobJournal(JobJournalLine);

        // get the original or the newly created line (if one was created)
        JobPlanningLine.FindLast();

        // verify
        JobLedgerEntry.SetRange(Description, JobJournalLine.Description);
        JobLedgerEntry.FindFirst();
        VerifyUsageLink(JobPlanningLine, JobLedgerEntry);

        exit(JobPlanningLine.Count - LineCount)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ResourcePriceWhenWorkTypeCodeMatched()
    var
        JobTask: Record "Job Task";
        Resource: Record Resource;
        JobResourcePrice: Record "Job Resource Price";
        PriceListLine: Record "Price List Line";
        WorkTypeCode: Code[10];
        UnitPrice: Decimal;
    begin
        // Test Unit Price is suggested correctly according to JobResourcePrice setup when WorkTypeCode matched. Cover scenario 359275.
        // Setup: Create a Job, Job Task and Resource with UOM.
        ResourcePriceSuggestedSetup(JobTask, Resource, WorkTypeCode);
        JobResourcePrice.DeleteAll();

        // Create 2 Job Resource Price Lines.
        UnitPrice := LibraryRandom.RandDec(100, 2);
        CreateJobResourcePriceWithUnitPrice(JobTask, JobResourcePrice.Type::All, '', '', LibraryRandom.RandDec(100, 2)); // WorkTypeCode is blank
        CreateJobResourcePriceWithUnitPrice(JobTask, JobResourcePrice.Type::All, '', WorkTypeCode, UnitPrice);
        PriceListLine.DeleteAll();
        CopyFromToPriceListLine.CopyFrom(JobResourcePrice, PriceListLine);

        // Exercise: Create a Job Planning & Journal Line
        // Verify: Unit Price is suggested correctly according to JobResourcePrice setup when WorkTypeCode matched.
        Assert.AreEqual(
          UnitPrice, CreateJobPlanningLineWithWorkTypeCode(JobTask, Resource."No.", WorkTypeCode), UnitPriceErr);
        Assert.AreEqual(
          UnitPrice, CreateJobJournalLineWithWorkTypeCode(JobTask, Resource."No.", WorkTypeCode), UnitPriceErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ResourcePriceWhenResoureNoMatchedButWorkTypeCodeNotMatched()
    var
        JobTask: Record "Job Task";
        Resource: Record Resource;
        Resource2: Record Resource;
        JobResourcePrice: Record "Job Resource Price";
        PriceListLine: Record "Price List Line";
        WorkTypeCode: Code[10];
        WorkTypeCode2: Code[10];
        UnitPrice: Decimal;
    begin
        // Unit Price is suggested correctly according to JobResourcePrice setup when ResoureNo matched but WorkTypeCode not matched.
        // Setup: Create a Job, Job Task and Resource
        ResourcePriceSuggestedSetup(JobTask, Resource, WorkTypeCode);
        JobResourcePrice.DeleteAll();
        CreateResourceWithWorkTypeCodeAndUOM(Resource2, WorkTypeCode2);

        // Create 1 Job Resource Price Lines
        UnitPrice := LibraryRandom.RandDec(100, 2);
        CreateJobResourcePriceWithUnitPrice(JobTask, JobResourcePrice.Type::All, '', '', UnitPrice);
        CreateJobResourcePriceWithUnitPrice(
          JobTask, JobResourcePrice.Type::"Group(Resource)", CreateResourceGroup(Resource),
          WorkTypeCode, LibraryRandom.RandDec(100, 2));
        CreateJobResourcePriceWithUnitPrice(
          JobTask, JobResourcePrice.Type::"Group(Resource)", CreateResourceGroup(Resource2),
          WorkTypeCode2, LibraryRandom.RandDec(100, 2));
        PriceListLine.DeleteAll();
        CopyFromToPriceListLine.CopyFrom(JobResourcePrice, PriceListLine);

        // Exercise: Create a Job Planning & Journal Line
        // Verify: Unit Price is suggested correctly according to JobResourcePrice setup when ResoureNo matched but WorkTypeCode not matched.
        Assert.AreEqual(
          UnitPrice, CreateJobPlanningLineWithWorkTypeCode(JobTask, Resource2."No.", WorkTypeCode), UnitPriceErr);
        Assert.AreEqual(
          UnitPrice, CreateJobJournalLineWithWorkTypeCode(JobTask, Resource2."No.", WorkTypeCode), UnitPriceErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ResourcePriceWhenResourceWithGroupNoAndWorkTypeCode()
    var
        JobTask: Record "Job Task";
        Resource: Record Resource;
        JobResourcePrice: Record "Job Resource Price";
        PriceListLine: Record "Price List Line";
        WorkTypeCode: Code[10];
        UnitPrice: Decimal;
    begin
        // Test Unit Price is suggested correctly according to JobResourcePrice setup when Resource with Group No. and Work Type Code. Cover scenario PS42257 (TFS211740)
        // Setup: Create a Job, Job Task and Resource
        ResourcePriceSuggestedSetup(JobTask, Resource, WorkTypeCode);
        JobResourcePrice.DeleteAll();
        CreateResourceGroup(Resource);

        // Create 1 Job Resource Price Lines.
        UnitPrice := LibraryRandom.RandDec(100, 2);
        CreateJobResourcePriceWithUnitPrice(JobTask, JobResourcePrice.Type::All, '', '', UnitPrice);
        PriceListLine.DeleteAll();
        CopyFromToPriceListLine.CopyFrom(JobResourcePrice, PriceListLine);

        // Exercise: Create a Job Planning & Journal Line
        // Verify: Unit Price is suggested correctly according to JobResourcePrice setup when Resource with Group No. and Work Type Code.
        Assert.AreEqual(
          UnitPrice, CreateJobPlanningLineWithWorkTypeCode(JobTask, Resource."No.", WorkTypeCode), UnitPriceErr);
        Assert.AreEqual(
          UnitPrice, CreateJobJournalLineWithWorkTypeCode(JobTask, Resource."No.", WorkTypeCode), UnitPriceErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmSpecificMessageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ConfirmUsagePostingWithBlankLineAndApplyUsageEnabled()
    var
        JobTask: Record "Job Task";
        JobJournalLine: Record "Job Journal Line";
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        // [SCENARIO 380473] Confirmation is raised when post usage with blank "Line Type" and "Apply Usage Link"

        Initialize();

        // [GIVEN] Job with "Apply Usage Link"
        CreateJobWithTaskAndApplyUsageLink(JobTask);

        // [GIVEN] Job Journal Line for Usage with blank "Line Type"
        LibraryJob.CreateJobJournalLineForType(LibraryJob.UsageLineTypeBlank(), LibraryJob.ItemType(), JobTask, JobJournalLine);
        SetSourceForConfirmSpecificMessageHandler(true);

        // [WHEN] Post Job Journal Line and confirm message "The Line Type of Job Journal Line was not defined. Do you want to continue?"
        LibraryJob.PostJobJournal(JobJournalLine);

        // [THEN] Job Ledger Entry for Usage is posted
        JobLedgerEntry.SetRange("Entry Type", JobLedgerEntry."Entry Type"::Usage);
        JobLedgerEntry.SetRange("Job No.", JobTask."Job No.");
        Assert.RecordIsNotEmpty(JobLedgerEntry);
    end;

    [Test]
    [HandlerFunctions('ConfirmSpecificMessageHandler')]
    [Scope('OnPrem')]
    procedure CancelConfirmationUsagePostingWithBlankLineAndApplyUsageEnabled()
    var
        JobTask: Record "Job Task";
        JobJournalLine: Record "Job Journal Line";
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        // [SCENARIO 380473] No entries are posted if cancel confirmation when post usage with blank "Line Type" and "Apply Usage Link"

        Initialize();

        // [GIVEN] Job with "Apply Usage Link"
        CreateJobWithTaskAndApplyUsageLink(JobTask);

        // [GIVEN] Job Journal Line for Usage with blank "Line Type"
        LibraryJob.CreateJobJournalLineForType(LibraryJob.UsageLineTypeBlank(), LibraryJob.ItemType(), JobTask, JobJournalLine);
        SetSourceForConfirmSpecificMessageHandler(false);

        // [WHEN] Post Job Journal Line and cancel confirmation message "The Line Type of Job Journal Line was not defined. Do you want to continue?"
        asserterror LibraryJob.PostJobJournal(JobJournalLine);

        // [THEN] Job Ledger Entry for Usage is not posted
        JobLedgerEntry.SetRange("Entry Type", JobLedgerEntry."Entry Type"::Usage);
        JobLedgerEntry.SetRange("Job No.", JobTask."Job No.");
        Assert.RecordIsEmpty(JobLedgerEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobUsageLinkTableRelations_UT()
    var
        Job1: Record Job;
        Job2: Record Job;
        JobTask1: Record "Job Task";
        JobTask2: Record "Job Task";
        JobPlanningLine1: Record "Job Planning Line";
        JobPlanningLine2: Record "Job Planning Line";
        JobUsageLink: Record "Job Usage Link";
        JobTaskNo: Code[20];
        JobPlanningLineNo: Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 380845] Renaming of "Job" or "Job Task" causes proper update in "Job Usage Link" table
        JobTaskNo := LibraryUtility.GenerateGUID();
        JobPlanningLineNo := 10000;
        MockJobPlanningLine(Job1, JobTask1, JobPlanningLine1, JobTaskNo, JobPlanningLineNo);
        MockJobUsageLink(JobUsageLink, Job1."No.", JobTask1."Job Task No.", JobPlanningLine1."Line No.");

        MockJobPlanningLine(Job2, JobTask2, JobPlanningLine2, JobTaskNo, JobPlanningLineNo);
        MockJobUsageLink(JobUsageLink, Job2."No.", JobTask2."Job Task No.", JobPlanningLine2."Line No.");

        Job2.Rename(LibraryUtility.GenerateGUID());

        JobUsageLink.SetRange("Job No.", Job1."No.");
        Assert.AreEqual(1, JobUsageLink.Count, 'Wrong number of Job Usage Links');
        JobUsageLink.SetRange("Job No.", Job2."No.");
        Assert.AreEqual(1, JobUsageLink.Count, 'Wrong number of Job Usage Links');

        JobUsageLink.Reset();

        JobTask2.Get(Job2."No.", JobTask2."Job Task No.");
        JobTask2.Rename(Job2."No.", LibraryUtility.GenerateGUID());

        JobUsageLink.SetRange("Job Task No.", JobTask1."Job Task No.");
        Assert.AreEqual(1, JobUsageLink.Count, 'Wrong number of Job Usage Links');
        JobUsageLink.SetRange("Job Task No.", JobTask2."Job Task No.");
        Assert.AreEqual(1, JobUsageLink.Count, 'Wrong number of Job Usage Links');

        JobPlanningLine2.Get(Job2."No.", JobTask2."Job Task No.", JobPlanningLine2."Line No.");
        asserterror JobPlanningLine2.Rename(JobPlanningLine2."Job No.", JobPlanningLine2."Job Task No.", JobPlanningLine2."Line No." + 1);

        Assert.ExpectedError(
          StrSubstNo(
            JobPlanningLineRenameErr,
            JobPlanningLine2.FieldCaption("Job No."),
            JobPlanningLine2.FieldCaption("Job Task No."),
            JobPlanningLine2.TableCaption()));
    end;

    local procedure CreateJobResourcePriceWithUnitPrice(JobTask: Record "Job Task"; JobResourcePriceType: Option; "Code": Code[20]; WorkTypeCode: Code[10]; UnitPrice: Decimal)
    var
        JobResourcePrice: Record "Job Resource Price";
    begin
        LibraryJob.CreateJobResourcePrice(
          JobResourcePrice, JobTask."Job No.", JobTask."Job Task No.", JobResourcePriceType, Code, WorkTypeCode, '');
        JobResourcePrice.Validate("Unit Price", UnitPrice);
        JobResourcePrice.Modify(true);
    end;

    local procedure CreateJobPlanningLineWithWorkTypeCode(JobTask: Record "Job Task"; ResourceNo: Code[20]; WorkTypeCode: Code[10]): Decimal
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        LibraryJob.CreateJobPlanningLine(LibraryJob.PlanningLineTypeContract(), LibraryJob.ResourceType(), JobTask, JobPlanningLine);
        JobPlanningLine.Validate("No.", ResourceNo);
        JobPlanningLine.Validate("Work Type Code", WorkTypeCode);
        JobPlanningLine.Modify(true);
        exit(JobPlanningLine."Unit Price");
    end;

    local procedure CreateJobJournalLineWithWorkTypeCode(JobTask: Record "Job Task"; ResourceNo: Code[20]; WorkTypeCode: Code[10]): Decimal
    var
        JobJournalLine: Record "Job Journal Line";
    begin
        LibraryJob.CreateJobJournalLineForType(LibraryJob.UsageLineTypeContract(), LibraryJob.ResourceType(), JobTask, JobJournalLine);
        JobJournalLine.Validate("No.", ResourceNo);
        JobJournalLine.Validate("Work Type Code", WorkTypeCode);
        JobJournalLine.Modify(true);
        exit(JobJournalLine."Unit Price");
    end;

    local procedure CreateJob(ApplyUsageLink: Boolean; BothAllowed: Boolean; var Job: Record Job)
    begin
        LibraryJob.CreateJob(Job);
        Job.Validate("Apply Usage Link", ApplyUsageLink);
        Job.Validate("Allow Schedule/Contract Lines", BothAllowed);
        Job.Modify(true)
    end;

    local procedure CreateJobWithTaskAndApplyUsageLink(var JobTask: Record "Job Task")
    var
        Job: Record Job;
    begin
        LibraryJob.CreateJob(Job);
        Job.Validate("Apply Usage Link", true);
        Job.Modify(true);
        LibraryJob.CreateJobTask(Job, JobTask);
    end;

    local procedure CreateResourceGroup(Resource: Record Resource): Code[10]
    var
        ResourceGroup: Record "Resource Group";
    begin
        LibraryResource.CreateResourceGroup(ResourceGroup);
        Resource.Validate("Resource Group No.", ResourceGroup."No.");
        Resource.Modify(true);
        exit(ResourceGroup."No.");
    end;

    local procedure CreateResourceWithWorkTypeCodeAndUOM(var Resource: Record Resource; var WorkTypeCode: Code[10])
    begin
        LibraryResource.CreateResourceNew(Resource);
        WorkTypeCode := Format(LibraryRandom.RandIntInRange(1000000, 9999999));
        CreateWorkType(WorkTypeCode);
        UpdateWorkTypeForUnitOfMeasureCode(WorkTypeCode, Resource."Base Unit of Measure");
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

    local procedure CreateJobPlanningLinePerType(JobTask: Record "Job Task"; var JobPlanningLine: Record "Job Planning Line")
    begin
        // Create planning line for all line types
        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::Budget, JobPlanningLine.Type::Resource, JobTask, JobPlanningLine);
        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::"Both Budget and Billable", JobPlanningLine.Type::Resource, JobTask, JobPlanningLine);
        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::Billable, JobPlanningLine.Type::Resource, JobTask, JobPlanningLine);

        JobPlanningLine.SetRange("Job No.", JobTask."Job No.");
        JobPlanningLine.SetRange("Job Task No.", JobTask."Job Task No.");
        JobPlanningLine.FindSet();
    end;

    local procedure CreateItemVariant(ItemNo: Code[20]; VariantCode: Code[10]): Code[10]
    var
        ItemVariant: Record "Item Variant";
    begin
        if (VariantCode = '') or ItemVariant.Get(ItemNo, VariantCode) then
            exit(VariantCode);

        ItemVariant.Init();
        ItemVariant.Validate("Item No.", ItemNo);
        ItemVariant.Validate(Code, VariantCode);
        ItemVariant.Insert(true);
        exit(VariantCode)
    end;

    local procedure CreateWorkType(WorkTypeCode: Code[10]): Code[10]
    var
        WorkType: Record "Work Type";
    begin
        if WorkType.Get(WorkTypeCode) then
            exit(WorkTypeCode);

        WorkType.Init();
        WorkType.Validate(Code, WorkTypeCode);
        WorkType.Insert(true);
        exit(WorkTypeCode)
    end;

    local procedure CreatePurchaseLineForJobPlanningLine(Purchaseheader: Record "Purchase Header"; JobPlanningLine: Record "Job Planning Line"; Qty: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", JobPlanningLine."No.", Qty);
        PurchaseLine.Validate("Job No.", JobPlanningLine."Job No.");
        PurchaseLine.Validate("Job Task No.", JobPlanningLine."Job Task No.");
        PurchaseLine.Validate("Job Planning Line No.", JobPlanningLine."Line No.");
        PurchaseLine.Modify(true);
    end;

    local procedure MockJobPlanningLine(var Job: Record Job; var JobTask: Record "Job Task"; var JobPlanningLine: Record "Job Planning Line"; JobTaskNo: Code[20]; JobPlanningLineNo: Integer)
    begin
        Job.Init();
        Job."No." := LibraryUtility.GenerateGUID();
        Job.Insert();

        JobTask.Init();
        JobTask."Job No." := Job."No.";
        JobTask."Job Task No." := JobTaskNo;
        JobTask.Insert();

        JobPlanningLine.Init();
        JobPlanningLine."Job No." := JobTask."Job No.";
        JobPlanningLine."Job Task No." := JobTask."Job Task No.";
        JobPlanningLine."Line No." := JobPlanningLineNo;
        JobPlanningLine.Insert();
    end;

    local procedure MockJobUsageLink(var JobUsageLink: Record "Job Usage Link"; JobNo: Code[20]; JobTaskNo: Code[20]; LineNo: Integer)
    begin
        JobUsageLink.Init();
        JobUsageLink."Job No." := JobNo;
        JobUsageLink."Job Task No." := JobTaskNo;
        JobUsageLink."Line No." := LineNo;
        JobUsageLink."Entry No." := LibraryRandom.RandInt(10);
        JobUsageLink.Insert();
    end;

    local procedure ResourcePriceSuggestedSetup(var JobTask: Record "Job Task"; var Resource: Record Resource; var WorkTypeCode: Code[10])
    var
        Job: Record Job;
    begin
        Initialize();
        CreateJob(true, true, Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        CreateResourceWithWorkTypeCodeAndUOM(Resource, WorkTypeCode);
    end;

    local procedure UpdateWorkTypeForUnitOfMeasureCode(WorkTypeCode: Code[10]; BaseUnitOfMeasure: Code[10])
    var
        WorkType: Record "Work Type";
    begin
        WorkType.Get(WorkTypeCode);
        WorkType.Validate("Unit of Measure Code", BaseUnitOfMeasure);
        WorkType.Modify(true);
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

    local procedure VerifyJobPlanningLineDone(JobPlanningLine: Record "Job Planning Line")
    begin
        JobPlanningLine.TestField("Remaining Qty.", 0);
        JobPlanningLine.TestField("Remaining Total Cost", 0);
        JobPlanningLine.TestField("Remaining Line Amount", 0);
        JobPlanningLine.TestField("Qty. Posted", JobPlanningLine.Quantity)
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

    local procedure UseFromPlan(var JobJournalLine: Record "Job Journal Line"; var JobPlanningLine: Record "Job Planning Line")
    var
        RemainingUsage: Decimal;
    begin
        Assert.AreEqual(JobJournalLine.Type, JobPlanningLine.Type, 'Incompatible types.');
        RemainingUsage := JobJournalLine.Quantity - JobPlanningLine."Remaining Qty.";

        // idem
        if (RemainingUsage > 0) <> (JobPlanningLine."Remaining Qty." > 0) then
            RemainingUsage := 0;
        JobJournalLine.Validate(Quantity, RemainingUsage)
    end;

    local procedure "Max"(x: Decimal; y: Decimal): Decimal
    begin
        if x > y then
            exit(x);
        exit(y)
    end;

    local procedure SetSourceForConfirmSpecificMessageHandler(ConfirmPostingOfBlankLineType: Boolean)
    begin
        LibraryVariableStorage.Enqueue(PostJournalLineQst);
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(ConfirmUsageWithBlankLineTypeQst);
        LibraryVariableStorage.Enqueue(ConfirmPostingOfBlankLineType);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmSpecificMessageHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Question);
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    local procedure GetLocationA(): Code[10]
    var
        Location: Record Location;
    begin
        if LibraryVariableStorage.Length() < 1 then begin
            LibraryJob.FindLocation(Location);
            LibraryInventory.UpdateInventoryPostingSetup(Location);
            LibraryVariableStorage.Enqueue(Location.Code);
            exit(Location.Code);
        end;
        exit(LibraryVariableStorage.PeekText(1));
    end;

    local procedure GetLocationB(): Code[10]
    var
        Location: Record Location;
    begin
        if LibraryVariableStorage.Length() < 2 then begin
            Location.SetFilter(Code, '<>%1', GetLocationA());
            LibraryJob.FindLocation(Location);
            LibraryInventory.UpdateInventoryPostingSetup(Location);
            LibraryVariableStorage.Enqueue(Location.Code);
            exit(Location.Code);
        end;
        exit(LibraryVariableStorage.PeekText(2));
    end;

    local procedure UpdateCustNoSeries()
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        SalesSetup.Get();
        SalesSetup.Validate("Customer Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesSetup.Modify(true);
    end;
}
