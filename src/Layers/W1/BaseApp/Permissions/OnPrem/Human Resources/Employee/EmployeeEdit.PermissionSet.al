namespace System.Security.AccessControl;

using Microsoft.HumanResources.Employee;
using Microsoft.HumanResources.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Finance.Dimension;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.HumanResources.Comment;
using Microsoft.Projects.Resources.Resource;
using Microsoft.HumanResources.Absence;
using Microsoft.CRM.Team;

permissionset 2698 "Employee - Edit"
{
    Access = Public;
    Assignable = false;

    Caption = 'Edit employees';
    Permissions = tabledata "Alternative Address" = RIMD,
                  tabledata "Alt. Employee Posting Group" = R,
                  tabledata "Cause of Absence" = R,
                  tabledata "Cause of Inactivity" = R,
                  tabledata "Confidential Information" = RiD,
                  tabledata "Country/Region" = R,
                  tabledata "Default Dimension" = RIMD,
                  tabledata Employee = RIMD,
                  tabledata "Employee Absence" = RmD,
                  tabledata "Employee Qualification" = RIMD,
                  tabledata "Employee Relative" = RIMD,
                  tabledata "Employee Statistics Group" = R,
                  tabledata "Employment Contract" = R,
                  tabledata "Fixed Asset" = rm,
                  tabledata "Grounds for Termination" = R,
                  tabledata "Human Resource Comment Line" = RIMD,
                  tabledata "Misc. Article" = R,
                  tabledata "Misc. Article Information" = RIMD,
                  tabledata "Nationality" = RIMD,
                  tabledata Qualification = R,
                  tabledata Resource = Rm,
                  tabledata "Salesperson/Purchaser" = Rm,
                  tabledata Union = R;
}
