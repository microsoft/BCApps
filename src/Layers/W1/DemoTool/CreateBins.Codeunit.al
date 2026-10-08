codeunit 119003 "Create Bins"
{

    trigger OnRun()
    begin
        InsertData(XBLUE, 'A1', XPlaceA1);
    end;

    var
        Bin: Record Bin;
        XBLUE: Label 'BLUE';
        XPlaceA1: Label 'Place A1';

    procedure InsertData(LocationCode: Code[10]; BinCode: Code[20]; Description: Text[30])
    begin
        Bin.Validate("Location Code", LocationCode);
        Bin.Validate(Code, BinCode);
        Bin.Validate(Description, Description);
        Bin.Insert();
    end;
}

