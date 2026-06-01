namespace Microsoft.Foundation;

using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;

permissionset 5 "Bus. Found. - Admin"
{
    Access = Public;
    Assignable = true;
    Caption = 'Business Foundation - Admin';

    IncludedPermissionSets = "Bus. Found. - Edit",
                             "Audit Codes - Admin",
                             "No. Series - Admin";
}