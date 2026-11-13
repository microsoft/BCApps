// [FEATURE] [Fixed Assets] [UI]
codeunit 148140 "Fixed Assets UI CZF"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    var
        LibraryDialogHandler: Codeunit "Library - Dialog Handler";
        LibraryERM: Codeunit "Library - ERM";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryFixedAssetCZF: Codeunit "Library - Fixed Asset CZF";
        LibraryHumanResource: Codeunit "Library - Human Resource";
        isInitialized: Boolean;
        ChangeCalculationQst: Label 'Changing this setting changes the way new depreciation is calculated. Do you really want to make the change?';

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure EndingBookValueEnableDeclined()
    var
        FASetup: Record "FA Setup";
        FixedAssetSetup: TestPage "Fixed Asset Setup";
    begin
        // [SCENARIO] Declining residual inclusion leaves the setting disabled.
        Initialize();

        // [GIVEN] The setting is disabled and the setup page is editable.
        SetIncludeEndingBookValue(false);
        LibraryDialogHandler.SetExpectedConfirm(ChangeCalculationQst, false);
        FixedAssetSetup.OpenEdit();

        // [WHEN] Enabling residual inclusion is declined.
        FixedAssetSetup."Incl. Ending Book Value CZF".SetValue(true);

        // [THEN] The page and stored setting remain disabled.
        FixedAssetSetup."Incl. Ending Book Value CZF".AssertEquals(false);
        FixedAssetSetup.Close();
        FASetup.Get();
        FASetup.TestField("Incl. Ending Book Value CZF", false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure EndingBookValueEnableAccepted()
    var
        FASetup: Record "FA Setup";
        FixedAssetSetup: TestPage "Fixed Asset Setup";
    begin
        // [SCENARIO] Accepting residual inclusion persists the enabled setting.
        Initialize();

        // [GIVEN] The setting is disabled and the setup page is editable.
        SetIncludeEndingBookValue(false);
        LibraryDialogHandler.SetExpectedConfirm(ChangeCalculationQst, true);
        FixedAssetSetup.OpenEdit();

        // [WHEN] Enabling residual inclusion is accepted.
        FixedAssetSetup."Incl. Ending Book Value CZF".SetValue(true);

        // [THEN] The page and stored setting are enabled.
        FixedAssetSetup."Incl. Ending Book Value CZF".AssertEquals(true);
        FixedAssetSetup.Close();
        FASetup.Get();
        FASetup.TestField("Incl. Ending Book Value CZF", true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure EndingBookValueDisableDeclined()
    var
        FASetup: Record "FA Setup";
        FixedAssetSetup: TestPage "Fixed Asset Setup";
    begin
        // [SCENARIO] Declining removal of residual inclusion leaves the setting enabled.
        Initialize();

        // [GIVEN] The setting is enabled and the setup page is editable.
        SetIncludeEndingBookValue(true);
        LibraryDialogHandler.SetExpectedConfirm(ChangeCalculationQst, false);
        FixedAssetSetup.OpenEdit();

        // [WHEN] Disabling residual inclusion is declined.
        FixedAssetSetup."Incl. Ending Book Value CZF".SetValue(false);

        // [THEN] The page and stored setting remain enabled.
        FixedAssetSetup."Incl. Ending Book Value CZF".AssertEquals(true);
        FixedAssetSetup.Close();
        FASetup.Get();
        FASetup.TestField("Incl. Ending Book Value CZF", true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure EndingBookValueDisableAccepted()
    var
        FASetup: Record "FA Setup";
        FixedAssetSetup: TestPage "Fixed Asset Setup";
    begin
        // [SCENARIO] Accepting removal of residual inclusion persists the disabled setting.
        Initialize();

        // [GIVEN] The setting is enabled and the setup page is editable.
        SetIncludeEndingBookValue(true);
        LibraryDialogHandler.SetExpectedConfirm(ChangeCalculationQst, true);
        FixedAssetSetup.OpenEdit();

        // [WHEN] Disabling residual inclusion is accepted.
        FixedAssetSetup."Incl. Ending Book Value CZF".SetValue(false);

        // [THEN] The page and stored setting are disabled.
        FixedAssetSetup."Incl. Ending Book Value CZF".AssertEquals(false);
        FixedAssetSetup.Close();
        FASetup.Get();
        FASetup.TestField("Incl. Ending Book Value CZF", false);
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
        // [SCENARIO] Changing the responsible employee and location on the asset card creates history entries.
        Initialize();

        // [GIVEN] Fixed asset history is enabled.
        UpdateFASetupWithFAHistory(true);

        // [GIVEN] An employee, location and fixed asset exist.
        LibraryHumanResource.CreateEmployee(Employee);
        LibraryFixedAssetCZF.CreateFALocation(FALocation);
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);

        // [WHEN] The responsible employee and location are changed on the fixed asset card.
        FixedAssetCard.OpenEdit();
        FixedAssetCard.GoToRecord(FixedAsset);
        FixedAssetCard."Responsible Employee".SetValue(Employee."No.");
        FixedAssetCard."FA Location Code".SetValue(FALocation.Code);
        FixedAssetCard.OK().Invoke();

        // [THEN] History entries contain the new employee and location.
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

    local procedure Initialize()
    var
        FASetup: Record "FA Setup";
        HumanResourcesSetup: Record "Human Resources Setup";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Fixed Assets UI CZF");
        LibraryDialogHandler.ClearVariableStorage();
        if isInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Fixed Assets UI CZF");

        FASetup.Get();
        FASetup.Validate("Fixed Asset Nos.", LibraryERM.CreateNoSeriesCode());
        FASetup.Modify(true);
        HumanResourcesSetup.Get();
        HumanResourcesSetup.Validate("Employee Nos.", LibraryERM.CreateNoSeriesCode());
        HumanResourcesSetup.Modify(true);

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Fixed Assets UI CZF");
    end;

    local procedure SetIncludeEndingBookValue(IncludeEndingBookValue: Boolean)
    var
        FASetup: Record "FA Setup";
    begin
        FASetup.Get();
        FASetup.Validate("Incl. Ending Book Value CZF", IncludeEndingBookValue);
        FASetup.Modify(true);
    end;

    local procedure UpdateFASetupWithFAHistory(FixedAssetHistory: Boolean)
    var
        FASetup: Record "FA Setup";
    begin
        FASetup.Get();
        FASetup.Validate("Fixed Asset History CZF", FixedAssetHistory);
        FASetup.Validate("Fixed Asset History Nos. CZF", LibraryERM.CreateNoSeriesCode());
        FASetup.Modify(true);
    end;

    [ModalPageHandler]
    procedure ModalCreateFAHistoryHandler(var CreateFAHistoryCZF: TestPage "Create FA History CZF")
    begin
        CreateFAHistoryCZF.OK().Invoke();
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        LibraryDialogHandler.HandleConfirm(Question, Reply);
    end;

    [ConfirmHandler]
    procedure NoConfirmHandler(Message: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;
}