codeunit 135021 "Data Migr. Notification Tests"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Data Migration] [Notification]
    end;

    var
        Assert: Codeunit Assert;
        DataMigrationMgt: Codeunit "Data Migration Mgt.";
        DashboardEmptyNotificationMsg: Label 'This page shows the status of a data migration. It''s empty because you have not migrated data.';
        RefreshNotificationMsg: Label 'Data migration is in progress. Refresh the page to update the migration status.';
        DataMigrationInProgressMsg: Label 'We''re migrating data to', Comment = ' %1 Product name ';
        DataMigrationCompletedWithErrosMsg: Label 'Data migration has stopped due to errors. Go to the %1 page to fix them.', Comment = '%1 Data Migration Overview page';
        DataMigrationFinishedMsg: Label 'Yes! The data you chose was successfully migrated.';
        DataMigrationEntriesToPostMsg: Label 'Data migration is complete, however, there are still a few things to do. Go to the Data Migration Overview page for more information.';

    [Test]
    [HandlerFunctions('EmptyDashBoardNotificationHandler,DataMigrationWizardPageHandler')]
    [Scope('OnPrem')]
    procedure TestEmptyDashBoardNotification()
    var
        DataMigrationStatus: Record "Data Migration Status";
        DataMigrationOverview: TestPage "Data Migration Overview";
    begin
        // [SCENARIO] A Notification with an action to start data migration is shown when user visits the empty data migration overview page
        // [GIVEN] No Migration has started
        DataMigrationStatus.DeleteAll();
        // [WHEN] User opens Data Migration Overview page
        DataMigrationOverview.OpenView();
        // [THEN] A notification is fired with an action to start the data migration wizzard
        // Verify on EmptyDashBoardNotificationHandler and DataMigrationWizardPageHandler
    end;

    [Test]
    [HandlerFunctions('RefreshDashBoardNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestRefreshDashBoardNotification()
    var
        JobQueueEntry: Record "Job Queue Entry";
        DataMigrationStatus: Record "Data Migration Status";
        DataMigrationOverview: TestPage "Data Migration Overview";
    begin
        // [SCENATIO] A Notification to refresh the overview is fired when a data migration is in progress
        // [GIVEN] Data Migration is In Progress
        InitializeMigration(DataMigrationStatus.Status::"In Progress", JobQueueEntry.Status::"In Process");

        // [WHEN] User opens Data Migration Overview page
        DataMigrationOverview.OpenView();

        // [THEN] A notification is fired
        // Verify on EmptyDashBoardNotificationHandler
        CleanUp();
    end;

    [Test]
    [HandlerFunctions('MigrationInProgressNotificationHandler,MoreInfoModalPageHandler,DataMigrationOverviewPageHandler')]
    [Scope('OnPrem')]
    procedure TestRoleCenterNotificationWhenMigrationInProgress()
    var
        JobQueueEntry: Record "Job Queue Entry";
        DataMigrationStatus: Record "Data Migration Status";
        AccountantActivities: TestPage "Accountant Activities";
    begin
        // [SCENARIO] A notification is shown in the role center when a migration is in progress
        // [GIVEN] Data Migration is In Progress
        InitializeMigration(DataMigrationStatus.Status::"In Progress", JobQueueEntry.Status::"In Process");

        // [WHEN] The role center is opened
        AccountantActivities.OpenView();

        // [THEN] A notification is shown
        // Verify in MigrationInProgressNotification, MoreInfoPageHandler and DataMigrationOverviewPageHandler
        CleanUp();
    end;

    [Test]
    [HandlerFunctions('MigrationCompletedWithErrorsNotificationHandler,DataMigrationOverviewPageHandler')]
    [Scope('OnPrem')]
    procedure TestRoleCenterNotificationWhenMigrationsHasErrors()
    var
        JobQueueEntry: Record "Job Queue Entry";
        DataMigrationStatus: Record "Data Migration Status";
        AccountantActivities: TestPage "Accountant Activities";
    begin
        // [SCENARIO] A notification is shown in the role center when a migration is completed with errors and has an action that lead to the overview page
        // [GIVEN] Data Migration is completed with errors
        InitializeMigration(DataMigrationStatus.Status::"Completed with Errors", JobQueueEntry.Status::Finished);

        // [WHEN] The role center is opened
        AccountantActivities.OpenView();

        // [THEN] A notification is shown
        // Verify in MigrationCompletedWithErrorsNotificationHandler, DataMigrationOverviewPageHandler
        CleanUp();
    end;

    [Test]
    [HandlerFunctions('MigrationCompletedNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestRoleCenterNotificationWhenMigrationsHasCompleted()
    var
        JobQueueEntry: Record "Job Queue Entry";
        DataMigrationStatus: Record "Data Migration Status";
        AccountantActivities: TestPage "Accountant Activities";
    begin
        // [SCENARIO] A notification is shown in the role center when a migration is completed and has an action to not show it again
        // [GIVEN] Data Migration is completed
        InitializeMigration(DataMigrationStatus.Status::Completed, JobQueueEntry.Status::Finished);

        // [WHEN] The role center is opened
        AccountantActivities.OpenView();

        // [THEN] A notification is shown
        // Verify in MigrationCompletedNotificationHandler
        CleanUp();
    end;

    [Test]
    [HandlerFunctions('MigrationEntriesToBePostedNotificationHandler,DataMigrationOverviewPageHandler')]
    [Scope('OnPrem')]
    procedure TestRoleCenterNotificationWhenThereAreCustEntriesToBePosted()
    var
        DataMigrNotificationTests: Codeunit "Data Migr. Notification Tests";
        AccountantActivities: TestPage "Accountant Activities";
    begin
        // [SCENARIO] A notification is shown in the role center when a migration is completed
        // but there are still records to be posted and has an action that lead to the overview page
        BindSubscription(DataMigrNotificationTests);
        // [GIVEN] Data Migration is completed and there are entries to be posted
        InitializeCompletedMigrationWithCustVendEntriesToBePosted(DATABASE::Customer);

        // [WHEN] The role center is opened
        AccountantActivities.OpenView();

        // [THEN] A notification is shown
        // Verify in MigrationEntriesToBePostedNotificationHandler
        CleanUp();
        UnbindSubscription(DataMigrNotificationTests);
    end;

    [Test]
    [HandlerFunctions('MigrationEntriesToBePostedNotificationHandler,DataMigrationOverviewPageHandler')]
    [Scope('OnPrem')]
    procedure TestRoleCenterNotificationWhenThereAreVendEntriesToBePosted()
    var
        DataMigrNotificationTests: Codeunit "Data Migr. Notification Tests";
        AccountantActivities: TestPage "Accountant Activities";
    begin
        // [SCENARIO] A notification is shown in the role center when a migration is completed
        // but there are still records to be posted and has an action that lead to the overview page
        BindSubscription(DataMigrNotificationTests);
        // [GIVEN] Data Migration is completed and there are entries to be posted
        InitializeCompletedMigrationWithCustVendEntriesToBePosted(DATABASE::Vendor);

        // [WHEN] The role center is opened
        AccountantActivities.OpenView();

        // [THEN] A notification is shown
        // Verify in MigrationEntriesToBePostedNotificationHandler
        CleanUp();
        UnbindSubscription(DataMigrNotificationTests);
    end;

    [Test]
    [HandlerFunctions('MigrationEntriesToBePostedNotificationHandler,DataMigrationOverviewPageHandler')]
    [Scope('OnPrem')]
    procedure TestRoleCenterNotificationWhenThereAreItemEntriesToBePosted()
    var
        DataMigrNotificationTests: Codeunit "Data Migr. Notification Tests";
        AccountantActivities: TestPage "Accountant Activities";
    begin
        // [SCENARIO] A notification is shown in the role center when a migration is completed
        // but there are still records to be posted and has an action that lead to the overview page
        BindSubscription(DataMigrNotificationTests);
        // [GIVEN] Data Migration is completed and there are entries to be posted
        InitializeCompletedMigrationWithItemEntriesToBePosted();

        // [WHEN] The role center is opened
        AccountantActivities.OpenView();

        // [THEN] A notification is shown
        // Verify in MigrationEntriesToBePostedNotificationHandler
        CleanUp();
        UnbindSubscription(DataMigrNotificationTests);
    end;

    [Test]
    [HandlerFunctions('MigrationEntriesToBePostedNotificationHandler,DataMigrationOverviewPageHandler')]
    [Scope('OnPrem')]
    procedure TestRoleCenterNotificationWhenThereAreAccountEntriesToBePosted()
    var
        DataMigrNotificationTests: Codeunit "Data Migr. Notification Tests";
        AccountantActivities: TestPage "Accountant Activities";
    begin
        // [SCENARIO] A notification is shown in the role center when a migration is completed
        // but there are still records to be posted and has an action that lead to the overview page
        BindSubscription(DataMigrNotificationTests);
        // [GIVEN] Data Migration is completed and there are entries to be posted
        InitializeCompletedMigrationWithAccountEntriesToBePosted();

        // [WHEN] The role center is opened
        AccountantActivities.OpenView();

        // [THEN] A notification is shown
        // Verify in MigrationEntriesToBePostedNotificationHandler
        CleanUp();
        UnbindSubscription(DataMigrNotificationTests);
    end;

    [Test]
    [HandlerFunctions('MigrationCompletedNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestRoleCenterNotificationWhenExtensionHasNotRegisteredASubscriber()
    var
        AccountantActivities: TestPage "Accountant Activities";
    begin
        // [SCENARIO] When a migration is completed, there are still records to be posted,
        // but the extension has not subscribed to OnFindBatchForItemTransactions event,
        // then the completed notification is fired
        // [GIVEN] Data Migration is completed and there are entries to be posted
        InitializeCompletedMigrationWithItemEntriesToBePosted();

        // [WHEN] The role center is opened
        AccountantActivities.OpenView();

        // [THEN] A notification is shown
        // Verify in MigrationCompletedNotificationHandler
        CleanUp();
    end;

    local procedure InitializeMigration(MigrationStatus: Option; JobQueueStatus: Option)
    var
        JobQueueEntry: Record "Job Queue Entry";
        DataMigrationStatus: Record "Data Migration Status";
    begin
        // A Data Migration Status entry with Status:In Progress
        DataMigrationStatus.DeleteAll();

        DataMigrationStatus.Init();
        DataMigrationStatus.Status := MigrationStatus;
        DataMigrationStatus.Insert(true);

        // The corresponding job queue is running
        JobQueueEntry.Init();
        JobQueueEntry.ID := CreateGuid();
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := CODEUNIT::"Data Migration Mgt.";
        JobQueueEntry.Status := JobQueueStatus;
        JobQueueEntry.Insert();
    end;

    local procedure InitializeCompletedMigrationWithItemEntriesToBePosted()
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        JobQueueEntry: Record "Job Queue Entry";
        DataMigrationStatus: Record "Data Migration Status";
    begin
        InitializeMigration(DataMigrationStatus.Status::Completed, JobQueueEntry.Status::Finished);

        // Create entries to be posted for items
        ItemJournalTemplate.Init();
        ItemJournalTemplate.Name := 'IJTN';
        ItemJournalTemplate.Insert(true);

        ItemJournalBatch.Init();
        ItemJournalBatch."Journal Template Name" := ItemJournalTemplate.Name;
        ItemJournalBatch.Name := 'JBN';
        ItemJournalBatch.Insert(true);

        ItemJournalLine.Init();
        ItemJournalLine."Journal Batch Name" := 'JBN';
        ItemJournalLine."Journal Template Name" := ItemJournalTemplate.Name;
        ItemJournalLine."Item No." := 'IT001';
        ItemJournalLine.Insert(true);

        // Ensure items migration is selected
        DataMigrationStatus.FindFirst();
        DataMigrationStatus.Rename('', DATABASE::Item);
    end;

    local procedure InitializeCompletedMigrationWithCustVendEntriesToBePosted(TableNo: Integer)
    var
        JobQueueEntry: Record "Job Queue Entry";
        DataMigrationStatus: Record "Data Migration Status";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        InitializeMigration(DataMigrationStatus.Status::Completed, JobQueueEntry.Status::Finished);

        // Create entries to be posted for items
        GenJournalTemplate.Init();
        GenJournalTemplate.Name := 'GJTN';
        GenJournalTemplate.Insert(true);

        GenJournalBatch.Init();
        GenJournalBatch."Journal Template Name" := GenJournalTemplate.Name;
        GenJournalBatch.Name := 'JBN';
        GenJournalBatch.Insert(true);

        GenJournalLine.Init();
        GenJournalLine."Journal Batch Name" := 'JBN';
        GenJournalLine."Journal Template Name" := GenJournalTemplate.Name;
        GenJournalLine."Account Type" := GenJournalLine."Account Type"::Customer;
        GenJournalLine."Account No." := 'Gl0001';
        GenJournalLine."Line No." := 1;
        GenJournalLine.Insert(true);

        GenJournalLine.Init();
        GenJournalLine."Journal Batch Name" := 'JBN';
        GenJournalLine."Journal Template Name" := GenJournalTemplate.Name;
        GenJournalLine."Account Type" := GenJournalLine."Account Type"::Vendor;
        GenJournalLine."Account No." := 'Gl0001';
        GenJournalLine."Line No." := 2;
        GenJournalLine.Insert(true);

        // Ensure proper migration is selected
        DataMigrationStatus.FindFirst();
        DataMigrationStatus.Rename('', TableNo);
    end;

    local procedure InitializeCompletedMigrationWithAccountEntriesToBePosted()
    var
        JobQueueEntry: Record "Job Queue Entry";
        DataMigrationStatus: Record "Data Migration Status";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        InitializeMigration(DataMigrationStatus.Status::Completed, JobQueueEntry.Status::Finished);

        // Create entries to be posted for items
        GenJournalTemplate.Init();
        GenJournalTemplate.Name := 'GJTN';
        GenJournalTemplate.Insert(true);

        GenJournalBatch.Init();
        GenJournalBatch."Journal Template Name" := GenJournalTemplate.Name;
        GenJournalBatch.Name := 'JBN';
        GenJournalBatch.Insert(true);

        GenJournalLine.Init();
        GenJournalLine."Journal Batch Name" := 'JBN';
        GenJournalLine."Journal Template Name" := GenJournalTemplate.Name;
        GenJournalLine."Account Type" := GenJournalLine."Account Type"::"G/L Account";
        GenJournalLine."Account No." := 'Gl0001';
        GenJournalLine."Line No." := 1;
        GenJournalLine.Insert(true);

        // Ensure Accounts migration is selected
        DataMigrationStatus.FindFirst();
        DataMigrationStatus.Rename('', DATABASE::"G/L Account");
    end;

    local procedure CleanUp()
    var
        JobQueueEntry: Record "Job Queue Entry";
        DataMigrationStatus: Record "Data Migration Status";
        MyNotifications: Record "My Notifications";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        JobQueueEntry.DeleteAll();
        DataMigrationStatus.DeleteAll();
        if MyNotifications.Get(UserId, DataMigrationMgt.GetGlobalNotificationId()) then begin
            MyNotifications.Enabled := true;
            MyNotifications.Modify(true);
        end;
        ItemJournalBatch.SetRange(Name, 'IJTN');
        ItemJournalTemplate.DeleteAll();
        ItemJournalBatch.SetRange(Name, 'JBN');
        ItemJournalBatch.DeleteAll();
        ItemJournalLine.SetRange("Journal Batch Name", 'JBN');
        ItemJournalLine.DeleteAll();
        GenJournalTemplate.SetRange(Name, 'GJTN');
        GenJournalTemplate.DeleteAll();
        GenJournalBatch.SetRange(Name, 'JBN');
        GenJournalBatch.DeleteAll();
        GenJournalLine.SetRange("Journal Batch Name", 'JBN');
        GenJournalLine.DeleteAll();
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure EmptyDashBoardNotificationHandler(var Notification: Notification): Boolean
    begin
        Assert.ExpectedMessage(DashboardEmptyNotificationMsg, Notification.Message);
        DataMigrationMgt.StartDataMigrationWizardFromNotification(Notification);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure DataMigrationWizardPageHandler(var DataMigrationWizard: Page "Data Migration Wizard")
    begin
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure RefreshDashBoardNotificationHandler(var Notification: Notification): Boolean
    begin
        Assert.ExpectedMessage(RefreshNotificationMsg, Notification.Message);
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure MigrationInProgressNotificationHandler(var Notification: Notification): Boolean
    begin
        if Notification.Id <> DataMigrationMgt.GetGlobalNotificationId() then
            exit;
        Assert.ExpectedMessage(StrSubstNo(DataMigrationInProgressMsg, PRODUCTNAME.Short()), Notification.Message);
        DataMigrationMgt.ShowMoreInfoPage(Notification);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure MoreInfoModalPageHandler(var DataMigrationAbout: Page "Data Migration About"; var Response: Action)
    begin
        Response := ACTION::LookupOK;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure DataMigrationOverviewPageHandler(var DataMigrationOverview: Page "Data Migration Overview")
    begin
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure MigrationCompletedWithErrorsNotificationHandler(var Notification: Notification): Boolean
    var
        DataMigrationOverview: Page "Data Migration Overview";
    begin
        if Notification.Id <> DataMigrationMgt.GetGlobalNotificationId() then
            exit;
        Assert.ExpectedMessage(StrSubstNo(DataMigrationCompletedWithErrosMsg, DataMigrationOverview.Caption), Notification.Message);
        DataMigrationMgt.ShowDataMigrationOverviewFromNotification(Notification);
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure MigrationCompletedNotificationHandler(var Notification: Notification): Boolean
    var
        MyNotifications: Record "My Notifications";
    begin
        if Notification.Id <> DataMigrationMgt.GetGlobalNotificationId() then
            exit;
        Assert.ExpectedMessage(DataMigrationFinishedMsg, Notification.Message);
        DataMigrationMgt.DisableDataMigrationRelatedGlobalNotifications(Notification);
        // Verify Notification is disabled
        Assert.IsFalse(MyNotifications.IsEnabled(DataMigrationMgt.GetGlobalNotificationId()), 'Notification should have been disabled');
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure MigrationEntriesToBePostedNotificationHandler(var Notification: Notification): Boolean
    begin
        if Notification.Id <> DataMigrationMgt.GetGlobalNotificationId() then
            exit;
        Assert.ExpectedMessage(DataMigrationEntriesToPostMsg, Notification.Message);
        DataMigrationMgt.ShowDataMigrationOverviewFromNotification(Notification);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Data Migration Facade", 'OnFindBatchForItemTransactions', '', false, false)]
    local procedure OnFindBatchForItemTransactions(MigrationType: Text[250]; var ItemJournalBatchName: Code[10])
    begin
        ItemJournalBatchName := 'JBN';
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Data Migration Facade", 'OnFindBatchForCustomerTransactions', '', false, false)]
    local procedure OnFindBatchForCustomerTransactions(MigrationType: Text[250]; var GenJournalBatchName: Code[10])
    begin
        GenJournalBatchName := 'JBN';
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Data Migration Facade", 'OnFindBatchForVendorTransactions', '', false, false)]
    local procedure OnFindBatchForVendorTransactions(MigrationType: Text[250]; var GenJournalBatchName: Code[10])
    begin
        GenJournalBatchName := 'JBN';
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Data Migration Facade", 'OnFindBatchForAccountTransactions', '', false, false)]
    local procedure OnFindBatchForAccountTransactions(DataMigrationStatus: Record "Data Migration Status"; var GenJournalBatchName: Code[10])
    begin
        GenJournalBatchName := 'JBN';
    end;
}

