namespace System.Security.AccessControl;

using Microsoft.Foundation.Address;
using System.Integration;

permissionset 2613 "Web Services - Admin"
{
    Access = Public;
    Assignable = false;
    Caption = 'Web Services Setup';

    IncludedPermissionSets = "Web Service Management - Admin";

    Permissions = tabledata "Tenant Web Service" = RIMD,
                  tabledata "Web Service" = RIMD,
                  tabledata "Postcode Service Config" = RIMD;
}
