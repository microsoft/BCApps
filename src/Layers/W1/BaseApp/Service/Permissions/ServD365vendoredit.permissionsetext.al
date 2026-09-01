namespace System.Security.AccessControl;

using Microsoft.Service.Contract;
using Microsoft.Service.Item;
using Microsoft.Service.Ledger;

permissionsetextension 5914 "SERV D365 VENDOR, EDIT" extends "D365 VENDOR, EDIT"
{
    Permissions =
                  tabledata "Contract Gain/Loss Entry" = rm,
                  tabledata "Filed Contract Line" = rm,
                  tabledata "Service Item" = r,
                  tabledata "Warranty Ledger Entry" = rm;
}