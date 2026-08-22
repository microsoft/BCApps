// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.DemoData.Finance;
using Microsoft.DemoData.HumanResources;

codeunit 8327 "Update Emp. Posting Grp AT"
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
        HRGLAccount: Codeunit "Create HR GL Account";
        ExpenseGLAccount: Codeunit "Create Expense G/L Account";
        CreateExpGLAccountAT: Codeunit "Create Exp. GL Account AT";
        ExpenseGLAccountNamesAT: Codeunit "Expense GL Account Names AT";
        ContosoExpenseAgent: Codeunit "Contoso Expense Agent";
        CreateEmployeePostingGroup: Codeunit "Create Employee Posting Group";
    begin
        ContosoExpenseAgent.SetOverwriteData(true);
        ContosoExpenseAgent.UpdateEmployeePostingGroup(CreateEmployeePostingGroup.EmployeeExpenses(), ExpenseGLAccount.FindGLAccountByName(HRGLAccount.EmployeesPayableName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesAT.SettlementAccountCashBankName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.BankLcyName()), CreateExpGLAccountAT.CompanyCreditCardsClearingAccount());
        ContosoExpenseAgent.SetOverwriteData(false);
    end;
}
