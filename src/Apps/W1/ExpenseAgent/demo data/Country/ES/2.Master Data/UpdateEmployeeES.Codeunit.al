// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.DemoData.HumanResources;
using Microsoft.HumanResources.Employee;

codeunit 8286 "Update Employee ES"
{
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata Employee = rm;

    trigger OnRun()
    begin
        UpdateEmployees();
    end;

    local procedure UpdateEmployees()
    var
        CreateEmployee: Codeunit "Create Employee";
        CreateEmployeePostingGroup: Codeunit "Create Employee Posting Group";
    begin
        SetEmployeePostingGroup(CreateEmployee.ManagingDirector(), CreateEmployeePostingGroup.EmployeeExpenses());
        SetEmployeePostingGroup(CreateEmployee.SalesManager(), CreateEmployeePostingGroup.EmployeeExpenses());
        SetEmployeePostingGroup(CreateEmployee.Designer(), CreateEmployeePostingGroup.EmployeeExpenses());
        SetEmployeePostingGroup(CreateEmployee.ProductionAssistant(), CreateEmployeePostingGroup.EmployeeExpenses());
        SetEmployeePostingGroup(CreateEmployee.ProductionManager(), CreateEmployeePostingGroup.EmployeeExpenses());
        SetEmployeePostingGroup(CreateEmployee.Secretary(), CreateEmployeePostingGroup.EmployeeExpenses());
        SetEmployeePostingGroup(CreateEmployee.InventoryManager(), CreateEmployeePostingGroup.EmployeeExpenses());
    end;

    local procedure SetEmployeePostingGroup(EmployeeNo: Code[20]; PostingGroupCode: Code[20])
    var
        Employee: Record Employee;
    begin
        if Employee.Get(EmployeeNo) then begin
            Employee.Validate("Employee Posting Group", PostingGroupCode);
            Employee.Modify();
        end;
    end;
}
