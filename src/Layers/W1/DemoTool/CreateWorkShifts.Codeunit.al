codeunit 119010 "Create Work Shifts"
{

    trigger OnRun()
    begin
        InsertData('1', X1stshift);
        InsertData('2', X2ndshift);
    end;

    var
        X1stshift: Label '1st shift';
        X2ndshift: Label '2nd shift';

    procedure InsertData("Code": Code[10]; Description: Text[50])
    var
        WorkShift: Record "Work Shift";
    begin
        WorkShift.Validate(Code, Code);
        WorkShift.Validate(Description, Description);
        WorkShift.Insert();
    end;
}

