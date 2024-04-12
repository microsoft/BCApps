// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Security.Authentication;

/// <summary>
/// Contains methods supporting authentication via OAuth 2.0 protocol.
/// </summary>
codeunit 501 OAuth2
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        [NonDebuggable]
        OAuth2Impl: Codeunit OAuth2Impl;

#pragma warning disable AS0105
    /// <summary>
    /// Gets the authorization token based on the authorization code via the OAuth2 v1.0 code grant flow.
    /// </summary>
    /// <param name="ClientId">The Application (client) ID that the "Azure portal – App registrations" experience assigned to your app.</param>
    /// <param name="Certificate">The Base64-encoded certificate for the Application (client) configured in the "Azure Portal - Certificates &amp; Secrets".</param>
    /// <param name="OAuthAuthorityUrl">The identity authorization provider URL.</param>
    /// <param name="RedirectURL">The redirectURL of your app, where authentication responses can be sent and received by your app. It must exactly match one of the redirectURLs you registered in the portal. If this parameter is empty, the default Business Central URL will be used.</param>
    /// <param name="ResourceURL">The Application ID of the resource the application is requesting access to. This parameter can be empty.</param>
    /// <param name="PromptInteraction">Indicates the type of user interaction that is required.</param>
    /// <param name="AccessToken">Exit parameter containing the access token. When this parameter is empty, check the AuthCodeErr for a description of the error.</param>
    /// <param name="AuthCodeErr">Exit parameter containing the encountered error in the authorization code grant flow. This parameter will be empty in case the token is aquired successfuly.</param>
    [NonDebuggable]
    [TryFunction]
    [Obsolete('Use AcquireTokenByAuthorizationCodeWithCertificate with SecretText data type for AccessToken.', '24.0')]
    procedure AcquireTokenByAuthorizationCodeWithCertificate(ClientId: Text; Certificate: Text; OAuthAuthorityUrl: Text; RedirectURL: Text; ResourceURL: Text; PromptInteraction: Enum "Prompt Interaction"; var AccessToken: Text; var AuthCodeErr: Text)
    begin
#pragma warning disable AL0432
        OAuth2Impl.AcquireTokenByAuthorizationCodeWithCertificate(ClientId, Certificate, OAuthAuthorityUrl, RedirectURL, ResourceURL, PromptInteraction, AccessToken, AuthCodeErr);
#pragma warning restore AL0432
    end;

    /// <summary>
    /// Gets the authorization token based on the authorization code via the OAuth2 v2.0 code grant flow.
    /// </summary>
    /// <param name="ClientId">The Application (client) ID that the "Azure portal – App registrations" experience assigned to your app.</param>
    /// <param name="ClientSecret">The Application (client) secret configured in the "Azure Portal - Certificates &amp; Secrets".</param>
    /// <param name="OAuthAuthorityUrl">The identity authorization provider URL.</param>
    /// <param name="RedirectURL">The redirectURL of your app, where authentication responses can be sent and received by your app. It must exactly match one of the redirectURLs you registered in the portal. If this parameter is empty, the default Business Central URL will be used.</param>
    /// <param name="Scopes">A list of scopes that you want the user to consent to.</param>
    /// <param name="PromptInteraction">Indicates the type of user interaction that is required.</param>
    /// <param name="AccessToken">Exit parameter containing the access token. When this parameter is empty, check the AuthCodeErr for a description of the error.</param>
    /// <param name="AuthCodeErr">Exit parameter containing the encountered error in the authorization code grant flow. This parameter will be empty in case the token is aquired successfuly.</param>
    [NonDebuggable]
    [TryFunction]
    [Obsolete('Use AcquireTokenByAuthorizationCode with SecretText data type for AccessToken.', '24.0')]
    procedure AcquireTokenByAuthorizationCode(ClientId: Text; ClientSecret: Text; OAuthAuthorityUrl: Text; RedirectURL: Text; Scopes: List of [Text]; PromptInteraction: Enum "Prompt Interaction"; var AccessToken: Text; var AuthCodeErr: Text)
    begin
#pragma warning disable AL0432
        OAuth2Impl.AcquireTokenByAuthorizationCode(ClientId, ClientSecret, OAuthAuthorityUrl, RedirectURL, Scopes, PromptInteraction, AccessToken, AuthCodeErr);
#pragma warning restore AL0432
    end;

    /// <summary>
    /// Gets the authorization token based on the authorization code via the OAuth2 v2.0 code grant flow.
    /// </summary>
    /// <param name="ClientId">The Application (client) ID that the "Azure portal – App registrations" experience assigned to your app.</param>
    /// <param name="Certificate">The Base64-encoded certificate for the application (client) configured in the "Azure Portal - Certificates &amp; Secrets".</param>
    /// <param name="OAuthAuthorityUrl">The identity authorization provider URL.</param>
    /// <param name="RedirectURL">The redirectURL of your app, where authentication responses can be sent and received by your app. It must exactly match one of the redirectURLs you registered in the portal. If this parameter is empty, the default Business Central URL will be used.</param>
    /// <param name="Scopes">A list of scopes that you want the user to consent to.</param>
    /// <param name="PromptInteraction">Indicates the type of user interaction that is required.</param>
    /// <param name="AccessToken">Exit parameter containing the access token. When this parameter is empty, check the AuthCodeErr for a description of the error.</param>
    /// <param name="AuthCodeErr">Exit parameter containing the encountered error in the authorization code grant flow. This parameter will be empty in case the token is aquired successfuly.</param>
    [NonDebuggable]
    [TryFunction]
    [Obsolete('Use AcquireTokenByAuthorizationCodeWithCertificate with SecretText data type for AccessToken.', '24.0')]
    procedure AcquireTokenByAuthorizationCodeWithCertificate(ClientId: Text; Certificate: Text; OAuthAuthorityUrl: Text; RedirectURL: Text; Scopes: List of [Text]; PromptInteraction: Enum "Prompt Interaction"; var AccessToken: Text; var AuthCodeErr: Text)
    begin
#pragma warning disable AL0432
        OAuth2Impl.AcquireTokenByAuthorizationCodeWithCertificate(ClientId, Certificate, OAuthAuthorityUrl, RedirectURL, Scopes, PromptInteraction, AccessToken, AuthCodeErr);
#pragma warning restore AL0432
    end;

    /// <summary>
    /// Gets the authorization token based on the authorization code via the OAuth2 v2.0 code grant flow.
    /// </summary>
    /// <param name="ClientId">The Application (client) ID that the "Azure portal – App registrations" experience assigned to your app.</param>
    /// <param name="ClientSecret">The Application (client) secret configured in the "Azure Portal - Certificates &amp; Secrets".</param>
    /// <param name="OAuthAuthorityUrl">The identity authorization provider URL.</param>
    /// <param name="RedirectURL">The redirectURL of your app, where authentication responses can be sent and received by your app. It must exactly match one of the redirectURLs you registered in the portal. If this parameter is empty, the default Business Central URL will be used.</param>
    /// <param name="Scopes">A list of scopes that you want the user to consent to.</param>
    /// <param name="PromptInteraction">Indicates the type of user interaction that is required.</param>
    /// <param name="AccessToken">Exit parameter containing the access token. When this parameter is empty, check the AuthCodeErr for a description of the error.</param>
    /// <param name="IdToken">Exit parameter containing the id token.</param>
    /// <param name="AuthCodeErr">Exit parameter containing the encountered error in the authorization code grant flow. This parameter will be empty in case the token is aquired successfuly.</param>
    [NonDebuggable]
    [TryFunction]
    [Obsolete('Use AcquireTokensByAuthorizationCode with SecretText data type for AccessToken.', '24.0')]
    procedure AcquireTokensByAuthorizationCode(ClientId: Text; ClientSecret: Text; OAuthAuthorityUrl: Text; RedirectURL: Text; Scopes: List of [Text]; PromptInteraction: Enum "Prompt Interaction"; var AccessToken: Text; var IdToken: Text; var AuthCodeErr: Text)
    begin
#pragma warning disable AL0432
        OAuth2Impl.AcquireTokensByAuthorizationCode(ClientId, ClientSecret, OAuthAuthorityUrl, RedirectURL, Scopes, PromptInteraction, AccessToken, IdToken, AuthCodeErr);
#pragma warning restore AL0432
    end;

    /// <summary>
    /// Gets the authorization token based on the authorization code via the OAuth2 v2.0 code grant flow.
    /// </summary>
    /// <param name="ClientId">The Application (client) ID that the "Azure portal – App registrations" experience assigned to your app.</param>
    /// <param name="Certificate">The Base64-encoded certificate for the application (client) configured in the "Azure Portal - Certificates &amp; Secrets".</param>
    /// <param name="OAuthAuthorityUrl">The identity authorization provider URL.</param>
    /// <param name="RedirectURL">The redirectURL of your app, where authentication responses can be sent and received by your app. It must exactly match one of the redirectURLs you registered in the portal. If this parameter is empty, the default Business Central URL will be used.</param>
    /// <param name="Scopes">A list of scopes that you want the user to consent to.</param>
    /// <param name="PromptInteraction">Indicates the type of user interaction that is required.</param>
    /// <param name="AccessToken">Exit parameter containing the access token. When this parameter is empty, check the AuthCodeErr for a description of the error.</param>
    /// <param name="IdToken">Exit parameter containing the id token.</param>
    /// <param name="AuthCodeErr">Exit parameter containing the encountered error in the authorization code grant flow. This parameter will be empty in case the token is aquired successfuly.</param>
    [NonDebuggable]
    [TryFunction]
    [Obsolete('Use AcquireTokensByAuthorizationCodeWithCertificate with SecretText data type for AccessToken.', '24.0')]
    procedure AcquireTokensByAuthorizationCodeWithCertificate(ClientId: Text; Certificate: Text; OAuthAuthorityUrl: Text; RedirectURL: Text; Scopes: List of [Text]; PromptInteraction: Enum "Prompt Interaction"; var AccessToken: Text; var IdToken: Text; var AuthCodeErr: Text)
    begin
#pragma warning disable AL0432
        OAuth2Impl.AcquireTokensByAuthorizationCodeWithCertificate(ClientId, Certificate, OAuthAuthorityUrl, RedirectURL, Scopes, PromptInteraction, AccessToken, IdToken, AuthCodeErr);
#pragma warning restore AL0432
    end;

    /// <summary>
    /// Gets the access token and token cache state with authorization code flow.
    /// </summary>
    /// <param name="ClientId">The Application (client) ID that the "Azure portal – App registrations" experience assigned to your app.</param>
    /// <param name="ClientSecret">The Application (client) secret configured in the "Azure Portal - Certificates &amp; Secrets".</param>
    /// <param name="OAuthAuthorityUrl">The identity authorization provider URL.</param>
    /// <param name="RedirectURL">The redirectURL of your app, where authentication responses can be sent and received by your app. It must exactly match one of the redirectURLs you registered in the portal. If this parameter is empty, the default Business Central URL will be used.</param>
    /// <param name="Scopes">A list of scopes that you want the user to consent to.</param>
    /// <param name="PromptInteraction">Indicates the type of user interaction that is required.</param>
    /// <param name="AccessToken">Exit parameter containing the access token. When this parameter is empty, check the Error for a description of the error.</param>
    /// <param name="TokenCache">Exit parameter containing the token cache acquired when the access token was requested.</param>
    /// <param name="Error">Exit parameter containing the encountered error in the authorization code grant flow. This parameter will be empty in case the token is aquired successfuly.</param>
    [NonDebuggable]
    [TryFunction]
    [Obsolete('Use AcquireTokenAndTokenCacheByAuthorizationCode with SecretText data type for AccessToken.', '24.0')]
    procedure AcquireTokenAndTokenCacheByAuthorizationCode(ClientId: Text; ClientSecret: Text; OAuthAuthorityUrl: Text; RedirectURL: Text; Scopes: List of [Text]; PromptInteraction: Enum "Prompt Interaction"; var AccessToken: Text; var TokenCache: Text; var Error: Text)
    begin
#pragma warning disable AL0432
        OAuth2Impl.AcquireTokenAndTokenCacheByAuthorizationCode(ClientId, ClientSecret, OAuthAuthorityUrl, RedirectURL, Scopes, PromptInteraction, AccessToken, TokenCache, Error);
#pragma warning restore AL0432
    end;

    /// <summary>
    /// Gets the access token and token cache state with authorization code flow.
    /// </summary>
    /// <param name="ClientId">The Application (client) ID that the "Azure portal – App registrations" experience assigned to your app.</param>
    /// <param name="Certificate">The Base64-encoded certificate for the application (client) configured in the "Azure Portal - Certificates &amp; Secrets".</param>
    /// <param name="OAuthAuthorityUrl">The identity authorization provider URL.</param>
    /// <param name="RedirectURL">The redirectURL of your app, where authentication responses can be sent and received by your app. It must exactly match one of the redirectURLs you registered in the portal. If this parameter is empty, the default Business Central URL will be used.</param>
    /// <param name="Scopes">A list of scopes that you want the user to consent to.</param>
    /// <param name="PromptInteraction">Indicates the type of user interaction that is required.</param>
    /// <param name="AccessToken">Exit parameter containing the access token. When this parameter is empty, check the Error for a description of the error.</param>
    /// <param name="TokenCache">Exit parameter containing the token cache acquired when the access token was requested.</param>
    /// <param name="Error">Exit parameter containing the encountered error in the authorization code grant flow. This parameter will be empty in case the token is aquired successfuly.</param>
    [NonDebuggable]
    [TryFunction]
    [Obsolete('Use AcquireTokenAndTokenCacheByAuthorizationCodeWithCertificate with SecretText data type for AccessToken.', '24.0')]
    procedure AcquireTokenAndTokenCacheByAuthorizationCodeWithCertificate(ClientId: Text; Certificate: Text; OAuthAuthorityUrl: Text; RedirectURL: Text; Scopes: List of [Text]; PromptInteraction: Enum "Prompt Interaction"; var AccessToken: Text; var TokenCache: Text; var Error: Text)
    begin
#pragma warning disable AL0432
        OAuth2Impl.AcquireTokenAndTokenCacheByAuthorizationCodeWithCertificate(ClientId, Certificate, OAuthAuthorityUrl, RedirectURL, Scopes, PromptInteraction, AccessToken, TokenCache, Error);
#pragma warning restore AL0432
    end;

    /// <summary>
    /// Gets the access token and token cache state with authorization code flow.
    /// </summary>
    /// <param name="ClientId">The Application (client) ID that the "Azure portal – App registrations" experience assigned to your app.</param>
    /// <param name="ClientSecret">The Application (client) secret configured in the "Azure Portal - Certificates &amp; Secrets".</param>
    /// <param name="OAuthAuthorityUrl">The identity authorization provider URL.</param>
    /// <param name="RedirectURL">The redirectURL of your app, where authentication responses can be sent and received by your app. It must exactly match one of the redirectURLs you registered in the portal. If this parameter is empty, the default Business Central URL will be used.</param>
    /// <param name="Scopes">A list of scopes that you want the user to consent to.</param>
    /// <param name="PromptInteraction">Indicates the type of user interaction that is required.</param>
    /// <param name="AccessToken">Exit parameter containing the access token. When this parameter is empty, check the Error for a description of the error.</param>
    /// <param name="IdToken">Exit parameter containing the id token.</param>
    /// <param name="TokenCache">Exit parameter containing the token cache acquired when the access token was requested.</param>
    /// <param name="Error">Exit parameter containing the encountered error in the authorization code grant flow. This parameter will be empty in case the token is aquired successfuly.</param>
    [NonDebuggable]
    [TryFunction]
    [Obsolete('Use AcquireTokensAndTokenCacheByAuthorizationCode with SecretText data type for AccessToken.', '24.0')]
    procedure AcquireTokensAndTokenCacheByAuthorizationCode(ClientId: Text; ClientSecret: Text; OAuthAuthorityUrl: Text; RedirectURL: Text; Scopes: List of [Text]; PromptInteraction: Enum "Prompt Interaction"; var AccessToken: Text; var IdToken: Text; var TokenCache: Text; var Error: Text)
    begin
#pragma warning disable AL0432
        OAuth2Impl.AcquireTokensAndTokenCacheByAuthorizationCode(ClientId, ClientSecret, OAuthAuthorityUrl, RedirectURL, Scopes, PromptInteraction, AccessToken, IdToken, TokenCache, Error);
