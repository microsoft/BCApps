namespace System.Security.AccessControl;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Location;
using Microsoft.Warehouse.Activity.History;
using Microsoft.Warehouse.Comment;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Ledger;
using Microsoft.Foundation.Shipping;
using Microsoft.Foundation.UOM;

permissionset 4667 "Warehouse Documents - Read"
{
    Access = Public;
    Assignable = false;
    Caption = 'Read posted put away, etc.';

    Permissions = tabledata Item = R,
                  tabledata "Item Ledger Entry" = R,
                  tabledata "Item Tracking Code" = R,
                  tabledata "Item Translation" = R,
                  tabledata "Item Unit of Measure" = R,
                  tabledata "Item Variant" = R,
                  tabledata Location = R,
                  tabledata "Registered Whse. Activity Hdr." = R,
                  tabledata "Registered Whse. Activity Line" = R,
                  tabledata "Shipment Method" = R,
                  tabledata "Shipping Agent" = R,
                  tabledata "Shipping Agent Services" = R,
                  tabledata "Unit of Measure" = R,
                  tabledata "Unit of Measure Translation" = R,
                  tabledata "Warehouse Comment Line" = R,
                  tabledata "Warehouse Employee" = R,
                  tabledata "Warehouse Entry" = Ri,
                  tabledata "Warehouse Register" = Rd;
}
