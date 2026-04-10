codeunit 134297 "Http Web Req. Mgt. Tests"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;

    trigger OnRun()
    begin
        // [FEATURE] [Http Web Request]
    end;

    var
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        Assert: Codeunit Assert;
        HttpWebReqMgtTests: Codeunit "Http Web Req. Mgt. Tests";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        Initialized: Boolean;
        UrlTok: Label 'http://127.0.0.1/', Locked = true;
        RewritenUrlTok: Label 'http://127.0.0.2/', Locked = true;

    [Test]
    [Scope('OnPrem')]
    procedure TestRewriteURLOnPrem()
    var
        HttpWebRequestMgt: Codeunit "Http Web Request Mgt.";
    begin
        // [GIVEN] Everything set up for new request on prem.
        Initialize();
        LibraryLowerPermissions.SetO365Basic();

        // [WHEN] We initialize Http Web Request Management with a new Url.
        HttpWebRequestMgt.Initialize(UrlTok);

        // [THEN] Url is changed to a new value.
        Assert.AreEqual(RewritenUrlTok, HttpWebRequestMgt.GetUrl(), 'Url should be changed if rewriten.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRewriteURLOnSaaS()
    var
        HttpWebRequestMgt: Codeunit "Http Web Request Mgt.";
    begin
        // [GIVEN] Everything set up for new request in SaaS.
        Initialize();
        LibraryLowerPermissions.SetO365Basic();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        // [WHEN] We initialize Http Web Request Management with a new Url.
        HttpWebRequestMgt.Initialize(UrlTok);

        // [THEN] Url remains identical as it was.
        Assert.AreEqual(UrlTok, HttpWebRequestMgt.GetUrl(), 'Url can not be rewritten in SaaS.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestNoRewriteSubscribers()
    var
        HttpWebRequestMgt: Codeunit "Http Web Request Mgt.";
    begin
        // [GIVEN] Everything set up for new request, there are not rewrite subscribers.
        Initialize();
        LibraryLowerPermissions.SetO365Basic();
        Initialized := false;
        UnbindSubscription(HttpWebReqMgtTests);

        // [WHEN] We initialize Http Web Request Management with a new Url.
        HttpWebRequestMgt.Initialize(UrlTok);

        // [THEN] Url should remain identical.
        Assert.AreEqual(UrlTok, HttpWebRequestMgt.GetUrl(), 'Url cannot change if there are not subscribers.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetBasicAuth()
    var
        HttpWebRequestMgt: Codeunit "Http Web Request Mgt.";
        DummyPassword: Text;
    begin
        // [GIVEN] Everything set up for new request on prem.
        Initialize();
        LibraryLowerPermissions.SetO365Basic();

        // [WHEN] We initialize Http Web Request Management with a new Url and set basic authentication
        HttpWebRequestMgt.Initialize(UrlTok);
        DummyPassword := 'SomePassword';
        HttpWebRequestMgt.AddBasicAuthentication('SomeUser', DummyPassword);

        // [THEN]
        // No validation - other than the function passes
    end;

    [Scope('OnPrem')]
    procedure Initialize()
    begin
        if Initialized then
            exit;

        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
        BindSubscription(HttpWebReqMgtTests);
        Initialized := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Http Web Request Mgt.", 'OnOverrideUrl', '', false, false)]
    [Scope('OnPrem')]
    procedure ChangeUrlOnOverrideUrl(var Url: Text)
    begin
        Url := RewritenUrlTok;
    end;
}

