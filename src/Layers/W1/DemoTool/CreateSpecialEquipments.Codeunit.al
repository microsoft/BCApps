codeunit 118836 "Create Special Equipments"
{

    trigger OnRun()
    begin
        InsertData(XHT1, XHandtruckone);
        InsertData(XHT2, XHandtrucktwo);
        InsertData(XLIFT, XLiftlc);
    end;

    var
        XHT1: Label 'HT1';
        XHT2: Label 'HT2';
        XHandtruckone: Label 'Hand truck one';
        XHandtrucktwo: Label 'Hand truck two';
        XLIFT: Label 'LIFT';
        XLiftlc: Label 'Lift';

    procedure InsertData("Code": Code[10]; Description: Text[30])
    var
        "Special Equipment": Record "Special Equipment";
    begin
        "Special Equipment".Validate(Code, Code);
        "Special Equipment".Validate(Description, Description);
        "Special Equipment".Insert();
    end;
}

