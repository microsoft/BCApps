codeunit 134981 "ERM Fixed Assets Reports - II"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        // [FEATURE] [Fixed Asset]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryERM: Codeunit "Library - ERM";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        isInitialized: Boolean;
        LaterEndingDateErr: Label 'The Starting Date is later than the Ending Date.';
        UnknownErr: Label 'Unknown Error.';
        GapWarningMsg: Label 'There is a gap in the number series.';
        LaterDepreciationDateErr: Label 'The First Depreciation Date is later than the Last Depreciation Date.';
        NoOfDaysErr: Label 'Number of Days must not be greater than 360 or less than 5.';
        BlankDatesErr: Label 'You must specify the Starting Date and the Ending Date.';
        GLAcquisitionDateTxt: Label 'G/L Acquisition Date';
        AcquisitionCostTxt: Label 'Acquisition Cost';
        AppreciationTxt: Label 'Appreciation';
        DepreciationTxt: Label 'Depreciation';
        GainLossTxt: Label 'Gain/Loss';
        BalanceDisposalErr: Label 'Bal. Disposal must be specified only together with the types Write-Down, Appreciation, Custom 1 or Custom 2.';
        CustomTxt: Label 'Custom %1', Comment = '%1 = Integer (1 or 2)';
        WriteDownTxt: Label 'Write-Down';
        ValidationErr: Label '%1 must be %2 .', Comment = '%1 = Column Caption, %2 = Column Value';
        StartingEndingDateErr: Label 'The Starting Date is later than the Ending Date.';
        SpecifyDepreciationDateErr: Label 'You must specify the First Depreciation Date and the Last Depreciation Date.';
        FAJnlDepreciationPostErr: Label 'You cannot post depreciation, because the calculation is across different fiscal year periods, which is not supported.';
        GroupTotals: Option " ","FA Class","FA Subclass","FA Location","Main Asset","Global Dimension 1","Global Dimension 2","FA Posting Group";
        GLBudgetEntryNotFoundErr: Label 'G/L Budget Entry with appropriate dimension value code not found.';
        CopyDimToBudgetEntryErr: Label 'Default Dimensions were not copied to Budget.';
        GLBudgetEntryWithDateNotFoundErr: Label 'G/L Budget Entry with appropriate date value code not found.';
        FAPostingDateErr: Label 'FA Posting Date is not correct for %1 in FA Ledger Entry', Comment = '%1 = Fixed Asset No.';
        CompletionStatsTok: Label 'The depreciation has been calculated.';

    [Test]
    [HandlerFunctions('RHFAProjectedValue')]
    [Scope('OnPrem')]
    procedure FixedAssetWithProjectedDisposal()
    var
        FixedAsset: Record "Fixed Asset";
        FixedAsset2: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        FADepreciationBook2: Record "FA Depreciation Book";
    begin
        // Test values on Fixed Asset Projected Value Report after running with Projected Disposal & Print Per FA as True.

        // 1.Setup: Create two Fixed Asset & FA Depreciation Books with projected disposal and Post FA General Journal Lines.
        Initialize();
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset2);
        CreateFADepreciationBookWithProjectedDisposal(FADepreciationBook, FixedAsset);
        CreateFADepreciationBookWithProjectedDisposal(FADepreciationBook2, FixedAsset2);
        CreateAndPostFAGenJournalLine(FADepreciationBook, FADepreciationBook2);

        // 2.Exercise: Run Fixed Asset Projected Value Report with Projected Disposal & Print Per Fixed Asset as True.
        FixedAsset.SetFilter("No.", '%1|%2', FixedAsset."No.", FixedAsset2."No.");
        RunFixedAssetProjectedValue(FixedAsset, GroupTotals::" ", true, true, '', false);

        // 3.Verify: Verify values on Projected Value Report.
        LibraryReportDataset.LoadDataSetFile();
        VerifyProjectedDisposalValues(FADepreciationBook, FADepreciationBook2);
        LibraryFixedAsset.VerifyLastFARegisterGLRegisterOneToOneRelation(); // TFS 376879
    end;

    [Test]
    [HandlerFunctions('RHMaintenanceRegister')]
    [Scope('OnPrem')]
    procedure MaintenanceRegisterReport()
    var
        FixedAsset: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        FARegister: Record "FA Register";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        Maintenance: Record Maintenance;
        Maintenance2: Record Maintenance;
        MaintenanceRegister: Report "Maintenance Register";
        OldDefaultDeprBook: Code[10];
    begin
        // Test and verify Maintenance Register Report.

        // 1. Setup: Create Fixed Asset, FA Depreciation Book, First Maintenance, Second Maintenance, General Journal Batch,
        // First Journal Line with First Maintenance, Second Journal Line with Second Maintenance, Post Journal Line.
        Initialize();
        OldDefaultDeprBook := UpdateFASetup(CreateDepreciationBook());
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset);
        LibraryFixedAsset.CreateMaintenance(Maintenance);
        LibraryFixedAsset.CreateMaintenance(Maintenance2);

        CreateGeneralJournalBatch(GenJournalBatch);
        CreateGeneralJournalLine(GenJournalLine, GenJournalBatch, FADepreciationBook, GenJournalLine."FA Posting Type"::Maintenance);
        UpdateMaintenanceOnJournalLine(GenJournalLine, Maintenance.Code);

        CreateGeneralJournalLine(GenJournalLine, GenJournalBatch, FADepreciationBook, GenJournalLine."FA Posting Type"::Maintenance);
        UpdateMaintenanceOnJournalLine(GenJournalLine, Maintenance2.Code);

        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 2. Exercise: Run the Maintenance Register Report.
        FARegister.SetRange("Journal Batch Name", GenJournalBatch.Name);
        Clear(MaintenanceRegister);
        MaintenanceRegister.SetTableView(FARegister);
        MaintenanceRegister.Run();

        // 3. Verify: Verify values on Maintenance Register Report.
        LibraryReportDataset.LoadDataSetFile();
        VerifyMaintenanceRegisterLine(Maintenance.Code);
        VerifyMaintenanceRegisterLine(Maintenance2.Code);

        // Tear Down.
        UpdateFASetup(OldDefaultDeprBook);
        LibraryFixedAsset.VerifyMaintenanceLastFARegisterGLRegisterOneToOneRelation(); // TFS 376879
    end;

    [Test]
    [HandlerFunctions('RHMaintenanceNextService')]
    [Scope('OnPrem')]
    procedure MaintenanceNextServiceError()
    var
        MaintenanceNextService: Report "Maintenance - Next Service";
    begin
        // Test that System generates an error when Starting Date is later than the Ending Date on Report Maintenance Next Service.

        // 1. Setup.
        Initialize();

        // 2. Exercise: Run the Report.
        Clear(MaintenanceNextService);

        // Using the Random Number for the Day.
        MaintenanceNextService.InitializeRequest(CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()), WorkDate());
        Commit();
        asserterror MaintenanceNextService.Run();

        // 3. Verify: Verify that System generates an error when Starting Date is later than the Ending Date.
        Assert.AreEqual(StrSubstNo(LaterEndingDateErr), GetLastErrorText, UnknownErr);
    end;

    [Test]
    [HandlerFunctions('RHMaintenanceNextService')]
    [Scope('OnPrem')]
    procedure MaintenanceNextServiceReport()
    var
        FixedAsset: Record "Fixed Asset";
        MaintenanceNextService: Report "Maintenance - Next Service";
    begin
        // Test and verify Maintenance Next Service Report.

        // 1. Setup: Create Fixed Asset, Update Maintenance Information on Fixed Asset.
        Initialize();
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        UpdateMaintenanceOnFixedAsset(FixedAsset);

        // 2. Exercise: Run the Maintenance Next Service Report.
        FixedAsset.SetRange("No.", FixedAsset."No.");
        Clear(MaintenanceNextService);

        // Using the Random Number for the Day.
        MaintenanceNextService.InitializeRequest(WorkDate(), CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()));
        Commit();
        MaintenanceNextService.Run();

        // 3. Verify: Verify values on Maintenance Next Service Report.
        LibraryReportDataset.LoadDataSetFile();
        VerifyMaintenanceNextService(FixedAsset);
    end;

    [Test]
    [HandlerFunctions('RHFADocumentNos')]
    [Scope('OnPrem')]
    procedure FixedAssetSeriesWithWarning()
    var
        FixedAsset: Record "Fixed Asset";
        FixedAsset2: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        FADepreciationBook2: Record "FA Depreciation Book";
        FALedgerEntry: Record "FA Ledger Entry";
        FixedAssetDocumentNos: Report "Fixed Asset Document Nos.";
    begin
        // Test and verify Fixed Asset Document Nos. Report with Warning.

        // 1. Setup: Create two Fixed Asset, two FA Depreciation Book, General Journal Batch, two Fixed Asset Journal Lines
        // Post Journal Line.
        Initialize();
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset2);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset);
        CreateFADepreciationBook(FADepreciationBook2, FixedAsset2);
        CreateAndPostFAGenJournalLine(FADepreciationBook, FADepreciationBook2);

        // 2. Exercise: Run the Fixed Asset Document Nos. Report.
        FALedgerEntry.SetFilter("FA No.", '%1|%2', FixedAsset."No.", FixedAsset2."No.");
        Clear(FixedAssetDocumentNos);
        FixedAssetDocumentNos.SetTableView(FALedgerEntry);
        FixedAssetDocumentNos.Run();

        // 3. Verify: Verify warning and other values on Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('ErrorText_Number__Control15', Format(GapWarningMsg));
        VerifyFixedAssetDocument(FixedAsset."No.");
        VerifyFixedAssetDocument(FixedAsset2."No.");
        LibraryFixedAsset.VerifyLastFARegisterGLRegisterOneToOneRelation(); // TFS 376879
    end;

    [Test]
    [HandlerFunctions('RHFADocumentNos')]
    [Scope('OnPrem')]
    procedure FixedAssetSeriesWithoutWarning()
    var
        FixedAsset: Record "Fixed Asset";
        FixedAsset2: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        FADepreciationBook2: Record "FA Depreciation Book";
        FALedgerEntry: Record "FA Ledger Entry";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        FixedAssetDocumentNos: Report "Fixed Asset Document Nos.";
        DocumentNo: Code[20];
    begin
        // Test and verify Fixed Asset Document Nos. Report without Warning.

        // 1. Setup: Create two Fixed Asset, two FA Depreciation Book, General Journal Batch, two Fixed Asset Journal Lines
        // Post Journal Line.
        Initialize();
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset2);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset);
        CreateFADepreciationBook(FADepreciationBook2, FixedAsset2);

        CreateGeneralJournalBatch(GenJournalBatch);
        CreateGeneralJournalLine(GenJournalLine, GenJournalBatch, FADepreciationBook, GenJournalLine."FA Posting Type"::"Acquisition Cost");
        DocumentNo := GenJournalLine."Document No.";

        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, FADepreciationBook2, GenJournalLine."FA Posting Type"::"Acquisition Cost");
        UpdateDocumentNoOnJournalLine(GenJournalLine, IncStr(DocumentNo));

        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 2. Exercise: Run the Fixed Asset Document Nos. Report.
        FALedgerEntry.SetFilter("FA No.", '%1|%2', FixedAsset."No.", FixedAsset2."No.");
        Clear(FixedAssetDocumentNos);
        FixedAssetDocumentNos.SetTableView(FALedgerEntry);
        FixedAssetDocumentNos.Run();

        // 3. Verify: Verify values on Report.
        LibraryReportDataset.LoadDataSetFile();
        VerifyFixedAssetDocument(FixedAsset."No.");
        VerifyFixedAssetDocument(FixedAsset2."No.");
        asserterror LibraryReportDataset.AssertElementWithValueExists('', GapWarningMsg);
        LibraryFixedAsset.VerifyLastFARegisterGLRegisterOneToOneRelation(); // TFS 376879
    end;

    [Test]
    [HandlerFunctions('RHFARegister')]
    [Scope('OnPrem')]
    procedure FixedAssetRegisterReport()
    var
        FixedAsset: Record "Fixed Asset";
        FixedAsset2: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        FADepreciationBook2: Record "FA Depreciation Book";
        FARegister: Record "FA Register";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        FixedAssetRegister: Report "Fixed Asset Register";
    begin
        // Test and verify Fixed Asset Register Report.

        // 1. Setup: Create two Fixed Asset, two FA Depreciation Book, General Journal Batch, two Fixed Asset Journal Lines
        // Post Journal Line.
        Initialize();
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset2);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset);
        CreateFADepreciationBook(FADepreciationBook2, FixedAsset2);

        CreateGeneralJournalBatch(GenJournalBatch);
        CreateGeneralJournalLine(GenJournalLine, GenJournalBatch, FADepreciationBook, GenJournalLine."FA Posting Type"::"Acquisition Cost");
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, FADepreciationBook2, GenJournalLine."FA Posting Type"::"Acquisition Cost");

        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 2. Exercise: Run the Report.
        FARegister.SetFilter("Journal Batch Name", GenJournalBatch.Name);
        Clear(FixedAssetRegister);
        FixedAssetRegister.SetTableView(FARegister);
        FixedAssetRegister.Run();

        // 3. Verify: Verify values on Fixed Asset Register Report.
        LibraryReportDataset.LoadDataSetFile();
        VerifyFixedAssetRegisterLine(FixedAsset."No.");
        VerifyFixedAssetRegisterLine(FixedAsset2."No.");
        LibraryFixedAsset.VerifyLastFARegisterGLRegisterOneToOneRelation(); // TFS 376879
    end;

    [Test]
    [HandlerFunctions('RHFixedAssetProjectedValue')]
    [Scope('OnPrem')]
    procedure BlankDepreciationBookCodeError()
    var
        FixedAssetProjectedValue: Report "Fixed Asset - Projected Value";
    begin
        // Test error occurs on Running Fixed Asset Projected Value Report without Depreciation Book Code.

        // 1. Setup.
        Initialize();

        // 2. Exercise: Run Fixed Asset Projected Value Report without Depreciation Book Code.
        Clear(FixedAssetProjectedValue);
        LibraryVariableStorage.Enqueue('');
        LibraryVariableStorage.Enqueue(WorkDate());
        LibraryVariableStorage.Enqueue(WorkDate());
        Commit();
        asserterror FixedAssetProjectedValue.Run();

        // 3. Verify: Verify that System generates an error without Depreciation Book Code.
        Assert.ExpectedErrorCannotFind(Database::"Depreciation Book");
    end;

    [Test]
    [HandlerFunctions('RHFixedAssetProjectedValue')]
    [Scope('OnPrem')]
    procedure FAProjectedBlankDateError()
    var
        FixedAssetProjectedValue: Report "Fixed Asset - Projected Value";
    begin
        // Test error occurs on Running Fixed Asset Projected Value Report without Starting Date and Ending Date.

        // 1. Setup.
        Initialize();

        // 2. Exercise: Run Fixed Asset Projected Value Report without Starting Date and Ending Date.
        Clear(FixedAssetProjectedValue);
        LibraryVariableStorage.Enqueue(LibraryFixedAsset.GetDefaultDeprBook());
        LibraryVariableStorage.Enqueue(0D);
        LibraryVariableStorage.Enqueue(0D);
        FixedAssetProjectedValue.GetFASetup();
        Commit();
        asserterror FixedAssetProjectedValue.Run();

        // 3. Verify: Verify that System generates an error without Starting Date and Ending Date.
        Assert.ExpectedError(SpecifyDepreciationDateErr);
    end;

    [Test]
    [HandlerFunctions('RHFAProjectedValue')]
    [Scope('OnPrem')]
    procedure StartDateLaterEndingDateError()
    var
        FixedAssetProjectedValue: Report "Fixed Asset - Projected Value";
    begin
        // Test error occurs on Running Fixed Asset Projected Value Report with Starting Date greater than Ending Date.

        // 1. Setup.
        Initialize();

        // 2. Exercise: Run Fixed Asset Projected Value Report with Starting Date greater than Ending Date.
        Clear(FixedAssetProjectedValue);

        // Using the Random Number for the Day.
        FixedAssetProjectedValue.SetMandatoryFields(
          '', CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()), WorkDate());
        FixedAssetProjectedValue.GetFASetup();

        asserterror FixedAssetProjectedValue.Run();

        // 3. Verify: Verify that System generates an error when Starting Date is later than the Ending Date.
        Assert.AreEqual(StrSubstNo(LaterDepreciationDateErr), GetLastErrorText, UnknownErr);
    end;

    [Test]
    [HandlerFunctions('RHFixedAssetProjectedValueNoOfDaysError')]
    [Scope('OnPrem')]
    procedure FAProjectedNoOfDaysError()
    begin
        // Test error occurs on Running Fixed Asset Projected Value Report with Number of Days less than 5.

        // 1. Setup.
        Initialize();

        // 2. Exercise: Run Fixed Asset Projected Value Report with Number of Days less than 5.
        asserterror REPORT.Run(REPORT::"Fixed Asset - Projected Value");

        // 3. Verify: Verify that System generates an error when Number of Days less than 5.
        Assert.AreEqual(StrSubstNo(NoOfDaysErr), GetLastErrorText, UnknownErr);
    end;

    [Test]
    [HandlerFunctions('RHFAProjectedValue')]
    [Scope('OnPrem')]
    procedure FAProjectedValueWithFAClass()
    var
        FixedAsset: Record "Fixed Asset";
        FixedAsset2: Record "Fixed Asset";
        FAClass: Record "FA Class";
        FADepreciationBook: Record "FA Depreciation Book";
        FADepreciationBook2: Record "FA Depreciation Book";
    begin
        // Test values on Fixed Asset Projected Value Report after running with Group Total as FA Class.

        // 1. Setup: Create two Fixed Asset with same FA Class, two FA Depreciation Book, General Journal Batch,
        // two Fixed Asset Journal Lines, Post Journal Lines.
        Initialize();
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset2);

        LibraryFixedAsset.FindFAClass(FAClass);
        UpdateFAClassCode(FixedAsset, FAClass.Code);
        UpdateFAClassCode(FixedAsset2, FAClass.Code);

        CreateFADepreciationBook(FADepreciationBook, FixedAsset);
        CreateFADepreciationBook(FADepreciationBook2, FixedAsset2);
        CreateAndPostFAGenJournalLine(FADepreciationBook, FADepreciationBook2);

        // 2. Exercise: Run Fixed Asset Projected Value Report with Group Total as FA Class.
        FixedAsset.SetFilter("No.", '%1|%2', FixedAsset."No.", FixedAsset2."No.");
        RunFixedAssetProjectedValue(FixedAsset, GroupTotals::"FA Class", true, false, '', false);

        // 3. Verify: Verify values on report generated with FA Class.
        LibraryReportDataset.LoadDataSetFile();
        VerifyValuesOnGroupTotal(FADepreciationBook, FADepreciationBook2);
        LibraryFixedAsset.VerifyLastFARegisterGLRegisterOneToOneRelation(); // TFS 376879
    end;

    [Test]
    [HandlerFunctions('RHFAProjectedValue')]
    [Scope('OnPrem')]
    procedure FAProjectedValueWithFASubclass()
    var
        FixedAsset: Record "Fixed Asset";
        FixedAsset2: Record "Fixed Asset";
        FASubclass: Record "FA Subclass";
        FADepreciationBook: Record "FA Depreciation Book";
        FADepreciationBook2: Record "FA Depreciation Book";
    begin
        // Test values on Fixed Asset Projected Value Report after running with Group Total as FA Subclass.

        // 1. Setup: Create two Fixed Asset with same FA Subclass, two FA Depreciation Book, General Journal Batch,
        // two Fixed Asset Journal Lines, Post Journal Lines.
        Initialize();
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset2);

        LibraryFixedAsset.FindFASubclass(FASubclass);
        UpdateFASubclassCode(FixedAsset, FASubclass.Code);
        UpdateFASubclassCode(FixedAsset2, FASubclass.Code);

        CreateFADepreciationBook(FADepreciationBook, FixedAsset);
        CreateFADepreciationBook(FADepreciationBook2, FixedAsset2);
        CreateAndPostFAGenJournalLine(FADepreciationBook, FADepreciationBook2);

        // 2. Exercise: Run Fixed Asset Projected Value Report with Group Total as FA Subclass.
        FixedAsset.SetFilter("No.", '%1|%2', FixedAsset."No.", FixedAsset2."No.");
        RunFixedAssetProjectedValue(FixedAsset, GroupTotals::"FA Subclass", true, false, '', false);

        // 3. Verify: Verify values on report generated with FA Subclass.
        LibraryReportDataset.LoadDataSetFile();
        VerifyValuesOnGroupTotal(FADepreciationBook, FADepreciationBook2);
        LibraryFixedAsset.VerifyLastFARegisterGLRegisterOneToOneRelation(); // TFS 376879
    end;

    [Test]
    [HandlerFunctions('RHFAProjectedValue')]
    [Scope('OnPrem')]
    procedure FAProjectedValueWithFALocation()
    var
        FixedAsset: Record "Fixed Asset";
        FixedAsset2: Record "Fixed Asset";
        FALocation: Record "FA Location";
        FADepreciationBook: Record "FA Depreciation Book";
        FADepreciationBook2: Record "FA Depreciation Book";
    begin
        // Test values on Fixed Asset Projected Value Report after running with Group Total as FA Location.

        // 1. Setup: Create two Fixed Asset with same FA Location, two FA Depreciation Book, General Journal Batch,
        // two Fixed Asset Journal Lines, Post Journal Lines.
        Initialize();
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset2);

        LibraryFixedAsset.FindFALocation(FALocation);
        UpdateFALocationCode(FixedAsset, FALocation.Code);
        UpdateFALocationCode(FixedAsset2, FALocation.Code);

        CreateFADepreciationBook(FADepreciationBook, FixedAsset);
        CreateFADepreciationBook(FADepreciationBook2, FixedAsset2);
        CreateAndPostFAGenJournalLine(FADepreciationBook, FADepreciationBook2);

        // 2. Exercise: Run Fixed Asset Projected Value Report with Group Total as FA Location.
        FixedAsset.SetFilter("No.", '%1|%2', FixedAsset."No.", FixedAsset2."No.");
        RunFixedAssetProjectedValue(FixedAsset, GroupTotals::"FA Location", true, false, '', false);

        // 3. Verify: Verify values on report generated with FA Location.
        LibraryReportDataset.LoadDataSetFile();
        VerifyProjectedGroupValue(FADepreciationBook, FADepreciationBook2);
        VerifyValuesOnGroupTotal(FADepreciationBook, FADepreciationBook2);
        LibraryFixedAsset.VerifyLastFARegisterGLRegisterOneToOneRelation(); // TFS 376879
    end;

    [Test]
    [HandlerFunctions('RHFAProjectedValue')]
    [Scope('OnPrem')]
    procedure FAProjectedValueWithMainAsset()
    var
        FixedAsset: Record "Fixed Asset";
        FixedAsset2: Record "Fixed Asset";
        FixedAsset3: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        FADepreciationBook2: Record "FA Depreciation Book";
        FADepreciationBook3: Record "FA Depreciation Book";
        MainAssetComponent: Record "Main Asset Component";
    begin
        // Test values on Fixed Asset Projected Value Report after running with Group Total as Main Asset.

        // 1. Setup: Create Three Fixed Asset, Create Main Asset Components, two FA Depreciation Book, General Journal Batch,
        // two Fixed Asset Journal Lines, Post Journal Lines.
        Initialize();
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset2);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset3);

        LibraryFixedAsset.CreateMainAssetComponent(MainAssetComponent, FixedAsset3."No.", FixedAsset."No.");
        LibraryFixedAsset.CreateMainAssetComponent(MainAssetComponent, FixedAsset3."No.", FixedAsset2."No.");

        CreateFADepreciationBook(FADepreciationBook, FixedAsset);
        CreateFADepreciationBook(FADepreciationBook2, FixedAsset2);
        CreateFADepreciationBook(FADepreciationBook3, FixedAsset3);
        CreateAndPostFAGenJournalLine(FADepreciationBook, FADepreciationBook2);

        // 2. Exercise: Run Fixed Asset Projected Value Report with Group Total as Main Asset.
        FixedAsset.SetFilter("No.", '%1|%2', FixedAsset."No.", FixedAsset2."No.");
        RunFixedAssetProjectedValue(FixedAsset, GroupTotals::"Main Asset", true, false, '', false);

        // 3.Verify: Verify values on report generated with Main Asset.
        LibraryReportDataset.LoadDataSetFile();
        VerifyValuesOnGroupTotal(FADepreciationBook, FADepreciationBook2);
        LibraryFixedAsset.VerifyLastFARegisterGLRegisterOneToOneRelation(); // TFS 376879
    end;

    [Test]
    [HandlerFunctions('RHFAProjectedValue')]
    [Scope('OnPrem')]
    procedure FAProjectedValueWithAccPeriod()
    var
        FixedAsset: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        NewAccPeriodDate: Date;
        NoOfDays: Integer;
    begin
        // 1. Setup: Create Fixed Asset, FA Depreciation Book, General Journal Batch,
        // Fixed Asset Journal Line, Post Journal Lines, change Accounting Period with end of month.
        Initialize();

        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset);
        CreateGeneralJournalBatch(GenJournalBatch);
        CreateGeneralJournalLine(GenJournalLine, GenJournalBatch, FADepreciationBook, GenJournalLine."FA Posting Type"::"Acquisition Cost");
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 2. Exercise: Run Fixed Asset Projected Value Report with new Accounting Period Starting Date value.
        ModifyAccountingPeriod(NewAccPeriodDate, NoOfDays);
        RunFAProjectedValueMultiLines(FixedAsset, GroupTotals::" ", true, false, '', false);

        // 3. Verify: Verify values on report.
        LibraryReportDataset.LoadDataSetFile();

        VerifyValuesOnNewAccPeriod(NewAccPeriodDate, NoOfDays);
    end;

    [Test]
    [HandlerFunctions('RHFAProjectedValue')]
    [Scope('OnPrem')]
    procedure FAProjectedValueGLBudgetEntryDate()
    var
        FixedAsset: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GLBudgetName: Record "G/L Budget Name";
        NewAccPeriodDate: Date;
        NoOfDays: Integer;
    begin
        // 1. Setup: Create Fixed Asset, FA Depreciation Book, General Journal Batch,
        // Fixed Asset Journal Line, Post Journal Lines, change Accounting Period with end of month.
        Initialize();

        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset);
        CreateGeneralJournalBatch(GenJournalBatch);
        CreateGeneralJournalLine(GenJournalLine, GenJournalBatch, FADepreciationBook, GenJournalLine."FA Posting Type"::"Acquisition Cost");
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 2. Exercise: Run Fixed Asset Projected Value Report with new Accounting Period Starting Date value.
        ModifyAccountingPeriod(NewAccPeriodDate, NoOfDays);
        LibraryERM.CreateGLBudgetName(GLBudgetName);
        Commit();

        RunFAProjectedValueMultiLines(FixedAsset, GroupTotals::" ", true, false, GLBudgetName.Name, false);

        // 3. Verify: Verify date on G/L Budget Entry.
        VerifyGLBudgetEntryDate(GLBudgetName.Name, NewAccPeriodDate);
    end;

    [Test]
    [HandlerFunctions('RHFAProjectedValue')]
    [Scope('OnPrem')]
    procedure FAProjectedGlobalDimension1()
    var
        DimensionValue: Record "Dimension Value";
        FixedAsset: Record "Fixed Asset";
        FixedAsset2: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        FADepreciationBook2: Record "FA Depreciation Book";
        GeneralLedgerSetup: Record "General Ledger Setup";
        LibraryDimension: Codeunit "Library - Dimension";
    begin
        // Test values on Fixed Asset Projected Value Report after running with Group Total as Global Dimension 1.

        // 1. Setup: Create two Fixed Asset with same Global Dimension 1 Code, two FA Depreciation Book, General Journal Batch,
        // two Fixed Asset Journal Lines, Post Journal Lines.
        Initialize();
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset2);
        GeneralLedgerSetup.Get();
        LibraryDimension.FindDimensionValue(DimensionValue, LibraryERM.GetGlobalDimensionCode(1));
        UpdateGlobalDimension1Code(FixedAsset, DimensionValue.Code);
        UpdateGlobalDimension1Code(FixedAsset2, DimensionValue.Code);

        CreateFADepreciationBook(FADepreciationBook, FixedAsset);
        CreateFADepreciationBook(FADepreciationBook2, FixedAsset2);
        CreateAndPostFAGenJournalLine(FADepreciationBook, FADepreciationBook2);

        // 2. Exercise: Run Fixed Asset Projected Value Report with Group Total as Global Dimension 1.
        FixedAsset.SetFilter("No.", '%1|%2', FixedAsset."No.", FixedAsset2."No.");
        RunFixedAssetProjectedValue(FixedAsset, GroupTotals::"Global Dimension 1", true, false, '', false);

        // 3. Verify: Verify values on report generated with Global Dimension 1.
        LibraryReportDataset.LoadDataSetFile();
        VerifyValuesOnGroupTotal(FADepreciationBook, FADepreciationBook2);
        LibraryFixedAsset.VerifyLastFARegisterGLRegisterOneToOneRelation(); // TFS 376879
    end;

    [Test]
    [HandlerFunctions('RHFAProjectedValue')]
    [Scope('OnPrem')]
    procedure FAProjectedGlobalDimension2()
    var
        DimensionValue: Record "Dimension Value";
        FixedAsset: Record "Fixed Asset";
        FixedAsset2: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        FADepreciationBook2: Record "FA Depreciation Book";
    begin
        // Test values on Fixed Asset Projected Value Report after running with Group Total as Global Dimension 2.

        // 1. Setup: Create two Fixed Asset with same Global Dimension 2 Code, two FA Depreciation Book, General Journal Batch,
        // two Fixed Asset Journal Lines, Post Journal Lines.
        Initialize();
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset2);
        LibraryDimension.FindDimensionValue(DimensionValue, LibraryERM.GetGlobalDimensionCode(2));
        UpdateGlobalDimension2Code(FixedAsset, DimensionValue.Code);
        UpdateGlobalDimension2Code(FixedAsset2, DimensionValue.Code);

        CreateFADepreciationBook(FADepreciationBook, FixedAsset);
        CreateFADepreciationBook(FADepreciationBook2, FixedAsset2);
        CreateAndPostFAGenJournalLine(FADepreciationBook, FADepreciationBook2);

        // 2. Exercise: Run Fixed Asset Projected Value Report with Group Total as Global Dimension 2.
        FixedAsset.SetFilter("No.", '%1|%2', FixedAsset."No.", FixedAsset2."No.");
        RunFixedAssetProjectedValue(FixedAsset, GroupTotals::"Global Dimension 2", true, false, '', false);

        // 3. Verify: Verify values on report generated with Global Dimension 2.
        LibraryReportDataset.LoadDataSetFile();
        VerifyValuesOnGroupTotal(FADepreciationBook, FADepreciationBook2);
        LibraryFixedAsset.VerifyLastFARegisterGLRegisterOneToOneRelation(); // TFS 376879
    end;

    [Test]
    [HandlerFunctions('RHFAProjectedValue')]
    [Scope('OnPrem')]
    procedure FAProjectedFAPostingGroup()
    var
        FixedAsset: Record "Fixed Asset";
        FixedAsset2: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        FADepreciationBook2: Record "FA Depreciation Book";
    begin
        // Test values on Fixed Asset Projected Value Report after running with Group Total as FA Posting Group.

        // 1.Setup: Create two Fixed Asset with same FA Posting Group, two FA Depreciation Book, General Journal Batch,
        // two Fixed Asset Journal Lines, Post Journal Lines.
        Initialize();
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset2);
        AttachFAPostingGroup(FixedAsset2, FixedAsset."FA Posting Group");

        CreateFADepreciationBook(FADepreciationBook, FixedAsset);
        CreateFADepreciationBook(FADepreciationBook2, FixedAsset2);
        CreateAndPostFAGenJournalLine(FADepreciationBook, FADepreciationBook2);

        // 2.Exercise: Run Fixed Asset Projected Value Report with Group Total as FA Posting Group.
        FixedAsset.SetFilter("No.", '%1|%2', FixedAsset."No.", FixedAsset2."No.");
        RunFixedAssetProjectedValue(FixedAsset, GroupTotals::"FA Posting Group", true, false, '', false);

        // 3.Verify: Verify values on report generated with FA Posting Group.
        LibraryReportDataset.LoadDataSetFile();
        VerifyValuesOnGroupTotal(FADepreciationBook, FADepreciationBook2);
        LibraryFixedAsset.VerifyLastFARegisterGLRegisterOneToOneRelation(); // TFS 376879
    end;

    [Test]
    [HandlerFunctions('RHFAProjectedValue')]
    [Scope('OnPrem')]
    procedure FAProjectedWithBlankGroup()
    var
        FixedAsset: Record "Fixed Asset";
        FixedAsset2: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        FADepreciationBook2: Record "FA Depreciation Book";
    begin
        // Test values on Fixed Asset Projected Value Report after running with Blank Group Total and Print Details as False.

        // 1.Setup: Create two Fixed Asset, two FA Depreciation Book, General Journal Batch,
        // two Fixed Asset Journal Lines, Post Journal Lines.
        Initialize();
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset2);

        CreateFADepreciationBook(FADepreciationBook, FixedAsset);
        CreateFADepreciationBook(FADepreciationBook2, FixedAsset2);
        CreateAndPostFAGenJournalLine(FADepreciationBook, FADepreciationBook2);

        // 2.Exercise: Run Fixed Asset Projected Value Report with Group Total as Blank and Print Details as False.
        FixedAsset.SetFilter("No.", '%1|%2', FixedAsset."No.", FixedAsset2."No.");
        RunFixedAssetProjectedValue(FixedAsset, GroupTotals, false, false, '', false);

        // 3.Verify: Verify values on report generated with blank Group.
        LibraryReportDataset.LoadDataSetFile();
        VerifyFAProjectedValueTotal(FADepreciationBook, FADepreciationBook2);
        LibraryFixedAsset.VerifyLastFARegisterGLRegisterOneToOneRelation(); // TFS 376879
    end;

    [Test]
    [HandlerFunctions('RHFAProjectedValue')]
    [Scope('OnPrem')]
    procedure FAProjectedWithDisposal()
    var
        FixedAsset: Record "Fixed Asset";
        FixedAsset2: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        FADepreciationBook2: Record "FA Depreciation Book";
    begin
        // Test values on Fixed Asset Projected Value Report after running with Projected Disposal as True.

        // 1.Setup: Create two Fixed Asset, two FA Depreciation Book, General Journal Batch,
        // two Fixed Asset Journal Lines, Post Journal Lines.
        Initialize();
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset2);

        CreateFADepreciationBook(FADepreciationBook, FixedAsset);
        CreateFADepreciationBook(FADepreciationBook2, FixedAsset2);
        CreateAndPostFAGenJournalLine(FADepreciationBook, FADepreciationBook2);

        // 2.Exercise: Run Fixed Asset Projected Value Report with Projected Disposal as True.
        FixedAsset.SetFilter("No.", '%1|%2', FixedAsset."No.", FixedAsset2."No.");
        RunFixedAssetProjectedValue(FixedAsset, GroupTotals, false, true, '', false);

        // 3.Verify: Verify values on report generated with Project Disposal as True.
        LibraryReportDataset.LoadDataSetFile();
        VerifyProjectedDisposalTotal(FADepreciationBook, FADepreciationBook2);
        LibraryFixedAsset.VerifyLastFARegisterGLRegisterOneToOneRelation(); // TFS 376879
    end;

    [Test]
    [HandlerFunctions('RHFAProjectedValue')]
    [Scope('OnPrem')]
    procedure FAProjectedWithBudget()
    var
        FixedAsset: Record "Fixed Asset";
        FixedAsset2: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        FADepreciationBook2: Record "FA Depreciation Book";
        GLBudgetName: Record "G/L Budget Name";
        GLBudgetEntry: Record "G/L Budget Entry";
    begin
        // Test values on Fixed Asset Projected Value Report after running with Budget and Insert Balance Account as True.

        // 1.Setup: Create two Fixed Asset, two FA Depreciation Book, General Journal Batch,
        // two Fixed Asset Journal Lines, Post Journal Lines.
        Initialize();
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset2);

        CreateFADepreciationBook(FADepreciationBook, FixedAsset);
        CreateFADepreciationBook(FADepreciationBook2, FixedAsset2);
        CreateAndPostFAGenJournalLine(FADepreciationBook, FADepreciationBook2);

        // 2.Exercise: Run Fixed Asset Projected Value Report with Budget and Insert Balance Account as True.
        FixedAsset.SetFilter("No.", '%1|%2', FixedAsset."No.", FixedAsset2."No.");
        LibraryFixedAsset.CreateGLBudgetName(GLBudgetName);
        Commit();
        RunFixedAssetProjectedValue(FixedAsset, GroupTotals, false, false, GLBudgetName.Name, true);

        // 3.Verify: Verify values on Report and G/L Budget Entry.
        LibraryReportDataset.LoadDataSetFile();
        VerifyFAProjectedValueTotal(FADepreciationBook, FADepreciationBook2);
        GLBudgetEntry.SetRange("Budget Name", GLBudgetName.Name);
        GLBudgetEntry.FindFirst();
        LibraryFixedAsset.VerifyLastFARegisterGLRegisterOneToOneRelation(); // TFS 376879
    end;

    [Test]
    [HandlerFunctions('RHFixedAssetGLAnalysis')]
    [Scope('OnPrem')]
    procedure FAGLAnalysisBookCodeError()
    begin
        // Test error occurs on Running Fixed Asset - G/L Analysis Report without Depreciation Book Code.

        // 1. Setup.
        Initialize();

        // 2. Exercise: Run Fixed Asset - G/L Analysis Report without Depreciation Book Code.
        asserterror RunFAGLAnalysisWithPeriod('', '', WorkDate(), WorkDate(), '', '', '', 0, 0, false);

        // 3. Verify: Verify that System generates an error without Depreciation Book Code.
        Assert.ExpectedErrorCannotFind(Database::"Depreciation Book");
    end;

    [Test]
    [HandlerFunctions('RHFixedAssetGLAnalysis')]
    [Scope('OnPrem')]
    procedure FAGLAnalysisBlankDateError()
    begin
        // Test error occurs on Running Fixed Asset - G/L Analysis Report without Starting Date and Ending Date.

        // 1. Setup.
        Initialize();

        // 2. Exercise: Run Fixed Asset - G/L Analysis Report without Starting Date and Ending Date.
        asserterror RunFAGLAnalysisWithPeriod('', LibraryFixedAsset.GetDefaultDeprBook(), 0D, 0D, '', '', '', 0, 0, false);

        // 3. Verify: Verify that System generates an error when Starting Date and Ending Date are blank.
        Assert.AreEqual(StrSubstNo(BlankDatesErr), GetLastErrorText, UnknownErr);
    end;

    [Test]
    [HandlerFunctions('RHFAGLAnalysis')]
    [Scope('OnPrem')]
    procedure FAGLAnalysisEndingDateError()
    var
        FixedAsset: Record "Fixed Asset";
        Period: Option " ",Disposal,"Bal. Disposal";
    begin
        // Test error occurs on Running Fixed Asset - G/L Analysis Report with Starting Date greater than Ending Date.

        // 1. Setup.
        Initialize();

        // 2. Exercise: Run Fixed Asset - G/L Analysis Report with Starting Date greater than Ending Date.
        asserterror RunFAGLAnalysisWithGroupPrint(
            FixedAsset,
            CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()),
            AcquisitionCostTxt, Period::" ", Period::" ", Period::" ", GroupTotals::" ", false, false);

        // 3. Verify: Verify that System generates an error when Starting Date is later than the Ending Date.
        Assert.ExpectedError(StartingEndingDateErr);
    end;

    [Test]
    [HandlerFunctions('RHFixedAssetGLAnalysis')]
    [Scope('OnPrem')]
    procedure AcquisitionWithBlankPeriod()
    var
        FixedAsset: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        Period: Option " ",Disposal,"Bal. Disposal";
    begin
        // Test values on Running Fixed Asset - G/L Analysis Report with PostingType1 as Acquisition Cost and All Period as blank.

        // 1. Setup: Create Fixed Asset, FA Depreciation Book, General Journal Batch, Create and Post FA Acquisition Line.
        Initialize();
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset);
        CreateGeneralJournalBatch(GenJournalBatch);
        CreateGeneralJournalLine(GenJournalLine, GenJournalBatch, FADepreciationBook, GenJournalLine."FA Posting Type"::"Acquisition Cost");
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 2. Exercise: Run Fixed Asset - G/L Analysis Report with PostingType1 as Acquisition Cost and All Period as blank.
        RunFAGLAnalysisWithPeriod(
          FixedAsset."No.", FADepreciationBook."Depreciation Book Code",
          WorkDate(), WorkDate(), AcquisitionCostTxt, '', '', Period, 0, false);

        // 3. Verify: Verify value of Acquisition Cost on report with PostingType1 as Acquisition Cost and All Period as blank.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('HeadLineText3', AcquisitionCostTxt + '  ');
        LibraryReportDataset.AssertElementWithValueExists('Amounts1', GenJournalLine.Amount);
    end;

    [Test]
    [HandlerFunctions('RHFixedAssetGLAnalysis')]
    [Scope('OnPrem')]
    procedure AcquisitionWithDisposalPeriod()
    begin
        // Test values on Running Fixed Asset - G/L Analysis Report with PostingType2 as Acquisition Cost and All Period as Disposal
        // and SalesReport as False.

        FAGLAnalysisSalesReport(false);
    end;

    [Test]
    [HandlerFunctions('RHFixedAssetGLAnalysis')]
    [Scope('OnPrem')]
    procedure FAGLAnalysisWithSalesReport()
    begin
        // Test values on Running Fixed Asset - G/L Analysis Report with PostingType2 as Acquisition Cost and All Period as Disposal
        // and SalesReport as True.

        FAGLAnalysisSalesReport(true);
    end;

    local procedure FAGLAnalysisSalesReport(SalesReport: Boolean)
    var
        FixedAsset: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        Period: Option " ",Disposal,"Bal. Disposal";
        AcquisitionAmount: Decimal;
    begin
        // 1. Setup: Create Fixed Asset, FA Depreciation Book, General Journal Batch, Create and Post FA Acquisition and Disposal Lines.
        Initialize();
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset);

        CreateGeneralJournalBatch(GenJournalBatch);
        CreateGeneralJournalLine(GenJournalLine, GenJournalBatch, FADepreciationBook, GenJournalLine."FA Posting Type"::"Acquisition Cost");
        AcquisitionAmount := GenJournalLine.Amount;

        CreateNegativeFAGeneralLine(
          GenJournalLine, FADepreciationBook."Depreciation Book Code", GenJournalLine."FA Posting Type"::Disposal);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 2. Exercise: Run Fixed Asset - G/L Analysis Report with PostingType2 as Acquisition Cost and SalesReport with True or False.
        RunFAGLAnalysisWithPeriod(
          FixedAsset."No.", FADepreciationBook."Depreciation Book Code",
          WorkDate(), WorkDate(), AcquisitionCostTxt, '', '', Period::Disposal, GroupTotals, SalesReport);

        // 3. Verify: Verify value of Acquisition Cost on report with PostingType2 as Acquisition Cost and SalesReport with True or False.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('HeadLineText3', AcquisitionCostTxt + ' Disposal');
        LibraryReportDataset.AssertElementWithValueExists('Amounts1', -AcquisitionAmount);
        LibraryFixedAsset.VerifyLastFARegisterGLRegisterOneToOneRelation(); // TFS 376879
    end;

    [Test]
    [HandlerFunctions('RHFixedAssetGLAnalysis')]
    [Scope('OnPrem')]
    procedure BalanceDisposalError()
    var
        Period: Option " ",Disposal,"Bal. Disposal";
    begin
        // Test error occurs on Running Fixed Asset - G/L Analysis Report with PostingType1 as Acquisition Cost and
        // All Period as Bal. Disposal.

        // 1. Setup.
        Initialize();

        // 2. Exercise: Run Fixed Asset - G/L Analysis Report with PostingType1 as Acquisition Cost and All Period as Bal. Disposal.
        asserterror RunFAGLAnalysisWithPeriod(
            '', LibraryFixedAsset.GetDefaultDeprBook(),
            WorkDate(), WorkDate(), AcquisitionCostTxt, '', '', Period::"Bal. Disposal", 0, false);

        // 3. Verify: Verify error occurs on Running Fixed Asset - G/L Analysis Report with PostingType1 as Acquisition Cost and
        // All Period as Bal. Disposal.
        Assert.AreEqual(StrSubstNo(BalanceDisposalErr), GetLastErrorText, UnknownErr);
    end;

    [Test]
    [HandlerFunctions('RHFixedAssetGLAnalysis')]
    [Scope('OnPrem')]
    procedure DepreciationWithBlankPeriod()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Test values on Running Fixed Asset - G/L Analysis Report with PostingType1 as Depreciation and All Period as blank.

        PostingTypeWithBlankPeriod(DepreciationTxt, GenJournalLine."FA Posting Type"::Depreciation);
    end;

    [Test]
    [HandlerFunctions('RHFixedAssetGLAnalysis')]
    [Scope('OnPrem')]
    procedure Custom1WithBlankPeriod()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Test values on Running Fixed Asset - G/L Analysis Report with PostingType1 as Custom 1 and All Period as blank.

        PostingTypeWithBlankPeriod(StrSubstNo(CustomTxt, 1), GenJournalLine."FA Posting Type"::"Custom 1");
    end;

    [Test]
    [HandlerFunctions('RHFixedAssetGLAnalysis')]
    [Scope('OnPrem')]
    procedure Custom2WithBlankPeriod()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Test values on Running Fixed Asset - G/L Analysis Report with PostingType1 as Custom 2 and All Period as blank.

        PostingTypeWithBlankPeriod(StrSubstNo(CustomTxt, 2), GenJournalLine."FA Posting Type"::"Custom 2");
    end;

    [Test]
    [HandlerFunctions('RHFixedAssetGLAnalysis')]
    [Scope('OnPrem')]
    procedure WriteDownWithBlankPeriod()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Test values on Running Fixed Asset - G/L Analysis Report with PostingType1 as Write-Down and All Period as blank.

        PostingTypeWithBlankPeriod(WriteDownTxt, GenJournalLine."FA Posting Type"::"Write-Down");
    end;

    local procedure PostingTypeWithBlankPeriod(PostingType1: Text[30]; FAPostingType: Enum "Gen. Journal Line FA Posting Type")
    var
        FixedAsset: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        Period: Option " ",Disposal,"Bal. Disposal";
    begin
        // 1. Setup: Create Fixed Asset, FA Depreciation Book, General Journal Batch, Create and Post FA General Lines.
        Initialize();
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset);
        CreateGeneralJournalBatch(GenJournalBatch);
        CreateGeneralJournalLine(GenJournalLine, GenJournalBatch, FADepreciationBook, GenJournalLine."FA Posting Type"::"Acquisition Cost");
        CreateNegativeFAGeneralLine(GenJournalLine, FADepreciationBook."Depreciation Book Code", FAPostingType);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 2.Exercise: Run Fixed Asset - G/L Analysis Report with different PostingType1 and All Period as Blank.
        RunFAGLAnalysisWithPeriod(
          FixedAsset."No.", FADepreciationBook."Depreciation Book Code",
          WorkDate(), WorkDate(), PostingType1, '', '', Period, 0, false);

        // 3. Verify: Verify values on report with different PostingType1 and All Period as Blank.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('HeadLineText3', PostingType1 + '  ');
        LibraryReportDataset.AssertElementWithValueExists('Amounts1', GenJournalLine.Amount);
        LibraryFixedAsset.VerifyLastFARegisterGLRegisterOneToOneRelation(); // TFS 376879
    end;

    [Test]
    [HandlerFunctions('RHFixedAssetGLAnalysis')]
    [Scope('OnPrem')]
    procedure AppreciationWithBlankPeriod()
    var
        FixedAsset: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        Period: Option " ",Disposal,"Bal. Disposal";
    begin
        // Test values on Running Fixed Asset - G/L Analysis with PostingType3 as Appreciation and All Period as blank.

        // 1. Setup: Create Fixed Asset, FA Depreciation Book, General Journal Batch, Create and Post FA Acquisition and
        // Appreciation Lines.
        Initialize();
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset);

        CreateGeneralJournalBatch(GenJournalBatch);
        CreateGeneralJournalLine(GenJournalLine, GenJournalBatch, FADepreciationBook, GenJournalLine."FA Posting Type"::"Acquisition Cost");
        CreateGeneralJournalLine(GenJournalLine, GenJournalBatch, FADepreciationBook, GenJournalLine."FA Posting Type"::Appreciation);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 2. Exercise: Run Fixed Asset - G/L Analysis Report with PostingType3 as Appreciation and All Period as blank.
        RunFAGLAnalysisWithPeriod(
          FixedAsset."No.", FADepreciationBook."Depreciation Book Code",
          WorkDate(), WorkDate(), '', '', AppreciationTxt, Period, 0, false);

        // 3. Verify: Verify value of Appreciation on Report with PostingType3 as Appreciation and All Period as blank.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('HeadLineText5', AppreciationTxt + '  ');
        LibraryReportDataset.AssertElementWithValueExists('Amounts3', GenJournalLine.Amount);
        LibraryFixedAsset.VerifyLastFARegisterGLRegisterOneToOneRelation(); // TFS 376879
    end;

    [Test]
    [HandlerFunctions('RHFixedAssetGLAnalysis')]
    [Scope('OnPrem')]
    procedure GainLossWithDisposalPeriod()
    var
        FixedAsset: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        Period: Option " ",Disposal,"Bal. Disposal";
        AcquisitionAmount: Decimal;
    begin
        // Test values on Running Fixed Asset - G/L Analysis Report with PostingType1 as Gain/Loss and All Period as Disposal.

        // 1. Setup: Create Fixed Asset, FA Depreciation Book, General Journal Batch, Create and Post FA Acquisition and Disposal Lines.
        Initialize();
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset);

        CreateGeneralJournalBatch(GenJournalBatch);
        CreateGeneralJournalLine(GenJournalLine, GenJournalBatch, FADepreciationBook, GenJournalLine."FA Posting Type"::"Acquisition Cost");
        AcquisitionAmount := GenJournalLine.Amount;

        CreateNegativeFAGeneralLine(
          GenJournalLine, FADepreciationBook."Depreciation Book Code", GenJournalLine."FA Posting Type"::Disposal);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 2. Exercise: Run Fixed Asset - G/L Analysis Report with PostingType1 as Gain/Loss and All Period as Disposal.
        FixedAsset.SetRange("No.", FixedAsset."No.");
        RunFAGLAnalysisWithPeriod(
          FixedAsset."No.", FADepreciationBook."Depreciation Book Code",
          WorkDate(), WorkDate(), GainLossTxt, '', '', Period::Disposal, 0, false);

        // 3. Verify: Verify value of Gain/Loss on report with PostingType1 as Gain/Loss and All Period as Disposal.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('HeadLineText3', GainLossTxt + '  ');
        LibraryReportDataset.AssertElementWithValueExists('Amounts1', AcquisitionAmount + GenJournalLine.Amount);
        LibraryFixedAsset.VerifyLastFARegisterGLRegisterOneToOneRelation(); // TFS 376879
    end;

    [Test]
    [HandlerFunctions('RHFAGLAnalysis')]
    [Scope('OnPrem')]
    procedure FAGLAnalysisGroupFAClass()
    var
        FixedAsset: array[2] of Record "Fixed Asset";
        FAClass: Record "FA Class";
        Amount: Decimal;
        Period: Option " ",Disposal,"Bal. Disposal";
    begin
        // Test values on Fixed Asset - G/L Analysis Report after running with Group Total as FA Class.

        // 1. Setup: Create two Fixed Asset with same FA Class, two FA Depreciation Book, General Journal Batch,
        // two Fixed Asset Journal Lines, Post Journal Lines.
        Initialize();
        CreateTwoFixedAsset(FixedAsset);

        LibraryFixedAsset.FindFAClass(FAClass);
        UpdateFAClassCode(FixedAsset[1], FAClass.Code);
        UpdateFAClassCode(FixedAsset[2], FAClass.Code);

        Amount := CreatePostTwoFAAcqCost(FixedAsset);

        // 2. Exercise: Run Fixed Asset - G/L Analysis Report with Group Total as FA Class.
        FixedAsset[1].SetFilter("No.", '%1|%2', FixedAsset[1]."No.", FixedAsset[2]."No.");
        RunFAGLAnalysisWithGroupPrint(
          FixedAsset[1], WorkDate(), AcquisitionCostTxt, Period::" ", Period::" ", Period::" ", GroupTotals::"FA Class", false, false);

        // 3. Verify: Verify values on Fixed Asset - G/L Analysis Report with Group Total as FA Class.
        LibraryReportDataset.LoadDataSetFile();
        VerifyGroupTotalValue(AcquisitionCostTxt, Amount);
        LibraryFixedAsset.VerifyLastFARegisterGLRegisterOneToOneRelation(); // TFS 376879
    end;

    [Test]
    [HandlerFunctions('RHFAGLAnalysis')]
    [Scope('OnPrem')]
    procedure FAGLAnalysisGroupFASubclass()
    var
        FixedAsset: array[2] of Record "Fixed Asset";
        FASubclass: Record "FA Subclass";
        Amount: Decimal;
        Period: Option " ",Disposal,"Bal. Disposal";
    begin
        // Test values on Fixed Asset - G/L Analysis Report after running with Group Total as FA Subclass.

        // 1. Setup: Create two Fixed Asset with same FA Subclass, two FA Depreciation Book, General Journal Batch,
        // two Fixed Asset Journal Lines, Post Journal Lines.
        Initialize();
        CreateTwoFixedAsset(FixedAsset);

        LibraryFixedAsset.FindFASubclass(FASubclass);
        UpdateFASubclassCode(FixedAsset[1], FASubclass.Code);
        UpdateFASubclassCode(FixedAsset[2], FASubclass.Code);

        Amount := CreatePostTwoFAAcqCost(FixedAsset);

        // 2. Exercise: Run Fixed Asset - G/L Analysis Report with Group Total as FA Subclass.
        FixedAsset[1].SetFilter("No.", '%1|%2', FixedAsset[1]."No.", FixedAsset[2]."No.");
        RunFAGLAnalysisWithGroupPrint(
          FixedAsset[1], WorkDate(), AcquisitionCostTxt, Period::" ", Period::" ", Period::" ", GroupTotals::"FA Subclass", false, false);

        // 3. Verify: Verify values on Fixed Asset - G/L Analysis Report with Group Total as FA Subclass.
        LibraryReportDataset.LoadDataSetFile();
        VerifyGroupTotalValue(AcquisitionCostTxt, Amount);
        LibraryFixedAsset.VerifyLastFARegisterGLRegisterOneToOneRelation(); // TFS 376879
    end;

    [Test]
    [HandlerFunctions('RHFAGLAnalysis')]
    [Scope('OnPrem')]
    procedure FAGLAnalysisGroupFALocation()
    var
        FixedAsset: array[2] of Record "Fixed Asset";
        FALocation: Record "FA Location";
        Amount: Decimal;
        Period: Option " ",Disposal,"Bal. Disposal";
    begin
        // Test values on Fixed Asset - G/L Analysis Report after running with Group Total as FA Location.

        // 1. Setup: Create two Fixed Asset with same FA Location, two FA Depreciation Book, General Journal Batch,
        // two Fixed Asset Journal Lines, Post Journal Lines.
        Initialize();
        CreateTwoFixedAsset(FixedAsset);

        LibraryFixedAsset.FindFALocation(FALocation);
        UpdateFALocationCode(FixedAsset[1], FALocation.Code);
        UpdateFALocationCode(FixedAsset[2], FALocation.Code);

        Amount := CreatePostTwoFAAcqCost(FixedAsset);

        // 2. Exercise: Run Fixed Asset - G/L Analysis Report with Group Total as FA Location.
        FixedAsset[1].SetFilter("No.", '%1|%2', FixedAsset[1]."No.", FixedAsset[2]."No.");
        RunFAGLAnalysisWithGroupPrint(
          FixedAsset[1], WorkDate(), AcquisitionCostTxt, Period::" ", Period::" ", Period::" ", GroupTotals::"FA Location", false, false);

        // 3. Verify: Verify values on Fixed Asset - G/L Analysis Report with Group Total as FA Location.
        LibraryReportDataset.LoadDataSetFile();
        VerifyGroupTotalValue(AcquisitionCostTxt, Amount);
        LibraryFixedAsset.VerifyLastFARegisterGLRegisterOneToOneRelation(); // TFS 376879
    end;

    [Test]
    [HandlerFunctions('RHFAGLAnalysis')]
    [Scope('OnPrem')]
    procedure FAGLAnalysisGroupMainAsset()
    var
        FixedAsset: array[2] of Record "Fixed Asset";
        FixedAsset3: Record "Fixed Asset";
        FADepreciationBook3: Record "FA Depreciation Book";
        MainAssetComponent: Record "Main Asset Component";
        Amount: Decimal;
        Period: Option " ",Disposal,"Bal. Disposal";
    begin
        // Test values on Fixed Asset - G/L Analysis Report after running with Group Total as Main Asset.

        // 1. Setup: Create Three Fixed Asset, Create Main Asset Components, two FA Depreciation Book, General Journal Batch,
        // two Fixed Asset Journal Lines, Post Journal Lines.
        Initialize();
        CreateTwoFixedAsset(FixedAsset);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset3);

        LibraryFixedAsset.CreateMainAssetComponent(MainAssetComponent, FixedAsset3."No.", FixedAsset[1]."No.");
        LibraryFixedAsset.CreateMainAssetComponent(MainAssetComponent, FixedAsset3."No.", FixedAsset[2]."No.");

        CreateFADepreciationBook(FADepreciationBook3, FixedAsset3);

        Amount := CreatePostTwoFAAcqCost(FixedAsset);

        // 2. Exercise: Run Fixed Asset - G/L Analysis Report with Group Total as Main Asset.
        FixedAsset[1].SetFilter("No.", '%1|%2', FixedAsset[1]."No.", FixedAsset[2]."No.");
        RunFAGLAnalysisWithGroupPrint(
          FixedAsset[1], WorkDate(), AcquisitionCostTxt, Period::" ", Period::" ", Period::" ", GroupTotals::"Main Asset", false, false);

        // 3. Verify: Verify values on Fixed Asset - G/L Analysis Report with Group Total as Main Asset.
        LibraryReportDataset.LoadDataSetFile();
        VerifyGroupTotalValue(AcquisitionCostTxt, Amount);
        LibraryFixedAsset.VerifyLastFARegisterGLRegisterOneToOneRelation(); // TFS 376879
    end;

    [Test]
    [HandlerFunctions('RHFAGLAnalysis')]
    [Scope('OnPrem')]
    procedure FAGLAnalysisGlobalDimension1()
    var
        DimensionValue: Record "Dimension Value";
        FixedAsset: array[2] of Record "Fixed Asset";
        GeneralLedgerSetup: Record "General Ledger Setup";
        LibraryDimension: Codeunit "Library - Dimension";
        Amount: Decimal;
        Period: Option " ",Disposal,"Bal. Disposal";
    begin
        // Test values on Fixed Asset - G/L Analysis Report after running with Group Total as Global Dimension 1.

        // 1. Setup: Create two Fixed Asset with same Global Dimension 1 Code, two FA Depreciation Book, General Journal Batch,
        // two Fixed Asset Journal Lines, Post Journal Lines.
        Initialize();
        CreateTwoFixedAsset(FixedAsset);

        GeneralLedgerSetup.Get();
        LibraryDimension.FindDimensionValue(DimensionValue, GeneralLedgerSetup."Global Dimension 1 Code");
        UpdateGlobalDimension1Code(FixedAsset[1], DimensionValue.Code);
        UpdateGlobalDimension1Code(FixedAsset[2], DimensionValue.Code);

        Amount := CreatePostTwoFAAcqCost(FixedAsset);

        // 2. Exercise: Run Fixed Asset - G/L Analysis Report with Group Total as Global Dimension 1.
        FixedAsset[1].SetFilter("No.", '%1|%2', FixedAsset[1]."No.", FixedAsset[2]."No.");
        RunFAGLAnalysisWithGroupPrint(
          FixedAsset[1], WorkDate(), AcquisitionCostTxt, Period::" ", Period::" ", Period::" ", GroupTotals::"Global Dimension 1", false, false);

        // 3. Verify: Verify values on Fixed Asset - G/L Analysis Report with Group Total as Global Dimension 1.
        LibraryReportDataset.LoadDataSetFile();
        VerifyGroupTotalValue(AcquisitionCostTxt, Amount);
        LibraryFixedAsset.VerifyLastFARegisterGLRegisterOneToOneRelation(); // TFS 376879
    end;

    [Test]
    [HandlerFunctions('RHFAGLAnalysis')]
    [Scope('OnPrem')]
    procedure FAGLAnalysisGlobalDimension2()
    var
        DimensionValue: Record "Dimension Value";
        FixedAsset: array[2] of Record "Fixed Asset";
        GeneralLedgerSetup: Record "General Ledger Setup";
        LibraryDimension: Codeunit "Library - Dimension";
        Amount: Decimal;
        Period: Option " ",Disposal,"Bal. Disposal";
    begin
        // Test values on Fixed Asset - G/L Analysis Report after running with Group Total as Global Dimension 2.

        // 1. Setup: Create two Fixed Asset with same Global Dimension 2 Code, two FA Depreciation Book, General Journal Batch,
        // two Fixed Asset Journal Lines, Post Journal Lines.
        Initialize();
        CreateTwoFixedAsset(FixedAsset);

        GeneralLedgerSetup.Get();
        LibraryDimension.FindDimensionValue(DimensionValue, GeneralLedgerSetup."Global Dimension 2 Code");
        UpdateGlobalDimension2Code(FixedAsset[1], DimensionValue.Code);
        UpdateGlobalDimension2Code(FixedAsset[2], DimensionValue.Code);

        Amount := CreatePostTwoFAAcqCost(FixedAsset);

        // 2. Exercise: Run Fixed Asset - G/L Analysis Report with Group Total as Global Dimension 2.
        FixedAsset[1].SetFilter("No.", '%1|%2', FixedAsset[1]."No.", FixedAsset[2]."No.");
        RunFAGLAnalysisWithGroupPrint(
          FixedAsset[1], WorkDate(), AcquisitionCostTxt, Period::" ", Period::" ", Period::" ", GroupTotals::"Global Dimension 2", false, false);

        // 3. Verify: Verify values on Fixed Asset - G/L Analysis Report with Group Total as Global Dimension 2.
        LibraryReportDataset.LoadDataSetFile();
        VerifyGroupTotalValue(AcquisitionCostTxt, Amount);
        LibraryFixedAsset.VerifyLastFARegisterGLRegisterOneToOneRelation(); // TFS 376879
    end;

    [Test]
    [HandlerFunctions('RHFAGLAnalysis')]
    [Scope('OnPrem')]
    procedure FAGLAnalysisFAPostingGroup()
    var
        FixedAsset: array[2] of Record "Fixed Asset";
        Period: Option " ",Disposal,"Bal. Disposal";
        Amount: Decimal;
    begin
        // Test values on Fixed Asset - G/L Analysis Report after running with Group Total as FA Posting Group.

        // 1. Setup: Create two Fixed Asset with same FA Posting Group, two FA Depreciation Book, General Journal Batch,
        // two Fixed Asset Journal Lines, Post Journal Lines.
        Initialize();
        CreateTwoFixedAsset(FixedAsset);
        AttachFAPostingGroup(FixedAsset[2], FixedAsset[1]."FA Posting Group");

        Amount := CreatePostTwoFAAcqCost(FixedAsset);

        // 2. Exercise: Run Fixed Asset - G/L Analysis Report with Group Total as FA Posting Group.
        FixedAsset[1].SetFilter("No.", '%1|%2', FixedAsset[1]."No.", FixedAsset[2]."No.");
        RunFAGLAnalysisWithGroupPrint(
          FixedAsset[1], WorkDate(), AcquisitionCostTxt, Period::" ", Period::" ", Period::" ", GroupTotals::"FA Posting Group", false, false);

        // 3. Verify: Verify values on report generated with FA Posting Group.
        LibraryReportDataset.LoadDataSetFile();
        VerifyGroupTotalValue(AcquisitionCostTxt, Amount);
    end;

    [Test]
    [HandlerFunctions('CalculateDepreciationRequestPageHandler,DepreciationCalcConfirmHandler')]
    [Scope('OnPrem')]
    procedure DepCalculationWithDecliningBalance()
    var
        FADepreciationBook: Record "FA Depreciation Book";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Test no error occurs on posting FA G/L Journal with in Fiscal Year Period.

        // Setup: Create Fixed Asset,FA Posting Group, FA Depreciation Book, Post GL Journal and Calculate Depreciation.
        Initialize();
        CreateFixedAssetWithDepreciationBook(FADepreciationBook);
        IndexationAndIntegrationInBook(FADepreciationBook."Depreciation Book Code");
        CreateAndPostGenJournalLine(FADepreciationBook);
        EnqueueValuesInCalDepReqPageHandler(FADepreciationBook, true, LibraryRandom.RandInt(10), CalcDate('<1Y>', WorkDate()));
        REPORT.Run(REPORT::"Calculate Depreciation");

        // Exercise: Post General Journal Line.
        PostDepreciationWithDocumentNo(FADepreciationBook."Depreciation Book Code", 1);

        // Verify: Check Posting will not throw any error when calculation within Fiscal year period and Verified Amount in FA Transaction.
        VerifyAmountInFATransaction(FADepreciationBook."FA No.", GenJournalLine."FA Posting Type"::"Acquisition Cost");
    end;

    [Test]
    [HandlerFunctions('CalculateDepreciationRequestPageHandler,DepreciationCalcConfirmHandler')]
    [Scope('OnPrem')]
    procedure DepCalculationWithDecliningBalanceError()
    var
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        // Test Error occurs on posting FA G/L Journal with different Fiscal Year Periods.

        // Setup: Create Fixed Asset,FA Posting Group, FA Depreciation Book, Post GL Journal and Calculate Depreciation.
        Initialize();
        CreateFixedAssetWithDepreciationBook(FADepreciationBook);
        IndexationAndIntegrationInBook(FADepreciationBook."Depreciation Book Code");
        CreateAndPostGenJournalLine(FADepreciationBook);
        EnqueueValuesInCalDepReqPageHandler(
          FADepreciationBook, true, CalcDate('<CY>', WorkDate()) - CalcDate('<CY-1Y>', WorkDate()), CalcDate('<1Y>', WorkDate()));
        REPORT.Run(REPORT::"Calculate Depreciation");

        // Exercise: Post General Journal Line.
        asserterror PostDepreciationWithDocumentNo(FADepreciationBook."Depreciation Book Code", 1);

        // Verify: Check Posting throws an error when calculation is across different Fiscal year periods.
        Assert.ExpectedError(FAJnlDepreciationPostErr);
    end;

    [Test]
    [HandlerFunctions('RHFAProjectedValue')]
    [Scope('OnPrem')]
    procedure FAProjectedBudgetDimension1()
    var
        DimensionValue: Record "Dimension Value";
        FixedAsset: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GLBudgetName: Record "G/L Budget Name";
        LibraryDimension: Codeunit "Library - Dimension";
    begin
        // Test Dimension values after running Fixed Asset Projected Value Report with Group Total as Budget Dimension 1

        // 1. Setup: Create Fixed Asset with Shortcut Dimension 3 Code, FA Depreciation Book, General Journal Batch,
        // Fixed Asset Journal Line, Post Journal Line.
        Initialize();
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        GeneralLedgerSetup.Get();
        LibraryDimension.FindDimensionValue(DimensionValue, GeneralLedgerSetup."Shortcut Dimension 3 Code");
        UpdateDimension3Code(FixedAsset, GeneralLedgerSetup."Shortcut Dimension 3 Code", DimensionValue.Code);

        CreateFADepreciationBook(FADepreciationBook, FixedAsset);

        CreateGeneralJournalBatch(GenJournalBatch);
        CreateGeneralJournalLine(GenJournalLine, GenJournalBatch, FADepreciationBook, GenJournalLine."FA Posting Type"::"Acquisition Cost");
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 2. Exercise: Run Fixed Asset Projected Value Report.
        FixedAsset.SetRange("No.", FixedAsset."No.");
        LibraryFixedAsset.CreateGLBudgetName(GLBudgetName);
        UpdateBudgetDimensionCode(GLBudgetName, GeneralLedgerSetup."Shortcut Dimension 3 Code");
        Commit();
        RunFixedAssetProjectedValue(FixedAsset, GroupTotals::"Global Dimension 1", false, false, GLBudgetName.Name, false);

        // 3. Verify: Verify values on G/L Budget Entries generated with Shortcut Dimension 3 Code.
        VerifyGLBudgetEntryDimension(GLBudgetName.Name, DimensionValue.Code);
    end;

    [Test]
    [HandlerFunctions('RHFAProjectedValue')]
    [Scope('OnPrem')]
    procedure FAProjectedBudgetEntryDefaultDim()
    var
        FixedAsset: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        GLBudgetName: Record "G/L Budget Name";
        GLBudgetEntry: Record "G/L Budget Entry";
        GroupTotals: Option " ","FA Class","FA Subclass","FA Location","Main Asset","Global Dimension 1","Global Dimension 2","FA Posting Group";
    begin
        // Test Default Dimension values on Fixed Asset Projected Value Report after running are copied to Budget.

        // 1.Setup: Create two Fixed Asset, two FA Depreciation Book, General Journal Batch,
        // two Fixed Asset Journal Lines, Post Journal Lines.
        Initialize();
        CreateFixedAssetWithGroupAndDim(FixedAsset);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset);
        CreateAndPostGenJournalLine(FADepreciationBook);

        // 2.Exercise: Run Fixed Asset Projected Value Report with Budget.
        FixedAsset.SetRange("No.", FixedAsset."No.");
        LibraryFixedAsset.CreateGLBudgetName(GLBudgetName);
        Commit();
        RunFixedAssetProjectedValue(FixedAsset, GroupTotals, false, false, GLBudgetName.Name, true);

        // 3.Verify: Verify G/L Budget Entry.
        GLBudgetEntry.SetRange("Budget Name", GLBudgetName.Name);
        GLBudgetEntry.FindSet();
        repeat
            Assert.IsTrue(GLBudgetEntry."Global Dimension 1 Code" <> '', CopyDimToBudgetEntryErr);
            Assert.IsTrue(GLBudgetEntry."Global Dimension 2 Code" <> '', CopyDimToBudgetEntryErr);
        until GLBudgetEntry.Next() = 0;
    end;

    [Test]
    [HandlerFunctions('DepreciationCalcConfirmHandler')]
    [Scope('OnPrem')]
    procedure RunCalculateDepreciationForGenJnlWithBlankDocNoTwoFA()
    var
        FADepreciationBook: Record "FA Depreciation Book";
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Calculate Depreciation]
        // [SCENARIO 352564] Run Calculate Depreciation for two fixed assets with blank Document No
        Initialize();

        // [GIVEN] Fixed asset "FA1" with aquisition cost
        CreateFixedAssetWithDepreciationBook(FADepreciationBook);
        IndexationAndIntegrationInBook(FADepreciationBook."Depreciation Book Code");
        CreateAndPostGenJournalLine(FADepreciationBook);

        // [GIVEN] Gen Journal Line has Document No "DeprDoc" after running Calculate Depreciation report for "FA1"
        RunCalculateDepreciation(
          FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code", '', true, CalcDate('<1M>', WorkDate()));
        GenJournalLine.SetRange("Account No.", FADepreciationBook."FA No.");
        GenJournalLine.FindFirst();
        DocumentNo := GenJournalLine."Document No.";

        // [GIVEN] Fixed asset "FA2" with aquisition cost
        CreateFixedAssetWithDepreciationBook(FADepreciationBook);
        IndexationAndIntegrationInBook(FADepreciationBook."Depreciation Book Code");
        CreateAndPostGenJournalLine(FADepreciationBook);

        // [WHEN]  Run Calculate Depreciation report for "FA2"
        RunCalculateDepreciation(
          FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code", '', true, CalcDate('<1M>', WorkDate()));

        // [THEN] Gen Journal Line has Document No "DeprDoc" in the same journal for "FA2"
        GenJournalLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        GenJournalLine.SetRange("Account No.", FADepreciationBook."FA No.");
        GenJournalLine.FindFirst();
        GenJournalLine.TestField("Document No.", DocumentNo);
    end;

    [Test]
    [HandlerFunctions('CalculateDepreciationRequestPostingDatePageHandler')]
    [Scope('OnPrem')]
    procedure CalculateDepreciationRunBackgroundDateCheck()
    var
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        ClientTypeManagement: Codeunit "Client Type Management";
        CalculateDepreciation: Report "Calculate Depreciation";
        OldClientType: ClientType;
    begin
        // [SCENARIO 408658] Calculate Depreciation, when scheduled should use saved dates instead workdate(it was real date before)
        Initialize();

        // [GIVEN] Calculate Depreciation is initialized with Posting Date/FA Posting Date = WorkDate() + 1 day
        CalculateDepreciation.InitializeRequest('', WorkDate() + 1, false, 0, WorkDate() + 1, '', '', false);

        // [WHEN] Calculate Depreciation request page is opened 
        CalculateDepreciation.UseRequestPage(true);
        CalculateDepreciation.Run();

        // [THEN] "Posting Date"/"FA Posting Date" on request page = Workdate
        Assert.AreEqual(WorkDate(), LibraryVariableStorage.DequeueDate(), 'Wrong FA Posting Date');
        Assert.AreEqual(WorkDate(), LibraryVariableStorage.DequeueDate(), 'Wrong Posting Date');

        // [GIVEN] Client type = background
        BindSubscription(TestClientTypeSubscriber);
        OldClientType := ClientTypeManagement.GetCurrentClientType();
        TestClientTypeSubscriber.SetClientType(ClientType::Background);

        // [GIVEN] Calculate Depreciation is initialized with Posting Date/FA Posting Date = WorkDate() + 1 day
        CalculateDepreciation.InitializeRequest('', WorkDate() + 1, false, 0, WorkDate() + 1, '', '', false);

        // [WHEN] Calculated Depreciation request page is opened in background (simulate scheduled report)
        CalculateDepreciation.Run();

        // [THEN] "Posting Date"/"FA Posting Date" on request page = WorkDate() + 1
        Assert.AreEqual(WorkDate() + 1, LibraryVariableStorage.DequeueDate(), 'Wrong FA Posting Date');
        Assert.AreEqual(WorkDate() + 1, LibraryVariableStorage.DequeueDate(), 'Wrong Posting Date');

        // tear down
        TestClientTypeSubscriber.SetClientType(OldClientType);
        UnbindSubscription(TestClientTypeSubscriber);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Fixed Assets Reports - II");
        Clear(LibraryReportDataset);
        LibraryVariableStorage.Clear();

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Fixed Assets Reports - II");

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Fixed Assets Reports - II");
    end;

    local procedure AttachFAPostingGroup(var FixedAsset: Record "Fixed Asset"; FAPostingGroup: Code[20])
    begin
        FixedAsset.Validate("FA Posting Group", FAPostingGroup);
        FixedAsset.Modify(true);
    end;

    [Test]
    [HandlerFunctions('DepreciationCalcConfirmHandler')]
    [Scope('OnPrem')]
    procedure CalculateAndPostDepreciationWithMultipleFiscalYearPeriods()
    begin
        // Test Depreciation can be post successfully when Depreciation Period not across Fiscal Year Periods.
        CalculateAndPostDepreciationWithFiscalYearPeriods(false); // Not Across Fiscal Year Periods.
    end;

    [Test]
    [HandlerFunctions('DepreciationCalcConfirmHandler')]
    [Scope('OnPrem')]
    procedure CalculateAndPostDepreciationAcrossDifferentFiscalYearPeriods()
    begin
        // Test Depreciation cannot post successfully when Depreciation Period across different Fiscal Year Periods.
        asserterror CalculateAndPostDepreciationWithFiscalYearPeriods(true); // Across Fiscal Year Periods.
        Assert.ExpectedError(FAJnlDepreciationPostErr);
    end;

    local procedure CalculateAndPostDepreciationWithFiscalYearPeriods(AcrossFiscalYear: Boolean)
    var
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        FALedgerEntry: Record "FA Ledger Entry";
        FixedAssetNo: Code[20];
        DepreciationStartingDate: Date;
        NewPostingDate: array[3] of Date;
        i: Integer;
    begin
        // Setup: Create Accounting Periods with every month is a New Fiscal Year
        Initialize();
        CreateAccountingPeriodsWithNewFiscalYear(DepreciationStartingDate);

        // Create a Fix Asset with "Declining-Balance 1" and "Depreciation Starting Date"
        FixedAssetNo := CreateFAWithDepreciationMethod(FADepreciationBook, DepreciationBook, DepreciationStartingDate);

        // Post the Acquisition Cost for the new asset
        IndexationAndIntegrationInBook(DepreciationBook.Code);
        CreateAndPostGenJournalLine(FADepreciationBook);

        // Exercise: Run the Calculate Depreciation and post FA Journal Line - Repeat 3 times to cover the condition of month with 28,29 or 30 days
        for i := 1 to 3 do
            NewPostingDate[i] := CalcDate(StrSubstNo('<%1M - 1M + CM>', i), DepreciationStartingDate);
        if AcrossFiscalYear then
            NewPostingDate[3] := CalcDate('<2M + CM + 1D>', DepreciationStartingDate);

        for i := 1 to ArrayLen(NewPostingDate) do begin
            DeleteGeneralJournalLine(DepreciationBook.Code);
            RunCalculateDepreciation(FixedAssetNo, DepreciationBook.Code, FixedAssetNo, true, NewPostingDate[i]);
            PostDepreciationWithDocumentNo(DepreciationBook.Code, i);
        end;

        // Verify: Verify FA Posting Date is correct in FA Entry
        FindFALedgerEntry(FALedgerEntry, FixedAssetNo, FALedgerEntry."FA Posting Type"::Depreciation);
        for i := 1 to ArrayLen(NewPostingDate) do begin
            Assert.AreEqual(NewPostingDate[i], FALedgerEntry."FA Posting Date", StrSubstNo(FAPostingDateErr, FixedAssetNo));
            FALedgerEntry.Next();
        end;
    end;

    local procedure CreateAccountingPeriodsWithNewFiscalYear(var StartingDate: Date)
    var
        AccountingPeriod: Record "Accounting Period";
        i: Integer;
    begin
        // Create Fiscal Year.
        LibraryFiscalYear.CloseAccountingPeriod();
        LibraryFiscalYear.CreateFiscalYear();
        FindAccountingPeriod(AccountingPeriod);
        while not (AccountingPeriod."Starting Date" >= WorkDate()) do
            AccountingPeriod.Next(); // Cannot Calculate FA Depreciation if Depreciation Date earlier than Workdate
        StartingDate := AccountingPeriod."Starting Date";

        // For first 4 months, mark "New Fiscal Year Period" as true.
        for i := 1 to 4 do begin
            UpdateAccountingPeriodForNewFiscalYear(AccountingPeriod, true);
            AccountingPeriod.Next();
        end;
    end;

    local procedure CreateFAWithDepreciationMethod(var FADepreciationBook: Record "FA Depreciation Book"; var DepreciationBook: Record "Depreciation Book"; DepreciationStartingDate: Date): Code[20]
    var
        FixedAsset: Record "Fixed Asset";
    begin
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateJournalSetupDepreciation(DepreciationBook);
        CreateFADepBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", DepreciationBook.Code);
        UpdateFADepreciationBook(FADepreciationBook);
        UpdateFADepreciationBookForDepreciationStartingDate(FADepreciationBook, DepreciationStartingDate);

        exit(FixedAsset."No.");
    end;

    local procedure CreateDepreciationBook(): Code[10]
    var
        DepreciationBook: Record "Depreciation Book";
    begin
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        DepreciationBook.Validate("Use Rounding in Periodic Depr.", true);
        DepreciationBook.Validate("G/L Integration - Acq. Cost", true);
        DepreciationBook.Validate("G/L Integration - Depreciation", true);
        DepreciationBook.Validate("G/L Integration - Write-Down", true);
        DepreciationBook.Validate("G/L Integration - Appreciation", true);
        DepreciationBook.Validate("G/L Integration - Custom 1", true);
        DepreciationBook.Validate("G/L Integration - Custom 2", true);
        DepreciationBook.Validate("G/L Integration - Disposal", true);
        DepreciationBook.Validate("G/L Integration - Maintenance", true);
        DepreciationBook.Modify(true);
        exit(DepreciationBook.Code);
    end;

    local procedure CreateFADepreciationBookWithProjectedDisposal(var FADepreciationBook: Record "FA Depreciation Book"; FixedAsset: Record "Fixed Asset")
    var
        DepreciationBook: Record "Depreciation Book";
    begin
        DepreciationBook.Get(LibraryFixedAsset.GetDefaultDeprBook());
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", DepreciationBook.Code);
        FADepreciationBook.Validate("Depreciation Starting Date", WorkDate());
        FADepreciationBook.Validate("Depreciation Ending Date", CalcDate(StrSubstNo('<%1Y>', LibraryRandom.RandInt(5)), WorkDate()));
        FADepreciationBook.Validate("FA Posting Group", FixedAsset."FA Posting Group");
        FADepreciationBook.Validate("Projected Disposal Date", WorkDate());
        FADepreciationBook.Validate("Projected Proceeds on Disposal", LibraryRandom.RandDec(100, 2));
        FADepreciationBook.Modify(true);
    end;

    local procedure CreateFADepreciationBook(var FADepreciationBook: Record "FA Depreciation Book"; FixedAsset: Record "Fixed Asset")
    var
        DepreciationBook: Record "Depreciation Book";
    begin
        DepreciationBook.Get(LibraryFixedAsset.GetDefaultDeprBook());
        DepreciationBook.Validate("Use Custom 1 Depreciation", true);
        DepreciationBook.Modify(true);
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", DepreciationBook.Code);
        FADepreciationBook.Validate("Depreciation Starting Date", WorkDate());

        // Random Number Generator for Ending date.
        FADepreciationBook.Validate("Depreciation Ending Date", CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'Y>', WorkDate()));
        FADepreciationBook.Validate("FA Posting Group", FixedAsset."FA Posting Group");
        FADepreciationBook.Modify(true);
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

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; FADepreciationBook: Record "FA Depreciation Book"; FAPostingType: Enum "Gen. Journal Line FA Posting Type")
    begin
        // Random Number Generator for Amount.
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"Fixed Asset", FADepreciationBook."FA No.", LibraryRandom.RandDec(10000, 2));
        PostingSetupFAGLJournalLine(GenJournalLine, FAPostingType, FADepreciationBook."Depreciation Book Code");
    end;

    local procedure CreateNegativeFAGeneralLine(var GenJournalLine: Record "Gen. Journal Line"; DepreciationBookCode: Code[10]; FAPostingType: Enum "Gen. Journal Line FA Posting Type")
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"Fixed Asset", GenJournalLine."Account No.", -GenJournalLine.Amount / 2);
        PostingSetupFAGLJournalLine(GenJournalLine, FAPostingType, DepreciationBookCode);
    end;

    local procedure BalanceAccountFAGLJournalLine(var GenJournalLine: Record "Gen. Journal Line")
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GenJournalLine.Validate("Bal. Account No.", GLAccount."No.");
        GenJournalLine.Modify(true);
    end;

    local procedure CreateAndPostGenJournalLine(FADepreciationBook: Record "FA Depreciation Book")
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateAndUpdateJournalLine(
          GenJournalLine, FADepreciationBook."FA No.",
          FADepreciationBook."Depreciation Book Code", GenJournalLine."FA Posting Type"::"Acquisition Cost");
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndPostFAGenJournalLine(FADepreciationBook: Record "FA Depreciation Book"; FADepreciationBook2: Record "FA Depreciation Book")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateGeneralJournalBatch(GenJournalBatch);
        CreateGeneralJournalLine(GenJournalLine, GenJournalBatch, FADepreciationBook, GenJournalLine."FA Posting Type"::"Acquisition Cost");
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, FADepreciationBook2, GenJournalLine."FA Posting Type"::"Acquisition Cost");
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateFixedAssetWithDepreciationBook(var FADepreciationBook: Record "FA Depreciation Book")
    var
        DepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
    begin
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateJournalSetupDepreciation(DepreciationBook);
        CreateFADepBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", DepreciationBook.Code);
        UpdateFADepreciationBook(FADepreciationBook);
    end;

    local procedure CreateAndUpdateJournalLine(var GenJournalLine: Record "Gen. Journal Line"; FixedAssetNo: Code[20]; DepreciationBookCode: Code[10]; FAPostingType: Enum "Gen. Journal Line FA Posting Type")
    begin
        CreateFAGLJournal(GenJournalLine, FixedAssetNo, DepreciationBookCode, FAPostingType);
        BalanceAccountFAGLJournalLine(GenJournalLine);
    end;

    local procedure CreateJournalSetupDepreciation(var DepreciationBook: Record "Depreciation Book")
    var
        FAJournalSetup: Record "FA Journal Setup";
    begin
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        LibraryFixedAsset.CreateFAJournalSetup(FAJournalSetup, DepreciationBook.Code, '');
        UpdateFAJournalSetup(FAJournalSetup);
    end;

    local procedure CreateFADepBook(var FADepreciationBook: Record "FA Depreciation Book"; FANo: Code[20]; FAPostingGroupCode: Code[20]; DepreciationBookCode: Code[10])
    begin
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FANo, DepreciationBookCode);
        FADepreciationBook.Validate("FA Posting Group", FAPostingGroupCode);
        FADepreciationBook.Validate("Depreciation Starting Date", WorkDate());

        // Depreciation Ending Date greater than Depreciation Starting Date, Using the Random Number for the Year.
        FADepreciationBook.Validate("Depreciation Ending Date", CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'Y>', WorkDate()));
        FADepreciationBook.Modify(true);
    end;

    local procedure CreateFAGLJournal(var GenJournalLine: Record "Gen. Journal Line"; AccountNo: Code[20]; DepreciationBookCode: Code[10]; FAPostingType: Enum "Gen. Journal Line FA Posting Type")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type",
          GenJournalLine."Account Type"::"Fixed Asset",
          AccountNo, LibraryRandom.RandInt(1000));  // Using Random Number Generator for Amount.
        GenJournalLine.Validate("Depreciation Book Code", DepreciationBookCode);
        GenJournalLine.Validate("FA Posting Type", FAPostingType);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Recurring, false);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        GenJournalBatch.Modify(true);
    end;

    local procedure CreateFixedAssetWithGroupAndDim(var FixedAsset: Record "Fixed Asset")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        DimensionValue: Record "Dimension Value";
        LibraryDimension: Codeunit "Library - Dimension";
    begin
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        GeneralLedgerSetup.Get();
        LibraryDimension.FindDimensionValue(DimensionValue, GeneralLedgerSetup."Global Dimension 1 Code");
        UpdateGlobalDimension1Code(FixedAsset, DimensionValue.Code);
        LibraryDimension.FindDimensionValue(DimensionValue, GeneralLedgerSetup."Global Dimension 2 Code");
        UpdateGlobalDimension2Code(FixedAsset, DimensionValue.Code);
    end;

    local procedure CreateTwoFixedAsset(var FixedAsset: array[2] of Record "Fixed Asset")
    var
        i: Integer;
    begin
        for i := 1 to ArrayLen(FixedAsset) do
            LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset[i]);
    end;

    local procedure CreatePostTwoFAAcqCost(FixedAsset: array[2] of Record "Fixed Asset") Amount: Decimal
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        FADepreciationBook: array[2] of Record "FA Depreciation Book";
        i: Integer;
    begin
        CreateGeneralJournalBatch(GenJournalBatch);
        for i := 1 to ArrayLen(FixedAsset) do begin
            CreateFADepreciationBook(FADepreciationBook[i], FixedAsset[i]);
            CreateGeneralJournalLine(
              GenJournalLine, GenJournalBatch, FADepreciationBook[i], GenJournalLine."FA Posting Type"::"Acquisition Cost");
            Amount += GenJournalLine.Amount;
        end;
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure DeleteGeneralJournalLine(DepreciationBookCode: Code[10])
    var
        GenJournalLine: Record "Gen. Journal Line";
        FAJournalSetup: Record "FA Journal Setup";
    begin
        FAJournalSetup.Get(DepreciationBookCode, '');
        GenJournalLine.SetRange("Journal Template Name", FAJournalSetup."Gen. Jnl. Template Name");
        GenJournalLine.SetRange("Journal Batch Name", FAJournalSetup."Gen. Jnl. Batch Name");
        GenJournalLine.DeleteAll(true);
    end;

    local procedure EnqueueValuesInCalDepReqPageHandler(FADepreciationBook: Record "FA Depreciation Book"; UseForceNoOfDays: Boolean; ForceNoOfDays: Integer; PostingDate: Date)
    begin
        LibraryVariableStorage.Enqueue(FADepreciationBook."Depreciation Book Code");
        LibraryVariableStorage.Enqueue(FADepreciationBook."FA No.");
        LibraryVariableStorage.Enqueue(UseForceNoOfDays);
        LibraryVariableStorage.Enqueue(ForceNoOfDays);
        LibraryVariableStorage.Enqueue(PostingDate);
    end;

    local procedure FindAccountingPeriod(var AccountingPeriod: Record "Accounting Period")
    begin
        AccountingPeriod.SetRange("New Fiscal Year", false);
        AccountingPeriod.SetRange(Closed, false);
        AccountingPeriod.SetRange("Date Locked", false);
        AccountingPeriod.FindFirst();
    end;

    local procedure FindFALedgerEntry(var FALedgerEntry: Record "FA Ledger Entry"; FANo: Code[20]; FAPostingType: Enum "FA Ledger Entry FA Posting Type")
    begin
        FALedgerEntry.SetRange("FA No.", FANo);
        FALedgerEntry.SetRange("FA Posting Type", FAPostingType);
        FALedgerEntry.FindFirst();
    end;

    local procedure GetDepreciationAmount(FADepreciationBook: Record "FA Depreciation Book"): Decimal
    begin
        // Using Round with 1 for Projected Depreciation in Report.
        exit(Round(FADepreciationBook."Book Value" / FADepreciationBook."No. of Depreciation Months", 1));
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
        DepreciationBook.Validate("Use Same FA+G/L Posting Dates", true);
        DepreciationBook.Modify(true);
    end;

    local procedure PostingSetupFAGLJournalLine(var GenJournalLine: Record "Gen. Journal Line"; FAPostingType: Enum "Gen. Journal Line FA Posting Type"; DepreciationBookCode: Code[10])
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.FindGLAccount(GLAccount);

        // Value of Document No. is not important.
        GenJournalLine.Validate("Document No.", GenJournalLine."Journal Batch Name" + Format(GenJournalLine."Line No."));
        GenJournalLine.Validate("FA Posting Type", FAPostingType);
        GenJournalLine.Validate("Depreciation Book Code", DepreciationBookCode);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", GLAccount."No.");
        GenJournalLine.Modify(true);
    end;

    local procedure RunCalculateDepreciation(No: Code[20]; DepreciationBookCode: Code[10]; DocumentNo: Code[20]; BalAccount: Boolean; NewPostingDate: Date)
    var
        FixedAsset: Record "Fixed Asset";
        CalculateDepreciation: Report "Calculate Depreciation";
    begin
        Clear(CalculateDepreciation);
        FixedAsset.SetRange("No.", No);

        CalculateDepreciation.SetTableView(FixedAsset);
        CalculateDepreciation.InitializeRequest(
          DepreciationBookCode, NewPostingDate, false, 0, NewPostingDate, DocumentNo, FixedAsset.Description, BalAccount);
        CalculateDepreciation.UseRequestPage(false);
        CalculateDepreciation.Run();
    end;

    local procedure RunFixedAssetProjectedValue(var FixedAsset: Record "Fixed Asset"; GroupTotals: Option; PrintDetails: Boolean; ProjectedDisposal: Boolean; BudgetNameCode: Code[10]; InsertBalanceAccount: Boolean)
    var
        FixedAssetProjectedValue: Report "Fixed Asset - Projected Value";
    begin
        Clear(FixedAssetProjectedValue);
        FixedAssetProjectedValue.SetTableView(FixedAsset);
        FixedAssetProjectedValue.SetMandatoryFields('', WorkDate(), WorkDate());
        FixedAssetProjectedValue.GetFASetup();
        FixedAssetProjectedValue.SetTotalFields(GroupTotals, PrintDetails);

        // 30 for days in first period.
        FixedAssetProjectedValue.SetPeriodFields(0, 30, WorkDate(), false);
        FixedAssetProjectedValue.SetBudgetField(BudgetNameCode, InsertBalanceAccount, ProjectedDisposal, false);
        FixedAssetProjectedValue.Run();
    end;

    local procedure RunFAProjectedValueMultiLines(var FixedAsset: Record "Fixed Asset"; GroupTotals: Option; PrintDetails: Boolean; ProjectedDisposal: Boolean; BudgetNameCode: Code[10]; InsertBalanceAccount: Boolean)
    var
        FixedAssetProjectedValue: Report "Fixed Asset - Projected Value";
    begin
        Clear(FixedAssetProjectedValue);
        FixedAssetProjectedValue.SetTableView(FixedAsset);
        FixedAssetProjectedValue.SetMandatoryFields('', CalcDate('<-CY>', WorkDate()), CalcDate('<CY>', WorkDate()));
        FixedAssetProjectedValue.GetFASetup();
        FixedAssetProjectedValue.SetTotalFields(GroupTotals, PrintDetails);

        FixedAssetProjectedValue.SetPeriodFields(0, 0, 0D, true);
        FixedAssetProjectedValue.SetBudgetField(BudgetNameCode, InsertBalanceAccount, ProjectedDisposal, true);
        FixedAssetProjectedValue.Run();
    end;

    local procedure RunFAGLAnalysisWithPeriod(FixedAssetNo: Code[20]; DepreciationBookCode: Code[10]; StartingDate: Date; EndingDate: Date; PostingType1: Text[30]; PostingType2: Text[30]; PostingType3: Text[30]; Period: Option; GroupTotals: Option; OnlySoldAssets: Boolean)
    var
        FixedAssetGLAnalysis: Report "Fixed Asset - G/L Analysis";
    begin
        Clear(FixedAssetGLAnalysis);
        LibraryVariableStorage.Enqueue(FixedAssetNo);
        LibraryVariableStorage.Enqueue(DepreciationBookCode);
        LibraryVariableStorage.Enqueue(StartingDate);
        LibraryVariableStorage.Enqueue(EndingDate);
        LibraryVariableStorage.Enqueue(GLAcquisitionDateTxt);
        LibraryVariableStorage.Enqueue(GLAcquisitionDateTxt);
        LibraryVariableStorage.Enqueue(PostingType1);
        LibraryVariableStorage.Enqueue(PostingType2);
        LibraryVariableStorage.Enqueue(PostingType3);
        LibraryVariableStorage.Enqueue(Period);
        LibraryVariableStorage.Enqueue(GroupTotals);
        LibraryVariableStorage.Enqueue(OnlySoldAssets);
        Commit();
        FixedAssetGLAnalysis.Run();
    end;

    local procedure RunFAGLAnalysisWithGroupPrint(var FixedAsset: Record "Fixed Asset"; StartingDate: Date; PostingType1: Text[30]; Period1: Option; Period2: Option; Period3: Option; GroupTotals: Option; PrintDetails: Boolean; SalesReport: Boolean)
    var
        FixedAssetGLAnalysis: Report "Fixed Asset - G/L Analysis";
    begin
        LibraryVariableStorage.Enqueue(StartingDate);
        LibraryVariableStorage.Enqueue(WorkDate());
        LibraryVariableStorage.Enqueue(GLAcquisitionDateTxt);
        LibraryVariableStorage.Enqueue(GLAcquisitionDateTxt);
        LibraryVariableStorage.Enqueue(PostingType1);
        LibraryVariableStorage.Enqueue(Period1);
        LibraryVariableStorage.Enqueue(Period2);
        LibraryVariableStorage.Enqueue(Period3);
        LibraryVariableStorage.Enqueue(GroupTotals);
        LibraryVariableStorage.Enqueue(PrintDetails);
        LibraryVariableStorage.Enqueue(SalesReport);
        FixedAssetGLAnalysis.GetFASetup();
        Commit();
        REPORT.Run(REPORT::"Fixed Asset - G/L Analysis", true, false, FixedAsset);
    end;

    local procedure PostDepreciationWithDocumentNo(DepreciationBookCode: Code[10]; CountPostDepreciationNumber: Integer)
    var
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        FAJournalSetup: Record "FA Journal Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        NoSeries: Codeunit "No. Series";
        DocumentNo: Code[20];
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        FAJournalSetup.Get(DepreciationBookCode, '');
        GenJournalLine.SetRange("Journal Template Name", FAJournalSetup."Gen. Jnl. Template Name");
        GenJournalLine.SetRange("Journal Batch Name", FAJournalSetup."Gen. Jnl. Batch Name");
        GenJournalLine.FindSet();
        GenJournalBatch.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name");
        if CountPostDepreciationNumber <= 1 then begin
            GenJournalBatch.Validate("No. Series", LibraryERM.CreateNoSeriesCode());
            GenJournalBatch.Modify(true);
        end;
        DocumentNo := NoSeries.PeekNextNo(GenJournalBatch."No. Series");
        repeat
            GenJournalLine.Validate("Document No.", DocumentNo);
            GenJournalLine.Validate(Description, FAJournalSetup."Gen. Jnl. Batch Name");
            GenJournalLine.Validate("FA Posting Date", GenJournalLine."Posting Date");
            GenJournalLine.Validate("Bal. Account No.", GLAccount."No.");
            GenJournalLine.Modify(true);
        until GenJournalLine.Next() = 0;
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure UpdateAccountingPeriodForNewFiscalYear(var AccountingPeriod: Record "Accounting Period"; NewFiscalYear: Boolean)
    begin
        AccountingPeriod.Validate("New Fiscal Year", NewFiscalYear);
        AccountingPeriod.Modify(true);
    end;

    local procedure UpdateFADepreciationBookForDepreciationStartingDate(var FADepreciationBook: Record "FA Depreciation Book"; DepreciationStartingDate: Date)
    begin
        FADepreciationBook.Validate("Depreciation Starting Date", DepreciationStartingDate);
        FADepreciationBook.Modify(true);
    end;

    local procedure UpdateDocumentNoOnJournalLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentNo: Code[20])
    begin
        GenJournalLine.Validate("Document No.", DocumentNo);
        GenJournalLine.Modify(true);
    end;

    local procedure UpdateFAClassCode(FixedAsset: Record "Fixed Asset"; FAClassCode: Code[10])
    begin
        FixedAsset.Validate("FA Class Code", FAClassCode);
        FixedAsset.Modify(true);
    end;

    local procedure UpdateFALocationCode(FixedAsset: Record "Fixed Asset"; FALocationCode: Code[10])
    begin
        FixedAsset.Validate("FA Location Code", FALocationCode);
        FixedAsset.Modify(true);
    end;

    local procedure UpdateFASubclassCode(FixedAsset: Record "Fixed Asset"; FASubclassCode: Code[10])
    begin
        FixedAsset.Validate("FA Subclass Code", FASubclassCode);
        FixedAsset.Modify(true);
    end;

    local procedure UpdateFASetup(DefaultDeprBook: Code[10]) OldDefaultDeprBook: Code[10]
    var
        FASetup: Record "FA Setup";
    begin
        FASetup.Get();
        OldDefaultDeprBook := FASetup."Default Depr. Book";
        FASetup.Validate("Default Depr. Book", DefaultDeprBook);
        FASetup.Modify(true);
    end;

    local procedure UpdateGlobalDimension1Code(FixedAsset: Record "Fixed Asset"; GlobalDimension1Code: Code[20])
    begin
        FixedAsset.Validate("Global Dimension 1 Code", GlobalDimension1Code);
        FixedAsset.Modify(true);
    end;

    local procedure UpdateGlobalDimension2Code(FixedAsset: Record "Fixed Asset"; GlobalDimension2Code: Code[20])
    begin
        FixedAsset.Validate("Global Dimension 2 Code", GlobalDimension2Code);
        FixedAsset.Modify(true);
    end;

    local procedure UpdateDimension3Code(FixedAsset: Record "Fixed Asset"; DimensionCode: Code[20]; DimensionValue: Code[20])
    var
        DefaultDimension: Record "Default Dimension";
    begin
        DefaultDimension.Init();
        DefaultDimension.Validate("Table ID", DATABASE::"Fixed Asset");
        DefaultDimension.Validate("No.", FixedAsset."No.");
        DefaultDimension.Validate("Dimension Code", DimensionCode);
        DefaultDimension.Validate("Dimension Value Code", DimensionValue);
        DefaultDimension.Insert();
    end;

    local procedure UpdateMaintenanceOnFixedAsset(var FixedAsset: Record "Fixed Asset")
    var
        Vendor: Record Vendor;
        LibraryPurchase: Codeunit "Library - Purchase";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        FixedAsset.Validate("Maintenance Vendor No.", Vendor."No.");
        FixedAsset.Validate("Under Maintenance", true);
        FixedAsset.Validate("Next Service Date", WorkDate());
        FixedAsset.Modify(true);
    end;

    local procedure UpdateMaintenanceOnJournalLine(var GenJournalLine: Record "Gen. Journal Line"; MaintenanceCode: Code[10])
    begin
        GenJournalLine.Validate("Maintenance Code", MaintenanceCode);
        GenJournalLine.Modify(true);
    end;

    local procedure UpdateFADepreciationBook(var FADepreciationBook: Record "FA Depreciation Book")
    begin
        FADepreciationBook.Validate("Depreciation Method", FADepreciationBook."Depreciation Method"::"Declining-Balance 1");
        FADepreciationBook.Validate("Declining-Balance %", LibraryRandom.RandDec(10, 2));
        FADepreciationBook.Modify(true);
    end;

    local procedure UpdateFAJournalSetup(var FAJournalSetup: Record "FA Journal Setup")
    var
        FAJournalSetup2: Record "FA Journal Setup";
    begin
        FAJournalSetup2.SetRange("Depreciation Book Code", LibraryFixedAsset.GetDefaultDeprBook());
        FAJournalSetup2.FindFirst();
        FAJournalSetup.TransferFields(FAJournalSetup2, false);
        FAJournalSetup.Modify(true);
    end;

    local procedure UpdateBudgetDimensionCode(var GLBudgetName: Record "G/L Budget Name"; BudgetDimension1Code: Code[20])
    begin
        GLBudgetName.Validate("Budget Dimension 1 Code", BudgetDimension1Code);
        GLBudgetName.Modify();
    end;

    local procedure ModifyAccountingPeriod(var NewDate: Date; var NoOfDays: Integer)
    var
        AccountingPeriod: Record "Accounting Period";
        Month: Integer;
    begin
        AccountingPeriod.ModifyAll("Date Locked", false);
        Month := LibraryRandom.RandIntInRange(3, 7);
        if Month mod 2 = 0 then
            Month += 1;
        NewDate := DMY2Date(31, Month, Date2DMY(WorkDate(), 3));
        AccountingPeriod.Validate("Starting Date", NewDate);
        if not AccountingPeriod.Get(AccountingPeriod."Starting Date") then
            AccountingPeriod.Insert(true);
        Commit();
        AccountingPeriod.Next(-1);
        NoOfDays := NewDate - AccountingPeriod."Starting Date";
    end;

    local procedure VerifyFAProjectedValueTotal(FADepreciationBook: Record "FA Depreciation Book"; FADepreciationBook2: Record "FA Depreciation Book")
    var
        Amount: Decimal;
        Amount2: Decimal;
    begin
        FADepreciationBook.CalcFields("Book Value");
        FADepreciationBook2.CalcFields("Book Value");

        Amount := GetDepreciationAmount(FADepreciationBook);
        Amount2 := GetDepreciationAmount(FADepreciationBook2);

        LibraryReportDataset.AssertElementWithValueExists('TotalBookValue2',
          FADepreciationBook."Book Value" - Amount + FADepreciationBook2."Book Value" - Amount2);
        LibraryReportDataset.AssertElementWithValueExists('TotalAmounts1', -Amount - Amount2);
    end;

    local procedure VerifyFixedAssetDocument(FANo: Code[20])
    var
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        FALedgerEntry.SetRange("FA No.", FANo);
        FALedgerEntry.FindFirst();
        LibraryReportDataset.SetRange('FALedgEntry__FA_No__', FANo);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('FALedgEntry__Document_No__', FALedgerEntry."Document No.");
    end;

    local procedure VerifyFixedAssetRegisterLine(FANo: Code[20])
    var
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        FALedgerEntry.SetRange("FA No.", FANo);
        FALedgerEntry.FindFirst();
        LibraryReportDataset.SetRange('FA_Ledger_Entry__FA_No__', FANo);
        LibraryReportDataset.GetNextRow();

        LibraryReportDataset.AssertCurrentRowValueEquals('FA_Ledger_Entry_Amount', FALedgerEntry.Amount);
        LibraryReportDataset.AssertCurrentRowValueEquals('FA_Ledger_Entry__G_L_Entry_No__', FALedgerEntry."G/L Entry No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('FA_Ledger_Entry__Entry_No__', FALedgerEntry."Entry No.");
    end;

    local procedure VerifyGroupTotalValue(ColumnCaption: Text[30]; TotalAmountExpected: Decimal)
    var
        TotalAmountActual: Decimal;
    begin
        TotalAmountActual := LibraryReportDataset.Sum('Amounts1');
        Assert.AreEqual(TotalAmountExpected, TotalAmountActual, StrSubstNo(ValidationErr, ColumnCaption, TotalAmountActual));
    end;

    local procedure VerifyMaintenanceNextService(FixedAsset: Record "Fixed Asset")
    begin
        LibraryReportDataset.SetRange('Fixed_Asset__No__', FixedAsset."No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('Fixed_Asset__Next_Service_Date_', Format(FixedAsset."Next Service Date"));
    end;

    local procedure VerifyMaintenanceRegisterLine(MaintenanceCode: Code[10])
    var
        MaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
    begin
        MaintenanceLedgerEntry.SetRange("Maintenance Code", MaintenanceCode);
        MaintenanceLedgerEntry.FindFirst();
        LibraryReportDataset.SetRange('Maintenance_Ledger_Entry__Maintenance_Code_', MaintenanceCode);
        LibraryReportDataset.GetNextRow();

        LibraryReportDataset.AssertCurrentRowValueEquals(
          'Maintenance_Ledger_Entry__Document_No__', MaintenanceLedgerEntry."Document No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('Maintenance_Ledger_Entry__Depreciation_Book_Code_',
          MaintenanceLedgerEntry."Depreciation Book Code");
        LibraryReportDataset.AssertCurrentRowValueEquals('Maintenance_Ledger_Entry__FA_No__', MaintenanceLedgerEntry."FA No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('Maintenance_Ledger_Entry_Amount', MaintenanceLedgerEntry.Amount);
        LibraryReportDataset.AssertCurrentRowValueEquals('Maintenance_Ledger_Entry__G_L_Entry_No__',
          MaintenanceLedgerEntry."G/L Entry No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('Maintenance_Ledger_Entry__Entry_No__', MaintenanceLedgerEntry."Entry No.");
    end;

    local procedure VerifyProjectedDisposalTotal(FADepreciationBook: Record "FA Depreciation Book"; FADepreciationBook2: Record "FA Depreciation Book")
    var
        Amount: Decimal;
        Amount2: Decimal;
        TotalBookValue: Decimal;
        TotalAmountValue: Decimal;
    begin
        FADepreciationBook.CalcFields("Book Value");
        FADepreciationBook2.CalcFields("Book Value");

        Amount := GetDepreciationAmount(FADepreciationBook);
        Amount2 := GetDepreciationAmount(FADepreciationBook2);
        TotalBookValue := FADepreciationBook."Book Value" - Amount + FADepreciationBook2."Book Value" - Amount2 -
          FADepreciationBook."Projected Proceeds on Disposal" - FADepreciationBook2."Projected Proceeds on Disposal";
        TotalAmountValue :=
          FADepreciationBook."Projected Proceeds on Disposal" + FADepreciationBook2."Projected Proceeds on Disposal";

        LibraryReportDataset.AssertElementWithValueExists('TotalBookValue2', TotalBookValue);
        LibraryReportDataset.AssertElementWithValueExists('TotalAmounts2', TotalAmountValue);
    end;

    local procedure VerifyProjectedGroupValue(FADepreciationBook: Record "FA Depreciation Book"; FADepreciationBook2: Record "FA Depreciation Book")
    var
        TotalDepCustomAmt: Decimal;
    begin
        FADepreciationBook.CalcFields("Book Value");
        FADepreciationBook2.CalcFields("Book Value");
        TotalDepCustomAmt := GetDepreciationAmount(FADepreciationBook) + GetDepreciationAmount(FADepreciationBook2);
        LibraryReportDataset.AssertElementWithValueExists('GroupAmounts_1', -TotalDepCustomAmt);
    end;

    local procedure VerifyValuesOnGroupTotal(FADepreciationBook: Record "FA Depreciation Book"; FADepreciationBook2: Record "FA Depreciation Book")
    var
        Amount: Decimal;
        Amount2: Decimal;
    begin
        FADepreciationBook.CalcFields("Book Value");
        FADepreciationBook2.CalcFields("Book Value");

        Amount := GetDepreciationAmount(FADepreciationBook);
        Amount2 := GetDepreciationAmount(FADepreciationBook2);

        LibraryReportDataset.SetRange('FixedAssetNo', FADepreciationBook."FA No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('BookValue', FADepreciationBook."Book Value");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('DeprAmount', -Amount);
        LibraryReportDataset.AssertCurrentRowValueEquals('GroupTotalBookValue', FADepreciationBook."Book Value" - Amount);

        LibraryReportDataset.SetRange('FixedAssetNo', FADepreciationBook2."FA No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('BookValue', FADepreciationBook2."Book Value");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('DeprAmount', -Amount2);
        LibraryReportDataset.AssertCurrentRowValueEquals(
          'GroupTotalBookValue',
          FADepreciationBook."Book Value" + FADepreciationBook2."Book Value" - Amount - Amount2);
    end;

    local procedure VerifyValuesOnNewAccPeriod(NewPeriodDate: Date; NoOfDays: Integer)
    begin
        LibraryReportDataset.SetRange('FormatUntilDate', Format(NewPeriodDate - 1));
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('NumberOfDays', NoOfDays);

        LibraryReportDataset.Reset();
        LibraryReportDataset.AssertElementWithValueExists('FormatUntilDate', Format(CalcDate('<CM+1M>', NewPeriodDate)));
    end;

    local procedure VerifyAmountInFATransaction(FANo: Code[20]; FAPostingType: Enum "FA Ledger Entry FA Posting Type")
    var
        FALedgerEntry: Record "FA Ledger Entry";
        GLEntry: Record "G/L Entry";
    begin
        FindFALedgerEntry(FALedgerEntry, FANo, FAPostingType);
        GLEntry.Get(FALedgerEntry."G/L Entry No.");
        GLEntry.TestField(Amount, FALedgerEntry.Amount);
    end;

    local procedure VerifyProjectedDisposalValues(FADepreciationBook: Record "FA Depreciation Book"; FADepreciationBook2: Record "FA Depreciation Book")
    var
        TotalBookValue: Decimal;
        TotalAmountValue: Decimal;
    begin
        FADepreciationBook.CalcFields("Book Value");
        FADepreciationBook2.CalcFields("Book Value");
        TotalBookValue := FADepreciationBook."Book Value" - GetDepreciationAmount(FADepreciationBook) +
          FADepreciationBook2."Book Value" - GetDepreciationAmount(FADepreciationBook2) -
          FADepreciationBook."Projected Proceeds on Disposal" - FADepreciationBook2."Projected Proceeds on Disposal";
        TotalAmountValue :=
          FADepreciationBook."Projected Proceeds on Disposal" + FADepreciationBook2."Projected Proceeds on Disposal";

        LibraryReportDataset.AssertElementWithValueExists('TotalAmounts4', TotalBookValue);
        LibraryReportDataset.AssertElementWithValueExists('TotalAmounts3', TotalAmountValue);
    end;

    local procedure VerifyGLBudgetEntryDimension(BudgetName: Code[10]; DimensionValue: Code[20])
    var
        GLBudgetEntry: Record "G/L Budget Entry";
    begin
        GLBudgetEntry.SetRange("Budget Name", BudgetName);
        GLBudgetEntry.SetRange("Budget Dimension 1 Code", DimensionValue);
        Assert.IsFalse(GLBudgetEntry.IsEmpty, GLBudgetEntryNotFoundErr);
    end;

    local procedure VerifyGLBudgetEntryDate(GLBudgetNameName: Code[20]; AccPeriodDate: Date)
    var
        GLBudgetEntry: Record "G/L Budget Entry";
    begin
        GLBudgetEntry.SetRange("Budget Name", GLBudgetNameName);
        GLBudgetEntry.SetFilter(Date, '%1..%2', CalcDate('<-CM>', AccPeriodDate), CalcDate('<CM>', AccPeriodDate));
        GLBudgetEntry.FindFirst();
        Assert.AreEqual(GLBudgetEntry.Date, AccPeriodDate - 1, GLBudgetEntryWithDateNotFoundErr);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHFixedAssetGLAnalysis(var FixedAssetGLAnalysis: TestRequestPage "Fixed Asset - G/L Analysis")
    var
        FileName: Text;
        ParametersFileName: Text;
        FixedAssetNo: Variant;
        DepreciationBookCode: Variant;
        StartingDate: Variant;
        EndingDate: Variant;
        DateField1: Variant;
        DateField2: Variant;
        AmountField1: Variant;
        AmountField2: Variant;
        AmountField3: Variant;
        Period: Variant;
        GroupTotals: Variant;
        OnlySoldAssets: Variant;
    begin
        LibraryVariableStorage.Dequeue(FixedAssetNo);
        LibraryVariableStorage.Dequeue(DepreciationBookCode);
        LibraryVariableStorage.Dequeue(StartingDate);
        LibraryVariableStorage.Dequeue(EndingDate);
        LibraryVariableStorage.Dequeue(DateField1);
        LibraryVariableStorage.Dequeue(DateField2);
        LibraryVariableStorage.Dequeue(AmountField1);
        LibraryVariableStorage.Dequeue(AmountField2);
        LibraryVariableStorage.Dequeue(AmountField3);
        LibraryVariableStorage.Dequeue(Period);
        LibraryVariableStorage.Dequeue(GroupTotals);
        LibraryVariableStorage.Dequeue(OnlySoldAssets);
        FixedAssetGLAnalysis."Fixed Asset".SetFilter("No.", FixedAssetNo);
        FixedAssetGLAnalysis.DepreciationBook.SetValue(DepreciationBookCode);
        FixedAssetGLAnalysis.StartingDate.SetValue(Format(StartingDate));
        FixedAssetGLAnalysis.EndingDate.SetValue(Format(EndingDate));
        FixedAssetGLAnalysis.DateField1.SetValue(DateField1);
        FixedAssetGLAnalysis.DateField2.SetValue(DateField2);
        FixedAssetGLAnalysis.AmountField1.SetValue(AmountField1);
        FixedAssetGLAnalysis.AmountField2.SetValue(AmountField2);
        FixedAssetGLAnalysis.AmountField3.SetValue(AmountField3);
        FixedAssetGLAnalysis.Period1.SetValue(Period);
        FixedAssetGLAnalysis.GroupTotals.SetValue(GroupTotals);
        FixedAssetGLAnalysis.OnlySoldAssets.SetValue(OnlySoldAssets);
        ParametersFileName := LibraryReportDataset.GetParametersFileName();
        FileName := LibraryReportDataset.GetFileName();
        FixedAssetGLAnalysis.SaveAsXml(ParametersFileName, FileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHFixedAssetProjectedValue(var FixedAssetProjectedValue: TestRequestPage "Fixed Asset - Projected Value")
    var
        DepreciationBook: Variant;
        StartingDate: Variant;
        EndingDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(DepreciationBook);
        LibraryVariableStorage.Dequeue(StartingDate);
        LibraryVariableStorage.Dequeue(EndingDate);
        FixedAssetProjectedValue.DepreciationBook.SetValue(DepreciationBook);
        FixedAssetProjectedValue.FirstDeprDate.SetValue(Format(StartingDate));
        FixedAssetProjectedValue.LastDeprDate.SetValue(Format(EndingDate));
        FixedAssetProjectedValue.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHFixedAssetProjectedValueNoOfDaysError(var FixedAssetProjectedValue: TestRequestPage "Fixed Asset - Projected Value")
    begin
        FixedAssetProjectedValue.DepreciationBook.SetValue(LibraryFixedAsset.GetDefaultDeprBook());
        FixedAssetProjectedValue.FirstDeprDate.SetValue(Format(WorkDate()));
        FixedAssetProjectedValue.LastDeprDate.SetValue(Format(WorkDate()));
        FixedAssetProjectedValue.NumberOfDays.SetValue(LibraryRandom.RandInt(4));
        FixedAssetProjectedValue.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHFAGLAnalysis(var FixedAssetGLAnalysis: TestRequestPage "Fixed Asset - G/L Analysis")
    var
        FileName: Text;
        ParametersFileName: Text;
        StartingDate: Variant;
        EndingDate: Variant;
        DateField1: Variant;
        DateField2: Variant;
        PostingType1: Variant;
        Period1: Variant;
        Period2: Variant;
        Period3: Variant;
        GroupTotals: Variant;
        PrintperFixedAsset: Variant;
        OnlySoldAssets: Variant;
    begin
        LibraryVariableStorage.Dequeue(StartingDate);
        LibraryVariableStorage.Dequeue(EndingDate);
        LibraryVariableStorage.Dequeue(DateField1);
        LibraryVariableStorage.Dequeue(DateField2);
        LibraryVariableStorage.Dequeue(PostingType1);
        LibraryVariableStorage.Dequeue(Period1);
        LibraryVariableStorage.Dequeue(Period2);
        LibraryVariableStorage.Dequeue(Period3);
        LibraryVariableStorage.Dequeue(GroupTotals);
        LibraryVariableStorage.Dequeue(PrintperFixedAsset);
        LibraryVariableStorage.Dequeue(OnlySoldAssets);
        FixedAssetGLAnalysis.StartingDate.SetValue(Format(StartingDate));
        FixedAssetGLAnalysis.EndingDate.SetValue(Format(EndingDate));
        FixedAssetGLAnalysis.DateField1.SetValue(DateField1);
        FixedAssetGLAnalysis.DateField2.SetValue(DateField1);
        FixedAssetGLAnalysis.AmountField1.SetValue(PostingType1);
        FixedAssetGLAnalysis.Period1.SetValue(Period1);
        FixedAssetGLAnalysis.Period2.SetValue(Period2);
        FixedAssetGLAnalysis.Period3.SetValue(Period3);
        FixedAssetGLAnalysis.AmountField2.SetValue('');
        FixedAssetGLAnalysis.AmountField3.SetValue('');
        FixedAssetGLAnalysis.GroupTotals.SetValue(GroupTotals);
        FixedAssetGLAnalysis.PrintperFixedAsset.SetValue(PrintperFixedAsset);
        FixedAssetGLAnalysis.OnlySoldAssets.SetValue(OnlySoldAssets);
        ParametersFileName := LibraryReportDataset.GetParametersFileName();
        FileName := LibraryReportDataset.GetFileName();
        FixedAssetGLAnalysis.SaveAsXml(ParametersFileName, FileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHFAProjectedValue(var FixedAssetGLAnalysis: TestRequestPage "Fixed Asset - Projected Value")
    begin
        FixedAssetGLAnalysis.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHFARegister(var FixedAssetGLAnalysis: TestRequestPage "Fixed Asset Register")
    begin
        FixedAssetGLAnalysis.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHFADocumentNos(var FixedAssetGLAnalysis: TestRequestPage "Fixed Asset Document Nos.")
    begin
        FixedAssetGLAnalysis.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHMaintenanceNextService(var FixedAssetGLAnalysis: TestRequestPage "Maintenance - Next Service")
    begin
        FixedAssetGLAnalysis.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHMaintenanceRegister(var FixedAssetGLAnalysis: TestRequestPage "Maintenance Register")
    begin
        FixedAssetGLAnalysis.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CalculateDepreciationRequestPageHandler(var CalculateDepreciation: TestRequestPage "Calculate Depreciation")
    var
        DepreciationBook: Variant;
        ForceNoOfDays: Variant;
        No: Variant;
        PostingDate: Variant;
        UseForceNoOfDays: Variant;
    begin
        LibraryVariableStorage.Dequeue(DepreciationBook);
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(UseForceNoOfDays);
        LibraryVariableStorage.Dequeue(ForceNoOfDays);
        LibraryVariableStorage.Dequeue(PostingDate);
        CalculateDepreciation."Fixed Asset".SetFilter("No.", No);
        CalculateDepreciation.DepreciationBook.SetValue(DepreciationBook);
        CalculateDepreciation.PostingDate.SetValue(PostingDate);
        CalculateDepreciation.FAPostingDate.SetValue(PostingDate);
        CalculateDepreciation.UseForceNoOfDays.SetValue(UseForceNoOfDays);
        CalculateDepreciation.ForceNoOfDays.SetValue(ForceNoOfDays);
        CalculateDepreciation.DocumentNo.SetValue(No);
        CalculateDepreciation.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure DepreciationCalcConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(CompletionStatsTok, Question);
        Reply := false;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CalculateDepreciationRequestPostingDatePageHandler(var CalculateDepreciationReport: TestRequestPage "Calculate Depreciation")
    begin
        LibraryVariableStorage.Enqueue(CalculateDepreciationReport.FAPostingDate.AsDate());
        LibraryVariableStorage.Enqueue(CalculateDepreciationReport.PostingDate.AsDate());
        CalculateDepreciationReport.Cancel().Invoke();
    end;
}

