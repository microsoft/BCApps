codeunit 144028 "ERM FA Derogatory Depreciation"
{
    // // [FEATURE] [Fixed Asset] [Derogatory]
    // 
    // Test for feature FADD - Fixed Asset Derogatory Depreciation.
    //  1. Verify values on Report Fixed Asset - Book Value 02 with No details.
    //  2. Verify values on Report Fixed Asset - Book Value 02 with FA Posting Group.
    //  3. Verify values on Report Fixed Asset - Book Value 02 with FA Posting Group and Print Details.
    //  4. Verify values on Report Fixed Asset - Book Value 02 with FA Posting Group, Print FA Setup and Print Details.
    //  5. Verify values on Report Fixed Asset - Book Value 01 with No details.
    //  6. Verify values on Report Fixed Asset - Book Value 01 with FA Posting Group.
    //  7. Verify values on Report Fixed Asset - Book Value 01 with FA Posting Group and Print Details.
    //  8. Verify values on Report Fixed Asset - Book Value 01 with FA Posting Group, Print FA Setup and Print Details.
    //  9. Verify values on Report Fixed Asset - Projected Value without Details.
    // 10. Verify values on Report Fixed Asset - Projected Value with FA Posting Group and Print Details.
    // 
    // Covers Test Cases for WI - 344095
    // ------------------------------------------------------------------------------------
    // Test Function Name                                                            TFS ID
    // ------------------------------------------------------------------------------------
    // FABookValue02ReportWithNoDetails                                              151349
    // FABookValue02ReportWithFAPostGroup                                            169597
    // FABookValue02ReportWithPrintDetails                                           169598
    // FABookValue02ReportWithPrintFASetup                                           199599
    // 
    // Covers Test Cases for WI - 344094
    // ------------------------------------------------------------------------------------
    // Test Function Name                                                            TFS ID
    // ------------------------------------------------------------------------------------
    // FABookValue01ReportWithNoDetails                                       169600,169634
    // FABookValue01ReportWithFAPostGroup                                     169594,155383
    // FABookValue01ReportWithPrintDetails                                    169595,155384
    // FABookValue01ReportWithPrintFASetup                                    169596,155385
    // 
    // Covers Test Cases for WI - 344093
    // ------------------------------------------------------------------------------------
    // Test Function Name                                                            TFS ID
    // ------------------------------------------------------------------------------------
    // FAProjectedValueReportWithNoDetails                                           169592
    // FAProjectedValueReportWithDetails                                             169593

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
#if not CLEAN28
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
#endif
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryReportValidation: Codeunit "Library - Report Validation";
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
    [Scope('OnPrem')]
    procedure FABookValue02ReportWithNoDetails()
    var
        FADepreciationBook: Record "FA Depreciation Book";
        FALedgerEntry: Record "FA Ledger Entry";
        GroupTotals: Option " ","FA Class","FA Subclass","FA Location","Main Asset","Global Dimension 1","Global Dimension 2","FA Posting Group";
    begin
        // Verify values on Report Fixed Asset - Book Value 02 with No details.

        // Setup: Create Fixed Asset Depreciation Book, create and post FA General Journal Line with Acquisition Cost and Derogatory.
        CreateFADepreciationBookAndPostFAGLJournal(FADepreciationBook);

        // Exercise.
        RunReportFABookValue02(FADepreciationBook, GroupTotals::" ", false);  // Opens FixedAssetBookValue02RequestPageHandler, FALSE for Print Details .

        // Verify: Verify values on Report - Fixed Asset - Book Value 02 with No details.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('HeadLineText10', Format(FALedgerEntry."FA Posting Type"::Derogatory));
        LibraryReportDataset.AssertElementWithValueExists(
          'TotalEndingAmt7', FALedgerEntryAmount(FADepreciationBook."FA No.", FALedgerEntry."FA Posting Type"::Derogatory));
    end;

    [Test]
    [HandlerFunctions('FixedAssetBookValue02RequestPageHandler')]
    [Scope('OnPrem')]
    procedure FABookValue02ReportWithFAPostGroup()
    var
        FADepreciationBook: Record "FA Depreciation Book";
        FALedgerEntry: Record "FA Ledger Entry";
        GroupTotals: Option " ","FA Class","FA Subclass","FA Location","Main Asset","Global Dimension 1","Global Dimension 2","FA Posting Group";
    begin
        // Verify values on Report Fixed Asset - Book Value 02 with FA Posting Group.

        // Setup: Create Fixed Asset Depreciation Book, create and post FA General Journal Line with Acquisition Cost and Derogatory.
        CreateFADepreciationBookAndPostFAGLJournal(FADepreciationBook);

        // Exercise.
        RunReportFABookValue02(FADepreciationBook, GroupTotals::"FA Posting Group", false);  // Opens FixedAssetBookValue02RequestPageHandler, FALSE for Print Details.

        // Verify: Verify values on Report - Fixed Asset - Book Value 02 with FA Posting Group.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(GroupTotalsCap, Format(GroupTotals::"FA Posting Group"));
        LibraryReportDataset.AssertElementWithValueExists(
          'GroupNetChangeAmt1', FALedgerEntryAmount(FADepreciationBook."FA No.", FALedgerEntry."FA Posting Type"::"Acquisition Cost"));
    end;

    [Test]
    [HandlerFunctions('FixedAssetBookValue02RequestPageHandler')]
    [Scope('OnPrem')]
    procedure FABookValue02ReportWithPrintDetails()
    var
        FADepreciationBook: Record "FA Depreciation Book";
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        // Verify values on Report Fixed Asset - Book Value 02 with FA Posting Group and Print Details.

        // Setup: Create Fixed Asset Depreciation Book, create and post FA General Journal Line with Acquisition Cost and Derogatory.
        CreateFADepreciationBookAndPostFAGLJournal(FADepreciationBook);

        // Exercise: Run report with FA Posting Group and Print Details TRUE.
        RunReportFABookValue02(FADepreciationBook, LibraryRandom.RandIntInRange(1, 7), true);  // Opens FixedAssetBookValue02RequestPageHandler, using Random value in range for GroupTotals and TRUE for Print Details.

        // Verify: Verify values on Report - Fixed Asset - Book Value 02 with FA Posting Group and Print Details.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(NoFixedAssetCap, FADepreciationBook."FA No.");
        LibraryReportDataset.AssertElementWithValueExists(
          NetChangeAmt1Cap, FALedgerEntryAmount(FADepreciationBook."FA No.", FALedgerEntry."FA Posting Type"::"Acquisition Cost"));
    end;

    [Test]
    [HandlerFunctions('PrintFASetupFixedAssetBookValue02RequestPageHandler')]
    [Scope('OnPrem')]
    procedure FABookValue02ReportWithPrintFASetup()
    var
        FADepreciationBook: Record "FA Depreciation Book";
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        // Verify values on Report Fixed Asset - Book Value 02 with FA Posting Group, Print FA Setup and Print Details.

        // Setup: Create Fixed Asset Depreciation Book, create and post FA General Journal Line with Acquisition Cost and Derogatory.
        CreateFADepreciationBookAndPostFAGLJournal(FADepreciationBook);

        // Exercise: Run report with FA Posting Group, Print Details TRUE and Print FA Setup TRUE in handler PrintFASetupFixedAssetBookValue02RequestPageHandler.
        RunReportFABookValue02(FADepreciationBook, LibraryRandom.RandIntInRange(1, 7), true);  // Using Random value in range for GroupTotals and TRUE for Print Details.

        // Verify: Verify values on Report - Fixed Asset - Book Value 02 with FA Posting Group, Print FA Setup and Print Details.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(DeprBookInfo1Cap, FADepreciationBook."Depreciation Book Code");
        LibraryReportDataset.AssertElementWithValueExists(DeprBookInfo2Cap, Format(FADepreciationBook."Depreciation Method"));
        LibraryReportDataset.AssertElementWithValueExists(
          NetChangeAmt1Cap, FALedgerEntryAmount(FADepreciationBook."FA No.", FALedgerEntry."FA Posting Type"::"Acquisition Cost"));
    end;

    [Test]
    [HandlerFunctions('FixedAssetBookValue01RequestPageHandler')]
    [Scope('OnPrem')]
    procedure FABookValue01ReportWithNoDetails()
    var
        FADepreciationBook: Record "FA Depreciation Book";
        FALedgerEntry: Record "FA Ledger Entry";
        GroupTotals: Option " ","FA Class","FA Subclass","FA Location","Main Asset","Global Dimension 1","Global Dimension 2","FA Posting Group";
    begin
        // Verify values on Report Fixed Asset - Book Value 01 with No details.

        // Setup: Create Fixed Asset Depreciation Book, create and post FA General Journal Line with Acquisition Cost and Derogatory.
        CreateFADepreciationBookAndPostFAGLJournal(FADepreciationBook);

        // Exercise.
        RunReportFABookValue01(FADepreciationBook, GroupTotals::" ", false);  // Opens FixedAssetBookValue01RequestPageHandler, FALSE for Print Details.

        // Verify: Verify values on Report - Fixed Asset - Book Value 01 with No details.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(
          'HeadLineText14', StrSubstNo('%1 %2', FADepreciationBook.FieldCaption(Derogatory), FADepreciationBook."Depreciation Starting Date"));
        LibraryReportDataset.AssertElementWithValueExists(
          'TotalEndingAmounts7', FALedgerEntryAmount(FADepreciationBook."FA No.", FALedgerEntry."FA Posting Type"::Derogatory));
    end;

    [Test]
    [HandlerFunctions('FixedAssetBookValue01RequestPageHandler')]
    [Scope('OnPrem')]
    procedure FABookValue01ReportWithFAPostGroup()
    var
        FADepreciationBook: Record "FA Depreciation Book";
        FALedgerEntry: Record "FA Ledger Entry";
        GroupTotals: Option " ","FA Class","FA Subclass","FA Location","Main Asset","Global Dimension 1","Global Dimension 2","FA Posting Group";
    begin
        // Verify values on Report Fixed Asset - Book Value 01 with FA Posting Group.

        // Setup: Create Fixed Asset Depreciation Book, create and post FA General Journal Line with Acquisition Cost and Derogatory.
        CreateFADepreciationBookAndPostFAGLJournal(FADepreciationBook);

        // Exercise.
        RunReportFABookValue01(FADepreciationBook, GroupTotals::"FA Posting Group", false);  // Opens FixedAssetBookValue01RequestPageHandler, FALSE for Print Details.

        // Verify: Verify values on Report - Fixed Asset - Book Value 01 with FA Posting Group.
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
    [Scope('OnPrem')]
    procedure FABookValue01ReportWithPrintDetails()
    var
        FADepreciationBook: Record "FA Depreciation Book";
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        // Verify values on Report Fixed Asset - Book Value 01 with FA Posting Group and Print Details.

        // Setup: Create Fixed Asset Depreciation Book, create and post FA General Journal Line with Acquisition Cost and Derogatory.
        CreateFADepreciationBookAndPostFAGLJournal(FADepreciationBook);

        // Exercise: Run report with FA Posting Group and Print Details TRUE.
        RunReportFABookValue01(FADepreciationBook, LibraryRandom.RandIntInRange(1, 7), true);  // Opens FixedAssetBookValue01RequestPageHandler, using Random value in range for GroupTotals and TRUE for Print Details.

        // Verify: Verify values on Report - Fixed Asset - Book Value 01 with FA Posting Group and Print Details.
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
    [Scope('OnPrem')]
    procedure FABookValue01ReportWithPrintFASetup()
    var
        FADepreciationBook: Record "FA Depreciation Book";
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        // Verify values on Report Fixed Asset - Book Value 01 with FA Posting Group, Print FA Setup and Print Details.

        // Setup: Create Fixed Asset Depreciation Book, create and post FA General Journal Line with Acquisition Cost and Derogatory.
        CreateFADepreciationBookAndPostFAGLJournal(FADepreciationBook);

        // Exercise: Run report with FA Posting Group, Print Details TRUE and Print FA Setup TRUE in handler PrintFASetupFixedAssetBookValue01RequestPageHandler.
        RunReportFABookValue01(FADepreciationBook, LibraryRandom.RandIntInRange(1, 7), true);  // Using Random value in range for GroupTotals and TRUE for Print Details.

        // Verify: Verify values on Report - Fixed Asset - Book Value 01 with FA Posting Group, Print FA Setup and Print Details.
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

