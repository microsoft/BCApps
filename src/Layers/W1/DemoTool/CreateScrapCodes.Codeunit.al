codeunit 119018 "Create Scrap Codes"
{

    trigger OnRun()
    begin
    end;

    procedure InserData("Code": Code[10]; Description: Text[50])
    var
        Scrap: Record Scrap;
    begin
        Scrap.Validate(Code, Code);
        Scrap.Validate(Description, Description);
        Scrap.Insert();
    end;
}

