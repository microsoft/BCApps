codeunit 134111 "ERM FA Derogatory Depreciation"
{
    // [FEATURE] [Fixed Asset] [Derogatory]

    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        GroupTotalsCap: Label 'GroupTotals';
        NoFixedAssetCap: Label 'No_FixedAsset';
        NetChangeAmt1Cap: Label 'NetChangeAmt1';
        BookValueAtEndingDateCap: Label 'BookValueAtEndingDate';
        NoFATxt: Label 'No_FA';
        GroupTotalsTxt: Label 'Group Totals: %1', Comment = '%1 = Field Caption';
        GroupTotalTxt: Label 'Group Total:';
        RowNotFoundErr: Label 'Could not find report dataset row for %1 = %2.', Comment = '%1 = element name, %2 = element value';
        RenderedValueMissingErr: Label 'The rendered report does not contain %1.', Comment = '%1 = expected value';
        UnexpectedRenderedValueErr: Label 'The rendered report unexpectedly contains %1.', Comment = '%1 = unexpected value';
        RenderedRowValueMissingErr: Label 'The rendered row for %1 does not contain %2.', Comment = '%1 = row identifier, %2 = expected value';
        ReclassificationTxt: Label 'Reclassification';
        TotalTxt: Label 'Total';

    [Test]
    [HandlerFunctions('FixedAssetBookValue02RequestPageHandler')]
    procedure FABookValue02ReportWithNoDetails()
    var
        FADepreciationBook: Record "FA Depreciation Book";
        FALedgerEntry: Record "FA Ledger Entry";
        GroupTotals: Option " ","FA Class","FA Subclass","FA Location","Main Asset","Global Dimension 1","Global Dimension 2","FA Posting Group";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Fixed Asset - Book Value 02 shows derogatory values without details
        Initialize();

        // [GIVEN] FA "FA" with posted acquisition cost and derogatory entries
        CreateFADepreciationBookAndPostFAGLJournal(FADepreciationBook);

        // [WHEN] Run Fixed Asset - Book Value 02 without details
        RunReportFABookValue02(FADepreciationBook, GroupTotals::" ", false);

        // [THEN] The report shows the derogatory posting type and ending amount
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('DerogatoryAmountHeading', Format(FALedgerEntry."FA Posting Type"::Derogatory));
        LibraryReportDataset.AssertElementWithValueExists(
          'DerogatoryClosingAmount', FALedgerEntryAmount(FADepreciationBook."FA No.", FALedgerEntry."FA Posting Type"::Derogatory));
    end;

    [Test]
    [HandlerFunctions('FixedAssetBookValue02RequestPageHandler')]
    procedure FABookValue02ReportWithFAPostGroup()
    var
        FADepreciationBook: Record "FA Depreciation Book";
        FALedgerEntry: Record "FA Ledger Entry";
        GroupTotals: Option " ","FA Class","FA Subclass","FA Location","Main Asset","Global Dimension 1","Global Dimension 2","FA Posting Group";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Fixed Asset - Book Value 02 groups values by FA posting group
        Initialize();

        // [GIVEN] FA "FA" with posted acquisition cost and derogatory entries
        CreateFADepreciationBookAndPostFAGLJournal(FADepreciationBook);

        // [WHEN] Run Fixed Asset - Book Value 02 grouped by FA posting group
        RunReportFABookValue02(FADepreciationBook, GroupTotals::"FA Posting Group", false);

        // [THEN] The report shows the group and its acquisition cost
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(GroupTotalsCap, Format(GroupTotals::"FA Posting Group"));
        LibraryReportDataset.AssertElementWithValueExists(
          'GroupNetChangeAmt1', FALedgerEntryAmount(FADepreciationBook."FA No.", FALedgerEntry."FA Posting Type"::"Acquisition Cost"));
    end;

    [Test]
    [HandlerFunctions('FixedAssetBookValue02RequestPageHandler')]
    procedure FABookValue02ReportWithPrintDetails()
    var
        FADepreciationBook: Record "FA Depreciation Book";
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Fixed Asset - Book Value 02 shows detailed fixed asset values
        Initialize();

        // [GIVEN] FA "FA" with posted acquisition cost and derogatory entries
        CreateFADepreciationBookAndPostFAGLJournal(FADepreciationBook);

        // [WHEN] Run Fixed Asset - Book Value 02 with details
        RunReportFABookValue02(FADepreciationBook, LibraryRandom.RandIntInRange(1, 7), true);

        // [THEN] The report shows the fixed asset and its acquisition cost
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(NoFixedAssetCap, FADepreciationBook."FA No.");
        LibraryReportDataset.AssertElementWithValueExists(
          NetChangeAmt1Cap, FALedgerEntryAmount(FADepreciationBook."FA No.", FALedgerEntry."FA Posting Type"::"Acquisition Cost"));
    end;

    [Test]
    [HandlerFunctions('PrintFASetupFixedAssetBookValue02RequestPageHandler')]
    procedure FABookValue02ReportWithPrintFASetup()
    var
        DerogatoryFADepreciationBook: Record "FA Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Fixed Asset - Book Value 02 includes FA setup information
        Initialize();

        // [GIVEN] FA "FA" with posted acquisition cost and derogatory entries
        CreateFADepreciationBookAndPostFAGLJournal(FADepreciationBook);
        GetLinkedDerogatoryFADepreciationBook(DerogatoryFADepreciationBook, FADepreciationBook);

        // [WHEN] Run Fixed Asset - Book Value 02 with details and FA setup
        RunReportFABookValue02(FADepreciationBook, LibraryRandom.RandIntInRange(1, 7), true);

        // [THEN] The report shows depreciation setup and acquisition cost
        LibraryReportDataset.LoadDataSetFile();
        VerifyBookValue02SetupMetadata(FADepreciationBook, DerogatoryFADepreciationBook);
        LibraryReportDataset.AssertElementWithValueExists(
          NetChangeAmt1Cap, FALedgerEntryAmount(FADepreciationBook."FA No.", FALedgerEntry."FA Posting Type"::"Acquisition Cost"));
    end;

    [Test]
    [HandlerFunctions('FixedAssetBookValue01RequestPageHandler')]
    procedure FABookValue01ReportWithNoDetails()
    var
        FADepreciationBook: Record "FA Depreciation Book";
        FALedgerEntry: Record "FA Ledger Entry";
        GroupTotals: Option " ","FA Class","FA Subclass","FA Location","Main Asset","Global Dimension 1","Global Dimension 2","FA Posting Group";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Fixed Asset - Book Value 01 shows derogatory values without details
        Initialize();

        // [GIVEN] FA "FA" with posted acquisition cost and derogatory entries
        CreateFADepreciationBookAndPostFAGLJournal(FADepreciationBook);

        // [WHEN] Run Fixed Asset - Book Value 01 without details
        RunReportFABookValue01(FADepreciationBook, GroupTotals::" ", false);

        // [THEN] The report shows derogatory heading and ending amount
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(
          'DerogatoryClosingHeading', StrSubstNo('%1 %2', FADepreciationBook.FieldCaption("Derogatory Amount"), FADepreciationBook."Depreciation Starting Date"));
        LibraryReportDataset.AssertElementWithValueExists(
          'DerogatoryClosingAmount', FALedgerEntryAmount(FADepreciationBook."FA No.", FALedgerEntry."FA Posting Type"::Derogatory));
    end;

    [Test]
    [HandlerFunctions('FixedAssetBookValue01RequestPageHandler')]
    procedure FABookValue01ReportWithFAPostGroup()
    var
        FADepreciationBook: Record "FA Depreciation Book";
        FALedgerEntry: Record "FA Ledger Entry";
        GroupTotals: Option " ","FA Class","FA Subclass","FA Location","Main Asset","Global Dimension 1","Global Dimension 2","FA Posting Group";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Fixed Asset - Book Value 01 groups values by FA posting group
        Initialize();

        // [GIVEN] FA "FA" with posted acquisition cost and derogatory entries
        CreateFADepreciationBookAndPostFAGLJournal(FADepreciationBook);

        // [WHEN] Run Fixed Asset - Book Value 01 grouped by FA posting group
        RunReportFABookValue01(FADepreciationBook, GroupTotals::"FA Posting Group", false);

        // [THEN] The report shows the group, acquisition cost, and ending book value
        FADepreciationBook.CalcFields("Book Value");
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(GroupTotalsCap, Format(GroupTotals::"FA Posting Group"));
        LibraryReportDataset.AssertElementWithValueExists(
          'GroupNetChangeAmounts1', FALedgerEntryAmount(FADepreciationBook."FA No.", FALedgerEntry."FA Posting Type"::"Acquisition Cost"));
        LibraryReportDataset.AssertElementWithValueExists(
          BookValueAtEndingDateCap, FADepreciationBook."Book Value");
    end;

    [Test]
    [HandlerFunctions('FixedAssetBookValue01RequestPageHandler')]
    procedure FABookValue01ReportWithPrintDetails()
    var
        FADepreciationBook: Record "FA Depreciation Book";
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Fixed Asset - Book Value 01 shows detailed fixed asset values
        Initialize();

        // [GIVEN] FA "FA" with posted acquisition cost and derogatory entries
        CreateFADepreciationBookAndPostFAGLJournal(FADepreciationBook);

        // [WHEN] Run Fixed Asset - Book Value 01 with details
        RunReportFABookValue01(FADepreciationBook, LibraryRandom.RandIntInRange(1, 7), true);

        // [THEN] The report shows the fixed asset, acquisition cost, and ending book value
        FADepreciationBook.CalcFields("Book Value");
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(NoFATxt, FADepreciationBook."FA No.");
        LibraryReportDataset.AssertElementWithValueExists(
          'NetChangeAmounts1', FALedgerEntryAmount(FADepreciationBook."FA No.", FALedgerEntry."FA Posting Type"::"Acquisition Cost"));
        LibraryReportDataset.AssertElementWithValueExists(
          BookValueAtEndingDateCap, FADepreciationBook."Book Value");
    end;

    [Test]
    [HandlerFunctions('PrintFASetupFixedAssetBookValue01RequestPageHandler')]
    procedure FABookValue01ReportWithPrintFASetup()
    var
        DerogatoryFADepreciationBook: Record "FA Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Fixed Asset - Book Value 01 includes FA setup information
        Initialize();

        // [GIVEN] FA "FA" with posted acquisition cost and derogatory entries
        CreateFADepreciationBookAndPostFAGLJournal(FADepreciationBook);
        GetLinkedDerogatoryFADepreciationBook(DerogatoryFADepreciationBook, FADepreciationBook);

        // [WHEN] Run Fixed Asset - Book Value 01 with details and FA setup
        RunReportFABookValue01(FADepreciationBook, LibraryRandom.RandIntInRange(1, 7), true);

        // [THEN] The report shows depreciation setup, acquisition cost, and ending book value
        FADepreciationBook.CalcFields("Book Value");
        LibraryReportDataset.LoadDataSetFile();
        VerifyBookValue01SetupMetadata(FADepreciationBook, DerogatoryFADepreciationBook);
        LibraryReportDataset.AssertElementWithValueExists(
          'TotalNetChangeAmounts1', FALedgerEntryAmount(FADepreciationBook."FA No.", FALedgerEntry."FA Posting Type"::"Acquisition Cost"));
        LibraryReportDataset.AssertElementWithValueExists(
          BookValueAtEndingDateCap, FADepreciationBook."Book Value");
    end;

    [Test]
    [HandlerFunctions('FixedAssetBookValue01RequestPageHandler')]
    procedure FABookValue01WithoutLinkedBookHasNoDerogatoryAmounts()
    var
        FADepreciationBook: Record "FA Depreciation Book";
        GenJournalLine: Record "Gen. Journal Line";
        GroupTotals: Option " ","FA Class","FA Subclass","FA Location","Main Asset","Global Dimension 1","Global Dimension 2","FA Posting Group";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Fixed Asset Book Value 01 suppresses derogatory amounts without a linked book
        Initialize();

        // [GIVEN] FA "FA" has a derogatory entry but its accounting book has no linked derogatory book
        CreateFADepreciationBook(FADepreciationBook);
        CreateAndPostFAGLJournal(
          FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code", GenJournalLine."FA Posting Type"::Derogatory);

        // [WHEN] Run Fixed Asset Book Value 01
        RunReportFABookValue01(FADepreciationBook, GroupTotals::" ", true);

        // [THEN] Derogatory reporting is inactive and all per-asset derogatory amounts are zero
        LibraryReportDataset.LoadDataSetFile();
        VerifyNoDerogatoryBookValue01();
    end;

    [Test]
    [HandlerFunctions('FixedAssetBookValue02RequestPageHandler')]
    procedure FABookValue02WithoutLinkedBookHasNoDerogatoryAmounts()
    var
        FADepreciationBook: Record "FA Depreciation Book";
        GenJournalLine: Record "Gen. Journal Line";
        GroupTotals: Option " ","FA Class","FA Subclass","FA Location","Main Asset","Global Dimension 1","Global Dimension 2","FA Posting Group";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Fixed Asset Book Value 02 suppresses derogatory amounts without a linked book
        Initialize();

        // [GIVEN] FA "FA" has a derogatory entry but its accounting book has no linked derogatory book
        CreateFADepreciationBook(FADepreciationBook);
        CreateAndPostFAGLJournal(
          FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code", GenJournalLine."FA Posting Type"::Derogatory);

        // [WHEN] Run Fixed Asset Book Value 02
        RunReportFABookValue02(FADepreciationBook, GroupTotals::" ", true);

        // [THEN] Derogatory reporting is inactive and all per-asset derogatory amounts are zero
        LibraryReportDataset.LoadDataSetFile();
        VerifyNoDerogatoryBookValue02();
    end;

    [Test]
    [HandlerFunctions('FixedAssetBookValue01RequestPageHandler')]
    procedure FABookValue01EligibleValuesDoNotLeakToIneligibleAsset()
    var
        EligibleFADepreciationBook: Record "FA Depreciation Book";
        FALedgerEntry: Record "FA Ledger Entry";
        IneligibleFADepreciationBook: Record "FA Depreciation Book";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Fixed Asset Book Value 01 clears derogatory values after an eligible asset
        Initialize();

        // [GIVEN] Eligible FA "FA1" followed by ineligible FA "FA2" in the same linked accounting book
        CreateMixedEligibilityFADepreciationBooks(EligibleFADepreciationBook, IneligibleFADepreciationBook);

        // [WHEN] Run Fixed Asset Book Value 01 for both assets
        RunReportFABookValue01(EligibleFADepreciationBook, IneligibleFADepreciationBook);

        // [THEN] Only the eligible FA contributes to derogatory group and report totals
        LibraryReportDataset.LoadDataSetFile();
        VerifyMixedBookValue01Amounts(
            EligibleFADepreciationBook, IneligibleFADepreciationBook,
            FALedgerEntryAmount(EligibleFADepreciationBook."FA No.", FALedgerEntry."FA Posting Type"::Derogatory),
            FALedgerEntryAmount(EligibleFADepreciationBook."FA No.", FALedgerEntry."FA Posting Type"::"Acquisition Cost"));
    end;

    [Test]
    [HandlerFunctions('FixedAssetBookValue02RequestPageHandler')]
    procedure FABookValue02EligibleValuesDoNotLeakToIneligibleAsset()
    var
        EligibleFADepreciationBook: Record "FA Depreciation Book";
        FALedgerEntry: Record "FA Ledger Entry";
        IneligibleFADepreciationBook: Record "FA Depreciation Book";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Fixed Asset Book Value 02 clears derogatory and reclassification values after an eligible asset
        Initialize();

        // [GIVEN] Eligible FA "FA1" followed by ineligible FA "FA2" in the same linked accounting book
        CreateMixedEligibilityFADepreciationBooks(EligibleFADepreciationBook, IneligibleFADepreciationBook);

        // [WHEN] Run Fixed Asset Book Value 02 for both assets
        RunReportFABookValue02(EligibleFADepreciationBook, IneligibleFADepreciationBook);

        // [THEN] Only the eligible FA contributes to derogatory group and report totals
        LibraryReportDataset.LoadDataSetFile();
        VerifyMixedBookValue02Amounts(
            EligibleFADepreciationBook, IneligibleFADepreciationBook,
            FALedgerEntryAmount(EligibleFADepreciationBook."FA No.", FALedgerEntry."FA Posting Type"::Derogatory),
            FALedgerEntryAmount(EligibleFADepreciationBook."FA No.", FALedgerEntry."FA Posting Type"::"Acquisition Cost"));
    end;

    [Test]
    [HandlerFunctions('FixedAssetBookValue01RequestPageHandler')]
    procedure FABookValue01MixedEligibilityReverseOrderDoesNotLeakValues()
    var
        EligibleFADepreciationBook: Record "FA Depreciation Book";
        FALedgerEntry: Record "FA Ledger Entry";
        IneligibleFADepreciationBook: Record "FA Depreciation Book";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Fixed Asset Book Value 01 isolates derogatory values in reverse asset order
        Initialize();

        // [GIVEN] Eligible and ineligible FAs in the same linked accounting book
        CreateMixedEligibilityFADepreciationBooks(EligibleFADepreciationBook, IneligibleFADepreciationBook);

        // [WHEN] Run Fixed Asset Book Value 01 for both assets in descending order
        RunReportFABookValue01(EligibleFADepreciationBook, IneligibleFADepreciationBook, false);

        // [THEN] Only the eligible FA contributes to derogatory group and report totals
        LibraryReportDataset.LoadDataSetFile();
        VerifyMixedBookValue01Amounts(
            EligibleFADepreciationBook, IneligibleFADepreciationBook,
            FALedgerEntryAmount(EligibleFADepreciationBook."FA No.", FALedgerEntry."FA Posting Type"::Derogatory),
            FALedgerEntryAmount(EligibleFADepreciationBook."FA No.", FALedgerEntry."FA Posting Type"::"Acquisition Cost"));
    end;

    [Test]
    [HandlerFunctions('FixedAssetBookValue02RequestPageHandler')]
    procedure FABookValue02MixedEligibilityReverseOrderDoesNotLeakValues()
    var
        EligibleFADepreciationBook: Record "FA Depreciation Book";
        FALedgerEntry: Record "FA Ledger Entry";
        IneligibleFADepreciationBook: Record "FA Depreciation Book";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Fixed Asset Book Value 02 isolates derogatory values in reverse asset order
        Initialize();

        // [GIVEN] Eligible and ineligible FAs in the same linked accounting book
        CreateMixedEligibilityFADepreciationBooks(EligibleFADepreciationBook, IneligibleFADepreciationBook);

        // [WHEN] Run Fixed Asset Book Value 02 for both assets in descending order
        RunReportFABookValue02(EligibleFADepreciationBook, IneligibleFADepreciationBook, false);

        // [THEN] Only the eligible FA contributes to derogatory group and report totals
        LibraryReportDataset.LoadDataSetFile();
        VerifyMixedBookValue02Amounts(
            EligibleFADepreciationBook, IneligibleFADepreciationBook,
            FALedgerEntryAmount(EligibleFADepreciationBook."FA No.", FALedgerEntry."FA Posting Type"::Derogatory),
            FALedgerEntryAmount(EligibleFADepreciationBook."FA No.", FALedgerEntry."FA Posting Type"::"Acquisition Cost"));
    end;

    [Test]
    [HandlerFunctions('FixedAssetBookValue02RequestPageHandler')]
    procedure FABookValue02HidesZeroDerogatorySections()
    var
        FADepreciationBook: Record "FA Depreciation Book";
        GenJournalLine: Record "Gen. Journal Line";
        GroupTotals: Option " ","FA Class","FA Subclass","FA Location","Main Asset","Global Dimension 1","Global Dimension 2","FA Posting Group";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Fixed Asset Book Value 02 hides empty derogatory rows in every section
        Initialize();

        // [GIVEN] Eligible FA "FA" with acquisition cost but no derogatory movements
        CreateLinkedFADepreciationBook(FADepreciationBook);
        CreateAndPostFAGLJournal(
            FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code",
            GenJournalLine."FA Posting Type"::"Acquisition Cost");

        // [WHEN] Run Fixed Asset Book Value 02 with details, grouping, and reclassification
        RunReportFABookValue02(FADepreciationBook, GroupTotals::"FA Posting Group", true, true);

        // [THEN] Detail, group, and report-total derogatory sections are hidden
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('HasDerogatorySetup', true);
        LibraryReportDataset.AssertElementWithValueExists('ShowDerogatoryDetail', false);
        LibraryReportDataset.AssertElementWithValueExists('ShowDerogatoryGroup', false);
        LibraryReportDataset.AssertElementWithValueExists('ShowDerogatoryTotal', false);
    end;

    [Test]
    [HandlerFunctions('PrintFASetupFixedAssetBookValue01RequestPageHandler')]
    procedure FABookValue01PrintSetupIdentifiesIneligibleAsset()
    var
        EligibleFADepreciationBook: Record "FA Depreciation Book";
        IneligibleFADepreciationBook: Record "FA Depreciation Book";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Fixed Asset Book Value 01 identifies an asset without linked-book setup
        Initialize();

        // [GIVEN] Eligible and ineligible FAs in the same linked accounting book
        CreateMixedEligibilityFADepreciationBooks(EligibleFADepreciationBook, IneligibleFADepreciationBook);

        // [WHEN] Run Fixed Asset Book Value 01 with FA setup
        RunReportFABookValue01(EligibleFADepreciationBook, IneligibleFADepreciationBook);

        // [THEN] The ineligible row prints setup, identifies missing linked setup, and has no derogatory data
        LibraryReportDataset.LoadDataSetFile();
        VerifyIneligibleBookValue01SetupRow(IneligibleFADepreciationBook."FA No.");
    end;

    [Test]
    [HandlerFunctions('PrintFASetupFixedAssetBookValue02RequestPageHandler')]
    procedure FABookValue02PrintSetupIdentifiesIneligibleAsset()
    var
        EligibleFADepreciationBook: Record "FA Depreciation Book";
        IneligibleFADepreciationBook: Record "FA Depreciation Book";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Fixed Asset Book Value 02 identifies an asset without linked-book setup
        Initialize();

        // [GIVEN] Eligible and ineligible FAs in the same linked accounting book
        CreateMixedEligibilityFADepreciationBooks(EligibleFADepreciationBook, IneligibleFADepreciationBook);

        // [WHEN] Run Fixed Asset Book Value 02 with FA setup
        RunReportFABookValue02(EligibleFADepreciationBook, IneligibleFADepreciationBook);

        // [THEN] The ineligible row prints setup, identifies missing linked setup, and has no derogatory data
        LibraryReportDataset.LoadDataSetFile();
        VerifyIneligibleBookValue02SetupRow(IneligibleFADepreciationBook."FA No.");
    end;

    [Test]
    [HandlerFunctions('FixedAssetBookValue01RequestPageHandler')]
    procedure FABookValue01ShowsDerogatoryMovementsAtAllLevels()
    var
        FADepreciationBook: Record "FA Depreciation Book";
        GenJournalLine: Record "Gen. Journal Line";
        GroupTotals: Option " ","FA Class","FA Subclass","FA Location","Main Asset","Global Dimension 1","Global Dimension 2","FA Posting Group";
        AcquisitionAmount: Decimal;
        OpeningAmount: Decimal;
        IncreaseAmount: Decimal;
        DecreaseAmount: Decimal;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Fixed Asset Book Value 01 reports derogatory movements at detail, group, and grand-total levels
        Initialize();

        // [GIVEN] Eligible FA "FA" with an opening derogatory balance and in-period increase and decrease
        CreateLinkedFADepreciationBook(FADepreciationBook);
        AcquisitionAmount := LibraryRandom.RandDec(1000, 2);
        OpeningAmount := -LibraryRandom.RandDec(100, 2);
        IncreaseAmount := -LibraryRandom.RandDec(100, 2);
        DecreaseAmount := LibraryRandom.RandDec(100, 2);
        CreateAndPostFAGLJournal(
            FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code",
            GenJournalLine."FA Posting Type"::"Acquisition Cost", WorkDate(), AcquisitionAmount, false);
        CreateAndPostFAGLJournal(
            FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code",
            GenJournalLine."FA Posting Type"::Derogatory, WorkDate() - 1, OpeningAmount, false);
        CreateAndPostFAGLJournal(
            FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code",
            GenJournalLine."FA Posting Type"::Derogatory, WorkDate(), IncreaseAmount, false);
        CreateAndPostFAGLJournal(
            FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code",
            GenJournalLine."FA Posting Type"::Derogatory, WorkDate(), DecreaseAmount, false);

        // [WHEN] Run Fixed Asset Book Value 01 with details and grouping
        RunReportFABookValue01(FADepreciationBook, GroupTotals::"FA Posting Group", true);

        // [THEN] Detail and group values provide the correct inputs for the grand-total sums, without changing book value
        LibraryReportDataset.LoadDataSetFile();
        VerifyBookValue01DerogatoryAmounts(
            FADepreciationBook."FA No.", OpeningAmount, IncreaseAmount, DecreaseAmount,
            OpeningAmount + IncreaseAmount + DecreaseAmount, AcquisitionAmount);
    end;

    [Test]
    [HandlerFunctions('FixedAssetBookValue02RequestPageHandler')]
    procedure FABookValue02ShowsDerogatoryAndReclassificationMovementsAtAllLevels()
    var
        FADepreciationBook: Record "FA Depreciation Book";
        GenJournalLine: Record "Gen. Journal Line";
        GroupTotals: Option " ","FA Class","FA Subclass","FA Location","Main Asset","Global Dimension 1","Global Dimension 2","FA Posting Group";
        AcquisitionAmount: Decimal;
        OpeningAmount: Decimal;
        IncreaseAmount: Decimal;
        DecreaseAmount: Decimal;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Fixed Asset Book Value 02 reports derogatory and reclassification movements at all levels
        Initialize();

        // [GIVEN] Eligible FA "FA" with opening, increase, decrease, and reclassified derogatory entries
        CreateLinkedFADepreciationBook(FADepreciationBook);
        AcquisitionAmount := LibraryRandom.RandDec(1000, 2);
        OpeningAmount := -LibraryRandom.RandDec(100, 2);
        IncreaseAmount := -LibraryRandom.RandDec(100, 2);
        DecreaseAmount := LibraryRandom.RandDec(100, 2);
        CreateAndPostFAGLJournal(
            FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code",
            GenJournalLine."FA Posting Type"::"Acquisition Cost", WorkDate(), AcquisitionAmount, false);
        CreateAndPostFAGLJournal(
            FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code",
            GenJournalLine."FA Posting Type"::Derogatory, WorkDate() - 1, OpeningAmount, false);
        CreateAndPostFAGLJournal(
            FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code",
            GenJournalLine."FA Posting Type"::Derogatory, WorkDate(), IncreaseAmount, true);
        CreateAndPostFAGLJournal(
            FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code",
            GenJournalLine."FA Posting Type"::Derogatory, WorkDate(), DecreaseAmount, false);

        // [WHEN] Run Fixed Asset Book Value 02 with details, grouping, and reclassification
        RunReportFABookValue02(FADepreciationBook, GroupTotals::"FA Posting Group", true, true);

        // [THEN] Detail, group, and report totals are correct and accounting book value excludes derogatory amounts
        LibraryReportDataset.LoadDataSetFile();
        VerifyBookValue02DerogatoryAmounts(
            FADepreciationBook."FA No.", OpeningAmount, IncreaseAmount, DecreaseAmount,
            OpeningAmount + IncreaseAmount + DecreaseAmount, AcquisitionAmount);
    end;

    [Test]
    procedure ShowDerogatoryValueofPreviousMonthInFixedAssetBookValue()
    var
        FixedAsset: Record "Fixed Asset";
        DepreciationBook: array[2] of Record "Depreciation Book";
        FADepreciationBook: array[2] of Record "FA Depreciation Book";
        FAJournalLine: Record "FA Journal Line";
        GroupTotals: Option " ","FA Class","FA Subclass","FA Location","Main Asset","Global Dimension 1","Global Dimension 2","FA Posting Group";
        PostingDate: Date;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 578183] Fixed Asset Book Value - 01 report generates the derogatory value of previous month.
        Initialize();

        // [GIVEN] Two depreciation books
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook[1]);
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook[2]);
        DepreciationBook[2].Validate("Derogatory Calc.", DepreciationBook[1].Code);
        DepreciationBook[2].Modify(true);

        // [GIVEN] FA "FA" with an FA posting group
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);

        // [GIVEN] FA depreciation book "DB1" with declining-balance depreciation
        CreateFADepreciationBook(
            FADepreciationBook[1],
            FixedAsset."No.",
            FixedAsset."FA Posting Group",
            DepreciationBook[1].Code);
        FADepreciationBook[1].Validate("Depreciation Method", FADepreciationBook[1]."Depreciation Method"::"DB2/SL");
        FADepreciationBook[1].Validate("No. of Depreciation Years", LibraryRandom.RandDecInDecimalRange(0.41, 0.41, 2));
        FADepreciationBook[1].Validate("Declining-Balance %", LibraryRandom.RandIntInRange(20, 25));
        FADepreciationBook[1].Modify(true);

        // [GIVEN] FA depreciation book "DB2"
        CreateFADepreciationBook(FADepreciationBook[2], FixedAsset."No.", FixedAsset."FA Posting Group", DepreciationBook[2].Code);

        // [GIVEN] Posting date "D" before the work date
        PostingDate := CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate());

        // [GIVEN] Posted acquisition cost for "FA"
        CreateAndPostFAJournalLine(
            FixedAsset."No.",
            FAJournalLine."FA Posting Type"::"Acquisition Cost",
            DepreciationBook[1].Code,
            PostingDate);

        // [GIVEN] Posted depreciation and derogatory entries for two months
        PostDisposalFAJournalLine(
            FixedAsset."No.",
            FAJournalLine."FA Posting Type"::Depreciation,
            DepreciationBook[1].Code,
            PostingDate);

        PostDisposalFAJournalLine(
            FixedAsset."No.",
            FAJournalLine."FA Posting Type"::Derogatory,
            DepreciationBook[1].Code,
            PostingDate);

        PostDisposalFAJournalLine(
            FixedAsset."No.",
            FAJournalLine."FA Posting Type"::Depreciation,
            DepreciationBook[1].Code,
            CalcDate('<1M>', PostingDate));

        // [WHEN] Run Fixed Asset - Book Value 01 for the first period
        // LibraryLowerPermissions.SetO365FAView();
        RunFixedAssetBookValue01Report1(
            FixedAsset,
            DepreciationBook[1].Code,
            GroupTotals::"FA Posting Group",
            false,
            false,
            CalcDate('<CM>', PostingDate) + 1);

        // [THEN] The report shows the derogatory value of the first period
        LibraryReportValidation.OpenFile();
        LibraryReportValidation.SetRange(StrSubstNo(GroupTotalsTxt, FixedAsset.FieldCaption("FA Posting Group")), GroupTotalTxt + ' ' + FixedAsset."FA Posting Group");
        LibraryReportValidation.CheckIfValueExists(
            StrSubstNo(
                '%1 %2',
                FADepreciationBook[1].FieldCaption("Derogatory Amount"),
                CalcDate('<CM>', PostingDate)));
    end;

    [Test]
    [HandlerFunctions('PrintFASetupFixedAssetBookValue01ExcelRequestPageHandler')]
    procedure FABookValue01RendersDerogatoryMovementsAndSetup()
    var
        DerogatoryFADepreciationBook: Record "FA Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        GenJournalLine: Record "Gen. Journal Line";
        GroupTotals: Option " ","FA Class","FA Subclass","FA Location","Main Asset","Global Dimension 1","Global Dimension 2","FA Posting Group";
        AcquisitionAmount: Decimal;
        OpeningAmount: Decimal;
        IncreaseAmount: Decimal;
        DecreaseAmount: Decimal;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Fixed Asset Book Value 01 renders derogatory movements and distinct setup rows
        Initialize();

        // [GIVEN] Eligible FA "FA" with distinct accounting and derogatory setup and movements
        CreateLinkedFADepreciationBook(FADepreciationBook);
        GetLinkedDerogatoryFADepreciationBook(DerogatoryFADepreciationBook, FADepreciationBook);
        SetDistinctDepreciationSetup(FADepreciationBook, DerogatoryFADepreciationBook);
        AcquisitionAmount := 1000.01;
        OpeningAmount := -111.11;
        IncreaseAmount := -222.22;
        DecreaseAmount := 33.33;
        CreateAndPostFAGLJournal(
            FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code",
            GenJournalLine."FA Posting Type"::"Acquisition Cost", WorkDate(), AcquisitionAmount, false);
        CreateAndPostFAGLJournal(
            FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code",
            GenJournalLine."FA Posting Type"::Derogatory, WorkDate() - 1, OpeningAmount, false);
        CreateAndPostFAGLJournal(
            FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code",
            GenJournalLine."FA Posting Type"::Derogatory, WorkDate(), IncreaseAmount, false);
        CreateAndPostFAGLJournal(
            FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code",
            GenJournalLine."FA Posting Type"::Derogatory, WorkDate(), DecreaseAmount, false);

        // [WHEN] Render Fixed Asset Book Value 01 with details, grouping, and FA setup
        RunFixedAssetBookValue01AsExcel(FADepreciationBook, GroupTotals::"FA Posting Group", true);

        // [THEN] The layout renders each movement and keeps accounting and derogatory setup on their own rows
        LibraryReportValidation.OpenFile();
        VerifyRenderedDecimalValue(AcquisitionAmount);
        VerifyRenderedDecimalValue(OpeningAmount);
        VerifyRenderedDecimalValue(IncreaseAmount);
        VerifyRenderedDecimalValue(DecreaseAmount);
        VerifyRenderedDecimalValue(OpeningAmount + IncreaseAmount + DecreaseAmount);
        VerifyRenderedValueContains(FADepreciationBook.FieldCaption("Derogatory Amount"));
        VerifyRenderedSetupRow(FADepreciationBook);
        VerifyRenderedSetupRow(DerogatoryFADepreciationBook);
    end;

    [Test]
    [HandlerFunctions('FixedAssetBookValue01ExcelRequestPageHandler')]
    procedure FABookValue01WithoutLinkedBookHidesDerogatoryColumns()
    var
        FADepreciationBook: Record "FA Depreciation Book";
        GenJournalLine: Record "Gen. Journal Line";
        GroupTotals: Option " ","FA Class","FA Subclass","FA Location","Main Asset","Global Dimension 1","Global Dimension 2","FA Posting Group";
        AcquisitionAmount: Decimal;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Fixed Asset Book Value 01 hides derogatory columns when no linked book exists
        Initialize();

        // [GIVEN] FA "FA" in an accounting book without a linked derogatory book
        CreateFADepreciationBook(FADepreciationBook);
        AcquisitionAmount := 1000.02;
        CreateAndPostFAGLJournal(
            FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code",
            GenJournalLine."FA Posting Type"::"Acquisition Cost", WorkDate(), AcquisitionAmount, false);

        // [WHEN] Render Fixed Asset Book Value 01 with details
        RunFixedAssetBookValue01AsExcel(FADepreciationBook, GroupTotals::" ", false);

        // [THEN] Accounting output remains visible and derogatory headings are absent
        LibraryReportValidation.OpenFile();
        VerifyRenderedValue(FADepreciationBook."FA No.");
        VerifyRenderedDecimalValue(AcquisitionAmount);
        VerifyRenderedValueIsAbsent(FADepreciationBook.FieldCaption("Derogatory Amount"), true);
    end;

    [Test]
    [HandlerFunctions('PrintFASetupFixedAssetBookValue02ExcelRequestPageHandler')]
    procedure FABookValue02RendersAccountingAndDerogatorySetup()
    var
        DerogatoryFADepreciationBook: Record "FA Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        GenJournalLine: Record "Gen. Journal Line";
        GroupTotals: Option " ","FA Class","FA Subclass","FA Location","Main Asset","Global Dimension 1","Global Dimension 2","FA Posting Group";
        AcquisitionAmount: Decimal;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Fixed Asset Book Value 02 renders accounting and derogatory setup on distinct rows
        Initialize();

        // [GIVEN] Eligible FA "FA" with distinct accounting and derogatory setup
        CreateLinkedFADepreciationBook(FADepreciationBook);
        GetLinkedDerogatoryFADepreciationBook(DerogatoryFADepreciationBook, FADepreciationBook);
        SetDistinctDepreciationSetup(FADepreciationBook, DerogatoryFADepreciationBook);
        AcquisitionAmount := 1000;
        CreateAndPostFAGLJournal(
            FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code",
            GenJournalLine."FA Posting Type"::"Acquisition Cost", WorkDate(), AcquisitionAmount, false);

        // [WHEN] Render Fixed Asset Book Value 02 with FA setup
        RunFixedAssetBookValue02AsExcel(FADepreciationBook, GroupTotals::" ", false, false);

        // [THEN] Accounting and derogatory setup values are rendered on their respective rows
        LibraryReportValidation.OpenFile();
        VerifyRenderedSetupRow(FADepreciationBook);
        VerifyRenderedSetupRow(DerogatoryFADepreciationBook);
    end;

    [Test]
    [HandlerFunctions('FixedAssetBookValue02ExcelRequestPageHandler')]
    procedure FABookValue02RendersDerogatoryAndReclassificationTotals()
    var
        FADepreciationBook: Record "FA Depreciation Book";
        GenJournalLine: Record "Gen. Journal Line";
        GroupTotals: Option " ","FA Class","FA Subclass","FA Location","Main Asset","Global Dimension 1","Global Dimension 2","FA Posting Group";
        AcquisitionAmount: Decimal;
        OpeningAmount: Decimal;
        ReclassifiedIncreaseAmount: Decimal;
        DecreaseAmount: Decimal;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Fixed Asset Book Value 02 renders derogatory and reclassification totals
        Initialize();

        // [GIVEN] Eligible FA "FA" with opening, decrease, and reclassified derogatory movements
        CreateLinkedFADepreciationBook(FADepreciationBook);
        AcquisitionAmount := 1000.03;
        OpeningAmount := -111.12;
        ReclassifiedIncreaseAmount := -222.23;
        DecreaseAmount := 33.34;
        CreateAndPostFAGLJournal(
            FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code",
            GenJournalLine."FA Posting Type"::"Acquisition Cost", WorkDate(), AcquisitionAmount, false);
        CreateAndPostFAGLJournal(
            FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code",
            GenJournalLine."FA Posting Type"::Derogatory, WorkDate() - 1, OpeningAmount, false);
        CreateAndPostFAGLJournal(
            FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code",
            GenJournalLine."FA Posting Type"::Derogatory, WorkDate(), ReclassifiedIncreaseAmount, true);
        CreateAndPostFAGLJournal(
            FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code",
            GenJournalLine."FA Posting Type"::Derogatory, WorkDate(), DecreaseAmount, false);

        // [WHEN] Render Fixed Asset Book Value 02 with details, grouping, and reclassification
        RunFixedAssetBookValue02AsExcel(FADepreciationBook, GroupTotals::"FA Posting Group", true, true);

        // [THEN] Detail movements, group/report totals, and the reclassification section are rendered
        LibraryReportValidation.OpenFile();
        VerifyRenderedValue(FADepreciationBook."FA No.");
        VerifyRenderedValue(FADepreciationBook.FieldCaption("Derogatory Amount"));
        VerifyRenderedValue(ReclassificationTxt);
        VerifyRenderedValue(GroupTotalTxt + ' ' + FADepreciationBook."FA Posting Group");
        VerifyRenderedValue(TotalTxt);
        VerifyRenderedDecimalValueMinimumCount(OpeningAmount, 3);
        VerifyRenderedDecimalValueMinimumCount(ReclassifiedIncreaseAmount, 3);
        VerifyRenderedDecimalValueMinimumCount(DecreaseAmount, 3);
        VerifyRenderedDecimalValueMinimumCount(OpeningAmount + ReclassifiedIncreaseAmount + DecreaseAmount, 3);
    end;

    [Test]
    [HandlerFunctions('FixedAssetBookValue02ExcelRequestPageHandler')]
    procedure FABookValue02WithZeroDerogatoryAmountsHidesRows()
    var
        FADepreciationBook: Record "FA Depreciation Book";
        GenJournalLine: Record "Gen. Journal Line";
        GroupTotals: Option " ","FA Class","FA Subclass","FA Location","Main Asset","Global Dimension 1","Global Dimension 2","FA Posting Group";
        AcquisitionAmount: Decimal;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Fixed Asset Book Value 02 hides zero-valued derogatory rows
        Initialize();

        // [GIVEN] Eligible FA "FA" with an acquisition but no derogatory movements
        CreateLinkedFADepreciationBook(FADepreciationBook);
        AcquisitionAmount := 1000.04;
        CreateAndPostFAGLJournal(
            FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code",
            GenJournalLine."FA Posting Type"::"Acquisition Cost", WorkDate(), AcquisitionAmount, false);

        // [WHEN] Render Fixed Asset Book Value 02 with details and grouping
        RunFixedAssetBookValue02AsExcel(FADepreciationBook, GroupTotals::"FA Posting Group", true, false);

        // [THEN] Accounting output remains visible and all derogatory rows are absent
        LibraryReportValidation.OpenFile();
        VerifyRenderedValue(FADepreciationBook."FA No.");
        VerifyRenderedDecimalValue(AcquisitionAmount);
        VerifyRenderedValueIsAbsent(FADepreciationBook.FieldCaption("Derogatory Amount"), false);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"ERM FA Derogatory Depreciation");
        LibraryReportDataset.Reset();

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"ERM FA Derogatory Depreciation");
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"ERM FA Derogatory Depreciation");
    end;

    local procedure CreateAndPostFAGLJournal(FANo: Code[20]; DepreciationBookCode: Code[10]; FAPostingType: Enum "Gen. Journal Line FA Posting Type")
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        GLAccount: Record "G/L Account";
        SourceCode: Record "Source Code";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateSourceCode(SourceCode);
        CreateGeneralJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"Fixed Asset", FANo, LibraryRandom.RandDec(100, 2));  // Using Random value for Amount.
        GenJournalLine.Validate("Document No.", GenJournalLine."Account No.");
        GenJournalLine.Validate("FA Posting Type", FAPostingType);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Depreciation Book Code", DepreciationBookCode);
        GenJournalLine.Validate("Source Code", SourceCode.Code);
        GenJournalLine.Validate("Bal. Account No.", GLAccount."No.");
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndPostFAGLJournal(FANo: Code[20]; DepreciationBookCode: Code[10]; FAPostingType: Enum "Gen. Journal Line FA Posting Type"; PostingDate: Date; Amount: Decimal; ReclassificationEntry: Boolean)
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        GLAccount: Record "G/L Account";
        SourceCode: Record "Source Code";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateSourceCode(SourceCode);
        CreateGeneralJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
            GenJournalLine."Account Type"::"Fixed Asset", FANo, Amount);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("FA Posting Date", PostingDate);
        GenJournalLine.Validate("Document No.", GenJournalLine."Account No.");
        GenJournalLine.Validate("FA Posting Type", FAPostingType);
        GenJournalLine.Validate("FA Reclassification Entry", ReclassificationEntry);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Depreciation Book Code", DepreciationBookCode);
        GenJournalLine.Validate("Source Code", SourceCode.Code);
        GenJournalLine.Validate("Bal. Account No.", GLAccount."No.");
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndPostFAJournalLine(FANo: Code[20]; FAPostingType: Enum "FA Journal Line FA Posting Type"; DepreciationBookCode: Code[10]; PostingDate: Date) FAJournalLineAmount: Decimal
    var
        FAJournalLine: Record "FA Journal Line";
    begin
        CreateFAJournalLine(FAJournalLine, FANo, DepreciationBookCode, FAPostingType, PostingDate);
        FAJournalLineAmount := FAJournalLine.Amount;
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);
    end;

    local procedure CreateDepreciationBook(): Code[10]
    var
        DepreciationBook: Record "Depreciation Book";
    begin
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        DepreciationBook.Validate("G/L Integration - Acq. Cost", true);
        DepreciationBook.Validate("G/L Integration - Depreciation", true);
        DepreciationBook.Validate("Integration G/L - Derogatory", true);
        DepreciationBook.Modify(true);
        exit(DepreciationBook.Code);
    end;

    local procedure CreateFADepreciationBook(var FADepreciationBook: Record "FA Depreciation Book")
    var
        FAPostingGroup: Record "FA Posting Group";
        FixedAsset: Record "Fixed Asset";
    begin
        // Create a dedicated FA posting group with derogatory accounts set, so the derogatory posting is
        // independent of country demo data (some localizations' demo FA posting groups have no derogatory account).
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);
        UpdateDerogatoryAccounts(FAPostingGroup);
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", CreateDepreciationBook());
        FADepreciationBook.Validate("FA Posting Group", FAPostingGroup.Code);
        FADepreciationBook.Validate("Depreciation Starting Date", WorkDate());
        FADepreciationBook.Validate("Depreciation Ending Date", WorkDate());
        FADepreciationBook.Modify(true);
    end;

    local procedure CreateFADepreciationBook(var FADepreciationBook: Record "FA Depreciation Book"; FANo: Code[20]; FAPostingGroup: Code[20]; DepreciationBookCode: Code[10])
    begin
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FANo, DepreciationBookCode);
        FADepreciationBook.Validate("FA Posting Group", FAPostingGroup);
        FADepreciationBook.Validate("Depreciation Starting Date", WorkDate());
        FADepreciationBook.Validate("Depreciation Ending Date", CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'Y>', WorkDate()));
        FADepreciationBook.Modify(true);
    end;

    local procedure CreateFADepreciationBookAndPostFAGLJournal(var FADepreciationBook: Record "FA Depreciation Book")
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateLinkedFADepreciationBook(FADepreciationBook);
        CreateAndPostFAGLJournal(
          FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code", GenJournalLine."FA Posting Type"::"Acquisition Cost");
        CreateAndPostFAGLJournal(
          FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code", GenJournalLine."FA Posting Type"::Derogatory);
    end;

    local procedure CreateLinkedFADepreciationBook(var FADepreciationBook: Record "FA Depreciation Book")
    var
        DerogatoryDepreciationBook: Record "Depreciation Book";
        DerogatoryFADepreciationBook: Record "FA Depreciation Book";
    begin
        CreateFADepreciationBook(FADepreciationBook);
        LibraryFixedAsset.CreateDepreciationBook(DerogatoryDepreciationBook);
        DerogatoryDepreciationBook.Validate("Derogatory Calc.", FADepreciationBook."Depreciation Book Code");
        DerogatoryDepreciationBook.Modify(true);
        CreateFADepreciationBook(
            DerogatoryFADepreciationBook,
            FADepreciationBook."FA No.",
            FADepreciationBook."FA Posting Group",
            DerogatoryDepreciationBook.Code);
    end;

    local procedure CreateMixedEligibilityFADepreciationBooks(var EligibleFADepreciationBook: Record "FA Depreciation Book"; var IneligibleFADepreciationBook: Record "FA Depreciation Book")
    var
        FixedAsset: Record "Fixed Asset";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateFADepreciationBookAndPostFAGLJournal(EligibleFADepreciationBook);
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        CreateFADepreciationBook(
            IneligibleFADepreciationBook,
            FixedAsset."No.",
            EligibleFADepreciationBook."FA Posting Group",
            EligibleFADepreciationBook."Depreciation Book Code");
        CreateAndPostFAGLJournal(
            IneligibleFADepreciationBook."FA No.",
            IneligibleFADepreciationBook."Depreciation Book Code",
            GenJournalLine."FA Posting Type"::Derogatory);
    end;

    local procedure GetLinkedDerogatoryBookCode(DepreciationBookCode: Code[10]): Code[10]
    var
        DepreciationBook: Record "Depreciation Book";
    begin
        DepreciationBook.SetRange("Derogatory Calc.", DepreciationBookCode);
        DepreciationBook.FindFirst();
        exit(DepreciationBook.Code);
    end;

    local procedure GetLinkedDerogatoryFADepreciationBook(var DerogatoryFADepreciationBook: Record "FA Depreciation Book"; FADepreciationBook: Record "FA Depreciation Book")
    begin
        DerogatoryFADepreciationBook.Get(
            FADepreciationBook."FA No.", GetLinkedDerogatoryBookCode(FADepreciationBook."Depreciation Book Code"));
    end;

    local procedure SetDistinctDepreciationSetup(var FADepreciationBook: Record "FA Depreciation Book"; var DerogatoryFADepreciationBook: Record "FA Depreciation Book")
    begin
        FADepreciationBook.Validate("Depreciation Method", FADepreciationBook."Depreciation Method"::"DB2/SL");
        FADepreciationBook.Validate("Depreciation Starting Date", WorkDate() - 10);
        FADepreciationBook.Validate("Depreciation Ending Date", WorkDate() + 100);
        FADepreciationBook.Validate("Declining-Balance %", 11);
        FADepreciationBook.Modify(true);

        DerogatoryFADepreciationBook.Validate(
            "Depreciation Method", DerogatoryFADepreciationBook."Depreciation Method"::"Declining-Balance 1");
        DerogatoryFADepreciationBook.Validate("Depreciation Starting Date", WorkDate() - 20);
        DerogatoryFADepreciationBook.Validate("Depreciation Ending Date", WorkDate() + 200);
        DerogatoryFADepreciationBook.Validate("Declining-Balance %", 22);
        DerogatoryFADepreciationBook.Modify(true);
    end;

    local procedure VerifyRenderedSetupRow(FADepreciationBook: Record "FA Depreciation Book")
    var
        RowValues: array[50] of Text[250];
    begin
        LibraryReportValidation.SetRange(
            FADepreciationBook."Depreciation Book Code", FADepreciationBook."Depreciation Book Code");
        LibraryReportValidation.FindFirstRow(RowValues);
        AssertRowContainsValue(RowValues, FADepreciationBook."Depreciation Book Code");
        AssertRowContainsValue(RowValues, Format(FADepreciationBook."Depreciation Method"));
        AssertRowContainsValue(RowValues, Format(FADepreciationBook."Depreciation Starting Date"));
        AssertRowContainsValue(RowValues, Format(FADepreciationBook."Depreciation Ending Date"));
        AssertRowContainsValue(RowValues, Format(FADepreciationBook."Declining-Balance %"));
    end;

    local procedure VerifyRenderedDecimalValueMinimumCount(ExpectedValue: Decimal; MinimumCount: Integer)
    var
        ExcelBuffer: Record "Excel Buffer";
    begin
        ExcelBuffer.SetRange("Cell Value as Text", LibraryReportValidation.FormatDecimalValue(ExpectedValue));
        Assert.IsTrue(
            ExcelBuffer.Count >= MinimumCount,
            StrSubstNo(RenderedValueMissingErr, ExpectedValue));
    end;

    local procedure AssertRowContainsValue(RowValues: array[50] of Text[250]; ExpectedValue: Text)
    var
        Index: Integer;
    begin
        for Index := 1 to ArrayLen(RowValues) do
            if RowValues[Index] = ExpectedValue then
                exit;

        Error(RenderedRowValueMissingErr, RowValues[1], ExpectedValue);
    end;

    local procedure VerifyRenderedValue(ExpectedValue: Text)
    begin
        Assert.IsTrue(
            LibraryReportValidation.CheckIfValueExists(ExpectedValue),
            StrSubstNo(RenderedValueMissingErr, ExpectedValue));
    end;

    local procedure VerifyRenderedDecimalValue(ExpectedValue: Decimal)
    begin
        Assert.IsTrue(
            LibraryReportValidation.CheckIfDecimalValueExists(ExpectedValue),
            StrSubstNo(RenderedValueMissingErr, ExpectedValue));
    end;

    local procedure VerifyRenderedValueContains(ExpectedValue: Text)
    var
        ExcelBuffer: Record "Excel Buffer";
    begin
        ExcelBuffer.SetFilter("Cell Value as Text", '@*%1*', ExpectedValue);
        Assert.IsFalse(ExcelBuffer.IsEmpty(), StrSubstNo(RenderedValueMissingErr, ExpectedValue));
    end;

    local procedure VerifyRenderedValueIsAbsent(UnexpectedValue: Text; PartialMatch: Boolean)
    var
        ExcelBuffer: Record "Excel Buffer";
    begin
        if PartialMatch then begin
            ExcelBuffer.SetFilter("Cell Value as Text", '@*%1*', UnexpectedValue);
            Assert.IsTrue(ExcelBuffer.IsEmpty(), StrSubstNo(UnexpectedRenderedValueErr, UnexpectedValue));
        end else
            Assert.IsFalse(
                LibraryReportValidation.CheckIfValueExists(UnexpectedValue),
                StrSubstNo(UnexpectedRenderedValueErr, UnexpectedValue));
    end;

    local procedure VerifyBookValue01SetupMetadata(FADepreciationBook: Record "FA Depreciation Book"; DerogatoryFADepreciationBook: Record "FA Depreciation Book")
    begin
        LibraryReportDataset.AssertElementWithValueExists('AccountingDeprBookCode', FADepreciationBook."Depreciation Book Code");
        LibraryReportDataset.AssertElementWithValueExists('AccountingDeprMethod', Format(FADepreciationBook."Depreciation Method"));
        LibraryReportDataset.AssertElementWithValueExists('AccountingDeprStartingDate', FADepreciationBook."Depreciation Starting Date");
        LibraryReportDataset.AssertElementWithValueExists('AccountingDeprEndingDate', FADepreciationBook."Depreciation Ending Date");
        LibraryReportDataset.AssertElementWithValueExists('AccountingDecliningBalancePct', FADepreciationBook."Declining-Balance %");
        LibraryReportDataset.AssertElementWithValueExists('DerogatoryDeprBookCode', DerogatoryFADepreciationBook."Depreciation Book Code");
        LibraryReportDataset.AssertElementWithValueExists('DerogatoryDeprMethod', Format(DerogatoryFADepreciationBook."Depreciation Method"));
        LibraryReportDataset.AssertElementWithValueExists('DerogatoryDeprStartingDate', DerogatoryFADepreciationBook."Depreciation Starting Date");
        LibraryReportDataset.AssertElementWithValueExists('DerogatoryDeprEndingDate', DerogatoryFADepreciationBook."Depreciation Ending Date");
        LibraryReportDataset.AssertElementWithValueExists('DerogatoryDecliningBalancePct', DerogatoryFADepreciationBook."Declining-Balance %");
    end;

    local procedure VerifyBookValue02SetupMetadata(FADepreciationBook: Record "FA Depreciation Book"; DerogatoryFADepreciationBook: Record "FA Depreciation Book")
    begin
        LibraryReportDataset.AssertElementWithValueExists('AccountingDeprBookCode', FADepreciationBook."Depreciation Book Code");
        LibraryReportDataset.AssertElementWithValueExists('AccountingDeprMethod', Format(FADepreciationBook."Depreciation Method"));
        LibraryReportDataset.AssertElementWithValueExists('AccountingDeprStartingDate', FADepreciationBook."Depreciation Starting Date");
        LibraryReportDataset.AssertElementWithValueExists('AccountingDeprEndingDate', FADepreciationBook."Depreciation Ending Date");
        LibraryReportDataset.AssertElementWithValueExists('AccountingDecliningBalancePct', FADepreciationBook."Declining-Balance %");
        LibraryReportDataset.AssertElementWithValueExists('DerogatoryDeprBookCode', DerogatoryFADepreciationBook."Depreciation Book Code");
        LibraryReportDataset.AssertElementWithValueExists('DerogatoryDeprMethod', Format(DerogatoryFADepreciationBook."Depreciation Method"));
        LibraryReportDataset.AssertElementWithValueExists('DerogatoryDeprStartingDate', DerogatoryFADepreciationBook."Depreciation Starting Date");
        LibraryReportDataset.AssertElementWithValueExists('DerogatoryDeprEndingDate', DerogatoryFADepreciationBook."Depreciation Ending Date");
        LibraryReportDataset.AssertElementWithValueExists('DerogatoryDecliningBalancePct', DerogatoryFADepreciationBook."Declining-Balance %");
    end;

    local procedure VerifyNoDerogatoryBookValue01()
    begin
        LibraryReportDataset.AssertElementWithValueExists('HasDerogatoryBook', false);
        LibraryReportDataset.AssertElementWithValueExists('HasDerogatorySetup', false);
        LibraryReportDataset.AssertElementWithValueExists('DerogatoryOpeningAmount', 0);
        LibraryReportDataset.AssertElementWithValueExists('DerogatoryIncreaseAmount', 0);
        LibraryReportDataset.AssertElementWithValueExists('DerogatoryDecreaseAmount', 0);
        LibraryReportDataset.AssertElementWithValueExists('DerogatoryClosingAmount', 0);
    end;

    local procedure VerifyNoDerogatoryBookValue02()
    begin
        LibraryReportDataset.AssertElementWithValueExists('HasDerogatoryBook', false);
        LibraryReportDataset.AssertElementWithValueExists('HasDerogatorySetup', false);
        LibraryReportDataset.AssertElementWithValueExists('DerogatoryOpeningAmount', 0);
        LibraryReportDataset.AssertElementWithValueExists('DerogatoryIncreaseAmount', 0);
        LibraryReportDataset.AssertElementWithValueExists('DerogatoryDecreaseAmount', 0);
        LibraryReportDataset.AssertElementWithValueExists('DerogatoryClosingAmount', 0);
    end;

    local procedure VerifyIneligibleBookValue01Row(FANo: Code[20])
    begin
        LibraryReportDataset.SetRange(NoFATxt, FANo);
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), StrSubstNo(RowNotFoundErr, NoFATxt, FANo));
        LibraryReportDataset.AssertCurrentRowValueEquals('HasDerogatorySetup', false);
        LibraryReportDataset.AssertCurrentRowValueEquals('DerogatoryOpeningAmount', 0);
        LibraryReportDataset.AssertCurrentRowValueEquals('DerogatoryIncreaseAmount', 0);
        LibraryReportDataset.AssertCurrentRowValueEquals('DerogatoryDecreaseAmount', 0);
        LibraryReportDataset.AssertCurrentRowValueEquals('DerogatoryClosingAmount', 0);
    end;

    local procedure VerifyIneligibleBookValue02Row(FANo: Code[20])
    begin
        LibraryReportDataset.SetRange(NoFixedAssetCap, FANo);
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), StrSubstNo(RowNotFoundErr, NoFixedAssetCap, FANo));
        LibraryReportDataset.AssertCurrentRowValueEquals('HasDerogatorySetup', false);
        LibraryReportDataset.AssertCurrentRowValueEquals('DerogatoryOpeningAmount', 0);
        LibraryReportDataset.AssertCurrentRowValueEquals('DerogatoryIncreaseAmount', 0);
        LibraryReportDataset.AssertCurrentRowValueEquals('DerogatoryDecreaseAmount', 0);
        LibraryReportDataset.AssertCurrentRowValueEquals('DerogatoryReclassOpeningAmt', 0);
        LibraryReportDataset.AssertCurrentRowValueEquals('DerogatoryReclassIncreaseAmt', 0);
        LibraryReportDataset.AssertCurrentRowValueEquals('DerogatoryReclassDecreaseAmt', 0);
    end;

    local procedure VerifyIneligibleBookValue01SetupRow(FANo: Code[20])
    begin
        VerifyIneligibleBookValue01Row(FANo);
        LibraryReportDataset.AssertCurrentRowValueEquals('PrintFASetup', true);
        LibraryReportDataset.AssertCurrentRowValueEquals('DerogatoryDeprBookCode', '');
        LibraryReportDataset.AssertCurrentRowValueEquals('DerogatoryDeprMethod', '');
        LibraryReportDataset.AssertCurrentRowValueEquals('DerogatoryDeprStartingDate', 0D);
        LibraryReportDataset.AssertCurrentRowValueEquals('DerogatoryDeprEndingDate', 0D);
        LibraryReportDataset.AssertCurrentRowValueEquals('DerogatoryDecliningBalancePct', 0);
    end;

    local procedure VerifyIneligibleBookValue02SetupRow(FANo: Code[20])
    begin
        VerifyIneligibleBookValue02Row(FANo);
        LibraryReportDataset.AssertCurrentRowValueEquals('PrintFASetup', true);
        LibraryReportDataset.AssertCurrentRowValueEquals('DerogatoryDeprBookCode', '');
        LibraryReportDataset.AssertCurrentRowValueEquals('DerogatoryDeprMethod', '');
        LibraryReportDataset.AssertCurrentRowValueEquals('DerogatoryDeprStartingDate', 0D);
        LibraryReportDataset.AssertCurrentRowValueEquals('DerogatoryDeprEndingDate', 0D);
        LibraryReportDataset.AssertCurrentRowValueEquals('DerogatoryDecliningBalancePct', 0);
    end;

    local procedure VerifyMixedBookValue01Amounts(EligibleFADepreciationBook: Record "FA Depreciation Book"; IneligibleFADepreciationBook: Record "FA Depreciation Book"; DerogatoryAmount: Decimal; AccountingBookValue: Decimal)
    begin
        LibraryReportDataset.SetRange(NoFATxt, EligibleFADepreciationBook."FA No.");
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), StrSubstNo(RowNotFoundErr, NoFATxt, EligibleFADepreciationBook."FA No."));
        LibraryReportDataset.AssertCurrentRowValueEquals('HasDerogatorySetup', true);
        LibraryReportDataset.AssertCurrentRowValueEquals('DerogatoryDecreaseAmount', DerogatoryAmount);
        LibraryReportDataset.AssertCurrentRowValueEquals('DerogatoryClosingAmount', DerogatoryAmount);
        VerifyIneligibleBookValue01Row(IneligibleFADepreciationBook."FA No.");
        LibraryReportDataset.AssertElementWithValueExists('DerogatoryGroupDecreaseAmount', DerogatoryAmount);
        LibraryReportDataset.AssertElementWithValueExists(BookValueAtEndingDateCap, AccountingBookValue);
    end;

    local procedure VerifyMixedBookValue02Amounts(EligibleFADepreciationBook: Record "FA Depreciation Book"; IneligibleFADepreciationBook: Record "FA Depreciation Book"; DerogatoryAmount: Decimal; AccountingBookValue: Decimal)
    begin
        LibraryReportDataset.SetRange(NoFixedAssetCap, EligibleFADepreciationBook."FA No.");
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), StrSubstNo(RowNotFoundErr, NoFixedAssetCap, EligibleFADepreciationBook."FA No."));
        LibraryReportDataset.AssertCurrentRowValueEquals('HasDerogatorySetup', true);
        LibraryReportDataset.AssertCurrentRowValueEquals('DerogatoryDecreaseAmount', DerogatoryAmount);
        LibraryReportDataset.AssertCurrentRowValueEquals('DerogatoryClosingAmount', DerogatoryAmount);
        VerifyIneligibleBookValue02Row(IneligibleFADepreciationBook."FA No.");
        LibraryReportDataset.AssertElementWithValueExists('DerogatoryGroupDecreaseAmount', DerogatoryAmount);
        LibraryReportDataset.AssertElementWithValueExists('DerogatoryTotalDecreaseAmount', DerogatoryAmount);
        LibraryReportDataset.AssertElementWithValueExists('BookValueAtEndingDate_Control125', AccountingBookValue);
        LibraryReportDataset.AssertElementWithValueExists('BookValueAtEndingDate_Control169', AccountingBookValue);
    end;

    local procedure VerifyBookValue01DerogatoryAmounts(FANo: Code[20]; OpeningAmount: Decimal; IncreaseAmount: Decimal; DecreaseAmount: Decimal; ClosingAmount: Decimal; BookValue: Decimal)
    begin
        LibraryReportDataset.SetRange(NoFATxt, FANo);
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), StrSubstNo(RowNotFoundErr, NoFATxt, FANo));
        LibraryReportDataset.AssertCurrentRowValueEquals('DerogatoryOpeningAmount', OpeningAmount);
        LibraryReportDataset.AssertCurrentRowValueEquals('DerogatoryIncreaseAmount', IncreaseAmount);
        LibraryReportDataset.AssertCurrentRowValueEquals('DerogatoryDecreaseAmount', DecreaseAmount);
        LibraryReportDataset.AssertCurrentRowValueEquals('DerogatoryClosingAmount', ClosingAmount);
        LibraryReportDataset.AssertCurrentRowValueEquals(BookValueAtEndingDateCap, BookValue);
        LibraryReportDataset.AssertCurrentRowValueEquals('PrintFASetup', false);
        LibraryReportDataset.AssertElementWithValueExists('DerogatoryGroupOpeningAmount', OpeningAmount);
        LibraryReportDataset.AssertElementWithValueExists('DerogatoryGroupIncreaseAmount', IncreaseAmount);
        LibraryReportDataset.AssertElementWithValueExists('DerogatoryGroupDecreaseAmount', DecreaseAmount);
    end;

    local procedure VerifyBookValue02DerogatoryAmounts(FANo: Code[20]; OpeningAmount: Decimal; IncreaseAmount: Decimal; DecreaseAmount: Decimal; ClosingAmount: Decimal; BookValue: Decimal)
    begin
        LibraryReportDataset.SetRange(NoFixedAssetCap, FANo);
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), StrSubstNo(RowNotFoundErr, NoFixedAssetCap, FANo));
        LibraryReportDataset.AssertCurrentRowValueEquals('DerogatoryOpeningAmount', OpeningAmount);
        LibraryReportDataset.AssertCurrentRowValueEquals('DerogatoryIncreaseAmount', IncreaseAmount);
        LibraryReportDataset.AssertCurrentRowValueEquals('DerogatoryDecreaseAmount', DecreaseAmount);
        LibraryReportDataset.AssertCurrentRowValueEquals('DerogatoryClosingAmount', ClosingAmount);
        LibraryReportDataset.AssertCurrentRowValueEquals('DerogatoryReclassIncreaseAmt', IncreaseAmount);
        LibraryReportDataset.AssertCurrentRowValueEquals(BookValueAtEndingDateCap, BookValue);
        LibraryReportDataset.AssertCurrentRowValueEquals('PrintFASetup', false);
        LibraryReportDataset.AssertCurrentRowValueEquals('ShowDerogatoryDetail', true);
        LibraryReportDataset.AssertElementWithValueExists('ShowDerogatoryGroup', true);
        LibraryReportDataset.AssertElementWithValueExists('ShowDerogatoryTotal', true);
        VerifyBookValue02AggregateAmounts('Group', OpeningAmount, IncreaseAmount, DecreaseAmount);
        VerifyBookValue02AggregateAmounts('Total', OpeningAmount, IncreaseAmount, DecreaseAmount);
    end;

    local procedure VerifyBookValue02AggregateAmounts(Prefix: Text; OpeningAmount: Decimal; IncreaseAmount: Decimal; DecreaseAmount: Decimal)
    begin
        LibraryReportDataset.AssertElementWithValueExists('Derogatory' + Prefix + 'OpeningAmount', OpeningAmount);
        LibraryReportDataset.AssertElementWithValueExists('Derogatory' + Prefix + 'IncreaseAmount', IncreaseAmount);
        LibraryReportDataset.AssertElementWithValueExists('Derogatory' + Prefix + 'DecreaseAmount', DecreaseAmount);
        LibraryReportDataset.AssertElementWithValueExists('Derogatory' + Prefix + 'ReclassOpeningAmt', 0);
        LibraryReportDataset.AssertElementWithValueExists('Derogatory' + Prefix + 'ReclassIncreaseAmt', IncreaseAmount);
        LibraryReportDataset.AssertElementWithValueExists('Derogatory' + Prefix + 'ReclassDecreaseAmt', 0);
    end;

    local procedure CreateFAJournalBatch(var FAJournalBatch: Record "FA Journal Batch")
    var
        FAJournalTemplate: Record "FA Journal Template";
    begin
        FAJournalTemplate.SetRange(Recurring, false);
        LibraryFixedAsset.FindFAJournalTemplate(FAJournalTemplate);
        LibraryFixedAsset.CreateFAJournalBatch(FAJournalBatch, FAJournalTemplate.Name);
    end;

    local procedure CreateFAJournalLine(var FAJournalLine: Record "FA Journal Line"; FANo: Code[20]; DepreciationBookCode: Code[10]; FAPostingType: Enum "FA Journal Line FA Posting Type"; PostingDate: Date)
    var
        FAJournalBatch: Record "FA Journal Batch";
    begin
        CreateFAJournalBatch(FAJournalBatch);
        LibraryFixedAsset.CreateFAJournalLine(FAJournalLine, FAJournalBatch."Journal Template Name", FAJournalBatch.Name);
        FAJournalLine.Validate("Document No.", FAJournalBatch.Name);
        FAJournalLine.Validate("Posting Date", PostingDate);
        FAJournalLine.Validate("FA Posting Date", PostingDate);
        FAJournalLine.Validate("FA Posting Type", FAPostingType);
        FAJournalLine.Validate("FA No.", FANo);
        FAJournalLine.Validate(Amount, LibraryRandom.RandDec(1000, 2));
        FAJournalLine.Validate("Depreciation Book Code", DepreciationBookCode);
        FAJournalLine.Modify(true);
    end;

    local procedure CreateGeneralJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Assets);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure FALedgerEntryAmount(FANo: Code[20]; FAPostingType: Enum "FA Ledger Entry FA Posting Type"): Decimal
    var
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        FALedgerEntry.SetRange("FA No.", FANo);
        FALedgerEntry.SetRange("FA Posting Type", FAPostingType);
        FALedgerEntry.FindFirst();
        exit(FALedgerEntry.Amount);
    end;

    local procedure PostDisposalFAJournalLine(FixedAssetNo: Code[20]; FAPostingType: Enum "FA Journal Line FA Posting Type"; DepreciationBookCode: Code[10]; PostingDate: Date) FAJournalLineAmount: Decimal
    var
        FAJournalLine: Record "FA Journal Line";
    begin
        CreateFAJournalLine(FAJournalLine, FixedAssetNo, DepreciationBookCode, FAPostingType, PostingDate);
        FAJournalLine.Validate(Amount, -LibraryRandom.RandDec(10, 2));
        FAJournalLine.Modify(true);
        FAJournalLineAmount := FAJournalLine.Amount;
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);
    end;

    local procedure RunFixedAssetBookValue01Report1(FixedAsset: Record "Fixed Asset"; DepreciationBookCode: Code[10]; GroupTotals: Option; PrintTotal: Boolean; BudgetReport: Boolean; StartDate: Date)
    var
        FixedAssetBookValue01: Report "Fixed Asset - Book Value 01";
    begin
        Clear(FixedAssetBookValue01);
        FixedAssetBookValue01.SetTableView(FixedAsset);
        FixedAssetBookValue01.UseRequestPage(false);
        FixedAssetBookValue01.SetMandatoryFields(DepreciationBookCode, StartDate, CalcDate('<CM>', StartDate));
        FixedAssetBookValue01.SetTotalFields(GroupTotals, PrintTotal, BudgetReport);
        LibraryReportValidation.SetFileName(CreateGuid());
        FixedAssetBookValue01.SaveAsExcel(LibraryReportValidation.GetFileName());
    end;

    local procedure RunFixedAssetBookValue01AsExcel(FADepreciationBook: Record "FA Depreciation Book"; GroupTotals: Option; PrintTotal: Boolean)
    var
        FixedAsset: Record "Fixed Asset";
        FixedAssetBookValue01: Report "Fixed Asset - Book Value 01";
    begin
        LibraryReportValidation.SetFileName(CreateGuid());
        FixedAsset.SetRange("No.", FADepreciationBook."FA No.");
        FixedAssetBookValue01.SetTableView(FixedAsset);
        FixedAssetBookValue01.SetMandatoryFields(FADepreciationBook."Depreciation Book Code", WorkDate(), WorkDate());
        FixedAssetBookValue01.SetTotalFields(GroupTotals, true, PrintTotal);
        FixedAssetBookValue01.Run();
    end;

    local procedure RunFixedAssetBookValue02AsExcel(FADepreciationBook: Record "FA Depreciation Book"; GroupTotals: Option; PrintTotal: Boolean; Reclassify: Boolean)
    var
        FixedAsset: Record "Fixed Asset";
        FixedAssetBookValue02: Report "Fixed Asset - Book Value 02";
    begin
        LibraryReportValidation.SetFileName(CreateGuid());
        FixedAsset.SetRange("No.", FADepreciationBook."FA No.");
        FixedAssetBookValue02.SetTableView(FixedAsset);
        FixedAssetBookValue02.SetMandatoryFields(FADepreciationBook."Depreciation Book Code", WorkDate(), WorkDate());
        FixedAssetBookValue02.SetTotalFields(GroupTotals, true, PrintTotal, Reclassify);
        FixedAssetBookValue02.Run();
        LibraryReportValidation.DownloadFile();
    end;

    local procedure RunReportFABookValue01(FADepreciationBook: Record "FA Depreciation Book"; GroupTotals: Option; PrintDetails: Boolean)
    var
        FixedAsset: Record "Fixed Asset";
        FixedAssetBookValue01: Report "Fixed Asset - Book Value 01";
    begin
        Clear(FixedAssetBookValue01);
        FixedAsset.SetRange("No.", FADepreciationBook."FA No.");
        FixedAssetBookValue01.SetTableView(FixedAsset);
        FixedAssetBookValue01.SetMandatoryFields(FADepreciationBook."Depreciation Book Code", WorkDate(), WorkDate());
        FixedAssetBookValue01.SetTotalFields(GroupTotals, PrintDetails, false);  // Using FALSE for Budget Report.
        FixedAssetBookValue01.Run();
    end;

    local procedure RunReportFABookValue02(FADepreciationBook: Record "FA Depreciation Book"; GroupTotals: Option; PrintDetails: Boolean)
    begin
        RunReportFABookValue02(FADepreciationBook, GroupTotals, PrintDetails, false);
    end;

    local procedure RunReportFABookValue02(FADepreciationBook: Record "FA Depreciation Book"; GroupTotals: Option; PrintDetails: Boolean; Reclassify: Boolean)
    var
        FixedAsset: Record "Fixed Asset";
        FixedAssetBookValue02: Report "Fixed Asset - Book Value 02";
    begin
        Clear(FixedAssetBookValue02);
        FixedAsset.SetRange("No.", FADepreciationBook."FA No.");
        FixedAssetBookValue02.SetTableView(FixedAsset);
        FixedAssetBookValue02.SetMandatoryFields(FADepreciationBook."Depreciation Book Code", WorkDate(), WorkDate());
        FixedAssetBookValue02.SetTotalFields(GroupTotals, PrintDetails, false, Reclassify);
        FixedAssetBookValue02.Run();
    end;

    local procedure RunReportFABookValue01(EligibleFADepreciationBook: Record "FA Depreciation Book"; IneligibleFADepreciationBook: Record "FA Depreciation Book")
    begin
        RunReportFABookValue01(EligibleFADepreciationBook, IneligibleFADepreciationBook, true);
    end;

    local procedure RunReportFABookValue01(EligibleFADepreciationBook: Record "FA Depreciation Book"; IneligibleFADepreciationBook: Record "FA Depreciation Book"; Ascending: Boolean)
    var
        FixedAsset: Record "Fixed Asset";
        FixedAssetBookValue01: Report "Fixed Asset - Book Value 01";
    begin
        FixedAsset.SetCurrentKey("No.");
        FixedAsset.Ascending(Ascending);
        FixedAsset.SetFilter("No.", '%1|%2', EligibleFADepreciationBook."FA No.", IneligibleFADepreciationBook."FA No.");
        FixedAssetBookValue01.SetTableView(FixedAsset);
        FixedAssetBookValue01.SetMandatoryFields(EligibleFADepreciationBook."Depreciation Book Code", WorkDate(), WorkDate());
        FixedAssetBookValue01.SetTotalFields(0, true, false);
        FixedAssetBookValue01.Run();
    end;

    local procedure RunReportFABookValue02(EligibleFADepreciationBook: Record "FA Depreciation Book"; IneligibleFADepreciationBook: Record "FA Depreciation Book")
    begin
        RunReportFABookValue02(EligibleFADepreciationBook, IneligibleFADepreciationBook, true);
    end;

    local procedure RunReportFABookValue02(EligibleFADepreciationBook: Record "FA Depreciation Book"; IneligibleFADepreciationBook: Record "FA Depreciation Book"; Ascending: Boolean)
    var
        FixedAsset: Record "Fixed Asset";
        FixedAssetBookValue02: Report "Fixed Asset - Book Value 02";
    begin
        FixedAsset.SetCurrentKey("No.");
        FixedAsset.Ascending(Ascending);
        FixedAsset.SetFilter("No.", '%1|%2', EligibleFADepreciationBook."FA No.", IneligibleFADepreciationBook."FA No.");
        FixedAssetBookValue02.SetTableView(FixedAsset);
        FixedAssetBookValue02.SetMandatoryFields(EligibleFADepreciationBook."Depreciation Book Code", WorkDate(), WorkDate());
        FixedAssetBookValue02.SetTotalFields(0, true, false, true);
        FixedAssetBookValue02.Run();
    end;

    local procedure UpdateDerogatoryAccounts(var FAPostingGroup: Record "FA Posting Group")
    begin
        // Reuse the group's existing valid accounts so the derogatory setup is deterministic and country-independent.
        FAPostingGroup.Validate("Derogatory Acc.", FAPostingGroup."Accum. Depreciation Account");
        FAPostingGroup.Validate("Derogatory Account (Decrease)", FAPostingGroup."Accum. Depreciation Account");
        FAPostingGroup.Validate("Derogatory Expense Acc.", FAPostingGroup."Depreciation Expense Acc.");
        FAPostingGroup.Validate("Derog. Bal. Account (Decrease)", FAPostingGroup."Depreciation Expense Acc.");
        FAPostingGroup.Modify(true);
    end;

    [RequestPageHandler]
    procedure FixedAssetBookValue02RequestPageHandler(var FixedAssetBookValue02: TestRequestPage "Fixed Asset - Book Value 02")
    begin
        FixedAssetBookValue02.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    procedure PrintFASetupFixedAssetBookValue02RequestPageHandler(var FixedAssetBookValue02: TestRequestPage "Fixed Asset - Book Value 02")
    begin
        FixedAssetBookValue02.Print_FASetup.SetValue(true);
        FixedAssetBookValue02.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    procedure FixedAssetBookValue01RequestPageHandler(var FixedAssetBookValue01: TestRequestPage "Fixed Asset - Book Value 01")
    begin
        FixedAssetBookValue01.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    procedure PrintFASetupFixedAssetBookValue01RequestPageHandler(var FixedAssetBookValue01: TestRequestPage "Fixed Asset - Book Value 01")
    begin
        FixedAssetBookValue01.Print_FASetup.SetValue(true);
        FixedAssetBookValue01.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    procedure PrintFASetupFixedAssetBookValue01ExcelRequestPageHandler(var FixedAssetBookValue01: TestRequestPage "Fixed Asset - Book Value 01")
    begin
        FixedAssetBookValue01.Print_FASetup.SetValue(true);
        FixedAssetBookValue01.SaveAsExcel(LibraryReportValidation.GetFileName());
    end;

    [RequestPageHandler]
    procedure FixedAssetBookValue01ExcelRequestPageHandler(var FixedAssetBookValue01: TestRequestPage "Fixed Asset - Book Value 01")
    begin
        FixedAssetBookValue01.SaveAsExcel(LibraryReportValidation.GetFileName());
    end;

    [RequestPageHandler]
    procedure PrintFASetupFixedAssetBookValue02ExcelRequestPageHandler(var FixedAssetBookValue02: TestRequestPage "Fixed Asset - Book Value 02")
    begin
        FixedAssetBookValue02.Print_FASetup.SetValue(true);
        FixedAssetBookValue02.SaveAsExcel(LibraryReportValidation.GetFileName());
    end;

    [RequestPageHandler]
    procedure FixedAssetBookValue02ExcelRequestPageHandler(var FixedAssetBookValue02: TestRequestPage "Fixed Asset - Book Value 02")
    begin
        FixedAssetBookValue02.SaveAsExcel(LibraryReportValidation.GetFileName());
    end;

}
