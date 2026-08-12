namespace Microsoft.API.V2;

using System.Security.AccessControl;

permissionsetextension 20766 "D365 AUTOMATION - APIV2" extends "D365 AUTOMATION"
{
    // The included permission set is what grants access to this application's own
    // API objects, so extending the platform permission set with it is intentional.
#pragma warning disable AS0112
    IncludedPermissionSets = "D365 Automation APIV2";
#pragma warning restore AS0112
}
