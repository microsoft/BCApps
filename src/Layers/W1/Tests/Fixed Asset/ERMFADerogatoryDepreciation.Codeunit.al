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
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        GroupTotalsCap: Label 'GroupTotals';
        DeprBookInfo1Cap: Label 'DeprBookInfo1';
        DeprBookInfo2Cap: Label 'DeprBookInfo2';
        NoFixedAssetCap: Label 'No_FixedAsset';
        NetChangeAmt1Cap: Label 'NetChangeAmt1';
        BookValueAtEndingDateCap: Label 'BookValueAtEndingDate';
        NoFATxt: Label 'No_FA';
        GroupTotalsTxt: Label 'Group Totals: %1', Comment = '%1 = Field Caption';
        GroupTotalTxt: Label 'Group Total:';

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
        LibraryReportDataset.AssertElementWithValueExists('HeadLineText10', Format(FALedgerEntry."FA Posting Type"::Derogatory));
        LibraryReportDataset.AssertElementWithValueExists(
          'TotalEndingAmt7', FALedgerEntryAmount(FADepreciationBook."FA No.", FALedgerEntry."FA Posting Type"::Derogatory));
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
        FADepreciationBook: Record "FA Depreciation Book";
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Fixed Asset - Book Value 02 includes FA setup information
        Initialize();

        // [GIVEN] FA "FA" with posted acquisition cost and derogatory entries
        CreateFADepreciationBookAndPostFAGLJournal(FADepreciationBook);

        // [WHEN] Run Fixed Asset - Book Value 02 with details and FA setup
        RunReportFABookValue02(FADepreciationBook, LibraryRandom.RandIntInRange(1, 7), true);

        // [THEN] The report shows depreciation setup and acquisition cost
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(DeprBookInfo1Cap, FADepreciationBook."Depreciation Book Code");
        LibraryReportDataset.AssertElementWithValueExists(DeprBookInfo2Cap, Format(FADepreciationBook."Depreciation Method"));
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
          'HeadLineText14', StrSubstNo('%1 %2', FADepreciationBook.FieldCaption("Derogatory Amount"), FADepreciationBook."Depreciation Starting Date"));
        LibraryReportDataset.AssertElementWithValueExists(
          'TotalEndingAmounts7', FALedgerEntryAmount(FADepreciationBook."FA No.", FALedgerEntry."FA Posting Type"::Derogatory));
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
          BookValueAtEndingDateCap, FALedgerEntryAmount(FADepreciationBook."FA No.", FALedgerEntry."FA Posting Type"::Derogatory) +
          FADepreciationBook."Book Value");
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
          BookValueAtEndingDateCap, FALedgerEntryAmount(FADepreciationBook."FA No.", FALedgerEntry."FA Posting Type"::Derogatory) +
          FADepreciationBook."Book Value");
    end;

    [Test]
    [HandlerFunctions('PrintFASetupFixedAssetBookValue01RequestPageHandler')]
    procedure FABookValue01ReportWithPrintFASetup()
    var
        FADepreciationBook: Record "FA Depreciation Book";
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Fixed Asset - Book Value 01 includes FA setup information
        Initialize();

        // [GIVEN] FA "FA" with posted acquisition cost and derogatory entries
        CreateFADepreciationBookAndPostFAGLJournal(FADepreciationBook);

        // [WHEN] Run Fixed Asset - Book Value 01 with details and FA setup
        RunReportFABookValue01(FADepreciationBook, LibraryRandom.RandIntInRange(1, 7), true);

        // [THEN] The report shows depreciation setup, acquisition cost, and ending book value
        FADepreciationBook.CalcFields("Book Value");
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(DeprBookInfo1Cap, FADepreciationBook."Depreciation Book Code");
        LibraryReportDataset.AssertElementWithValueExists(DeprBookInfo2Cap, Format(FADepreciationBook."Depreciation Method"));
        LibraryReportDataset.AssertElementWithValueExists(
          'TotalNetChangeAmounts1', FALedgerEntryAmount(FADepreciationBook."FA No.", FALedgerEntry."FA Posting Type"::"Acquisition Cost"));
        LibraryReportDataset.AssertElementWithValueExists(
          BookValueAtEndingDateCap, FALedgerEntryAmount(FADepreciationBook."FA No.", FALedgerEntry."FA Posting Type"::Derogatory) +
          FADepreciationBook."Book Value");
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
        // Create Fixed Asset Depreciation Book, create and post FA General Journal Line with Acquisition Cost and Derogatory.
        CreateFADepreciationBook(FADepreciationBook);
        CreateAndPostFAGLJournal(
          FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code", GenJournalLine."FA Posting Type"::"Acquisition Cost");
        CreateAndPostFAGLJournal(
          FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code", GenJournalLine."FA Posting Type"::Derogatory);
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
    var
        FixedAsset: Record "Fixed Asset";
        FixedAssetBookValue02: Report "Fixed Asset - Book Value 02";
    begin
        Clear(FixedAssetBookValue02);
        FixedAsset.SetRange("No.", FADepreciationBook."FA No.");
        FixedAssetBookValue02.SetTableView(FixedAsset);
        FixedAssetBookValue02.SetMandatoryFields(FADepreciationBook."Depreciation Book Code", WorkDate(), WorkDate());
        FixedAssetBookValue02.SetTotalFields(GroupTotals, PrintDetails, false, false);  // Using FALSE for Budget Report and Reclassify.
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

}
