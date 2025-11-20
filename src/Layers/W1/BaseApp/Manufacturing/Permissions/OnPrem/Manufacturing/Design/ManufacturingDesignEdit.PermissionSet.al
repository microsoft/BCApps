namespace System.Security.AccessControl;

using Microsoft.Manufacturing.Capacity;
using Microsoft.Inventory.Item;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.Comment;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Manufacturing.Setup;

permissionset 5053 "Manufacturing Design - Edit"
{
    Access = Public;
    Assignable = false;
    Caption = 'Edit Production BOM & Routing';

    Permissions = tabledata "Capacity Constrained Resource" = R,
                  tabledata "Capacity Unit of Measure" = R,
                  tabledata Item = Rm,
                  tabledata "Machine Center" = R,
                  tabledata "Manufacturing Comment Line" = RIMD,
                  tabledata "Production BOM Comment Line" = RIMD,
                  tabledata "Production BOM Header" = RIMD,
                  tabledata "Production BOM Line" = RIMD,
                  tabledata "Production BOM Version" = RIMD,
                  tabledata "Production Matrix  BOM Entry" = Rimd,
                  tabledata "Production Matrix BOM Line" = Rimd,
                  tabledata "Quality Measure" = R,
                  tabledata "Routing Comment Line" = RIMD,
                  tabledata "Routing Header" = RIMD,
                  tabledata "Routing Line" = RIMD,
                  tabledata "Routing Link" = R,
                  tabledata "Routing Personnel" = RIMD,
                  tabledata "Routing Quality Measure" = RIMD,
                  tabledata "Routing Tool" = RIMD,
                  tabledata "Routing Version" = R,
                  tabledata "Standard Task" = R,
                  tabledata "Standard Task Description" = R,
                  tabledata "Standard Task Personnel" = R,
                  tabledata "Standard Task Quality Measure" = R,
                  tabledata "Standard Task Tool" = R,
                  tabledata "Where-Used Line" = Rimd,
                  tabledata "Work Center" = R;
}
