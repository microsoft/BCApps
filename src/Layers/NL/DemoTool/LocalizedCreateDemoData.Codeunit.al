codeunit 101903 "Localized Create Demo Data"
{

    trigger OnRun()
    begin
    end;

    procedure CreateDataBeforeActions()
    begin
    end;

    procedure CreateDataAfterActions()
    var
        DemoDataSetup: Record "Demo Data Setup";
    begin
        DemoDataSetup.Get();
        if DemoDataSetup."Data Type" <> DemoDataSetup."Data Type"::O365 then
            CODEUNIT.Run(CODEUNIT::"Create Local Funct. Demo Data");
    end;

    procedure CreateEvaluationData()
    begin
    end;

    procedure CreateExtendedData()
    begin
    end;
}

