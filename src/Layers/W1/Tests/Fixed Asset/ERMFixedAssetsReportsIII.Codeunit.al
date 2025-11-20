codeunit 134990 "ERM Fixed Assets Reports - III"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Fixed Asset] [Report]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        AccNoFAPostGrpBuffer1Caption: Label 'AccNo_FAPostGrpBuffer1';
        AmtFAPostGroupBuffer1Caption: Label 'Amt_FAPostGroupBuffer1';
        AccNoFAPostGrpBuffer2Caption: Label 'AccNo_FAPostGrpBuffer2';
        Amounts1Caption: Label 'Amounts1';
        Amounts2Caption: Label 'Amounts2';
        AmountCaption: Label 'Maintenance_Ledger_Entry_Amount';
        Amounts3Caption: Label 'Amounts3';
        DateErr: Label 'You must specify the Starting Date and the Ending Date.';
        DateErr2: Label 'You must specify the starting date and the ending date';
        EndingDateErr: Label 'You must specify an Ending Date.';
        FaDeprBookAcquDateCaption: Label 'FaDeprBookAcquDate';
        FANoCaption: Label 'FANo';
        FixedAssetFilter: Label '%1|%2', Locked = true;
        FieldError: Label '%1 must be specified.';
        FieldError2: Label '%1 is not different than %2.';
        FieldError3: Label '%1 %2 %3 does not exist.', Comment = '%1=Table name,%2=Field value,%3=Field value';
        FieldError4: Label '%1 must not be specified when %2 is specified.';
        FormatString: Label '<Precision,2><Standard Format,0>', Locked = true;
        GLAccNetChangeCaption: Label 'GLAccNetChange';
        MaintenanceCodeCaption: Label 'Maintenance_Ledger_Entry__Maintenance_Code_';
        NoFACaption: Label 'No_FA';
        NoFixedAssetCaption: Label 'No_FixedAsset';
        PageGroupNoCaption: Label 'PageGroupNo';
        ReverseEntryMessage: Label 'To reverse these entries, correcting entries will be posted.';
        RowNotFound: Label 'There is not dataset row corresponding to Element Name %1 with value %2';
        StartingDateError: Label 'You must specify a Starting Date.';
        SuccessfulReversedMessage: Label 'The entries were successfully reversed.';
        FALedgEntryAmountCap: Label 'Amt_FALedgEntry';
        FALedgEntryDocNoCap: Label 'DocNo_FALedgEntry';
        MaintLedgEntryAmountCap: Label 'Amt_MaintLedgEntry';
        MaintLedgEntryDocNoCap: Label 'DocNo_MaintLedgEntry';
        InsCoverageLedgEntryAmountCap: Label 'Amt_InsCoverageLedgEntry';
        InsCoverageLedgEntryDocNoCap: Label 'DocNo_InsCoverageLedgEntry';
        TableNameCap: Label 'DocEntryTableName';
        NoOfRecordsCap: Label 'DocEntryNoofRecords';
        LibraryDimension: Codeunit "Library - Dimension";
        IsInitialized: Boolean;

    [Test]
    [HandlerFunctions('RHFixedAssetJournalTest')]
    [Scope('OnPrem')]
    procedure FixedAssetJournalTestWarning()
    var
        FAJournalLine: Record "FA Journal Line";
        FAJournalBatch: Record "FA Journal Batch";
        FixedAssetJournalTest: Report "Fixed Asset Journal - Test";
    begin
        // Check Fixed Asset Journal Test Report with Different Types of Warning Message.

        // Setup: Create FA Journal Line with Modification of Some fields.
        Initialize();
        SelectFAJournalBatch(FAJournalBatch);
        LibraryFixedAsset.CreateFAJournalLine(FAJournalLine, FAJournalBatch."Journal Template Name", FAJournalBatch.Name);
        ModifyFAJournalLine(FAJournalLine);

        // Exercise: Run and Save Fixed Asset Journal Test Report.
        Clear(FixedAssetJournalTest);
        FixedAssetJournalTest.SetTableView(FAJournalBatch);
        Commit();
        FixedAssetJournalTest.Run();

        // Verify: Verify different warnings on Fixed Asset Journal Test Report.
        VerifyFAJournalTestReportWarning(FAJournalLine);
    end;

    [Test]
    [HandlerFunctions('RHInsuranceJournalTest')]
    [Scope('OnPrem')]
    procedure InsuranceJournalTestWarning()
    var
        InsuranceJournalLine: Record "Insurance Journal Line";
        InsuranceJournalBatch: Record "Insurance Journal Batch";
        InsuranceJournalTest: Report "Insurance Journal - Test";
    begin
        // Check Insurance Journal Test Report with Different Types of Warning Message.

        // Setup: Create Insurance Journal Line with Modification of Some fields.
        Initialize();
        SelectInsuranceJournalBatch(InsuranceJournalBatch);
        LibraryFixedAsset.CreateInsuranceJournalLine(
          InsuranceJournalLine, InsuranceJournalBatch."Journal Template Name", InsuranceJournalBatch.Name);
        ModifyInsuranceJournalLine(InsuranceJournalLine, 0D, '', '');  // Take 0D for Blank Posting Date and Blank value for Document No. and Fixed Asset No.

        // Exercise: Run and Save Fixed Asset Journal Test Report.
        Clear(InsuranceJournalTest);
        InsuranceJournalTest.SetTableView(InsuranceJournalBatch);
        Commit();
        InsuranceJournalTest.Run();

        // Verify: Verify different warnings on Insurance Journal Test Report.
        VerifyInsuranceJournalTestReportWarning(InsuranceJournalLine);
    end;

    [Test]
    [HandlerFunctions('RHFixedAssetBookValue02Report')]
    [Scope('OnPrem')]
    procedure FABookValue02WithCustomSections()
    var
        FixedAsset: Record "Fixed Asset";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        AcquisitionCost: Decimal;
    begin
        // Verify Program populate value on Custom 1 and Custom 2 section on FA Book Value 02 Report after posting the FA G/L Journal.

        // 1. Setup: Create and Post FA GL Journal for Custom 1 and Custom 2.
        Initialize();
        AcquisitionCost := CreateFixedAssetWithAcquisitionCost(FixedAsset);
        CreateGeneralJournalBatch(GenJournalBatch);

        // Taking Custom 1 value less than Acquisition Cost.
        CreateFAGLJournalLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          FixedAsset."No.", GenJournalLine."FA Posting Type"::"Custom 1", -AcquisitionCost / 2);
        CreateFAGLJournalLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, FixedAsset."No.",
          GenJournalLine."FA Posting Type"::"Custom 2", GenJournalLine.Amount / 2);  // Taking Custom 2 value different from Custom 1 value.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 2. Exercise: Run Fixed Asset Book Value 02 Report.
        RunFixedAssetBookValue02Report(FixedAsset."No.");

        // 3. Verify: Verify Custom 1 and Custom 2 values on Fixed Asset Book Value 02 Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('NetChangeAmt5', -AcquisitionCost / 2);
        LibraryReportDataset.AssertElementWithValueExists('NetChangeAmt6', GenJournalLine.Amount);
        LibraryFixedAsset.VerifyLastFARegisterGLRegisterOneToOneRelation(); // TFS 376879
    end;

    [Test]
    [HandlerFunctions('FAPostingTypesOvervMatrixPageHandler')]
    [Scope('OnPrem')]
    procedure FAPostingTypesOverviewMatrix()
    var
        FixedAsset: Record "Fixed Asset";
        FAPostingTypesOverview: TestPage "FA Posting Types Overview";
        AcquisitionCost: Decimal;
    begin
        // Verify amounts are displayed as per the Date Filter applied in the FA Posting Types Overview Matrix.

        // Setup: Create and Post FA GL Journal for Acquisition Cost.
        Initialize();
        AcquisitionCost := CreateFixedAssetWithAcquisitionCost(FixedAsset);

        // Enqueue values for FAPostingTypesOvervMatrixPageHandler.
        LibraryVariableStorage.Enqueue(FixedAsset."No.");
        LibraryVariableStorage.Enqueue(AcquisitionCost);
        FAPostingTypesOverview.OpenView();
        FAPostingTypesOverview.FILTER.SetFilter("FA Posting Date Filter", Format(WorkDate()));

        // Exercise: Open FA Posting Types Overview Matrix page.
        FAPostingTypesOverview.ShowMatrix.Invoke();

        // Verify: Verification done in FAPostingTypesOvervMatrixPageHandler.
    end;

    [Test]
    [HandlerFunctions('FixedAssetAcquisitionListHandler')]
    [Scope('OnPrem')]
    procedure FAAcquisitionListReportStartingDateError()
    begin
        // Verify error on Fixed Asset Acquisition List Report for blank Starting date.
        FAAcquisitionListReportDateError(0D, 0D, StartingDateError);  // 0D for Starting Date and Ending Date.
    end;

    [Test]
    [HandlerFunctions('FixedAssetAcquisitionListHandler')]
    [Scope('OnPrem')]
    procedure FAAcquisitionListReportEndingDateError()
    begin
        // Verify error on Fixed Asset Acquisition List Report for blank Ending date.
        FAAcquisitionListReportDateError(WorkDate(), 0D, EndingDateErr);  // 0D for Ending Date.
    end;

    local procedure FAAcquisitionListReportDateError(StartingDate: Date; EndingDate: Date; ExpectedError: Text[50])
    begin
        // Setup: Enqueue values for FixedAssetAcquisitionListHandler.
        Initialize();
        EnqueueValuesForForFixedAssetReport('', StartingDate, EndingDate, false);  // '' for Fixed Asset No and FALSE for FixedAssetsAcquired.

        // Exercise.
        asserterror REPORT.Run(REPORT::"Fixed Asset - Acquisition List");

        // Verify: Verify error on Fixed Asset Acquisition List Report for blank date.
        Assert.ExpectedError(ExpectedError);
    end;

    [Test]
    [HandlerFunctions('FixedAssetAcquisitionListHandler')]
    [Scope('OnPrem')]
    procedure FAAcquisitionListReportForFANotAcquired()
    var
        FixedAsset: Record "Fixed Asset";
    begin
        // Verify Fixed Asset Acquisition List Report for Fixed Asset not yet Acquired.

        // Setup: Create Fixed Asset.
        Initialize();
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        EnqueueValuesForForFixedAssetReport(FixedAsset."No.", WorkDate(), WorkDate(), true);  // TRUE for FixedAssetsAcquired.
        Commit();  // Commit required for running report.

        // Exercise:
        REPORT.Run(REPORT::"Fixed Asset - Acquisition List");

        // Verify: Verify Fixed Asset No. on Fixed Asset Acquisition List Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(NoFixedAssetCaption, FixedAsset."No.");
    end;

    [Test]
    [HandlerFunctions('FixedAssetAcquisitionListHandler')]
    [Scope('OnPrem')]
    procedure FAAcquisitionListReportForFAAcquired()
    var
        FixedAsset: Record "Fixed Asset";
    begin
        // Verify Fixed Asset Acquisition List Report for Acquired Fixed Asset.

        // Setup: Create Fixed Asset with Acquisition.
        Initialize();
        CreateFixedAssetWithAcquisitionCost(FixedAsset);
        EnqueueValuesForForFixedAssetReport(FixedAsset."No.", WorkDate(), WorkDate(), false);  // FALSE for FixedAssetsAcquired.
        Commit();  // Commit required for running report.

        // Exercise.
        REPORT.Run(REPORT::"Fixed Asset - Acquisition List");

        // Verify: Verify Acquisition Date on Fixed Asset Acquisition List Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange(NoFixedAssetCaption, FixedAsset."No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals(FaDeprBookAcquDateCaption, Format(WorkDate()));
    end;

    [Test]
    [HandlerFunctions('FAPostingGroupNetChangeHandler')]
    [Scope('OnPrem')]
    procedure FAPostingGroupNetChangeReportDateError()
    begin
        // Verify error on 'Fixed Asset Posting Group Net Change' report for blank Starting date and ending date.

        // Setup:
        Initialize();
        EnqueueValuesForForFixedAssetReport('', 0D, 0D, false);  // 0D for starting Date and Ending Date, '' for Fixed Asset No., FALSE for TotalPerGLAccount.

        // Exercise:
        asserterror REPORT.Run(REPORT::"FA Posting Group - Net Change");

        // Verify: Verify error on 'Fixed Asset Posting Group Net Change' report for blank Starting date and ending date.
        Assert.ExpectedError(DateErr);
    end;

    [Test]
    [HandlerFunctions('FAPostingGroupNetChangeHandler')]
    [Scope('OnPrem')]
    procedure FAPostingGroupNetChangeReportGLAccFalse()
    var
        FixedAsset: Record "Fixed Asset";
        FAPostingGroup: Record "FA Posting Group";
        AcquisitionCost: Decimal;
    begin
        // Verify 'Fixed Asset Posting Group Net Change' report for Acquired Fixed Asset.

        // Setup: Create Fixed Asset with Acquisition.
        Initialize();
        AcquisitionCost := CreateFixedAssetWithAcquisitionCost(FixedAsset);
        EnqueueValuesForForFixedAssetReport(FixedAsset."No.", WorkDate(), WorkDate(), false);  // FALSE for FixedAssetsAcquired.

        // Exercise.
        REPORT.Run(REPORT::"FA Posting Group - Net Change");

        // Verify: Verify Acquisition Cost Amount on 'Fixed Asset Posting Group Net Change'.
        FAPostingGroup.Get(FixedAsset."FA Posting Group");
        LibraryReportDataset.LoadDataSetFile();
        VerifyFixedAssetReport(
          AccNoFAPostGrpBuffer1Caption, FAPostingGroup."Acquisition Cost Account",
          AmtFAPostGroupBuffer1Caption, AcquisitionCost);
    end;

    [Test]
    [HandlerFunctions('FAPostingGroupNetChangeHandler')]
    [Scope('OnPrem')]
    procedure FAPostingGroupNetChangeReportGLAccTrue()
    var
        FixedAsset: Record "Fixed Asset";
        GenJournalLine: Record "Gen. Journal Line";
        FAPostingGroup: Record "FA Posting Group";
    begin
        // Verify 'Fixed Asset Posting Group Net Change' report for Acquired Fixed Asset with Totals as per G/L Account TRUE.

        // Setup: Create Fixed Asset and post its Acquisition and depreciation.
        Initialize();
        CreateFixedAssetWithAcquisitionCost(FixedAsset);
        EnqueueValuesForForFixedAssetReport(FixedAsset."No.", WorkDate(), WorkDate(), true);  // TRUE for FixedAssetsAcquired.
        CreateAndPostFAJournalLine(
          FixedAsset."No.", GenJournalLine."FA Posting Type"::Depreciation, '', -LibraryRandom.RandDec(5, 2));

        // Exercise.
        REPORT.Run(REPORT::"FA Posting Group - Net Change");

        // Verify: Verify Net Change in Acquisition Cost Amount and Accumulated Depreciation Amount.
        FAPostingGroup.Get(FixedAsset."FA Posting Group");
        LibraryReportDataset.LoadDataSetFile();
        VerifyFixedAssetReport(
          AccNoFAPostGrpBuffer2Caption, FAPostingGroup."Accum. Depreciation Account",
          GLAccNetChangeCaption, CalculateAmount(FAPostingGroup."Accum. Depreciation Account"));
        VerifyFixedAssetReport(
          AccNoFAPostGrpBuffer2Caption, FAPostingGroup."Acquisition Cost Account",
          GLAccNetChangeCaption, CalculateAmount(FAPostingGroup."Acquisition Cost Account"));
    end;

    [Test]
    [HandlerFunctions('FixedAssetListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure FixedAssetListReportDeprCodeError()
    begin
        // Verify error on Fixed Asset List report for blank Depreciation Book Code.

        // Setup.
        Initialize();
        EnqueueValuesForFixedAssetListReport('', false, '');  // '' for Depreciation Book Code and Fixed Asset No., FALSE for New Page Per Asset.

        // Exercise.
        asserterror REPORT.Run(REPORT::"Fixed Asset - List");

        // Verify: Verify error on Fixed Asset List report for blank Depreciation Book Code.
        Assert.ExpectedErrorCannotFind(Database::"Depreciation Book");
    end;

    [Test]
    [HandlerFunctions('FixedAssetListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure FAListReportNewPagePerAssetFalse()
    var
        FixedAsset: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        // Verify Fixed Asset List report with New Page per Asset FALSE.

        // Setup: Create Fixed Asset, create FA Depreciation Book.
        Initialize();
        CreateAndModifyFixedAsset(FixedAsset);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", LibraryFixedAsset.GetDefaultDeprBook());
        EnqueueValuesForFixedAssetListReport(FADepreciationBook."Depreciation Book Code", false, FixedAsset."No.");  // FALSE for New Page Per Asset.
        Commit();  // Commit required for running report.

        // Exercise.
        REPORT.Run(REPORT::"Fixed Asset - List");

        // Verify: Verify Fixed Asset No. on Fixed Asset report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(FANoCaption, FADepreciationBook."FA No.");
    end;

    [Test]
    [HandlerFunctions('FixedAssetListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure FAListReportNewPagePerAssetTrue()
    var
        FixedAsset: Record "Fixed Asset";
        FixedAsset2: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        // Verify Fixed Asset List report with New Page per Asset TRUE.

        // Setup: Create Fixed Asset, create FA Depreciation Book.
        Initialize();
        CreateAndModifyFixedAsset(FixedAsset);
        CreateAndModifyFixedAsset(FixedAsset2);
        CreateFADepreciationBook(
          FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", LibraryFixedAsset.GetDefaultDeprBook());
        CreateFADepreciationBook(
          FADepreciationBook, FixedAsset2."No.", FixedAsset2."FA Posting Group", LibraryFixedAsset.GetDefaultDeprBook());
        EnqueueValuesForFixedAssetListReport(
          FADepreciationBook."Depreciation Book Code", true,
          StrSubstNo(FixedAssetFilter, FixedAsset."No.", FixedAsset2."No."));  // TRUE for New Page Per Asset.
        FixedAsset.SetRange("No.", FixedAsset."No.", FixedAsset2."No.");
        Commit();  // Commit required for running report.

        // Exercise.
        REPORT.Run(REPORT::"Fixed Asset - List");

        // Verify: Verify two fixed Asset printed on two different pages when 'New Page per Asset' TRUE on Fixed Asset report.
        LibraryReportDataset.LoadDataSetFile();
        VerifyFixedAssetReport(FANoCaption, FixedAsset."No.", PageGroupNoCaption, FixedAsset.Count);
        VerifyFixedAssetReport(FANoCaption, FixedAsset2."No.", PageGroupNoCaption, FixedAsset.Count + 1);  // Adding 1 for next page Group No.
    end;

    [Test]
    [HandlerFunctions('MaintenanceAnalysisRequestPageHandler')]
    [Scope('OnPrem')]
    procedure MaintenanceAnalysisDeprCodeError()
    begin
        // Verify error on Maintenance Analysis report for blank Depreciation Book Code.

        // Setup:
        Initialize();
        EnqueueValuesForMaintenanceAnalysisReport('', 0D, 0D, '');  // '' for Depreciation Book code, maintenance code, 0D for Starting Date and Ending date.
        Commit();  // Commit required for running report.

        // Exercise.
        asserterror REPORT.Run(REPORT::"Maintenance - Analysis");

        // Verify: Verify error on Maintenance Analysis report for blank Depreciation Book Code.
        Assert.ExpectedErrorCannotFind(Database::"Depreciation Book");
    end;

    [Test]
    [HandlerFunctions('MaintenanceAnalysisRequestPageHandler')]
    [Scope('OnPrem')]
    procedure MaintenanceAnalysisDateError()
    var
        DepreciationBook: Record "Depreciation Book";
    begin
        // Verify error on Maintenance Analysis report for blank Starting Date.

        // Setup:
        Initialize();
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        EnqueueValuesForMaintenanceAnalysisReport(DepreciationBook.Code, 0D, 0D, '');  // '' for Maintenance code.
        Commit();  // Commit required for running report.

        // Exercise.
        asserterror REPORT.Run(REPORT::"Maintenance - Analysis");

        // Verify: Verify error on Maintenance Analysis report for blank Starting Date.
        Assert.ExpectedError(DateErr2);
    end;

    [Test]
    [HandlerFunctions('MaintenanceAnalysisRequestPageHandler')]
    [Scope('OnPrem')]
    procedure MaintenanceAnalysisReportForFAAcquired()
    var
        FixedAsset: Record "Fixed Asset";
        GenJournalLine: Record "Gen. Journal Line";
        Maintenance: Record Maintenance;
        FADepreciationBook: Record "FA Depreciation Book";
        Amount: Decimal;
    begin
        // Verify Maintenance Analysis report for Fixed Asset after posting its Acquisition and Maintenance.

        // Setup:
        Initialize();
        CreateFixedAssetWithAcquisitionCost(FixedAsset);
        LibraryFixedAsset.CreateMaintenance(Maintenance);
        Amount := LibraryRandom.RandDec(100, 2);  // Take random Amount.
        CreateAndPostFAJournalLine(FixedAsset."No.", GenJournalLine."FA Posting Type"::Maintenance, Maintenance.Code, Amount);
        FADepreciationBook.SetRange("FA No.", FixedAsset."No.");
        FADepreciationBook.FindFirst();
        EnqueueValuesForMaintenanceAnalysisReport(FADepreciationBook."Depreciation Book Code", WorkDate(), WorkDate(), Maintenance.Code);
        Commit();  // Commit required for running report.

        // Exercise.
        REPORT.Run(REPORT::"Maintenance - Analysis");

        // Verify: Verify Fixed Asset No and Maintenance amount on Maintenance Analysis report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(NoFACaption, FixedAsset."No.");
        LibraryReportDataset.AssertElementWithValueExists(Amounts1Caption, Amount);
        LibraryReportDataset.AssertElementWithValueExists(Amounts2Caption, 0);
        LibraryReportDataset.AssertElementWithValueExists(Amounts3Caption, Amount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,MaintenanceDetailsRequestPagetHandler')]
    [Scope('OnPrem')]
    procedure MaintenanceDetailExcludeReversedEntries()
    var
        Maintenance: Record Maintenance;
        AcquisitionCost: Decimal;
    begin
        // Verify Report Maintenance - Detail exclude Reversed entries.

        // Setup: Create and Post FA GL Journal for Acquisition Cost. Post Maintenance Entries. Reverse Maintenance Ledger Entries.
        Initialize();
        LibraryFixedAsset.CreateMaintenance(Maintenance);
        AcquisitionCost := CreatePostMaintenanceEntryAndReverse(Maintenance.Code, false);

        // Exercise: Run Maintenance - Detail Report excluding Reversed entries.
        REPORT.Run(REPORT::"Maintenance - Details");

        // Verify: Verify Amount for Maintenance Entry.
        LibraryReportDataset.LoadDataSetFile();
        VerifyMaintenanceDetailReport(Maintenance.Code, Round(AcquisitionCost / 2));  // Devide by 2 since Maintenance Cost is half of Acquisition Cost.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,MaintenanceDetailsRequestPagetHandler')]
    [Scope('OnPrem')]
    procedure MaintenanceDetailIncludeReversedEntries()
    var
        Maintenance: Record Maintenance;
        AcquisitionCost: Decimal;
    begin
        // Verify Report Maintenance - Detail include Reversed entries.

        // Setup: Create and Post FA GL Journal for Acquisition Cost. Post Maintenance Entries. Reverse Maintenance Ledger Entries.
        Initialize();
        LibraryFixedAsset.CreateMaintenance(Maintenance);
        AcquisitionCost := CreatePostMaintenanceEntryAndReverse(Maintenance.Code, true);

        // Exercise: Run Maintenance - Detail Report including Reversed entries.
        REPORT.Run(REPORT::"Maintenance - Details");

        // Verify: Verify Amounts for Maintenance and Reversed Entries.
        LibraryReportDataset.LoadDataSetFile();
        VerifyMaintenanceDetailReport(Maintenance.Code, Round(AcquisitionCost / 2));  // Devide by 2 since Maintenance Cost is half of Acquisition Cost.
        LibraryReportDataset.Reset();
        VerifyMaintenanceDetailReport('', Round(AcquisitionCost / 2));  // Devide by 2 since Maintenance Cost is half of Acquisition Cost.
        LibraryReportDataset.AssertElementWithValueExists(AmountCaption, -Round(AcquisitionCost / 2));
    end;

    [Test]
    [HandlerFunctions('DocumentEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DocumentEntriesForFALedgerEntry()
    var
        FixedAsset: Record "Fixed Asset";
        FALedgerEntry: Record "FA Ledger Entry";
        TempDocumentEntry: Record "Document Entry" temporary;
        DocumentEntries: Report "Document Entries";
        FALedgerEntries: TestPage "FA Ledger Entries";
    begin
        // Verify Document Entries Report for FA Ledger Entry.

        // Setup: Create Fixed Asset and post Acquisition Cost for It.
        Initialize();
        CreateFixedAssetWithAcquisitionCost(FixedAsset);
        FALedgerEntries.OpenView();
        FALedgerEntries.FILTER.SetFilter("FA No.", FixedAsset."No.");

        // Exercise: Run Document Entries Report as if from NavigatePage.
        FALedgerEntry.SetRange("FA No.", FixedAsset."No.");
        FALedgerEntry.FindFirst();
        CollectDocEntries(FALedgerEntry, TempDocumentEntry);
        DocumentEntries.TransferDocEntries(TempDocumentEntry);
        DocumentEntries.TransferFilters(FALedgerEntry."Document No.", Format(FALedgerEntry."Posting Date"));
        DocumentEntries.Run(); // SaveAxXML in DocumentEntriesRequestPageHandler

        // Verify: Verify FA Ledger Entry Table Name. no. of Records and Amount on Document Entries Report.
        LibraryReportDataset.LoadDataSetFile();
        FALedgerEntry.SetRange("FA No.", FixedAsset."No.");
        VerifyDocumentEntries(TableNameCap, FALedgerEntry.TableCaption(), NoOfRecordsCap, FALedgerEntry.Count);
        FALedgerEntry.FindFirst();
        VerifyDocumentEntries(FALedgEntryDocNoCap, FALedgerEntry."Document No.", FALedgEntryAmountCap, FALedgerEntry.Amount);
    end;

    [Test]
    [HandlerFunctions('DocumentEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DocumentEntriesForMaintenanceLedgerEntry()
    var
        FixedAsset: Record "Fixed Asset";
        GenJournalLine: Record "Gen. Journal Line";
        MaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        TempDocumentEntry: Record "Document Entry" temporary;
        DocumentEntries: Report "Document Entries";
        MaintenanceLedgerEntries: TestPage "Maintenance Ledger Entries";
    begin
        // Verify Document Entries Report for Maintenance Ledger Entry.

        // Setup: Create Fixed Asset and post Acquisition Cost and Maintenance Entry for It.
        Initialize();
        CreateFixedAssetWithAcquisitionCost(FixedAsset);
        CreateAndPostFAJournalLine(
          FixedAsset."No.", GenJournalLine."FA Posting Type"::Maintenance, '', LibraryRandom.RandDec(100, 2));  // Take Random Amount.
        MaintenanceLedgerEntries.OpenView();
        MaintenanceLedgerEntries.FILTER.SetFilter("FA No.", FixedAsset."No.");

        // Exercise: Run Document Entries Report as if from NavigatePage.
        MaintenanceLedgerEntry.SetRange("FA No.", FixedAsset."No.");
        MaintenanceLedgerEntry.FindFirst();
        CollectDocEntries(MaintenanceLedgerEntry, TempDocumentEntry);
        DocumentEntries.TransferDocEntries(TempDocumentEntry);
        DocumentEntries.TransferFilters(MaintenanceLedgerEntry."Document No.", Format(MaintenanceLedgerEntry."Posting Date"));
        DocumentEntries.Run(); // SaveAxXML in DocumentEntriesRequestPageHandler

        // Verify: Verify Maintenance Ledger Entry Table Name, no. of Records and Amount on Document Entries Report.
        LibraryReportDataset.LoadDataSetFile();
        MaintenanceLedgerEntry.SetRange("FA No.", FixedAsset."No.");
        VerifyDocumentEntries(TableNameCap, MaintenanceLedgerEntry.TableCaption(), NoOfRecordsCap, MaintenanceLedgerEntry.Count);
        MaintenanceLedgerEntry.FindFirst();
        VerifyDocumentEntries(
          MaintLedgEntryDocNoCap, MaintenanceLedgerEntry."Document No.", MaintLedgEntryAmountCap, MaintenanceLedgerEntry.Amount);
    end;

    [Test]
    [HandlerFunctions('DocumentEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DocumentEntriesForInsCoverageLedgerEntry()
    var
        FixedAsset: Record "Fixed Asset";
        InsuranceJournalBatch: Record "Insurance Journal Batch";
        InsuranceJournalLine: Record "Insurance Journal Line";
        InsCoverageLedgerEntry: Record "Ins. Coverage Ledger Entry";
        TempDocumentEntry: Record "Document Entry" temporary;
        DocumentEntries: Report "Document Entries";
        InsCoverageLedgerEntries: TestPage "Ins. Coverage Ledger Entries";
    begin
        // Verify Document Entries Report for Insurance Coverage Ledger Entry.

        // Setup: Create Fixed Asset and post Insurance for it.
        Initialize();
        CreateAndModifyFixedAsset(FixedAsset);
        ModifyInsuranceJournalBatch(InsuranceJournalBatch);
        LibraryFixedAsset.CreateInsuranceJournalLine(
          InsuranceJournalLine, InsuranceJournalBatch."Journal Template Name", InsuranceJournalBatch.Name);
        ModifyInsuranceJournalLine(InsuranceJournalLine, WorkDate(), LibraryUtility.GenerateGUID(), FixedAsset."No.");
        LibraryFixedAsset.PostInsuranceJournal(InsuranceJournalLine);
        InsCoverageLedgerEntries.OpenView();
        InsCoverageLedgerEntries.FILTER.SetFilter("FA No.", FixedAsset."No.");

        // Exercise: Run Document Entries Report as if from NavigatePage.
        InsCoverageLedgerEntry.SetRange("FA No.", FixedAsset."No.");
        InsCoverageLedgerEntry.FindFirst();
        CollectDocEntries(InsCoverageLedgerEntry, TempDocumentEntry);
        DocumentEntries.TransferDocEntries(TempDocumentEntry);
        DocumentEntries.TransferFilters(InsCoverageLedgerEntry."Document No.", Format(InsCoverageLedgerEntry."Posting Date"));
        DocumentEntries.Run(); // SaveAxXML in DocumentEntriesRequestPageHandler

        // Verify: Verify Ins. Coverage Ledger Entry Table Name, no. of Records and Amount on Document Entries Report.
        LibraryReportDataset.LoadDataSetFile();
        InsCoverageLedgerEntry.SetRange("FA No.", FixedAsset."No.");
        VerifyDocumentEntries(TableNameCap, InsCoverageLedgerEntry.TableCaption(), NoOfRecordsCap, InsCoverageLedgerEntry.Count);
        InsCoverageLedgerEntry.FindFirst();
        VerifyDocumentEntries(
          InsCoverageLedgEntryDocNoCap, InsCoverageLedgerEntry."Document No.",
          InsCoverageLedgEntryAmountCap, InsCoverageLedgerEntry.Amount);
    end;

    [Test]
    [HandlerFunctions('FixedAssetListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure FAListReportCheckGlobalDimensionCaption()
    var
        FixedAsset: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        Dimension: Record Dimension;
        FirstDimensionCodeCaption: Text[80];
    begin
        // [FEATURE] [Fixed Asset - List]
        // [SCENARIO 275371] Global Dimensions on report "Fixed Asset - List" have correct captions

        Initialize();

        // [GIVEN] Global Dimension 1 Caption = 'X', Global Dimension 2 Caption = 'Y'
        LibraryDimension.CreateDimension(Dimension);
        LibraryERM.SetGlobalDimensionCode(1, Dimension.Code);
        FirstDimensionCodeCaption := Dimension."Code Caption";
        LibraryDimension.CreateDimension(Dimension);
        LibraryERM.SetGlobalDimensionCode(2, Dimension.Code);

        // [GIVEN] Fixed Asset and FA Depreciation Book
        CreateAndModifyFixedAsset(FixedAsset);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", LibraryFixedAsset.GetDefaultDeprBook());
        EnqueueValuesForFixedAssetListReport(FADepreciationBook."Depreciation Book Code", false, FixedAsset."No.");
        Commit();

        // [WHEN] Run report "Fixed Asset - List"
        REPORT.Run(REPORT::"Fixed Asset - List");

        // [THEN] Element with Tag 'GlobalDim1CodeCaption' and value 'X' exists
        // [THEN] Element with Tag 'GlobalDim2CodeCaption' and value 'Y' exists
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementTagWithValueExists('GlobalDim1CodeCaption', FirstDimensionCodeCaption);
        LibraryReportDataset.AssertElementTagWithValueExists('GlobalDim2CodeCaption', Dimension."Code Caption");
    end;

    [Test]
    [HandlerFunctions('FixedAssetListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure FAListReportOnlyOneGlobalDimension()
    var
        FixedAsset: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        Dimension: Record Dimension;
        DimensionCode: Code[20];
    begin
        // [FEATURE] [Fixed Asset - List]
        // [SCENARIO 325988] "Fixed Asset - List" runs correctly with GeneralLedgerSetup."Global Dimension 2 Code" = ''
        Initialize();
        // [GIVEN] GeneralLedgerSetup."Global Dimension 2 Code" = ''
        DimensionCode := LibraryERM.GetGlobalDimensionCode(2);
        LibraryERM.SetGlobalDimensionCode(2, '');

        // [WHEN] Run "Fixed Asset - List" with some FA No. = "X"
        CreateAndModifyFixedAsset(FixedAsset);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", LibraryFixedAsset.GetDefaultDeprBook());
        EnqueueValuesForFixedAssetListReport(FADepreciationBook."Depreciation Book Code", false, FixedAsset."No.");
        Commit();
        REPORT.Run(REPORT::"Fixed Asset - List");

        // [THEN] Report terminates successfully and contains "X"
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(FANoCaption, FADepreciationBook."FA No.");
        Dimension.Get(LibraryERM.GetGlobalDimensionCode(1));
        LibraryReportDataset.AssertElementTagWithValueExists('GlobalDim1CodeCaption', Dimension."Code Caption");
        LibraryReportDataset.AssertElementTagWithValueExists('GlobalDim2CodeCaption', '');

        // tear down
        LibraryERM.SetGlobalDimensionCode(2, DimensionCode);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        Clear(LibraryReportDataset);
        LibraryVariableStorage.Clear();

        if IsInitialized then
            exit;

        LibraryERMCountryData.UpdateGeneralLedgerSetup();

        IsInitialized := true;
        Commit();
    end;

    local procedure CalculateAmount(GLAccountNo: Code[20]): Decimal
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.SetRange("No.", GLAccountNo);
        GLAccount.SetFilter("Date Filter", '%1', WorkDate());
        GLAccount.FindFirst();
        GLAccount.CalcFields("Net Change");
        exit(GLAccount."Net Change");
    end;

    local procedure CollectDocEntries(FALedgerEntry: Record "FA Ledger Entry"; var TempDocumentEntry: Record "Document Entry" temporary)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.Reset();
        GLEntry.SetCurrentKey("Document No.", "Posting Date");
        GLEntry.SetFilter("Document No.", FALedgerEntry."Document No.");
        GLEntry.SetRange("Posting Date", FALedgerEntry."Posting Date");
        TempDocumentEntry.InsertIntoDocEntry(DATABASE::"G/L Entry", GLEntry.TableCaption(), GLEntry.Count);
        FALedgerEntry.Reset();
        FALedgerEntry.SetCurrentKey("Document No.", "Posting Date");
        FALedgerEntry.SetFilter("Document No.", FALedgerEntry."Document No.");
        FALedgerEntry.SetRange("Posting Date", FALedgerEntry."Posting Date");
        TempDocumentEntry.InsertIntoDocEntry(DATABASE::"FA Ledger Entry", FALedgerEntry.TableCaption(), FALedgerEntry.Count);
    end;

    local procedure CollectDocEntries(MaintenanceLedgEntry: Record "Maintenance Ledger Entry"; var TempDocumentEntry: Record "Document Entry" temporary)
    begin
        MaintenanceLedgEntry.Reset();
        MaintenanceLedgEntry.SetCurrentKey("Document No.", "Posting Date");
        MaintenanceLedgEntry.SetFilter("Document No.", MaintenanceLedgEntry."Document No.");
        MaintenanceLedgEntry.SetRange("Posting Date", MaintenanceLedgEntry."Posting Date");
        TempDocumentEntry.InsertIntoDocEntry(DATABASE::"Maintenance Ledger Entry", MaintenanceLedgEntry.TableCaption(), MaintenanceLedgEntry.Count);
    end;

    local procedure CollectDocEntries(var InsCoverageLedgerEntry: Record "Ins. Coverage Ledger Entry"; var TempDocumentEntry: Record "Document Entry" temporary)
    begin
        InsCoverageLedgerEntry.Reset();
        InsCoverageLedgerEntry.SetCurrentKey("Document No.", "Posting Date");
        InsCoverageLedgerEntry.SetFilter("Document No.", InsCoverageLedgerEntry."Document No.");
        InsCoverageLedgerEntry.SetRange("Posting Date", InsCoverageLedgerEntry."Posting Date");
        TempDocumentEntry.InsertIntoDocEntry(DATABASE::"Ins. Coverage Ledger Entry", InsCoverageLedgerEntry.TableCaption(), InsCoverageLedgerEntry.Count);
    end;

    local procedure CreateAndPostFAJournalLine(FANo: Code[20]; FAPostingType: Enum "Gen. Journal Line FA Posting Type"; MaintenanceCode: Code[10]; Amount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGeneralJournalBatch(GenJournalBatch);
        CreateFAGLJournalLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, FANo, FAPostingType, Amount);
        GenJournalLine.Validate("Maintenance Code", MaintenanceCode);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreatePostMaintenanceEntryAndReverse(MaintenanceCode: Code[10]; IncludeReversedEntries: Boolean) AcquisitionCost: Decimal
    var
        GenJournalLine: Record "Gen. Journal Line";
        FixedAsset: Record "Fixed Asset";
    begin
        AcquisitionCost := CreateFixedAssetWithAcquisitionCost(FixedAsset);
        CreateAndPostFAJournalLine(FixedAsset."No.", GenJournalLine."FA Posting Type"::Maintenance, MaintenanceCode, AcquisitionCost / 2);  // Take Amount half of Acquisition Cost.
        CreateAndPostFAJournalLine(FixedAsset."No.", GenJournalLine."FA Posting Type"::Maintenance, '', AcquisitionCost / 2);  // Take Amount half of Acquisition Cost.

        // Enqueue values for Confirm and Message Handler.
        LibraryVariableStorage.Enqueue(ReverseEntryMessage);
        LibraryVariableStorage.Enqueue(SuccessfulReversedMessage);
        ReverseMaintenanceLedgerEntry(FixedAsset."No.");

        // Enqueue values for MaintenanceDetailsRequestPagetHandler.
        LibraryVariableStorage.Enqueue(FixedAsset."No.");
        LibraryVariableStorage.Enqueue(IncludeReversedEntries);
        Commit();  // Required to run Maintenance - Details report.
    end;

    local procedure CreateAndModifyFixedAsset(var FixedAsset: Record "Fixed Asset")
    begin
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        FixedAsset.Validate("FA Posting Group", ModifyFAPostingGroup());
        FixedAsset.Modify(true);
    end;

    local procedure CreateFixedAssetWithAcquisitionCost(var FixedAsset: Record "Fixed Asset") Amount: Decimal
    var
        FADepreciationBook: Record "FA Depreciation Book";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Create Fixed Asset, Post Acquisition Cost for it.
        CreateAndModifyFixedAsset(FixedAsset);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", LibraryFixedAsset.GetDefaultDeprBook());
        Amount := LibraryRandom.RandDec(100, 2);  // Taking Random value for Acqusition Cost.
        CreateAndPostFAJournalLine(FixedAsset."No.", GenJournalLine."FA Posting Type"::"Acquisition Cost", '', Amount);
    end;

    local procedure CreateFADepreciationBook(var FADepreciationBook: Record "FA Depreciation Book"; FANo: Code[20]; FAPostingGroup: Code[20]; DepreciationBookCode: Code[10])
    begin
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FANo, DepreciationBookCode);
        FADepreciationBook.Validate("FA Posting Group", FAPostingGroup);
        FADepreciationBook.Modify(true);
    end;

    local procedure CreateFAGLJournalLine(var GenJournalLine: Record "Gen. Journal Line"; JournalTemplateName: Code[10]; JournalTemplateBatch: Code[10]; FANo: Code[20]; FAPostingType: Enum "Gen. Journal Line FA Posting Type"; Amount: Decimal)
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, JournalTemplateName, JournalTemplateBatch, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"Fixed Asset", FANo, Amount);
        GLAccount.SetFilter("Gen. Posting Type", '<>%1', GLAccount."Gen. Posting Type"::" ");
        LibraryERM.FindGLAccount(GLAccount);
        GenJournalLine.Validate("FA Posting Type", FAPostingType);
        GenJournalLine.Validate("Bal. Account No.", GLAccount."No.");
        GenJournalLine.Modify(true);
    end;

    local procedure CreateGeneralJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Assets);
        GenJournalTemplate.SetRange(Recurring, false);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure EnqueueValuesForForFixedAssetReport(FixedAssetNo: Code[20]; StartingDate: Date; EndingDate: Date; FixedAssetsAcquired: Boolean)
    begin
        EnqueueValues(FixedAssetNo, StartingDate, EndingDate);
        LibraryVariableStorage.Enqueue(FixedAssetsAcquired);
    end;

    local procedure EnqueueValuesForFixedAssetListReport(DepreciationBookCode: Variant; NewPagePerAsset: Variant; FixedAssetFilter: Variant)
    begin
        LibraryVariableStorage.Enqueue(DepreciationBookCode);
        LibraryVariableStorage.Enqueue(NewPagePerAsset);
        LibraryVariableStorage.Enqueue(FixedAssetFilter);
    end;

    local procedure EnqueueValuesForMaintenanceAnalysisReport(DepreciationBookCode: Code[20]; StartingDate: Date; EndingDate: Date; MaintenanceCode: Code[10])
    begin
        EnqueueValues(DepreciationBookCode, StartingDate, EndingDate);
        LibraryVariableStorage.Enqueue(MaintenanceCode);
    end;

    local procedure EnqueueValues(No: Code[20]; StartingDate: Date; EndingDate: Date)
    begin
        LibraryVariableStorage.Enqueue(No);
        LibraryVariableStorage.Enqueue(StartingDate);
        LibraryVariableStorage.Enqueue(EndingDate);
    end;

    local procedure ModifyFAJournalLine(var FAJournalLine: Record "FA Journal Line")
    var
        FixedAsset: Record "Fixed Asset";
    begin
        // Take Random Values for Different fields.
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        FAJournalLine.Validate("FA Posting Date", 0D); // 0D for Blank Posting Date.
        FAJournalLine.Validate("Posting Date", 0D);
        FAJournalLine.Validate("Document No.", '');
        FAJournalLine.Validate("FA No.", FixedAsset."No.");
        FAJournalLine.Validate("FA Posting Type", FAJournalLine."FA Posting Type"::"Acquisition Cost");
        FAJournalLine.Validate("Depr. until FA Posting Date", true);
        FAJournalLine.Validate("Depr. Acquisition Cost", true);
        FAJournalLine.Validate("Salvage Value", LibraryRandom.RandDec(10, 1));
        FAJournalLine.Validate("FA Reclassification Entry", true);
        FAJournalLine.Validate("FA Error Entry No.", LibraryRandom.RandInt(10));
        FAJournalLine.Modify(true);
    end;

    local procedure ModifyInsuranceJournalBatch(var InsuranceJournalBatch: Record "Insurance Journal Batch")
    begin
        SelectInsuranceJournalBatch(InsuranceJournalBatch);
        InsuranceJournalBatch.Validate("No. Series", '');  // Modify No. Series with blank value.
        InsuranceJournalBatch.Modify(true);
    end;

    local procedure ModifyInsuranceJournalLine(var InsuranceJournalLine: Record "Insurance Journal Line"; PostingDate: Date; DocumentNo: Code[20]; FANo: Code[20])
    var
        Insurance: Record Insurance;
    begin
        LibraryFixedAsset.FindInsurance(Insurance);
        InsuranceJournalLine.Validate("Posting Date", PostingDate);
        InsuranceJournalLine.Validate("Document No.", DocumentNo);
        InsuranceJournalLine.Validate("Insurance No.", Insurance."No.");
        InsuranceJournalLine.Validate("FA No.", FANo);
        InsuranceJournalLine.Validate(Amount, LibraryRandom.RandDec(100, 2));  // Use Random Amount.
        InsuranceJournalLine.Modify(true);
    end;

    local procedure ModifyFAPostingGroup(): Code[20]
    var
        FAPostingGroup: Record "FA Posting Group";
    begin
        FAPostingGroup.FindFirst();
        FAPostingGroup.Validate("Custom 1 Account", LibraryERM.CreateGLAccountNo());
        FAPostingGroup.Validate("Custom 2 Account", LibraryERM.CreateGLAccountNo());
        FAPostingGroup.Modify(true);
        exit(FAPostingGroup.Code);
    end;

    local procedure ReverseMaintenanceLedgerEntry(FANo: Code[20])
    var
        MaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        ReversalEntry: Record "Reversal Entry";
    begin
        MaintenanceLedgerEntry.SetRange("FA No.", FANo);
        MaintenanceLedgerEntry.SetRange("Maintenance Code", '');
        MaintenanceLedgerEntry.FindFirst();
        ReversalEntry.SetHideDialog(true);
        ReversalEntry.ReverseTransaction(MaintenanceLedgerEntry."Transaction No.");
    end;

    local procedure RunFixedAssetBookValue02Report(No: Code[20])
    var
        FixedAsset: Record "Fixed Asset";
        FixedAssetBookValue02: Report "Fixed Asset - Book Value 02";
    begin
        Clear(FixedAssetBookValue02);
        FixedAsset.SetRange("No.", No);
        FixedAssetBookValue02.SetTableView(FixedAsset);
        FixedAssetBookValue02.SetMandatoryFields(LibraryFixedAsset.GetDefaultDeprBook(), WorkDate(), WorkDate());
        Commit();
        FixedAssetBookValue02.Run();
    end;

    local procedure SelectFAJournalBatch(var FAJournalBatch: Record "FA Journal Batch")
    var
        FAJournalTemplate: Record "FA Journal Template";
        FAJournalLine: Record "FA Journal Line";
    begin
        // Delete All FA General Line with Selected Batch.
        FAJournalTemplate.SetRange(Recurring, false);
        LibraryFixedAsset.FindFAJournalTemplate(FAJournalTemplate);
        LibraryFixedAsset.FindFAJournalBatch(FAJournalBatch, FAJournalTemplate.Name);
        FAJournalLine.SetRange("Journal Template Name", FAJournalBatch."Journal Template Name");
        FAJournalLine.SetRange("Journal Batch Name", FAJournalBatch.Name);
        FAJournalLine.DeleteAll(true);
    end;

    local procedure SelectInsuranceJournalBatch(var InsuranceJournalBatch: Record "Insurance Journal Batch")
    var
        InsuranceJournalLine: Record "Insurance Journal Line";
    begin
        InsuranceJournalBatch.FindFirst();
        InsuranceJournalLine.SetRange("Journal Template Name", InsuranceJournalBatch."Journal Template Name");
        InsuranceJournalLine.SetRange("Journal Batch Name", InsuranceJournalBatch.Name);
        InsuranceJournalLine.DeleteAll(true);
    end;

    local procedure VerifyDocumentEntries(RowCaption: Text[50]; RowValue: Text[50]; ColumnCaption: Text[50]; ColumnValue: Decimal)
    begin
        LibraryReportDataset.SetRange(RowCaption, RowValue);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals(ColumnCaption, ColumnValue);
    end;

    local procedure VerifyFixedAssetReport(RowCaption: Text[50]; RowValue: Text[50]; ColumnCaption: Text[50]; ColumnValue: Decimal)
    begin
        LibraryReportDataset.SetRange(RowCaption, RowValue);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals(ColumnCaption, ColumnValue)
    end;

    local procedure VerifyFAJournalTestReportWarning(FAJournalLine: Record "FA Journal Line")
    var
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('ErrorText_Number_',
          StrSubstNo(FieldError, FAJournalLine.FieldCaption("FA Posting Date")));
        LibraryReportDataset.AssertElementWithValueExists('ErrorText_Number_',
          StrSubstNo(FieldError, FAJournalLine.FieldCaption("Document No.")));
        LibraryReportDataset.AssertElementWithValueExists('ErrorText_Number_',
          StrSubstNo(FieldError, FAJournalLine.FieldCaption("Depreciation Book Code")));
        LibraryReportDataset.AssertElementWithValueExists('ErrorText_Number_',
          StrSubstNo(FieldError2,
            FAJournalLine.FieldCaption("Depreciation Book Code"),
            FAJournalLine.FieldCaption("Duplicate in Depreciation Book")));
        LibraryReportDataset.AssertElementWithValueExists('ErrorText_Number_',
          StrSubstNo(FieldError3,
            FADepreciationBook.TableCaption(),
            FAJournalLine."FA No.", FAJournalLine."Depreciation Book Code"));
        LibraryReportDataset.AssertElementWithValueExists('ErrorText_Number_',
          StrSubstNo(FieldError4,
            FAJournalLine.FieldCaption("Depr. until FA Posting Date"),
            FAJournalLine.FieldCaption("FA Error Entry No.")));
        LibraryReportDataset.AssertElementWithValueExists('ErrorText_Number_',
          StrSubstNo(FieldError4,
            FAJournalLine.FieldCaption("Depr. Acquisition Cost"),
            FAJournalLine.FieldCaption("FA Error Entry No.")));
        LibraryReportDataset.AssertElementWithValueExists('ErrorText_Number_',
          StrSubstNo(FieldError4,
            FAJournalLine.FieldCaption("Salvage Value"),
            FAJournalLine.FieldCaption("FA Error Entry No.")));

        LibraryReportDataset.SetRange('FA_Journal_Line__FA_No__', FAJournalLine."FA No.");
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFound, 'FA_Journal_Line__FA_No__', FAJournalLine."FA No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('FA_Journal_Line__FA_Posting_Type_', Format(FAJournalLine."FA Posting Type"));
        LibraryReportDataset.AssertCurrentRowValueEquals('FA_Journal_Line_Description', FAJournalLine.Description);
        LibraryReportDataset.AssertCurrentRowValueEquals('FA_Journal_Line__Depr__until_FA_Posting_Date_', true);
    end;

    local procedure VerifyMaintenanceDetailReport(MaintenanceCode: Code[10]; Amount: Decimal)
    begin
        LibraryReportDataset.SetRange(MaintenanceCodeCaption, MaintenanceCode);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals(AmountCaption, Amount);
    end;

    local procedure VerifyInsuranceJournalTestReportWarning(InsuranceJournalLine: Record "Insurance Journal Line")
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('ErrorText_Number_',
          StrSubstNo(FieldError, InsuranceJournalLine.FieldCaption("Posting Date")));
        LibraryReportDataset.AssertElementWithValueExists('ErrorText_Number_',
          StrSubstNo(FieldError, InsuranceJournalLine.FieldCaption("FA No.")));
        LibraryReportDataset.AssertElementWithValueExists('ErrorText_Number_',
          StrSubstNo(FieldError, InsuranceJournalLine.FieldCaption("Document No.")));

        LibraryReportDataset.SetRange('Insurance_Journal_Line__Insurance_No__', InsuranceJournalLine."Insurance No.");
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFound, 'Insurance_Journal_Line__Insurance_No__', InsuranceJournalLine."Insurance No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('Insurance_Journal_Line_Description', InsuranceJournalLine.Description);
        LibraryReportDataset.AssertCurrentRowValueEquals('Insurance_Journal_Line_Amount', InsuranceJournalLine.Amount);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Message: Text[1024]; var Reply: Boolean)
    var
        ExpectedMessage: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage);  // Dequeue Variable.
        Assert.IsTrue(StrPos(Message, ExpectedMessage) > 0, Message);
        Reply := true;
    end;

    [RequestPageHandler]
    procedure DocumentEntriesRequestPageHandler(var DocumentEntries: TestRequestPage "Document Entries")
    begin
        DocumentEntries.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure FAPostingTypesOvervMatrixPageHandler(var FAPostingTypesOvervMatrix: TestPage "FA Posting Types Overv. Matrix")
    var
        FANo: Variant;
        Amount: Variant;
    begin
        // Dequeue variables.
        LibraryVariableStorage.Dequeue(FANo);
        LibraryVariableStorage.Dequeue(Amount);
        FAPostingTypesOvervMatrix.FILTER.SetFilter("FA No.", FANo);
        FAPostingTypesOvervMatrix.Field1.AssertEquals(Format(Amount, 0, FormatString));  // Verifying Book Value.
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure FixedAssetAcquisitionListHandler(var FixedAssetAcquisitionList: TestRequestPage "Fixed Asset - Acquisition List")
    var
        StartingDate: Variant;
        EndingDate: Variant;
        FixedAssetNo: Variant;
        FixedAssetsAcquired: Variant;
    begin
        LibraryVariableStorage.Dequeue(FixedAssetNo);
        LibraryVariableStorage.Dequeue(StartingDate);
        LibraryVariableStorage.Dequeue(EndingDate);
        LibraryVariableStorage.Dequeue(FixedAssetsAcquired);
        FixedAssetAcquisitionList.StartingDate.SetValue(StartingDate);
        FixedAssetAcquisitionList.EndingDate.SetValue(EndingDate);
        FixedAssetAcquisitionList.FAWithoutAcqDate.SetValue(FixedAssetsAcquired);  // Setting Include Fixed Assets Not Yet Acquired.
        FixedAssetAcquisitionList."Fixed Asset".SetFilter("No.", FixedAssetNo);
        FixedAssetAcquisitionList.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure FAPostingGroupNetChangeHandler(var FAPostingGroupNetChange: TestRequestPage "FA Posting Group - Net Change")
    var
        StartingDate: Variant;
        EndingDate: Variant;
        FixedAssetNo: Variant;
        TotalPerGLAccount: Variant;
    begin
        LibraryVariableStorage.Dequeue(FixedAssetNo);
        LibraryVariableStorage.Dequeue(StartingDate);
        LibraryVariableStorage.Dequeue(EndingDate);
        LibraryVariableStorage.Dequeue(TotalPerGLAccount);
        FAPostingGroupNetChange.StartingDate.SetValue(StartingDate);
        FAPostingGroupNetChange.EndingDate.SetValue(EndingDate);
        FAPostingGroupNetChange.OnlyTotals.SetValue(TotalPerGLAccount);  // Setting Total as per G/L Account.
        FAPostingGroupNetChange."FA Depreciation Book".SetFilter("FA No.", FixedAssetNo);
        FAPostingGroupNetChange.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure FixedAssetListRequestPageHandler(var FixedAssetList: TestRequestPage "Fixed Asset - List")
    var
        DepreciationBookCode: Variant;
        NewPagePerAsset: Variant;
        FixedAssetFilter: Variant;
    begin
        LibraryVariableStorage.Dequeue(DepreciationBookCode);
        LibraryVariableStorage.Dequeue(NewPagePerAsset);
        LibraryVariableStorage.Dequeue(FixedAssetFilter);
        FixedAssetList.DeprBookCode.SetValue(DepreciationBookCode);  // Setting Depreciation Book Code.
        FixedAssetList.PrintOnlyOnePerPage.SetValue(NewPagePerAsset);  // Setting New Page per Asset.
        FixedAssetList."Fixed Asset".SetFilter("No.", FixedAssetFilter);
        FixedAssetList.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure MaintenanceAnalysisRequestPageHandler(var MaintenanceAnalysis: TestRequestPage "Maintenance - Analysis")
    var
        ParametersFileName: Text;
        FileName: Text;
        DepreciationBookCode: Variant;
        StartingDate: Variant;
        EndingDate: Variant;
        MaintenanceCode: Variant;
        Period: Option "before Starting Date","Net Change","at Ending Date";
    begin
        ParametersFileName := LibraryReportDataset.GetParametersFileName();
        FileName := LibraryReportDataset.GetFileName();
        LibraryVariableStorage.Dequeue(DepreciationBookCode);
        LibraryVariableStorage.Dequeue(StartingDate);
        LibraryVariableStorage.Dequeue(EndingDate);
        LibraryVariableStorage.Dequeue(MaintenanceCode);
        MaintenanceAnalysis.DeprBookCode.SetValue(DepreciationBookCode);  // Setting Depreciation Book Code.
        MaintenanceAnalysis.StartingDate.SetValue(StartingDate);
        MaintenanceAnalysis.EndingDate.SetValue(EndingDate);
        MaintenanceAnalysis.AmountField1.SetValue(MaintenanceCode);
        MaintenanceAnalysis.Period1.SetValue(Period::"at Ending Date");  // Setting Period1.
        MaintenanceAnalysis.AmountField2.SetValue(MaintenanceCode);
        MaintenanceAnalysis.Period2.SetValue(Period::"before Starting Date");  // Setting Period2.
        MaintenanceAnalysis.AmountField3.SetValue(MaintenanceCode);
        MaintenanceAnalysis.Period3.SetValue(Period::"Net Change");  // Setting Period3.
        MaintenanceAnalysis.SaveAsXml(ParametersFileName, FileName);
        Sleep(500);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure MaintenanceDetailsRequestPagetHandler(var MaintenanceDetails: TestRequestPage "Maintenance - Details")
    var
        No: Variant;
        IncludeReversedEntries: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);  // Dequeue Variable.
        LibraryVariableStorage.Dequeue(IncludeReversedEntries);
        MaintenanceDetails."Fixed Asset".SetFilter("No.", No);
        MaintenanceDetails.IncludeReversedEntries.SetValue(IncludeReversedEntries);  // Setting Include Reversed Entries boolean.
        MaintenanceDetails.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    var
        ExpectedMessage: Variant;
    begin
        // Message Handler.
        LibraryVariableStorage.Dequeue(ExpectedMessage);  // Dequeue Variable.
        Assert.IsTrue(StrPos(Message, ExpectedMessage) > 0, Message);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHFixedAssetJournalTest(var FixedAssetJournalTest: TestRequestPage "Fixed Asset Journal - Test")
    begin
        FixedAssetJournalTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHInsuranceJournalTest(var InsuranceJournalTest: TestRequestPage "Insurance Journal - Test")
    begin
        InsuranceJournalTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHFixedAssetBookValue02Report(var FixedAssetBookValue02Report: TestRequestPage "Fixed Asset - Book Value 02")
    begin
        FixedAssetBookValue02Report.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