#if not CLEAN28
    [Test]
    [HandlerFunctions('FAProjValueDerogRPH,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure FAProjectedValueReportWithNoDetails()
    var
        GroupTotals: Option " ","FA Class","FA Subclass","FA Location","Main Asset","Global Dimension 1","Global Dimension 2","FA Posting Group";
    begin
        // [SCENARIO] Report "Fixed Asset - Projected Value (Derogatory)" shows correct depreciation amounts when run with empty GroupTotals
        // [GIVEN] Fixed Asset. Post Acquisition Cost with amount = "A"
        // [WHEN] Run report "Fixed Asset - Projected Value (Derogatory)" with empty Group Totals option
        // [THEN] Report shows Depreciation Amount = "A"
        FAProjectedValueReport(GroupTotals::" ", false);  // FA Posting Group blank, Print Details FALSE.
    end;

    [Test]
    [HandlerFunctions('FAProjValueDerogRPH,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure FAProjectedValueReportWithDetails()
    begin
        // [SCENARIO] Report "Fixed Asset - Projected Value (Derogatory)" shows correct depreciation amounts when run with non-empty GroupTotals and Print Details=TRUE
        // [GIVEN] Fixed Asset. Post Acquisition Cost with amount = "A"
        // [WHEN] Run report "Fixed Asset - Projected Value (Derogatory)" with non-empty Group Totals and Print Details = TRUE
        // [THEN] Report shows Depreciation Amount = "A"
        FAProjectedValueReport(LibraryRandom.RandIntInRange(1, 7), true);  // Using Random value in range for GroupTotals and TRUE for Print Details.
    end;
#endif

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
        // [SCENARIO 578183] Fixed Asset Book Value - 01 report generates the derogatory value of previous month.
        // [GIVEN] Cretae two Depreciation Books.
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook[1]);
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook[2]);

        // [GIVEN] Create Fixed Asset wit FA Posting Group.
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);

        // [GIVEN] Create FA Depreciation Book and Validate "Depreciation Method", "No. of Depreciation Years", "Declining-Balance %".
        CreateFADepreciationBook(
            FADepreciationBook[1],
            FixedAsset."No.",
            FixedAsset."FA Posting Group",
            DepreciationBook[1].Code);
        FADepreciationBook[1].Validate("Depreciation Method", FADepreciationBook[1]."Depreciation Method"::"DB2/SL");
        FADepreciationBook[1].Validate("No. of Depreciation Years", LibraryRandom.RandDecInDecimalRange(0.41, 0.41, 2));
        FADepreciationBook[1].Validate("Declining-Balance %", LibraryRandom.RandIntInRange(20, 25));
        FADepreciationBook[1].Modify(true);

        // [GIVEN] Create FA Depreciation Book.
        CreateFADepreciationBook(FADepreciationBook[2], FixedAsset."No.", FixedAsset."FA Posting Group", DepreciationBook[2].Code);

        // [GIVEN] Create a Posting Date.
        PostingDate := CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate());

        // [GIVEN] Create and Post Acquisition Cost using FA Journal.
        CreateAndPostFAJournalLine(
            FixedAsset."No.",
            FAJournalLine."FA Posting Type"::"Acquisition Cost",
            DepreciationBook[1].Code,
            PostingDate);

        // [GIVEN] Create and Post Depreciation and Derogatory using FA Journal for two months.
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

        // [WHEN] Run Fixed Asset Book Value 01 Report
        // LibraryLowerPermissions.SetO365FAView();
        RunFixedAssetBookValue01Report1(
            FixedAsset,
            DepreciationBook[1].Code,
            GroupTotals::"FA Posting Group",
            false,
            false,
            CalcDate('<CM>', PostingDate) + 1);

        // [THEN] Derogatory of first period will have value.
        LibraryReportValidation.OpenFile();
        LibraryReportValidation.SetRange(StrSubstNo(GroupTotalsTxt, FixedAsset.FieldCaption("FA Posting Group")), GroupTotalTxt + ' ' + FixedAsset."FA Posting Group");
        LibraryReportValidation.CheckIfValueExists(
            StrSubstNo(
                '%1 %2',
                FADepreciationBook[1].FieldCaption(Derogatory),
                CalcDate('<CM>', PostingDate)));
    end;

