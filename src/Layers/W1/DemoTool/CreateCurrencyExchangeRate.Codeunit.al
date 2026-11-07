codeunit 101330 "Create Currency Exchange Rate"
{
    TableNo = "Currency Exchange Rate";

    trigger OnRun()
    begin
    end;

    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        DemoDataSetup: Record "Demo Data Setup";

    procedure InsertData("Currency Code": Code[10]; "Starting Date": Date; "Exchange Rate Amount": Decimal; "Adjustment Exch. Rate Amount": Decimal; "Relational Currency Code": Code[10]; "Relational Exch. rate Amount": Decimal; "Fix Exchange Rate Amount": Option; "Relational Adjmt Exch Rate Amt": Decimal)
    begin
        CurrencyExchangeRate.Validate("Currency Code", "Currency Code");
        CurrencyExchangeRate.Validate("Starting Date", "Starting Date");
        CurrencyExchangeRate.Validate("Exchange Rate Amount", "Exchange Rate Amount");
        CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", "Adjustment Exch. Rate Amount");
        CurrencyExchangeRate.Validate("Relational Currency Code", "Relational Currency Code");
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", "Relational Exch. rate Amount");
        CurrencyExchangeRate.Validate("Fix Exchange Rate Amount", "Fix Exchange Rate Amount");
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", "Relational Adjmt Exch Rate Amt");
        CurrencyExchangeRate.Insert();
    end;

    procedure LocalizeExchangeRates()
    begin
        DemoDataSetup.Get();
        CurrencyExchangeRate.Reset();
        if CurrencyExchangeRate.Find('-') then
            repeat
                CurrencyExchangeRate."Relational Exch. Rate Amount" :=
                  Round(
                    CurrencyExchangeRate."Relational Exch. Rate Amount" *
                    DemoDataSetup."Local Currency Factor", 0.0001);
                CurrencyExchangeRate."Relational Adjmt Exch Rate Amt" :=
                  CurrencyExchangeRate."Relational Exch. Rate Amount";
                CurrencyExchangeRate."Adjustment Exch. Rate Amount" :=
                  CurrencyExchangeRate."Exchange Rate Amount";
                CurrencyExchangeRate.Modify();
            until CurrencyExchangeRate.Next() = 0;
    end;
}

