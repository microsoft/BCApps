// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Integration.Sharepoint;

codeunit 9145 "SharePoint Client Credentials" implements "SharePoint Authorization"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        ClientId: Text;
        Certificate: SecretText;

        AadTenantId: Text;
        Scopes: List of [Text];
        CertificatePassword: SecretText;

    procedure SetParameters(NewAadTenantId: Text; NewClientId: Text; NewCertificate: SecretText; NewCertificatePassword: SecretText; NewScopes: List of [Text])

    begin
        AadTenantId := NewAadTenantId;
        ClientId := NewClientId;
        Certificate := NewCertificate;
        CertificatePassword := NewCertificatePassword;
        Scopes := NewScopes;
    end;

    procedure Authorize(var HttpRequestMessage: HttpRequestMessage);
    var
        Headers: HttpHeaders;
        BearerTxt: Label 'Bearer %1', Comment = '%1 = Token', Locked = true;
    begin
        HttpRequestMessage.GetHeaders(Headers);
        Headers.Add('Authorization', SecretStrSubstNo(BearerTxt, GetToken()));
    end;

    local procedure GetToken(): SecretText
    var
        ErrorText: Text;
        AccessToken: SecretText;
    begin
        if not AcquireToken(AccessToken, ErrorText) then
            Error(ErrorText);
        exit(AccessToken);
    end;

    local procedure AcquireToken(var AccessToken: SecretText; var ErrorText: Text): Boolean
    var
        OAuth2: Codeunit System.Security.Authentication.OAuth2;
        FailedErr: Label 'Failed to retrieve an access token.';
        ClientCredentialsTokenAuthorityUrlTxt: Label 'https://login.microsoftonline.com/%1/oauth2/v2.0/token', Comment = '%1 = AAD tenant ID', Locked = true;
        IsSuccess: Boolean;
        AuthorityUrl: Text;
        IdToken: Text;
    begin
        AuthorityUrl := StrSubstNo(ClientCredentialsTokenAuthorityUrlTxt, AadTenantId);
        ClearLastError();
        if (not OAuth2.AcquireTokensFromCacheWithCertificate(ClientId, Certificate, CertificatePassword, '', AuthorityUrl, Scopes, AccessToken, IdToken)) or (AccessToken.IsEmpty()) then
            OAuth2.AcquireTokensWithCertificate(ClientId, Certificate, CertificatePassword, '', AuthorityUrl, Scopes, AccessToken, IdToken);

        IsSuccess := not AccessToken.IsEmpty();

        if not IsSuccess then begin
            ErrorText := GetLastErrorText();
            if ErrorText = '' then
                ErrorText := FailedErr;
        end;

        exit(IsSuccess);
    end;
}