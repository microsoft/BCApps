// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Security.AccessControl;

using Microsoft.Intercompany.BankAccount;
using Microsoft.Intercompany.Comment;
using Microsoft.Intercompany.Dimension;
using Microsoft.Intercompany.GLAccount;
using Microsoft.Intercompany.Inbox;
using Microsoft.Intercompany.Outbox;
using Microsoft.Intercompany.Partner;
using Microsoft.Intercompany.Setup;

permissionsetextension 8406 "IC D365 TEAM MEMBER" extends "D365 TEAM MEMBER"
{
    Permissions =
                  tabledata "Handled IC Inbox Jnl. Line" = RM,
                  tabledata "Handled IC Inbox Purch. Header" = RM,
                  tabledata "Handled IC Inbox Purch. Line" = RM,
                  tabledata "Handled IC Inbox Sales Header" = RM,
                  tabledata "Handled IC Inbox Sales Line" = RM,
                  tabledata "Handled IC Inbox Trans." = RM,
                  tabledata "Handled IC Outbox Jnl. Line" = RM,
                  tabledata "Handled IC Outbox Purch. Hdr" = RM,
                  tabledata "Handled IC Outbox Purch. Line" = RM,
                  tabledata "Handled IC Outbox Sales Header" = RM,
                  tabledata "Handled IC Outbox Sales Line" = RM,
                  tabledata "Handled IC Outbox Trans." = RM,
                  tabledata "IC Bank Account" = RM,
                  tabledata "IC Comment Line" = RM,
                  tabledata "IC Dimension" = RM,
                  tabledata "IC Dimension Value" = RM,
                  tabledata "IC Document Dimension" = RM,
                  tabledata "IC G/L Account" = RM,
                  tabledata "IC Inbox Jnl. Line" = RM,
                  tabledata "IC Inbox Purchase Header" = RM,
                  tabledata "IC Inbox Purchase Line" = RM,
                  tabledata "IC Inbox Sales Header" = RM,
                  tabledata "IC Inbox Sales Line" = RM,
                  tabledata "IC Inbox Transaction" = RM,
                  tabledata "IC Inbox/Outbox Jnl. Line Dim." = RM,
                  tabledata "IC Outbox Jnl. Line" = RM,
                  tabledata "IC Outbox Purchase Header" = RM,
                  tabledata "IC Outbox Purchase Line" = RM,
                  tabledata "IC Outbox Sales Header" = RM,
                  tabledata "IC Outbox Sales Line" = RM,
                  tabledata "IC Outbox Transaction" = RM,
                  tabledata "IC Partner" = RM,
                  tabledata "IC Setup" = RM;
}
