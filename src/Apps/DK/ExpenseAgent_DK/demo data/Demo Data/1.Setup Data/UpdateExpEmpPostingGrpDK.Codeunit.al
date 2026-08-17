// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.DemoData.Finance;
using Microsoft.DemoData.HumanResources;

codeunit 13677 "Update Exp. Emp Posting Grp DK"
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
        ExpenseGLAccountDK: Codeunit "Create Expense G/L Account DK";
        CreateDKGLAccounts: Codeunit "Create GL Acc. DK";
        ContosoExpenseAgent: Codeunit "Contoso Expense Agent";
        CreateEmployeePostingGroup: Codeunit "Create Employee Posting Group";
    begin
        ContosoExpenseAgent.SetOverwriteData(true);
        ContosoExpenseAgent.UpdateEmployeePostingGroup(CreateEmployeePostingGroup.EmployeeExpenses(), ExpenseGLAccount.FindGLAccountByName(CreateDKGLAccounts.AccountsPayablePostingName()), ExpenseGLAccount.FindGLAccountByName(CreateDKGLAccounts.PrepaymentsAccruedCostsName()), ExpenseGLAccount.FindGLAccountByName(CreateDKGLAccounts.BankName()), ExpenseGLAccountDK.CompanyCreditCards());
        ContosoExpenseAgent.SetOverwriteData(false);
    end;
}