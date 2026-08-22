// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

permissionset 6905 "Expense Mgmt. Admin"
{
    Assignable = true;
    Caption = 'Expense Management - Admin';

    IncludedPermissionSets = "Expense Mgmt. Edit";

    Permissions =
        tabledata "Expense Agent Access Control" = RIMD,
#if not CLEAN29
#pragma warning disable AL0432 // Object is obsoleted
        tabledata "Expense Agent Consumption" = i,
#pragma warning restore AL0432
#endif
        tabledata "Expense Agent Env. Consumption" = i,
        tabledata "Expense Category" = IMD,
        tabledata "Expense Group" = IMD,
        tabledata "Expense Location" = IMD,
        tabledata "Expense Vehicle Type" = IMD,
        tabledata "Mileage Rate Setup" = IMD,
        tabledata "Expense Agent Setup" = IMD,
        tabledata "Expense Agent Status" = IMD,
        tabledata "Expense Rule Condition" = IMD,
        tabledata "Expense Rule Header" = IMD,
        tabledata "Expense Policy" = IMD,
        tabledata "Expense Policy Evaluation" = IMD,
        tabledata "Expense Posting Group" = IMD,
        tabledata "Expense Subcategory" = IMD,
        tabledata "EA Email" = R,
        tabledata "EA Email Attachment" = R,
        tabledata "EA Scheduler Task" = R,
        tabledata "Posted Expense Report Header" = IM,
        tabledata "Posted Expense Report Line" = IM,
        tabledata "Expense Ledger Entry" = IM,
        tabledata "EA Outbox Email" = RIMD;
}