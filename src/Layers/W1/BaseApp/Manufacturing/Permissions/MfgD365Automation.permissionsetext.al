namespace System.Security.AccessControl;

using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Comment;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Family;
using Microsoft.Manufacturing.Forecast;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.RoleCenters;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Manufacturing.Reports;

permissionsetextension 99000750 "MFG D365 AUTOMATION" extends "D365 AUTOMATION"
{
    Permissions =
                  tabledata "Calendar Absence Entry" = RIMD,
                  tabledata "Calendar Entry" = RIMD,
                  tabledata "Capacity Constrained Resource" = RIMD,
                  tabledata "Cost Share Buffer" = RIMD,
                  tabledata Family = RIMD,
                  tabledata "Family Line" = RIMD,
                  tabledata "Load Buffer" = RIMD,
                  tabledata "Machine Center" = RIMD,
                  tabledata "Manufacturing Comment Line" = RIMD,
                  tabledata "Manufacturing Cue" = RIMD,
                  tabledata "Manufacturing Setup" = RIMD,
                  tabledata "Planning Routing Line" = RIMD,
                  tabledata "Prod. Order Capacity Need" = RIMD,
                  tabledata "Prod. Order Comment Line" = RIMD,
                  tabledata "Prod. Order Comp. Cmt Line" = RIMD,
                  tabledata "Prod. Order Component" = RIMD,
                  tabledata "Prod. Order Line" = RIMD,
                  tabledata "Prod. Order Routing Line" = RIMD,
                  tabledata "Prod. Order Routing Personnel" = RIMD,
                  tabledata "Prod. Order Routing Tool" = RIMD,
                  tabledata "Prod. Order Rtng Comment Line" = RIMD,
                  tabledata "Prod. Order Rtng Qlty Meas." = RIMD,
                  tabledata "Production BOM Comment Line" = RIMD,
                  tabledata "Production BOM Header" = RIMD,
                  tabledata "Production BOM Line" = RIMD,
                  tabledata "Production BOM Version" = RIMD,
                  tabledata "Production Forecast Entry" = RIMD,
                  tabledata "Production Forecast Name" = RIMD,
                  tabledata "Production Matrix  BOM Entry" = Rimd,
                  tabledata "Production Matrix BOM Line" = Rimd,
                  tabledata "Production Order" = RIMD,
                  tabledata "Quality Measure" = RIMD,
                  tabledata "Registered Absence" = RIMD,
                  tabledata "Routing Comment Line" = RIMD,
                  tabledata "Routing Header" = RIMD,
                  tabledata "Routing Line" = RIMD,
                  tabledata "Routing Link" = RIMD,
                  tabledata "Routing Personnel" = RIMD,
                  tabledata "Routing Quality Measure" = RIMD,
                  tabledata "Routing Tool" = RIMD,
                  tabledata "Routing Version" = RIMD,
                  tabledata Scrap = RIMD,
                  tabledata "Shop Calendar" = RIMD,
                  tabledata "Shop Calendar Holiday" = RIMD,
                  tabledata "Shop Calendar Working Days" = RIMD,
                  tabledata "Standard Task" = RIMD,
                  tabledata "Standard Task Description" = RIMD,
                  tabledata "Standard Task Personnel" = RIMD,
                  tabledata "Standard Task Quality Measure" = RIMD,
                  tabledata "Standard Task Tool" = RIMD,
                  tabledata Stop = RIMD,
                  tabledata "Where-Used Line" = Rimd,
                  tabledata "Work Center" = RIMD,
                  tabledata "Work Center Group" = RIMD,
                  tabledata "Work Shift" = RIMD;
}
