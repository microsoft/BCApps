namespace Microsoft.Integration.MDM;

using System.Security.AccessControl;

permissionsetextension 7236 "D365 BUS PREMIUM - Master Data Mgt." extends "D365 BUS PREMIUM"
{
#pragma warning disable AA0052, PTE0018 // Accepted: The existing cross-application inclusion must remain to preserve the current permission composition.
    IncludedPermissionSets = "Master Data Mgt. - View";
#pragma warning restore AA0052, PTE0018
}
