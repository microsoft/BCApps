// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestLibraries.Email;

using System.Email;

codeunit 134056 "Http Mock Email Mgnt."
{
    Permissions = tabledata "Email Message" = rid,
                  tabledata "Email Outbox" = rimd,
                  tabledata "Email Rate Limit" = rimd,
                  tabledata "Sent Email" = rid;


    var
        SentEmail: Record "Sent Email";
        EmailError: Record "Email Error";
        NoSentEmailRecordFoundErr: Label 'No Sent Email record found for the given Message Id.';


    procedure AddAccount(var EmailAccount: Record "Email Account"; Connector: Enum "Email Connector")
    var
        ConnectorMock: Codeunit "Connector Mock";
    begin
        ConnectorMock.AddAccount(EmailAccount, Connector);
    end;

    procedure HasAtLeastOneEmailInSentEmail(EmailMessageId: Guid): Boolean
    begin
        SentEmail.SetRange("Message Id", EmailMessageId);
        exit(SentEmail.FindFirst());
    end;

    procedure CheckSentEmailDescription(EmailMessageId: Guid; ExpectedDescription: Text): Boolean
    begin
        SentEmail.SetRange("Message Id", EmailMessageId);
        if not SentEmail.FindFirst() then
            Error(NoSentEmailRecordFoundErr);
        exit(ExpectedDescription = SentEmail.Description);
    end;


    procedure CheckSentEmailFrom(EmailMessageId: Guid; ExpectedFrom: Text): Boolean
    begin
        SentEmail.SetRange("Message Id", EmailMessageId);
        if not SentEmail.FindFirst() then
            Error(NoSentEmailRecordFoundErr);
        exit(ExpectedFrom = SentEmail."Sent From");
    end;


    procedure CheckSentEmailAccountId(EmailMessageId: Guid; ExpectedAccountId: Guid): Boolean
    begin
        SentEmail.SetRange("Message Id", EmailMessageId);
        if not SentEmail.FindFirst() then
            Error(NoSentEmailRecordFoundErr);
        exit(ExpectedAccountId = SentEmail."Account Id");
    end;

    procedure CheckSentEmailConnector(EmailMessageId: Guid; ExpectedConnector: Enum "Email Connector"): Boolean
    begin
        SentEmail.SetRange("Message Id", EmailMessageId);
        if not SentEmail.FindFirst() then
            Error(NoSentEmailRecordFoundErr);
        exit(ExpectedConnector = SentEmail.Connector);
    end;

    procedure SetupEmailOutbox(EmailMessageId: Guid; Connector: Enum "Email Connector"; EmailAccountId: Guid; EmailDescription: Text; EmailAddress: Text[250]; UserSecurityId: Code[50])
    var
        EmailOutbox: Record "Email Outbox";
    begin
        EmailOutbox."Message Id" := EmailMessageId;
        EmailOutbox.Insert();
        EmailOutbox.Connector := Connector;
        EmailOutbox."Account Id" := EmailAccountId;
        EmailOutbox.Description := CopyStr('Test Subject', 1, MaxStrLen(EmailOutbox.Description));
        EmailOutbox."User Security Id" := UserSecurityId;
        EmailOutbox."Send From" := EmailAddress;
        EmailOutbox.Modify();
    end;

    procedure RunEmailDispatcher(EmailMessageId: Guid)
    var
        EmailOutbox: Record "Email Outbox";
    begin
        EmailOutbox.SetRange("Message Id", EmailMessageId);
        if not EmailOutbox.FindFirst() then
            Error('No Email Outbox record found for the given Message Id.');
        Codeunit.Run(Codeunit::"Email Dispatcher", EmailOutbox);
    end;

    procedure CleanEmailErrors()
    begin
        EmailError.DeleteAll();
    end;

    procedure GetEmailErrorCount(): Integer
    begin
        EmailError.Reset();
        exit(EmailError.Count());
    end;

    procedure GetEmailOutBoxStatusWithMessageId(MessageId: Guid): Enum "Email Status"
    var
        EmailOutbox: Record "Email Outbox";
    begin
        EmailOutbox.SetRange("Message Id", MessageId);
        if not EmailOutbox.FindFirst() then
            Error('No Email Outbox record found for the given Message Id.');
        exit(EmailOutbox.Status);
    end;

}