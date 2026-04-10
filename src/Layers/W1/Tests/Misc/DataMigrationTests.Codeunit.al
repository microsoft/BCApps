codeunit 135020 "Data Migration Tests"
{
    EventSubscriberInstance = Manual;
    SingleInstance = true;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Data Migration]
    end;

    var
        FakeMigrationTxt: Label 'Fake Migration';
        ItemAKeyTxt: Label 'ITEMA';
        ItemADescTxt: Label 'This is the description for item A.';
        ItemBKeyTxt: Label 'ITEMB';
        ItemBDescTxt: Label 'This is the description for item B.';
        ItemCKeyTxt: Label 'ITEMC';
        ItemCDescTxt: Label 'This is the description for item C.';
        FakeErrorErr: Label 'Fake error raised.';
        Assert: Codeunit Assert;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        IssueError: Boolean;
        GLAccountTxt: Label 'GLACC';
        ExtensionNotInstalledErr: Label 'Sorry, but it looks like someone uninstalled the data migration extension you are trying to use. When that happens, we remove all data that was not fully migrated.';
        CustomerTxt: Label 'CUST';
        VendorTxt: Label 'VEND';
        ExistingDataCheck: Boolean;
        SkipSelectionConfirmQst: Label 'The selected errors will be deleted and the corresponding entities will not be migrated. Do you want to continue?';
        MigrationStartedMsg: Label 'The selected records are scheduled for data migration. To check the status of the migration, go to the Data Migration Overview page.', Comment = '%1 = Caption for the page Data Migration Overview';
        SkipEditNotificationMsg: Label 'Skip errors, or edit the entity to fix them, and then migrate again.';

    local procedure Initialize()
    var
        DataMigItemStagingTable: Record "Data Mig. Item Staging Table";
        Item: Record Item;
        DataMigrationStatus: Record "Data Migration Status";
        GLAccount: Record "G/L Account";
        Customer: Record Customer;
        Vendor: Record Vendor;
        DataMigrationError: Record "Data Migration Error";
        DataMigrationTests: Codeunit "Data Migration Tests";
    begin
        if Item.Get(ItemAKeyTxt) then
            Item.Delete();
        if Item.Get(ItemBKeyTxt) then
            Item.Delete();
        if Item.Get(ItemCKeyTxt) then
            Item.Delete();

        if GLAccount.Get(GLAccountTxt) then
            GLAccount.Delete();

        if Customer.Get(CustomerTxt) then
            Customer.Delete();

        if Vendor.Get(VendorTxt) then
            Vendor.Delete();

        Clear(LibraryVariableStorage);
        Clear(DataMigrationTests);
        DataMigItemStagingTable.DeleteAll();
        DataMigrationStatus.DeleteAll();
        DataMigrationError.DeleteAll();
        ExistingDataCheck := false;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestErrorHandled()
    var
        DataMigrationStatus: Record "Data Migration Status";
        DataMigItemStagingTable: Record "Data Mig. Item Staging Table";
        Item: Record Item;
        DataMigrationError: Record "Data Migration Error";
        Customer: Record Customer;
        GLAccount: Record "G/L Account";
        DataMigrationMgt: Codeunit "Data Migration Mgt.";
        DataMigrationTests: Codeunit "Data Migration Tests";
    begin
        // [SCENARIO] An error is raised during migration, this is then re-migrated

        Initialize();
        IssueError := true;

        if not BindSubscription(DataMigrationTests) then;

        // [GIVEN] Fill the staging table with 3 records
        CreateStagingTableEntry(ItemAKeyTxt, CopyStr(ItemADescTxt, 1, 50));
        CreateStagingTableEntry(ItemBKeyTxt, CopyStr(ItemBDescTxt, 1, 50));
        CreateStagingTableEntry(ItemCKeyTxt, CopyStr(ItemCDescTxt, 1, 50));
        GLAccount.Init();
        GLAccount."No." := GLAccountTxt;
        GLAccount.Insert();

        // [GIVEN] Create the data migration status line for item
        DataMigrationStatus.Init();
        DataMigrationStatus."Migration Type" := FakeMigrationTxt;
        DataMigrationStatus."Destination Table ID" := DATABASE::Item;
        DataMigrationStatus."Source Staging Table ID" := DATABASE::"Data Mig. Item Staging Table";
        DataMigrationStatus."Total Number" := DataMigItemStagingTable.Count();
        DataMigrationStatus.Insert();

        // [WHEN] Call the migration codeunit
        DataMigrationMgt.StartMigration(FakeMigrationTxt, false);

        // [THEN] Check for the result on the status line
        DataMigrationStatus.Get(DataMigrationStatus."Migration Type", DataMigrationStatus."Destination Table ID");

        Assert.AreEqual(DataMigItemStagingTable.Count, DataMigrationStatus."Total Number", 'Wrong total number');
        Assert.AreEqual(2, DataMigrationStatus."Migrated Number", 'Only two migrated');
        DataMigrationStatus.CalcFields("Error Count");
        Assert.AreEqual(1, DataMigrationStatus."Error Count", 'Only one not migrated');
        Assert.AreEqual(DataMigrationStatus.Status::"Completed with Errors", DataMigrationStatus.Status, 'Errors expected');

        // [THEN] The right items are created
        Assert.IsTrue(Item.Get(ItemAKeyTxt), 'Item A exists');
        Assert.IsFalse(Item.Get(ItemBKeyTxt), 'Item B should not exist');
        Assert.IsTrue(Item.Get(ItemCKeyTxt), 'Item C exists');

        // [THEN] One entry on the data migration errors
        Assert.AreEqual(1, DataMigrationError.Count, 'Only one error occured');
        DataMigrationError.FindFirst();
        Assert.AreEqual(FakeErrorErr, DataMigrationError."Error Message", 'The wrong error message');

        // [THEN] G/L Account table is not cleared
        GLAccount.Reset();
        Assert.IsFalse(GLAccount.IsEmpty, 'GL account table is empty, it should not');
        GLAccount.Get(GLAccountTxt);
        GLAccount.Delete();

        // [WHEN] Re-migrate the entity with error without marking it
        IssueError := false;
        DataMigrationMgt.StartMigration(FakeMigrationTxt, true);

        // [THEN] Error persists. One entry on the data migration errors
        Assert.AreEqual(1, DataMigrationError.Count, 'Only one error occured');
        DataMigrationError.FindFirst();
        Assert.AreEqual(FakeErrorErr, DataMigrationError."Error Message", 'The wrong error message');

        // [WHEN] Mark the error as Scheduled for migrate
        DataMigrationError."Scheduled For Retry" := true;
        DataMigrationError.Modify();

        // [WHEN] Re-migrate the entity with error and we have an existing Customer
        Customer.Init();
        Customer."No." := CustomerTxt;
        Customer.Insert();
        DataMigrationStatus.Init();
        DataMigrationStatus."Destination Table ID" := DATABASE::Customer;
        DataMigrationStatus."Migration Type" := FakeMigrationTxt;
        DataMigrationStatus."Total Number" := 1; // dummy number to migrate (if 0, the status line won't be created)
        DataMigrationStatus."Source Staging Table ID" := DATABASE::"Data Mig. Item Staging Table"; // dummy staging table to use
        DataMigrationStatus.Insert();
        DataMigrationMgt.StartMigration(FakeMigrationTxt, true);

        // [THEN] No errors occur about the customer nor the item that we migrate
        Assert.AreEqual(0, DataMigrationError.Count, 'No errors occured');

        // [THEN] Item B exists
        Assert.IsTrue(Item.Get(ItemBKeyTxt), 'Item B exists');

        // [THEN] Status line shows no errors
        DataMigrationStatus.Get(DataMigrationStatus."Migration Type", DATABASE::Item);
        Assert.AreEqual(DataMigItemStagingTable.Count, DataMigrationStatus."Total Number", 'Wrong total number');
        Assert.AreEqual(DataMigItemStagingTable.Count, DataMigrationStatus."Migrated Number", 'All migrated');
        DataMigrationStatus.CalcFields("Error Count");
        Assert.AreEqual(0, DataMigrationStatus."Error Count", 'All migrated');
        Assert.AreEqual(DataMigrationStatus.Status::Completed, DataMigrationStatus.Status, 'No errors expected');

        UnbindSubscription(DataMigrationTests);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestMigrateWithExistingEntitiesThrowsError()
    var
        DataMigrationStatus: Record "Data Migration Status";
        Customer: Record Customer;
        Vendor: Record Vendor;
        Item: Record Item;
        DataMigrationMgt: Codeunit "Data Migration Mgt.";
        DataMigrationTests: Codeunit "Data Migration Tests";
    begin
        // [SCENARIO] Item, Customer and Vendor migration is run, with existing entities

        Initialize();
        IssueError := true;
        ExistingDataCheck := true;

        if not BindSubscription(DataMigrationTests) then;

        // [GIVEN] We have an existing Customer
        Customer.Init();
        Customer."No." := CustomerTxt;
        Customer.Insert();

        DataMigrationStatus.Init();
        DataMigrationStatus."Migration Type" := FakeMigrationTxt;
        DataMigrationStatus."Destination Table ID" := DATABASE::Customer;
        DataMigrationStatus."Source Staging Table ID" := DATABASE::"Data Mig. Item Staging Table"; // dummy staging table to use
        DataMigrationStatus."Total Number" := 1; // dummy number to migrate (if 0, the status line won't be created)
        DataMigrationStatus.Insert();

        // [WHEN] Call the migration codeunit
        asserterror DataMigrationMgt.StartMigration(FakeMigrationTxt, false);
        DataMigrationStatus.DeleteAll();

        // [THEN] It should error because there is an existing customer
        Assert.IsTrue(
          StrPos(GetLastErrorText, 'customers') > 0, StrSubstNo('Expected the error to be about customer but %1', GetLastErrorText));

        // [GIVEN] We have an existing Vendor
        Vendor.Init();
        Vendor."No." := VendorTxt;
        Vendor.Insert();

        DataMigrationStatus.Init();
        DataMigrationStatus."Destination Table ID" := DATABASE::Vendor;
        DataMigrationStatus."Migration Type" := FakeMigrationTxt;
        DataMigrationStatus."Source Staging Table ID" := DATABASE::"Data Mig. Item Staging Table"; // dummy staging table to use
        DataMigrationStatus."Total Number" := 1; // dummy number to migrate (if 0, the status line won't be created)
        DataMigrationStatus.Insert();

        // [WHEN] Call the migration codeunit
        asserterror DataMigrationMgt.StartMigration(FakeMigrationTxt, false);
        DataMigrationStatus.DeleteAll();
        if Item.Get(ItemAKeyTxt) then
            Item.Delete();

        // [THEN] It should error because there is an existing vendor
        Assert.IsTrue(
          StrPos(GetLastErrorText, 'vendors') > 0, StrSubstNo('Expected the error to be about vendor but %1', GetLastErrorText));

        // [GIVEN] We have an existing Item

        Item.Init();
        Item."No." := ItemAKeyTxt;
        Item.Insert();

        DataMigrationStatus.Init();
        DataMigrationStatus."Migration Type" := FakeMigrationTxt;
        DataMigrationStatus."Destination Table ID" := DATABASE::Item;
        DataMigrationStatus."Total Number" := 1; // dummy number to migrate (if 0, the status line won't be created)
        DataMigrationStatus."Source Staging Table ID" := DATABASE::"Data Mig. Item Staging Table";
        DataMigrationStatus.Insert();

        // [WHEN] Call the migration codeunit
        asserterror DataMigrationMgt.StartMigration(FakeMigrationTxt, false);

        // [THEN] It should error because there is an existing item
        Assert.IsTrue(StrPos(GetLastErrorText, 'items') > 0, StrSubstNo('Expected the error to be about item but %1', GetLastErrorText));

        UnbindSubscription(DataMigrationTests);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGLAccountsCleared()
    var
        DataMigrationStatus: Record "Data Migration Status";
        GLAccount: Record "G/L Account";
        DataMigrationMgt: Codeunit "Data Migration Mgt.";
        DataMigrationTests: Codeunit "Data Migration Tests";
    begin
        // [SCENARIO] GL account migration is run, and existing GL accounts are cleared

        Initialize();
        IssueError := true;

        if not BindSubscription(DataMigrationTests) then;

        // [GIVEN] We have a GL account that already exists
        GLAccount.Init();
        GLAccount."No." := GLAccountTxt;
        GLAccount.Insert();

        // [GIVEN] Create the data migration status line for GL account
        DataMigrationStatus.Init();
        DataMigrationStatus."Migration Type" := FakeMigrationTxt;
        DataMigrationStatus."Destination Table ID" := DATABASE::"G/L Account"; // GL account migration
        DataMigrationStatus."Source Staging Table ID" := DATABASE::"Data Mig. Item Staging Table"; // dummy staging table to use
        DataMigrationStatus."Total Number" := 1; // dummy number to migrate (if 0, the status line won't be created)
        DataMigrationStatus.Insert();

        // [WHEN] Call the migration codeunit
        DataMigrationMgt.StartMigration(FakeMigrationTxt, false);

        // [THEN] Check for the result on the status line
        DataMigrationStatus.Get(DataMigrationStatus."Migration Type", DataMigrationStatus."Destination Table ID");

        Assert.AreEqual(1, DataMigrationStatus."Total Number", 'Wrong total number');
        Assert.AreEqual(0, DataMigrationStatus."Migrated Number", 'None should be migrated since there is nothing to migrate');
        DataMigrationStatus.CalcFields("Error Count");
        Assert.AreEqual(0, DataMigrationStatus."Error Count", 'No error should happen');
        Assert.AreEqual(DataMigrationStatus.Status::Completed, DataMigrationStatus.Status, 'No error expected');

        // [THEN] G/L Account table is cleared
        GLAccount.Reset();
        Assert.IsTrue(GLAccount.IsEmpty, 'GL account table is not empty, it should be');

        UnbindSubscription(DataMigrationTests);
    end;

    local procedure CreateStagingTableEntry("Key": Code[10]; Description: Text[50])
    var
        DataMigItemStagingTable: Record "Data Mig. Item Staging Table";
    begin
        DataMigItemStagingTable.Init();
        DataMigItemStagingTable."Item Key" := Key;
        DataMigItemStagingTable."Item Description" := Description;
        DataMigItemStagingTable.Insert();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Data Migration Mgt.", 'OnBeforeStartMigration', '', false, false)]
    local procedure OnBeforeStartMigration(var StartNewSession: Boolean; var CheckExistingData: Boolean)
    begin
        StartNewSession := false;
        CheckExistingData := ExistingDataCheck;
        LibraryVariableStorage.Enqueue(StartNewSession);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Data Migration Facade", 'OnMigrateItem', '', false, false)]
    local procedure OnMigrateItem(var Sender: Codeunit "Item Data Migration Facade"; RecordIdToMigrate: RecordID)
    var
        DataMigItemStagingTable: Record "Data Mig. Item Staging Table";
        Item: Record Item;
    begin
        if RecordIdToMigrate.TableNo <> DATABASE::"Data Mig. Item Staging Table" then
            exit;

        DataMigItemStagingTable.Get(RecordIdToMigrate);

        // Raise error for the second item
        if IssueError and (DataMigItemStagingTable."Item Key" = ItemBKeyTxt) then
            Error(FakeErrorErr);

        Sender.CreateItemIfNeeded(DataMigItemStagingTable."Item Key", DataMigItemStagingTable."Item Description", '',
          Item.Type::Inventory.AsInteger());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSearchLanguage()
    var
        Language: Record Language;
        DataMigrationFacadeHelper: Codeunit "Data Migration Facade Helper";
        ResultCode: Code[10];
    begin
        Language.Get('FRA');
        Assert.IsTrue(DataMigrationFacadeHelper.SearchLanguage('FRA', ResultCode), 'Language search failed');
        Assert.AreEqual(Language.Code, ResultCode, 'Language search did not return the expected language');
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestExtensionUninstalled()
    var
        DataMigrationErrorTable: Record "Data Migration Error";
        DataMigrationStatus: Record "Data Migration Status";
        Customer: Record Customer;
        DataMigrationError: TestPage "Data Migration Error";
    begin
        // [SCENARIO] When the extension is uninstalled and you drilldown on the migration errors throw the right error
        DataMigrationErrorTable.DeleteAll();
        Customer.DeleteAll();
        DataMigrationStatus.DeleteAll();

        // [GIVEN] Data Migration Error table gets populated with errors
        Customer.Init();
        DataMigrationErrorTable.Init();
        DataMigrationErrorTable."Error Message" := 'Some error';
        DataMigrationErrorTable."Migration Type" := 'MigrationType';
        DataMigrationErrorTable."Source Staging Table Record ID" := Customer.RecordId;
        DataMigrationErrorTable."Destination Table ID" := 1000;
        DataMigrationErrorTable.Insert();

        DataMigrationStatus.Init();
        DataMigrationStatus."Migration Type" := DataMigrationErrorTable."Migration Type";
        DataMigrationStatus."Destination Table ID" := DataMigrationErrorTable."Destination Table ID";
        DataMigrationStatus.Insert();
        DataMigrationError.OpenEdit();

        // [WHEN] we Drilldown on the Migration error messages
        asserterror DataMigrationError."Error Message".DrillDown();

        // [THEN] The right error message gets thrown that the extension is not installed.
        Assert.ExpectedError(ExtensionNotInstalledErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnSelectRowFromDashboardEvent()
    var
        DataMigrationStatus: Record "Data Migration Status";
        DataMigrationTests: Codeunit "Data Migration Tests";
        DataMigrationOverview: TestPage "Data Migration Overview";
    begin
        // [SCENARIO] Extensions can subscribe on the OnSelectRecord event to open a page for showing the staging records
        Initialize();

        if not BindSubscription(DataMigrationTests) then;
        // [GIVEN] There is at least one line on the Data Migration Overview Page
        DataMigrationStatus.Init();
        DataMigrationStatus.Status := DataMigrationStatus.Status::Completed;
        DataMigrationStatus.Insert();

        // [WHEN] The Total Number field on a record is clicked
        // [THEN] an event is raised that can be captured on the extensions
        DataMigrationOverview.OpenEdit();
        DataMigrationOverview.First();
        asserterror DataMigrationOverview."Total Number".DrillDown();

        // Verify that the error on our event subscriber was thrown
        Assert.ExpectedError(FakeErrorErr);

        UnbindSubscription(DataMigrationTests);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SendNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestSkipAllRecords()
    var
        Customer: Record Customer;
        DataMigrationStatus: Record "Data Migration Status";
        DataMigrationTests: Codeunit "Data Migration Tests";
        DataMigrationErrorPage: TestPage "Data Migration Error";
    begin
        // [SCENARIO] When a record is skipped then error count and total number of records decreases
        // if the total number of records reaches 0 then this entry is removed
        Initialize();

        if not BindSubscription(DataMigrationTests) then;

        // [GIVEN] The Migration has completed with errors
        InitializeMigrationWithErrors(2);

        // [WHEN] The first error is skipped
        DataMigrationErrorPage.OpenView();
        SkipFirstError(DataMigrationErrorPage);

        // [THEN] The staging table record is deleted
        // [THEN] The Total number of records and errors decreases by one
        VerifySkippedRecords(1, 1);

        // [WHEN] The second error is skipped
        SkipFirstError(DataMigrationErrorPage);

        // [THEN] The staging table record is deleted
        Assert.IsFalse(Customer.Get(LibraryVariableStorage.DequeueText()), 'Staging record was expected to be deleted');

        // [THEN] The whole entry of Data Migration Status is deleted
        Assert.RecordIsEmpty(DataMigrationStatus);

        UnbindSubscription(DataMigrationTests);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SendNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestSkipSomeRecords()
    var
        DataMigrationStatus: Record "Data Migration Status";
        DataMigrationTests: Codeunit "Data Migration Tests";
        DataMigrationErrorPage: TestPage "Data Migration Error";
    begin
        // [SCENARIO] When a record is skipped then error count and total number of records decreases
        // if all errors are skipped or corrected then the status changes to completed
        Initialize();

        if not BindSubscription(DataMigrationTests) then;

        // [GIVEN] The Migration has completed with errors
        InitializeMigrationWithErrors(3);

        // [WHEN] The first error is skipped
        DataMigrationErrorPage.OpenView();
        SkipFirstError(DataMigrationErrorPage);

        // [THEN] The staging table record is deleted
        // [THEN] The Total number of records and errors decreases by one
        VerifySkippedRecords(2, 1);

        // [WHEN] The second error is skipped
        SkipFirstError(DataMigrationErrorPage);

        // [THEN] The status is changed to completed
        DataMigrationStatus.FindFirst();
        Assert.AreEqual(DataMigrationStatus.Status::Completed, DataMigrationStatus.Status, 'Status was expected to be completed.');

        UnbindSubscription(DataMigrationTests);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,SendNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestRetry()
    var
        DataMigrationTests: Codeunit "Data Migration Tests";
        DataMigrationErrorPage: TestPage "Data Migration Error";
        DummyVariable: Variant;
    begin
        // [SCENARIO] When the action migrate is clicked for a record with errors
        // then migration starts on the background
        if not BindSubscription(DataMigrationTests) then;
        Initialize();

        // [GIVEN] The Migration has completed errors
        InitializeMigrationWithErrors(2);

        // [WHEN] The first error is retried
        DataMigrationErrorPage.OpenView();
        DataMigrationErrorPage.First();
        DataMigrationErrorPage.Migrate.Invoke();

        // [THEN] The migration for the corresponding records starts
        // Verify the OnBeforeStartMigration event was fired by trying to enqueue a variable enqueueed in the subscriber
        LibraryVariableStorage.Dequeue(DummyVariable);

        UnbindSubscription(DataMigrationTests);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdateMigrationStatus()
    var
        DataMigrationStatus: Record "Data Migration Status";
        JobQueueEntry: Record "Job Queue Entry";
        DataMigrationMgt: Codeunit "Data Migration Mgt.";
    begin
        // [SCENARIO] The Data Migration Status is changed based on the Job Queue Status
        JobQueueEntry.DeleteAll();

        // [GIVEN] There is a failed Job Queue
        InitializeJobQueueWithStatus(JobQueueEntry.Status::Error);
        // [GIVEN] The MigrationStatus is in progress
        InitializeDataMigrationStatusWithStatus(DataMigrationStatus, DataMigrationStatus.Status::"In Progress");
        // [WHEN] The UpdateMigrationStatus is called
        DataMigrationMgt.UpdateMigrationStatus(DataMigrationStatus);
        // [THEN] The migration Status is set to failed
        Assert.AreEqual(DataMigrationStatus.Status::Failed, DataMigrationStatus.Status, 'Status is not failed');

        // [GIVEN] There is a failed Job Queue
        // [GIVEN] The MigrationStatus is pending
        InitializeDataMigrationStatusWithStatus(DataMigrationStatus, DataMigrationStatus.Status::Pending);
        // [WHEN] The UpdateMigrationStatus is called
        DataMigrationMgt.UpdateMigrationStatus(DataMigrationStatus);
        // [THEN] The migration Status is set to failed
        Assert.AreEqual(DataMigrationStatus.Status::Failed, DataMigrationStatus.Status, 'Status is not failed');

        // [GIVEN] There is a failed Job Queue
        // [GIVEN] The MigrationStatus is pending
        InitializeDataMigrationStatusWithStatus(DataMigrationStatus, DataMigrationStatus.Status::Completed);
        // [WHEN] The UpdateMigrationStatus is called
        DataMigrationMgt.UpdateMigrationStatus(DataMigrationStatus);
        // [THEN] The migration Status remains unchanged
        Assert.AreEqual(DataMigrationStatus.Status::Completed, DataMigrationStatus.Status, 'Status is changed');

        // [GIVEN] There is a failed Job Queue and a job queue in progress
        // [GIVEN] The MigrationStatus is in progress
        InitializeJobQueueWithStatus(JobQueueEntry.Status::"In Process");
        InitializeDataMigrationStatusWithStatus(DataMigrationStatus, DataMigrationStatus.Status::"In Progress");
        // [WHEN] The UpdateMigrationStatus is called
        DataMigrationMgt.UpdateMigrationStatus(DataMigrationStatus);
        // [THEN] The migration Status is unchanged
        Assert.AreEqual(DataMigrationStatus.Status::"In Progress", DataMigrationStatus.Status, 'Status is changed');

        // [GIVEN] There is a failed Job Queue and a job queue Ready
        // [GIVEN] The MigrationStatus is in progress
        InitializeJobQueueWithStatus(JobQueueEntry.Status::Ready);
        InitializeDataMigrationStatusWithStatus(DataMigrationStatus, DataMigrationStatus.Status::Pending);
        // [WHEN] The UpdateMigrationStatus is called
        DataMigrationMgt.UpdateMigrationStatus(DataMigrationStatus);
        // [THEN] The migration Status is unchanged
        Assert.AreEqual(DataMigrationStatus.Status::Pending, DataMigrationStatus.Status, 'Status is changed');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Data Migration Facade", 'OnSelectRowFromDashboard', '', false, false)]
    local procedure OnSelectRowFromDashboardSubscriber(var DataMigrationStatus: Record "Data Migration Status")
    begin
        Error(FakeErrorErr);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(SkipSelectionConfirmQst, Question);
        Reply := true;
    end;

    local procedure SkipFirstError(var DataMigrationErrorPage: TestPage "Data Migration Error")
    begin
        DataMigrationErrorPage.First();
        DataMigrationErrorPage.SkipSelection.Invoke();
    end;

    local procedure VerifySkippedRecords(TotalNumber: Integer; ErrorCount: Integer)
    var
        DataMigrationStatus: Record "Data Migration Status";
        Customer: Record Customer;
        CustomerNoVariant: Variant;
    begin
        LibraryVariableStorage.Dequeue(CustomerNoVariant);
        Assert.IsFalse(Customer.Get(CustomerNoVariant), 'Staging record was expected to be deleted');

        DataMigrationStatus.FindFirst();
        Assert.AreEqual(TotalNumber, DataMigrationStatus."Total Number", 'A different number of total records was expected.');
        DataMigrationStatus.CalcFields("Error Count");
        Assert.AreEqual(ErrorCount, DataMigrationStatus."Error Count", 'A different number of errors was expected.');
    end;

    local procedure InitializeMigrationWithErrors(TotalNumberOfRecord: Integer)
    var
        DataMigrationStatus: Record "Data Migration Status";
        DataMigrationError: Record "Data Migration Error";
        Customer: Record Customer;
    begin
        DataMigrationStatus.Init();
        DataMigrationStatus."Migration Type" := 'Migration1';
        DataMigrationStatus."Destination Table ID" := DATABASE::Item;
        DataMigrationStatus.Status := DataMigrationStatus.Status::"Completed with Errors";
        DataMigrationStatus."Migration Codeunit To Run" := CODEUNIT::"Data Migration Facade";
        DataMigrationStatus."Total Number" := TotalNumberOfRecord;
        DataMigrationStatus."Error Count" := 2;
        DataMigrationStatus.Insert();

        Customer.DeleteAll();
        Customer."No." := '1';
        LibraryVariableStorage.Enqueue(Customer."No.");
        Customer.Insert();

        DataMigrationError.Init();
        DataMigrationError.Id := 1;
        DataMigrationError."Migration Type" := 'Migration1';
        DataMigrationError."Destination Table ID" := DATABASE::Item;
        DataMigrationError."Source Staging Table Record ID" := Customer.RecordId;
        DataMigrationError.Insert();

        Customer."No." := '2';
        LibraryVariableStorage.Enqueue(Customer."No.");
        Customer.Insert();

        DataMigrationError.Init();
        DataMigrationError."Destination Table ID" := DATABASE::Item;
        DataMigrationError."Migration Type" := 'Migration1';
        DataMigrationError.Id := 2;
        DataMigrationError."Source Staging Table Record ID" := Customer.RecordId;
        DataMigrationError.Insert();
    end;

    [Scope('OnPrem')]
    procedure InitializeJobQueueWithStatus(Status: Option)
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.ID := CreateGuid();
        JobQueueEntry."Object ID to Run" := CODEUNIT::"Data Migration Mgt.";
        JobQueueEntry.Status := Status;
        JobQueueEntry.Insert();
    end;

    [Scope('OnPrem')]
    procedure InitializeDataMigrationStatusWithStatus(var DataMigrationStatus: Record "Data Migration Status"; Status: Option)
    begin
        DataMigrationStatus.DeleteAll();
        DataMigrationStatus.Status := Status;
        DataMigrationStatus.Insert();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text)
    begin
        Assert.ExpectedMessage(MigrationStartedMsg, Message);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Data Migration Facade", 'OnFillStagingTables', '', false, false)]
    local procedure OnFillStagingTablesSubscriber()
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Queue - Enqueue", 'OnBeforeJobQueueScheduleTask', '', true, true)]
    local procedure OnBeforeScheduleTask(var JobQueueEntry: Record "Job Queue Entry"; var DoNotScheduleTask: Boolean)
    begin
        DoNotScheduleTask := true;
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SendNotificationHandler(var Notification: Notification): Boolean
    begin
        Assert.ExpectedMessage(SkipEditNotificationMsg, Notification.Message);
    end;
}

