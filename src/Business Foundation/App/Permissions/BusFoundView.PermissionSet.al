namespace Microsoft.Foundation;

using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.AuditCodes;

permissionset 3 "Bus. Found. - View"
{
    Access = Public;
    Assignable = true;
    Caption = 'Business Foundation - View';

    IncludedPermissionSets = "Bus. Found. - Read",
                             "Audit Codes - View",
                             "No. Series - View";
}