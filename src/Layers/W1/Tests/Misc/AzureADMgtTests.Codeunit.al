codeunit 139086 "Azure AD Mgt. Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Azure AD Management]
    end;

    var
        Assert: Codeunit Assert;
        LibraryAzureADAuthFlow: Codeunit "Library - Azure AD Auth Flow";
        AuthUrlSaasWithResourceTxt: Label 'https://login.microsoftonline.com/common/oauth2/authorize?response_type=code&client_id=11111111-1111-1111-1111-111111111111&resource=http%3a%2f%2fcontoso.com%2fa%2fvalid%2fresource&redirect_uri=', Locked = true;
        AuthUrlSaasNoResourceTxt: Label 'https://login.microsoftonline.com/common/oauth2/authorize?response_type=code&client_id=11111111-1111-1111-1111-111111111111&redirect_uri=', Locked = true;
        AuthUrlOnPremWithResourceTxt: Label 'https://login.microsoftonline.com/common/oauth2/authorize?response_type=code&client_id=22222222-2222-2222-2222-222222222222&resource=http%3a%2f%2fcontoso.com%2fa%2fvalid%2fresource&redirect_uri=', Locked = true;
        AuthUrlOnPremNoResourceTxt: Label 'https://login.microsoftonline.com/common/oauth2/authorize?response_type=code&client_id=22222222-2222-2222-2222-222222222222&redirect_uri=', Locked = true;
        AuthUrlFromUrlHelperTxt: Label 'https://login.microsoftonline.com/common/oauth2/authorize', Locked = true;
        ValidResourceUrlTxt: Label 'http://contoso.com/a/valid/resource', Locked = true;
        ValidResourceNameTxt: Label 'Azure Service', Locked = true;
        ValidGuestTenantTxt: Label 'fabrikam.contoso.biz', Locked = true;

    [Test]
    [Scope('OnPrem')]
    procedure GetUrlFromUrlHelperReturnsExpectedUrl()
    var
        UrlHelper: Codeunit "Url Helper";
    begin
        // [GIVEN] A SaaS environment.
        // [WHEN] Azure AD Mgt calls Url Helper to get the Azure AD Auth Endpoint.
        // [THEN] The return URL is the expected one (from the server settings).
        Assert.AreEqual(UrlHelper.GetAzureADAuthEndpoint(), AuthUrlFromUrlHelperTxt, 'The auth endpoint should match the expected value.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetAuthCodeUrlSaasWithResourceCreatesValidResourceUrl()
    var
        AzureAdMgt: Codeunit "Azure AD Mgt.";
        Result: Text;
        ExpectedAuthUrl: Text;
    begin
        // [SCENARIO] In a SaaS environment, user calls GetAuthCodeUrl with a non-empty resource name and gets a valid URL-specific auth code URL.

        // [GIVEN] SaaS environment with no token available and client ID available from server configuration.
        Initialize(false, false, false, true, true);
        ExpectedAuthUrl := AuthUrlSaasWithResourceTxt + GetExpectedRedirectUrl('OAuthLanding.htm');

        // [WHEN] The user invokes the GetAuthCodeUrl method with a resource.
        Result := AzureAdMgt.GetAuthCodeUrl(ValidResourceUrlTxt);

        // [THEN] The user recieves a validly formed and escaped URL to retrieve the auth code from.
        Assert.AreEqual(ExpectedAuthUrl, Result, 'The auth code URL should match the expected value.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetAuthCodeUrlSaasNoResourceCreatesValidGenericUrl()
    var
        AzureAdMgt: Codeunit "Azure AD Mgt.";
        Result: Text;
        ExpectedAuthUrl: Text;
    begin
        // [SCENARIO] In a SaaS environment, user calls GetAuthCodeUrl with an empty resource name and gets a valid generic auth code URL.

        // [GIVEN] SaaS environment with no token availabie and client ID available from server configuration.
        Initialize(false, false, false, true, true);
        ExpectedAuthUrl := AuthUrlSaasNoResourceTxt + GetExpectedRedirectUrl('OAuthLanding.htm');

        // [WHEN] The user invokes the GetAuthCodeUrl method with no resource specified.
        Result := AzureAdMgt.GetAuthCodeUrl('');

        // [THEN] The user recieves a validly formed and escaped URL to retrieve the auth code from.
        Assert.AreEqual(ExpectedAuthUrl, Result, 'The auth code URL should match the expected value.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetAuthCodeUrlOnPremWithResourceCreatesValidResourceUrl()
    var
        AzureAdMgt: Codeunit "Azure AD Mgt.";
        Result: Text;
        ExpectedAuthUrl: Text;
    begin
        // [SCENARIO] In an On-Prem/PaaS environment, user calls GetAuthCodeUrl with a resource name and gets a valid URL-specific auth code URL.

        // [GIVEN] On-Prem environment with no token availabie and client ID available.
        Initialize(false, false, false, true, false);
        ExpectedAuthUrl := AuthUrlOnPremWithResourceTxt + GetExpectedRedirectUrl('OAuthLanding.htm');

        // [WHEN] The user invokes the GetAuthCodeUrl method with a resource.
        Result := AzureAdMgt.GetAuthCodeUrl(ValidResourceUrlTxt);

        // [THEN] The user recieves a validly formed and escaped URL to retrieve the auth code from.
        Assert.AreEqual(ExpectedAuthUrl, Result, 'The auth code URL should match the expected value.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetAuthCodeUrlOnPremNoResourceCreatesValidGenericUrl()
    var
        AzureAdMgt: Codeunit "Azure AD Mgt.";
        Result: Text;
        ExpectedAuthUrl: Text;
    begin
        // [SCENARIO] In an On-Prem/PaaS environment, user calls GetAuthCodeUrl with an empty resource name and gets a valid generic auth code URL.

        // [GIVEN] On-Prem environment with no token availabie and client ID available.
        Initialize(false, false, false, true, false);
        ExpectedAuthUrl := AuthUrlOnPremNoResourceTxt + GetExpectedRedirectUrl('OAuthLanding.htm');

        // [WHEN] The user invokes the GetAuthCodeUrl method with no resource specified.
        Result := AzureAdMgt.GetAuthCodeUrl('');

        // [THEN] The user recieves a validly formed and escaped URL to retrieve the auth code from.
        Assert.AreEqual(ExpectedAuthUrl, Result, 'The auth code URL should match the expected value.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetAccessTokenSaasNoDialogNoTokenAvailableIsBlank()
    var
        AzureAdMgt: Codeunit "Azure AD Mgt.";
    begin
        // [SCENARIO] In a SaaS environment, user calls GetAccessToken and gets an error because there is not one available in the cache.

        // [GIVEN] SaaS environment with no token available at all.
        Initialize(false, false, false, true, true);

        // [WHEN] The user invokes GetAccessToken method.
        // [THEN] The return value is empty.
        Assert.IsTrue(AzureAdMgt.GetAccessTokenAsSecretText(ValidResourceUrlTxt, ValidResourceNameTxt, false).IsEmpty(), 'Expected the access token to be empty.')
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetAccessTokenSaasNoDialogGetsFromCache()
    var
        AzureAdMgt: Codeunit "Azure AD Mgt.";
        Result: SecretText;
    begin
        // [SCENARIO] In a SaaS environment, user calls GetAccessToken with no dialog and recieves the cached access token.

        // [GIVEN] SaaS environment with only cached token available.
        Initialize(false, true, false, true, true);

        // [WHEN] The user invokes GetAccessToken method requesting no dialog.
        Result := AzureAdMgt.GetAccessTokenAsSecretText(ValidResourceUrlTxt, ValidResourceNameTxt, false);

        // [THEN] The user recieves the access token from the cache.
        AssertSecret('TokenFromCache', Result, 'The access token should be pulling from the SaaS cache.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetAccessTokenOnPremNoDialogNoTokenAvailableIsBlank()
    var
        AzureAdMgt: Codeunit "Azure AD Mgt.";
        Result: SecretText;
    begin
        // [SCENARIO] In an On-Prem environment, user calls GetAccessToken with no dialog and recieves a blank token because there is not one available in the cache.

        // [GIVEN] On-Prem environment with no token available at all.
        Initialize(false, false, false, true, false);

        // [WHEN] The user invokes GetAccessToken method requesting no dialog.
        Result := AzureAdMgt.GetAccessTokenAsSecretText(ValidResourceUrlTxt, ValidResourceNameTxt, false);

        // [THEN] The user recieves a blank access token.
        Assert.IsTrue(Result.IsEmpty(), 'The access token should be an empty string.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetAccessTokenOnPremNoDialogGetsFromCache()
    var
        AzureAdMgt: Codeunit "Azure AD Mgt.";
        Result: SecretText;
    begin
        // [SCENARIO] In an On-Prem environment, user calls GetAccessToken with no dialog and recieves the cached access token.

        // [GIVEN] On-Prem environment with only cached token available.
        Initialize(false, true, false, true, false);

        // [WHEN] The user invokes GetAccessToken method requesting no dialog.
        Result := AzureAdMgt.GetAccessTokenAsSecretText(ValidResourceUrlTxt, ValidResourceNameTxt, false);

        // [THEN] The user recieves the access token from the cache.
        AssertSecret('TokenFromCacheWithCredentials', Result, 'The access token should be pulling from the On-Prem cache.');
    end;

    [Test]
    [HandlerFunctions('AzureADAccessDialogHandler')]
    [Scope('OnPrem')]
    procedure GetAccessTokenOnPremWithDialogNoTokenAvailableOpensDialog()
    var
        AzureAdMgt: Codeunit "Azure AD Mgt.";
    begin
        // [SCENARIO] In an On-Prem environment, user calls GetAccessToken with dialog and NAV opens the Azure AD Access Dialog.

        // [GIVEN] On-Prem environment with no token available.
        Initialize(false, false, false, true, false);

        // [WHEN] The user invokes GetAccessToken method requesting no dialog.
        AzureAdMgt.GetAccessTokenAsSecretText(ValidResourceUrlTxt, ValidResourceNameTxt, true);

        // [THEN] The user recieves the access token from the cache.
        // Test will fail if attached modal handler is not invoked
    end;

    [Test]
    [HandlerFunctions('AzureADAppSetupWizardHandler')]
    [Scope('OnPrem')]
    procedure GetAccessTokenOnPremWithDialogNoClientIdAvailableOpensDialog()
    var
        AzureAdMgt: Codeunit "Azure AD Mgt.";
    begin
        // [SCENARIO] In an On-Prem environment, user calls GetAccessToken with dialog and NAV opens the Azure AD Access Dialog.

        // [GIVEN] On-Prem environment with no token available.
        Initialize(false, false, false, false, false);

        // [WHEN] The user invokes GetAccessToken method requesting no dialog.
        AzureAdMgt.GetAccessTokenAsSecretText(ValidResourceUrlTxt, ValidResourceNameTxt, true);

        // [THEN] The user recieves the access token from the cache.
        // Test will fail if attached modal handler is not invoked
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetGuestAccessTokenSaasGetsToken()
    var
        AzureAdMgt: Codeunit "Azure AD Mgt.";
        Result: Text;
    begin
        // [SCENARIO] In a SaaS environment, user calls GetGuestAccessToken, which returns an access token.

        // [GIVEN] SaaS environment with guest token available.
        Initialize(false, false, true, false, true);

        // [WHEN] The user invokes the GetGuestAccessToken method.
        Result := AzureAdMgt.GetGuestAccessToken(ValidResourceUrlTxt, ValidGuestTenantTxt);

        // [THEN] The user recieves a guest access token.
        Assert.AreEqual(Result, 'GuestTokenTxt', 'The access token should be retrieved successfully in a SaaS scenario.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetGuestAccessTokenOnPremIsBlank()
    var
        AzureAdMgt: Codeunit "Azure AD Mgt.";
        Result: Text;
    begin
        // [SCENARIO] In an On-Prem environment, user calls GetGuestAccessToken, which returns an blank token.

        // [GIVEN] SaaS environment with guest token available.
        Initialize(false, false, true, false, false);

        // [WHEN] The user invokes the GetGuestAccessToken method.
        Result := AzureAdMgt.GetGuestAccessToken(ValidResourceUrlTxt, ValidGuestTenantTxt);

        // [THEN] The user recieves a blank guest access token.
        Assert.AreEqual(Result, '', 'The access token should not be retrieved in a non-SaaS scenario.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IsSaasForSaasReturnsTrue()
    var
        AzureAdMgt: Codeunit "Azure AD Mgt.";
        Result: Boolean;
    begin
        // [SCENARIO] In a SaaS environment, user calls IsSaaS which returns true.

        // [GIVEN] SaaS environment.
        Initialize(false, false, false, false, true);

        // [WHEN] The user invokes IsSaaS.
        Result := AzureAdMgt.IsSaaS();

        // [THEN] The user recieves true.
        Assert.IsTrue(Result, 'IsSaaS should return true, indicating that the user is in a SaaS environment.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IsSaasForOnPremReturnsFalse()
    var
        AzureAdMgt: Codeunit "Azure AD Mgt.";
        Result: Boolean;
    begin
        // [SCENARIO] In an On-Prem environment, user calls IsSaaS which returns false.

        // [GIVEN] On-Prem environment.
        Initialize(false, false, false, false, false);

        // [WHEN] The user invokes IsSaaS.
        Result := AzureAdMgt.IsSaaS();

        // [THEN] The user recieves false.
        Assert.IsFalse(Result, 'IsSaaS should return false, indicating that the user is in a On-Prem/PaaS environment.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IsAzureADAppSetupDoneSaasNoSetupReturnsTrue()
    var
        AzureAdMgt: Codeunit "Azure AD Mgt.";
        Result: Boolean;
    begin
        // [SCENARIO] In a SaaS environment with no AAD setup available, user calls IsAzureADAppSetupDone which returns true.

        // [GIVEN] On-Prem environment with no AAD setup available.
        Initialize(false, false, false, false, true);

        // [WHEN] The user invokes IsAzureADAppSetupDone.
        Result := AzureAdMgt.IsAzureADAppSetupDone();

        // [THEN] The user recieves true.
        Assert.IsTrue(Result, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IsAzureADAppSetupDoneSaasSetupDoneReturnsTrue()
    var
        AzureAdMgt: Codeunit "Azure AD Mgt.";
        Result: Boolean;
    begin
        // [SCENARIO] In a SaaS environment with no AAD setup available, user calls IsAzureADAppSetupDone which returns true.

        // [GIVEN] On-Prem environment with AAD setup completed.
        Initialize(false, false, false, true, true);

        // [WHEN] The user invokes IsAzureADAppSetupDone.
        Result := AzureAdMgt.IsAzureADAppSetupDone();

        // [THEN] The user recieves true.
        Assert.IsTrue(Result, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IsAzureADAppSetupDoneOnPremNoSetupReturnsFalse()
    var
        AzureAdMgt: Codeunit "Azure AD Mgt.";
        Result: Boolean;
    begin
        // [SCENARIO] In an On-Prem/PaaS environment with no AAD setup available, user calls IsAzureADAppSetupDone which returns false.

        // [GIVEN] On-Prem environment with AAD setup completed.
        Initialize(false, false, false, false, false);

        // [WHEN] The user invokes IsAzureADAppSetupDone.
        Result := AzureAdMgt.IsAzureADAppSetupDone();

        // [THEN] The user recieves true.
        Assert.IsFalse(Result, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IsAzureADAppSetupDoneOnPremSetupDoneReturnsTrue()
    var
        AzureAdMgt: Codeunit "Azure AD Mgt.";
        Result: Boolean;
    begin
        // [SCENARIO] In an On-Prem/PaaS environment with AAD setup completed, user calls IsAzureADAppSetupDone which returns true.

        // [GIVEN] On-Prem/PaaS environment with AAD setup completed.
        Initialize(false, false, false, true, false);

        // [WHEN] The user invokes IsAzureADAppSetupDone.
        Result := AzureAdMgt.IsAzureADAppSetupDone();

        // [THEN] The user recieves true.
        Assert.IsTrue(Result, '');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AzureADAccessDialogHandler(var AzureADAccessDialog: TestPage "Azure AD Access Dialog")
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AzureADAppSetupWizardHandler(var AzureADAppSetupWizard: TestPage "Azure AD App Setup Wizard")
    begin
    end;

    [NonDebuggable]
    local procedure AssertSecret(Expected: Text; Actual: SecretText; Message: Text)
    begin
        Assert.AreEqual(Expected, Actual.Unwrap(), Message);
    end;

    [Normal]
    local procedure Initialize(FreshTokenAvailable: Boolean; CachedTokenAvailable: Boolean; GuestTokenAvailable: Boolean; ClientIdAvailable: Boolean; IsSaaS: Boolean)
    var
        AzureADAppSetup: Record "Azure AD App Setup";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        DummySecretKey: Text;
    begin
        // Configure the auth flow library
        Clear(LibraryAzureADAuthFlow);
        LibraryAzureADAuthFlow.SetTokenAvailable(FreshTokenAvailable);
        LibraryAzureADAuthFlow.SetCachedTokenAvailable(CachedTokenAvailable);
        BindSubscription(LibraryAzureADAuthFlow);
        SetAuthFlowProvider(CODEUNIT::"Library - Azure AD Auth Flow");

        // Set SaaS singleton flag
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(IsSaaS);

        // Reset both sources of the client ID to be empty
        AzureADAppSetup.DeleteAll();
        LibraryAzureADAuthFlow.SetClientIdAvailable(false);

        // Set the client ID source based on whether the app is SaaS or On-Prem/PaaS
        if IsSaaS then
            LibraryAzureADAuthFlow.SetClientIdAvailable(ClientIdAvailable)
        else
            if ClientIdAvailable then begin
                AzureADAppSetup.Init();
                AzureADAppSetup."App ID" := '22222222-2222-2222-2222-222222222222';
                DummySecretKey := 'Ultra super secret key';
                AzureADAppSetup.SetSecretKeyToIsolatedStorage(DummySecretKey);
                AzureADAppSetup."Redirect URL" := GetUnencodedRedirectUrl('OAuthLanding.htm');
                AzureADAppSetup.Insert();
            end;

        LibraryAzureADAuthFlow.SetGuestTokenAvailable(GuestTokenAvailable);
    end;

    [Normal]
    local procedure SetAuthFlowProvider(ProviderCodeunit: Integer)
    var
        AzureADMgtSetup: Record "Azure AD Mgt. Setup";
    begin
        AzureADMgtSetup.Get();
        AzureADMgtSetup."Auth Flow Codeunit ID" := ProviderCodeunit;
        AzureADMgtSetup.Modify();
    end;

    [Normal]
    local procedure GetExpectedRedirectUrl("Page": Text): Text
    var
        HttpUtility: DotNet HttpUtility;
    begin
        exit(HttpUtility.UrlEncode(GetUnencodedRedirectUrl(Page)));
    end;

    [Normal]
    local procedure GetUnencodedRedirectUrl("Page": Text): Text[150]
    var
        UriBuilder: DotNet UriBuilder;
        PathString: DotNet String;
    begin
        UriBuilder := UriBuilder.UriBuilder(GetUrl(CLIENTTYPE::Web));
        PathString := UriBuilder.Path;
        if PathString.LastIndexOf('/') < (PathString.Length - 1) then
            UriBuilder.Path := UriBuilder.Path + '/';
        UriBuilder.Path := UriBuilder.Path + Page;
        UriBuilder.Query := '';
        exit(UriBuilder.Uri.ToString());
    end;
}

