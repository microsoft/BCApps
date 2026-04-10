namespace System.Security.AccessControl;

using Microsoft.Finance.Consolidation;

permissionset 738 "D365 Fin Cons Setup"
{
    Access = Public;
    Assignable = true;
    Caption = 'Dynamics 365 Business Central Financial Consolidations Setup';
    IncludedPermissionSets = "D365 Fin. Consolid";

    Permissions = tabledata "Business Unit" = RIM,
                    tabledata "Consolidation Setup" = RIM,
                    tabledata "Consolidation Log Entry" = RIMD;
}