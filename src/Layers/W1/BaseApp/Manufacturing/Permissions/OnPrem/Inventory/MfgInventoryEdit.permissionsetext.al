namespace System.Security.AccessControl;

using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Forecast;
using Microsoft.Manufacturing.Routing;

permissionsetextension 99000771 "Mfg. Inventory - Edit" extends "Inventory - Edit"
{
    Permissions =
                  tabledata "Prod. Order Component" = Rm,
                  tabledata "Prod. Order Line" = Rm,
                  tabledata "Production BOM Header" = R,
                  tabledata "Production BOM Line" = R,
                  tabledata "Production Forecast Entry" = rm,
                  tabledata "Production Order" = rm,
                  tabledata "Routing Header" = R;
}