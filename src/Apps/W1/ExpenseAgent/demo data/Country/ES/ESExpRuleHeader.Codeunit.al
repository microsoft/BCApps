// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.DemoData.Finance;

codeunit 8282 "ES Exp. Rule Header"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    var
        CreateCurrency: Codeunit "Create Currency";
        ESExpCategories: Codeunit "ES Exp. Categories";
        CreateExpenseLocation: Codeunit "Create Expense Location";
        ContosoExpenseAgent: Codeunit "Contoso Expense Agent";
    begin
        ContosoExpenseAgent.InsertExpenseRuleHeader(ESExpCategories.PerDiem(), CreateExpenseLocation.CanadaAll(), 0D, Enum::"Expense Justification"::" ", false, '', CreateCurrency.CAD(), '');
        ContosoExpenseAgent.InsertExpenseRuleHeader(ESExpCategories.PerDiem(), CreateExpenseLocation.DenmarkAll(), 0D, Enum::"Expense Justification"::" ", false, '', CreateCurrency.USD(), '');
        ContosoExpenseAgent.InsertExpenseRuleHeader(ESExpCategories.PerDiem(), CreateExpenseLocation.Domestic(), 0D, Enum::"Expense Justification"::" ", false, '', '', '');
        ContosoExpenseAgent.InsertExpenseRuleHeader(ESExpCategories.PerDiem(), CreateExpenseLocation.FranceAll(), 0D, Enum::"Expense Justification"::" ", false, '', CreateCurrency.USD(), '');
        ContosoExpenseAgent.InsertExpenseRuleHeader(ESExpCategories.PerDiem(), CreateExpenseLocation.GermanyAll(), 0D, Enum::"Expense Justification"::" ", false, '', CreateCurrency.USD(), '');
        ContosoExpenseAgent.InsertExpenseRuleHeader(ESExpCategories.PerDiem(), CreateExpenseLocation.UKOther(), 0D, Enum::"Expense Justification"::" ", false, '', CreateCurrency.GBP(), '');
        ContosoExpenseAgent.InsertExpenseRuleHeader(ESExpCategories.PerDiem(), CreateExpenseLocation.USAOther(), 0D, Enum::"Expense Justification"::" ", false, '', '', '');
    end;
}
