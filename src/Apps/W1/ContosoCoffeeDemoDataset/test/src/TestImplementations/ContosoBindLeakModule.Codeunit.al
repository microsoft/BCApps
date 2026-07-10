namespace Microsoft.Test.DemoTool;

using Microsoft.DemoTool;

codeunit 148140 "Contoso Bind Leak Module" implements "Contoso Demo Data Module"
{
    var
        GenerateFailedErr: Label 'Contoso Bind Leak Module generation failed on purpose.';

    procedure RunConfigurationPage();
    begin

    end;

    procedure GetDependencies(): List of [enum "Contoso Demo Data Module"]
    begin

    end;

    procedure CreateSetupData();
    var
        ContosoBindLeakSubscriber: Codeunit "Contoso Bind Leak Subscriber";
    begin
        if ContosoBindLeakSubscriber.GetFailOnGenerate() then
            Error(GenerateFailedErr);
    end;

    procedure CreateMasterData();
    begin

    end;

    procedure CreateTransactionalData();
    begin

    end;

    procedure CreateHistoricalData();
    begin

    end;
}
