namespace System.Security.AccessControl;

using Microsoft.Intercompany.Partner;

permissionset 200 "D365 IC Partner Edit"
{
    Access = Public;
    Assignable = true;

    Caption = 'Create and modify Intercompany Partner';
    Permissions = tabledata "IC Partner" = RIMD;
}