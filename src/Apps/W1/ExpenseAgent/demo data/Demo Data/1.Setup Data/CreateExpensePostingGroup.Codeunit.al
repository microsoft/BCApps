// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 8215 "Create Expense Posting Group"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    var
        ContosoExpenseAgent: Codeunit "Contoso Expense Agent";
    begin
        ContosoExpenseAgent.InsertExpensePostingGroup(ExpenseEntertainment(), ExpenseEntertainmentLbl);
        ContosoExpenseAgent.InsertExpensePostingGroup(ExpenseMeals(), ExpenseMealsLbl);
        ContosoExpenseAgent.InsertExpensePostingGroup(ExpenseMileage(), ExpenseMileageLbl);
        ContosoExpenseAgent.InsertExpensePostingGroup(ExpenseTravel(), ExpenseTravelLbl);
        ContosoExpenseAgent.InsertExpensePostingGroup(ExpenseOther(), ExpenseOtherLbl);
        ContosoExpenseAgent.InsertExpensePostingGroup(ExpenseRentalCars(), ExpenseRentalCarsLbl);
    end;

    var
        ExpenseENTERTTok: Label 'EXPENSE ENTERT', MaxLength = 20, Locked = true;
        ExpenseMEALSTok: Label 'EXPENSE MEALS', MaxLength = 20, Locked = true;
        ExpenseMILEAGETok: Label 'EXPENSE MILEAGE', MaxLength = 20, Locked = true;
        ExpenseOTHERTok: Label 'EXPENSE-OTHER', MaxLength = 20, Locked = true;
        ExpenseTRAVELTok: Label 'EXPENSE-TRAVEL', MaxLength = 20, Locked = true;
        ExpenseRENTALTok: Label 'EXPENSE-RENTAL', MaxLength = 20, Locked = true;
        ExpenseEntertainmentLbl: Label 'Expense - Entertainment', MaxLength = 100;
        ExpenseMealsLbl: Label 'Expense - Meals', MaxLength = 100;
        ExpenseMileageLbl: Label 'Expense - Mileage', MaxLength = 100;
        ExpenseOtherLbl: Label 'Expense - Other', MaxLength = 100;
        ExpenseTravelLbl: Label 'Expense - Travel', MaxLength = 100;
        ExpenseRentalCarsLbl: Label 'Expense - Rental Cars', MaxLength = 100;

    procedure ExpenseEntertainment(): Code[20]
    begin
        exit(ExpenseENTERTTok);
    end;

    procedure ExpenseMeals(): Code[20]
    begin
        exit(ExpenseMEALSTok);
    end;

    procedure ExpenseMileage(): Code[20]
    begin
        exit(ExpenseMILEAGETok);
    end;

    procedure ExpenseTravel(): Code[20]
    begin
        exit(ExpenseTRAVELTok);
    end;

    procedure ExpenseOther(): Code[20]
    begin
        exit(ExpenseOTHERTok);
    end;

    procedure ExpenseRentalCars(): Code[20]
    begin
        exit(ExpenseRENTALTok);
    end;

#if not CLEAN29
    [Obsolete('This function is no longer used.', '29.0')]
    procedure ExpensePerDiem(): Code[20]
    begin
    end;
#endif
}