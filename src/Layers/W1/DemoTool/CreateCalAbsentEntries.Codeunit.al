codeunit 119021 "Create Cal. Absent. Entries"
{

    trigger OnRun()
    begin
    end;

    procedure InsertData(SourceType: Option "Work Center","Machine Center"; No: Code[20]; Date: Date; StartingTime: Time; EndingTime: Time; Description: Text[30])
    var
        CalAbsentEntry: Record "Calendar Absence Entry";
    begin
        CalAbsentEntry.Validate("Capacity Type", SourceType);
        CalAbsentEntry.Validate("No.", No);
        CalAbsentEntry.Validate(Date, Date);
        CalAbsentEntry.Validate("Starting Time", StartingTime);
        CalAbsentEntry.Validate("Ending Time", EndingTime);
        CalAbsentEntry.Validate(Description, Description);
        CalAbsentEntry.Insert();
    end;
}

