namespace Microsoft.API.V1;

using System.Security.AccessControl;

permissionsetextension 5503 "D365 AUTOMATION - APIV1" extends "D365 AUTOMATION"
{
    // The included permission set is what grants access to this application's own
    // API objects, so extending the platform permission set with it is intentional.
#pragma warning disable AS0112
    IncludedPermissionSets = "D365 Automation APIV1";
#pragma warning restore AS0112
}
