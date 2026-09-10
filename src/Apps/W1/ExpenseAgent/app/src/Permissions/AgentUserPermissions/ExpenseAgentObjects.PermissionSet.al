// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

/// <summary>
/// Execute permissions for Expense Agent objects (pages, tables, codeunits).
/// </summary>
permissionset 6952 "Expense Agent - Objects"
{
    Access = Internal;
    Assignable = false;
    Caption = 'Expense Agent - Objects';

    Permissions =
                  page "EA Outbox Email API" = X,
                  page "Expense User Cons. API" = X,
                  page "Approver View API" = X,
                  page "Expense Capabilities API" = X,
                  page "Expense Activity Log API" = X,
                  page "Expense Agent Access Ctrl API" = X,
                  page "Expense Agent Setup API" = X,
                  page "Expense Approval Setup API" = X,
                  page "Expense Attachments API" = X,
                  page "Expense Categories API" = X,
                  page "Expense Groups API" = X,
                  page "Expense Itemizations API" = X,
                  page "Expense Locations API" = X,
                  page "Expense Participants API" = X,
                  page "Expense Payment Method API" = X,
                  page "Expense Per Diem API" = X,
                  page "Expense Posting Groups API" = X,
                  page "Expense Vehicle Type API" = X,
                  page "Mileage Rate Setup API" = X,
                  page "Expense Report Line Item API" = X,
                  page "Expense Report Lines API" = X,
                  page "Expense Reports API" = X,
                  page "Expense Rule Conditions API" = X,
                  page "Expense Rules API" = X,
                  page "Expense Rule Violations API" = X,
                  page "Expense Subcategories API" = X,
                  page "Expense Users API" = X,
                  page "Expense VAT Spec. API" = X,
                  page "Expenses API" = X,
                  page "Employees API" = X,
                  page "Expense Picture" = X,
                  page "Exp. Rep. Line Attachments API" = X,
                  page "Exp. Report Line Particip. API" = X,
                  page "Exp. Report Line Per Diem API" = X,
                  page "Exp. Rep. Rule Violations API" = X,
                  page "Expense Policies API" = X,
                  page "Expense Policy Evaluations API" = X,
                  page "Posted Policy Evaluations API" = X,
                  page "Posted Exp.Rep.Line VAT Spec" = X,
                  page "Posted Expense Reports API" = X,
                  page "Posted Exp. Rep. Line Att. API" = X,
                  page "Posted Exp. Rep. Line Item API" = X,
                  page "Posted Exp. Report Lines API" = X,
#if not CLEAN30
#pragma warning disable AL0432 // Object is obsoleted
                  page "Spend Requests API" = X,
                  page "Spend Request Details API" = X,
#pragma warning restore AL0432
#endif
                  page "Travel Requests API" = X,
                  page "Travel Request Details API" = X,
                  page "Travelers API" = X,
                  page "Tenant Feedback Setting API" = X,
                  page "Expense Projects API" = X,
                  page "Exp. Policies To Eval API" = X,
                  query "Expense Project Tasks Qry" = X,
#if not CLEAN29
#pragma warning disable AL0432 // Object is obsoleted
                  query "Expense Projects List" = X,
                  query "Expense User Assigned Projects" = X,
                  query "Expense User Assigned Plan Ln" = X,
#pragma warning restore AL0432
#endif
                  query "Expense Per Diem Locations" = X,
#if not CLEAN29
#pragma warning disable AL0432 // Object is obsoleted
                  page "Expense Location API" = X,
#pragma warning restore AL0432
#endif

                  table Expense = X,
                  table "Expense Approval Setup" = X,
                  table "Expense Capabilities Buffer" = X,
                  table "Expense Activity Log Entry" = X,
                  table "Expense Project Buf" = X,
                  table "Exp. Policy To Eval Buffer" = X,
#if not CLEAN29
#pragma warning disable AL0432 // Object is obsoleted
                  table "Expense Agent Consumption" = X,
#pragma warning restore AL0432
#endif
                  table "Expense Agent Env. Consumption" = X,
                  table "Expense Category" = X,
                  table "Expense Group" = X,
                  table "Expense Itemization" = X,
                  table "Expense Ledger Entry" = X,
                  table "Expense Location" = X,
                  table "Expense Vehicle Type" = X,
                  table "Mileage Rate Setup" = X,
                  table "Expense Participant" = X,
                  table "Expense Payment Method" = X,
                  table "Expense Per Diem" = X,
                  table "Expense Posting Group" = X,
                  table "Expense Report Comment Line" = X,
                  table "Expense Report Header" = X,
                  table "Expense Report Line" = X,
                  table "Expense Report Line Item" = X,
                  table "Expense Report Line Particip." = X,
                  table "Expense Report Line Per Diem" = X,
                  table "Expense Report Rule Violation" = X,
                  table "Expense Rule Condition" = X,
                  table "Expense Rule Header" = X,
                  table "Expense Rule Violation" = X,
                  table "Expense Policy" = X,
                  table "Expense Policy Evaluation" = X,
                  table "Posted Exp. Policy Evaluation" = X,
                  table "Expense Subcategory" = X,
                  table "Expense Team" = X,
                  table "Expense User" = X,
                  table "Expense VAT Specification" = X,
                  table "Expense Vendor" = X,
                  table "EA Outbox Email" = X,
                  table "Tenant Feedback Setting" = X,
                  table "Posted Exp. Rep. Line Item" = X,
                  table "Posted Exp. Rep. Line Particip" = X,
                  table "Posted Exp. Rep. Line Per Diem" = X,
                  table "Posted Expense Report Header" = X,
                  table "Posted Expense Report Line" = X,
                  table "Posted Exp. Rep. Line VAT Spec" = X,

                  codeunit "Cancel Posted Expense Report" = X,
                  codeunit "Create Expense Report" = X,
                  codeunit "Expense API Currency Helper" = X,
                  codeunit "Expense Agent Privacy Subs." = X,
                  codeunit "Expense Approval Helper" = X,
                  codeunit "Expense Attachment Mgt." = X,
                  codeunit "Expense Auto Population" = X,
                  codeunit "Expense Capabilities Provider" = X,
                  codeunit "Expense Activity Log Mgt." = X,
                  codeunit "Expense Projects Builder" = X,
                  codeunit "Exp. Policies To Eval Builder" = X,
                  codeunit "Expense Consumption Handler" = X,
                  codeunit "Expense Currency" = X,
                  codeunit "Expense Doc No Visibility" = X,
                  codeunit "Expense Doc. Att. Subscribers" = X,
                  codeunit "Expense Event Subscriber" = X,
                  codeunit "Expense Manual Release" = X,
                  codeunit "Expense Manual Reopen" = X,
                  codeunit "Expense OAuth Client" = X,
                  codeunit "Expense Per Diem Calculation" = X,
                  codeunit "Expense Report-Post" = X,
                  codeunit "Expense Preview Post Instance" = X,
                  codeunit "Expense Preview Post Mgt." = X,
                  codeunit "Expense Report" = X,
                  codeunit "Expense Report Approval Mgmt" = X,
                  codeunit "Expense Report Batch Post Mgt." = X,
                  codeunit "Expense Report Manual Release" = X,
                  codeunit "Expense Report Manual Reopen" = X,
                  codeunit "Expense Rule Validation" = X,
                  codeunit "Expense Total Caption Class" = X,
                  codeunit "Travel Request Approval" = X,
                  codeunit "Expense Vendor Matching" = X,
                  codeunit "Exp. Attach. Buffer Handler" = X,
                  codeunit "Exp. Preview Post. Subscriber" = X,
                  codeunit "Exp. Preview Posting Handler" = X,
                  codeunit "Import Expense User" = X,
                  codeunit "Release Exp. Report Document" = X,
#if not CLEAN29
#pragma warning disable AL0432 // Object is obsoleted
                  codeunit "Expense Agent MCP Config." = X,
#pragma warning restore AL0432
#endif
                  codeunit "Release Expense Document" = X;

}
