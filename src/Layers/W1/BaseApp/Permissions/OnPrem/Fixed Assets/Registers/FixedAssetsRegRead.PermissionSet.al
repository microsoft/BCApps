namespace System.Security.AccessControl;

using Microsoft.FixedAssets.Ledger;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.FixedAssets.Maintenance;

permissionset 9918 "Fixed Assets Reg. - Read"
{
    Access = Public;
    Assignable = false;
    Caption = 'Read FA registers';

    Permissions = tabledata "FA Ledger Entry" = R,
                  tabledata "FA Register" = R,
                  tabledata "G/L Register" = R,
                  tabledata "Maintenance Ledger Entry" = R;
}
