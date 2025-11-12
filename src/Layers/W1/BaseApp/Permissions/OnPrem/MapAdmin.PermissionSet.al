namespace System.Security.AccessControl;

using System.Security.User;
using Microsoft.EServices.OnlineMap;

permissionset 2406 "Map - Admin"
{
    Access = Public;
    Assignable = false;
    Caption = 'MapPoint Setup';

    Permissions = tabledata "Online Map Parameter Setup" = RIMD,
                  tabledata "Online Map Setup" = RIMD,
                  tabledata "User Setup" = RIMD;
}
