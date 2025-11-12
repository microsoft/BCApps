namespace Microsoft.Foundation;

using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;

permissionset 3 "Bus. Found. - View"
{
    Access = Public;
    Assignable = true;
    Caption = 'Business Foundation - View';

    IncludedPermissionSets = "Bus. Found. - Read",
                             "Audit Codes - View",
                             "No. Series - View";
}