namespace System.Security.AccessControl;

using Microsoft.Manufacturing.ProductionBOM;

permissionsetextension 99000756 "MFG D365 ITEM, EDIT" extends "D365 ITEM, EDIT"
{
    Permissions =
                  tabledata "Production BOM Line" = R;
}