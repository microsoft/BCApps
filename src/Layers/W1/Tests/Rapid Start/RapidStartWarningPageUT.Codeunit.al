codeunit 139188 "RapidStart Warning Page UT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        EnviromentInfoLibrary: Codeunit "Environment Info Test Library";

    trigger OnRun()
    begin
        // [FEATURE] [Rapid Start] [Data Exchange] [Mapping]
    end;

    [Test]
    [HandlerFunctions('ConfigPackageWarningOK')]
    procedure WarningPageIsShownWhenApplyingBigPackages()
    var
        ConfigPackageManagement: Codeunit "Config. Package Management";
    begin
        // [GIVEN] In SaaS
        // [GIVEN] User clicks OK 
        EnviromentInfoLibrary.SetTestabilitySoftwareAsAService(true);
        // [THEN] The warning page is shwonn and the Response is Ok
        Assert.IsTrue(Action::OK = ConfigPackageManagement.ShowWarningOnApplyingBigConfPackage(5001), 'Action::OK was expected');
    end;

    [Test]
    [HandlerFunctions('ConfigPackageWarningCancel')]
    procedure WarningPageIsShownWhenImportingBigRapidstartFiles()
    var
        ConfigPackageManagement: Codeunit "Config. Package Management";
    begin
        // [GIVEN] In SaaS
        // [GIVEN] User clicks Cancel 
        EnviromentInfoLibrary.SetTestabilitySoftwareAsAService(true);
        // [THEN] The warning page is shwonn and the Response is Cancel
        Assert.IsTrue(Action::Cancel = ConfigPackageManagement.ShowWarningOnImportingBigConfPackageFromRapidStart(3145729), 'Action::Cancel was expected');
    end;

    [Test]
    [HandlerFunctions('ConfigPackageWarningClose')]
    procedure WarningPageIsShownWhenImportingBigExcelFiles()
    var
        ConfigPackageManagement: Codeunit "Config. Package Management";
    begin
        // [GIVEN] In SaaS
        // [GIVEN] User closes the page
        EnviromentInfoLibrary.SetTestabilitySoftwareAsAService(true);
        // [THEN] The warning page is shwonn and the Response is Cancel
        Assert.IsTrue(Action::Cancel = ConfigPackageManagement.ShowWarningOnImportingBigConfPackageFromExcel(3145729), 'Action::Cancel was expected');
    end;

    [Test]
    procedure WarningPageIsNotShownOnPrem()
    var
        ConfigPackageManagement: Codeunit "Config. Package Management";
    begin
        // [GIVEN] Not SaaS
        EnviromentInfoLibrary.SetTestabilitySoftwareAsAService(false);

        // [WHEN] The ShowWarning* function are called
        ConfigPackageManagement.ShowWarningOnApplyingBigConfPackage(5001); // 1 more than the limit
        ConfigPackageManagement.ShowWarningOnImportingBigConfPackageFromExcel(3145729); // 1 more than 3MB
        ConfigPackageManagement.ShowWarningOnImportingBigConfPackageFromRapidStart(3145729);
        // [THEN] The warning is not showm / No Error for missing handler
    end;

    [Test]
    procedure WarningPageIsNotShownForSmallFileSizes()
    var
        ConfigPackageManagement: Codeunit "Config. Package Management";
    begin
        // [GIVEN] In SaaS
        EnviromentInfoLibrary.SetTestabilitySoftwareAsAService(true);

        // [GIVEN] Small file sizes and a few Records
        // [WHEN] The ShowWarning* function are called
        ConfigPackageManagement.ShowWarningOnApplyingBigConfPackage(4000);
        ConfigPackageManagement.ShowWarningOnImportingBigConfPackageFromRapidStart(200000);
        ConfigPackageManagement.ShowWarningOnImportingBigConfPackageFromExcel(200000);
        // [THEN] The warning is not showm / No Error for missing handler
    end;


    [ModalPageHandler]
    procedure ConfigPackageWarningOK(var ConfigPackageWarning: TestPage "Config. Package Warning")
    begin
        Assert.IsFalse(ConfigPackageWarning.Ok.Enabled(), 'Ok Action Should be disabled');
        ConfigPackageWarning.ConfirmationField.SetValue(true);
        ConfigPackageWarning.Ok.Invoke();
    end;

    [ModalPageHandler]
    procedure ConfigPackageWarningCancel(var ConfigPackageWarning: TestPage "Config. Package Warning")
    begin
        ConfigPackageWarning.Cancel.Invoke();
    end;

    [ModalPageHandler]
    procedure ConfigPackageWarningClose(var ConfigPackageWarning: TestPage "Config. Package Warning")
    begin
    end;
}

