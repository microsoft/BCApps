permissionset 149000 "BC Perf. Toolkit"
{
    Caption = 'Businss Central Performance Toolkit';
    Access = Public;
    Assignable = true;

    IncludedPermissionSets = "BC Perf. Toolkit - Obj";

    Permissions = tabledata "BCPT Header" = RIMD,
        tabledata "BCPT Line" = RIMD,
        tabledata "BCPT Log Entry" = RIMD,
        tabledata "BCPT Parameter Line" = RIMD;
}