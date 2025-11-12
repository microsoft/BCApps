namespace System.Security.AccessControl;

using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Family;
using Microsoft.Inventory.Tracking;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.Comment;
using Microsoft.Manufacturing.Setup;
using Microsoft.Inventory.Requisition;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.WorkCenter;

permissionsetextension 99000766 "MFG D365 PREM EDIT" extends "D365PREM MFG, EDIT"
{
    Permissions = tabledata "Calendar Absence Entry" = ID,
                  tabledata "Calendar Entry" = ID,
                  tabledata "Capacity Constrained Resource" = ID,
                  tabledata "Capacity Ledger Entry" = id,
                  tabledata "Capacity Unit of Measure" = ID,
                  tabledata Family = ID,
                  tabledata "Family Line" = ID,
                  tabledata "Inventory Profile" = id,
                  tabledata "Machine Center" = ID,
                  tabledata "Manufacturing Comment Line" = ID,
                  tabledata "Manufacturing Setup" = ID,
                  tabledata "Manufacturing User Template" = ID,
                  tabledata "Planning Routing Line" = ID,
                  tabledata "Prod. Order Capacity Need" = ID,
                  tabledata "Prod. Order Comment Line" = ID,
                  tabledata "Prod. Order Comp. Cmt Line" = ID,
                  tabledata "Prod. Order Component" = ID,
                  tabledata "Prod. Order Line" = ID,
                  tabledata "Prod. Order Routing Line" = ID,
                  tabledata "Prod. Order Routing Personnel" = ID,
                  tabledata "Prod. Order Routing Tool" = ID,
                  tabledata "Prod. Order Rtng Comment Line" = ID,
                  tabledata "Prod. Order Rtng Qlty Meas." = ID,
                  tabledata "Production BOM Comment Line" = ID,
                  tabledata "Production BOM Header" = ID,
                  tabledata "Production BOM Line" = ID,
                  tabledata "Production BOM Version" = ID,
                  tabledata "Production Matrix  BOM Entry" = id,
                  tabledata "Production Matrix BOM Line" = id,
                  tabledata "Production Order" = ID,
                  tabledata "Quality Measure" = ID,
                  tabledata "Registered Absence" = ID,
                  tabledata "Routing Comment Line" = ID,
                  tabledata "Routing Header" = ID,
                  tabledata "Routing Line" = ID,
                  tabledata "Routing Link" = ID,
                  tabledata "Routing Personnel" = ID,
                  tabledata "Routing Quality Measure" = ID,
                  tabledata "Routing Tool" = ID,
                  tabledata "Routing Version" = ID,
                  tabledata Scrap = ID,
                  tabledata "Shop Calendar" = ID,
                  tabledata "Shop Calendar Holiday" = ID,
                  tabledata "Shop Calendar Working Days" = ID,
                  tabledata "Standard Task" = ID,
                  tabledata "Standard Task Description" = ID,
                  tabledata "Standard Task Personnel" = ID,
                  tabledata "Standard Task Quality Measure" = ID,
                  tabledata "Standard Task Tool" = ID,
                  tabledata Stop = ID,
                  tabledata "Where-Used Line" = id,
                  tabledata "Work Center Group" = ID,
                  tabledata "Work Shift" = ID;
}
