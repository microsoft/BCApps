namespace System.Security.AccessControl;

using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Reports;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.WorkCenter;

permissionsetextension 99000753 "MFG D365 BASIC ISV" extends "D365 BASIC ISV"
{
    Permissions =
                  tabledata "Cost Share Buffer" = RIMD,
                  tabledata "Load Buffer" = RIMD,
                  tabledata "Manufacturing Setup" = Ri,
                  tabledata "Work Center" = RIMD;
}