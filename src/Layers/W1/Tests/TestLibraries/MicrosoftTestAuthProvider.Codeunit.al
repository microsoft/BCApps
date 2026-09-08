// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.TestLibraries.ERP;

using System;
using System.Azure.KeyVault;
using System.Environment;
using System.Security.AccessControl;

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
        ContainerPasswordReadErr: Label 'The API test password could not be read from %1.', Comment = '%1 - Password file path';
        KeyVaultPasswordReadErr: Label 'The API test password could not be retrieved from the %1 secret.', Comment = '%1 - Azure Key Vault secret name';
        PasswordRetrievalFailedErr: Label 'The API test password could not be retrieved.';

    /// <summary>
    /// Configures authentication for API test requests, preserving ambient authentication on Windows and SaaS.
    /// </summary>
    /// <param name="Authentication">The authentication context to configure.</param>
    procedure ConfigureAuthentication(var Authentication: Codeunit "API Test Auth Context")
    var
        EnvironmentInfo: Codeunit "Environment Information";
        SecurityGroup: Codeunit "Security Group";
    begin
        if EnvironmentInfo.IsSaaSInfrastructure() then
            exit;
        if SecurityGroup.IsWindowsAuthentication() then
            exit;

        Authentication.SetBasicAuthentication(UserId(), GetAuthenticationPassword());
    end;

    local procedure GetAuthenticationPassword(): SecretText
    var
        Password: SecretText;
    begin
        if not CachedAuthenticationPassword.IsEmpty() then
            exit(CachedAuthenticationPassword);

        if ContainerPasswordFileExists() then begin
            if not TryGetContainerPassword(Password) then
                Error(ContainerPasswordReadErr, ApiTestPasswordFileTok);
        end else
            if not TryGetNavEnlistmentPassword(Password) then
                Error(KeyVaultPasswordReadErr, NavServerUserPasswordKeyTok);

        CachedAuthenticationPassword := Password;
        exit(CachedAuthenticationPassword);
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
