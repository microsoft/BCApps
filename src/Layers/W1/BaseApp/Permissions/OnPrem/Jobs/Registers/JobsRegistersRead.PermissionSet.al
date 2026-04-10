namespace System.Security.AccessControl;

using Microsoft.Projects.Project.Ledger;

permissionset 3871 "Jobs Registers - Read"
{
    Access = Public;
    Assignable = false;
    Caption = 'Read project registers';

    Permissions = tabledata "Job Ledger Entry" = R,
                  tabledata "Job Register" = R;
}
