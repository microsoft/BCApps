namespace System.Diagnostics;

codeunit 510 "Change Log Entry - Delete"
{
    Access = Internal;
    Permissions = TableData "Change Log Entry" = rd;
    TableNo = "Change Log Entry";

    trigger OnRun()
    begin
        Rec.SetRange("Field Log Entry Feature", "Field Log Entry Feature"::"Change Log");
        Rec.SetRange(Protected, true);
        Rec.Delete(); // do not call trigger as that will fail for protected entries
    end;
}
