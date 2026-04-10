codeunit 101805 "Create FA Subclass"
{

    trigger OnRun()
    begin
        InsertData(XCAR, XCarlc, '');
        InsertData(XMACHINERY, XMachinerylc, '');
        InsertData(XTELEPHONE, XTelephoneEquipment, '');

        InsertData(XESTATE, XRealEstate, '');
        InsertData(XSOFTWARE, XSoftwarelc, '');
        InsertData(XBUILDING, XBuildings, '');
    end;

    var
        "FA Subclass": Record "FA Subclass";
        XCAR: Label 'CAR';
        XCarlc: Label 'Car';
        XMACHINERY: Label 'MACHINERY';
        XMachinerylc: Label 'Machinery';
        XTELEPHONE: Label 'TELEPHONE';
        XTelephoneEquipment: Label 'Telephone Equipment';
        XESTATE: Label 'ESTATE';
        XRealEstate: Label 'Real Estate';
        XSOFTWARE: Label 'SOFTWARE';
        XSoftwarelc: Label 'Software';
        XBUILDING: Label 'BUILDING';
        XBuildings: Label 'Buildings';
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
        XLEASEHOLD: Label 'LEASEHOLD';
        XLEASEHOLDlc: Label 'Leasehold';

    procedure InsertData("Code": Code[10]; Name: Text[50]; ClassCode: Code[10])
    begin
        "FA Subclass".Init();
        "FA Subclass".Validate(Code, Code);
        "FA Subclass".Validate(Name, Name);
        "FA Subclass".Validate("FA Class Code", ClassCode);
        "FA Subclass".Insert();
    end;

    procedure CreateTrialData()
    begin
        InsertData(XPATENTS, XPatentslc, '');
        InsertData(XGOODWILL, XGoodwilllc, '');
        InsertData(XEQUIPMENT, XEquipmentlc, '');
        InsertData(XPLANT, XPlantlc, '');
        InsertData(XPROPERTY, XPropertylc, '');
        InsertData(XVEHICLES, XVehicleslc, '');
        InsertData(XFURNITUREFIXTURES, XFurnitureFixtureslc, '');
        InsertData(XIP, XIPlc, '');
        InsertData(XLEASEHOLD, XLEASEHOLDlc, '');
    end;
}

