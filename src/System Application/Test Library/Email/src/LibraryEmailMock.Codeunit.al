// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestLibraries.Email;

using System.Email;

codeunit 134107 "Library - Email Mock"
{
    Permissions = tabledata "Email Message" = rid,
                  tabledata "Email Outbox" = rimd,
                  tabledata "Email Rate Limit" = rimd,
                  tabledata "Sent Email" = rid;


    procedure AddAccount(var EmailAccount: Record "Email Account"; Connector: Enum "Email Connector")
    var
        ConnectorMock: Codeunit "Connector Mock";
    begin
        ConnectorMock.AddAccount(EmailAccount, Connector);
    end;

    procedure SentEmailExists(EmailMessageId: Guid): Boolean
    var
        SentEmail: Record "Sent Email";
    begin
        SentEmail.SetRange("Message Id", EmailMessageId);
        exit(not SentEmail.IsEmpty());
    end;

    procedure CheckSentEmailDescription(EmailMessageId: Guid; ExpectedDescription: Text): Boolean
    var
        SentEmail: Record "Sent Email";
    begin
        SentEmail.SetRange("Message Id", EmailMessageId);
        SentEmail.FindFirst();
        exit(ExpectedDescription = SentEmail.Description);
    end;

    procedure CheckSentEmailFrom(EmailMessageId: Guid; ExpectedFrom: Text): Boolean
    var
        SentEmail: Record "Sent Email";
    begin
        SentEmail.SetRange("Message Id", EmailMessageId);
        SentEmail.FindFirst();
        exit(ExpectedFrom = SentEmail."Sent From");
    end;

    procedure CheckSentEmailAccountId(EmailMessageId: Guid; ExpectedAccountId: Guid): Boolean
    var
        SentEmail: Record "Sent Email";
    begin
        SentEmail.SetRange("Message Id", EmailMessageId);
        SentEmail.FindFirst();
        exit(ExpectedAccountId = SentEmail."Account Id");
    end;

    procedure CheckSentEmailConnector(EmailMessageId: Guid; ExpectedConnector: Enum "Email Connector"): Boolean
    var
        SentEmail: Record "Sent Email";
    begin
        SentEmail.SetRange("Message Id", EmailMessageId);
        SentEmail.FindFirst();
        exit(ExpectedConnector = SentEmail.Connector);
    end;

    procedure SetupEmailOutbox(EmailMessageId: Guid; Connector: Enum "Email Connector"; EmailAccountId: Guid;
                                                                    EmailDescription: Text;
                                                                    EmailAddress: Text[250];
                                                                    UserSecurityId: Code[50])
    var
        EmailOutbox: Record "Email Outbox";
    begin
        EmailOutbox.Validate("Message Id", EmailMessageId);
        EmailOutbox.Insert();
        EmailOutbox.Validate(Connector, Connector);
        EmailOutbox.Validate("Account Id", EmailAccountId);
        EmailOutbox.Validate(Description, EmailDescription);
        EmailOutbox.Validate("User Security Id", UserSecurityId);
        EmailOutbox.Validate("Send From", EmailAddress);
        EmailOutbox.Modify();
    end;

    procedure RunEmailDispatcher(EmailMessageId: Guid)
    var
        EmailOutbox: Record "Email Outbox";
    begin
        EmailOutbox.SetRange("Message Id", EmailMessageId);
        EmailOutbox.FindFirst();
        Codeunit.Run(Codeunit::"Email Dispatcher", EmailOutbox);
    end;

    procedure CleanEmailErrors()
    var
        EmailError: Record "Email Error";
    begin
        EmailError.DeleteAll();
    end;

    procedure GetEmailErrorCount(): Integer
    var
        EmailError: Record "Email Error";
    begin
        EmailError.Reset();
        exit(EmailError.Count());
    end;

    procedure CheckEmailOutBoxStatusWithMessageId(MessageId: Guid; Status: Enum "Email Status"): Boolean
    var
        EmailOutbox: Record "Email Outbox";
    begin
        EmailOutbox.SetRange("Message Id", MessageId);
        EmailOutbox.FindFirst();
        exit(EmailOutbox.Status = Status);
    end;

}