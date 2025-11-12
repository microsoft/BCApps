codeunit 139085 "Exchange Sync Credentials Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Exchange Sync]
    end;

    var
        Assert: Codeunit Assert;
        LibraryAzureADAuthFlow: Codeunit "Library - Azure AD Auth Flow";
        Initialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure ExchangeContactSyncShowsPasswordFieldIfTokenNotAvailable()
    var
        ExchangeSyncSetup: TestPage "Exchange Sync. Setup";
    begin
        // [SCENARIO] User is prompted for password if no token is available for the user.

        // [GIVEN] No token is available for the user.
        Initialize(false, false);

        // [WHEN] The user runs the Exchange Sync. Setup page.
        ExchangeSyncSetup.Trap();
        PAGE.Run(PAGE::"Exchange Sync. Setup");

        // [THEN] The password field is visible.
        Assert.IsTrue(ExchangeSyncSetup.ExchangeAccountPasswordTemp.Visible(), 'Password should be visible when token is not available.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExchangeContactSyncHidesPasswordFieldIfTokenAvailable()
    var
        ExchangeSyncSetup: TestPage "Exchange Sync. Setup";
    begin
        // [SCENARIO] User is not prompted for a password if a token is available to use.

        // [GIVEN] A token is available for the user.
        Initialize(false, true);

        // [WHEN] The user runs the Exchange Sync. Setup page.
        ExchangeSyncSetup.Trap();
        PAGE.Run(PAGE::"Exchange Sync. Setup");

        // [THEN] The user does not see the password field.
        Assert.IsFalse(ExchangeSyncSetup.ExchangeAccountPasswordTemp.Visible(), 'Password should not be visible when token available.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UserMustEnterPasswordToProceedWhenTokenNotAvailable()
    var
        ExchangeSyncSetup: TestPage "Exchange Sync. Setup";
    begin
        // [SCENARIO] User cannot proceed to contact sync setup if a password isn't present.

        // [GIVEN] No token is available for the user.
        Initialize(false, false);

        // [WHEN] The user runs the Exchange Sync. Setup page.
        ExchangeSyncSetup.Trap();
        PAGE.Run(PAGE::"Exchange Sync. Setup");

        // [THEN] User receives an error message when they try to open the contact sync or Bookings sync page.
        asserterror ExchangeSyncSetup.SetupContactSync.Invoke();
        asserterror ExchangeSyncSetup.SetupBookingSync.Invoke();
    end;

    [Test]
    [HandlerFunctions('ContactSyncSetupHandler,BookingSyncSetupHandler')]
    [Scope('OnPrem')]
    procedure UserCanProceedWithNoPasswordWhenTokenAvailable()
    var
        ExchangeSyncSetup: TestPage "Exchange Sync. Setup";
    begin
        // [SCENARIO] User can proceed to contact sync setup without a password when a token is available.

        // [GIVEN] An access token is available for the user.
        Initialize(false, true);

        // [WHEN] The user runs the Exchange Sync. Setup page.
        ExchangeSyncSetup.Trap();
        PAGE.Run(PAGE::"Exchange Sync. Setup");

        // [WHEN] The user clicks the "Contact Sync Setup" button
        ExchangeSyncSetup.SetupContactSync.Invoke();

        // [WHEN] The user clicks the "Bookings sync setup" button
        ExchangeSyncSetup.SetupBookingSync.Invoke();

        // [THEN] User gets in without issue.
        // Verified through handlers.
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ContactSyncSetupHandler(var ContactSyncSetup: TestPage "Contact Sync. Setup")
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure BookingSyncSetupHandler(var BookingSyncSetup: TestPage "Booking Sync. Setup")
    begin
    end;

    local procedure Initialize(FreshTokenAvailable: Boolean; CachedTokenAvailable: Boolean)
    var
        BookingSync: Record "Booking Sync";
        LibraryO365Sync: Codeunit "Library - O365 Sync";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
    begin
        Clear(LibraryAzureADAuthFlow);
        LibraryAzureADAuthFlow.SetTokenAvailable(FreshTokenAvailable);
        LibraryAzureADAuthFlow.SetCachedTokenAvailable(CachedTokenAvailable);
        BindSubscription(LibraryAzureADAuthFlow);
        SetAuthFlowProvider(CODEUNIT::"Library - Azure AD Auth Flow");
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);

        if Initialized then
            exit;

        LibraryO365Sync.SetupNavUser();
        LibraryO365Sync.SetupBookingsSync(BookingSync);

        Initialized := true;
    end;

    local procedure SetAuthFlowProvider(ProviderCodeunit: Integer)
    var
        AzureADMgtSetup: Record "Azure AD Mgt. Setup";
        AzureADAppSetup: Record "Azure AD App Setup";
        DummyKey: Text;
    begin
        AzureADMgtSetup.Get();
        AzureADMgtSetup."Auth Flow Codeunit ID" := ProviderCodeunit;
        AzureADMgtSetup.Modify();

        if not AzureADAppSetup.Get() then begin
            AzureADAppSetup.Init();
            AzureADAppSetup."Redirect URL" := 'http://dummyurl:1234/Main_Instance1/WebClient/OAuthLanding.htm';
            AzureADAppSetup."App ID" := CreateGuid();
            DummyKey := CreateGuid();
            AzureADAppSetup.SetSecretKeyToIsolatedStorage(DummyKey);
            AzureADAppSetup.Insert();
        end;
    end;
}

