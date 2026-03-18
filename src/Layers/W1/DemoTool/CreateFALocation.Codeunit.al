codeunit 101806 "Create FA Location"
{

    trigger OnRun()
    begin
        InsertData(XYELLOW, XYellowWarehouse);
        InsertData(XGREEN, XGreenWarehouse);
        InsertData(XBLUE, XBlueWarehouse);
        InsertData(XRED, XRedWarehouse);
        InsertData(XBUILDING2, XMachineryBuilding2);
        InsertData(XRECEPTION, XReceptionlc);
        InsertData(XADM, XAdministration);
        InsertData(XSALES, XSaleslc);
        InsertData(XPROD, XProduction);
    end;

    var
        "FA Location": Record "FA Location";
        XYELLOW: Label 'YELLOW';
        XGREEN: Label 'GREEN';
        XBLUE: Label 'BLUE';
        XRED: Label 'RED';
        XRECEPTION: Label 'RECEPTION';
        XADM: Label 'ADM';
        XSALES: Label 'SALES';
        XPROD: Label 'PROD';
        XYellowWarehouse: Label 'Yellow Warehouse';
        XGreenWarehouse: Label 'Green Warehouse';
        XBlueWarehouse: Label 'Blue Warehouse';
        XRedWarehouse: Label 'Red Warehouse';
        XMachineryBuilding2: Label 'Machinery Building 2';
        XReceptionlc: Label 'Reception';
        XAdministration: Label 'Administration';
        XSaleslc: Label 'Sales';
        XProduction: Label 'Production';
        XAdministrationBuilding1: Label 'Administration, Building 1';
        XBUILDING1: Label 'BUILD_1';
        XBuilding1lc: Label 'Building 1';
        XBUILDING2: Label 'BUILD_2';
        XBuilding2lc: Label 'Building 2';
        XProductionBuilding2: Label 'Production, Building 2';
        XReceptionBuilding1: Label 'Reception, Building 1';
        XSalesBuilding1: Label 'Sales, Building 1';
        XWARE1: Label 'WARE_1';
        XWarehouse1: Label 'Warehouse 1';
        XWARE2: Label 'WARE_2';
        XWarehouse2: Label 'Warehouse 2';

    procedure InsertData("Code": Code[10]; Name: Text[50])
    begin
        "FA Location".Init();
        "FA Location".Validate(Code, Code);
        "FA Location".Validate(Name, Name);
        "FA Location".Insert();
    end;

    procedure CreateTrialData()
    begin
        InsertData(XADM, XAdministrationBuilding1);
        InsertData(XBUILDING1, XBuilding1lc);
        InsertData(XBUILDING2, XBuilding2lc);
        InsertData(XPROD, XProductionBuilding2);
        InsertData(XRECEPTION, XReceptionBuilding1);
        InsertData(XSALES, XSalesBuilding1);
        InsertData(XWARE1, XWarehouse1);
        InsertData(XWARE2, XWarehouse2);
    end;
}

