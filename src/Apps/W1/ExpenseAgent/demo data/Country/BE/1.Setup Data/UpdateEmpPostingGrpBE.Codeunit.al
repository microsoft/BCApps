// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.DemoData.HumanResources;

codeunit 8415 "Update Emp. Posting Grp BE"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    begin
        UpdateEmployeePostingGroup();
    end;

    local procedure UpdateEmployeePostingGroup()
    var
        CreateExpGLAccountBE: Codeunit "Create Exp. GL Account BE";
        ExpenseGLAccountNamesBE: Codeunit "Expense GL Account Names BE";
        ExpenseGLAccount: Codeunit "Create Expense G/L Account";
        ContosoExpenseAgent: Codeunit "Contoso Expense Agent";
        CreateEmployeePostingGroup: Codeunit "Create Employee Posting Group";
    begin
        ContosoExpenseAgent.SetOverwriteData(true);
        ContosoExpenseAgent.UpdateEmployeePostingGroup(CreateEmployeePostingGroup.EmployeeExpenses(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesBE.EmployeesPayableName()), CreateExpGLAccountBE.EmployeeTravelAdvances(), CreateExpGLAccountBE.CompanyPaidExpenseClearing(), CreateExpGLAccountBE.CorporateCardExpenseClearing());
        ContosoExpenseAgent.SetOverwriteData(false);
    end;
}
