namespace System.Security.AccessControl;

using Microsoft.Manufacturing.Document;

permissionsetextension 99000755 "MFG D365 ITEM AVAIL CALC" extends "D365 ITEM AVAIL CALC"
{
    Permissions =
        tabledata "Prod. Order Component" = r,
        tabledata "Prod. Order Line" = r;
}