#pragma warning restore AL0432
    end;

    /// <summary>
    /// Gets the access token and token cache state with authorization code flow.
    /// </summary>
    /// <param name="ClientId">The Application (client) ID that the "Azure portal – App registrations" experience assigned to your app.</param>
    /// <param name="Certificate">The Base64-encoded certificate for the application (client) configured in the "Azure Portal - Certificates &amp; Secrets".</param>
    /// <param name="OAuthAuthorityUrl">The identity authorization provider URL.</param>
    /// <param name="RedirectURL">The redirectURL of your app, where authentication responses can be sent and received by your app. It must exactly match one of the redirectURLs you registered in the portal. If this parameter is empty, the default Business Central URL will be used.</param>
    /// <param name="Scopes">A list of scopes that you want the user to consent to.</param>
    /// <param name="PromptInteraction">Indicates the type of user interaction that is required.</param>
    /// <param name="AccessToken">Exit parameter containing the access token. When this parameter is empty, check the Error for a description of the error.</param>
    /// <param name="IdToken">Exit parameter containing the id token.</param>
    /// <param name="TokenCache">Exit parameter containing the token cache acquired when the access token was requested.</param>
    /// <param name="Error">Exit parameter containing the encountered error in the authorization code grant flow. This parameter will be empty in case the token is aquired successfuly.</param>
    [NonDebuggable]
    [TryFunction]
    [Obsolete('Use AcquireTokensAndTokenCacheByAuthorizationCodeWithCertificate with SecretText data type for AccessToken.', '24.0')]
    procedure AcquireTokensAndTokenCacheByAuthorizationCodeWithCertificate(ClientId: Text; Certificate: Text; OAuthAuthorityUrl: Text; RedirectURL: Text; Scopes: List of [Text]; PromptInteraction: Enum "Prompt Interaction"; var AccessToken: Text; var IdToken: Text; var TokenCache: Text; var Error: Text)
    begin
#pragma warning disable AL0432
        OAuth2Impl.AcquireTokensAndTokenCacheByAuthorizationCodeWithCertificate(ClientId, Certificate, OAuthAuthorityUrl, RedirectURL, Scopes, PromptInteraction, AccessToken, IdToken, TokenCache, Error);
#pragma warning restore AL0432
    end;

    /// <summary>
    /// Gets the authentication token via the On-Behalf-Of OAuth2 v2.0 protocol flow.
    /// </summary>
    /// <param name="RedirectURL">The redirectURL of your app, where authentication responses can be sent and received by your app. It must exactly match one of the redirectURLs you registered in the portal. If this parameter is empty, the default Business Central URL will be used.</param>
    /// <param name="Scopes">A list of scopes that you want the user to consent to.</param>
    /// <param name="AccessToken">Exit parameter containing the access token.</param>
    [NonDebuggable]
    [Scope('OnPrem')]
    [TryFunction]
    [Obsolete('Use AcquireOnBehalfOfToken with SecretText data type for AccessToken.', '24.0')]
    procedure AcquireOnBehalfOfToken(RedirectURL: Text; Scopes: List of [Text]; var AccessToken: Text)
    begin
#pragma warning disable AL0432
        OAuth2Impl.AcquireOnBehalfOfToken(RedirectURL, Scopes, AccessToken);
#pragma warning restore AL0432
    end;

    /// <summary>
    /// Gets the authentication token via the On-Behalf-Of OAuth2 v2.0 protocol flow.
    /// </summary>
    /// <param name="RedirectURL">The redirectURL of your app, where authentication responses can be sent and received by your app. It must exactly match one of the redirectURLs you registered in the portal. If this parameter is empty, the default Business Central URL will be used.</param>
    /// <param name="Scopes">A list of scopes that you want the user to consent to.</param>
    /// <param name="AccessToken">Exit parameter containing the access token.</param>
    /// <param name="IdToken">Exit parameter containing the id token.</param>
    [NonDebuggable]
    [Scope('OnPrem')]
    [TryFunction]
    [Obsolete('Use AcquireOnBehalfOfTokens with SecretText data type for AccessToken.', '24.0')]
    procedure AcquireOnBehalfOfTokens(RedirectURL: Text; Scopes: List of [Text]; var AccessToken: Text; var IdToken: Text)
    begin
#pragma warning disable AL0432
        OAuth2Impl.AcquireOnBehalfOfTokens(RedirectURL, Scopes, AccessToken, IdToken);
#pragma warning restore AL0432
    end;

    /// <summary>
    /// Gets the access token via the Client Credentials OAuth2 v1.0 grant flow.
    /// </summary>
    /// <param name="ClientId">The Application (client) ID that the Azure portal – App registrations experience assigned to your app.</param>
    /// <param name="ClientSecret">The Application (client) secret configured in the Azure Portal - Certificates &amp; Secrets.</param>
    /// <param name="OAuthAuthorityUrl">The identity authorization provider URL.</param>
    /// <param name="RedirectURL">The redirectURL of your app, where authentication responses can be sent and received by your app. It must exactly match one of the redirectURLs you registered in the portal. If this parameter is empty, the default Business Central URL will be used.</param>
    /// <param name="ResourceURL">The Application ID of the resource the application is requesting access to. This parameter can be empty.</param>
    /// <param name="AccessToken">Exit parameter containing the access token.</param>
    [NonDebuggable]
    [TryFunction]
    [Obsolete('Use AcquireTokenWithClientCredentials with SecretText data type for AccessToken.', '24.0')]
    procedure AcquireTokenWithClientCredentials(ClientId: Text; ClientSecret: Text; OAuthAuthorityUrl: Text; RedirectURL: Text; ResourceURL: Text; var AccessToken: Text)
    begin
#pragma warning disable AL0432
        OAuth2Impl.AcquireTokenWithClientCredentials(ClientId, ClientSecret, OAuthAuthorityUrl, RedirectURL, ResourceURL, AccessToken);
#pragma warning restore AL0432
    end;

    /// <summary>
    /// Gets the access token via the Client Credentials OAuth2 v2.0 grant flow.
    /// </summary>
    /// <param name="ClientId">The Application (client) ID that the Azure portal – App registrations experience assigned to your app.</param>
    /// <param name="ClientSecret">The Application (client) secret configured in the Azure Portal - Certificates &amp; Secrets.</param>
    /// <param name="OAuthAuthorityUrl">The identity authorization provider URL.</param>
    /// <param name="RedirectURL">The redirectURL of your app, where authentication responses can be sent and received by your app. It must exactly match one of the redirectURLs you registered in the portal. If this parameter is empty, the default Business Central URL will be used.</param>
    /// <param name="Scopes">A list of scopes that you want the user to consent to.</param>
    /// <param name="AccessToken">Exit parameter containing the access token.</param>
    [NonDebuggable]
    [TryFunction]
    [Obsolete('Use AcquireTokenWithClientCredentials with SecretText data type for AccessToken.', '24.0')]
    procedure AcquireTokenWithClientCredentials(ClientId: Text; ClientSecret: Text; OAuthAuthorityUrl: Text; RedirectURL: Text; Scopes: List of [Text]; var AccessToken: Text)
    begin
#pragma warning disable AL0432
        OAuth2Impl.AcquireTokenWithClientCredentials(ClientId, ClientSecret, OAuthAuthorityUrl, RedirectURL, Scopes, AccessToken);
#pragma warning restore AL0432
    end;

    /// <summary>
    /// Gets the access token from cache or a refreshed token via OAuth2 v1.0 protocol.
    /// </summary>
    /// <param name="ClientId">The Application (client) ID that the Azure portal – App registrations experience assigned to your app.</param>
    /// <param name="Certificate">The Base64-encoded certificate for the Application (client) configured in the Azure Portal - Certificates &amp; Secrets.</param>
    /// <param name="RedirectURL">The redirectURL of your app, where authentication responses can be sent and received by your app. It must exactly match one of the redirectURLs you registered in the portal. If this parameter is empty, the default Business Central URL will be used.</param>
    /// <param name="OAuthAuthorityUrl">The identity authorization provider URL.</param>
    /// <param name="ResourceURL">The Application ID of the resource the application is requesting access to. This parameter can be empty.</param>
    /// <param name="AccessToken">Exit parameter containing the access token.</param>
    [NonDebuggable]
    [TryFunction]
    [Obsolete('Use AcquireAuthorizationCodeTokenFromCacheWithCertificate with SecretText data type for AccessToken.', '24.0')]
    procedure AcquireAuthorizationCodeTokenFromCacheWithCertificate(ClientId: Text; Certificate: Text; RedirectURL: Text; OAuthAuthorityUrl: Text; ResourceURL: Text; var AccessToken: Text)
    begin
#pragma warning disable AL0432
        OAuth2Impl.AcquireTokenFromCacheWithCertificate(RedirectURL, ClientId, Certificate, OAuthAuthorityUrl, ResourceURL, AccessToken);
#pragma warning restore AL0432
    end;

    /// <summary>
    /// Gets the access token from cache or a refreshed token via OAuth2 v2.0 protocol.
    /// </summary>
    /// <param name="ClientId">The Application (client) ID that the Azure portal – App registrations experience assigned to your app.</param>
    /// <param name="ClientSecret">The Application (client) secret configured in the Azure Portal - Certificates &amp; Secrets.</param>
    /// <param name="RedirectURL">The redirectURL of your app, where authentication responses can be sent and received by your app. It must exactly match one of the redirectURLs you registered in the portal. If this parameter is empty, the default Business Central URL will be used.</param>
    /// <param name="Scopes">A list of scopes that you want the user to consent to.</param>
    /// <param name="AccessToken">Exit parameter containing the access token.</param>
    [NonDebuggable]
    [TryFunction]
    [Obsolete('Use AcquireAuthorizationCodeTokenFromCache with SecretText data type for AccessToken.', '24.0')]
    procedure AcquireAuthorizationCodeTokenFromCache(ClientId: Text; ClientSecret: Text; RedirectURL: Text; OAuthAuthorityUrl: Text; Scopes: List of [Text]; var AccessToken: Text)
    begin
#pragma warning disable AL0432
        OAuth2Impl.AcquireTokenFromCache(RedirectURL, ClientId, ClientSecret, OAuthAuthorityUrl, Scopes, AccessToken);
#pragma warning restore AL0432
    end;

    /// <summary>
    /// Gets the access token from cache or a refreshed token via OAuth2 v2.0 protocol.
    /// </summary>
    /// <param name="ClientId">The Application (client) ID that the Azure portal – App registrations experience assigned to your app.</param>
    /// <param name="ClientSecret">The Application (client) secret configured in the Azure Portal - Certificates &amp; Secrets.</param>
    /// <param name="RedirectURL">The redirectURL of your app, where authentication responses can be sent and received by your app. It must exactly match one of the redirectURLs you registered in the portal. If this parameter is empty, the default Business Central URL will be used.</param>
    /// <param name="Scopes">A list of scopes that you want the user to consent to.</param>
    /// <param name="AccessToken">Exit parameter containing the access token.</param>
    /// <param name="IdToken">Exit parameter containing the id token.</param>
    [NonDebuggable]
    [TryFunction]
    [Obsolete('Use AcquireTokensFromCache with SecretText data type for AccessToken.', '24.0')]
    procedure AcquireTokensFromCache(ClientId: Text; ClientSecret: Text; RedirectURL: Text; OAuthAuthorityUrl: Text; Scopes: List of [Text]; var AccessToken: Text; var IdToken: Text)
    begin
#pragma warning disable AL0432
        OAuth2Impl.AcquireTokensFromCache(RedirectURL, ClientId, ClientSecret, OAuthAuthorityUrl, Scopes, AccessToken, IdToken);
#pragma warning restore AL0432
    end;

    /// <summary>
    /// Gets the access token from cache or a refreshed token via OAuth2 v2.0 protocol.
    /// </summary>
    /// <param name="ClientId">The Application (client) ID that the Azure portal – App registrations experience assigned to your app.</param>
    /// <param name="Certificate">The Base64-encoded certificate for the Application (client) configured in the Azure Portal - Certificates &amp; Secrets.</param>
    /// <param name="RedirectURL">The redirectURL of your app, where authentication responses can be sent and received by your app. It must exactly match one of the redirectURLs you registered in the portal. If this parameter is empty, the default Business Central URL will be used.</param>
    /// <param name="Scopes">A list of scopes that you want the user to consent to.</param>
    /// <param name="AccessToken">Exit parameter containing the access token.</param>
    [NonDebuggable]
    [TryFunction]
    [Obsolete('Use AcquireAuthorizationCodeTokenFromCacheWithCertificate with SecretText data type for AccessToken.', '24.0')]
    procedure AcquireAuthorizationCodeTokenFromCacheWithCertificate(ClientId: Text; Certificate: Text; RedirectURL: Text; OAuthAuthorityUrl: Text; Scopes: List of [Text]; var AccessToken: Text)
    begin
#pragma warning disable AL0432
        OAuth2Impl.AcquireTokenFromCacheWithCertificate(RedirectURL, ClientId, Certificate, OAuthAuthorityUrl, Scopes, AccessToken);
#pragma warning restore AL0432
    end;

    /// <summary>
    /// Gets the access token from cache or a refreshed token via OAuth2 v2.0 protocol.
    /// </summary>
    /// <param name="ClientId">The Application (client) ID that the Azure portal – App registrations experience assigned to your app.</param>
    /// <param name="Certificate">The Base64-encoded certificate for the Application (client) configured in the Azure Portal - Certificates &amp; Secrets.</param>
    /// <param name="RedirectURL">The redirectURL of your app, where authentication responses can be sent and received by your app. It must exactly match one of the redirectURLs you registered in the portal. If this parameter is empty, the default Business Central URL will be used.</param>
    /// <param name="Scopes">A list of scopes that you want the user to consent to.</param>
    /// <param name="AccessToken">Exit parameter containing the access token.</param>
    /// <param name="IdToken">Exit parameter containing the id token.</param>
    [NonDebuggable]
    [TryFunction]
    [Obsolete('Use AcquireTokensFromCacheWithCertificate with SecretText data type for AccessToken.', '24.0')]
    procedure AcquireTokensFromCacheWithCertificate(ClientId: Text; Certificate: Text; RedirectURL: Text; OAuthAuthorityUrl: Text; Scopes: List of [Text]; var AccessToken: Text; var IdToken: Text)
    begin
#pragma warning disable AL0432
        OAuth2Impl.AcquireTokensFromCacheWithCertificate(RedirectURL, ClientId, Certificate, OAuthAuthorityUrl, Scopes, AccessToken, IdToken);
#pragma warning restore AL0432
    end;

    /// <summary>
    /// Gets the access token via OAuth2 v2.0 protocol, authenticating as a service principal (as the app whose credentials you are providing).
    /// </summary>
    /// <param name="ClientId">The Application (client) ID that the Azure portal – App registrations experience assigned to your app.</param>
    /// <param name="Certificate">The Base64-encoded certificate for the Application (client) configured in the Azure Portal - Certificates &amp; Secrets.</param>
    /// <param name="RedirectURL">The redirectURL of your app, where authentication responses can be sent and received by your app. It must exactly match one of the redirectURLs you registered in the portal. If this parameter is empty, the default Business Central URL will be used.</param>
    /// <param name="Scopes">A list of scopes that you want the user to consent to.</param>
    /// <param name="AccessToken">Exit parameter containing the access token.</param>
    /// <param name="IdToken">Exit parameter containing the id token.</param>
    [NonDebuggable]
    [TryFunction]
    [Obsolete('Use AcquireTokensWithCertificate with SecretText data type for AccessToken.', '24.0')]
    procedure AcquireTokensWithCertificate(ClientId: Text; Certificate: Text; RedirectURL: Text; OAuthAuthorityUrl: Text; Scopes: List of [Text]; var AccessToken: Text; var IdToken: Text)
    begin
#pragma warning disable AL0432
        OAuth2Impl.AcquireTokensWithCertificate(RedirectURL, ClientId, Certificate, OAuthAuthorityUrl, Scopes, AccessToken, IdToken);
