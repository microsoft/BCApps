namespace System.Test.Tooling;
using System.Threading;

codeunit 149130 "BCPT Sleep X seconds"
{
    TableNo = "Job Queue Entry";

    trigger OnRun();
    var
        NoOfSeconds: Integer;
    begin
        NoOfSeconds := 1;
        if Rec."Parameter String" <> '' then
            if not Evaluate(NoOfSeconds, Rec."Parameter String") then
                NoOfSeconds := 1;
        Sleep(1000 * NoOfSeconds);
    end;
}