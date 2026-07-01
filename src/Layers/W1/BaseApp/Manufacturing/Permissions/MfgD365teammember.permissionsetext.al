namespace System.Security.AccessControl;

using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Reports;
using Microsoft.Manufacturing.RoleCenters;
using Microsoft.Manufacturing.WorkCenter;

permissionsetextension 99000759 "MFG D365 TEAM MEMBER" extends "D365 TEAM MEMBER"
{
    Permissions =
                  tabledata "Cost Share Buffer" = RM,
                  tabledata "Load Buffer" = RIMD,
                  tabledata "Manufacturing Cue" = RM,
                  tabledata "Work Center" = RM;
}