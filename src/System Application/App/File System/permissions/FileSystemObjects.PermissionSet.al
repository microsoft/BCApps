namespace FileSystem.FileSystem;

using System.FileSystem;

permissionset 9452 "File System - Objects"
{
    Access = Internal;
    Assignable = false;

    Permissions =
        table "File Account" = X,
        table "File System Connector" = X,
        table "File System Connector Logo" = X,
        table "File Account Content" = X,
        table "File Account Scenario" = X,
        table "File Scenario" = X;
}
