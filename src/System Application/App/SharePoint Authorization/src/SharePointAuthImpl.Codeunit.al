// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Integration.Sharepoint;

codeunit 9143 "SharePoint Auth. - Impl."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure CreateAuthorizationCode(EntraTenantId: Text; ClientId: Text; ClientSecret: SecretText; Scopes: List of [Text]): Interface "SharePoint Authorization";
    var
        SharePointAuthorizationCode: Codeunit "SharePoint Authorization Code";
    begin
        SharePointAuthorizationCode.SetParameters(EntraTenantId, ClientId, ClientSecret, Scopes);
        exit(SharePointAuthorizationCode);
    end;

    procedure CreateClientCredentials(AadTenantId: Text; ClientId: Text; Certificate: SecretText; CertificatePassword: SecretText; Scopes: List of [Text]): Interface "SharePoint Authorization";
    var
        SharePointClientCredentials: Codeunit "SharePoint Client Credentials";
    begin
        SharePointClientCredentials.SetParameters(AadTenantId, ClientId, Certificate, CertificatePassword, Scopes);
        exit(SharePointClientCredentials);
    end;
}