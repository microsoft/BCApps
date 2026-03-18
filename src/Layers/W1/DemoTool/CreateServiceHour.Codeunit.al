codeunit 117011 "Create Service Hour"
{

    trigger OnRun()
    begin
        InsertData(ServiceHour."Service Contract Type"::" ", '', ServiceHour.Day::Monday, 0D, 080000T, 170000T, false);
        InsertData(ServiceHour."Service Contract Type"::" ", '', ServiceHour.Day::Tuesday, 0D, 080000T, 170000T, false);
        InsertData(ServiceHour."Service Contract Type"::" ", '', ServiceHour.Day::Wednesday, 0D, 080000T, 170000T, false);
        InsertData(ServiceHour."Service Contract Type"::" ", '', ServiceHour.Day::Thursday, 0D, 080000T, 170000T, false);
        InsertData(ServiceHour."Service Contract Type"::" ", '', ServiceHour.Day::Friday, 0D, 080000T, 170000T, false);
    end;

    var
        ServiceHour: Record "Service Hour";

    procedure InsertData("Service Contract Type": Enum "Service Hour Contract Type"; "Service Contract No.": Text[250]; Day: Option; "Starting Date": Date; "Starting Time": Time; "Ending Time": Time; "Valid on Holidays": Boolean)
    begin
        ServiceHour.Init();
        ServiceHour.Validate("Service Contract Type", "Service Contract Type");
        ServiceHour.Validate("Service Contract No.", "Service Contract No.");
        ServiceHour.Validate(Day, Day);
        ServiceHour.Validate("Starting Date", "Starting Date");
        ServiceHour.Validate("Starting Time", "Starting Time");
        ServiceHour.Validate("Ending Time", "Ending Time");
        ServiceHour.Validate("Valid on Holidays", "Valid on Holidays");
        ServiceHour.Insert(true);
    end;
}

