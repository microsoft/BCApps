namespace System.Security.AccessControl;

using System.Environment.Configuration;
using System.Automation;
using System.Security.User;
using Microsoft.CRM.Team;
using Microsoft.Foundation.Task;

permissionset 8881 "Document Approvals - Admin"
{
    Access = Public;
    Assignable = false;
    Caption = 'Document Approval Setup';

    Permissions = tabledata "Dynamic Request Page Entity" = RIMD,
                  tabledata "Dynamic Request Page Field" = RIMD,
                  tabledata "Notification Schedule" = RIMD,
                  tabledata "Notification Setup" = RIMD,
                  tabledata "Overdue Approval Entry" = RIMD,
                  tabledata "Salesperson/Purchaser" = R,
                  tabledata "User Setup" = RIMD,
                  tabledata "User Task Group" = RIMD,
                  tabledata "User Task Group Member" = RIMD,
                  tabledata "WF Event/Response Combination" = RIMD,
                  tabledata "Workflow - Record Change" = RIMD,
                  tabledata "Workflow - Table Relation" = RIMD,
                  tabledata Workflow = RIMD,
                  tabledata "Workflow Category" = RIMD,
                  tabledata "Workflow Event" = RIMD,
                  tabledata "Workflow Event Queue" = RIMD,
                  tabledata "Workflow Record Change Archive" = RIMD,
                  tabledata "Workflow Response" = RIMD,
                  tabledata "Workflow Rule" = RIMD,
                  tabledata "Workflow Step" = RIMD,
                  tabledata "Workflow Step Argument" = RIMD,
                  tabledata "Workflow Step Argument Archive" = RIMD,
                  tabledata "Workflow Step Buffer" = RIMD,
                  tabledata "Workflow Step Instance" = Rimd,
                  tabledata "Workflow Step Instance Archive" = RIMD,
                  tabledata "Workflow Table Relation Value" = Rimd,
                  tabledata "Workflow User Group" = RIMD,
                  tabledata "Workflow User Group Member" = RIMD;
}
