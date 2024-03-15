namespace Microsoft.Foundation;

using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.AuditCodes;

permissionset 2 "Bus. Found. - Read"
{
    Access = Public;
    Assignable = true;
    Caption = 'Business Foundation - Read';

    IncludedPermissionSets = "Bus. Found. - Obj.",
                             "Audit Codes - Read",
                             "No. Series - Read";
}