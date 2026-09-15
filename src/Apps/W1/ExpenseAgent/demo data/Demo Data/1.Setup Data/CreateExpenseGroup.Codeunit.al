// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 8206 "Create Expense Group"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    var
        ContosoExpenseAgent: Codeunit "Contoso Expense Agent";
    begin
        ContosoExpenseAgent.InsertExpenseGroup(DayExpense(), DayToDayExpensesLbl);
        ContosoExpenseAgent.InsertExpenseGroup(FoodBeverage(), FoodBeverageExpensesLbl);
        ContosoExpenseAgent.InsertExpenseGroup(Personal(), PersonalExpensesLbl);
        ContosoExpenseAgent.InsertExpenseGroup(Prepayment(), PrepaymentCashAdvanceLbl);
        ContosoExpenseAgent.InsertExpenseGroup(Travel(), TravelExpensesLbl);
    end;

    var
        DayExpenseTok: Label 'DAY-EXPENSE', MaxLength = 20, Locked = true;
        FoodBeverageTok: Label 'FOOD-BEVERAGE', MaxLength = 20, Locked = true;
        PersonalTok: Label 'PERSONAL', MaxLength = 20, Locked = true;
        PrepaymentTok: Label 'PREPAYMENT', MaxLength = 20, Locked = true;
        TravelTok: Label 'TRAVEL', MaxLength = 20, Locked = true;
        FoodBeverageExpensesLbl: Label 'Food & Beverage Expenses', MaxLength = 50;
        DayToDayExpensesLbl: Label 'Day-to-Day Expenses', MaxLength = 50;
        PersonalExpensesLbl: Label 'Personal Expenses', MaxLength = 50;
        PrepaymentCashAdvanceLbl: Label 'Prepayments - Cash Advance', MaxLength = 50;
        TravelExpensesLbl: Label 'Travel Expenses', MaxLength = 50;

    procedure DayExpense(): Code[20]
    begin
        exit(DayExpenseTok);
    end;

    procedure FoodBeverage(): Code[20]
    begin
        exit(FoodBeverageTok);
    end;

    procedure Personal(): Code[20]
    begin
        exit(PersonalTok);
    end;

    procedure Prepayment(): Code[20]
    begin
        exit(PrepaymentTok);
    end;

    procedure Travel(): Code[20]
    begin
        exit(TravelTok);
    end;
}