// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.DemoData.Finance;

codeunit 8251 "Create Exp. Rule Header CA"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    var
        CreateCurrency: Codeunit "Create Currency";
        CreateExpCategoriesCA: Codeunit "Create Exp. Categories CA";
        CreateExpenseLocation: Codeunit "Create Expense Location";
        ContosoExpenseAgent: Codeunit "Contoso Expense Agent";
    begin
        ContosoExpenseAgent.InsertExpenseRuleHeader(CreateExpCategoriesCA.PerDiem(), CreateExpenseLocation.CanadaAll(), 0D, Enum::"Expense Justification"::" ", false, '', '', '');
        ContosoExpenseAgent.InsertExpenseRuleHeader(CreateExpCategoriesCA.PerDiem(), CreateExpenseLocation.DenmarkAll(), 0D, Enum::"Expense Justification"::" ", false, '', CreateCurrency.EUR(), '');
        ContosoExpenseAgent.InsertExpenseRuleHeader(CreateExpCategoriesCA.PerDiem(), CreateExpenseLocation.Domestic(), 0D, Enum::"Expense Justification"::" ", false, '', '', '');
        ContosoExpenseAgent.InsertExpenseRuleHeader(CreateExpCategoriesCA.PerDiem(), CreateExpenseLocation.FranceAll(), 0D, Enum::"Expense Justification"::" ", false, '', CreateCurrency.EUR(), '');
        ContosoExpenseAgent.InsertExpenseRuleHeader(CreateExpCategoriesCA.PerDiem(), CreateExpenseLocation.GermanyAll(), 0D, Enum::"Expense Justification"::" ", false, '', CreateCurrency.EUR(), '');
        ContosoExpenseAgent.InsertExpenseRuleHeader(CreateExpCategoriesCA.PerDiem(), CreateExpenseLocation.UKOther(), 0D, Enum::"Expense Justification"::" ", false, '', CreateCurrency.GBP(), '');
        ContosoExpenseAgent.InsertExpenseRuleHeader(CreateExpCategoriesCA.PerDiem(), CreateExpenseLocation.USAOther(), 0D, Enum::"Expense Justification"::" ", false, '', '', '');
    end;
}
