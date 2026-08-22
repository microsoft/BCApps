// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.DemoData.HumanResources;
using Microsoft.HumanResources.Employee;

codeunit 8470 "Update Emp. Posting Grp CZ"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    begin
        UpdateEmployeePostingGroup();
    end;

    local procedure UpdateEmployeePostingGroup()
    var
        CreateExpGLAccountCZ: Codeunit "Create Exp. GL Account CZ";
        ExpenseGLAccountNamesCZ: Codeunit "Expense GL Account Names CZ";
        ExpenseGLAccount: Codeunit "Create Expense G/L Account";
        ContosoExpenseAgent: Codeunit "Contoso Expense Agent";
        CreateEmployeePostingGroup: Codeunit "Create Employee Posting Group";
    begin
        ContosoExpenseAgent.SetOverwriteData(true);
        ContosoExpenseAgent.UpdateEmployeePostingGroup(CreateEmployeePostingGroup.EmployeeExpenses(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesCZ.PayablesToEmployeesName()), CreateExpGLAccountCZ.EmployeeExpenseAdvances(), CreateExpGLAccountCZ.CompanyCardExpensesPayable(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesCZ.BankAccountKBName()));
        ContosoExpenseAgent.SetOverwriteData(false);

        UpdatePayablesAccountInEmployeePostingGroup(CreateEmployeePostingGroup.EmployeeExpenses(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesCZ.PayablesToEmployeesName()));
    end;

    local procedure UpdatePayablesAccountInEmployeePostingGroup(EmployeePostingGroupCode: Code[20]; PayablesAccount: Code[20])
    var
        EmployeePostingGroup: Record "Employee Posting Group";
    begin
        if not EmployeePostingGroup.Get(EmployeePostingGroupCode) then
            exit;

        if EmployeePostingGroup."Payables Account" <> '' then
            exit;

        EmployeePostingGroup.Validate("Payables Account", PayablesAccount);
        EmployeePostingGroup.Modify(true);
    end;
}
