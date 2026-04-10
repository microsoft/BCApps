namespace System.Security.AccessControl;

using Microsoft.EServices.OnlineMap;
using System.Security.User;

permissionset 2406 "Map - Admin"
{
    Access = Public;
    Assignable = false;
    Caption = 'MapPoint Setup';

    Permissions = tabledata "Online Map Parameter Setup" = RIMD,
                  tabledata "Online Map Setup" = RIMD,
                  tabledata "User Setup" = RIMD;
}
