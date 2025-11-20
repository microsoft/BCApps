namespace System.Security.AccessControl;

using Microsoft.Service.Contract;
using Microsoft.Service.Resources;
using Microsoft.Service.Item;

permissionsetextension 5903 "SERV D365 Basic Read" extends "D365 Basic - Read"
{
    Permissions =
                  tabledata "Contract Trend Buffer" = R,
                  tabledata "Resource Skill" = R,
                  tabledata "Service Item Trend Buffer" = R;
}