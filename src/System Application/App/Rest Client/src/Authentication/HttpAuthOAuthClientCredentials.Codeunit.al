/// <summary>Implementation of the "Http Authentication" interface for a request that requires basic authentication</summary>
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.RestClient;

codeunit 2361 "HttpAuthOAuthClientCredentials" implements "Http Authentication"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        BearerTxt: Label 'Bearer %1', Comment = '%1 - Token', Locked = true;
        ScopesGlobal: List of [Text];
        ClientCredentialsType: Option ClientSecret,Certificate;
        CertificateGlobal: SecretText;
        CertificatePasswordGlobal: SecretText;
        ClientSecretGlobal: SecretText;
        ClientIdGlobal: Text;
        OAuthAuthorityUrlGlobal: Text;

    /// <summary>
    /// Initializes the authentication object with the given AuthorityUrl, ClientId, ClientSecret and scopes
    /// </summary>
    /// <param name="OAuthAuthorityUrl">The OAuthAuthorityUrl to use for authentication</param>
    /// <param name="ClientId">The ClientId to use for authentication</param>
    /// <param name="ClientSecret">The ClientSecret to use for authentication</param>
    /// <param name="Scopes">The Scopes to use for authentication</param>
    procedure Initialize(OAuthAuthorityUrl: Text; ClientId: Text; ClientSecret: SecretText; Scopes: List of [Text])
    begin
        ClientCredentialsType := ClientCredentialsType::ClientSecret;
        OAuthAuthorityUrlGlobal := OAuthAuthorityUrl;
        ClientIdGlobal := ClientId;
        ClientSecretGlobal := ClientSecret;
        ScopesGlobal := Scopes;
    end;

    /// <summary>
    /// Initializes the authentication object with the given AuthorityUrl, ClientId, Certificate, Certifacte Password  and Scopes
    /// </summary>
    /// <param name="OAuthAuthorityUrl">The OAuthAuthorityUrl to use for authentication</param>
    /// <param name="ClientId">The ClientId to use for authentication</param>
    /// <param name="Certificate">The Base64-encoded certificate for the Application (client) configured in the Azure Portal - Certificates &amp; Secrets.</param>
    /// <param name="CertificatePassword">Password for the certificate.</param>
    /// <param name="Scopes">The Scopes to use for authentication</param>
    procedure Initialize(OAuthAuthorityUrl: Text; ClientId: Text; Certificate: SecretText; CertificatePassword: SecretText; Scopes: List of [Text])
    begin
        ClientCredentialsType := ClientCredentialsType::Certificate;
        OAuthAuthorityUrlGlobal := OAuthAuthorityUrl;
        ClientIdGlobal := ClientId;
        CertificateGlobal := Certificate;
        CertificatePasswordGlobal := CertificatePassword;
        ScopesGlobal := Scopes;
    end;

    /// <summary>Checks if authentication is required for the request</summary>
    /// <returns>Returns true because authentication is required</returns>
    procedure IsAuthenticationRequired(): Boolean;
    begin
        exit(true);
    end;

    /// <summary>Gets the authorization headers for the request</summary>
    /// <returns>Returns a dictionary of headers that need to be added to the request</returns>
    procedure GetAuthorizationHeaders() Header: Dictionary of [Text, SecretText];
    begin
        Header.Add('Authorization', SecretStrSubstNo(BearerTxt, GetToken()));
    end;

    local procedure GetToken(): SecretText
    var
        Success: Boolean;
        AccessToken: SecretText;
        ErrorText: Text;
    begin
        case
            ClientCredentialsType of
            ClientCredentialsType::ClientSecret:
                Success := AcquireTokenWithClientSecret(AccessToken, ErrorText);
            ClientCredentialsType::Certificate:
                Success := AcquireTokenWithCertificate(AccessToken, ErrorText);
        end;
        if not Success then
            Error(ErrorText);
        exit(AccessToken);
    end;

    local procedure AcquireTokenWithClientSecret(var AccessToken: SecretText; var ErrorText: Text): Boolean
    var
        OAuth2: Codeunit System.Security.Authentication.OAuth2;
        IsSuccess: Boolean;
        AquireTokenFailedErr: Label 'Acquire of token with Client Credentials failed.';
    begin
        if (not OAuth2.AcquireAuthorizationCodeTokenFromCache(ClientIdGlobal, ClientSecretGlobal, '', OAuthAuthorityUrlGlobal, ScopesGlobal, AccessToken) or (AccessToken.IsEmpty())) then
            OAuth2.AcquireTokenWithClientCredentials(ClientIdGlobal, ClientSecretGlobal, OAuthAuthorityUrlGlobal, '', ScopesGlobal, AccessToken);
        IsSuccess := not AccessToken.IsEmpty();

        if not IsSuccess then begin
            ErrorText := GetLastErrorText();

            if ErrorText = '' then
                ErrorText := AquireTokenFailedErr;
        end;

        exit(IsSuccess);
    end;

    local procedure AcquireTokenWithCertificate(var AccessToken: SecretText; var ErrorText: Text): Boolean
    var
        OAuth2: Codeunit System.Security.Authentication.OAuth2;
        IsSuccess: Boolean;
        IdToken: Text;
        AcquireTokenWithCertificateFailedErr: Label 'Acquire of token with Certificate failed.';
    begin
        ClearLastError();
        if (not OAuth2.AcquireTokensFromCacheWithCertificate(ClientIdGlobal, CertificateGlobal, CertificatePasswordGlobal, '', OAuthAuthorityUrlGlobal, ScopesGlobal, AccessToken, IdToken)) or (AccessToken.IsEmpty()) then
            OAuth2.AcquireTokensWithCertificate(ClientIdGlobal, CertificateGlobal, CertificatePasswordGlobal, '', OAuthAuthorityUrlGlobal, ScopesGlobal, AccessToken, IdToken);

        IsSuccess := not AccessToken.IsEmpty();

        if not IsSuccess then begin
            ErrorText := GetLastErrorText();
            if ErrorText = '' then
                ErrorText := AcquireTokenWithCertificateFailedErr;
        end;

        exit(IsSuccess);
    end;
}