// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

codeunit 131022 "Library - Graph Auth Mgt."
{
    Access = Internal;
    EventSubscriberInstance = Manual;

    var
        ApiTestPasswordFileTok: Label 'C:\Run\my\ApiTestPassword', Locked = true;
        NavServerUserPasswordKeyTok: Label 'NavServerUserPassword', Locked = true;
        CurrentUserNotFoundErr: Label 'The current test user could not be found.';
        ContainerPasswordReadErr: Label 'The API test password could not be read from %1.', Comment = '%1 - Password file path';
        KeyVaultPasswordReadErr: Label 'The API test password could not be retrieved from the %1 secret.', Comment = '%1 - Azure Key Vault secret name';
        PasswordRetrievalFailedErr: Label 'The API test password could not be retrieved.', Locked = true;

    [NonDebuggable]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Library - Graph Mgt", OnAfterInitializeWebRequestWithURL, '', false, false)]
    local procedure AddAuthentication(var HttpWebRequestMgt: Codeunit "Http Web Request Mgt.")
    var
        User: Record User;
        Password: SecretText;
    begin
        if not User.Get(UserSecurityId()) then
            Error(CurrentUserNotFoundErr);

        if ContainerPasswordFileExists() then begin
            if not TryGetContainerPassword(Password) then
                Error(ContainerPasswordReadErr, ApiTestPasswordFileTok);
            HttpWebRequestMgt.AddBasicAuthentication(UserId(), Password);
            exit;
        end;

        if User."Windows Security ID" <> '' then
            exit;

        if not TryGetNavEnlistmentPassword(Password) then
            Error(KeyVaultPasswordReadErr, NavServerUserPasswordKeyTok);

        HttpWebRequestMgt.AddBasicAuthentication(UserId(), Password);
    end;

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
