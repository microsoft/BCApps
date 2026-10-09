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
            DataItemTableView = sorting("No.") where(Status = const("Pending Approval"));
            RequestFilterFields = "No.", "Expense User No.", "Final Approver No.", "Interim Approver No.", "Alternate Approver No.";

            trigger OnAfterGetRecord()
            begin
                // Commit so a failing report rolls back alone and the remaining reports still run.
                Commit();
                if not Codeunit.Run(Codeunit::"Delegate Expense Approval Run", ExpenseReportHeader) then
                    ClearLastError();
            end;
        }
    }
}