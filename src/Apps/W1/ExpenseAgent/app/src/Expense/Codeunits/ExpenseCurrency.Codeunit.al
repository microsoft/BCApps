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

    procedure ShowMissingExchangeRateError(CurrencyDate: Date; CurrencyCode: Code[10])
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        StartingDate: Date;
    begin
        if CurrencyDate = 0D then
            CurrencyDate := WorkDate();

        StartingDate := CurrencyDate;
        CurrencyExchangeRate.SetLoadFields("Starting Date");
        CurrencyExchangeRate.SetRange("Currency Code", CurrencyCode);
        if CurrencyExchangeRate.FindFirst() then
            StartingDate := CurrencyExchangeRate."Starting Date";

        Error(ReceiptDatedBeforeExchRateErr, StartingDate, CurrencyCode);
    end;

    var
        Expense: Record Expense;
        Currency: Record Currency;
        HasExpense: Boolean;
        ReceiptDatedBeforeExchRateErr: Label 'You cannot upload a receipt dated before %1 for currency %2.\\Please update the Currency Exchange Rates setup or contact your administrator before proceeding.', Comment = '%1 = Starting Date, %2 = Currency Code';
}