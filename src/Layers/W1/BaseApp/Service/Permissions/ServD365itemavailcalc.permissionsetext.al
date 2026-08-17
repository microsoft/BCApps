namespace System.Security.AccessControl;

using Microsoft.Service.Document;

permissionsetextension 5909 "SERV D365 ITEM AVAIL CALC" extends "D365 ITEM AVAIL CALC"
{
    Permissions =
        tabledata "Service Line" = r;
}