// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Integration.Graph.Authorization;

codeunit 9356 "Graph Authorization - Impl."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure CreateAuthorizationWithClientCredentials(AadTenantId: Text; ClientId: Text; ClientSecret: SecretText; Scopes: List of [Text]): Interface "Graph Authorization";
    var
        GraphAuthClientCredentials: Codeunit "Graph Auth. Client Credentials";
    begin
        GraphAuthClientCredentials.SetParameters(AadTenantId, ClientId, ClientSecret, Scopes);
        exit(GraphAuthClientCredentials);
    end;

    procedure CreateAuthorizationWithClientCredentials(AadTenantId: Text; ClientId: Text; Certificate: SecretText; CertificatePassword: SecretText; Scopes: List of [Text]): Interface "Graph Authorization";
    var
        GraphAuthClientCredentials: Codeunit "Graph Auth. Client Credentials";
    begin
        GraphAuthClientCredentials.SetParameters(AadTenantId, ClientId, Certificate, CertificatePassword, Scopes);
        exit(GraphAuthClientCredentials);
    end;
}