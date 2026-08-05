// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Finance.Currency;

codeunit 6903 "Expense Currency"
{
    Access = Internal;

    procedure GetExpense(ExpenseNo: Code[20]): Record Expense
    begin
        GetExpense(Expense, Currency, ExpenseNo);
        exit(Expense);
    end;

    procedure GetExpense(var OutExpense: Record Expense; var OutCurrency: Record Currency; ExpenseNo: Code[20])
    begin
        if (ExpenseNo <> Expense."No.") then
            if Expense.Get(ExpenseNo) then begin
                HasExpense := true;
                if Expense."Currency Code" = '' then
                    Currency.InitRoundingPrecision()
                else begin
                    Expense.TestField("Currency Factor");
                    Currency.Get(Expense."Currency Code");
                    Currency.TestField("Amount Rounding Precision");
                end
            end else
                Clear(Expense);

        OutExpense := Expense;
        OutCurrency := Currency;
    end;

    procedure GetHasExpense(): Boolean
    begin
        exit(HasExpense);
    end;

    var
        Expense: Record Expense;
        Currency: Record Currency;
        HasExpense: Boolean;
}