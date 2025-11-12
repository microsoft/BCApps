// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Email;

using Microsoft.Utilities;

/// <summary>
/// Provides functionality to determine whether the email enhancements have been enabled.
/// </summary>
codeunit 8895 "Email Feature"
{
    Access = Internal;

    [EventSubscriber(ObjectType::Table, Database::"Service Connection", 'OnRegisterServiceConnection', '', false, false)]
    local procedure AddEmailAccountsToServiceConnections(var ServiceConnection: Record "Service Connection")
    var
        EmailAccounts: Record "Email Account";
        EmailAccount: Codeunit "Email Account";
        EmailAccountsPage: Page "Email Accounts";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(EmailAccounts); // So that it's not empty RecordId

        ServiceConnection.Status := ServiceConnection.Status::Enabled;
        if not EmailAccount.IsAnyAccountRegistered() then
            ServiceConnection.Status := ServiceConnection.Status::Disabled;

        ServiceConnection.InsertServiceConnection(
            ServiceConnection, RecRef.RecordId, EmailAccountsPage.Caption(), '', Page::"Email Accounts");
    end;
}