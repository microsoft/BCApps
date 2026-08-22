// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.DemoData.HumanResources;

codeunit 8279 "ES Upd. Emp. Posting Grp"
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
        ESExpGLAccount: Codeunit "ES Exp. GL Account";
        ESGLAccountNames: Codeunit "ES GL Account Names";
        ContosoExpenseAgent: Codeunit "Contoso Expense Agent";
        CreateEmployeePostingGroup: Codeunit "Create Employee Posting Group";
    begin
        ContosoExpenseAgent.SetOverwriteData(true);
        ContosoExpenseAgent.UpdateEmployeePostingGroup(CreateEmployeePostingGroup.EmployeeExpenses(), ExpenseGLAccount.FindGLAccountByName(ESGLAccountNames.RemunerationAdvancesName()), ESExpGLAccount.ExpensesPrepayments(), ExpenseGLAccount.FindGLAccountByName(ESGLAccountNames.BanksEuroName()), ESExpGLAccount.CompanyCreditCardsClearingAccount());
        ContosoExpenseAgent.SetOverwriteData(false);
    end;
}
