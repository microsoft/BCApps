// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.TestLibraries.ERP;

using System;
using System.Azure.KeyVault;
using System.Environment;
using System.Security.AccessControl;
using System.Utilities;

/// <summary>
/// Provides authentication for API tests running in Microsoft test environments.
/// </summary>
codeunit 131022 "Microsoft Test Auth Provider" implements "API Test Auth Provider"
{
    Access = Internal;

    var
        ApiTestPasswordFileTok: Label 'C:\Run\my\ApiTestPassword', Locked = true;
        NavServerUserPasswordKeyTok: Label 'NavServerUserPassword', Locked = true;
        CachedAuthenticationPassword: SecretText;
        AuthenticationResolved: Boolean;
        AuthenticationRequired: Boolean;
        ContainerPasswordReadErr: Label 'The API test password could not be read from %1.', Comment = '%1 - Password file path';
        KeyVaultPasswordReadErr: Label 'The API test password could not be retrieved from the %1 secret.', Comment = '%1 - Azure Key Vault secret name';
        PasswordRetrievalFailedErr: Label 'The API test password could not be retrieved.';

    /// <summary>
    /// Configures authentication for a request targeting the current Business Central API service.
    /// </summary>
    /// <param name="TargetURL">The final request URL after URL overrides have been applied.</param>
    /// <param name="Authentication">The authentication context to configure.</param>
    procedure ConfigureAuthentication(TargetURL: Text; var Authentication: Codeunit "API Test Auth Context")
    var
        Password: SecretText;
    begin
        if not IsCurrentTestServiceURL(TargetURL) then
            exit;
        if not GetAuthenticationPassword(Password) then
            exit;

        Authentication.SetBasicAuthentication(UserId(), Password);
    end;

    local procedure GetAuthenticationPassword(var Password: SecretText): Boolean
    var
        User: Record User;
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        if AuthenticationResolved then begin
            if AuthenticationRequired then
                Password := CachedAuthenticationPassword;
            exit(AuthenticationRequired);
        end;

        if EnvironmentInfo.IsSaaSInfrastructure() then
            exit(CacheAuthenticationResult(Password, false));
        if ContainerPasswordFileExists() then begin
            if not TryGetContainerPassword(Password) then
                Error(ContainerPasswordReadErr, ApiTestPasswordFileTok);
            exit(CacheAuthenticationResult(Password, true));
        end;

        if not User.Get(UserSecurityId()) then
            exit(CacheAuthenticationResult(Password, false));
        if User."Windows Security ID" <> '' then
            exit(CacheAuthenticationResult(Password, false));

        if not TryGetNavEnlistmentPassword(Password) then
            Error(KeyVaultPasswordReadErr, NavServerUserPasswordKeyTok);

        exit(CacheAuthenticationResult(Password, true));
    end;

    local procedure CacheAuthenticationResult(Password: SecretText; IsRequired: Boolean): Boolean
    begin
        AuthenticationRequired := IsRequired;
        AuthenticationResolved := true;
        if IsRequired then
            CachedAuthenticationPassword := Password;
        exit(IsRequired);
    end;

    local procedure IsCurrentTestServiceURL(TargetURL: Text): Boolean
    var
        CurrentServiceUri: Codeunit Uri;
        TargetUri: Codeunit Uri;
    begin
        CurrentServiceUri.Init(GetUrl(ClientType::Api));
        TargetUri.Init(TargetURL);
        exit(
            (LowerCase(TargetUri.GetScheme()) = LowerCase(CurrentServiceUri.GetScheme())) and
            (LowerCase(TargetUri.GetAuthority()) = LowerCase(CurrentServiceUri.GetAuthority())));
    end;

    [Scope('OnPrem')]
    local procedure ContainerPasswordFileExists(): Boolean
    var
        File: DotNet File;
    begin
        exit(File.Exists(ApiTestPasswordFileTok));
    end;

    [TryFunction]
    local procedure TryGetContainerPassword(var Password: SecretText)
    var
        AzureKeyVault: Codeunit "Azure Key Vault";
        LibraryAzureKVMockMgmt: Codeunit "Library - Azure KV Mock Mgmt.";
    begin
        LibraryAzureKVMockMgmt.InitMockAzureKeyvaultSecretProvider();
        LibraryAzureKVMockMgmt.AddMockAzureKeyvaultSecretProviderMappingFromFile(NavServerUserPasswordKeyTok, ApiTestPasswordFileTok);
        LibraryAzureKVMockMgmt.UseAzureKeyvaultSecretProvider();
        if not AzureKeyVault.GetAzureKeyVaultSecret(NavServerUserPasswordKeyTok, Password) then
            Error(PasswordRetrievalFailedErr);
        if Password.IsEmpty() then
            Error(PasswordRetrievalFailedErr);
    end;

    [TryFunction]
    local procedure TryGetNavEnlistmentPassword(var Password: SecretText)
    var
        AzureKeyVault: Codeunit "Azure Key Vault";
    begin
        if not AzureKeyVault.GetAzureKeyVaultSecret(NavServerUserPasswordKeyTok, Password) then
            Error(PasswordRetrievalFailedErr);
        if Password.IsEmpty() then
            Error(PasswordRetrievalFailedErr);
    end;
}
