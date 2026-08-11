// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 8242 "Create Exp. Rule Condition GB"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    var
        CreateExpCategoriesGB: Codeunit "Create Exp. Categories GB";
        CreateExpenseLocation: Codeunit "Create Expense Location";
        ContosoExpenseAgent: Codeunit "Contoso Expense Agent";
    begin
        ContosoExpenseAgent.InsertExpenseRuleCondition(CreateExpCategoriesGB.PerDiem(), CreateExpenseLocation.CanadaAll(), 0D, 10000, Enum::"Expense Rule Condition Type"::"Daily Rate", 125);
        ContosoExpenseAgent.InsertExpenseRuleCondition(CreateExpCategoriesGB.PerDiem(), CreateExpenseLocation.DenmarkAll(), 0D, 10000, Enum::"Expense Rule Condition Type"::"Daily Rate", 450);
        ContosoExpenseAgent.InsertExpenseRuleCondition(CreateExpCategoriesGB.PerDiem(), CreateExpenseLocation.Domestic(), 0D, 10000, Enum::"Expense Rule Condition Type"::"Daily Rate", 50);
        ContosoExpenseAgent.InsertExpenseRuleCondition(CreateExpCategoriesGB.PerDiem(), CreateExpenseLocation.FranceAll(), 0D, 10000, Enum::"Expense Rule Condition Type"::"Daily Rate", 110);
        ContosoExpenseAgent.InsertExpenseRuleCondition(CreateExpCategoriesGB.PerDiem(), CreateExpenseLocation.GermanyAll(), 0D, 10000, Enum::"Expense Rule Condition Type"::"Daily Rate", 105);
        ContosoExpenseAgent.InsertExpenseRuleCondition(CreateExpCategoriesGB.PerDiem(), CreateExpenseLocation.UKOther(), 0D, 10000, Enum::"Expense Rule Condition Type"::"Daily Rate", 115);
        ContosoExpenseAgent.InsertExpenseRuleCondition(CreateExpCategoriesGB.PerDiem(), CreateExpenseLocation.USAOther(), 0D, 10000, Enum::"Expense Rule Condition Type"::"Daily Rate", 120);
    end;
}
