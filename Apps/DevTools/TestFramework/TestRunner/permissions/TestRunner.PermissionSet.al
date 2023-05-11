permissionset 130451 TestRunner
{
    Assignable = true;
    Caption = 'TestRunner Permissions';

    IncludedPermissionSets = "Test Runner - Exec";

    Permissions = tabledata "AL Test Suite" = RIMD,
        tabledata "Test Method Line" = RIMD;
}