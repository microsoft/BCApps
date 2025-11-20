namespace System.Security.AccessControl;

using Microsoft.Sales.Receivables;
using Microsoft.Finance.GeneralLedger.Ledger;

permissionset 2816 "Recievables Reg. - Read"
{
    Access = Public;
    Assignable = false;
    Caption = 'Read G/L registers (S&R)';

    Permissions = tabledata "Cust. Ledger Entry" = R,
                  tabledata "Detailed Cust. Ledg. Entry" = R,
                  tabledata "G/L Register" = R;
}
