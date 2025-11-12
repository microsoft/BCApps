namespace System.Security.AccessControl;

using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;

permissionsetextension 99000772 "Mfg. Inventory - View" extends "Inventory - View"
{
    Permissions =
                  tabledata "Prod. Order Component" = Rm,
                  tabledata "Prod. Order Line" = RIMD,
                  tabledata "Production BOM Header" = R,
                  tabledata "Routing Header" = R;
}