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
    begin
        CODEUNIT.Run(CODEUNIT::"Create Demodata ESR");
        CODEUNIT.Run(CODEUNIT::"Create Demodata LSV");
        CODEUNIT.Run(CODEUNIT::"Create CH VAT Cipher Setup");
    end;

    procedure CreateExtendedData()
    begin
        CODEUNIT.Run(CODEUNIT::"Create Demodata ESR");
        CODEUNIT.Run(CODEUNIT::"Create Demodata GlForeign Curr");
        CODEUNIT.Run(CODEUNIT::"Create Demodata DTA");
        CODEUNIT.Run(CODEUNIT::"Create Demodata Offers");
        CODEUNIT.Run(CODEUNIT::"Create Demodata LSV");
        CODEUNIT.Run(CODEUNIT::"Create CH VAT Cipher Setup");
    end;
}

