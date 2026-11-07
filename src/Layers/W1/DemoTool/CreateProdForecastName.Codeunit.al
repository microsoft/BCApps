codeunit 119063 "Create Prod. Forecast Name"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        InsertData(Format(DemoDataSetup."Starting Year" + 1));
        InsertData(Format(DemoDataSetup."Starting Year" + 2));
    end;

    var
        ProductionForecastName: Record "Production Forecast Name";
        XForecast: Label 'Forecast';
        Text000: Label '%1 %2';
        DemoDataSetup: Record "Demo Data Setup";

    procedure InsertData(Name: Code[10])
    begin
        ProductionForecastName.Init();
        ProductionForecastName.Validate(Name, Name);
        ProductionForecastName.Validate(Description, StrSubstNo(Text000, Name, XForecast));
        ProductionForecastName.Insert();
    end;
}

