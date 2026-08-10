// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

codeunit 131022 "Library - Graph Auth Mgt."
{
    var
        ApiTestPasswordFileTok: Label 'C:\Run\my\ApiTestPassword', Locked = true;
        NavServerUserPasswordKeyTok: Label 'NavServerUserPassword', Locked = true;
        CurrentUserNotFoundErr: Label 'The current test user could not be found.';
        MissingContainerPasswordFileErr: Label 'The API test password file is not available.', Locked = true;
        MissingPasswordErr: Label 'API tests require a password when the server uses NavUserPassword authentication. Configure the BCApps container credential bridge or the NavServerUserPassword secret.';
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
        if User."Windows Security ID" <> '' then
            exit;

        if not TryGetContainerPassword(Password) then
            if not TryGetNavEnlistmentPassword(Password) then
                Error(MissingPasswordErr);

        HttpWebRequestMgt.AddBasicAuthentication(UserId(), Password);
    end;

    [NonDebuggable]
    [TryFunction]
    local procedure TryGetContainerPassword(var Password: SecretText)
    var
        File: DotNet File;
        PasswordText: Text;
    begin
        if not File.Exists(ApiTestPasswordFileTok) then
            Error(MissingContainerPasswordFileErr);

        PasswordText := File.ReadAllText(ApiTestPasswordFileTok);
        Password := PasswordText;
        Clear(PasswordText);
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
