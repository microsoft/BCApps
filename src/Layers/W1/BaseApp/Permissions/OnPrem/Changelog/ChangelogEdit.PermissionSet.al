namespace System.Security.AccessControl;

using System.Diagnostics;

permissionset 8929 "Changelog - Edit"
{
    Access = Public;
    Assignable = false;
    Caption = 'Delete Change Log Entries';

    Permissions = tabledata "Change Log Entry" = RIMD;
}
