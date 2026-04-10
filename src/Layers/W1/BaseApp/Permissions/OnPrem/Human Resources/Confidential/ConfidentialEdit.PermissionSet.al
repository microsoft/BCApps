namespace System.Security.AccessControl;

using Microsoft.HumanResources.Employee;
using Microsoft.HumanResources.Setup;

permissionset 2521 "Confidential - Edit"
{
    Access = Public;
    Assignable = false;

    Caption = 'Create and edit confidential';
    Permissions = tabledata Confidential = R,
                  tabledata "Confidential Information" = RIMD,
                  tabledata "HR Confidential Comment Line" = RIMD;
}
