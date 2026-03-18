codeunit 101605 "Create Causes of Absence"
{

    trigger OnRun()
    begin
        InsertData(XSICK, XSicklc, XHOUR);
        InsertData(XDAYOFF, XDayOfflc, XHOUR);
        InsertData(XHOLIDAY, XHolidaylc, XDAY);
    end;

    var
        "Cause of Absence": Record "Cause of Absence";
        XSICK: Label 'SICK';
        XSicklc: Label 'Sick';
        XHOUR: Label 'HOUR';
        XDAYOFF: Label 'DAYOFF';
        XDayOfflc: Label 'Day Off';
        XHOLIDAY: Label 'HOLIDAY';
        XHolidaylc: Label 'Holiday';
        XDAY: Label 'DAY';

    procedure InsertData("Code": Code[10]; Description: Text[30]; "Unit of Measure Code": Text[10])
    begin
        "Cause of Absence".Init();
        "Cause of Absence".Code := Code;
        "Cause of Absence".Description := Description;
        "Cause of Absence".Validate("Unit of Measure Code", "Unit of Measure Code");
        "Cause of Absence".Insert();
    end;
}

