// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.DemoData.HumanResources;

codeunit 8315 "Update Emp. Posting Grp DE"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    begin
        UpdateEmployeePostingGroup();
    end;

    local procedure UpdateEmployeePostingGroup()
    var
        HRGLAccount: Codeunit "Create HR GL Account";
        ExpenseGLAccountNamesDE: Codeunit "Expense GL Account Names DE";
        ExpenseGLAccount: Codeunit "Create Expense G/L Account";
        CreateExpGLAccountDE: Codeunit "Create Exp. GL Account DE";
        ContosoExpenseAgent: Codeunit "Contoso Expense Agent";
        CreateEmployeePostingGroup: Codeunit "Create Employee Posting Group";
    begin
        ContosoExpenseAgent.SetOverwriteData(true);
        ContosoExpenseAgent.UpdateEmployeePostingGroup(CreateEmployeePostingGroup.EmployeeExpenses(), ExpenseGLAccount.FindGLAccountByName(HRGLAccount.EmployeesPayableName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesDE.AssetsintheformofprepaidexpensesName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesDE.BusinessaccountOperatingDomesticName()), CreateExpGLAccountDE.CompanyCreditCardsClearingAccount());
        ContosoExpenseAgent.SetOverwriteData(false);
    end;
}
