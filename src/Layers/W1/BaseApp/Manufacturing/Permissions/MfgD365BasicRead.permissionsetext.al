namespace System.Security.AccessControl;

using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Reports;
using Microsoft.Manufacturing.Setup;

permissionsetextension 99000752 "MFG D365 Basic - Read" extends "D365 Basic - Read"
{
    Permissions =
                  tabledata "Cost Share Buffer" = R,
                  tabledata "Load Buffer" = R,
                  tabledata "Manufacturing Setup" = R;
}