namespace Microsoft.Foundation;

using Microsoft.Foundation.NoSeries;

permissionset 3 "Bus. Found. - View"
{
    Access = Public;
    Assignable = true;

    IncludedPermissionSets = "Bus. Found. - Read",
                             "No. Series - View";
}