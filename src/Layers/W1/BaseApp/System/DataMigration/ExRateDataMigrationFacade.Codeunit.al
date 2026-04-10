namespace System.Integration;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;

codeunit 6114 "Ex. Rate Data Migration Facade"
{

    trigger OnRun()
    begin
    end;

    procedure CreateSimpleExchangeRateIfNeeded(CurrencyCode: Code[10]; StartingDate: Date; RelationalExchangeRateAmount: Decimal; ExchangeRateAmount: Decimal)
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        if GeneralLedgerSetup."LCY Code" = CurrencyCode then
            exit; // no exchange rate from local currency to local currency

        if not CurrencyExchangeRate.Get(CurrencyCode, StartingDate) then begin
            CurrencyExchangeRate.Init();
            CurrencyExchangeRate.Validate("Currency Code", CurrencyCode);
            CurrencyExchangeRate.Validate("Starting Date", StartingDate);
            CurrencyExchangeRate.Validate("Exchange Rate Amount", ExchangeRateAmount);
            CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", ExchangeRateAmount);
            CurrencyExchangeRate.Validate("Relational Currency Code", '');
            CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", RelationalExchangeRateAmount);
            CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", RelationalExchangeRateAmount);
            CurrencyExchangeRate.Validate("Fix Exchange Rate Amount", CurrencyExchangeRate."Fix Exchange Rate Amount"::Currency);
            CurrencyExchangeRate.Insert();
        end;
    end;
}

