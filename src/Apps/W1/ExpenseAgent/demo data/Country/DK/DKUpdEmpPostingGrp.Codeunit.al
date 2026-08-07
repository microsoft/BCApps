// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.DemoData.HumanResources;

codeunit 8292 "DK Upd. Emp. Posting Grp"
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
        DKExpGLAccount: Codeunit "DK Exp. GL Account";
        DKGLAccountNames: Codeunit "DK GL Account Names";
        ContosoExpenseAgent: Codeunit "Contoso Expense Agent";
        CreateEmployeePostingGroup: Codeunit "Create Employee Posting Group";
    begin
        ContosoExpenseAgent.SetOverwriteData(true);
        ContosoExpenseAgent.UpdateEmployeePostingGroup(CreateEmployeePostingGroup.EmployeeExpenses(), ExpenseGLAccount.FindGLAccountByName(DKGLAccountNames.AccountsPayablePostingName()), ExpenseGLAccount.FindGLAccountByName(DKGLAccountNames.PrepaymentsAccruedCostsName()), ExpenseGLAccount.FindGLAccountByName(DKGLAccountNames.BankName()), DKExpGLAccount.CompanyCreditCards());
        ContosoExpenseAgent.SetOverwriteData(false);
    end;
}
