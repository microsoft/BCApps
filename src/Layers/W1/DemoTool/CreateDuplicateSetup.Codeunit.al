codeunit 101595 "Create Duplicate Setup"
{

    trigger OnRun()
    begin
        InsertData(2, 0, 5);
        InsertData(2, 1, 5);
        InsertData(5, 0, 5);
        InsertData(5, 1, 5);
        InsertData(91, 0, 5);
        InsertData(91, 1, 5);
        InsertData(7, 0, 5);
        InsertData(7, 1, 5);
        InsertData(9, 0, 5);
        InsertData(9, 1, 5);
        InsertData(102, 0, 5);
        InsertData(102, 1, 5);
        InsertData(5061, 0, 5);
        InsertData(5061, 1, 5);
        InsertData(86, 0, 5);
        InsertData(86, 1, 5);
    end;

    var
        "Duplicate Setup": Record "Duplicate Search String Setup";

    procedure InsertData("Field": Option; "Part": Option; Length: Integer)
    begin
        "Duplicate Setup".Init();
        "Duplicate Setup".Validate("Field No.", Field);
        "Duplicate Setup".Validate("Part of Field", Part);
        "Duplicate Setup".Validate(Length, Length);
        "Duplicate Setup".Insert();
    end;
}

