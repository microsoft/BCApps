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
        XKG: Label 'KG';
        XG: Label 'G';
        XPCS: Label 'PCS';

    procedure InsertData("No.": Code[10]; Description: Text[50])
    begin
        "Tariff Number".Init();
        "Tariff Number".Validate("No.", "No.");
        "Tariff Number".Validate(Description, Description);
        "Tariff Number".Insert();
    end;

    procedure InsertData("No.": Code[10]; Description: Text[50]; StatementCode: Code[10]; StatementLimitCode: Code[10]; VATStatUnitOfMeasCode: Code[10])
    begin
        // NAVCZ
        "Tariff Number".Init();
        "Tariff Number".Validate("No.", "No.");
        "Tariff Number".Validate(Description, Description);
        "Tariff Number"."Statement Code CZL" := StatementCode;
        "Tariff Number"."Statement Limit Code CZL" := StatementLimitCode;
        "Tariff Number"."VAT Stat. UoM Code CZL" := VATStatUnitOfMeasCode;
        "Tariff Number"."Allow Empty UoM Code CZL" := true;
        "Tariff Number".Insert();
    end;

    procedure InsertMiniAppData()
    begin
        // NAVCZ 
        InsertData('001', '§92b - dodání zlata', '1', '0', XG);
        InsertData('004', '§92e - poskytnutí stavebních nebo montážních prací', '4', '0', '');
        InsertData('005', '§92c - zboží uvedené v příloze č.5 zákona', '5', '0', XKG);
        InsertData('011', '§92f - povolenky na emise', '11', '0', XPCS);
        InsertData('012', '§92f - obiloviny a technické plodiny', '12', '12', XKG);
        InsertData('013', '§92f - kovy', '13', '13', XKG);
        InsertData('014', '§92f - mobilní telefony', '14', '14', XPCS);
        InsertData('015', '§92f - integrované obvody', '15', '15', XPCS);
        InsertData('016', '§92f - přenos. zařízení pro aut. zprac. dat', '16', '16', XPCS);
        InsertData('017', '§92f - videoherní konzole', '17', '17', XPCS);
    end;
}

