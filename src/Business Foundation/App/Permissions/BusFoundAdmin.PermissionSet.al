namespace Microsoft.Foundation;

using Microsoft.Foundation.NoSeries;

permissionset 5 "Bus. Found. - Admin"
{
    Access = Public;
    Assignable = true;
    Caption = 'Business Foundation - Admin';

    IncludedPermissionSets = "Bus. Found. - Edit",
                             "No. Series - Admin";
}