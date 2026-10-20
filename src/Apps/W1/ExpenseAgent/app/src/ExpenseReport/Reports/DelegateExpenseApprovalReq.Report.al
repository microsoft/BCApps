// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

report 6900 "Delegate Expense Approval Req"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Delegate Expense Approval Request';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem(ExpenseReportHeader; "Expense Report Header")
        {
            DataItemTableView = sorting("No.") where(Status = filter("Pending Approval" | "Interim Approved"));
            RequestFilterFields = "No.", "Expense User No.", "Final Approver No.", "Interim Approver No.", "Alternate Approver No.";

            trigger OnAfterGetRecord()
            var
                ExpenseReportApprovalMgmt: Codeunit "Expense Report Approval Mgmt";
            begin
                Commit();
                ExpenseReportApprovalMgmt.AssignActiveAlternateApproverForExpenseReport(ExpenseReportHeader);
            end;
        }
    }
}