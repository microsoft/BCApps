codeunit 148087 "Fixed Assets CZF"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    var
        Assert: Codeunit Assert;
        LibraryDialogHandler: Codeunit "Library - Dialog Handler";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryFixedAssetCZF: Codeunit "Library - Fixed Asset CZF";
        LibraryHumanResource: Codeunit "Library - Human Resource";
        LibraryRandom: Codeunit "Library - Random";
        isInitialized: Boolean;
        DepreciationGroupFilterErr: Label 'Depreciation Group Filter is not set.';
        ChangeCalculationQst: Label 'Changing this setting changes the way new depreciation is calculated. Do you really want to make the change?';

    local procedure Initialize()
    var
        FAJournalTemplate: Record "FA Journal Template";
        FAJournalBatch: Record "FA Journal Batch";
        FAJournalSetup: Record "FA Journal Setup";
        DepreciationBook: Record "Depreciation Book";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Fixed Assets CZF");
        LibraryVariableStorage.Clear();
        LibraryDialogHandler.ClearVariableStorage();
        if isInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Fixed Assets CZF");

        CreateDepreciationBook(DepreciationBook);
        CreateFAJournalTemplate(FAJournalTemplate);
        CreateFAJournalBatch(FAJournalBatch, FAJournalTemplate.Name);
        CreateFAJournalSetup(
          FAJournalSetup, DepreciationBook.Code,
          FAJournalBatch."Journal Template Name", FAJournalBatch.Name);
        UpdateFASetup(DepreciationBook.Code);
        UpdateHumanResourcesSetup();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Fixed Assets CZF");
    end;

    [Test]
    [HandlerFunctions('NoConfirmHandler')]
    procedure CalculateDepreciationStraightLine()
    begin
        // [SCENARIO] Test the Posting of Calculated Depreciation with use Depreciation Group of Straight-line type
        CalculateDepreciation(Enum::"Tax Depreciation Type CZF"::"Straight-line");
    end;

    [Test]
    [HandlerFunctions('NoConfirmHandler')]
    procedure CalculateDepreciationDecliningBalance()
    begin
        // [SCENARIO] Test the Posting of Calculated Depreciation with use Depreciation Group of Declining-Balance type
        CalculateDepreciation(Enum::"Tax Depreciation Type CZF"::"Declining-Balance");
    end;

    [Test]
    [HandlerFunctions('NoConfirmHandler')]
    procedure CalculateDepreciationStraightLineIntangible()
    begin
        // [SCENARIO] Test the Posting of Calculated Depreciation with use Depreciation Group of Straight-line Intangible type
        CalculateDepreciation(Enum::"Tax Depreciation Type CZF"::"Straight-line Intangible");
    end;

    [HandlerFunctions('NoConfirmHandler')]
    local procedure CalculateDepreciation(TaxDepreciationTypeCZF: Enum "Tax Depreciation Type CZF")
    var
        FixedAsset: Record "Fixed Asset";
        FASetup: Record "FA Setup";
        FADepreciationBook: Record "FA Depreciation Book";
        TaxDepreciationGroupCZF: Record "Tax Depreciation Group CZF";
        FAJournalLine: Record "FA Journal Line";
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        Initialize();

        // [GIVEN] The FA Setup has been got
        FASetup.Get();

        // [GIVEN] The Fixed Asset and FA Depreciation Book have been created
        CreateFixedAsset(FixedAsset);
        CreateTaxDepreciationGroupCZF(TaxDepreciationGroupCZF, TaxDepreciationTypeCZF);
        CreateFADepreciationBook(
          FADepreciationBook, FixedAsset."No.",
          FASetup."Tax Depreciation Book CZF", TaxDepreciationGroupCZF.Code, true,
          FADepreciationBook."Depreciation Method"::"Straight-Line");
        if TaxDepreciationTypeCZF = TaxDepreciationGroupCZF."Depreciation Type"::"Straight-line Intangible" then begin
            FADepreciationBook.Validate("No. of Depreciation Years", 3);
            FADepreciationBook.Modify(true);
        end;

        // [GIVEN] The FA Journal Line has been created
        CreateFAJournalLine(
          FAJournalLine, FASetup."Tax Depreciation Book CZF",
          FAJournalLine."FA Posting Type"::"Acquisition Cost", FixedAsset."No.");

        // [GIVEN] The FA Journal Line for Acquisition Cost has been posted
        PostFAJournalLine(FAJournalLine);

        // [GIVEN] The Calculate Depreciation has been executed
        RunCalculateDepreciation(FixedAsset, FASetup."Tax Depreciation Book CZF");

        // [WHEN] Post FA Journal Line for Depreciation
        PostDepreciationWithDocumentNo(FASetup."Tax Depreciation Book CZF");

        // [THEN] FA Ledger Entry for Depreciation will be created
        FALedgerEntry.SetCurrentKey("FA No.", "Depreciation Book Code");
        FALedgerEntry.SetRange("FA No.", FixedAsset."No.");
        FALedgerEntry.SetRange("Depreciation Book Code", FASetup."Tax Depreciation Book CZF");
        FALedgerEntry.SetRange("FA Posting Type", FALedgerEntry."FA Posting Type"::Depreciation);
        Assert.RecordIsNotEmpty(FALedgerEntry);
    end;

    [Test]
    [HandlerFunctions('NoConfirmHandler')]
    procedure CalculateDepreciationWithInterruption()
    var
        FixedAsset: Record "Fixed Asset";
        FASetup: Record "FA Setup";
        FADepreciationBook: Record "FA Depreciation Book";
        TaxDepreciationGroupCZF: Record "Tax Depreciation Group CZF";
        FAJournalLine: Record "FA Journal Line";
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        // [SCENARIO] Test the Posting of Calculated Depreciation with use Depreciation Group of Straight-line type with Interruption
        Initialize();

        // [GIVEN] The FA Setup has been got
        FASetup.Get();

        // [GIVEN] The Fixed Asset and FA Depreciation Book have been created
        CreateFixedAsset(FixedAsset);
        CreateTaxDepreciationGroupCZF(TaxDepreciationGroupCZF, TaxDepreciationGroupCZF."Depreciation Type"::"Straight-line");
        CreateFADepreciationBook(
          FADepreciationBook, FixedAsset."No.",
          FASetup."Tax Depreciation Book CZF", TaxDepreciationGroupCZF.Code, true,
          FADepreciationBook."Depreciation Method"::"Straight-Line");
        FADepreciationBook.Validate("No. of Depreciation Years", 3);
        FADepreciationBook.Modify(true);

        // [GIVEN] The FA Journal Line has been created
        CreateFAJournalLine(
          FAJournalLine, FASetup."Tax Depreciation Book CZF",
          FAJournalLine."FA Posting Type"::"Acquisition Cost", FixedAsset."No.");

        // [GIVEN] The FA Journal Line for Acquisition Cost has been posted
        PostFAJournalLine(FAJournalLine);

        // [GIVEN] The depreciation interruption has been setup
        FADepreciationBook.Find();
        FADepreciationBook.Validate("Deprec. Interrupted up to CZF", CalcDate('<-CY+1Y>', WorkDate()));
        FADepreciationBook.Modify(true);

        // [GIVEN] The Calculate Depreciation has been executed
        RunCalculateDepreciation(FixedAsset, FASetup."Tax Depreciation Book CZF");

        // [WHEN] Post FA Journal Line for Depreciation
        PostDepreciationWithDocumentNo(FASetup."Tax Depreciation Book CZF");

        // [THEN] The FA Ledger Entry for Depreciation with interruption will be created
        FALedgerEntry.SetCurrentKey("FA No.", "Depreciation Book Code");
        FALedgerEntry.SetRange("FA No.", FixedAsset."No.");
        FALedgerEntry.SetRange("Depreciation Book Code", FASetup."Tax Depreciation Book CZF");
        FALedgerEntry.SetRange("FA Posting Type", FALedgerEntry."FA Posting Type"::Depreciation);
        FALedgerEntry.FindFirst();
        FALedgerEntry.TestField(Amount, 0);
    end;

    [Test]
    [HandlerFunctions('ModalCreateFAHistoryHandler,NoConfirmHandler')]
    procedure LoggingFixedAssetChanges()
    var
        FixedAsset: Record "Fixed Asset";
        Employee: Record Employee;
        FALocation: Record "FA Location";
        FAHistoryEntry: Record "FA History Entry CZF";
        FixedAssetCard: TestPage "Fixed Asset Card";
    begin
        // [SCENARIO] Verify that change of Responsible Employee or FA Location Code on the Fixed Asset Card will cause creation FA HIstory Entry
        Initialize();

        // [GIVEN] The FA History has been enabled in FA Setup
        UpdateFASetupWithFAHistory(true);

        // [GIVEN] The Employee has been created
        CreateEmployee(Employee);

        // [GIVEN] The FA Location has been created
        CreateFALocation(FALocation);

        // [GIVEN] The Fixed Asset has been created
        CreateFixedAsset(FixedAsset);

        // [WHEN] Validate "Responsible Employee" and "FA Location Code" fields on Fixed Asset Card
        FixedAssetCard.OpenEdit();
        FixedAssetCard.GoToRecord(FixedAsset);
        FixedAssetCard."Responsible Employee".SetValue(Employee."No.");
        FixedAssetCard."FA Location Code".SetValue(FALocation.Code);
        FixedAssetCard.OK().Invoke();

        // [THEN] The FA History Entry will be created
        FAHistoryEntry.SetCurrentKey("FA No.");
        FAHistoryEntry.SetRange("FA No.", FixedAsset."No.");
        FAHistoryEntry.SetRange(Type, FAHistoryEntry.Type::"Responsible Employee");
        FAHistoryEntry.FindFirst();
        FAHistoryEntry.TestField("New Value", Employee."No.");

        FAHistoryEntry.SetRange(Type, FAHistoryEntry.Type::"FA Location");
        FAHistoryEntry.FindFirst();
        FAHistoryEntry.TestField("New Value", FALocation.Code);

        // Teardown
        UpdateFASetupWithFAHistory(false);
    end;

    [Test]
    procedure PostingFixedAssetDisposal()
    var
        FixedAsset: Record "Fixed Asset";
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        TaxDepreciationGroupCZF: Record "Tax Depreciation Group CZF";
        FAPostingGroup: Record "FA Posting Group";
        FAExtendedPostingGroupCZF: Record "FA Extended Posting Group CZF";
        GenJournalLine: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
    begin
        // [SCENARIO] Test the Posting of Fixed Asset Disposal, change field "Disposed" on the FA Depreciation Book and
        // creation G/L Entry with G/L Account from FA Extended Posting Group
        Initialize();

        // [GIVEN] The Depreciation Book has been created
        CreateDepreciationBook(DepreciationBook);
        DepreciationBook.Validate("G/L Integration - Disposal", true);
        DepreciationBook.Modify(true);

        // [GIVEN] The FA Posting Group and FA Extended Posting Group have been created
        CreateFAPostingGroup(FAPostingGroup);
        CreateFAExtendedPostingGroupDisposal(FAExtendedPostingGroupCZF, FAPostingGroup.Code);

        // [GIVEN] The Fixed Asset and FA Depreciation Book have been created
        CreateFixedAsset(FixedAsset);
        CreateTaxDepreciationGroupCZF(TaxDepreciationGroupCZF, TaxDepreciationGroupCZF."Depreciation Type"::"Straight-line");
        CreateFADepreciationBook(
          FADepreciationBook, FixedAsset."No.",
          DepreciationBook.Code, TaxDepreciationGroupCZF.Code, true,
          FADepreciationBook."Depreciation Method"::"Straight-Line");
        FADepreciationBook.Validate("FA Posting Group", FAPostingGroup.Code);
        FADepreciationBook.Validate("Acquisition Date", WorkDate());
        FADepreciationBook.Modify(true);

        // [GIVEN] The FA Journal Line has been created
        CreateGenJournalLine(
          GenJournalLine, DepreciationBook.Code,
          GenJournalLine."FA Posting Type"::Disposal, FixedAsset."No.");
        GenJournalLine.Validate("Reason Code", FAExtendedPostingGroupCZF.Code);
        GenJournalLine.Modify(true);

        // [WHEN] Post Gen. Journal Line

        PostGenJournalLine(GenJournalLine);

        // [THEN] The Fixed Asset will be Disposed
        FADepreciationBook.Get(FixedAsset."No.", DepreciationBook.Code);
        FADepreciationBook.TestField("Disposal Date");

        // [THEN] The G/L Account No. in the G/L Entry will have the same value as FAExtendedPostingGroupCZF."Sales Acc. On Disp. (Gain)"
        GLEntry.SetCurrentKey("Document No.", "Posting Date");
        GLEntry.SetRange("Document No.", GenJournalLine."Document No.");
        GLEntry.SetRange("Posting Date", GenJournalLine."Posting Date");
        GLEntry.FindFirst();
        GLEntry.TestField("G/L Account No.", FAExtendedPostingGroupCZF."Sales Acc. On Disp. (Gain)");
    end;

    [Test]
    procedure SetFATaxDeprGroupDoesNotClearTaxDepreciationGroupWhenDepreciationBookTaxDepGroupIsBlank()
    var
        FASetup: Record "FA Setup";
        FixedAsset: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        TaxDepreciationGroupCZF: Record "Tax Depreciation Group CZF";
        FAGeneralReportCZF: Codeunit "FA General Report CZF";
        OriginalTaxDepGroupCode: Code[20];
    begin
        // [SCENARIO] SetFATaxDeprGroup does not clear Tax Deprec. Group Code CZF on Fixed Asset
        // when FA Depreciation Book has blank Tax Deprec. Group Code CZF.

        Initialize();
        FASetup.Get();

        // [GIVEN] Fixed Asset and FA Depreciation Book with Tax Deprec. Group Code CZF are created.
        CreateFixedAsset(FixedAsset);
        CreateTaxDepreciationGroupCZF(TaxDepreciationGroupCZF, TaxDepreciationGroupCZF."Depreciation Type"::"Straight-line");
        CreateFADepreciationBook(
          FADepreciationBook, FixedAsset."No.",
          FASetup."Tax Depreciation Book CZF", TaxDepreciationGroupCZF.Code, true,
          FADepreciationBook."Depreciation Method"::"Straight-Line");
        FixedAsset.Validate("Tax Deprec. Group Code CZF", TaxDepreciationGroupCZF.Code);
        FixedAsset.Modify(true);
        OriginalTaxDepGroupCode := FixedAsset."Tax Deprec. Group Code CZF";

        // [GIVEN] FA Depreciation Book Tax Deprec. Group Code CZF is blank.
        FADepreciationBook."Tax Deprec. Group Code CZF" := ''; // Without validation because validation set the Fixed Asset Tax Deprec. Group Code CZF to blank.
        FADepreciationBook.Modify(true);

        // [WHEN] SetFATaxDeprGroup is called.
        FixedAsset.SetRange("No.", FixedAsset."No.");
        FAGeneralReportCZF.SetFATaxDeprGroup(FixedAsset, FADepreciationBook."Depreciation Book Code");

        // [THEN] Tax Deprec. Group Code CZF on Fixed Asset remains unchanged.
        FixedAsset.Get(FixedAsset."No.");
        FixedAsset.TestField("Tax Deprec. Group Code CZF", OriginalTaxDepGroupCode);
    end;

    [Test]
    procedure SetFATaxDeprGroupUpdatesTaxDepreciationGroupWhenDepreciationBookTaxDepGroupIsDifferentAndNotBlank()
    var
        FASetup: Record "FA Setup";
        FixedAsset: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        TaxDepreciationGroupCZF: Record "Tax Depreciation Group CZF";
        NewTaxDepreciationGroupCZF: Record "Tax Depreciation Group CZF";
        FAGeneralReportCZF: Codeunit "FA General Report CZF";
        NewTaxDepGroupCode: Code[20];
    begin
        // [SCENARIO] SetFATaxDeprGroup updates Tax Deprec. Group Code CZF on Fixed Asset
        // when FA Depreciation Book has a different non-blank Tax Deprec. Group Code CZF.

        Initialize();
        FASetup.Get();

        // [GIVEN] Fixed Asset and FA Depreciation Book with initial Tax Deprec. Group Code CZF are created.
        CreateFixedAsset(FixedAsset);
        CreateTaxDepreciationGroupCZF(TaxDepreciationGroupCZF, TaxDepreciationGroupCZF."Depreciation Type"::"Straight-line");
        CreateFADepreciationBook(
          FADepreciationBook, FixedAsset."No.",
          FASetup."Tax Depreciation Book CZF", TaxDepreciationGroupCZF.Code, true,
          FADepreciationBook."Depreciation Method"::"Straight-Line");
        FixedAsset.Validate("Tax Deprec. Group Code CZF", TaxDepreciationGroupCZF.Code);
        FixedAsset.Modify(true);

        // [GIVEN] FA Depreciation Book has another non-blank Tax Deprec. Group Code CZF.
        CreateTaxDepreciationGroupCZF(NewTaxDepreciationGroupCZF, NewTaxDepreciationGroupCZF."Depreciation Type"::"Declining-Balance");
        NewTaxDepGroupCode := NewTaxDepreciationGroupCZF.Code;
        FADepreciationBook."Tax Deprec. Group Code CZF" := NewTaxDepGroupCode; // Without validation because validation set the Fixed Asset Tax Deprec. Group Code CZF to new value.
        FADepreciationBook.Modify(true);

        // [WHEN] SetFATaxDeprGroup is called.
        FixedAsset.SetRange("No.", FixedAsset."No.");
        FAGeneralReportCZF.SetFATaxDeprGroup(FixedAsset, FADepreciationBook."Depreciation Book Code");

        // [THEN] Tax Deprec. Group Code CZF on Fixed Asset is updated from FA Depreciation Book.
        FixedAsset.Get(FixedAsset."No.");
        FixedAsset.TestField("Tax Deprec. Group Code CZF", NewTaxDepGroupCode);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure EndingBookValueSetupConfirmation()
    var
        FASetup: Record "FA Setup";
        FixedAssetSetup: TestPage "Fixed Asset Setup";
    begin
        // [SCENARIO] Both directions require confirmation; declining keeps the stored setting.
        Initialize();
        // [GIVEN] The setting is disabled and the setup page is editable.
        SetIncludeEndingBookValue(false);
        FixedAssetSetup.OpenEdit();
        // [WHEN] Enabling is declined.
        SetExpectedConfirm(ChangeCalculationQst, false);
        FixedAssetSetup."Incl. Ending Book Value CZF".SetValue(true);
        // [THEN] The setting remains disabled.
        FixedAssetSetup."Incl. Ending Book Value CZF".AssertEquals(false);
        // [WHEN] Enabling is accepted.
        SetExpectedConfirm(ChangeCalculationQst, true);
        FixedAssetSetup."Incl. Ending Book Value CZF".SetValue(true);
        // [THEN] The setting is enabled.
        FixedAssetSetup."Incl. Ending Book Value CZF".AssertEquals(true);
        // [WHEN] Disabling is declined.
        SetExpectedConfirm(ChangeCalculationQst, false);
        FixedAssetSetup."Incl. Ending Book Value CZF".SetValue(false);
        // [THEN] The setting remains enabled.
        FixedAssetSetup."Incl. Ending Book Value CZF".AssertEquals(true);
        // [WHEN] Disabling is accepted and the page is closed.
        SetExpectedConfirm(ChangeCalculationQst, true);
        FixedAssetSetup."Incl. Ending Book Value CZF".SetValue(false);
        FixedAssetSetup.Close();
        // [THEN] The disabled setting is persisted.
        FASetup.Get();
        FASetup.TestField("Incl. Ending Book Value CZF", false);
    end;

    [Test]
    procedure EndingBookValueSLPercentEnabled()
    begin
        // [GIVEN] SL percent and residual inclusion are selected in the delegated fixture.
        // [WHEN] The helper calculates monthly depreciation.
        // [THEN] It verifies the independently prorated, reduced basis.
        VerifyEndingBookValueMonthly(true, true);
    end;

    [Test]
    procedure EndingBookValueSLPercentDisabled()
    begin
        // [GIVEN] SL percent without residual inclusion is selected in the delegated fixture.
        // [WHEN] The helper calculates monthly depreciation.
        // [THEN] It verifies the independently prorated, full basis.
        VerifyEndingBookValueMonthly(false, true);
    end;

    [Test]
    procedure EndingBookValueRemainingLifeEnabled()
    begin
        // [GIVEN] Remaining life and residual inclusion are selected in the delegated fixture.
        // [WHEN] The helper calculates monthly depreciation.
        // [THEN] It verifies the reduced book value distributed over remaining life.
        VerifyEndingBookValueMonthly(true, false);
    end;

    [Test]
    procedure EndingBookValueRemainingLifeDisabled()
    begin
        // [GIVEN] Remaining life without residual inclusion is selected in the delegated fixture.
        // [WHEN] The helper calculates monthly depreciation.
        // [THEN] It verifies the full book value distributed over remaining life.
        VerifyEndingBookValueMonthly(false, false);
    end;

    [Test]
    procedure EndingBookValueDefaultAndIndividual()
    var
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        ResidualValue: Decimal;
        UntilDate: Date;
    begin
        // [SCENARIO] The book default is used only when there is no individual residual.
        Initialize();
        // [GIVEN] The fixture residual is supplied by the book default, not the asset.
        SetIncludeEndingBookValue(true);
        CreateEndingValueAsset(DepreciationBook, FADepreciationBook);
        ResidualValue := FADepreciationBook."Ending Book Value";
        UntilDate := CalcDate('<CM>', FADepreciationBook."Depreciation Starting Date");
        // Clear the individual value before setting the default; OnModify otherwise copies the default into it.
        FADepreciationBook.Validate("Ending Book Value", 0);
        FADepreciationBook.Modify(true);
        DepreciationBook.Validate("Default Ending Book Value", ResidualValue);
        DepreciationBook.Modify(true);
        FADepreciationBook.Get(FADepreciationBook."FA No.", DepreciationBook.Code);
        FADepreciationBook.TestField("Ending Book Value", 0);
        // [WHEN] Monthly depreciation is calculated without an individual residual.
        // [THEN] The independently calculated amount uses the book default.
        AssertNormalEndingValueDepreciation(FADepreciationBook, UntilDate, true, 0);

        // [GIVEN] A different book default and an individual residual are configured.
        DepreciationBook.Validate("Default Ending Book Value", ResidualValue * 2);
        DepreciationBook.Modify(true);
        FADepreciationBook.Validate("Ending Book Value", ResidualValue);
        FADepreciationBook.Modify(true);
        // [WHEN] Monthly depreciation is calculated again.
        // [THEN] The individual residual overrides the default in the expected basis.
        AssertNormalEndingValueDepreciation(FADepreciationBook, UntilDate, true, 0);
    end;

    [Test]
    procedure EndingBookValueIgnoreDefault()
    var
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        // [SCENARIO] Ignoring a default residual restores the full formula base.
        Initialize();
        // [GIVEN] Residual inclusion is enabled, but the asset ignores the book default.
        SetIncludeEndingBookValue(true);
        CreateEndingValueAsset(DepreciationBook, FADepreciationBook);
        DepreciationBook.Validate("Default Ending Book Value", FADepreciationBook."Ending Book Value");
        DepreciationBook.Modify(true);
        FADepreciationBook.Validate("Ending Book Value", 0);
        FADepreciationBook.Validate("Ignore Def. Ending Book Value", true);
        FADepreciationBook.Modify(true);
        // [WHEN] Monthly depreciation is calculated.
        // [THEN] The independently prorated amount uses the full basis.
        AssertNormalEndingValueDepreciation(FADepreciationBook, CalcDate('<CM>', FADepreciationBook."Depreciation Starting Date"), true, 0);
    end;

    [Test]
    procedure EndingBookValueAnnualFloorEnabled()
    begin
        // [GIVEN] Residual inclusion is enabled in the delegated annual fixture.
        // [WHEN] The helper calculates depreciation to year end.
        // [THEN] It verifies the amount against the independently calculated residual floor.
        VerifyEndingBookValueAnnualFloor(true);
    end;

    [Test]
    procedure EndingBookValueAnnualFloorDisabled()
    begin
        // [GIVEN] Residual inclusion is disabled in the delegated annual fixture.
        // [WHEN] The helper calculates depreciation to year end.
        // [THEN] It verifies that the full-base formula still respects the residual floor.
        VerifyEndingBookValueAnnualFloor(false);
    end;

    [Test]
    procedure EndingBookValueLastDeprEntry()
    var
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        UntilDate: Date;
    begin
        // [SCENARIO] Recalculation from ledger values still reduces the formula base.
        Initialize();
        // [GIVEN] Residual inclusion and calculation from the last depreciation entry are enabled.
        SetIncludeEndingBookValue(true);
        CreateEndingValueAsset(DepreciationBook, FADepreciationBook);
        DepreciationBook.Validate("Periodic Depr. Date Calc.", DepreciationBook."Periodic Depr. Date Calc."::"Last Depr. Entry");
        DepreciationBook.Modify(true);
        UntilDate := CalcDate('<CM>', FADepreciationBook."Depreciation Starting Date");
        // [WHEN] The first month is calculated.
        // [THEN] Its amount uses the independently reduced basis.
        AssertNormalEndingValueDepreciation(FADepreciationBook, UntilDate, true, 0);
        // [GIVEN] The first month has been posted.
        PostEndingValueDepreciation(FADepreciationBook, UntilDate);
        UntilDate := CalcDate('<CM+1D+CM>', UntilDate);
        // [WHEN] The next month is calculated from the updated ledger.
        // [THEN] Only the new interval is depreciated from the reduced basis.
        AssertNormalEndingValueDepreciation(FADepreciationBook, UntilDate, true, 0);
        // [WHEN] The unposted calculation is repeated.
        // [THEN] Repeating an unposted calculation does not subtract the residual again.
        AssertNormalEndingValueDepreciation(FADepreciationBook, UntilDate, true, 0);
    end;

    [Test]
    procedure EndingBookValueTwelveMonthlyPostings()
    var
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        FALedgerEntry: Record "FA Ledger Entry";
        UntilDate: Date;
        MonthCount: Integer;
        ExpectedDepreciation: Decimal;
        ResidualValue: Decimal;
    begin
        // [SCENARIO] Monthly postings over the configured life leave exactly the residual.
        Initialize();
        // [GIVEN] A remaining-life asset with a posted acquisition and an individual residual.
        SetIncludeEndingBookValue(true);
        CreateEndingValueAsset(DepreciationBook, FADepreciationBook);
        // Remaining-life depreciation distributes rounding differences across subsequent periods.
        FADepreciationBook.Validate("No. of Depreciation Years", 1);
        FADepreciationBook.Modify(true);
        FADepreciationBook.CalcFields("Acquisition Cost");
        ResidualValue := FADepreciationBook."Ending Book Value";
        ExpectedDepreciation := -(FADepreciationBook."Acquisition Cost" - ResidualValue);
        UntilDate := FADepreciationBook."Depreciation Starting Date";
        // [WHEN] Each configured month is calculated and posted.
        while UntilDate <= FADepreciationBook."Depreciation Ending Date" do begin
            MonthCount += 1;
            UntilDate := CalcDate('<CM>', UntilDate);
            if UntilDate > FADepreciationBook."Depreciation Ending Date" then
                UntilDate := FADepreciationBook."Depreciation Ending Date";
            // [THEN] Every monthly amount agrees with the independent remaining-life formula.
            AssertNormalEndingValueDepreciation(FADepreciationBook, UntilDate, true, 0);
            PostEndingValueDepreciation(FADepreciationBook, UntilDate);
            UntilDate += 1;
        end;
        // [THEN] Total depreciation equals acquisition less residual, with one entry per month.
        FADepreciationBook.Get(FADepreciationBook."FA No.", DepreciationBook.Code);
        FADepreciationBook.CalcFields(Depreciation, "Book Value");
        FADepreciationBook.TestField(Depreciation, ExpectedDepreciation);
        FADepreciationBook.TestField("Book Value", ResidualValue);
        FALedgerEntry.SetRange("FA No.", FADepreciationBook."FA No.");
        FALedgerEntry.SetRange("Depreciation Book Code", DepreciationBook.Code);
        FALedgerEntry.SetRange("FA Posting Type", FALedgerEntry."FA Posting Type"::Depreciation);
        Assert.RecordCount(FALedgerEntry, MonthCount);
        // [WHEN] Another month is calculated after the residual has been reached.
        // [THEN] No further depreciation is available, but days still describe the new interval.
        AssertEndingValueDepreciation(FADepreciationBook, CalcDate('<CM>', UntilDate), 0);
    end;

    [Test]
    procedure EndingBookValueTaxProrated()
    var
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        TaxDepreciationGroupCZF: Record "Tax Depreciation Group CZF";
    begin
        // [SCENARIO] Prorated tax depreciation ignores the residual in the formula and final limit.
        Initialize();
        // [GIVEN] A prorated tax asset with a configured first-year rate and residual inclusion.
        SetIncludeEndingBookValue(true);
        CreateEndingValueAsset(DepreciationBook, FADepreciationBook);
        // Exercise statutory whole-unit rounding as well as time proration.
        DepreciationBook.Validate("Use Rounding in Periodic Depr.", true);
        DepreciationBook.Modify(true);
        EnsureEndingValueAccountingPeriods(FADepreciationBook."Depreciation Starting Date");
        CreateTaxDepreciationGroupCZF(TaxDepreciationGroupCZF, TaxDepreciationGroupCZF."Depreciation Type"::"Straight-line");
        TaxDepreciationGroupCZF.Validate("Straight First Year", 100);
        TaxDepreciationGroupCZF.Modify(true);
        FADepreciationBook.Validate("Tax Deprec. Group Code CZF", TaxDepreciationGroupCZF.Code);
        FADepreciationBook.Validate("Prorated CZF", true);
        FADepreciationBook.Modify(true);
        // [WHEN] Monthly and annual tax depreciation are calculated.
        // [THEN] The independent first-year formula uses the full basis and no residual floor.
        AssertTaxEndingValueDepreciation(FADepreciationBook, CalcDate('<CM>', FADepreciationBook."Depreciation Starting Date"), true, TaxDepreciationGroupCZF."Straight First Year");
        AssertTaxEndingValueDepreciation(FADepreciationBook, CalcDate('<CY>', FADepreciationBook."Depreciation Starting Date"), true, TaxDepreciationGroupCZF."Straight First Year");
    end;

    [Test]
    procedure EndingBookValueSwitchAfterPosting()
    var
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        UntilDate: Date;
        ExpectedPostedAmount: Decimal;
    begin
        // [SCENARIO] Enabling the setting only changes future calculations, not posted depreciation.
        Initialize();
        // [GIVEN] A full-base monthly amount is independently calculated before it is posted.
        SetIncludeEndingBookValue(false);
        CreateEndingValueAsset(DepreciationBook, FADepreciationBook);
        UntilDate := CalcDate('<CM>', FADepreciationBook."Depreciation Starting Date");
        ExpectedPostedAmount := ExpectedNormalEndingValueAmount(FADepreciationBook, UntilDate, false, 0);
        PostEndingValueDepreciation(FADepreciationBook, UntilDate);
        // [WHEN] Residual inclusion is enabled after posting.
        SetIncludeEndingBookValue(true);
        // [THEN] The ledger retains the independently expected old amount.
        FADepreciationBook.CalcFields(Depreciation);
        FADepreciationBook.TestField(Depreciation, ExpectedPostedAmount);
        // [WHEN] The following month is calculated.
        // [THEN] Only future depreciation uses the independently reduced basis.
        AssertNormalEndingValueDepreciation(FADepreciationBook, CalcDate('<CM+1D+CM>', UntilDate), true, 0);
    end;

    [Test]
    procedure EndingBookValueTaxEnabled()
    begin
        // [GIVEN] Residual inclusion is enabled in the delegated tax fixture.
        // [WHEN] The helper calculates first-year tax depreciation.
        // [THEN] It verifies the full basis without a residual floor and unchanged stored settings.
        VerifyEndingBookValueTax(true);
    end;

    [Test]
    procedure EndingBookValueTaxDisabled()
    begin
        // [GIVEN] Residual inclusion is disabled in the delegated tax fixture.
        // [WHEN] The helper calculates first-year tax depreciation.
        // [THEN] It verifies the full basis capped at the residual and unchanged stored settings.
        VerifyEndingBookValueTax(false);
    end;

    [Test]
    procedure EndingBookValueTableEnabled()
    begin
        // [GIVEN] A constructed annual table and residual inclusion are selected by the helper.
        // [WHEN] Monthly and annual depreciation are calculated.
        // [THEN] The helper verifies the table rate against the independently reduced basis.
        VerifyEndingBookValueTable(true);
    end;

    [Test]
    procedure EndingBookValueTableDisabled()
    begin
        // [GIVEN] A constructed annual table without residual inclusion is selected by the helper.
        // [WHEN] Monthly and annual depreciation are calculated.
        // [THEN] The helper verifies the full basis, table rate, and residual floor.
        VerifyEndingBookValueTable(false);
    end;

    [Test]
    procedure EndingBookValueDecliningBalance1()
    var
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        // [GIVEN] The delegated fixture selects DB1 and its configured annual rate.
        // [WHEN] The helper calculates a month in each inclusion mode.
        // [THEN] It verifies independent linear proration of each effective book value.
        VerifyEndingBookValueDeclining(FADepreciationBook."Depreciation Method"::"Declining-Balance 1");
    end;

    [Test]
    procedure EndingBookValueDecliningBalance2()
    var
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        // [GIVEN] The delegated fixture selects DB2 and its configured annual rate.
        // [WHEN] The helper calculates a month in each inclusion mode.
        // [THEN] It verifies independent exponential proration of each effective book value.
        VerifyEndingBookValueDeclining(FADepreciationBook."Depreciation Method"::"Declining-Balance 2");
    end;

    [Test]
    procedure EndingBookValueCombinedMethod()
    var
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        // [SCENARIO] The actual SL and DB1 branches of a combined method use their respective base contexts.
        // [GIVEN] The delegated fixture selects the combined DB1/SL method.
        // [WHEN] The helper exercises both candidate branches in each inclusion mode.
        // [THEN] It verifies the more negative independently calculated candidate.
        VerifyEndingBookValueDeclining(FADepreciationBook."Depreciation Method"::"DB1/SL");
    end;

    [Test]
    procedure EndingBookValueBelowZeroPercent()
    var
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        UntilDate: Date;
    begin
        // [SCENARIO] The standard exposes the below-zero base, but CZ does not subtract the residual from it.
        Initialize();
        // [GIVEN] Below-zero depreciation is allowed and the residual equals acquisition cost.
        SetIncludeEndingBookValue(true);
        CreateEndingValueAsset(DepreciationBook, FADepreciationBook);
        DepreciationBook.Validate("Allow Depr. below Zero", true);
        DepreciationBook.Modify(true);
        FADepreciationBook.CalcFields("Acquisition Cost");
        FADepreciationBook.Validate("Ending Book Value", FADepreciationBook."Acquisition Cost");
        FADepreciationBook.Validate("Depr. below Zero %", 100);
        FADepreciationBook.Modify(true);
        UntilDate := CalcDate('<CM>', FADepreciationBook."Depreciation Starting Date");
        // [WHEN] Below-zero depreciation is calculated with residual inclusion enabled.
        // [THEN] The independent below-zero percentage uses the full basis.
        AssertNormalEndingValueDepreciation(FADepreciationBook, UntilDate, true, 0);
        // [WHEN] Residual inclusion is disabled and the calculation is repeated.
        SetIncludeEndingBookValue(false);
        // [THEN] The same full-base below-zero formula still applies.
        AssertNormalEndingValueDepreciation(FADepreciationBook, UntilDate, false, 0);
    end;

    [Test]
    procedure EndingBookValueSummarization()
    var
        SourceDepreciationBook: Record "Depreciation Book";
        TargetDepreciationBook: Record "Depreciation Book";
        SourceFADepreciationBook: Record "FA Depreciation Book";
        TargetFADepreciationBook: Record "FA Depreciation Book";
        SourceFALedgerEntry: Record "FA Ledger Entry";
        UntilDate: Date;
        ExpectedAmount: Decimal;
    begin
        // [SCENARIO] A summarized amount already reduced in the source is not reduced twice.
        Initialize();
        // [GIVEN] Source and target books share the asset and residual; the target summarizes the source.
        SetIncludeEndingBookValue(true);
        CreateEndingValueAsset(SourceDepreciationBook, SourceFADepreciationBook);
        CreateEndingValueBook(TargetDepreciationBook);
        CreateFADepreciationBook(
          TargetFADepreciationBook, SourceFADepreciationBook."FA No.", TargetDepreciationBook.Code, '', false,
          TargetFADepreciationBook."Depreciation Method"::"Straight-Line");
        TargetFADepreciationBook.Validate("Depreciation Starting Date", SourceFADepreciationBook."Depreciation Starting Date");
        TargetFADepreciationBook.Validate("No. of Depreciation Years", 1);
        TargetFADepreciationBook.Validate("Ending Book Value", SourceFADepreciationBook."Ending Book Value");
        TargetFADepreciationBook.Validate("Sum. Deprec. Entries From CZF", SourceDepreciationBook.Code);
        TargetFADepreciationBook.Modify(true);
        PostEndingValueAcquisition(TargetFADepreciationBook);
        EnsureEndingValueAccountingPeriods(SourceFADepreciationBook."Depreciation Starting Date");
        UntilDate := CalcDate('<CY>', SourceFADepreciationBook."Depreciation Starting Date");
        // [WHEN] The source's annual depreciation is calculated.
        // [THEN] It agrees with the independent normal formula before posting.
        AssertNormalEndingValueDepreciation(SourceFADepreciationBook, UntilDate, true, 0);
        PostEndingValueDepreciation(SourceFADepreciationBook, UntilDate);
        // [GIVEN] The expected target amount is the posted source ledger sum, rounded to whole units and capped at its own floor.
        SourceFALedgerEntry.SetRange("FA No.", SourceFADepreciationBook."FA No.");
        SourceFALedgerEntry.SetRange("Depreciation Book Code", SourceDepreciationBook.Code);
        SourceFALedgerEntry.SetRange("FA Posting Type", SourceFALedgerEntry."FA Posting Type"::Depreciation);
        SourceFALedgerEntry.SetRange("FA Posting Date", SourceFADepreciationBook."Depreciation Starting Date", UntilDate);
        SourceFALedgerEntry.SetRange(Reversed, false);
        SourceFALedgerEntry.CalcSums(Amount);
        ExpectedAmount := LimitEndingValueAmount(TargetFADepreciationBook, -Round(-SourceFALedgerEntry.Amount, 1, '>'), EndingValueResidual(TargetFADepreciationBook));
        // [WHEN] The target calculates summarized depreciation.
        // [THEN] The source amount is not reduced by the residual a second time.
        AssertEndingValueDepreciation(TargetFADepreciationBook, UntilDate, ExpectedAmount);
    end;

    [Test]
    procedure EndingBookValueFieldsRequireAllowChanges()
    var
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        ChangedResidualValue: Decimal;
    begin
        // [SCENARIO] Both residual fields are protected after a real depreciation posting.
        Initialize();
        // [GIVEN] Depreciation has been posted and changes to depreciation fields are not allowed.
        SetIncludeEndingBookValue(true);
        CreateEndingValueAsset(DepreciationBook, FADepreciationBook);
        PostEndingValueDepreciation(FADepreciationBook, CalcDate('<CM>', FADepreciationBook."Depreciation Starting Date"));
        FADepreciationBook.Get(FADepreciationBook."FA No.", DepreciationBook.Code);
        FADepreciationBook.TestField("Last Depreciation Date");
        ChangedResidualValue := FADepreciationBook."Ending Book Value" + 10000;
        // [WHEN] The individual residual is changed.
        asserterror FADepreciationBook.Validate("Ending Book Value", ChangedResidualValue);
        // [THEN] The book must permit changes to depreciation fields.
        Assert.ExpectedTestFieldError(DepreciationBook.FieldCaption("Allow Changes in Depr. Fields"), Format(true));
        FADepreciationBook.Get(FADepreciationBook."FA No.", DepreciationBook.Code);
        // [WHEN] Ignoring the default residual is requested.
        asserterror FADepreciationBook.Validate("Ignore Def. Ending Book Value", true);
        // [THEN] The same protection applies.
        Assert.ExpectedTestFieldError(DepreciationBook.FieldCaption("Allow Changes in Depr. Fields"), Format(true));

        // [GIVEN] Changes to depreciation fields are now allowed.
        DepreciationBook.Validate("Allow Changes in Depr. Fields", true);
        DepreciationBook.Modify(true);
        FADepreciationBook.Get(FADepreciationBook."FA No.", DepreciationBook.Code);
        // [WHEN] Both residual fields are changed and saved.
        FADepreciationBook.Validate("Ending Book Value", ChangedResidualValue);
        FADepreciationBook.Validate("Ignore Def. Ending Book Value", true);
        FADepreciationBook.Modify(true);
        // [THEN] Both assigned values are persisted.
        FADepreciationBook.Get(FADepreciationBook."FA No.", DepreciationBook.Code);
        FADepreciationBook.TestField("Ending Book Value", ChangedResidualValue);
        FADepreciationBook.TestField("Ignore Def. Ending Book Value", true);
    end;

    local procedure VerifyEndingBookValueMonthly(IncludeEndingBookValue: Boolean; UseSLPercent: Boolean)
    var
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        // [SCENARIO] Monthly SL uses either the full base or the base less the residual.
        Initialize();
        // [GIVEN] An acquired asset uses the selected inclusion mode and SL formula.
        SetIncludeEndingBookValue(IncludeEndingBookValue);
        CreateEndingValueAsset(DepreciationBook, FADepreciationBook);
        if not UseSLPercent then begin
            FADepreciationBook.Validate("No. of Depreciation Years", 1);
            FADepreciationBook.Modify(true);
        end;
        FADepreciationBook.Get(FADepreciationBook."FA No.", DepreciationBook.Code);
        FADepreciationBook.TestField("Acquisition Date", FADepreciationBook."Depreciation Starting Date");
        // [WHEN] Depreciation is calculated through the first month end.
        // [THEN] The amount and days agree with the independent rate/life and calendar calculations.
        AssertNormalEndingValueDepreciation(FADepreciationBook, CalcDate('<CM>', FADepreciationBook."Depreciation Starting Date"), IncludeEndingBookValue, 0);
    end;

    local procedure VerifyEndingBookValueAnnualFloor(IncludeEndingBookValue: Boolean)
    var
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        // [SCENARIO] Normal annual depreciation retains the residual floor in both modes.
        Initialize();
        // [GIVEN] An acquired asset has an individual residual and the selected inclusion mode.
        SetIncludeEndingBookValue(IncludeEndingBookValue);
        CreateEndingValueAsset(DepreciationBook, FADepreciationBook);
        // [WHEN] Annual depreciation is calculated.
        // [THEN] The independently prorated formula cannot depreciate beyond the residual floor.
        AssertNormalEndingValueDepreciation(FADepreciationBook, CalcDate('<CY>', FADepreciationBook."Depreciation Starting Date"), IncludeEndingBookValue, 0);
    end;

    local procedure VerifyEndingBookValueTax(IncludeEndingBookValue: Boolean)
    var
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        TaxDepreciationGroupCZF: Record "Tax Depreciation Group CZF";
        StoredResidualValue: Decimal;
        StoredIgnoreDefault: Boolean;
        UntilDate: Date;
    begin
        // [SCENARIO] Tax depreciation ignores both the residual base reduction and floor only when enabled.
        Initialize();
        // [GIVEN] An acquired asset has a first-year tax rate, individual residual and selected inclusion mode.
        SetIncludeEndingBookValue(IncludeEndingBookValue);
        CreateEndingValueAsset(DepreciationBook, FADepreciationBook);
        EnsureEndingValueAccountingPeriods(FADepreciationBook."Depreciation Starting Date");
        CreateTaxDepreciationGroupCZF(TaxDepreciationGroupCZF, TaxDepreciationGroupCZF."Depreciation Type"::"Straight-line");
        TaxDepreciationGroupCZF.Validate("No. of Depreciation Years", 1);
        TaxDepreciationGroupCZF.Validate("Straight First Year", 100);
        TaxDepreciationGroupCZF.Validate("Straight Next Years", 100);
        TaxDepreciationGroupCZF.Validate("Straight Appreciation", 100);
        TaxDepreciationGroupCZF.Modify(true);
        FADepreciationBook.Get(FADepreciationBook."FA No.", DepreciationBook.Code);
        FADepreciationBook.Validate("Tax Deprec. Group Code CZF", TaxDepreciationGroupCZF.Code);
        FADepreciationBook.Modify(true);
        StoredResidualValue := FADepreciationBook."Ending Book Value";
        StoredIgnoreDefault := FADepreciationBook."Ignore Def. Ending Book Value";
        UntilDate := CalcDate('<CY>', FADepreciationBook."Depreciation Starting Date");
        // [WHEN] First-year tax depreciation is calculated.
        // [THEN] The full-basis tax formula respects the residual floor only when inclusion is disabled.
        AssertTaxEndingValueDepreciation(FADepreciationBook, UntilDate, IncludeEndingBookValue, TaxDepreciationGroupCZF."Straight First Year");
        // [THEN] Calculation changes only the working record, not the stored residual settings.
        FADepreciationBook.Get(FADepreciationBook."FA No.", DepreciationBook.Code);
        FADepreciationBook.TestField("Ending Book Value", StoredResidualValue);
        FADepreciationBook.TestField("Ignore Def. Ending Book Value", StoredIgnoreDefault);

        // [GIVEN] The same residual is supplied by the book default instead of the individual amount.
        // Clear the individual value before setting the default; OnModify otherwise copies the default into it.
        FADepreciationBook.Validate("Ending Book Value", 0);
        FADepreciationBook.Modify(true);
        DepreciationBook.Validate("Default Ending Book Value", StoredResidualValue);
        DepreciationBook.Modify(true);
        FADepreciationBook.Get(FADepreciationBook."FA No.", DepreciationBook.Code);
        FADepreciationBook.TestField("Ending Book Value", 0);
        // [WHEN] First-year tax depreciation is calculated using the default residual.
        // [THEN] The same independently calculated formula and floor apply, without changing stored settings.
        AssertTaxEndingValueDepreciation(FADepreciationBook, UntilDate, IncludeEndingBookValue, TaxDepreciationGroupCZF."Straight First Year");
        FADepreciationBook.Get(FADepreciationBook."FA No.", DepreciationBook.Code);
        FADepreciationBook.TestField("Ending Book Value", 0);
        FADepreciationBook.TestField("Ignore Def. Ending Book Value", StoredIgnoreDefault);
        DepreciationBook.Get(DepreciationBook.Code);
        DepreciationBook.TestField("Default Ending Book Value", StoredResidualValue);
    end;

    local procedure VerifyEndingBookValueTable(IncludeEndingBookValue: Boolean)
    var
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        DepreciationTableHeader: Record "Depreciation Table Header";
        DepreciationTableLine: Record "Depreciation Table Line";
    begin
        // [SCENARIO] A 100-percent annual table uses the effective base for annual and prorated monthly depreciation.
        Initialize();
        // [GIVEN] An acquired asset uses a constructed annual table and the selected inclusion mode.
        SetIncludeEndingBookValue(IncludeEndingBookValue);
        CreateEndingValueAsset(DepreciationBook, FADepreciationBook);
        DepreciationTableHeader.Init();
        DepreciationTableHeader.Code := LibraryUtility.GenerateRandomCode(DepreciationTableHeader.FieldNo(Code), Database::"Depreciation Table Header");
        DepreciationTableHeader.Validate("Period Length", DepreciationTableHeader."Period Length"::Year);
        DepreciationTableHeader.Insert(true);
        DepreciationTableLine.Init();
        DepreciationTableLine.Validate("Depreciation Table Code", DepreciationTableHeader.Code);
        DepreciationTableLine.Validate("Period No.", 1);
        DepreciationTableLine.Validate("Period Depreciation %", 100);
        DepreciationTableLine.Insert(true);
        FADepreciationBook.Validate("Depreciation Method", FADepreciationBook."Depreciation Method"::"User-Defined");
        FADepreciationBook.Validate("Depreciation Table Code", DepreciationTableHeader.Code);
        FADepreciationBook.Validate("First User-Defined Depr. Date", FADepreciationBook."Depreciation Starting Date");
        FADepreciationBook.Modify(true);
        // [WHEN] Monthly and annual table depreciation are calculated.
        // [THEN] The constructed table's actual rate is prorated independently, subject to the residual floor.
        AssertNormalEndingValueDepreciation(FADepreciationBook, CalcDate('<CM>', FADepreciationBook."Depreciation Starting Date"), IncludeEndingBookValue, DepreciationTableLine."Period Depreciation %");
        AssertNormalEndingValueDepreciation(FADepreciationBook, CalcDate('<CY>', FADepreciationBook."Depreciation Starting Date"), IncludeEndingBookValue, DepreciationTableLine."Period Depreciation %");
    end;

    local procedure VerifyEndingBookValueDeclining(DepreciationMethod: Enum "FA Depreciation Method")
    var
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        UntilDate: Date;
    begin
        // [SCENARIO] Both declining-balance formulae reduce their base, not their final limit.
        Initialize();
        // [GIVEN] An acquired asset uses the selected declining method with residual inclusion enabled.
        SetIncludeEndingBookValue(true);
        CreateEndingValueAsset(DepreciationBook, FADepreciationBook);
        FADepreciationBook.Validate("Depreciation Method", DepreciationMethod);
        FADepreciationBook.Validate("Declining-Balance %", 50);
        FADepreciationBook.Modify(true);
        UntilDate := CalcDate('<CM>', FADepreciationBook."Depreciation Starting Date");
        // [WHEN] First-month depreciation is calculated with inclusion enabled.
        // [THEN] The independent DB formula (or minimum of DB and SL) uses the reduced base.
        AssertNormalEndingValueDepreciation(FADepreciationBook, UntilDate, true, 0);
        // [WHEN] The same unposted period is calculated with inclusion disabled.
        SetIncludeEndingBookValue(false);
        // [THEN] The independent candidates now use the full base.
        AssertNormalEndingValueDepreciation(FADepreciationBook, UntilDate, false, 0);

        if DepreciationMethod = FADepreciationBook."Depreciation Method"::"DB1/SL" then begin
            // [GIVEN] A lower SL rate makes DB1 the selected candidate instead of SL.
            FADepreciationBook.Validate("Straight-Line %", FADepreciationBook."Declining-Balance %" / 2);
            FADepreciationBook.Modify(true);
            // [WHEN] Both inclusion modes are recalculated with DB1 as the larger depreciation.
            // [THEN] The independent minimum selects DB1 and uses the appropriate base in each mode.
            AssertNormalEndingValueDepreciation(FADepreciationBook, UntilDate, false, 0);
            SetIncludeEndingBookValue(true);
            AssertNormalEndingValueDepreciation(FADepreciationBook, UntilDate, true, 0);
        end;
    end;

    local procedure SetIncludeEndingBookValue(IncludeEndingBookValue: Boolean)
    var
        FASetup: Record "FA Setup";
    begin
        FASetup.Get();
        FASetup.Validate("Incl. Ending Book Value CZF", IncludeEndingBookValue);
        FASetup.Modify(true);
    end;

    local procedure CreateEndingValueBook(var DepreciationBook: Record "Depreciation Book")
    begin
        CreateDepreciationBook(DepreciationBook);
        DepreciationBook.Validate("G/L Integration - Acq. Cost", false);
        DepreciationBook.Validate("G/L Integration - Depreciation", false);
        DepreciationBook.Validate("Use Rounding in Periodic Depr.", false);
        DepreciationBook.Validate("Fiscal Year 365 Days", false);
        DepreciationBook.Validate("Use Accounting Period", false);
        DepreciationBook.Validate("No. of Days in Fiscal Year", 360);
        DepreciationBook.Validate("Periodic Depr. Date Calc.", DepreciationBook."Periodic Depr. Date Calc."::"Last Entry");
        DepreciationBook.Validate("Default Final Rounding Amount", 0.01);
        DepreciationBook.Validate("Default Ending Book Value", 0);
        DepreciationBook.Validate("Allow Changes in Depr. Fields", false);
        DepreciationBook.Modify(true);
    end;

    local procedure CreateEndingValueAsset(var DepreciationBook: Record "Depreciation Book"; var FADepreciationBook: Record "FA Depreciation Book")
    var
        FixedAsset: Record "Fixed Asset";
    begin
        CreateEndingValueBook(DepreciationBook);
        CreateFixedAsset(FixedAsset);
        CreateFADepreciationBook(
          FADepreciationBook, FixedAsset."No.", DepreciationBook.Code, '', false,
          FADepreciationBook."Depreciation Method"::"Straight-Line");
        FADepreciationBook.Validate("Depreciation Starting Date", DMY2Date(1, 1, Date2DMY(WorkDate(), 3)));
        FADepreciationBook.Validate("No. of Depreciation Years", 1);
        FADepreciationBook.Validate("Straight-Line %", 100);
        FADepreciationBook.Validate("Ending Book Value", 20000);
        FADepreciationBook.Validate("Final Rounding Amount", 0.01);
        FADepreciationBook.Modify(true);
        PostEndingValueAcquisition(FADepreciationBook);
    end;

    local procedure PostEndingValueAcquisition(var FADepreciationBook: Record "FA Depreciation Book")
    var
        FAJournalLine: Record "FA Journal Line";
        AcquisitionDate: Date;
    begin
        CreateFAJournalLine(
          FAJournalLine, FADepreciationBook."Depreciation Book Code", FAJournalLine."FA Posting Type"::"Acquisition Cost", FADepreciationBook."FA No.");
        FAJournalLine.Validate("Posting Date", FADepreciationBook."Depreciation Starting Date");
        FAJournalLine.Validate("FA Posting Date", FADepreciationBook."Depreciation Starting Date");
        FAJournalLine.Validate(Amount, 120000);
        FAJournalLine.Modify(true);
        AcquisitionDate := FAJournalLine."FA Posting Date";
        PostFAJournalLine(FAJournalLine);
        // Posting updates the book's acquisition dates. Do not let subsequent fixture changes overwrite them.
        FADepreciationBook.Get(FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code");
        FADepreciationBook.TestField("Acquisition Date", AcquisitionDate);
    end;

    local procedure CalculateEndingValueDepreciation(FADepreciationBook: Record "FA Depreciation Book"; UntilDate: Date; var Amount: Decimal; var Days: Integer)
    var
        CalculateNormalDepreciation: Codeunit "Calculate Normal Depreciation";
        EntryAmounts: array[4] of Decimal;
    begin
        CalculateNormalDepreciation.Calculate(
          Amount, Days, FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code", UntilDate, EntryAmounts, 0D, 0);
    end;

    local procedure AssertNormalEndingValueDepreciation(FADepreciationBook: Record "FA Depreciation Book"; UntilDate: Date; IncludeResidual: Boolean; TablePercent: Decimal)
    var
        ExpectedAmount: Decimal;
    begin
        // [GIVEN] Expected depreciation is derived from stored basis/book value, rate and calendar only.
        ExpectedAmount := ExpectedNormalEndingValueAmount(FADepreciationBook, UntilDate, IncludeResidual, TablePercent);
        // [WHEN] The production calculation is executed by the assertion helper.
        // [THEN] It must match the independent amount and interval.
        AssertEndingValueDepreciation(FADepreciationBook, UntilDate, ExpectedAmount);
    end;

    local procedure ExpectedNormalEndingValueAmount(FADepreciationBook: Record "FA Depreciation Book"; UntilDate: Date; IncludeResidual: Boolean; TablePercent: Decimal): Decimal
    var
        DepreciationBook: Record "Depreciation Book";
        Basis: Decimal;
        CurrentValue: Decimal;
        Residual: Decimal;
        PeriodFraction: Decimal;
        RemainingDays: Decimal;
        SLAmount: Decimal;
        DBAmount: Decimal;
        ExpectedAmount: Decimal;
        PeriodStart: Date;
        YearDays: Integer;
    begin
        // Only the normal formulae exercised by these fixtures are needed; no production amount helpers are used.
        FADepreciationBook.Get(FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code");
        DepreciationBook.Get(FADepreciationBook."Depreciation Book Code");
        FADepreciationBook.CalcFields("Depreciable Basis", "Book Value");
        Basis := FADepreciationBook."Depreciable Basis";
        CurrentValue := FADepreciationBook."Book Value";
        Residual := EndingValueResidual(FADepreciationBook);
        PeriodStart := EndingValuePeriodStart(FADepreciationBook);
        YearDays := EndingValueYearDays(DepreciationBook, UntilDate);
        PeriodFraction := EndingValueDays(DepreciationBook, PeriodStart, UntilDate) / YearDays;

        // The below-zero scenario deliberately starts at its residual and keeps the full basis.
        if DepreciationBook."Allow Depr. below Zero" and (CurrentValue <= Residual) then
            exit(Round(-Basis * FADepreciationBook."Depr. below Zero %" / 100 * PeriodFraction));

        if IncludeResidual then begin
            Basis -= Residual;
            CurrentValue -= Residual;
        end;
        if Basis < 0 then
            Basis := 0;
        if CurrentValue < 0 then
            CurrentValue := 0;

        if FADepreciationBook."Straight-Line %" <> 0 then
            SLAmount := Round(-Basis * FADepreciationBook."Straight-Line %" / 100 * PeriodFraction, 0.0001)
        else begin
            RemainingDays := FADepreciationBook."No. of Depreciation Years" * YearDays;
            if DepreciationBook."Fiscal Year 365 Days" then
                RemainingDays := EndingValueDays(DepreciationBook, FADepreciationBook."Depreciation Starting Date", FADepreciationBook."Depreciation Ending Date");
            RemainingDays -= EndingValueDays(DepreciationBook, FADepreciationBook."Depreciation Starting Date", PeriodStart - 1);
            if RemainingDays > 0 then
                SLAmount := -CurrentValue * EndingValueDays(DepreciationBook, PeriodStart, UntilDate) / RemainingDays
            else
                SLAmount := -CurrentValue;
        end;

        // DB fixtures are first-period calculations: there is no posted in-year depreciation to add back to DB1's base.
        case FADepreciationBook."Depreciation Method" of
            FADepreciationBook."Depreciation Method"::"Straight-Line":
                ExpectedAmount := SLAmount;
            FADepreciationBook."Depreciation Method"::"User-Defined":
                ExpectedAmount := -Basis * TablePercent / 100 * PeriodFraction;
            FADepreciationBook."Depreciation Method"::"Declining-Balance 1",
            FADepreciationBook."Depreciation Method"::"DB1/SL":
                ExpectedAmount := -CurrentValue * FADepreciationBook."Declining-Balance %" / 100 * PeriodFraction;
            FADepreciationBook."Depreciation Method"::"Declining-Balance 2":
                ExpectedAmount := -CurrentValue * (1 - Power(1 - FADepreciationBook."Declining-Balance %" / 100, PeriodFraction));
            else
                Error('The independent expectation does not support this depreciation method.');
        end;
        if FADepreciationBook."Depreciation Method" = FADepreciationBook."Depreciation Method"::"DB1/SL" then begin
            DBAmount := ExpectedAmount;
            if SLAmount < DBAmount then
                ExpectedAmount := SLAmount;
        end;
        exit(LimitEndingValueAmount(FADepreciationBook, ExpectedAmount, Residual));
    end;

    local procedure AssertTaxEndingValueDepreciation(FADepreciationBook: Record "FA Depreciation Book"; UntilDate: Date; IncludeResidual: Boolean; FirstYearPercent: Decimal)
    var
        DepreciationBook: Record "Depreciation Book";
        ExpectedAmount: Decimal;
        Residual: Decimal;
        PeriodStart: Date;
    begin
        // [GIVEN] First-year tax depreciation uses the full posted basis and the supplied tax-group rate.
        FADepreciationBook.Get(FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code");
        DepreciationBook.Get(FADepreciationBook."Depreciation Book Code");
        FADepreciationBook.CalcFields("Depreciable Basis");
        PeriodStart := EndingValuePeriodStart(FADepreciationBook);
        if FADepreciationBook."Prorated CZF" then
            PeriodStart := CalcDate('<-CY>', UntilDate);
        ExpectedAmount := FADepreciationBook."Depreciable Basis" * FirstYearPercent / 100 *
          EndingValueDays(DepreciationBook, PeriodStart, UntilDate) / EndingValueYearDays(DepreciationBook, UntilDate);
        if DepreciationBook."Use Rounding in Periodic Depr." then
            ExpectedAmount := Round(Round(ExpectedAmount), 1, '>');
        if not IncludeResidual then
            Residual := EndingValueResidual(FADepreciationBook);
        ExpectedAmount := LimitEndingValueAmount(FADepreciationBook, -ExpectedAmount, Residual);
        // [WHEN] The production tax calculation is executed.
        // [THEN] The independently prorated full-base amount and selected residual floor apply.
        AssertEndingValueDepreciation(FADepreciationBook, UntilDate, ExpectedAmount);
    end;

    local procedure EndingValueResidual(FADepreciationBook: Record "FA Depreciation Book"): Decimal
    var
        DepreciationBook: Record "Depreciation Book";
    begin
        if (FADepreciationBook."Ending Book Value" <> 0) or FADepreciationBook."Ignore Def. Ending Book Value" then
            exit(FADepreciationBook."Ending Book Value");
        DepreciationBook.Get(FADepreciationBook."Depreciation Book Code");
        exit(DepreciationBook."Default Ending Book Value");
    end;

    local procedure LimitEndingValueAmount(FADepreciationBook: Record "FA Depreciation Book"; ExpectedAmount: Decimal; Residual: Decimal): Decimal
    var
        DepreciationBook: Record "Depreciation Book";
        AvailableAmount: Decimal;
        FinalRounding: Decimal;
    begin
        DepreciationBook.Get(FADepreciationBook."Depreciation Book Code");
        if DepreciationBook."Use Rounding in Periodic Depr." then
            ExpectedAmount := Round(ExpectedAmount, 1, '>')
        else
            ExpectedAmount := Round(ExpectedAmount);
        if ExpectedAmount >= 0 then
            exit(0);
        FADepreciationBook.CalcFields("Book Value");
        AvailableAmount := FADepreciationBook."Book Value" - Residual;
        if AvailableAmount <= 0 then
            exit(0);
        FinalRounding := FADepreciationBook."Final Rounding Amount";
        if FinalRounding = 0 then
            FinalRounding := DepreciationBook."Default Final Rounding Amount";
        if AvailableAmount + ExpectedAmount < FinalRounding then
            exit(-Round(AvailableAmount));
        exit(ExpectedAmount);
    end;

    local procedure EndingValuePeriodStart(FADepreciationBook: Record "FA Depreciation Book"): Date
    var
        DepreciationBook: Record "Depreciation Book";
        DepreciationCalculation: Codeunit "Depreciation Calculation";
    begin
        FADepreciationBook.Get(FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code");
        if FADepreciationBook."Last Depreciation Date" = 0D then
            exit(FADepreciationBook."Depreciation Starting Date");
        DepreciationBook.Get(FADepreciationBook."Depreciation Book Code");
        // Calendar utility only; no production amount calculation participates in expectations.
        exit(DepreciationCalculation.ToMorrow(FADepreciationBook."Last Depreciation Date", DepreciationBook."Fiscal Year 365 Days", DepreciationBook."Use Accounting Period"));
    end;

    local procedure EndingValueDays(DepreciationBook: Record "Depreciation Book"; StartingDate: Date; EndingDate: Date): Integer
    var
        DepreciationCalculation: Codeunit "Depreciation Calculation";
    begin
        // Reuse only the calendar convention, not a depreciation amount formula.
        exit(DepreciationCalculation.DeprDays(StartingDate, EndingDate, DepreciationBook."Fiscal Year 365 Days", DepreciationBook."Use Accounting Period"));
    end;

    local procedure EndingValueYearDays(DepreciationBook: Record "Depreciation Book"; UntilDate: Date): Integer
    begin
        if (not DepreciationBook."Fiscal Year 365 Days") and (DepreciationBook."No. of Days in Fiscal Year" <> 0) then
            exit(DepreciationBook."No. of Days in Fiscal Year");
        exit(EndingValueDays(DepreciationBook, CalcDate('<-CY>', UntilDate), CalcDate('<CY>', UntilDate)));
    end;

    local procedure AssertEndingValueDepreciation(FADepreciationBook: Record "FA Depreciation Book"; UntilDate: Date; ExpectedAmount: Decimal)
    var
        DepreciationBook: Record "Depreciation Book";
        Amount: Decimal;
        Days: Integer;
        ExpectedDays: Integer;
    begin
        // [GIVEN] Expected days come from the stored last posting/start date and book calendar, even for zero amounts.
        DepreciationBook.Get(FADepreciationBook."Depreciation Book Code");
        ExpectedDays := EndingValueDays(DepreciationBook, EndingValuePeriodStart(FADepreciationBook), UntilDate);
        // [WHEN] Actual depreciation is calculated by the production engine.
        CalculateEndingValueDepreciation(FADepreciationBook, UntilDate, Amount, Days);
        // [THEN] Actual amount and days agree with independently prepared expectations.
        Assert.AreEqual(ExpectedAmount, Amount, 'Unexpected depreciation amount for the effective ending book value.');
        Assert.AreEqual(ExpectedDays, Days, 'Unexpected depreciation days.');
    end;

    local procedure PostEndingValueDepreciation(FADepreciationBook: Record "FA Depreciation Book"; UntilDate: Date)
    var
        FAJournalLine: Record "FA Journal Line";
        Amount: Decimal;
        Days: Integer;
    begin
        CalculateEndingValueDepreciation(FADepreciationBook, UntilDate, Amount, Days);
        Assert.IsTrue(Amount < 0, 'A real depreciation amount must be posted.');
        CreateFAJournalLine(
          FAJournalLine, FADepreciationBook."Depreciation Book Code", FAJournalLine."FA Posting Type"::Depreciation, FADepreciationBook."FA No.");
        FAJournalLine.Validate("Posting Date", UntilDate);
        FAJournalLine.Validate("FA Posting Date", UntilDate);
        FAJournalLine.Validate(Amount, Amount);
        FAJournalLine.Validate("No. of Depreciation Days", Days);
        FAJournalLine.Modify(true);
        PostFAJournalLine(FAJournalLine);
    end;

    local procedure EnsureEndingValueAccountingPeriods(StartingDate: Date)
    var
        AccountingPeriod: Record "Accounting Period";
        YearOffset: Integer;
        PeriodDate: Date;
    begin
        for YearOffset := 0 to 1 do begin
            PeriodDate := DMY2Date(1, 1, Date2DMY(StartingDate, 3) + YearOffset);
            if not AccountingPeriod.Get(PeriodDate) then begin
                AccountingPeriod.Init();
                AccountingPeriod.Validate("Starting Date", PeriodDate);
                AccountingPeriod.Validate("New Fiscal Year", true);
                AccountingPeriod.Insert(true);
            end else
                if not AccountingPeriod."New Fiscal Year" then begin
                    AccountingPeriod.Validate("New Fiscal Year", true);
                    AccountingPeriod.Modify(true);
                end;
        end;
    end;

    local procedure CreateFixedAsset(var FixedAsset: Record "Fixed Asset")
    begin
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
    end;

    local procedure CreateFAJournalTemplate(var FAJournalTemplate: Record "FA Journal Template")
    begin
        LibraryFixedAsset.CreateJournalTemplate(FAJournalTemplate);
        FAJournalTemplate.SetRange(Recurring, false);
        FAJournalTemplate.Modify(true);
    end;

    local procedure CreateFAJournalBatch(var FAJournalBatch: Record "FA Journal Batch"; FAJournalTemplateName: Code[10])
    begin
        LibraryFixedAsset.CreateFAJournalBatch(FAJournalBatch, FAJournalTemplateName);
        FAJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        FAJournalBatch.Modify(true);
    end;

    local procedure CreateFAJournalLine(var FAJournalLine: Record "FA Journal Line"; DepreciationBookCode: Code[10]; FAPostingType: Enum "FA Journal Line FA Posting Type"; FANo: Code[20])
    var
        FAJournalTemplate: Record "FA Journal Template";
        FAJournalBatch: Record "FA Journal Batch";
    begin
        CreateFAJournalTemplate(FAJournalTemplate);
        CreateFAJournalBatch(FAJournalBatch, FAJournalTemplate.Name);

        LibraryFixedAsset.CreateFAJournalLine(FAJournalLine, FAJournalBatch."Journal Template Name", FAJournalBatch.Name);
        FAJournalLine.Validate("Document No.", GetFAJournalLineDocumentNo(FAJournalBatch));
        FAJournalLine.Validate("Posting Date", WorkDate());
        FAJournalLine.Validate("FA Posting Date", WorkDate());
        FAJournalLine.Validate("FA Posting Type", FAPostingType);
        FAJournalLine.Validate("FA No.", FANo);
        FAJournalLine.Validate("Debit Amount", LibraryRandom.RandDec(1000, 2));
        FAJournalLine.Validate("Depreciation Book Code", DepreciationBookCode);
        FAJournalLine.Modify(true);
    end;

    local procedure CreateGenJournalTemplate(var GenJournalTemplate: Record "Gen. Journal Template")
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.SetRange(Recurring, false);
        GenJournalTemplate.Modify(true);
    end;

    local procedure CreateGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch"; GenJournalTemplateName: Code[10])
    begin
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplateName);
        GenJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        GenJournalBatch.Modify(true);
    end;

    local procedure CreateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; DepreciationBookCode: Code[10]; FAPostingType: Enum "Gen. Journal Line FA Posting Type"; FANo: Code[20])
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGenJournalTemplate(GenJournalTemplate);
        CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);

        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"Fixed Asset", FANo, 0);
        GenJournalLine.Validate("Document No.", GetGenJournalLineDocumentNo(GenJournalBatch));
        GenJournalLine.Validate("Posting Date", WorkDate());
        GenJournalLine.Validate("FA Posting Date", WorkDate());
        GenJournalLine.Validate("FA Posting Type", FAPostingType);
        GenJournalLine.Validate("Depreciation Book Code", DepreciationBookCode);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateDepreciationBook(var DepreciationBook: Record "Depreciation Book")
    var
        FAPostingTypeSetup: Record "FA Posting Type Setup";
    begin
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        DepreciationBook.Validate("Disposal Calculation Method", DepreciationBook."Disposal Calculation Method"::Gross);
        DepreciationBook.Validate("Corresp. G/L Entries Disp. CZF", true);
        DepreciationBook.Validate("Corresp. FA Entries Disp. CZF", true);
        DepreciationBook.Validate("Deprec. from 1st Year Day CZF", true);
        DepreciationBook.Validate("Check Deprec. on Disposal CZF", true);
        DepreciationBook.Validate("Use FA Ledger Check", true);
        DepreciationBook.Validate("Use Rounding in Periodic Depr.", true);
        DepreciationBook.Modify(true);

        FAPostingTypeSetup.SetRange("Depreciation Book Code", DepreciationBook.Code);
        if FAPostingTypeSetup.FindSet() then
            repeat
                FAPostingTypeSetup."Include in Gain/Loss Calc." := true;
                FAPostingTypeSetup.Modify();
            until FAPostingTypeSetup.Next() = 0;
    end;

    local procedure CreateFADepreciationBook(var FADepreciationBook: Record "FA Depreciation Book"; FANo: Code[20]; DepreciationBookCode: Code[10]; DepreciationGroupCode: Code[20]; DefaultFADepreciationBook: Boolean; DepreciationMethod: Enum "FA Depreciation Method")
    var
        AccountingPeriodMgt: Codeunit "Accounting Period Mgt.";
    begin
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FANo, DepreciationBookCode);
        FADepreciationBook.Validate("Depreciation Starting Date", AccountingPeriodMgt.FindFiscalYear(WorkDate()));
        FADepreciationBook.Validate("Tax Deprec. Group Code CZF", DepreciationGroupCode);
        FADepreciationBook.Validate("Default FA Depreciation Book", DefaultFADepreciationBook);
        FADepreciationBook.Validate("Depreciation Method", DepreciationMethod);
        FADepreciationBook.Modify(true);
    end;

    local procedure CreateFAJournalSetup(var FAJournalSetup: Record "FA Journal Setup"; DepreciationBookCode: Code[10]; FAJournalTemplateName: Code[10]; FAJournalBatchName: Code[10])
    begin
        LibraryFixedAsset.CreateFAJournalSetup(FAJournalSetup, DepreciationBookCode, CopyStr(UserId(), 1, 50));
        FAJournalSetup.Validate("FA Jnl. Template Name", FAJournalTemplateName);
        FAJournalSetup.Validate("FA Jnl. Batch Name", FAJournalBatchName);
        FAJournalSetup.Modify(true);
    end;

    local procedure CreateTaxDepreciationGroupCZF(var TaxDepreciationGroupCZF: Record "Tax Depreciation Group CZF"; DepreciationType: Enum "Tax Depreciation Type CZF")
    begin
        LibraryFixedAssetCZF.CreateTaxDepreciationGroup(TaxDepreciationGroupCZF, CalcDate('<-CY-5Y>', WorkDate()));
        TaxDepreciationGroupCZF.Validate("Depreciation Group", LibraryFixedAssetCZF.GenerateDeprecationGroupCode());
        case DepreciationType of
            TaxDepreciationGroupCZF."Depreciation Type"::"Straight-line":
                UpdateTaxDepreciationGroupCZFStraightLine(TaxDepreciationGroupCZF);
            TaxDepreciationGroupCZF."Depreciation Type"::"Declining-Balance":
                UpdateTaxDepreciationGroupCZFDecliningBalance(TaxDepreciationGroupCZF);
            TaxDepreciationGroupCZF."Depreciation Type"::"Straight-line Intangible":
                UpdateTaxDepreciationGroupCZFStraightLineIntangible(TaxDepreciationGroupCZF);
        end;
    end;

    local procedure CreateFAPostingGroup(var FAPostingGroup: Record "FA Posting Group")
    begin
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);
        FAPostingGroup.Validate("Custom 2 Account", GetNewGLAccountNo());
        FAPostingGroup.Modify(true);
    end;

    local procedure CreateFAExtendedPostingGroupDisposal(var FAExtendedPostingGroupCZF: Record "FA Extended Posting Group CZF"; FAPostingGroupCode: Code[20])
    var
        ReasonCode: Record "Reason Code";
    begin
        CreateReasonCode(ReasonCode);
        LibraryFixedAssetCZF.CreateFAExtendedPostingGroup(
          FAExtendedPostingGroupCZF, FAPostingGroupCode, FAExtendedPostingGroupCZF."FA Posting Type"::Disposal, ReasonCode.Code);
        FAExtendedPostingGroupCZF.Validate("Book Val. Acc. on Disp. (Gain)", GetNewGLAccountNo());
        FAExtendedPostingGroupCZF.Validate("Book Val. Acc. on Disp. (Loss)", GetNewGLAccountNo());
        FAExtendedPostingGroupCZF.Validate("Sales Acc. On Disp. (Gain)", GetNewGLAccountNo());
        FAExtendedPostingGroupCZF.Validate("Sales Acc. On Disp. (Loss)", GetNewGLAccountNo());
        FAExtendedPostingGroupCZF.Modify(true);
    end;

    local procedure CreateReasonCode(var ReasonCode: Record "Reason Code")
    begin
        LibraryERM.CreateReasonCode(ReasonCode);
    end;

    local procedure CreateFALocation(var FALocation: Record "FA Location")
    begin
        LibraryFixedAssetCZF.CreateFALocation(FALocation);
    end;

    local procedure CreateEmployee(var Employee: Record Employee)
    begin
        LibraryHumanResource.CreateEmployee(Employee);
    end;

    local procedure CreateGLAccount(var GLAccount: Record "G/L Account")
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Posting Type", GLAccount."Gen. Posting Type"::Purchase);
        GLAccount.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Modify(true);
    end;

    local procedure UpdateTaxDepreciationGroupCZFStraightLine(var TaxDepreciationGroupCZF: Record "Tax Depreciation Group CZF")
    begin
        TaxDepreciationGroupCZF.Validate("Depreciation Type", TaxDepreciationGroupCZF."Depreciation Type"::"Straight-line");
        TaxDepreciationGroupCZF.Validate("No. of Depreciation Years", 3);
        TaxDepreciationGroupCZF.Validate("Straight First Year", 20);
        TaxDepreciationGroupCZF.Validate("Straight Next Years", 40);
        TaxDepreciationGroupCZF.Validate("Straight Appreciation", 33.3);
        TaxDepreciationGroupCZF.Modify(true);
    end;

    local procedure UpdateTaxDepreciationGroupCZFDecliningBalance(var TaxDepreciationGroupCZF: Record "Tax Depreciation Group CZF")
    begin
        TaxDepreciationGroupCZF.Validate("Depreciation Type", TaxDepreciationGroupCZF."Depreciation Type"::"Declining-Balance");
        TaxDepreciationGroupCZF.Validate("No. of Depreciation Years", 3);
        TaxDepreciationGroupCZF.Validate("Declining First Year", 3);
        TaxDepreciationGroupCZF.Validate("Declining Next Years", 4);
        TaxDepreciationGroupCZF.Validate("Declining Appreciation", 3);
        TaxDepreciationGroupCZF.Modify(true);
    end;

    local procedure UpdateTaxDepreciationGroupCZFStraightLineIntangible(var TaxDepreciationGroupCZF: Record "Tax Depreciation Group CZF")
    begin
        TaxDepreciationGroupCZF.Validate("Depreciation Type", TaxDepreciationGroupCZF."Depreciation Type"::"Straight-line Intangible");
        TaxDepreciationGroupCZF.Validate("No. of Depreciation Years", 3);
        TaxDepreciationGroupCZF.Validate("Min. Months After Appreciation", 18);
        TaxDepreciationGroupCZF.Modify(true);
    end;

    local procedure UpdateFASetup(TaxDeprBookCode: Code[10])
    var
        FASetup: Record "FA Setup";
    begin
        FASetup.Get();
        FASetup.Validate("Tax Depreciation Book CZF", TaxDeprBookCode);
        FASetup.Validate("Fixed Asset Nos.", LibraryERM.CreateNoSeriesCode());
        FASetup.Modify(true);
    end;

    local procedure UpdateFASetupWithFAHistory(FixedAssetHistory: Boolean)
    var
        FASetup: Record "FA Setup";
    begin
        LibraryVariableStorage.Enqueue(WorkDate());
        FASetup.Get();
        FASetup.Validate("Fixed Asset History CZF", FixedAssetHistory);
        FASetup.Validate("Fixed Asset History Nos. CZF", LibraryERM.CreateNoSeriesCode());
        FASetup.Modify(true);
    end;

    local procedure UpdateHumanResourcesSetup()
    var
        HumanResourcesSetup: Record "Human Resources Setup";
    begin
        HumanResourcesSetup.Get();
        HumanResourcesSetup.Validate("Employee Nos.", LibraryERM.CreateNoSeriesCode());
        HumanResourcesSetup.Modify(true);
    end;

    local procedure GetFAJournalLineDocumentNo(FAJournalBatch: Record "FA Journal Batch"): Code[20]
    var
        NoSeries: Record "No. Series";
        NoSeriesCodeunit: Codeunit "No. Series";
    begin
        NoSeries.Get(FAJournalBatch."No. Series");
        exit(NoSeriesCodeunit.PeekNextNo(FAJournalBatch."No. Series"));
    end;

    local procedure GetGenJournalLineDocumentNo(GenJournalBatch: Record "Gen. Journal Batch"): Code[20]
    var
        NoSeries: Record "No. Series";
        NoSeriesCodeunit: Codeunit "No. Series";
    begin
        NoSeries.Get(GenJournalBatch."No. Series");
        exit(NoSeriesCodeunit.PeekNextNo(GenJournalBatch."No. Series"));
    end;

    local procedure GetNewGLAccountNo(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        CreateGLAccount(GLAccount);
        exit(GLAccount."No.");
    end;

    local procedure PostDepreciationWithDocumentNo(DepreciationBookCode: Code[10])
    var
        FAJournalLine: Record "FA Journal Line";
        FAJournalSetup: Record "FA Journal Setup";
        FAJournalBatch: Record "FA Journal Batch";
    begin
        FAJournalSetup.Get(DepreciationBookCode, UserId);
        FAJournalLine.SetRange("Journal Template Name", FAJournalSetup."FA Jnl. Template Name");
        FAJournalLine.SetRange("Journal Batch Name", FAJournalSetup."FA Jnl. Batch Name");
        FAJournalLine.FindFirst();

        FAJournalBatch.Get(FAJournalLine."Journal Template Name", FAJournalLine."Journal Batch Name");
        FAJournalBatch.Validate("No. Series", '');
        FAJournalBatch.Modify(true);

        PostFAJournalLine(FAJournalLine);
    end;

    local procedure PostFAJournalLine(var FAJournalLine: Record "FA Journal Line")
    begin
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);
    end;

    local procedure PostGenJournalLine(var GenJournalLine: Record "Gen. Journal Line")
    begin
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure RunCalculateDepreciation(var FixedAsset: Record "Fixed Asset"; DepreciationBookCode: Code[10])
    begin
        FixedAsset.SetRecFilter();
        LibraryFixedAssetCZF.RunCalculateDepreciation(
          FixedAsset, DepreciationBookCode, CalcDate('<CY>', WorkDate()), FixedAsset."No.", FixedAsset.Description);
    end;

    local procedure SetExpectedConfirm(Question: Text; Reply: Boolean)
    begin
        LibraryDialogHandler.SetExpectedConfirm(Question, Reply);
    end;

    [ModalPageHandler]
    procedure ModalTaxDepreciationGroupCZFsHandler(var TaxDepreciationGroupsCZF: TestPage "Tax Depreciation Groups CZF")
    begin
        Assert.IsTrue(
          TaxDepreciationGroupsCZF.Filter.GetFilter("Depreciation Group") = Format(LibraryVariableStorage.DequeueText()), DepreciationGroupFilterErr);
    end;

    [ModalPageHandler]
    procedure ModalCreateFAHistoryHandler(var CreateFAHistoryCZF: TestPage "Create FA History CZF")
    begin
        CreateFAHistoryCZF.OK().Invoke();
    end;

    [MessageHandler]
    procedure MessageHandler(Message: Text)
    begin
        // Dummy Message Handler
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        LibraryDialogHandler.HandleConfirm(Question, Reply);
    end;

    // [ConfirmHandler]
    // procedure EndingValueSetupConfirmHandler(Message: Text[1024]; var Reply: Boolean)
    // begin
    //     Assert.IsTrue(StrPos(Message, 'new depreciation') > 0, 'The confirmation must describe the depreciation calculation change.');
    //     Reply := LibraryVariableStorage.DequeueBoolean();
    // end;

    [ConfirmHandler]
    procedure NoConfirmHandler(Message: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;
}

