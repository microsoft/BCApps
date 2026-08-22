// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.DemoData.HumanResources;

codeunit 8437 "Update Emp. Posting Grp CH"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    begin
        UpdateEmployeePostingGroup();
    end;

    local procedure UpdateEmployeePostingGroup()
    var
        CreateExpGLAccountCH: Codeunit "Create Exp. GL Account CH";
        ContosoExpenseAgent: Codeunit "Contoso Expense Agent";
        CreateEmployeePostingGroup: Codeunit "Create Employee Posting Group";
    begin
        ContosoExpenseAgent.SetOverwriteData(true);
        ContosoExpenseAgent.UpdateEmployeePostingGroup(CreateEmployeePostingGroup.EmployeeExpenses(), CreateExpGLAccountCH.EmployeeExpenseReimbursementsPayable(), CreateExpGLAccountCH.EmployeeExpenseAdvances(), CreateExpGLAccountCH.CompanyPaidExpenseClearing(), CreateExpGLAccountCH.CompanyCardExpensesPayable());
        ContosoExpenseAgent.SetOverwriteData(false);
    end;
}
