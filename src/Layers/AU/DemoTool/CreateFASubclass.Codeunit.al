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
        XEQUIPMENT: Label 'EQUIPMENT';
        XEquipmentlc: Label 'Equipment';
        XVEHICLES: Label 'VEHICLES';
        XVehicleslc: Label 'Vehicles';
        XTANGIBLE: Label 'TANGIBLE';
        XINTANGIBLE: Label 'INTANGIBLE';
        XBuilding: Label 'BUILDING';
        XBuildinglc: Label 'Building';

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
        InsertData(XEQUIPMENT, XEquipmentlc, XTANGIBLE);
        InsertData(XBuilding, XBuildinglc, XINTANGIBLE);
        InsertData(XVEHICLES, XVehicleslc, XTANGIBLE);
    end;
}

