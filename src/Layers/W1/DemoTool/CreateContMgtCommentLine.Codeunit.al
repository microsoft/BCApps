codeunit 101561 "Create Cont. Mgt. Comment Line"
{

    trigger OnRun()
    begin
    end;

    var
        "Cont. Mgt Comment Line": Record "Rlshp. Mgt. Comment Line";

    procedure InsertData("Table Name": Option; "No.": Code[20]; "Sub No.": Integer; "Line No.": Integer; Date: Date; "Code": Code[10]; Comment: Text[80]; "Last Date Modified": Date)
    begin
        "Cont. Mgt Comment Line".Init();
        "Cont. Mgt Comment Line".Validate("Table Name", "Table Name");
        "Cont. Mgt Comment Line".Validate("No.", "No.");
        "Cont. Mgt Comment Line".Validate("Sub No.", "Sub No.");
        "Cont. Mgt Comment Line".Validate("Line No.", "Line No.");
        "Cont. Mgt Comment Line".Validate(Date, Date);
        "Cont. Mgt Comment Line".Validate(Code, Code);
        "Cont. Mgt Comment Line".Validate(Comment, Comment);
        "Cont. Mgt Comment Line".Validate("Last Date Modified", "Last Date Modified");
        "Cont. Mgt Comment Line".Insert();
    end;
}

