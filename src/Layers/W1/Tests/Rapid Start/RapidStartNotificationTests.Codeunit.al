codeunit 139171 "RapidStart Notification Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        EnviromentInfoLibrary: Codeunit "Environment Info Test Library";

    trigger OnRun()
    begin
        // [FEATURE] [Rapid Start]
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler,PageHandler')]
    procedure NotificationIsShown()
    begin
        // [GIVEN] In SaaS
        // [GIVEN] Company Created 4 months ago
        Initialize();

        // [WHEN] Configuration Packages page is opened
        Page.Run(Page::"Config. Packages");

        // [THEN] Notification is shown, verify in SendNotificationHandler
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandlerThrowError,PageHandler')]
    procedure NotificationIsNotShownOnPrem()
    var
        Notification: Notification;
    begin
        // [GIVEN] Company Created 4 months ago
        Initialize();
        // [GIVEN] Not SaaS
        EnviromentInfoLibrary.SetTestabilitySoftwareAsAService(false);

        // [WHEN] Configuration Packages page is opened
        // [THEN] NO notification is shown/ No error is thrown
        Page.Run(Page::"Config. Packages");

        // Needed to make sure the handler is called even when no Notification is sent
        Notification.Message('Dummy');
        asserterror Notification.Send();
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandlerThrowError,PageHandler')]
    procedure NotificationIsNotShownForNewComapnies()
    var
        CompanyInformation: Record "Company Information";
        Notification: Notification;
    begin
        // [GIVEN] In SaaS
        Initialize();

        // [GIVEN] Company is created just now
        CompanyInformation.Get();
        CompanyInformation."Created DateTime" := CurrentDateTime();
        CompanyInformation.Modify();

        // [WHEN] Configuration Packages page is opened
        // [THEN] NO notification is shown/ No error is thrown
        Page.Run(Page::"Config. Packages");

        // Needed to make sure the handler is called even when no Notification is sent
        Notification.Message('Dummy');
        asserterror Notification.Send();
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandlerThrowError,PageHandler')]
    procedure NotificationIsNotShownWhenCreatedDatedIsNotSet()
    var
        CompanyInformation: Record "Company Information";
        Notification: Notification;
    begin
        // [GIVEN] In SaaS
        Initialize();

        // [GIVEN] Company info is not initialized, OnPrem only case, but just to be safe
        CompanyInformation.Get();
        CompanyInformation."Created DateTime" := 0DT;
        CompanyInformation.Modify();

        // [WHEN] Configuration Packages page is opened
        // [THEN] NO notification is shown/ No error is thrown
        Page.Run(Page::"Config. Packages");

        // Needed to make sure the handler is called even when no Notification is sent
        Notification.Message('Dummy');
        asserterror Notification.Send();
    end;

    [Test]
    [HandlerFunctions('PageHandler')]
    procedure NotificationIsNotShownWhenCompanyInfoIsMissing()
    var
        CompanyInformation: Record "Company Information";
    begin
        Initialize();

        CompanyInformation.DeleteAll();

        // [WHEN] Configuration Packages page is opened
        Page.Run(Page::"Config. Packages");
    end;

    [PageHandler]
    procedure PageHandler(var ConfigPackages: TestPage "Config. Packages")
    begin

    end;

    local procedure Initialize()
    var
        CompanyInformation: Record "Company Information";
    begin
        EnviromentInfoLibrary.SetTestabilitySoftwareAsAService(true);
        CompanyInformation.DeleteAll();

        CompanyInformation."Created DateTime" := CreateDateTime(CalcDate('<-4M>', Today()), Time());
        CompanyInformation.Insert();
    end;

    [SendNotificationHandler]
    procedure SendNotificationHandler(var Notification: Notification): Boolean
    begin
        Assert.ExpectedMessage('Use configuration packages to import data when setting up new companies', Notification.Message);
    end;

    [SendNotificationHandler]
    procedure SendNotificationHandlerThrowError(var Notification: Notification): Boolean
    begin
        Error('No notification was expected.')
    end;
}

