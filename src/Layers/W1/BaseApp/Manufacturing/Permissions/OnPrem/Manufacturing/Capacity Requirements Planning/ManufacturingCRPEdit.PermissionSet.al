namespace System.Security.AccessControl;

using Microsoft.Manufacturing.Capacity;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.Comment;
using Microsoft.Inventory.Planning;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Document;
using Microsoft.Purchases.Vendor;
using Microsoft.Manufacturing.WorkCenter;

permissionset 9322 "Manufacturing CRP - Edit"
{
    Access = Public;
    Assignable = false;
    Caption = 'Edit Work & machine ctr.';

    Permissions = tabledata "Calendar Absence Entry" = RIMD,
                  tabledata "Calendar Entry" = RIMD,
                  tabledata "Capacity Constrained Resource" = RIMD,
                  tabledata "Capacity Ledger Entry" = R,
                  tabledata "Capacity Unit of Measure" = R,
                  tabledata "Default Dimension" = RIMD,
                  tabledata "Gen. Product Posting Group" = R,
                  tabledata "Machine Center" = RIMD,
                  tabledata "Manufacturing Comment Line" = RIMD,
                  tabledata "Planning Component" = Rimd,
                  tabledata "Planning Routing Line" = RIMD,
                  tabledata "Prod. Order Capacity Need" = RIMD,
                  tabledata "Prod. Order Component" = Rimd,
                  tabledata "Prod. Order Line" = Rimd,
                  tabledata "Prod. Order Routing Line" = RIMD,
                  tabledata "Registered Absence" = RIMD,
                  tabledata "Shop Calendar" = RIMD,
                  tabledata Vendor = R,
                  tabledata "Work Center" = RIMD,
                  tabledata "Work Center Group" = R;
}
