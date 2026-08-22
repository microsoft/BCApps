// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.DemoData.HumanResources;

codeunit 8448 "Update Emp. Posting Grp NO"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    begin
        UpdateEmployeePostingGroup();
    end;

    local procedure UpdateEmployeePostingGroup()
    var
        CreateExpGLAccountNO: Codeunit "Create Exp. GL Account NO";
        ContosoExpenseAgent: Codeunit "Contoso Expense Agent";
        CreateEmployeePostingGroup: Codeunit "Create Employee Posting Group";
    begin
        ContosoExpenseAgent.SetOverwriteData(true);
        ContosoExpenseAgent.UpdateEmployeePostingGroup(CreateEmployeePostingGroup.EmployeeExpenses(), CreateExpGLAccountNO.EmployeeExpensePayableCash(), CreateExpGLAccountNO.EmployeeExpensePrepayments(), CreateExpGLAccountNO.EmployeeExpensePayableCompanyPaid(), CreateExpGLAccountNO.EmployeeExpensePayableCard());
        ContosoExpenseAgent.SetOverwriteData(false);
    end;
}
