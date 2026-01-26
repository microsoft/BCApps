codeunit 101200 "Create Work Type"
{

    trigger OnRun()
    begin
        // NAVCZ
        InsertData(XKM, XKilometer, XKM);
        InsertData(XHOUR, XHour2, XHOUR);
        // NAVCZ
    end;

    var
        WorkType: Record "Work Type";
        XKilometer: Label 'Kilometer';
        XKM: Label 'KM';
        XHOUR: Label 'HOUR';
        XHour2: Label 'Hour';

    procedure InsertData("Code": Code[10]; Description: Text[30]; UnitOfMeasure: Code[20])
    begin
        WorkType.Init();
        WorkType.Validate(Code, Code);
        WorkType.Validate(Description, Description);
        WorkType.Validate("Unit of Measure Code", UnitOfMeasure);
        WorkType.Insert();
    end;
}

