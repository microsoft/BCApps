codeunit 119017 "Create Stop Codes"
{

    trigger OnRun()
    begin
    end;

    procedure InserData("Code": Code[10]; Description: Text[50])
    var
        Stop: Record Stop;
    begin
        Stop.Validate(Code, Code);
        Stop.Validate(Description, Description);
        Stop.Insert();
    end;
}

