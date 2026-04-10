codeunit 134478 "ERM Dimension Fixed Assets"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Fixed Asset] [Dimension]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryERM: Codeunit "Library - ERM";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        isInitialized: Boolean;
        LinesMustNotBeCreated: Label 'Lines must not be created for Fixed Asset %1. ';
        DimensionValueError: Label 'A dimension used in %1 %2, %3, %4 has caused an error. Select a %5 for the %6 %7 for %8 %9.', Comment = '%1: Table Caption1,%2: Field Value1,%3: Field Value2,%4: Field Value3,%5:Field Caption1,%6:Field Caption2,%7:Field Value4,%8: Table Caption2,%9: Field Value5.';
        DimensionValueError2: Label 'Select a %1 for the %2 %3 for %4 %5.', Comment = '%1: Table Caption1,%2: Field Value1,%3: Field Value2,%4: Field Value3,%5:Field Caption1,%6:Field Caption2,%7:Field Value4,%8: Table Caption2,%9: Field Value5.';
        CheckDimValueInGenJournalErr: Label 'Wrong %1 in Dimension Set for Gen. Journal Line. Document No. = %2, Account No. = %3, Batch Name = %4.';
        CompletionStatsTok: Label 'The depreciation has been calculated.';
        DimensionsAreNotEqual: Label 'The dimensions must be equal.';


    [Test]
    [Scope('OnPrem')]
    procedure AutomaticInsuranceLedger()
    var
        GenJournalLine: Record "Gen. Journal Line";
        OldInsuranceDeprBook: Code[10];
        AutomaticInsurancePosting: Boolean;
        DimensionSetID: Integer;
    begin
        // Test the Fixed Asset General Journal with Insurance.

        // 1.Setup: Create FA General Journal Line of Fixed Asset type, update the Insurance Number, modify the
        // Insurance Depreciation Book in FA Setup Dimension in General Journal Line.
        Initialize();
        CreateFAGLJournalLine(GenJournalLine);
        InsuranceInGenJournalLine(GenJournalLine, FindInsurance());
        OldInsuranceDeprBook := InsuranceDeprBookInFASetup(GenJournalLine."Depreciation Book Code");
        AutomaticInsurancePosting := ModifyInsurancePosting(true);
        AttachDimensionInJournalLine(GenJournalLine);
        DimensionSetID := GenJournalLine."Dimension Set ID";

        // 2.Exercise: Post the General Journal Line.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 3.Verify: Verify Insurance Ledger Entries.
        VerifyInsCoverageLedgerEntry(GenJournalLine."Account No.", DimensionSetID);

        // 4.Tear Down: Change back to the Insurance Depreciation Book in FA Setup.
        InsuranceDeprBookInFASetup(OldInsuranceDeprBook);
        ModifyInsurancePosting(AutomaticInsurancePosting);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ManualInsuranceNotDefaultDim()
    var
        GenJournalLine: Record "Gen. Journal Line";
        OldInsuranceDeprBook: Code[10];
        AutomaticInsurancePosting: Boolean;
        OldUseDefaultDimension: Boolean;
        DimensionSetID: Integer;
    begin
        // Test the Fixed Asset General Journal with Automatic Insurance Posting False in FA Setup with Insurance and
        // Use Default Dimension False in Depreciation Book.

        // 1.Setup: Create General Journal Line of Fixed Asset type and update the Insurance Number, Dimension in General Journal Line.
        Initialize();
        CreateFAGLJournalLine(GenJournalLine);
        OldUseDefaultDimension := UseDefaultDimDepreciationBook(GenJournalLine."Depreciation Book Code", false);
        InsuranceInGenJournalLine(GenJournalLine, FindInsurance());
        AutomaticInsurancePosting := ModifyInsurancePosting(false);
        OldInsuranceDeprBook := InsuranceDeprBookInFASetup(GenJournalLine."Depreciation Book Code");
        AttachDimensionInJournalLine(GenJournalLine);
        DimensionSetID := GenJournalLine."Dimension Set ID";

        // 2.Exercise: Post the General Journal Line.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 3.Verify: Verify Insurance Journal Line.
        VerifyInsuranceJournalLine(GenJournalLine."Account No.", DimensionSetID);

        // 4.Tear Down: Change back to the FA Setup.
        InsuranceDeprBookInFASetup(OldInsuranceDeprBook);
        ModifyInsurancePosting(AutomaticInsurancePosting);
        UseDefaultDimDepreciationBook(GenJournalLine."Depreciation Book Code", OldUseDefaultDimension);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ManualInsuranceWithDefaultDim()
    var
        DefaultDimension: Record "Default Dimension";
        GenJournalLine: Record "Gen. Journal Line";
        OldInsuranceDeprBook: Code[10];
        AutomaticInsurancePosting: Boolean;
        OldUseDefaultDimension: Boolean;
    begin
        // Test the Fixed Asset General Journal with Automatic Insurance Posting FALSE in FA Setup with new Insurance and
        // Use Default Dimension True in Depreciation Book.

        // 1.Setup: Create General Journal Line of Fixed Asset type and update the Insurance Number.
        Initialize();
        CreateFAGLJournalLine(GenJournalLine);
        OldUseDefaultDimension := UseDefaultDimDepreciationBook(GenJournalLine."Depreciation Book Code", true);
        InsuranceInGenJournalLine(GenJournalLine, CreateInsuranceWithDimension());
        AutomaticInsurancePosting := ModifyInsurancePosting(false);
        LibraryDimension.FindDefaultDimension(DefaultDimension, DATABASE::Insurance, GenJournalLine."Insurance No.");
        OldInsuranceDeprBook := InsuranceDeprBookInFASetup(GenJournalLine."Depreciation Book Code");
        AttachDimensionInJournalLine(GenJournalLine);

        // 2.Exercise: Post the General Journal Line.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 3.Verify: Verify Insurance's Dimension on Insurance Journal Line.
        VerifyInsuranceDimension(DefaultDimension, GenJournalLine."Account No.");

        // 4.Tear Down: Change back to the FA Setup.
        InsuranceDeprBookInFASetup(OldInsuranceDeprBook);
        ModifyInsurancePosting(AutomaticInsurancePosting);
        UseDefaultDimDepreciationBook(GenJournalLine."Depreciation Book Code", OldUseDefaultDimension);
    end;

    [Test]
    [HandlerFunctions('DepreciationCalcConfirmHandler')]
    [Scope('OnPrem')]
    procedure DepreciationBalanceAccount()
    var
        FAAllocation: Record "FA Allocation";
        FANo: Code[20];
    begin
        // Test the Calculate Depreciation with Balance Account.

        // 1.Setup,Exercise: Calculate Depreciation.
        Initialize();
        FANo := DepreciationWithFixedAsset(FAAllocation, true);

        // 2.Verify: Verify Dimension on FA GL Journal.
        VerifyDimensionOnGLJournal(FANo, FAAllocation.Code, FAAllocation."Allocation Type"::Depreciation);
        VerifyFAGLJournal(FANo, 0);
    end;

    [Test]
    [HandlerFunctions('DepreciationCalcConfirmHandler')]
    [Scope('OnPrem')]
    procedure DepreciationNotBalanceAccount()
    var
        FAAllocation: Record "FA Allocation";
        FANo: Code[20];
    begin
        // Test the Calculate Depreciation with out Balance Account.

        // 1.Setup,Exercise: Calculate Depreciation.
        Initialize();
        FANo := DepreciationWithFixedAsset(FAAllocation, false);

        // 2.Verify: Verify FA General Journal.
        VerifyFAGLJournal(FANo, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DimensionOnFALedgerEntry()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DimensionSetID: Integer;
    begin
        // Test the FA Ledger Entry with FA General Journal.

        // 1.Setup: Create FA Gen Journal Line of Fixed Asset type, Dimension in FA General Journal Line.
        Initialize();
        CreateFAGLJournalLine(GenJournalLine);
        AttachDimensionInJournalLine(GenJournalLine);
        DimensionSetID := GenJournalLine."Dimension Set ID";

        // 2.Exercise: Post the General Journal Line.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 3.Verify: Verify FA Ledger Entries.
        VerifyFALedgerEntry(GenJournalLine."Account No.", DimensionSetID);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CancelLedgerEntry()
    var
        FADepreciationBook: Record "FA Depreciation Book";
        FALedgerEntry: Record "FA Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        DimensionSetID: Integer;
    begin
        // 1.Setup: Create Fixed Asset, Depreciation Book, FA Depreciation Book, create FA Journal Line, create the Dimensions for
        // FA General Journal, post the created FA Gl Journal.
        Initialize();
        CreateFixedAssetDepreciation(FADepreciationBook);
        CreateFAGLJournalLines(GenJournalLine, FADepreciationBook);
        AttachDimensionInJournalLine(GenJournalLine);
        DimensionSetID := GenJournalLine."Dimension Set ID";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        FindFALedgerEntry(FALedgerEntry, GenJournalLine."Account No.");

        // Exercise: Cancel FA Ledger Entries.
        RunCancelFAEntries(FALedgerEntry);

        // Verify: Verify the FA Journal Line.
        VerifyFAGLJournal(GenJournalLine."Account No.", DimensionSetID);
        LibraryFixedAsset.VerifyLastFARegisterGLRegisterOneToOneRelation(); // TFS 376879
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelLedgerBalanceAccount()
    begin
        // Test the Cancel FA Ledger Entry with Balance Account.
        CancelFALedgerEntry(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelLedgerNotBalanceAccount()
    begin
        // Test the Cancel FA Ledger Entry with out Balance Account.
        CancelFALedgerEntry(false);
    end;

    local procedure CancelFALedgerEntry(BalAccount: Boolean)
    var
        FADepreciationBook: Record "FA Depreciation Book";
        GenJournalLine: Record "Gen. Journal Line";
        DimensionSetID: Integer;
    begin
        // 1.Setup: Create Fixed Asset, Depreciation Book, FA Depreciation Book, create FA Journal Line, create the Dimensions for
        // FA General Journal, post the created FA Gl Journal.
        Initialize();
        CreateFixedAssetDepreciation(FADepreciationBook);
        CreateFAGLJournalLines(GenJournalLine, FADepreciationBook);
        AttachDimensionInJournalLine(GenJournalLine);
        DimensionSetID := GenJournalLine."Dimension Set ID";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        UpdateGenJournalBatchPostingNoSeries(GenJournalLine."Depreciation Book Code");

        // 2.Exercise: Run the Cancel FA Ledger Entry.
        RunCancelFALedgerEntry(GenJournalLine."Account No.", GenJournalLine."Depreciation Book Code", BalAccount);

        // 3.Verify: Verify General Journal.
        VerifyFAGLJournal(GenJournalLine."Account No.", DimensionSetID);
        LibraryFixedAsset.VerifyLastFARegisterGLRegisterOneToOneRelation(); // TFS 376879
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DepreciationByCopyDepreciation()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DimensionSetID: Integer;
        DepreciationBookToCopy: Code[10];
    begin
        // Test the Copy Depreciation Book.

        // 1.Setup: Create FA General Journal Line, create Dimension for FA General Journal, post the FA GL Journal, Create a new
        // Depreciation Book.
        Initialize();
        CreateFAGLJournalLine(GenJournalLine);
        AttachDimensionInJournalLine(GenJournalLine);
        DimensionSetID := GenJournalLine."Dimension Set ID";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        DepreciationBookToCopy := CreateDepreciationBookAndSetup();

        // 2.Exercise: Run Copy Depreciation Book.
        RunCopyDepreciationBook(GenJournalLine."Account No.", GenJournalLine."Depreciation Book Code", DepreciationBookToCopy);

        // 3.Verify: Verify FA Journal Line and FA Ledger Entry.
        VerifyFAJournalLine(GenJournalLine."Account No.", DepreciationBookToCopy, DimensionSetID);
        VerifyFALedgerEntry(GenJournalLine."Account No.", DimensionSetID);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DuplicateWithOutUseDefaultDim()
    begin
        // Test the creation of Journal by Duplication of Journal and Use Default Dimension is FALSE.
        CreatingJournalByDuplication(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DuplicateWithUseDefaultDim()
    begin
        // Test the creation of Journal by Duplication of Journal and Use Default Dimension is TRUE.
        CreatingJournalByDuplication(true);
    end;

    local procedure CreatingJournalByDuplication(UseDefaultDimension: Boolean)
    var
        FADepreciationBook: Record "FA Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        GenJournalLine: Record "Gen. Journal Line";
        OldUseDefaultDimension: Boolean;
        DimensionSetID: Integer;
        DepreciationBookToCopy: Code[10];
    begin
        // 1.Setup: Create FA General Journal Line, create Dimension for FA General Journal, post the FA GL Journal, Create a new
        // Depreciation Book.
        Initialize();
        CreateFAGLJournalLine(GenJournalLine);
        FixedAsset.Get(GenJournalLine."Account No.");
        OldUseDefaultDimension := UseDefaultDimDepreciationBook(GenJournalLine."Depreciation Book Code", UseDefaultDimension);
        UseDefaultDimDepreciationBook(GenJournalLine."Depreciation Book Code", OldUseDefaultDimension);
        DepreciationBookToCopy := CreateDepreciationBookAndSetup();
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", DepreciationBookToCopy, FixedAsset."FA Posting Group");
        GenJournalLine.Validate("Duplicate in Depreciation Book", DepreciationBookToCopy);
        GenJournalLine.Modify(true);
        AttachDimensionInJournalLine(GenJournalLine);
        DimensionSetID := GenJournalLine."Dimension Set ID";

        // 2.Exercise: Post the FA General Line.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 3.Verify: Verify the FA Journal.
        VerifyFAJournalLine(FixedAsset."No.", DepreciationBookToCopy, DimensionSetID);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DimensionOnFixedAsset()
    var
        DimensionValue: Record "Dimension Value";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Test the dimension in FA Ledger Entry of Fixed Asset.

        // 1.Setup: Create FA Gen Journal Line of Fixed Asset type, attach dimension on Fixed Asset, update the Account No in FA General
        // Journal Line.
        Initialize();
        CreateFAGLJournalLine(GenJournalLine);
        AttachDimensionOnFixedAsset(DimensionValue, GenJournalLine."Account No.");
        UpdateAccountNoInJournalLine(GenJournalLine, GenJournalLine."Account No.");

        // 2.Exercise: Post the General Journal Line.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 3.Verify: Verify dimension in FA Ledger Entry.
        VerifyDimensionOnLedgerEntry(DimensionValue, GenJournalLine."Account No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DimensionOnMaintenanceLedger()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DimensionSetID: Integer;
    begin
        // Test the Dimension in Maintenance Ledger Entry.

        // 1.Setup: Create FA General Journal Line of Posting Type Maintenance, create Dimension for FA General Journal.
        Initialize();
        CreateFAGLJournalLine(GenJournalLine);
        ModifyFAPostingType(GenJournalLine, GenJournalLine."FA Posting Type"::Maintenance);
        AttachDimensionInJournalLine(GenJournalLine);
        DimensionSetID := GenJournalLine."Dimension Set ID";

        // 2.Exercise: Post the FA General Journal Line.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 3.Verify: Verify Maintenance Ledger Entry.
        VerifyMaintenanceLedgerEntry(GenJournalLine."Account No.", DimensionSetID);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DimensionOnLedgerEntry()
    var
        FADepreciationBook: Record "FA Depreciation Book";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
        DimensionSetID: Integer;
        DimensionSetID2: Integer;
        FixedAssetNo: Code[20];
        FixedAssetNo2: Code[20];
    begin
        // Test the Dimension in FA Ledger Entry and Maintenance Ledger Entry.

        // 1.Setup: Create FA General Journal Lines and attach Dimension on FA General Journal Line.
        Initialize();
        LibraryERM.CreateGLAccount(GLAccount);
        CreateFAGLJournalLine(GenJournalLine);
        FixedAssetNo := GenJournalLine."Account No.";
        AttachDimensionInJournalLine(GenJournalLine);
        DimensionSetID := GenJournalLine."Dimension Set ID";
        GenJournalBatch.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name");
        CreateFixedAssetDepreciation(FADepreciationBook);
        FixedAssetNo2 := FADepreciationBook."FA No.";
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, FixedAssetNo2, GenJournalLine."FA Posting Type"::Maintenance, GLAccount."No.",
          LibraryRandom.RandDec(1000, 2));  // Take Random Value.
        AttachDimensionInJournalLine(GenJournalLine);
        DimensionSetID2 := GenJournalLine."Dimension Set ID";

        // 2.Exercise: Post the FA General Journal Line.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 3.Verify: Verify FA Ledger Entry and Maintenance Ledger Entry.
        VerifyFALedgerEntry(FixedAssetNo, DimensionSetID);
        VerifyMaintenanceLedgerEntry(FixedAssetNo2, DimensionSetID2);
        LibraryFixedAsset.VerifyLastFARegisterGLRegisterOneToOneRelation(); // TFS 376879
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DimensionOnInsuranceLedger()
    var
        Insurance: Record Insurance;
        InsuranceJournalLine: Record "Insurance Journal Line";
        FANo: Code[20];
        DimensionSetID: Integer;
    begin
        // Test the Dimension in Insurance Ledger Entry.

        // 1.Setup: Create Insurance Journal Line, create Dimension for Insurance Journal.
        Initialize();
        LibraryFixedAsset.CreateInsurance(Insurance);
        CreateInsuranceJournalLine(InsuranceJournalLine, Insurance."No.");
        DimensionOnInsuranceJournal(InsuranceJournalLine);
        FANo := InsuranceJournalLine."FA No.";
        DimensionSetID := InsuranceJournalLine."Dimension Set ID";

        // 2.Exercise: Post the created Insurance Journal Line.
        LibraryFixedAsset.PostInsuranceJournal(InsuranceJournalLine);

        // 3.Verify: Verify Insurance Ledger Entry.
        VerifyInsCoverageLedgerEntry(FANo, DimensionSetID);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IndexFAWithBalanceAccount()
    var
        DimensionValue: Record "Dimension Value";
        FANo: Code[20];
        FAAllocationCode: Code[20];
    begin
        // Test the Index Fixed Assets with Balance Account.

        // 1.Setup, Exercise: Create and post FA General Journal for Posting Type Acquisition Cost, run the Index Fixed Assets.
        Initialize();
        FANo := IndexFixedAsset(DimensionValue, FAAllocationCode, true);

        // 2.Verify: Verify the FA General Journal.
        VerifyFAGLJournalLines(DimensionValue, FANo);
        VerifyDimensionOnFAAllocation(FANo, FAAllocationCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IndexFAWithOutBalanceAccount()
    var
        DimensionValue: Record "Dimension Value";
        FANo: Code[20];
        FAAllocationCode: Code[20];
    begin
        // Test the Index Fixed Assets with out Balance Account.

        // 1.Setup, Exercise: Create and post FA General Journal for Posting Type Acquisition Cost, run the Index Fixed Assets.
        Initialize();
        FANo := IndexFixedAsset(DimensionValue, FAAllocationCode, false);

        // 2.Verify: Verify the FA General Journal.
        VerifyFAGLJournalLines(DimensionValue, FANo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InsuranceIndex()
    var
        DefaultDimension: Record "Default Dimension";
        InsuranceJournalLine: Record "Insurance Journal Line";
        FANo: Code[20];
        InsuranceNo: Code[20];
    begin
        // Test the Index Insurance.

        // 1.Setup: Create and post the created Insurance Journal Line.
        Initialize();
        CreateInsuranceJournalLine(InsuranceJournalLine, CreateInsuranceWithDimension());
        FANo := InsuranceJournalLine."FA No.";
        InsuranceNo := InsuranceJournalLine."Insurance No.";
        LibraryFixedAsset.PostInsuranceJournal(InsuranceJournalLine);

        // 2.Exercise: Run the Index Insurance.
        RunIndexInsurance(FANo);

        // 3.Verify: Verify Dimension on Insurance Journal.
        LibraryDimension.FindDefaultDimension(DefaultDimension, DATABASE::Insurance, InsuranceNo);
        VerifyInsuranceDimension(DefaultDimension, FANo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InsertFABalanceAccount()
    var
        DimensionValue: Record "Dimension Value";
        FADepreciationBook: Record "FA Depreciation Book";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        FAGetBalanceAccount: Codeunit "FA Get Balance Account";
    begin
        // Test the Insert Balance Account.

        // 1.Setup: Create Insurance Journal, create Dimension for Insurance Journal.
        Initialize();
        CreateFixedAssetDepreciation(FADepreciationBook);
        AttachDimensionOnFixedAsset(DimensionValue, FADepreciationBook."FA No.");
        CreateGenJournalBatch(GenJournalBatch);
        CreateGenJournalNoBalAccount(GenJournalLine, GenJournalBatch, FADepreciationBook."FA No.");

        // 2.Exercise: Post the FA General Journal Line.
        FAGetBalanceAccount.InsertAcc(GenJournalLine);

        // 3.Verify: Verify the FA General Journal Lines.
        VerifyFAGLJournalLines(DimensionValue, FADepreciationBook."FA No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ReclassifyFixedAsset()
    var
        DimensionValue: Record "Dimension Value";
        DimensionValue2: Record "Dimension Value";
        FixedAsset: Record "Fixed Asset";
        FixedAsset2: Record "Fixed Asset";
        FAReclassJournalLine: Record "FA Reclass. Journal Line";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Test Reclassify the FA Reclass Journal.

        // 1.Setup: Create FA General Journal Line, attach dimesnion on Fixed Asset, post the created FA General Journal Line,
        // Create FA Reclass Journal Line.
        Initialize();
        CreateFAGLJournalLine(GenJournalLine);
        AttachDimensionOnFixedAsset(DimensionValue, GenJournalLine."Account No.");
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        FixedAsset.Get(GenJournalLine."Account No.");
        ModifyAccountInFAPostingGroup(FixedAsset."FA Posting Group");
        CreateFAGLJournalLine(GenJournalLine);
        AttachDimensionOnFixedAsset(DimensionValue2, GenJournalLine."Account No.");
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        FixedAsset2.Get(GenJournalLine."Account No.");
        ModifyAccountInFAPostingGroup(FixedAsset2."FA Posting Group");
        CreateFAReclassJournalLine(FAReclassJournalLine);
        UpdateFAReclassJournal(FAReclassJournalLine, FixedAsset."No.", FixedAsset2."No.");

        // 2.Exercise: Reclassify the Journal.
        CODEUNIT.Run(CODEUNIT::"FA Reclass. Jnl.-Transfer", FAReclassJournalLine);

        // 3.Verify: Verify the created FA General Journal Lines.
        VerifyFAGLJournalLines(DimensionValue, FixedAsset."No.");
        VerifyFAGLJournalLines(DimensionValue2, FixedAsset2."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateFixedAssetWithDimension()
    var
        DimensionValue: Record "Dimension Value";
        FixedAsset: Record "Fixed Asset";
    begin
        // Test Create New Fixed Asset and Attach a Dimension with Fixed Asset.

        // 1. Setup: Create Fixed Asset.
        Initialize();
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);

        // 2. Exercise: Adding Dimension on Fixed Asset.
        AttachDimensionOnFixedAsset(DimensionValue, FixedAsset."No.");

        // 3. Verify: Verify Fixed Asset Dimension Values.
        VerifyDimensionValue(DimensionValue, FixedAsset."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelFALedgerEntryDepreciationBookError()
    begin
        // Test error occurs on Running Cancel FA Ledger Entry Report without Depreciation Book Code.

        // 1. Setup.
        Initialize();

        // 2. Exercise: Run Cancel FA Ledger Entry Report.
        asserterror RunCancelFALedgerEntry('', '', false);

        // 3. Verify: Verify error occurs on Running Cancel FA Ledger Entry Report without Depreciation Book Code.
        Assert.ExpectedErrorCannotFind(Database::"Depreciation Book");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelFALedgerEntryGLIntegrationFalse()
    var
        DepreciationBook: Record "Depreciation Book";
        FANo: Code[20];
    begin
        // Test and verify Cancel FA Ledger Entry Report functionality for Depreciation Book G/L Integration as FALSE.

        // 1. Setup: Create Initial Setup for Fixed Asset. Update G/L Integration on Depreciation Book as FALSE.
        // Create and post FA Journal Lines.
        Initialize();
        FANo := CreateInitialSetupAndPostFAJournalLines(DepreciationBook);

        // 2. Exercise: Run Cancel FA Ledger Entry Report.
        RunCancelFALedgerEntry(FANo, DepreciationBook.Code, true);

        // 3. Verify: Verify created FA Journal Lines after running Cancel FA Ledger Entry Report.
        VerifyCancelFAJournalLines(FANo);

        // 4. Tear Down: Roll back changes on Depreciation Book.
        UpdateGLIntegration(
          DepreciationBook.Code, DepreciationBook."G/L Integration - Acq. Cost", DepreciationBook."G/L Integration - Depreciation");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelFALedgerEntryGLIntegrationTrue()
    var
        DepreciationBook: Record "Depreciation Book";
        FANo: Code[20];
    begin
        // Test and verify Cancel FA Ledger Entry Report functionality for Depreciation Book G/L Integration as TRUE.

        // 1. Setup: Create Initial Setup for Fixed Asset. Update G/L Integration on Depreciation Book as FALSE.
        // Create and post FA Journal Lines.
        Initialize();
        FANo := CreateInitialSetupAndPostFAJournalLines(DepreciationBook);

        // 2. Exercise: Update G/L Integration on Depreciation Book as TRUE and run Cancel FA Ledger Entry Report.
        UpdateGLIntegration(DepreciationBook.Code, true, true);
        RunCancelFALedgerEntry(FANo, DepreciationBook.Code, true);

        // 3. Verify: Verify created General Journal Lines after running Cancel FA Ledger Entry Report.
        VerifyCancelGenJournalLines(FANo);

        // 4. Tear Down: Roll back changes on Depreciation Book.
        UpdateGLIntegration(
          DepreciationBook.Code, DepreciationBook."G/L Integration - Acq. Cost", DepreciationBook."G/L Integration - Depreciation");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelFALedgerEntryWithInactiveFixedAsset()
    var
        DepreciationBook: Record "Depreciation Book";
        FANo: Code[20];
    begin
        // Test and verify Cancel FA Ledger Entry Report functionality for Inactive Fixed Asset.

        // 1. Setup: Create Initial Setup for Fixed Asset. Update G/L Integration on Depreciation Book as FALSE.
        // Create and post FA Journal Lines.
        Initialize();
        FANo := CreateInitialSetupAndPostFAJournalLines(DepreciationBook);

        // 2. Exercise: Check Inactive on Fixed Asset and run Cancel FA Ledger Entry Report.
        UpdateInactiveOnFixedAsset(FANo);
        RunCancelFALedgerEntry(FANo, DepreciationBook.Code, true);

        // 3. Verify: Verify General Journal Lines and FA Journal Lines must not be create after running Cancel FA Ledger Entry Report.
        Assert.IsFalse(FindFAJournalLine(FANo), StrSubstNo(LinesMustNotBeCreated, FANo));
        Assert.IsFalse(FindGeneralJournalLine(FANo), StrSubstNo(LinesMustNotBeCreated, FANo));

        // 4. Tear Down: Roll back changes on Depreciation Book.
        UpdateGLIntegration(
          DepreciationBook.Code, DepreciationBook."G/L Integration - Acq. Cost", DepreciationBook."G/L Integration - Depreciation");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelFALedgerEntryUseNewPostingDateGenJnl()
    var
        FAJournalSetup: Record "FA Journal Setup";
        FADepreciationBook: Record "FA Depreciation Book";
        DepreciationBook: Record "Depreciation Book";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        ExpectedDocumentNo: Code[20];
        PostingDate: Date;
        NewPostingDate: Date;
    begin
        // Test and verify general journal line "Document No." created by Cancel FA Ledger Entry Report with UseNewPostingDate option

        CreateFixedAssetDepreciation(FADepreciationBook);
        DepreciationBook.Get(FADepreciationBook."Depreciation Book Code"); // Get Depreciation book record to save values before updating
        UpdateUseSameDates(DepreciationBook.Code, false);

        CreateAndPostGenJournalLines(GenJournalLine, FADepreciationBook."FA No.");
        PostingDate := GenJournalLine."Posting Date";

        // Clean up Gen. Journal Lines with new batch created by procedure CreateAndPostGenJournalLines
        DeleteGeneralJournalLine(GenJournalLine."Journal Template Name", ''); // take '' for batch name

        CreateGenJournalBatchWithNoSeries(GenJournalBatch, FADepreciationBook."Depreciation Book Code", PostingDate, 2); // take 2 to series line count
        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);

        // Use new period (new series line) for the next calculations
        NewPostingDate := CalcDate('<1M>', PostingDate);

        // Change template and batch to get Expected Document No from batch series line.
        GenJournalLine."Journal Template Name" := GenJournalBatch."Journal Template Name";
        GenJournalLine."Journal Batch Name" := GenJournalBatch.Name;
        ExpectedDocumentNo := FAJournalSetup.GetGenJnlDocumentNo(GenJournalLine, NewPostingDate, false);

        // Exercise: Run Cancel FA Ledger Entry Report for the first period. Use New Posting date - next period.
        RunCancelFALedgerEntryWithtParams(
          FADepreciationBook."FA No.", DepreciationBook.Code, PostingDate, PostingDate, true, NewPostingDate, false);

        // Verify
        VerifyExpectedGenJnlDocNo(GenJournalBatch."Journal Template Name", GenJournalBatch.Name, ExpectedDocumentNo);

        // Tear Down: Rollbak Depreciation Book and clean up Gen. Journal Lines
        UpdateUseSameDates(FADepreciationBook."Depreciation Book Code", DepreciationBook."Use Same FA+G/L Posting Dates");
        DeleteGeneralJournalLine(GenJournalBatch."Journal Template Name", GenJournalBatch.Name);
        LibraryFixedAsset.VerifyLastFARegisterGLRegisterOneToOneRelation(); // TFS 376879
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelFALedgerEntryUseNewPostingDateFAJnl()
    var
        FAJournalSetup: Record "FA Journal Setup";
        FADepreciationBook: Record "FA Depreciation Book";
        DepreciationBook: Record "Depreciation Book";
        FAJournalBatch: Record "FA Journal Batch";
        FAJournalLine: Record "FA Journal Line";
        ExpectedDocumentNo: Code[20];
        PostingDate: Date;
        NewPostingDate: Date;
    begin
        // Test and verify FA journal line "Document No." created by Cancel FA Ledger Entry Report with UseNewPostingDate option

        CreateFixedAssetDepreciation(FADepreciationBook);
        DepreciationBook.Get(FADepreciationBook."Depreciation Book Code"); // Get Depreciation book record to save values before updating
        UpdateUseSameDates(DepreciationBook.Code, false);
        UpdateGLIntegration(DepreciationBook.Code, false, false);

        PostingDate := CreateAndPostFAJournalLines(FAJournalLine, FADepreciationBook);

        // Clean up FA Journal Lines with new batch created by procedure CreateAndPostFAJournalLines
        DeleteFAJournalLine(FAJournalLine."Journal Template Name", ''); // take '' for batch name

        CreateFAJournalBatchWithNoSeries(FAJournalBatch, FADepreciationBook."Depreciation Book Code", PostingDate, 2); // take 2 to series line count
        FAJournalLine.SetRange("Journal Template Name", FAJournalBatch."Journal Template Name");
        FAJournalLine.SetRange("Journal Batch Name", FAJournalBatch.Name);

        // Use new period (new series line) for the next calculations
        NewPostingDate := CalcDate('<1M>', PostingDate);

        // Change template and batch to get Expected Document No from batch series line.
        FAJournalLine."Journal Template Name" := FAJournalBatch."Journal Template Name";
        FAJournalLine."Journal Batch Name" := FAJournalBatch.Name;
        ExpectedDocumentNo := FAJournalSetup.GetFAJnlDocumentNo(FAJournalLine, NewPostingDate, false);

        // Exercise: Run Cancel FA Ledger Entry Report for the first period. Use New Posting date - next period.
        RunCancelFALedgerEntryWithtParams(
          FADepreciationBook."FA No.", DepreciationBook.Code, PostingDate, PostingDate, true, NewPostingDate, false);

        // Verify
        VerifyExpectedFAJnlDocNo(FAJournalBatch."Journal Template Name", FAJournalBatch.Name, ExpectedDocumentNo);

        // Tear Down: Rollback Depreciation Book and delete FA Journal Lines,
        UpdateUseSameDates(FADepreciationBook."Depreciation Book Code", DepreciationBook."Use Same FA+G/L Posting Dates");
        UpdateGLIntegration(
          FADepreciationBook."Depreciation Book Code", DepreciationBook."G/L Integration - Acq. Cost",
          DepreciationBook."G/L Integration - Depreciation");
        DeleteFAJournalLine(FAJournalBatch."Journal Template Name", FAJournalBatch.Name);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DimensionErrorOnFixedAsset()
    var
        DefaultDimension: Record "Default Dimension";
        FADepreciationBook: Record "FA Depreciation Book";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        GLAccount: Record "G/L Account";
    begin
        // Test Error Message while posting Disposal of zero Amount from FA GL Journal Line when Balance Account having Dimension Value Blank and Value Posting as Code Mandatory.

        // 1. Setup: Create Disposal entry for Fixed Asset using FA GL Journal with Zero Amount, Take Balance Account with Dimension Value Blank and Value Posting Code Mandatory.
        Initialize();
        CreateFixedAssetDepreciation(FADepreciationBook);
        CreateGenJournalBatch(GenJournalBatch);
        CreateGLAccountWithDimension(DefaultDimension);
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, FADepreciationBook."FA No.", GenJournalLine."FA Posting Type"::Disposal, DefaultDimension."No.",
          0);

        // 2. Exercise: Try to post General Journal Line.
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 3. Verify: Verify Error Message.
        Assert.ExpectedError(
          StrSubstNo(
            DimensionValueError, GenJournalLine.TableCaption(), GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name",
            GenJournalLine."Line No.", DefaultDimension.FieldCaption("Dimension Value Code"),
            DefaultDimension.FieldCaption("Dimension Code"), DefaultDimension."Dimension Code", GLAccount.TableCaption(),
            GenJournalLine."Bal. Account No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DimensionErrorOnFixedAssetAllocation()
    var
        DefaultDimension: Record "Default Dimension";
        FAAllocation: Record "FA Allocation";
        FADepreciationBook: Record "FA Depreciation Book";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
    begin
        // Test Error Message while posting Disposal of zero Amount from FA GL Journal Line when Dimension Value on FA Allocation Dimension Account is Blank and Value Posting is Code Mandatory.

        // 1. Setup: Create FA Allocation with Account having Dimension Value Blank, Create Aquisition Cost and Disposal Entry for Fixed Asset using FA GL Journal, take Random Amount.
        Initialize();
        LibraryERM.CreateGLAccount(GLAccount);
        CreateGLAccountWithDimension(DefaultDimension);
        CreateFixedAssetDepreciation(FADepreciationBook);
        CreateAndAttachDimensionOnFAAllocation(FAAllocation, FADepreciationBook."FA Posting Group", FAAllocation."Allocation Type"::Loss);
        UpdateAccountNoInFAAllocation(FAAllocation, DefaultDimension."No.");

        CreateGenJournalBatch(GenJournalBatch);
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, FADepreciationBook."FA No.", GenJournalLine."FA Posting Type"::"Acquisition Cost",
          GLAccount."No.", LibraryRandom.RandDec(100, 2));
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, FADepreciationBook."FA No.", GenJournalLine."FA Posting Type"::Disposal, GLAccount."No.", 0);

        // 2. Exercise: Try to post General Journal Line.
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 3. Verify: Verify Error Message.
        Assert.ExpectedError(
          StrSubstNo(DimensionValueError2,
            DefaultDimension.FieldCaption("Dimension Value Code"),
            DefaultDimension.FieldCaption("Dimension Code"), DefaultDimension."Dimension Code", GLAccount.TableCaption(),
            DefaultDimension."No."));
    end;

    [Test]
    [HandlerFunctions('DepreciationCalcConfirmHandler')]
    [Scope('OnPrem')]
    procedure DepreciationBalanceAccountDimension()
    var
        GLAccount: Record "G/L Account";
        DefaultDimension: Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
        FADepreciationBook: Record "FA Depreciation Book";
        FAAllocation: Record "FA Allocation";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Test the Calculate Depreciation with Bal Account and two Dimensions.

        // 1. Setup.
        Initialize();
        GLAccount.Get(CreateGLAccountWithDimension(DefaultDimension));
        CreateFixedAssetDepreciation(FADepreciationBook);
        CreateAndAttachDimensionOnFAAllocation(FAAllocation,
          FADepreciationBook."FA Posting Group", FAAllocation."Allocation Type"::Depreciation);
        UpdateAccountNoInFAAllocation(FAAllocation, GLAccount."No.");

        LibraryDimension.FindDimensionValue(DimensionValue, DefaultDimension."Dimension Code");
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, DATABASE::"Fixed Asset", FADepreciationBook."FA No.",
          DimensionValue."Dimension Code", DimensionValue.Code);

        CreateGenJournalBatch(GenJournalBatch);
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, FADepreciationBook."FA No.", GenJournalLine."FA Posting Type"::"Acquisition Cost",
          GLAccount."No.", LibraryRandom.RandDec(100, 2));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 2.Exercise: Run the Calculate Depreciation.
        RunCalculateDepreciation(FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code", true);

        // 3. Verify.
        VerifyDimensionValueOnGLJournal(FADepreciationBook."FA No.", GLAccount."No.", DimensionValue);
    end;

    [Test]
    [HandlerFunctions('DepreciationCalcConfirmHandler')]
    [Scope('OnPrem')]
    procedure CombinedDiffDefaultDimOnCalculateDepreciationWithInsertBalAcc()
    var
        FADepreciationBook: Record "FA Depreciation Book";
        GLAccNo: Code[20];
        GLIntegrationAcqCostOld: Boolean;
    begin
        // [FEATURE] [Depreciation]
        // [SCENARIO 361995] Combination of the different Default Dimensions when depreciation calculated with "Insert Bal. Account" option

        Initialize();
        // [GIVEN] G/L Account "X" with Default Dimension "A"
        GLAccNo := CreateGLAccountWithDefaultDimension();
        // [GIVEN] Create Fixed Asset with "Depreciation Expense Acc." = "X" and Default Dimension "B"
        CreateFixedAssetDepreciationWithSetup(FADepreciationBook, GLIntegrationAcqCostOld, GLAccNo);
        CreateDefaultDim(DATABASE::"Fixed Asset", FADepreciationBook."FA No.");

        // [GIVEN] Posted Acquisition
        PostAcquisitionCost(FADepreciationBook);

        // [WHEN] Run Calculate Depreciation Job with "Insert Bal. Account"
        RunCalculateDepreciation(FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code", true);

        // [THEN] "Dimension Set ID" in "Gen. Journal Line" with "Bal. Account" = "X" combined from default dimensions "A" and "B"
        VerifyDimSetEntryOnGenJnlLine(
          FADepreciationBook."FA No.", GLAccNo, GetDefaultDimID(GLAccNo, FADepreciationBook."FA No."));

        // Teardown
        ModifyAcquisitionIntegration(FADepreciationBook."Depreciation Book Code", GLIntegrationAcqCostOld);
    end;

    [Test]
    [HandlerFunctions('DepreciationCalcConfirmHandler')]
    [Scope('OnPrem')]
    procedure CombinedSameDefaultDimOnCalculateDepreciationWithInsertBalAcc()
    var
        GLAccount: Record "G/L Account";
        DefaultDimension: Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
        FADepreciationBook: Record "FA Depreciation Book";
        GLIntegrationAcqCostOld: Boolean;
    begin
        // [FEATURE] [Depreciation]
        // [SCENARIO 361995] Combination of the same Default Dimensions with different values when depreciation calculated with "Insert Bal. Account" option

        Initialize();
        // [GIVEN] G/L Account "X" with Default Dimension "Area" = "A"
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, DATABASE::"G/L Account", GLAccount."No.",
          DimensionValue."Dimension Code", DimensionValue.Code);

        // [GIVEN] Create Fixed Asset with "Depreciation Expense Acc." = "X" and Default Dimension "Area" = "B"
        CreateFixedAssetDepreciationWithSetup(FADepreciationBook, GLIntegrationAcqCostOld, GLAccount."No.");
        LibraryDimension.CreateDimensionValue(DimensionValue, DimensionValue."Dimension Code");
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, DATABASE::"Fixed Asset", FADepreciationBook."FA No.",
          DimensionValue."Dimension Code", DimensionValue.Code);

        // [GIVEN] Posted Acquisition
        PostAcquisitionCost(FADepreciationBook);

        // [WHEN] Run Calculate Depreciation Job with "Insert Bal. Account"
        RunCalculateDepreciation(FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code", true);

        // [THEN] "Dimension Set ID" in "Gen. Journal Line" with "Bal. Account" = "X" is equal default dimension "Area" = "B"
        VerifyDimSetEntryOnGenJnlLine(
          FADepreciationBook."FA No.", GLAccount."No.", GetDefaultDimID('', FADepreciationBook."FA No."));

        // Teardown
        ModifyAcquisitionIntegration(FADepreciationBook."Depreciation Book Code", GLIntegrationAcqCostOld);
    end;

    [Test]
    [HandlerFunctions('DepreciationCalcConfirmHandler')]
    [Scope('OnPrem')]
    procedure FADefaultDimPriorityHigherOnCalculateDepreciationWithInsertBalAcc()
    var
        GLAccount: Record "G/L Account";
        DefaultDimension: Record "Default Dimension";
        DefaultDimensionPriority: Record "Default Dimension Priority";
        DimensionValue: Record "Dimension Value";
        FADepreciationBook: Record "FA Depreciation Book";
        SourceCode: Code[10];
        GLIntegrationAcqCostOld: Boolean;
    begin
        // [FEATURE] [Depreciation]
        // [SCENARIO 357636] Fixed Asset Default Dimension priority is higher than G/L Accout Default Dimension priority when depreciation calculated with "Insert Bal. Account" option.
        Initialize();

        // [GIVEN] Default Dimension Priorities with Source Code = "Fixed Asset G/L Journal" where "Fixed Asset" priority > "G/L Account" priority.
        SourceCode := GetFAGLJournalSourceCode();
        CreateDefaultDimensionPriorityWithPriorityValue(
          DefaultDimensionPriority, SourceCode, DATABASE::"Fixed Asset", LibraryRandom.RandInt(10));
        CreateDefaultDimensionPriorityWithPriorityValue(
          DefaultDimensionPriority, SourceCode, DATABASE::"G/L Account", LibraryRandom.RandIntInRange(11, 20));

        // [GIVEN] G/L Account "X" with Default Dimension "Area" = "A".
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, DATABASE::"G/L Account", GLAccount."No.",
          DimensionValue."Dimension Code", DimensionValue.Code);

        // [GIVEN] Create Fixed Asset with "Depreciation Expense Acc." = "X" and Default Dimension "Area" = "B".
        CreateFixedAssetDepreciationWithSetup(FADepreciationBook, GLIntegrationAcqCostOld, GLAccount."No.");
        LibraryDimension.CreateDimensionValue(DimensionValue, DimensionValue."Dimension Code");
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, DATABASE::"Fixed Asset", FADepreciationBook."FA No.",
          DimensionValue."Dimension Code", DimensionValue.Code);

        // [GIVEN] Posted Acquisition.
        PostAcquisitionCost(FADepreciationBook);

        // [WHEN] Run Calculate Depreciation Job with "Insert Bal. Account".
        RunCalculateDepreciation(FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code", true);

        // [THEN] "Dimension Set ID" in "Gen. Journal Line" with "Bal. Account" = "X" is equal default dimension "Area" = "B".
        VerifyDimSetEntryOnGenJnlLine(
          FADepreciationBook."FA No.", GLAccount."No.", GetDefaultDimID('', FADepreciationBook."FA No."));

        // Teardown
        ModifyAcquisitionIntegration(FADepreciationBook."Depreciation Book Code", GLIntegrationAcqCostOld);
        DeleteDefaultDimensionPriorities(SourceCode);
    end;

    [Test]
    [HandlerFunctions('DepreciationCalcConfirmHandler')]
    [Scope('OnPrem')]
    procedure BalAccDefaultDimPriorityHigherOnCalculateDepreciationWithInsertBalAcc()
    var
        GLAccount: Record "G/L Account";
        DefaultDimension: Record "Default Dimension";
        DefaultDimensionPriority: Record "Default Dimension Priority";
        DimensionValue: Record "Dimension Value";
        FADepreciationBook: Record "FA Depreciation Book";
        SourceCode: Code[10];
        GLIntegrationAcqCostOld: Boolean;
    begin
        // [FEATURE] [Depreciation]
        // [SCENARIO 357636] Fixed Asset Default Dimension priority is lower than G/L Accout Default Dimension priority when depreciation calculated with "Insert Bal. Account" option.
        Initialize();

        // [GIVEN] Default Dimension Priorities with Source Code = "Fixed Asset G/L Journal" where "Fixed Asset" priority < "G/L Account" priority.
        SourceCode := GetFAGLJournalSourceCode();
        CreateDefaultDimensionPriorityWithPriorityValue(
          DefaultDimensionPriority, SourceCode, DATABASE::"G/L Account", LibraryRandom.RandInt(10));
        CreateDefaultDimensionPriorityWithPriorityValue(
          DefaultDimensionPriority, SourceCode, DATABASE::"Fixed Asset", LibraryRandom.RandIntInRange(11, 20));

        // [GIVEN] G/L Account "X" with Default Dimension "Area" = "A".
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, DATABASE::"G/L Account", GLAccount."No.",
          DimensionValue."Dimension Code", DimensionValue.Code);

        // [GIVEN] Create Fixed Asset with "Depreciation Expense Acc." = "X" and Default Dimension "Area" = "B".
        CreateFixedAssetDepreciationWithSetup(FADepreciationBook, GLIntegrationAcqCostOld, GLAccount."No.");
        LibraryDimension.CreateDimensionValue(DimensionValue, DimensionValue."Dimension Code");
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, DATABASE::"Fixed Asset", FADepreciationBook."FA No.",
          DimensionValue."Dimension Code", DimensionValue.Code);

        // [GIVEN] Posted Acquisition.
        PostAcquisitionCost(FADepreciationBook);

        // [WHEN] Run Calculate Depreciation Job with "Insert Bal. Account".
        RunCalculateDepreciation(FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code", true);

        // [THEN] "Dimension Set ID" in "Gen. Journal Line" with "Bal. Account" = "X" is equal default dimension "Area" = "A".
        VerifyDimSetEntryOnGenJnlLine(
          FADepreciationBook."FA No.", GLAccount."No.", GetDefaultDimID(GLAccount."No.", ''));

        // Teardown
        ModifyAcquisitionIntegration(FADepreciationBook."Depreciation Book Code", GLIntegrationAcqCostOld);
        DeleteDefaultDimensionPriorities(SourceCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FALedgerEntryMoveToGenJnlCopyGlobalDimensions()
    var
        FALedgerEntry: Record "FA Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 376439] "FA Ledger Entry".MoveToGenJnl must copy values of global dimension from FA Ledger Entry to Gen. Journal Line
        Initialize();

        // [GIVEN] FA Ledger Entry with
        // [GIVEN] Global Dimension 1 Code = "GD1C"
        // [GIVEN] Global Dimension 2 Code = "GD2C"
        FALedgerEntry."Global Dimension 1 Code" := LibraryUtility.GenerateRandomCode20(
            FALedgerEntry.FieldNo("Global Dimension 1 Code"), Database::"FA Ledger Entry");
        FALedgerEntry."Global Dimension 2 Code" := LibraryUtility.GenerateRandomCode20(
            FALedgerEntry.FieldNo("Global Dimension 2 Code"), Database::"FA Ledger Entry");

        // [GIVEN] Gen. Journal Line
        CreateGenJournalBatch(GenJournalBatch);
        GenJournalLine."Journal Template Name" := GenJournalBatch."Journal Template Name";
        GenJournalLine."Journal Batch Name" := GenJournalBatch.Name;

        // [WHEN] Invoke "FA Ledger Entry".MoveToGenJnl
        FALedgerEntry.MoveToGenJnl(GenJournalLine);

        // [THEN] "Gen. Journal Line"."Shortcut Dimension 1 Code" = "GD1C"
        GenJournalLine.TestField("Shortcut Dimension 1 Code", FALedgerEntry."Global Dimension 1 Code");

        // [THEN] "Gen. Journal Line"."Shortcut Dimension 2 Code" = "GD2C"
        GenJournalLine.TestField("Shortcut Dimension 2 Code", FALedgerEntry."Global Dimension 2 Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FALedgerEntryMoveToFAJnlCopyGlobalDimensions()
    var
        FALedgerEntry: Record "FA Ledger Entry";
        FAJournalLine: Record "FA Journal Line";
        FAJournalBatch: Record "FA Journal Batch";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 376439] "FA Ledger Entry".MoveToFAJnl must copy values of global dimension from FA Ledger Entry to FA Journa Line
        Initialize();

        // [GIVEN] FA Ledger Entry with
        // [GIVEN] Global Dimension 1 Code = "GD1C"
        // [GIVEN] Global Dimension 2 Code = "GD2C"
        FALedgerEntry."Global Dimension 1 Code" := LibraryUtility.GenerateRandomCode20(
            FALedgerEntry.FieldNo("Global Dimension 1 Code"), Database::"FA Ledger Entry");
        FALedgerEntry."Global Dimension 2 Code" := LibraryUtility.GenerateRandomCode20(
            FALedgerEntry.FieldNo("Global Dimension 2 Code"), Database::"FA Ledger Entry");

        // [GIVEN] FA Journal Line
        CreateFAJournalBatch(FAJournalBatch);
        FAJournalLine."Journal Template Name" := FAJournalBatch."Journal Template Name";
        FAJournalLine."Journal Batch Name" := FAJournalBatch.Name;

        // [WHEN] Invoke "FA Ledger Entry".MoveToFAJnl
        FALedgerEntry.MoveToFAJnl(FAJournalLine);

        // [THEN] "FA Journal Line"."Shortcut Dimension 1 Code" = "GD1C"
        FAJournalLine.TestField("Shortcut Dimension 1 Code", FALedgerEntry."Global Dimension 1 Code");

        // [THEN] "FA Journal Line"."Shortcut Dimension 2 Code" = "GD2C"
        FAJournalLine.TestField("Shortcut Dimension 2 Code", FALedgerEntry."Global Dimension 2 Code");
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('DepreciationCalcConfirmHandler')]
    procedure CalcDeprOnFixedAssetWithDeprAllocAndDimMandatory()
    var
        DefaultDimension: Record "Default Dimension";
        FAAllocation: Record "FA Allocation";
        FADepreciationBook: Record "FA Depreciation Book";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        FAJournalSetup: Record "FA Journal Setup";
        GLAccount: Record "G/L Account";
    begin
        // [SCENARIO 432878] Calculate depreciation task should create journal lines when dimension value on depreciation FA allocation dimension account is blank and Code Mandatory.
        Initialize();

        // [GIVEN] Acquired fixed asset with depreciation FA allocation with G/L account with mandatory dimension
        LibraryERM.CreateGLAccount(GLAccount);
        CreateGLAccountWithDimension(DefaultDimension);
        CreateFixedAssetDepreciation(FADepreciationBook);
        CreateAndAttachDimensionOnFAAllocation(FAAllocation, FADepreciationBook."FA Posting Group", FAAllocation."Allocation Type"::Depreciation);
        UpdateAccountNoInFAAllocation(FAAllocation, DefaultDimension."No.");
        CreateGenJournalBatch(GenJournalBatch);
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, FADepreciationBook."FA No.", GenJournalLine."FA Posting Type"::"Acquisition Cost",
          GLAccount."No.", LibraryRandom.RandDec(100, 2));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Calculate depreciation
        if not FAJournalSetup.Get(FADepreciationBook."Depreciation Book Code", UserId) then
            FAJournalSetup.Get(FADepreciationBook."Depreciation Book Code", '');
        GenJournalLine.SetRange("Journal Template Name", FAJournalSetup."Gen. Jnl. Template Name");
        GenJournalLine.SetRange("Journal Batch Name", FAJournalSetup."Gen. Jnl. Batch Name");
        GenJournalLine.DeleteAll();
        RunCalculateDepreciation(FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code", true);

        // [THEN] Depreciation calculated, general journal line created
        GenJournalLine.SetRange("Journal Template Name", FAJournalSetup."Gen. Jnl. Template Name");
        GenJournalLine.SetRange("Journal Batch Name", FAJournalSetup."Gen. Jnl. Batch Name");
        GenJournalLine.FindSet();
        GenJournalLine.TestField("FA Posting Type", GenJournalLine."FA Posting Type"::Depreciation);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('DepreciationCalcConfirmHandler')]
    procedure CalcDeprAndPostOnFixedAssetWithDeprAllocAndDimMandatory()
    var
        DefaultDimension: Record "Default Dimension";
        FAAllocation: Record "FA Allocation";
        FADepreciationBook: Record "FA Depreciation Book";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        FAJournalSetup: Record "FA Journal Setup";
        GLAccount: Record "G/L Account";
    begin
        // [SCENARIO 432878] Calculate and post depreciation should give an error when dimension value on depreciation FA allocation dimension account is blank and Code Mandatory.
        Initialize();

        // [GIVEN] Acquired fixed asset with depreciation FA allocation with G/L account with mandatory dimension
        LibraryERM.CreateGLAccount(GLAccount);
        CreateGLAccountWithDimension(DefaultDimension);
        CreateFixedAssetDepreciation(FADepreciationBook);
        CreateAndAttachDimensionOnFAAllocation(FAAllocation, FADepreciationBook."FA Posting Group", FAAllocation."Allocation Type"::Depreciation);
        UpdateAccountNoInFAAllocation(FAAllocation, DefaultDimension."No.");
        CreateGenJournalBatch(GenJournalBatch);
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, FADepreciationBook."FA No.", GenJournalLine."FA Posting Type"::"Acquisition Cost",
          GLAccount."No.", LibraryRandom.RandDec(100, 2));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Calculated depreciation
        if not FAJournalSetup.Get(FADepreciationBook."Depreciation Book Code", UserId) then
            FAJournalSetup.Get(FADepreciationBook."Depreciation Book Code", '');
        GenJournalLine.SetRange("Journal Template Name", FAJournalSetup."Gen. Jnl. Template Name");
        GenJournalLine.SetRange("Journal Batch Name", FAJournalSetup."Gen. Jnl. Batch Name");
        GenJournalLine.DeleteAll();
        RunCalculateDepreciation(FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code", true);

        // [WHEN] Post depreciation
        GenJournalLine.SetRange("Journal Template Name", FAJournalSetup."Gen. Jnl. Template Name");
        GenJournalLine.SetRange("Journal Batch Name", FAJournalSetup."Gen. Jnl. Batch Name");
        GenJournalLine.FindSet();
        GenJournalLine.ModifyAll(Description, 'depreciation');
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Error message (dimension value required) is thrown
        Assert.ExpectedError(
            StrSubstNo(
                DimensionValueError2, DefaultDimension.FieldCaption("Dimension Value Code"), DefaultDimension.FieldCaption("Dimension Code"),
                DefaultDimension."Dimension Code", GLAccount.TableCaption(), DefaultDimension."No."));
    end;

    [Test]
    procedure VerifyDefaultDimensionsArePulledInFixedAssetInsuranceJournalLineFromFixedAsset()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        FixedAsset: Record "Fixed Asset";
        Insurance: Record "Insurance";
        DimensionValue1: Record "Dimension Value";
        DimensionValue2: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        InsuranceJournalLine: Record "Insurance Journal Line";
    begin
        // [SCENARIO 470969] Verify default dimensions are pulled in fixed asset insurance journal line from fixed asset
        Initialize();

        // [GIVEN] Get General Ledger Setup
        GeneralLedgerSetup.Get();

        // [GIVEN] Create fixed asset
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);

        // [GIVEN] Create insurance
        LibraryFixedAsset.CreateInsurance(Insurance);

        // [GIVEN] Create Global Dimension values
        LibraryDimension.CreateDimensionValue(DimensionValue1, GeneralLedgerSetup."Global Dimension 1 Code");
        LibraryDimension.CreateDimensionValue(DimensionValue2, GeneralLedgerSetup."Global Dimension 2 Code");

        // [GIVEN] Create default dimensions
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, DATABASE::"Fixed Asset", FixedAsset."No.", DimensionValue1."Dimension Code", DimensionValue1.Code);
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, DATABASE::"Fixed Asset", FixedAsset."No.", DimensionValue2."Dimension Code", DimensionValue2.Code);

        // [WHEN] Create insurance journal line
        CreateInsuranceJournalLine(InsuranceJournalLine, Insurance."No.", FixedAsset."No.");

        // [THEN]  Verify results
        Assert.AreEqual(DimensionValue1.Code, InsuranceJournalLine."Shortcut Dimension 1 Code", DimensionsAreNotEqual);
        Assert.AreEqual(DimensionValue2.Code, InsuranceJournalLine."Shortcut Dimension 2 Code", DimensionsAreNotEqual);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Dimension Fixed Assets");
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Dimension Fixed Assets");
        LibraryFiscalYear.CreateFiscalYear();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Dimension Fixed Assets");
    end;

    local procedure AllowIndexationInDepreciation("Code": Code[20]; AllowIndexation: Boolean) AllowIndexationOld: Boolean
    var
        DepreciationBook: Record "Depreciation Book";
    begin
        DepreciationBook.Get(Code);
        AllowIndexationOld := DepreciationBook."Allow Indexation";
        DepreciationBook.Validate("Allow Indexation", AllowIndexation);
        DepreciationBook.Modify(true);
    end;

    local procedure AttachDimensionInJournalLine(var GenJournalLine: Record "Gen. Journal Line")
    var
        DimensionValue: Record "Dimension Value";
    begin
        FindNonGlobalDimValue(DimensionValue);
        GenJournalLine.Validate(
          "Dimension Set ID",
          LibraryDimension.CreateDimSet(GenJournalLine."Dimension Set ID", DimensionValue."Dimension Code", DimensionValue.Code));
        GenJournalLine.Modify(true);
    end;

    local procedure AttachDimensionInFAJournalLine(var FAJournalLine: Record "FA Journal Line")
    var
        DimensionValue: Record "Dimension Value";
    begin
        FindNonGlobalDimValue(DimensionValue);
        FAJournalLine.Validate(
          "Dimension Set ID",
          LibraryDimension.CreateDimSet(FAJournalLine."Dimension Set ID", DimensionValue."Dimension Code", DimensionValue.Code));
        FAJournalLine.Modify(true);
    end;

    local procedure AttachDimensionOnFAAllocation(var FAAllocation: Record "FA Allocation")
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
    begin
        LibraryDimension.FindDimension(Dimension);

        FAAllocation.SetRange(Code, FAAllocation.Code);
        FAAllocation.FindSet();
        repeat
            LibraryDimension.FindDimensionValue(DimensionValue, Dimension.Code);
            FAAllocation.Validate(
              "Dimension Set ID", LibraryDimension.CreateDimSet(FAAllocation."Dimension Set ID", Dimension.Code, DimensionValue.Code));
            Dimension.Next();
            FAAllocation.Modify(true);
        until FAAllocation.Next() = 0;
    end;

    local procedure AttachDimensionOnFixedAsset(var DimensionValue: Record "Dimension Value"; FixedAssetNo: Code[20])
    var
        DefaultDimension: Record "Default Dimension";
    begin
        FindNonGlobalDimValue(DimensionValue);
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, DATABASE::"Fixed Asset", FixedAssetNo, DimensionValue."Dimension Code", DimensionValue.Code);
    end;

    local procedure CreateAndAttachDimensionOnFAAllocation(var FAAllocation: Record "FA Allocation"; FAPostingGroup: Code[20]; AllocationType: Enum "FA Allocation Type")
    begin
        CreateFAAllocation(FAAllocation, FAPostingGroup, AllocationType);
        AttachDimensionOnFAAllocation(FAAllocation);
    end;

    local procedure CreateInitialSetupAndPostFAJournalLines(var DepreciationBook: Record "Depreciation Book"): Code[20]
    var
        FAJournalBatch: Record "FA Journal Batch";
        FAJournalLine: Record "FA Journal Line";
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        CreateFixedAssetDepreciation(FADepreciationBook);
        DepreciationBook.Get(FADepreciationBook."Depreciation Book Code");
        UpdateGLIntegration(DepreciationBook.Code, false, false);
        CreateFAJournalBatch(FAJournalBatch);
        CreateFAJournalLine(
          FAJournalLine, FAJournalBatch, FADepreciationBook, FAJournalLine."FA Posting Type"::"Acquisition Cost",
          LibraryRandom.RandDec(1000, 2) * 100);  // Take Random Value.
        CreateFAJournalLine(
          FAJournalLine, FAJournalBatch, FADepreciationBook, FAJournalLine."FA Posting Type"::Depreciation, -FAJournalLine.Amount / 2);
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);
        exit(FADepreciationBook."FA No.");
    end;

    local procedure CreateDefaultDimensionPriorityWithPriorityValue(DefaultDimensionPriority: Record "Default Dimension Priority"; SourceCode: Code[10]; TableID: Integer; PriorityValue: Integer)
    begin
        LibraryDimension.CreateDefaultDimensionPriority(DefaultDimensionPriority, SourceCode, TableID);
        DefaultDimensionPriority.Validate(Priority, PriorityValue);
        DefaultDimensionPriority.Modify(true);
    end;

    local procedure CreateDepreciationBookAndSetup(): Code[10]
    var
        DepreciationBook: Record "Depreciation Book";
    begin
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        CreateFAJournalSetup(DepreciationBook.Code);
        exit(DepreciationBook.Code);
    end;

    local procedure CreateFAAllocation(var FAAllocation: Record "FA Allocation"; FAPostingGroup: Code[20]; AllocationType: Enum "FA Allocation Type")
    var
        Counter: Integer;
    begin
        // Using Random Number Generator for creating the lines between 1 to 4.
        for Counter := 1 to 1 + LibraryRandom.RandInt(3) do begin
            Clear(FAAllocation);
            LibraryFixedAsset.CreateFAAllocation(FAAllocation, FAPostingGroup, AllocationType);
            UpdateAllocationPercent(FAAllocation);
        end;
    end;

    local procedure CreateFADepreciationBook(var FADepreciationBook: Record "FA Depreciation Book"; No: Code[20]; DepreciationBookCode: Code[10]; FAPostingGroup: Code[20])
    begin
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, No, DepreciationBookCode);
        UpdateDateFADepreciationBook(FADepreciationBook, DepreciationBookCode);
        FADepreciationBook.Validate("FA Posting Group", FAPostingGroup);
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

    local procedure CreateFAJournalBatchWithNoSeries(var FAJournalBatch: Record "FA Journal Batch"; DepreciationBookCode: Code[10]; PostingDate: Date; SeriesLineCount: Integer)
    begin
        // Create a few series lines with Starting Date starts from first day of month. Period is 1 month.

        CreateFAJournalBatch(FAJournalBatch);
        FAJournalBatch.Validate("No. Series", CreateNoSeriesCode(SeriesLineCount, CalcDate('<-CM>', PostingDate)));
        FAJournalBatch.Modify(true);
        CreateFAJnlSetupWithTemplateBatch(DepreciationBookCode, FAJournalBatch."Journal Template Name", FAJournalBatch.Name, true);
    end;

    local procedure CreateNoSeriesCode(NoOfPeriods: Integer; StartingDate: Date): Code[20]
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        i: Integer;
    begin
        LibraryUtility.CreateNoSeries(NoSeries, true, true, false);
        for i := 1 to NoOfPeriods do begin
            LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, Format(i) + '00000000', Format(i) + '99999999');
            NoSeriesLine.Validate("Starting Date", StartingDate);
            NoSeriesLine.Modify(true);
            StartingDate := CalcDate('<1M>', StartingDate);
        end;
        exit(NoSeries.Code);
    end;

    local procedure CreateFAJournalLine(var FAJournalLine: Record "FA Journal Line"; FAJournalBatch: Record "FA Journal Batch"; FADepreciationBook: Record "FA Depreciation Book"; FAPostingType: Enum "FA Journal Line FA Posting Type"; Amount: Decimal)
    begin
        LibraryFixedAsset.CreateFAJournalLine(FAJournalLine, FAJournalBatch."Journal Template Name", FAJournalBatch.Name);
        FAJournalLine.Validate("Document Type", FAJournalLine."Document Type"::" ");
        FAJournalLine.Validate("Document No.", FADepreciationBook."FA No.");
        FAJournalLine.Validate("Posting Date", WorkDate());
        FAJournalLine.Validate("FA Posting Date", WorkDate());
        FAJournalLine.Validate("FA Posting Type", FAPostingType);
        FAJournalLine.Validate("FA No.", FADepreciationBook."FA No.");
        FAJournalLine.Validate(Amount, Amount);
        FAJournalLine.Validate("Depreciation Book Code", FADepreciationBook."Depreciation Book Code");
        FAJournalLine.Modify(true);
    end;

    local procedure CreateFAJournalSetup(DepreciationBook: Code[10])
    var
        FAJournalSetup: Record "FA Journal Setup";
    begin
        LibraryFixedAsset.CreateFAJournalSetup(FAJournalSetup, DepreciationBook, '');
        UpdateFAJournalSetup(FAJournalSetup);
    end;

    local procedure CreateFAJnlSetupWithTemplateBatch(DepreciationBook: Code[10]; JournalTemplateName: Code[10]; JournalBatchName: Code[10]; UpdateFASetup: Boolean)
    var
        FAJournalSetup: Record "FA Journal Setup";
    begin
        if not FAJournalSetup.Get(DepreciationBook, '') then
            LibraryFixedAsset.CreateFAJournalSetup(FAJournalSetup, DepreciationBook, '');
        if UpdateFASetup then begin
            FAJournalSetup.Validate("FA Jnl. Template Name", JournalTemplateName);
            FAJournalSetup.Validate("FA Jnl. Batch Name", JournalBatchName);
        end else begin
            FAJournalSetup.Validate("Gen. Jnl. Template Name", JournalTemplateName);
            FAJournalSetup.Validate("Gen. Jnl. Batch Name", JournalBatchName);
        end;
        FAJournalSetup.Modify(true);
    end;

    local procedure CreateFAGLJournalLine(var GenJournalLine: Record "Gen. Journal Line")
    var
        FADepreciationBook: Record "FA Depreciation Book";
        GenJournalBatch: Record "Gen. Journal Batch";
        GLAccount: Record "G/L Account";
    begin
        CreateFixedAssetDepreciation(FADepreciationBook);
        LibraryERM.CreateGLAccount(GLAccount);

        // Using Random Number Generator for Amount.
        CreateGenJournalBatch(GenJournalBatch);
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, FADepreciationBook."FA No.", GenJournalLine."FA Posting Type"::"Acquisition Cost",
          GLAccount."No.", LibraryRandom.RandDec(1000, 2));
    end;

    local procedure CreateFAGLJournalLines(var GenJournalLine: Record "Gen. Journal Line"; FADepreciationBook: Record "FA Depreciation Book")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GLAccount: Record "G/L Account";
    begin
        // Using Random Number Generator for Amount.
        LibraryERM.CreateGLAccount(GLAccount);
        CreateGenJournalBatch(GenJournalBatch);
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, FADepreciationBook."FA No.", GenJournalLine."FA Posting Type"::"Acquisition Cost",
          GLAccount."No.", LibraryRandom.RandDec(1000, 2));
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, FADepreciationBook."FA No.", GenJournalLine."FA Posting Type"::Depreciation, GLAccount."No.",
          -GenJournalLine.Amount / 2);
    end;

    local procedure CreateFAReclassJournalBatch(var FAReclassJournalBatch: Record "FA Reclass. Journal Batch")
    var
        FAReclassJournalTemplate: Record "FA Reclass. Journal Template";
    begin
        FAReclassJournalTemplate.FindFirst();
        LibraryFixedAsset.CreateFAReclassJournalBatch(FAReclassJournalBatch, FAReclassJournalTemplate.Name);
    end;

    local procedure CreateFAReclassJournalLine(var FAReclassJournalLine: Record "FA Reclass. Journal Line")
    var
        FAReclassJournalBatch: Record "FA Reclass. Journal Batch";
    begin
        CreateFAReclassJournalBatch(FAReclassJournalBatch);
        LibraryFixedAsset.CreateFAReclassJournal(
          FAReclassJournalLine, FAReclassJournalBatch."Journal Template Name", FAReclassJournalBatch.Name);
    end;

    local procedure CreateFixedAssetDepreciationWithSetup(var FADepreciationBook: Record "FA Depreciation Book"; var GLIntegrationAcqCostOld: Boolean; GLAccNo: Code[20])
    begin
        CreateFixedAssetDepreciation(FADepreciationBook);
        UpdateDeprExpenseAccInFAPostingGroup(FADepreciationBook."FA Posting Group", GLAccNo);
        GLIntegrationAcqCostOld := ModifyAcquisitionIntegration(FADepreciationBook."Depreciation Book Code", false);
    end;

    local procedure CreateFixedAssetDepreciation(var FADepreciationBook: Record "FA Depreciation Book")
    var
        FixedAsset: Record "Fixed Asset";
        DepreciationBook: Record "Depreciation Book";
    begin
        DepreciationBook.Get(LibraryFixedAsset.GetDefaultDeprBook());
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", DepreciationBook.Code, FixedAsset."FA Posting Group");
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; AccountNo: Code[20]; FAPostingType: Enum "Gen. Journal Line FA Posting Type"; BalAccountNo: Code[20]; Amount: Decimal)
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"Fixed Asset", AccountNo, Amount);
        GenJournalLine.Validate("FA Posting Type", FAPostingType);
        GenJournalLine.Validate("Bal. Account No.", BalAccountNo);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateGenJournalNoBalAccount(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; AccountNo: Code[20])
    begin
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, AccountNo, GenJournalLine."FA Posting Type"::Depreciation, '',
          -LibraryRandom.RandDec(1000, 2));  // Take Random Amount, using Blank for Balance Account No.
        GenJournalLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
    end;

    local procedure CreateAndPostGenJournalLines(var GenJournalLine: Record "Gen. Journal Line"; FANo: Code[20])
    var
        GLAccount: Record "G/L Account";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGLAccount(GLAccount);
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, FANo, GenJournalLine."FA Posting Type"::"Acquisition Cost", GLAccount."No.",
          LibraryRandom.RandDec(1000, 2));
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, FANo, GenJournalLine."FA Posting Type"::Depreciation, GLAccount."No.", -GenJournalLine.Amount / 2);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure DeleteGeneralJournalLine(JournalTemplateName: Code[20]; JournalBatchName: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetRange("Journal Template Name", JournalTemplateName);
        if JournalBatchName <> '' then
            GenJournalLine.SetRange("Journal Batch Name", JournalBatchName);
        GenJournalLine.DeleteAll(true);
    end;

    local procedure CreateAndPostFAJournalLines(var FAJournalLine: Record "FA Journal Line"; FADepreciationBook: Record "FA Depreciation Book") PostingDate: Date
    var
        FAJournalBatch: Record "FA Journal Batch";
    begin
        CreateFAJournalBatch(FAJournalBatch);
        CreateFAJournalLine(
          FAJournalLine, FAJournalBatch, FADepreciationBook, FAJournalLine."FA Posting Type"::"Acquisition Cost",
          LibraryRandom.RandDec(1000, 2) * 100);
        CreateFAJournalLine(
          FAJournalLine, FAJournalBatch, FADepreciationBook, FAJournalLine."FA Posting Type"::Depreciation, -FAJournalLine.Amount / 2);
        PostingDate := FAJournalLine."Posting Date";
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);
    end;

    local procedure DeleteFAJournalLine(JournalTemplateName: Code[20]; JournalBatchName: Code[20])
    var
        FAJournalLine: Record "FA Journal Line";
    begin
        FAJournalLine.SetRange("Journal Template Name", JournalTemplateName);
        if JournalBatchName <> '' then
            FAJournalLine.SetRange("Journal Batch Name", JournalBatchName);
        FAJournalLine.DeleteAll(true);
    end;

    local procedure CreateGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.Init();
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Assets);
        GenJournalTemplate.SetRange(Recurring, false);

        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure CreateGenJournalBatchWithNoSeries(var GenJournalBatch: Record "Gen. Journal Batch"; DepreciationBookCode: Code[10]; PostingDate: Date; SeriesLineCount: Integer)
    begin
        // Create a few series lines with Starting Date starts from first day of month. Period is 1 month.

        CreateGenJournalBatch(GenJournalBatch);
        GenJournalBatch.Validate("No. Series", CreateNoSeriesCode(SeriesLineCount, CalcDate('<-CM>', PostingDate)));
        GenJournalBatch.Modify(true);
        CreateFAJnlSetupWithTemplateBatch(DepreciationBookCode, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, false);
    end;

    local procedure CreateGLAccountWithDimension(var DefaultDimension: Record "Default Dimension"): Code[20]
    var
        GLAccount: Record "G/L Account";
        Dimension: Record Dimension;
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryDimension.FindDimension(Dimension);
        LibraryDimension.CreateDefaultDimension(DefaultDimension, DATABASE::"G/L Account", GLAccount."No.", Dimension.Code, '');  // Passing Blank for Dimension Value Code.
        DefaultDimension.Validate("Value Posting", DefaultDimension."Value Posting"::"Code Mandatory");
        DefaultDimension.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateGLAccountWithDefaultDimension() GLAccountNo: Code[20]
    begin
        GLAccountNo := LibraryERM.CreateGLAccountNo();
        CreateDefaultDim(DATABASE::"G/L Account", GLAccountNo);
    end;

    local procedure CreateDefaultDim(TableID: Integer; No: Code[20])
    var
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
    begin
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, TableID, No,
          DimensionValue."Dimension Code", DimensionValue.Code);
    end;

    local procedure CreateInsuranceJournalBatch(var InsuranceJournalBatch: Record "Insurance Journal Batch")
    var
        InsuranceJournalTemplate: Record "Insurance Journal Template";
    begin
        InsuranceJournalTemplate.FindFirst();
        LibraryFixedAsset.CreateInsuranceJournalBatch(InsuranceJournalBatch, InsuranceJournalTemplate.Name);
    end;

    local procedure CreateInsuranceJournalLine(var InsuranceJournalLine: Record "Insurance Journal Line"; InsuranceNo: Code[20])
    var
        InsuranceJournalBatch: Record "Insurance Journal Batch";
    begin
        CreateInsuranceJournalBatch(InsuranceJournalBatch);
        LibraryFixedAsset.CreateInsuranceJournalLine(
          InsuranceJournalLine, InsuranceJournalBatch."Journal Template Name", InsuranceJournalBatch.Name);
        UpdateInsuranceJournalLine(InsuranceJournalLine, InsuranceNo);
    end;

    local procedure CreateInsuranceWithDimension(): Code[20]
    var
        DefaultDimension: Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
        Insurance: Record Insurance;
    begin
        LibraryFixedAsset.CreateInsurance(Insurance);
        FindNonGlobalDimValue(DimensionValue);
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, DATABASE::Insurance, Insurance."No.", DimensionValue."Dimension Code", DimensionValue.Code);
        exit(Insurance."No.");
    end;

    local procedure CalculateDepreciationDateAfterOneYear(): Date
    begin
        exit(CalcDate('<1Y>', WorkDate()));
    end;

    local procedure DeleteDefaultDimensionPriorities(SourceCode: Code[10])
    var
        DefaultDimensionPriority: Record "Default Dimension Priority";
    begin
        DefaultDimensionPriority.SetRange("Source Code", SourceCode);
        DefaultDimensionPriority.DeleteAll(true);
    end;

    local procedure DepreciationWithFixedAsset(var FAAllocation: Record "FA Allocation"; BalAccount: Boolean) FANo: Code[20]
    var
        FADepreciationBook: Record "FA Depreciation Book";
        FAJournalBatch: Record "FA Journal Batch";
        FAJournalLine: Record "FA Journal Line";
        GLIntegrationAcqCostOld: Boolean;
    begin
        // 1.Setup: Create Fixed Asset, Depreciation Book, FA Depreciation Book, modify Depreciation Book, create FA Journal Line, Post the
        // FA Journal Line, create FA Allocation with Dimension.
        CreateFixedAssetDepreciation(FADepreciationBook);
        GLIntegrationAcqCostOld := ModifyAcquisitionIntegration(FADepreciationBook."Depreciation Book Code", false);
        CreateFAJournalBatch(FAJournalBatch);
        CreateFAJournalLine(
          FAJournalLine, FAJournalBatch, FADepreciationBook, FAJournalLine."FA Posting Type"::"Acquisition Cost",
          LibraryRandom.RandDec(1000, 2));  // Take Random Amount.
        AttachDimensionInFAJournalLine(FAJournalLine);
        FANo := FADepreciationBook."FA No.";
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);
        CreateAndAttachDimensionOnFAAllocation(
          FAAllocation, FADepreciationBook."FA Posting Group", FAAllocation."Allocation Type"::Depreciation);

        // 2.Exercise: Run the Calculate Depreciation.
        RunCalculateDepreciation(FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code", BalAccount);
        ModifyAcquisitionIntegration(FADepreciationBook."Depreciation Book Code", GLIntegrationAcqCostOld);
    end;

    local procedure DimensionOnInsuranceJournal(var InsuranceJournalLine: Record "Insurance Journal Line")
    var
        DimensionValue: Record "Dimension Value";
    begin
        FindNonGlobalDimValue(DimensionValue);
        InsuranceJournalLine.Validate(
          "Dimension Set ID",
          LibraryDimension.CreateDimSet(InsuranceJournalLine."Dimension Set ID", DimensionValue."Dimension Code", DimensionValue.Code));
        InsuranceJournalLine.Modify(true);
    end;

    local procedure FindNonGlobalDimValue(var DimensionValue: Record "Dimension Value")
    var
        Dimension: Record Dimension;
    begin
        Dimension.SetRange(Blocked, false);
        Dimension.SetFilter(Code, '<>%1&<>%2', LibraryERM.GetGlobalDimensionCode(1), LibraryERM.GetGlobalDimensionCode(2));
        LibraryDimension.FindDimension(Dimension);
        LibraryDimension.FindDimensionValue(DimensionValue, Dimension.Code);
    end;

    local procedure FindFAJournalLine(FANo: Code[20]): Boolean
    var
        FAJournalLine: Record "FA Journal Line";
    begin
        FAJournalLine.SetRange("FA No.", FANo);
        exit(FAJournalLine.FindFirst())
    end;

    local procedure FindGeneralJournalLine(AccountNo: Code[20]): Boolean
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetRange("Account No.", AccountNo);
        exit(GenJournalLine.FindFirst())
    end;

    local procedure FindFALedgerEntry(var FALedgerEntry: Record "FA Ledger Entry"; FANo: Code[20])
    begin
        FALedgerEntry.SetRange("FA No.", FANo);
        FALedgerEntry.FindFirst();
    end;

    local procedure FindInsurance(): Code[20]
    var
        Insurance: Record Insurance;
    begin
        Insurance.FindFirst();
        exit(Insurance."No.");
    end;

    local procedure FindGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; DocumentNo: Code[20]; AccountNo: Code[20])
    begin
        GenJnlLine.SetRange("Document No.", DocumentNo);
        GenJnlLine.SetRange("Account No.", AccountNo);
        GenJnlLine.FindFirst();
    end;

    local procedure GetFAGLJournalSourceCode(): Code[10]
    var
        SourceCodeSetup: Record "Source Code Setup";
    begin
        SourceCodeSetup.Get();
        exit(SourceCodeSetup."Fixed Asset G/L Journal");
    end;

    local procedure IndexFixedAsset(var DimensionValue: Record "Dimension Value"; var FAAllocationCode: Code[20]; BalAccount: Boolean): Code[20]
    var
        FAAllocation: Record "FA Allocation";
        FixedAsset: Record "Fixed Asset";
        GenJournalLine: Record "Gen. Journal Line";
        AllowIndexationOld: Boolean;
    begin
        // Create and post FA General Journal for Posting Type Acquisition Cost, modify the Allow Indexation in Depreciation Book,
        // create FA Allocation with dimension.
        CreateFAGLJournalLine(GenJournalLine);
        FixedAsset.Get(GenJournalLine."Account No.");
        AttachDimensionOnFixedAsset(DimensionValue, FixedAsset."No.");
        AllowIndexationOld := AllowIndexationInDepreciation(GenJournalLine."Depreciation Book Code", true);
        ModifyAccountInFAPostingGroup(FixedAsset."FA Posting Group");
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        CreateAndAttachDimensionOnFAAllocation(FAAllocation, FixedAsset."FA Posting Group", FAAllocation."Allocation Type"::Acquisition);
        FAAllocationCode := FAAllocation.Code;

        UpdateInsuranceJournalBatchPostingNoSeries(GenJournalLine."Depreciation Book Code");

        // 2.Exercise: Run the Index Fixed Assets.
        RunIndexFixedAssets(FixedAsset."No.", GenJournalLine."Depreciation Book Code", BalAccount);

        // 3.Tear Down: Change back into the Depreciation Book.
        AllowIndexationInDepreciation(GenJournalLine."Depreciation Book Code", AllowIndexationOld);
        exit(FixedAsset."No.");
    end;

    local procedure InsuranceDeprBookInFASetup(InsuranceDeprBook: Code[10]) OldInsuranceDeprBook: Code[10]
    var
        FASetup: Record "FA Setup";
    begin
        FASetup.Get();
        OldInsuranceDeprBook := FASetup."Insurance Depr. Book";
        FASetup.Validate("Insurance Depr. Book", InsuranceDeprBook);
        FASetup.Modify(true)
    end;

    local procedure InsuranceInGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; InsuranceNo: Code[20])
    begin
        GenJournalLine.Validate("Insurance No.", InsuranceNo);
        GenJournalLine.Modify(true);
    end;

    local procedure GetDefaultDimID(GLAccountNo: Code[20]; FANo: Code[20]): Integer
    var
        DimMgt: Codeunit DimensionManagement;
        GlobalDim1Code: Code[20];
        GlobalDim2Code: Code[20];
        DefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
    begin
        if FANo <> '' then
            DimMgt.AddDimSource(DefaultDimSource, Database::"Fixed Asset", FANo);
        if GLAccountNo <> '' then
            DimMgt.AddDimSource(DefaultDimSource, Database::"G/L Account", GLAccountNo);
        exit(DimMgt.GetDefaultDimID(DefaultDimSource, '', GlobalDim1Code, GlobalDim2Code, 0, 0));
    end;

    local procedure ModifyAcquisitionIntegration(DepreciationBookCode: Code[10]; GLIntegrationAcqCost: Boolean) GLIntegrationAcqCostOld: Boolean
    var
        DepreciationBook: Record "Depreciation Book";
    begin
        DepreciationBook.Get(DepreciationBookCode);
        GLIntegrationAcqCostOld := DepreciationBook."G/L Integration - Acq. Cost";
        DepreciationBook.Validate("G/L Integration - Acq. Cost", GLIntegrationAcqCost);
        DepreciationBook.Modify(true);
    end;

    local procedure ModifyAccountInFAPostingGroup("Code": Code[20])
    var
        FAPostingGroup: Record "FA Posting Group";
    begin
        FAPostingGroup.Get(Code);
        FAPostingGroup.Validate("Acquisition Cost Bal. Acc.", LibraryERM.CreateGLAccountNo());
        FAPostingGroup.Validate("Appreciation Bal. Account", LibraryERM.CreateGLAccountNo());
        FAPostingGroup.Modify(true);
    end;

    local procedure ModifyFAPostingType(var GenJournalLine: Record "Gen. Journal Line"; FAPostingType: Enum "Gen. Journal Line FA Posting Type")
    begin
        GenJournalLine.Validate("FA Posting Type", FAPostingType);
        GenJournalLine.Modify(true);
    end;

    local procedure ModifyInsurancePosting(AutomaticInsurancePosting: Boolean) AutomaticInsurancePostingOld: Boolean
    var
        FASetup: Record "FA Setup";
    begin
        FASetup.Get();
        AutomaticInsurancePostingOld := FASetup."Automatic Insurance Posting";
        FASetup.Validate("Automatic Insurance Posting", AutomaticInsurancePosting);
        FASetup.Modify(true);
    end;

    local procedure RunCalculateDepreciation(No: Code[20]; DepreciationBookCode: Code[10]; BalAccount: Boolean)
    var
        FixedAsset: Record "Fixed Asset";
        CalculateDepreciation: Report "Calculate Depreciation";
    begin
        Clear(CalculateDepreciation);
        FixedAsset.SetRange("No.", No);
        CalculateDepreciation.SetTableView(FixedAsset);

        CalculateDepreciation.InitializeRequest(
          DepreciationBookCode, CalculateDepreciationDateAfterOneYear(), false, 0, 0D, No, FixedAsset.Description, BalAccount);
        CalculateDepreciation.UseRequestPage(false);
        CalculateDepreciation.Run();
    end;

    local procedure RunCancelFALedgerEntry(No: Code[20]; DepreciationBookCode: Code[10]; BalAccount: Boolean)
    var
        FixedAsset: Record "Fixed Asset";
        CancelFALedgerEntries: Report "Cancel FA Ledger Entries";
    begin
        Clear(CancelFALedgerEntries);
        FixedAsset.SetRange("No.", No);
        CancelFALedgerEntries.SetTableView(FixedAsset);
        CancelFALedgerEntries.InitializeRequest(DepreciationBookCode, WorkDate(), WorkDate(), false, 0D, No, FixedAsset.Description, BalAccount);
        CancelFALedgerEntries.SetCancelAcquisitionCost(true);
        CancelFALedgerEntries.SetCancelDepreciation(true);
        CancelFALedgerEntries.UseRequestPage(false);
        CancelFALedgerEntries.Run();
    end;

    local procedure RunCancelFALedgerEntryWithtParams(No: Code[20]; DepreciationBookCode: Code[10]; StartingDateFrom: Date; EndingDateFrom: Date; UseNewPostingDate: Boolean; NewPostingDate: Date; BalAccount: Boolean)
    var
        FixedAsset: Record "Fixed Asset";
        CancelFALedgerEntries: Report "Cancel FA Ledger Entries";
    begin
        Clear(CancelFALedgerEntries);
        FixedAsset.SetRange("No.", No);
        CancelFALedgerEntries.SetTableView(FixedAsset);
        CancelFALedgerEntries.InitializeRequest(
          DepreciationBookCode, StartingDateFrom, EndingDateFrom, UseNewPostingDate, NewPostingDate, '', '', BalAccount);
        CancelFALedgerEntries.SetCancelDepreciation(true);
        CancelFALedgerEntries.UseRequestPage(false);
        CancelFALedgerEntries.Run();
    end;

    local procedure RunCancelFAEntries(var FALedgerEntry: Record "FA Ledger Entry")
    var
        CancelFAEntries: Report "Cancel FA Entries";
    begin
        Clear(CancelFAEntries);
        CancelFAEntries.GetFALedgEntry(FALedgerEntry);
        CancelFAEntries.UseRequestPage(false);
        CancelFAEntries.Run();
    end;

    local procedure RunCopyDepreciationBook(No: Code[20]; DepreciationBookCode: Code[10]; DepreciationBookCode2: Code[10])
    var
        FixedAsset: Record "Fixed Asset";
        CopyDepreciationBook: Report "Copy Depreciation Book";
    begin
        Clear(CopyDepreciationBook);
        FixedAsset.SetRange("No.", No);
        CopyDepreciationBook.SetTableView(FixedAsset);
        CopyDepreciationBook.InitializeRequest(
          DepreciationBookCode, DepreciationBookCode2, WorkDate(), CalculateDepreciationDateAfterOneYear(), No, FixedAsset.Description, false);
        CopyDepreciationBook.SetCopyAcquisitionCost(true);
        CopyDepreciationBook.UseRequestPage(false);
        CopyDepreciationBook.Run();
    end;

    local procedure RunIndexFixedAssets(No: Code[20]; DepreciationBookCode: Code[10]; BalAccount: Boolean)
    var
        FixedAsset: Record "Fixed Asset";
        IndexFixedAssets: Report "Index Fixed Assets";
    begin
        Clear(IndexFixedAssets);
        FixedAsset.SetRange("No.", No);
        IndexFixedAssets.SetTableView(FixedAsset);
        IndexFixedAssets.InitializeRequest(DepreciationBookCode, LibraryRandom.RandInt(100), WorkDate(), 0D, No, No, BalAccount);  // Using Random Value for Index.
        IndexFixedAssets.SetIndexAcquisitionCost(true);
        IndexFixedAssets.SetIndexDepreciation(true);
        IndexFixedAssets.UseRequestPage(false);
        IndexFixedAssets.Run();
    end;

    local procedure RunIndexInsurance(No: Code[20])
    var
        FixedAsset: Record "Fixed Asset";
        IndexInsurance: Report "Index Insurance";
    begin
        Clear(IndexInsurance);
        FixedAsset.SetRange("No.", No);
        IndexInsurance.SetTableView(FixedAsset);
        IndexInsurance.InitializeRequest(No, No, WorkDate(), LibraryRandom.RandInt(100));  // Using Random Value for Index Figure.
        IndexInsurance.UseRequestPage(false);
        IndexInsurance.Run();
    end;

    local procedure UpdateAccountNoInFAAllocation(FAAllocation: Record "FA Allocation"; AccountNo: Code[20])
    begin
        FAAllocation.Validate("Account No.", AccountNo);
        FAAllocation.Modify(true);
    end;

    local procedure UpdateAccountNoInJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AccountNo: Code[20])
    begin
        GenJournalLine.Validate("Account No.", AccountNo);
        GenJournalLine.Modify(true);
    end;

    local procedure UpdateAllocationPercent(var FAAllocation: Record "FA Allocation")
    var
        GLAccount: Record "G/L Account";
    begin
        FAAllocation.SetRange(Code, FAAllocation.Code);
        FAAllocation.SetRange("Allocation Type", FAAllocation."Allocation Type");
        FAAllocation.FindSet();

        // Using Random Number Generator for Allocation Percent.
        repeat
            LibraryERM.CreateGLAccount(GLAccount);
            FAAllocation.Validate("Account No.", GLAccount."No.");
            FAAllocation.Validate("Allocation %", LibraryRandom.RandInt(20));
            FAAllocation.Modify(true);
            GLAccount.Next();
        until FAAllocation.Next() = 0;
    end;

    local procedure UpdateDateFADepreciationBook(var FADepreciationBook: Record "FA Depreciation Book"; DepreciationBookCode: Code[10])
    begin
        FADepreciationBook.Validate("Depreciation Book Code", DepreciationBookCode);
        FADepreciationBook.Validate("Depreciation Starting Date", WorkDate());

        FADepreciationBook.Validate("Depreciation Ending Date", CalculateDepreciationDateAfterOneYear());
        FADepreciationBook.Modify(true);
    end;

    local procedure UpdateFAJournalSetup(var FAJournalSetup: Record "FA Journal Setup")
    var
        FAJournalSetup2: Record "FA Journal Setup";
        FASetup: Record "FA Setup";
    begin
        FASetup.Get();
        FAJournalSetup2.SetRange("Depreciation Book Code", FASetup."Default Depr. Book");
        FAJournalSetup2.FindFirst();
        FAJournalSetup.TransferFields(FAJournalSetup2, false);
        FAJournalSetup.Modify(true);
    end;

    local procedure UpdateFAReclassJournal(var FAReclassJournalLine: Record "FA Reclass. Journal Line"; FANo: Code[20]; NewFANo: Code[20])
    begin
        FAReclassJournalLine.Validate("FA Posting Date", WorkDate());
        FAReclassJournalLine.Validate("Document No.", FANo);
        FAReclassJournalLine.Validate("FA No.", FANo);
        FAReclassJournalLine.Validate("New FA No.", NewFANo);
        FAReclassJournalLine.Validate("Reclassify Acq. Cost %", LibraryRandom.RandInt(100));  // Using Ranodm Reclassify Acq. Cost.
        FAReclassJournalLine.Validate("Reclassify Acquisition Cost", true);
        FAReclassJournalLine.Validate("Reclassify Depreciation", true);
        FAReclassJournalLine.Validate("Insert Bal. Account", true);
        FAReclassJournalLine.Modify(true);
    end;

    local procedure UpdateUseSameDates("Code": Code[10]; UseSameFAGLDates: Boolean)
    var
        DepreciationBook: Record "Depreciation Book";
    begin
        DepreciationBook.Get(Code);
        DepreciationBook.Validate("Use Same FA+G/L Posting Dates", UseSameFAGLDates);
        DepreciationBook.Modify(true);
    end;

    local procedure UpdateGLIntegration("Code": Code[10]; GLIntegrationAcqCost: Boolean; GLIntegrationDepreciation: Boolean)
    var
        DepreciationBook: Record "Depreciation Book";
    begin
        DepreciationBook.Get(Code);
        DepreciationBook.Validate("G/L Integration - Acq. Cost", GLIntegrationAcqCost);
        DepreciationBook.Validate("G/L Integration - Depreciation", GLIntegrationDepreciation);
        DepreciationBook.Modify(true);
    end;

    local procedure UpdateInactiveOnFixedAsset(No: Code[20])
    var
        FixedAsset: Record "Fixed Asset";
    begin
        FixedAsset.Get(No);
        FixedAsset.Validate(Inactive, true);
        FixedAsset.Modify(true);
    end;

    local procedure UpdateInsuranceJournalLine(var InsuranceJournalLine: Record "Insurance Journal Line"; InsuranceNo: Code[20])
    var
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        CreateFixedAssetDepreciation(FADepreciationBook);

        InsuranceJournalLine.Validate("Posting Date", WorkDate());
        InsuranceJournalLine.Validate("Document No.", FADepreciationBook."FA No.");
        InsuranceJournalLine.Validate("FA No.", FADepreciationBook."FA No.");
        InsuranceJournalLine.Validate("Insurance No.", InsuranceNo);
        InsuranceJournalLine.Validate(Amount, LibraryRandom.RandDec(1000, 2));  // Using Random Number Generator for Amount.
        InsuranceJournalLine.Modify(true);
    end;

    local procedure UpdateDeprExpenseAccInFAPostingGroup(FAPostingGroupCode: Code[20]; GLAccountNo: Code[20])
    var
        FAPostingGroup: Record "FA Posting Group";
    begin
        FAPostingGroup.Get(FAPostingGroupCode);
        FAPostingGroup.Validate("Depreciation Expense Acc.", GLAccountNo);
        FAPostingGroup.Modify(true);
    end;

    local procedure UseDefaultDimDepreciationBook("Code": Code[10]; UseDefaultDimension: Boolean) OldUseDefaultDimension: Boolean
    var
        DepreciationBook: Record "Depreciation Book";
    begin
        DepreciationBook.Get(Code);
        OldUseDefaultDimension := DepreciationBook."Use Default Dimension";
        DepreciationBook.Validate("Use Default Dimension", UseDefaultDimension);
        DepreciationBook.Modify(true);
    end;

    local procedure UpdateGenJournalBatchPostingNoSeries(DepreciationBookCode: Code[10])
    var
        FAJournalSetup: Record "FA Journal Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        FAJournalSetup.Get(DepreciationBookCode, '');
        GenJournalBatch.Get(FAJournalSetup."Gen. Jnl. Template Name", FAJournalSetup."Gen. Jnl. Batch Name");
        GenJournalBatch."Posting No. Series" :=
          LibraryUtility.GenerateRandomCode20(GenJournalBatch.FieldNo("Posting No. Series"), DATABASE::"Gen. Journal Batch");
        GenJournalBatch.Modify();
    end;

    local procedure UpdateInsuranceJournalBatchPostingNoSeries(DepreciationBookCode: Code[10])
    var
        FAJournalSetup: Record "FA Journal Setup";
        InsuranceJournalBatch: Record "Insurance Journal Batch";
    begin
        FAJournalSetup.Get(DepreciationBookCode, '');
        InsuranceJournalBatch.Get(FAJournalSetup."Insurance Jnl. Template Name", FAJournalSetup."Insurance Jnl. Batch Name");
        InsuranceJournalBatch."Posting No. Series" :=
          LibraryUtility.GenerateRandomCode20(InsuranceJournalBatch.FieldNo("Posting No. Series"), DATABASE::"Insurance Journal Batch");
        InsuranceJournalBatch.Modify();
    end;

    local procedure PostAcquisitionCost(var FADepreciationBook: Record "FA Depreciation Book")
    var
        FAJournalBatch: Record "FA Journal Batch";
        FAJournalLine: Record "FA Journal Line";
    begin
        CreateFAJournalBatch(FAJournalBatch);
        CreateFAJournalLine(
          FAJournalLine, FAJournalBatch, FADepreciationBook, FAJournalLine."FA Posting Type"::"Acquisition Cost",
          LibraryRandom.RandDec(10000, 2));
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);
    end;

    local procedure VerifyCancelFAJournalLines(FANo: Code[20])
    var
        FALedgerEntry: Record "FA Ledger Entry";
        FAJournalLine: Record "FA Journal Line";
    begin
        FALedgerEntry.SetRange("FA No.", FANo);
        FALedgerEntry.FindSet();
        repeat
            FAJournalLine.SetRange("FA Error Entry No.", FALedgerEntry."Entry No.");
            FAJournalLine.FindFirst();
            FAJournalLine.TestField("FA No.", FALedgerEntry."FA No.");
            FAJournalLine.TestField(Amount, -FALedgerEntry.Amount);
        until FALedgerEntry.Next() = 0;
    end;

    local procedure VerifyCancelGenJournalLines(FANo: Code[20])
    var
        FALedgerEntry: Record "FA Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        FALedgerEntry.SetRange("FA No.", FANo);
        FALedgerEntry.FindSet();
        repeat
            GenJournalLine.SetRange("FA Error Entry No.", FALedgerEntry."Entry No.");
            GenJournalLine.FindFirst();
            GenJournalLine.TestField("Account No.", FALedgerEntry."FA No.");
            GenJournalLine.TestField(Amount, -FALedgerEntry.Amount);
        until FALedgerEntry.Next() = 0;
    end;

    local procedure VerifyDimensionCodeAndValue(FAAllocation: Record "FA Allocation"; GenJournalLine: Record "Gen. Journal Line")
    var
        DimensionSetEntry: Record "Dimension Set Entry";
        DimensionSetEntry2: Record "Dimension Set Entry";
    begin
        LibraryDimension.FindDimensionSetEntry(DimensionSetEntry, FAAllocation."Dimension Set ID");
        GenJournalLine.SetRange("Account No.", FAAllocation."Account No.");
        GenJournalLine.FindFirst();
        LibraryDimension.FindDimensionSetEntry(DimensionSetEntry2, GenJournalLine."Dimension Set ID");
        DimensionSetEntry2.SetRange("Dimension Set ID", DimensionSetEntry."Dimension Set ID");
        DimensionSetEntry2.FindFirst();
        DimensionSetEntry2.TestField("Dimension Code", DimensionSetEntry."Dimension Code");
        DimensionSetEntry2.TestField("Dimension Value Code", DimensionSetEntry."Dimension Value Code");
    end;

    local procedure VerifyDimensionOnFAAllocation(DocumentNo: Code[20]; "Code": Code[20])
    var
        FAAllocation: Record "FA Allocation";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        FAAllocation.SetRange(Code, Code);
        FAAllocation.SetRange("Allocation Type", FAAllocation."Allocation Type"::Acquisition);
        FAAllocation.FindSet();
        GenJournalLine.SetRange("Document No.", DocumentNo);
        GenJournalLine.FindFirst();
        repeat
            VerifyDimensionCodeAndValue(FAAllocation, GenJournalLine);
        until FAAllocation.Next() = 0;
    end;

    local procedure VerifyDimensionOnGLJournal(DocumentNo: Code[20]; "Code": Code[20]; AllocationType: Enum "FA Allocation Type")
    var
        FAAllocation: Record "FA Allocation";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        FAAllocation.SetRange(Code, Code);
        FAAllocation.SetRange("Allocation Type", AllocationType);
        FAAllocation.FindSet();
        GenJournalLine.SetRange("Document No.", DocumentNo);
        repeat
            GenJournalLine.SetRange("Account No.", FAAllocation."Account No.");
            GenJournalLine.FindFirst();
            GenJournalLine.TestField("Dimension Set ID", FAAllocation."Dimension Set ID");
        until FAAllocation.Next() = 0;
    end;

    local procedure VerifyDimensionValueOnGLJournal(DocumentNo: Code[20]; AccountNo: Code[20]; DimensionValue: Record "Dimension Value")
    var
        GenJournalLine: Record "Gen. Journal Line";
        DimensionSetEntry: Record "Dimension Set Entry";
        FAJournalSetup: Record "FA Journal Setup";
    begin
        FAJournalSetup.FindLast();
        FindGenJnlLine(GenJournalLine, DocumentNo, AccountNo);
        LibraryDimension.FindDimensionSetEntry(DimensionSetEntry, GenJournalLine."Dimension Set ID");
        Assert.AreEqual(
          DimensionValue."Dimension Code", DimensionSetEntry."Dimension Code",
          StrSubstNo(CheckDimValueInGenJournalErr, DimensionSetEntry.FieldCaption("Dimension Code"),
            GenJournalLine."Document No.", GenJournalLine."Account No.", FAJournalSetup."Gen. Jnl. Batch Name"));
        Assert.AreEqual(
          DimensionValue.Code, DimensionSetEntry."Dimension Value Code",
          StrSubstNo(CheckDimValueInGenJournalErr, DimensionSetEntry.FieldCaption("Dimension Value Code"),
            GenJournalLine."Document No.", GenJournalLine."Account No.", FAJournalSetup."Gen. Jnl. Batch Name"));
    end;

    local procedure VerifyDimSetEntryOnGenJnlLine(DocumentNo: Code[20]; AccountNo: Code[20]; ExpectedDimSetEntry: Integer)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        FindGenJnlLine(GenJournalLine, DocumentNo, AccountNo);
        Assert.AreEqual(ExpectedDimSetEntry, GenJournalLine."Dimension Set ID", GenJournalLine.FieldCaption("Dimension Set ID"));
    end;

    local procedure VerifyDimensionOnLedgerEntry(DimensionValue: Record "Dimension Value"; FANo: Code[20])
    var
        DimensionSetEntry: Record "Dimension Set Entry";
        FALedgerEntry: Record "FA Ledger Entry";
        LibraryDimension: Codeunit "Library - Dimension";
    begin
        FALedgerEntry.SetRange("FA No.", FANo);
        FALedgerEntry.FindFirst();
        LibraryDimension.FindDimensionSetEntry(DimensionSetEntry, FALedgerEntry."Dimension Set ID");
        DimensionSetEntry.TestField("Dimension Code", DimensionValue."Dimension Code");
        DimensionSetEntry.TestField("Dimension Value Code", DimensionValue.Code);
    end;

    local procedure VerifyFAGLJournal(AccountNo: Code[20]; DimensionSetID: Integer)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetRange("Account No.", AccountNo);
        GenJournalLine.FindFirst();
        GenJournalLine.TestField("Dimension Set ID", DimensionSetID);
    end;

    local procedure VerifyFAGLJournalLines(DimensionValue: Record "Dimension Value"; AccountNo: Code[20])
    var
        DimensionSetEntry: Record "Dimension Set Entry";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetRange("Account No.", AccountNo);
        GenJournalLine.FindFirst();
        LibraryDimension.FindDimensionSetEntry(DimensionSetEntry, GenJournalLine."Dimension Set ID");
        DimensionSetEntry.TestField("Dimension Code", DimensionValue."Dimension Code");
        DimensionSetEntry.TestField("Dimension Value Code", DimensionValue.Code);
    end;

    local procedure VerifyFAJournalLine(FANo: Code[20]; DepreciationBookCode: Code[10]; DimensionSetID: Integer)
    var
        FAJournalLine: Record "FA Journal Line";
    begin
        FAJournalLine.SetRange("Depreciation Book Code", DepreciationBookCode);
        FAJournalLine.SetRange("FA No.", FANo);
        FAJournalLine.FindFirst();
        FAJournalLine.TestField("Dimension Set ID", DimensionSetID);
    end;

    local procedure VerifyFALedgerEntry(FANo: Code[20]; DimensionSetID: Integer)
    var
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        FindFALedgerEntry(FALedgerEntry, FANo);
        FALedgerEntry.TestField("Dimension Set ID", DimensionSetID);
    end;

    local procedure VerifyInsuranceDimension(DefaultDimension: Record "Default Dimension"; FANo: Code[20])
    var
        DimensionSetEntry: Record "Dimension Set Entry";
        InsuranceJournalLine: Record "Insurance Journal Line";
    begin
        InsuranceJournalLine.SetRange("FA No.", FANo);
        InsuranceJournalLine.FindFirst();
        LibraryDimension.FindDimensionSetEntry(DimensionSetEntry, InsuranceJournalLine."Dimension Set ID");
        DimensionSetEntry.TestField("Dimension Code", DefaultDimension."Dimension Code");
        DimensionSetEntry.TestField("Dimension Value Code", DefaultDimension."Dimension Value Code");
    end;

    local procedure VerifyInsuranceJournalLine(FANo: Code[20]; DimensionSetID: Integer)
    var
        InsuranceJournalLine: Record "Insurance Journal Line";
    begin
        InsuranceJournalLine.SetRange("FA No.", FANo);
        InsuranceJournalLine.FindFirst();
        InsuranceJournalLine.TestField("Dimension Set ID", DimensionSetID);
    end;

    local procedure VerifyInsCoverageLedgerEntry(FANo: Code[20]; DimensionSetID: Integer)
    var
        InsCoverageLedgerEntry: Record "Ins. Coverage Ledger Entry";
    begin
        InsCoverageLedgerEntry.SetRange("FA No.", FANo);
        InsCoverageLedgerEntry.FindFirst();
        InsCoverageLedgerEntry.TestField("Dimension Set ID", DimensionSetID);
    end;

    local procedure VerifyMaintenanceLedgerEntry(FANo: Code[20]; DimensionSetID: Integer)
    var
        MaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
    begin
        MaintenanceLedgerEntry.SetRange("FA No.", FANo);
        MaintenanceLedgerEntry.FindFirst();
        MaintenanceLedgerEntry.TestField("Dimension Set ID", DimensionSetID);
    end;

    local procedure VerifyDimensionValue(DimensionValue: Record "Dimension Value"; FixedAssetNo: Code[20])
    var
        DefaultDimension: Record "Default Dimension";
    begin
        DefaultDimension.Get(DATABASE::"Fixed Asset", FixedAssetNo, DimensionValue."Dimension Code");
        DefaultDimension.TestField("Dimension Value Code", DimensionValue.Code);
    end;

    local procedure VerifyExpectedGenJnlDocNo(JournalTemplateName: Code[20]; JournalBatchName: Code[20]; ExpectedDocumentNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetRange("Journal Template Name", JournalTemplateName);
        GenJournalLine.SetRange("Journal Batch Name", JournalBatchName);
        GenJournalLine.FindFirst();
        GenJournalLine.TestField("Document No.", ExpectedDocumentNo);
    end;

    local procedure VerifyExpectedFAJnlDocNo(JournalTemplateName: Code[20]; JournalBatchName: Code[20]; ExpectedDocumentNo: Code[20])
    var
        FAJournalLine: Record "FA Journal Line";
    begin
        FAJournalLine.SetRange("Journal Template Name", JournalTemplateName);
        FAJournalLine.SetRange("Journal Batch Name", JournalBatchName);
        FAJournalLine.FindFirst();
        FAJournalLine.TestField("Document No.", ExpectedDocumentNo);
    end;

    local procedure CreateInsuranceJournalLine(var InsuranceJournalLine: Record "Insurance Journal Line"; InsuranceNo: Code[20]; FixedAssetNo: Code[20])
    var
        InsuranceJournalBatch: Record "Insurance Journal Batch";
    begin
        CreateInsuranceJournalBatch(InsuranceJournalBatch);
        LibraryFixedAsset.CreateInsuranceJournalLine(
          InsuranceJournalLine, InsuranceJournalBatch."Journal Template Name", InsuranceJournalBatch.Name);

        InsuranceJournalLine.Validate("Posting Date", WorkDate());
        InsuranceJournalLine.Validate("FA No.", FixedAssetNo);
        InsuranceJournalLine.Validate("Insurance No.", InsuranceNo);
        InsuranceJournalLine.Validate(Amount, LibraryRandom.RandDec(1000, 2));
        InsuranceJournalLine.Modify(true);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure DepreciationCalcConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(CompletionStatsTok, Question);
        Reply := false;
    end;
}