#pragma warning restore AL0432
    end;

    /// <summary>
    /// Gets the access and refresh token via the On-Behalf-Of OAuth2 v2.0 protocol flow.
    /// </summary>
    /// <param name="OAuthAuthorityUrl">The identity authorization provider URL.</param>
    /// <param name="RedirectURL">The redirectURL of your app, where authentication responses can be sent and received by your app. It must exactly match one of the redirectURLs you registered in the portal. If this parameter is empty, the default Business Central URL will be used.</param>
    /// <param name="Scopes">A list of scopes that you want the user to consent to.</param>
    /// <param name="AccessToken">Exit parameter containing the access token.</param>
    /// <param name="TokenCache">Exit parameter containing the token cache acquired when the access token was requested .</param>
    [NonDebuggable]
    [Scope('OnPrem')]
    [TryFunction]
    [Obsolete('Use AcquireOnBehalfAccessTokenAndTokenCache with SecretText data type for AccessToken.', '24.0')]
    procedure AcquireOnBehalfAccessTokenAndTokenCache(OAuthAuthorityUrl: Text; RedirectURL: Text; Scopes: List of [Text]; var AccessToken: Text; var TokenCache: Text)
    begin
#pragma warning disable AL0432
        OAuth2Impl.AcquireOnBehalfAccessTokenAndTokenCache(OAuthAuthorityUrl, RedirectURL, Scopes, AccessToken, TokenCache);
#pragma warning restore AL0432
    end;

    /// <summary>
    /// Gets the access and refresh token via the On-Behalf-Of OAuth2 v2.0 protocol flow.
    /// </summary>
    /// <param name="OAuthAuthorityUrl">The identity authorization provider URL.</param>
    /// <param name="RedirectURL">The redirectURL of your app, where authentication responses can be sent and received by your app. It must exactly match one of the redirectURLs you registered in the portal. If this parameter is empty, the default Business Central URL will be used.</param>
    /// <param name="Scopes">A list of scopes that you want the user to consent to.</param>
    /// <param name="AccessToken">Exit parameter containing the access token.</param>
    /// <param name="IdToken">Exit parameter containing the id token.</param>
    /// <param name="TokenCache">Exit parameter containing the token cache acquired when the access token was requested .</param>
    [NonDebuggable]
    [Scope('OnPrem')]
    [TryFunction]
    [Obsolete('Use AcquireOnBehalfTokensAndTokenCache with SecretText data type for AccessToken.', '24.0')]
    procedure AcquireOnBehalfTokensAndTokenCache(OAuthAuthorityUrl: Text; RedirectURL: Text; Scopes: List of [Text]; var AccessToken: Text; var IdToken: Text; var TokenCache: Text)
    begin
#pragma warning disable AL0432
        OAuth2Impl.AcquireOnBehalfTokensAndTokenCache(OAuthAuthorityUrl, RedirectURL, Scopes, AccessToken, IdToken, TokenCache);
#pragma warning restore AL0432
    end;

    /// <summary>
    /// Gets the token and token cache via the On-Behalf-Of OAuth2 v1.0 protocol flow.
    /// </summary>
    /// <param name="LoginHint">The user login hint, i.e. authentication email.</param>
    /// <param name="RedirectURL">The redirectURL of your app, where authentication responses can be sent and received by your app. It must exactly match one of the redirectURLs you registered in the portal. If this parameter is empty, the default Business Central URL will be used.</param>
    /// <param name="Scopes">A list of scopes that you want the user to consent to.</param>
    /// <param name="TokenCache">The token cache acquired when the access token was requested .</param>
    /// <param name="AccessToken">Exit parameter containing the access token.</param>
    /// <param name="NewTokenCache">Exit parameter containing the new token cache.</param>
    [NonDebuggable]
    [Scope('OnPrem')]
    [TryFunction]
    [Obsolete('Use AcquireOnBehalfOfTokenByTokenCache with SecretText data type for AccessToken.', '24.0')]
    procedure AcquireOnBehalfOfTokenByTokenCache(LoginHint: Text; RedirectURL: Text; Scopes: List of [Text]; TokenCache: Text; var AccessToken: Text; var NewTokenCache: Text)
    begin
#pragma warning disable AL0432
        OAuth2Impl.AcquireOnBehalfOfTokenByTokenCache(LoginHint, RedirectURL, Scopes, TokenCache, AccessToken, NewTokenCache);
#pragma warning restore AL0432
    end;

    /// <summary>
    /// Gets the token and token cache via the On-Behalf-Of OAuth2 v1.0 protocol flow.
    /// </summary>
    /// <param name="LoginHint">The user login hint, i.e. authentication email.</param>
    /// <param name="RedirectURL">The redirectURL of your app, where authentication responses can be sent and received by your app. It must exactly match one of the redirectURLs you registered in the portal. If this parameter is empty, the default Business Central URL will be used.</param>
    /// <param name="Scopes">A list of scopes that you want the user to consent to.</param>
    /// <param name="TokenCache">The token cache acquired when the access token was requested .</param>
    /// <param name="AccessToken">Exit parameter containing the access token.</param>
    /// <param name="IdToken">Exit parameter containing the id token.</param>
    /// <param name="NewTokenCache">Exit parameter containing the new token cache.</param>
    [NonDebuggable]
    [Scope('OnPrem')]
    [TryFunction]
    [Obsolete('Use AcquireOnBehalfOfTokensByTokenCache with SecretText data type for AccessToken.', '24.0')]
    procedure AcquireOnBehalfOfTokensByTokenCache(LoginHint: Text; RedirectURL: Text; Scopes: List of [Text]; TokenCache: Text; var AccessToken: Text; var IdToken: Text; var NewTokenCache: Text)
    begin
#pragma warning disable AL0432
        OAuth2Impl.AcquireOnBehalfOfTokensByTokenCache(LoginHint, RedirectURL, Scopes, TokenCache, AccessToken, IdToken, NewTokenCache);
#pragma warning restore AL0432
    end;

    /// <summary>
    /// Gets the token and token cache via the On-Behalf-Of OAuth2 v1.0 protocol flow.
    /// </summary>
    /// <param name="ClientId">The Application (client) ID that the Azure portal - App registrations experience assigned to your app.</param>
    /// <param name="ClientSecret">The Application (client) secret configured in the Azure Portal - Certificates &amp; Secrets.</param>
    /// <param name="LoginHint">The user login hint, i.e. authentication email.</param>
    /// <param name="RedirectURL">The redirectURL of your app, where authentication responses can be sent and received by your app. It must exactly match one of the redirectURLs you registered in the portal. If this parameter is empty, the default Business Central URL will be used.</param>
    /// <param name="Scopes">A list of scopes that you want the user to consent to.</param>
    /// <param name="TokenCache">The token cache acquired when the access token was requested .</param>
    /// <param name="AccessToken">Exit parameter containing the access token.</param>
    /// <param name="NewTokenCache">Exit parameter containing the new token cache.</param>
    [NonDebuggable]
    [TryFunction]
    [Obsolete('Use AcquireOnBehalfOfTokenByTokenCache with SecretText data type for AccessToken.', '24.0')]
    procedure AcquireOnBehalfOfTokenByTokenCache(ClientId: Text; ClientSecret: Text; LoginHint: Text; RedirectURL: Text; Scopes: List of [Text]; TokenCache: Text; var AccessToken: Text; var NewTokenCache: Text)
    begin
#pragma warning disable AL0432
        OAuth2Impl.AcquireOnBehalfOfTokenByTokenCache(ClientId, ClientSecret, LoginHint, RedirectURL, Scopes, TokenCache, AccessToken, NewTokenCache);
#pragma warning restore AL0432
    end;

    /// <summary>
    /// Gets the token and token cache via the On-Behalf-Of OAuth2 v1.0 protocol flow.
    /// </summary>
    /// <param name="ClientId">The Application (client) ID that the Azure portal - App registrations experience assigned to your app.</param>
    /// <param name="ClientSecret">The Application (client) secret configured in the Azure Portal - Certificates &amp; Secrets.</param>
    /// <param name="LoginHint">The user login hint, i.e. authentication email.</param>
    /// <param name="RedirectURL">The redirectURL of your app, where authentication responses can be sent and received by your app. It must exactly match one of the redirectURLs you registered in the portal. If this parameter is empty, the default Business Central URL will be used.</param>
    /// <param name="Scopes">A list of scopes that you want the user to consent to.</param>
    /// <param name="TokenCache">The token cache acquired when the access token was requested .</param>
    /// <param name="AccessToken">Exit parameter containing the access token.</param>
    /// <param name="IdToken">Exit parameter containing the id token.</param>
    /// <param name="NewTokenCache">Exit parameter containing the new token cache.</param>
    [NonDebuggable]
    [TryFunction]
    [Obsolete('Use AcquireOnBehalfOfTokensByTokenCache with SecretText data type for AccessToken.', '24.0')]
    procedure AcquireOnBehalfOfTokensByTokenCache(ClientId: Text; ClientSecret: Text; LoginHint: Text; RedirectURL: Text; Scopes: List of [Text]; TokenCache: Text; var AccessToken: Text; var IdToken: Text; var NewTokenCache: Text)
    begin
#pragma warning disable AL0432
        OAuth2Impl.AcquireOnBehalfOfTokensByTokenCache(ClientId, ClientSecret, LoginHint, RedirectURL, Scopes, TokenCache, AccessToken, IdToken, NewTokenCache);
#pragma warning restore AL0432
    end;

    /// <summary>
    /// Gets the authorization token based on the authorization code via the OAuth2 v1.0 code grant flow.
    /// </summary>
    /// <param name="ClientId">The Application (client) ID that the "Azure portal – App registrations" experience assigned to your app.</param>
    /// <param name="Certificate">The Base64-encoded certificate for the Application (client) configured in the "Azure Portal - Certificates &amp; Secrets".</param>
    /// <param name="OAuthAuthorityUrl">The identity authorization provider URL.</param>
    /// <param name="RedirectURL">The redirectURL of your app, where authentication responses can be sent and received by your app. It must exactly match one of the redirectURLs you registered in the portal. If this parameter is empty, the default Business Central URL will be used.</param>
    /// <param name="ResourceURL">The Application ID of the resource the application is requesting access to. This parameter can be empty.</param>
    /// <param name="PromptInteraction">Indicates the type of user interaction that is required.</param>
    /// <param name="AccessToken">Exit parameter containing the access token. When this parameter is empty, check the AuthCodeErr for a description of the error.</param>
    /// <param name="AuthCodeErr">Exit parameter containing the encountered error in the authorization code grant flow. This parameter will be empty in case the token is aquired successfuly.</param>
    [TryFunction]
    [Obsolete('Use AcquireTokenByAuthorizationCodeWithCertificate with SecretText data type for AccessToken and Certificate.', '25.0')]
    procedure AcquireTokenByAuthorizationCodeWithCertificate(ClientId: Text; Certificate: Text; OAuthAuthorityUrl: Text; RedirectURL: Text; ResourceURL: Text; PromptInteraction: Enum "Prompt Interaction"; var AccessToken: SecretText; var AuthCodeErr: Text)
    begin
#pragma warning disable AL0432
        OAuth2Impl.AcquireTokenByAuthorizationCodeWithCertificate(ClientId, Certificate, OAuthAuthorityUrl, RedirectURL, ResourceURL, PromptInteraction, AccessToken, AuthCodeErr);
#pragma warning restore AL0432
    end;
#pragma warning restore AS0105

    /// <summary>
    /// Gets the authorization token based on the authorization code via the OAuth2 v1.0 code grant flow.
    /// </summary>
    /// <param name="ClientId">The Application (client) ID that the "Azure portal – App registrations" experience assigned to your app.</param>
    /// <param name="Certificate">The Base64-encoded certificate for the Application (client) configured in the "Azure Portal - Certificates &amp; Secrets".</param>
    /// <param name="OAuthAuthorityUrl">The identity authorization provider URL.</param>
    /// <param name="RedirectURL">The redirectURL of your app, where authentication responses can be sent and received by your app. It must exactly match one of the redirectURLs you registered in the portal. If this parameter is empty, the default Business Central URL will be used.</param>
    /// <param name="ResourceURL">The Application ID of the resource the application is requesting access to. This parameter can be empty.</param>
    /// <param name="PromptInteraction">Indicates the type of user interaction that is required.</param>
    /// <param name="AccessToken">Exit parameter containing the access token. When this parameter is empty, check the AuthCodeErr for a description of the error.</param>
    /// <param name="AuthCodeErr">Exit parameter containing the encountered error in the authorization code grant flow. This parameter will be empty in case the token is aquired successfuly.</param>
    [TryFunction]
    procedure AcquireTokenByAuthorizationCodeWithCertificate(ClientId: Text; Certificate: SecretText; OAuthAuthorityUrl: Text; RedirectURL: Text; ResourceURL: Text; PromptInteraction: Enum "Prompt Interaction"; var AccessToken: SecretText; var AuthCodeErr: Text)
    begin
        OAuth2Impl.AcquireTokenByAuthorizationCodeWithCertificate(ClientId, Certificate, OAuthAuthorityUrl, RedirectURL, ResourceURL, PromptInteraction, AccessToken, AuthCodeErr);
    end;

#pragma warning disable AS0105
    /// <summary>
    /// Gets the authorization token based on the authorization code via the OAuth2 v1.0 code grant flow.
    /// </summary>
    /// <param name="ClientId">The Application (client) ID that the "Azure portal – App registrations" experience assigned to your app.</param>
    /// <param name="Certificate">The Base64-encoded certificate for the Application (client) configured in the "Azure Portal - Certificates &amp; Secrets".</param>
    /// <param name="CertificatePassword">Password for the certificate.</param>
    /// <param name="OAuthAuthorityUrl">The identity authorization provider URL.</param>
    /// <param name="RedirectURL">The redirectURL of your app, where authentication responses can be sent and received by your app. It must exactly match one of the redirectURLs you registered in the portal. If this parameter is empty, the default Business Central URL will be used.</param>
    /// <param name="ResourceURL">The Application ID of the resource the application is requesting access to. This parameter can be empty.</param>
    /// <param name="PromptInteraction">Indicates the type of user interaction that is required.</param>
    /// <param name="AccessToken">Exit parameter containing the access token. When this parameter is empty, check the AuthCodeErr for a description of the error.</param>
    /// <param name="AuthCodeErr">Exit parameter containing the encountered error in the authorization code grant flow. This parameter will be empty in case the token is aquired successfuly.</param>
    [TryFunction]
    [Obsolete('Use AcquireTokenByAuthorizationCodeWithCertificate with SecretText data type for AccessToken, Certificate and CertificatePassword.', '25.0')]
    procedure AcquireTokenByAuthorizationCodeWithCertificate(ClientId: Text; Certificate: Text; CertificatePassword: SecretText; OAuthAuthorityUrl: Text; RedirectURL: Text; ResourceURL: Text; PromptInteraction: Enum "Prompt Interaction"; var AccessToken: SecretText; var AuthCodeErr: Text)
    begin
#pragma warning disable AL0432
        OAuth2Impl.AcquireTokenByAuthorizationCodeWithCertificate(ClientId, Certificate, CertificatePassword, OAuthAuthorityUrl, RedirectURL, ResourceURL, PromptInteraction, AccessToken, AuthCodeErr);
#pragma warning restore AL0432
    end;
