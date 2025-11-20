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

permissionset 8992 "D365 WHSE, EDIT"
{
    Assignable = true;
    Caption = 'Dynamics 365 Create warehouse';

    IncludedPermissionSets = "D365 WHSE, SETUP",
                             "D365 WHSE, VIEW";

    Permissions = tabledata "Bin Content" = IMD,
                  tabledata "Bin Content Buffer" = IMD,
                  tabledata "Bin Creation Wksh. Name" = IMD,
                  tabledata "Bin Creation Wksh. Template" = IMD,
                  tabledata "Bin Creation Worksheet Line" = IMD,
                  tabledata "Bin Template" = IMD,
                  tabledata "Bin Type" = IMD,
                  tabledata "Posted Invt. Pick Header" = IMD,
                  tabledata "Posted Invt. Pick Line" = IMD,
                  tabledata "Posted Invt. Put-away Header" = IMD,
                  tabledata "Posted Invt. Put-away Line" = IMD,
                  tabledata "Posted Whse. Receipt Header" = IMD,
                  tabledata "Posted Whse. Receipt Line" = IMD,
                  tabledata "Posted Whse. Shipment Header" = IMD,
                  tabledata "Posted Whse. Shipment Line" = IMD,
                  tabledata "Put-away Template Header" = IMD,
                  tabledata "Put-away Template Line" = IMD,
                  tabledata "Registered Whse. Activity Hdr." = imD,
                  tabledata "Registered Whse. Activity Line" = imD,
                  tabledata "Special Equipment" = IMD,
                  tabledata "Warehouse Activity Header" = IM,
                  tabledata "Warehouse Activity Line" = IM,
                  tabledata "Warehouse Reason Code" = IM,
                  tabledata "Warehouse Class" = RIMD,
                  tabledata "Warehouse Employee" = IM,
                  tabledata "Warehouse Entry" = md,
                  tabledata "Warehouse Journal Batch" = IMD,
                  tabledata "Warehouse Journal Line" = IMD,
                  tabledata "Warehouse Journal Template" = IMD,
                  tabledata "Warehouse Receipt Header" = IMD,
                  tabledata "Warehouse Receipt Line" = IMD,
                  tabledata "Warehouse Register" = IM,
                  tabledata "Warehouse Request" = IM,
                  tabledata "Warehouse Shipment Header" = IMD,
                  tabledata "Warehouse Shipment Line" = IM,
                  tabledata "Warehouse Source Filter" = IM,
                  tabledata "Whse. Cross-Dock Opportunity" = IMD,
                  tabledata "Whse. Internal Pick Header" = IMD,
                  tabledata "Whse. Internal Pick Line" = IMD,
                  tabledata "Whse. Internal Put-away Header" = IMD,
                  tabledata "Whse. Internal Put-away Line" = IMD,
                  tabledata "Whse. Item Entry Relation" = IMD,
                  tabledata "Whse. Pick Request" = IM,
                  tabledata "Whse. Put-away Request" = IM,
                  tabledata "Whse. Worksheet Line" = IMD,
                  tabledata "Whse. Worksheet Name" = IMD,
                  tabledata "Whse. Worksheet Template" = IMD,
                  tabledata Zone = IMD;
}
