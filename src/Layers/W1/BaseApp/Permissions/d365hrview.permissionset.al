namespace System.Security.AccessControl;

using Microsoft.HumanResources.Employee;
using Microsoft.HumanResources.Payables;

permissionset 1825 "D365 HR, VIEW"
{
    Assignable = true;

    Caption = 'Dynamics 365 View Basic HR';
    Permissions = tabledata Employee = R,
                  tabledata "Employee Ledger Entry" = R;
}
