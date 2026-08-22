// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.DemoData.HumanResources;

codeunit 8426 "Update Emp. Posting Grp IT"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    begin
        UpdateEmployeePostingGroup();
    end;

    local procedure UpdateEmployeePostingGroup()
    var
        CreateExpGLAccountIT: Codeunit "Create Exp. GL Account IT";
        ContosoExpenseAgent: Codeunit "Contoso Expense Agent";
        CreateEmployeePostingGroup: Codeunit "Create Employee Posting Group";
    begin
        ContosoExpenseAgent.SetOverwriteData(true);
        ContosoExpenseAgent.UpdateEmployeePostingGroup(CreateEmployeePostingGroup.EmployeeExpenses(), CreateExpGLAccountIT.EmployeeExpenseReimbursementPayable(), CreateExpGLAccountIT.EmployeeAdvancesPrepayments(), CreateExpGLAccountIT.CompanyPaidExpenseClearing(), CreateExpGLAccountIT.CorporateCardExpenseClearing());
        ContosoExpenseAgent.SetOverwriteData(false);
    end;
}
