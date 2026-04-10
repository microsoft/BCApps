namespace System.Test.Tooling;

codeunit 149133 "BCPT Sleep 1s and Error"
{
    trigger OnRun()
    begin
        Sleep(1000);
        error('something happened')
    end;

}