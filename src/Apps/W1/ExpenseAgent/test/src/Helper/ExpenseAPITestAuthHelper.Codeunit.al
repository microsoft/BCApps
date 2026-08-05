// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using System.Azure.KeyVault;
using System.Environment;
using System.Integration;
using System.Security.AccessControl;

/// <summary>
/// Test-only authentication helper for the API test codeunits in this app.
/// </summary>
codeunit 148332 "Expense API Test Auth Helper"
{
    Access = Internal;
    EventSubscriberInstance = Manual;

    var
        NavServerUserPasswordKeyTok: Label 'NavServerUserPassword', Locked = true;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Library - Graph Mgt", OnAfterInitializeWebRequestWithURL, '', false, false)]
    local procedure OnAfterInitializeWebRequest(var HttpWebRequestMgt: Codeunit "Http Web Request Mgt.")
    var
        Password: SecretText;
    begin
        if not ShouldInjectBasicAuth() then
            exit;
        if not TryGetPassword(Password) then
            exit;
        HttpWebRequestMgt.AddBasicAuthentication(UserId(), Password);
    end;

    local procedure ShouldInjectBasicAuth(): Boolean
    var
        User: Record User;
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        if EnvironmentInfo.IsSaaSInfrastructure() then
            exit(false);

        // If the current user authenticates via Windows
        if not User.Get(UserSecurityId()) then
            exit(false);
        if User."Windows Security ID" <> '' then
            exit(false);

        // Inject Basic auth when using username password authentication.
        exit(true);
    end;

    [TryFunction]
    local procedure TryGetPassword(var Password: SecretText)
    var
        AzureKeyVault: Codeunit "Azure Key Vault";
    begin
        AzureKeyVault.GetAzureKeyVaultSecret(NavServerUserPasswordKeyTok, Password);
    end;
}

