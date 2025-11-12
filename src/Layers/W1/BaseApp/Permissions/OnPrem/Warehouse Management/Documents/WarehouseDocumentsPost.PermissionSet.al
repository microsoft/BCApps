namespace System.Security.AccessControl;

using Microsoft.Warehouse.Structure;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Location;
using Microsoft.Warehouse.History;
using Microsoft.Purchases.Document;
using Microsoft.Warehouse.Activity.History;
using Microsoft.Sales.Document;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Comment;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Request;
using Microsoft.Foundation.Shipping;
using Microsoft.Foundation.UOM;

permissionset 9425 "Warehouse Documents - Post"
{
    Access = Public;
    Assignable = false;
    Caption = 'Post receipt, put away,etc.';

    Permissions = tabledata Bin = M,
                  tabledata Item = R,
                  tabledata "Item Ledger Entry" = RIMD,
                  tabledata "Item Tracking Code" = R,
                  tabledata "Item Tracking Comment" = RIMD,
                  tabledata "Item Translation" = R,
                  tabledata "Item Unit of Measure" = R,
                  tabledata "Item Variant" = RIMD,
                  tabledata Location = R,
                  tabledata "Lot No. Information" = R,
                  tabledata "Package No. Information" = R,
                  tabledata "Posted Whse. Receipt Header" = RD,
                  tabledata "Posted Whse. Receipt Line" = RD,
                  tabledata "Posted Whse. Shipment Header" = RD,
                  tabledata "Posted Whse. Shipment Line" = RD,
                  tabledata "Purchase Header" = RM,
                  tabledata "Purchase Line" = RM,
                  tabledata "Registered Whse. Activity Hdr." = RIMD,
                  tabledata "Registered Whse. Activity Line" = RIMD,
                  tabledata "Sales Header" = RM,
                  tabledata "Sales Line" = RM,
                  tabledata "Serial No. Information" = R,
                  tabledata "Shipment Method" = R,
                  tabledata "Shipping Agent" = R,
                  tabledata "Shipping Agent Services" = R,
                  tabledata "Unit of Measure" = R,
                  tabledata "Unit of Measure Translation" = R,
                  tabledata "Warehouse Activity Header" = RIMD,
                  tabledata "Warehouse Activity Line" = RIMD,
                  tabledata "Warehouse Comment Line" = RIMD,
                  tabledata "Warehouse Employee" = RM,
                  tabledata "Warehouse Entry" = R,
                  tabledata "Warehouse Reason Code" = RIMD,
                  tabledata "Warehouse Register" = R,
                  tabledata "Warehouse Request" = RMD,
                  tabledata "Warehouse Setup" = Rm,
                  tabledata "Whse. Pick Request" = RD,
                  tabledata "Whse. Put-away Request" = RD;
}
