namespace Microsoft.Foundation;

using Microsoft.Foundation.NoSeries;

permissionset 2 "Bus. Found. - Read"
{
    Access = Public;
    Assignable = true;
    Caption = 'Business Foundation - Read';

    IncludedPermissionSets = "Bus. Found. - Obj.",
                             "No. Series - Read";
}