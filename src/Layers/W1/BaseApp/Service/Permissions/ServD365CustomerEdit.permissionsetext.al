namespace System.Security.AccessControl;

using Microsoft.Service.Archive;
using Microsoft.Service.Contract;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using Microsoft.Service.Item;
using Microsoft.Service.Ledger;

permissionsetextension 5907 "SERV D365 CUSTOMER, EDIT" extends "D365 CUSTOMER, EDIT"
{
    Permissions =
                  tabledata "Contract Gain/Loss Entry" = rm,
                  tabledata "Filed Contract Line" = rm,
                  tabledata "Service Contract Header" = Rm,
                  tabledata "Service Contract Line" = Rm,
                  tabledata "Service Header" = Rm,
                  tabledata "Service Header Archive" = rm,
                  tabledata "Service Invoice Line" = Rm,
                  tabledata "Service Item" = Rm,
                  tabledata "Service Item Line" = Rm,
                  tabledata "Service Item Line Archive" = rm,
                  tabledata "Service Ledger Entry" = rm,
                  tabledata "Service Line" = r,
                  tabledata "Service Line Archive" = r,
                  tabledata "Warranty Ledger Entry" = rm;
}