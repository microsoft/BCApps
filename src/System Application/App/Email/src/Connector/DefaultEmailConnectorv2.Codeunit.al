// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Email;

/// <summary>
/// This is the default implementation of the Email Connector v2 interface which adds the reply, retrievial of emails and marking them as read functionalities.
/// </summary>
#if not CLEAN26
#pragma warning disable AL0432
codeunit 8998 "Default Email Connector v2" implements "Email Connector v2", "Email Connector v3", "Email Connector v4"
#pragma warning restore AL0432
#else
#if not CLEAN28
#pragma warning disable AL0432
codeunit 8998 "Default Email Connector v2" implements "Email Connector v3", "Email Connector v4"
#pragma warning restore AL0432
#else
codeunit 8998 "Default Email Connector v2" implements "Email Connector v4"
#endif
#endif
{

    procedure Send(EmailMessage: Codeunit "Email Message"; AccountId: Guid)
    begin

    end;

    procedure GetAccounts(var Accounts: Record "Email Account")
    begin

    end;

    procedure ShowAccountInformation(AccountId: Guid)
    begin

    end;

    procedure RegisterAccount(var EmailAccount: Record "Email Account"): Boolean
    begin

    end;

    procedure DeleteAccount(AccountId: Guid): Boolean
    begin

    end;

    procedure GetLogoAsBase64(): Text
    begin

    end;

    procedure GetDescription(): Text[250]
    begin

    end;

    procedure Reply(var EmailMessage: Codeunit "Email Message"; AccountId: Guid)
    begin

    end;

#if not CLEAN26
    [Obsolete('Replaced by RetrieveEmails with an additional Filters parameter of type Record "Email Retrieval Filters".', '26.0')]
    procedure RetrieveEmails(AccountId: Guid; var EmailInbox: Record "Email Inbox")
    begin

    end;
#endif

    procedure RetrieveEmails(AccountId: Guid; var EmailInbox: Record "Email Inbox"; var Filters: Record "Email Retrieval Filters" temporary)
    begin

    end;

    procedure MarkAsRead(AccountId: Guid; ExternalId: Text)
    begin

    end;

    procedure GetEmailFolders(AccountId: Guid; var EmailFolders: Record "Email Folders" temporary)
    begin
    end;
}