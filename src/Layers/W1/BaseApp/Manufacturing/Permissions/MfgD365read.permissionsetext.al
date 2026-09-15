namespace System.Security.AccessControl;

using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Comment;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Family;
using Microsoft.Manufacturing.Forecast;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Reports;
using Microsoft.Manufacturing.RoleCenters;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.StandardCost;
using Microsoft.Manufacturing.WorkCenter;

permissionsetextension 99000757 "MFG D365 READ" extends "D365 READ"
{
    Permissions =
                  tabledata "Calendar Absence Entry" = R,
                  tabledata "Calendar Entry" = R,
                  tabledata "Capacity Constrained Resource" = R,
                  tabledata "Cost Share Buffer" = R,
                  tabledata Family = R,
                  tabledata "Family Line" = R,
                  tabledata "Load Buffer" = R,
                  tabledata "Machine Center" = R,
                  tabledata "Manufacturing Comment Line" = R,
                  tabledata "Manufacturing Cue" = R,
                  tabledata "Manufacturing Setup" = R,
                  tabledata "Planning Routing Line" = R,
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
                  tabledata "Production BOM Comment Line" = R,
                  tabledata "Production BOM Header" = R,
                  tabledata "Production BOM Line" = R,
                  tabledata "Production BOM Version" = R,
                  tabledata "Production Forecast Entry" = R,
                  tabledata "Production Forecast Name" = R,
                  tabledata "Production Matrix  BOM Entry" = R,
                  tabledata "Production Matrix BOM Line" = R,
                  tabledata "Production Order" = R,
                  tabledata "Quality Measure" = R,
                  tabledata "Registered Absence" = R,
                  tabledata "Routing Comment Line" = R,
                  tabledata "Routing Header" = R,
                  tabledata "Routing Line" = R,
                  tabledata "Routing Link" = R,
                  tabledata "Routing Personnel" = R,
                  tabledata "Routing Quality Measure" = R,
                  tabledata "Routing Tool" = R,
                  tabledata "Routing Version" = R,
                  tabledata Scrap = R,
                  tabledata "Shop Calendar" = R,
                  tabledata "Shop Calendar Holiday" = R,
                  tabledata "Shop Calendar Working Days" = R,
                  tabledata "Standard Cost Worksheet" = R,
                  tabledata "Standard Cost Worksheet Name" = R,
                  tabledata "Standard Task" = R,
                  tabledata "Standard Task Description" = R,
                  tabledata "Standard Task Personnel" = R,
                  tabledata "Standard Task Quality Measure" = R,
                  tabledata "Standard Task Tool" = R,
                  tabledata Stop = R,
                  tabledata "Where-Used Line" = R,
                  tabledata "Work Center" = R,
                  tabledata "Work Center Group" = R,
                  tabledata "Work Shift" = R;
}