codeunit 163550 "Create Curr. Nominal Value CZP"
{
    trigger OnRun()
    begin
        InsertData('', 1);
        InsertData('', 2);
        InsertData('', 5);
        InsertData('', 10);
        InsertData('', 20);
        InsertData('', 50);
        InsertData('', 100);
        InsertData('', 200);
        InsertData('', 500);
        InsertData('', 1000);
        InsertData('', 2000);
        InsertData('', 5000);
    end;

    procedure InsertData(CurrencyCode: Code[10]; NominalValue: Decimal)
    var
        CurrencyNominalValueCZP: Record "Currency Nominal Value CZP";
    begin
        CurrencyNominalValueCZP.Init();
        CurrencyNominalValueCZP."Currency Code" := CurrencyCode;
        CurrencyNominalValueCZP."Nominal Value" := NominalValue;
        CurrencyNominalValueCZP.Insert();
    end;
}