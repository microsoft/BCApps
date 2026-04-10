namespace System.Security.AccessControl;

using Microsoft.HumanResources.Setup;

permissionset 366 "D365 HR, SETUP"
{
    Assignable = true;

    Caption = 'Dynamics 365 Basic HR Setup';
    Permissions = tabledata "Human Resource Unit of Measure" = RIMD,
                  tabledata "Human Resources Setup" = RIMD;
}
