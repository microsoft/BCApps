namespace System.Security.AccessControl;

using Microsoft.Manufacturing.Document;

permissionsetextension 99000776 "Mfg. Payables Documents Post" extends "Payables Documents - Post"
{
    Permissions =
                  tabledata "Prod. Order Component" = Rm,
                  tabledata "Prod. Order Line" = Rm;
}