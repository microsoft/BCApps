// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

permissionset 6907 "Expense Mgmt. Read"
{
    Caption = 'Expense Management - Read';
    Access = Public;
    Assignable = true;

    IncludedPermissionSets = "Expense Management - Objects";

    Permissions =
        tabledata "Expense Vendor" = R,
        tabledata "Expense Report Line Item" = R,
        tabledata Expense = R,
        tabledata "Expense Category" = R,
        tabledata "Expense Report Comment Line" = R,
        tabledata "Expense User" = R,
        tabledata "Expense Group" = R,
        tabledata "Expense Itemization" = R,
        tabledata "Expense Location" = R,
        tabledata "Expense Vehicle Type" = R,
        tabledata "Mileage Rate Setup" = R,
        tabledata "Expense Agent Setup" = R,
        tabledata "Expense Agent Status" = R,
#if not CLEAN29
#pragma warning disable AL0432 // Object is obsoleted
        tabledata "Expense Agent Consumption" = R,
#pragma warning restore AL0432
#endif
        tabledata "Expense Agent Env. Consumption" = R,
        tabledata "Expense Participant" = R,
        tabledata "Expense Rule Condition" = R,
        tabledata "Expense Rule Header" = R,
        tabledata "Expense Payment Method" = R,
        tabledata "Expense Posting Group" = R,
        tabledata "Expense Report Header" = R,
        tabledata "Expense Report Line" = R,
        tabledata "Expense Report Line Particip." = R,
        tabledata "Expense Report Line Per Diem" = R,
        tabledata "Expense Subcategory" = R,
        tabledata "Expense Per Diem" = R,
        tabledata "Posted Expense Report Header" = R,
        tabledata "Posted Expense Report Line" = R,
        tabledata "Posted Exp. Rep. Line Item" = R,
        tabledata "Posted Exp. Rep. Line Per Diem" = R,
        tabledata "Expense Ledger Entry" = R,
        tabledata "Expense Team" = R,
        tabledata "Expense Approval Setup" = R,
        tabledata "Expense Rule Violation" = R,
        tabledata "Expense Policy" = R,
        tabledata "Expense Policy Evaluation" = R,
        tabledata "Posted Exp. Policy Evaluation" = R,
        tabledata "Expense Report Rule Violation" = R,
        tabledata "Posted Exp. Rep. Line Particip" = R,
        tabledata "Tenant Feedback Setting" = R,
        tabledata "EA Outbox Email" = R,
        tabledata "EA KPI" = R,
        tabledata "EA KPI Entry" = R,
        tabledata Traveler = R,
        tabledata "Expense VAT Specification" = R,
        tabledata "Expense Report Line VAT Spec." = R,
        tabledata "Expense Activity Log Entry" = R,
        tabledata "Posted Exp. Rep. Line VAT Spec" = R;
}