#pragma warning restore AS0105

    /// <summary>
    /// Gets the authorization token based on the authorization code via the OAuth2 v1.0 code grant flow.
    /// </summary>
    /// <param name="ClientId">The Application (client) ID that the "Azure portal – App registrations" experience assigned to your app.</param>
    /// <param name="Certificate">The Base64-encoded certificate for the Application (client) configured in the "Azure Portal - Certificates &amp; Secrets".</param>
    /// <param name="CertificatePassword">Password for the certificate.</param>
    /// <param name="OAuthAuthorityUrl">The identity authorization provider URL.</param>
    /// <param name="RedirectURL">The redirectURL of your app, where authentication responses can be sent and received by your app. It must exactly match one of the redirectURLs you registered in the portal. If this parameter is empty, the default Business Central URL will be used.</param>
    /// <param name="ResourceURL">The Application ID of the resource the application is requesting access to. This parameter can be empty.</param>
    /// <param name="PromptInteraction">Indicates the type of user interaction that is required.</param>
    /// <param name="AccessToken">Exit parameter containing the access token. When this parameter is empty, check the AuthCodeErr for a description of the error.</param>
    /// <param name="AuthCodeErr">Exit parameter containing the encountered error in the authorization code grant flow. This parameter will be empty in case the token is aquired successfuly.</param>
    [TryFunction]
    procedure AcquireTokenByAuthorizationCodeWithCertificate(ClientId: Text; Certificate: SecretText; CertificatePassword: SecretText; OAuthAuthorityUrl: Text; RedirectURL: Text; ResourceURL: Text; PromptInteraction: Enum "Prompt Interaction"; var AccessToken: SecretText; var AuthCodeErr: Text)
    begin
        OAuth2Impl.AcquireTokenByAuthorizationCodeWithCertificate(ClientId, Certificate, CertificatePassword, OAuthAuthorityUrl, RedirectURL, ResourceURL, PromptInteraction, AccessToken, AuthCodeErr);
    end;

    /// <summary>
    /// Gets the authorization token based on the authorization code via the OAuth2 v2.0 code grant flow.
    /// </summary>
    /// <param name="ClientId">The Application (client) ID that the "Azure portal – App registrations" experience assigned to your app.</param>
    /// <param name="ClientSecret">The Application (client) secret configured in the "Azure Portal - Certificates &amp; Secrets".</param>
    /// <param name="OAuthAuthorityUrl">The identity authorization provider URL.</param>
    /// <param name="RedirectURL">The redirectURL of your app, where authentication responses can be sent and received by your app. It must exactly match one of the redirectURLs you registered in the portal. If this parameter is empty, the default Business Central URL will be used.</param>
    /// <param name="Scopes">A list of scopes that you want the user to consent to.</param>
    /// <param name="PromptInteraction">Indicates the type of user interaction that is required.</param>
    /// <param name="AccessToken">Exit parameter containing the access token. When this parameter is empty, check the AuthCodeErr for a description of the error.</param>
    /// <param name="AuthCodeErr">Exit parameter containing the encountered error in the authorization code grant flow. This parameter will be empty in case the token is aquired successfuly.</param>
    [TryFunction]
    procedure AcquireTokenByAuthorizationCode(ClientId: Text; ClientSecret: SecretText; OAuthAuthorityUrl: Text; RedirectURL: Text; Scopes: List of [Text]; PromptInteraction: Enum "Prompt Interaction"; var AccessToken: SecretText; var AuthCodeErr: Text)
    begin
        OAuth2Impl.AcquireTokenByAuthorizationCode(ClientId, ClientSecret, OAuthAuthorityUrl, RedirectURL, Scopes, PromptInteraction, AccessToken, AuthCodeErr);
    end;

#pragma warning disable AS0105
    /// <summary>
    /// Gets the authorization token based on the authorization code via the OAuth2 v2.0 code grant flow.
    /// </summary>
    /// <param name="ClientId">The Application (client) ID that the "Azure portal – App registrations" experience assigned to your app.</param>
    /// <param name="Certificate">The Base64-encoded certificate for the application (client) configured in the "Azure Portal - Certificates &amp; Secrets".</param>
    /// <param name="OAuthAuthorityUrl">The identity authorization provider URL.</param>
    /// <param name="RedirectURL">The redirectURL of your app, where authentication responses can be sent and received by your app. It must exactly match one of the redirectURLs you registered in the portal. If this parameter is empty, the default Business Central URL will be used.</param>
    /// <param name="Scopes">A list of scopes that you want the user to consent to.</param>
    /// <param name="PromptInteraction">Indicates the type of user interaction that is required.</param>
    /// <param name="AccessToken">Exit parameter containing the access token. When this parameter is empty, check the AuthCodeErr for a description of the error.</param>
    /// <param name="AuthCodeErr">Exit parameter containing the encountered error in the authorization code grant flow. This parameter will be empty in case the token is aquired successfuly.</param>
    [TryFunction]
    [Obsolete('Use AcquireTokenByAuthorizationCodeWithCertificate with SecretText data type for AccessToken and Certificate.', '25.0')]
    procedure AcquireTokenByAuthorizationCodeWithCertificate(ClientId: Text; Certificate: Text; OAuthAuthorityUrl: Text; RedirectURL: Text; Scopes: List of [Text]; PromptInteraction: Enum "Prompt Interaction"; var AccessToken: SecretText; var AuthCodeErr: Text)
    begin
#pragma warning disable AL0432
        OAuth2Impl.AcquireTokenByAuthorizationCodeWithCertificate(ClientId, Certificate, OAuthAuthorityUrl, RedirectURL, Scopes, PromptInteraction, AccessToken, AuthCodeErr);
#pragma warning restore AL0432
    end;
#pragma warning restore AS0105

    /// <summary>
    /// Gets the authorization token based on the authorization code via the OAuth2 v2.0 code grant flow.
    /// </summary>
    /// <param name="ClientId">The Application (client) ID that the "Azure portal – App registrations" experience assigned to your app.</param>
    /// <param name="Certificate">The Base64-encoded certificate for the application (client) configured in the "Azure Portal - Certificates &amp; Secrets".</param>
    /// <param name="OAuthAuthorityUrl">The identity authorization provider URL.</param>
    /// <param name="RedirectURL">The redirectURL of your app, where authentication responses can be sent and received by your app. It must exactly match one of the redirectURLs you registered in the portal. If this parameter is empty, the default Business Central URL will be used.</param>
    /// <param name="Scopes">A list of scopes that you want the user to consent to.</param>
    /// <param name="PromptInteraction">Indicates the type of user interaction that is required.</param>
    /// <param name="AccessToken">Exit parameter containing the access token. When this parameter is empty, check the AuthCodeErr for a description of the error.</param>
    /// <param name="AuthCodeErr">Exit parameter containing the encountered error in the authorization code grant flow. This parameter will be empty in case the token is aquired successfuly.</param>
    [TryFunction]
    procedure AcquireTokenByAuthorizationCodeWithCertificate(ClientId: Text; Certificate: SecretText; OAuthAuthorityUrl: Text; RedirectURL: Text; Scopes: List of [Text]; PromptInteraction: Enum "Prompt Interaction"; var AccessToken: SecretText; var AuthCodeErr: Text)
    begin
        OAuth2Impl.AcquireTokenByAuthorizationCodeWithCertificate(ClientId, Certificate, OAuthAuthorityUrl, RedirectURL, Scopes, PromptInteraction, AccessToken, AuthCodeErr);
    end;

#pragma warning disable AS0105
    /// <summary>
    /// Gets the authorization token based on the authorization code via the OAuth2 v2.0 code grant flow.
    /// </summary>
    /// <param name="ClientId">The Application (client) ID that the "Azure portal – App registrations" experience assigned to your app.</param>
    /// <param name="Certificate">The Base64-encoded certificate for the application (client) configured in the "Azure Portal - Certificates &amp; Secrets".</param>
    /// <param name="CertificatePassword">Password for the certificate.</param>
    /// <param name="OAuthAuthorityUrl">The identity authorization provider URL.</param>
    /// <param name="RedirectURL">The redirectURL of your app, where authentication responses can be sent and received by your app. It must exactly match one of the redirectURLs you registered in the portal. If this parameter is empty, the default Business Central URL will be used.</param>
    /// <param name="Scopes">A list of scopes that you want the user to consent to.</param>
    /// <param name="PromptInteraction">Indicates the type of user interaction that is required.</param>
    /// <param name="AccessToken">Exit parameter containing the access token. When this parameter is empty, check the AuthCodeErr for a description of the error.</param>
    /// <param name="AuthCodeErr">Exit parameter containing the encountered error in the authorization code grant flow. This parameter will be empty in case the token is aquired successfuly.</param>
    [TryFunction]
    [Obsolete('Use AcquireTokenByAuthorizationCodeWithCertificate with SecretText data type for AccessToken, Certificate and CertificatePassword.', '25.0')]
    procedure AcquireTokenByAuthorizationCodeWithCertificate(ClientId: Text; Certificate: Text; CertificatePassword: SecretText; OAuthAuthorityUrl: Text; RedirectURL: Text; Scopes: List of [Text]; PromptInteraction: Enum "Prompt Interaction"; var AccessToken: SecretText; var AuthCodeErr: Text)
    begin
#pragma warning disable AL0432
        OAuth2Impl.AcquireTokenByAuthorizationCodeWithCertificate(ClientId, Certificate, CertificatePassword, OAuthAuthorityUrl, RedirectURL, Scopes, PromptInteraction, AccessToken, AuthCodeErr);
#pragma warning restore AL0432
    end;
#pragma warning restore AS0105

    /// <summary>
    /// Gets the authorization token based on the authorization code via the OAuth2 v2.0 code grant flow.
    /// </summary>
    /// <param name="ClientId">The Application (client) ID that the "Azure portal – App registrations" experience assigned to your app.</param>
    /// <param name="Certificate">The Base64-encoded certificate for the application (client) configured in the "Azure Portal - Certificates &amp; Secrets".</param>
    /// <param name="CertificatePassword">Password for the certificate.</param>
    /// <param name="OAuthAuthorityUrl">The identity authorization provider URL.</param>
    /// <param name="RedirectURL">The redirectURL of your app, where authentication responses can be sent and received by your app. It must exactly match one of the redirectURLs you registered in the portal. If this parameter is empty, the default Business Central URL will be used.</param>
    /// <param name="Scopes">A list of scopes that you want the user to consent to.</param>
    /// <param name="PromptInteraction">Indicates the type of user interaction that is required.</param>
    /// <param name="AccessToken">Exit parameter containing the access token. When this parameter is empty, check the AuthCodeErr for a description of the error.</param>
    /// <param name="AuthCodeErr">Exit parameter containing the encountered error in the authorization code grant flow. This parameter will be empty in case the token is aquired successfuly.</param>
    [TryFunction]
    procedure AcquireTokenByAuthorizationCodeWithCertificate(ClientId: Text; Certificate: SecretText; CertificatePassword: SecretText; OAuthAuthorityUrl: Text; RedirectURL: Text; Scopes: List of [Text]; PromptInteraction: Enum "Prompt Interaction"; var AccessToken: SecretText; var AuthCodeErr: Text)
    begin
        OAuth2Impl.AcquireTokenByAuthorizationCodeWithCertificate(ClientId, Certificate, CertificatePassword, OAuthAuthorityUrl, RedirectURL, Scopes, PromptInteraction, AccessToken, AuthCodeErr);
    end;

    /// <summary>
    /// Gets the authorization token based on the authorization code via the OAuth2 v2.0 code grant flow.
    /// </summary>
    /// <param name="ClientId">The Application (client) ID that the "Azure portal – App registrations" experience assigned to your app.</param>
    /// <param name="ClientSecret">The Application (client) secret configured in the "Azure Portal - Certificates &amp; Secrets".</param>
    /// <param name="OAuthAuthorityUrl">The identity authorization provider URL.</param>
    /// <param name="RedirectURL">The redirectURL of your app, where authentication responses can be sent and received by your app. It must exactly match one of the redirectURLs you registered in the portal. If this parameter is empty, the default Business Central URL will be used.</param>
    /// <param name="Scopes">A list of scopes that you want the user to consent to.</param>
    /// <param name="PromptInteraction">Indicates the type of user interaction that is required.</param>
    /// <param name="AccessToken">Exit parameter containing the access token. When this parameter is empty, check the AuthCodeErr for a description of the error.</param>
    /// <param name="IdToken">Exit parameter containing the id token.</param>
    /// <param name="AuthCodeErr">Exit parameter containing the encountered error in the authorization code grant flow. This parameter will be empty in case the token is aquired successfuly.</param>
    [TryFunction]
    procedure AcquireTokensByAuthorizationCode(ClientId: Text; ClientSecret: SecretText; OAuthAuthorityUrl: Text; RedirectURL: Text; Scopes: List of [Text]; PromptInteraction: Enum "Prompt Interaction"; var AccessToken: SecretText; var IdToken: Text; var AuthCodeErr: Text)
    begin
        OAuth2Impl.AcquireTokensByAuthorizationCode(ClientId, ClientSecret, OAuthAuthorityUrl, RedirectURL, Scopes, PromptInteraction, AccessToken, IdToken, AuthCodeErr);
    end;

#pragma warning disable AS0105
    /// <summary>
    /// Gets the authorization token based on the authorization code via the OAuth2 v2.0 code grant flow.
    /// </summary>
    /// <param name="ClientId">The Application (client) ID that the "Azure portal – App registrations" experience assigned to your app.</param>
    /// <param name="Certificate">The Base64-encoded certificate for the application (client) configured in the "Azure Portal - Certificates &amp; Secrets".</param>
    /// <param name="OAuthAuthorityUrl">The identity authorization provider URL.</param>
    /// <param name="RedirectURL">The redirectURL of your app, where authentication responses can be sent and received by your app. It must exactly match one of the redirectURLs you registered in the portal. If this parameter is empty, the default Business Central URL will be used.</param>
    /// <param name="Scopes">A list of scopes that you want the user to consent to.</param>
    /// <param name="PromptInteraction">Indicates the type of user interaction that is required.</param>
    /// <param name="AccessToken">Exit parameter containing the access token. When this parameter is empty, check the AuthCodeErr for a description of the error.</param>
    /// <param name="IdToken">Exit parameter containing the id token.</param>
    /// <param name="AuthCodeErr">Exit parameter containing the encountered error in the authorization code grant flow. This parameter will be empty in case the token is aquired successfuly.</param>
    [TryFunction]
    [Obsolete('Use AcquireTokensByAuthorizationCodeWithCertificate with SecretText data type for AccessToken and Certificate.', '25.0')]
    procedure AcquireTokensByAuthorizationCodeWithCertificate(ClientId: Text; Certificate: Text; OAuthAuthorityUrl: Text; RedirectURL: Text; Scopes: List of [Text]; PromptInteraction: Enum "Prompt Interaction"; var AccessToken: SecretText; var IdToken: Text; var AuthCodeErr: Text)
    begin
#pragma warning disable AL0432
        OAuth2Impl.AcquireTokensByAuthorizationCodeWithCertificate(ClientId, Certificate, OAuthAuthorityUrl, RedirectURL, Scopes, PromptInteraction, AccessToken, IdToken, AuthCodeErr);
#pragma warning restore AL0432
    end;
#pragma warning restore AS0105

    /// <summary>
    /// Gets the authorization token based on the authorization code via the OAuth2 v2.0 code grant flow.
    /// </summary>
    /// <param name="ClientId">The Application (client) ID that the "Azure portal – App registrations" experience assigned to your app.</param>
    /// <param name="Certificate">The Base64-encoded certificate for the application (client) configured in the "Azure Portal - Certificates &amp; Secrets".</param>
    /// <param name="OAuthAuthorityUrl">The identity authorization provider URL.</param>
    /// <param name="RedirectURL">The redirectURL of your app, where authentication responses can be sent and received by your app. It must exactly match one of the redirectURLs you registered in the portal. If this parameter is empty, the default Business Central URL will be used.</param>
    /// <param name="Scopes">A list of scopes that you want the user to consent to.</param>
    /// <param name="PromptInteraction">Indicates the type of user interaction that is required.</param>
    /// <param name="AccessToken">Exit parameter containing the access token. When this parameter is empty, check the AuthCodeErr for a description of the error.</param>
    /// <param name="IdToken">Exit parameter containing the id token.</param>
    /// <param name="AuthCodeErr">Exit parameter containing the encountered error in the authorization code grant flow. This parameter will be empty in case the token is aquired successfuly.</param>
    [TryFunction]
    procedure AcquireTokensByAuthorizationCodeWithCertificate(ClientId: Text; Certificate: SecretText; OAuthAuthorityUrl: Text; RedirectURL: Text; Scopes: List of [Text]; PromptInteraction: Enum "Prompt Interaction"; var AccessToken: SecretText; var IdToken: Text; var AuthCodeErr: Text)
    begin
        OAuth2Impl.AcquireTokensByAuthorizationCodeWithCertificate(ClientId, Certificate, OAuthAuthorityUrl, RedirectURL, Scopes, PromptInteraction, AccessToken, IdToken, AuthCodeErr);
    end;

