namespace System.Security.AccessControl;

using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Forecast;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Reports;
using Microsoft.Manufacturing.RoleCenters;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.WorkCenter;

permissionsetextension 99000754 "MFG D365 BUS FULL ACCESS" extends "D365 BUS FULL ACCESS"
{
    Permissions =
                  tabledata "Cost Share Buffer" = RIMD,
                  tabledata "Load Buffer" = RIMD,
                  tabledata "Manufacturing Cue" = RIMD,
                  tabledata "Manufacturing Setup" = RIMD,
                  tabledata "Prod. Order Capacity Need" = rm,
                  tabledata "Prod. Order Component" = rm,
                  tabledata "Prod. Order Line" = rm,
                  tabledata "Prod. Order Routing Line" = rm,
                  tabledata "Prod. Order Routing Personnel" = rm,
                  tabledata "Prod. Order Routing Tool" = rm,
                  tabledata "Prod. Order Rtng Qlty Meas." = rm,
                  tabledata "Production BOM Header" = r,
                  tabledata "Production BOM Line" = Rm,
                  tabledata "Production Forecast Entry" = RIMD,
                  tabledata "Production Forecast Name" = RIMD,
                  tabledata "Production Order" = rm,
                  tabledata "Routing Header" = r,
                  tabledata "Work Center" = RIM;
}