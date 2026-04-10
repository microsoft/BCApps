codeunit 132461 "Job Queue Sleep 1s"
{
    TableNo = "Job Queue Entry";

    trigger OnRun()
    begin
        Sleep(1000);
    end;
}