#pragma warning disable AS0105
    /// <summary>
    /// Gets the authorization token based on the authorization code via the OAuth2 v2.0 code grant flow.
    /// </summary>
    /// <param name="ClientId">The Application (client) ID that the "Azure portal – App registrations" experience assigned to your app.</param>
    /// <param name="Certificate">The Base64-encoded certificate for the application (client) configured in the "Azure Portal - Certificates &amp; Secrets".</param>
    /// <param name="CertificatePassword">Password for the certificate.</param>
    /// <param name="OAuthAuthorityUrl">The identity authorization provider URL.</param>
    /// <param name="RedirectURL">The redirectURL of your app, where authentication responses can be sent and received by your app. It must exactly match one of the redirectURLs you registered in the portal. If this parameter is empty, the default Business Central URL will be used.</param>
    /// <param name="Scopes">A list of scopes that you want the user to consent to.</param>
    /// <param name="PromptInteraction">Indicates the type of user interaction that is required.</param>
    /// <param name="AccessToken">Exit parameter containing the access token. When this parameter is empty, check the AuthCodeErr for a description of the error.</param>
    /// <param name="IdToken">Exit parameter containing the id token.</param>
    /// <param name="AuthCodeErr">Exit parameter containing the encountered error in the authorization code grant flow. This parameter will be empty in case the token is aquired successfuly.</param>
    [TryFunction]
    [Obsolete('Use AcquireTokensByAuthorizationCodeWithCertificate with SecretText data type for AccessToken, Certificate and CertificatePassword.', '25.0')]
    procedure AcquireTokensByAuthorizationCodeWithCertificate(ClientId: Text; Certificate: Text; CertificatePassword: SecretText; OAuthAuthorityUrl: Text; RedirectURL: Text; Scopes: List of [Text]; PromptInteraction: Enum "Prompt Interaction"; var AccessToken: SecretText; var IdToken: Text; var AuthCodeErr: Text)
    begin
#pragma warning disable AL0432
        OAuth2Impl.AcquireTokensByAuthorizationCodeWithCertificate(ClientId, Certificate, CertificatePassword, OAuthAuthorityUrl, RedirectURL, Scopes, PromptInteraction, AccessToken, IdToken, AuthCodeErr);
#pragma warning restore AL0432
    end;
#pragma warning restore AS0105

    /// <summary>
    /// Gets the authorization token based on the authorization code via the OAuth2 v2.0 code grant flow.
    /// </summary>
    /// <param name="ClientId">The Application (client) ID that the "Azure portal – App registrations" experience assigned to your app.</param>
    /// <param name="Certificate">The Base64-encoded certificate for the application (client) configured in the "Azure Portal - Certificates &amp; Secrets".</param>
    /// <param name="CertificatePassword">Password for the certificate.</param>
    /// <param name="OAuthAuthorityUrl">The identity authorization provider URL.</param>
    /// <param name="RedirectURL">The redirectURL of your app, where authentication responses can be sent and received by your app. It must exactly match one of the redirectURLs you registered in the portal. If this parameter is empty, the default Business Central URL will be used.</param>
    /// <param name="Scopes">A list of scopes that you want the user to consent to.</param>
    /// <param name="PromptInteraction">Indicates the type of user interaction that is required.</param>
    /// <param name="AccessToken">Exit parameter containing the access token. When this parameter is empty, check the AuthCodeErr for a description of the error.</param>
    /// <param name="IdToken">Exit parameter containing the id token.</param>
    /// <param name="AuthCodeErr">Exit parameter containing the encountered error in the authorization code grant flow. This parameter will be empty in case the token is aquired successfuly.</param>
    [TryFunction]
    procedure AcquireTokensByAuthorizationCodeWithCertificate(ClientId: Text; Certificate: SecretText; CertificatePassword: SecretText; OAuthAuthorityUrl: Text; RedirectURL: Text; Scopes: List of [Text]; PromptInteraction: Enum "Prompt Interaction"; var AccessToken: SecretText; var IdToken: Text; var AuthCodeErr: Text)
    begin
        OAuth2Impl.AcquireTokensByAuthorizationCodeWithCertificate(ClientId, Certificate, CertificatePassword, OAuthAuthorityUrl, RedirectURL, Scopes, PromptInteraction, AccessToken, IdToken, AuthCodeErr);
    end;

    /// <summary>
    /// Gets the access token and token cache state with authorization code flow.
    /// </summary>
    /// <param name="ClientId">The Application (client) ID that the "Azure portal – App registrations" experience assigned to your app.</param>
    /// <param name="ClientSecret">The Application (client) secret configured in the "Azure Portal - Certificates &amp; Secrets".</param>
    /// <param name="OAuthAuthorityUrl">The identity authorization provider URL.</param>
    /// <param name="RedirectURL">The redirectURL of your app, where authentication responses can be sent and received by your app. It must exactly match one of the redirectURLs you registered in the portal. If this parameter is empty, the default Business Central URL will be used.</param>
    /// <param name="Scopes">A list of scopes that you want the user to consent to.</param>
    /// <param name="PromptInteraction">Indicates the type of user interaction that is required.</param>
    /// <param name="AccessToken">Exit parameter containing the access token. When this parameter is empty, check the Error for a description of the error.</param>
    /// <param name="TokenCache">Exit parameter containing the token cache acquired when the access token was requested.</param>
    /// <param name="Error">Exit parameter containing the encountered error in the authorization code grant flow. This parameter will be empty in case the token is aquired successfuly.</param>
    [TryFunction]
    procedure AcquireTokenAndTokenCacheByAuthorizationCode(ClientId: Text; ClientSecret: SecretText; OAuthAuthorityUrl: Text; RedirectURL: Text; Scopes: List of [Text]; PromptInteraction: Enum "Prompt Interaction"; var AccessToken: SecretText; var TokenCache: Text; var Error: Text)
    begin
        OAuth2Impl.AcquireTokenAndTokenCacheByAuthorizationCode(ClientId, ClientSecret, OAuthAuthorityUrl, RedirectURL, Scopes, PromptInteraction, AccessToken, TokenCache, Error);
    end;

#pragma warning disable AS0105
    /// <summary>
    /// Gets the access token and token cache state with authorization code flow.
    /// </summary>
    /// <param name="ClientId">The Application (client) ID that the "Azure portal – App registrations" experience assigned to your app.</param>
    /// <param name="Certificate">The Base64-encoded certificate for the application (client) configured in the "Azure Portal - Certificates &amp; Secrets".</param>
    /// <param name="OAuthAuthorityUrl">The identity authorization provider URL.</param>
    /// <param name="RedirectURL">The redirectURL of your app, where authentication responses can be sent and received by your app. It must exactly match one of the redirectURLs you registered in the portal. If this parameter is empty, the default Business Central URL will be used.</param>
    /// <param name="Scopes">A list of scopes that you want the user to consent to.</param>
    /// <param name="PromptInteraction">Indicates the type of user interaction that is required.</param>
    /// <param name="AccessToken">Exit parameter containing the access token. When this parameter is empty, check the Error for a description of the error.</param>
    /// <param name="TokenCache">Exit parameter containing the token cache acquired when the access token was requested.</param>
    /// <param name="Error">Exit parameter containing the encountered error in the authorization code grant flow. This parameter will be empty in case the token is aquired successfuly.</param>
    [TryFunction]
    [Obsolete('Use AcquireTokenAndTokenCacheByAuthorizationCodeWithCertificate with SecretText data type for AccessToken and Certificate.', '25.0')]
    procedure AcquireTokenAndTokenCacheByAuthorizationCodeWithCertificate(ClientId: Text; Certificate: Text; OAuthAuthorityUrl: Text; RedirectURL: Text; Scopes: List of [Text]; PromptInteraction: Enum "Prompt Interaction"; var AccessToken: SecretText; var TokenCache: Text; var Error: Text)
    begin
#pragma warning disable AL0432
        OAuth2Impl.AcquireTokenAndTokenCacheByAuthorizationCodeWithCertificate(ClientId, Certificate, OAuthAuthorityUrl, RedirectURL, Scopes, PromptInteraction, AccessToken, TokenCache, Error);
#pragma warning restore AL0432
    end;
#pragma warning restore AS0105

    /// <summary>
    /// Gets the access token and token cache state with authorization code flow.
    /// </summary>
    /// <param name="ClientId">The Application (client) ID that the "Azure portal – App registrations" experience assigned to your app.</param>
    /// <param name="Certificate">The Base64-encoded certificate for the application (client) configured in the "Azure Portal - Certificates &amp; Secrets".</param>
    /// <param name="OAuthAuthorityUrl">The identity authorization provider URL.</param>
    /// <param name="RedirectURL">The redirectURL of your app, where authentication responses can be sent and received by your app. It must exactly match one of the redirectURLs you registered in the portal. If this parameter is empty, the default Business Central URL will be used.</param>
    /// <param name="Scopes">A list of scopes that you want the user to consent to.</param>
    /// <param name="PromptInteraction">Indicates the type of user interaction that is required.</param>
    /// <param name="AccessToken">Exit parameter containing the access token. When this parameter is empty, check the Error for a description of the error.</param>
    /// <param name="TokenCache">Exit parameter containing the token cache acquired when the access token was requested.</param>
    /// <param name="Error">Exit parameter containing the encountered error in the authorization code grant flow. This parameter will be empty in case the token is aquired successfuly.</param>
    [TryFunction]
    procedure AcquireTokenAndTokenCacheByAuthorizationCodeWithCertificate(ClientId: Text; Certificate: SecretText; OAuthAuthorityUrl: Text; RedirectURL: Text; Scopes: List of [Text]; PromptInteraction: Enum "Prompt Interaction"; var AccessToken: SecretText; var TokenCache: Text; var Error: Text)
    begin
        OAuth2Impl.AcquireTokenAndTokenCacheByAuthorizationCodeWithCertificate(ClientId, Certificate, OAuthAuthorityUrl, RedirectURL, Scopes, PromptInteraction, AccessToken, TokenCache, Error);
    end;

#pragma warning disable AS0105
    /// <summary>
    /// Gets the access token and token cache state with authorization code flow.
    /// </summary>
    /// <param name="ClientId">The Application (client) ID that the "Azure portal – App registrations" experience assigned to your app.</param>
    /// <param name="Certificate">The Base64-encoded certificate for the application (client) configured in the "Azure Portal - Certificates &amp; Secrets".</param>
    /// <param name="CertificatePassword">Password for the certificate.</param>
    /// <param name="OAuthAuthorityUrl">The identity authorization provider URL.</param>
    /// <param name="RedirectURL">The redirectURL of your app, where authentication responses can be sent and received by your app. It must exactly match one of the redirectURLs you registered in the portal. If this parameter is empty, the default Business Central URL will be used.</param>
    /// <param name="Scopes">A list of scopes that you want the user to consent to.</param>
    /// <param name="PromptInteraction">Indicates the type of user interaction that is required.</param>
    /// <param name="AccessToken">Exit parameter containing the access token. When this parameter is empty, check the Error for a description of the error.</param>
    /// <param name="TokenCache">Exit parameter containing the token cache acquired when the access token was requested.</param>
    /// <param name="Error">Exit parameter containing the encountered error in the authorization code grant flow. This parameter will be empty in case the token is aquired successfuly.</param>
    [TryFunction]
    [Obsolete('Use AcquireTokenAndTokenCacheByAuthorizationCodeWithCertificate with SecretText data type for AccessToken, Certificate and CertificatePassword.', '25.0')]
    procedure AcquireTokenAndTokenCacheByAuthorizationCodeWithCertificate(ClientId: Text; Certificate: Text; CertificatePassword: SecretText; OAuthAuthorityUrl: Text; RedirectURL: Text; Scopes: List of [Text]; PromptInteraction: Enum "Prompt Interaction"; var AccessToken: SecretText; var TokenCache: Text; var Error: Text)
    begin
#pragma warning disable AL0432
        OAuth2Impl.AcquireTokenAndTokenCacheByAuthorizationCodeWithCertificate(ClientId, Certificate, CertificatePassword, OAuthAuthorityUrl, RedirectURL, Scopes, PromptInteraction, AccessToken, TokenCache, Error);
#pragma warning restore AL0432
    end;
#pragma warning restore AS0105


    /// <summary>
    /// Gets the access token and token cache state with authorization code flow.
    /// </summary>
    /// <param name="ClientId">The Application (client) ID that the "Azure portal – App registrations" experience assigned to your app.</param>
    /// <param name="Certificate">The Base64-encoded certificate for the application (client) configured in the "Azure Portal - Certificates &amp; Secrets".</param>
    /// <param name="CertificatePassword">Password for the certificate.</param>
    /// <param name="OAuthAuthorityUrl">The identity authorization provider URL.</param>
    /// <param name="RedirectURL">The redirectURL of your app, where authentication responses can be sent and received by your app. It must exactly match one of the redirectURLs you registered in the portal. If this parameter is empty, the default Business Central URL will be used.</param>
    /// <param name="Scopes">A list of scopes that you want the user to consent to.</param>
    /// <param name="PromptInteraction">Indicates the type of user interaction that is required.</param>
    /// <param name="AccessToken">Exit parameter containing the access token. When this parameter is empty, check the Error for a description of the error.</param>
    /// <param name="TokenCache">Exit parameter containing the token cache acquired when the access token was requested.</param>
    /// <param name="Error">Exit parameter containing the encountered error in the authorization code grant flow. This parameter will be empty in case the token is aquired successfuly.</param>
    [TryFunction]
    procedure AcquireTokenAndTokenCacheByAuthorizationCodeWithCertificate(ClientId: Text; Certificate: SecretText; CertificatePassword: SecretText; OAuthAuthorityUrl: Text; RedirectURL: Text; Scopes: List of [Text]; PromptInteraction: Enum "Prompt Interaction"; var AccessToken: SecretText; var TokenCache: Text; var Error: Text)
    begin
        OAuth2Impl.AcquireTokenAndTokenCacheByAuthorizationCodeWithCertificate(ClientId, Certificate, CertificatePassword, OAuthAuthorityUrl, RedirectURL, Scopes, PromptInteraction, AccessToken, TokenCache, Error);
    end;

    /// <summary>
    /// Gets the access token and token cache state with authorization code flow.
    /// </summary>
    /// <param name="ClientId">The Application (client) ID that the "Azure portal – App registrations" experience assigned to your app.</param>
    /// <param name="ClientSecret">The Application (client) secret configured in the "Azure Portal - Certificates &amp; Secrets".</param>
    /// <param name="OAuthAuthorityUrl">The identity authorization provider URL.</param>
    /// <param name="RedirectURL">The redirectURL of your app, where authentication responses can be sent and received by your app. It must exactly match one of the redirectURLs you registered in the portal. If this parameter is empty, the default Business Central URL will be used.</param>
    /// <param name="Scopes">A list of scopes that you want the user to consent to.</param>
    /// <param name="PromptInteraction">Indicates the type of user interaction that is required.</param>
    /// <param name="AccessToken">Exit parameter containing the access token. When this parameter is empty, check the Error for a description of the error.</param>
    /// <param name="IdToken">Exit parameter containing the id token.</param>
    /// <param name="TokenCache">Exit parameter containing the token cache acquired when the access token was requested.</param>
    /// <param name="Error">Exit parameter containing the encountered error in the authorization code grant flow. This parameter will be empty in case the token is aquired successfuly.</param>
    [TryFunction]
    procedure AcquireTokensAndTokenCacheByAuthorizationCode(ClientId: Text; ClientSecret: SecretText; OAuthAuthorityUrl: Text; RedirectURL: Text; Scopes: List of [Text]; PromptInteraction: Enum "Prompt Interaction"; var AccessToken: SecretText; var IdToken: Text; var TokenCache: Text; var Error: Text)
    begin
        OAuth2Impl.AcquireTokensAndTokenCacheByAuthorizationCode(ClientId, ClientSecret, OAuthAuthorityUrl, RedirectURL, Scopes, PromptInteraction, AccessToken, IdToken, TokenCache, Error);
    end;

