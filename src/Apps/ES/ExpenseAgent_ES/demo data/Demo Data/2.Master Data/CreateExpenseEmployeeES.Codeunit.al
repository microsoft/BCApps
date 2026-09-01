#if not CLEAN30
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.DemoData.HumanResources;
using Microsoft.HumanResources.Employee;

codeunit 10924 "Create Expense Employee ES"
{
    SingleInstance = true;
    EventSubscriberInstance = Manual;
    InherentEntitlements = X;
    InherentPermissions = X;
    ObsoleteState = Pending;
    ObsoleteReason = 'The country-specific Expense Agent demo data is being consolidated into a single app in W1 and will be removed in a future release.';
    ObsoleteTag = '30.0';

    [EventSubscriber(ObjectType::Table, Database::Employee, 'OnBeforeInsertEvent', '', false, false)]
    local procedure OnBeforeInsertResource(var Rec: Record Employee)
    var
        CreateEmployee: Codeunit "Create Employee";
        CreateEmployeePostingGroup: Codeunit "Create Employee Posting Group";
    begin
        case Rec."No." of
            CreateEmployee.ManagingDirector(),
            CreateEmployee.SalesManager(),
            CreateEmployee.Designer(),
            CreateEmployee.ProductionAssistant(),
            CreateEmployee.ProductionManager(),
            CreateEmployee.Secretary(),
            CreateEmployee.InventoryManager():
                Rec.Validate("Employee Posting Group", CreateEmployeePostingGroup.EmployeeExpenses());
        end;
    end;
}
#endif