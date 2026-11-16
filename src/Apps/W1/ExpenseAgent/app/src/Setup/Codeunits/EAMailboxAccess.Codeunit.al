// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.ExpenseAgent;

using System.Email;

/// <summary>
/// Verifies that the current user has access to a Microsoft 365 mailbox before the agent
/// is configured against it. Invoked via Codeunit.Run() so the probe can write (the underlying
/// Email.RetrieveEmails inserts a row in Email Inbox that we must clean up) and still allow the
/// caller to catch errors as a boolean result.
/// </summary>
codeunit 6942 "EA Mailbox Access"
{
    Access = Internal;
    Permissions = tabledata "Email Inbox" = rd;
    InherentEntitlements = X;
    InherentPermissions = X;
    TableNo = "Expense Agent Setup";

    trigger OnRun()
    begin
        AccessMailbox(TestAccountId, TestConnector);
    end;

    /// <summary>
    /// Sets the email account that the next Run() call should probe.
    /// </summary>
    /// <param name="AccountId">The email account ID to probe.</param>
    /// <param name="Connector">The email connector that owns the account.</param>
    procedure SetTestAccount(AccountId: Guid; Connector: Enum "Email Connector")
    begin
        TestAccountId := AccountId;
        TestConnector := Connector;
    end;

    local procedure AccessMailbox(AccountId: Guid; Connector: Enum "Email Connector")
    var
        EmailInbox: Record "Email Inbox";
        TempFilters: Record "Email Retrieval Filters" temporary;
        Email: Codeunit "Email";
    begin
        TempFilters."Unread Emails" := true;
        TempFilters."Max No. of Emails" := 1;
        Email.RetrieveEmails(AccountId, Connector, EmailInbox, TempFilters);

        // RetrieveEmails returns EmailInbox in MarkedOnly mode, scoped to just the rows from this call.
        if not EmailInbox.IsEmpty() then
            EmailInbox.DeleteAll();
    end;

    var
        TestAccountId: Guid;
        TestConnector: Enum "Email Connector";
}
