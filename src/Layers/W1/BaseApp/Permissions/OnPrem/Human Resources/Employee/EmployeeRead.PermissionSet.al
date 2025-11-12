namespace System.Security.AccessControl;

using Microsoft.HumanResources.Employee;
using Microsoft.Finance.Dimension;
using Microsoft.HumanResources.Comment;
using Microsoft.HumanResources.Setup;
using Microsoft.HumanResources.Absence;

permissionset 2084 "Employee - Read"
{
    Access = Public;
    Assignable = false;
    Caption = 'Read employees';

    Permissions = tabledata "Alternative Address" = R,
                  tabledata "Cause of Absence" = R,
                  tabledata "Default Dimension" = R,
                  tabledata Employee = R,
                  tabledata "Employee Absence" = R,
                  tabledata "Employee Qualification" = R,
                  tabledata "Employee Relative" = R,
                  tabledata "Human Resource Comment Line" = R,
                  tabledata "Misc. Article" = R,
                  tabledata "Misc. Article Information" = R,
                  tabledata Qualification = R,
                  tabledata Relative = R;
}
