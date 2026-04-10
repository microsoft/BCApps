#if not CLEAN26
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestLibraries.Email;

using System.Email;

#pragma warning disable AL0432
codeunit 134682 "Test Email Connector v2" implements "Email Connector v2"
#pragma warning restore AL0432
{

    var
        ConnectorMock: Codeunit "Connector Mock";

    procedure Send(EmailMessage: Codeunit "Email Message"; AccountId: Guid)
    begin
        ConnectorMock.SetEmailMessageID(EmailMessage.GetId());
        Commit();
        if ConnectorMock.FailOnSend() then
            Error('Failed to send email');
    end;

    procedure GetAccounts(var Accounts: Record "Email Account")
    begin
        ConnectorMock.GetAccounts(Accounts, Enum::"Email Connector"::"Test Email Connector v2");
    end;

    procedure ShowAccountInformation(AccountId: Guid)
    begin
        Message('Showing information for account: %1', AccountId);
    end;

    procedure RegisterAccount(var EmailAccount: Record "Email Account"): Boolean
    begin
        if ConnectorMock.FailOnRegisterAccount() then
            Error('Failed to register account');

        if ConnectorMock.UnsuccessfulRegister() then
            exit(false);

        EmailAccount."Account Id" := CreateGuid();
        EmailAccount."Email Address" := 'Test email address';
        EmailAccount.Name := 'Test account';

        exit(true);
    end;

    procedure DeleteAccount(AccountId: Guid): Boolean
    var
        TestEmailAccount: Record "Test Email Account";
    begin
        if TestEmailAccount.Get(AccountId) then
            exit(TestEmailAccount.Delete());
        exit(false);
    end;

    procedure GetLogoAsBase64(): Text
    begin

    end;

    procedure GetDescription(): Text[250]
    begin
        exit('Lorem ipsum dolor sit amet, consectetur adipiscing elit. Duis ornare ante a est commodo interdum. Pellentesque eu diam maximus, faucibus neque ut, viverra leo. Praesent ullamcorper nibh ut pretium dapibus. Nullam eu dui libero. Etiam ac cursus metus.')
    end;

    procedure Reply(var EmailMessage: Codeunit "Email Message"; AccountId: Guid)
    begin
        if ConnectorMock.FailOnReply() then
            Error('Failed to send email');
    end;

    procedure RetrieveEmails(AccountId: Guid; var EmailInbox: Record "Email Inbox")
    begin
        if ConnectorMock.FailOnRetrieveEmails() then
            Error('Failed to retrieve emails');

        ConnectorMock.CreateEmailInbox(AccountId, Enum::"Email Connector"::"Test Email Connector v2", EmailInbox);
        EmailInbox.Mark(true);
        ConnectorMock.CreateEmailInbox(AccountId, Enum::"Email Connector"::"Test Email Connector v2", EmailInbox);
        EmailInbox.Mark(true);
    end;

    procedure MarkAsRead(AccountId: Guid; ConversationId: Text)
    begin
        if ConnectorMock.FailOnMarkAsRead() then
            Error('Failed to mark email as read');
    end;
}
#endif