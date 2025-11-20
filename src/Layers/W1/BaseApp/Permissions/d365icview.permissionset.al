namespace System.Security.AccessControl;

using Microsoft.Intercompany.Comment;
using Microsoft.Intercompany.Inbox;
using Microsoft.Intercompany.Outbox;
using Microsoft.Intercompany.BankAccount;
using Microsoft.Intercompany.Dimension;
using Microsoft.Intercompany.GLAccount;
using Microsoft.Intercompany.Partner;
using Microsoft.Intercompany.Setup;

permissionset 3814 "D365 IC, VIEW"
{
    Assignable = true;

    Caption = 'Dyn. 365 View Intercompany';
    Permissions = tabledata "Handled IC Inbox Jnl. Line" = R,
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
                  tabledata "IC Document Dimension" = RIMD,
                  tabledata "IC G/L Account" = R,
                  tabledata "IC Inbox Jnl. Line" = R,
                  tabledata "IC Inbox Purchase Header" = R,
                  tabledata "IC Inbox Purchase Line" = R,
                  tabledata "IC Inbox Sales Header" = R,
                  tabledata "IC Inbox Sales Line" = R,
                  tabledata "IC Inbox Transaction" = R,
                  tabledata "IC Inbox/Outbox Jnl. Line Dim." = R,
                  tabledata "IC Outbox Jnl. Line" = R,
                  tabledata "IC Outbox Transaction" = R,
                  tabledata "IC Outbox Purchase Header" = R,
                  tabledata "IC Outbox Purchase Line" = R,
                  tabledata "IC Outbox Sales Header" = R,
                  tabledata "IC Outbox Sales Line" = R,
                  tabledata "IC Partner" = R,
                  tabledata "IC Setup" = R;
}
