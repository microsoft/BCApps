// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestLibraries.Email;

using System.Email;
using System.TestLibraries.Utilities;

codeunit 134688 "Connector Mock"
{
    Permissions = tabledata "Email Rate Limit" = rimd,
                  tabledata "Email Inbox" = rimd;

    var
        Any: Codeunit Any;

    procedure Initialize()
    var
        TestEmailConnectorSetup: Record "Test Email Connector Setup";
        EmailRateLimit: Record "Email Rate Limit";
        TestEmailAccount: Record "Test Email Account";
    begin
        TestEmailConnectorSetup.DeleteAll();
        TestEmailConnectorSetup.Init();
        TestEmailConnectorSetup.Id := Any.GuidValue();
        TestEmailConnectorSetup."Fail On Send" := false;
        TestEmailConnectorSetup."Fail On Register Account" := false;
        TestEmailConnectorSetup."Fail On Mark As Read" := false;
        TestEmailConnectorSetup."Fail On Reply" := false;
        TestEmailConnectorSetup."Fail On Retrieve Emails" := false;
        TestEmailConnectorSetup."Fail On Send" := false;
        TestEmailConnectorSetup."Unsuccessful Register" := false;
        TestEmailConnectorSetup.Insert();

        TestEmailAccount.DeleteAll();
        EmailRateLimit.DeleteAll();
    end;

    procedure GetAccounts(var EmailAccount: Record "Email Account"; Connector: Enum "Email Connector")
    var
        TestEmailAccount: Record "Test Email Account";
    begin
        TestEmailAccount.SetRange("Connector", Connector);
        if TestEmailAccount.FindSet() then
            repeat
                EmailAccount.Init();
                EmailAccount."Account Id" := TestEmailAccount.Id;
                EmailAccount.Name := TestEmailAccount.Name;
                EmailAccount."Email Address" := TestEmailAccount.Email;
                EmailAccount.Connector := Connector;
                EmailAccount.Insert();
            until TestEmailAccount.Next() = 0;
    end;

    procedure AddAccount(var EmailAccount: Record "Email Account")
    begin
        AddAccount(EmailAccount, Enum::"Email Connector"::"Test Email Connector");
    end;

    procedure AddAccount(var EmailAccount: Record "Email Account"; Connector: Enum "Email Connector")
    var
        EmailRateLimit: Record "Email Rate Limit";
        TestEmailAccount: Record "Test Email Account";
    begin
        TestEmailAccount.Id := Any.GuidValue();
        TestEmailAccount.Name := CopyStr(Any.AlphanumericText(250), 1, 250);
        TestEmailAccount.Email := CopyStr(Any.Email(), 1, 250);
        TestEmailAccount.Connector := Connector;
        TestEmailAccount.Insert();

        EmailAccount."Account Id" := TestEmailAccount.Id;
        EmailAccount.Name := TestEmailAccount.Name;
        EmailAccount."Email Address" := TestEmailAccount.Email;
        EmailAccount.Connector := Connector;

        EmailRateLimit."Account Id" := EmailAccount."Account Id";
        EmailRateLimit.Connector := EmailAccount.Connector;
        EmailRateLimit."Email Address" := EmailAccount."Email Address";
        EmailRateLimit."Rate Limit" := 0;
        EmailRateLimit.Insert();
    end;

    procedure AddAccount(var Id: Guid)
    begin
        AddAccount(Id, Enum::"Email Connector"::"Test Email Connector");
    end;

    procedure AddAccount(var Id: Guid; Connector: Enum "Email Connector")
    var
        EmailRateLimit: Record "Email Rate Limit";
        TestEmailAccount: Record "Test Email Account";
    begin
        TestEmailAccount.Id := Any.GuidValue();
        TestEmailAccount.Name := CopyStr(Any.AlphanumericText(250), 1, 250);
        TestEmailAccount.Email := CopyStr(Any.Email(), 1, 250);
        TestEmailAccount.Connector := Connector;
        TestEmailAccount.Insert();

        Id := TestEmailAccount.Id;

        EmailRateLimit."Account Id" := Id;
        EmailRateLimit.Connector := Enum::"Email Connector"::"Test Email Connector";
        EmailRateLimit."Email Address" := TestEmailAccount.Email;
        EmailRateLimit."Rate Limit" := 0;
        EmailRateLimit.Insert();
    end;

    procedure CreateEmailInbox(AccountId: Guid; Connector: Enum "Email Connector"; var EmailInbox: Record "Email Inbox")
    begin
        EmailInbox.Init();
        EmailInbox.Id := 0;
        EmailInbox."Account Id" := AccountId;
        EmailInbox.Connector := Connector;
        EmailInbox.Insert();
        Commit();
    end;

    procedure FailOnSend(): Boolean
    var
        TestEmailConnectorSetup: Record "Test Email Connector Setup";
    begin
        TestEmailConnectorSetup.FindFirst();
        exit(TestEmailConnectorSetup."Fail On Send");
    end;

    procedure FailOnSend(Fail: Boolean)
    var
        TestEmailConnectorSetup: Record "Test Email Connector Setup";
    begin
        TestEmailConnectorSetup.FindFirst();
        TestEmailConnectorSetup."Fail On Send" := Fail;
        TestEmailConnectorSetup.Modify();
    end;

    procedure FailOnReply(): Boolean
    var
        TestEmailConnectorSetup: Record "Test Email Connector Setup";
    begin
        TestEmailConnectorSetup.FindFirst();
        exit(TestEmailConnectorSetup."Fail On Reply");
    end;

    procedure FailOnReply(Fail: Boolean)
    var
        TestEmailConnectorSetup: Record "Test Email Connector Setup";
    begin
        TestEmailConnectorSetup.FindFirst();
        TestEmailConnectorSetup."Fail On Reply" := Fail;
        TestEmailConnectorSetup.Modify();
    end;

    procedure FailOnRetrieveEmails(): Boolean
    var
        TestEmailConnectorSetup: Record "Test Email Connector Setup";
    begin
        TestEmailConnectorSetup.FindFirst();
        exit(TestEmailConnectorSetup."Fail On Retrieve Emails");
    end;

    procedure FailOnRetrieveEmails(Fail: Boolean)
    var
        TestEmailConnectorSetup: Record "Test Email Connector Setup";
    begin
        TestEmailConnectorSetup.FindFirst();
        TestEmailConnectorSetup."Fail On Retrieve Emails" := Fail;
        TestEmailConnectorSetup.Modify();
    end;

    procedure FailOnMarkAsRead(): Boolean
    var
        TestEmailConnectorSetup: Record "Test Email Connector Setup";
    begin
        TestEmailConnectorSetup.FindFirst();
        exit(TestEmailConnectorSetup."Fail On Mark As Read");
    end;

    procedure FailOnMarkAsRead(Fail: Boolean)
    var
        TestEmailConnectorSetup: Record "Test Email Connector Setup";
    begin
        TestEmailConnectorSetup.FindFirst();
        TestEmailConnectorSetup."Fail On Mark As Read" := Fail;
        TestEmailConnectorSetup.Modify();
    end;

    procedure FailOnRegisterAccount(): Boolean
    var
        TestEmailConnectorSetup: Record "Test Email Connector Setup";
    begin
        TestEmailConnectorSetup.FindFirst();
        exit(TestEmailConnectorSetup."Fail On Register Account");
    end;

    procedure FailOnRegisterAccount(Fail: Boolean)
    var
        TestEmailConnectorSetup: Record "Test Email Connector Setup";
    begin
        TestEmailConnectorSetup.FindFirst();
        TestEmailConnectorSetup."Fail On Register Account" := Fail;
        TestEmailConnectorSetup.Modify();
    end;

    procedure UnsuccessfulRegister(): Boolean
    var
        TestEmailConnectorSetup: Record "Test Email Connector Setup";
    begin
        TestEmailConnectorSetup.FindFirst();
        exit(TestEmailConnectorSetup."Unsuccessful Register");
    end;

    procedure UnsuccessfulRegister(Fail: Boolean)
    var
        TestEmailConnectorSetup: Record "Test Email Connector Setup";
    begin
        TestEmailConnectorSetup.FindFirst();
        TestEmailConnectorSetup."Unsuccessful Register" := Fail;
        TestEmailConnectorSetup.Modify();
    end;

    procedure SetEmailMessageID(EmailMessageID: Guid)
    var
        TestEmailConnectorSetup: Record "Test Email Connector Setup";
    begin
        TestEmailConnectorSetup.FindFirst();
        TestEmailConnectorSetup."Email Message ID" := EmailMessageID;
        TestEmailConnectorSetup.Modify();
    end;

    procedure GetEmailMessageID(): Guid
    var
        TestEmailConnectorSetup: Record "Test Email Connector Setup";
    begin
        TestEmailConnectorSetup.FindFirst();
        exit(TestEmailConnectorSetup."Email Message ID");
    end;
}