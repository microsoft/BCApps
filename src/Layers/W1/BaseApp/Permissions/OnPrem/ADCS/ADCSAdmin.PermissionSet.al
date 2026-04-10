namespace System.Security.AccessControl;

using Microsoft.Warehouse.ADCS;

permissionset 388 "ADCS - Admin"
{
    Access = Public;
    Assignable = false;
    Caption = 'ADCS Set-up';

    Permissions = tabledata "ADCS User" = RIMD,
                  tabledata "Item Identifier" = RIMD,
                  tabledata "Miniform Function" = RIMD,
                  tabledata "Miniform Function Group" = RIMD,
                  tabledata "Miniform Header" = RIMD,
                  tabledata "Miniform Line" = RIMD;
}
