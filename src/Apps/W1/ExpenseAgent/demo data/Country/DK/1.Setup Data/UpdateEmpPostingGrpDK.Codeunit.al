// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;
using Microsoft.DemoData.HumanResources;

codeunit 8292 "Update Emp. Posting Grp DK"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    begin
        UpdateEmployeePostingGroup();
    end;

    local procedure UpdateEmployeePostingGroup()
    var
        ExpenseGLAccount: Codeunit "Create Expense G/L Account";
        CreateExpGLAccountDK: Codeunit "Create Exp. GL Account DK";
        ExpenseGLAccountNamesDK: Codeunit "Expense GL Account Names DK";
        ContosoExpenseAgent: Codeunit "Contoso Expense Agent";
        CreateEmployeePostingGroup: Codeunit "Create Employee Posting Group";
    begin
        ContosoExpenseAgent.SetOverwriteData(true);
        ContosoExpenseAgent.UpdateEmployeePostingGroup(CreateEmployeePostingGroup.EmployeeExpenses(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesDK.AccountsPayablePostingName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesDK.PrepaymentsAccruedCostsName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesDK.BankName()), CreateExpGLAccountDK.CompanyCreditCards());
        ContosoExpenseAgent.SetOverwriteData(false);
    end;
}
