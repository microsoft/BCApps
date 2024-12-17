namespace System.FileSystem;

permissionset 9452 "File System - Objects"
{
    Access = Internal;
    Assignable = false;

    Permissions =
        table "File Account" = X,
        table "File Account Content" = X,
        table "File Account Scenario" = X,
        table "File Scenario" = X;
}
