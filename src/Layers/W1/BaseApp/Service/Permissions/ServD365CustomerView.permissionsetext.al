namespace System.Security.AccessControl;

using Microsoft.Service.Setup;

permissionsetextension 5908 "SERV D365 CUSTOMER VIEW" extends "D365 CUSTOMER, VIEW"
{
    Permissions =
                  tabledata "Service Zone" = R;

}