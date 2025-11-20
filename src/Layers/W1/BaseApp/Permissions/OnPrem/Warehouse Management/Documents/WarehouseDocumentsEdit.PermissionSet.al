namespace System.Security.AccessControl;

using Microsoft.Warehouse.Structure;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Warehouse.History;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Document;
using Microsoft.Warehouse.Activity.History;
using Microsoft.Sales.History;
using Microsoft.Sales.Document;
using System.Security.User;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Comment;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.CrossDock;
using Microsoft.Warehouse.InternalDocument;
using Microsoft.Warehouse.Worksheet;
using Microsoft.Foundation.Reporting;
using Microsoft.Foundation.Shipping;
using Microsoft.Foundation.UOM;

permissionset 5888 "Warehouse Documents - Edit"
{
    Access = Public;
    Assignable = false;
    Caption = 'Create receipt, put away, etc.';

    Permissions = tabledata "Bin Content" = RI,
                  tabledata "Entry Summary" = RIMD,
                  tabledata Item = R,
                  tabledata "Item Application Entry" = RIMD,
                  tabledata "Item Ledger Entry" = R,
                  tabledata "Item Tracking Code" = R,
                  tabledata "Item Tracking Comment" = RIMD,
                  tabledata "Item Translation" = R,
                  tabledata "Item Unit of Measure" = R,
                  tabledata "Item Variant" = R,
                  tabledata Location = R,
                  tabledata "Lot No. Information" = RIMD,
                  tabledata "Package No. Information" = RIMD,
                  tabledata "Posted Whse. Receipt Header" = R,
                  tabledata "Posted Whse. Receipt Line" = R,
                  tabledata "Posted Whse. Shipment Header" = R,
                  tabledata "Posted Whse. Shipment Line" = R,
                  tabledata "Purch. Rcpt. Header" = RM,
                  tabledata "Purch. Rcpt. Line" = RM,
                  tabledata "Purchase Header" = R,
                  tabledata "Purchase Line" = R,
                  tabledata "Registered Whse. Activity Hdr." = R,
                  tabledata "Registered Whse. Activity Line" = R,
                  tabledata "Report Selections" = R,
                  tabledata "Reservation Entry" = RIMD,
                  tabledata "Return Receipt Header" = RM,
                  tabledata "Return Receipt Line" = RM,
                  tabledata "Return Shipment Header" = RM,
                  tabledata "Return Shipment Line" = RM,
                  tabledata "Sales Header" = R,
                  tabledata "Sales Line" = R,
                  tabledata "Sales Shipment Header" = RM,
                  tabledata "Sales Shipment Line" = RM,
                  tabledata "Serial No. Information" = RIMD,
                  tabledata "Shipment Method" = R,
                  tabledata "Shipping Agent" = R,
                  tabledata "Shipping Agent Services" = R,
                  tabledata "Tracking Specification" = RIMD,
                  tabledata "Unit of Measure" = R,
                  tabledata "Unit of Measure Translation" = R,
                  tabledata "User Setup" = R,
                  tabledata "Warehouse Activity Header" = RIMD,
                  tabledata "Warehouse Activity Line" = RIMD,
                  tabledata "Warehouse Comment Line" = RIMD,
                  tabledata "Warehouse Employee" = R,
                  tabledata "Warehouse Entry" = Ri,
                  tabledata "Warehouse Reason Code" = RIMD,
                  tabledata "Warehouse Receipt Header" = RIMD,
                  tabledata "Warehouse Receipt Line" = RIMD,
                  tabledata "Warehouse Register" = Rim,
                  tabledata "Warehouse Request" = R,
                  tabledata "Warehouse Shipment Header" = RIMD,
                  tabledata "Warehouse Shipment Line" = RIMD,
                  tabledata "Warehouse Source Filter" = RIMD,
                  tabledata "Whse. Cross-Dock Opportunity" = RIMD,
                  tabledata "Whse. Internal Pick Header" = RIMD,
                  tabledata "Whse. Internal Pick Line" = RIMD,
                  tabledata "Whse. Internal Put-away Header" = RIMD,
                  tabledata "Whse. Internal Put-away Line" = RIMD,
                  tabledata "Whse. Pick Request" = R,
                  tabledata "Whse. Put-away Request" = R,
                  tabledata "Whse. Worksheet Line" = RIMD,
                  tabledata "Whse. Worksheet Name" = R;
}
