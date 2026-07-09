namespace System.Security.AccessControl;

using Microsoft.Service.Contract;
using Microsoft.Service.Item;
using Microsoft.Service.Ledger;
using Microsoft.Service.Maintenance;
using Microsoft.Service.Resources;

permissionsetextension 5910 "SERV D365 ITEM EDIT" extends "D365 ITEM, EDIT"
{
    Permissions =
                  tabledata "Resource Skill" = RIMD,
                  tabledata "Service Contract Line" = R,
                  tabledata "Service Item" = RM,
                  tabledata "Service Item Component" = RM,
                  tabledata "Service Ledger Entry" = Rm,
                  tabledata "Troubleshooting Setup" = RIMD,
                  tabledata "Warranty Ledger Entry" = RM;
}