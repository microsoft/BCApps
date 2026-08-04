// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 8212 "Create Expense Rule Header"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    var
        CreateExpenseCategories: Codeunit "Create Expense Categories DM";
        ContosoExpenseAgent: Codeunit "Contoso Expense Agent";
    begin
        ContosoExpenseAgent.InsertExpenseRuleHeader(CreateExpenseCategories.Entertain(), '', 0D, Enum::"Expense Justification"::"Against Conditions", false, '', '', '');
        ContosoExpenseAgent.InsertExpenseRuleHeader(CreateExpenseCategories.Hotels(), '', 0D, Enum::"Expense Justification"::" ", false, '', '', '');
        ContosoExpenseAgent.InsertExpenseRuleHeader(CreateExpenseCategories.Mileage(), '', 0D, Enum::"Expense Justification"::" ", false, '', '', '');
        ContosoExpenseAgent.InsertExpenseRuleHeader(CreateExpenseCategories.Morale(), '', 0D, Enum::"Expense Justification"::" ", false, '', '', '');
    end;
}