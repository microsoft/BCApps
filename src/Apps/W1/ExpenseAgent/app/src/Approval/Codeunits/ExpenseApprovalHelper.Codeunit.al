// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 6909 "Expense Approval Helper"
{
    Access = Internal;

    procedure OpenApprovalSetupPage(ExpenseUser: Record "Expense User")
    var
        ApprovalExpenseUser: Record "Expense Approval Setup";
    begin
        ExpenseUser.TestField("No.");

        if not ApprovalExpenseUser.Get(ExpenseUser."No.") then
            CreateApprovalSetupForExpenseUser(ExpenseUser);

        ApprovalExpenseUser.SetRange("Expense User No.", ExpenseUser."No.");

        Commit();
        Page.RunModal(Page::"Expense Approval Setup", ApprovalExpenseUser);
    end;

    local procedure CreateApprovalSetupForExpenseUser(ExpenseUser: Record "Expense User")
    var
        ApprovalExpenseUser: Record "Expense Approval Setup";
    begin
        ApprovalExpenseUser.Init();
        ApprovalExpenseUser.Validate("Expense User No.", ExpenseUser."No.");
        ApprovalExpenseUser.Insert(true);
    end;
}