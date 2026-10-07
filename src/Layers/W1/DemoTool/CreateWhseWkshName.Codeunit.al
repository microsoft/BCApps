codeunit 118830 "Create Whse. Wksh.-Name"
{

    trigger OnRun()
    begin
        InsertData(XPUTAWAY, XYELLOW);
        InsertData(XPUTAWAY, XGREEN);
        InsertData(XPUTAWAY, XWHITE);
        InsertData(XPUTAWAY, XSILVER);

        InsertData(XPICK, XYELLOW);
        InsertData(XPICK, XGREEN);
        InsertData(XPICK, XWHITE);
        InsertData(XPICK, XSILVER);

        InsertData(XMOVEMENT, XWHITE);
    end;

    var
        WhseWkshName: Record "Whse. Worksheet Name";
        Text000: Label 'DEFAULT';
        Text001: Label 'Default Journal';
        XPUTAWAY: Label 'PUT-AWAY';
        XYELLOW: Label 'YELLOW';
        XGREEN: Label 'GREEN';
        XWHITE: Label 'WHITE';
        XSILVER: Label 'SILVER';
        XPICK: Label 'PICK';
        XMOVEMENT: Label 'MOVEMENT';

    procedure InsertData(WkshTemplateName: Code[10]; LocationCode: Code[10])
    begin
        WhseWkshName.Init();
        WhseWkshName.Validate("Worksheet Template Name", WkshTemplateName);
        WhseWkshName.Validate(Name, Text000);
        WhseWkshName.Validate("Location Code", LocationCode);
        WhseWkshName.Validate(Description, Text001);
        WhseWkshName.Insert(true);
    end;
}

