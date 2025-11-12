namespace System.Security.AccessControl;

using Microsoft.Manufacturing.Document;

permissionsetextension 99000774 "Mfg. Item Journals - Post" extends "Item Journals - Post"
{
    Permissions =
                  tabledata "Prod. Order Component" = Rm,
                  tabledata "Prod. Order Line" = Rm;
}