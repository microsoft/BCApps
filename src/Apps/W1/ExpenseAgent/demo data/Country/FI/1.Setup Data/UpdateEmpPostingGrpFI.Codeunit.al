// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.DemoData.HumanResources;

codeunit 8459 "Update Emp. Posting Grp FI"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    begin
        UpdateEmployeePostingGroup();
    end;

    local procedure UpdateEmployeePostingGroup()
    var
        CreateExpGLAccountFI: Codeunit "Create Exp. GL Account FI";
        ExpenseGLAccountNamesFI: Codeunit "Expense GL Account Names FI";
        ExpenseGLAccount: Codeunit "Create Expense G/L Account";
        ContosoExpenseAgent: Codeunit "Contoso Expense Agent";
        CreateEmployeePostingGroup: Codeunit "Create Employee Posting Group";
    begin
        ContosoExpenseAgent.SetOverwriteData(true);
        ContosoExpenseAgent.UpdateEmployeePostingGroup(CreateEmployeePostingGroup.EmployeeExpenses(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesFI.EmployeesPayableName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesFI.Otherreceivables1Name()), CreateExpGLAccountFI.CompanyPaidExpenseClearing(), CreateExpGLAccountFI.CompanyCardExpenseClearing());
        ContosoExpenseAgent.SetOverwriteData(false);
    end;
}
