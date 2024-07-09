// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Integration.Graph.Authorization;

using System.RestClient;

codeunit 9357 "Graph Auth. Client Credentials" implements "Graph Authorization"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        ClientCredentialsTokenAuthorityUrlTxt: Label 'https://login.microsoftonline.com/%1/oauth2/v2.0/token', Comment = '%1 = AAD tenant ID', Locked = true;
        Scopes: List of [Text];
        ClientCredentialsType: Option ClientSecret,Certificate;
        Certificate: SecretText;
        CertificatePassword: SecretText;
        ClientSecret: SecretText;
        AadTenantId: Text;
        ClientId: Text;

    procedure SetParameters(NewAadTenantId: Text; NewClientId: Text; NewClientSecret: SecretText; NewScopes: List of [Text])
    begin
        ClientCredentialsType := ClientCredentialsType::ClientSecret;
        AadTenantId := NewAadTenantId;
        ClientId := NewClientId;
        ClientSecret := NewClientSecret;
        Scopes := NewScopes;
    end;

    procedure SetParameters(NewAadTenantId: Text; NewClientId: Text; NewCertificate: SecretText; NewCertificatePassword: SecretText; NewScopes: List of [Text])
    begin
        ClientCredentialsType := ClientCredentialsType::Certificate;
        AadTenantId := NewAadTenantId;
        ClientId := NewClientId;
        Certificate := Certificate;
        CertificatePassword := NewCertificatePassword;
        Scopes := NewScopes;
    end;

    procedure GetHttpAuthorization(): Interface "Http Authentication"
    var
        HttpAuthOAuthClientCredentials: Codeunit HttpAuthOAuthClientCredentials;
        OAuthAuthorityUrl: Text;
    begin
        OAuthAuthorityUrl := StrSubstNo(ClientCredentialsTokenAuthorityUrlTxt, AadTenantId);
        case ClientCredentialsType of
            ClientCredentialsType::ClientSecret:
                HttpAuthOAuthClientCredentials.Initialize(OAuthAuthorityUrl, ClientId, ClientSecret, Scopes);
            ClientCredentialsType::Certificate:
                HttpAuthOAuthClientCredentials.Initialize(OAuthAuthorityUrl, ClientId, Certificate, CertificatePassword, Scopes);
        end;
        exit(HttpAuthOAuthClientCredentials);
    end;

}