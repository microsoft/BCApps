namespace System.Security.AccessControl;

using Microsoft.Manufacturing.Document;

permissionsetextension 99000779 "Mfg. Receivables Documents Post" extends "Recievables Documents - Post"
{
    Permissions =
                  tabledata "Prod. Order Component" = Rm,
                  tabledata "Prod. Order Line" = Rm;
}