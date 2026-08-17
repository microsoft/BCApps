namespace System.Security.AccessControl;

using Microsoft.Manufacturing.WorkCenter;

permissionsetextension 99000758 "MFG D365 SETUP" extends "D365 SETUP"
{
    Permissions =
                  tabledata "Work Center" = D;
}