namespace System.Security.AccessControl;

using Microsoft.FixedAssets.Insurance;

permissionset 3423 "Insurance Registers - Read"
{
    Access = Public;
    Assignable = false;
    Caption = 'Read insurance registers';

    Permissions = tabledata "Ins. Coverage Ledger Entry" = R,
                  tabledata "Insurance Register" = R;
}
