namespace System.Security.AccessControl;

using Microsoft.Manufacturing.Document;

permissionsetextension 99000773 "Mfg. Item Journals - Edit" extends "Item Journals - Edit"
{
    Permissions =
                  tabledata "Prod. Order Component" = Rm,
                  tabledata "Prod. Order Line" = Rm;
}