#if not CLEAN28
    local procedure FAProjectedValueReport(GroupTotals: Option " ","FA Class","FA Subclass","FA Location","Main Asset","Global Dimension 1","Global Dimension 2","FA Posting Group"; PrintDetails: Boolean)
    var
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        // Setup: Create Fixed Asset Depreciation Book, create and post FA General Journal Line with Acquisition Cost and Derogatory.
        LibraryFiscalYear.CloseFiscalYear();
        LibraryFiscalYear.CreateFiscalYear();
        CreateFADepreciationBookAndPostFAGLJournal(FADepreciationBook);

        // Exercise.
        RunReportFAProjValueDerogatory(FADepreciationBook, GroupTotals, PrintDetails);

        // Verify: Verify values on Report "Fixed Asset - Projected Value (Derogatory)"
        VerifyFAProjectedValueReport(FADepreciationBook."FA No.");
    end;
#endif

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

    local procedure CreateDepreciationBook(): Code[10]
    var
        DepreciationBook: Record "Depreciation Book";
    begin
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        DepreciationBook.Validate("G/L Integration - Acq. Cost", true);
        DepreciationBook.Validate("G/L Integration - Depreciation", true);
        DepreciationBook.Validate("G/L Integration - Derogatory", true);
        DepreciationBook.Modify(true);
        exit(DepreciationBook.Code);
    end;

    local procedure CreateFADepreciationBook(var FADepreciationBook: Record "FA Depreciation Book")
    var
        FAPostingGroup: Record "FA Posting Group";
        FixedAsset: Record "Fixed Asset";
    begin
        FAPostingGroup.FindFirst();
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", CreateDepreciationBook());
        FADepreciationBook.Validate("FA Posting Group", FAPostingGroup.Code);
        FADepreciationBook.Validate("Depreciation Starting Date", WorkDate());
        FADepreciationBook.Validate("Depreciation Ending Date", WorkDate());
        FADepreciationBook.Modify(true);
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

