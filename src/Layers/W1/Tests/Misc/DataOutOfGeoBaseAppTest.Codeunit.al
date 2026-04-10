codeunit 135154 "Data Out Of Geo. BaseApp Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        Assert: Codeunit Assert;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        DataOutOfGeoApp: Codeunit "Data Out Of Geo. App";
        GeoNotificationsExistingAppsMsg: Label 'Your Dynamics 365 Business Central environment has apps installed that may transfer data to other geographies than the current geography of your Dynamics 365 Business Central environment. This is to ensure proper functionality of the apps.';
        GeoNotificationExistingAppsIdTxt: Label 'c414a6bd-a8f2-4182-9059-0c4e88238046';
        RandAppIdTxt: Label 'f0d20973-77c8-44ef-a99a-dd15c40767c4';
        LearnMoreUrlTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2153389';


    [Test]
    [Scope('OnPrem')]
    procedure NoNotificationWhenOpeningRoleCenterWithNoAppsOnPrem()
    var
        BusinessManagerRolecenter: TestPage "Business Manager Role Center";
    begin
        LibraryVariableStorage.Clear();

        // [GIVEN] That the environment is onprem.
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);

        // [GIVEN] There are no data out of geo apps in the module
        // [WHEN] the rolecenter page is opened
        BusinessManagerRolecenter.OpenView();

        // [THEN] Notifications are not shown.
        AssertNotificationFound(false);

        BusinessManagerRolecenter.Close();
    end;


    [Test]
    [Scope('OnPrem')]
    procedure NoNotificationWhenOpeningRoleCenterWithRandomAppInsertedOnPrem()
    var
        BusinessManagerRolecenter: TestPage "Business Manager Role Center";
    begin
        LibraryVariableStorage.Clear();

        // [GIVEN] That the environment is onprem.
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);

        // [GIVEN] There are is a random app in the module that is not currently installed
        DataOutOfGeoApp.Add(RandAppIdTxt);

        // [WHEN] the rolecenter page is opened
        BusinessManagerRolecenter.OpenView();

        // [THEN] Notifications are not shown.
        AssertNotificationFound(false);

        DataOutOfGeoApp.Remove(RandAppIdTxt);
        BusinessManagerRolecenter.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoNotificationWhenOpeningRoleCenterWithInstalledAppOnPrem()
    var
        BusinessManagerRolecenter: TestPage "Business Manager Role Center";
        ModuleInfo: ModuleInfo;
    begin
        LibraryVariableStorage.Clear();

        // [GIVEN] That the environment is onprem.
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);

        // [GIVEN] The currently installed app is in the module
        NavApp.GetCurrentModuleInfo(ModuleInfo);
        DataOutOfGeoApp.Add(ModuleInfo.Id);

        // [WHEN] the rolecenter page is opened
        BusinessManagerRolecenter.OpenView();

        // [THEN] Notifications are not shown.
        AssertNotificationFound(false);

        DataOutOfGeoApp.Remove(ModuleInfo.Id);
        BusinessManagerRolecenter.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoNotificationWhenOpeningRoleCenterWithNoAppsSaaS()
    var
        BusinessManagerRolecenter: TestPage "Business Manager Role Center";
    begin
        LibraryVariableStorage.Clear();

        // [GIVEN] That the environment is SaaS and not Demo Company
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        SetCompanyToDemo(false);

        // [GIVEN] There are no data out of geo apps in the module
        // [WHEN] the rolecenter page is opened
        BusinessManagerRolecenter.OpenView();

        // [THEN] Notifications are not shown.
        AssertNotificationFound(false);

        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
        SetCompanyToDemo(true);
        BusinessManagerRolecenter.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoNotificationWhenOpeningRoleCenterWithRandomAppInsertedSaaS()
    var
        BusinessManagerRolecenter: TestPage "Business Manager Role Center";
    begin
        LibraryVariableStorage.Clear();

        // [GIVEN] That the environment is SaaS and not Demo Company
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        SetCompanyToDemo(false);

        // [GIVEN] There are is a random app in the module that is not currently installed
        DataOutOfGeoApp.Add(RandAppIdTxt);

        // [WHEN] the rolecenter page is opened
        BusinessManagerRolecenter.OpenView();

        // [THEN] Notifications are not shown.
        AssertNotificationFound(false);

        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
        SetCompanyToDemo(true);
        DataOutOfGeoApp.Remove(RandAppIdTxt);
        BusinessManagerRolecenter.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('NotificationHandler')]
    procedure NotificationWhenOpeningRoleCenterWithInstalledAppInsertedSaaS()
    var
        BusinessManagerRolecenter: TestPage "Business Manager Role Center";
        ModuleInfo: ModuleInfo;
    begin
        LibraryVariableStorage.Clear();

        // [GIVEN] That the environment is SaaS and not Demo Company
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        SetCompanyToDemo(false);

        // [GIVEN] The currently installed app is in the module
        NavApp.GetCurrentModuleInfo(ModuleInfo);
        DataOutOfGeoApp.Add(ModuleInfo.Id);

        // [WHEN] the rolecenter page is opened
        BusinessManagerRolecenter.OpenView();

        // [THEN] Notifications are shown.
        AssertNotificationFound(true);

        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
        SetCompanyToDemo(true);
        BusinessManagerRolecenter.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('LinkHandler')]
    procedure NotificationLearnMoreWillOpenTheCorrectHyperlink()
    var
        DataGeoNotification: Codeunit "Data Geo. Notification";
        Notification: Notification;
    begin
        LibraryVariableStorage.Clear();
        Notification.Id(GeoNotificationExistingAppsIdTxt);

        // [GIVEN] That the environment is SaaS and not Demo Company
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        SetCompanyToDemo(false);

        // [WHEN] the learn more notification button is clicked
        DataGeoNotification.LearnMoreNotification(Notification);

        // [THEN] The correct URL will be opened
        Assert.AreEqual(LearnMoreUrlTxt, LibraryVariableStorage.DequeueText(), 'Wrong URL Opened');

        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
        SetCompanyToDemo(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotificationDontShowAgainTest()
    var
        DataGeoNotification: Codeunit "Data Geo. Notification";
        MyNotifications: Record "My Notifications";
        BusinessManagerRolecenter: TestPage "Business Manager Role Center";
        Notification: Notification;
        ModuleInfo: ModuleInfo;
    begin
        LibraryVariableStorage.Clear();
        Notification.Id(GeoNotificationExistingAppsIdTxt);

        // [GIVEN] That the environment is SaaS and not Demo Company
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        SetCompanyToDemo(false);

        // [WHEN] the don't show again notification button is clicked
        DataGeoNotification.DisableNotification(Notification);

        // [THEN] Notifications is disabled
        Assert.IsFalse(MyNotifications.IsEnabled(GeoNotificationExistingAppsIdTxt), 'The notification was not disabled after clicking don''t show again');

        // [GIVEN] The currently installed app is in the module
        NavApp.GetCurrentModuleInfo(ModuleInfo);
        DataOutOfGeoApp.Add(ModuleInfo.Id);

        // [WHEN] the rolecenter page is opened
        BusinessManagerRolecenter.OpenView();

        // [THEN] notification is not shown
        AssertNotificationFound(false);

        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
        SetCompanyToDemo(true);
        BusinessManagerRolecenter.Close();
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure NotificationHandler(var Notification: Notification): Boolean
    begin
        LibraryVariableStorage.Enqueue(Notification.Message);
    end;

    [HyperlinkHandler]
    [Scope('OnPrem')]
    procedure LinkHandler(Message: Text)
    begin
        LibraryVariableStorage.Enqueue(Message);
    end;

    local procedure SetCompanyToDemo(SetToDemo: Boolean)
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation."Demo Company" := SetToDemo;
        CompanyInformation.Modify();
    end;

    local procedure AssertNotificationFound(Expected: Boolean)
    var
        i, Length : Integer;
        Found: Boolean;
        NotificationText: Text;
    begin
        Length := LibraryVariableStorage.Length();
        for i := 1 to Length do begin
            NotificationText := LibraryVariableStorage.DequeueText();
            if GeoNotificationsExistingAppsMsg = NotificationText then
                found := true;
        end;

        LibraryVariableStorage.Clear();
        if Expected then
            Assert.IsTrue(found, 'Data out of geo notification was not triggered.')
        else
            Assert.IsFalse(found, 'Data out of geo notification was triggered.');
    end;

}