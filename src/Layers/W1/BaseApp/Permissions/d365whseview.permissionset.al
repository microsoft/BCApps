namespace System.Security.AccessControl;

using Microsoft.Warehouse.Structure;
using Microsoft.Warehouse.InventoryDocument;
using Microsoft.Warehouse.History;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Activity.History;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.CrossDock;
using Microsoft.Warehouse.InternalDocument;
using Microsoft.Warehouse.Worksheet;

permissionset 910 "D365 WHSE, VIEW"
{
    Assignable = true;

    Caption = 'Dynamics 365 View warehouse';
    Permissions = tabledata "Bin Content" = R,
                  tabledata "Bin Content Buffer" = R,
                  tabledata "Bin Creation Wksh. Name" = R,
                  tabledata "Bin Creation Wksh. Template" = R,
                  tabledata "Bin Creation Worksheet Line" = R,
                  tabledata "Bin Template" = R,
                  tabledata "Bin Type" = R,
                  tabledata "Posted Invt. Pick Header" = R,
                  tabledata "Posted Invt. Pick Line" = R,
                  tabledata "Posted Invt. Put-away Header" = R,
                  tabledata "Posted Invt. Put-away Line" = R,
                  tabledata "Posted Whse. Receipt Header" = R,
                  tabledata "Posted Whse. Receipt Line" = R,
                  tabledata "Posted Whse. Shipment Header" = R,
                  tabledata "Posted Whse. Shipment Line" = R,
                  tabledata "Put-away Template Header" = R,
                  tabledata "Put-away Template Line" = R,
                  tabledata "Registered Whse. Activity Hdr." = R,
                  tabledata "Registered Whse. Activity Line" = R,
                  tabledata "Special Equipment" = R,
                  tabledata "Warehouse Activity Header" = R,
                  tabledata "Warehouse Activity Line" = R,
                  tabledata "Warehouse Employee" = R,
                  tabledata "Warehouse Entry" = Ri,
                  tabledata "Warehouse Journal Batch" = R,
                  tabledata "Warehouse Journal Line" = R,
                  tabledata "Warehouse Journal Template" = R,
                  tabledata "Warehouse Reason Code" = R,
                  tabledata "Warehouse Receipt Header" = R,
                  tabledata "Warehouse Receipt Line" = R,
                  tabledata "Warehouse Register" = R,
                  tabledata "Warehouse Request" = R,
                  tabledata "Warehouse Shipment Header" = R,
                  tabledata "Warehouse Shipment Line" = R,
                  tabledata "Warehouse Source Filter" = R,
                  tabledata "Whse. Cross-Dock Opportunity" = R,
                  tabledata "Whse. Internal Pick Header" = R,
                  tabledata "Whse. Internal Pick Line" = R,
                  tabledata "Whse. Internal Put-away Header" = R,
                  tabledata "Whse. Internal Put-away Line" = R,
                  tabledata "Whse. Item Entry Relation" = R,
                  tabledata "Whse. Pick Request" = R,
                  tabledata "Whse. Put-away Request" = R,
                  tabledata "Whse. Worksheet Line" = R,
                  tabledata "Whse. Worksheet Name" = R,
                  tabledata "Whse. Worksheet Template" = R,
                  tabledata Zone = R;
}
