namespace Microsoft.API.V2;

using System.Security.AccessControl;

permissionsetextension 20766 "D365 AUTOMATION - APIV2" extends "D365 AUTOMATION"
{
#pragma warning disable AA0052, PTE0018 // Accepted: The existing cross-application inclusion must remain to preserve the current permission composition.
    IncludedPermissionSets = "D365 Automation APIV2";
#pragma warning restore AA0052, PTE0018
}
