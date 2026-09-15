namespace Microsoft.Integration.MDM;

using System.Security.AccessControl;

permissionsetextension 7239 "INTELLIGENT CLOUD - Master Data Mgt." extends "INTELLIGENT CLOUD"
{
#pragma warning disable AA0052, PTE0018 // Accepted: The existing cross-application inclusion must remain to preserve the current permission composition.
    IncludedPermissionSets = "Master Data Mgt. - Read";
#pragma warning restore AA0052, PTE0018
}
