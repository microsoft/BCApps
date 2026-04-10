namespace System.Security.AccessControl;

using Microsoft.Assembly.Setup;

permissionset 9931 "D365 ASSEMBLY, SETUP"
{
    Assignable = true;

    Caption = 'Dynamics 365 Setup assembly';
    Permissions = tabledata "Assembly Setup" = RIMD;
}
