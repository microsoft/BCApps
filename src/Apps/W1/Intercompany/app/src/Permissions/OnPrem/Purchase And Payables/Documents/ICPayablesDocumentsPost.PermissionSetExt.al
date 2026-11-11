// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Security.AccessControl;

using Microsoft.Intercompany.BankAccount;
using Microsoft.Intercompany.Comment;
using Microsoft.Intercompany.Dimension;
using Microsoft.Intercompany.GLAccount;
using Microsoft.Intercompany.Outbox;
using Microsoft.Intercompany.Partner;
using Microsoft.Intercompany.Setup;

permissionsetextension 8413 "IC PAYABLES DOCUMENTS - POST" extends "Payables Documents - Post"
{
    Permissions =
                  tabledata "IC Bank Account" = R,
                  tabledata "IC Comment Line" = RIMD,
                  tabledata "IC Dimension" = R,
                  tabledata "IC Dimension Value" = R,
                  tabledata "IC Document Dimension" = RIMD,
                  tabledata "IC G/L Account" = R,
                  tabledata "IC Inbox/Outbox Jnl. Line Dim." = RIMD,
                  tabledata "IC Outbox Jnl. Line" = RIMD,
                  tabledata "IC Outbox Purchase Header" = RIMD,
                  tabledata "IC Outbox Purchase Line" = RIMD,
                  tabledata "IC Outbox Transaction" = RIMD,
                  tabledata "IC Partner" = R,
                  tabledata "IC Setup" = R;
}
