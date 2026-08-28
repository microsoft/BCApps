// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.DemoData.Finance;
using Microsoft.DemoData.HumanResources;

codeunit 8248 "CA Upd. Emp. Posting Grp"
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
        ContosoExpenseAgent: Codeunit "Contoso Expense Agent";
        CreateEmployeePostingGroup: Codeunit "Create Employee Posting Group";
    begin
        ContosoExpenseAgent.SetOverwriteData(true);
        ContosoExpenseAgent.UpdateEmployeePostingGroup(CreateEmployeePostingGroup.EmployeeExpenses(), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.VacationCompensationPayableName()), ExpenseGLAccount.EmployeePrepaymentsExpensesAccount(), ExpenseGLAccount.FindGLAccountByName(BankCheckingLbl), ExpenseGLAccount.CompanyCreditCardsAccount());
        ContosoExpenseAgent.SetOverwriteData(false);
    end;

    var
        BankCheckingLbl: Label 'Bank, Checking', MaxLength = 100;
}
