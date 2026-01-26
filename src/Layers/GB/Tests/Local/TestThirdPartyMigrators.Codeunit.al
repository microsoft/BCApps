codeunit 144503 "Test Third Party Migrators"
{
    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        IsInitialized: Boolean;
        SageDataMigratorDescriptionTxt: Label 'Import from Sage Line 50 delivered by Technology Management';

    [Test]
    [HandlerFunctions('DataMigratorsPageHandler,ConfirmYesHandler,ExtensionManagementPageHandler')]
    [Scope('OnPrem')]
    procedure SageExtensionNotInstalledMigratorRegistered()
    var
        DataMigrationWizard: TestPage "Data Migration Wizard";
    begin
        // [SCENARIO] Verify that 3rd party Sage Data Migration is shown even the extension is not installed
        // [GIVEN] Sage extension not installed and Data Migration is started
        Initialize();

        // [WHEN] The data migration wizard is run
        // [THEN] Sage migrator is registered
        LibraryLowerPermissions.SetO365Basic();
        LibraryLowerPermissions.AddO365Setup();
        LibraryLowerPermissions.AddO365ExtensionMGT();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        DataMigrationWizard.Trap();
        PAGE.Run(PAGE::"Data Migration Wizard");
        LibraryVariableStorage.Enqueue(GetSageCodeunitNumber());

        DataMigrationWizard.ActionNext.Invoke();
        // Choose Data Source page
        DataMigrationWizard.Description.Lookup();
        // Lookup to different data migrations tools
        DataMigrationWizard.Description.SetValue(SageDataMigratorDescriptionTxt);
        // [THEN] Instruction that Sage extension must be installed is shown
        DataMigrationWizard.ActionNext.Invoke();
        // Instructions & Settings
        // [THEN] Extension Management page is displayed
    end;

    local procedure Initialize()
    var
        DataMigrationEntity: Record "Data Migration Entity";
    begin
        LibraryVariableStorage.Clear();
        if IsInitialized then
            exit;

        DataMigrationEntity.DeleteAll();

        IsInitialized := true;
    end;

    local procedure GetSageCodeunitNumber(): Integer
    begin
        exit(70000005); // Sage Data Migrator No
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DataMigratorsPageHandler(var DataMigrators: TestPage "Data Migrators")
    var
        CodeunitNumber: Integer;
    begin
        CodeunitNumber := LibraryVariableStorage.DequeueInteger();
        DataMigrators.GotoKey(CodeunitNumber);
        DataMigrators.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmYesHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ExtensionManagementPageHandler(var ExtensionManagement: TestPage "Extension Management")
    begin
    end;
}

