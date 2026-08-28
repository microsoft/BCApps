// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.DemoData.Finance;

codeunit 8271 "AU Exp. Rule Header"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    var
        CreateCurrency: Codeunit "Create Currency";
        AUExpCategories: Codeunit "AU Exp. Categories";
        CreateExpenseLocation: Codeunit "Create Expense Location";
        ContosoExpenseAgent: Codeunit "Contoso Expense Agent";
    begin
        ContosoExpenseAgent.InsertExpenseRuleHeader(AUExpCategories.PerDiem(), CreateExpenseLocation.CanadaAll(), 0D, Enum::"Expense Justification"::" ", false, '', CreateCurrency.CAD(), '');
        ContosoExpenseAgent.InsertExpenseRuleHeader(AUExpCategories.PerDiem(), CreateExpenseLocation.DenmarkAll(), 0D, Enum::"Expense Justification"::" ", false, '', CreateCurrency.EUR(), '');
        ContosoExpenseAgent.InsertExpenseRuleHeader(AUExpCategories.PerDiem(), CreateExpenseLocation.Domestic(), 0D, Enum::"Expense Justification"::" ", false, '', '', '');
        ContosoExpenseAgent.InsertExpenseRuleHeader(AUExpCategories.PerDiem(), CreateExpenseLocation.FranceAll(), 0D, Enum::"Expense Justification"::" ", false, '', CreateCurrency.EUR(), '');
        ContosoExpenseAgent.InsertExpenseRuleHeader(AUExpCategories.PerDiem(), CreateExpenseLocation.GermanyAll(), 0D, Enum::"Expense Justification"::" ", false, '', CreateCurrency.EUR(), '');
        ContosoExpenseAgent.InsertExpenseRuleHeader(AUExpCategories.PerDiem(), CreateExpenseLocation.UKOther(), 0D, Enum::"Expense Justification"::" ", false, '', CreateCurrency.GBP(), '');
        ContosoExpenseAgent.InsertExpenseRuleHeader(AUExpCategories.PerDiem(), CreateExpenseLocation.USAOther(), 0D, Enum::"Expense Justification"::" ", false, '', '', '');
    end;
}
