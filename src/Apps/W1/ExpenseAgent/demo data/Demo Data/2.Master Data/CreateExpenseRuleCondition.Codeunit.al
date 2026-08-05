// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 8213 "Create Expense Rule Condition"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    var
        CreateExpenseCategories: Codeunit "Create Expense Categories DM";
        ContosoExpenseAgent: Codeunit "Contoso Expense Agent";
    begin
        ContosoExpenseAgent.InsertExpenseRuleCondition(CreateExpenseCategories.Entertain(), '', 0D, 10000, Enum::"Expense Rule Condition Type"::"At Least Justification Needed", 500);
        ContosoExpenseAgent.InsertExpenseRuleCondition(CreateExpenseCategories.Entertain(), '', 0D, 20000, Enum::"Expense Rule Condition Type"::"Max Amount", 1000);
        ContosoExpenseAgent.InsertExpenseRuleCondition(CreateExpenseCategories.Mileage(), '', 0D, 10000, Enum::"Expense Rule Condition Type"::"Max Amount", 300);
    end;
}