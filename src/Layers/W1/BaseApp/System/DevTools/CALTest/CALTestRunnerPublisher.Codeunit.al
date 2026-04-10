namespace System.TestTools.TestRunner;

codeunit 130403 "CAL Test Runner Publisher"
{

    trigger OnRun()
    begin
    end;

    procedure SetSeed(NewSeed: Integer)
    begin
        OnSetSeed(NewSeed);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetSeed(NewSeed: Integer)
    begin
    end;
}

