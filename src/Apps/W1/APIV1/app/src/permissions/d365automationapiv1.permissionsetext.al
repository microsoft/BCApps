namespace Microsoft.API.V1;

using System.Security.AccessControl;

permissionsetextension 5503 "D365 AUTOMATION - APIV1" extends "D365 AUTOMATION"
{
#pragma warning disable AA0052, PTE0018 // Accepted: The existing cross-application inclusion must remain to preserve the current permission composition.
    IncludedPermissionSets = "D365 Automation APIV1";
#pragma warning restore AA0052, PTE0018
}
