// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Security.Authentication;

using System;
using System.Text;
using System.Environment;
using System.Utilities;

codeunit 502 OAuth2Impl
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        [NonDebuggable]
        AuthFlow: DotNet ALAzureAdCodeGrantFlow;
        OAuthLandingPageTxt: Label 'OAuthLanding.htm', Locked = true;
        Oauth2CategoryLbl: Label 'OAuth2', Locked = true;
        RedirectUrlTxt: Label 'The defined redirectURL is: %1', Comment = '%1 = The redirect URL', Locked = true;
        DefaultRedirectUrlTxt: Label 'The default redirectURL is: %1', Comment = '%1 = The redirect URL', Locked = true;
        AuthRequestUrlTxt: Label 'The authentication request URL %1 has been succesfully retrieved.', Comment = '%1=Authentication request URL';
        MissingClientIdRedirectUrlErr: Label 'The authorization request URL for the OAuth2 Grant flow cannot be constructed because of missing ClientId or RedirectUrl', Locked = true;
        AuthorizationCodeErr: Label 'The OAuth2 authentication code retrieved is empty.', Locked = true;
        EmptyAccessTokenClientCredsErr: Label 'The access token failed to be retrieved by the client credentials grant flow.', Locked = true;
        PopupBlockedCodeErrLbl: Label 'Popup blocked', Locked = true;
        PopupBlockedErr: Label 'Your browser may be blocking pop-ups needed by %1.\\Change your browser settings to allow pop-ups or allow pop-ups from the %1 site, then try again.', Comment = '%1 = Short product name (e.g. Business Central)';

    [NonDebuggable]
    procedure GetAuthRequestUrl(ClientId: Text; Url: Text; RedirectUrl: Text; var State: Text; ResourceUrl: Text; PromptConsent: Enum "Prompt Interaction"): Text
    var
        AuthRequestUrl: Text;
    begin
        if (ClientId = '') or (RedirectUrl = '') then begin
            Session.LogMessage('0000CCI', MissingClientIdRedirectUrlErr, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', Oauth2CategoryLbl);
            exit('');
        end;

        State := Format(CreateGuid(), 0, 4);

        AuthRequestUrl := Url + '?client_id=' + ClientId + '&redirect_uri=' + RedirectUrl + '&state=' + State + '&response_type=code&response_mode=query';

        if ResourceUrl <> '' then
            AuthRequestUrl := AuthRequestUrl + '&resource=' + ResourceUrl;

        AppendPromptParameter(PromptConsent, AuthRequestUrl);

        Session.LogMessage('0000BRH', StrSubstNo(AuthRequestUrlTxt, AuthRequestUrl), Verbosity::Normal, DataClassification::AccountData, TelemetryScope::ExtensionPublisher, 'Category', Oauth2CategoryLbl);
        exit(AuthRequestUrl);
    end;

    procedure GetAuthRequestUrl(ClientId: Text; ClientSecret: SecretText; Url: Text; RedirectUrl: Text; var State: Text; Scopes: List of [Text]; PromptConsent: Enum "Prompt Interaction"): Text
    begin
        exit(GetAuthRequestUrl(ClientId, ClientSecret, Url, RedirectUrl, State, Scopes, PromptConsent, ''));
    end;

    procedure GetAuthRequestUrl(ClientId: Text; ClientSecret: SecretText; Url: Text; RedirectUrl: Text; var State: Text; Scopes: List of [Text]; PromptConsent: Enum "Prompt Interaction"; Audience: Text): Text
    var
        OAuthAuthorization: DotNet OAuthAuthorization;
        Consumer: DotNet Consumer;
        Token: DotNet Token;
        Scope: Text;
        ScopeText: Text;
        AuthRequestUrl: Text;
        SecretClientId: SecretText;
        EmptySecretText: SecretText;
    begin
        if (ClientId = '') or (RedirectUrl = '') then begin
            Session.LogMessage('0000D1J', MissingClientIdRedirectUrlErr, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', Oauth2CategoryLbl);
            exit('');
        end;
        Token := Token.Token(EmptySecretText, EmptySecretText);
        SecretClientId := ClientId;
        Consumer := Consumer.Consumer(SecretClientId, ClientSecret);
        OAuthAuthorization := OAuthAuthorization.OAuthAuthorization(Consumer, Token);

        foreach Scope in Scopes do
            if ScopeText = '' then
                ScopeText := ScopeText + Scope
            else
                ScopeText := ScopeText + ' ' + Scope;

        State := Format(CreateGuid(), 0, 4);

        AuthRequestUrl := OAuthAuthorization.CalculateAuthRequestUrl(Url, RedirectUrl, ScopeText, State);

        AppendPromptParameter(PromptConsent, AuthRequestUrl);

        AppendAudienceParameter(Audience, AuthRequestUrl);

        Session.LogMessage('0000D1K', StrSubstNo(AuthRequestUrlTxt, AuthRequestUrl), Verbosity::Normal, DataClassification::AccountData, TelemetryScope::ExtensionPublisher, 'Category', Oauth2CategoryLbl);
        exit(AuthRequestUrl);
    end;

    local procedure AppendAudienceParameter(Audience: Text; var AuthRequestUrl: Text)
    var
        Uri: Dotnet Uri;
    begin
        if (Audience = '') then
            exit;

        AuthRequestUrl += '&audience=' + Uri.EscapeDataString(Audience);
    end;

    [NonDebuggable]
    procedure AppendPromptParameter(PromptConsent: Enum "Prompt Interaction"; var AuthRequestUrl: Text)
    begin
        case PromptConsent of
            PromptConsent::Login:
                AuthRequestUrl := AuthRequestUrl + '&prompt=login';
            PromptConsent::"Select Account":
                AuthRequestUrl := AuthRequestUrl + '&prompt=select_account';
            PromptConsent::Consent:
                AuthRequestUrl := AuthRequestUrl + '&prompt=consent';
            PromptConsent::"Admin Consent":
                AuthRequestUrl := AuthRequestUrl + '&prompt=admin_consent';
        end;
    end;

    procedure GetOAuthProperties(AuthorizationCode: Text; var CodeOut: Text; var StateOut: Text; var AdminConsent: Text)
    begin
        if AuthorizationCode = '' then begin
            Session.LogMessage('0000C1V', AuthorizationCodeErr, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', Oauth2CategoryLbl);
            exit;
        end;

        if AuthorizationCode.EndsWith('#') then
            AuthorizationCode := CopyStr(AuthorizationCode, 1, StrLen(AuthorizationCode) - 1);

        CodeOut := GetPropertyFromCode(AuthorizationCode, 'code');
        StateOut := GetPropertyFromCode(AuthorizationCode, 'state');
        AdminConsent := GetPropertyFromCode(AuthorizationCode, 'admin_consent');
    end;

    procedure GetDefaultRedirectUrl(): Text
    var
        EnvironmentInformation: Codeunit "Environment Information";
        UriBuilder: DotNet UriBuilder;
        PathString: DotNet String;
        RedirectUrl: Text;
    begin
        // Retrieve the Client URL
        RedirectUrl := GetUrl(ClientType::Web);

        // For SaaS Extract the Base Url (domain) from the full CLient URL
        if EnvironmentInformation.IsSaaSInfrastructure() then
            RedirectUrl := GetBaseUrl(RedirectUrl);

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

        Session.LogMessage('0000C21', StrSubstNo(DefaultRedirectUrlTxt, RedirectUrl), Verbosity::Normal, DataClassification::AccountData, TelemetryScope::ExtensionPublisher, 'Category', Oauth2CategoryLbl);
        exit(RedirectUrl);
    end;

    [TryFunction]
    procedure RequestClientCredentialsAdminPermissions(ClientId: Text; OAuthAuthorityUrl: Text; RedirectURL: Text; var HasGrantConsentSucceeded: Boolean; var PermissionGrantError: Text)
    var
        OAuth2ControlAddIn: Page OAuth2ControlAddIn;
        Url: Text;
        State: Text;
    begin
        if RedirectURL = '' then
            RedirectURL := GetDefaultRedirectUrl();
        State := Format(CreateGuid(), 0, 4);
        Url := OAuthAuthorityUrl + '?client_id=' + ClientId + '&redirect_uri=' + RedirectURL + '&state=' + State;

        OAuth2ControlAddIn.SetOAuth2Properties(Url, State);
        OAuth2ControlAddIn.RunModal();

        HasGrantConsentSucceeded := OAuth2ControlAddIn.GetGrantConsentSuccess();
        PermissionGrantError := OAuth2ControlAddIn.GetAuthError();
    end;

#if not CLEAN25
    [TryFunction]
    [Obsolete('Use AcquireTokenByAuthorizationCodeWithCertificate with SecretText data type for AccessToken and Certificate.', '25.0')]
    procedure AcquireTokenByAuthorizationCodeWithCertificate(ClientId: Text; Certificate: Text; OAuthAuthorityUrl: Text; RedirectURL: Text; ResourceUrl: Text; PromptInteraction: Enum "Prompt Interaction"; var AccessToken: SecretText; var AuthCodeErr: Text)
    var
        CertificateSecret: SecretText;
        CertificatePassword: SecretText;
    begin
        CertificateSecret := Certificate;
        AcquireTokenByAuthorizationCodeWithCertificate(ClientId, CertificateSecret, CertificatePassword, OAuthAuthorityUrl, RedirectURL, ResourceUrl, PromptInteraction, AccessToken, AuthCodeErr);
    end;

    [TryFunction]
    [Obsolete('Use AcquireTokenByAuthorizationCodeWithCertificate with SecretText data type for AccessToken, Certificate and CertificatePassword.', '25.0')]
    procedure AcquireTokenByAuthorizationCodeWithCertificate(ClientId: Text; Certificate: Text; CertificatePassword: SecretText; OAuthAuthorityUrl: Text; RedirectURL: Text; ResourceUrl: Text; PromptInteraction: Enum "Prompt Interaction"; var AccessToken: SecretText; var AuthCodeErr: Text)
    var
        CertificateSecret: SecretText;
    begin
        CertificateSecret := Certificate;
        AcquireTokenByAuthorizationCodeWithCertificate(ClientId, CertificateSecret, CertificatePassword, OAuthAuthorityUrl, RedirectURL, ResourceUrl, PromptInteraction, AccessToken, AuthCodeErr);
    end;

    [TryFunction]
    [Obsolete('Use AcquireTokenByAuthorizationCodeWithCertificate with SecretText data type for AccessToken and Certificate.', '25.0')]
    procedure AcquireTokenByAuthorizationCodeWithCertificate(ClientId: Text; Certificate: Text; OAuthAuthorityUrl: Text; RedirectURL: Text; Scopes: List of [Text]; PromptInteraction: Enum "Prompt Interaction"; var AccessToken: SecretText; var AuthCodeErr: Text)
    var
        CertificateSecret: SecretText;
        CertificatePassword: SecretText;
    begin
        CertificateSecret := Certificate;
        AcquireTokenByAuthorizationCodeWithCertificate(ClientId, CertificateSecret, CertificatePassword, OAuthAuthorityUrl, RedirectURL, Scopes, PromptInteraction, AccessToken, AuthCodeErr);
    end;

    [TryFunction]
    [Obsolete('Use AcquireTokenByAuthorizationCodeWithCertificate with SecretText data type for AccessToken, Certificate and CertificatePassword.', '25.0')]
    procedure AcquireTokenByAuthorizationCodeWithCertificate(ClientId: Text; Certificate: Text; CertificatePassword: SecretText; OAuthAuthorityUrl: Text; RedirectURL: Text; Scopes: List of [Text]; PromptInteraction: Enum "Prompt Interaction"; var AccessToken: SecretText; var AuthCodeErr: Text)
    var
        CertificateSecret: SecretText;
    begin
        CertificateSecret := Certificate;
        AcquireTokenByAuthorizationCodeWithCertificate(ClientId, CertificateSecret, CertificatePassword, OAuthAuthorityUrl, RedirectURL, Scopes, PromptInteraction, AccessToken, AuthCodeErr);
    end;

    [TryFunction]
    [Obsolete('Use AcquireTokensByAuthorizationCodeWithCertificate with SecretText data type for AccessToken and Certificate.', '25.0')]
    procedure AcquireTokensByAuthorizationCodeWithCertificate(ClientId: Text; Certificate: Text; OAuthAuthorityUrl: Text; RedirectURL: Text; Scopes: List of [Text]; PromptInteraction: Enum "Prompt Interaction"; var AccessToken: SecretText; var IdToken: Text; var AuthCodeErr: Text)
    var
        CertificateSecret: SecretText;
        CertificatePassword: SecretText;
    begin
        CertificateSecret := Certificate;
        AcquireTokensByAuthorizationCodeWithCertificate(ClientId, CertificateSecret, CertificatePassword, OAuthAuthorityUrl, RedirectURL, Scopes, PromptInteraction, AccessToken, IdToken, AuthCodeErr);
    end;

    [TryFunction]
    [Obsolete('Use AcquireTokensByAuthorizationCodeWithCertificate with SecretText data type for AccessToken, Certificate and CertificatePassword.', '25.0')]
    procedure AcquireTokensByAuthorizationCodeWithCertificate(ClientId: Text; Certificate: Text; CertificatePassword: SecretText; OAuthAuthorityUrl: Text; RedirectURL: Text; Scopes: List of [Text]; PromptInteraction: Enum "Prompt Interaction"; var AccessToken: SecretText; var IdToken: Text; var AuthCodeErr: Text)
    var
        CertificateSecret: SecretText;
    begin
        CertificateSecret := Certificate;
        AcquireTokensByAuthorizationCodeWithCertificate(ClientId, CertificateSecret, CertificatePassword, OAuthAuthorityUrl, RedirectURL, Scopes, PromptInteraction, AccessToken, IdToken, AuthCodeErr);
    end;

    [TryFunction]
    [Obsolete('Use AcquireTokenAndTokenCacheByAuthorizationCodeWithCertificate with SecretText data type for AccessToken and Certificate.', '25.0')]
    procedure AcquireTokenAndTokenCacheByAuthorizationCodeWithCertificate(ClientId: Text; Certificate: Text; OAuthAuthorityUrl: Text; RedirectURL: Text; Scopes: List of [Text]; PromptInteraction: Enum "Prompt Interaction"; var AccessToken: SecretText; var TokenCache: Text; var Error: Text)
    var
        CertificateSecret: SecretText;
        CertificatePassword: SecretText;
    begin
        CertificateSecret := Certificate;
        AcquireTokenAndTokenCacheByAuthorizationCodeWithCertificate(ClientId, CertificateSecret, CertificatePassword, OAuthAuthorityUrl, RedirectURL, Scopes, PromptInteraction, AccessToken, TokenCache, Error);
    end;

    [TryFunction]
    [Obsolete('Use AcquireTokenAndTokenCacheByAuthorizationCodeWithCertificate with SecretText data type for AccessToken, Certificate and CertificatePassword.', '25.0')]
    procedure AcquireTokenAndTokenCacheByAuthorizationCodeWithCertificate(ClientId: Text; Certificate: Text; CertificatePassword: SecretText; OAuthAuthorityUrl: Text; RedirectURL: Text; Scopes: List of [Text]; PromptInteraction: Enum "Prompt Interaction"; var AccessToken: SecretText; var TokenCache: Text; var Error: Text)
    var
        CertificateSecret: SecretText;
    begin
        CertificateSecret := Certificate;
        AcquireTokenAndTokenCacheByAuthorizationCodeWithCertificate(ClientId, CertificateSecret, CertificatePassword, OAuthAuthorityUrl, RedirectURL, Scopes, PromptInteraction, AccessToken, TokenCache, Error);
    end;

    [TryFunction]
    [Obsolete('Use AcquireTokensAndTokenCacheByAuthorizationCodeWithCertificate with SecretText data type for AccessToken and Certificate.', '25.0')]
    procedure AcquireTokensAndTokenCacheByAuthorizationCodeWithCertificate(ClientId: Text; Certificate: Text; OAuthAuthorityUrl: Text; RedirectURL: Text; Scopes: List of [Text]; PromptInteraction: Enum "Prompt Interaction"; var AccessToken: SecretText; var IdToken: Text; var TokenCache: Text; var Error: Text)
    var
        CertificateSecret: SecretText;
        CertificatePassword: SecretText;
    begin
        CertificateSecret := Certificate;
        AcquireTokensAndTokenCacheByAuthorizationCodeWithCertificate(ClientId, CertificateSecret, CertificatePassword, OAuthAuthorityUrl, RedirectURL, Scopes, PromptInteraction, AccessToken, IdToken, TokenCache, Error);
    end;

    [TryFunction]
    [Obsolete('Use AcquireTokensAndTokenCacheByAuthorizationCodeWithCertificate with SecretText data type for AccessToken, Certificate and CertificatePassword.', '25.0')]
    procedure AcquireTokensAndTokenCacheByAuthorizationCodeWithCertificate(ClientId: Text; Certificate: Text; CertificatePassword: SecretText; OAuthAuthorityUrl: Text; RedirectURL: Text; Scopes: List of [Text]; PromptInteraction: Enum "Prompt Interaction"; var AccessToken: SecretText; var IdToken: Text; var TokenCache: Text; var Error: Text)
    var
        CertificateSecret: SecretText;
    begin
        CertificateSecret := Certificate;
        AcquireTokensAndTokenCacheByAuthorizationCodeWithCertificate(ClientId, CertificateSecret, CertificatePassword, OAuthAuthorityUrl, RedirectURL, Scopes, PromptInteraction, AccessToken, IdToken, TokenCache, Error);
    end;

    [TryFunction]
    [Obsolete('Use AcquireTokenFromCacheWithCertificate with SecretText data type for AccessToken and Certificate.', '25.0')]
    procedure AcquireTokenFromCacheWithCertificate(RedirectURL: Text; ClientId: Text; Certificate: Text; OAuthAuthorityUrl: Text; ResourceURL: Text; var AccessToken: SecretText)
    var
        CertificateSecret: SecretText;
        CertificatePassword: SecretText;
    begin
        CertificateSecret := Certificate;
        AcquireTokenFromCacheWithCertificate(RedirectURL, ClientId, CertificateSecret, CertificatePassword, OAuthAuthorityUrl, ResourceURL, AccessToken);
    end;

    [NonDebuggable]
    [TryFunction]
    [Obsolete('Use AcquireTokenFromCacheWithCertificate with SecretText data type for AccessToken, Certificate and CertificatePassword.', '25.0')]
    procedure AcquireTokenFromCacheWithCertificate(RedirectURL: Text; ClientId: Text; Certificate: Text; CertificatePassword: SecretText; OAuthAuthorityUrl: Text; ResourceURL: Text; var AccessToken: SecretText)
    var
        CertificateSecret: SecretText;
    begin
        CertificateSecret := Certificate;
        AcquireTokenFromCacheWithCertificate(RedirectURL, ClientId, CertificateSecret, CertificatePassword, OAuthAuthorityUrl, ResourceURL, AccessToken);
    end;

    [TryFunction]
    [Obsolete('Use AcquireTokenFromCacheWithCertificate with SecretText data type for AccessToken and Certificate.', '25.0')]
    procedure AcquireTokenFromCacheWithCertificate(RedirectURL: Text; ClientId: Text; Certificate: Text; OAuthAuthorityUrl: Text; Scopes: List of [Text]; var AccessToken: SecretText)
    var
        CertificateSecret: SecretText;
        CertificatePassword: SecretText;
    begin
        CertificateSecret := Certificate;
        AcquireTokenFromCacheWithCertificate(RedirectURL, ClientId, CertificateSecret, CertificatePassword, OAuthAuthorityUrl, Scopes, AccessToken);
    end;

    [TryFunction]
    [Obsolete('Use AcquireTokenFromCacheWithCertificate with SecretText data type for AccessToken, Certificate and CertificatePassword.', '25.0')]
    procedure AcquireTokenFromCacheWithCertificate(RedirectURL: Text; ClientId: Text; Certificate: Text; CertificatePassword: SecretText; OAuthAuthorityUrl: Text; Scopes: List of [Text]; var AccessToken: SecretText)
    var
        CertificateSecret: SecretText;
    begin
        CertificateSecret := Certificate;
        AcquireTokenFromCacheWithCertificate(RedirectURL, ClientId, CertificateSecret, CertificatePassword, OAuthAuthorityUrl, Scopes, AccessToken);
    end;

    [TryFunction]
    [Obsolete('Use AcquireTokensFromCacheWithCertificate with SecretText data type for AccessToken and Certificate.', '25.0')]
    procedure AcquireTokensFromCacheWithCertificate(RedirectURL: Text; ClientId: Text; Certificate: Text; OAuthAuthorityUrl: Text; Scopes: List of [Text]; var AccessToken: SecretText; var IdToken: Text)
    var
        CertificateSecret: SecretText;
        CertificatePassword: SecretText;
    begin
        CertificateSecret := Certificate;
        AcquireTokensFromCacheWithCertificate(RedirectURL, ClientId, CertificateSecret, CertificatePassword, OAuthAuthorityUrl, Scopes, AccessToken, IdToken);
    end;

    [TryFunction]
    [Obsolete('Use AcquireTokensFromCacheWithCertificate with SecretText data type for AccessToken, Certificate and CertificatePassword.', '25.0')]
    procedure AcquireTokensFromCacheWithCertificate(RedirectURL: Text; ClientId: Text; Certificate: Text; CertificatePassword: SecretText; OAuthAuthorityUrl: Text; Scopes: List of [Text]; var AccessToken: SecretText; var IdToken: Text)
    var
        CertificateSecret: SecretText;
    begin
        CertificateSecret := Certificate;
        AcquireTokensFromCacheWithCertificate(RedirectURL, ClientId, CertificateSecret, CertificatePassword, OAuthAuthorityUrl, Scopes, AccessToken, IdToken);
    end;

    [TryFunction]
    [Obsolete('Use AcquireTokensWithCertificate with SecretText data type for AccessToken and Certificate.', '25.0')]
    procedure AcquireTokensWithCertificate(RedirectURL: Text; ClientId: Text; Certificate: Text; OAuthAuthorityUrl: Text; Scopes: List of [Text]; var AccessToken: SecretText; var IdToken: Text)
    var
        CertificateSecret: SecretText;
        CertificatePassword: SecretText;
    begin
        CertificateSecret := Certificate;
        AcquireTokensWithCertificate(RedirectURL, ClientId, CertificateSecret, CertificatePassword, OAuthAuthorityUrl, Scopes, AccessToken, IdToken);
    end;

    [TryFunction]
    [Obsolete('Use AcquireTokensWithCertificate with SecretText data type for AccessToken, Certificate and CertificatePassword.', '25.0')]
    procedure AcquireTokensWithCertificate(RedirectURL: Text; ClientId: Text; Certificate: Text; CertificatePassword: SecretText; OAuthAuthorityUrl: Text; Scopes: List of [Text]; var AccessToken: SecretText; var IdToken: Text)
    var
        CertificateSecret: SecretText;
    begin
        CertificateSecret := Certificate;
        AcquireTokensWithCertificate(RedirectURL, ClientId, CertificateSecret, CertificatePassword, OAuthAuthorityUrl, Scopes, AccessToken, IdToken);
    end;

    [TryFunction]
    [Obsolete('Use AcquireTokenByAuthorizationCodeWithCertificate with SecretText data type for AccessToken and Certificate.', '25.0')]
    procedure AcquireTokenByAuthorizationCodeWithCertificate(AuthorizationCode: Text; ClientId: Text; Certificate: Text; RedirectUrl: Text; OAuthAuthorityUrl: Text; ResourceURL: Text; var AccessToken: SecretText)
    var
        CertificateSecret: SecretText;
        CertificatePassword: SecretText;
    begin
        CertificateSecret := Certificate;
        AcquireTokenByAuthorizationCodeWithCertificate(AuthorizationCode, ClientId, CertificateSecret, CertificatePassword, RedirectUrl, OAuthAuthorityUrl, ResourceURL, AccessToken);
    end;

    [TryFunction]
    [Obsolete('Use AcquireTokenByAuthorizationCodeWithCertificate with SecretText data type for AccessToken, Certificate and CertificatePassword.', '25.0')]
    procedure AcquireTokenByAuthorizationCodeWithCertificate(AuthorizationCode: Text; ClientId: Text; Certificate: Text; CertificatePassword: SecretText; RedirectUrl: Text; OAuthAuthorityUrl: Text; ResourceURL: Text; var AccessToken: SecretText)
    var
        CertificateSecret: SecretText;
    begin
        CertificateSecret := Certificate;
        AcquireTokenByAuthorizationCodeWithCertificate(AuthorizationCode, ClientId, CertificateSecret, CertificatePassword, RedirectUrl, OAuthAuthorityUrl, ResourceURL, AccessToken);
    end;

    [TryFunction]
    [Obsolete('Use AcquireTokenByAuthorizationCodeWithCertificate with SecretText data type for AccessToken and Certificate.', '25.0')]
    procedure AcquireTokenByAuthorizationCodeWithCertificate(AuthorizationCode: Text; ClientId: Text; Certificate: Text; RedirectUrl: Text; OAuthAuthorityUrl: Text; Scopes: List of [Text]; var AccessToken: SecretText)
    var
        CertificateSecret: SecretText;
        CertificatePassword: SecretText;
    begin
        CertificateSecret := Certificate;
        AcquireTokenByAuthorizationCodeWithCertificate(AuthorizationCode, ClientId, CertificateSecret, CertificatePassword, RedirectUrl, OAuthAuthorityUrl, Scopes, AccessToken);
    end;

    [TryFunction]
    [Obsolete('Use AcquireTokenByAuthorizationCodeWithCertificate with SecretText data type for AccessToken, Certificate and CertificatePassword.', '25.0')]
    procedure AcquireTokenByAuthorizationCodeWithCertificate(AuthorizationCode: Text; ClientId: Text; Certificate: Text; CertificatePassword: SecretText; RedirectUrl: Text; OAuthAuthorityUrl: Text; Scopes: List of [Text]; var AccessToken: SecretText)
    var
        CertificateSecret: SecretText;
    begin
        CertificateSecret := Certificate;
        AcquireTokenByAuthorizationCodeWithCertificate(AuthorizationCode, ClientId, CertificateSecret, CertificatePassword, RedirectUrl, OAuthAuthorityUrl, Scopes, AccessToken);
    end;

    [TryFunction]
    [Obsolete('Use AcquireTokensByAuthorizationCodeWithCertificate with SecretText data type for AccessToken and Certificate.', '25.0')]
    procedure AcquireTokensByAuthorizationCodeWithCertificate(AuthorizationCode: Text; ClientId: Text; Certificate: Text; RedirectUrl: Text; OAuthAuthorityUrl: Text; Scopes: List of [Text]; var AccessToken: SecretText; var IdToken: Text)
    var
        CertificateSecret: SecretText;
        CertificatePassword: SecretText;
    begin
        CertificateSecret := Certificate;
        AcquireTokensByAuthorizationCodeWithCertificate(AuthorizationCode, ClientId, CertificateSecret, CertificatePassword, RedirectUrl, OAuthAuthorityUrl, Scopes, AccessToken, IdToken);
    end;

    [TryFunction]
    [Obsolete('Use AcquireTokensByAuthorizationCodeWithCertificate with SecretText data type for AccessToken, Certificate and CertificatePassword.', '25.0')]
    procedure AcquireTokensByAuthorizationCodeWithCertificate(AuthorizationCode: Text; ClientId: Text; Certificate: Text; CertificatePassword: SecretText; RedirectUrl: Text; OAuthAuthorityUrl: Text; Scopes: List of [Text]; var AccessToken: SecretText; var IdToken: Text)
    var
        CertificateSecret: SecretText;
    begin
        CertificateSecret := Certificate;
        AcquireTokensByAuthorizationCodeWithCertificate(AuthorizationCode, ClientId, CertificateSecret, CertificatePassword, RedirectUrl, OAuthAuthorityUrl, Scopes, AccessToken, IdToken);
    end;

    [TryFunction]
    [Obsolete('Use AcquireTokenAndTokenCacheByAuthorizationCodeWithCertificate with SecretText data type for AccessToken and Certificate.', '25.0')]
    procedure AcquireTokenAndTokenCacheByAuthorizationCodeWithCertificate(AuthorizationCode: Text; ClientId: Text; Certificate: Text; RedirectUrl: Text; OAuthAuthorityUrl: Text; Scopes: List of [Text]; var AccessToken: SecretText; var TokenCache: Text)
    var
        CertificateSecret: SecretText;
        CertificatePassword: SecretText;
    begin
        CertificateSecret := Certificate;
        AcquireTokenAndTokenCacheByAuthorizationCodeWithCertificate(AuthorizationCode, ClientId, CertificateSecret, CertificatePassword, RedirectUrl, OAuthAuthorityUrl, Scopes, AccessToken, TokenCache);
    end;

    [TryFunction]
    [Obsolete('Use AcquireTokenAndTokenCacheByAuthorizationCodeWithCertificate with SecretText data type for AccessToken, Certificate and CertificatePassword.', '25.0')]
    procedure AcquireTokenAndTokenCacheByAuthorizationCodeWithCertificate(AuthorizationCode: Text; ClientId: Text; Certificate: Text; CertificatePassword: SecretText; RedirectUrl: Text; OAuthAuthorityUrl: Text; Scopes: List of [Text]; var AccessToken: SecretText; var TokenCache: Text)
    var
        CertificateSecret: SecretText;
    begin
        CertificateSecret := Certificate;
        AcquireTokenAndTokenCacheByAuthorizationCodeWithCertificate(AuthorizationCode, ClientId, CertificateSecret, CertificatePassword, RedirectUrl, OAuthAuthorityUrl, Scopes, AccessToken, TokenCache);
    end;

    [TryFunction]
    [Obsolete('Use AcquireTokensAndTokenCacheByAuthorizationCodeWithCertificate with SecretText data type for AccessToken and Certificate.', '25.0')]
    procedure AcquireTokensAndTokenCacheByAuthorizationCodeWithCertificate(AuthorizationCode: Text; ClientId: Text; Certificate: Text; RedirectUrl: Text; OAuthAuthorityUrl: Text; Scopes: List of [Text]; var AccessToken: SecretText; var IdToken: Text; var TokenCache: Text)
    var
        CertificateSecret: SecretText;
        CertificatePassword: SecretText;
    begin
        CertificateSecret := Certificate;
        AcquireTokensAndTokenCacheByAuthorizationCodeWithCertificate(AuthorizationCode, ClientId, CertificateSecret, CertificatePassword, RedirectUrl, OAuthAuthorityUrl, Scopes, AccessToken, IdToken, TokenCache);
    end;

    [TryFunction]
    [Obsolete('Use AcquireTokensAndTokenCacheByAuthorizationCodeWithCertificate with SecretText data type for AccessToken, Certificate and CertificatePassword.', '25.0')]
    procedure AcquireTokensAndTokenCacheByAuthorizationCodeWithCertificate(AuthorizationCode: Text; ClientId: Text; Certificate: Text; CertificatePassword: SecretText; RedirectUrl: Text; OAuthAuthorityUrl: Text; Scopes: List of [Text]; var AccessToken: SecretText; var IdToken: Text; var TokenCache: Text)
    var
        CertificateSecret: SecretText;
    begin
        CertificateSecret := Certificate;
        AcquireTokensAndTokenCacheByAuthorizationCodeWithCertificate(AuthorizationCode, ClientId, CertificateSecret, CertificatePassword, RedirectUrl, OAuthAuthorityUrl, Scopes, AccessToken, IdToken, TokenCache);
    end;
#endif
    [TryFunction]
    procedure AcquireTokenByAuthorizationCode(ClientId: Text; ClientSecret: SecretText; OAuthAuthorityUrl: Text; RedirectURL: Text; ResourceUrl: Text; PromptInteraction: Enum "Prompt Interaction"; var AccessToken: SecretText; var AuthCodeErr: Text)
    var
        AuthRequestUrl: Text;
        AuthCode: Text;
        State: Text;
    begin
        Initialize(OAuthAuthorityUrl, RedirectURL);

        AuthRequestUrl := GetAuthRequestUrl(ClientId, OAuthAuthorityUrl, RedirectURL, State, ResourceUrl, PromptInteraction);

        SetPropertiesBasedOnAuthRequestUrlAndRunOAuth2ControlAddIn(AuthRequestUrl, State, AuthCode, AuthCodeErr);

        if StrPos(AuthCodeErr, PopupBlockedCodeErrLbl) > 0 then
            Error(PopupBlockedErr, ProductName.Short());

        if AuthCode = '' then
            exit;

        AcquireTokenByAuthorizationCodeWithCredentials(AuthCode, ClientId, ClientSecret, RedirectURL, OAuthAuthorityUrl, ResourceUrl, AccessToken);
    end;

    [TryFunction]
    procedure AcquireTokenByAuthorizationCodeWithCertificate(ClientId: Text; Certificate: SecretText; OAuthAuthorityUrl: Text; RedirectURL: Text; ResourceUrl: Text; PromptInteraction: Enum "Prompt Interaction"; var AccessToken: SecretText; var AuthCodeErr: Text)
    var
        CertificatePassword: SecretText;
    begin
        AcquireTokenByAuthorizationCodeWithCertificate(ClientId, Certificate, CertificatePassword, OAuthAuthorityUrl, RedirectURL, ResourceUrl, PromptInteraction, AccessToken, AuthCodeErr);
    end;

    [TryFunction]
    procedure AcquireTokenByAuthorizationCodeWithCertificate(ClientId: Text; Certificate: SecretText; CertificatePassword: SecretText; OAuthAuthorityUrl: Text; RedirectURL: Text; ResourceUrl: Text; PromptInteraction: Enum "Prompt Interaction"; var AccessToken: SecretText; var AuthCodeErr: Text)
    var
        AuthRequestUrl: Text;
        AuthCode: Text;
        State: Text;
    begin
        Initialize(OAuthAuthorityUrl, RedirectURL);

        AuthRequestUrl := GetAuthRequestUrl(ClientId, OAuthAuthorityUrl, RedirectURL, State, ResourceUrl, PromptInteraction);

        SetPropertiesBasedOnAuthRequestUrlAndRunOAuth2ControlAddIn(AuthRequestUrl, State, AuthCode, AuthCodeErr);

        if AuthCode = '' then
            exit;

        AcquireTokenByAuthorizationCodeWithCertificate(AuthCode, ClientId, Certificate, CertificatePassword, RedirectURL, OAuthAuthorityUrl, ResourceUrl, AccessToken);
    end;

    [TryFunction]
    procedure AcquireTokenByAuthorizationCode(ClientId: Text; ClientSecret: SecretText; OAuthAuthorityUrl: Text; RedirectURL: Text; Scopes: List of [Text]; PromptInteraction: Enum "Prompt Interaction"; var AccessToken: SecretText; var AuthCodeErr: Text)
    var
        AuthRequestUrl: Text;
        AuthCode: Text;
        State: Text;
    begin
        Initialize(OAuthAuthorityUrl, RedirectURL);

        AuthRequestUrl := GetAuthRequestUrl(ClientId, ClientSecret, OAuthAuthorityUrl, RedirectURL, State, Scopes, PromptInteraction);

        SetPropertiesBasedOnAuthRequestUrlAndRunOAuth2ControlAddIn(AuthRequestUrl, State, AuthCode, AuthCodeErr);

        if StrPos(AuthCodeErr, PopupBlockedCodeErrLbl) > 0 then
            Error(PopupBlockedErr, ProductName.Short());

        if AuthCode = '' then
            exit;

        AcquireTokenByAuthorizationCodeWithCredentials(AuthCode, ClientId, ClientSecret, RedirectURL, OAuthAuthorityUrl, Scopes, AccessToken);
    end;

    [TryFunction]
    procedure AcquireTokenByAuthorizationCodeWithCertificate(ClientId: Text; Certificate: SecretText; OAuthAuthorityUrl: Text; RedirectURL: Text; Scopes: List of [Text]; PromptInteraction: Enum "Prompt Interaction"; var AccessToken: SecretText; var AuthCodeErr: Text)
    var
        CertificatePassword: SecretText;
    begin
        AcquireTokenByAuthorizationCodeWithCertificate(ClientId, Certificate, CertificatePassword, OAuthAuthorityUrl, RedirectURL, Scopes, PromptInteraction, AccessToken, AuthCodeErr);
    end;

    [TryFunction]
    procedure AcquireTokenByAuthorizationCodeWithCertificate(ClientId: Text; Certificate: SecretText; CertificatePassword: SecretText; OAuthAuthorityUrl: Text; RedirectURL: Text; Scopes: List of [Text]; PromptInteraction: Enum "Prompt Interaction"; var AccessToken: SecretText; var AuthCodeErr: Text)
    var
        AuthRequestUrl: Text;
        AuthCode: Text;
        State: Text;
    begin
        Initialize(OAuthAuthorityUrl, RedirectURL);

        AuthRequestUrl := GetAuthRequestUrl(ClientId, Certificate, OAuthAuthorityUrl, RedirectURL, State, Scopes, PromptInteraction);

        SetPropertiesBasedOnAuthRequestUrlAndRunOAuth2ControlAddIn(AuthRequestUrl, State, AuthCode, AuthCodeErr);

        if AuthCode = '' then
            exit;

        AcquireTokenByAuthorizationCodeWithCertificate(AuthCode, ClientId, Certificate, CertificatePassword, RedirectURL, OAuthAuthorityUrl, Scopes, AccessToken);
    end;

    [TryFunction]
    procedure AcquireTokensByAuthorizationCode(ClientId: Text; ClientSecret: SecretText; OAuthAuthorityUrl: Text; RedirectURL: Text; Scopes: List of [Text]; PromptInteraction: Enum "Prompt Interaction"; var AccessToken: SecretText; var IdToken: Text; var AuthCodeErr: Text)
    var
        AuthRequestUrl: Text;
        AuthCode: Text;
        State: Text;
    begin
        Initialize(OAuthAuthorityUrl, RedirectURL);

        AuthRequestUrl := GetAuthRequestUrl(ClientId, ClientSecret, OAuthAuthorityUrl, RedirectURL, State, Scopes, PromptInteraction);

        SetPropertiesBasedOnAuthRequestUrlAndRunOAuth2ControlAddIn(AuthRequestUrl, State, AuthCode, AuthCodeErr);

        if AuthCode = '' then
            exit;

        AcquireTokensByAuthorizationCodeWithCredentials(AuthCode, ClientId, ClientSecret, RedirectURL, OAuthAuthorityUrl, Scopes, AccessToken, IdToken);
    end;

    [TryFunction]
    procedure AcquireTokensByAuthorizationCodeWithCertificate(ClientId: Text; Certificate: SecretText; OAuthAuthorityUrl: Text; RedirectURL: Text; Scopes: List of [Text]; PromptInteraction: Enum "Prompt Interaction"; var AccessToken: SecretText; var IdToken: Text; var AuthCodeErr: Text)
    var
        CertificatePassword: SecretText;
    begin
        AcquireTokensByAuthorizationCodeWithCertificate(ClientId, Certificate, CertificatePassword, OAuthAuthorityUrl, RedirectURL, Scopes, PromptInteraction, AccessToken, IdToken, AuthCodeErr);
    end;

    [TryFunction]
    procedure AcquireTokensByAuthorizationCodeWithCertificate(ClientId: Text; Certificate: SecretText; CertificatePassword: SecretText; OAuthAuthorityUrl: Text; RedirectURL: Text; Scopes: List of [Text]; PromptInteraction: Enum "Prompt Interaction"; var AccessToken: SecretText; var IdToken: Text; var AuthCodeErr: Text)
    var
        AuthRequestUrl: Text;
        AuthCode: Text;
        State: Text;
    begin
        Initialize(OAuthAuthorityUrl, RedirectURL);

        AuthRequestUrl := GetAuthRequestUrl(ClientId, Certificate, OAuthAuthorityUrl, RedirectURL, State, Scopes, PromptInteraction);

        SetPropertiesBasedOnAuthRequestUrlAndRunOAuth2ControlAddIn(AuthRequestUrl, State, AuthCode, AuthCodeErr);

        if AuthCode = '' then
            exit;

        AcquireTokensByAuthorizationCodeWithCertificate(AuthCode, ClientId, Certificate, CertificatePassword, RedirectURL, OAuthAuthorityUrl, Scopes, AccessToken, IdToken);
    end;

    [TryFunction]
    procedure AcquireTokenAndTokenCacheByAuthorizationCode(ClientId: Text; ClientSecret: SecretText; OAuthAuthorityUrl: Text; RedirectURL: Text; Scopes: List of [Text]; PromptInteraction: Enum "Prompt Interaction"; var AccessToken: SecretText; var TokenCache: Text; var Error: Text)
    var
        AuthRequestUrl: Text;
        AuthCode: Text;
        State: Text;
    begin
        Initialize(OAuthAuthorityUrl, RedirectURL);

        AuthRequestUrl := GetAuthRequestUrl(ClientId, ClientSecret, OAuthAuthorityUrl, RedirectURL, State, Scopes, PromptInteraction);

        SetPropertiesBasedOnAuthRequestUrlAndRunOAuth2ControlAddIn(AuthRequestUrl, State, AuthCode, Error);

        if AuthCode = '' then
            exit;

        AcquireTokenAndTokenCacheByAuthorizationCodeWithCredentials(AuthCode, ClientId, ClientSecret, RedirectURL, OAuthAuthorityUrl, Scopes, AccessToken, TokenCache);
    end;

    [TryFunction]
    procedure AcquireTokenAndTokenCacheByAuthorizationCodeWithCertificate(ClientId: Text; Certificate: SecretText; OAuthAuthorityUrl: Text; RedirectURL: Text; Scopes: List of [Text]; PromptInteraction: Enum "Prompt Interaction"; var AccessToken: SecretText; var TokenCache: Text; var Error: Text)
    var
        CertificatePassword: SecretText;
    begin
        AcquireTokenAndTokenCacheByAuthorizationCodeWithCertificate(ClientId, Certificate, CertificatePassword, OAuthAuthorityUrl, RedirectURL, Scopes, PromptInteraction, AccessToken, TokenCache, Error);
    end;

    [TryFunction]
    procedure AcquireTokenAndTokenCacheByAuthorizationCodeWithCertificate(ClientId: Text; Certificate: SecretText; CertificatePassword: SecretText; OAuthAuthorityUrl: Text; RedirectURL: Text; Scopes: List of [Text]; PromptInteraction: Enum "Prompt Interaction"; var AccessToken: SecretText; var TokenCache: Text; var Error: Text)
    var
        AuthRequestUrl: Text;
        AuthCode: Text;
        State: Text;
    begin
        Initialize(OAuthAuthorityUrl, RedirectURL);

        AuthRequestUrl := GetAuthRequestUrl(ClientId, Certificate, OAuthAuthorityUrl, RedirectURL, State, Scopes, PromptInteraction);

        SetPropertiesBasedOnAuthRequestUrlAndRunOAuth2ControlAddIn(AuthRequestUrl, State, AuthCode, Error);

        if AuthCode = '' then
            exit;

        AcquireTokenAndTokenCacheByAuthorizationCodeWithCertificate(AuthCode, ClientId, Certificate, CertificatePassword, RedirectURL, OAuthAuthorityUrl, Scopes, AccessToken, TokenCache);
    end;

    [TryFunction]
    procedure AcquireTokensAndTokenCacheByAuthorizationCode(ClientId: Text; ClientSecret: SecretText; OAuthAuthorityUrl: Text; RedirectURL: Text; Scopes: List of [Text]; PromptInteraction: Enum "Prompt Interaction"; var AccessToken: SecretText; var IdToken: Text; var TokenCache: Text; var Error: Text)
    var
        AuthRequestUrl: Text;
        AuthCode: Text;
        State: Text;
    begin
        Initialize(OAuthAuthorityUrl, RedirectURL);

        AuthRequestUrl := GetAuthRequestUrl(ClientId, ClientSecret, OAuthAuthorityUrl, RedirectURL, State, Scopes, PromptInteraction);

        SetPropertiesBasedOnAuthRequestUrlAndRunOAuth2ControlAddIn(AuthRequestUrl, State, AuthCode, Error);

        if AuthCode = '' then
            exit;

        AcquireTokensAndTokenCacheByAuthorizationCodeWithCredentials(AuthCode, ClientId, ClientSecret, RedirectURL, OAuthAuthorityUrl, Scopes, AccessToken, IdToken, TokenCache);
    end;

    [TryFunction]
    procedure AcquireTokensAndTokenCacheByAuthorizationCodeWithCertificate(ClientId: Text; Certificate: SecretText; OAuthAuthorityUrl: Text; RedirectURL: Text; Scopes: List of [Text]; PromptInteraction: Enum "Prompt Interaction"; var AccessToken: SecretText; var IdToken: Text; var TokenCache: Text; var Error: Text)
    var
        CertificatePassword: SecretText;
    begin
        AcquireTokensAndTokenCacheByAuthorizationCodeWithCertificate(ClientId, Certificate, CertificatePassword, OAuthAuthorityUrl, RedirectURL, Scopes, PromptInteraction, AccessToken, IdToken, TokenCache, Error);
    end;

    [TryFunction]
    procedure AcquireTokensAndTokenCacheByAuthorizationCodeWithCertificate(ClientId: Text; Certificate: SecretText; CertificatePassword: SecretText; OAuthAuthorityUrl: Text; RedirectURL: Text; Scopes: List of [Text]; PromptInteraction: Enum "Prompt Interaction"; var AccessToken: SecretText; var IdToken: Text; var TokenCache: Text; var Error: Text)
    var
        AuthRequestUrl: Text;
        AuthCode: Text;
        State: Text;
    begin
        Initialize(OAuthAuthorityUrl, RedirectURL);

        AuthRequestUrl := GetAuthRequestUrl(ClientId, Certificate, OAuthAuthorityUrl, RedirectURL, State, Scopes, PromptInteraction);

        SetPropertiesBasedOnAuthRequestUrlAndRunOAuth2ControlAddIn(AuthRequestUrl, State, AuthCode, Error);

        if AuthCode = '' then
            exit;

        AcquireTokensAndTokenCacheByAuthorizationCodeWithCertificate(AuthCode, ClientId, Certificate, CertificatePassword, RedirectURL, OAuthAuthorityUrl, Scopes, AccessToken, IdToken, TokenCache);
    end;

    [TryFunction]
    procedure SetPropertiesBasedOnAuthRequestUrlAndRunOAuth2ControlAddIn(AuthRequestUrl: Text; State: Text; var AuthCode: Text; var AuthCodeErr: Text)
    var
        OAuth2ControlAddIn: Page OAuth2ControlAddIn;
    begin
        if AuthRequestUrl = '' then begin
            AuthCode := '';
            exit;
        end;

        OAuth2ControlAddIn.SetOAuth2Properties(AuthRequestUrl, State);
        OAuth2ControlAddIn.RunModal();

        AuthCode := OAuth2ControlAddIn.GetAuthCode();
        AuthCodeErr := OAuth2ControlAddIn.GetAuthError();
    end;

    [TryFunction]
    procedure AcquireOnBehalfOfToken(RedirectURL: Text; ResourceUrl: Text; var AccessToken: SecretText)
    begin
        Initialize(RedirectURL);
        AccessToken := AuthFlow.ALAcquireOnBehalfOfToken(ResourceUrl);
    end;

    [TryFunction]
    procedure AcquireOnBehalfOfToken(RedirectURL: Text; Scopes: List of [Text]; var AccessToken: SecretText)
    var
        ScopesArray: DotNet StringArray;
    begin
        FillScopesArray(Scopes, ScopesArray);
        Initialize(RedirectURL);
        AccessToken := AuthFlow.ALAcquireOnBehalfOfToken(ScopesArray);
    end;

    [TryFunction]
    procedure AcquireOnBehalfOfTokens(RedirectURL: Text; Scopes: List of [Text]; var AccessToken: SecretText; var IdToken: Text)
    var
        ScopesArray: DotNet StringArray;
        CompoundToken: DotNet CompoundTokenInfo;
    begin
        FillScopesArray(Scopes, ScopesArray);
        Initialize(RedirectURL);
        CompoundToken := AuthFlow.ALAcquireOnBehalfOfTokens(ScopesArray);
        AccessToken := CompoundToken.AccessToken;
        IdToken := CompoundToken.IdToken;
    end;

    procedure AcquireOnBehalfAccessTokenAndTokenCache(OAuthAuthorityUrl: Text; RedirectURL: Text; ResourceUrl: Text; var AccessToken: SecretText; var RefreshToken: Text)
    begin
        Initialize(OAuthAuthorityUrl, RedirectURL);
        AccessToken := AuthFlow.ALAcquireOnBehalfOfToken(ResourceUrl, RefreshToken);
    end;

    procedure AcquireOnBehalfAccessTokenAndTokenCache(OAuthAuthorityUrl: Text; RedirectURL: Text; Scopes: List of [Text]; var AccessToken: SecretText; var RefreshToken: Text)
    var
        ScopesArray: DotNet StringArray;
    begin
        FillScopesArray(Scopes, ScopesArray);
        Initialize(OAuthAuthorityUrl, RedirectURL);
        AccessToken := AuthFlow.ALAcquireOnBehalfOfToken(ScopesArray, RefreshToken);
    end;

    procedure AcquireOnBehalfTokensAndTokenCache(OAuthAuthorityUrl: Text; RedirectURL: Text; Scopes: List of [Text]; var AccessToken: SecretText; var IdToken: Text; var RefreshToken: Text)
    var
        ScopesArray: DotNet StringArray;
        CompoundToken: DotNet CompoundTokenInfo;
    begin
        FillScopesArray(Scopes, ScopesArray);
        Initialize(OAuthAuthorityUrl, RedirectURL);
        CompoundToken := AuthFlow.ALAcquireOnBehalfOfTokens(ScopesArray, RefreshToken);
        AccessToken := CompoundToken.AccessToken;
        IdToken := CompoundToken.IdToken;
    end;

    procedure AcquireOnBehalfOfTokenByTokenCache(LoginHint: Text; RedirectURL: Text; ResourceURL: Text; RefreshToken: Text; var AccessToken: SecretText; var NewRefreshToken: Text)
    begin
        Initialize(RedirectURL);
        AccessToken := AuthFlow.ALAcquireTokenFromTokenCacheState(ResourceURL, LoginHint, RefreshToken, NewRefreshToken);
    end;

    procedure AcquireOnBehalfOfTokenByTokenCache(LoginHint: Text; RedirectURL: Text; Scopes: List of [Text]; RefreshToken: Text; var AccessToken: SecretText; var NewRefreshToken: Text)
    var
        ScopesArray: DotNet StringArray;
    begin
        FillScopesArray(Scopes, ScopesArray);
        Initialize(RedirectURL);
        AccessToken := AuthFlow.ALAcquireTokenFromTokenCacheState(ScopesArray, LoginHint, RefreshToken, NewRefreshToken);
    end;

    procedure AcquireOnBehalfOfTokensByTokenCache(LoginHint: Text; RedirectURL: Text; Scopes: List of [Text]; RefreshToken: Text; var AccessToken: SecretText; var IdToken: Text; var NewRefreshToken: Text)
    var
        ScopesArray: DotNet StringArray;
        CompoundToken: DotNet CompoundTokenInfo;
    begin
        FillScopesArray(Scopes, ScopesArray);
        Initialize(RedirectURL);
        CompoundToken := AuthFlow.ALAcquireTokensFromTokenCacheState(ScopesArray, LoginHint, RefreshToken, NewRefreshToken);
        AccessToken := CompoundToken.AccessToken;
        IdToken := CompoundToken.IdToken;
    end;

    procedure AcquireOnBehalfOfTokenByTokenCache(ClientId: Text; ClientSecret: SecretText; LoginHint: Text; RedirectURL: Text; Scopes: List of [Text]; TokenCache: Text; var AccessToken: SecretText; var NewTokenCache: Text)
    var
        ScopesArray: DotNet StringArray;
    begin
        FillScopesArray(Scopes, ScopesArray);
        Initialize(RedirectURL);
        AccessToken := AuthFlow.ALAcquireTokenFromTokenCacheState(ClientId, ClientSecret, ScopesArray, LoginHint, TokenCache, NewTokenCache);
    end;

    procedure AcquireOnBehalfOfTokensByTokenCache(ClientId: Text; ClientSecret: SecretText; LoginHint: Text; RedirectURL: Text; Scopes: List of [Text]; TokenCache: Text; var AccessToken: SecretText; var IdToken: Text; var NewTokenCache: Text)
    var
        ScopesArray: DotNet StringArray;
        CompoundToken: DotNet CompoundTokenInfo;
    begin
        FillScopesArray(Scopes, ScopesArray);
        Initialize(RedirectURL);
        CompoundToken := AuthFlow.ALAcquireTokensFromTokenCacheState(ClientId, ClientSecret, ScopesArray, LoginHint, TokenCache, NewTokenCache);
        AccessToken := CompoundToken.AccessToken;
        IdToken := CompoundToken.IdToken;
    end;

    [TryFunction]
    procedure AcquireTokenFromCache(RedirectURL: Text; ClientId: Text; ClientSecret: SecretText; OAuthAuthorityUrl: Text; ResourceURL: Text; var AccessToken: SecretText)
    begin
        Initialize(OAuthAuthorityUrl, RedirectURL);
        AccessToken := AuthFlow.ALAcquireTokenFromCacheWithCredentials(ClientId, ClientSecret, ResourceURL);
    end;

    [TryFunction]
    procedure AcquireTokenFromCacheWithCertificate(RedirectURL: Text; ClientId: Text; Certificate: SecretText; OAuthAuthorityUrl: Text; ResourceURL: Text; var AccessToken: SecretText)
    var
        CertificatePassword: SecretText;
    begin
        AcquireTokenFromCacheWithCertificate(RedirectURL, ClientId, Certificate, CertificatePassword, OAuthAuthorityUrl, ResourceURL, AccessToken);
    end;

    [TryFunction]
    procedure AcquireTokenFromCacheWithCertificate(RedirectURL: Text; ClientId: Text; Certificate: SecretText; CertificatePassword: SecretText; OAuthAuthorityUrl: Text; ResourceURL: Text; var AccessToken: SecretText)
    begin
        Initialize(OAuthAuthorityUrl, RedirectURL);
        AccessToken := AuthFlow.ALAcquireTokenFromCacheWithCertificate(ClientId, Certificate, CertificatePassword, ResourceURL);
    end;

    [TryFunction]
    procedure AcquireTokenFromCache(RedirectURL: Text; ClientId: Text; ClientSecret: SecretText; OAuthAuthorityUrl: Text; Scopes: List of [Text]; var AccessToken: SecretText)
    var
        ScopesArray: DotNet StringArray;
    begin
        FillScopesArray(Scopes, ScopesArray);
        Initialize(OAuthAuthorityUrl, RedirectURL);
        AccessToken := AuthFlow.ALAcquireTokenFromCacheWithCredentials(ClientId, ClientSecret, ScopesArray);
    end;

    [TryFunction]
    procedure AcquireTokenFromCacheWithCertificate(RedirectURL: Text; ClientId: Text; Certificate: SecretText; OAuthAuthorityUrl: Text; Scopes: List of [Text]; var AccessToken: SecretText)
    var
        CertificatePassword: SecretText;
    begin
        AcquireTokenFromCacheWithCertificate(RedirectURL, ClientId, Certificate, CertificatePassword, OAuthAuthorityUrl, Scopes, AccessToken);
    end;

    [TryFunction]
    procedure AcquireTokenFromCacheWithCertificate(RedirectURL: Text; ClientId: Text; Certificate: SecretText; CertificatePassword: SecretText; OAuthAuthorityUrl: Text; Scopes: List of [Text]; var AccessToken: SecretText)
    var
        ScopesArray: DotNet StringArray;
    begin
        FillScopesArray(Scopes, ScopesArray);
        Initialize(OAuthAuthorityUrl, RedirectURL);
        AccessToken := AuthFlow.ALAcquireTokenFromCacheWithCertificate(ClientId, Certificate, CertificatePassword, ScopesArray);
    end;

    [TryFunction]
    procedure AcquireTokensFromCache(RedirectURL: Text; ClientId: Text; ClientSecret: SecretText; OAuthAuthorityUrl: Text; Scopes: List of [Text]; var AccessToken: SecretText; var IdToken: Text)
    var
        ScopesArray: DotNet StringArray;
        CompoundToken: DotNet CompoundTokenInfo;
    begin
        FillScopesArray(Scopes, ScopesArray);
        Initialize(OAuthAuthorityUrl, RedirectURL);
        CompoundToken := AuthFlow.ALAcquireTokensFromCacheWithCredentials(ClientId, ClientSecret, ScopesArray);
        AccessToken := CompoundToken.AccessToken;
        IdToken := CompoundToken.IdToken;
    end;

    [TryFunction]
    procedure AcquireTokensFromCacheWithCertificate(RedirectURL: Text; ClientId: Text; Certificate: SecretText; OAuthAuthorityUrl: Text; Scopes: List of [Text]; var AccessToken: SecretText; var IdToken: Text)
    var
        CertificatePassword: SecretText;
    begin
        AcquireTokensFromCacheWithCertificate(RedirectURL, ClientId, Certificate, CertificatePassword, OAuthAuthorityUrl, Scopes, AccessToken, IdToken);
    end;

    [TryFunction]
    procedure AcquireTokensFromCacheWithCertificate(RedirectURL: Text; ClientId: Text; Certificate: SecretText; CertificatePassword: SecretText; OAuthAuthorityUrl: Text; Scopes: List of [Text]; var AccessToken: SecretText; var IdToken: Text)
    var
        ScopesArray: DotNet StringArray;
        CompoundToken: DotNet CompoundTokenInfo;
    begin
        FillScopesArray(Scopes, ScopesArray);
        Initialize(OAuthAuthorityUrl, RedirectURL);
        CompoundToken := AuthFlow.ALAcquireTokensFromCacheWithCertificate(ClientId, Certificate, CertificatePassword, ScopesArray);
        AccessToken := CompoundToken.AccessToken;
        IdToken := CompoundToken.IdToken;
    end;

    [TryFunction]
    procedure AcquireTokensWithCertificate(RedirectURL: Text; ClientId: Text; Certificate: SecretText; OAuthAuthorityUrl: Text; Scopes: List of [Text]; var AccessToken: SecretText; var IdToken: Text)
    var
        CertificatePassword: SecretText;
    begin
        AcquireTokensWithCertificate(RedirectURL, ClientId, Certificate, CertificatePassword, OAuthAuthorityUrl, Scopes, AccessToken, IdToken);
    end;

    [TryFunction]
    procedure AcquireTokensWithCertificate(RedirectURL: Text; ClientId: Text; Certificate: SecretText; CertificatePassword: SecretText; OAuthAuthorityUrl: Text; Scopes: List of [Text]; var AccessToken: SecretText; var IdToken: Text)
    var
        ScopesArray: DotNet StringArray;
        CompoundToken: DotNet CompoundTokenInfo;
    begin
        FillScopesArray(Scopes, ScopesArray);
        Initialize(OAuthAuthorityUrl, RedirectURL);
        CompoundToken := AuthFlow.ALAcquireApplicationTokensWithCertificate(ClientId, Certificate, CertificatePassword, OAuthAuthorityUrl, ScopesArray);
        AccessToken := CompoundToken.AccessToken;
        IdToken := CompoundToken.IdToken;
    end;

    [TryFunction]
    procedure AcquireTokenWithClientCredentials(ClientId: Text; ClientSecret: SecretText; OAuthAuthorityUrl: Text; RedirectURL: Text; ResourceURL: Text; var AccessToken: SecretText)
    begin
        Initialize(OAuthAuthorityUrl, RedirectURL);
        AccessToken := AuthFlow.ALAcquireApplicationToken(ClientId, ClientSecret, OAuthAuthorityUrl, ResourceURL);
        if AccessToken.IsEmpty() then
            Session.LogMessage('0000C23', EmptyAccessTokenClientCredsErr, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', Oauth2CategoryLbl);
    end;

    [TryFunction]
    procedure AcquireTokenWithClientCredentials(ClientId: Text; ClientSecret: SecretText; OAuthAuthorityUrl: Text; RedirectURL: Text; Scopes: List of [Text]; var AccessToken: SecretText)
    var
        ScopesArray: DotNet StringArray;
    begin
        FillScopesArray(Scopes, ScopesArray);
        Initialize(OAuthAuthorityUrl, RedirectURL);
        AccessToken := AuthFlow.ALAcquireApplicationToken(ClientId, ClientSecret, OAuthAuthorityUrl, ScopesArray);
        if AccessToken.IsEmpty() then
            Session.LogMessage('0000D1L', EmptyAccessTokenClientCredsErr, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', Oauth2CategoryLbl);
    end;

    [TryFunction]
    procedure AcquireTokenByAuthorizationCodeWithCredentials(AuthorizationCode: Text; ClientId: Text; ClientSecret: SecretText; RedirectUrl: Text; OAuthAuthorityUrl: Text; ResourceURL: Text; var AccessToken: SecretText)
    begin
        AccessToken := AuthFlow.ALAcquireTokenByAuthorizationCodeWithCredentials(AuthorizationCode, ClientId, ClientSecret, ResourceURL);
    end;

    [TryFunction]
    procedure AcquireTokenByAuthorizationCodeWithCertificate(AuthorizationCode: Text; ClientId: Text; Certificate: SecretText; RedirectUrl: Text; OAuthAuthorityUrl: Text; ResourceURL: Text; var AccessToken: SecretText)
    var
        CertificatePassword: SecretText;
    begin
        AcquireTokenByAuthorizationCodeWithCertificate(AuthorizationCode, ClientId, Certificate, CertificatePassword, RedirectUrl, OAuthAuthorityUrl, ResourceURL, AccessToken);
    end;

    [TryFunction]
    procedure AcquireTokenByAuthorizationCodeWithCertificate(AuthorizationCode: Text; ClientId: Text; Certificate: SecretText; CertificatePassword: SecretText; RedirectUrl: Text; OAuthAuthorityUrl: Text; ResourceURL: Text; var AccessToken: SecretText)
    begin
        AccessToken := AuthFlow.ALAcquireTokenByAuthorizationCodeWithCertificate(AuthorizationCode, ClientId, Certificate, CertificatePassword, ResourceURL);
    end;

    [TryFunction]
    procedure AcquireTokenByAuthorizationCodeWithCredentials(AuthorizationCode: Text; ClientId: Text; ClientSecret: SecretText; RedirectUrl: Text; OAuthAuthorityUrl: Text; Scopes: List of [Text]; var AccessToken: SecretText)
    var
        ScopesArray: DotNet StringArray;
    begin
        FillScopesArray(Scopes, ScopesArray);
        AccessToken := AuthFlow.ALAcquireTokenByAuthorizationCodeWithCredentials(AuthorizationCode, ClientId, ClientSecret, ScopesArray);
    end;

    [TryFunction]
    procedure AcquireTokenByAuthorizationCodeWithCertificate(AuthorizationCode: Text; ClientId: Text; Certificate: SecretText; RedirectUrl: Text; OAuthAuthorityUrl: Text; Scopes: List of [Text]; var AccessToken: SecretText)
    var
        CertificatePassword: SecretText;
    begin
        AcquireTokenByAuthorizationCodeWithCertificate(AuthorizationCode, ClientId, Certificate, CertificatePassword, RedirectUrl, OAuthAuthorityUrl, Scopes, AccessToken);
    end;

    [TryFunction]
    procedure AcquireTokenByAuthorizationCodeWithCertificate(AuthorizationCode: Text; ClientId: Text; Certificate: SecretText; CertificatePassword: SecretText; RedirectUrl: Text; OAuthAuthorityUrl: Text; Scopes: List of [Text]; var AccessToken: SecretText)
    var
        ScopesArray: DotNet StringArray;
    begin
        FillScopesArray(Scopes, ScopesArray);
        AccessToken := AuthFlow.ALAcquireTokenByAuthorizationCodeWithCertificate(AuthorizationCode, ClientId, Certificate, CertificatePassword, ScopesArray);
    end;

    [TryFunction]
    procedure AcquireTokensByAuthorizationCodeWithCredentials(AuthorizationCode: Text; ClientId: Text; ClientSecret: SecretText; RedirectUrl: Text; OAuthAuthorityUrl: Text; Scopes: List of [Text]; var AccessToken: SecretText; var IdToken: Text)
    var
        ScopesArray: DotNet StringArray;
        CompoundToken: DotNet CompoundTokenInfo;
    begin
        FillScopesArray(Scopes, ScopesArray);
        CompoundToken := AuthFlow.ALAcquireTokensByAuthorizationCodeWithCredentials(AuthorizationCode, ClientId, ClientSecret, ScopesArray);
        AccessToken := CompoundToken.AccessToken;
        IdToken := CompoundToken.IdToken;
    end;

    [TryFunction]
    procedure AcquireTokensByAuthorizationCodeWithCertificate(AuthorizationCode: Text; ClientId: Text; Certificate: SecretText; RedirectUrl: Text; OAuthAuthorityUrl: Text; Scopes: List of [Text]; var AccessToken: SecretText; var IdToken: Text)
    var
        CertificatePassword: SecretText;
    begin
        AcquireTokensByAuthorizationCodeWithCertificate(AuthorizationCode, ClientId, Certificate, CertificatePassword, RedirectUrl, OAuthAuthorityUrl, Scopes, AccessToken, IdToken);
    end;

    [TryFunction]
    procedure AcquireTokensByAuthorizationCodeWithCertificate(AuthorizationCode: Text; ClientId: Text; Certificate: SecretText; CertificatePassword: SecretText; RedirectUrl: Text; OAuthAuthorityUrl: Text; Scopes: List of [Text]; var AccessToken: SecretText; var IdToken: Text)
    var
        ScopesArray: DotNet StringArray;
        CompoundToken: DotNet CompoundTokenInfo;
    begin
        FillScopesArray(Scopes, ScopesArray);
        CompoundToken := AuthFlow.ALAcquireTokensByAuthorizationCodeWithCertificate(AuthorizationCode, ClientId, Certificate, CertificatePassword, ScopesArray);
        AccessToken := CompoundToken.AccessToken;
        IdToken := CompoundToken.IdToken;
    end;

    [TryFunction]
    procedure AcquireTokenAndTokenCacheByAuthorizationCodeWithCredentials(AuthorizationCode: Text; ClientId: Text; ClientSecret: SecretText; RedirectUrl: Text; OAuthAuthorityUrl: Text; Scopes: List of [Text]; var AccessToken: SecretText; var TokenCache: Text)
    var
        ScopesArray: DotNet StringArray;
    begin
        FillScopesArray(Scopes, ScopesArray);
        AccessToken := AuthFlow.ALAcquireTokenByAuthorizationCodeWithCredentials(AuthorizationCode, ClientId, ClientSecret, ScopesArray, TokenCache);
    end;

    [TryFunction]
    procedure AcquireTokenAndTokenCacheByAuthorizationCodeWithCertificate(AuthorizationCode: Text; ClientId: Text; Certificate: SecretText; RedirectUrl: Text; OAuthAuthorityUrl: Text; Scopes: List of [Text]; var AccessToken: SecretText; var TokenCache: Text)
    var
        CertificatePassword: SecretText;
    begin
        AcquireTokenAndTokenCacheByAuthorizationCodeWithCertificate(AuthorizationCode, ClientId, Certificate, CertificatePassword, RedirectUrl, OAuthAuthorityUrl, Scopes, AccessToken, TokenCache);
    end;

    [TryFunction]
    procedure AcquireTokenAndTokenCacheByAuthorizationCodeWithCertificate(AuthorizationCode: Text; ClientId: Text; Certificate: SecretText; CertificatePassword: SecretText; RedirectUrl: Text; OAuthAuthorityUrl: Text; Scopes: List of [Text]; var AccessToken: SecretText; var TokenCache: Text)
    var
        ScopesArray: DotNet StringArray;
    begin
        FillScopesArray(Scopes, ScopesArray);
        AccessToken := AuthFlow.ALAcquireTokenByAuthorizationCodeWithCertificate(AuthorizationCode, ClientId, Certificate, CertificatePassword, ScopesArray, TokenCache);
    end;

    [TryFunction]
    procedure AcquireTokensAndTokenCacheByAuthorizationCodeWithCredentials(AuthorizationCode: Text; ClientId: Text; ClientSecret: SecretText; RedirectUrl: Text; OAuthAuthorityUrl: Text; Scopes: List of [Text]; var AccessToken: SecretText; var IdToken: Text; var TokenCache: Text)
    var
        ScopesArray: DotNet StringArray;
        CompoundToken: DotNet CompoundTokenInfo;
    begin
        FillScopesArray(Scopes, ScopesArray);
        CompoundToken := AuthFlow.ALAcquireTokensByAuthorizationCodeWithCredentials(AuthorizationCode, ClientId, ClientSecret, ScopesArray, TokenCache);
        AccessToken := CompoundToken.AccessToken;
        IdToken := CompoundToken.IdToken;
    end;

    [TryFunction]
    procedure AcquireTokensAndTokenCacheByAuthorizationCodeWithCertificate(AuthorizationCode: Text; ClientId: Text; Certificate: SecretText; RedirectUrl: Text; OAuthAuthorityUrl: Text; Scopes: List of [Text]; var AccessToken: SecretText; var IdToken: Text; var TokenCache: Text)
    var
        CertificatePassword: SecretText;
    begin
        AcquireTokensAndTokenCacheByAuthorizationCodeWithCertificate(AuthorizationCode, ClientId, Certificate, CertificatePassword, RedirectUrl, OAuthAuthorityUrl, Scopes, AccessToken, IdToken, TokenCache);
    end;

    [TryFunction]
    procedure AcquireTokensAndTokenCacheByAuthorizationCodeWithCertificate(AuthorizationCode: Text; ClientId: Text; Certificate: SecretText; CertificatePassword: SecretText; RedirectUrl: Text; OAuthAuthorityUrl: Text; Scopes: List of [Text]; var AccessToken: SecretText; var IdToken: Text; var TokenCache: Text)
    var
        ScopesArray: DotNet StringArray;
        CompoundToken: DotNet CompoundTokenInfo;
    begin
        FillScopesArray(Scopes, ScopesArray);
        CompoundToken := AuthFlow.ALAcquireTokensByAuthorizationCodeWithCertificate(AuthorizationCode, ClientId, Certificate, CertificatePassword, ScopesArray, TokenCache);
        AccessToken := CompoundToken.AccessToken;
        IdToken := CompoundToken.IdToken;
    end;

    [TryFunction]
    procedure AcquireTokensWithUserCredentials(OAuthAuthorityUrl: Text; ClientId: Text; Scopes: List of [Text]; UserName: Text; Password: SecretText; var AccessToken: SecretText; var IdToken: Text)
    var
        ScopesArray: DotNet StringArray;
        CompoundToken: DotNet CompoundTokenInfo;
        RedirectUrl: Text;
        DashSecretText: SecretText;
        Dash: Text;
    begin
        Initialize(OAuthAuthorityUrl, RedirectUrl);
        FillScopesArray(Scopes, ScopesArray);
        Dash := '-';
        DashSecretText := Dash;
        CompoundToken := AuthFlow.ALAcquireTokenWithUserCredentials(ClientId, DashSecretText, ScopesArray, UserName, Password);
        AccessToken := CompoundToken.AccessToken;
        IdToken := CompoundToken.IdToken;
    end;

    [TryFunction]
    procedure AcquireTokensWithUserCredentials(OAuthAuthorityUrl: Text; Scopes: List of [Text]; UserName: Text; Credential: SecretText; var AccessToken: SecretText; var IdToken: Text)
    var
        ScopesArray: DotNet StringArray;
        CompoundToken: DotNet CompoundTokenInfo;
        RedirectUrl: Text;
    begin
        Initialize(OAuthAuthorityUrl, RedirectUrl);
        FillScopesArray(Scopes, ScopesArray);
        CompoundToken := AuthFlow.ALAcquireTokenWithUserCredentials(ScopesArray, UserName, Credential);
        AccessToken := CompoundToken.AccessToken;
        IdToken := CompoundToken.IdToken;
    end;

    [TryFunction]
    procedure AcquireAuthorizationCode(ClientId: Text; ClientSecret: SecretText; OAuthAuthorityUrl: Text; RedirectURL: Text; Scopes: List of [Text]; PromptInteraction: Enum "Prompt Interaction"; Audience: Text; var AuthCode: Text; var AuthCodeErr: Text)
    var
        AuthRequestUrl: Text;
        State: Text;
    begin
        Initialize(OAuthAuthorityUrl, RedirectURL);

        AuthRequestUrl := GetAuthRequestUrl(ClientId, ClientSecret, OAuthAuthorityUrl, RedirectURL, State, Scopes, PromptInteraction, Audience);

        SetPropertiesBasedOnAuthRequestUrlAndRunOAuth2ControlAddIn(AuthRequestUrl, State, AuthCode, AuthCodeErr);

        if StrPos(AuthCodeErr, PopupBlockedCodeErrLbl) > 0 then
            Error(PopupBlockedErr, ProductName.Short());
    end;

    [NonDebuggable]
    procedure GetClaims(JWT: SecretText) Result: JsonObject
    var
        Base64Convert: Codeunit "Base64 Convert";
        PlainTextJWT: Text;
        Base64Text: Text;
    begin
        if JWT.IsEmpty() then
            exit;
        PlainTextJWT := JWT.Unwrap();
        if PlainTextJWT.Split('.').Count() < 3 then
            exit;
        Base64Text := PlainTextJWT.Split('.').Get(2);
        Base64Text := Base64Text.Replace('-', '+').Replace('_', '/');
        if StrLen(Base64Text) mod 4 <> 0 then
            Base64Text := PadStr(Base64Text, StrLen(Base64Text) + (4 - StrLen(Base64Text) mod 4), '=');
        Result.ReadFrom(Base64Convert.FromBase64(Base64Text))
    end;

    procedure GetLastErrorMessage(): Text
    begin
        exit(AuthFlow.LastErrorMessage());
    end;

    local procedure Initialize(RedirectURL: Text)
    var
        Uri: DotNet Uri;
    begin
        if RedirectURL = '' then
            RedirectURL := GetDefaultRedirectUrl()
        else
            Session.LogMessage('0000C24', StrSubstNo(RedirectUrlTxt, RedirectURL), Verbosity::Normal, DataClassification::AccountData, TelemetryScope::ExtensionPublisher, 'Category', Oauth2CategoryLbl);

        AuthFlow := AuthFlow.ALAzureAdCodeGrantFlow(Uri.Uri(RedirectURL));
    end;

    local procedure Initialize(OAuthAuthorityUrl: Text; var RedirectURL: Text)
    var
        Uri: DotNet Uri;
    begin
        if RedirectURL = '' then
            RedirectURL := GetDefaultRedirectUrl()
        else
            Session.LogMessage('0000CXW', StrSubstNo(RedirectUrlTxt, RedirectURL), Verbosity::Normal, DataClassification::AccountData, TelemetryScope::ExtensionPublisher, 'Category', Oauth2CategoryLbl);

        AuthFlow := AuthFlow.ALAzureAdCodeGrantFlow(Uri.Uri(RedirectURL), Uri.Uri(OAuthAuthorityUrl));
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

    local procedure GetPropertyFromCode(CodeTxt: Text; Property: Text): Text
    var
        PosProperty: Integer;
        PosValue: Integer;
        PosEnd: Integer;
    begin
        PosProperty := StrPos(CodeTxt, Property);
        if PosProperty = 0 then
            exit('');
        PosValue := PosProperty + StrPos(CopyStr(CodeTxt, PosProperty), '=');
        PosEnd := PosValue + StrPos(CopyStr(CodeTxt, PosValue), '&');

        if PosEnd = PosValue then
            exit(CopyStr(CodeTxt, PosValue, StrLen(CodeTxt) - 1));
        exit(CopyStr(CodeTxt, PosValue, PosEnd - PosValue - 1));
    end;

    local procedure FillScopesArray(Scopes: List of [Text]; var Result: DotNet StringArray)
    var
        TempString: DotNet String;
        Scope: Text;
        Index: Integer;
    begin
        TempString := '';
        Result := Result.CreateInstance(TempString.GetType(), Scopes.Count);
        Index := 0;
        foreach Scope in Scopes do begin
            Result.SetValue(Scope, Index);
            Index += 1;
        end;
    end;
}
