codeunit 101903 "Localized Create Demo Data"
{

    trigger OnRun()
    begin
    end;

    procedure CreateDataBeforeActions()
    begin
    end;

    procedure CreateDataAfterActions()
    begin
    end;

    procedure CreateEvaluationData()
    var
        CreateBASSetup: Codeunit "Create BAS Setup";
    begin
        CreateBASSetup.CreateBASXMLFieldIDSetup();
    end;

    procedure CreateExtendedData()
    begin
        CODEUNIT.Run(CODEUNIT::"Create BAS Setup");
    end;
}

