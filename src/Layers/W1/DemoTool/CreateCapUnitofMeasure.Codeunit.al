codeunit 119015 "Create Cap. Unit of Measure"
{

    trigger OnRun()
    begin
        InsertData(XMINUTES, XMinuteslc, 2);
        InsertData(XHOURS, XHourslc, 3);
        InsertData(XDAYS, XDayslc, 4);
    end;

    var
        CapUnitOfMeasure: Record "Capacity Unit of Measure";
        XMINUTES: Label 'MINUTES';
        XMinuteslc: Label 'Minutes';
        XHourslc: Label 'Hours';
        XHOURS: Label 'HOURS';
        XDAYS: Label 'DAYS';
        XDayslc: Label 'Days';

    procedure InsertData("Code": Text[10]; Description: Text[50]; Type: Option " ","100/Minutes",Minutes,Hours,Days)
    begin
        CapUnitOfMeasure.Validate(Code, Code);
        CapUnitOfMeasure.Validate(Description, Description);
        CapUnitOfMeasure.Validate(Type, Type);
        CapUnitOfMeasure.Insert();
    end;
}

