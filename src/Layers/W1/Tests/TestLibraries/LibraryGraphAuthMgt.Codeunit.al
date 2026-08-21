// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.TestLibraries.ERP;

using System;
using System.Azure.KeyVault;
using System.Integration;
using System.Security.AccessControl;
using System.Text;

codeunit 131022 "Library - Graph Auth Mgt."
{
    Access = Internal;

    var
        ApiTestPasswordFileTok: Label 'C:\Run\my\ApiTestPassword', Locked = true;
        NavServerUserPasswordKeyTok: Label 'NavServerUserPassword', Locked = true;
        CurrentUserNotFoundErr: Label 'The current test user could not be found.';
        ContainerPasswordReadErr: Label 'The API test password could not be read from %1.', Comment = '%1 - Password file path';
        KeyVaultPasswordReadErr: Label 'The API test password could not be retrieved from the %1 secret.', Comment = '%1 - Azure Key Vault secret name';
        PasswordRetrievalFailedErr: Label 'The API test password could not be retrieved.', Locked = true;

    [NonDebuggable]
    internal procedure AddAuthentication(var HttpWebRequestMgt: Codeunit "Http Web Request Mgt.")
    var
        Password: SecretText;
    begin
        if not GetAuthenticationPassword(Password) then
            exit;

        AddUserPasswordAuthentication(HttpWebRequestMgt, Password);
    end;

    [NonDebuggable]
    internal procedure EnsureAuthenticationAvailable()
    var
        Password: SecretText;
    begin
        GetAuthenticationPassword(Password);
    end;

    [NonDebuggable]
    local procedure GetAuthenticationPassword(var Password: SecretText): Boolean
    var
        User: Record User;
    begin
        if not User.Get(UserSecurityId()) then
            Error(CurrentUserNotFoundErr);

        if ContainerPasswordFileExists() then begin
            if not TryGetContainerPassword(Password) then
                Error(ContainerPasswordReadErr, ApiTestPasswordFileTok);
            exit(true);
        end;

        if User."Windows Security ID" <> '' then
            exit(false);

        if not TryGetNavEnlistmentPassword(Password) then
            Error(KeyVaultPasswordReadErr, NavServerUserPasswordKeyTok);

        exit(true);
    end;

    [NonDebuggable]
    local procedure AddUserPasswordAuthentication(var HttpWebRequestMgt: Codeunit "Http Web Request Mgt."; Password: SecretText)
    var
        Base64Convert: Codeunit "Base64 Convert";
    begin
        HttpWebRequestMgt.AddBasicAuthentication(UserId(), Password);
        HttpWebRequestMgt.AddHeader(
            'Authorization',
            SecretStrSubstNo('Basic %1', Base64Convert.ToBase64(SecretStrSubstNo('%1:%2', UserId(), Password))));
    end;

    [Scope('OnPrem')]
    local procedure ContainerPasswordFileExists(): Boolean
    var
        File: DotNet File;
    begin
        exit(File.Exists(ApiTestPasswordFileTok));
    end;

    [NonDebuggable]
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

    [NonDebuggable]
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