#pragma warning disable AS0105
    /// <summary>
    /// Gets the access token and token cache state with authorization code flow.
    /// </summary>
    /// <param name="ClientId">The Application (client) ID that the "Azure portal – App registrations" experience assigned to your app.</param>
    /// <param name="Certificate">The Base64-encoded certificate for the application (client) configured in the "Azure Portal - Certificates &amp; Secrets".</param>
    /// <param name="OAuthAuthorityUrl">The identity authorization provider URL.</param>
    /// <param name="RedirectURL">The redirectURL of your app, where authentication responses can be sent and received by your app. It must exactly match one of the redirectURLs you registered in the portal. If this parameter is empty, the default Business Central URL will be used.</param>
    /// <param name="Scopes">A list of scopes that you want the user to consent to.</param>
    /// <param name="PromptInteraction">Indicates the type of user interaction that is required.</param>
    /// <param name="AccessToken">Exit parameter containing the access token. When this parameter is empty, check the Error for a description of the error.</param>
    /// <param name="IdToken">Exit parameter containing the id token.</param>
    /// <param name="TokenCache">Exit parameter containing the token cache acquired when the access token was requested.</param>
    /// <param name="Error">Exit parameter containing the encountered error in the authorization code grant flow. This parameter will be empty in case the token is aquired successfuly.</param>
    [TryFunction]
    [Obsolete('Use AcquireTokensAndTokenCacheByAuthorizationCodeWithCertificate with SecretText data type for AccessToken and Certificate.', '25.0')]
    procedure AcquireTokensAndTokenCacheByAuthorizationCodeWithCertificate(ClientId: Text; Certificate: Text; OAuthAuthorityUrl: Text; RedirectURL: Text; Scopes: List of [Text]; PromptInteraction: Enum "Prompt Interaction"; var AccessToken: SecretText; var IdToken: Text; var TokenCache: Text; var Error: Text)
    begin
#pragma warning disable AL0432
        OAuth2Impl.AcquireTokensAndTokenCacheByAuthorizationCodeWithCertificate(ClientId, Certificate, OAuthAuthorityUrl, RedirectURL, Scopes, PromptInteraction, AccessToken, IdToken, TokenCache, Error);
#pragma warning restore AL0432
    end;
#pragma warning restore AS0105

    /// <summary>
    /// Gets the access token and token cache state with authorization code flow.
    /// </summary>
    /// <param name="ClientId">The Application (client) ID that the "Azure portal – App registrations" experience assigned to your app.</param>
    /// <param name="Certificate">The Base64-encoded certificate for the application (client) configured in the "Azure Portal - Certificates &amp; Secrets".</param>
    /// <param name="OAuthAuthorityUrl">The identity authorization provider URL.</param>
    /// <param name="RedirectURL">The redirectURL of your app, where authentication responses can be sent and received by your app. It must exactly match one of the redirectURLs you registered in the portal. If this parameter is empty, the default Business Central URL will be used.</param>
    /// <param name="Scopes">A list of scopes that you want the user to consent to.</param>
    /// <param name="PromptInteraction">Indicates the type of user interaction that is required.</param>
    /// <param name="AccessToken">Exit parameter containing the access token. When this parameter is empty, check the Error for a description of the error.</param>
    /// <param name="IdToken">Exit parameter containing the id token.</param>
    /// <param name="TokenCache">Exit parameter containing the token cache acquired when the access token was requested.</param>
    /// <param name="Error">Exit parameter containing the encountered error in the authorization code grant flow. This parameter will be empty in case the token is aquired successfuly.</param>
    [TryFunction]
    procedure AcquireTokensAndTokenCacheByAuthorizationCodeWithCertificate(ClientId: Text; Certificate: SecretText; OAuthAuthorityUrl: Text; RedirectURL: Text; Scopes: List of [Text]; PromptInteraction: Enum "Prompt Interaction"; var AccessToken: SecretText; var IdToken: Text; var TokenCache: Text; var Error: Text)
    begin
        OAuth2Impl.AcquireTokensAndTokenCacheByAuthorizationCodeWithCertificate(ClientId, Certificate, OAuthAuthorityUrl, RedirectURL, Scopes, PromptInteraction, AccessToken, IdToken, TokenCache, Error);
    end;

#pragma warning disable AS0105
    /// <summary>
    /// Gets the access token and token cache state with authorization code flow.
    /// </summary>
    /// <param name="ClientId">The Application (client) ID that the "Azure portal – App registrations" experience assigned to your app.</param>
    /// <param name="Certificate">The Base64-encoded certificate for the application (client) configured in the "Azure Portal - Certificates &amp; Secrets".</param>
    /// <param name="CertificatePassword">Password for the certificate.</param>
    /// <param name="OAuthAuthorityUrl">The identity authorization provider URL.</param>
    /// <param name="RedirectURL">The redirectURL of your app, where authentication responses can be sent and received by your app. It must exactly match one of the redirectURLs you registered in the portal. If this parameter is empty, the default Business Central URL will be used.</param>
    /// <param name="Scopes">A list of scopes that you want the user to consent to.</param>
    /// <param name="PromptInteraction">Indicates the type of user interaction that is required.</param>
    /// <param name="AccessToken">Exit parameter containing the access token. When this parameter is empty, check the Error for a description of the error.</param>
    /// <param name="IdToken">Exit parameter containing the id token.</param>
    /// <param name="TokenCache">Exit parameter containing the token cache acquired when the access token was requested.</param>
    /// <param name="Error">Exit parameter containing the encountered error in the authorization code grant flow. This parameter will be empty in case the token is aquired successfuly.</param>
    [TryFunction]
    [Obsolete('Use AcquireTokensAndTokenCacheByAuthorizationCodeWithCertificate with SecretText data type for AccessToken, Certificate and CertificatePassword.', '25.0')]
    procedure AcquireTokensAndTokenCacheByAuthorizationCodeWithCertificate(ClientId: Text; Certificate: Text; CertificatePassword: SecretText; OAuthAuthorityUrl: Text; RedirectURL: Text; Scopes: List of [Text]; PromptInteraction: Enum "Prompt Interaction"; var AccessToken: SecretText; var IdToken: Text; var TokenCache: Text; var Error: Text)
    begin
#pragma warning disable AL0432
        OAuth2Impl.AcquireTokensAndTokenCacheByAuthorizationCodeWithCertificate(ClientId, Certificate, CertificatePassword, OAuthAuthorityUrl, RedirectURL, Scopes, PromptInteraction, AccessToken, IdToken, TokenCache, Error);
#pragma warning restore AL0432
    end;
#pragma warning restore AS0105

    /// <summary>
    /// Gets the access token and token cache state with authorization code flow.
    /// </summary>
    /// <param name="ClientId">The Application (client) ID that the "Azure portal – App registrations" experience assigned to your app.</param>
    /// <param name="Certificate">The Base64-encoded certificate for the application (client) configured in the "Azure Portal - Certificates &amp; Secrets".</param>
    /// <param name="CertificatePassword">Password for the certificate.</param>
    /// <param name="OAuthAuthorityUrl">The identity authorization provider URL.</param>
    /// <param name="RedirectURL">The redirectURL of your app, where authentication responses can be sent and received by your app. It must exactly match one of the redirectURLs you registered in the portal. If this parameter is empty, the default Business Central URL will be used.</param>
    /// <param name="Scopes">A list of scopes that you want the user to consent to.</param>
    /// <param name="PromptInteraction">Indicates the type of user interaction that is required.</param>
    /// <param name="AccessToken">Exit parameter containing the access token. When this parameter is empty, check the Error for a description of the error.</param>
    /// <param name="IdToken">Exit parameter containing the id token.</param>
    /// <param name="TokenCache">Exit parameter containing the token cache acquired when the access token was requested.</param>
    /// <param name="Error">Exit parameter containing the encountered error in the authorization code grant flow. This parameter will be empty in case the token is aquired successfuly.</param>
    [TryFunction]
    procedure AcquireTokensAndTokenCacheByAuthorizationCodeWithCertificate(ClientId: Text; Certificate: SecretText; CertificatePassword: SecretText; OAuthAuthorityUrl: Text; RedirectURL: Text; Scopes: List of [Text]; PromptInteraction: Enum "Prompt Interaction"; var AccessToken: SecretText; var IdToken: Text; var TokenCache: Text; var Error: Text)
    begin
        OAuth2Impl.AcquireTokensAndTokenCacheByAuthorizationCodeWithCertificate(ClientId, Certificate, CertificatePassword, OAuthAuthorityUrl, RedirectURL, Scopes, PromptInteraction, AccessToken, IdToken, TokenCache, Error);
    end;

    /// <summary>
    /// Gets the authentication token via the On-Behalf-Of OAuth2 v2.0 protocol flow.
    /// </summary>
    /// <param name="RedirectURL">The redirectURL of your app, where authentication responses can be sent and received by your app. It must exactly match one of the redirectURLs you registered in the portal. If this parameter is empty, the default Business Central URL will be used.</param>
    /// <param name="Scopes">A list of scopes that you want the user to consent to.</param>
    /// <param name="AccessToken">Exit parameter containing the access token.</param>
    [Scope('OnPrem')]
    [TryFunction]
    procedure AcquireOnBehalfOfToken(RedirectURL: Text; Scopes: List of [Text]; var AccessToken: SecretText)
    begin
        OAuth2Impl.AcquireOnBehalfOfToken(RedirectURL, Scopes, AccessToken);
    end;

    /// <summary>
    /// Gets the authentication token via the On-Behalf-Of OAuth2 v2.0 protocol flow.
    /// </summary>
    /// <param name="RedirectURL">The redirectURL of your app, where authentication responses can be sent and received by your app. It must exactly match one of the redirectURLs you registered in the portal. If this parameter is empty, the default Business Central URL will be used.</param>
    /// <param name="Scopes">A list of scopes that you want the user to consent to.</param>
    /// <param name="AccessToken">Exit parameter containing the access token.</param>
    /// <param name="IdToken">Exit parameter containing the id token.</param>
    [Scope('OnPrem')]
    [TryFunction]
    procedure AcquireOnBehalfOfTokens(RedirectURL: Text; Scopes: List of [Text]; var AccessToken: SecretText; var IdToken: Text)
    begin
        OAuth2Impl.AcquireOnBehalfOfTokens(RedirectURL, Scopes, AccessToken, IdToken);
    end;

    /// <summary>
    /// Request the permissions from a directory admin.
    /// </summary>
    /// <param name="ClientId">The Application (client) ID that the Azure portal – App registrations experience assigned to your app.</param>
    /// <param name="OAuthAuthorityUrl">The identity authorization provider URL.</param>
    /// <param name="RedirectURL">The redirectURL of your app, where authentication responses can be sent and received by your app. It must exactly match one of the redirectURLs you registered in the portal. If this parameter is empty, the default Business Central URL will be used.</param>
    /// <param name="HasGrantConsentSucceeded">Exit parameter indicating the success of granting application permissions.</param>
    /// <param name="PermissionGrantError">Exit parameter containing the encountered error in the application permissions grant. This parameter will be empty in case the flow is completed successfuly.</param>
    [TryFunction]
    procedure RequestClientCredentialsAdminPermissions(ClientId: Text; OAuthAuthorityUrl: Text; RedirectURL: Text; var HasGrantConsentSucceeded: Boolean; var PermissionGrantError: Text)
    begin
        OAuth2Impl.RequestClientCredentialsAdminPermissions(ClientId, OAuthAuthorityUrl, RedirectURL, HasGrantConsentSucceeded, PermissionGrantError);
    end;

    /// <summary>
    /// Gets the access token via the Client Credentials OAuth2 v1.0 grant flow.
    /// </summary>
    /// <param name="ClientId">The Application (client) ID that the Azure portal – App registrations experience assigned to your app.</param>
    /// <param name="ClientSecret">The Application (client) secret configured in the Azure Portal - Certificates &amp; Secrets.</param>
    /// <param name="OAuthAuthorityUrl">The identity authorization provider URL.</param>
    /// <param name="RedirectURL">The redirectURL of your app, where authentication responses can be sent and received by your app. It must exactly match one of the redirectURLs you registered in the portal. If this parameter is empty, the default Business Central URL will be used.</param>
    /// <param name="ResourceURL">The Application ID of the resource the application is requesting access to. This parameter can be empty.</param>
    /// <param name="AccessToken">Exit parameter containing the access token.</param>
    [TryFunction]
    procedure AcquireTokenWithClientCredentials(ClientId: Text; ClientSecret: SecretText; OAuthAuthorityUrl: Text; RedirectURL: Text; ResourceURL: Text; var AccessToken: SecretText)
    begin
        OAuth2Impl.AcquireTokenWithClientCredentials(ClientId, ClientSecret, OAuthAuthorityUrl, RedirectURL, ResourceURL, AccessToken);
    end;

    /// <summary>
    /// Gets the access token via the Client Credentials OAuth2 v2.0 grant flow.
    /// </summary>
    /// <param name="ClientId">The Application (client) ID that the Azure portal – App registrations experience assigned to your app.</param>
    /// <param name="ClientSecret">The Application (client) secret configured in the Azure Portal - Certificates &amp; Secrets.</param>
    /// <param name="OAuthAuthorityUrl">The identity authorization provider URL.</param>
    /// <param name="RedirectURL">The redirectURL of your app, where authentication responses can be sent and received by your app. It must exactly match one of the redirectURLs you registered in the portal. If this parameter is empty, the default Business Central URL will be used.</param>
    /// <param name="Scopes">A list of scopes that you want the user to consent to.</param>
    /// <param name="AccessToken">Exit parameter containing the access token.</param>
    [TryFunction]
    procedure AcquireTokenWithClientCredentials(ClientId: Text; ClientSecret: SecretText; OAuthAuthorityUrl: Text; RedirectURL: Text; Scopes: List of [Text]; var AccessToken: SecretText)
    begin
        OAuth2Impl.AcquireTokenWithClientCredentials(ClientId, ClientSecret, OAuthAuthorityUrl, RedirectURL, Scopes, AccessToken);
    end;

#pragma warning disable AS0105
    /// <summary>
    /// Gets the access token from cache or a refreshed token via OAuth2 v1.0 protocol.
    /// </summary>
    /// <param name="ClientId">The Application (client) ID that the Azure portal – App registrations experience assigned to your app.</param>
    /// <param name="Certificate">The Base64-encoded certificate for the Application (client) configured in the Azure Portal - Certificates &amp; Secrets.</param>
    /// <param name="RedirectURL">The redirectURL of your app, where authentication responses can be sent and received by your app. It must exactly match one of the redirectURLs you registered in the portal. If this parameter is empty, the default Business Central URL will be used.</param>
    /// <param name="OAuthAuthorityUrl">The identity authorization provider URL.</param>
    /// <param name="ResourceURL">The Application ID of the resource the application is requesting access to. This parameter can be empty.</param>
    /// <param name="AccessToken">Exit parameter containing the access token.</param>
    [TryFunction]
    [Obsolete('Use AcquireAuthorizationCodeTokenFromCacheWithCertificate with SecretText data type for AccessToken and Certificate.', '25.0')]
    procedure AcquireAuthorizationCodeTokenFromCacheWithCertificate(ClientId: Text; Certificate: Text; RedirectURL: Text; OAuthAuthorityUrl: Text; ResourceURL: Text; var AccessToken: SecretText)
    begin
#pragma warning disable AL0432
        OAuth2Impl.AcquireTokenFromCacheWithCertificate(RedirectURL, ClientId, Certificate, OAuthAuthorityUrl, ResourceURL, AccessToken);
#pragma warning restore AL0432
    end;
#pragma warning restore AS0105

    /// <summary>
    /// Gets the access token from cache or a refreshed token via OAuth2 v1.0 protocol.
    /// </summary>
    /// <param name="ClientId">The Application (client) ID that the Azure portal – App registrations experience assigned to your app.</param>
    /// <param name="Certificate">The Base64-encoded certificate for the Application (client) configured in the Azure Portal - Certificates &amp; Secrets.</param>
    /// <param name="RedirectURL">The redirectURL of your app, where authentication responses can be sent and received by your app. It must exactly match one of the redirectURLs you registered in the portal. If this parameter is empty, the default Business Central URL will be used.</param>
    /// <param name="OAuthAuthorityUrl">The identity authorization provider URL.</param>
    /// <param name="ResourceURL">The Application ID of the resource the application is requesting access to. This parameter can be empty.</param>
    /// <param name="AccessToken">Exit parameter containing the access token.</param>
    [TryFunction]
    procedure AcquireAuthorizationCodeTokenFromCacheWithCertificate(ClientId: Text; Certificate: SecretText; RedirectURL: Text; OAuthAuthorityUrl: Text; ResourceURL: Text; var AccessToken: SecretText)
    begin
        OAuth2Impl.AcquireTokenFromCacheWithCertificate(RedirectURL, ClientId, Certificate, OAuthAuthorityUrl, ResourceURL, AccessToken);
    end;

