#if not CLEAN30
#pragma warning disable AL0432
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
    ObsoleteState = Pending;
    ObsoleteReason = 'The country-specific Expense Agent demo data is being consolidated into a single app in W1 and will be removed in a future release.';
    ObsoleteTag = '30.0';

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
#endif