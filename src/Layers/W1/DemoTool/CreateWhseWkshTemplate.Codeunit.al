codeunit 118829 "Create Whse. Wksh.-Template"
{

    trigger OnRun()
    begin
        InsertData(XPICK, XPickWorksheet, WhseWkshTemplate.Type::Pick);
        InsertData(XPUTAWAY, XPutawayWorksheet, WhseWkshTemplate.Type::"Put-away");
        InsertData(XMOVEMENT, XMovementWorksheet, WhseWkshTemplate.Type::Movement);
    end;

    var
        WhseWkshTemplate: Record "Whse. Worksheet Template";
        XPICK: Label 'PICK';
        XPickWorksheet: Label 'Pick Worksheet';
        XPUTAWAY: Label 'PUT-AWAY';
        XPutawayWorksheet: Label 'Put-away Worksheet';
        XMOVEMENT: Label 'MOVEMENT';
        XMovementWorksheet: Label 'Movement Worksheet';

    procedure InsertData(Name: Code[10]; Description: Text[80]; Type: Enum "Warehouse Worksheet Template Type")
    begin
        WhseWkshTemplate.Init();
        WhseWkshTemplate.Validate(Name, Name);
        WhseWkshTemplate.Validate(Description, Description);
        WhseWkshTemplate.Insert(true);
        WhseWkshTemplate.Validate(Type, Type);
        WhseWkshTemplate.Modify();
    end;
}

