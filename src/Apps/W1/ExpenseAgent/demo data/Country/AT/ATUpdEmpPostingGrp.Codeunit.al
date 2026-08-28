// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.DemoData.Finance;
using Microsoft.DemoData.HumanResources;

codeunit 8327 "AT Upd. Emp. Posting Grp"
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
        ATExpGLAccount: Codeunit "AT Exp. GL Account";
        ATGLAccountNames: Codeunit "AT GL Account Names";
        ContosoExpenseAgent: Codeunit "Contoso Expense Agent";
        CreateEmployeePostingGroup: Codeunit "Create Employee Posting Group";
    begin
        ContosoExpenseAgent.SetOverwriteData(true);
        ContosoExpenseAgent.UpdateEmployeePostingGroup(CreateEmployeePostingGroup.EmployeeExpenses(), ExpenseGLAccount.FindGLAccountByName(HRGLAccount.EmployeesPayableName()), ExpenseGLAccount.FindGLAccountByName(ATGLAccountNames.SettlementAccountCashBankName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.BankLcyName()), ATExpGLAccount.CompanyCreditCardsClearingAccount());
        ContosoExpenseAgent.SetOverwriteData(false);
    end;
}
