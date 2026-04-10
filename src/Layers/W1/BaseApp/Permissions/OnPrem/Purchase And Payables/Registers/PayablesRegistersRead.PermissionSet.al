namespace System.Security.AccessControl;

using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.HumanResources.Payables;
using Microsoft.Purchases.Payables;

permissionset 3560 "Payables Registers - Read"
{
    Access = Public;
    Assignable = false;
    Caption = 'Read G/L registers (P&P)';

    Permissions = tabledata "Detailed Vendor Ledg. Entry" = R,
                  tabledata "Employee Ledger Entry" = R,
                  tabledata "G/L Register" = R,
                  tabledata "Vendor Ledger Entry" = R;
}
