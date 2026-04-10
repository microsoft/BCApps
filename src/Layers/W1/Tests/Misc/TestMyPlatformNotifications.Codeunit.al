codeunit 139034 "Test My Platform Notifications"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [My Platform Notifications] [UT] using work date notification as test notification
    end;

    var
        Assert: Codeunit Assert;
        SystemActionTriggers: Codeunit "System Action Triggers";
        WorkDateNotificationIdTxt: Label '53C1D678-1994-4981-97CE-D12D9EB887B0', Locked = true;

    [Test]
    [Scope('OnPrem')]
    procedure NotificationIsAddedToMyNotificationsOnOpeningMyNotificationsPage()
    var
        MyNotifications: Record "My Notifications";
        MyNotificationsTestPage: TestPage "My Notifications";
    begin
        // [SCENARIO] When My Notifications page is opened, the notification is initialized/added
        // if it doesn't exist
        // [GIVEN] No notification
        MyNotifications.DeleteAll();
        VerifyNotificationDoesNotExist();

        // [WHEN] Opened page "My Notifications"
        MyNotificationsTestPage.OpenView();

        // [THEN] The notification is initialized
        VerifyNotificationExists();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetNotificationStatusReturnsTrueForEnabledNotification()
    var
        MyNotifications: Record "My Notifications";
        Enabled: Boolean;
    begin
        // [SCENARIO] When GetNotificationStatus business event in System Action Triggers is raised
        // for an enabled notification, the enabled status is returned
        // [GIVEN] Enabled notification
        MyNotifications.DeleteAll();
        MyNotifications.InsertDefault(WorkDateNotificationIdTxt, '', '', true);
        VerifyNotificationExists();
        VerifyNotificationIsEnabled();

        // [WHEN] Raised GetNotificationStatus Event
        SystemActionTriggers.GetNotificationStatus(WorkDateNotificationIdTxt, Enabled);

        // [THEN] The notification is enabled
        Assert.IsTrue(Enabled, 'Notification status must be true for enabled notification');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetNotificationStatusReturnsFalseForDisabledNotification()
    var
        MyNotifications: Record "My Notifications";
        Enabled: Boolean;
    begin
        // [SCENARIO] When GetNotificationStatus business event in System Action Triggers is raised
        // for a disabled notification, the disabled status is returned
        // [GIVEN] Disabled notification
        MyNotifications.DeleteAll();
        MyNotifications.InsertDefault(WorkDateNotificationIdTxt, '', '', false);
        VerifyNotificationExists();
        VerifyNotificationIsDisabled();

        // [WHEN] Raised GetNotificationStatus Event
        SystemActionTriggers.GetNotificationStatus(WorkDateNotificationIdTxt, Enabled);

        // [THEN] The notification is disabled
        Assert.IsFalse(Enabled, 'Notification status must be false for disabled notification');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetNotificationStatusReturnsFalseForNotificationNotPreviouslySetup()
    var
        MyNotifications: Record "My Notifications";
        Enabled: Boolean;
    begin
        // [SCENARIO] When GetNotificationStatus business event in System Action Triggers is raised
        // for a notification that is not set up, the notification is set up/initialized with a disabled status and the disabled status is returned
        // [GIVEN] No notification
        MyNotifications.DeleteAll();
        VerifyNotificationDoesNotExist();

        // [WHEN] Raised GetNotificationStatus Event
        SystemActionTriggers.GetNotificationStatus(WorkDateNotificationIdTxt, Enabled);

        // [THEN] The notification is initialized/set up and status is disabled
        VerifyNotificationExists();
        VerifyNotificationIsDisabled();
        Assert.IsFalse(Enabled, 'Notification status must be false for disabled notification');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetNotificationStatusTurnsOffNotificationForEnabledNotification()
    var
        MyNotifications: Record "My Notifications";
    begin
        // [SCENARIO] When SetNotificationStatus business event in System Action Triggers is raised
        // for an enabled notification, the notification is turned off
        // [GIVEN] Enabled notification
        MyNotifications.DeleteAll();
        MyNotifications.InsertDefault(WorkDateNotificationIdTxt, '', '', true);
        VerifyNotificationExists();
        VerifyNotificationIsEnabled();

        // [WHEN] Raised SetNotificationStatus Event with status disabled
        SystemActionTriggers.SetNotificationStatus(WorkDateNotificationIdTxt, false);

        // [THEN] The notification is turned off
        VerifyNotificationIsDisabled();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetNotificationStatusTurnsOnNotificationForDisabledNotification()
    var
        MyNotifications: Record "My Notifications";
    begin
        // [SCENARIO] When SetNotificationStatus business event in System Action Triggers is raised
        // for a disabled notification, the notification is turned on
        // [GIVEN] Disabled notification
        MyNotifications.DeleteAll();
        MyNotifications.InsertDefault(WorkDateNotificationIdTxt, '', '', false);
        VerifyNotificationExists();
        VerifyNotificationIsDisabled();

        // [WHEN] Raised SetNotificationStatus Event with status enabled
        SystemActionTriggers.SetNotificationStatus(WorkDateNotificationIdTxt, true);

        // [THEN] The notification is turned on
        VerifyNotificationIsEnabled();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetNotificationStatusInitializesNotSetupNotificationWithSpecifiedStatus()
    var
        MyNotifications: Record "My Notifications";
    begin
        // [SCENARIO] When SetNotificationStatus business event in System Action Triggers is raised
        // for a notification that is not set up, the notification is set up/initialized with the specified status
        // [GIVEN] No notification
        MyNotifications.DeleteAll();
        VerifyNotificationDoesNotExist();

        // [WHEN] Raised SetNotificationStatus Event with status disabled
        SystemActionTriggers.SetNotificationStatus(WorkDateNotificationIdTxt, false);

        // [THEN] The notification is initialized/set up and status is disabled
        VerifyNotificationExists();
        VerifyNotificationIsDisabled();
    end;

    [Normal]
    local procedure VerifyNotificationExists()
    var
        MyNotifications: Record "My Notifications";
    begin
        Assert.IsTrue(MyNotifications.Get(UserId, WorkDateNotificationIdTxt), 'Notification should be present in My Notifications');
    end;

    [Normal]
    local procedure VerifyNotificationDoesNotExist()
    var
        MyNotifications: Record "My Notifications";
    begin
        Assert.IsFalse(MyNotifications.Get(UserId, WorkDateNotificationIdTxt), 'Notification should not be present in My Notifications');
    end;

    [Normal]
    local procedure VerifyNotificationIsEnabled()
    var
        MyNotifications: Record "My Notifications";
    begin
        Assert.IsTrue(MyNotifications.IsEnabled(WorkDateNotificationIdTxt), 'Notification should be enabled');
    end;

    [Normal]
    local procedure VerifyNotificationIsDisabled()
    var
        MyNotifications: Record "My Notifications";
    begin
        Assert.IsFalse(MyNotifications.IsEnabled(WorkDateNotificationIdTxt), 'Notification should be disabled');
    end;
}

