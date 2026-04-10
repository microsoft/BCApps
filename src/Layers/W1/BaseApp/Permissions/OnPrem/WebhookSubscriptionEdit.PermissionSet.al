namespace System.Security.AccessControl;

using System.Automation;

permissionset 9298 "Webhook Subscription - Edit"
{
    Access = Public;
    Assignable = false;
    Caption = 'Workflow Webhook Subscriptions';

    Permissions = tabledata "Workflow Webhook Subscription" = RIMD;
}
