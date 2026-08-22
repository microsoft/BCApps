// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.DemoData.Finance;
using Microsoft.DemoData.HumanResources;

codeunit 8226 "Update Emp. Posting Grp US"
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
        ExpenseGLAccountNamesUS: Codeunit "Expense GL Account Names US";
        ContosoExpenseAgent: Codeunit "Contoso Expense Agent";
        CreateEmployeePostingGroup: Codeunit "Create Employee Posting Group";
    begin
        ContosoExpenseAgent.SetOverwriteData(true);
        ContosoExpenseAgent.UpdateEmployeePostingGroup(CreateEmployeePostingGroup.EmployeeExpenses(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesUS.AccountsPayableDomesticName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.CashName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesUS.OtherBankAccountsName()), ExpenseGLAccount.CompanyCreditCardsAccount());
        ContosoExpenseAgent.SetOverwriteData(false);
    end;
}
