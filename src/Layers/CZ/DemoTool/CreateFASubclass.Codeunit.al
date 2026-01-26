codeunit 101805 "Create FA Subclass"
{

    trigger OnRun()
    begin
        InsertData(XCAR, XCarlc, XTANGIBLE);
        InsertData(XMACHINERY, XMachinerylc, XTANGIBLE);
        InsertData(XTELEPHONE, XTelephoneEquipment, XTANGIBLE);
        InsertData(XBUILDING, XBuildingTxt, XTANGIBLE); // NAVCZ
    end;

    var
        "FA Subclass": Record "FA Subclass";
        XCAR: Label 'CAR';
        XCarlc: Label 'Car';
        XMACHINERY: Label 'MACHINERY';
        XMachinerylc: Label 'Machinery';
        XTELEPHONE: Label 'TELEPHONE';
        XTelephoneEquipment: Label 'Telephone Equipment';
        XPATENTS: Label 'PATENTS';
        XPatentslc: Label 'Patents';
        XGOODWILL: Label 'GOODWILL';
        XGoodwilllc: Label 'Goodwill';
        XEQUIPMENT: Label 'EQUIPMENT';
        XEquipmentlc: Label 'Equipment';
        XVEHICLES: Label 'VEHICLES';
        XVehicleslc: Label 'Vehicles';
        XFURNITUREFIXTURES: Label 'FURNITURE';
        XFurnitureFixtureslc: Label 'Furniture & Fixtures';
        XTANGIBLE: Label 'TANGIBLE';
        XINTANGIBLE: Label 'INTANGIBLE';
        XBUILDING: Label 'BUILDING';
        XBuildingTxt: Label 'Building';

    procedure InsertData("Code": Code[10]; Name: Text[50]; ClassCode: Code[10])
    begin
        "FA Subclass".Init();
        "FA Subclass".Validate(Code, Code);
        "FA Subclass".Validate(Name, Name);
        "FA Subclass".Validate("FA Class Code", ClassCode);
        "FA Subclass".Validate("Default FA Posting Group", Code);
        "FA Subclass".Insert();
    end;

    procedure CreateTrialData()
    begin
        InsertData(XPATENTS, XPatentslc, XINTANGIBLE);
        InsertData(XGOODWILL, XGoodwilllc, XINTANGIBLE);
        InsertData(XEQUIPMENT, XEquipmentlc, XTANGIBLE);
        InsertData(XVEHICLES, XVehicleslc, XTANGIBLE);
        InsertData(XFURNITUREFIXTURES, XFurnitureFixtureslc, XTANGIBLE);
    end;
}

