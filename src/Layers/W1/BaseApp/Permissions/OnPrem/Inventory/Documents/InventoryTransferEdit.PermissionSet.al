namespace System.Security.AccessControl;

using Microsoft.Inventory.Transfer;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Inventory.Comment;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Location;
using Microsoft.Warehouse.History;
using Microsoft.Foundation.Reporting;
using Microsoft.Foundation.Shipping;
using Microsoft.Foundation.UOM;

permissionset 9714 "Inventory Transfer - Edit"
{
    Access = Public;
    Assignable = false;
    Caption = 'Create transfer orders';

    Permissions = tabledata "Direct Trans. Header" = R,
                  tabledata "Direct Trans. Line" = R,
                  tabledata "Gen. Business Posting Group" = R,
                  tabledata "Gen. Product Posting Group" = R,
                  tabledata "Inventory Comment Line" = RIMD,
                  tabledata "Inventory Posting Group" = R,
                  tabledata Item = R,
                  tabledata "Item Application Entry" = Ri,
                  tabledata "Item Tracking Code" = R,
                  tabledata "Item Tracking Comment" = RIMD,
                  tabledata "Item Unit of Measure" = R,
                  tabledata Location = R,
                  tabledata "Lot No. Information" = RIMD,
                  tabledata "Package No. Information" = RIMD,
                  tabledata "Posted Whse. Receipt Header" = R,
                  tabledata "Posted Whse. Receipt Line" = R,
                  tabledata "Posted Whse. Shipment Header" = R,
                  tabledata "Posted Whse. Shipment Line" = R,
                  tabledata "Report Selections" = R,
                  tabledata "Reservation Entry" = Rimd,
                  tabledata "Serial No. Information" = RIMD,
                  tabledata "Shipment Method" = R,
                  tabledata "Shipping Agent" = R,
                  tabledata "Shipping Agent Services" = R,
                  tabledata "Stockkeeping Unit" = R,
                  tabledata "Tracking Specification" = Rimd,
                  tabledata "Transfer Header" = RIMD,
                  tabledata "Transfer Line" = RIMD,
                  tabledata "Transfer Receipt Header" = R,
                  tabledata "Transfer Receipt Line" = R,
                  tabledata "Transfer Route" = R,
                  tabledata "Transfer Shipment Header" = R,
                  tabledata "Transfer Shipment Line" = R,
                  tabledata "Unit of Measure" = R,
                  tabledata "Unit of Measure Translation" = R,
                  tabledata "Value Entry" = r;
}
