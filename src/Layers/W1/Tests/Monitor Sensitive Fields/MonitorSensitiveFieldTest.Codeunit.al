codeunit 139064 "Monitor Sensitive Field Test"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [TestPermissions(TestPermissions::Disabled)]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UserAndEmailValidationBeforeEnableMonitor()
    var
        FieldMonitoringSetup: Record "Field Monitoring Setup";
        User: Record User;
        UserCard: TestPage "User Card";
    begin
        // [Scenario] try To enable without choosing user.
        // [GIVEN] Clean Entry and setup table
        MonitorFieldTestHelper.InitMonitor();

        // [WHEN] Try to enable without choosing a email account
        MonitorSensitiveField.GetSetupTable(FieldMonitoringSetup);
        asserterror MonitorSensitiveField.EnableMonitor(true);
        Assert.ExpectedError(EmailAccountMissingErr);

        MonitorSensitiveField.GetSetupTable(FieldMonitoringSetup);
        FieldMonitoringSetup."Email Account Name" := 'Test';
        FieldMonitoringSetup.Modify();

        asserterror MonitorSensitiveField.EnableMonitor(true);
        Assert.ExpectedError(UserNotFoundErr);

        InsertUser(User, 'TESTUSER', '');
        UserCard.Trap();
        asserterror FieldMonitoringSetup.Validate("User Id", User."User Name");
        FieldMonitoringSetup.Modify();
        Assert.AreEqual(User."User Name", UserCard."User Name".Value(), 'User card for selected user in setup table should have been opened');
        UserCard.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EnableMonitor()
    var
        FieldMonitoringSetup: Record "Field Monitoring Setup";
        User: Record User;
    begin
        // [Scenario] try To enable without choosing user.
        // [GIVEN] Clean Entry and setup table
        LibraryLowerPermissions.SetOutsideO365Scope();
        InsertUser(User, 'TESTUSER', 'test');
        MonitorFieldTestHelper.InitMonitor();

        LibraryLowerPermissions.SetSecurity();
        LibraryLowerPermissions.AddO365Full();
        LibraryLowerPermissions.PushPermissionSet(D365MonitorFields);

        // [WHEN]
        MonitorSensitiveField.GetSetupTable(FieldMonitoringSetup);
        FieldMonitoringSetup.Validate("Email Account Name", 'Test');
        FieldMonitoringSetup.Validate("User Id", User."User Name");
        FieldMonitoringSetup.Modify();

        MonitorSensitiveField.EnableMonitor(true);

        FieldMonitoringSetup.Get();
        Assert.IsTrue(FieldMonitoringSetup."Monitor Status", 'Monitor should be enabled');
        // [THEN] Entry should exist for enabling the monitor
        LibraryLowerPermissions.SetOutsideO365Scope();
        Assert.IsTrue(MonitorFieldTestHelper.EntryExists(Database::"Field Monitoring Setup", FieldMonitoringSetup.FieldNo(FieldMonitoringSetup."Monitor Status"),
            'false', 'true'), 'An entry should be logged after enabling the monitor');
    end;

    [Test]
    [TestPermissions(TestPermissions::Disabled)]
    [HandlerFunctions('CreatePromotionNotificationHandler')]
    procedure ShowPromotionNotification()
    var
        FieldMonitoringSetup: Record "Field Monitoring Setup";
        MyNotifications: Record "My Notifications";
        User: Record User;
    begin
        // [Scenario] Promoting monitor sensitive field in company information page
        // [GIVEN] Clean Entry and setup table
        User.SetRange("User Name", UserId());
        if not User.FindFirst() then
            InsertUser(User, UserId(), '');
        MonitorFieldTestHelper.InitMonitor();

        // [WHEN] Monitor opening company page
        // [THEN] User should get a notification
        MonitorSensitiveField.ShowPromotionNotification();
        Assert.IsTrue(IsPromotionNotificationShown, 'Promotion notification should show up when we open pages with sensitive field');
        CleanUpNotificationBoolean();

        // [WHEN] Monitor is enabled
        // [THEN] No notification
        MonitorSensitiveField.GetSetupTable(FieldMonitoringSetup);
        FieldMonitoringSetup."Monitor Status" := true;
        FieldMonitoringSetup.Modify(false);
        MonitorSensitiveField.ShowPromotionNotification();
        Assert.IsFalse(IsPromotionNotificationShown, 'Promotion notification should not be shown');

        // [WHEN] User ask not to see the promotion message again
        // [THEN] No notification
        MyNotifications.Disable(MonitorSensitiveField.GetPromoteMonitorFeatureNotificationId());
        MonitorSensitiveField.ShowPromotionNotification();
        Assert.IsFalse(IsPromotionNotificationShown, 'Promotion notification should not be shown');
        CleanUpNotificationBoolean();
    end;

    [Test]
    [HandlerFunctions('CreateHiddenTablesNotificationHandler')]
    [TestPermissions(TestPermissions::Disabled)]
    procedure ShowHiddenTablenotificationInChangeLogSetupTable()
    var
        ChangeLogSetupTableList: TestPage "Change Log Setup (Table) List";
        TestTableC: Record "Test Table C";
    begin
        // [Scenario] Notify the user that some tables are hidden because they are monitored in Monitor Sensitive field feature
        // [GIVEN] Clean Entry and setup table
        MonitorFieldTestHelper.InitMonitor();

        ChangeLogSetupTableList.OpenEdit();
        ChangeLogSetupTableList.Close();
        Assert.IsFalse(IsHiddenTableNotificationShown, 'If no fields are monitored, then change log should not have any hidden tables');
        CleanUpNotificationBoolean();

        // [WHEN] Adding record in the monitor
        // [THEN] User should get notification that some tables are hidden in change log
        MonitorSensitiveField.AddMonitoredField(Database::"Test Table C", TestTableC.FieldNo("Integer Field"), true);
        ChangeLogSetupTableList.OpenEdit();
        ChangeLogSetupTableList.Close();
        Assert.IsTrue(IsHiddenTableNotificationShown, 'Hidden table notification should be shown when opening change log table list');
        CleanUpNotificationBoolean();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MonitorSensitiveFieldWithNewEmailModule()
    var
        EmailAccount: Record "Email Account";
        FieldMonitoringSetup: Record "Field Monitoring Setup";
        User: Record User;
        ChangeLogEntry: Record "Change Log Entry";
        ConnectorMock: Codeunit "Connector Mock";
        ChangeLogManagement: Codeunit "Change Log Management";
    begin
        // [Scenario] When a sensitive field change with notification enabled using the new email module, entry should contain message id
        // [GIVEN] Setting up monitor sensitive field with new email module
        LibraryLowerPermissions.SetOutsideO365Scope();
        InsertUser(User, 'TESTUSER', 'test@contoso.com');
        ConnectorMock.Initialize();
        ConnectorMock.AddAccount(EmailAccount);
        MonitorFieldTestHelper.InitMonitor();

        LibraryLowerPermissions.SetSecurity();
        LibraryLowerPermissions.AddO365Full();
        LibraryLowerPermissions.PushPermissionSet(D365MonitorFields);
        LibraryLowerPermissions.AddO365BusFull();

        MonitorSensitiveField.GetSetupTable(FieldMonitoringSetup);
        FieldMonitoringSetup.Validate("Email Account Name", EmailAccount.Name);
        FieldMonitoringSetup.Validate("Email Account Id", EmailAccount."Account Id");
        FieldMonitoringSetup.Validate("User Id", User."User Name");
        FieldMonitoringSetup.Validate("Email Connector", FieldMonitoringSetup."Email Connector"::"Test Email Connector");
        FieldMonitoringSetup.Modify();
        ChangeLogManagement.InitChangeLog();

        // [WHEN] Monitoring field with notification - like status field on fild monitoring setup
        MonitorSensitiveField.EnableMonitor(false);

        // [THEN] Field changes should be logged and a notification email should be sent with the message id part of the entry
        ChangeLogEntry.SetRange("Table No.", Database::"Field Monitoring Setup");
        ChangeLogEntry.SetRange("Field No.", FieldMonitoringSetup.FieldNo("Monitor Status"));
        ChangeLogEntry.SetRange("Field Log Entry Feature", ChangeLogEntry."Field Log Entry Feature"::"Monitor Sensitive Fields");
        Assert.IsTrue(ChangeLogEntry.FindFirst(), 'A log entry should have been added when changing sensitive field');
        if TaskScheduler.CanCreateTask() then begin
            Assert.IsFalse(IsNullGuid(ChangeLogEntry."Notification Message Id"), 'Message Id should have been populated in the log entry');
            Assert.AreEqual(ChangeLogEntry."Notification Status"::"Email Enqueued", ChangeLogEntry."Notification Status", 'Notification status should be sent');
        end else begin
            Assert.IsTrue(IsNullGuid(ChangeLogEntry."Notification Message Id"), 'Fail to send email, Message Id should not be populated');
            Assert.AreEqual(ChangeLogEntry."Notification Status"::"Sending Email Failed", ChangeLogEntry."Notification Status", 'Notification status should be failed');
        end;
    end;

    [Test]
    [TestPermissions(TestPermissions::Disabled)]
    procedure TestNotificationCount()
    var
        FieldMonitoringSetup: Record "Field Monitoring Setup";
        ChangeLogEntry: Record "Change Log Entry";
        MonitorSensitiveFieldData: Codeunit "Monitor Sensitive Field Data";
        FieldLogEntryFeature: enum "Field Log Entry Feature";
    begin
        // [Scenario] Validate monitor notification count
        // [GIVEN] Empty setup and entries table
        MonitorFieldTestHelper.InitMonitor();
        FieldMonitoringSetup.Insert();
        ChangeLogEntry.SetFilter("Field Log Entry Feature", '%1|%2', ChangeLogEntry."Field Log Entry Feature"::"Monitor Sensitive Fields",
            ChangeLogEntry."Field Log Entry Feature"::All);
        ChangeLogEntry.DeleteAll();

        // [WHEN] Inserting new entries, notification count should not be changed.
        MonitorFieldTestHelper.InsertLogEntry(1, FieldLogEntryFeature::"Monitor Sensitive Fields");
        MonitorFieldTestHelper.InsertLogEntry(1, FieldLogEntryFeature::All);

        // [THEN] Notification count field in setup table should be set to 0, and total notification count should be 2
        FieldMonitoringSetup.Get();
        Assert.AreEqual(0, FieldMonitoringSetup."Notification Count", 'Notification Count should equal 0');
        Assert.AreEqual(2, MonitorSensitiveField.GetNotificationCount(), 'Notification Count should equal 2');

        // [WHEN] Resetting notification
        MonitorSensitiveFieldData.ResetNotificationCount();
        FieldMonitoringSetup.Get();

        // [THEN] Notification count field should be equal to current entries count, which should be 2 and getting total notification should be 0
        Assert.AreEqual(2, FieldMonitoringSetup."Notification Count", 'Notification Count should equal 2');
        Assert.AreEqual(0, MonitorSensitiveField.GetNotificationCount(), 'Notification Count should equal 0');
    end;

    local procedure CleanUpNotificationBoolean()
    begin
        IsHiddenTableNotificationShown := false;
        IsPromotionNotificationShown := false;
    end;

    [Normal]
    local procedure InsertUser(var User: Record User; UserName: Text; ContactEmail: Text);
    begin
        User."User Security ID" := CreateGuid();
        User."User Name" := UserName;
        User."Contact Email" := CopyStr(ContactEmail, 1, 80);
        User.State := User.State::Enabled;
        User.Insert();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure CreatePromotionNotificationHandler(var Notification: Notification): Boolean
    begin
        IsPromotionNotificationShown := Notification.Id = MonitorSensitiveField.GetPromoteMonitorFeatureNotificationId()
    end;


    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure CreateHiddenTablesNotificationHandler(var Notification: Notification): Boolean
    begin
        IsHiddenTableNotificationShown := Notification.Id = MonitorSensitiveField.GetChangeLogHiddenTablesNotificationId()
    end;

    var
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        Assert: Codeunit "Library Assert";
        MonitorSensitiveField: Codeunit "Monitor Sensitive Field";
        MonitorFieldTestHelper: Codeunit "Monitor Field Test Helper";
        IsHiddenTableNotificationShown, IsPromotionNotificationShown : boolean;
        EmailAccountMissingErr: label 'You must specify the email account to send notification email from when field values change. Specify the account in the Notification Email Account field. If no accounts are available, you can add one.';
        UserNotFoundErr: Label 'To start monitoring fields, you must specify the user who will receive notification emails when field values change.', Locked = true;
        D365MonitorFields: Label 'D365 Monitor Fields', Locked = true;
}
