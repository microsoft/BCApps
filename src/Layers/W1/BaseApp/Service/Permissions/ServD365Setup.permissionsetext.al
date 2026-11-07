namespace System.Security.AccessControl;

using Microsoft.Service.Contract;
using Microsoft.Service.Document;
using Microsoft.Service.Ledger;

permissionsetextension 5911 "SERV D365 SETUP" extends "D365 SETUP"
{
    Permissions =
                  tabledata "Contract Gain/Loss Entry" = D,
                  tabledata "Filed Contract Line" = RD,
                  tabledata "Service Line" = Rm,
                  tabledata "Warranty Ledger Entry" = d;
}