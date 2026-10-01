#if not CLEAN30
#pragma warning disable AL0432
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 13680 "Create Exp. Rule Condition DK"
{
    InherentEntitlements = X;
    InherentPermissions = X;
    ObsoleteState = Pending;
    ObsoleteReason = 'The country-specific Expense Agent demo data is being consolidated into a single app in W1 and will be removed in a future release.';
    ObsoleteTag = '30.0';

    trigger OnRun()
    var
        CreateExpenseCategoriesDK: Codeunit "Create Expense Categories DK";
        CreateExpenseLocation: Codeunit "Create Expense Location";
        ContosoExpenseAgent: Codeunit "Contoso Expense Agent";
    begin
        ContosoExpenseAgent.InsertExpenseRuleCondition(CreateExpenseCategoriesDK.PerDiem(), CreateExpenseLocation.CanadaAll(), 0D, 10000, Enum::"Expense Rule Condition Type"::"Daily Rate", 125);
        ContosoExpenseAgent.InsertExpenseRuleCondition(CreateExpenseCategoriesDK.PerDiem(), CreateExpenseLocation.DenmarkAll(), 0D, 10000, Enum::"Expense Rule Condition Type"::"Daily Rate", 450);
        ContosoExpenseAgent.InsertExpenseRuleCondition(CreateExpenseCategoriesDK.PerDiem(), CreateExpenseLocation.Domestic(), 0D, 10000, Enum::"Expense Rule Condition Type"::"Daily Rate", 50);
        ContosoExpenseAgent.InsertExpenseRuleCondition(CreateExpenseCategoriesDK.PerDiem(), CreateExpenseLocation.FranceAll(), 0D, 10000, Enum::"Expense Rule Condition Type"::"Daily Rate", 110);
        ContosoExpenseAgent.InsertExpenseRuleCondition(CreateExpenseCategoriesDK.PerDiem(), CreateExpenseLocation.GermanyAll(), 0D, 10000, Enum::"Expense Rule Condition Type"::"Daily Rate", 105);
        ContosoExpenseAgent.InsertExpenseRuleCondition(CreateExpenseCategoriesDK.PerDiem(), CreateExpenseLocation.UKOther(), 0D, 10000, Enum::"Expense Rule Condition Type"::"Daily Rate", 115);
        ContosoExpenseAgent.InsertExpenseRuleCondition(CreateExpenseCategoriesDK.PerDiem(), CreateExpenseLocation.USAOther(), 0D, 10000, Enum::"Expense Rule Condition Type"::"Daily Rate", 120);
    end;
}
#endif