#pragma warning disable AS0105
    /// <summary>
    /// Gets the access token from cache or a refreshed token via OAuth2 v1.0 protocol.
    /// </summary>
    /// <param name="ClientId">The Application (client) ID that the Azure portal – App registrations experience assigned to your app.</param>
    /// <param name="Certificate">The Base64-encoded certificate for the Application (client) configured in the Azure Portal - Certificates &amp; Secrets.</param>
    /// <param name="CertificatePassword">Password for the certificate.</param>
    /// <param name="RedirectURL">The redirectURL of your app, where authentication responses can be sent and received by your app. It must exactly match one of the redirectURLs you registered in the portal. If this parameter is empty, the default Business Central URL will be used.</param>
    /// <param name="OAuthAuthorityUrl">The identity authorization provider URL.</param>
    /// <param name="ResourceURL">The Application ID of the resource the application is requesting access to. This parameter can be empty.</param>
    /// <param name="AccessToken">Exit parameter containing the access token.</param>
    [TryFunction]
    [Obsolete('Use AcquireAuthorizationCodeTokenFromCacheWithCertificate with SecretText data type for AccessToken, Certificate and CertificatePassword.', '25.0')]
    procedure AcquireAuthorizationCodeTokenFromCacheWithCertificate(ClientId: Text; Certificate: Text; CertificatePassword: SecretText; RedirectURL: Text; OAuthAuthorityUrl: Text; ResourceURL: Text; var AccessToken: SecretText)
    begin
#pragma warning disable AL0432
        OAuth2Impl.AcquireTokenFromCacheWithCertificate(RedirectURL, ClientId, Certificate, CertificatePassword, OAuthAuthorityUrl, ResourceURL, AccessToken);
#pragma warning restore AL0432
    end;
#pragma warning restore AS0105

    /// <summary>
    /// Gets the access token from cache or a refreshed token via OAuth2 v1.0 protocol.
    /// </summary>
    /// <param name="ClientId">The Application (client) ID that the Azure portal – App registrations experience assigned to your app.</param>
    /// <param name="Certificate">The Base64-encoded certificate for the Application (client) configured in the Azure Portal - Certificates &amp; Secrets.</param>
    /// <param name="CertificatePassword">Password for the certificate.</param>
    /// <param name="RedirectURL">The redirectURL of your app, where authentication responses can be sent and received by your app. It must exactly match one of the redirectURLs you registered in the portal. If this parameter is empty, the default Business Central URL will be used.</param>
    /// <param name="OAuthAuthorityUrl">The identity authorization provider URL.</param>
    /// <param name="ResourceURL">The Application ID of the resource the application is requesting access to. This parameter can be empty.</param>
    /// <param name="AccessToken">Exit parameter containing the access token.</param>
    [TryFunction]
    procedure AcquireAuthorizationCodeTokenFromCacheWithCertificate(ClientId: Text; Certificate: SecretText; CertificatePassword: SecretText; RedirectURL: Text; OAuthAuthorityUrl: Text; ResourceURL: Text; var AccessToken: SecretText)
    begin
        OAuth2Impl.AcquireTokenFromCacheWithCertificate(RedirectURL, ClientId, Certificate, CertificatePassword, OAuthAuthorityUrl, ResourceURL, AccessToken);
    end;

    /// <summary>
    /// Gets the access token from cache or a refreshed token via OAuth2 v2.0 protocol.
    /// </summary>
    /// <param name="ClientId">The Application (client) ID that the Azure portal – App registrations experience assigned to your app.</param>
    /// <param name="ClientSecret">The Application (client) secret configured in the Azure Portal - Certificates &amp; Secrets.</param>
    /// <param name="RedirectURL">The redirectURL of your app, where authentication responses can be sent and received by your app. It must exactly match one of the redirectURLs you registered in the portal. If this parameter is empty, the default Business Central URL will be used.</param>
    /// <param name="Scopes">A list of scopes that you want the user to consent to.</param>
    /// <param name="AccessToken">Exit parameter containing the access token.</param>
    [TryFunction]
    procedure AcquireAuthorizationCodeTokenFromCache(ClientId: Text; ClientSecret: SecretText; RedirectURL: Text; OAuthAuthorityUrl: Text; Scopes: List of [Text]; var AccessToken: SecretText)
    begin
        OAuth2Impl.AcquireTokenFromCache(RedirectURL, ClientId, ClientSecret, OAuthAuthorityUrl, Scopes, AccessToken);
    end;

    /// <summary>
    /// Gets the access token from cache or a refreshed token via OAuth2 v2.0 protocol.
    /// </summary>
    /// <param name="ClientId">The Application (client) ID that the Azure portal – App registrations experience assigned to your app.</param>
    /// <param name="ClientSecret">The Application (client) secret configured in the Azure Portal - Certificates &amp; Secrets.</param>
    /// <param name="RedirectURL">The redirectURL of your app, where authentication responses can be sent and received by your app. It must exactly match one of the redirectURLs you registered in the portal. If this parameter is empty, the default Business Central URL will be used.</param>
    /// <param name="Scopes">A list of scopes that you want the user to consent to.</param>
    /// <param name="AccessToken">Exit parameter containing the access token.</param>
    /// <param name="IdToken">Exit parameter containing the id token.</param>
    [TryFunction]
    procedure AcquireTokensFromCache(ClientId: Text; ClientSecret: SecretText; RedirectURL: Text; OAuthAuthorityUrl: Text; Scopes: List of [Text]; var AccessToken: SecretText; var IdToken: Text)
    begin
        OAuth2Impl.AcquireTokensFromCache(RedirectURL, ClientId, ClientSecret, OAuthAuthorityUrl, Scopes, AccessToken, IdToken);
    end;

#pragma warning disable AS0105
    /// <summary>
    /// Gets the access token from cache or a refreshed token via OAuth2 v2.0 protocol.
    /// </summary>
    /// <param name="ClientId">The Application (client) ID that the Azure portal – App registrations experience assigned to your app.</param>
    /// <param name="Certificate">The Base64-encoded certificate for the Application (client) configured in the Azure Portal - Certificates &amp; Secrets.</param>
    /// <param name="RedirectURL">The redirectURL of your app, where authentication responses can be sent and received by your app. It must exactly match one of the redirectURLs you registered in the portal. If this parameter is empty, the default Business Central URL will be used.</param>
    /// <param name="Scopes">A list of scopes that you want the user to consent to.</param>
    /// <param name="AccessToken">Exit parameter containing the access token.</param>
    [TryFunction]
    [Obsolete('Use AcquireAuthorizationCodeTokenFromCacheWithCertificate with SecretText data type for AccessToken and Certificate.', '25.0')]
    procedure AcquireAuthorizationCodeTokenFromCacheWithCertificate(ClientId: Text; Certificate: Text; RedirectURL: Text; OAuthAuthorityUrl: Text; Scopes: List of [Text]; var AccessToken: SecretText)
    begin
#pragma warning disable AL0432
        OAuth2Impl.AcquireTokenFromCacheWithCertificate(RedirectURL, ClientId, Certificate, OAuthAuthorityUrl, Scopes, AccessToken);
#pragma warning restore AL0432
    end;
#pragma warning restore AS0105

    /// <summary>
    /// Gets the access token from cache or a refreshed token via OAuth2 v2.0 protocol.
    /// </summary>
    /// <param name="ClientId">The Application (client) ID that the Azure portal – App registrations experience assigned to your app.</param>
    /// <param name="Certificate">The Base64-encoded certificate for the Application (client) configured in the Azure Portal - Certificates &amp; Secrets.</param>
    /// <param name="RedirectURL">The redirectURL of your app, where authentication responses can be sent and received by your app. It must exactly match one of the redirectURLs you registered in the portal. If this parameter is empty, the default Business Central URL will be used.</param>
    /// <param name="Scopes">A list of scopes that you want the user to consent to.</param>
    /// <param name="AccessToken">Exit parameter containing the access token.</param>
    [TryFunction]
    procedure AcquireAuthorizationCodeTokenFromCacheWithCertificate(ClientId: Text; Certificate: SecretText; RedirectURL: Text; OAuthAuthorityUrl: Text; Scopes: List of [Text]; var AccessToken: SecretText)
    begin
        OAuth2Impl.AcquireTokenFromCacheWithCertificate(RedirectURL, ClientId, Certificate, OAuthAuthorityUrl, Scopes, AccessToken);
    end;

#pragma warning disable AS0105
    /// <summary>
    /// Gets the access token from cache or a refreshed token via OAuth2 v2.0 protocol.
    /// </summary>
    /// <param name="ClientId">The Application (client) ID that the Azure portal – App registrations experience assigned to your app.</param>
    /// <param name="Certificate">The Base64-encoded certificate for the Application (client) configured in the Azure Portal - Certificates &amp; Secrets.</param>
    /// <param name="CertificatePassword">Password for the certificate.</param>
    /// <param name="RedirectURL">The redirectURL of your app, where authentication responses can be sent and received by your app. It must exactly match one of the redirectURLs you registered in the portal. If this parameter is empty, the default Business Central URL will be used.</param>
    /// <param name="Scopes">A list of scopes that you want the user to consent to.</param>
    /// <param name="AccessToken">Exit parameter containing the access token.</param>
    [TryFunction]
    [Obsolete('Use AcquireAuthorizationCodeTokenFromCacheWithCertificate with SecretText data type for AccessToken, Certificate and CertificatePassword.', '25.0')]
    procedure AcquireAuthorizationCodeTokenFromCacheWithCertificate(ClientId: Text; Certificate: Text; CertificatePassword: SecretText; RedirectURL: Text; OAuthAuthorityUrl: Text; Scopes: List of [Text]; var AccessToken: SecretText)
    begin
#pragma warning disable AL0432
        OAuth2Impl.AcquireTokenFromCacheWithCertificate(RedirectURL, ClientId, Certificate, CertificatePassword, OAuthAuthorityUrl, Scopes, AccessToken);
#pragma warning restore AL0432
    end;
#pragma warning restore AS0105

    /// <summary>
    /// Gets the access token from cache or a refreshed token via OAuth2 v2.0 protocol.
    /// </summary>
    /// <param name="ClientId">The Application (client) ID that the Azure portal – App registrations experience assigned to your app.</param>
    /// <param name="Certificate">The Base64-encoded certificate for the Application (client) configured in the Azure Portal - Certificates &amp; Secrets.</param>
    /// <param name="CertificatePassword">Password for the certificate.</param>
    /// <param name="RedirectURL">The redirectURL of your app, where authentication responses can be sent and received by your app. It must exactly match one of the redirectURLs you registered in the portal. If this parameter is empty, the default Business Central URL will be used.</param>
    /// <param name="Scopes">A list of scopes that you want the user to consent to.</param>
    /// <param name="AccessToken">Exit parameter containing the access token.</param>
    [TryFunction]
    procedure AcquireAuthorizationCodeTokenFromCacheWithCertificate(ClientId: Text; Certificate: SecretText; CertificatePassword: SecretText; RedirectURL: Text; OAuthAuthorityUrl: Text; Scopes: List of [Text]; var AccessToken: SecretText)
    begin
        OAuth2Impl.AcquireTokenFromCacheWithCertificate(RedirectURL, ClientId, Certificate, CertificatePassword, OAuthAuthorityUrl, Scopes, AccessToken);
    end;

#pragma warning disable AS0105
    /// <summary>
    /// Gets the access token from cache or a refreshed token via OAuth2 v2.0 protocol.
    /// </summary>
    /// <param name="ClientId">The Application (client) ID that the Azure portal – App registrations experience assigned to your app.</param>
    /// <param name="Certificate">The Base64-encoded certificate for the Application (client) configured in the Azure Portal - Certificates &amp; Secrets.</param>
    /// <param name="OAuthAuthorityUrl">The identity authorization provider URL.</param>
    /// <param name="RedirectURL">The redirectURL of your app, where authentication responses can be sent and received by your app. It must exactly match one of the redirectURLs you registered in the portal. If this parameter is empty, the default Business Central URL will be used.</param>
    /// <param name="Scopes">A list of scopes that you want the user to consent to.</param>
    /// <param name="AccessToken">Exit parameter containing the access token.</param>
    /// <param name="IdToken">Exit parameter containing the id token.</param>
    [TryFunction]
    [Obsolete('Use AcquireTokensFromCacheWithCertificate with SecretText data type for AccessToken and Certificate.', '25.0')]
    procedure AcquireTokensFromCacheWithCertificate(ClientId: Text; Certificate: Text; RedirectURL: Text; OAuthAuthorityUrl: Text; Scopes: List of [Text]; var AccessToken: SecretText; var IdToken: Text)
    begin
#pragma warning disable AL0432
        OAuth2Impl.AcquireTokensFromCacheWithCertificate(RedirectURL, ClientId, Certificate, OAuthAuthorityUrl, Scopes, AccessToken, IdToken);
#pragma warning restore AL0432
    end;
#pragma warning restore AS0105

    /// <summary>
    /// Gets the access token from cache or a refreshed token via OAuth2 v2.0 protocol.
    /// </summary>
    /// <param name="ClientId">The Application (client) ID that the Azure portal – App registrations experience assigned to your app.</param>
    /// <param name="Certificate">The Base64-encoded certificate for the Application (client) configured in the Azure Portal - Certificates &amp; Secrets.</param>
    /// <param name="OAuthAuthorityUrl">The identity authorization provider URL.</param>
    /// <param name="RedirectURL">The redirectURL of your app, where authentication responses can be sent and received by your app. It must exactly match one of the redirectURLs you registered in the portal. If this parameter is empty, the default Business Central URL will be used.</param>
    /// <param name="Scopes">A list of scopes that you want the user to consent to.</param>
    /// <param name="AccessToken">Exit parameter containing the access token.</param>
    /// <param name="IdToken">Exit parameter containing the id token.</param>
    [TryFunction]
    procedure AcquireTokensFromCacheWithCertificate(ClientId: Text; Certificate: SecretText; RedirectURL: Text; OAuthAuthorityUrl: Text; Scopes: List of [Text]; var AccessToken: SecretText; var IdToken: Text)
    begin
        OAuth2Impl.AcquireTokensFromCacheWithCertificate(RedirectURL, ClientId, Certificate, OAuthAuthorityUrl, Scopes, AccessToken, IdToken);
    end;

#pragma warning disable AS0105
    /// <summary>
    /// Gets the access token from cache or a refreshed token via OAuth2 v2.0 protocol.
    /// </summary>
    /// <param name="ClientId">The Application (client) ID that the Azure portal – App registrations experience assigned to your app.</param>
    /// <param name="Certificate">The Base64-encoded certificate for the Application (client) configured in the Azure Portal - Certificates &amp; Secrets.</param>
    /// <param name="CertificatePassword">Password for the certificate.</param>
    /// <param name="OAuthAuthorityUrl">The identity authorization provider URL.</param>
    /// <param name="RedirectURL">The redirectURL of your app, where authentication responses can be sent and received by your app. It must exactly match one of the redirectURLs you registered in the portal. If this parameter is empty, the default Business Central URL will be used.</param>
    /// <param name="Scopes">A list of scopes that you want the user to consent to.</param>
    /// <param name="AccessToken">Exit parameter containing the access token.</param>
    /// <param name="IdToken">Exit parameter containing the id token.</param>
    [TryFunction]
    [Obsolete('Use AcquireTokensWithCertificate with SecretText data type for AccessToken, Certificate and CertificatePassword.', '25.0')]
    procedure AcquireTokensFromCacheWithCertificate(ClientId: Text; Certificate: Text; CertificatePassword: SecretText; RedirectURL: Text; OAuthAuthorityUrl: Text; Scopes: List of [Text]; var AccessToken: SecretText; var IdToken: Text)
    begin
#pragma warning disable AL0432
        OAuth2Impl.AcquireTokensFromCacheWithCertificate(RedirectURL, ClientId, Certificate, CertificatePassword, OAuthAuthorityUrl, Scopes, AccessToken, IdToken);
#pragma warning restore AL0432
    end;
