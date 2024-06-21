// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Integration.Graph.Authorization;

/// <summary>
/// Provides functionality for creating means for authorizing HTTP requests made to Microsoft Graph API.
/// </summary>
codeunit 9355 "Graph Authorization"
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    /// <summary>
    /// Creates an authorization mechanism with authentication code.
    /// </summary>
    /// <param name="AadTenantId">Azure Active Directory tenant ID</param>
    /// <param name="ClientId">The Application (client) ID that the Azure portal - App registrations experience assigned to your app.</param>        
    /// <param name="ClientSecret">The Application (client) secret configured in the "Azure Portal - Certificates &amp; Secrets".</param>    
    /// <param name="Scope">A scope that you want the user to consent to.</param>
    /// <returns>Codeunit instance implementing authorization interface</returns>
    procedure CreateAuthorizationWithClientCredentials(AadTenantId: Text; ClientId: Text; ClientSecret: SecretText; Scope: Text): Interface "Graph Authorization";
    var
        Scopes: List of [Text];
    begin
        Scopes.Add(Scope);
        exit(CreateAuthorizationWithClientCredentials(AadTenantId, ClientId, ClientSecret, Scopes));
    end;

    /// <summary>
    /// Creates an authorization mechanism with authentication code.
    /// </summary>
    /// <param name="AadTenantId">Azure Active Directory tenant ID</param>
    /// <param name="ClientId">The Application (client) ID that the Azure portal - App registrations experience assigned to your app.</param>        
    /// <param name="ClientSecret">The Application (client) secret configured in the "Azure Portal - Certificates &amp; Secrets".</param>
    /// <param name="Scopes">A list of scopes that you want the user to consent to.</param>
    /// <returns>Codeunit instance implementing authorization interface</returns>
    procedure CreateAuthorizationWithClientCredentials(AadTenantId: Text; ClientId: Text; ClientSecret: SecretText; Scopes: List of [Text]): Interface "Graph Authorization";
    var
        GraphAuthorizationImpl: Codeunit "Graph Authorization - Impl.";
    begin
        exit(GraphAuthorizationImpl.CreateAuthorizationWithClientCredentials(AadTenantId, ClientId, ClientSecret, Scopes));
    end;

    /// <summary>
    /// Creates an authorization mechanism with authentication code.
    /// </summary>
    /// <param name="AadTenantId">Azure Active Directory tenant ID</param>
    /// <param name="ClientId">The Application (client) ID that the Azure portal - App registrations experience assigned to your app.</param>
    /// <param name="Certificate">The Base64-encoded certificate for the Application (client) configured in the Azure Portal - Certificates &amp; Secrets.</param>
    /// <param name="CertificatePassword">Password for the certificate.</param>  
    /// <param name="Scope">A scope that you want the user to consent to.</param>
    /// <returns>Codeunit instance implementing authorization interface</returns>
    procedure CreateAuthorizationWithClientCredentials(AadTenantId: Text; ClientId: Text; Certificate: SecretText; CertificatePassword: SecretText; Scope: Text): Interface "Graph Authorization"
    var
        GraphAuthorizationImpl: Codeunit "Graph Authorization - Impl.";
        Scopes: List of [Text];
    begin
        Scopes.Add(Scope);
        exit(GraphAuthorizationImpl.CreateAuthorizationWithClientCredentials(AadTenantId, ClientId, Certificate, CertificatePassword, Scopes));
    end;

    /// <summary>
    /// Creates an authorization mechanism with authentication code.
    /// </summary>
    /// <param name="AadTenantId">Azure Active Directory tenant ID</param>
    /// <param name="ClientId">The Application (client) ID that the Azure portal - App registrations experience assigned to your app.</param>
    /// <param name="Certificate">The Base64-encoded certificate for the Application (client) configured in the Azure Portal - Certificates &amp; Secrets.</param>
    /// <param name="CertificatePassword">Password for the certificate.</param>  
    /// <param name="Scopes">A list of scopes that you want the user to consent to.</param>
    /// <returns>Codeunit instance implementing authorization interface</returns>
    procedure CreateAuthorizationWithClientCredentials(AadTenantId: Text; ClientId: Text; Certificate: SecretText; CertificatePassword: SecretText; Scopes: List of [Text]): Interface "Graph Authorization"
    var
        GraphAuthorizationImpl: Codeunit "Graph Authorization - Impl.";
    begin
        exit(GraphAuthorizationImpl.CreateAuthorizationWithClientCredentials(AadTenantId, ClientId, Certificate, CertificatePassword, Scopes));
    end;
}