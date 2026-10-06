#if not CLEAN30
#pragma warning disable AL0432
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 10606 "Create Exp. Rule Condition GB"
{
    InherentEntitlements = X;
    InherentPermissions = X;
    ObsoleteState = Pending;
    ObsoleteReason = 'The country-specific Expense Agent demo data is being consolidated into a single app in W1 and will be removed in a future release.';
    ObsoleteTag = '30.0';

    trigger OnRun()
    var
        CreateExpenseCategoriesGB: Codeunit "Create Expense Categories GB";
        CreateExpenseLocation: Codeunit "Create Expense Location";
        ContosoExpenseAgent: Codeunit "Contoso Expense Agent";
    begin
        ContosoExpenseAgent.InsertExpenseRuleCondition(CreateExpenseCategoriesGB.PerDiem(), CreateExpenseLocation.CanadaAll(), 0D, 10000, Enum::"Expense Rule Condition Type"::"Daily Rate", 125);
        ContosoExpenseAgent.InsertExpenseRuleCondition(CreateExpenseCategoriesGB.PerDiem(), CreateExpenseLocation.DenmarkAll(), 0D, 10000, Enum::"Expense Rule Condition Type"::"Daily Rate", 450);
        ContosoExpenseAgent.InsertExpenseRuleCondition(CreateExpenseCategoriesGB.PerDiem(), CreateExpenseLocation.Domestic(), 0D, 10000, Enum::"Expense Rule Condition Type"::"Daily Rate", 50);
        ContosoExpenseAgent.InsertExpenseRuleCondition(CreateExpenseCategoriesGB.PerDiem(), CreateExpenseLocation.FranceAll(), 0D, 10000, Enum::"Expense Rule Condition Type"::"Daily Rate", 110);
        ContosoExpenseAgent.InsertExpenseRuleCondition(CreateExpenseCategoriesGB.PerDiem(), CreateExpenseLocation.GermanyAll(), 0D, 10000, Enum::"Expense Rule Condition Type"::"Daily Rate", 105);
        ContosoExpenseAgent.InsertExpenseRuleCondition(CreateExpenseCategoriesGB.PerDiem(), CreateExpenseLocation.UKOther(), 0D, 10000, Enum::"Expense Rule Condition Type"::"Daily Rate", 115);
        ContosoExpenseAgent.InsertExpenseRuleCondition(CreateExpenseCategoriesGB.PerDiem(), CreateExpenseLocation.USAOther(), 0D, 10000, Enum::"Expense Rule Condition Type"::"Daily Rate", 120);
    end;
}
#endif