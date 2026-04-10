namespace System.Security.AccessControl;

using Microsoft.Warehouse.ADCS;

permissionset 6585 "D365 ADCS, VIEW"
{
    Assignable = true;

    Caption = 'Dynamics 365 View ADCS';
    Permissions = tabledata "ADCS User" = R,
                  tabledata "Miniform Function" = R,
                  tabledata "Miniform Function Group" = R,
                  tabledata "Miniform Header" = R,
                  tabledata "Miniform Line" = R;
}
