namespace System.Security.AccessControl;

using System.Diagnostics;

permissionset 6431 "Changelog - Read"
{
    Access = Public;
    Assignable = false;
    Caption = 'View Change Log Entries';

    Permissions = tabledata "Change Log Entry" = R;
}
