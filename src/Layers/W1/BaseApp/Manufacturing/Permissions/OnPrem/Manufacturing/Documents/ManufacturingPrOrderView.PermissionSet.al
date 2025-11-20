namespace System.Security.AccessControl;

using Microsoft.Warehouse.Structure;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Inventory.Tracking;
using Microsoft.Manufacturing.Family;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.RoleCenters;
using Microsoft.Inventory.Planning;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Purchases.Document;
using Microsoft.Inventory.Requisition;
using Microsoft.Manufacturing.Routing;
using Microsoft.Sales.Document;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.UOM;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Finance.VAT.RateChange;
using Microsoft.Finance.VAT.Reporting;
using Microsoft.Finance.VAT.Calculation;

permissionset 407 "Manufacturing Pr. Order - View"
{
    Access = Public;
    Assignable = false;
    Caption = 'Read production order';

    Permissions = tabledata Bin = R,
                  tabledata "Capacity Constrained Resource" = R,
                  tabledata "Capacity Ledger Entry" = R,
                  tabledata "Capacity Unit of Measure" = R,
                  tabledata "Entry Summary" = RIMD,
                  tabledata Family = R,
                  tabledata "Family Line" = R,
                  tabledata "Gen. Business Posting Group" = R,
                  tabledata "Gen. Product Posting Group" = R,
                  tabledata "General Posting Setup" = R,
                  tabledata "Inventory Posting Group" = R,
                  tabledata "Inventory Posting Setup" = R,
                  tabledata Item = R,
                  tabledata "Item Journal Line" = R,
                  tabledata "Item Ledger Entry" = R,
                  tabledata "Item Unit of Measure" = R,
                  tabledata "Item Variant" = R,
                  tabledata Location = R,
                  tabledata "Machine Center" = R,
                  tabledata "Manufacturing Cue" = R,
                  tabledata "Planning Component" = R,
                  tabledata "Prod. Order Capacity Need" = R,
                  tabledata "Prod. Order Comment Line" = R,
                  tabledata "Prod. Order Comp. Cmt Line" = R,
                  tabledata "Prod. Order Component" = R,
                  tabledata "Prod. Order Line" = R,
                  tabledata "Prod. Order Routing Line" = R,
                  tabledata "Prod. Order Routing Personnel" = R,
                  tabledata "Prod. Order Routing Tool" = R,
                  tabledata "Prod. Order Rtng Comment Line" = R,
                  tabledata "Prod. Order Rtng Qlty Meas." = R,
                  tabledata "Production BOM Header" = R,
                  tabledata "Production BOM Line" = R,
                  tabledata "Production BOM Version" = R,
                  tabledata "Production Order" = R,
                  tabledata "Purchase Line" = R,
                  tabledata "Reason Code" = R,
                  tabledata "Requisition Line" = R,
                  tabledata "Reservation Entry" = R,
                  tabledata "Routing Header" = R,
                  tabledata "Routing Line" = R,
                  tabledata "Routing Version" = R,
                  tabledata "Sales Header" = R,
                  tabledata "Sales Line" = R,
                  tabledata "Source Code" = R,
                  tabledata "Source Code Setup" = R,
                  tabledata "Standard Task" = R,
                  tabledata "Tracking Specification" = R,
                  tabledata "Unit of Measure" = R,
                  tabledata "Value Entry" = R,
                  tabledata "VAT Assisted Setup Bus. Grp." = R,
                  tabledata "VAT Assisted Setup Templates" = R,
                  tabledata "VAT Business Posting Group" = R,
                  tabledata "VAT Posting Setup" = R,
                  tabledata "VAT Product Posting Group" = R,
                  tabledata "VAT Rate Change Conversion" = R,
                  tabledata "VAT Rate Change Log Entry" = Ri,
                  tabledata "VAT Rate Change Setup" = R,
                  tabledata "VAT Reporting Code" = R,
                  tabledata "VAT Setup Posting Groups" = R,
                  tabledata "VAT Setup" = R,
                  tabledata "VAT Posting Parameters" = R,
                  tabledata "Work Center" = R;
}
