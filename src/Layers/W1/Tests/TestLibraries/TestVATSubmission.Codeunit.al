codeunit 132443 "Test VAT Submission"
{
    TableNo = "VAT Report Header";

    trigger OnRun()
    var
        LibraryUtility: Codeunit "Library - Utility";
    begin
        "Message Id" := LibraryUtility.GenerateGUID();
        Status := Status::Submitted;
        Modify(true);
    end;
}