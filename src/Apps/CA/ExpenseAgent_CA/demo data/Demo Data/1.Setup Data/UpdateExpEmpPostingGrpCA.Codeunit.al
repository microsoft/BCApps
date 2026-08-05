// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.DemoData.Finance;
using Microsoft.DemoData.HumanResources;

codeunit 27102 "Update Exp. Emp Posting Grp CA"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    begin
        UpdateEmployeePostingGroup();
    end;

    local procedure UpdateEmployeePostingGroup()
    var
        CreateGLAccount: Codeunit "Create G/L Account";
        ExpenseGLAccount: Codeunit "Create Expense G/L Account";
        CreateCAGLAccounts: Codeunit "Create CA GL Accounts";
        ContosoExpenseAgent: Codeunit "Contoso Expense Agent";
        CreateEmployeePostingGroup: Codeunit "Create Employee Posting Group";
    begin
        ContosoExpenseAgent.SetOverwriteData(true);
        ContosoExpenseAgent.UpdateEmployeePostingGroup(CreateEmployeePostingGroup.EmployeeExpenses(), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.VacationCompensationPayableName()), ExpenseGLAccount.EmployeePrepaymentsExpensesAccount(), ExpenseGLAccount.FindGLAccountByName(CreateCAGLAccounts.BankCheckingName()), ExpenseGLAccount.CompanyCreditCardsAccount());
        ContosoExpenseAgent.SetOverwriteData(false);
    end;
}