namespace Microsoft.SubscriptionBilling;

using System.Security.AccessControl;

permissionsetextension 8002 "Sub. Billing D365 S. Doc Edit" extends "D365 SALES DOC, EDIT"
{
    IncludedPermissionSets = "Sub. Billing User";
}