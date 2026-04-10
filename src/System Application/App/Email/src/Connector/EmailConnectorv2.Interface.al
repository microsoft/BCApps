#if not CLEAN26
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Email;

/// <summary>
/// An e-mail connector interface enhances the "Email Connector" with reading, replying to e-mails and marking emails as read.
/// </summary>
interface "Email Connector v2" extends "Email Connector"
{
    ObsoleteReason = 'Replaced by "Email Connector v3" which adds filtering capability for retrieval of emails';
    ObsoleteState = Pending;
    ObsoleteTag = '26.0';

    /// <summary>
    /// Reply to an e-mail using the provided account.
    /// </summary>
    /// <param name="EmailMessage">The email message that is to be sent out.</param>
    /// <param name="AccountId">The email account ID which is used to send out the email.</param>
    procedure Reply(var EmailMessage: Codeunit "Email Message"; AccountId: Guid);

    /// <summary>
    /// Read e-mails from the provided account.
    /// </summary>
    /// <param name="AccountId">The email account ID which is used to send out the email.</param>
    /// <param name="EmailInbox">The email inbox record that will store the emails.</param>
    procedure RetrieveEmails(AccountId: Guid; var EmailInbox: Record "Email Inbox");

    /// <summary>
    /// Mark an e-mail as read in the provided account.
    /// </summary>
    /// <param name="AccountId">The email account ID.</param>
    /// <param name="ExternalId">The external ID of the email.</param>
    procedure MarkAsRead(AccountId: Guid; ExternalId: Text);
}
#endif