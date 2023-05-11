permissionset 130450 "Test Runner - Exec"
{
    Assignable = true;

    IncludedPermissionSets = "Test Runner - Obj.";

    Permissions = tabledata "AL Test Suite" = rmid,
        tabledata "Test Method Line" = rmid,
        tabledata "Test Code Coverage Result" = rmid,
        tabledata "AL Code Coverage Map" = rmid;
}