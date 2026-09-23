#if not CLEAN30
#pragma warning disable AL0432
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.DemoData.Finance;

codeunit 11195 "Create Expense Rule Header AT"
{
    InherentEntitlements = X;
    InherentPermissions = X;
    ObsoleteState = Pending;
    ObsoleteReason = 'The country-specific Expense Agent demo data is being consolidated into a single app in W1 and will be removed in a future release.';
    ObsoleteTag = '30.0';

    trigger OnRun()
    var
        CreateCurrency: Codeunit "Create Currency";
        CreateExpenseCategoriesAT: Codeunit "Create Expense Categories AT";
        CreateExpenseLocation: Codeunit "Create Expense Location";
        ContosoExpenseAgent: Codeunit "Contoso Expense Agent";
    begin
        ContosoExpenseAgent.InsertExpenseRuleHeader(CreateExpenseCategoriesAT.PerDiemI(), CreateExpenseLocation.CanadaAll(), 0D, Enum::"Expense Justification"::" ", false, '', CreateCurrency.CAD(), '');
        ContosoExpenseAgent.InsertExpenseRuleHeader(CreateExpenseCategoriesAT.PerDiemI(), CreateExpenseLocation.DenmarkAll(), 0D, Enum::"Expense Justification"::" ", false, '', CreateCurrency.USD(), '');
        ContosoExpenseAgent.InsertExpenseRuleHeader(CreateExpenseCategoriesAT.PerDiemA(), CreateExpenseLocation.Domestic(), 0D, Enum::"Expense Justification"::" ", false, '', '', '');
        ContosoExpenseAgent.InsertExpenseRuleHeader(CreateExpenseCategoriesAT.PerDiemI(), CreateExpenseLocation.FranceAll(), 0D, Enum::"Expense Justification"::" ", false, '', CreateCurrency.USD(), '');
        ContosoExpenseAgent.InsertExpenseRuleHeader(CreateExpenseCategoriesAT.PerDiemI(), CreateExpenseLocation.GermanyAll(), 0D, Enum::"Expense Justification"::" ", false, '', CreateCurrency.USD(), '');
        ContosoExpenseAgent.InsertExpenseRuleHeader(CreateExpenseCategoriesAT.PerDiemI(), CreateExpenseLocation.UKOther(), 0D, Enum::"Expense Justification"::" ", false, '', CreateCurrency.GBP(), '');
        ContosoExpenseAgent.InsertExpenseRuleHeader(CreateExpenseCategoriesAT.PerDiemI(), CreateExpenseLocation.USAOther(), 0D, Enum::"Expense Justification"::" ", false, '', CreateCurrency.USD(), '');
    end;
}
#endif