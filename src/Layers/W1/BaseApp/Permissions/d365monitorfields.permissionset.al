namespace System.Security.AccessControl;

using System.Diagnostics;

permissionset 8802 "D365 MONITOR FIELDS"
{
    Assignable = true;

    Caption = 'Monitor Field Change Mgt.';
    Permissions = tabledata "Field Monitoring Setup" = RiMd;
}
