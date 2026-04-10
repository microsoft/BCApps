namespace System.Security.AccessControl;

using Microsoft.Warehouse.Request;

permissionset 3178 "Release Document - Edit"
{
    Access = Public;
    Assignable = false;
    Caption = 'Release documents';

    Permissions = tabledata "Warehouse Request" = RIMD;
}
