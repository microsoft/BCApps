namespace System.Security.AccessControl;

using Microsoft.Manufacturing.Document;

permissionsetextension 99000775 "Mfg. Payables Documents Edit" extends "Payables Documents - Edit"
{
    Permissions =
                  tabledata "Prod. Order Component" = Rm,
                  tabledata "Prod. Order Line" = Rm;
}