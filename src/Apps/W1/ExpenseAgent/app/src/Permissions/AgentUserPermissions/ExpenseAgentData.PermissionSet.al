// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

/// <summary>
/// All table data permissions for Expense Agent objects.
/// </summary>
permissionset 6953 "Expense Agent - Data"
{
    Access = Internal;
    Assignable = false;
    Caption = 'Expense Agent - Data';

    Permissions =
                  tabledata "Expense" = RIMD,
                  tabledata "Expense Report Comment Line" = RD,
                  tabledata "Expense Itemization" = RIMD,
                  tabledata "Expense Rule Violation" = RID,
                  tabledata "Expense Participant" = RIMD,
                  tabledata "Expense Per Diem" = RIMD,
                  tabledata "Expense Report Header" = RIMD,
                  tabledata "Expense Report Line" = RIMD,
                  tabledata "Expense Report Line Particip." = RIMD,
                  tabledata "Expense Report Line Per Diem" = RIMD,
                  tabledata "Expense Report Rule Violation" = RID,
                  tabledata "Expense Report Line Item" = RIMD,
                  tabledata "Expense VAT Specification" = RIMD,
                  tabledata "Expense Vendor" = RIM,
                  tabledata "Expense Ledger Entry" = RiM,
                  tabledata "Expense Payment Method" = R,
                  tabledata "Posted Expense Report Header" = Rim,
                  tabledata "Posted Expense Report Line" = Rim,
                  tabledata "Posted Exp. Rep. Line Particip" = RiM,
                  tabledata "Posted Exp. Rep. Line Per Diem" = Rim,
                  tabledata "Posted Exp. Rep. Line Item" = Rim,
                  tabledata "Posted Exp. Rep. Line VAT Spec" = Rim,
                  tabledata "Expense Category" = R,
                  tabledata "Expense User" = R,
                  tabledata "Expense Group" = R,
                  tabledata "Expense Location" = R,
                  tabledata "Expense Vehicle Type" = R,
                  tabledata "Mileage Rate Setup" = R,
                  tabledata "Expense Rule Condition" = R,
                  tabledata "Expense Rule Header" = R,
                  tabledata "Expense Policy" = R,
                  tabledata "Expense Policy Evaluation" = RIMD,
                  tabledata "Posted Exp. Policy Evaluation" = Rid,
                  tabledata "Expense Posting Group" = r,
                  tabledata "Expense Subcategory" = R,
                  tabledata "Expense Agent Access Control" = R,
                  tabledata "Expense Agent Setup" = R,
                  tabledata "Expense Team" = R,
                  tabledata "Expense Approval Setup" = R,
                  tabledata "EA Scheduler Task" = R,
                  tabledata "EA Email" = R,
                  tabledata "EA Email Attachment" = R,
#if not CLEAN29
#pragma warning disable AL0432 // Object is obsoleted
                  tabledata "Expense Agent Consumption" = Ri,
#pragma warning restore AL0432
#endif
                  tabledata "Expense Agent Env. Consumption" = Ri,
                  tabledata "Tenant Feedback Setting" = R,
                  tabledata "EA Outbox Email" = RIM,
                  tabledata "Expense Activity Log Entry" = Rimd;
}
