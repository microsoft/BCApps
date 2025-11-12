namespace System.Azure.Identity;

using System;
using System.Environment;
using System.Utilities;

codeunit 6300 "Azure AD Mgt."
{
    // // Provides functions to authorize NAV app to use Azure Active Directory resources on behalf of a user.
    InherentPermissions = X;
    InherentEntitlements = X;


    trigger OnRun()
    begin
    end;

    var
        AzureADAppSetup: Record "Azure AD App Setup";
        AzureADAuthFlow: Codeunit "Azure AD Auth Flow";
        AzureADNotSetupErr: Label '%1 is not registered in your Microsoft Entra tenant.', Comment = '%1 - product name';
        O365ResourceNameTxt: Label 'Office 365 Services', Locked = true;
        OAuthLandingPageTxt: Label 'OAuthLanding.htm', Locked = true;

    [Scope('OnPrem')]
    procedure GetAuthCodeUrl(ResourceName: Text) AuthCodeUrl: Text
    begin
        // Pass ResourceName as empty string if you want to authorize all azure resources.
        AuthCodeUrl := GetAzureADAuthEndpoint();
        AuthCodeUrl += '?response_type=code';
        AuthCodeUrl += '&client_id=' + UrlEncode(GetClientId());
        if ResourceName <> '' then
            AuthCodeUrl += '&resource=' + UrlEncode(ResourceName);
        AuthCodeUrl += '&redirect_uri=' + UrlEncode(GetRedirectUrl());
    end;
#if not CLEAN25

    [NonDebuggable]
    [Obsolete('Replaced by AcquireTokenByAuthorizationCodeAsSecretText', '25.0')]
    [Scope('OnPrem')]
    procedure AcquireTokenByAuthorizationCode(AuthorizationCode: Text; ResourceUrl: Text) AccessToken: Text
    begin
        exit(AcquireTokenByAuthorizationCodeAsSecretText(AuthorizationCode, ResourceUrl).Unwrap());
    end;
#endif

    [Scope('OnPrem')]
    procedure AcquireTokenByAuthorizationCodeAsSecretText(AuthorizationCode: SecretText; ResourceUrl: Text) AccessToken: SecretText
    begin
        // This will return access token and also cache it for future use.
        AzureADAuthFlow.Initialize(GetRedirectUrl());

        if IsSaaS() then
            AccessToken := AzureADAuthFlow.AcquireTokenByAuthorizationCodeAsSecretText(AuthorizationCode, ResourceUrl)
        else begin
            if not AzureADAppSetup.FindFirst() then
                exit;
            AccessToken := AzureADAuthFlow.AcquireTokenByAuthorizationCodeWithCredentialsAsSecretText(
                AuthorizationCode,
                GetClientId(),
                AzureADAppSetup.GetSecretKeyFromIsolatedStorageAsSecretText(),
                ResourceUrl);
        end;
    end;
#if not CLEAN25

    [Scope('OnPrem')]
    [NonDebuggable]
    [Obsolete('Replaced by GetAccessTokenAsSecretText', '25.0')]
    procedure GetAccessToken(ResourceUrl: Text; ResourceName: Text; ShowDialog: Boolean) AccessToken: Text
    begin
        exit(GetAccessTokenAsSecretText(ResourceUrl, ResourceName, ShowDialog).Unwrap());
    end;
#endif

    [Scope('OnPrem')]
    procedure GetAccessTokenAsSecretText(ResourceUrl: Text; ResourceName: Text; ShowDialog: Boolean) AccessToken: SecretText
    var
        AzureADAccessDialog: Page "Azure AD Access Dialog";
        AuthorizationCode: SecretText;
    begin
        // Does everything required to retrieve an access token for the given service, including
        // showing the Azure AD wizard and auth code retrieval form if necessary.
        if (not IsAzureADAppSetupDone()) and ShowDialog then begin
            PAGE.RunModal(PAGE::"Azure AD App Setup Wizard");
            if not IsAzureADAppSetupDone() then
                // Don't continue if user cancelled or errored out of the setup wizard.
                exit(AccessToken);
        end;

        if AcquireToken(ResourceUrl, AccessToken) then
            if not AccessToken.IsEmpty() then
                exit(AccessToken);

        if IsSaaS() then begin
            Clear(AccessToken);
            exit(AccessToken);
        end;

        if ShowDialog then
            AuthorizationCode := AzureADAccessDialog.GetAuthorizationCodeAsSecretText(ResourceUrl, ResourceName);
        if not AuthorizationCode.IsEmpty() then
            AccessToken := AcquireTokenByAuthorizationCodeAsSecretText(AuthorizationCode, ResourceUrl);
    end;

    [Scope('OnPrem')]
    [NonDebuggable]
    procedure GetGuestAccessToken(ResourceUrl: Text; GuestTenantId: Text) AccessToken: Text
    begin
        // Gets an access token for a guest user on a different tenant
        if AcquireGuestToken(ResourceUrl, GuestTenantId, AccessToken) then
            if AccessToken <> '' then
                exit(AccessToken);
    end;
#if not CLEAN25

    [Scope('OnPrem')]
    [NonDebuggable]
    [Obsolete('Replaced by GetOnBehalfAccessTokenAsSecretText(ResourceUrl: Text): SecretText', '25.0')]
    procedure GetOnBehalfAccessToken(ResourceUrl: Text): Text
    begin
        exit(GetOnBehalfAccessTokenAsSecretText(ResourceUrl).Unwrap());
    end;
#endif

    [Scope('OnPrem')]
    procedure GetOnBehalfAccessTokenAsSecretText(ResourceUrl: Text): SecretText
    begin
        AzureADAuthFlow.Initialize(GetRedirectUrl());
        exit(AzureADAuthFlow.AcquireOnBehalfOfTokenAsSecretText(ResourceUrl));
    end;

    [NonDebuggable]
    [Scope('OnPrem')]
    procedure GetOnBehalfAccessTokenAndTokenCacheState(ResourceUrl: Text; var TokenCacheState: Text): Text
    begin
        AzureADAuthFlow.Initialize(GetRedirectUrl());
        exit(AzureADAuthFlow.AcquireOnBehalfOfTokenAndTokenCacheState(ResourceUrl, TokenCacheState));
    end;

    [NonDebuggable]
    [Scope('OnPrem')]
    procedure GetTokenFromTokenCacheState(ResourceId: Text; AadUserId: Text; TokenCacheState: Text; var NewTokenCacheState: Text): Text
    begin
        AzureADAuthFlow.Initialize(GetRedirectUrl());
        exit(AzureADAuthFlow.AcquireTokenFromCacheState(ResourceId, AadUserId, TokenCacheState, NewTokenCacheState));
    end;

    local procedure UrlEncode(UrlComponent: Text): Text
    var
        HttpUtility: DotNet HttpUtility;
    begin
        exit(HttpUtility.UrlEncode(UrlComponent));
    end;

    procedure GetAzureADAuthEndpoint(): Text
    var
        UrlHelper: Codeunit "Url Helper";
    begin
        exit(UrlHelper.GetAzureADAuthEndpoint());
    end;

    [Scope('OnPrem')]
    procedure GetDefaultRedirectUrl(): Text[150]
    var
        UriBuilder: DotNet UriBuilder;
        PathString: DotNet String;
        RedirectUrl: Text;
    begin
        // Retrieve the Client URL
        RedirectUrl := GetUrl(ClientType::Web);
        // For SaaS Extract the Base Url (domain) from the full CLient URL
        if IsSaaS() then
            RedirectUrl := GetBaseUrl(RedirectUrl);

        // Due to a bug in ADAL 2.9, it will not consider URI's to be equal if one URI specified the default port number (ex: 443 for HTTPS)
        // and the other did not. UriBuilder(...).Uri.ToString() is a way to remove any protocol-default port numbers, such as 80 for HTTP
        // and 443 for HTTPS. This bug appears to be fixed in ADAL 3.1+.
        UriBuilder := UriBuilder.UriBuilder(RedirectUrl);

        // Append a '/' character to the end of the path if one does not exist already.
        PathString := UriBuilder.Path;
        if PathString.LastIndexOf('/') < (PathString.Length - 1) then
            UriBuilder.Path := UriBuilder.Path + '/';

        // Append the desired redirect page to the path.
        UriBuilder.Path := UriBuilder.Path + OAuthLandingPageTxt;
        UriBuilder.Query := '';

        // Pull out the full URL by the URI and convert it to a string.
        RedirectUrl := UriBuilder.Uri.ToString();

        exit(CopyStr(RedirectUrl, 1, 150));
    end;

    [Scope('OnPrem')]
    procedure GetRedirectUrl(): Text[150]
    begin
        if not IsSaaS() and not AzureADAppSetup.IsEmpty() then begin
            // Use existing redirect URL if already in table - necessary for Windows client which would otherwise
            // generate a different URL for each computer and thus not match the company's Azure application.
            AzureADAppSetup.FindFirst();
            exit(AzureADAppSetup."Redirect URL");
        end;

        exit(GetDefaultRedirectUrl());
    end;

    local procedure GetBaseUrl(RedirectUrl: Text): Text
    var

        BaseIndex: Integer;
        EndBaseUrlIndex: Integer;
        Baseurl: Text;
    begin
        if StrPos(LowerCase(RedirectUrl), 'https://') <> 0 then
            BaseIndex := 9;
        if StrPos(LowerCase(RedirectUrl), 'http://') <> 0 then
            BaseIndex := 8;

        Baseurl := CopyStr(RedirectUrl, BaseIndex);
        EndBaseUrlIndex := StrPos(Baseurl, '/');

        if EndBaseUrlIndex = 0 then
            exit(RedirectUrl);

        Baseurl := CopyStr(Baseurl, 1, EndBaseUrlIndex - 1);
        exit(CopyStr(RedirectUrl, 1, BaseIndex - 1) + Baseurl);
    end;

    procedure GetO365Resource(): Text
    var
        UrlHelper: Codeunit "Url Helper";
    begin
        exit(UrlHelper.GetO365Resource());
    end;

    procedure GetO365ResourceName(): Text
    begin
        exit(O365ResourceNameTxt);
    end;

    procedure IsSaaS(): Boolean
    var
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        exit(EnvironmentInfo.IsSaaSInfrastructure());
    end;

    local procedure GetClientId() ClientID: Text
    begin
        if IsSaaS() then begin
            AzureADAuthFlow.Initialize(GetRedirectUrl());
            ClientID := AzureADAuthFlow.GetSaasClientId();
        end else begin
            if AzureADAppSetup.IsEmpty() then
                Error(AzureADNotSetupErr, ProductName.Short());

            AzureADAppSetup.FindFirst();
            ClientID := LowerCase(Format(AzureADAppSetup."App ID", 0, 4));
        end;
    end;

    [Scope('OnPrem')]
    procedure GetInitialTenantDomainName() InitialTenantDomainName: Text
    begin
        if IsSaaS() then begin
            AzureADAuthFlow.Initialize(GetRedirectUrl());
            InitialTenantDomainName := AzureADAuthFlow.GetInitialTenantDomainName();
        end;
    end;

    procedure IsAzureADAppSetupDone(): Boolean
    begin
        if (not IsSaaS()) and AzureADAppSetup.IsEmpty() then
            exit(false);

        exit(true);
    end;
#if not CLEAN25

    [Scope('OnPrem')]
    [NonDebuggable]
    [Obsolete('Replaced by CreateExchangeServiceWrapperWithToken(Token: SecretText; var Service: DotNet ExchangeServiceWrapper)', '25.0')]
    procedure CreateExchangeServiceWrapperWithToken(Token: Text; var Service: DotNet ExchangeServiceWrapper)
    var
        TokenAsSecretText: SecretText;
    begin
        TokenAsSecretText := Token;
        CreateExchangeServiceWrapperWithToken(TokenAsSecretText, Service);
    end;
#endif

    [Scope('OnPrem')]
    procedure CreateExchangeServiceWrapperWithToken(Token: SecretText; var Service: DotNet ExchangeServiceWrapper)
    begin
        AzureADAuthFlow.CreateExchangeServiceWrapperWithToken(Token, Service);
    end;

    [Scope('OnPrem')]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Action Triggers", 'GetUserToken', '', false, false)]
    [NonDebuggable]
    local procedure OnGetUserToken(Resource: Text; Scenario: Text; var Token: Text)
    begin
        Token := GetAccessTokenAsSecretText(Resource, Resource, false).Unwrap();
    end;

    [TryFunction]
    [NonDebuggable]
    local procedure AcquireGuestToken(ResourceName: Text; GuestTenantId: Text; var AccessToken: Text)
    begin
        if IsSaaS() then begin
            // This is SaaS-only functionality at this point, so On-Prem/PaaS will not retrieve an access token
            AzureADAuthFlow.Initialize(GetRedirectUrl());
            AccessToken := AzureADAuthFlow.AcquireGuestToken(ResourceName, GuestTenantId);
        end else
            AccessToken := '';
    end;
#if not CLEAN25

    [TryFunction]
    [NonDebuggable]
    [Obsolete('Replaced by parameter with AccessToken: SecretText', '25.0')]
    local procedure AcquireToken(ResourceName: Text; var AccessToken: Text)
    var
        AccessTokenAsSecretText: SecretText;
    begin
        AcquireToken(ResourceName, AccessTokenAsSecretText);
        AccessToken := AccessTokenAsSecretText.Unwrap();
    end;
#endif

    [TryFunction]
    local procedure AcquireToken(ResourceName: Text; var AccessToken: SecretText)
    begin
        // This function will return access token for a resource
        // Need to run the Azure AD Setup wizard before calling into this.
        // Returns empty string if access token not available

        AzureADAuthFlow.Initialize(GetRedirectUrl());

        if IsSaaS() then
            AccessToken := AzureADAuthFlow.AcquireTokenFromCacheAsSecretText(ResourceName)
        else begin
            AzureADAppSetup.FindFirst();
            AccessToken := AzureADAuthFlow.AcquireTokenFromCacheWithCredentialsAsSecretText(
                GetClientId(),
                AzureADAppSetup.GetSecretKeyFromIsolatedStorageAsSecretText(),
                ResourceName);
        end;
    end;

    [NonDebuggable]
    [Scope('OnPrem')]
    procedure GetLastErrorMessage(): Text
    var
        AuthenticationError: Text;
    begin
        AuthenticationError := AzureADAuthFlow.GetLastErrorMessage();
        if AuthenticationError <> '' then
            exit(AuthenticationError);

        exit(GetLastErrorText());
    end;
}

