// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 6913 "Delegate Expense Approval Run"
{
    Access = Internal;
    TableNo = "Expense Report Header";

    trigger OnRun()
    var
        ExpenseReportApprovalMgmt: Codeunit "Expense Report Approval Mgmt";
    begin
        ExpenseReportApprovalMgmt.AssignActiveAlternateApproverForExpenseReport(Rec);
    end;
}
