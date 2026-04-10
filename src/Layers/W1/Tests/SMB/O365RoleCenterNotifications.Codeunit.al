codeunit 138073 "O365 Role Center Notifications"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Role Center Notifications] [License State]
    end;

    var
        Assert: Codeunit Assert;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        RoleCenterNotificationMgt: Codeunit "Role Center Notification Mgt.";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        IsInitialized: Boolean;
        UnexpectedNotificationIdTxt: Label 'Unexpected Notification ID';
        UnexpectedNotificationMsgTxt: Label 'Unexpected Notification Message';
        UnexpectedNotificationErr: Label 'Unexpected Notification: %1';
        MillisecondsPerDay: BigInteger;

    local procedure Initialize()
    var
        UserPreference: Record "User Preference";
        RoleCenterNotifications: Record "Role Center Notifications";
    begin
        if RoleCenterNotifications.FindFirst() then
            RoleCenterNotifications.DeleteAll();

        if UserPreference.FindFirst() then
            UserPreference.DeleteAll();

        if IsInitialized then
            exit;

        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        IsInitialized := true;
        MillisecondsPerDay := 86400000;
    end;

    local procedure SimulateSecondLogon()
    var
        RoleCenterNotifications: Record "Role Center Notifications";
    begin
        if RoleCenterNotifications.IsFirstLogon() then begin
            RoleCenterNotifications.Get(UserSecurityId());
            RoleCenterNotifications."First Session ID" := -2;
            RoleCenterNotifications."Last Session ID" := -1;
            RoleCenterNotifications.Modify();
        end;
    end;

    local procedure EnableSandbox()
    begin
        SetSandboxValue(true);
    end;

    local procedure DisableSandbox()
    begin
        SetSandboxValue(false);
    end;

    local procedure SetSandboxValue(Enable: Boolean)
    var
        LibraryPermissions: Codeunit "Library - Permissions";
    begin
        LibraryPermissions.SetTestTenantEnvironmentType(Enable);
    end;

    local procedure SetLicenseState(State: Option; StartDate: DateTime)
    var
        TenantLicenseState: Record "Tenant License State";
    begin
        TenantLicenseState.SetRange(State, State);
        if TenantLicenseState.FindLast() and not (TenantLicenseState.State = TenantLicenseState.State::Trial) then
            exit;
        TenantLicenseState.Init();
        TenantLicenseState."Start Date" := StartDate;
        TenantLicenseState.State := State;
        TenantLicenseState.Insert();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestTrialNoNotification()
    var
        TenantLicenseState: Record "Tenant License State";
    begin
        Initialize();
        SetLicenseState(TenantLicenseState.State::Trial, GetUtcNow());
        RoleCenterNotificationMgt.ShowTrialNotification();
    end;

    [Test]
    [HandlerFunctions('SendTrialNotificationHandler,HyperlinkHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestTrialNotification()
    var
        TenantLicenseState: Record "Tenant License State";
    begin
        Initialize();
        SetLicenseState(TenantLicenseState.State::Trial, GetUtcNow() - 16 * MillisecondsPerDay);
        RoleCenterNotificationMgt.ShowTrialNotification();
    end;

    [Test]
    [HandlerFunctions('SendNoNotificationHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestTrialNotificationPhone()
    var
        TenantLicenseState: Record "Tenant License State";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
    begin
        Initialize();
        SetLicenseState(TenantLicenseState.State::Trial, GetUtcNow() - 16 * MillisecondsPerDay);
        BindSubscription(TestClientTypeSubscriber);
        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Phone);
        // [WHEN]
        RoleCenterNotificationMgt.ShowTrialNotification();

        // [THEN] No notification is shown
    end;

    [Test]
    [HandlerFunctions('SendTrialSuspendedNotificationHandler,HyperlinkHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestTrialSuspendedNotification()
    var
        TenantLicenseState: Record "Tenant License State";
    begin
        Initialize();
        SetLicenseState(TenantLicenseState.State::Trial, GetUtcNow());
        SetLicenseState(TenantLicenseState.State::Suspended, GetUtcNow() + MillisecondsPerDay);
        RoleCenterNotificationMgt.ShowTrialSuspendedNotification();
    end;

    [Test]
    [HandlerFunctions('SendNoNotificationHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestTrialSuspendedNotificationPhone()
    var
        TenantLicenseState: Record "Tenant License State";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
    begin
        Initialize();
        SetLicenseState(TenantLicenseState.State::Trial, GetUtcNow());
        SetLicenseState(TenantLicenseState.State::Suspended, GetUtcNow() + MillisecondsPerDay);
        BindSubscription(TestClientTypeSubscriber);
        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Phone);
        // [WHEN]
        RoleCenterNotificationMgt.ShowTrialSuspendedNotification();

        // [THEN] No notification is shown
    end;

    [Test]
    [HandlerFunctions('SendTrialExtendedNotificationHandler,HyperlinkHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestTrialExtendedNotification()
    var
        TenantLicenseState: Record "Tenant License State";
    begin
        Initialize();
        SetLicenseState(TenantLicenseState.State::Trial, GetUtcNow() - 17 * MillisecondsPerDay);
        SetLicenseState(TenantLicenseState.State::Trial, GetUtcNow() - 16 * MillisecondsPerDay);
        RoleCenterNotificationMgt.ShowTrialExtendedNotification();
    end;

    [Test]
    [HandlerFunctions('SendNoNotificationHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestTrialExtendedNotificationPhone()
    var
        TenantLicenseState: Record "Tenant License State";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
    begin
        Initialize();
        SetLicenseState(TenantLicenseState.State::Trial, GetUtcNow() - 17 * MillisecondsPerDay);
        SetLicenseState(TenantLicenseState.State::Trial, GetUtcNow() - 16 * MillisecondsPerDay);
        BindSubscription(TestClientTypeSubscriber);
        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Phone);
        // [WHEN]
        RoleCenterNotificationMgt.ShowTrialExtendedNotification();

        // [THEN] No notification is shown
    end;

    [Test]
    [HandlerFunctions('SendTrialExtendedSuspendedNotificationHandler,HyperlinkHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestTrialExtendedSuspendedNotification()
    var
        TenantLicenseState: Record "Tenant License State";
    begin
        Initialize();
        SetLicenseState(TenantLicenseState.State::Trial, GetUtcNow() - 3 * MillisecondsPerDay);
        SetLicenseState(TenantLicenseState.State::Trial, GetUtcNow() - 2 * MillisecondsPerDay);
        SetLicenseState(TenantLicenseState.State::Trial, GetUtcNow() - 1 * MillisecondsPerDay);
        SetLicenseState(TenantLicenseState.State::Suspended, GetUtcNow());
        RoleCenterNotificationMgt.ShowTrialExtendedSuspendedNotification();
    end;

    [Test]
    [HandlerFunctions('SendNoNotificationHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestTrialExtendedSuspendedNotificationPhone()
    var
        TenantLicenseState: Record "Tenant License State";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
    begin
        Initialize();
        SetLicenseState(TenantLicenseState.State::Trial, GetUtcNow() - 3 * MillisecondsPerDay);
        SetLicenseState(TenantLicenseState.State::Trial, GetUtcNow() - 2 * MillisecondsPerDay);
        SetLicenseState(TenantLicenseState.State::Trial, GetUtcNow() - 1 * MillisecondsPerDay);
        SetLicenseState(TenantLicenseState.State::Suspended, GetUtcNow());
        BindSubscription(TestClientTypeSubscriber);
        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Phone);
        // [WHEN]
        RoleCenterNotificationMgt.ShowTrialExtendedSuspendedNotification();

        // [THEN] No notification is shown
    end;

    [Test]
    [HandlerFunctions('SendPaidWarningNotificationHandler,HyperlinkHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestWarningNotification()
    var
        TenantLicenseState: Record "Tenant License State";
    begin
        Initialize();
        SimulateSecondLogon();
        SetLicenseState(TenantLicenseState.State::Paid, GetUtcNow() - 1 * MillisecondsPerDay);
        SetLicenseState(TenantLicenseState.State::Warning, GetUtcNow());
        RoleCenterNotificationMgt.ShowPaidWarningNotification();
    end;

    [Test]
    [HandlerFunctions('SendPaidWarningNotificationHandler,HyperlinkHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestPaidWarningNotification()
    var
        TenantLicenseState: Record "Tenant License State";
    begin
        Initialize();
        SimulateSecondLogon();
        SetLicenseState(TenantLicenseState.State::Paid, GetUtcNow());
        SetLicenseState(TenantLicenseState.State::Warning, GetUtcNow() + MillisecondsPerDay);
        RoleCenterNotificationMgt.ShowPaidWarningNotification();
    end;

    [Test]
    [HandlerFunctions('SendPaidSuspendedNotificationHandler,HyperlinkHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestSuspendedNotification()
    var
        TenantLicenseState: Record "Tenant License State";
    begin
        Initialize();
        SimulateSecondLogon();
        SetLicenseState(TenantLicenseState.State::Paid, GetUtcNow() - 1 * MillisecondsPerDay);
        SetLicenseState(TenantLicenseState.State::Suspended, GetUtcNow());
        RoleCenterNotificationMgt.ShowPaidSuspendedNotification();
    end;

    [Test]
    [HandlerFunctions('SendPaidSuspendedNotificationHandler,HyperlinkHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestPaidSuspendedNotification()
    var
        TenantLicenseState: Record "Tenant License State";
    begin
        Initialize();
        SimulateSecondLogon();
        SetLicenseState(TenantLicenseState.State::Paid, GetUtcNow());
        SetLicenseState(TenantLicenseState.State::Suspended, GetUtcNow() + MillisecondsPerDay);
        RoleCenterNotificationMgt.ShowPaidSuspendedNotification();
    end;

    [Test]
    [HandlerFunctions('SendSandboxNotificationHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestSandboxNotification()
    var
        TenantLicenseState: Record "Tenant License State";
    begin
        // [SCENARIO 218238] User is getting notification when logs into a sandbox environment
        Initialize();
        EnableSandbox();
        SetLicenseState(TenantLicenseState.State::Evaluation, GetUtcNow());
        RoleCenterNotificationMgt.ShowSandboxNotification();
        DisableSandbox();
    end;

    [Test]
    [HandlerFunctions('DontShowSandboxNotificationHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestSandboxNotificationDontShowAgain()
    var
        TenantLicenseState: Record "Tenant License State";
        MyNotifications: Record "My Notifications";
    begin
        // [SCENARIO 218896] User can disable sandbox notification by clicking on 'Don't show this again.'
        Initialize();
        EnableSandbox();
        SetLicenseState(TenantLicenseState.State::Evaluation, GetUtcNow());
        // [GIVEN] Open role center once and see the notification
        LibraryVariableStorage.Enqueue(0); // to count calls of DontShowSandboxNotificationHandler
        RoleCenterNotificationMgt.ShowSandboxNotification();
        // [WHEN] Click on "Don't show this again." on the notification
        Assert.AreEqual(1, LibraryVariableStorage.DequeueInteger(), 'Notification should be called once.');
        // [THEN] Sandbox notification is disabled.
        Assert.IsFalse(MyNotifications.IsEnabled(RoleCenterNotificationMgt.GetSandboxNotificationId()), 'Notification should be disabled');

        // [WHEN] Open role center again
        LibraryVariableStorage.Enqueue(0); // to count calls of DontShowSandboxNotificationHandler
        RoleCenterNotificationMgt.ShowSandboxNotification();
        // [THEN] see no notification
        Assert.AreEqual(0, LibraryVariableStorage.DequeueInteger(), 'Notification should not be called.');

        DisableSandbox();
    end;

    [SendNotificationHandler(true)]
    [Scope('OnPrem')]
    procedure SendNoNotificationHandler(var Notification: Notification): Boolean
    begin
        Error(UnexpectedNotificationErr, Notification.Message);
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SendTrialNotificationHandler(var Notification: Notification): Boolean
    var
        NotificationId: Guid;
        RemainingDays: Integer;
    begin
        Evaluate(NotificationId, Format(Notification.Id));
        RemainingDays := RoleCenterNotificationMgt.GetLicenseRemainingDays();
        Assert.AreEqual(
          Format(RoleCenterNotificationMgt.GetTrialNotificationId()), Format(NotificationId), UnexpectedNotificationIdTxt);
        Assert.AreEqual(
          StrSubstNo(RoleCenterNotificationMgt.TrialNotificationMessage(), RemainingDays), Notification.Message,
          UnexpectedNotificationMsgTxt);
        RoleCenterNotificationMgt.TrialNotificationAction(Notification);
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SendTrialSuspendedNotificationHandler(var Notification: Notification): Boolean
    var
        NotificationId: Guid;
    begin
        Evaluate(NotificationId, Format(Notification.Id));
        Assert.AreEqual(
          Format(RoleCenterNotificationMgt.GetTrialSuspendedNotificationId()), Format(NotificationId), UnexpectedNotificationIdTxt);
        Assert.AreEqual(
          RoleCenterNotificationMgt.TrialSuspendedNotificationMessage(), Notification.Message,
          UnexpectedNotificationMsgTxt);
        RoleCenterNotificationMgt.TrialSuspendedNotificationAction(Notification);
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SendTrialExtendedNotificationHandler(var Notification: Notification): Boolean
    var
        NotificationId: Guid;
        RemainingDays: Integer;
    begin
        Evaluate(NotificationId, Format(Notification.Id));
        RemainingDays := RoleCenterNotificationMgt.GetLicenseRemainingDays();
        Assert.AreEqual(
          Format(RoleCenterNotificationMgt.GetTrialExtendedNotificationId()), Format(NotificationId), UnexpectedNotificationIdTxt);
        Assert.AreEqual(
          StrSubstNo(RoleCenterNotificationMgt.TrialExtendedNotificationMessage(), RemainingDays), Notification.Message,
          UnexpectedNotificationMsgTxt);
        RoleCenterNotificationMgt.TrialExtendedNotificationSubscribeAction(Notification);
        RoleCenterNotificationMgt.TrialExtendedNotificationPartnerAction(Notification);
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SendTrialExtendedSuspendedNotificationHandler(var Notification: Notification): Boolean
    var
        NotificationId: Guid;
    begin
        Evaluate(NotificationId, Format(Notification.Id));
        Assert.AreEqual(
          Format(RoleCenterNotificationMgt.GetTrialExtendedSuspendedNotificationId()), Format(NotificationId), UnexpectedNotificationIdTxt);
        Assert.AreEqual(
          RoleCenterNotificationMgt.TrialExtendedSuspendedNotificationMessage(), Notification.Message,
          UnexpectedNotificationMsgTxt);
        RoleCenterNotificationMgt.TrialExtendedNotificationSubscribeAction(Notification);
        RoleCenterNotificationMgt.TrialExtendedNotificationPartnerAction(Notification);
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SendPaidWarningNotificationHandler(var Notification: Notification): Boolean
    var
        NotificationId: Guid;
        RemainingDays: Integer;
    begin
        Evaluate(NotificationId, Format(Notification.Id));
        RemainingDays := RoleCenterNotificationMgt.GetLicenseRemainingDays();
        Assert.AreEqual(
          Format(RoleCenterNotificationMgt.GetPaidWarningNotificationId()), Format(NotificationId), UnexpectedNotificationIdTxt);
        Assert.AreEqual(
          StrSubstNo(RoleCenterNotificationMgt.PaidWarningNotificationMessage(), RemainingDays), Notification.Message,
          UnexpectedNotificationMsgTxt);
        RoleCenterNotificationMgt.PaidWarningNotificationAction(Notification);
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SendPaidSuspendedNotificationHandler(var Notification: Notification): Boolean
    var
        NotificationId: Guid;
        RemainingDays: Integer;
    begin
        Evaluate(NotificationId, Format(Notification.Id));
        RemainingDays := RoleCenterNotificationMgt.GetLicenseRemainingDays();
        Assert.AreEqual(
          Format(RoleCenterNotificationMgt.GetPaidSuspendedNotificationId()), Format(NotificationId), UnexpectedNotificationIdTxt);
        Assert.AreEqual(
          StrSubstNo(RoleCenterNotificationMgt.PaidSuspendedNotificationMessage(), RemainingDays), Notification.Message,
          UnexpectedNotificationMsgTxt);
        RoleCenterNotificationMgt.PaidSuspendedNotificationAction(Notification);
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SendSandboxNotificationHandler(var Notification: Notification): Boolean
    begin
        Assert.AreEqual(
          RoleCenterNotificationMgt.SandboxNotificationMessage(), Notification.Message, UnexpectedNotificationMsgTxt);
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure DontShowSandboxNotificationHandler(var Notification: Notification): Boolean
    var
        RoleCenterNotificationMgt: Codeunit "Role Center Notification Mgt.";
    begin
        LibraryVariableStorage.Enqueue(LibraryVariableStorage.DequeueInteger() + 1);
        Assert.AreEqual(
          RoleCenterNotificationMgt.SandboxNotificationMessage(), Notification.Message, UnexpectedNotificationMsgTxt);
        // Simulate click on "Don't show this again"
        RoleCenterNotificationMgt.DisableSandboxNotification(Notification);
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SendChangeToPremiumExpNotificationHandler(var Notification: Notification): Boolean
    begin
        Assert.AreEqual(
          RoleCenterNotificationMgt.ChangeToPremiumExpNotificationMessage(), Notification.Message, UnexpectedNotificationMsgTxt);
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure DontShowChangeToPremiumExpNotificationHandler(var Notification: Notification): Boolean
    var
        RoleCenterNotificationMgt: Codeunit "Role Center Notification Mgt.";
    begin
        LibraryVariableStorage.Enqueue(LibraryVariableStorage.DequeueInteger() + 1);
        Assert.AreEqual(
          RoleCenterNotificationMgt.ChangeToPremiumExpNotificationMessage(), Notification.Message, UnexpectedNotificationMsgTxt);
        // Simulate click on "Don't show this again"
        RoleCenterNotificationMgt.DisableChangeToPremiumExpNotification(Notification);
    end;

    [HyperlinkHandler]
    [Scope('OnPrem')]
    procedure HyperlinkHandler(Url: Text)
    begin
    end;

    local procedure GetUtcNow(): DateTime
    var
        DotNet_DateTimeOffset: Codeunit "DotNet_DateTimeOffset";
        Now: DateTime;
    begin
        Now := DotNet_DateTimeOffset.ConvertToUtcDateTime(CurrentDateTime);
        exit(Now);
    end;
}

