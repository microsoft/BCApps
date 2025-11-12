namespace System.Security.AccessControl;

using Microsoft.Manufacturing.WorkCenter;

permissionsetextension 99000760 "MFG D365 VENDOR, EDIT" extends "D365 VENDOR, EDIT"
{
    Permissions =
                  tabledata "Work Center" = r;
}