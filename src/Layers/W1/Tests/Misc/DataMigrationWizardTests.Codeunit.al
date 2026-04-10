codeunit 139305 "Data Migration Wizard Tests"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Data Migration]
    end;

    var
        Assert: Codeunit Assert;
        OnRegisterDataMigratorTxt: Label 'OnRegisterDataMigrator';
        OnHasSettingsTxt: Label 'OnHasSettings';
        OnOpenSettingsTxt: Label 'OnOpenSettings';
        OnGetInstructionsTxt: Label 'OnGetInstructions';
        OnHasTemplateTxt: Label 'OnHasTemplate';
        OnDownloadTemplateTxt: Label 'OnDownloadTemplate';
        OnDataImportTxt: Label 'OnDataImport';
        OnSelectDataToApplyTxt: Label 'OnSelectDataToApply';
        OnHasAdvancedApplyTxt: Label 'OnHasAdvancedApply';
        OnOpenAdvancedApplyTxt: Label 'OnOpenAdvancedApply';
        OnApplySelectedDataTxt: Label 'OnApplySelectedData';
        OnHasErrorsTxt: Label 'OnHasErrors';
        OnShowErrorsTxt: Label 'OnShowErrors';
        InsertDataMigrationRecordsTxt: Label 'InsertDataMigrationRecords';
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        PostingOptionsTok: Label 'PostingOptions', Locked = true;
        DuplicateContacatsTextTok: Label 'DuplicateContact', Locked = true;
        ShowBalanceTok: Label 'ShowBalance', Locked = true;
        ThatsItTok: Label 'ThatsIt';
        HideSelectedTok: Label 'HideSelected', Locked = true;

    local procedure Initialize(InsertDataForImport: Boolean)
    var
        AssistedSetupTestLibrary: Codeunit "Assisted Setup Test Library";
        DataTypeBuffer: Record "Data Type Buffer";
        AccountingPeriod: Record "Accounting Period";
        LibraryAzureKVMockMgmt: Codeunit "Library - Azure KV Mock Mgmt.";
    begin
        DataTypeBuffer.DeleteAll(true);
        AssistedSetupTestLibrary.DeleteAll();
        LibraryAzureKVMockMgmt.InitMockAzureKeyvaultSecretProvider();

        AssistedSetupTestLibrary.CallOnRegister();
        AccountingPeriod.DeleteAll();

        if InsertDataForImport then
            PopulateDataMigrationEntityRecord();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestWizardVerifyCostingMethodChange()
    var
        InventorySetup: Record "Inventory Setup";
        CostingMethodConfiguration: TestPage "Costing Method Configuration";
    begin
        // [WHEN] Opening Costing Method Configuration Page
        CostingMethodConfiguration.Trap();
        PAGE.Run(PAGE::"Costing Method Configuration");

        // [WHEN] Changing the costing method to Average
        CostingMethodConfiguration."Costing Method".SetValue(InventorySetup."Default Costing Method"::Average);

        // [THEN] The inventory setup Default Costing Method is updated to Average both in the Page and the Table
        InventorySetup.Reset();
        InventorySetup.Get();
        InventorySetup.TestField("Default Costing Method", InventorySetup."Default Costing Method"::Average);
        CostingMethodConfiguration."Costing Method".AssertEquals(InventorySetup."Default Costing Method");

        // [WHEN] Changing the costing method to Average
        CostingMethodConfiguration."Costing Method".SetValue(InventorySetup."Default Costing Method"::LIFO);

        // [THEN] The inventory setup Default Costing Method is updated to Average both in the Page and the Table
        InventorySetup.Reset();
        InventorySetup.Get();
        InventorySetup.TestField("Default Costing Method", InventorySetup."Default Costing Method"::LIFO);
        CostingMethodConfiguration."Costing Method".AssertEquals(InventorySetup."Default Costing Method");

        // [WHEN] Reopening the Wizard on the costing method page
        CostingMethodConfiguration.Close();
        CostingMethodConfiguration.Trap();
        PAGE.Run(PAGE::"Costing Method Configuration");

        // // [THEN] The wizard shows the previously changed value of Average
        CostingMethodConfiguration."Costing Method".AssertEquals(InventorySetup."Default Costing Method"::LIFO);
    end;

    [Test]
    [HandlerFunctions('NotificationHandler,ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure TestNotificationCostingMethodWhenPageOpens()
    var
        DataMigrationWizard: TestPage "Data Migration Wizard";
    begin
        DataMigrationWizard.OpenView();
        DataMigrationWizard.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler,DataMigrationOverviewHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VerifyOnlyOneMigration()
    var
        DataMigrationStatus: Record "Data Migration Status";
        DataMigrationWizard: TestPage "Data Migration Wizard";
    begin
        // [GIVEN] A newly setup company where the data migration wizard test extension is bound
        Initialize(true);

        // [WHEN] The data migration wizard is run with no migrations in progress or pending
        DataMigrationWizard.Trap();
        PAGE.Run(PAGE::"Data Migration Wizard");

        // [THEN] the page opens fine
        DataMigrationWizard.Close();

        // [WHEN] The data migration wizard is run with a migration in progress
        DataMigrationStatus.Init();
        DataMigrationStatus.Status := DataMigrationStatus.Status::"In Progress";
        DataMigrationStatus.Insert();

        // [THEN] an error is raised
        DataMigrationWizard.Trap();
        asserterror PAGE.Run(PAGE::"Data Migration Wizard");

        // Verify on DataMigrationOverviewHandler
    end;

    [Test]
    [HandlerFunctions('DataMigratorsPageHandler,ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VerifyStatusNotCompletedWhenNotFinished()
    var
        GuidedExperience: Codeunit "Guided Experience";
        DataMigrationWizardTests: Codeunit "Data Migration Wizard Tests";
        DataMigrationWizard: TestPage "Data Migration Wizard";
    begin
        // [GIVEN] A newly setup company where the data migration wizard test extension is bound
        Initialize(true);
        BindSubscription(DataMigrationWizardTests);

        // [WHEN] The data migration wizard is run to the end but not finished
        RunWizardToCompletionAndTestEvents(DataMigrationWizard);
        DataMigrationWizard.Close();

        // [THEN] Status of assisted setup remains Not Completed
        Assert.IsFalse(GuidedExperience.IsAssistedSetupComplete(ObjectType::Page, PAGE::"Data Migration Wizard"), 'Migrate Data status should not be completed.');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VerifyStatusNotCompletedWhenExitRightAway()
    var
        GuidedExperience: Codeunit "Guided Experience";
        DataMigrationWizardTests: Codeunit "Data Migration Wizard Tests";
        DataMigrationWizard: TestPage "Data Migration Wizard";
    begin
        // [GIVEN] A newly setup company where the data migration wizard test extension is bound
        Initialize(true);
        BindSubscription(DataMigrationWizardTests);

        // [WHEN] The data migration wizard is exited right away
        DataMigrationWizard.Trap();
        PAGE.Run(PAGE::"Data Migration Wizard");
        DataMigrationWizard.Close();

        // [THEN] Status of assisted setup remains Not Completed
        Assert.IsFalse(GuidedExperience.IsAssistedSetupComplete(ObjectType::Page, PAGE::"Data Migration Wizard"), 'Migrate Data status should not be completed.');
    end;

    [Test]
    [HandlerFunctions('DataMigratorsPageHandler,DataMigrationOverviewHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VerifyStatusCompletedWhenFinished()
    var
        GuidedExperience: Codeunit "Guided Experience";
        DataMigrationWizardTests: Codeunit "Data Migration Wizard Tests";
        DataMigrationWizard: TestPage "Data Migration Wizard";
    begin
        // [GIVEN] A newly setup company where the data migration wizard test extension is bound
        Initialize(true);
        BindSubscription(DataMigrationWizardTests);

        // [WHEN] The data migration wizard is completed
        RunWizardToCompletionAndTestEvents(DataMigrationWizard);
        DataMigrationWizard.ActionFinish.Invoke();

        // [THEN] Status of the setup step is set to Completed
        Assert.IsTrue(GuidedExperience.IsAssistedSetupComplete(ObjectType::Page, PAGE::"Data Migration Wizard"), 'Migrate Data status should be completed.');
    end;

    [Test]
    [HandlerFunctions('ConfirmNoHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VerifyWizardNotExitedWhenConfirmIsNo()
    var
        GuidedExperience: Codeunit "Guided Experience";
        DataMigrationWizardTests: Codeunit "Data Migration Wizard Tests";
        DataMigrationWizard: TestPage "Data Migration Wizard";
    begin
        // [GIVEN] A newly setup company where the data migration wizard test extension is bound
        Initialize(true);
        BindSubscription(DataMigrationWizardTests);

        // [WHEN] The data migration wizard is closed but closing is not confirmed
        DataMigrationWizard.Trap();
        PAGE.Run(PAGE::"Data Migration Wizard");
        DataMigrationWizard.Close();

        // [THEN] Status of assisted setup remains Not Completed
        Assert.IsFalse(GuidedExperience.IsAssistedSetupComplete(ObjectType::Page, PAGE::"Data Migration Wizard"), 'Migrate Data status should not be completed.');

        // [THEN] No events were fired
        VerifyDataTypeBuffer(OnGetInstructionsTxt, false);
        VerifyDataTypeBuffer(OnDataImportTxt, false);
        VerifyDataTypeBuffer(OnSelectDataToApplyTxt, false);
        VerifyDataTypeBuffer(OnApplySelectedDataTxt, false);
    end;

    [Test]
    [HandlerFunctions('DataMigratorsPageHandler,ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure VerifySettingsButtonWorks()
    var
        DataMigrationWizardTests: Codeunit "Data Migration Wizard Tests";
        DataMigrationWizard: TestPage "Data Migration Wizard";
    begin
        // [GIVEN] A newly setup company where the data migration wizard test extension is bound
        Initialize(true);
        BindSubscription(DataMigrationWizardTests);

        // [WHEN] The data migration wizard executed to the "Choose Data Source" page and the Settings button is pressed
        DataMigrationWizard.Trap();
        PAGE.Run(PAGE::"Data Migration Wizard");
        DataMigrationWizard.ActionNext.Invoke(); // Choose Data Source page
        DataMigrationWizard.Description.Lookup();
        DataMigrationWizard.ActionDataMigrationSettings.Invoke();

        // [THEN] The right events are fired
        VerifyDataTypeBuffer(OnHasSettingsTxt, true);
        VerifyDataTypeBuffer(OnOpenSettingsTxt, true);
    end;

    [Test]
    [HandlerFunctions('DataMigratorsPageHandler,ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure VerifyDownloadTemplateButtonWorks()
    var
        DataMigrationWizardTests: Codeunit "Data Migration Wizard Tests";
        DataMigrationWizard: TestPage "Data Migration Wizard";
    begin
        // [GIVEN] A newly setup company where the data migration wizard test extension is bound
        Initialize(true);
        BindSubscription(DataMigrationWizardTests);

        // [WHEN] The data migration wizard executed to the "Upload Data File page" page and the Download Template button is pressed
        DataMigrationWizard.Trap();
        PAGE.Run(PAGE::"Data Migration Wizard");
        DataMigrationWizard.ActionNext.Invoke(); // Choose Data Source page
        DataMigrationWizard.Description.Lookup();
        DataMigrationWizard.ActionNext.Invoke(); // Upload Data File page

        DataMigrationWizard.ActionDownloadTemplate.Invoke();

        // [THEN] The right events are fired
        VerifyDataTypeBuffer(OnHasTemplateTxt, true);
        VerifyDataTypeBuffer(OnDownloadTemplateTxt, true);
    end;

    [Test]
    [HandlerFunctions('DataMigratorsPageHandler,ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure VerifyAdvancedButtonWorks()
    var
        DataMigrationWizardTests: Codeunit "Data Migration Wizard Tests";
        DataMigrationWizard: TestPage "Data Migration Wizard";
    begin
        // [GIVEN] A newly setup company where the data migration wizard test extension is bound
        Initialize(true);
        BindSubscription(DataMigrationWizardTests);

        // [WHEN] The data migration wizard executed to the "Apply" page and the Advaced button is pressed
        DataMigrationWizard.Trap();
        PAGE.Run(PAGE::"Data Migration Wizard");
        DataMigrationWizard.ActionNext.Invoke(); // Choose Data Source page
        DataMigrationWizard.Description.Lookup();
        DataMigrationWizard.ActionNext.Invoke(); // Upload Data File page
        DataMigrationWizard.ActionNext.Invoke(); // Apply Imported Data page
        DataMigrationWizard.ActionOpenAdvancedApply.Invoke();

        // [THEN] The right events are fired
        VerifyDataTypeBuffer(OnHasAdvancedApplyTxt, true);
        VerifyDataTypeBuffer(OnOpenAdvancedApplyTxt, true);
    end;

    [Test]
    [HandlerFunctions('DataMigratorsPageHandler,ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure VerifyErrorButtonWorks()
    var
        DataMigrationWizardTests: Codeunit "Data Migration Wizard Tests";
        DataMigrationWizard: TestPage "Data Migration Wizard";
    begin
        // [GIVEN] A newly setup company where the data migration wizard test extension is bound
        Initialize(true);
        BindSubscription(DataMigrationWizardTests);

        // [WHEN] The data migration wizard executed to the "Finish" page and the Errors button is pressed
        DataMigrationWizard.Trap();
        PAGE.Run(PAGE::"Data Migration Wizard");
        DataMigrationWizard.ActionNext.Invoke(); // Choose Data Source page
        DataMigrationWizard.Description.Lookup();
        DataMigrationWizard.ActionNext.Invoke(); // Upload Data File page
        DataMigrationWizard.ActionNext.Invoke(); // Apply Imported Data page
        DataMigrationWizard.ActionApply.Invoke(); // That's it page
        DataMigrationWizard.ActionShowErrors.Invoke();

        // [THEN] The right events are fired
        VerifyDataTypeBuffer(OnHasErrorsTxt, true);
        VerifyDataTypeBuffer(OnShowErrorsTxt, true);
    end;

    [Test]
    [HandlerFunctions('DataMigratorsPageHandler,ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure VerifyImportDisabledIfNoRecordsToImport()
    var
        DataMigrationWizardTests: Codeunit "Data Migration Wizard Tests";
        DataMigrationWizard: TestPage "Data Migration Wizard";
    begin
        // [GIVEN] A newly setup company where the data migration wizard test extension is bound and no import records exist
        Initialize(false);
        BindSubscription(DataMigrationWizardTests);

        // [WHEN] The data migration wizard executed to the "Apply" page
        DataMigrationWizard.Trap();
        PAGE.Run(PAGE::"Data Migration Wizard");
        DataMigrationWizard.ActionNext.Invoke(); // Choose Data Source page
        DataMigrationWizard.Description.Lookup();
        DataMigrationWizard.ActionNext.Invoke(); // Upload Data File page
        DataMigrationWizard.ActionNext.Invoke(); // Apply Imported Data page

        // [THEN] The next button is disabled, if no records exist
        Assert.IsFalse(DataMigrationWizard.ActionNext.Visible(), 'Next button is enabled even if no records exist');
        Assert.IsFalse(DataMigrationWizard.ActionApply.Enabled(), 'Apply button is enabled even if no records exist');
    end;

    [Test]
    [HandlerFunctions('DataMigratorsPageHandler,ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure VerifyImportEnabledIfRecordsToImport()
    var
        DataMigrationWizardTests: Codeunit "Data Migration Wizard Tests";
        DataMigrationWizard: TestPage "Data Migration Wizard";
    begin
        // [GIVEN] A newly setup company where the data migration wizard test extension is bound
        Initialize(true);
        BindSubscription(DataMigrationWizardTests);

        // [WHEN] The data migration wizard executed to the "Apply" page
        DataMigrationWizard.Trap();
        PAGE.Run(PAGE::"Data Migration Wizard");
        DataMigrationWizard.ActionNext.Invoke(); // Choose Data Source page
        DataMigrationWizard.Description.Lookup();
        DataMigrationWizard.ActionNext.Invoke(); // Upload Data File page
        DataMigrationWizard.ActionNext.Invoke(); // Apply Imported Data page

        // [THEN] The next button is enabled, if records exist
        Assert.IsFalse(DataMigrationWizard.ActionNext.Visible(), 'Next hidden');
        Assert.IsTrue(DataMigrationWizard.ActionApply.Enabled(), 'Apply button is disabled even if records exist');
    end;

    [Test]
    [HandlerFunctions('DataMigratorsPageHandler,ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure VerifyDuplicateContactsTextIsShownOnEvent()
    var
        DataMigrationWizardTests: Codeunit "Data Migration Wizard Tests";
        DataMigrationWizard: TestPage "Data Migration Wizard";
    begin
        // [GIVEN] A newly setup company where the data migration wizard test extension is bound
        Initialize(true);
        LibraryVariableStorage.Enqueue(DuplicateContacatsTextTok); // Recipient of the event
        LibraryVariableStorage.Enqueue(true); // Show duplicate contact text
        BindSubscription(DataMigrationWizardTests);
        DataMigrationWizardTests.SetVariableStorage(LibraryVariableStorage);

        // [WHEN] The data migration wizard executed to the "That's it" page
        RunWizardToCompletionAndTestEvents(DataMigrationWizard);

        // [THEN] Duplicate contact group is visible
        Assert.IsTrue(DataMigrationWizard.DuplicateContacts.Visible(),
          'Duplicate contacts group was set to visible in event but it is hidden');
    end;

    [Test]
    [HandlerFunctions('DataMigratorsPageHandler,ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure VerifyDuplicateContactsTextIsHiddenByDefault()
    var
        DataMigrationWizardTests: Codeunit "Data Migration Wizard Tests";
        DataMigrationWizard: TestPage "Data Migration Wizard";
    begin
        // [GIVEN] A newly setup company where the data migration wizard test extension is bound
        Initialize(true);
        BindSubscription(DataMigrationWizardTests);

        // [WHEN] The data migration wizard executed to the "That's it" page
        RunWizardToCompletionAndTestEvents(DataMigrationWizard);

        // [THEN] Duplicate contact group is visible
        Assert.IsFalse(DataMigrationWizard.DuplicateContacts.Visible(),
          'Duplicate contacts group must be hidden by default.');
    end;

    [Test]
    [HandlerFunctions('DataMigratorsPageHandler,ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure VerifyPostingOptionsVisibleOnEventAndAutomaticPost()
    var
        DataMigrationWizardTests: Codeunit "Data Migration Wizard Tests";
        DataMigrationWizard: TestPage "Data Migration Wizard";
    begin
        // [GIVEN] A newly setup company where the data migration wizard test extension is bound
        Initialize(true);
        LibraryVariableStorage.Enqueue(PostingOptionsTok); // Recipient of the event
        LibraryVariableStorage.Enqueue(true); // Show posting options
        BindSubscription(DataMigrationWizardTests);
        DataMigrationWizardTests.SetVariableStorage(LibraryVariableStorage);

        // [WHEN] The data migration wizard executed to the "Apply" page
        RunWizardToApply(DataMigrationWizard);

        // [THEN] Posting options are not visible
        Assert.IsFalse(DataMigrationWizard.PostingDate.Visible(),
          'Posting options must be hidden');
    end;

    [Test]
    [HandlerFunctions('DataMigratorsPageHandler,ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure VerifyPostingOptionsHiddenByDefaultOnEvent()
    var
        AccountingPeriod: Record "Accounting Period";
        DataMigrationWizardTests: Codeunit "Data Migration Wizard Tests";
        DataMigrationWizard: TestPage "Data Migration Wizard";
    begin
        // [GIVEN] A newly setup company where the data migration wizard test extension is bound
        Initialize(true);
        AccountingPeriod."Starting Date" := CalcDate('<-CY+1D>', WorkDate());
        AccountingPeriod."New Fiscal Year" := true;
        AccountingPeriod.Insert();
        LibraryVariableStorage.Enqueue(PostingOptionsTok); // Recipient of the event
        LibraryVariableStorage.Enqueue(true); // Show posting options
        BindSubscription(DataMigrationWizardTests);
        DataMigrationWizardTests.SetVariableStorage(LibraryVariableStorage);

        // [WHEN] The data migration wizard executed to the "Apply" page
        RunWizardToApply(DataMigrationWizard);
        // [WHEN] Setting the Posting Option to "Post balances for me"
        DataMigrationWizard.BallancesPostingOption.SetValue('Post balances for me');

        // [THEN] Posting options are visible
        Assert.IsTrue(DataMigrationWizard.PostingDate.Visible(),
          'Posting options must be shown if event set to true');
    end;

    [Test]
    [HandlerFunctions('DataMigratorsPageHandler,ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure VerifyPostingOptionsMissingAccountingPeriode()
    var
        DataMigrationWizardTests: Codeunit "Data Migration Wizard Tests";
        DataMigrationWizard: TestPage "Data Migration Wizard";
    begin
        // [SCENARIO 222561] "Post balances for me" should be allowed to set in data migration wizard when no accounting periods

        // [GIVEN] A newly setup company where the data migration wizard test extension is bound
        Initialize(true);
        LibraryVariableStorage.Enqueue(PostingOptionsTok); // Recipient of the event
        LibraryVariableStorage.Enqueue(true); // Show posting options
        BindSubscription(DataMigrationWizardTests);
        DataMigrationWizardTests.SetVariableStorage(LibraryVariableStorage);

        // [GIVEN] The data migration wizard executed to the "Apply" page
        RunWizardToApply(DataMigrationWizard);

        // [WHEN] Setting the Posting Option to "Post balances for me"
        DataMigrationWizard.BallancesPostingOption.SetValue('Post balances for me');

        // [THEN] The option is updated
        DataMigrationWizard.BallancesPostingOption.AssertEquals('Post balances for me');
    end;

    [Test]
    [HandlerFunctions('DataMigratorsPageHandler,ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure VerifyPostingOptionsWrongAccountingPeriods()
    var
        AccountingPeriod: Record "Accounting Period";
        DataMigrationWizardTests: Codeunit "Data Migration Wizard Tests";
        DataMigrationWizard: TestPage "Data Migration Wizard";
    begin
        // [SCENARIO 222561] "Post balances for me" should be set in data migration wizard when wrong accounting periods exists

        // [GIVEN] A newly setup company where the data migration wizard test extension is bound
        Initialize(true);
        LibraryVariableStorage.Enqueue(PostingOptionsTok); // Recipient of the event
        LibraryVariableStorage.Enqueue(true); // Show posting options
        BindSubscription(DataMigrationWizardTests);
        DataMigrationWizardTests.SetVariableStorage(LibraryVariableStorage);

        // [GIVEN] Wrong accounting period out of fiscal year
        AccountingPeriod.Init();
        AccountingPeriod."Starting Date" := WorkDate();
        AccountingPeriod.Insert();

        // [GIVEN] The data migration wizard executed to the "Apply" page
        RunWizardToApply(DataMigrationWizard);

        // [WHEN] Setting the Posting Option to "Post balances for me"
        asserterror DataMigrationWizard.BallancesPostingOption.SetValue('Post balances for me');

        // [THEN] Error occurs that the date is not within an open accounting period
        Assert.ExpectedError('is not within an open accounting period');
        Assert.ExpectedErrorCode('TestValidation');
    end;

    [Test]
    [HandlerFunctions('DataMigratorsPageHandler,ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure VerifyPostingOptionsHiddenByDefault()
    var
        DataMigrationWizardTests: Codeunit "Data Migration Wizard Tests";
        DataMigrationWizard: TestPage "Data Migration Wizard";
    begin
        // [GIVEN] A newly setup company where the data migration wizard test extension is bound
        Initialize(true);
        // Do not set any recipient of the event, to simulate no event handler and default value
        BindSubscription(DataMigrationWizardTests);

        // [WHEN] The data migration wizard executed to the "Apply" page
        RunWizardToApply(DataMigrationWizard);

        // [THEN] Posting options are hidden
        Assert.IsFalse(DataMigrationWizard.BallancesPostingOption.Visible(),
          'Posting options must be hidden by default if there are no event handlers');
        Assert.IsFalse(DataMigrationWizard.PostingDate.Visible(),
          'Posting options must be hidden by default if there are no event handlers');
    end;

    [Test]
    [HandlerFunctions('DataMigratorsPageHandler,ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure VerifyMissingPostingOptionsMessage()
    var
        DataMigrationWizardTests: Codeunit "Data Migration Wizard Tests";
        DataMigrationWizard: TestPage "Data Migration Wizard";
    begin
        // [GIVEN] A newly setup company where the data migration wizard test extension is bound
        Initialize(true);
        LibraryVariableStorage.Enqueue(PostingOptionsTok); // Recipient of the event
        LibraryVariableStorage.Enqueue(true); // Show posting options
        BindSubscription(DataMigrationWizardTests);
        DataMigrationWizardTests.SetVariableStorage(LibraryVariableStorage);
        RunWizardToApply(DataMigrationWizard);

        // [WHEN] The data migration wizard executed to the "Apply" page
        asserterror DataMigrationWizard.ActionApply.Invoke();
        // [THEN] Error shown
        Assert.ExpectedError('We need to know what to do with opening balances.');
    end;

    [Test]
    [HandlerFunctions('DataMigratorsPageHandler,ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure VerifyBalanceColumnVisibleOnEvent()
    var
        DataMigrationWizardTests: Codeunit "Data Migration Wizard Tests";
        DataMigrationWizard: TestPage "Data Migration Wizard";
    begin
        // [GIVEN] A newly setup company where the data migration wizard test extension is bound
        Initialize(true);
        LibraryVariableStorage.Enqueue(ShowBalanceTok); // Recipient of the event
        LibraryVariableStorage.Enqueue(true); // Show posting options
        BindSubscription(DataMigrationWizardTests);
        DataMigrationWizardTests.SetVariableStorage(LibraryVariableStorage);

        // [WHEN] The data migration wizard executed to the "Apply" page
        RunWizardToApply(DataMigrationWizard);

        // [THEN] Balance column is visible
        Assert.IsTrue(DataMigrationWizard.DataMigrationEntities.Balance.Visible(),
          'Balance column must be visible if set to true in event');
    end;

    [Test]
    [HandlerFunctions('DataMigratorsPageHandler,ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure VerifyBalanceColumnHiddenByDefault()
    var
        DataMigrationWizardTests: Codeunit "Data Migration Wizard Tests";
        DataMigrationWizard: TestPage "Data Migration Wizard";
    begin
        // [GIVEN] A newly setup company where the data migration wizard test extension is bound
        Initialize(true);
        // Do not set any recipient of the event, to simulate no event handler and default value
        BindSubscription(DataMigrationWizardTests);

        // [WHEN] The data migration wizard executed to the "Apply" page
        RunWizardToApply(DataMigrationWizard);

        // [THEN] Balance column is hidden
        Assert.IsFalse(DataMigrationWizard.ThatsItText.Visible(),
          'That''s it text must be hidden if empty.');
    end;

    [Test]
    [HandlerFunctions('DataMigratorsPageHandler,ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure VerifyThatsItTextIsShownIfNotEmpty()
    var
        DataMigrationWizardTests: Codeunit "Data Migration Wizard Tests";
        DataMigrationWizard: TestPage "Data Migration Wizard";
    begin
        // [GIVEN] A newly setup company where the data migration wizard test extension is bound
        Initialize(true);
        // Do not set any recipient of the event, to simulate no event handler and default value
        LibraryVariableStorage.Enqueue(ThatsItTok);
        LibraryVariableStorage.Enqueue('Not empty');
        BindSubscription(DataMigrationWizardTests);
        DataMigrationWizardTests.SetVariableStorage(LibraryVariableStorage);

        // [WHEN] The data migration wizard executed to the "Apply" page
        RunWizardToCompletionAndTestEvents(DataMigrationWizard);

        // [THEN] Balance column is hidden
        Assert.IsTrue(DataMigrationWizard.ThatsItText.Visible(),
          'That''s it text must be shown if NOT empty.');
    end;

    [Test]
    [HandlerFunctions('DataMigratorsPageHandler,ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure VerifyThatsItTextIsHiddenIfEmpty()
    var
        DataMigrationWizardTests: Codeunit "Data Migration Wizard Tests";
        DataMigrationWizard: TestPage "Data Migration Wizard";
    begin
        // [GIVEN] A newly setup company where the data migration wizard test extension is bound
        Initialize(true);
        // Do not set any recipient of the event, to simulate no event handler and default value
        LibraryVariableStorage.Enqueue(ThatsItTok);
        LibraryVariableStorage.Enqueue('');
        BindSubscription(DataMigrationWizardTests);
        DataMigrationWizardTests.SetVariableStorage(LibraryVariableStorage);

        // [WHEN] The data migration wizard executed to the "Apply" page
        RunWizardToCompletionAndTestEvents(DataMigrationWizard);

        // [THEN] Balance column is hidden
        Assert.IsFalse(DataMigrationWizard.ThatsItText.Visible(),
          'That''s it text must be hidden if empty.');
    end;

    [Test]
    [HandlerFunctions('DataMigratorsPageHandler,ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure VerifySelectedColumnHiddenOnEvent()
    var
        DataMigrationWizardTests: Codeunit "Data Migration Wizard Tests";
        DataMigrationWizard: TestPage "Data Migration Wizard";
    begin
        // [GIVEN] A newly setup company where the data migration wizard test extension is bound
        Initialize(true);
        LibraryVariableStorage.Enqueue(HideSelectedTok);
        LibraryVariableStorage.Enqueue(true);
        BindSubscription(DataMigrationWizardTests);
        DataMigrationWizardTests.SetVariableStorage(LibraryVariableStorage);

        // [WHEN] The data migration wizard executed to the "Apply" page
        RunWizardToApply(DataMigrationWizard);

        // [THEN] Selected column is hidden
        Assert.IsFalse(DataMigrationWizard.DataMigrationEntities.Selected.Visible(),
          'Selected column must be hidden if set to true in event');
    end;

    [Test]
    [HandlerFunctions('DataMigratorsPageHandler,ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure VerifySelectedColumnShownByDefault()
    var
        DataMigrationWizardTests: Codeunit "Data Migration Wizard Tests";
        DataMigrationWizard: TestPage "Data Migration Wizard";
    begin
        // [GIVEN] A newly setup company where the data migration wizard test extension is bound
        Initialize(true);
        // Do not set any recipient of the event, to simulate no event handler and default value
        BindSubscription(DataMigrationWizardTests);

        // [WHEN] The data migration wizard executed to the "Apply" page
        RunWizardToApply(DataMigrationWizard);

        // [THEN] Selected column is shown
        Assert.IsTrue(DataMigrationWizard.DataMigrationEntities.Selected.Visible(),
          'Selected column must be shown by default.');
    end;

    local procedure RunWizardToCompletionAndTestEvents(var DataMigrationWizard: TestPage "Data Migration Wizard")
    begin
        DataMigrationWizard.Trap();
        PAGE.Run(PAGE::"Data Migration Wizard");

        VerifyDataTypeBuffer(OnRegisterDataMigratorTxt, true);

        DataMigrationWizard.ActionNext.Invoke(); // Choose Data Source page
        DataMigrationWizard.ActionBack.Invoke(); // Welcome page
        DataMigrationWizard.ActionNext.Invoke(); // Choose Data Source page
        DataMigrationWizard.Description.Lookup();
        Assert.AreEqual('Test', DataMigrationWizard.Description.Value, 'The Test data migrator was not selected.');

        DataMigrationWizard.ActionNext.Invoke(); // Upload Data File page
        VerifyDataTypeBuffer(OnGetInstructionsTxt, true);

        DataMigrationWizard.ActionNext.Invoke(); // Apply Imported Data page
        VerifyDataTypeBuffer(OnDataImportTxt, true);
        VerifyDataTypeBuffer(OnSelectDataToApplyTxt, true);

        DataMigrationWizard.ActionApply.Invoke(); // That's it page
        VerifyDataTypeBuffer(OnApplySelectedDataTxt, true);

        Assert.IsFalse(DataMigrationWizard.ActionNext.Enabled(), 'Next should not be enabled at the end of the wizard');
    end;

    local procedure RunWizardToApply(var DataMigrationWizard: TestPage "Data Migration Wizard")
    begin
        DataMigrationWizard.Trap();
        PAGE.Run(PAGE::"Data Migration Wizard");

        DataMigrationWizard.ActionNext.Invoke(); // Choose Data Source page
        DataMigrationWizard.ActionBack.Invoke(); // Welcome page
        DataMigrationWizard.ActionNext.Invoke(); // Choose Data Source page
        DataMigrationWizard.Description.Lookup();
        DataMigrationWizard.ActionNext.Invoke(); // Upload Data File page
        DataMigrationWizard.ActionNext.Invoke(); // Apply Imported Data page
    end;

    local procedure InsertDataMigrationEntityRecord(var DataMigrationEntity: Record "Data Migration Entity")
    begin
        if not DoInsertDataMigrationEntityRecord() then
            exit;

        DataMigrationEntity.Init();
        DataMigrationEntity."No. of Records" := 10;
        DataMigrationEntity.Insert();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmYesHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmNoHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DataMigratorsPageHandler(var DataMigrators: TestPage "Data Migrators")
    begin
        DataMigrators.GotoKey(GetCodeunitNumber());
        DataMigrators.OK().Invoke();
    end;

    local procedure GetCodeunitNumber(): Integer
    begin
        exit(CODEUNIT::"Data Migration Wizard Tests");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Data Migrator Registration", 'OnRegisterDataMigrator', '', false, false)]
    local procedure RegisterDataMigrator(var Sender: Record "Data Migrator Registration")
    begin
        Sender.RegisterDataMigrator(GetCodeunitNumber(), 'Test');

        InsertDataTypeBuffer(OnRegisterDataMigratorTxt);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Data Migrator Registration", 'OnHasSettings', '', false, false)]
    local procedure HasSettings(var Sender: Record "Data Migrator Registration"; var HasSettings: Boolean)
    begin
        if Sender."No." <> GetCodeunitNumber() then
            exit;

        HasSettings := true;

        InsertDataTypeBuffer(OnHasSettingsTxt);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Data Migrator Registration", 'OnOpenSettings', '', false, false)]
    local procedure OpenSettings(var Sender: Record "Data Migrator Registration"; var Handled: Boolean)
    begin
        if Sender."No." <> GetCodeunitNumber() then
            exit;

        Handled := true;
        InsertDataTypeBuffer(OnOpenSettingsTxt);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Data Migrator Registration", 'OnGetInstructions', '', false, false)]
    local procedure GetInstructions(var Sender: Record "Data Migrator Registration"; var Instructions: Text; var Handled: Boolean)
    begin
        if Sender."No." <> GetCodeunitNumber() then
            exit;

        Instructions := 'This data migrator comes from test codeunit 139305. It is non-functional and for testing only.';

        Handled := true;
        InsertDataTypeBuffer(OnGetInstructionsTxt);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Data Migrator Registration", 'OnHasTemplate', '', false, false)]
    local procedure HasTemplate(var Sender: Record "Data Migrator Registration"; var HasTemplate: Boolean)
    begin
        if Sender."No." <> GetCodeunitNumber() then
            exit;

        HasTemplate := true;
        InsertDataTypeBuffer(OnHasTemplateTxt);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Data Migrator Registration", 'OnDownloadTemplate', '', false, false)]
    local procedure DownloadTemplate(var Sender: Record "Data Migrator Registration"; var Handled: Boolean)
    begin
        if Sender."No." <> GetCodeunitNumber() then
            exit;

        Handled := true;
        InsertDataTypeBuffer(OnDownloadTemplateTxt);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Data Migrator Registration", 'OnDataImport', '', false, false)]
    local procedure ImportData(var Sender: Record "Data Migrator Registration"; var Handled: Boolean)
    begin
        if Sender."No." <> GetCodeunitNumber() then
            exit;

        Handled := true;
        InsertDataTypeBuffer(OnDataImportTxt);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Data Migrator Registration", 'OnSelectDataToApply', '', false, false)]
    local procedure SelectDataToApply(var Sender: Record "Data Migrator Registration"; var DataMigrationEntity: Record "Data Migration Entity"; var Handled: Boolean)
    begin
        if Sender."No." <> GetCodeunitNumber() then
            exit;

        InsertDataMigrationEntityRecord(DataMigrationEntity);

        Handled := true;
        InsertDataTypeBuffer(OnSelectDataToApplyTxt);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Data Migrator Registration", 'OnHasAdvancedApply', '', false, false)]
    local procedure HasAdvancedApply(var Sender: Record "Data Migrator Registration"; var HasAdvancedApply: Boolean)
    begin
        if Sender."No." <> GetCodeunitNumber() then
            exit;

        HasAdvancedApply := true;
        InsertDataTypeBuffer(OnHasAdvancedApplyTxt);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Data Migrator Registration", 'OnOpenAdvancedApply', '', false, false)]
    local procedure OpenAdvancedApply(var Sender: Record "Data Migrator Registration"; var DataMigrationEntity: Record "Data Migration Entity"; var Handled: Boolean)
    begin
        if Sender."No." <> GetCodeunitNumber() then
            exit;

        Handled := true;
        InsertDataTypeBuffer(OnOpenAdvancedApplyTxt);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Data Migrator Registration", 'OnApplySelectedData', '', false, false)]
    local procedure ApplySelectedData(var Sender: Record "Data Migrator Registration"; var DataMigrationEntity: Record "Data Migration Entity"; var Handled: Boolean)
    begin
        if Sender."No." <> GetCodeunitNumber() then
            exit;

        Handled := true;
        InsertDataTypeBuffer(OnApplySelectedDataTxt);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Data Migrator Registration", 'OnHideSelected', '', false, false)]
    local procedure HideSelectedColumn(var Sender: Record "Data Migrator Registration"; var HideSelectedCheckBoxes: Boolean)
    begin
        if Sender."No." <> GetCodeunitNumber() then
            exit;

        if LibraryVariableStorage.Length() < 2 then
            exit;

        if LibraryVariableStorage.PeekText(1) <> HideSelectedTok then
            exit;

        LibraryVariableStorage.DequeueText();
        HideSelectedCheckBoxes := LibraryVariableStorage.DequeueBoolean();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Data Migrator Registration", 'OnHasErrors', '', false, false)]
    local procedure HasErrors(var Sender: Record "Data Migrator Registration"; var HasErrors: Boolean)
    begin
        if Sender."No." <> GetCodeunitNumber() then
            exit;

        HasErrors := true;
        InsertDataTypeBuffer(OnHasErrorsTxt);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Data Migrator Registration", 'OnShowErrors', '', false, false)]
    local procedure ShowErrors(var Sender: Record "Data Migrator Registration"; var Handled: Boolean)
    begin
        if Sender."No." <> GetCodeunitNumber() then
            exit;

        Handled := true;
        InsertDataTypeBuffer(OnShowErrorsTxt);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Data Migrator Registration", 'OnShowDuplicateContactsText', '', false, false)]
    local procedure ShowDuplicateContactText(var Sender: Record "Data Migrator Registration"; var ShowDuplicateContactText: Boolean)
    begin
        if Sender."No." <> GetCodeunitNumber() then
            exit;

        if LibraryVariableStorage.Length() < 2 then
            exit;

        if LibraryVariableStorage.PeekText(1) <> DuplicateContacatsTextTok then
            exit;

        LibraryVariableStorage.DequeueText();
        ShowDuplicateContactText := LibraryVariableStorage.DequeueBoolean();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Data Migrator Registration", 'OnShowPostingOptions', '', false, false)]
    local procedure ShowPostingOptions(var Sender: Record "Data Migrator Registration"; var ShowPostingOptions: Boolean)
    begin
        if Sender."No." <> GetCodeunitNumber() then
            exit;

        if LibraryVariableStorage.Length() < 2 then
            exit;

        if LibraryVariableStorage.PeekText(1) <> PostingOptionsTok then
            exit;

        LibraryVariableStorage.DequeueText();
        ShowPostingOptions := LibraryVariableStorage.DequeueBoolean();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Data Migrator Registration", 'OnShowBalance', '', false, false)]
    local procedure ShowBalanceColumn(var Sender: Record "Data Migrator Registration"; var ShowBalance: Boolean)
    begin
        if Sender."No." <> GetCodeunitNumber() then
            exit;

        if LibraryVariableStorage.Length() < 2 then
            exit;

        if LibraryVariableStorage.PeekText(1) <> ShowBalanceTok then
            exit;

        LibraryVariableStorage.DequeueText();
        ShowBalance := LibraryVariableStorage.DequeueBoolean();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Data Migrator Registration", 'OnShowThatsItMessage', '', false, false)]
    local procedure ShowThatsItText(var Sender: Record "Data Migrator Registration"; var Message: Text)
    begin
        if Sender."No." <> GetCodeunitNumber() then
            exit;

        if LibraryVariableStorage.Length() < 2 then
            exit;

        if LibraryVariableStorage.PeekText(1) <> ThatsItTok then
            exit;

        LibraryVariableStorage.DequeueText();
        Message := LibraryVariableStorage.DequeueText();
    end;

    local procedure InsertDataTypeBuffer(EventText: Text)
    var
        DataTypeBuffer: Record "Data Type Buffer";
    begin
        if DataTypeBuffer.FindLast() then;

        DataTypeBuffer.Init();
        DataTypeBuffer.ID += 1;
        DataTypeBuffer.Text := CopyStr(EventText, 1, 30);
        DataTypeBuffer.Insert(true);
    end;

    local procedure VerifyDataTypeBuffer(VerifyText: Text; EventWasFired: Boolean)
    var
        DataTypeBuffer: Record "Data Type Buffer";
    begin
        DataTypeBuffer.SetRange(Text, VerifyText);
        if EventWasFired then
            Assert.IsFalse(DataTypeBuffer.IsEmpty, VerifyText + ' event was not executed.')
        else
            Assert.IsTrue(DataTypeBuffer.IsEmpty, VerifyText + ' event was executed.')
    end;

    local procedure DoInsertDataMigrationEntityRecord(): Boolean
    var
        DataTypeBuffer: Record "Data Type Buffer";
    begin
        DataTypeBuffer.SetRange(Text, InsertDataMigrationRecordsTxt);
        exit(not DataTypeBuffer.IsEmpty);
    end;

    local procedure PopulateDataMigrationEntityRecord()
    var
        DataTypeBuffer: Record "Data Type Buffer";
    begin
        if DataTypeBuffer.FindLast() then;

        DataTypeBuffer.Init();
        DataTypeBuffer.ID += 1;
        DataTypeBuffer.Text := CopyStr(InsertDataMigrationRecordsTxt, 1, 30);
        DataTypeBuffer.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure SetVariableStorage(var NewLibraryVariableStorage: Codeunit "Library - Variable Storage")
    begin
        LibraryVariableStorage := NewLibraryVariableStorage;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure DataMigrationOverviewHandler(var DataMigrationOverview: Page "Data Migration Overview")
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Data Migration Facade", 'OnEnableTogglingDataMigrationOverviewPage', '', false, false)]
    [Scope('OnPrem')]
    procedure OnShowOverview(var Sender: Codeunit "Data Migration Facade"; var DataMigratorRegistration: Record "Data Migrator Registration"; var EnableTogglingOverviewPage: Boolean)
    begin
        EnableTogglingOverviewPage := true;
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure NotificationHandler(var Notification: Notification): Boolean
    begin
    end;
}

