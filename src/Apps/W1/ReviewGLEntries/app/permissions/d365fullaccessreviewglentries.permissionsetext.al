namespace Microsoft.Finance.GeneralLedger.Review;

using System.Security.AccessControl;

permissionsetextension 22215 "D365 FULL ACCESS - Review G/L Entries" extends "D365 FULL ACCESS"
{
#pragma warning disable AA0052, PTE0018 // Accepted: The existing cross-application inclusion must remain to preserve the current permission composition.
    IncludedPermissionSets = "Review G/L Entries - View";
#pragma warning restore AA0052, PTE0018
}
