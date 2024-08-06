namespace Microsoft.Foundation;

using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.AuditCodes;

permissionset 5 "Bus. Found. - Admin"
{
    Access = Public;
    Assignable = true;
    Caption = 'Business Foundation - Admin';

    IncludedPermissionSets = "Bus. Found. - Edit",
                             "Audit Codes - Admin",
                             "No. Series - Admin";
}