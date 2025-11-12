namespace System.Security.AccessControl;

using System.Environment.Configuration;
using System.Automation;

permissionset 7111 "Document Approvals - Edit"
{
    Access = Public;
    Assignable = false;
    Caption = 'Document Approval';

    Permissions = tabledata "Approval Comment Line" = RIMD,
                  tabledata "Approval Entry" = RIMD,
                  tabledata "Dynamic Request Page Entity" = R,
                  tabledata "Dynamic Request Page Field" = R,
                  tabledata "Notification Entry" = Rimd,
                  tabledata "Posted Approval Comment Line" = RI,
                  tabledata "Posted Approval Entry" = RI,
                  tabledata "Restricted Record" = Rimd,
                  tabledata "Sent Notification Entry" = Rimd,
                  tabledata "Workflow - Record Change" = Rimd,
                  tabledata "Workflow - Table Relation" = R,
                  tabledata Workflow = R,
                  tabledata "Workflow Buffer" = RIMD,
                  tabledata "Workflow Category" = R,
                  tabledata "Workflow Event" = R,
                  tabledata "Workflow Event Queue" = Rimd,
                  tabledata "Workflow Record Change Archive" = Rimd,
                  tabledata "Workflow Response" = R,
                  tabledata "Workflow Rule" = Rimd,
                  tabledata "Workflow Step" = R,
                  tabledata "Workflow Step Argument" = Rimd,
                  tabledata "Workflow Step Argument Archive" = Rimd,
                  tabledata "Workflow Step Instance" = Rimd,
                  tabledata "Workflow Step Instance Archive" = Rimd,
                  tabledata "Workflow Table Relation Value" = Rimd,
                  tabledata "Workflow User Group" = R,
                  tabledata "Workflow User Group Member" = R,
                  tabledata "Workflow Webhook Entry" = RIMD,
                  tabledata "Workflow Webhook Notification" = RIMD,
                  tabledata "Workflow Webhook Sub Buffer" = RIMD,
                  tabledata "Workflow Webhook Subscription" = RIMD,
                  tabledata "Workflows Entries Buffer" = RIMD;
}
