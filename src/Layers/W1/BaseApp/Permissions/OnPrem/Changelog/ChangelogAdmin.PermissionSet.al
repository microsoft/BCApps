namespace System.Security.AccessControl;

using System.Diagnostics;

permissionset 3587 "Changelog - Admin"
{
    Access = Public;
    Assignable = false;
    Caption = 'Setup Change Log';

    Permissions = tabledata "Change Log Setup (Field)" = RIMD,
                  tabledata "Change Log Setup (Table)" = RIMD,
                  tabledata "Change Log Setup" = RIMD;
}
