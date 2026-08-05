// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.DemoData.Finance;
using Microsoft.DemoData.HumanResources;

codeunit 11193 "Update Exp. Emp Posting Grp AT"
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
        ExpenseGLAccountAT: Codeunit "Create Expense G/L Account AT";
        CreateATGLAccount: Codeunit "Create AT GL Account";
        ContosoExpenseAgent: Codeunit "Contoso Expense Agent";
        CreateEmployeePostingGroup: Codeunit "Create Employee Posting Group";
    begin
        ContosoExpenseAgent.SetOverwriteData(true);
        ContosoExpenseAgent.UpdateEmployeePostingGroup(CreateEmployeePostingGroup.EmployeeExpenses(), ExpenseGLAccount.FindGLAccountByName(HRGLAccount.EmployeesPayableName()), ExpenseGLAccount.FindGLAccountByName(CreateATGLAccount.SettlementAccountCashBankName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.BankLcyName()), ExpenseGLAccountAT.CompanyCreditCardsClearingAccount());
        ContosoExpenseAgent.SetOverwriteData(false);
    end;
}