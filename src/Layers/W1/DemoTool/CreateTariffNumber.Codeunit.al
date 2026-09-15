codeunit 101260 "Create Tariff Number"
{

    trigger OnRun()
    var
        DemoDataSetup: Record "Demo Data Setup";
    begin
        DemoDataSetup.Get();

        if DemoDataSetup."Data Type" <> DemoDataSetup."Data Type"::O365 then begin
            InsertData('9401 30 10', XSwivelchairsupholstered);
            InsertData('9401 71 00', XOtherchairsupholstered);
            InsertData('9403 30 11', XDesks);
            InsertData('9403 30 19', XOtherofficefurniture);
            InsertData('9403 30 91', XClosetswithdoordrawers);
            InsertData('9403 90 10', XFurnituremetalparts);
            InsertData('9403 90 30', XFurniturewoodenparts);
            InsertData('9403 90 90', XFurnitureotherparts);
            InsertData('9405 20 99', XDesklamps);
            InsertData('9999 99 99', XPaint);
        end;

        InsertData('9950 00 00', XSmallTransaction);
    end;

    var
        "Tariff Number": Record "Tariff Number";
        XSwivelchairsupholstered: Label 'Swivel chairs, upholstered';
        XOtherchairsupholstered: Label 'Other chairs, upholstered';
        XDesks: Label 'Desks';
        XOtherofficefurniture: Label 'Other office furniture';
        XClosetswithdoordrawers: Label 'Closets with door/drawers';
        XFurnituremetalparts: Label 'Furniture, metal parts';
        XFurniturewoodenparts: Label 'Furniture, wooden parts';
        XFurnitureotherparts: Label 'Furniture, other parts';
        XDesklamps: Label 'Desk lamps';
        XPaint: Label 'Paint';
        XSmallTransaction: Label 'Small Transaction Grouping';

    procedure InsertData("No.": Code[10]; Description: Text[50])
    begin
        "Tariff Number".Init();
        "Tariff Number".Validate("No.", "No.");
        "Tariff Number".Validate(Description, Description);
        "Tariff Number".Insert();
    end;
}

