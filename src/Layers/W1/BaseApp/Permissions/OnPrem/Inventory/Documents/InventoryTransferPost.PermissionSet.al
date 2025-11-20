namespace System.Security.AccessControl;

using Microsoft.Inventory.Transfer;
using Microsoft.Inventory.Comment;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Tracking;
using Microsoft.Warehouse.History;
using Microsoft.Inventory.Location;
using Microsoft.Warehouse.Request;
using Microsoft.Foundation.Shipping;

permissionset 5127 "Inventory Transfer - Post"
{
    Access = Public;
    Assignable = false;
    Caption = 'Post transfer orders';

    Permissions = tabledata "Direct Trans. Header" = IM,
                  tabledata "Direct Trans. Line" = IM,
                  tabledata "Inventory Comment Line" = RID,
                  tabledata "Item Application Entry" = RID,
                  tabledata "Item Journal Line" = ID,
                  tabledata "Item Ledger Entry" = Rim,
                  tabledata "Item Tracking Code" = R,
                  tabledata "Item Tracking Comment" = RIMD,
                  tabledata "Lot No. Information" = R,
                  tabledata "Package No. Information" = R,
                  tabledata "Posted Whse. Receipt Header" = IM,
                  tabledata "Posted Whse. Receipt Line" = IM,
                  tabledata "Posted Whse. Shipment Header" = IM,
                  tabledata "Posted Whse. Shipment Line" = IM,
                  tabledata "Reservation Entry" = RID,
                  tabledata "Serial No. Information" = R,
                  tabledata "Shipping Agent" = R,
                  tabledata "Shipping Agent Services" = R,
                  tabledata "Stockkeeping Unit" = R,
                  tabledata "Tracking Specification" = RID,
                  tabledata "Transfer Header" = RD,
                  tabledata "Transfer Line" = RD,
                  tabledata "Transfer Receipt Header" = IM,
                  tabledata "Transfer Receipt Line" = IM,
                  tabledata "Transfer Route" = R,
                  tabledata "Transfer Shipment Header" = IM,
                  tabledata "Transfer Shipment Line" = IM,
                  tabledata "Value Entry" = r,
                  tabledata "Warehouse Request" = RIMD,
                  tabledata "Whse. Pick Request" = RIMD,
                  tabledata "Whse. Put-away Request" = RIMD;
}
