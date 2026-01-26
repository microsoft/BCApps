codeunit 142059 "UT REP FIXEDASSET"
{
    // 1. Verify values on Fixed Asset Book Value 03 Report after posting FA Reclass. Journal.
    // 2. Verify values on Fixed Asset Book Value 03 Report after posting FA Reclass. Journal With Depreciation.
    // 
    // Cover Test Case for DACH - 353966
    // -----------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                   TFS ID
    // -----------------------------------------------------------------------------------------------------------
    // ReportFABookValue03WithPostingFAReclassJournal                                                       353966
    // 
    // Cover Test Case for Merge bug
    // -----------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                   TFS ID
    // -----------------------------------------------------------------------------------------------------------
    // ReportFABookValue03WithDepreciationAndReclass                                                        90877

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUTUtility: Codeunit "Library UT Utility";
        Assert: Codeunit Assert;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        GroupCodeNameTxt: Label 'Group Totals: %1';
        GroupCodeNameCap: Label 'GroupCodeName';
        GroupFieldIndexCap: Label 'GroupFieldIndex';
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";

    [Test]
    [HandlerFunctions('FixedAssetBookValue03FAPostingGroupReportHandler')]
    [Scope('OnPrem')]
    procedure OnPreDataItemGroupTotalsPostingGroupFABookValue03()
    var
        FixedAsset: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        // Purpose of the test is to validate the Fixed Asset - OnPreDataItem trigger of Fixed Asset Book Value 03 Report for Group Totals of FA Posting Group with FixedAssetBookValue03FAPostingGroupReportHandler.
        // Setup.
        Initialize();
        CreateFixedAssetWithDepreciationBookSetup(FADepreciationBook);

        // Exercise.
        Commit();  // Commit required for explicit commit used in SetFAPostingGroup function of Codeunit ID: 5626 - FA General Report.
        RunFixedAssetBookValue03Report(FADepreciationBook."FA No.");

        // Verify: Verify the Group Code Name and Group Field Index after running Fixed Asset Book Value 03 Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(GroupCodeNameCap, StrSubstNo(GroupCodeNameTxt, FixedAsset.FieldCaption("FA Posting Group")));
        LibraryReportDataset.AssertElementWithValueExists(GroupFieldIndexCap, 7);  // Group Field Index for FA Posting Group.
    end;

    [Test]
    [HandlerFunctions('FixedAssetBookValue03MainAssetReportHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemGroupTotalsMainAssetFABookValue03()
    var
        FixedAsset: Record "Fixed Asset";
    begin
        // Purpose of the test is to validate the Fixed Asset - OnPreDataItem trigger of Fixed Asset Book Value 03 Report for Group Totals of Main Asset with FixedAssetBookValue03MainAssetReportHandler.
        // Setup.
        Initialize();
        OnPreDataItemGroupTotalsFABookValue03(StrSubstNo(GroupCodeNameTxt, FixedAsset.FieldCaption("Main Asset/Component")), 4);  // Group Field Index for Main Asset / Component.
    end;

    [Test]
    [HandlerFunctions('FixedAssetBookValue03Dimension2ReportHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemGroupTotalsGlobalDim2FABookValue03()
    var
        FixedAsset: Record "Fixed Asset";
    begin
        // Purpose of the test is to validate the Fixed Asset - OnPreDataItem trigger of Fixed Asset Book Value 03 Report for Group Totals of Global Dimension 2 Code with FixedAssetBookValue03Dimension2ReportHandler.
        // Setup.
        Initialize();
        OnPreDataItemGroupTotalsFABookValue03(StrSubstNo(GroupCodeNameTxt, FixedAsset.FieldCaption("Global Dimension 2 Code")), 6);  // Group Field Index for Global Dimension 2 Code.
    end;

    [Test]
    [HandlerFunctions('FixedAssetBookValue03Dimension1ReportHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemGroupTotalsGlobalDim1FABookValue03()
    var
        FixedAsset: Record "Fixed Asset";
    begin
        // Purpose of the test is to validate the Fixed Asset - OnPreDataItem trigger of Fixed Asset Book Value 03 Report for Group Totals of Global Dimension 1 Code with FixedAssetBookValue03Dimension1ReportHandler.
        // Setup.
        Initialize();
        OnPreDataItemGroupTotalsFABookValue03(StrSubstNo(GroupCodeNameTxt, FixedAsset.FieldCaption("Global Dimension 1 Code")), 5);  // Group Field Index for Global Dimension 1 Code.
    end;

    [Test]
    [HandlerFunctions('FixedAssetBookValue03FALocationReportHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemGroupTotalsLocationFABookValue03()
    var
        FixedAsset: Record "Fixed Asset";
    begin
        // Purpose of the test is to validate the Fixed Asset - OnPreDataItem trigger of Fixed Asset Book Value 03 Report for Group Totals of FA Location Code with FixedAssetBookValue03FALocationReportHandler.
        // Setup.
        Initialize();
        OnPreDataItemGroupTotalsFABookValue03(StrSubstNo(GroupCodeNameTxt, FixedAsset.FieldCaption("FA Location Code")), 3);  // Group Field Index for FA Location Code.
    end;

    [Test]
    [HandlerFunctions('FixedAssetBookValue03FASubClassReportHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemGroupTotalsSubclassCodeFABookValue03()
    var
        FixedAsset: Record "Fixed Asset";
    begin
        // Purpose of the test is to validate the Fixed Asset - OnPreDataItem trigger of Fixed Asset Book Value 03 Report for Group Totals of FA Subclass Code with FixedAssetBookValue03FASubClassReportHandler.
        // Setup.
        Initialize();
        OnPreDataItemGroupTotalsFABookValue03(StrSubstNo(GroupCodeNameTxt, FixedAsset.FieldCaption("FA Subclass Code")), 2);  // Group Field Index for FA Subclass Code.
    end;

    [Test]
    [HandlerFunctions('FixedAssetBookValue03FAClassReportHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemGroupTotalsClassCodeFABookValue03()
    var
        FixedAsset: Record "Fixed Asset";
    begin
        // Purpose of the test is to validate the Fixed Asset - OnPreDataItem trigger of Fixed Asset Book Value 03 Report for Group Totals of FA Class Code with FixedAssetBookValue03FAClassReportHandler.
        // Setup.
        Initialize();
        OnPreDataItemGroupTotalsFABookValue03(StrSubstNo(GroupCodeNameTxt, FixedAsset.FieldCaption("FA Class Code")), 1);  // Group Field Index for FA Class Code.
    end;

    local procedure OnPreDataItemGroupTotalsFABookValue03(GroupCodeName: Text[50]; GroupFieldIndex: Integer)
    var
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        // Create Fixed Asset with Depreciation Book.
        CreateFixedAssetWithDepreciationBookSetup(FADepreciationBook);

        // Exercise.
        RunFixedAssetBookValue03Report(FADepreciationBook."FA No.");

        // Verify: Verify the Group Code Name and Group Field Index after running Fixed Asset Book Value 03 Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(GroupCodeNameCap, GroupCodeName);
        LibraryReportDataset.AssertElementWithValueExists(GroupFieldIndexCap, GroupFieldIndex);
    end;

    [Test]
    [HandlerFunctions('FixedAssetBookValue03PrintDetailsReportHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemPrintDetailsFABookValue03()
    var
        FixedAsset: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        // Purpose of the test is to validate the OnPreDataItem trigger of Fixed Asset Book Value 03 Report for Print Details option with FixedAssetBookValue03PrintDetailsReportHandler.
        // Setup.
        Initialize();
        CreateFixedAssetWithDepreciationBookSetup(FADepreciationBook);

        // Exercise.
        RunFixedAssetBookValue03Report(FADepreciationBook."FA No.");

        // Verify: Verify the FA No and FA Description after running Fixed Asset Book Value 03 Report.
        VerifyFixedAssetNameAndDescription(FixedAsset.FieldCaption("No."), FixedAsset.FieldCaption(Description))
    end;

    [Test]
    [HandlerFunctions('FixedAssetBookValue03BlankEndingDateReportHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportBlankEndingDateFABookValue03Error()
    begin
        // Purpose of the test is to validate the OnPreReport trigger of Fixed Asset Book Value 03 Report for Starting Date and Ending Date with FixedAssetBookValue03BlankEndingDateReportHandler.
        // Setup.
        Initialize();
        OnPreReportValidateDatesFABookValue03Error();
    end;

    [Test]
    [HandlerFunctions('FixedAssetBookValue03StartingDateReportHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportStartingDateFABookValue03Error()
    begin
        // Purpose of the test is to validate the OnPreReport trigger of Fixed Asset Book Value 03 Report for later Starting Date than Ending Date with FixedAssetBookValue03StartingDateReportHandler.
        // Setup.
        Initialize();
        OnPreReportValidateDatesFABookValue03Error();
    end;

    local procedure OnPreReportValidateDatesFABookValue03Error()
    var
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        // Create Fixed Asset with Depreciation Book.
        CreateFixedAssetWithDepreciationBookSetup(FADepreciationBook);

        // Exercise.
        asserterror RunFixedAssetBookValue03Report(FADepreciationBook."FA No.");

        // Verify: Verify the Error Code, Actual Errors - You must specify the Starting Date and the Ending Date and the Starting Date is later than the Ending Date.
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [HandlerFunctions('FixedAssetBookValue03WithBudgetReportHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportBudgetOptionFABookValue03()
    var
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        // Purpose of the test is to validate the OnPreReport trigger of Fixed Asset Book Value 03 Report for Budget Report Head Line Text with FixedAssetBookValue03WithBudgetReportHandler.
        // Setup.
        Initialize();
        CreateFixedAssetWithDepreciationBookSetup(FADepreciationBook);

        // Exercise.
        RunFixedAssetBookValue03Report(FADepreciationBook."FA No.");

        // Verify: Verify the Main Head Line Text after running Fixed Asset Book Value 03 Report. Verify the FA No and FA Description as blank.
        VerifyFixedAssetNameAndDescription('', '');
        LibraryReportDataset.AssertElementWithValueExists('MainHeadLineText', 'Fixed Asset - Book Value 03 (Budget Report)');
    end;

    [Test]
    [HandlerFunctions('FixedAssetBookValue03WithBudgetReportHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportCustomDepreciationFABookValue03Error()
    var
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        // Purpose of the test is to validate the OnPreReport trigger of Fixed Asset Book Value 03 Report for Budget Report Custom 1 Depreciation error with FixedAssetBookValue03WithBudgetReportHandler.
        // Setup.
        Initialize();
        CreateFixedAssetWithDepreciationBookSetup(FADepreciationBook);
        DepreciationBook.Get(FADepreciationBook."Depreciation Book Code");
        DepreciationBook."Use Custom 1 Depreciation" := true;
        DepreciationBook.Modify();

        // Exercise.
        asserterror RunFixedAssetBookValue03Report(FADepreciationBook."FA No.");

        // Verify: Verify the Error Code, Actual Error - In a budget report, Use Custom 1 Depreciation must be No in Depreciation Book.
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [HandlerFunctions('FixedAssetBookValue03FAClassReportHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordReclassificationAmountFABookValue03()
    var
        FADepreciationBook: Record "FA Depreciation Book";
        FALedgerEntry: Record "FA Ledger Entry";
        FALedgerEntryAmount: Decimal;
    begin
        // Purpose of the test is to validate the Fixed Asset - OnAfterGetRecord trigger of Fixed Asset Book Value 03 Report for Reclassification Amount with FixedAssetBookValue03FAClassReportHandler.
        // Setup.
        Initialize();
        CreateFixedAssetWithDepreciationBookSetup(FADepreciationBook);
        FALedgerEntryAmount := CreateFALedgerEntry(FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code", FALedgerEntry."FA Posting Type"::"Acquisition Cost");

        // Exercise.
        RunFixedAssetBookValue03Report(FADepreciationBook."FA No.");

        // Verify: Verify the Group Reclassification Amount and Total Reclassification Amount after running Fixed Asset Book Value 03 Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('NetChangeAmounts_1', FALedgerEntryAmount);
        LibraryReportDataset.AssertElementWithValueExists('TotalNetChangeAmounts_1', FALedgerEntryAmount);
    end;

    [Test]
    [HandlerFunctions('FixedAssetBookValue03FAClassReportHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordBookValueEndingDateFABookValue03()
    var
        FALedgerEntry: Record "FA Ledger Entry";
        FADepreciationBook: Record "FA Depreciation Book";
        FALedgerEntryAmount: Decimal;
    begin
        // Purpose of the test is to validate the Fixed Asset - OnAfterGetRecord trigger of Fixed Asset Book Value 03 Report for Disposal Date with FixedAssetBookValue03FAClassReportHandler.
        // Setup.
        Initialize();
        CreateFixedAssetWithDepreciationBookSetup(FADepreciationBook);
        FADepreciationBook."Disposal Date" := CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'Y>', WorkDate());
        FADepreciationBook.Modify();
        FALedgerEntryAmount := CreateFALedgerEntry(FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code", FALedgerEntry."FA Posting Type"::Depreciation);

        // Exercise.
        RunFixedAssetBookValue03Report(FADepreciationBook."FA No.");

        // Verify: Verify the Book Value At Starting Date and Book Value At Ending Date after running Fixed Asset Book Value 03 Report. Verify the FA No and FA Description as blank.
        VerifyFixedAssetNameAndDescription('', '');
        LibraryReportDataset.AssertElementWithValueExists('BookValueAtStartingDate', 0);  // Zero Book Value At Starting Date.
        LibraryReportDataset.AssertElementWithValueExists('BookValueAtEndingDate', FALedgerEntryAmount);
    end;

    [Test]
    [HandlerFunctions('FixedAssetBookValue03FAClassReportHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordNetChangeAppClassFABookValue03()
    begin
        // Purpose of the test is to validate the Fixed Asset - OnAfterGetRecord trigger of Fixed Asset Book Value 03 Report for Group, Total Net Change with FA Posting Type Appreciation and FixedAssetBookValue03FAClassReportHandler.
        // Setup.
        Initialize();
        OnAfterGetRecordNetChangeFABookValue03();
    end;

    [Test]
    [HandlerFunctions('FixedAssetBookValue03FASubClassReportHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordNetChangeAppSubClassFABookValue03()
    begin
        // Purpose of the test is to validate the Fixed Asset - OnAfterGetRecord trigger of Fixed Asset Book Value 03 Report for Group, Total Net Change with FA Posting Type Appreciation and FixedAssetBookValue03FASubClassReportHandler.
        // Setup.
        Initialize();
        OnAfterGetRecordNetChangeFABookValue03();
    end;

    local procedure OnAfterGetRecordNetChangeFABookValue03()
    var
        FADepreciationBook: Record "FA Depreciation Book";
        FALedgerEntry: Record "FA Ledger Entry";
        FALedgerEntryAmount: Decimal;
    begin
        CreateFixedAssetWithDepreciationBookSetup(FADepreciationBook);
        FALedgerEntryAmount := CreateFALedgerEntry(FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code", FALedgerEntry."FA Posting Type"::Appreciation);

        // Exercise.
        RunFixedAssetBookValue03Report(FADepreciationBook."FA No.");

        // Verify: Verify the Group Net Change Amount and Total Net Change Amount after running Fixed Asset Book Value 03 Report.
        VerifyFixedAssetGroupAndTotalNetChangeAmount(FALedgerEntryAmount, FALedgerEntryAmount);
    end;

    [Test]
    [HandlerFunctions('FixedAssetBookValue03FAClassReportHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordNetChangeCustomClassFABookValue03()
    begin
        // Purpose of the test is to validate the Fixed Asset - OnAfterGetRecord trigger of Fixed Asset Book Value 03 Report for Group, Total Net Change with FA Posting Type Custom 1 and FixedAssetBookValue03FAClassReportHandler.
        // Setup.
        Initialize();
        OnAfterGetRecordNetChangeCustom1FABookValue03();
    end;

    [Test]
    [HandlerFunctions('FixedAssetBookValue03FASubClassReportHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordNetChangeCustomSubClassFABookValue03()
    begin
        // Purpose of the test is to validate the Fixed Asset - OnAfterGetRecord trigger of Fixed Asset Book Value 03 Report for Group, Total Net Change with FA Posting Type Custom 1 and FixedAssetBookValue03FASubClassReportHandler.
        // Setup.
        Initialize();
        OnAfterGetRecordNetChangeCustom1FABookValue03();
    end;

    local procedure OnAfterGetRecordNetChangeCustom1FABookValue03()
    var
        FADepreciationBook: Record "FA Depreciation Book";
        FALedgerEntry: Record "FA Ledger Entry";
        FALedgerEntryAmount: Decimal;
    begin
        CreateFixedAssetWithDepreciationBookSetup(FADepreciationBook);
        FALedgerEntryAmount := CreateFALedgerEntry(FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code", FALedgerEntry."FA Posting Type"::"Custom 1");
        FilterFALedgerEntry(FALedgerEntry, FADepreciationBook."Depreciation Book Code", FADepreciationBook."FA No.");
        FALedgerEntry."FA Posting Date" := CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate());
        FALedgerEntry.Modify();

        // Exercise.
        RunFixedAssetBookValue03Report(FADepreciationBook."FA No.");

        // Verify: Verify the Group Net Change Amount, Total Net Change Amount as zero and Book Value at Starting Date after running Fixed Asset Book Value 03 Report.
        VerifyFixedAssetGroupAndTotalNetChangeAmount(0, 0);
        LibraryReportDataset.AssertElementWithValueExists('BookValueAtStartingDate', FALedgerEntryAmount);
    end;

    [Test]
    [HandlerFunctions('FixedAssetBookValue03FAClassReportHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordDisposalClassDepFABookValue03()
    begin
        // Purpose of the test is to validate the Fixed Asset - OnAfterGetRecord trigger of Fixed Asset Book Value 03 Report for Group, Total Net Change with FA Posting Type Depreciation and FixedAssetBookValue03FAClassReportHandler.
        // Setup.
        Initialize();
        OnAfterGetRecordDepreciationFABookValue03();
    end;

    [Test]
    [HandlerFunctions('FixedAssetBookValue03FASubClassReportHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordDisposalSubClassDepFABookValue03()
    begin
        // Purpose of the test is to validate the Fixed Asset - OnAfterGetRecord trigger of Fixed Asset Book Value 03 Report for Group, Total Net Change with FA Posting Type Depreciation and FixedAssetBookValue03FASubClassReportHandler.
        // Setup.
        Initialize();
        OnAfterGetRecordDepreciationFABookValue03();
    end;

    [Test]
    [HandlerFunctions('FixedAssetBookValue03FALocationReportHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordDisposalLocationDepFABookValue03()
    begin
        // Purpose of the test is to validate the Fixed Asset - OnAfterGetRecord trigger of Fixed Asset Book Value 03 Report for Group, Total Net Change with FA Posting Type Depreciation and FixedAssetBookValue03FALocationReportHandler.
        // Setup.
        Initialize();
        OnAfterGetRecordDepreciationFABookValue03();
    end;

    [Test]
    [HandlerFunctions('FixedAssetBookValue03WithBudgetReportHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordDisposalBudgetDepFABookValue03()
    begin
        // Purpose of the test is to validate the Fixed Asset - OnAfterGetRecord trigger of Fixed Asset Book Value 03 Report for Group, Total Net Change with FA Posting Type Depreciation and FixedAssetBookValue03WithBudgetReportHandler.
        // Setup.
        Initialize();
        OnAfterGetRecordDepreciationFABookValue03();
    end;

    local procedure OnAfterGetRecordDepreciationFABookValue03()
    var
        FADepreciationBook: Record "FA Depreciation Book";
        FALedgerEntry: Record "FA Ledger Entry";
        FALedgerEntryAmount: Decimal;
    begin
        CreateFixedAssetWithDepreciationBookSetup(FADepreciationBook);
        FALedgerEntryAmount := CreateFALedgerEntry(FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code", FALedgerEntry."FA Posting Type"::Depreciation);

        // Exercise.
        RunFixedAssetBookValue03Report(FADepreciationBook."FA No.");

        // Verify: Verify the Group Net Change Amount and Total Net Change Amount as zero after running Fixed Asset Book Value 03 Report. Verify the Group and Total Disposal and Net Change Amount.
        VerifyFixedAssetGroupAndTotalNetChangeAmount(0, 0);
        LibraryReportDataset.AssertElementWithValueExists('GroupDisposalAmounts_2_', -FALedgerEntryAmount);
        LibraryReportDataset.AssertElementWithValueExists('TotalDisposalAmounts_2_', -FALedgerEntryAmount);
        LibraryReportDataset.AssertElementWithValueExists('GroupNetChangeAmounts_2_', FALedgerEntryAmount);
        LibraryReportDataset.AssertElementWithValueExists('TotalNetChangeAmounts_2_', FALedgerEntryAmount);
    end;

    [Test]
    [HandlerFunctions('FixedAssetBookValue03PrintDetailsReportHandler')]
    [Scope('OnPrem')]
    procedure ReportFABookValue03WithPostingFAReclassJournal()
    var
        FANo: Code[20];
        FANo2: Code[20];
        AcqCostAmount: Decimal;
        AcqCostPercent: Decimal;
    begin
        // Setup: Create 2 Fixed Assets, Create FA Depreciation Books, Create and Post FA G/L Journal Lines with FA Posting Type
        // Acquisition cost for first Fixed Asset, create and Post Reclassify Journal.
        // Exercise: Run Fixed Asset Book Value 03 Report.
        AcqCostAmount := LibraryRandom.RandInt(1000);
        AcqCostPercent := LibraryRandom.RandInt(100) / 100;
        InitalSetupForReportFABookValue03(FANo, FANo2, false, AcqCostAmount, 0, AcqCostPercent);

        // Verify: Verify values of Fixed Asset Book Value 03 Report.
        VerifyValuesOfReportFABookValue03(
          FANo, AcqCostAmount, 0, -AcqCostAmount * AcqCostPercent, AcqCostAmount * (1 - AcqCostPercent));
        VerifyValuesOfReportFABookValue03(
          FANo2, 0, 0, AcqCostAmount * AcqCostPercent, AcqCostAmount * AcqCostPercent);
    end;

    [Test]
    [HandlerFunctions('FixedAssetBookValue03PrintDetailsReportHandler')]
    [Scope('OnPrem')]
    procedure ReportFABookValue03WithPostingFAReclassJnlAndDisposal()
    var
        FANo: Code[20];
        AcqCostAmount: Decimal;
        AcqCostPercent: Decimal;
    begin
        // Setup: Create 2 Fixed Assets, Create FA Depreciation Books, Create and Post FA G/L Journal Lines with FA Posting Type
        // Acquisition cost for first Fixed Asset, create and Post Reclassify Journal.
        // Exercise: Run Fixed Asset Book Value 03 Report.
        AcqCostAmount := LibraryRandom.RandInt(1000);
        AcqCostPercent := LibraryRandom.RandInt(100) / 100;
        InitalSetupForReportFABookValue03WithDisposal(FANo, AcqCostAmount, AcqCostPercent);

        // Verify: Verify values of Fixed Asset Book Value 03 Report.
        VerifyValuesOfReportFABookValue03WithDisposal(
          FANo, AcqCostAmount, -AcqCostAmount * AcqCostPercent, AcqCostAmount * (1 - AcqCostPercent));
    end;

    [Test]
    [HandlerFunctions('FixedAssetBookValue03PrintDetailsReportHandler')]
    [Scope('OnPrem')]
    procedure ReportFABookValue03WithDepreciationAndReclass()
    var
        FANo: Code[20];
        FANo2: Code[20];
        AcqCostAmount: Decimal;
        AcqCostPercent: Decimal;
        DepreciationAmount: Decimal;
    begin
        // Setup: Create 2 Fixed Assets, Create FA Depreciation Books, Create and Post FA G/L Journal Lines with FA Posting Type
        // Acquisition cost and Depreciation for first Fixed Asset, create and Post Reclassify Journal.
        // Exercise: Run Fixed Asset Book Value 03 Report.
        AcqCostAmount := LibraryRandom.RandIntInRange(500, 1000);
        DepreciationAmount := LibraryRandom.RandInt(100);
        AcqCostPercent := LibraryRandom.RandInt(100) / 100;
        InitalSetupForReportFABookValue03(FANo, FANo2, true, AcqCostAmount, DepreciationAmount, AcqCostPercent);

        // Verify: Verify values of Fixed Asset Book Value 03 Report.
        VerifyValuesOfReportFABookValue03(
          FANo, AcqCostAmount, DepreciationAmount * (AcqCostPercent - 1),
          -AcqCostAmount * AcqCostPercent, (AcqCostAmount - DepreciationAmount) * (1 - AcqCostPercent));
        VerifyValuesOfReportFABookValue03(
          FANo2, 0, -DepreciationAmount * AcqCostPercent, AcqCostAmount * AcqCostPercent,
          (AcqCostAmount - DepreciationAmount) * AcqCostPercent);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure InitalSetupForReportFABookValue03(var FANo: Code[20]; var FANo2: Code[20]; HasDepreciation: Boolean; AcqCostAmount: Decimal; DepreciationAmount: Decimal; AcqCostPercent: Decimal)
    var
        FASetup: Record "FA Setup";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        Initialize();
        FASetup.Get();
        FANo := CreateFAWithDepreciationBookSetup(FASetup."Default Depr. Book");
        FANo2 := CreateFAWithDepreciationBookSetup(FASetup."Default Depr. Book");

        CreateAndPostFAGLJournal(FANo, GenJournalLine."FA Posting Type"::"Acquisition Cost", AcqCostAmount);
        if HasDepreciation then
            CreateAndPostFAGLJournal(FANo, GenJournalLine."FA Posting Type"::Depreciation, -DepreciationAmount);
        CreateAndPostFAReclassJournal(FASetup."Default Depr. Book", FANo, FANo2, AcqCostPercent);

        LibraryVariableStorage.Enqueue(FASetup."Default Depr. Book");
        RunFixedAssetBookValue03Report(StrSubstNo('%1|%2', FANo, FANo2));
        LibraryReportDataset.LoadDataSetFile();
    end;

    local procedure InitalSetupForReportFABookValue03WithDisposal(var FANo: Code[20]; AcqCostAmount: Decimal; AcqCostPercent: Decimal)
    var
        FASetup: Record "FA Setup";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        Initialize();
        FASetup.Get();
        FANo := CreateFAWithDepreciationBookSetup(FASetup."Default Depr. Book");

        CreateAndPostFAGLJournal(FANo, GenJournalLine."FA Posting Type"::"Acquisition Cost", AcqCostAmount);
        CreateAndPostFAReclassJournal(
          FASetup."Default Depr. Book", FANo, CreateFAWithDepreciationBookSetup(FASetup."Default Depr. Book"), AcqCostPercent);
        CreateAndPostFAGLJournal(FANo, GenJournalLine."FA Posting Type"::Disposal, -LibraryRandom.RandInt(200));

        LibraryVariableStorage.Enqueue(FASetup."Default Depr. Book");
        RunFixedAssetBookValue03Report(FANo);
        LibraryReportDataset.LoadDataSetFile();
    end;

    local procedure CreateDepreciationBook(var DepreciationBook: Record "Depreciation Book")
    var
        FAPostingTypeSetup: Record "FA Posting Type Setup";
    begin
        DepreciationBook.Code := LibraryUTUtility.GetNewCode10();
        DepreciationBook.Insert();
        CreateFAPostingTypeSetup(DepreciationBook.Code, FAPostingTypeSetup."FA Posting Type"::Appreciation);
        CreateFAPostingTypeSetup(DepreciationBook.Code, FAPostingTypeSetup."FA Posting Type"::"Write-Down");
        CreateFAPostingTypeSetup(DepreciationBook.Code, FAPostingTypeSetup."FA Posting Type"::"Custom 2");
        CreateFAPostingTypeSetup(DepreciationBook.Code, FAPostingTypeSetup."FA Posting Type"::"Custom 1");
        LibraryVariableStorage.Enqueue(DepreciationBook.Code);  // Enqueue value for use in UpdateFixedAssetBookValue03ReportRequestPage.
    end;

    local procedure CreateFixedAsset(var FixedAsset: Record "Fixed Asset")
    begin
        FixedAsset."No." := LibraryUTUtility.GetNewCode();
        FixedAsset."FA Class Code" := LibraryUTUtility.GetNewCode10();
        FixedAsset."FA Subclass Code" := LibraryUTUtility.GetNewCode10();
        FixedAsset."Global Dimension 1 Code" := LibraryUTUtility.GetNewCode();
        FixedAsset."Global Dimension 2 Code" := LibraryUTUtility.GetNewCode();
        FixedAsset."FA Posting Group" := LibraryUTUtility.GetNewCode10();
        FixedAsset.Insert();
    end;

    local procedure CreateFADepreciationBook(var FADepreciationBook: Record "FA Depreciation Book"; DepreciationBookCode: Code[10]; FANo: Code[20]; FAPostingGroup: Code[20])
    begin
        FADepreciationBook."Depreciation Book Code" := DepreciationBookCode;
        FADepreciationBook."FA No." := FANo;
        FADepreciationBook."FA Posting Group" := FAPostingGroup;
        FADepreciationBook."Depreciation Starting Date" := WorkDate();

        // Depreciation Ending Date greater than Depreciation Starting Date.
        FADepreciationBook."Depreciation Ending Date" := CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'Y>', WorkDate());
        FADepreciationBook."Acquisition Date" := WorkDate();
        FADepreciationBook."Disposal Date" := WorkDate();
        FADepreciationBook.Insert();
    end;

    local procedure CreateAndUpdateFADepreciationBook(var FADepreciationBook: Record "FA Depreciation Book"; FANo: Code[20]; FAPostingGroup: Code[20]; DepreciationBookCode: Code[10])
    begin
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FANo, DepreciationBookCode);
        FADepreciationBook.Validate("FA Posting Group", FAPostingGroup);
        FADepreciationBook.Validate("Depreciation Starting Date", WorkDate());
        FADepreciationBook.Validate(
          "Depreciation Ending Date", CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'Y>', WorkDate()));
        FADepreciationBook.Modify(true);
    end;

    local procedure CreateFALedgerEntry(FANo: Code[20]; DepreciationBookCode: Code[10]; FAPostingType: Enum "FA Ledger Entry FA Posting Type"): Decimal
    var
        FALedgerEntry: Record "FA Ledger Entry";
        FALedgerEntry2: Record "FA Ledger Entry";
    begin
        FALedgerEntry2.FindLast();
        FALedgerEntry."Entry No." := FALedgerEntry2."Entry No." + 1;
        FALedgerEntry."FA No." := FANo;
        FALedgerEntry."Depreciation Book Code" := DepreciationBookCode;
        FALedgerEntry."FA Posting Date" := WorkDate();
        FALedgerEntry."FA Posting Type" := FAPostingType;
        FALedgerEntry."Part of Book Value" := true;
        FALedgerEntry.Amount := 1;
        FALedgerEntry.Insert();
        exit(FALedgerEntry.Amount);
    end;

    local procedure CreateFAPostingTypeSetup(DepreciationBookCode: Code[10]; FAPostingType: Enum "FA Posting Type Setup Type")
    var
        FAPostingTypeSetup: Record "FA Posting Type Setup";
    begin
        FAPostingTypeSetup."Depreciation Book Code" := DepreciationBookCode;
        FAPostingTypeSetup."FA Posting Type" := FAPostingType;
        FAPostingTypeSetup.Insert();
    end;

    local procedure CreateFAWithPostingGroup(var FixedAsset: Record "Fixed Asset")
    var
        FAPostingGroup: Record "FA Posting Group";
    begin
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);
        UpdateFAPostingGroup(FAPostingGroup);
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        FixedAsset.Validate("FA Posting Group", FAPostingGroup.Code);
        FixedAsset.Modify(true);
    end;

    local procedure CreateFixedAssetWithDepreciationBookSetup(var FADepreciationBook: Record "FA Depreciation Book")
    var
        FixedAsset: Record "Fixed Asset";
        DepreciationBook: Record "Depreciation Book";
    begin
        CreateDepreciationBook(DepreciationBook);
        CreateFixedAsset(FixedAsset);
        CreateFADepreciationBook(FADepreciationBook, DepreciationBook.Code, FixedAsset."No.", FixedAsset."FA Posting Group");
    end;

    local procedure CreateFAWithDepreciationBookSetup(DepreciationBookCode: Code[10]): Code[20]
    var
        FADepreciationBook: Record "FA Depreciation Book";
        FixedAsset: Record "Fixed Asset";
    begin
        CreateFAWithPostingGroup(FixedAsset);
        CreateAndUpdateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", DepreciationBookCode);
        exit(FixedAsset."No.");
    end;

    local procedure CreateGeneralJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch"; TemplateType: Enum "Gen. Journal Template Type")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        CreateGeneralJournalTemplate(GenJournalTemplate, TemplateType);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure CreateGeneralJournalTemplate(var GenJournalTemplate: Record "Gen. Journal Template"; Type: Enum "Gen. Journal Template Type")
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate(Type, Type);
        GenJournalTemplate.Modify(true);
    end;

    local procedure CreateAndPostFAGLJournal(FANo: Code[20]; FAPostingType: Enum "Gen. Journal Line FA Posting Type"; Amount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        CreateGeneralJournalBatch(GenJournalBatch, GenJournalTemplate.Type::Assets);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"Fixed Asset", FANo, Amount);
        UpdateFAGLJournalLine(GenJournalLine, FAPostingType);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndPostFAReclassJournal(DepreciationBookCode: Code[10]; FixedAssetNo: Code[20]; FixedAssetNo2: Code[20]; AcqCostPercent: Decimal)
    var
        FAReclassJournalLine: Record "FA Reclass. Journal Line";
        FAReclassJournalBatch: Record "FA Reclass. Journal Batch";
        FAReclassJournalTemplate: Record "FA Reclass. Journal Template";
    begin
        FAReclassJournalTemplate.FindFirst();
        LibraryFixedAsset.CreateFAReclassJournalBatch(FAReclassJournalBatch, FAReclassJournalTemplate.Name);
        LibraryFixedAsset.CreateFAReclassJournal(
          FAReclassJournalLine, FAReclassJournalBatch."Journal Template Name", FAReclassJournalBatch.Name);
        UpdateFAReclassJournalLine(FAReclassJournalLine, FixedAssetNo, FixedAssetNo2, AcqCostPercent * 100);
        CODEUNIT.Run(CODEUNIT::"FA Reclass. Transfer Batch", FAReclassJournalLine);
        UpdateAndPostGLJournalLine(DepreciationBookCode);
    end;

    local procedure FilterFALedgerEntry(var FALedgerEntry: Record "FA Ledger Entry"; DepreciationBookCode: Code[10]; FANo: Code[20])
    begin
        FALedgerEntry.SetRange("Depreciation Book Code", DepreciationBookCode);
        FALedgerEntry.SetRange("FA No.", FANo);
        FALedgerEntry.FindFirst();
    end;

    local procedure RunFixedAssetBookValue03Report(NoFilter: Text)
    var
        FixedAsset: Record "Fixed Asset";
        FixedAssetBookValue03: Report "Fixed Asset - Book Value 03";
    begin
        FixedAsset.SetFilter("No.", NoFilter);
        FixedAssetBookValue03.SetTableView(FixedAsset);
        FixedAssetBookValue03.Run();  // Invokes handlers through UpdateFixedAssetBookValue03ReportRequestPage.
    end;

    local procedure UpdateAndPostGLJournalLine(DepreciationBookCode: Code[10])
    var
        FAJournalSetup: Record "FA Journal Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        NoSeries: Codeunit "No. Series";
        DocumentNo: Code[20];
    begin
        FAJournalSetup.SetRange("Depreciation Book Code", DepreciationBookCode);
        FAJournalSetup.FindFirst();
        GenJournalBatch.Get(FAJournalSetup."Gen. Jnl. Template Name", FAJournalSetup."Gen. Jnl. Batch Name");
        DocumentNo := NoSeries.PeekNextNo(GenJournalBatch."No. Series");
        GenJournalLine.SetRange("Journal Template Name", FAJournalSetup."Gen. Jnl. Template Name");
        GenJournalLine.SetRange("Journal Batch Name", FAJournalSetup."Gen. Jnl. Batch Name");
        GenJournalLine.FindSet();
        repeat
            GenJournalLine.Validate("Document No.", DocumentNo);
            GenJournalLine.Modify(true);
        until GenJournalLine.Next() = 0;
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure UpdateFAGLJournalLine(var GenJournalLine: Record "Gen. Journal Line"; FAPostingType: Enum "Gen. Journal Line FA Posting Type")
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GenJournalLine.Validate("Document No.", GenJournalLine."Account No.");
        GenJournalLine.Validate("FA Posting Type", FAPostingType);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", GLAccount."No.");
        GenJournalLine.Modify(true);
    end;

    local procedure UpdateFAPostingGroup(var FAPostingGroup: Record "FA Posting Group")
    var
        FAPostingGroup2: Record "FA Posting Group";
        RecRef: RecordRef;
    begin
        FAPostingGroup2.Init();
        FAPostingGroup2.SetFilter("Acquisition Cost Account", '<>''''');
        RecRef.GetTable(FAPostingGroup2);
        LibraryUtility.FindRecord(RecRef);
        RecRef.SetTable(FAPostingGroup2);
        FAPostingGroup.TransferFields(FAPostingGroup2, false);
        FAPostingGroup.Modify(true);
    end;

    local procedure UpdateFAReclassJournalLine(var FAReclassJournalLine: Record "FA Reclass. Journal Line"; FANo: Code[20]; NewFANo: Code[20]; AcqCostPercent: Decimal)
    begin
        FAReclassJournalLine.Validate("FA Posting Date", WorkDate());
        FAReclassJournalLine.Validate(
          "Document No.",
          CopyStr(
            LibraryUtility.GenerateRandomCode(FAReclassJournalLine.FieldNo("Document No."), DATABASE::"FA Reclass. Journal Line"),
            1,
            LibraryUtility.GetFieldLength(DATABASE::"FA Reclass. Journal Line", FAReclassJournalLine.FieldNo("Document No."))));
        FAReclassJournalLine.Validate("FA No.", FANo);
        FAReclassJournalLine.Validate("New FA No.", NewFANo);
        FAReclassJournalLine.Validate("Reclassify Acq. Cost %", AcqCostPercent);
        FAReclassJournalLine.Validate("Reclassify Acquisition Cost", true);
        FAReclassJournalLine.Validate("Reclassify Depreciation", true);
        FAReclassJournalLine.Modify(true);
    end;

    local procedure VerifyFixedAssetNameAndDescription(FANo: Variant; FADescription: Variant)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('FANo', FANo);
        LibraryReportDataset.AssertElementWithValueExists('FADescription', FADescription);
    end;

    local procedure VerifyFixedAssetGroupAndTotalNetChangeAmount(GroupNetChangeAmounts: Variant; TotalNetChangeAmounts: Variant)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('GroupNetChangeAmounts_4_', GroupNetChangeAmounts);
        LibraryReportDataset.AssertElementWithValueExists('TotalNetChangeAmounts_4_', TotalNetChangeAmounts);
    end;

    local procedure VerifyValuesOfReportFABookValue03(FANo: Code[20]; NetChangeAmounts: Decimal; DepreciationAmounts: Decimal; ReclassAmount: Decimal; BookValueAtEndingDate: Decimal)
    begin
        LibraryReportDataset.SetRange('Fixed_Asset__No__', FANo);
        LibraryReportDataset.AssertElementWithValueExists('NetChangeAmounts_1', NetChangeAmounts);
        LibraryReportDataset.AssertElementWithValueExists('NetChangeAmounts_2_', DepreciationAmounts);
        LibraryReportDataset.AssertElementWithValueExists('ReclassAmount', ReclassAmount);
        LibraryReportDataset.AssertElementWithValueExists('BookValueAtEndingDate', BookValueAtEndingDate);
    end;

    local procedure VerifyValuesOfReportFABookValue03WithDisposal(FANo: Code[20]; NetChangeAmounts: Decimal; ReclassAmount: Decimal; BookValueAtEndingDate: Decimal)
    begin
        LibraryReportDataset.SetRange('Fixed_Asset__No__', FANo);
        LibraryReportDataset.AssertElementWithValueExists('NetChangeAmounts_1', NetChangeAmounts);
        LibraryReportDataset.AssertElementWithValueExists('ReclassAmount', ReclassAmount);
        LibraryReportDataset.AssertElementWithValueExists('BookValueAtEndingDate', 0);
        LibraryReportDataset.AssertElementWithValueExists('DisposalAmounts_1_', -BookValueAtEndingDate);
    end;

    local procedure UpdateFixedAssetBookValue03ReportRequestPage(FixedAssetBookValue03: TestRequestPage "Fixed Asset - Book Value 03"; StartingDate: Date; EndingDate: Date; GroupTotals: Option; BudgetReport: Boolean; PrintPerFixedAsset: Boolean)
    var
        DepreciationBookCode: Variant;
    begin
        LibraryVariableStorage.Dequeue(DepreciationBookCode);
        FixedAssetBookValue03.DepreciationBook.SetValue(DepreciationBookCode);
        FixedAssetBookValue03.StartingDate.SetValue(StartingDate);
        FixedAssetBookValue03.EndingDate.SetValue(EndingDate);
        FixedAssetBookValue03.GroupTotals.SetValue(GroupTotals);
        FixedAssetBookValue03.PrintPerFixedAsset.SetValue(PrintPerFixedAsset);
        FixedAssetBookValue03.BudgetReport.SetValue(BudgetReport);
        FixedAssetBookValue03.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure FixedAssetBookValue03FAClassReportHandler(var FixedAssetBookValue03: TestRequestPage "Fixed Asset - Book Value 03")
    var
        GroupTotals: Option " ","FA Class","FA Subclass","FA Location","Main Asset","Global Dimension 1","Global Dimension 2","FA Posting Group";
    begin
        UpdateFixedAssetBookValue03ReportRequestPage(FixedAssetBookValue03, WorkDate(), WorkDate(), GroupTotals::"FA Class", false, false);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure FixedAssetBookValue03FASubClassReportHandler(var FixedAssetBookValue03: TestRequestPage "Fixed Asset - Book Value 03")
    var
        GroupTotals: Option " ","FA Class","FA Subclass","FA Location","Main Asset","Global Dimension 1","Global Dimension 2","FA Posting Group";
    begin
        UpdateFixedAssetBookValue03ReportRequestPage(FixedAssetBookValue03, WorkDate(), WorkDate(), GroupTotals::"FA Subclass", false, false);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure FixedAssetBookValue03FALocationReportHandler(var FixedAssetBookValue03: TestRequestPage "Fixed Asset - Book Value 03")
    var
        GroupTotals: Option " ","FA Class","FA Subclass","FA Location","Main Asset","Global Dimension 1","Global Dimension 2","FA Posting Group";
    begin
        UpdateFixedAssetBookValue03ReportRequestPage(FixedAssetBookValue03, WorkDate(), WorkDate(), GroupTotals::"FA Location", false, false);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure FixedAssetBookValue03Dimension1ReportHandler(var FixedAssetBookValue03: TestRequestPage "Fixed Asset - Book Value 03")
    var
        GroupTotals: Option " ","FA Class","FA Subclass","FA Location","Main Asset","Global Dimension 1","Global Dimension 2","FA Posting Group";
    begin
        UpdateFixedAssetBookValue03ReportRequestPage(FixedAssetBookValue03, WorkDate(), WorkDate(), GroupTotals::"Global Dimension 1", false, false);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure FixedAssetBookValue03Dimension2ReportHandler(var FixedAssetBookValue03: TestRequestPage "Fixed Asset - Book Value 03")
    var
        GroupTotals: Option " ","FA Class","FA Subclass","FA Location","Main Asset","Global Dimension 1","Global Dimension 2","FA Posting Group";
    begin
        UpdateFixedAssetBookValue03ReportRequestPage(FixedAssetBookValue03, WorkDate(), WorkDate(), GroupTotals::"Global Dimension 2", false, false);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure FixedAssetBookValue03FAPostingGroupReportHandler(var FixedAssetBookValue03: TestRequestPage "Fixed Asset - Book Value 03")
    var
        GroupTotals: Option " ","FA Class","FA Subclass","FA Location","Main Asset","Global Dimension 1","Global Dimension 2","FA Posting Group";
    begin
        UpdateFixedAssetBookValue03ReportRequestPage(FixedAssetBookValue03, WorkDate(), WorkDate(), GroupTotals::"FA Posting Group", false, false);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure FixedAssetBookValue03MainAssetReportHandler(var FixedAssetBookValue03: TestRequestPage "Fixed Asset - Book Value 03")
    var
        GroupTotals: Option " ","FA Class","FA Subclass","FA Location","Main Asset","Global Dimension 1","Global Dimension 2","FA Posting Group";
    begin
        UpdateFixedAssetBookValue03ReportRequestPage(FixedAssetBookValue03, WorkDate(), WorkDate(), GroupTotals::"Main Asset", false, false);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure FixedAssetBookValue03WithBudgetReportHandler(var FixedAssetBookValue03: TestRequestPage "Fixed Asset - Book Value 03")
    var
        GroupTotals: Option " ","FA Class","FA Subclass","FA Location","Main Asset","Global Dimension 1","Global Dimension 2","FA Posting Group";
    begin
        UpdateFixedAssetBookValue03ReportRequestPage(FixedAssetBookValue03, WorkDate(), WorkDate(), GroupTotals::"FA Class", true, false);  // TRUE for Budget Report.
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure FixedAssetBookValue03PrintDetailsReportHandler(var FixedAssetBookValue03: TestRequestPage "Fixed Asset - Book Value 03")
    var
        GroupTotals: Option " ","FA Class","FA Subclass","FA Location","Main Asset","Global Dimension 1","Global Dimension 2","FA Posting Group";
    begin
        UpdateFixedAssetBookValue03ReportRequestPage(FixedAssetBookValue03, WorkDate(), WorkDate(), GroupTotals, false, true);  // TRUE for Print Details.
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure FixedAssetBookValue03StartingDateReportHandler(var FixedAssetBookValue03: TestRequestPage "Fixed Asset - Book Value 03")
    var
        GroupTotals: Option " ","FA Class","FA Subclass","FA Location","Main Asset","Global Dimension 1","Global Dimension 2","FA Posting Group";
    begin
        UpdateFixedAssetBookValue03ReportRequestPage(
          FixedAssetBookValue03, CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'M>', WorkDate()), WorkDate(), GroupTotals, false, false);  // Starting Date later than Ending Date.
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure FixedAssetBookValue03BlankEndingDateReportHandler(var FixedAssetBookValue03: TestRequestPage "Fixed Asset - Book Value 03")
    var
        GroupTotals: Option " ","FA Class","FA Subclass","FA Location","Main Asset","Global Dimension 1","Global Dimension 2","FA Posting Group";
    begin
        UpdateFixedAssetBookValue03ReportRequestPage(FixedAssetBookValue03, WorkDate(), 0D, GroupTotals, false, false);  // Blank Ending Date.
    end;
}

