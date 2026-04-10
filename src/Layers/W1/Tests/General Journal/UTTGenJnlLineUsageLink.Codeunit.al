codeunit 136359 "UT T Gen Jnl Line Usage Link"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [General Journal] [Job]
        IsInitialized := false;
    end;

    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        Text001: Label 'Rolling back changes.';
        JobCurrencyFactorErr: Label 'Job Currency Factor should be: %1.', Comment = '%1 -Expected Job Currency Factor';
        TotalCostLCYErr: Label 'Total Cost (LCY) should be: %1.', Comment = '%1 -Expected Total Cost (LCY)';
        IsInitialized: Boolean;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"UT T Gen Jnl Line Usage Link");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"UT T Gen Jnl Line Usage Link");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"UT T Gen Jnl Line Usage Link");
    end;

    [Normal]
    local procedure SetUp()
    var
        LibraryJob: Codeunit "Library - Job";
    begin
        LibraryJob.CreateJob(Job);
        Job.Validate("Apply Usage Link", true);
        Job.Modify();
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryJob.CreateJobPlanningLine(
          JobPlanningLine."Line Type"::Budget, JobPlanningLine.Type::"G/L Account", JobTask, JobPlanningLine);
        JobPlanningLine.Validate(Quantity, 1);
        JobPlanningLine.Modify();

        GenJournalTemplate.Init();
        GenJournalTemplate.Validate(Name, 'TEST');
        GenJournalTemplate.Insert();

        GenJournalBatch.Init();
        GenJournalBatch.Validate("Journal Template Name", GenJournalTemplate.Name);
        GenJournalBatch.Validate(Name, 'TEST');
        GenJournalBatch.Insert();

        GenJournalLine.Init();
        GenJournalLine.Validate("Journal Template Name", GenJournalTemplate.Name);
        GenJournalLine.Validate("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.Validate("Posting Date", WorkDate());
        GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::"G/L Account");
        GenJournalLine.Validate("Account No.", JobPlanningLine."No.");
        GenJournalLine.Validate("Job No.", Job."No.");
        GenJournalLine.Validate("Job Task No.", JobTask."Job Task No.");
        GenJournalLine.Validate("Job Line Type", GenJournalLine."Job Line Type"::Budget);
        GenJournalLine.Insert(true);
    end;

    [Normal]
    local procedure TearDown()
    begin
        Clear(Job);
        Clear(JobTask);
        Clear(JobPlanningLine);
        Clear(GenJournalLine);
        Clear(GenJournalBatch);
        Clear(GenJournalTemplate);

        asserterror Error(Text001);
        IsInitialized := false;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInitialization()
    begin
        Initialize();
        SetUp();

        // Verify that "Job Planning Line No." is initialized correctly.
        Assert.AreEqual(0, GenJournalLine."Job Planning Line No.", 'Job Planning Line No. is not 0 by default.');

        // Verify that "Remaining Qty." is initialized correctly.
        Assert.AreEqual(0, GenJournalLine."Job Remaining Qty.", 'Remaining Qty. is not 0 by default.');

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFieldLineType()
    begin
        Initialize();
        SetUp();

        // Verify that "Line Type" is set to the correct value when a "Job Planning Line No." is set.
        GenJournalLine.Validate("Job Line Type", 0);
        GenJournalLine.Validate("Job Planning Line No.", JobPlanningLine."Line No.");
        Assert.AreEqual(JobPlanningLine."Line Type".AsInteger(), GenJournalLine."Job Line Type".AsInteger() - 1,
          'Line type is not set correctly when Job Planning Line No. is defined.');

        // Verify that "Line Type" can't be changed if a "Job Planning Line No." is defined.
        asserterror GenJournalLine.Validate("Job Line Type", 0);

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFieldJobPlanningLineNo()
    begin
        Initialize();
        SetUp();

        // Verify that "Job Planning Line No." and "Remaining Qty." are blanked when the No. changes.
        GenJournalLine.Validate("Job Planning Line No.", JobPlanningLine."Line No.");
        GenJournalLine.TestField("Job Planning Line No.");
        GenJournalLine.Validate("Account No.", '');
        Assert.AreEqual(0, GenJournalLine."Job Planning Line No.", 'Job Planning Line No. is not 0 when No. changes.');
        Assert.AreEqual(0, GenJournalLine."Job Remaining Qty.", 'Remaining Qty. is not 0 when No. changes.');

        TearDown();

        Initialize();
        SetUp();

        // Verify that "Job Planning Line No." is blanked when the Job No. changes.
        GenJournalLine.Validate("Job Planning Line No.", JobPlanningLine."Line No.");
        GenJournalLine.TestField("Job Planning Line No.");
        GenJournalLine.Validate("Job No.", '');
        Assert.AreEqual(0, GenJournalLine."Job Planning Line No.", 'Job Planning Line No. is not 0 when Job No. changes.');

        // Remaining test for this field are found in test function TestFieldRemainingQty.

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFieldRemainingQty()
    var
        QtyDelta: Decimal;
        OldRemainingQty: Decimal;
    begin
        Initialize();
        SetUp();

        // Verify that "Remaining Qty." can't be set if "Job Planning Line No." isn't set.
        asserterror GenJournalLine.Validate("Job Remaining Qty.", LibraryRandom.RandInt(Round(GenJournalLine."Job Quantity", 1)));

        TearDown();

        Initialize();
        SetUp();

        // Verify that "Remaining Qty." is set correctly when a "Job Planning Line No." is defined.
        GenJournalLine.TestField("Job Planning Line No.", 0);
        GenJournalLine.TestField("Job Remaining Qty.", 0);
        GenJournalLine.TestField("Job Quantity", 0);
        GenJournalLine.Validate("Job Planning Line No.", JobPlanningLine."Line No.");
        Assert.AreEqual(JobPlanningLine."Remaining Qty.", GenJournalLine."Job Remaining Qty.", 'Remaining Qty. is not set correctly');

        // Verify that "Remaining Qty." changes correctly when Job Quantity is changed.
        OldRemainingQty := GenJournalLine."Job Remaining Qty.";
        QtyDelta := LibraryRandom.RandInt(Round(GenJournalLine."Job Remaining Qty.", 1));
        GenJournalLine.Validate("Job Quantity", GenJournalLine."Job Quantity" + QtyDelta);
        Assert.AreEqual(OldRemainingQty - QtyDelta, GenJournalLine."Job Remaining Qty.",
          'Remaining Qty. is not updated correctly');

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFieldJobCurrencyCode()
    var
        CurrExchRate: Record "Currency Exchange Rate";
        CurrencyCode: Code[10];
        ExchRate: Decimal;
    begin
        // [SCENARIO 434995] To check if Job Currency Factor gets updated every time when Job Currency Code is updated on Journal Line, also to ensure that if Job Currency Code is set to blank from a non blank value then Job currency factor is also 0.
        // [GIVEN] A Gen. Journal Line with a Job No., Task No., Job Line Type as billable and also with Job Currency Code.
        Initialize();
        SetUp();

        GenJournalLine.Validate("Job Line Type", GenJournalLine."Job Line Type"::Billable);
        GenJournalLine.Validate(Amount, LibraryRandom.RandDecInRange(1, 1000, 2));

        // [GIVEN] Clear Gen. Posting Type, Gen. Bus. Posting Group , Gen. Prod. Posting group, VAT Bus. Posting Group, VAT Prod. Posting Group
        GenJournalLine.Validate("Gen. Posting Type", GenJournalLine."Gen. Posting Type"::" ");
        GenJournalLine.Validate("Gen. Bus. Posting Group", '');
        GenJournalLine.Validate("Gen. Prod. Posting Group", '');
        GenJournalLine.Validate("VAT Bus. Posting Group", '');
        GenJournalLine.Validate("VAT Prod. Posting Group", '');

        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDecInRange(10, 20, 2), LibraryRandom.RandDecInRange(10, 20, 2));
        LibraryERM.FindExchRate(CurrExchRate, CurrencyCode, WorkDate());
        ExchRate := CurrExchRate."Exchange Rate Amount";

        // [WHEN] When the Job currency code is updated on Gen. Journal Line
        GenJournalLine.Validate("Job Currency Code", CurrencyCode);

        // [THEN] Job Currency factor should be equal to the exchange rate Amount
        Assert.AreEqual(ExchRate, GenJournalLine."Job Currency Factor", StrSubstNo(JobCurrencyFactorErr, ExchRate));

        // [WHEN] When the Job currency code is set to blank
        GenJournalLine.Validate("Job Currency Code", '');

        // [THEN] Job Currency factor should be 0
        Assert.AreEqual(0, GenJournalLine."Job Currency Factor", StrSubstNo(JobCurrencyFactorErr, 0));

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTotalCostLCYOnJobLedgEntry()
    var
        CurrExchRate: Record "Currency Exchange Rate";
        JobLedgEntry: Record "Job Ledger Entry";
        SourceCodeSetup: Record "Source Code Setup";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        ExchRate: Decimal;
        ExpectedAmount: Decimal;
        CurrencyCode: Code[10];
        DocumentNo: Code[20];
    begin
        // [SCENARIO 434995] Validate if Job ledger Entry is updated with correct Total Cost LCY if Job Currency Code on Journal Line is update to blank after a non blank Value
        // [GIVEN] A Gen. Journal Line with a Job No., Task No., Job Line Type as billable and also with Job Currency Code and a job currency Factor
        Initialize();
        SetUp();
        SourceCodeSetup.Get();

        GenJournalLine.Validate("Source Code", SourceCodeSetup."General Journal");
        DocumentNo := LibraryRandom.RandText(20);
        GenJournalLine.Validate("Document No.", DocumentNo);

        // [GIVEN] Clear Gen. Posting Type, Gen. Bus. Posting Group , Gen. Prod. Posting group, VAT Bus. Posting Group, VAT Prod. Posting Group
        GenJournalLine.Validate("Gen. Posting Type", GenJournalLine."Gen. Posting Type"::" ");
        GenJournalLine.Validate("Gen. Bus. Posting Group", '');
        GenJournalLine.Validate("Gen. Prod. Posting Group", '');
        GenJournalLine.Validate("VAT Bus. Posting Group", '');
        GenJournalLine.Validate("VAT Prod. Posting Group", '');

        GenJournalLine.Validate("Job Line Type", GenJournalLine."Job Line Type"::Billable);
        GenJournalLine.Validate("Job Quantity", 1);
        GenJournalLine.Validate(Amount, LibraryRandom.RandDecInRange(1, 1000, 2));
        ExpectedAmount := GenJournalLine."Job Total Cost (LCY)";

        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDecInRange(10, 20, 2), LibraryRandom.RandDecInRange(10, 20, 2));
        LibraryERM.FindExchRate(CurrExchRate, CurrencyCode, WorkDate());
        ExchRate := CurrExchRate."Exchange Rate Amount";
        GenJournalLine.Validate("Job Currency Code", CurrencyCode);

        // [WHEN] When the Job currency code is set to blank and Journal Line is Posted
        GenJournalLine.Validate("Job Currency Code", '');
        GenJnlPostLine.RunWithCheck(GenJournalLine);

        // [THEN] Total Cost (LCY) on Job Ledger Entry should be same as Amount of Journal Line
        JobLedgEntry.FindLast();
        Assert.AreEqual(ExpectedAmount, JobLedgEntry."Total Cost (LCY)", StrSubstNo(TotalCostLCYErr, ExpectedAmount));

        TearDown();
    end;
}