#if not CLEAN28
    local procedure RunReportFAProjValueDerogatory(FADepreciationBook: Record "FA Depreciation Book"; GroupTotals: Option; PrintDetails: Boolean)
    var
        FixedAsset: Record "Fixed Asset";
        FAProjValueDerogatory: Report "FA - Proj. Value (Derogatory)";
    begin
        Clear(FAProjValueDerogatory);
        FixedAsset.SetRange("No.", FADepreciationBook."FA No.");
        FAProjValueDerogatory.SetTableView(FixedAsset);
        FAProjValueDerogatory.SetMandatoryFields(FADepreciationBook."Depreciation Book Code", WorkDate(), WorkDate());
        FAProjValueDerogatory.SetTotalFields(GroupTotals, PrintDetails);
        FAProjValueDerogatory.Run();
    end;

    local procedure VerifyFAProjectedValueReport(FANo: Code[20])
    var
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(
          'FixedAssetProjectedValueCaption', 'Fixed Asset - Projected Value (Derogatory)');
        LibraryReportDataset.AssertElementWithValueExists(
          'DeprAmount', -FALedgerEntryAmount(FANo, FALedgerEntry."FA Posting Type"::"Acquisition Cost"));
        LibraryReportDataset.AssertElementWithValueExists(
          'AssetAmounts1', -FALedgerEntryAmount(FANo, FALedgerEntry."FA Posting Type"::"Acquisition Cost"));
    end;
