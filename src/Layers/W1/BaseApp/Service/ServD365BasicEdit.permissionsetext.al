namespace System.Security.AccessControl;

using Microsoft.Service.Contract;
using Microsoft.Service.Resources;
using Microsoft.Service.Item;

permissionsetextension 5902 "SERV D365 Basic - Edit" extends "D365 Basic - Edit"
{
    Permissions =
                  tabledata "Contract Trend Buffer" = IMD,
                  tabledata "Resource Skill" = im,
                  tabledata "Service Item Trend Buffer" = IMD;
}