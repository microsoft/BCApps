namespace System.Security.AccessControl;

using Microsoft.HumanResources.Setup;
using Microsoft.HumanResources.Absence;

permissionset 7665 "Time Sheets - Post"
{
    Access = Public;
    Assignable = false;
    Caption = 'Approve time sheets';

    Permissions = tabledata "Employee Absence" = RIM,
                  tabledata "Human Resource Unit of Measure" = R;
}
