namespace Microsoft.Finance.GeneralLedger.Review;

using System.Security.AccessControl;

permissionsetextension 22214 "D365 READ - Review G/L Entries" extends "D365 READ"
{
#pragma warning disable AA0052, PTE0018 // Accepted: The existing cross-application inclusion must remain to preserve the current permission composition.
    IncludedPermissionSets = "Review G/L Entries - Read";
#pragma warning restore AA0052, PTE0018
}
