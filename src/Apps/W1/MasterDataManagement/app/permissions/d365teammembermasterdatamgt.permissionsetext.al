namespace Microsoft.Integration.MDM;

using System.Security.AccessControl;

permissionsetextension 7240 "D365 TEAM MEMBER - Master Data Mgt." extends "D365 TEAM MEMBER"
{
#pragma warning disable AA0052, PTE0018 // Accepted: The existing cross-application inclusion must remain to preserve the current permission composition.
    IncludedPermissionSets = "Master Data Mgt. - Read";
#pragma warning restore AA0052, PTE0018
}
