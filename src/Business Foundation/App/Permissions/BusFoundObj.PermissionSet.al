namespace Microsoft.Foundation;

using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;

permissionset 1 "Bus. Found. - Obj."
{
    Access = Public;
    Assignable = true;
    Caption = 'Business Foundation - Objects';

    IncludedPermissionSets = "Audit Codes - Objects",
                            "No. Series - Objects";
}