#pragma warning restore AS0105

    /// <summary>
    /// Gets the access token from cache or a refreshed token via OAuth2 v2.0 protocol.
    /// </summary>
    /// <param name="ClientId">The Application (client) ID that the Azure portal – App registrations experience assigned to your app.</param>
    /// <param name="Certificate">The Base64-encoded certificate for the Application (client) configured in the Azure Portal - Certificates &amp; Secrets.</param>
    /// <param name="CertificatePassword">Password for the certificate.</param>
    /// <param name="OAuthAuthorityUrl">The identity authorization provider URL.</param>
    /// <param name="RedirectURL">The redirectURL of your app, where authentication responses can be sent and received by your app. It must exactly match one of the redirectURLs you registered in the portal. If this parameter is empty, the default Business Central URL will be used.</param>
    /// <param name="Scopes">A list of scopes that you want the user to consent to.</param>
    /// <param name="AccessToken">Exit parameter containing the access token.</param>
    /// <param name="IdToken">Exit parameter containing the id token.</param>
    [TryFunction]
    procedure AcquireTokensFromCacheWithCertificate(ClientId: Text; Certificate: SecretText; CertificatePassword: SecretText; RedirectURL: Text; OAuthAuthorityUrl: Text; Scopes: List of [Text]; var AccessToken: SecretText; var IdToken: Text)
    begin
        OAuth2Impl.AcquireTokensFromCacheWithCertificate(RedirectURL, ClientId, Certificate, CertificatePassword, OAuthAuthorityUrl, Scopes, AccessToken, IdToken);
    end;

#pragma warning disable AS0105
    /// <summary>
    /// Gets the access token via OAuth2 v2.0 protocol, authenticating as a service principal (as the app whose credentials you are providing).
    /// </summary>
    /// <param name="ClientId">The Application (client) ID that the Azure portal – App registrations experience assigned to your app.</param>
    /// <param name="Certificate">The Base64-encoded certificate for the Application (client) configured in the Azure Portal - Certificates &amp; Secrets.</param>
    /// <param name="OAuthAuthorityUrl">The identity authorization provider URL.</param>
    /// <param name="RedirectURL">The redirectURL of your app, where authentication responses can be sent and received by your app. It must exactly match one of the redirectURLs you registered in the portal. If this parameter is empty, the default Business Central URL will be used.</param>
    /// <param name="Scopes">A list of scopes that you want the user to consent to.</param>
    /// <param name="AccessToken">Exit parameter containing the access token.</param>
    /// <param name="IdToken">Exit parameter containing the id token.</param>
    [TryFunction]
    [Obsolete('Use AcquireTokensWithCertificate with SecretText data type for AccessToken and Certificate.', '25.0')]
    procedure AcquireTokensWithCertificate(ClientId: Text; Certificate: Text; RedirectURL: Text; OAuthAuthorityUrl: Text; Scopes: List of [Text]; var AccessToken: SecretText; var IdToken: Text)
    begin
#pragma warning disable AL0432
        OAuth2Impl.AcquireTokensWithCertificate(RedirectURL, ClientId, Certificate, OAuthAuthorityUrl, Scopes, AccessToken, IdToken);
#pragma warning restore AL0432
    end;
#pragma warning restore AS0105

    /// <summary>
    /// Gets the access token via OAuth2 v2.0 protocol, authenticating as a service principal (as the app whose credentials you are providing).
    /// </summary>
    /// <param name="ClientId">The Application (client) ID that the Azure portal – App registrations experience assigned to your app.</param>
    /// <param name="Certificate">The Base64-encoded certificate for the Application (client) configured in the Azure Portal - Certificates &amp; Secrets.</param>
    /// <param name="OAuthAuthorityUrl">The identity authorization provider URL.</param>
    /// <param name="RedirectURL">The redirectURL of your app, where authentication responses can be sent and received by your app. It must exactly match one of the redirectURLs you registered in the portal. If this parameter is empty, the default Business Central URL will be used.</param>
    /// <param name="Scopes">A list of scopes that you want the user to consent to.</param>
    /// <param name="AccessToken">Exit parameter containing the access token.</param>
    /// <param name="IdToken">Exit parameter containing the id token.</param>
    [TryFunction]
    procedure AcquireTokensWithCertificate(ClientId: Text; Certificate: SecretText; RedirectURL: Text; OAuthAuthorityUrl: Text; Scopes: List of [Text]; var AccessToken: SecretText; var IdToken: Text)
    begin
        OAuth2Impl.AcquireTokensWithCertificate(RedirectURL, ClientId, Certificate, OAuthAuthorityUrl, Scopes, AccessToken, IdToken);
    end;

#pragma warning disable AS0105
    /// <summary>
    /// Gets the access token via OAuth2 v2.0 protocol, authenticating as a service principal (as the app whose credentials you are providing).
    /// </summary>
    /// <param name="ClientId">The Application (client) ID that the Azure portal – App registrations experience assigned to your app.</param>
    /// <param name="Certificate">The Base64-encoded certificate for the Application (client) configured in the Azure Portal - Certificates &amp; Secrets.</param>
    /// <param name="CertificatePassword">Password for the certificate.</param>
    /// <param name="OAuthAuthorityUrl">The identity authorization provider URL.</param>
    /// <param name="RedirectURL">The redirectURL of your app, where authentication responses can be sent and received by your app. It must exactly match one of the redirectURLs you registered in the portal. If this parameter is empty, the default Business Central URL will be used.</param>
    /// <param name="Scopes">A list of scopes that you want the user to consent to.</param>
    /// <param name="AccessToken">Exit parameter containing the access token.</param>
    /// <param name="IdToken">Exit parameter containing the id token.</param>
    [TryFunction]
    [Obsolete('Use AcquireTokensWithCertificate with SecretText data type for AccessToken, Certificate and CertificatePassword.', '25.0')]
    procedure AcquireTokensWithCertificate(ClientId: Text; Certificate: Text; CertificatePassword: SecretText; RedirectURL: Text; OAuthAuthorityUrl: Text; Scopes: List of [Text]; var AccessToken: SecretText; var IdToken: Text)
    begin
#pragma warning disable AL0432
        OAuth2Impl.AcquireTokensWithCertificate(RedirectURL, ClientId, Certificate, CertificatePassword, OAuthAuthorityUrl, Scopes, AccessToken, IdToken);
#pragma warning restore AL0432
    end;
#pragma warning restore AS0105

    /// <summary>
    /// Gets the access token via OAuth2 v2.0 protocol, authenticating as a service principal (as the app whose credentials you are providing).
    /// </summary>
    /// <param name="ClientId">The Application (client) ID that the Azure portal – App registrations experience assigned to your app.</param>
    /// <param name="Certificate">The Base64-encoded certificate for the Application (client) configured in the Azure Portal - Certificates &amp; Secrets.</param>
    /// <param name="CertificatePassword">Password for the certificate.</param>
    /// <param name="OAuthAuthorityUrl">The identity authorization provider URL.</param>
    /// <param name="RedirectURL">The redirectURL of your app, where authentication responses can be sent and received by your app. It must exactly match one of the redirectURLs you registered in the portal. If this parameter is empty, the default Business Central URL will be used.</param>
    /// <param name="Scopes">A list of scopes that you want the user to consent to.</param>
    /// <param name="AccessToken">Exit parameter containing the access token.</param>
    /// <param name="IdToken">Exit parameter containing the id token.</param>
    [TryFunction]
    procedure AcquireTokensWithCertificate(ClientId: Text; Certificate: SecretText; CertificatePassword: SecretText; RedirectURL: Text; OAuthAuthorityUrl: Text; Scopes: List of [Text]; var AccessToken: SecretText; var IdToken: Text)
    begin
        OAuth2Impl.AcquireTokensWithCertificate(RedirectURL, ClientId, Certificate, CertificatePassword, OAuthAuthorityUrl, Scopes, AccessToken, IdToken);
    end;

    /// <summary>
    /// Gets the access and refresh token via the On-Behalf-Of OAuth2 v2.0 protocol flow.
    /// </summary>
    /// <param name="OAuthAuthorityUrl">The identity authorization provider URL.</param>
    /// <param name="RedirectURL">The redirectURL of your app, where authentication responses can be sent and received by your app. It must exactly match one of the redirectURLs you registered in the portal. If this parameter is empty, the default Business Central URL will be used.</param>
    /// <param name="Scopes">A list of scopes that you want the user to consent to.</param>
    /// <param name="AccessToken">Exit parameter containing the access token.</param>
    /// <param name="TokenCache">Exit parameter containing the token cache acquired when the access token was requested .</param>
    [Scope('OnPrem')]
    [TryFunction]
    procedure AcquireOnBehalfAccessTokenAndTokenCache(OAuthAuthorityUrl: Text; RedirectURL: Text; Scopes: List of [Text]; var AccessToken: SecretText; var TokenCache: Text)
    begin
        OAuth2Impl.AcquireOnBehalfAccessTokenAndTokenCache(OAuthAuthorityUrl, RedirectURL, Scopes, AccessToken, TokenCache);
    end;

    /// <summary>
    /// Gets the access and refresh token via the On-Behalf-Of OAuth2 v2.0 protocol flow.
    /// </summary>
    /// <param name="OAuthAuthorityUrl">The identity authorization provider URL.</param>
    /// <param name="RedirectURL">The redirectURL of your app, where authentication responses can be sent and received by your app. It must exactly match one of the redirectURLs you registered in the portal. If this parameter is empty, the default Business Central URL will be used.</param>
    /// <param name="Scopes">A list of scopes that you want the user to consent to.</param>
    /// <param name="AccessToken">Exit parameter containing the access token.</param>
    /// <param name="IdToken">Exit parameter containing the id token.</param>
    /// <param name="TokenCache">Exit parameter containing the token cache acquired when the access token was requested .</param>
    [Scope('OnPrem')]
    [TryFunction]
    procedure AcquireOnBehalfTokensAndTokenCache(OAuthAuthorityUrl: Text; RedirectURL: Text; Scopes: List of [Text]; var AccessToken: SecretText; var IdToken: Text; var TokenCache: Text)
    begin
        OAuth2Impl.AcquireOnBehalfTokensAndTokenCache(OAuthAuthorityUrl, RedirectURL, Scopes, AccessToken, IdToken, TokenCache);
    end;

    /// <summary>
    /// Gets the token and token cache via the On-Behalf-Of OAuth2 v1.0 protocol flow.
    /// </summary>
    /// <param name="LoginHint">The user login hint, i.e. authentication email.</param>
    /// <param name="RedirectURL">The redirectURL of your app, where authentication responses can be sent and received by your app. It must exactly match one of the redirectURLs you registered in the portal. If this parameter is empty, the default Business Central URL will be used.</param>
    /// <param name="Scopes">A list of scopes that you want the user to consent to.</param>
    /// <param name="TokenCache">The token cache acquired when the access token was requested .</param>
    /// <param name="AccessToken">Exit parameter containing the access token.</param>
    /// <param name="NewTokenCache">Exit parameter containing the new token cache.</param>
    [Scope('OnPrem')]
    [TryFunction]
    procedure AcquireOnBehalfOfTokenByTokenCache(LoginHint: Text; RedirectURL: Text; Scopes: List of [Text]; TokenCache: Text; var AccessToken: SecretText; var NewTokenCache: Text)
    begin
        OAuth2Impl.AcquireOnBehalfOfTokenByTokenCache(LoginHint, RedirectURL, Scopes, TokenCache, AccessToken, NewTokenCache);
    end;

    /// <summary>
    /// Gets the token and token cache via the On-Behalf-Of OAuth2 v1.0 protocol flow.
    /// </summary>
    /// <param name="LoginHint">The user login hint, i.e. authentication email.</param>
    /// <param name="RedirectURL">The redirectURL of your app, where authentication responses can be sent and received by your app. It must exactly match one of the redirectURLs you registered in the portal. If this parameter is empty, the default Business Central URL will be used.</param>
    /// <param name="Scopes">A list of scopes that you want the user to consent to.</param>
    /// <param name="TokenCache">The token cache acquired when the access token was requested .</param>
    /// <param name="AccessToken">Exit parameter containing the access token.</param>
    /// <param name="IdToken">Exit parameter containing the id token.</param>
    /// <param name="NewTokenCache">Exit parameter containing the new token cache.</param>
    [Scope('OnPrem')]
    [TryFunction]
    procedure AcquireOnBehalfOfTokensByTokenCache(LoginHint: Text; RedirectURL: Text; Scopes: List of [Text]; TokenCache: Text; var AccessToken: SecretText; var IdToken: Text; var NewTokenCache: Text)
    begin
        OAuth2Impl.AcquireOnBehalfOfTokensByTokenCache(LoginHint, RedirectURL, Scopes, TokenCache, AccessToken, IdToken, NewTokenCache);
    end;

    /// <summary>
    /// Gets the token and token cache via the On-Behalf-Of OAuth2 v1.0 protocol flow.
    /// </summary>
    /// <param name="ClientId">The Application (client) ID that the Azure portal - App registrations experience assigned to your app.</param>
    /// <param name="ClientSecret">The Application (client) secret configured in the Azure Portal - Certificates &amp; Secrets.</param>
    /// <param name="LoginHint">The user login hint, i.e. authentication email.</param>
    /// <param name="RedirectURL">The redirectURL of your app, where authentication responses can be sent and received by your app. It must exactly match one of the redirectURLs you registered in the portal. If this parameter is empty, the default Business Central URL will be used.</param>
    /// <param name="Scopes">A list of scopes that you want the user to consent to.</param>
    /// <param name="TokenCache">The token cache acquired when the access token was requested .</param>
    /// <param name="AccessToken">Exit parameter containing the access token.</param>
    /// <param name="NewTokenCache">Exit parameter containing the new token cache.</param>
    [TryFunction]
    procedure AcquireOnBehalfOfTokenByTokenCache(ClientId: Text; ClientSecret: SecretText; LoginHint: Text; RedirectURL: Text; Scopes: List of [Text]; TokenCache: Text; var AccessToken: SecretText; var NewTokenCache: Text)
    begin
        OAuth2Impl.AcquireOnBehalfOfTokenByTokenCache(ClientId, ClientSecret, LoginHint, RedirectURL, Scopes, TokenCache, AccessToken, NewTokenCache);
    end;

    /// <summary>
    /// Gets the token and token cache via the On-Behalf-Of OAuth2 v1.0 protocol flow.
    /// </summary>
    /// <param name="ClientId">The Application (client) ID that the Azure portal - App registrations experience assigned to your app.</param>
    /// <param name="ClientSecret">The Application (client) secret configured in the Azure Portal - Certificates &amp; Secrets.</param>
    /// <param name="LoginHint">The user login hint, i.e. authentication email.</param>
    /// <param name="RedirectURL">The redirectURL of your app, where authentication responses can be sent and received by your app. It must exactly match one of the redirectURLs you registered in the portal. If this parameter is empty, the default Business Central URL will be used.</param>
    /// <param name="Scopes">A list of scopes that you want the user to consent to.</param>
    /// <param name="TokenCache">The token cache acquired when the access token was requested .</param>
    /// <param name="AccessToken">Exit parameter containing the access token.</param>
    /// <param name="IdToken">Exit parameter containing the id token.</param>
    /// <param name="NewTokenCache">Exit parameter containing the new token cache.</param>
    [TryFunction]
    procedure AcquireOnBehalfOfTokensByTokenCache(ClientId: Text; ClientSecret: SecretText; LoginHint: Text; RedirectURL: Text; Scopes: List of [Text]; TokenCache: Text; var AccessToken: SecretText; var IdToken: Text; var NewTokenCache: Text)
    begin
        OAuth2Impl.AcquireOnBehalfOfTokensByTokenCache(ClientId, ClientSecret, LoginHint, RedirectURL, Scopes, TokenCache, AccessToken, IdToken, NewTokenCache);
    end;

    /// <summary>
    /// Get the last error message that happened during acquiring of an access token.
    /// </summary>
    /// <returns>The last error message that happened during acquiring of an access token.</returns>
    procedure GetLastErrorMessage(): Text
    begin
        exit(OAuth2Impl.GetLastErrorMessage());
    end;

    /// <summary>
    /// Returns the default Business Central redirectURL
    /// </summary>
    [NonDebuggable]
    procedure GetDefaultRedirectURL(var RedirectUrl: Text)
    begin
        RedirectUrl := OAuth2Impl.GetDefaultRedirectUrl();
    end;
}