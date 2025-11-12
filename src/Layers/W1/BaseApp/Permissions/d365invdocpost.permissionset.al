namespace System.Security.AccessControl;

using Microsoft.Inventory.Ledger;
using System.Environment.Configuration;
using Microsoft.Inventory.Transfer;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Document;
using Microsoft.Inventory.Costing;

permissionset 5267 "D365 INV DOC, POST"
{
    Assignable = true;

    Caption = 'Dyn. 365 Post inventory doc';
    Permissions = tabledata "Avg. Cost Adjmt. Entry Point" = RIM,
                  tabledata "Item Register" = Rimd,
                  tabledata "Notification Entry" = RIMD,
                  tabledata "Sent Notification Entry" = RIMD,
                  tabledata "Transfer Header" = RM,
                  tabledata "Transfer Line" = RM,
                  tabledata "Transfer Receipt Header" = RIMD,
                  tabledata "Transfer Receipt Line" = RIMD,
                  tabledata "Transfer Shipment Header" = RIMD,
                  tabledata "Transfer Shipment Line" = RIMD,
                  tabledata "Warehouse Activity Line" = RIMD,
                  tabledata "Warehouse Reason Code" = RIMD,
                  tabledata "Warehouse Shipment Line" = RIMD;
}
