namespace System.ExternalFileStorage;

permissionset 9452 "File Storage - Objects"
{
    Access = Internal;
    Assignable = false;

    Permissions =
        table "File Account" = X,
        table "File Account Content" = X,
        table "File Account Scenario" = X,
        table "File Scenario" = X;
}
