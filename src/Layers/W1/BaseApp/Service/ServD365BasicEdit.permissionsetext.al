namespace System.Security.AccessControl;

using Microsoft.Service.Contract;
using Microsoft.Service.Item;
using Microsoft.Service.Resources;

permissionsetextension 5902 "SERV D365 Basic - Edit" extends "D365 Basic - Edit"
{
    Permissions =
                  tabledata "Contract Trend Buffer" = IMD,
                  tabledata "Resource Skill" = im,
                  tabledata "Service Item Trend Buffer" = IMD;
}