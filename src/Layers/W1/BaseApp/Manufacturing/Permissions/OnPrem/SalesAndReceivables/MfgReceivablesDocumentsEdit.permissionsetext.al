namespace System.Security.AccessControl;

using Microsoft.Manufacturing.Document;

permissionsetextension 99000778 "Mfg Receivables Documents Edit" extends "Recievables Documents - Edit"
{
    Permissions =
                  tabledata "Prod. Order Component" = Rm,
                  tabledata "Prod. Order Line" = Rm;
}