#endif

    local procedure CreateFADepreciationBook(var FADepreciationBook: Record "FA Depreciation Book"; FANo: Code[20]; FAPostingGroup: Code[20]; DepreciationBookCode: Code[10])
    begin
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FANo, DepreciationBookCode);
        FADepreciationBook.Validate("FA Posting Group", FAPostingGroup);
        FADepreciationBook.Validate("Depreciation Starting Date", WorkDate());
        FADepreciationBook.Validate("Depreciation Ending Date", CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'Y>', WorkDate()));
        FADepreciationBook.Modify(true);
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

    local procedure CreateAndPostFAJournalLine(FANo: Code[20]; FAPostingType: Enum "FA Journal Line FA Posting Type"; DepreciationBookCode: Code[10]; PostingDate: Date) FAJournalLineAmount: Decimal
    var
        FAJournalLine: Record "FA Journal Line";
    begin
        CreateFAJournalLine(FAJournalLine, FANo, DepreciationBookCode, FAPostingType, PostingDate);
        FAJournalLineAmount := FAJournalLine.Amount;
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);
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

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure FixedAssetBookValue02RequestPageHandler(var FixedAssetBookValue02: TestRequestPage "Fixed Asset - Book Value 02")
    begin
        FixedAssetBookValue02.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PrintFASetupFixedAssetBookValue02RequestPageHandler(var FixedAssetBookValue02: TestRequestPage "Fixed Asset - Book Value 02")
    begin
        FixedAssetBookValue02.PrintFASetup.SetValue(true);
        FixedAssetBookValue02.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure FixedAssetBookValue01RequestPageHandler(var FixedAssetBookValue01: TestRequestPage "Fixed Asset - Book Value 01")
    begin
        FixedAssetBookValue01.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PrintFASetupFixedAssetBookValue01RequestPageHandler(var FixedAssetBookValue01: TestRequestPage "Fixed Asset - Book Value 01")
    begin
        FixedAssetBookValue01.PrintFASetup.SetValue(true);
        FixedAssetBookValue01.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

#if not CLEAN28
    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure FAProjValueDerogRPH(var FAProjValueDerogatory: TestRequestPage "FA - Proj. Value (Derogatory)")
    begin
        FAProjValueDerogatory.UseAccountingPeriod.SetValue(true);
        FAProjValueDerogatory.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
#endif

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

