namespace System.Security.AccessControl;

using Microsoft.Intercompany.BankAccount;
using Microsoft.Intercompany.Dimension;
using Microsoft.Intercompany.GLAccount;
using Microsoft.Intercompany.Partner;
using Microsoft.Intercompany.Setup;

permissionset 3239 "D365 IC, SETUP"
{
    Assignable = true;

    Caption = 'Dyn. 365 Intercompany Setup';
    Permissions = tabledata "IC Bank Account" = RIMD,
                  tabledata "IC Dimension" = RIMD,
                  tabledata "IC Dimension Value" = RIMD,
                  tabledata "IC G/L Account" = RIMD,
                  tabledata "IC Partner" = RIMD,
                  tabledata "IC Setup" = RIMD;
}
