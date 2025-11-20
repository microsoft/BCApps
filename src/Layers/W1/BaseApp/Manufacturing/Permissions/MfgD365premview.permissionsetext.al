namespace System.Security.AccessControl;

using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Tracking;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Family;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.Comment;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.WorkCenter;

permissionsetextension 99000765 "MFG D365 PREM VIEW" extends "D365PREM MFG, VIEW"
{
    Permissions = tabledata "Calendar Absence Entry" = RM,
                  tabledata "Calendar Entry" = RM,
                  tabledata "Capacity Constrained Resource" = RM,
                  tabledata "Capacity Ledger Entry" = Rm,
                  tabledata "Capacity Unit of Measure" = RM,
                  tabledata Family = RM,
                  tabledata "Family Line" = RM,
                  tabledata "Inventory Profile" = Rm,
                  tabledata "Machine Center" = RM,
                  tabledata "Manufacturing Comment Line" = RM,
                  tabledata "Manufacturing Setup" = RM,
                  tabledata "Manufacturing User Template" = RM,
                  tabledata "Planning Routing Line" = RM,
                  tabledata "Prod. Order Capacity Need" = RM,
                  tabledata "Prod. Order Comment Line" = RM,
                  tabledata "Prod. Order Comp. Cmt Line" = RM,
                  tabledata "Prod. Order Component" = RM,
                  tabledata "Prod. Order Line" = RM,
                  tabledata "Prod. Order Routing Line" = RM,
                  tabledata "Prod. Order Routing Personnel" = RM,
                  tabledata "Prod. Order Routing Tool" = RM,
                  tabledata "Prod. Order Rtng Comment Line" = RM,
                  tabledata "Prod. Order Rtng Qlty Meas." = RM,
                  tabledata "Production BOM Comment Line" = RM,
                  tabledata "Production BOM Header" = RM,
                  tabledata "Production BOM Line" = RM,
                  tabledata "Production BOM Version" = RM,
                  tabledata "Production Matrix  BOM Entry" = Rm,
                  tabledata "Production Matrix BOM Line" = Rm,
                  tabledata "Production Order" = RM,
                  tabledata "Quality Measure" = RM,
                  tabledata "Registered Absence" = RM,
                  tabledata "Routing Comment Line" = RM,
                  tabledata "Routing Header" = RM,
                  tabledata "Routing Line" = RM,
                  tabledata "Routing Link" = RM,
                  tabledata "Routing Personnel" = RM,
                  tabledata "Routing Quality Measure" = RM,
                  tabledata "Routing Tool" = RM,
                  tabledata "Routing Version" = RM,
                  tabledata Scrap = RM,
                  tabledata "Shop Calendar" = RM,
                  tabledata "Shop Calendar Holiday" = RM,
                  tabledata "Shop Calendar Working Days" = RM,
                  tabledata "Standard Task" = RM,
                  tabledata "Standard Task Description" = RM,
                  tabledata "Standard Task Personnel" = RM,
                  tabledata "Standard Task Quality Measure" = RM,
                  tabledata "Standard Task Tool" = RM,
                  tabledata Stop = RM,
                  tabledata "Where-Used Line" = Rm,
                  tabledata "Work Center Group" = RM,
                  tabledata "Work Shift" = RM;
}
