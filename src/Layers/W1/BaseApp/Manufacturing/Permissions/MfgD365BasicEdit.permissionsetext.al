namespace System.Security.AccessControl;

using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Reports;

permissionsetextension 99000751 "MFG D365 Basic - Edit" extends "D365 Basic - Edit"
{
    Permissions =
                  tabledata "Cost Share Buffer" = IMD,
                  tabledata "Load Buffer" = IMD;
}
