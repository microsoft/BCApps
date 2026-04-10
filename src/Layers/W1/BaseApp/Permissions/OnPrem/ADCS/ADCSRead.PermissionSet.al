namespace System.Security.AccessControl;

using Microsoft.Warehouse.ADCS;

permissionset 7685 "ADCS - Read"
{
    Access = Public;
    Assignable = false;
    Caption = 'ADCS User';

    Permissions = tabledata "ADCS User" = R,
                  tabledata "Item Identifier" = R,
                  tabledata "Miniform Function" = R,
                  tabledata "Miniform Function Group" = R,
                  tabledata "Miniform Header" = R,
                  tabledata "Miniform Line" = R;
}
