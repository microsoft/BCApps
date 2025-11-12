namespace System.Security.AccessControl;

using Microsoft.Service.Ledger;

permissionsetextension 5900 "SERV D365 ACCOUNTANTS" extends "D365 ACCOUNTANTS"
{
    Permissions =
                  tabledata "Warranty Ledger Entry" = Rm;
}