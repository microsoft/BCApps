codeunit 131338 "ERM PE Empty Source Test mock"
{
    SingleInstance = true;
    TableNo = "Data Exch.";

    trigger OnRun()
    begin
        Init();
    end;
}

