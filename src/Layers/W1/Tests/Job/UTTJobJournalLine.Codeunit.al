codeunit 136351 "UT T Job Journal Line"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Job] [UT]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        LibraryJob: Codeunit "Library - Job";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        IsInitialized: Boolean;
        RoundingTo0Err: Label 'Rounding of the field';

    [Test]
    [Scope('OnPrem')]
    procedure TestInitialization()
    var
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        JobJournalLine: Record "Job Journal Line";
    begin
        Initialize();
        SetUp(JobTask, JobPlanningLine, JobJournalLine);

        // Verify that "Job Planning Line No." is initialized correctly.
        Assert.AreEqual(0, JobJournalLine."Job Planning Line No.", 'Job Planning Line No. is not 0 by default.');

        // Verify that "Remaining Qty." is initialized correctly.
        Assert.AreEqual(0, JobJournalLine."Remaining Qty.", 'Remaining Qty. is not 0 by default.');

        TearDown(JobTask, JobPlanningLine, JobJournalLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFieldLineType()
    var
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        JobJournalLine: Record "Job Journal Line";
    begin
        Initialize();
        SetUp(JobTask, JobPlanningLine, JobJournalLine);

        // Verify that "Line Type" is set to the correct value when a "Job Planning Line No." is set.
        JobJournalLine.Validate("Line Type", 0);
        JobJournalLine.Validate("Job Planning Line No.", JobPlanningLine."Line No.");
        Assert.AreEqual(JobPlanningLine."Line Type", JobJournalLine."Line Type".AsInteger() - 1,
          'Line type is not set correctly when Job Planning Line No. is defined.');

        // Verify that "Line Type" can't be changed if a "Job Planning Line No." is defined.
        asserterror JobJournalLine.Validate("Line Type", 0);

        TearDown(JobTask, JobPlanningLine, JobJournalLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestFieldJobPlanningLineNo()
    var
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        JobJournalLine: Record "Job Journal Line";
        TestJobPlanningLine: Record "Job Planning Line";
        JobJournalLine2: Record "Job Journal Line";
    begin
        Initialize();
        SetUp(JobTask, JobPlanningLine, JobJournalLine);

        // Verify that you cannot set a Job Planning Line with a wrong Job No., Job Task No., Type or No. (Test of one is enough).
        TestJobPlanningLine.Init();
        TestJobPlanningLine."Job No." := JobJournalLine."Job No.";
        TestJobPlanningLine."Job Task No." := JobJournalLine."Job Task No.";
        TestJobPlanningLine."Line No." := 1;
        TestJobPlanningLine.Type := JobJournalLine.Type;
        TestJobPlanningLine."No." := JobJournalLine."No.";
        TestJobPlanningLine."Usage Link" := true;
        TestJobPlanningLine.Insert();

        JobJournalLine.Validate("Job Planning Line No.", TestJobPlanningLine."Line No."); // Prove that it works.
        JobJournalLine.Validate("Job Planning Line No.", 0);

        TestJobPlanningLine.Get(JobTask."Job No.", JobTask."Job Task No.", 1);
        TestJobPlanningLine."No." := 'TEST';
        TestJobPlanningLine.Modify();
        asserterror JobJournalLine.Validate("Job Planning Line No.", TestJobPlanningLine."Line No.");
        // Prove that it does not work anymore.

        TearDown(JobTask, JobPlanningLine, JobJournalLine);

        SetUp(JobTask, JobPlanningLine, JobJournalLine);

        // Verify that "Job Planning Line No." (and "Remaining Qty.") is blanked when the No. changes.
        JobJournalLine.Validate("Job Planning Line No.", JobPlanningLine."Line No.");
        JobJournalLine.TestField("Job Planning Line No.");
        JobJournalLine.Validate("No.", '');
        Assert.AreEqual(0, JobJournalLine."Job Planning Line No.", 'Job Planning Line No. is not 0 when No. changes.');
        Assert.AreEqual(0, JobJournalLine."Remaining Qty.", 'Remaining Qty. is not 0 when No. changes.');

        // Remaining test for this field are found in test function TestFieldRemainingQty.

        TearDown(JobTask, JobPlanningLine, JobJournalLine);

        SetUp(JobTask, JobPlanningLine, JobJournalLine);

        // Validate that function does not throw message when no Job Planning Line is linked before linking.
        JobJournalLine.Validate("Job Planning Line No.", JobPlanningLine."Line No.");
        JobJournalLine.Modify();

        // Validate that function throws a message when another Job Planning Line is linked before linking.
        LibraryJob.CreateJobJournalLine(JobJournalLine2."Line Type"::Budget, JobTask, JobJournalLine2);
        JobJournalLine2.Validate(Type, JobPlanningLine.Type);
        JobJournalLine2.Validate("No.", JobPlanningLine."No.");
        JobJournalLine2.Modify();

        asserterror JobJournalLine2.Validate("Job Planning Line No.", JobPlanningLine."Line No.");

        TearDown(JobTask, JobPlanningLine, JobJournalLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFieldRemainingQty()
    var
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        JobJournalLine: Record "Job Journal Line";
        QtyDelta: Decimal;
        OldRemainingQty: Decimal;
    begin
        Initialize();
        SetUp(JobTask, JobPlanningLine, JobJournalLine);

        // Verify that "Remaining Qty." can't be set if not "Job Planning Line No." is set.
        asserterror JobJournalLine.Validate("Remaining Qty.", LibraryRandom.RandInt(Round(JobJournalLine.Quantity, 1)));

        TearDown(JobTask, JobPlanningLine, JobJournalLine);

        SetUp(JobTask, JobPlanningLine, JobJournalLine);

        // Verify that "Remaining Qty." is set correctly when a "Job Planning Line No." is defined.
        JobJournalLine.TestField("Job Planning Line No.", 0);
        JobJournalLine.TestField("Remaining Qty.", 0);
        JobJournalLine.TestField(Quantity, 0);
        JobJournalLine.Validate("Job Planning Line No.", JobPlanningLine."Line No.");
        Assert.AreEqual(JobPlanningLine."Remaining Qty.", JobJournalLine."Remaining Qty.", 'Remaining Qty. is not set correctly');
        Assert.AreEqual(JobPlanningLine."Remaining Qty. (Base)", JobJournalLine."Remaining Qty. (Base)",
          'Remaining Qty. (Base) is not set correctly');

        // Verify that "Remaining Qty." changes correctly when Quantity is changed.
        OldRemainingQty := JobJournalLine."Remaining Qty.";
        QtyDelta := LibraryRandom.RandInt(Round(JobJournalLine."Remaining Qty.", 1));
        JobJournalLine.Validate(Quantity, JobJournalLine.Quantity + QtyDelta);
        Assert.AreEqual(OldRemainingQty - QtyDelta, JobJournalLine."Remaining Qty.",
          'Remaining Qty. is not updated correctly');
        // Test only valid because no Unit Of Measure Code is defined:
        JobJournalLine.TestField("Qty. per Unit of Measure", 1);
        Assert.AreEqual(JobJournalLine."Remaining Qty.", JobJournalLine."Remaining Qty. (Base)",
          'Remaining Qty. (Base) is not updated correctly');

        TearDown(JobTask, JobPlanningLine, JobJournalLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure ApplyUsageForJobJnlLineWithBlankLineType()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobJournalLine: Record "Job Journal Line";
        JobPlanningLine: Record "Job Planning Line";
        JobLedgEntry: Record "Job Ledger Entry";
        JobLinkUsage: Codeunit "Job Link Usage";
    begin
        // [FEATURE] [Apply Usage Link]
        // [SCENARIO 374943] No Job Planning Lines are created when apply usage for Job with "Apply Usage Link" and Job Journal Line with blank "Line Type"

        Initialize();
        // [GIVEN] Job with "Apply Usage Link" = Yes
        CreateJobWithApplyUsageLink(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        // [GIVEN] Job Journal Line with blank "Line Type"
        LibraryJob.CreateJobJournalLine(JobJournalLine."Line Type"::" ", JobTask, JobJournalLine);
        // [GIVEN] Job Ledger entry with random Item and Quantity
        CreateJobLedgEntry(JobLedgEntry, JobTask);

        // [WHEN] Apply Usage for Job Journal Line and Job Ledger Entry
        JobLinkUsage.ApplyUsage(JobLedgEntry, JobJournalLine);

        // [THEN] No Job Planning Lines are created
        JobPlanningLine.Init();
        JobPlanningLine.SetRange("Job No.", Job."No.");
        Assert.RecordIsEmpty(JobPlanningLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanLineUnitCostAndUnitPriceRemainsWhenApplyUsage()
    var
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        JobLedgerEntry: Record "Job Ledger Entry";
        JobJournalLine: Record "Job Journal Line";
        Item: Record Item;
        JobLinkUsage: Codeunit "Job Link Usage";
        PlanLineUnitCost: Decimal;
        PlanLineUnitPrice: Decimal;
    begin
        // [FEATURE] [Apply Usage Link]
        // [SCENARIO 375866] Job Planning Line fields "Unit Cost (LCY)" and "Unit Price" remains when post Job Journal with Apply Usage Link and Quantity changing
        Initialize();
        SetUp(JobTask, JobPlanningLine, JobJournalLine);

        // [GIVEN] Item with "Unit Cost" = 10, "Unit Price" = 20.
        Item.Get(JobPlanningLine."No.");
        PlanLineUnitCost := Item."Unit Cost" * 2;
        PlanLineUnitPrice := Item."Unit Price" * 2;

        // [GIVEN] Job Planning Line with Item: "Usage Link" = TRUE, Quantity = 1,  "Unit Cost" = 100, "Unit Price" = 200.
        JobPlanningLine.Validate("Unit Cost (LCY)", PlanLineUnitCost);
        JobPlanningLine.Validate("Unit Price", PlanLineUnitPrice);
        JobPlanningLine.Modify();

        // [WHEN] Post Job Journal Line linked to Planning Line and Quantity = 2.
        JobJournalLine.Validate(Quantity, JobPlanningLine.Quantity * 2);
        JobJournalLine."Job Planning Line No." := JobPlanningLine."Line No.";
        JobLedgerEntry.Init();
        JobLedgerEntry.Validate("Job No.", JobTask."Job No.");
        JobLedgerEntry.Validate("Job Task No.", JobTask."Job Task No.");
        JobLinkUsage.ApplyUsage(JobLedgerEntry, JobJournalLine);

        // [THEN] Job Planning Line Quantity = 2, "Unit Cost (LCY)" = 100, "Unit Price" = 200
        JobPlanningLine.Find();
        Assert.AreEqual(JobJournalLine.Quantity, JobPlanningLine.Quantity, JobPlanningLine.FieldCaption(Quantity));
        Assert.AreEqual(PlanLineUnitCost, JobPlanningLine."Unit Cost (LCY)", JobPlanningLine.FieldCaption("Unit Cost (LCY)"));
        Assert.AreEqual(PlanLineUnitPrice, JobPlanningLine."Unit Price", JobPlanningLine.FieldCaption("Unit Price"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlankJobJnlLineDiscAmountLCYWhenValidateJobUnitPriceWithZeroValue()
    var
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        JobJnlLine: Record "Job Journal Line";
    begin
        // [SCENARIO 378016] "Line Discount Amount (LCY)" should be blank when validate "Unit Price" with zero value in Job Journal Line

        Initialize();
        SetUp(JobTask, JobPlanningLine, JobJnlLine);
        JobJnlLine.Validate("Line Discount Amount (LCY)", LibraryRandom.RandDec(200, 2));

        JobJnlLine.Validate("Unit Price (LCY)", 0);

        JobJnlLine.TestField("Line Discount Amount (LCY)", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlankPurchJobLineAmountLCYWhenValidateJobUnitPriceWithZeroValue()
    var
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        JobJnlLine: Record "Job Journal Line";
        PurchLine: Record "Purchase Line";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 378016] "Job Line Amount (LCY)" should be blank when validate "Job Unit Price" with zero value in Purchase Line

        Initialize();
        SetUp(JobTask, JobPlanningLine, JobJnlLine);

        MockPurchLineWithJobAmounts(PurchLine, JobTask);

        PurchLine.Validate("Job Unit Price", 0);

        PurchLine.TestField("Job Line Amount (LCY)", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlankPurchJobLineDiscAmountLCYWhenValidateJobUnitPriceWithZeroValue()
    var
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        JobJnlLine: Record "Job Journal Line";
        PurchLine: Record "Purchase Line";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 378016] "Job Line Disc. Amount (LCY)" should be blank when validate "Job Unit Price" with zero value in Purchase Line

        Initialize();
        SetUp(JobTask, JobPlanningLine, JobJnlLine);

        MockPurchLineWithJobAmounts(PurchLine, JobTask);

        PurchLine.Validate("Job Unit Price", 0);

        PurchLine.TestField("Job Line Disc. Amount (LCY)", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CountryRegionCodeAssignsFromJobToJobJnlLine()
    var
        CountryRegion: Record "Country/Region";
        Job: Record Job;
        JobJournalLine: Record "Job Journal Line";
    begin
        // [SCENARIO 258997] Country/Region code assigns from Job to Job Journal Line

        Initialize();
        LibraryJob.CreateJob(Job, LibrarySales.CreateCustomerNo());
        LibraryERM.CreateCountryRegion(CountryRegion);
        Job.Validate("Bill-to Country/Region Code", CountryRegion.Code);
        Job.Modify(true);

        JobJournalLine.Validate("Job No.", Job."No.");

        JobJournalLine.TestField("Country/Region Code", Job."Bill-to Country/Region Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobJournalValidateBlankPostingDate_TempTable()
    var
        TempJobJournalLine: Record "Job Journal Line" temporary;
    begin
        // [SCENARIO 337585] Can validate blank "Posting Date" on "Job Journal Line"
        TempJobJournalLine.Init();

        TempJobJournalLine.Validate("Posting Date", WorkDate());
        TempJobJournalLine.Validate("Posting Date", 0D);

        TempJobJournalLine.TestField("Posting Date", 0D);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobJournalValidateBlankPostingDate_NormalTable()
    var
        JobJournalLine: Record "Job Journal Line";
    begin
        // [SCENARIO 337585] Cannot validate blank "Posting Date" on "Job Journal Line"
        JobJournalLine.Init();
        JobJournalLine.Validate("Posting Date", WorkDate());
        asserterror JobJournalLine.Validate("Posting Date", 0D);

        JobJournalLine.TestField("Posting Date", WorkDate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorThrownWhenBaseQtyIsRoundedTo0OnJobJournalLine()
    var
        JobJournalLine: Record "Job Journal Line";
        Job: Record Job;
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        NonBaseQtyPerUOM: Decimal;
        QtyRoundingPrecision: Decimal;
    begin
        // [FEATURE] [Job Journal Line - Rounding Precision]
        // [SCENARIO] Error is thrown when rounding precision causes the base quantity to be rounded to 0.
        Initialize();

        // [GIVEN] An item with 2 unit of measures and qty. rounding precision on the base item unit of measure set.
        QtyRoundingPrecision := Round(1 / LibraryRandom.RandIntInRange(2, 10), 0.00001);
        NonBaseQtyPerUOM := Round(LibraryRandom.RandIntInRange(2, 10), QtyRoundingPrecision);

        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateUnitOfMeasureCode(BaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", BaseUOM.Code, 1);
        ItemUOM."Qty. Rounding Precision" := QtyRoundingPrecision;
        ItemUOM.Modify();
        Item.Validate("Base Unit of Measure", ItemUOM.Code);
        Item.Modify();

        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", NonBaseUOM.Code, NonBaseQtyPerUOM);

        // [GIVEN] A Job Journal Line where the unit of measure code is set to the non-base unit of measure.
        LibraryJob.CreateJob(Job);
        JobJournalLine.Init();
        JobJournalLine.Validate("Job No.", Job."No.");
        JobJournalLine.Validate(Type, JobJournalLine.Type::Item);
        JobJournalLine.Validate("No.", Item."No.");
        JobJournalLine.Validate("Unit of Measure Code", NonBaseUOM.Code);

        // [WHEN] Quantity is set to a value that rounds the base quantity to 0
        asserterror JobJournalLine.Validate(Quantity, 1 / (LibraryRandom.RandIntInRange(300, 1000)));

        // [THEN] Error is thrown
        Assert.ExpectedError(RoundingTo0Err);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BaseQtyIsRoundedWithRoundingPrecisionSpecifiedOnJobJournalLine()
    var
        JobJournalLine: Record "Job Journal Line";
        Job: Record Job;
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        NonBaseQtyPerUOM: Decimal;
        QtyRoundingPrecision: Decimal;
        QtyToSet: Decimal;
    begin
        // [FEATURE] [Job Journal Line - Rounding Precision]
        // [SCENARIO] Quantity (Base) is rounded with the specified rounding precision.
        Initialize();

        // [GIVEN] An item with 2 unit of measures and qty. rounding precision on the base item unit of measure set.
        QtyRoundingPrecision := Round(1 / LibraryRandom.RandIntInRange(2, 10), 0.00001);
        NonBaseQtyPerUOM := Round(LibraryRandom.RandIntInRange(2, 10), QtyRoundingPrecision);
        QtyToSet := LibraryRandom.RandDecInRange(1, 10, 2);

        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateUnitOfMeasureCode(BaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", BaseUOM.Code, 1);
        ItemUOM."Qty. Rounding Precision" := QtyRoundingPrecision;
        ItemUOM.Modify();
        Item.Validate("Base Unit of Measure", ItemUOM.Code);
        Item.Modify();
        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", NonBaseUOM.Code, NonBaseQtyPerUOM);

        // [GIVEN] A Job Journal Line where the unit of measure code is set to the non-base unit of measure.
        LibraryJob.CreateJob(Job);
        JobJournalLine.Init();
        JobJournalLine.Validate("Job No.", Job."No.");
        JobJournalLine.Validate(Type, JobJournalLine.Type::Item);
        JobJournalLine.Validate("No.", Item."No.");
        JobJournalLine.Validate("Unit of Measure Code", NonBaseUOM.Code);

        // [WHEN] Quantity is set to a value that rounds the base quantity to 0
        JobJournalLine.Validate(Quantity, QtyToSet);

        // [THEN] Quantity (Base) is rounded with the specified rounding precision
        Assert.AreEqual(Round(NonBaseQtyPerUOM * QtyToSet, QtyRoundingPrecision), JobJournalLine."Quantity (Base)", 'Base quantity is not rounded correctly.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BaseQtyIsRoundedWithRoundingPrecisionUnspecifiedOnJobJournalLine()
    var
        JobJournalLine: Record "Job Journal Line";
        Job: Record Job;
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        NonBaseQtyPerUOM: Decimal;
        QtyToSet: Decimal;
    begin
        // [FEATURE] [Job Journal Line - Rounding Precision]
        // [SCENARIO] Quantity (Base) is rounded with the default rounding precision when rounding precision is not specified.
        Initialize();

        // [GIVEN] An item with 2 unit of measures and qty. rounding precision on the base item unit of measure set.
        NonBaseQtyPerUOM := LibraryRandom.RandIntInRange(2, 10);
        QtyToSet := LibraryRandom.RandDecInRange(1, 10, 7);

        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateUnitOfMeasureCode(BaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", BaseUOM.Code, 1);
        Item.Validate("Base Unit of Measure", ItemUOM.Code);
        Item.Modify();
        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", NonBaseUOM.Code, NonBaseQtyPerUOM);

        // [GIVEN] A Job Journal Line where the unit of measure code is set to the non-base unit of measure.
        LibraryJob.CreateJob(Job);
        JobJournalLine.Init();
        JobJournalLine.Validate("Job No.", Job."No.");
        JobJournalLine.Validate(Type, JobJournalLine.Type::Item);
        JobJournalLine.Validate("No.", Item."No.");
        JobJournalLine.Validate("Unit of Measure Code", NonBaseUOM.Code);

        // [WHEN] Quantity is set to a value that rounds the base quantity to 0
        JobJournalLine.Validate(Quantity, QtyToSet);

        // [THEN] Quantity is rounded with the default rounding precision
        Assert.AreEqual(Round(QtyToSet, 0.00001), JobJournalLine.Quantity, 'Qty. is not rounded correctly.');

        // [THEN] Quantity (Base) is rounded with the default rounding precision
        Assert.AreEqual(Round(NonBaseQtyPerUOM * JobJournalLine.Quantity, 0.00001),
                        JobJournalLine."Quantity (Base)", 'Base qty. is not rounded correctly.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BaseQtyIsRoundedWithRoundingPrecisionOnJobJournalLine()
    var
        JobJournalLine: Record "Job Journal Line";
        Job: Record Job;
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        NonBaseQtyPerUOM: Decimal;
        QtyRoundingPrecision: Decimal;
    begin
        // [FEATURE] [Job Journal Line - Rounding Precision]
        // [SCENARIO] Quantity (Base) is rounded with the specified rounding precision.
        Initialize();

        // [GIVEN] An item with 2 unit of measures and qty. rounding precision on the base item unit of measure set.
        QtyRoundingPrecision := Round(1 / LibraryRandom.RandIntInRange(2, 10), 0.00001);
        NonBaseQtyPerUOM := Round(LibraryRandom.RandIntInRange(5, 10), QtyRoundingPrecision);

        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateUnitOfMeasureCode(BaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", BaseUOM.Code, 1);
        ItemUOM."Qty. Rounding Precision" := QtyRoundingPrecision;
        ItemUOM.Modify();
        Item.Validate("Base Unit of Measure", ItemUOM.Code);
        Item.Modify();
        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", NonBaseUOM.Code, NonBaseQtyPerUOM);

        // [GIVEN] A Job Journal Line where the unit of measure code is set to the non-base unit of measure.
        LibraryJob.CreateJob(Job);
        JobJournalLine.Init();
        JobJournalLine.Validate("Job No.", Job."No.");
        JobJournalLine.Validate(Type, JobJournalLine.Type::Item);
        JobJournalLine.Validate("No.", Item."No.");
        JobJournalLine.Validate("Unit of Measure Code", NonBaseUOM.Code);

        // [WHEN] Quantity is set to a value that rounds the base quantity to 0
        JobJournalLine.Validate(Quantity, (NonBaseQtyPerUOM - 1) / NonBaseQtyPerUOM);

        // [THEN] Quantity (Base) is rounded with the specified rounding precision
        Assert.AreEqual(Round(NonBaseQtyPerUOM - 1, QtyRoundingPrecision),
                        JobJournalLine."Quantity (Base)", 'Base quantity is not rounded correctly.');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure RenumberDocNoOneLine()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobJournalLine: Record "Job Journal Line";
        OldDocNo: Code[20];
    begin
        // [FEATURE] [Job Journal] [Renumber documents]
        // [SCENARIO 257226] Generate one line in the Job Journal and renumber the document number.
        Initialize();

        // [GIVEN] Create random Jobs and Job Tasks
        CreateJobWithApplyUsageLink(Job);
        LibraryJob.CreateJobTask(Job, JobTask);

        // [GIVEN] Create one Job Journal line with the created Job Task
        JobJournalLine.DeleteAll();
        LibraryJob.CreateJobJournalLine(JobJournalLine."Line Type"::Budget, JobTask, JobJournalLine);

        OldDocNo := JobJournalLine."Document No.";
        SetNewDocNo(JobJournalLine);

        // [WHEN] Enable the functionality renumber document no. on Job journal
        Commit();
        JobJournalLine.RenumberDocumentNo();

        // [THEN] The lines must have the first value from the No. Series
        VerifyJobJnlLineDocNo(JobJournalLine."Journal Template Name", JobJournalLine."Journal Batch Name",
          JobJournalLine."Line No.", OldDocNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure RenumberDocNoMultipleLines()
    var
        Job, Job2 : Record Job;
        JobTask, JobTask2 : Record "Job Task";
        JobJournalLine, JobJournalLine2 : Record "Job Journal Line";
        NoSeries: Codeunit "No. Series";
        NoSeriesCode: Code[20];
        NewDocNo: Code[20];
        JobJnlBatch: Record "Job Journal Batch";
    begin
        // [FEATURE] [Job Journal] [Renumber documents]
        // [SCENARIO 257227] Generate multiple lines in the Job Journal and renumber the "Document No.".
        Initialize();

        // [GIVEN] Create two random Jobs and Job Tasks
        CreateJobWithApplyUsageLink(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        CreateJobWithApplyUsageLink(Job2);
        LibraryJob.CreateJobTask(Job2, JobTask2);

        // [GIVEN] Create multiple Job Journal lines with the created Jobs and a random "Document No."
        JobJournalLine.DeleteAll();
        LibraryJob.CreateJobJournalLine(JobJournalLine2."Line Type"::Budget, JobTask, JobJournalLine2);
        LibraryJob.CreateJobJournalLine(JobJournalLine."Line Type"::Budget, JobTask2, JobJournalLine);
        LibraryJob.CreateJobJournalLine(JobJournalLine."Line Type"::Budget, JobTask2, JobJournalLine);

        // [WHEN] Enable the functionality renumber "Document No." on Job journal
        Commit();
        JobJournalLine.RenumberDocumentNo();

        // [THEN] All the lines must have the same "Document No."
        if JobJnlBatch.Get(JobJournalLine."Journal Template Name", JobJournalLine."Journal Batch Name") then
            NoSeriesCode := JobJnlBatch."No. Series";

        NewDocNo := NoSeries.PeekNextNo(NoSeriesCode);
        VerifyJobJnlLineDocNo(JobJournalLine."Journal Template Name", JobJournalLine."Journal Batch Name",
          1, NewDocNo);
        VerifyJobJnlLineDocNo(JobJournalLine."Journal Template Name", JobJournalLine."Journal Batch Name",
          2, NewDocNo);
        VerifyJobJnlLineDocNo(JobJournalLine."Journal Template Name", JobJournalLine2."Journal Batch Name",
          1, NewDocNo);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"UT T Job Journal Line");
        LibrarySetupStorage.Restore();
        LibraryRandom.Init();
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"UT T Job Journal Line");

        LibraryERMCountryData.UpdateGeneralPostingSetup();

        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"UT T Job Journal Line");
        LibrarySetupStorage.SavePurchasesSetup();
    end;

    local procedure SetUp(var JobTask: Record "Job Task"; var JobPlanningLine: Record "Job Planning Line"; var JobJournalLine: Record "Job Journal Line")
    var
        Job: Record Job;
    begin
        CreateJobWithApplyUsageLink(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::Budget, JobPlanningLine.Type::Item, JobTask, JobPlanningLine);
        JobPlanningLine.Validate(Quantity, LibraryRandom.RandInt(1000));
        JobPlanningLine.Modify();
        LibraryJob.CreateJobJournalLine(JobJournalLine."Line Type"::Budget, JobTask, JobJournalLine);
        JobJournalLine.Validate(Type, JobPlanningLine.Type);
        JobJournalLine.Validate("No.", JobPlanningLine."No.");
        JobJournalLine.Modify();
    end;

    local procedure TearDown(var JobTask: Record "Job Task"; var JobPlanningLine: Record "Job Planning Line"; var JobJournalLine: Record "Job Journal Line")
    var
        Job: Record Job;
    begin
        JobJournalLine.SetRange("Job No.", Job."No.");
        JobJournalLine.DeleteAll(true);
        JobJournalLine.Reset();

        JobPlanningLine.SetRange("Job No.", Job."No.");
        JobPlanningLine.DeleteAll(true);
        JobPlanningLine.Reset();

        JobTask.SetRange("Job No.", Job."No.");
        JobTask.DeleteAll(true);
        JobTask.Reset();

        Job.SetRange("No.", JobTask."Job No.");
        Job.DeleteAll(true);
        Job.Reset();
    end;

    local procedure CreateJobWithApplyUsageLink(var Job: Record Job)
    begin
        LibraryJob.CreateJob(Job);
        Job.Validate("Apply Usage Link", true);
        Job.Modify();
    end;

    local procedure CreateJobLedgEntry(var JobLedgEntry: Record "Job Ledger Entry"; JobTask: Record "Job Task")
    begin
        JobLedgEntry.Init();
        JobLedgEntry."Job No." := JobTask."Job No.";
        JobLedgEntry."Job Task No." := JobTask."Job Task No.";
        JobLedgEntry.Type := JobLedgEntry.Type::Item;
        JobLedgEntry."No." := LibraryJob.FindConsumable(JobLedgEntry.Type);
        JobLedgEntry."Quantity (Base)" := LibraryRandom.RandDecInRange(1, 100, 2);
        JobLedgEntry."Qty. per Unit of Measure" := 1;
        JobLedgEntry.Insert();
    end;

    local procedure MockPurchLineWithJobAmounts(var PurchLine: Record "Purchase Line"; JobTask: Record "Job Task")
    var
        PurchHeader: Record "Purchase Header";
    begin
        LibraryPurchase.SetDefaultPostingDateNoDate();

        PurchHeader.Init();
        PurchHeader."Document Type" := PurchHeader."Document Type"::Invoice;
        PurchHeader.Insert(true);

        PurchLine.Init();
        PurchLine."Document Type" := PurchHeader."Document Type";
        PurchLine."Document No." := PurchHeader."No.";
        PurchLine."Line No." := LibraryUtility.GetNewRecNo(PurchLine, PurchLine.FieldNo("Line No."));
        PurchLine.Type := PurchLine.Type::Item;
        PurchLine."No." := LibraryInventory.CreateItemNo();
        PurchLine."Job No." := JobTask."Job No.";
        PurchLine."Job Task No." := JobTask."Job Task No.";
        PurchLine.Quantity := LibraryRandom.RandDecInRange(1, 200, 2);
        PurchLine."Job Unit Price" := LibraryRandom.RandDec(200, 2);
        PurchLine."Job Total Price" := LibraryRandom.RandDec(200, 2);
        PurchLine."Job Line Amount (LCY)" := LibraryRandom.RandDec(200, 2);
        PurchLine."Job Line Discount %" := LibraryRandom.RandInt(100);
        PurchLine."Job Line Disc. Amount (LCY)" := LibraryRandom.RandDec(200, 2);
        PurchLine.Insert();
    end;

    local procedure VerifyJobJnlLineDocNo(TemplateName: Code[20]; BatchName: Code[20]; LineNo: Integer; DocNo: Code[20])
    var
        JobJournalLine: Record "Job Journal Line";
    begin
        JobJournalLine.Get(TemplateName, BatchName, LineNo);
        JobJournalLine.TestField("Document No.", DocNo)
    end;

    local procedure SetNewDocNo(var JobJournalLine: Record "Job Journal Line"): Code[20]
    var
        i: Integer;
    begin
        for i := 1 to LibraryRandom.RandIntInRange(2, 10) do
            JobJournalLine."Document No." := IncStr(JobJournalLine."Document No.");
        JobJournalLine.Modify();
        exit(JobJournalLine."Document No.")
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

