namespace System.Security.AccessControl;

using Microsoft.HumanResources.Setup;
using Microsoft.HumanResources.Employee;
using Microsoft.HumanResources.Absence;
using Microsoft.Foundation.UOM;

permissionset 4592 "Human Resources - Admin"
{
    Access = Public;
    Assignable = false;
    Caption = 'Human Resources setup';

    Permissions = tabledata "Cause of Absence" = RIMD,
                  tabledata "Cause of Inactivity" = RIMD,
                  tabledata Confidential = RIMD,
                  tabledata Employee = R,
                  tabledata "Employee Absence" = R,
                  tabledata "Employee Qualification" = R,
                  tabledata "Employee Statistics Group" = RIMD,
                  tabledata "Employment Contract" = RIMD,
                  tabledata "Grounds for Termination" = RIMD,
                  tabledata "Human Resources Setup" = RIMD,
                  tabledata "Misc. Article" = RIMD,
                  tabledata "Misc. Article Information" = R,
                  tabledata Qualification = RIMD,
                  tabledata Relative = RIMD,
                  tabledata Union = RIMD,
                  tabledata "Unit of Measure" = RIMD;
}
