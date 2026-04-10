namespace System.Security.AccessControl;

using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Sales.Receivables;

permissionset 2816 "Recievables Reg. - Read"
{
    Access = Public;
    Assignable = false;
    Caption = 'Read G/L registers (S&R)';

    Permissions = tabledata "Cust. Ledger Entry" = R,
                  tabledata "Detailed Cust. Ledg. Entry" = R,
                  tabledata "G/L Register" = R;
}
