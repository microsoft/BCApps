// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Email;

permissionset 8906 "Email - Objects"
{
    Access = Internal;
    Assignable = false;

    Permissions = table "Email Account" = X,
                  table "Email Attachments" = X,
                  table "Email Connector" = X,
                  table "Email Outbox" = X,
                  table "Email Inbox" = X,
                  table "Email Related Attachment" = X,
                  table "Email Scenario" = X,
                  table "Email Scenario Attachments" = X,
                  table "Sent Email" = X,
                  codeunit Email = X,
                  codeunit "Email Account" = X,
                  codeunit "Email Address Lookup" = X,
                  codeunit "Default Email Connector v2" = X,
                  codeunit "Email Dispatcher" = X,
                  codeunit "Email Message" = X,
                  codeunit "Email Scenario" = X,
                  codeunit "Email Test Mail" = X,
                  page "Email Accounts" = X,
                  page "Email Account Wizard" = X,
                  page "Email Activities" = X,
                  page "Email Address Lookup" = X,
                  page "Email Attachments" = X,
                  page "Email Choose Scenario Attach" = X,
                  page "Email Editor" = X,
                  page "Email Outbox" = X,
                  page "Email Rate Limit Wizard" = X,
                  page "Email Related Attachments" = X,
                  page "Email Relation Picker" = X,
                  page "Email Scenario Attach Setup" = X,
                  page "Email Scenario Setup" = X,
                  page "Email Scenarios FactBox" = X,
                  page "Email Scenarios for Account" = X,
                  page "Email User-Specified Address" = X,
                  page "Email Viewer" = X,
                  page "Email View Policy List" = X,
                  page "Sent Emails" = X,
                  page "Sent Emails List Part" = X,
                  query "Email Related Record" = X,
                  query "Outbox Emails" = X,
                  query "Sent Emails" = X;
}
