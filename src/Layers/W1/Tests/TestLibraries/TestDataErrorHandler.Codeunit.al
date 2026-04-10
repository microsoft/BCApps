codeunit 130151 "Test Data Error Handler"
{
    TableNo = "Generate Test Data Line";

    trigger OnRun()
    begin
        LockTable();
        if Get("Table ID") then begin
            Status := Status::Incomplete;
            "Last Error Message" := CopyStr(GetLastErrorText, 1, MaxStrLen("Last Error Message"));
            Modify();
        end;
    end;
}

