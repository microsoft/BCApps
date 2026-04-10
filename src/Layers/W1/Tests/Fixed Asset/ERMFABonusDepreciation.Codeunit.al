codeunit 134454 "ERM FA Bonus Depreciation"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Fixed Asset] [Bonus Depreciation]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        isInitialized: Boolean;
        BonusDepreciationTurnedOnErr: Label 'You must uncheck Use Bonus Depreciation, because this change is making the fixed asset not eligible for bonus depreciation.';
        BonusDepreciationNotSetupCorrectlyErr: Label 'Bonus depreciation is not set up correctly in the Fixed Asset Setup.';
        CannotUseBonusDepreciationDepreciationStartedErr: Label 'Bonus depreciation cannot be used because depreciation has already started for this fixed asset.';
        CannotTurnOffBonusDepreciationAlreadyAppliedErr: Label 'Bonus depreciation has already been applied to this fixed asset.';
        BonusDepreciationExceedsAllowedValueErr: Label 'The amount of bonus depreciation must not exceed the allowed value calculated based on acquisition cost and bonus depreciation percentage set up in Fixed Asset Setup.';
        DepreciationAlreadyAppliedErr: Label 'Depreciation ledger entries have already been posted for fixed asset %1 in depreciation book %2. You must first reverse them in order to post bonus depreciation.', Comment = '%1 - fixed asset code; %2 - depreciation book code';

    [Test]
    [Scope('OnPrem')]
    procedure FASetupBonusDepreciationCorrectlySetup()
    var
        FASetup: Record "FA Setup";
        BonusDeprPct: Decimal;
        BonusDeprEffectiveDate: Date;
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO 620699] BonusDepreciationCorrectlySetup returns true when both percentage and effective date are set
        Initialize();

        // [GIVEN] FA Setup with "Bonus Depreciation %" and "Bonus Depr. Effective Date" configured
        BonusDeprPct := LibraryRandom.RandIntInRange(10, 50);
        BonusDeprEffectiveDate := WorkDate();
        SetupBonusDepreciation(BonusDeprPct, BonusDeprEffectiveDate);

        // [WHEN] BonusDepreciationCorrectlySetup is called
        FASetup.Get();

        // [THEN] The result is true
        Assert.IsTrue(FASetup.BonusDepreciationCorrectlySetup(), 'BonusDepreciationCorrectlySetup should return true when both fields are set.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FASetupBonusDepreciationNotSetupWhenPercentZero()
    var
        FASetup: Record "FA Setup";
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO 620699] BonusDepreciationCorrectlySetup returns false when percentage is zero
        Initialize();

        // [GIVEN] FA Setup with "Bonus Depreciation %" = 0 and a valid "Bonus Depr. Effective Date"
        SetupBonusDepreciation(0, WorkDate());

        // [WHEN] BonusDepreciationCorrectlySetup is called
        FASetup.Get();

        // [THEN] The result is false
        Assert.IsFalse(FASetup.BonusDepreciationCorrectlySetup(), 'BonusDepreciationCorrectlySetup should return false when percentage is zero.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FASetupBonusDepreciationNotSetupWhenDateEmpty()
    var
        FASetup: Record "FA Setup";
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO 620699] BonusDepreciationCorrectlySetup returns false when effective date is empty
        Initialize();

        // [GIVEN] FA Setup with a valid "Bonus Depreciation %" but "Bonus Depr. Effective Date" = 0D
        SetupBonusDepreciation(LibraryRandom.RandIntInRange(10, 50), 0D);

        // [WHEN] BonusDepreciationCorrectlySetup is called
        FASetup.Get();

        // [THEN] The result is false
        Assert.IsFalse(FASetup.BonusDepreciationCorrectlySetup(), 'BonusDepreciationCorrectlySetup should return false when effective date is empty.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FADeprBookEligibleForBonusDepreciation()
    var
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        FASetup: Record "FA Setup";
        BonusDeprEffectiveDate: Date;
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO 620699] EligibleForBonusDepreciation returns true when depreciation starting date >= effective date
        Initialize();

        // [GIVEN] FA Setup with bonus depreciation correctly configured
        BonusDeprEffectiveDate := WorkDate();
        SetupBonusDepreciation(LibraryRandom.RandIntInRange(10, 50), BonusDeprEffectiveDate);

        // [GIVEN] Fixed asset "FA" with depreciation starting date >= effective date
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateJournalSetupDepreciation(DepreciationBook);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", DepreciationBook.Code);

        // [WHEN] EligibleForBonusDepreciation is called
        FADepreciationBook.Get(FixedAsset."No.", DepreciationBook.Code);
        FASetup.Get();

        // [THEN] The result is true
        Assert.IsTrue(FADepreciationBook.EligibleForBonusDepreciation(FASetup), 'Fixed asset should be eligible for bonus depreciation.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FADeprBookNotEligibleWhenStartingDateBeforeEffective()
    var
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        FASetup: Record "FA Setup";
        BonusDeprEffectiveDate: Date;
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO 620699] EligibleForBonusDepreciation returns false when depreciation starting date < effective date
        Initialize();

        // [GIVEN] FA Setup with bonus depreciation effective date in the future
        BonusDeprEffectiveDate := CalcDate('<+1Y>', WorkDate());
        SetupBonusDepreciation(LibraryRandom.RandIntInRange(10, 50), BonusDeprEffectiveDate);

        // [GIVEN] Fixed asset "FA" with depreciation starting date < effective date
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateJournalSetupDepreciation(DepreciationBook);
        CreateFADepreciationBookWithStartDate(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", DepreciationBook.Code, WorkDate());

        // [WHEN] EligibleForBonusDepreciation is called
        FADepreciationBook.Get(FixedAsset."No.", DepreciationBook.Code);
        FASetup.Get();

        // [THEN] The result is false
        Assert.IsFalse(FADepreciationBook.EligibleForBonusDepreciation(FASetup), 'Fixed asset should not be eligible for bonus depreciation when starting date < effective date.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FADeprBookBonusDepreciationAmount()
    var
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        FAJournalLine: Record "FA Journal Line";
        FALedgerEntry: Record "FA Ledger Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
        AcquisitionAmount: Decimal;
        BonusDeprPct: Decimal;
        ExpectedBonusDeprAmount: Decimal;
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO 620699] Bonus depreciation amount is calculated as Acquisition Cost * Bonus Depreciation % / 100 rounded
        Initialize();

        // [GIVEN] FA Setup with bonus depreciation percentage "P" and effective date
        BonusDeprPct := LibraryRandom.RandIntInRange(10, 50);
        SetupBonusDepreciation(BonusDeprPct, WorkDate());

        // [GIVEN] Fixed asset "FA" with acquisition cost posted and "Use Bonus Depreciation" enabled
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateJournalSetupDepreciation(DepreciationBook);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", DepreciationBook.Code);
        FADepreciationBook.Validate("Use Bonus Depreciation", true);
        FADepreciationBook.Modify(true);
        AcquisitionAmount := CreateAndPostAcquisitionFAJournalLine(FADepreciationBook);

        // [GIVEN] Expected bonus depreciation amount calculated as Acquisition Cost * P / 100
        GeneralLedgerSetup.Get();
        ExpectedBonusDeprAmount := Round(AcquisitionAmount * BonusDeprPct * 0.01, GeneralLedgerSetup."Amount Rounding Precision");

        // [WHEN] Bonus depreciation journal line with the expected amount is posted
        CreateFAJournalLineWithPostingType(
            FAJournalLine, FixedAsset."No.", DepreciationBook.Code,
            FAJournalLine."FA Posting Type"::"Bonus Depreciation", -ExpectedBonusDeprAmount);
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        // [THEN] FA Ledger Entry is created with the correct bonus depreciation amount
        FALedgerEntry.SetRange("FA No.", FixedAsset."No.");
        FALedgerEntry.SetRange("FA Posting Type", FALedgerEntry."FA Posting Type"::"Bonus Depreciation");
        FALedgerEntry.FindFirst();
        Assert.AreEqual(-ExpectedBonusDeprAmount, FALedgerEntry.Amount, 'Bonus depreciation amount is incorrect.');
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('UseBonusDepreciationMessageHandler')]
    procedure FADeprBookToggleUseBonusOnSetStartingDate()
    var
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        BonusDeprEffectiveDate: Date;
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO 620699] Use Bonus Depreciation is toggled on when depreciation starting date >= effective date on a depreciation book with Use Bonus Depreciation
        Initialize();

        // [GIVEN] FA Setup with bonus depreciation correctly configured with effective date "D"
        BonusDeprEffectiveDate := WorkDate();
        SetupBonusDepreciation(LibraryRandom.RandIntInRange(10, 50), BonusDeprEffectiveDate);

        // [GIVEN] Depreciation book "DB" with "Use Bonus Depreciation" = true
        CreateJournalSetupDepreciation(DepreciationBook);
        DepreciationBook.Validate("Use Bonus Depreciation", true);
        DepreciationBook.Modify(true);

        // [GIVEN] Fixed asset "FA" with FA depreciation book for "DB"
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", DepreciationBook.Code);
        FADepreciationBook.Validate("FA Posting Group", FixedAsset."FA Posting Group");

        // [WHEN] Depreciation Starting Date is set to a date >= effective date "D"
        FADepreciationBook.Validate("Depreciation Starting Date", BonusDeprEffectiveDate);
        FADepreciationBook.Validate("Depreciation Ending Date", CalcDate('<+1Y>', BonusDeprEffectiveDate));
        FADepreciationBook.Modify(true);

        // [THEN] "Use Bonus Depreciation" is true on the FA Depreciation Book
        FADepreciationBook.Get(FixedAsset."No.", DepreciationBook.Code);
        Assert.IsTrue(FADepreciationBook."Use Bonus Depreciation", 'Use Bonus Depreciation should be toggled on when starting date >= effective date.');
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('UseBonusDepreciationMessageHandler')]
    procedure FADeprBookToggleUseBonusOffWhenStartingDateBeforeEffective()
    var
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        BonusDeprEffectiveDate: Date;
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO 620699] Error when changing depreciation starting date to before effective date while Use Bonus Depreciation is enabled
        Initialize();

        // [GIVEN] FA Setup with bonus depreciation effective date in the future
        BonusDeprEffectiveDate := CalcDate('<+1Y>', WorkDate());
        SetupBonusDepreciation(LibraryRandom.RandIntInRange(10, 50), BonusDeprEffectiveDate);

        // [GIVEN] Depreciation book "DB" with "Use Bonus Depreciation" = true
        CreateJournalSetupDepreciation(DepreciationBook);
        DepreciationBook.Validate("Use Bonus Depreciation", true);
        DepreciationBook.Modify(true);

        // [GIVEN] Fixed asset "FA" with FA depreciation book that has "Use Bonus Depreciation" initially set via starting date >= effective date
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", DepreciationBook.Code);
        FADepreciationBook.Validate("FA Posting Group", FixedAsset."FA Posting Group");
        FADepreciationBook.Validate("Depreciation Starting Date", BonusDeprEffectiveDate);
        FADepreciationBook.Validate("Depreciation Ending Date", CalcDate('<+1Y>', BonusDeprEffectiveDate));
        FADepreciationBook.Modify(true);

        // [WHEN] Depreciation Starting Date is changed to before effective date
        asserterror FADepreciationBook.Validate("Depreciation Starting Date", WorkDate());

        // [THEN] Error is raised about Use Bonus Depreciation must be unchecked
        Assert.ExpectedError(BonusDepreciationTurnedOnErr);
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FADeprBookCannotUseBonusDeprWhenSetupIncomplete()
    var
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        FixedAsset: Record "Fixed Asset";
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO 620699] Error when enabling Use Bonus Depreciation on FA Depreciation Book when FA Setup is not correctly configured
        Initialize();

        // [GIVEN] FA Setup with "Bonus Depreciation %" = 0 (incomplete setup)
        SetupBonusDepreciation(0, 0D);

        // [GIVEN] Fixed asset "FA" with depreciation book
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateJournalSetupDepreciation(DepreciationBook);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", DepreciationBook.Code);

        // [WHEN] "Use Bonus Depreciation" is set to true
        asserterror FADepreciationBook.Validate("Use Bonus Depreciation", true);

        // [THEN] Error is raised about bonus depreciation setup
        Assert.ExpectedError(BonusDepreciationNotSetupCorrectlyErr);
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FADeprBookCannotUseBonusDeprWhenDepreciationStarted()
    var
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        FAJournalLine: Record "FA Journal Line";
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO 620699] Error when enabling Use Bonus Depreciation after depreciation has already been posted
        Initialize();

        // [GIVEN] FA Setup with bonus depreciation correctly configured
        SetupBonusDepreciation(LibraryRandom.RandIntInRange(10, 50), WorkDate());

        // [GIVEN] Fixed asset "FA" with depreciation book and posted depreciation entries
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateJournalSetupDepreciation(DepreciationBook);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", DepreciationBook.Code);
        CreateAndPostAcquisitionFAJournalLine(FADepreciationBook);
        CreateFAJournalLineWithPostingType(
            FAJournalLine, FixedAsset."No.", DepreciationBook.Code,
            FAJournalLine."FA Posting Type"::Depreciation, -LibraryRandom.RandIntInRange(100, 500));
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        // [WHEN] "Use Bonus Depreciation" is set to true
        FADepreciationBook.Get(FixedAsset."No.", DepreciationBook.Code);
        asserterror FADepreciationBook.Validate("Use Bonus Depreciation", true);

        // [THEN] Error is raised about depreciation already started
        Assert.ExpectedError(CannotUseBonusDepreciationDepreciationStartedErr);
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FADeprBookCannotTurnOffBonusDeprWhenAlreadyApplied()
    var
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        FAJournalLine: Record "FA Journal Line";
        AcquisitionAmount: Decimal;
        BonusDeprPct: Decimal;
        BonusDeprAmount: Decimal;
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO 620699] Error when disabling Use Bonus Depreciation after bonus depreciation ledger entries exist
        Initialize();

        // [GIVEN] FA Setup with bonus depreciation correctly configured
        BonusDeprPct := LibraryRandom.RandIntInRange(10, 50);
        SetupBonusDepreciation(BonusDeprPct, WorkDate());

        // [GIVEN] Fixed asset "FA" with "Use Bonus Depreciation" = true and posted bonus depreciation entries
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateJournalSetupDepreciation(DepreciationBook);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", DepreciationBook.Code);
        FADepreciationBook.Validate("Use Bonus Depreciation", true);
        FADepreciationBook.Modify(true);
        AcquisitionAmount := CreateAndPostAcquisitionFAJournalLine(FADepreciationBook);
        BonusDeprAmount := Round(AcquisitionAmount * BonusDeprPct * 0.01);
        CreateFAJournalLineWithPostingType(
            FAJournalLine, FixedAsset."No.", DepreciationBook.Code,
            FAJournalLine."FA Posting Type"::"Bonus Depreciation", -BonusDeprAmount);
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        // [WHEN] "Use Bonus Depreciation" is set to false
        FADepreciationBook.Get(FixedAsset."No.", DepreciationBook.Code);
        asserterror FADepreciationBook.Validate("Use Bonus Depreciation", false);

        // [THEN] Error is raised about bonus depreciation already applied
        Assert.ExpectedError(CannotTurnOffBonusDepreciationAlreadyAppliedErr);
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BonusDeprJournalLineExceedsAllowedAmount()
    var
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        FAJournalLine: Record "FA Journal Line";
        AcquisitionAmount: Decimal;
        BonusDeprPct: Decimal;
        ExcessiveAmount: Decimal;
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO 620699] Error when bonus depreciation journal line amount exceeds the calculated allowed amount
        Initialize();

        // [GIVEN] FA Setup with bonus depreciation percentage "P"
        BonusDeprPct := LibraryRandom.RandIntInRange(10, 50);
        SetupBonusDepreciation(BonusDeprPct, WorkDate());

        // [GIVEN] Fixed asset "FA" with posted acquisition cost
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateJournalSetupDepreciation(DepreciationBook);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", DepreciationBook.Code);
        FADepreciationBook.Validate("Use Bonus Depreciation", true);
        FADepreciationBook.Modify(true);
        AcquisitionAmount := CreateAndPostAcquisitionFAJournalLine(FADepreciationBook);

        // [GIVEN] FA Journal line with bonus depreciation amount exceeding the allowed value
        ExcessiveAmount := Round(AcquisitionAmount * BonusDeprPct * 0.01) + LibraryRandom.RandIntInRange(100, 500);
        CreateFAJournalLineWithPostingType(
            FAJournalLine, FixedAsset."No.", DepreciationBook.Code,
            FAJournalLine."FA Posting Type"::"Bonus Depreciation", -ExcessiveAmount);

        // [WHEN] The journal line is posted
        asserterror LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        // [THEN] Error is raised about bonus depreciation exceeding the allowed value
        Assert.ExpectedError(BonusDepreciationExceedsAllowedValueErr);
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BonusDeprCheckMultipleLinesPerFADeprBook()
    var
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        FAJournalLine: Record "FA Journal Line";
        FAJournalBatch: Record "FA Journal Batch";
        AcquisitionAmount: Decimal;
        BonusDeprPct: Decimal;
        BonusDeprAmount: Decimal;
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO 620699] Error when a journal batch contains multiple bonus depreciation lines for the same FA Depreciation Book
        Initialize();

        // [GIVEN] FA Setup with bonus depreciation percentage "P"
        BonusDeprPct := LibraryRandom.RandIntInRange(10, 50);
        SetupBonusDepreciation(BonusDeprPct, WorkDate());

        // [GIVEN] Fixed asset "FA" with posted acquisition cost and "Use Bonus Depreciation" enabled
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateJournalSetupDepreciation(DepreciationBook);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", DepreciationBook.Code);
        FADepreciationBook.Validate("Use Bonus Depreciation", true);
        FADepreciationBook.Modify(true);
        AcquisitionAmount := CreateAndPostAcquisitionFAJournalLine(FADepreciationBook);
        BonusDeprAmount := Round(AcquisitionAmount * BonusDeprPct * 0.01);

        // [GIVEN] Two bonus depreciation lines for the same FA Depreciation Book in a batch
        CreateFAJournalBatch(FAJournalBatch);
        CreateFAJnlLineInBatch(
            FAJournalLine, FAJournalBatch, FixedAsset."No.", DepreciationBook.Code,
            FAJournalLine."FA Posting Type"::"Bonus Depreciation", -BonusDeprAmount / 2);
        CreateFAJnlLineInBatch(
            FAJournalLine, FAJournalBatch, FixedAsset."No.", DepreciationBook.Code,
            FAJournalLine."FA Posting Type"::"Bonus Depreciation", -BonusDeprAmount / 2);

        // [WHEN] The journal batch is posted
        FAJournalLine.SetRange("Journal Template Name", FAJournalBatch."Journal Template Name");
        FAJournalLine.SetRange("Journal Batch Name", FAJournalBatch.Name);
        FAJournalLine.FindFirst();
        asserterror LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        // [THEN] Error is raised about depreciation already applied
        Assert.ExpectedError(StrSubstNo(DepreciationAlreadyAppliedErr, FixedAsset."No.", DepreciationBook.Code));
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BonusDeprCheckAlreadyAppliedInBatch()
    var
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        FAJournalLine: Record "FA Journal Line";
        FAJournalLine2: Record "FA Journal Line";
        FAJournalBatch: Record "FA Journal Batch";
        AcquisitionAmount: Decimal;
        BonusDeprPct: Decimal;
        BonusDeprAmount: Decimal;
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO 620699] Error when posting bonus depreciation for an FA that already has a posted bonus depreciation entry
        Initialize();

        // [GIVEN] FA Setup with bonus depreciation percentage "P"
        BonusDeprPct := LibraryRandom.RandIntInRange(10, 50);
        SetupBonusDepreciation(BonusDeprPct, WorkDate());

        // [GIVEN] Fixed asset "FA" with posted acquisition cost and a previously posted bonus depreciation entry
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateJournalSetupDepreciation(DepreciationBook);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", DepreciationBook.Code);
        FADepreciationBook.Validate("Use Bonus Depreciation", true);
        FADepreciationBook.Modify(true);
        AcquisitionAmount := CreateAndPostAcquisitionFAJournalLine(FADepreciationBook);
        BonusDeprAmount := Round(AcquisitionAmount * BonusDeprPct * 0.01);
        CreateFAJournalLineWithPostingType(
            FAJournalLine2, FixedAsset."No.", DepreciationBook.Code,
            FAJournalLine2."FA Posting Type"::"Bonus Depreciation", -BonusDeprAmount);
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine2);

        // [GIVEN] A new bonus depreciation journal line for the same FA Depreciation Book
        CreateFAJournalBatch(FAJournalBatch);
        CreateFAJnlLineInBatch(
            FAJournalLine, FAJournalBatch, FixedAsset."No.", DepreciationBook.Code,
            FAJournalLine."FA Posting Type"::"Bonus Depreciation", -BonusDeprAmount);

        // [WHEN] The journal batch is posted
        asserterror LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        // [THEN] Error is raised about depreciation already applied
        Assert.ExpectedError(StrSubstNo(DepreciationAlreadyAppliedErr, FixedAsset."No.", DepreciationBook.Code));
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostBonusDepreciationFromFAJournal()
    var
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        FAJournalLine: Record "FA Journal Line";
        FALedgerEntry: Record "FA Ledger Entry";
        AcquisitionAmount: Decimal;
        BonusDeprPct: Decimal;
        BonusDeprAmount: Decimal;
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO 620699] Post a bonus depreciation line from FA Journal and verify FA Ledger Entry
        Initialize();

        // [GIVEN] FA Setup with bonus depreciation percentage "P"
        BonusDeprPct := LibraryRandom.RandIntInRange(10, 50);
        SetupBonusDepreciation(BonusDeprPct, WorkDate());

        // [GIVEN] Fixed asset "FA" with posted acquisition cost and "Use Bonus Depreciation" enabled
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateJournalSetupDepreciation(DepreciationBook);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", DepreciationBook.Code);
        FADepreciationBook.Validate("Use Bonus Depreciation", true);
        FADepreciationBook.Modify(true);
        AcquisitionAmount := CreateAndPostAcquisitionFAJournalLine(FADepreciationBook);
        BonusDeprAmount := Round(AcquisitionAmount * BonusDeprPct * 0.01);

        // [GIVEN] FA Journal line with bonus depreciation posting type and correct amount
        CreateFAJournalLineWithPostingType(
            FAJournalLine, FixedAsset."No.", DepreciationBook.Code,
            FAJournalLine."FA Posting Type"::"Bonus Depreciation", -BonusDeprAmount);

        // [WHEN] FA Journal Line is posted
        LibraryLowerPermissions.SetJournalsPost();
        LibraryLowerPermissions.AddO365FAEdit();
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        // [THEN] FA Ledger Entry is created with Bonus Depreciation posting type
        FALedgerEntry.SetRange("FA No.", FixedAsset."No.");
        FALedgerEntry.SetRange("FA Posting Type", FALedgerEntry."FA Posting Type"::"Bonus Depreciation");
        FALedgerEntry.FindFirst();
        Assert.AreEqual(-BonusDeprAmount, FALedgerEntry.Amount, 'Bonus depreciation FA Ledger Entry amount is incorrect.');

        // [THEN] Bonus Depr. Applied Amount on FA Depreciation Book is updated
        FADepreciationBook.Get(FixedAsset."No.", DepreciationBook.Code);
        FADepreciationBook.CalcFields("Bonus Depr. Applied Amount");
        Assert.AreEqual(-BonusDeprAmount, FADepreciationBook."Bonus Depr. Applied Amount", 'Bonus Depr. Applied Amount is incorrect.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostBonusDepreciationFromGenJournal()
    var
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        GenJournalLine: Record "Gen. Journal Line";
        FALedgerEntry: Record "FA Ledger Entry";
        AcquisitionAmount: Decimal;
        BonusDeprPct: Decimal;
        BonusDeprAmount: Decimal;
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO 620699] Post a bonus depreciation line from Gen. Journal with G/L integration and verify FA and G/L entries
        Initialize();

        // [GIVEN] FA Setup with bonus depreciation percentage "P"
        BonusDeprPct := LibraryRandom.RandIntInRange(10, 50);
        SetupBonusDepreciation(BonusDeprPct, WorkDate());

        // [GIVEN] Fixed asset "FA" with posted acquisition cost and "Use Bonus Depreciation" enabled
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateJournalSetupDepreciation(DepreciationBook);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", DepreciationBook.Code);
        FADepreciationBook.Validate("Use Bonus Depreciation", true);
        FADepreciationBook.Modify(true);
        IndexationAndIntegrationInBook(DepreciationBook.Code);
        AcquisitionAmount := CreateAndPostAcquisitionGenJournalLine(FADepreciationBook);
        BonusDeprAmount := Round(AcquisitionAmount * BonusDeprPct * 0.01);

        // [GIVEN] Gen. Journal line with bonus depreciation posting type
        CreateGenJournalLineWithPostingType(
            GenJournalLine, FixedAsset."No.", DepreciationBook.Code,
            GenJournalLine."FA Posting Type"::"Bonus Depreciation", -BonusDeprAmount);

        // [WHEN] Gen. Journal Line is posted
        LibraryLowerPermissions.SetJournalsPost();
        LibraryLowerPermissions.AddO365FAEdit();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] FA Ledger Entry is created with Bonus Depreciation posting type
        FALedgerEntry.SetRange("FA No.", FixedAsset."No.");
        FALedgerEntry.SetRange("FA Posting Type", FALedgerEntry."FA Posting Type"::"Bonus Depreciation");
        FALedgerEntry.FindFirst();
        Assert.AreEqual(-BonusDeprAmount, FALedgerEntry.Amount, 'Bonus depreciation FA Ledger Entry amount is incorrect.');

        // [THEN] Bonus Depr. Applied Amount on FA Depreciation Book is updated
        FADepreciationBook.Get(FixedAsset."No.", DepreciationBook.Code);
        FADepreciationBook.CalcFields("Bonus Depr. Applied Amount");
        Assert.AreEqual(-BonusDeprAmount, FADepreciationBook."Bonus Depr. Applied Amount", 'Bonus Depr. Applied Amount is incorrect.');
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('DepreciationCalcConfirmHandler')]
    procedure CalculateDepreciationCreatesBonusDeprLine()
    var
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        FAJournalLine: Record "FA Journal Line";
        FALedgerEntry: Record "FA Ledger Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
        AcquisitionAmount: Decimal;
        BonusDeprPct: Decimal;
        ExpectedBonusDeprAmount: Decimal;
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO 620699] Calculate Depreciation report creates a bonus depreciation line for eligible FA with first depreciation after acquisition
        Initialize();

        // [GIVEN] FA Setup with bonus depreciation percentage "P" and effective date
        BonusDeprPct := LibraryRandom.RandIntInRange(10, 50);
        SetupBonusDepreciation(BonusDeprPct, WorkDate());

        // [GIVEN] Fixed asset "FA" with depreciation book and "Use Bonus Depreciation" enabled
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateJournalSetupDepreciation(DepreciationBook);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", DepreciationBook.Code);
        FADepreciationBook.Validate("Use Bonus Depreciation", true);
        FADepreciationBook.Modify(true);

        // [GIVEN] Posted acquisition cost for "FA"
        AcquisitionAmount := CreateAndPostAcquisitionFAJournalLine(FADepreciationBook);
        GeneralLedgerSetup.Get();
        ExpectedBonusDeprAmount := Round(AcquisitionAmount * BonusDeprPct * 0.01, GeneralLedgerSetup."Amount Rounding Precision");

        // [WHEN] Calculate Depreciation report is run for "FA"
        LibraryLowerPermissions.SetJournalsPost();
        LibraryLowerPermissions.AddO365FAEdit();
        RunCalculateDepreciation(FixedAsset."No.", DepreciationBook.Code);

        // [THEN] FA Journal contains a bonus depreciation line with correct amount
        FindFAJournalLine(FAJournalLine, DepreciationBook.Code, FAJournalLine."FA Posting Type"::"Bonus Depreciation");
        Assert.AreEqual(FixedAsset."No.", FAJournalLine."FA No.", 'Bonus depreciation line should be for the correct FA.');
        Assert.AreEqual(-ExpectedBonusDeprAmount, FAJournalLine.Amount, 'Bonus depreciation amount is incorrect.');

        // [THEN] FA Journal also contains a normal depreciation line
        FindFAJournalLine(FAJournalLine, DepreciationBook.Code, FAJournalLine."FA Posting Type"::Depreciation);
        Assert.AreEqual(FixedAsset."No.", FAJournalLine."FA No.", 'Depreciation line should be for the correct FA.');

        // [WHEN] Both journal lines are posted
        PostDepreciationWithDocumentNo(DepreciationBook.Code);

        // [THEN] FA Ledger Entry exists for Bonus Depreciation
        FALedgerEntry.SetRange("FA No.", FixedAsset."No.");
        FALedgerEntry.SetRange("FA Posting Type", FALedgerEntry."FA Posting Type"::"Bonus Depreciation");
        FALedgerEntry.FindFirst();
        Assert.AreEqual(-ExpectedBonusDeprAmount, FALedgerEntry.Amount, 'Bonus depreciation FA Ledger Entry amount is incorrect.');

        // [THEN] FA Ledger Entry exists for Depreciation
        FALedgerEntry.SetRange("FA Posting Type", FALedgerEntry."FA Posting Type"::Depreciation);
        FALedgerEntry.FindFirst();
        Assert.AreEqual(DepreciationBook.Code, FALedgerEntry."Depreciation Book Code", 'Depreciation FA Ledger Entry should have the correct depreciation book.');
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"ERM FA Bonus Depreciation");
        LibrarySetupStorage.Restore();

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"ERM FA Bonus Depreciation");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateFAPostingGroup();
        LibraryERMCountryData.CreateNewFiscalYear();
        LibraryERMCountryData.UpdateVATPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateAccountInCustomerPostingGroup();

        LibrarySetupStorage.Save(DATABASE::"FA Setup");
        LibrarySetupStorage.SaveGeneralLedgerSetup();
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"ERM FA Bonus Depreciation");
    end;

    local procedure SetupBonusDepreciation(BonusDeprPct: Decimal; BonusDeprEffectiveDate: Date)
    var
        FASetup: Record "FA Setup";
    begin
        FASetup.Get();
        FASetup."Bonus Depreciation %" := BonusDeprPct;
        FASetup."Bonus Depr. Effective Date" := BonusDeprEffectiveDate;
        FASetup.Modify(true);
    end;

    local procedure CreateJournalSetupDepreciation(var DepreciationBook: Record "Depreciation Book")
    var
        FAJournalSetup: Record "FA Journal Setup";
        FAJournalSetup2: Record "FA Journal Setup";
    begin
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        SetAllowDepreciationIfExists(DepreciationBook);
        LibraryFixedAsset.CreateFAJournalSetup(FAJournalSetup, DepreciationBook.Code, '');
        FAJournalSetup2.SetRange("Depreciation Book Code", LibraryFixedAsset.GetDefaultDeprBook());
        FAJournalSetup2.FindFirst();
        FAJournalSetup.TransferFields(FAJournalSetup2, false);
        FAJournalSetup.Modify(true);
    end;

    local procedure CreateFADepreciationBook(var FADepreciationBook: Record "FA Depreciation Book"; FANo: Code[20]; FAPostingGroupCode: Code[20]; DepreciationBookCode: Code[10])
    begin
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FANo, DepreciationBookCode);
        FADepreciationBook.Validate("FA Posting Group", FAPostingGroupCode);
        FADepreciationBook.Validate("Depreciation Starting Date", WorkDate());
        FADepreciationBook.Validate("Depreciation Ending Date", CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'Y>', WorkDate()));
        FADepreciationBook.Modify(true);
    end;

    local procedure CreateFADepreciationBookWithStartDate(var FADepreciationBook: Record "FA Depreciation Book"; FANo: Code[20]; FAPostingGroupCode: Code[20]; DepreciationBookCode: Code[10]; StartDate: Date)
    begin
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FANo, DepreciationBookCode);
        FADepreciationBook.Validate("FA Posting Group", FAPostingGroupCode);
        FADepreciationBook.Validate("Depreciation Starting Date", StartDate);
        FADepreciationBook.Validate("Depreciation Ending Date", CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'Y>', StartDate));
        FADepreciationBook.Modify(true);
    end;

    local procedure CreateFAJournalBatch(var FAJournalBatch: Record "FA Journal Batch")
    var
        FAJournalTemplate: Record "FA Journal Template";
    begin
        LibraryFixedAsset.CreateJournalTemplate(FAJournalTemplate);
        LibraryFixedAsset.CreateFAJournalBatch(FAJournalBatch, FAJournalTemplate.Name);
        FAJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        FAJournalBatch.Modify(true);
    end;

    local procedure CreateFAJnlLineInBatch(var FAJournalLine: Record "FA Journal Line"; FAJournalBatch: Record "FA Journal Batch"; FANo: Code[20]; DepreciationBookCode: Code[10]; FAPostingType: Enum "FA Journal Line FA Posting Type"; Amount: Decimal)
    begin
        LibraryFixedAsset.CreateFAJournalLine(FAJournalLine, FAJournalBatch."Journal Template Name", FAJournalBatch.Name);
        FAJournalLine.Validate("Document No.", LibraryUtility.GenerateGUID());
        FAJournalLine.Validate("Posting Date", WorkDate());
        FAJournalLine.Validate("FA Posting Date", WorkDate());
        FAJournalLine.Validate("FA Posting Type", FAPostingType);
        FAJournalLine.Validate("FA No.", FANo);
        FAJournalLine.Validate(Amount, Amount);
        FAJournalLine.Validate("Depreciation Book Code", DepreciationBookCode);
        FAJournalLine.Modify(true);
    end;

    local procedure CreateAndPostAcquisitionFAJournalLine(FADepreciationBook: Record "FA Depreciation Book"): Decimal
    var
        FAJournalLine: Record "FA Journal Line";
        Amount: Decimal;
    begin
        Amount := LibraryRandom.RandIntInRange(10000, 50000);
        CreateFAJournalLineWithPostingType(
            FAJournalLine, FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code",
            FAJournalLine."FA Posting Type"::"Acquisition Cost", Amount);
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);
        exit(Amount);
    end;

    local procedure CreateAndPostAcquisitionGenJournalLine(FADepreciationBook: Record "FA Depreciation Book"): Decimal
    var
        GenJournalLine: Record "Gen. Journal Line";
        VATPostingSetup: Record "VAT Posting Setup";
        Amount: Decimal;
    begin
        Amount := LibraryRandom.RandIntInRange(10000, 50000);
        CreateGenJournalLineWithPostingType(
            GenJournalLine, FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code",
            GenJournalLine."FA Posting Type"::"Acquisition Cost", Amount);
        GenJournalLine.Validate("Gen. Posting Type", GenJournalLine."Gen. Posting Type"::Purchase);
        VATPostingSetup.SetFilter("VAT Bus. Posting Group", '<>''''');
        VATPostingSetup.SetFilter("VAT Prod. Posting Group", '<>''''');
        VATPostingSetup.SetRange("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.SetRange("VAT %", 0);
        VATPostingSetup.FindFirst();
        GenJournalLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GenJournalLine.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(Amount);
    end;

    local procedure CreateFAJournalLineWithPostingType(var FAJournalLine: Record "FA Journal Line"; FANo: Code[20]; DepreciationBookCode: Code[10]; FAPostingType: Enum "FA Journal Line FA Posting Type"; Amount: Decimal)
    var
        FAJournalBatch: Record "FA Journal Batch";
    begin
        CreateFAJournalBatch(FAJournalBatch);
        CreateFAJnlLineInBatch(FAJournalLine, FAJournalBatch, FANo, DepreciationBookCode, FAPostingType, Amount);
    end;

    local procedure CreateGenJournalLineWithPostingType(var GenJournalLine: Record "Gen. Journal Line"; FANo: Code[20]; DepreciationBookCode: Code[10]; FAPostingType: Enum "Gen. Journal Line FA Posting Type"; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate(Recurring, false);
        GenJournalTemplate.Modify(true);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        GenJournalBatch.Modify(true);

        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type",
            GenJournalLine."Account Type"::"Fixed Asset", FANo, Amount);
        GenJournalLine.Validate("Depreciation Book Code", DepreciationBookCode);
        GenJournalLine.Validate("FA Posting Type", FAPostingType);

        LibraryERM.CreateGLAccount(GLAccount);
        GenJournalLine.Validate("Bal. Account No.", GLAccount."No.");
        GenJournalLine.Modify(true);
    end;

    local procedure IndexationAndIntegrationInBook(DepreciationBookCode: Code[10])
    var
        DepreciationBook: Record "Depreciation Book";
    begin
        DepreciationBook.Get(DepreciationBookCode);
        DepreciationBook.Validate("G/L Integration - Acq. Cost", true);
        DepreciationBook.Validate("G/L Integration - Depreciation", true);
        DepreciationBook.Validate("G/L Integration - Write-Down", true);
        DepreciationBook.Validate("G/L Integration - Appreciation", true);
        DepreciationBook.Validate("G/L Integration - Disposal", true);
        DepreciationBook.Validate("Allow Indexation", true);
        DepreciationBook.Validate("G/L Integration - Custom 1", true);
        DepreciationBook.Validate("G/L Integration - Custom 2", true);
        DepreciationBook.Validate("G/L Integration - Maintenance", true);
        DepreciationBook.Validate("G/L Integration - Bonus Depr.", true);
        DepreciationBook.Validate("Use Same FA+G/L Posting Dates", true);
        DepreciationBook.Modify(true);
    end;

    local procedure SetAllowDepreciationIfExists(var DepreciationBook: Record "Depreciation Book")
    var
        RecRef: RecordRef;
        AllowDeprFieldRef: FieldRef;
        AllowDeprFieldNo: Integer;
    begin
        // "Allow Depreciation" (field 12402) is an RU-specific field required for Calculate Depreciation.
        // Use RecRef to set it conditionally so the test compiles in all country builds.
        AllowDeprFieldNo := 12402;
        RecRef.GetTable(DepreciationBook);
        if RecRef.FieldExist(AllowDeprFieldNo) then begin
            AllowDeprFieldRef := RecRef.Field(AllowDeprFieldNo);
            AllowDeprFieldRef.Validate(true);
            RecRef.Modify(true);
            DepreciationBook.Get(DepreciationBook.Code);
        end;
    end;

    [MessageHandler]
    procedure UseBonusDepreciationMessageHandler(Message: Text[1024])
    begin
    end;

    local procedure RunCalculateDepreciation(FixedAssetNo: Code[20]; DepreciationBookCode: Code[10])
    var
        FixedAsset: Record "Fixed Asset";
        CalculateDepreciation: Report "Calculate Depreciation";
    begin
        Clear(CalculateDepreciation);
        FixedAsset.SetRange("No.", FixedAssetNo);
        CalculateDepreciation.SetTableView(FixedAsset);
        CalculateDepreciation.InitializeRequest(
            DepreciationBookCode, CalcDate('<1D>', WorkDate()), false, 0, CalcDate('<1D>', WorkDate()), FixedAssetNo, FixedAsset.Description, false);
        CalculateDepreciation.UseRequestPage(false);
        CalculateDepreciation.Run();
    end;

    local procedure FindFAJournalLine(var FAJournalLine: Record "FA Journal Line"; DepreciationBookCode: Code[10]; FAPostingType: Enum "FA Journal Line FA Posting Type")
    var
        FAJournalSetup: Record "FA Journal Setup";
    begin
        FAJournalSetup.Get(DepreciationBookCode, '');
        FAJournalLine.SetRange("Journal Template Name", FAJournalSetup."FA Jnl. Template Name");
        FAJournalLine.SetRange("Journal Batch Name", FAJournalSetup."FA Jnl. Batch Name");
        FAJournalLine.SetRange("FA Posting Type", FAPostingType);
        FAJournalLine.FindFirst();
    end;

    local procedure PostDepreciationWithDocumentNo(DepreciationBookCode: Code[10])
    var
        FAJournalLine: Record "FA Journal Line";
        FAJournalSetup: Record "FA Journal Setup";
        FAJournalBatch: Record "FA Journal Batch";
    begin
        FAJournalSetup.Get(DepreciationBookCode, '');
        FAJournalLine.SetRange("Journal Template Name", FAJournalSetup."FA Jnl. Template Name");
        FAJournalLine.SetRange("Journal Batch Name", FAJournalSetup."FA Jnl. Batch Name");
        FAJournalLine.FindFirst();

        FAJournalBatch.Get(FAJournalLine."Journal Template Name", FAJournalLine."Journal Batch Name");
        FAJournalBatch.Validate("No. Series", '');
        FAJournalBatch.Modify(true);

        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);
    end;

    [ConfirmHandler]
    procedure DepreciationCalcConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;
}
