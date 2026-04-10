namespace System.Security.AccessControl;

using System.Automation;

permissionset 6006 "D365 WEBHOOK SUBSCR"
{
    Assignable = true;

    Caption = 'D365 Webhook Subscription';
    Permissions = tabledata "Workflow Webhook Sub Buffer" = RIMD,
                  tabledata "Workflow Webhook Subscription" = RIMD;
}
