codeunit 101805 "Create FA Subclass"
{

    trigger OnRun()
    begin
        InsertData(XCAR, XCarlc, XTANGIBLE);
        InsertData(XMACHINERY, XMachinerylc, XTANGIBLE);
        InsertData(XTELEPHONE, XTelephoneEquipment, XTANGIBLE);
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
        XPLANT: Label 'PLANT';
        XPlantlc: Label 'Plants/Buildings';
        XPROPERTY: Label 'PROPERTY';
        XPropertylc: Label 'Property/Land';
        XVEHICLES: Label 'VEHICLES';
        XVehicleslc: Label 'Vehicles';
        XFURNITUREFIXTURES: Label 'FURNITURE';
        XFurnitureFixtureslc: Label 'Furniture & Fixtures';
        XIP: Label 'IP';
        XIPlc: Label 'Intellectual Property';
        XTANGIBLE: Label 'TANGIBLE';
        XINTANGIBLE: Label 'INTANGIBLE';
        XFINANCIAL: Label 'FINANCIAL';
        XLEASEHOLD: Label 'LEASEHOLD';
        XLEASEHOLDlc: Label 'Leasehold';

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
        InsertData(XPLANT, XPlantlc, XTANGIBLE);
        InsertData(XPROPERTY, XPropertylc, XTANGIBLE);
        InsertData(XVEHICLES, XVehicleslc, XTANGIBLE);
        InsertData(XFURNITUREFIXTURES, XFurnitureFixtureslc, XTANGIBLE);
        InsertData(XIP, XIPlc, XINTANGIBLE);
        InsertData(XLEASEHOLD, XLEASEHOLDlc, XFINANCIAL);
    end;
}

