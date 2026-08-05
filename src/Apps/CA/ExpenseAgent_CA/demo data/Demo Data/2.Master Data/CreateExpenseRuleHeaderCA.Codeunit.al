// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.DemoData.Finance;

codeunit 27105 "Create Expense Rule Header CA"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    var
        CreateCurrency: Codeunit "Create Currency";
        CreateExpenseCategoriesCA: Codeunit "Create Expense Categories CA";
        CreateExpenseLocation: Codeunit "Create Expense Location";
        ContosoExpenseAgent: Codeunit "Contoso Expense Agent";
    begin
        ContosoExpenseAgent.InsertExpenseRuleHeader(CreateExpenseCategoriesCA.PerDiem(), CreateExpenseLocation.CanadaAll(), 0D, Enum::"Expense Justification"::" ", false, '', '', '');
        ContosoExpenseAgent.InsertExpenseRuleHeader(CreateExpenseCategoriesCA.PerDiem(), CreateExpenseLocation.DenmarkAll(), 0D, Enum::"Expense Justification"::" ", false, '', CreateCurrency.EUR(), '');
        ContosoExpenseAgent.InsertExpenseRuleHeader(CreateExpenseCategoriesCA.PerDiem(), CreateExpenseLocation.Domestic(), 0D, Enum::"Expense Justification"::" ", false, '', '', '');
        ContosoExpenseAgent.InsertExpenseRuleHeader(CreateExpenseCategoriesCA.PerDiem(), CreateExpenseLocation.FranceAll(), 0D, Enum::"Expense Justification"::" ", false, '', CreateCurrency.EUR(), '');
        ContosoExpenseAgent.InsertExpenseRuleHeader(CreateExpenseCategoriesCA.PerDiem(), CreateExpenseLocation.GermanyAll(), 0D, Enum::"Expense Justification"::" ", false, '', CreateCurrency.EUR(), '');
        ContosoExpenseAgent.InsertExpenseRuleHeader(CreateExpenseCategoriesCA.PerDiem(), CreateExpenseLocation.UKOther(), 0D, Enum::"Expense Justification"::" ", false, '', CreateCurrency.GBP(), '');
        ContosoExpenseAgent.InsertExpenseRuleHeader(CreateExpenseCategoriesCA.PerDiem(), CreateExpenseLocation.USAOther(), 0D, Enum::"Expense Justification"::" ", false, '', '', '');
    end;
}