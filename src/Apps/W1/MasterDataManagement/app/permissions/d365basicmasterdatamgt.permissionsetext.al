namespace Microsoft.Integration.MDM;

using System.Security.AccessControl;

permissionsetextension 7233 "D365 BASIC - Master Data Mgt." extends "D365 BASIC"
{
#pragma warning disable AA0052, PTE0018 // Accepted: The existing cross-application inclusion must remain to preserve the current permission composition.
    IncludedPermissionSets = "Master Data Mgt. - Read";
#pragma warning restore AA0052, PTE0018
}
