namespace System.Security.AccessControl;

permissionset 444 "BaseApp Objects - Exec"
{
    Access = Internal;
    Assignable = false;

    Permissions = codeunit * = X,
                  table * = X,
                  page * = X,
                  report * = X,
                  query * = X,
                  xmlport * = X;
}