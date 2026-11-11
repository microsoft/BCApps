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

permissionsetextension 8404 "IC D365 READ" extends "D365 READ"
{
    Permissions =
                  tabledata "Handled IC Inbox Jnl. Line" = R,
                  tabledata "Handled IC Inbox Purch. Header" = R,
                  tabledata "Handled IC Inbox Purch. Line" = R,
                  tabledata "Handled IC Inbox Sales Header" = R,
                  tabledata "Handled IC Inbox Sales Line" = R,
                  tabledata "Handled IC Inbox Trans." = R,
                  tabledata "Handled IC Outbox Jnl. Line" = R,
                  tabledata "Handled IC Outbox Purch. Hdr" = R,
                  tabledata "Handled IC Outbox Purch. Line" = R,
                  tabledata "Handled IC Outbox Sales Header" = R,
                  tabledata "Handled IC Outbox Sales Line" = R,
                  tabledata "Handled IC Outbox Trans." = R,
                  tabledata "IC Bank Account" = R,
                  tabledata "IC Comment Line" = R,
                  tabledata "IC Dimension" = R,
                  tabledata "IC Dimension Value" = R,
                  tabledata "IC Document Dimension" = R,
                  tabledata "IC G/L Account" = R,
                  tabledata "IC Inbox Jnl. Line" = R,
                  tabledata "IC Inbox Purchase Header" = R,
                  tabledata "IC Inbox Purchase Line" = R,
                  tabledata "IC Inbox Sales Header" = R,
                  tabledata "IC Inbox Sales Line" = R,
                  tabledata "IC Inbox Transaction" = R,
                  tabledata "IC Inbox/Outbox Jnl. Line Dim." = R,
                  tabledata "IC Outbox Jnl. Line" = R,
                  tabledata "IC Outbox Purchase Header" = R,
                  tabledata "IC Outbox Purchase Line" = R,
                  tabledata "IC Outbox Sales Header" = R,
                  tabledata "IC Outbox Sales Line" = R,
                  tabledata "IC Outbox Transaction" = R,
                  tabledata "IC Partner" = R,
                  tabledata "IC Setup" = R;
}
