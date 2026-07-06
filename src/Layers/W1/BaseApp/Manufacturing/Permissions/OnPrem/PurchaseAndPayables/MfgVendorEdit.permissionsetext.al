namespace System.Security.AccessControl;

using Microsoft.Manufacturing.WorkCenter;

permissionsetextension 99000777 "Mfg. Vendor - Edit" extends "Vendor - Edit"
{
    Permissions =
                  tabledata "Work Center" = r;
}