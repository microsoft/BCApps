// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.DemoData.Finance;
using Microsoft.DemoData.HumanResources;

codeunit 10922 "Update Exp. Emp Posting Grp ES"
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
        ExpenseGLAccountES: Codeunit "Create Expense G/L Account ES";
        CreateESGLAccounts: Codeunit "Create ES GL Accounts";
        ContosoExpenseAgent: Codeunit "Contoso Expense Agent";
        CreateEmployeePostingGroup: Codeunit "Create Employee Posting Group";
    begin
        ContosoExpenseAgent.SetOverwriteData(true);
        ContosoExpenseAgent.UpdateEmployeePostingGroup(CreateEmployeePostingGroup.EmployeeExpenses(), ExpenseGLAccount.FindGLAccountByName(CreateESGLAccounts.RemunerationAdvancesName()), ExpenseGLAccountES.ExpensesPrepayments(), ExpenseGLAccount.FindGLAccountByName(CreateESGLAccounts.BanksEuroName()), ExpenseGLAccountES.CompanyCreditCardsClearingAccount());
        ContosoExpenseAgent.SetOverwriteData(false);
    end;
}