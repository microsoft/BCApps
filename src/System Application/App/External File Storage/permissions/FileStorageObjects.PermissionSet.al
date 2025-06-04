namespace System.ExternalFileStorage;

permissionset 9452 "File Storage - Objects"
{
    Access = Internal;
    Assignable = false;
    Caption = 'External File Storage - Objects';

    Permissions =
        codeunit "File Account" = X,
        codeunit "External File Storage" = X,
        codeunit "File Pagination Data" = X,
        codeunit "File Scenario" = X,
        table "File Account" = X,
        table "File Account Content" = X,
        table "File Account Scenario" = X,
        table "File Scenario" = X;
}
