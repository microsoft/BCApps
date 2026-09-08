// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

permissionset 6906 "Expense Mgmt. Edit"
{
    Assignable = true;
    Caption = 'Expense Management - Edit';

    IncludedPermissionSets = "Expense Mgmt. Read";

    Permissions =
        tabledata Expense = IMD,
        tabledata "Expense Vehicle Type" = IMD,
        tabledata "Mileage Rate Setup" = IMD,
        tabledata "Expense User" = IMD,
        tabledata "Expense Report Comment Line" = IMD,
        tabledata "Expense Itemization" = IMD,
        tabledata "Expense Participant" = IMD,
        tabledata "Expense Report Header" = IMD,
        tabledata "Expense Report Line" = IMD,
        tabledata "Expense Report Line Item" = IMD,
        tabledata "Expense Report Line Particip." = IMD,
        tabledata "Expense Report Line Per Diem" = IMD,
        tabledata "Expense Per Diem" = IMD,
        tabledata "Expense Activity Log Entry" = imd,
        tabledata "Expense Team" = IMD,
        tabledata "Expense Approval Setup" = IMD,
        tabledata "Posted Expense Report Header" = im,
        tabledata "Posted Expense Report Line" = im,
        tabledata "Posted Exp. Rep. Line Item" = im,
        tabledata "Posted Exp. Rep. Line Per Diem" = im,
        tabledata "Posted Exp. Rep. Line Particip" = im,
        tabledata "Posted Exp. Rep. Line VAT Spec" = im,
        tabledata "Expense Ledger Entry" = im,
        tabledata "Expense Payment Method" = IMD,
        tabledata "Expense Rule Violation" = IMD,
        tabledata "Expense Policy Evaluation" = imd,
        tabledata "Posted Exp. Policy Evaluation" = id,
        tabledata "Expense Report Rule Violation" = IMD,
        tabledata "Tenant Feedback Setting" = IMD,
        tabledata "EA KPI" = IMD,
        tabledata "EA KPI Entry" = IMD,
        tabledata Traveler = IMD,
        tabledata "Expense VAT Specification" = IMD,
        tabledata "Expense Report Line VAT Spec." = IMD,
        tabledata "Expense Vendor" = RIMD;
}