namespace System.Security.AccessControl;

using Microsoft.Assembly.Document;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Projects.Project.Planning;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;

permissionset 2919 "D365 ITEM AVAIL CALC"
{
    Assignable = true;

    Caption = 'Calculate item availability';

    Permissions =
        tabledata "Assembly Header" = r,
        tabledata "Assembly Line" = r,
        tabledata "Item Ledger Entry" = r,
        tabledata "Job Planning Line" = r,
        tabledata "Planning Component" = r,
        tabledata "Purchase Line" = r,
        tabledata "Requisition Line" = r,
        tabledata "Reservation Entry" = r,
        tabledata "Sales Line" = r,
        tabledata "Transfer Line" = r,
        tabledata "Value Entry" = r;
}