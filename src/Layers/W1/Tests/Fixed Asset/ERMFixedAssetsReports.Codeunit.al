codeunit 134978 "ERM Fixed Assets Reports"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Fixed Asset]
        isInitialized := false;
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;
        SpecifyDateErr: Label 'You must specify the Starting Date and the Ending Date.';
        LaterEndingDateErr: Label 'The Starting Date is later than the Ending Date.';
        AcquisitionCostTxt: Label 'Acquisition Cost';
        BookValueTxt: Label 'Book Value';
        TotalTxt: Label 'Total';
        GroupTotalTxt: Label 'Group Total:';
        UnknownErr: Label 'Unknown Error.';
        GroupTotalsTxt: Label 'Group Totals: %1', Comment = '%1 = Field Caption';
        AdditionInPeriodTxt: Label 'Addition in Period';
        DisposalInPeriodTxt: Label 'Disposal in Period';
        DepreciationInPeriodTxt: Label 'Depreciation in Period';
        DepreciationTxt: Label 'Depreciation %1', Comment = '%1 = Depreciation Cost Amount';
        DisposalDepreciationTxt: Label 'Disposal Depreciation in Period';
        Custom1DepreciationErr: Label 'In a budget report, %1 must be No in Depreciation Book.', Comment = '%1 = Field Name';
        BookValueBudgetReportTxt: Label 'Fixed Asset - Book Value 0%1 (Budget Report)', Comment = '%1 = Integer (1 or 2)';
        ExistErr: Label '%1 must exist.', Comment = '%1 = Column or field value';
        ValueMismatchErr: Label '%1 must be %2.', Comment = '%1 = Column Caption, %2 = Value';
        ReclassifyTxt: Label 'Reclassification';

    [Test]
    [Scope('OnPrem')]
    procedure DateErrorFixedAssetBookValue01()
    var
        FixedAsset: Record "Fixed Asset";
        FixedAssetBookValue01: Report "Fixed Asset - Book Value 01";
    begin
        // Test error occurs on Running Fixed Asset Book Value 01 Report without Starting and Ending Date.

        // 1. Setup.
        Initialize();

        // 2. Exercise: Run Fixed Asset Book Value 01 Report without Starting and Ending Date.
        LibraryLowerPermissions.SetO365FAView();
        FixedAssetBookValue01.UseRequestPage(false);
        FixedAssetBookValue01.SetMandatoryFields('', 0D, 0D);
        FixedAssetBookValue01.GetDepreciationBookCode();
        LibraryReportValidation.SetFileName(FixedAsset.TableCaption());
        asserterror FixedAssetBookValue01.SaveAsExcel(LibraryReportValidation.GetFileName());

        // 3. Verify: Verify "You must specify the Starting Date and the Ending Date" error occurs.
        Assert.AreEqual(StrSubstNo(SpecifyDateErr), GetLastErrorText, UnknownErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EndingDateErrorBookValue01()
    var
        DepreciationBook: Record "Depreciation Book";
        FixedAssetBookValue01: Report "Fixed Asset - Book Value 01";
    begin
        // Test error occurs on Running Fixed Asset Book Value 01 Report with Starting Date greater than Ending Date.

        // 1. Setup: Create Depreciation Book.
        Initialize();
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);

        // 2. Exercise: Run Fixed Asset Book Value 01 Report with Starting Date greater than Ending Date.
        LibraryLowerPermissions.SetO365FAView();
        FixedAssetBookValue01.UseRequestPage(false);

        // Using Random Number for the Day.
        FixedAssetBookValue01.SetMandatoryFields(
          DepreciationBook.Code, CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()), WorkDate());
        LibraryReportValidation.SetFileName(DepreciationBook.Code);
        asserterror FixedAssetBookValue01.SaveAsExcel(LibraryReportValidation.GetFileName());

        // 3. Verify: Verify "The Starting Date is later than the Ending Date" error occurs.
        Assert.AreEqual(StrSubstNo(LaterEndingDateErr), GetLastErrorText, UnknownErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DepreciationBookCodeError()
    var
        DepreciationBook: Record "Depreciation Book";
        FixedAssetBookValue01: Report "Fixed Asset - Book Value 01";
    begin
        // Test error occurs on Running Fixed Asset Book Value 01 Report without Depreciation Book Code.

        // 1. Setup.
        Initialize();

        // 2. Exercise: Run Fixed Asset Book Value 01 Report without Depreciation Book Code.
        LibraryLowerPermissions.SetO365FAView();
        FixedAssetBookValue01.UseRequestPage(false);
        FixedAssetBookValue01.SetMandatoryFields('', WorkDate(), WorkDate());
        LibraryReportValidation.SetFileName(DepreciationBook.TableCaption());
        asserterror FixedAssetBookValue01.SaveAsExcel(LibraryReportValidation.GetFileName());

        // 3. Verify: Verify "Depreciation Book Code does not exist" error occurs.
        Assert.ExpectedErrorCannotFind(Database::"Depreciation Book");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BookValueGroupByFAPostingGroup()
    var
        FixedAsset: Record "Fixed Asset";
        FixedAsset2: Record "Fixed Asset";
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        GroupTotals: Option " ","FA Class","FA Subclass","FA Location","Main Asset","Global Dimension 1","Global Dimension 2","FA Posting Group";
        AcquisitionCostAmount: Decimal;
        AcquisitionCostAmount2: Decimal;
        DepreciationCostAmount: Decimal;
        DepreciationCostAmount2: Decimal;
        PostingDate: Date;
    begin
        // Test values on Fixed Asset Book Value 01 Report after running with Group Total as FA Posting Group.

        // 1. Setup: Create Depreciation Book, Create 2 Fixed Assets with Same FA Posting Group, Create FA Depreciation Book, Create and
        // Post FA Journal Lines with FA Posting Type Acquisition cost, Depreciation and Disposal for both Fixed Assets.
        Initialize();
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset2);
        AttachFAPostingGroup(FixedAsset2, FixedAsset."FA Posting Group");
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", DepreciationBook.Code);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset2."No.", FixedAsset."FA Posting Group", DepreciationBook.Code);

        // Using the Random Number for the Day.
        PostingDate := CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate());
        AcquisitionCostAmount := PostAcquisitionDifferentFA(FixedAsset."No.", FixedAsset2."No.", DepreciationBook.Code, PostingDate);
        AcquisitionCostAmount2 := PostAcquisitionDifferentFA(FixedAsset."No.", FixedAsset2."No.", DepreciationBook.Code, WorkDate());
        DepreciationCostAmount := PostDepreciationDifferentFA(FixedAsset."No.", FixedAsset2."No.", DepreciationBook.Code, PostingDate);
        DepreciationCostAmount2 := PostDepreciationDifferentFA(FixedAsset."No.", FixedAsset2."No.", DepreciationBook.Code, WorkDate());
        PostDisposalDifferentFA(FixedAsset."No.", FixedAsset2."No.", DepreciationBook.Code, WorkDate());

        // 2. Exercise: Run Fixed Asset Book Value 01 Report with Group Total as FA Posting Group.
        LibraryLowerPermissions.SetO365FAView();
        FixedAsset.SetFilter("No.", '%1|%2', FixedAsset."No.", FixedAsset2."No.");
        RunFixedAssetBookValue01Report(FixedAsset, DepreciationBook.Code, GroupTotals::"FA Posting Group", false, false);

        // 3. Verify: Verify values on Fixed Asset Book Value 01 Report.
        LibraryReportValidation.OpenFile();
        LibraryReportValidation.SetRange(
          StrSubstNo(GroupTotalsTxt, FixedAsset.FieldCaption("FA Posting Group")),
          GroupTotalTxt + ' ' + FixedAsset."FA Posting Group");
        VerifyFixedAssetBookValue(AcquisitionCostAmount, AcquisitionCostAmount2, DepreciationCostAmount, DepreciationCostAmount2);
        VerifyBookValue(FindDisposalAmount(FixedAsset."No.") + FindDisposalAmount(FixedAsset2."No."), DisposalDepreciationTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BookValueGroupByFAClass()
    var
        FixedAsset: Record "Fixed Asset";
        FixedAsset2: Record "Fixed Asset";
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        FAClass: Record "FA Class";
        GroupTotals: Option " ","FA Class","FA Subclass","FA Location","Main Asset","Global Dimension 1","Global Dimension 2","FA Posting Group";
        AcquisitionCostAmount: Decimal;
        AcquisitionCostAmount2: Decimal;
        DepreciationCostAmount: Decimal;
        DepreciationCostAmount2: Decimal;
        PostingDate: Date;
    begin
        // Test values on Fixed Asset Book Value 01 Report after running with Group Total as FA Class.

        // 1. Setup: Create Depreciation Book, Create 2 Fixed Assets with Same FA Class Code, Create FA Depreciation Book, Create and
        // Post FA Journal Lines with FA Posting Type Acquisition cost, Depreciation and Disposal for both Fixed Assets.
        Initialize();
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset2);
        CreateFixedAssetClass(FAClass);

        UpdateFAClassCode(FixedAsset, FAClass.Code);
        UpdateFAClassCode(FixedAsset2, FAClass.Code);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", '', DepreciationBook.Code);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset2."No.", '', DepreciationBook.Code);

        // Using the Random Number for the Day.
        PostingDate := CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate());
        AcquisitionCostAmount := PostAcquisitionDifferentFA(FixedAsset."No.", FixedAsset2."No.", DepreciationBook.Code, PostingDate);
        AcquisitionCostAmount2 := PostAcquisitionDifferentFA(FixedAsset."No.", FixedAsset2."No.", DepreciationBook.Code, WorkDate());
        DepreciationCostAmount := PostDepreciationDifferentFA(FixedAsset."No.", FixedAsset2."No.", DepreciationBook.Code, PostingDate);
        DepreciationCostAmount2 := PostDepreciationDifferentFA(FixedAsset."No.", FixedAsset2."No.", DepreciationBook.Code, WorkDate());
        PostDisposalDifferentFA(FixedAsset."No.", FixedAsset2."No.", DepreciationBook.Code, WorkDate());

        // 2. Exercise: Run Fixed Asset Book Value 01 Report with Group Total as FA Class.
        LibraryLowerPermissions.SetO365FAView();
        FixedAsset.SetFilter("No.", '%1|%2', FixedAsset."No.", FixedAsset2."No.");
        RunFixedAssetBookValue01Report(FixedAsset, DepreciationBook.Code, GroupTotals::"FA Class", false, false);

        // 3. Verify: Verify values on Fixed Asset Book Value 01 Report.
        LibraryReportValidation.OpenFile();
        LibraryReportValidation.SetRange(
          StrSubstNo(GroupTotalsTxt, FixedAsset.FieldCaption("FA Class Code")), GroupTotalTxt + ' ' + FAClass.Code);
        VerifyFixedAssetBookValue(AcquisitionCostAmount, AcquisitionCostAmount2, DepreciationCostAmount, DepreciationCostAmount2);
        VerifyBookValue(FindDisposalAmount(FixedAsset."No.") + FindDisposalAmount(FixedAsset2."No."), DisposalDepreciationTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BookValueGroupByFASubclass()
    var
        FixedAsset: Record "Fixed Asset";
        FixedAsset2: Record "Fixed Asset";
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        FASubclass: Record "FA Subclass";
        GroupTotals: Option " ","FA Class","FA Subclass","FA Location","Main Asset","Global Dimension 1","Global Dimension 2","FA Posting Group";
        AcquisitionCostAmount: Decimal;
        AcquisitionCostAmount2: Decimal;
        DepreciationCostAmount: Decimal;
        DepreciationCostAmount2: Decimal;
        PostingDate: Date;
    begin
        // Test values on Fixed Asset Book Value 01 Report after running with Group Total as FA SubClass.

        // 1. Setup: Create Depreciation Book, Create 2 Fixed Assets with Same FA SubClass Code, Create FA Depreciation Book, Create and
        // Post FA Journal Lines with FA Posting Type Acquisition cost, Depreciation and Disposal for both Fixed Assets.
        Initialize();
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset2);
        LibraryFixedAsset.CreateFASubclass(FASubclass);
        UpdateFASubClassCode(FixedAsset, FASubclass.Code);
        UpdateFASubClassCode(FixedAsset2, FASubclass.Code);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", '', DepreciationBook.Code);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset2."No.", '', DepreciationBook.Code);

        // Using the Random Number for the Day.
        PostingDate := CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate());
        AcquisitionCostAmount := PostAcquisitionDifferentFA(FixedAsset."No.", FixedAsset2."No.", DepreciationBook.Code, PostingDate);
        AcquisitionCostAmount2 := PostAcquisitionDifferentFA(FixedAsset."No.", FixedAsset2."No.", DepreciationBook.Code, WorkDate());
        DepreciationCostAmount := PostDepreciationDifferentFA(FixedAsset."No.", FixedAsset2."No.", DepreciationBook.Code, PostingDate);
        DepreciationCostAmount2 := PostDepreciationDifferentFA(FixedAsset."No.", FixedAsset2."No.", DepreciationBook.Code, WorkDate());
        PostDisposalDifferentFA(FixedAsset."No.", FixedAsset2."No.", DepreciationBook.Code, WorkDate());

        // 2. Exercise: Run Fixed Asset Book Value 01 Report with Group Total as FA Subclass.
        LibraryLowerPermissions.SetO365FAView();
        FixedAsset.SetFilter("No.", '%1|%2', FixedAsset."No.", FixedAsset2."No.");
        RunFixedAssetBookValue01Report(FixedAsset, DepreciationBook.Code, GroupTotals::"FA Subclass", false, false);

        // 3. Verify: Verify values on Fixed Asset Book Value 01 Report.
        LibraryReportValidation.OpenFile();
        LibraryReportValidation.SetRange(
          StrSubstNo(GroupTotalsTxt, FixedAsset.FieldCaption("FA Subclass Code")), GroupTotalTxt + ' ' + FASubclass.Code);
        VerifyFixedAssetBookValue(AcquisitionCostAmount, AcquisitionCostAmount2, DepreciationCostAmount, DepreciationCostAmount2);
        VerifyBookValue(FindDisposalAmount(FixedAsset."No.") + FindDisposalAmount(FixedAsset2."No."), DisposalDepreciationTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BookValueGroupByFALocation()
    var
        FixedAsset: Record "Fixed Asset";
        FixedAsset2: Record "Fixed Asset";
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        FALocation: Record "FA Location";
        GroupTotals: Option " ","FA Class","FA Subclass","FA Location","Main Asset","Global Dimension 1","Global Dimension 2","FA Posting Group";
        AcquisitionCostAmount: Decimal;
        AcquisitionCostAmount2: Decimal;
        DepreciationCostAmount: Decimal;
        DepreciationCostAmount2: Decimal;
        PostingDate: Date;
    begin
        // Test values on Fixed Asset Book Value 01 Report after running with Group Total as FA Location.

        // 1. Setup: Create Depreciation Book, Create 2 Fixed Assets with Same FA Location Code, Create FA Depreciation Books, Create and
        // Post FA Journal Lines with FA Posting Type Acquisition cost, Depreciation and Disposal for both Fixed Assets.
        Initialize();
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset2);
        CreateFixedAssetLocation(FALocation);
        UpdateFALocationCode(FixedAsset, FALocation.Code);
        UpdateFALocationCode(FixedAsset2, FALocation.Code);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", '', DepreciationBook.Code);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset2."No.", '', DepreciationBook.Code);

        // Using the Random Number for the Day.
        PostingDate := CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate());
        AcquisitionCostAmount := PostAcquisitionDifferentFA(FixedAsset."No.", FixedAsset2."No.", DepreciationBook.Code, PostingDate);
        AcquisitionCostAmount2 := PostAcquisitionDifferentFA(FixedAsset."No.", FixedAsset2."No.", DepreciationBook.Code, WorkDate());
        DepreciationCostAmount := PostDepreciationDifferentFA(FixedAsset."No.", FixedAsset2."No.", DepreciationBook.Code, PostingDate);
        DepreciationCostAmount2 := PostDepreciationDifferentFA(FixedAsset."No.", FixedAsset2."No.", DepreciationBook.Code, WorkDate());
        PostDisposalDifferentFA(FixedAsset."No.", FixedAsset2."No.", DepreciationBook.Code, WorkDate());

        // 2. Exercise: Run Fixed Asset Book Value 01 Report with Group Total as FA Location.
        LibraryLowerPermissions.SetO365FAView();
        FixedAsset.SetFilter("No.", '%1|%2', FixedAsset."No.", FixedAsset2."No.");
        RunFixedAssetBookValue01Report(FixedAsset, DepreciationBook.Code, GroupTotals::"FA Location", false, false);

        // 3. Verify: Verify values on Fixed Asset Book Value 01 Report.
        LibraryReportValidation.OpenFile();
        LibraryReportValidation.SetRange(
          StrSubstNo(GroupTotalsTxt, FixedAsset.FieldCaption("FA Location Code")), GroupTotalTxt + ' ' + FALocation.Code);
        VerifyFixedAssetBookValue(AcquisitionCostAmount, AcquisitionCostAmount2, DepreciationCostAmount, DepreciationCostAmount2);
        VerifyBookValue(FindDisposalAmount(FixedAsset."No.") + FindDisposalAmount(FixedAsset2."No."), DisposalDepreciationTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BookValueGroupGlobalDimension1()
    var
        FixedAsset: Record "Fixed Asset";
        GeneralLedgerSetup: Record "General Ledger Setup";
        DimensionValue: Record "Dimension Value";
        FixedAsset2: Record "Fixed Asset";
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        GroupTotals: Option " ","FA Class","FA Subclass","FA Location","Main Asset","Global Dimension 1","Global Dimension 2","FA Posting Group";
        AcquisitionCostAmount: Decimal;
        AcquisitionCostAmount2: Decimal;
        DepreciationCostAmount: Decimal;
        DepreciationCostAmount2: Decimal;
        PostingDate: Date;
    begin
        // Test values on Fixed Asset Book Value 01 Report after running with Group Total as Global Dimension 1.

        // 1. Setup: Create Depreciation Book, Create 2 Fixed Assets with Same Global Dimension 1 Code, Create FA Depreciation Books, Create
        // and Post FA Journal Lines with FA Posting Type Acquisition cost, Depreciation and Disposal for both Fixed Assets.
        Initialize();
        GeneralLedgerSetup.Get();
        LibraryDimension.FindDimensionValue(DimensionValue, GeneralLedgerSetup."Global Dimension 1 Code");
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset2);
        UpdateGlobalDimension1Code(FixedAsset, DimensionValue.Code);
        UpdateGlobalDimension1Code(FixedAsset2, DimensionValue.Code);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", '', DepreciationBook.Code);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset2."No.", '', DepreciationBook.Code);

        // Using the Random Number for the Day.
        PostingDate := CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate());
        AcquisitionCostAmount := PostAcquisitionDifferentFA(FixedAsset."No.", FixedAsset2."No.", DepreciationBook.Code, PostingDate);
        AcquisitionCostAmount2 := PostAcquisitionDifferentFA(FixedAsset."No.", FixedAsset2."No.", DepreciationBook.Code, WorkDate());
        DepreciationCostAmount := PostDepreciationDifferentFA(FixedAsset."No.", FixedAsset2."No.", DepreciationBook.Code, PostingDate);
        DepreciationCostAmount2 := PostDepreciationDifferentFA(FixedAsset."No.", FixedAsset2."No.", DepreciationBook.Code, WorkDate());
        PostDisposalDifferentFA(FixedAsset."No.", FixedAsset2."No.", DepreciationBook.Code, WorkDate());

        // 2. Exercise: Run Fixed Asset Book Value 01 Report with Group Total as Global Dimension 1.
        LibraryLowerPermissions.SetO365FAView();
        FixedAsset.SetFilter("No.", '%1|%2', FixedAsset."No.", FixedAsset2."No.");
        RunFixedAssetBookValue01Report(FixedAsset, DepreciationBook.Code, GroupTotals::"Global Dimension 1", false, false);

        // 3. Verify: Verify values on Fixed Asset Book Value 01 Report.
        LibraryReportValidation.OpenFile();
        LibraryReportValidation.SetRange(
          StrSubstNo(GroupTotalsTxt, FixedAsset.FieldCaption("Global Dimension 1 Code")), GroupTotalTxt + ' ' + DimensionValue.Code);
        VerifyFixedAssetBookValue(AcquisitionCostAmount, AcquisitionCostAmount2, DepreciationCostAmount, DepreciationCostAmount2);
        VerifyBookValue(FindDisposalAmount(FixedAsset."No.") + FindDisposalAmount(FixedAsset2."No."), DisposalDepreciationTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BookValueGroupGlobalDimension2()
    var
        FixedAsset: Record "Fixed Asset";
        GeneralLedgerSetup: Record "General Ledger Setup";
        DimensionValue: Record "Dimension Value";
        FixedAsset2: Record "Fixed Asset";
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        GroupTotals: Option " ","FA Class","FA Subclass","FA Location","Main Asset","Global Dimension 1","Global Dimension 2","FA Posting Group";
        AcquisitionCostAmount: Decimal;
        AcquisitionCostAmount2: Decimal;
        DepreciationCostAmount: Decimal;
        DepreciationCostAmount2: Decimal;
        PostingDate: Date;
    begin
        // Test values on Fixed Asset Book Value 01 Report after running with Group Total as Global Dimension 2.

        // 1. Setup: Create Depreciation Book, Create 2 Fixed Assets with Same Global Dimension 2 Code, Create FA Depreciation Books, Create
        // and Post FA Journal Lines with FA Posting Type Acquisition cost, Depreciation and Disposal for both Fixed Assets.
        Initialize();
        GeneralLedgerSetup.Get();
        LibraryDimension.FindDimensionValue(DimensionValue, GeneralLedgerSetup."Global Dimension 2 Code");
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset2);
        UpdateGlobalDimension2Code(FixedAsset, DimensionValue.Code);
        UpdateGlobalDimension2Code(FixedAsset2, DimensionValue.Code);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", '', DepreciationBook.Code);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset2."No.", '', DepreciationBook.Code);

        // Using the Random Number for the Day.
        PostingDate := CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate());
        AcquisitionCostAmount := PostAcquisitionDifferentFA(FixedAsset."No.", FixedAsset2."No.", DepreciationBook.Code, PostingDate);
        AcquisitionCostAmount2 := PostAcquisitionDifferentFA(FixedAsset."No.", FixedAsset2."No.", DepreciationBook.Code, WorkDate());
        DepreciationCostAmount := PostDepreciationDifferentFA(FixedAsset."No.", FixedAsset2."No.", DepreciationBook.Code, PostingDate);
        DepreciationCostAmount2 := PostDepreciationDifferentFA(FixedAsset."No.", FixedAsset2."No.", DepreciationBook.Code, WorkDate());
        PostDisposalDifferentFA(FixedAsset."No.", FixedAsset2."No.", DepreciationBook.Code, WorkDate());

        // 2. Exercise: Run Fixed Asset Book Value 01 Report with Group Total as Global Dimension 2.
        LibraryLowerPermissions.SetO365FAView();
        FixedAsset.SetFilter("No.", '%1|%2', FixedAsset."No.", FixedAsset2."No.");
        RunFixedAssetBookValue01Report(FixedAsset, DepreciationBook.Code, GroupTotals::"Global Dimension 2", false, false);

        // 3. Verify: Verify values on Fixed Asset Book Value 01 Report.
        LibraryReportValidation.OpenFile();
        LibraryReportValidation.SetRange(
          StrSubstNo(GroupTotalsTxt, FixedAsset.FieldCaption("Global Dimension 2 Code")), GroupTotalTxt + ' ' + DimensionValue.Code);
        VerifyFixedAssetBookValue(AcquisitionCostAmount, AcquisitionCostAmount2, DepreciationCostAmount, DepreciationCostAmount2);
        VerifyBookValue(FindDisposalAmount(FixedAsset."No.") + FindDisposalAmount(FixedAsset2."No."), DisposalDepreciationTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BookValueGroupByMainAsset()
    var
        FixedAsset: Record "Fixed Asset";
        FixedAsset2: Record "Fixed Asset";
        FixedAsset3: Record "Fixed Asset";
        MainAssetComponent: Record "Main Asset Component";
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        GroupTotals: Option " ","FA Class","FA Subclass","FA Location","Main Asset","Global Dimension 1","Global Dimension 2","FA Posting Group";
        AcquisitionCostAmount: Decimal;
        AcquisitionCostAmount2: Decimal;
        DepreciationCostAmount: Decimal;
        DepreciationCostAmount2: Decimal;
        PostingDate: Date;
    begin
        // Test values on Fixed Asset Book Value 01 Report after running with Group Total as Main Asset.

        // 1. Setup: Create Depreciation Book, Create 3 Fixed Assets, Create Main Asset Components, Create FA Depreciation Books, Create
        // and Post FA Journal Lines with FA Posting Type Acquisition cost, Depreciation and Disposal for first 2 Fixed Assets.
        Initialize();
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset2);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset3);
        LibraryFixedAsset.CreateMainAssetComponent(MainAssetComponent, FixedAsset3."No.", FixedAsset."No.");
        LibraryFixedAsset.CreateMainAssetComponent(MainAssetComponent, FixedAsset3."No.", FixedAsset2."No.");
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", '', DepreciationBook.Code);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset2."No.", '', DepreciationBook.Code);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset3."No.", '', DepreciationBook.Code);

        // Using the Random Number for the Day.
        PostingDate := CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate());
        AcquisitionCostAmount := PostAcquisitionDifferentFA(FixedAsset."No.", FixedAsset2."No.", DepreciationBook.Code, PostingDate);
        AcquisitionCostAmount2 := PostAcquisitionDifferentFA(FixedAsset."No.", FixedAsset2."No.", DepreciationBook.Code, WorkDate());
        DepreciationCostAmount := PostDepreciationDifferentFA(FixedAsset."No.", FixedAsset2."No.", DepreciationBook.Code, PostingDate);
        DepreciationCostAmount2 := PostDepreciationDifferentFA(FixedAsset."No.", FixedAsset2."No.", DepreciationBook.Code, WorkDate());
        PostDisposalDifferentFA(FixedAsset."No.", FixedAsset2."No.", DepreciationBook.Code, WorkDate());

        // 2. Exercise: Run Fixed Asset Book Value 01 Report with Group Total as Main Asset.
        LibraryLowerPermissions.SetO365FAView();
        FixedAsset.SetFilter("No.", '%1|%2', FixedAsset."No.", FixedAsset2."No.");
        RunFixedAssetBookValue01Report(FixedAsset, DepreciationBook.Code, GroupTotals::"Main Asset", false, false);

        // 3. Verify: Verify values on Fixed Asset Book Value 01 Report.
        LibraryReportValidation.OpenFile();
        LibraryReportValidation.SetRange(
          StrSubstNo(GroupTotalsTxt, FixedAsset.FieldCaption("Main Asset/Component")),
          StrSubstNo('Group Total: Main Asset %1', FixedAsset3."No."));
        VerifyFixedAssetBookValue(AcquisitionCostAmount, AcquisitionCostAmount2, DepreciationCostAmount, DepreciationCostAmount2);
        VerifyBookValue(FindDisposalAmount(FixedAsset."No.") + FindDisposalAmount(FixedAsset2."No."), DisposalDepreciationTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrintDetailsBookValue()
    var
        FixedAsset: Record "Fixed Asset";
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        FAJournalLine: Record "FA Journal Line";
        GroupTotals: Option " ","FA Class","FA Subclass","FA Location","Main Asset","Global Dimension 1","Global Dimension 2","FA Posting Group";
        AcquisitionCostAmount: Decimal;
        AcquisitionCostAmount2: Decimal;
        DepreciationCostAmount: Decimal;
        DepreciationCostAmount2: Decimal;
        PostingDate: Date;
    begin
        // Test values on Fixed Asset Book Value 01 Report after running with Print Details as True.

        // 1. Setup: Create Depreciation Book, Create Fixed Asset, Create FA Depreciation Book, Create and Post FA Journal Lines with FA
        // Posting Type Acquisition cost, Depreciation and Disposal for Fixed Asset.
        Initialize();
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", DepreciationBook.Code);

        // Using the Random Number for the Day.
        PostingDate := CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate());
        AcquisitionCostAmount :=
          CreateAndPostFAJournalLine(
            FixedAsset."No.", FAJournalLine."FA Posting Type"::"Acquisition Cost", DepreciationBook.Code, PostingDate);
        AcquisitionCostAmount2 :=
          CreateAndPostFAJournalLine(
            FixedAsset."No.", FAJournalLine."FA Posting Type"::"Acquisition Cost", DepreciationBook.Code, WorkDate());
        DepreciationCostAmount :=
          PostDisposalFAJournalLine(FixedAsset."No.", FAJournalLine."FA Posting Type"::Depreciation, DepreciationBook.Code, PostingDate);
        DepreciationCostAmount2 :=
          PostDisposalFAJournalLine(FixedAsset."No.", FAJournalLine."FA Posting Type"::Depreciation, DepreciationBook.Code, WorkDate());
        PostDisposalFAJournalLine(FixedAsset."No.", FAJournalLine."FA Posting Type"::Disposal, DepreciationBook.Code, WorkDate());

        // 2. Exercise: Run Fixed Asset Book Value 01 Report with Print Details as True.
        LibraryLowerPermissions.SetO365FAView();
        FixedAsset.SetRange("No.", FixedAsset."No.");
        RunFixedAssetBookValue01Report(FixedAsset, DepreciationBook.Code, GroupTotals::" ", true, false);

        // 3. Verify: Verify values on Fixed Asset Book Value 01 Report.
        LibraryReportValidation.OpenFile();
        LibraryReportValidation.SetRange(FixedAsset.FieldCaption("No."), FixedAsset."No.");
        VerifyFixedAssetBookValue(AcquisitionCostAmount, AcquisitionCostAmount2, DepreciationCostAmount, DepreciationCostAmount2);
        VerifyBookValue(FindDisposalAmount(FixedAsset."No."), DisposalDepreciationTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TotalOnBookValue()
    var
        FixedAsset: Record "Fixed Asset";
        FixedAsset2: Record "Fixed Asset";
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        GroupTotals: Option " ","FA Class","FA Subclass","FA Location","Main Asset","Global Dimension 1","Global Dimension 2","FA Posting Group";
        AcquisitionCostAmount: Decimal;
        AcquisitionCostAmount2: Decimal;
        DepreciationCostAmount: Decimal;
        DepreciationCostAmount2: Decimal;
        PostingDate: Date;
    begin
        // Test Total on Fixed Asset Book Value 01 Report after running with Print Details as True.

        // 1. Setup: Create Depreciation Book, Create 2 Fixed Assets, Create FA Depreciation Books, Create and Post FA Journal Lines with FA
        // Posting Type Acquisition cost, Depreciation and Disposal for Fixed Assets.
        Initialize();
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset2);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", '', DepreciationBook.Code);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset2."No.", '', DepreciationBook.Code);

        // Using the Random Number for the Day.
        PostingDate := CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate());
        AcquisitionCostAmount := PostAcquisitionDifferentFA(FixedAsset."No.", FixedAsset2."No.", DepreciationBook.Code, PostingDate);
        AcquisitionCostAmount2 := PostAcquisitionDifferentFA(FixedAsset."No.", FixedAsset2."No.", DepreciationBook.Code, WorkDate());
        DepreciationCostAmount := PostDepreciationDifferentFA(FixedAsset."No.", FixedAsset2."No.", DepreciationBook.Code, PostingDate);
        DepreciationCostAmount2 := PostDepreciationDifferentFA(FixedAsset."No.", FixedAsset2."No.", DepreciationBook.Code, WorkDate());
        PostDisposalDifferentFA(FixedAsset."No.", FixedAsset2."No.", DepreciationBook.Code, WorkDate());

        // 2. Exercise: Run Fixed Asset Book Value 01 Report with Print Details as True.
        LibraryLowerPermissions.SetO365FAView();
        FixedAsset.SetFilter("No.", '%1|%2', FixedAsset."No.", FixedAsset2."No.");
        RunFixedAssetBookValue01Report(FixedAsset, DepreciationBook.Code, GroupTotals::" ", true, false);

        // 3. Verify: Verify Total on Fixed Asset Book Value 01 Report.
        LibraryReportValidation.OpenFile();
        LibraryReportValidation.SetRange(FixedAsset.FieldCaption("No."), TotalTxt);
        VerifyFixedAssetBookValue(AcquisitionCostAmount, AcquisitionCostAmount2, DepreciationCostAmount, DepreciationCostAmount2);
        VerifyBookValue(FindDisposalAmount(FixedAsset."No.") + FindDisposalAmount(FixedAsset2."No."), DisposalDepreciationTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BudgetReportBookValue()
    var
        FixedAsset: Record "Fixed Asset";
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        FAJournalLine: Record "FA Journal Line";
        GroupTotals: Option " ","FA Class","FA Subclass","FA Location","Main Asset","Global Dimension 1","Global Dimension 2","FA Posting Group";
    begin
        // Test Fixed Asset Book Value 01 Report after running with Budget Report as True.

        // 1. Setup: Create Depreciation Book, Create Fixed Asset, Create FA Depreciation Book, Create and Post FA Journal Lines with FA
        // Posting Type Acquisition cost.
        Initialize();
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", DepreciationBook.Code);
        CreateAndPostFAJournalLine(FixedAsset."No.", FAJournalLine."FA Posting Type"::"Acquisition Cost", DepreciationBook.Code, WorkDate());

        // 2. Exercise: Run Fixed Asset Book Value 01 Report with Budget Report as True.
        LibraryLowerPermissions.SetO365FAView();
        FixedAsset.SetRange("No.", FixedAsset."No.");
        RunFixedAssetBookValue01Report(FixedAsset, DepreciationBook.Code, GroupTotals::" ", false, true);

        // 3. Verify: Verify Fixed Asset - Book Value 01 (Budget Report) exist on report.
        LibraryReportValidation.OpenFile();
        Assert.IsTrue(
          LibraryReportValidation.CheckIfValueExists(StrSubstNo(BookValueBudgetReportTxt, 1)),
          StrSubstNo(ExistErr, BookValueBudgetReportTxt));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UseCustom1DepreciationError()
    var
        FixedAsset: Record "Fixed Asset";
        DepreciationBook: Record "Depreciation Book";
        FAJournalLine: Record "FA Journal Line";
        FADepreciationBook: Record "FA Depreciation Book";
        GroupTotals: Option " ","FA Class","FA Subclass","FA Location","Main Asset","Global Dimension 1","Global Dimension 2","FA Posting Group";
    begin
        // Test error occurs on running Fixed Asset Book Value 01 Report with Use Custom 1 Depreciation True on Depreciation Book.

        // 1. Setup: Create Depreciation Book, Create Fixed Asset, Create FA Depreciation Book, Create and Post FA Journal Lines with FA
        // Posting Type Acquisition cost.
        Initialize();
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        UpdateCustom1Depreciation(DepreciationBook);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", DepreciationBook.Code);
        CreateAndPostFAJournalLine(FixedAsset."No.", FAJournalLine."FA Posting Type"::"Acquisition Cost", DepreciationBook.Code, WorkDate());

        // 2. Exercise: Run Fixed Asset Book Value 01 Report with Budget Report as True.
        LibraryLowerPermissions.SetO365FAView();
        FixedAsset.SetRange("No.", FixedAsset."No.");
        asserterror RunFixedAssetBookValue01Report(FixedAsset, DepreciationBook.Code, GroupTotals::" ", false, true);

        // 3. Verify: Verify error "Use Custom 1 Depreciation must be No" occurs.
        Assert.AreEqual(
          StrSubstNo(
            Custom1DepreciationErr, DepreciationBook.FieldCaption("Use Custom 1 Depreciation")), GetLastErrorText, UnknownErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DateErrorFixedAssetBookValue02()
    var
        FixedAsset: Record "Fixed Asset";
        FixedAssetBookValue02: Report "Fixed Asset - Book Value 02";
    begin
        // Test error occurs on Running Fixed Asset Book Value 02 Report without Starting and Ending Date.

        // 1. Setup.
        Initialize();

        // 2. Exercise: Run Fixed Asset Book Value 02 Report without Starting and Ending Date.
        LibraryLowerPermissions.SetO365FAView();
        Clear(FixedAssetBookValue02);
        FixedAssetBookValue02.UseRequestPage(false);
        FixedAssetBookValue02.SetMandatoryFields('', 0D, 0D);
        FixedAssetBookValue02.GetDepreciationBookCode();
        LibraryReportValidation.SetFileName(FixedAsset.TableCaption());
        asserterror FixedAssetBookValue02.SaveAsExcel(LibraryReportValidation.GetFileName());

        // 3. Verify: Verify "You must specify the Starting Date and the Ending Date" error occurs.
        Assert.AreEqual(StrSubstNo(SpecifyDateErr), GetLastErrorText, UnknownErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EndingDateErrorBookValue02()
    var
        DepreciationBook: Record "Depreciation Book";
        FixedAssetBookValue02: Report "Fixed Asset - Book Value 02";
    begin
        // Test error occurs on Running Fixed Asset Book Value 02 Report with Starting Date greater than Ending Date.

        // 1. Setup: Create Depreciation Book.
        Initialize();
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);

        // 2. Exercise: Run Fixed Asset Book Value 02 Report with Starting Date greater than Ending Date.
        LibraryLowerPermissions.SetO365FAView();
        Clear(FixedAssetBookValue02);
        FixedAssetBookValue02.UseRequestPage(false);

        // Using Random Number for the Day.
        FixedAssetBookValue02.SetMandatoryFields(
          DepreciationBook.Code, CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()), WorkDate());
        LibraryReportValidation.SetFileName(DepreciationBook.Code);
        asserterror FixedAssetBookValue02.SaveAsExcel(LibraryReportValidation.GetFileName());

        // 3. Verify: Verify "The Starting Date is later than the Ending Date" error occurs.
        Assert.AreEqual(StrSubstNo(LaterEndingDateErr), GetLastErrorText, UnknownErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlankDepreciationBookCode()
    var
        DepreciationBook: Record "Depreciation Book";
        FixedAssetBookValue02: Report "Fixed Asset - Book Value 02";
    begin
        // Test error occurs on Running Fixed Asset Book Value 02 Report without Depreciation Book Code.

        // 1. Setup.
        Initialize();

        // 2. Exercise: Run Fixed Asset Book Value 02 Report without Depreciation Book Code.
        LibraryLowerPermissions.SetO365FAView();
        Clear(FixedAssetBookValue02);
        FixedAssetBookValue02.UseRequestPage(false);
        FixedAssetBookValue02.SetMandatoryFields('', WorkDate(), WorkDate());
        LibraryReportValidation.SetFileName(DepreciationBook.TableCaption());
        asserterror FixedAssetBookValue02.SaveAsExcel(LibraryReportValidation.GetFileName());

        // 3. Verify: Verify "Depreciation Book Code does not exist" error occurs.
        Assert.ExpectedErrorCannotFind(Database::"Depreciation Book");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BudgetReportBookValue02()
    var
        FixedAsset: Record "Fixed Asset";
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        FAJournalLine: Record "FA Journal Line";
        GroupTotals: Option " ","FA Class","FA Subclass","FA Location","Main Asset","Global Dimension 1","Global Dimension 2","FA Posting Group";
    begin
        // Test Fixed Asset Book Value 02 Report after running with Budget Report as True.

        // 1. Setup: Create Depreciation Book, Create Fixed Asset, Create FA Depreciation Book, Create and Post FA Journal Lines with FA
        // Posting Type Acquisition cost.
        Initialize();
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", DepreciationBook.Code);
        CreateAndPostFAJournalLine(FixedAsset."No.", FAJournalLine."FA Posting Type"::"Acquisition Cost", DepreciationBook.Code, WorkDate());

        // 2. Exercise: Run Fixed Asset Book Value 02 Report with Budget Report as True.
        LibraryLowerPermissions.SetO365FAView();
        FixedAsset.SetRange("No.", FixedAsset."No.");
        RunFixedAssetBookValue02Report(FixedAsset, DepreciationBook.Code, GroupTotals::" ", false, true, false);

        // 3. Verify: Verify Fixed Asset - Book Value 02 (Budget Report) exist on report.
        LibraryReportValidation.OpenFile();
        Assert.IsTrue(
          LibraryReportValidation.CheckIfValueExists(StrSubstNo(BookValueBudgetReportTxt, 2)),
          StrSubstNo(ExistErr, BookValueBudgetReportTxt));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UseCustom1ErrorBookValue02()
    var
        FixedAsset: Record "Fixed Asset";
        DepreciationBook: Record "Depreciation Book";
        FAJournalLine: Record "FA Journal Line";
        FADepreciationBook: Record "FA Depreciation Book";
        GroupTotals: Option " ","FA Class","FA Subclass","FA Location","Main Asset","Global Dimension 1","Global Dimension 2","FA Posting Group";
    begin
        // Test error occurs on running Fixed Asset Book Value 02 Report with Use Custom 1 Depreciation True on Depreciation Book.

        // 1. Setup: Create Depreciation Book, Create Fixed Asset, Create FA Depreciation Book, Create and Post FA Journal Lines with FA
        // Posting Type Acquisition cost.
        Initialize();
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        UpdateCustom1Depreciation(DepreciationBook);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", DepreciationBook.Code);
        CreateAndPostFAJournalLine(FixedAsset."No.", FAJournalLine."FA Posting Type"::"Acquisition Cost", DepreciationBook.Code, WorkDate());

        // 2. Exercise: Run Fixed Asset Book Value 02 Report with Budget Report as True.
        LibraryLowerPermissions.SetO365FAView();
        FixedAsset.SetRange("No.", FixedAsset."No.");
        asserterror RunFixedAssetBookValue02Report(FixedAsset, DepreciationBook.Code, GroupTotals::" ", false, true, false);

        // 3. Verify: Verify error "Use Custom 1 Depreciation must be No" occurs.
        Assert.AreEqual(
          StrSubstNo(
            Custom1DepreciationErr, DepreciationBook.FieldCaption("Use Custom 1 Depreciation")), GetLastErrorText, UnknownErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GroupFAPostingGroupBookValue02()
    var
        FixedAsset: Record "Fixed Asset";
        FixedAsset2: Record "Fixed Asset";
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        GroupTotals: Option " ","FA Class","FA Subclass","FA Location","Main Asset","Global Dimension 1","Global Dimension 2","FA Posting Group";
        AcquisitionCostAmount: Decimal;
        AcquisitionCostAmount2: Decimal;
        DepreciationCostAmount: Decimal;
        DepreciationCostAmount2: Decimal;
        PostingDate: Date;
    begin
        // Test values on Fixed Asset Book Value 02 Report after running with Group Total as FA Posting Group.

        // 1. Setup: Create Depreciation Book, Create 2 Fixed Assets with Same FA Posting Group, Create FA Depreciation Books, Create and
        // Post FA Journal Lines with FA Posting Type Acquisition cost and Depreciation for both Fixed Assets.
        Initialize();
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset2);
        AttachFAPostingGroup(FixedAsset2, FixedAsset."FA Posting Group");
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", DepreciationBook.Code);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset2."No.", FixedAsset."FA Posting Group", DepreciationBook.Code);

        // Using the Random Number for the Day.
        PostingDate := CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate());
        AcquisitionCostAmount := PostAcquisitionDifferentFA(FixedAsset."No.", FixedAsset2."No.", DepreciationBook.Code, PostingDate);
        AcquisitionCostAmount2 := PostAcquisitionDifferentFA(FixedAsset."No.", FixedAsset2."No.", DepreciationBook.Code, WorkDate());
        DepreciationCostAmount := PostDepreciationDifferentFA(FixedAsset."No.", FixedAsset2."No.", DepreciationBook.Code, PostingDate);
        DepreciationCostAmount2 := PostDepreciationDifferentFA(FixedAsset."No.", FixedAsset2."No.", DepreciationBook.Code, WorkDate());

        // 2. Exercise: Run Fixed Asset Book Value 02 Report with Group Total as FA Posting Group.
        LibraryLowerPermissions.SetO365FAView();
        FixedAsset.SetFilter("No.", '%1|%2', FixedAsset."No.", FixedAsset2."No.");
        RunFixedAssetBookValue02Report(FixedAsset, DepreciationBook.Code, GroupTotals::"FA Posting Group", false, false, false);

        // 3. Verify: Verify values on Fixed Asset Book Value 02 Report.
        VerifyTotalExistenceOnReport(FixedAsset.FieldCaption("FA Posting Group"), FixedAsset."FA Posting Group");
        VerifyDecimalValuesOnReport(AcquisitionCostAmount, AcquisitionCostAmount2, DepreciationCostAmount, DepreciationCostAmount2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeprValuesGroupFAPostingGroupBookValue()
    var
        FixedAsset: Record "Fixed Asset";
        FixedAsset2: Record "Fixed Asset";
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        FAJournalLine: Record "FA Journal Line";
        GroupTotals: Option " ","FA Class","FA Subclass","FA Location","Main Asset","Global Dimension 1","Global Dimension 2","FA Posting Group";
        AcquisitionCostAmount: Decimal;
        DepreciationCostAmount: Decimal;
    begin
        // Test values on Fixed Asset Book Value 02 Report after running with Group Total as FA Posting Group. First FA does not have
        // depreciation entries.
        // 1. Setup: Create Depreciation Book, Create 2 Fixed Assets with Same FA Posting Group, Create FA Depreciation Books, Create and
        // Post FA Journal Lines with FA Posting Type Acquisition cost and Depreciation for both Fixed Assets.
        Initialize();
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset2);
        AttachFAPostingGroup(FixedAsset2, FixedAsset."FA Posting Group");
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", DepreciationBook.Code);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset2."No.", FixedAsset."FA Posting Group", DepreciationBook.Code);

        AcquisitionCostAmount := PostAcquisitionDifferentFA(FixedAsset."No.", FixedAsset2."No.", DepreciationBook.Code, WorkDate());
        DepreciationCostAmount :=
          PostDisposalFAJournalLine(FixedAsset2."No.", FAJournalLine."FA Posting Type"::Depreciation, DepreciationBook.Code, WorkDate());

        // 2. Exercise: Run Fixed Asset Book Value 02 Report with Group Total as FA Posting Group.
        LibraryLowerPermissions.SetO365FAView();
        FixedAsset.SetFilter("No.", '%1|%2', FixedAsset."No.", FixedAsset2."No.");
        RunFixedAssetBookValue02Report(FixedAsset, DepreciationBook.Code, GroupTotals::"FA Posting Group", false, false, false);

        // 3. Verify: Verify depreciation values exist on Fixed Asset Book Value 02 Report.
        VerifyDecimalValuesOnReport(AcquisitionCostAmount, 0, DepreciationCostAmount, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GroupByFAClassBookValue02()
    var
        FixedAsset: Record "Fixed Asset";
        FixedAsset2: Record "Fixed Asset";
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        FAClass: Record "FA Class";
        GroupTotals: Option " ","FA Class","FA Subclass","FA Location","Main Asset","Global Dimension 1","Global Dimension 2","FA Posting Group";
        AcquisitionCostAmount: Decimal;
        AcquisitionCostAmount2: Decimal;
        DepreciationCostAmount: Decimal;
        DepreciationCostAmount2: Decimal;
        PostingDate: Date;
    begin
        // Test values on Fixed Asset Book Value 02 Report after running with Group Total as FA Class.

        // 1. Setup: Create Depreciation Book, Create 2 Fixed Assets with Same FA Class Code, Create FA Depreciation Books, Create and
        // Post FA Journal Lines with FA Posting Type Acquisition cost and Depreciation for both Fixed Assets.
        Initialize();
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset2);
        CreateFixedAssetClass(FAClass);
        UpdateFAClassCode(FixedAsset, FAClass.Code);
        UpdateFAClassCode(FixedAsset2, FAClass.Code);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", '', DepreciationBook.Code);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset2."No.", '', DepreciationBook.Code);

        // Using the Random Number for the Day.
        PostingDate := CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate());
        AcquisitionCostAmount := PostAcquisitionDifferentFA(FixedAsset."No.", FixedAsset2."No.", DepreciationBook.Code, PostingDate);
        AcquisitionCostAmount2 := PostAcquisitionDifferentFA(FixedAsset."No.", FixedAsset2."No.", DepreciationBook.Code, WorkDate());
        DepreciationCostAmount := PostDepreciationDifferentFA(FixedAsset."No.", FixedAsset2."No.", DepreciationBook.Code, PostingDate);
        DepreciationCostAmount2 := PostDepreciationDifferentFA(FixedAsset."No.", FixedAsset2."No.", DepreciationBook.Code, WorkDate());

        // 2. Exercise: Run Fixed Asset Book Value 02 Report with Group Total as FA Class.
        LibraryLowerPermissions.SetO365FAView();
        FixedAsset.SetFilter("No.", '%1|%2', FixedAsset."No.", FixedAsset2."No.");
        RunFixedAssetBookValue02Report(FixedAsset, DepreciationBook.Code, GroupTotals::"FA Class", false, false, false);

        // 3. Verify: Verify values on Fixed Asset Book Value 02 Report.
        VerifyTotalExistenceOnReport(FixedAsset.FieldCaption("FA Class Code"), FAClass.Code);
        VerifyDecimalValuesOnReport(AcquisitionCostAmount, AcquisitionCostAmount2, DepreciationCostAmount, DepreciationCostAmount2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GroupByFASubclassBookValue02()
    var
        FixedAsset: Record "Fixed Asset";
        FixedAsset2: Record "Fixed Asset";
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        FASubclass: Record "FA Subclass";
        GroupTotals: Option " ","FA Class","FA Subclass","FA Location","Main Asset","Global Dimension 1","Global Dimension 2","FA Posting Group";
        AcquisitionCostAmount: Decimal;
        AcquisitionCostAmount2: Decimal;
        DepreciationCostAmount: Decimal;
        DepreciationCostAmount2: Decimal;
        PostingDate: Date;
    begin
        // Test values on Fixed Asset Book Value 02 Report after running with Group Total as FA SubClass.

        // 1. Setup: Create Depreciation Book, Create 2 Fixed Assets with Same FA SubClass Code, Create FA Depreciation Books, Create and
        // Post FA Journal Lines with FA Posting Type Acquisition cost and Depreciation for both Fixed Assets.
        Initialize();
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset2);
        LibraryFixedAsset.CreateFASubclass(FASubclass);
        UpdateFASubClassCode(FixedAsset, FASubclass.Code);
        UpdateFASubClassCode(FixedAsset2, FASubclass.Code);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", '', DepreciationBook.Code);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset2."No.", '', DepreciationBook.Code);

        // Using the Random Number for the Day.
        PostingDate := CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate());
        AcquisitionCostAmount := PostAcquisitionDifferentFA(FixedAsset."No.", FixedAsset2."No.", DepreciationBook.Code, PostingDate);
        AcquisitionCostAmount2 := PostAcquisitionDifferentFA(FixedAsset."No.", FixedAsset2."No.", DepreciationBook.Code, WorkDate());
        DepreciationCostAmount := PostDepreciationDifferentFA(FixedAsset."No.", FixedAsset2."No.", DepreciationBook.Code, PostingDate);
        DepreciationCostAmount2 := PostDepreciationDifferentFA(FixedAsset."No.", FixedAsset2."No.", DepreciationBook.Code, WorkDate());

        // 2. Exercise: Run Fixed Asset Book Value 02 Report with Group Total as FA Subclass.
        LibraryLowerPermissions.SetO365FAView();
        FixedAsset.SetFilter("No.", '%1|%2', FixedAsset."No.", FixedAsset2."No.");
        RunFixedAssetBookValue02Report(FixedAsset, DepreciationBook.Code, GroupTotals::"FA Subclass", false, false, false);

        // 3. Verify: Verify values on Fixed Asset Book Value 02 Report.
        VerifyTotalExistenceOnReport(FixedAsset.FieldCaption("FA Subclass Code"), FASubclass.Code);
        VerifyDecimalValuesOnReport(AcquisitionCostAmount, AcquisitionCostAmount2, DepreciationCostAmount, DepreciationCostAmount2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GroupByFALocationBookValue02()
    var
        FixedAsset: Record "Fixed Asset";
        FixedAsset2: Record "Fixed Asset";
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        FALocation: Record "FA Location";
        GroupTotals: Option " ","FA Class","FA Subclass","FA Location","Main Asset","Global Dimension 1","Global Dimension 2","FA Posting Group";
        AcquisitionCostAmount: Decimal;
        AcquisitionCostAmount2: Decimal;
        DepreciationCostAmount: Decimal;
        DepreciationCostAmount2: Decimal;
        PostingDate: Date;
    begin
        // Test values on Fixed Asset Book Value 02 Report after running with Group Total as FA Location.

        // 1. Setup: Create Depreciation Book, Create 2 Fixed Assets with Same FA Location Code, Create FA Depreciation Books, Create and
        // Post FA Journal Lines with FA Posting Type Acquisition cost and Depreciation for both Fixed Assets.
        Initialize();
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset2);
        CreateFixedAssetLocation(FALocation);
        UpdateFALocationCode(FixedAsset, FALocation.Code);
        UpdateFALocationCode(FixedAsset2, FALocation.Code);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", '', DepreciationBook.Code);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset2."No.", '', DepreciationBook.Code);

        // Using the Random Number for the Day.
        PostingDate := CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate());
        AcquisitionCostAmount := PostAcquisitionDifferentFA(FixedAsset."No.", FixedAsset2."No.", DepreciationBook.Code, PostingDate);
        AcquisitionCostAmount2 := PostAcquisitionDifferentFA(FixedAsset."No.", FixedAsset2."No.", DepreciationBook.Code, WorkDate());
        DepreciationCostAmount := PostDepreciationDifferentFA(FixedAsset."No.", FixedAsset2."No.", DepreciationBook.Code, PostingDate);
        DepreciationCostAmount2 := PostDepreciationDifferentFA(FixedAsset."No.", FixedAsset2."No.", DepreciationBook.Code, WorkDate());

        // 2. Exercise: Run Fixed Asset Book Value 02 Report with Group Total as FA Location.
        LibraryLowerPermissions.SetO365FAView();
        FixedAsset.SetFilter("No.", '%1|%2', FixedAsset."No.", FixedAsset2."No.");
        RunFixedAssetBookValue02Report(FixedAsset, DepreciationBook.Code, GroupTotals::"FA Location", false, false, false);

        // 3. Verify: Verify values on Fixed Asset Book Value 02 Report.
        VerifyTotalExistenceOnReport(FixedAsset.FieldCaption("FA Location Code"), FALocation.Code);
        VerifyDecimalValuesOnReport(AcquisitionCostAmount, AcquisitionCostAmount2, DepreciationCostAmount, DepreciationCostAmount2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GlobalDimension1BookValue02()
    var
        FixedAsset: Record "Fixed Asset";
        GeneralLedgerSetup: Record "General Ledger Setup";
        DimensionValue: Record "Dimension Value";
        FixedAsset2: Record "Fixed Asset";
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        GroupTotals: Option " ","FA Class","FA Subclass","FA Location","Main Asset","Global Dimension 1","Global Dimension 2","FA Posting Group";
        AcquisitionCostAmount: Decimal;
        AcquisitionCostAmount2: Decimal;
        DepreciationCostAmount: Decimal;
        DepreciationCostAmount2: Decimal;
        PostingDate: Date;
    begin
        // Test values on Fixed Asset Book Value 02 Report after running with Group Total as Global Dimension 1.

        // 1. Setup: Create Depreciation Book, Create 2 Fixed Assets with Same Global Dimension 1 Code, Create FA Depreciation Books, Create
        // and Post FA Journal Lines with FA Posting Type Acquisition cost and Depreciation for both Fixed Assets.
        Initialize();
        GeneralLedgerSetup.Get();
        LibraryDimension.FindDimensionValue(DimensionValue, GeneralLedgerSetup."Global Dimension 1 Code");
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset2);
        UpdateGlobalDimension1Code(FixedAsset, DimensionValue.Code);
        UpdateGlobalDimension1Code(FixedAsset2, DimensionValue.Code);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", '', DepreciationBook.Code);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset2."No.", '', DepreciationBook.Code);

        // Using the Random Number for the Day.
        PostingDate := CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate());
        AcquisitionCostAmount := PostAcquisitionDifferentFA(FixedAsset."No.", FixedAsset2."No.", DepreciationBook.Code, PostingDate);
        AcquisitionCostAmount2 := PostAcquisitionDifferentFA(FixedAsset."No.", FixedAsset2."No.", DepreciationBook.Code, WorkDate());
        DepreciationCostAmount := PostDepreciationDifferentFA(FixedAsset."No.", FixedAsset2."No.", DepreciationBook.Code, PostingDate);
        DepreciationCostAmount2 := PostDepreciationDifferentFA(FixedAsset."No.", FixedAsset2."No.", DepreciationBook.Code, WorkDate());

        // 2. Exercise: Run Fixed Asset Book Value 02 Report with Group Total as Global Dimension 1.
        LibraryLowerPermissions.SetO365FAView();
        FixedAsset.SetFilter("No.", '%1|%2', FixedAsset."No.", FixedAsset2."No.");
        RunFixedAssetBookValue02Report(FixedAsset, DepreciationBook.Code, GroupTotals::"Global Dimension 1", false, false, false);

        // 3. Verify: Verify values on Fixed Asset Book Value 02 Report.
        VerifyTotalExistenceOnReport(FixedAsset.FieldCaption("Global Dimension 1 Code"), DimensionValue.Code);
        VerifyDecimalValuesOnReport(AcquisitionCostAmount, AcquisitionCostAmount2, DepreciationCostAmount, DepreciationCostAmount2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GlobalDimension2BookValue02()
    var
        FixedAsset: Record "Fixed Asset";
        GeneralLedgerSetup: Record "General Ledger Setup";
        DimensionValue: Record "Dimension Value";
        FixedAsset2: Record "Fixed Asset";
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        GroupTotals: Option " ","FA Class","FA Subclass","FA Location","Main Asset","Global Dimension 1","Global Dimension 2","FA Posting Group";
        AcquisitionCostAmount: Decimal;
        AcquisitionCostAmount2: Decimal;
        DepreciationCostAmount: Decimal;
        DepreciationCostAmount2: Decimal;
        PostingDate: Date;
    begin
        // Test values on Fixed Asset Book Value 02 Report after running with Group Total as Global Dimension 2.

        // 1. Setup: Create Depreciation Book, Create 2 Fixed Assets with Same Global Dimension 2 Code, Create FA Depreciation Books, Create
        // and Post FA Journal Lines with FA Posting Type Acquisition cost and Depreciation for both Fixed Assets.
        Initialize();
        GeneralLedgerSetup.Get();
        LibraryDimension.FindDimensionValue(DimensionValue, GeneralLedgerSetup."Global Dimension 2 Code");
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset2);
        UpdateGlobalDimension2Code(FixedAsset, DimensionValue.Code);
        UpdateGlobalDimension2Code(FixedAsset2, DimensionValue.Code);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", '', DepreciationBook.Code);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset2."No.", '', DepreciationBook.Code);

        // Using the Random Number for the Day.
        PostingDate := CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate());
        AcquisitionCostAmount := PostAcquisitionDifferentFA(FixedAsset."No.", FixedAsset2."No.", DepreciationBook.Code, PostingDate);
        AcquisitionCostAmount2 := PostAcquisitionDifferentFA(FixedAsset."No.", FixedAsset2."No.", DepreciationBook.Code, WorkDate());
        DepreciationCostAmount := PostDepreciationDifferentFA(FixedAsset."No.", FixedAsset2."No.", DepreciationBook.Code, PostingDate);
        DepreciationCostAmount2 := PostDepreciationDifferentFA(FixedAsset."No.", FixedAsset2."No.", DepreciationBook.Code, WorkDate());

        // 2. Exercise: Run Fixed Asset Book Value 02 Report with Group Total as Global Dimension 2.
        LibraryLowerPermissions.SetO365FAView();
        FixedAsset.SetFilter("No.", '%1|%2', FixedAsset."No.", FixedAsset2."No.");
        RunFixedAssetBookValue02Report(FixedAsset, DepreciationBook.Code, GroupTotals::"Global Dimension 2", false, false, false);

        // 3. Verify: Verify values on Fixed Asset Book Value 02 Report.
        VerifyTotalExistenceOnReport(FixedAsset.FieldCaption("Global Dimension 2 Code"), DimensionValue.Code);
        VerifyDecimalValuesOnReport(AcquisitionCostAmount, AcquisitionCostAmount2, DepreciationCostAmount, DepreciationCostAmount2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GroupByMainAssetBookValue02()
    var
        FixedAsset: Record "Fixed Asset";
        FixedAsset2: Record "Fixed Asset";
        FixedAsset3: Record "Fixed Asset";
        MainAssetComponent: Record "Main Asset Component";
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        GroupTotals: Option " ","FA Class","FA Subclass","FA Location","Main Asset","Global Dimension 1","Global Dimension 2","FA Posting Group";
        AcquisitionCostAmount: Decimal;
        AcquisitionCostAmount2: Decimal;
        DepreciationCostAmount: Decimal;
        DepreciationCostAmount2: Decimal;
        PostingDate: Date;
    begin
        // Test values on Fixed Asset Book Value 02 Report after running with Group Total as Main Asset.

        // 1. Setup: Create Depreciation Book, Create 3 Fixed Assets, Create Main Asset Components, Create FA Depreciation Books, Create
        // and Post FA Journal Lines with FA Posting Type Acquisition cost and Depreciation for first 2 Fixed Assets.
        Initialize();
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset2);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset3);
        LibraryFixedAsset.CreateMainAssetComponent(MainAssetComponent, FixedAsset3."No.", FixedAsset."No.");
        LibraryFixedAsset.CreateMainAssetComponent(MainAssetComponent, FixedAsset3."No.", FixedAsset2."No.");
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", '', DepreciationBook.Code);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset2."No.", '', DepreciationBook.Code);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset3."No.", '', DepreciationBook.Code);

        // Using the Random Number for the Day.
        PostingDate := CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate());
        AcquisitionCostAmount := PostAcquisitionDifferentFA(FixedAsset."No.", FixedAsset2."No.", DepreciationBook.Code, PostingDate);
        AcquisitionCostAmount2 := PostAcquisitionDifferentFA(FixedAsset."No.", FixedAsset2."No.", DepreciationBook.Code, WorkDate());
        DepreciationCostAmount := PostDepreciationDifferentFA(FixedAsset."No.", FixedAsset2."No.", DepreciationBook.Code, PostingDate);
        DepreciationCostAmount2 := PostDepreciationDifferentFA(FixedAsset."No.", FixedAsset2."No.", DepreciationBook.Code, WorkDate());

        // 2. Exercise: Run Fixed Asset Book Value 02 Report with Group Total as Main Asset.
        LibraryLowerPermissions.SetO365FAView();
        FixedAsset.SetFilter("No.", '%1|%2', FixedAsset."No.", FixedAsset2."No.");
        RunFixedAssetBookValue02Report(FixedAsset, DepreciationBook.Code, GroupTotals::"Main Asset", false, false, false);

        // 3. Verify: Verify values on Fixed Asset Book Value 02 Report.
        VerifyTotalExistenceOnReport(FixedAsset.FieldCaption("Main Asset/Component"), StrSubstNo('Main Asset %1', FixedAsset3."No."));
        VerifyDecimalValuesOnReport(AcquisitionCostAmount, AcquisitionCostAmount2, DepreciationCostAmount, DepreciationCostAmount2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrintDetailsBookValue02()
    var
        FixedAsset: Record "Fixed Asset";
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        FAJournalLine: Record "FA Journal Line";
        GroupTotals: Option " ","FA Class","FA Subclass","FA Location","Main Asset","Global Dimension 1","Global Dimension 2","FA Posting Group";
        AcquisitionCostAmount: Decimal;
        AcquisitionCostAmount2: Decimal;
        DepreciationCostAmount: Decimal;
        DepreciationCostAmount2: Decimal;
        PostingDate: Date;
    begin
        // Test values on Fixed Asset Book Value 02 Report after running with Print Details as True.

        // 1. Setup: Create Depreciation Book, Create Fixed Asset, Create FA Depreciation Book, Create and Post FA Journal Lines with FA
        // Posting Type Acquisition cost and Depreciation for Fixed Asset.
        Initialize();
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", DepreciationBook.Code);

        // Using the Random Number for the Day.
        PostingDate := CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate());
        AcquisitionCostAmount :=
          CreateAndPostFAJournalLine(
            FixedAsset."No.", FAJournalLine."FA Posting Type"::"Acquisition Cost", DepreciationBook.Code, PostingDate);
        AcquisitionCostAmount2 :=
          CreateAndPostFAJournalLine(
            FixedAsset."No.", FAJournalLine."FA Posting Type"::"Acquisition Cost", DepreciationBook.Code, WorkDate());
        DepreciationCostAmount :=
          PostDisposalFAJournalLine(FixedAsset."No.", FAJournalLine."FA Posting Type"::Depreciation, DepreciationBook.Code, PostingDate);
        DepreciationCostAmount2 :=
          PostDisposalFAJournalLine(FixedAsset."No.", FAJournalLine."FA Posting Type"::Depreciation, DepreciationBook.Code, WorkDate());

        // 2. Exercise: Run Fixed Asset Book Value 02 Report with Print Details as True.
        LibraryLowerPermissions.SetO365FAView();
        FixedAsset.SetRange("No.", FixedAsset."No.");
        RunFixedAssetBookValue02Report(FixedAsset, DepreciationBook.Code, GroupTotals::" ", true, false, false);

        // 3. Verify: Verify values on Fixed Asset Book Value 02 Report.
        LibraryReportValidation.OpenFile();
        Assert.IsTrue(LibraryReportValidation.CheckIfValueExists(FixedAsset."No."), StrSubstNo(ExistErr, FixedAsset."No."));
        VerifyDecimalValuesOnReport(AcquisitionCostAmount, AcquisitionCostAmount2, DepreciationCostAmount, DepreciationCostAmount2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReclassifyBookValue02()
    var
        FixedAsset: Record "Fixed Asset";
        FixedAsset2: Record "Fixed Asset";
        GenJournalLine: Record "Gen. Journal Line";
        FADepreciationBook: Record "FA Depreciation Book";
        GroupTotals: Option " ","FA Class","FA Subclass","FA Location","Main Asset","Global Dimension 1","Global Dimension 2","FA Posting Group";
        AcquisitionCostAmount: Decimal;
        DepreciationCostAmount: Decimal;
    begin
        // Test values on Fixed Asset Book Value 02 Report after running with Reclassify as True.

        // 1. Setup: Create 2 Fixed Assets, Create FA Depreciation Books, Create and Post FA G/L Journal Lines with FA Posting Type
        // Acquisition cost and Depreciation for first Fixed Asset, create and Post Reclassify Journal.
        Initialize();
        SetDepreciationBook();
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset2);
        CreateFADepreciationBook(
          FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", LibraryFixedAsset.GetDefaultDeprBook());
        CreateFADepreciationBook(
          FADepreciationBook, FixedAsset2."No.", FixedAsset2."FA Posting Group", LibraryFixedAsset.GetDefaultDeprBook());
        AcquisitionCostAmount := LibraryRandom.RandDec(1000, 2);  // Using Random Number Generator for Amount.
        DepreciationCostAmount := AcquisitionCostAmount / 2;  // using 2 for partial Depreciation Amount.
        CreateAndPostFAGLJournalLine(FixedAsset."No.", GenJournalLine."FA Posting Type"::"Acquisition Cost", AcquisitionCostAmount);
        CreateAndPostFAGLJournalLine(FixedAsset."No.", GenJournalLine."FA Posting Type"::Depreciation, -DepreciationCostAmount);

        CreateAndPostFAReclassJournal(LibraryFixedAsset.GetDefaultDeprBook(), FixedAsset."No.", FixedAsset2."No.");

        // 2. Exercise: Run Fixed Asset Book Value 02 Report with Reclassify as True.
        LibraryLowerPermissions.SetO365FAView();
        LibraryLowerPermissions.AddJournalsEdit();
        FixedAsset.SetFilter("No.", '%1|%2', FixedAsset."No.", FixedAsset2."No.");
        RunFixedAssetBookValue02Report(FixedAsset, LibraryFixedAsset.GetDefaultDeprBook(), GroupTotals::" ", true, false, true);

        // 3. Verify: Verify values on Fixed Asset Book Value 02 Report.
        LibraryReportValidation.OpenFile();
        Assert.IsTrue(LibraryReportValidation.CheckIfValueExists(ReclassifyTxt), StrSubstNo(ExistErr, ReclassifyTxt));
        Assert.IsTrue(
          LibraryReportValidation.CheckIfValueExists(Format(-AcquisitionCostAmount, 0, '<Precision,2><Standard Format,0>')),
          StrSubstNo(ExistErr, -AcquisitionCostAmount));
        Assert.IsTrue(
          LibraryReportValidation.CheckIfValueExists(Format(DepreciationCostAmount, 0, '<Precision,2><Standard Format,0>')),
          StrSubstNo(ExistErr, DepreciationCostAmount));
        LibraryFixedAsset.VerifyLastFARegisterGLRegisterOneToOneRelation(); // TFS 376879
    end;

    [Test]
    [HandlerFunctions('FixedAssetBookValue02ReportHandler')]
    [Scope('OnPrem')]
    procedure DisposalBookValue02()
    var
        FixedAsset: Record "Fixed Asset";
        GenJournalLine: Record "Gen. Journal Line";
        FADepreciationBook: Record "FA Depreciation Book";
        AcquisitionCostAmount: Decimal;
        DepreciationCostAmount: Decimal;
        OldGainOnDisposalAcc: Code[20];
    begin
        // Test values on Fixed Asset Book Value 02 Report after doing disposal of the fixed asset.

        // 1. Setup: Create Fixed Asset,FA Depreciation Books,Create and Post FA G/L Journal Lines with different FA Posting Type
        Initialize();
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", LibraryFixedAsset.GetDefaultDeprBook());
        UpdateGainAccOnDisposal(OldGainOnDisposalAcc, FixedAsset."FA Posting Group");
        LibraryVariableStorage.Enqueue(LibraryFixedAsset.GetDefaultDeprBook());
        AcquisitionCostAmount := LibraryRandom.RandDec(1000, 2);
        DepreciationCostAmount := AcquisitionCostAmount / LibraryRandom.RandIntInRange(2, 4);
        CreateAndPostFAGLJournalLine(FixedAsset."No.", GenJournalLine."FA Posting Type"::"Acquisition Cost", AcquisitionCostAmount);
        CreateAndPostFAGLJournalLine(FixedAsset."No.", GenJournalLine."FA Posting Type"::Depreciation, -1 * DepreciationCostAmount);
        CreateAndPostFAGLJournalLine(
          FixedAsset."No.", GenJournalLine."FA Posting Type"::Disposal, -1 * LibraryRandom.RandDec(1000, 2));

        // 2. Exercise: Run report Fixed Asset Book Value 02.
        LibraryLowerPermissions.SetO365FAView();
        FixedAsset.SetFilter("No.", FixedAsset."No.");
        REPORT.Run(REPORT::"Fixed Asset - Book Value 02", true, false, FixedAsset);

        // 3. Verify: Verify values on Fixed Asset Book Value 02 report that sign gets reversed for Acquisition cost and Depriciation after doing disposal.
        LibraryReportValidation.DownloadFile();
        LibraryReportValidation.OpenFile();
        Assert.IsTrue(
          LibraryReportValidation.CheckIfValueExists(Format(-1 * AcquisitionCostAmount, 0, '<Precision,2><Standard Format,0>')),
          StrSubstNo(ExistErr, -1 * AcquisitionCostAmount));
        Assert.IsTrue(
          LibraryReportValidation.CheckIfValueExists(Format(DepreciationCostAmount, 0, '<Precision,2><Standard Format,0>')),
          StrSubstNo(ExistErr, DepreciationCostAmount));

        // 4. Tear Down: Restore the value of FA Group Gain on Disposal Acc.
        LibraryLowerPermissions.SetO365Full();
        RestoreGainAccOnDisposal(FixedAsset."FA Posting Group", OldGainOnDisposalAcc);
    end;

    [Test]
    [HandlerFunctions('FixedAssetListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure FixedAssetListReportDepreciationEndingDate()
    var
        FADepreciationBook: Record "FA Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        DepreciationBook: Record "Depreciation Book";
    begin
        // [FEATURE] [Fixed Asset - List]
        // [SCENARIO 378065] "Depreciation Ending date" of Deprciation Book should be printed in "Fixed Assets - list" report

        Initialize();

        // [GIVEN] Depreciation Book having "Fiscal Year 365 Days" = True and "Depreciation Ending date" = 31.12.17
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateDepreciationJournalSetup(DepreciationBook);
        DepreciationBook.Validate("Fiscal Year 365 Days", true);
        DepreciationBook.Modify(true);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", DepreciationBook.Code);
        FADepreciationBook.Validate("Depreciation Ending Date", WorkDate() + 1);
        FADepreciationBook.Modify(true);

        // [WHEN] Running "Fixed Asset - List" report
        LibraryLowerPermissions.SetO365FAView();
        LibraryVariableStorage.Enqueue(FADepreciationBook."Depreciation Book Code");
        LibraryVariableStorage.Enqueue(FixedAsset."No.");
        Commit();
        REPORT.Run(REPORT::"Fixed Asset - List");

        // [THEN] "Fixed Asset - List" report contains "Depreciation Ending date" (31.12.17)
        LibraryReportValidation.DownloadFile();
        LibraryReportValidation.OpenFile();
        LibraryReportValidation.VerifyCellValueByRef('B', 27, 1, Format(WorkDate() + 1));
    end;

    [Test]
    procedure FAReclassificationRespectsDepreciationRounding()
    var
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        FAJournalSetup: Record "FA Journal Setup";
        FAReclassJournalBatch: Record "FA Reclass. Journal Batch";
        FAReclassJournalLine: Record "FA Reclass. Journal Line";
        FASetup: Record "FA Setup";
        FixedAsset2: Record "Fixed Asset";
        FixedAsset: Record "Fixed Asset";
        GenJournalLine: Record "Gen. Journal Line";
        DepreciationCalculation: Codeunit "Depreciation Calculation";
        AcquisitionCostAmount: Decimal;
        DepreciationCostAmount: Decimal;
    begin
        // [SCENARIO 614879] Depreciation amounts during FA reclassification should respect the rounding settings defined in the Depreciation Book
        Initialize();

        // [GIVEN] Depreciation Book having "Use Rounding in Periodic Depr." = True.
        FASetup.Get();
        DepreciationBook.Get(FASetup."Default Depr. Book");
        DepreciationBook.Validate("Use Rounding in Periodic Depr.", true);
        DepreciationBook.Modify();

        // [GIVEN] Two Fixed Assets with FA Depreciation Books, FA G/L Journal Lines posted with FA Posting Type Acquisition cost and Depreciation for first Fixed Asset.
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset2);

        // [GIVEN] FA Depreciation Books created for Fixed Assets "A".
        CreateFADepreciationBook(
            FADepreciationBook,
            FixedAsset."No.",
            FixedAsset."FA Posting Group",
            LibraryFixedAsset.GetDefaultDeprBook());

        // [GIVEN] FA Depreciation Books created for Fixed Assets "B".
        CreateFADepreciationBook(
            FADepreciationBook,
            FixedAsset2."No.",
            FixedAsset2."FA Posting Group",
            LibraryFixedAsset.GetDefaultDeprBook());

        // [GIVEN] FA G/L Journal Lines posted with FA Posting Type Acquisition cost and Depreciation for Fixed Asset "A".
        AcquisitionCostAmount := LibraryRandom.RandDec(1000, 2);
        DepreciationCostAmount := AcquisitionCostAmount / 2;
        CreateAndPostFAGLJournalLine(FixedAsset."No.", GenJournalLine."FA Posting Type"::"Acquisition Cost", AcquisitionCostAmount);
        CreateAndPostFAGLJournalLine(FixedAsset."No.", GenJournalLine."FA Posting Type"::Depreciation, -DepreciationCostAmount);

        // [GIVEN] Create Reclassification Journal is created and posted from Fixed Asset "A" to Fixed Asset "B".
        CreateFAReclassJournalBatch(FAReclassJournalBatch);

        // [GIVEN] FA Reclassification Journal is created and posted from Fixed Asset "A" to Fixed Asset "B".
        LibraryFixedAsset.CreateFAReclassJournal(
            FAReclassJournalLine,
            FAReclassJournalBatch."Journal Template Name",
            FAReclassJournalBatch.Name);

        // [GIVEN] Depreciation Cost Amount is rounded as per Depreciation Book Rounding Setup.
        DepreciationCostAmount := DepreciationCalculation.CalcRounding(DepreciationBook.Code, DepreciationCostAmount);

        // [WHEN] FA Reclassification Journal is posted.
        UpdateFAReclassJournal(FAReclassJournalLine, FixedAsset."No.", FixedAsset2."No.");
        CODEUNIT.Run(CODEUNIT::"FA Reclass. Transfer Batch", FAReclassJournalLine);

        // [THEN] General Journal Lines are created for both Fixed Assets with correct rounded Depreciation Amounts.
        FAJournalSetup.SetRange("Depreciation Book Code", DepreciationBook.Code);
        FAJournalSetup.FindFirst();
        GenJournalLine.SetRange("Journal Template Name", FAJournalSetup."Gen. Jnl. Template Name");
        GenJournalLine.SetRange("Journal Batch Name", FAJournalSetup."Gen. Jnl. Batch Name");
        GenJournalLine.SetRange(Amount, DepreciationCostAmount);
        GenJournalLine.FindFirst();
        Assert.RecordIsNotEmpty(GenJournalLine);
    end;

    local procedure Initialize()
    var
        DimValue: Record "Dimension Value";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Fixed Assets Reports");
        LibraryVariableStorage.Clear();
        Clear(LibraryReportValidation);
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Fixed Assets Reports");

        // Trigger update of global dimension setup in general ledger
        LibraryDimension.GetGlobalDimCodeValue(1, DimValue);
        LibraryDimension.GetGlobalDimCodeValue(2, DimValue);

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Fixed Assets Reports");
    end;

    local procedure AttachFAPostingGroup(FixedAsset: Record "Fixed Asset"; FAPostingGroup: Code[20])
    begin
        FixedAsset.Validate("FA Posting Group", FAPostingGroup);
        FixedAsset.Modify(true);
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

    local procedure CreateFixedAssetClass(var FAClass: Record "FA Class")
    begin
        LibraryFixedAsset.FindFAClass(FAClass);
        FAClass.Validate(
          Code,
          CopyStr(
            LibraryUtility.GenerateRandomCode(FAClass.FieldNo(Code), DATABASE::"FA Class"), 1,
            LibraryUtility.GetFieldLength(DATABASE::"FA Class", FAClass.FieldNo(Code))));
        FAClass.Insert();
    end;

    local procedure CreateFixedAssetLocation(var FALocation: Record "FA Location")
    begin
        LibraryFixedAsset.FindFALocation(FALocation);
        FALocation.Validate(
          Code,
          CopyStr(
            LibraryUtility.GenerateRandomCode(FALocation.FieldNo(Code), DATABASE::"FA Location"), 1,
            LibraryUtility.GetFieldLength(DATABASE::"FA Location", FALocation.FieldNo(Code))));
        FALocation.Insert();
    end;

    local procedure CreateFADepreciationBook(var FADepreciationBook: Record "FA Depreciation Book"; FANo: Code[20]; FAPostingGroup: Code[20]; DepreciationBookCode: Code[10])
    begin
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FANo, DepreciationBookCode);
        FADepreciationBook.Validate("FA Posting Group", FAPostingGroup);
        FADepreciationBook.Validate("Depreciation Starting Date", WorkDate());

        // Depreciation Ending Date greater than Depreciation Starting Date, Using the Random Number for the Year.
        FADepreciationBook.Validate("Depreciation Ending Date", CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'Y>', WorkDate()));
        FADepreciationBook.Modify(true);
    end;

    local procedure CreateDepreciationJournalSetup(var DepreciationBook: Record "Depreciation Book")
    var
        FAJournalSetup: Record "FA Journal Setup";
    begin
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        LibraryFixedAsset.CreateFAJournalSetup(FAJournalSetup, DepreciationBook.Code, '');
        UpdateFAJournalSetup(FAJournalSetup);
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
        FAJournalLine.Validate(Amount, LibraryRandom.RandDec(1000, 2));  // Using Random Number Generator for Amount.
        FAJournalLine.Validate("Depreciation Book Code", DepreciationBookCode);
        FAJournalLine.Modify(true);
    end;

    local procedure CreateAndPostFAGLJournalLine(FANo: Code[20]; FAPostingType: Enum "Gen. Journal Line FA Posting Type"; Amount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGeneralJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"Fixed Asset", FANo, Amount);
        PostingSetupFAGLJournalLine(GenJournalLine, FAPostingType);
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

    local procedure CreateAndPostFAReclassJournal(DepreciationBookCode: Code[10]; FixedAssetNo: Code[20]; FixedAssetNo2: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
        FAReclassJournalLine: Record "FA Reclass. Journal Line";
        FAReclassJournalBatch: Record "FA Reclass. Journal Batch";
    begin
        CreateFAReclassJournalBatch(FAReclassJournalBatch);
        LibraryFixedAsset.CreateFAReclassJournal(
          FAReclassJournalLine, FAReclassJournalBatch."Journal Template Name", FAReclassJournalBatch.Name);
        UpdateFAReclassJournal(FAReclassJournalLine, FixedAssetNo, FixedAssetNo2);
        CODEUNIT.Run(CODEUNIT::"FA Reclass. Transfer Batch", FAReclassJournalLine);

        UpdateDocumentNo(GenJournalLine, DepreciationBookCode);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateFAJournalBatch(var FAJournalBatch: Record "FA Journal Batch")
    var
        FAJournalTemplate: Record "FA Journal Template";
    begin
        FAJournalTemplate.SetRange(Recurring, false);
        LibraryFixedAsset.FindFAJournalTemplate(FAJournalTemplate);
        LibraryFixedAsset.CreateFAJournalBatch(FAJournalBatch, FAJournalTemplate.Name);
    end;

    local procedure CreateFAReclassJournalBatch(var FAReclassJournalBatch: Record "FA Reclass. Journal Batch")
    var
        FAReclassJournalTemplate: Record "FA Reclass. Journal Template";
    begin
        FAReclassJournalTemplate.FindFirst();
        LibraryFixedAsset.CreateFAReclassJournalBatch(FAReclassJournalBatch, FAReclassJournalTemplate.Name);
    end;

    local procedure FindDisposalAmount(FANo: Code[20]): Decimal
    var
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        FALedgerEntry.SetRange("FA No.", FANo);
        FALedgerEntry.SetRange("FA Posting Category", FALedgerEntry."FA Posting Category"::Disposal);
        FALedgerEntry.SetRange("FA Posting Type", FALedgerEntry."FA Posting Type"::Depreciation);
        FALedgerEntry.FindFirst();
        exit(FALedgerEntry.Amount);
    end;

    local procedure PostAcquisitionDifferentFA(FixedAssetNo: Code[20]; FixedAssetNo2: Code[20]; DepreciationBookCode: Code[10]; PostingDate: Date): Decimal
    var
        FAJournalLine: Record "FA Journal Line";
    begin
        exit(
          CreateAndPostFAJournalLine(FixedAssetNo, FAJournalLine."FA Posting Type"::"Acquisition Cost", DepreciationBookCode, PostingDate) +
          CreateAndPostFAJournalLine(
            FixedAssetNo2, FAJournalLine."FA Posting Type"::"Acquisition Cost", DepreciationBookCode, PostingDate));
    end;

    local procedure PostDepreciationDifferentFA(FixedAssetNo: Code[20]; FixedAssetNo2: Code[20]; DepreciationBookCode: Code[10]; PostingDate: Date): Decimal
    var
        FAJournalLine: Record "FA Journal Line";
    begin
        exit(
          PostDisposalFAJournalLine(FixedAssetNo, FAJournalLine."FA Posting Type"::Depreciation, DepreciationBookCode, PostingDate) +
          PostDisposalFAJournalLine(FixedAssetNo2, FAJournalLine."FA Posting Type"::Depreciation, DepreciationBookCode, PostingDate));
    end;

    local procedure PostDisposalDifferentFA(FixedAssetNo: Code[20]; FixedAssetNo2: Code[20]; DepreciationBookCode: Code[10]; PostingDate: Date)
    var
        FAJournalLine: Record "FA Journal Line";
    begin
        PostDisposalFAJournalLine(FixedAssetNo, FAJournalLine."FA Posting Type"::Disposal, DepreciationBookCode, PostingDate);
        PostDisposalFAJournalLine(FixedAssetNo2, FAJournalLine."FA Posting Type"::Disposal, DepreciationBookCode, PostingDate);
    end;

    local procedure PostDisposalFAJournalLine(FixedAssetNo: Code[20]; FAPostingType: Enum "FA Journal Line FA Posting Type"; DepreciationBookCode: Code[10]; PostingDate: Date) FAJournalLineAmount: Decimal
    var
        FAJournalLine: Record "FA Journal Line";
    begin
        CreateFAJournalLine(
          FAJournalLine, FixedAssetNo, DepreciationBookCode, FAPostingType, PostingDate);
        FAJournalLine.Validate(Amount, -LibraryRandom.RandDec(10, 2));  // Using Random Number Generator for Amount.
        FAJournalLine.Modify(true);
        FAJournalLineAmount := FAJournalLine.Amount;
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);
    end;

    local procedure PostingSetupFAGLJournalLine(var GenJournalLine: Record "Gen. Journal Line"; FAPostingType: Enum "Gen. Journal Line FA Posting Type")
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.SetFilter("Gen. Posting Type", '<>%1', GLAccount."Gen. Posting Type"::" ");
        LibraryERM.FindGLAccount(GLAccount);
        GenJournalLine.Validate("Document No.", GenJournalLine."Account No.");
        GenJournalLine.Validate("FA Posting Type", FAPostingType);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", GLAccount."No.");
        GenJournalLine.Modify(true);
    end;

    local procedure RunFixedAssetBookValue01Report(FixedAsset: Record "Fixed Asset"; DepreciationBookCode: Code[10]; GroupTotals: Option; PrintTotal: Boolean; BudgetReport: Boolean)
    var
        FixedAssetBookValue01: Report "Fixed Asset - Book Value 01";
    begin
        Clear(FixedAssetBookValue01);
        FixedAssetBookValue01.SetTableView(FixedAsset);
        FixedAssetBookValue01.UseRequestPage(false);
        FixedAssetBookValue01.SetMandatoryFields(DepreciationBookCode, WorkDate(), WorkDate());
        FixedAssetBookValue01.SetTotalFields(GroupTotals, PrintTotal, BudgetReport);
        LibraryReportValidation.SetFileName(CreateGuid());
        FixedAssetBookValue01.SaveAsExcel(LibraryReportValidation.GetFileName());
        LibraryReportValidation.DownloadFile();
    end;

    local procedure RunFixedAssetBookValue02Report(var FixedAsset: Record "Fixed Asset"; DepreciationBookCode: Code[10]; GroupTotals: Option; PrintTotal: Boolean; BudgetReport: Boolean; Reclassify: Boolean)
    var
        FixedAssetBookValue02: Report "Fixed Asset - Book Value 02";
    begin
        Clear(FixedAssetBookValue02);
        FixedAssetBookValue02.SetTableView(FixedAsset);
        FixedAssetBookValue02.UseRequestPage(false);
        FixedAssetBookValue02.SetMandatoryFields(DepreciationBookCode, WorkDate(), WorkDate());
        FixedAssetBookValue02.SetTotalFields(GroupTotals, PrintTotal, BudgetReport, Reclassify);
        LibraryReportValidation.SetFileName(CreateGuid());
        FixedAssetBookValue02.SaveAsExcel(LibraryReportValidation.GetFileName());
        LibraryReportValidation.DownloadFile();
    end;

    local procedure RestoreGainAccOnDisposal(FAPostingGroupCode: Code[20]; GainAccOnDisposal: Code[20])
    var
        FAPostingGroup: Record "FA Posting Group";
    begin
        FAPostingGroup.Get(FAPostingGroupCode);
        FAPostingGroup.Validate("Gains Acc. on Disposal", GainAccOnDisposal);
        FAPostingGroup.Modify(true);
    end;

    local procedure UpdateCustom1Depreciation(var DepreciationBook: Record "Depreciation Book")
    begin
        DepreciationBook.Validate("Use Custom 1 Depreciation", true);
        DepreciationBook.Modify(true);
    end;

    local procedure UpdateDocumentNo(var GenJournalLine: Record "Gen. Journal Line"; DepreciationBookCode: Code[10])
    var
        FAJournalSetup: Record "FA Journal Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
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

    local procedure UpdateFAJournalSetup(var FAJournalSetup: Record "FA Journal Setup")
    var
        FAJournalSetup2: Record "FA Journal Setup";
    begin
        FAJournalSetup2.SetRange("Depreciation Book Code", LibraryFixedAsset.GetDefaultDeprBook());
        FAJournalSetup2.FindFirst();
        FAJournalSetup.TransferFields(FAJournalSetup2, false);
        FAJournalSetup.Modify(true);
    end;

    local procedure UpdateFAReclassJournal(var FAReclassJournalLine: Record "FA Reclass. Journal Line"; FANo: Code[20]; NewFANo: Code[20])
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
        FAReclassJournalLine.Validate("Reclassify Acq. Cost %", 100);  // Using 100 for Reclassify - required for test case.
        FAReclassJournalLine.Validate("Reclassify Acquisition Cost", true);
        FAReclassJournalLine.Validate("Reclassify Depreciation", true);
        FAReclassJournalLine.Modify(true);
    end;

    local procedure UpdateFASubClassCode(FixedAsset: Record "Fixed Asset"; FASubClassCode: Code[10])
    begin
        FixedAsset.Validate("FA Subclass Code", FASubClassCode);
        FixedAsset.Modify(true);
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

    local procedure UpdateGainAccOnDisposal(var OldGainAccOnDisposal: Code[20]; FAPostingGroupCode: Code[20])
    var
        FAPostingGroup: Record "FA Posting Group";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.FindGLAccount(GLAccount);
        FAPostingGroup.Get(FAPostingGroupCode);
        OldGainAccOnDisposal := FAPostingGroup."Gains Acc. on Disposal";
        RestoreGainAccOnDisposal(FAPostingGroup.Code, GLAccount."No.");
    end;

    local procedure VerifyBookValue(ExpectedAmount: Decimal; ColumnCaption: Text[250])
    var
        ActualAmount: Decimal;
    begin
        LibraryReportValidation.SetColumn(ColumnCaption);
        Evaluate(ActualAmount, LibraryReportValidation.GetValue());
        Assert.AreEqual(ExpectedAmount, ActualAmount, StrSubstNo(ValueMismatchErr, ColumnCaption, ExpectedAmount));
    end;

    local procedure VerifyDecimalValuesOnReport(Amount: Decimal; Amount2: Decimal; DepreciationAmount: Decimal; DepreciationAmount2: Decimal)
    begin
        Assert.IsTrue(
          LibraryReportValidation.CheckIfDecimalValueExists(Amount), StrSubstNo(ExistErr, Amount));
        Assert.IsTrue(
          LibraryReportValidation.CheckIfDecimalValueExists(Amount2),
          StrSubstNo(ExistErr, Amount2));
        Assert.IsTrue(
          LibraryReportValidation.CheckIfDecimalValueExists(Amount + Amount2),
          StrSubstNo(ExistErr, Amount + Amount2));
        Assert.IsTrue(
          LibraryReportValidation.CheckIfDecimalValueExists(DepreciationAmount),
          StrSubstNo(ExistErr, DepreciationAmount));
        Assert.IsTrue(
          LibraryReportValidation.CheckIfDecimalValueExists(DepreciationAmount2),
          StrSubstNo(ExistErr, DepreciationAmount2));
        Assert.IsTrue(
          LibraryReportValidation.CheckIfDecimalValueExists(DepreciationAmount + DepreciationAmount2),
          StrSubstNo(ExistErr, DepreciationAmount + DepreciationAmount2));
    end;

    local procedure VerifyFixedAssetBookValue(AcquisitionCostAmount: Decimal; AcquisitionCostAmount2: Decimal; DepreciationCostAmount: Decimal; DepreciationCostAmount2: Decimal)
    begin
        VerifyBookValue(AcquisitionCostAmount2, AdditionInPeriodTxt);
        VerifyBookValue(-AcquisitionCostAmount - AcquisitionCostAmount2, DisposalInPeriodTxt);
        VerifyBookValue(DepreciationCostAmount2, DepreciationInPeriodTxt);

        // Use 1 because it used as in Report for creating Header Line.
        VerifyBookValue(AcquisitionCostAmount, AcquisitionCostTxt + ' ' + Format(CalcDate('<-1D>', WorkDate())));
        VerifyBookValue(DepreciationCostAmount, StrSubstNo(DepreciationTxt, CalcDate('<-1D>', WorkDate())));
        VerifyBookValue(AcquisitionCostAmount + DepreciationCostAmount, BookValueTxt + ' ' + Format(CalcDate('<-1D>', WorkDate())));
    end;

    local procedure VerifyTotalExistenceOnReport(FieldCaption: Text[30]; FieldValue: Text[50])
    begin
        LibraryReportValidation.OpenFile();
        Assert.IsTrue(
          LibraryReportValidation.CheckIfValueExists(StrSubstNo(GroupTotalsTxt, FieldCaption)), StrSubstNo(ExistErr, FieldCaption));
        Assert.IsTrue(LibraryReportValidation.CheckIfValueExists(GroupTotalTxt + ' ' + FieldValue), StrSubstNo(ExistErr, FieldValue));
    end;

    local procedure SetDepreciationBook()
    var
        DepreciationBook: Record "Depreciation Book";
        FASetup: Record "FA Setup";
    begin
        FASetup.Get();
        DepreciationBook.Get(FASetup."Default Depr. Book");
        DepreciationBook.Validate("Use Rounding in Periodic Depr.", false);
        DepreciationBook.Modify();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure FixedAssetBookValue02ReportHandler(var FixedAssetBookValue02: TestRequestPage "Fixed Asset - Book Value 02")
    var
        DepriciationBookCode: Text;
    begin
        DepriciationBookCode := LibraryVariableStorage.DequeueText();
        FixedAssetBookValue02.DeprBookCode.SetValue(DepriciationBookCode);
        FixedAssetBookValue02.StartingDate.SetValue(WorkDate());
        FixedAssetBookValue02.EndingDate.SetValue(WorkDate());
        LibraryReportValidation.SetFileName(CreateGuid());
        FixedAssetBookValue02.SaveAsExcel(LibraryReportValidation.GetFileName());
        Sleep(200);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure FixedAssetListRequestPageHandler(var FixedAssetList: TestRequestPage "Fixed Asset - List")
    begin
        FixedAssetList.DeprBookCode.SetValue(LibraryVariableStorage.DequeueText());  // Setting Depreciation Book Code.
        FixedAssetList."Fixed Asset".SetFilter("No.", LibraryVariableStorage.DequeueText());
        LibraryReportValidation.SetFileName(CreateGuid());
        FixedAssetList.SaveAsExcel(LibraryReportValidation.GetFileName());
        Sleep(200);
    end;
}

