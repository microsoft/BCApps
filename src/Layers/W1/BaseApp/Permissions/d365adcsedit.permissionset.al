namespace System.Security.AccessControl;

using Microsoft.Warehouse.ADCS;

permissionset 1778 "D365 ADCS, EDIT"
{
    Assignable = true;
    Caption = 'Dynamics 365 Create ADCS';

    IncludedPermissionSets = "D365 ADCS, VIEW";

    Permissions = tabledata "ADCS User" = IMD,
                  tabledata "Miniform Function" = IMD,
                  tabledata "Miniform Function Group" = IMD,
                  tabledata "Miniform Header" = IMD,
                  tabledata "Miniform Line" = IMD;
}
