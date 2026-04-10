codeunit 135023 "Data Migration Status Test"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;

    trigger OnRun()
    begin
        // [FEATURE] [Data Migration] [Status]
    end;

    var
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        DataMigrationStatusFacade: Codeunit "Data Migration Status Facade";
        Assert: Codeunit Assert;
        DataMigrationStatusTest: Codeunit "Data Migration Status Test";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        SkipEditNotificationMsg: Label 'Skip errors, or edit the entity to fix them, and then migrate again.';

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestOverviewOk()
    var
        DataMigrationStatus: Record "Data Migration Status";
    begin
        // [SCENARIO] Test valid cases: Init a dashboard line, increment it, update the status
        LibraryLowerPermissions.SetO365Setup();

        // [WHEN] We init a dashboard line
        DataMigrationStatusFacade.InitStatusLine(
          'Test', DATABASE::Item, 100, DATABASE::Customer, CODEUNIT::"Data Migration Status Test");

        // [THEN] It is populated correctly
        DataMigrationStatus.Get('Test', DATABASE::Item);
        Assert.AreEqual(100, DataMigrationStatus."Total Number", 'Total nb incorrect');
        Assert.AreEqual(0, DataMigrationStatus."Migrated Number", 'Migrated nb incorrect');
        Assert.AreEqual(0, DataMigrationStatus."Progress Percent", 'Progress percent incorrect');
        Assert.AreEqual(DataMigrationStatus.Status::Pending, DataMigrationStatus.Status, 'Status incorrect');
        Assert.AreEqual(DATABASE::Customer, DataMigrationStatus."Source Staging Table ID", '"Source Staging Table ID" incorrect');
        Assert.AreEqual(
          CODEUNIT::"Data Migration Status Test", DataMigrationStatus."Migration Codeunit To Run",
          '"Migration Codeunit To Run" incorrect');
        Assert.AreEqual(DATABASE::Item, DataMigrationStatus."Destination Table ID", '"Destination Table ID" incorrect');

        // [WHEN] We increment the migrated entities for this line
        DataMigrationStatusFacade.IncrementMigratedRecordCount('Test', DATABASE::Item, 1);
        DataMigrationStatusFacade.IncrementMigratedRecordCount('Test', DATABASE::Item, 42);
        DataMigrationStatusFacade.IncrementMigratedRecordCount('Test', DATABASE::Item, 0);
        DataMigrationStatusFacade.IncrementMigratedRecordCount('Test', DATABASE::Item, -1);

        // [THEN] the line is updated correctly
        DataMigrationStatus.Get('Test', DATABASE::Item);
        Assert.AreEqual(42, DataMigrationStatus."Migrated Number", 'Migrated nb incorrect');
        Assert.AreEqual(42 / 100 * 10000, DataMigrationStatus."Progress Percent", 'Progress percent incorrect');

        // [WHEN] We update the line status
        DataMigrationStatusFacade.UpdateLineStatus('Test', DATABASE::Item, DataMigrationStatus.Status::Completed);
        DataMigrationStatus.Get('Test', DATABASE::Item);

        // [THEN] The status is updated correctly
        Assert.AreEqual(DataMigrationStatus.Status::Completed, DataMigrationStatus.Status, 'Status incorrect');

        // [WHEN] We init a dashboard line that already exists
        DataMigrationStatusFacade.InitStatusLine(
          'Test', DATABASE::Item, 100, DATABASE::Customer, CODEUNIT::"Data Migration Status Test");

        // [THEN] It is deleted and recreated from scratch with all the expected values
        DataMigrationStatus.Get('Test', DATABASE::Item);
        Assert.AreEqual(100, DataMigrationStatus."Total Number", 'Total nb incorrect');
        Assert.AreEqual(0, DataMigrationStatus."Migrated Number", 'Migrated nb incorrect');
        Assert.AreEqual(0, DataMigrationStatus."Progress Percent", 'Progress percent incorrect');
        Assert.AreEqual(DataMigrationStatus.Status::Pending, DataMigrationStatus.Status, 'Status incorrect');
        Assert.AreEqual(DATABASE::Customer, DataMigrationStatus."Source Staging Table ID", '"Source Staging Table ID" incorrect');
        Assert.AreEqual(
          CODEUNIT::"Data Migration Status Test", DataMigrationStatus."Migration Codeunit To Run",
          '"Migration Codeunit To Run" incorrect');
        Assert.AreEqual(DATABASE::Item, DataMigrationStatus."Destination Table ID", '"Destination Table ID" incorrect');

        // [WHEN] The InitStatusLine function is called with total number 0
        DataMigrationStatusFacade.InitStatusLine(
          'Test', DATABASE::Item, 0, DATABASE::Customer, CODEUNIT::"Data Migration Status Test");

        // [THEN] The Status Line remains as it was
        DataMigrationStatus.Get('Test', DATABASE::Item);
        Assert.AreEqual(100, DataMigrationStatus."Total Number", 'Total nb incorrect');
        Assert.AreEqual(0, DataMigrationStatus."Migrated Number", 'Migrated nb incorrect');
        Assert.AreEqual(0, DataMigrationStatus."Progress Percent", 'Progress percent incorrect');
        Assert.AreEqual(DataMigrationStatus.Status::Pending, DataMigrationStatus.Status, 'Status incorrect');
        Assert.AreEqual(DATABASE::Customer, DataMigrationStatus."Source Staging Table ID", '"Source Staging Table ID" incorrect');
        Assert.AreEqual(
          CODEUNIT::"Data Migration Status Test", DataMigrationStatus."Migration Codeunit To Run",
          '"Migration Codeunit To Run" incorrect');
        Assert.AreEqual(DATABASE::Item, DataMigrationStatus."Destination Table ID", '"Destination Table ID" incorrect');

        DataMigrationStatus.Delete();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestOverviewNok()
    var
        DataMigrationStatus: Record "Data Migration Status";
    begin
        // [SCENARIO] Test error cases
        LibraryLowerPermissions.SetO365Setup();

        // [WHEN] We try to update a non-existing line
        // [THEN] It fails
        asserterror DataMigrationStatusFacade.IncrementMigratedRecordCount('Test', DATABASE::Item, 1);

        // [WHEN] We try to update a non-existing line
        // [THEN] It fails
        asserterror DataMigrationStatusFacade.UpdateLineStatus(
            'Test', DATABASE::Item, DataMigrationStatus.Status::Completed);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestCreateErrorWithMessage()
    var
        DataMigrationError: Record "Data Migration Error";
        DataMigrationStatusFacade: Codeunit "Data Migration Status Facade";
    begin
        // [SCENARIO] Test error cases
        LibraryLowerPermissions.SetO365Setup();
        DataMigrationError.DeleteAll();

        // [WHEN] we register an error for the non staging table case
        DataMigrationStatusFacade.RegisterErrorNoStagingTablesCase('Test', DATABASE::Item, 'Very bad error happened.');

        // [THEN] It is created correctly
        DataMigrationError.FindFirst();
        Assert.AreEqual('Very bad error happened.', DataMigrationError."Error Message", 'Unexpected error message');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestHasMigratedChartOfAccounts()
    var
        DataMigrationStatus: Record "Data Migration Status";
        DataMigrationParameters: Record "Data Migration Parameters";
        DataMigrationStatusFacade: Codeunit "Data Migration Status Facade";
    begin
        // [SCENARIO] HasMigratedChartOfAccounts function returns true if G/L Account Migration has been selected

        LibraryLowerPermissions.SetO365Setup();
        // [GIVEN] G/L Account migration has been selected
        DataMigrationStatus.Init();
        DataMigrationStatus."Migration Type" := 'Migration1';
        DataMigrationStatus."Destination Table ID" := DATABASE::"G/L Account";
        DataMigrationStatus.Insert();

        DataMigrationParameters.Init();
        DataMigrationParameters."Migration Type" := 'Migration1';
        DataMigrationParameters.Insert();

        // [WHEN] HasMigratedChartOfAccounts is called
        // [THEN] It return TRUE
        Assert.IsTrue(DataMigrationStatusFacade.HasMigratedChartOfAccounts(DataMigrationParameters),
          'Chart of Accounts was expected to be migrated');

        // [GIVEN] G/L Account migration has not been selected
        DataMigrationStatus.DeleteAll();

        // [WHEN] HasMigratedChartOfAccounts is called
        // [THEN] It return FALSE
        Assert.IsFalse(DataMigrationStatusFacade.HasMigratedChartOfAccounts(DataMigrationParameters),
          'Chart of Accounts was not expected to be migrated');
    end;

    [Test]
    [HandlerFunctions('DataMigrationErrorModalPageHandler,ConfirmHandler,ItemJournalPageHandler,GeneralJournalPageHandler,SendNotificationHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestNextStep()
    var
        DataMigrationStatus: Record "Data Migration Status";
        DataMigrationError: Record "Data Migration Error";
        Customer: Record Customer;
        ItemDataMigrationFacade: Codeunit "Item Data Migration Facade";
        VendorDataMigrationFacade: Codeunit "Vendor Data Migration Facade";
        CustomerDataMigrationFacade: Codeunit "Customer Data Migration Facade";
        LibrarySales: Codeunit "Library - Sales";
        DataMigrationOverview: TestPage "Data Migration Overview";
        CalculationFormula: DateFormula;
    begin
        // [SCENARIO] The Next Task column open the proper page when drilled down

        BindSubscription(DataMigrationStatusTest);

        LibraryLowerPermissions.SetO365BusFull();

        DataMigrationError.DeleteAll();
        DataMigrationStatus.DeleteAll();

        // [GIVEN] The Migration for Item is selected
        DataMigrationStatusFacade.InitStatusLine(
          'Test', DATABASE::Item, 100, DATABASE::Customer, CODEUNIT::"Data Migration Status Test");

        // [GIVEN] The Migration for Item has been completed with errors
        DataMigrationStatus.Get('Test', DATABASE::Item);
        DataMigrationStatus."Migrated Number" := 99;
        DataMigrationStatus.Status := DataMigrationStatus.Status::"Completed with Errors";
        DataMigrationStatus.Modify();

        // Dummy staging table record
        LibrarySales.CreateCustomer(Customer);

        DataMigrationError.CreateEntryWithMessage('Test', DATABASE::Item, Customer.RecordId, 'Error occured');

        // [WHEN] The Data Migration Overview Page is opened
        DataMigrationOverview.OpenView();

        // [THEN] The next task is review and fix
        DataMigrationOverview.First();
        Assert.AreEqual('Review and fix errors', DataMigrationOverview."Next Task".Value, 'A different next task was expected');

        // [WHEN] The Next Task is drilled down
        DataMigrationOverview."Next Task".DrillDown();

        // [THEN] Data Migration error page is opened and the right error message is displayed
        // Verify in DataMigrationErrorModalPageHandler and Skip Error

        DataMigrationOverview.Close();

        // [THEN] The Next task is changed to blank
        DataMigrationOverview.OpenView();
        DataMigrationOverview.First();
        Assert.AreEqual(' ', DataMigrationOverview."Next Task".Value, 'A different next task was expected');

        // [WHEN] There are transactions for the items
        ItemDataMigrationFacade.CreateItemJournalBatchIfNeeded('IJB', '', '');
        ItemDataMigrationFacade.CreateGeneralProductPostingSetupIfNeeded('GPPG', '', '');
        ItemDataMigrationFacade.CreateItemIfNeeded('IT001', '', '', 0);
        ItemDataMigrationFacade.CreateItemJournalLine('IJB', 'Doc1', 'Description', WorkDate(), 1, 123, '', 'GPPG');

        DataMigrationOverview.Close();

        // [THEN] The Next task is changed to Review and post
        DataMigrationOverview.OpenView();
        DataMigrationOverview.First();
        Assert.AreEqual('Review and post', DataMigrationOverview."Next Task".Value, 'A different next task was expected');

        // [WHEN] The Next Task is drilled down
        DataMigrationOverview."Next Task".DrillDown();

        // [THEN] Item Journal page is opened
        // Verify in ItemJournalPageHandler

        DataMigrationOverview.Close();
        DataMigrationStatus.DeleteAll();

        // [GIVEN] The Migration for Customer is selected
        DataMigrationStatusFacade.InitStatusLine(
          'Test', DATABASE::Customer, 100, DATABASE::Customer, CODEUNIT::"Data Migration Status Test");

        // [GIVEN] The Migration for Customer has been completed
        DataMigrationStatus.Get('Test', DATABASE::Customer);
        DataMigrationStatus."Migrated Number" := 100;
        DataMigrationStatus.Status := DataMigrationStatus.Status::Completed;
        DataMigrationStatus.Modify();

        // [GIVEN] Customer transaction have been created
        CustomerDataMigrationFacade.CreateCustomerIfNeeded('C001', '');
        Evaluate(CalculationFormula, '<14D>');
        CustomerDataMigrationFacade.CreatePaymentTermsIfNeeded('PT', '', CalculationFormula);
        CustomerDataMigrationFacade.SetPaymentTermsCode('PT');
        CustomerDataMigrationFacade.CreatePaymentMethodIfNeeded('PM', 'Payment Method');
        CustomerDataMigrationFacade.SetPaymentMethodCode('PM');
        CustomerDataMigrationFacade.ModifyCustomer(true);
        CustomerDataMigrationFacade.CreateGeneralJournalBatchIfNeeded('GJB', '', '');
        CustomerDataMigrationFacade.CreateGeneralJournalLine('GJB', 'Doc1', 'Description', WorkDate(), WorkDate(), 123, 123, '', '');

        // [WHEN] The Data Migration Overview Page Opens
        DataMigrationOverview.OpenView();

        // [THEN] The Next task is changed to Review and post
        DataMigrationOverview.First();
        Assert.AreEqual('Review and post', DataMigrationOverview."Next Task".Value, 'A different next task was expected');

        // [WHEN] The Next Task is drilled down
        LibraryVariableStorage.Enqueue('Customer');
        DataMigrationOverview."Next Task".DrillDown();

        // [THEN] General Journal page is opened
        // Verify in GeneralJournalPageHandler

        DataMigrationStatus.DeleteAll();
        DataMigrationOverview.Close();

        // [GIVEN] The Migration for Vendor is selected
        DataMigrationStatusFacade.InitStatusLine(
          'Test', DATABASE::Vendor, 100, DATABASE::Customer, CODEUNIT::"Data Migration Status Test");

        // [GIVEN] The Migration for Customer has been completed
        DataMigrationStatus.Get('Test', DATABASE::Vendor);
        DataMigrationStatus.Status := DataMigrationStatus.Status::Completed;
        DataMigrationStatus."Migrated Number" := 100;
        DataMigrationStatus.Modify();

        // [GIVEN] Vendor transaction have been created
        VendorDataMigrationFacade.CreateVendorIfNeeded('V001', '');
        Evaluate(CalculationFormula, '<14D>');
        VendorDataMigrationFacade.CreatePaymentTermsIfNeeded('PT', '', CalculationFormula);
        VendorDataMigrationFacade.SetPaymentTermsCode('PT');
        VendorDataMigrationFacade.CreatePaymentMethodIfNeeded('PM', 'Payment Method');
        VendorDataMigrationFacade.SetPaymentMethod('PM');
        VendorDataMigrationFacade.ModifyVendor(true);
        VendorDataMigrationFacade.CreateGeneralJournalLine('GJB', 'Doc1', 'Description', WorkDate(), WorkDate(), 123, 123, '', '');

        // [WHEN] The Data Migration Overview Page Opens
        DataMigrationOverview.OpenView();

        // [THEN] The Next task is changed to Review and post
        DataMigrationOverview.First();
        Assert.AreEqual('Review and post', DataMigrationOverview."Next Task".Value, 'A different next task was expected');

        // [WHEN] The Next Task is drilled down
        LibraryVariableStorage.Enqueue('Vendor');
        DataMigrationOverview."Next Task".DrillDown();

        // [THEN] General Journal page is opened
        // Verify in GeneralJournalPageHandler

        DataMigrationOverview.Close();
        DataMigrationStatus.DeleteAll();

        // [GIVEN] The Migration for Account is selected
        DataMigrationStatusFacade.InitStatusLine(
          'Test', DATABASE::"G/L Account", 100, DATABASE::Customer, CODEUNIT::"Data Migration Status Test");

        // [GIVEN] The Migration for Accounts has been Failed
        DataMigrationStatus.Get('Test', DATABASE::"G/L Account");
        DataMigrationStatus."Migrated Number" := 99;
        DataMigrationStatus.Status := DataMigrationStatus.Status::Failed;
        DataMigrationStatus.Modify();

        CreateGenJournalLine();

        // [WHEN] The Data Migration Overview Page Opens
        DataMigrationOverview.OpenView();

        // [THEN] The Next task is changed to Review and Delete
        DataMigrationOverview.First();
        Assert.AreEqual('Review and Delete', DataMigrationOverview."Next Task".Value, 'A different next task was expected');

        // [WHEN] The Next Task is drilled down
        LibraryVariableStorage.Enqueue('G/L Account');
        DataMigrationOverview."Next Task".DrillDown();

        // [THEN] General Journal page is opened
        // Verify in GeneralJournalPageHandler

        UnbindSubscription(DataMigrationStatusTest);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DataMigrationErrorModalPageHandler(var DataMigrationError: TestPage "Data Migration Error")
    begin
        DataMigrationError.First();
        Assert.AreEqual('Error occured', DataMigrationError."Error Message".Value, 'A different error was expected');

        DataMigrationError.SkipSelection.Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Data Migration Facade", 'OnFindBatchForItemTransactions', '', false, false)]
    local procedure OnFindItemJournalBatch(MigrationType: Text[250]; var ItemJournalBatchName: Code[10])
    begin
        ItemJournalBatchName := 'IJB';
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ItemJournalPageHandler(var ItemJournal: TestPage "Item Journal")
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Data Migration Facade", 'OnFindBatchForCustomerTransactions', '', false, false)]
    local procedure OnFindCustomerJournalBatch(MigrationType: Text[250]; var GenJournalBatchName: Code[10])
    begin
        GenJournalBatchName := 'GJB';
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure GeneralJournalPageHandler(var GeneralJournal: TestPage "General Journal")
    begin
        GeneralJournal.First();
        Assert.AreEqual(LibraryVariableStorage.DequeueText(), GeneralJournal."Account Type".Value, 'A different option was expected')
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Data Migration Facade", 'OnFindBatchForVendorTransactions', '', false, false)]
    local procedure OnFindVendorJournalBatch(MigrationType: Text[250]; var GenJournalBatchName: Code[10])
    begin
        GenJournalBatchName := 'GJB';
    end;

    local procedure CreateGenJournalLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        GenJournalBatch.SetRange(Name, 'GJB');
        GenJournalBatch.FindFirst();

        GenJournalLine.Init();
        GenJournalLine."Journal Batch Name" := GenJournalBatch.Name;
        GenJournalLine."Journal Template Name" := GenJournalBatch."Journal Template Name";
        GenJournalLine."Account Type" := GenJournalLine."Account Type"::"G/L Account";
        GenJournalLine."Account No." := 'GL001';
        GenJournalLine.Insert();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Data Migration Facade", 'OnFindBatchForAccountTransactions', '', false, false)]
    local procedure OnFindAccountJournalBatch(DataMigrationStatus: Record "Data Migration Status"; var GenJournalBatchName: Code[10])
    begin
        GenJournalBatchName := 'GJB';
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SendNotificationHandler(var Notification: Notification): Boolean
    begin
        Assert.ExpectedMessage(SkipEditNotificationMsg, Notification.Message);
    end;
}

