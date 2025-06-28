// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestLibraries.Email;

using System.Email;

codeunit 134702 "Test Email Connector v3" implements "Email Connector v3"
{
    SingleInstance = true;

    var
        TempEmailInbox: Record "Email Inbox" temporary;
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
        ConnectorMock.GetAccounts(Accounts, Enum::"Email Connector"::"Test Email Connector v3");
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

    procedure SetEmailInbox(var EmailInbox: Record "Email Inbox" temporary)
    var
        MailId: Integer;
    begin
        TempEmailInbox.DeleteAll();
        if EmailInbox.FindSet() then
            repeat
                MailId += 1;
                TempEmailInbox.Init();
                TempEmailInbox := EmailInbox;
                TempEmailInbox.Id := MailId;
                TempEmailInbox.Insert();
            until EmailInbox.Next() = 0;
    end;

    procedure RetrieveEmails(AccountId: Guid; var EmailInbox: Record "Email Inbox"; var Filter: Record "Email Retrieval Filters" temporary)
    begin
        if ConnectorMock.FailOnRetrieveEmails() then
            Error('Failed to retrieve emails');

        if TempEmailInbox.FindSet() then
            repeat
                EmailInbox := TempEmailInbox;
                EmailInbox.Id := 0; // Reset ID to ensure a new record is created
                EmailInbox.Insert();
                EmailInbox.Mark(true);
            until TempEmailInbox.Next() = 0
        else begin
            ConnectorMock.CreateEmailInbox(AccountId, Enum::"Email Connector"::"Test Email Connector v3", EmailInbox);
            EmailInbox.Mark(true);
            ConnectorMock.CreateEmailInbox(AccountId, Enum::"Email Connector"::"Test Email Connector v3", EmailInbox);
            EmailInbox.Mark(true);
        end;
    end;

    procedure MarkAsRead(AccountId: Guid; ConversationId: Text)
    begin
        if ConnectorMock.FailOnMarkAsRead() then
            Error('Failed to mark email as read');
    end;
}