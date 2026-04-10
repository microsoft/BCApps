namespace System.Security.AccessControl;

using Microsoft.Utilities;

permissionset 4656 "Dynamics Online Setup"
{
    Access = Public;
    Assignable = false;
    Caption = 'Dynamics Online Setup';

    Permissions = tabledata "Name/Value Buffer" = RIMD;
}
