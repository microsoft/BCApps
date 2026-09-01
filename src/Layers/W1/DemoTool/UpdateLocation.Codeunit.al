codeunit 118014 "Update Location"
{

    trigger OnRun()
    begin
        ModifyData(XYELLOW, true, true, true, true, false, false, 0, false, '', '', '', '', '', '', '', '', "Location Default Bin Selection"::" ", '', '');
        ModifyData(XGREEN, true, true, true, true, false, false, 0, false, '', '', '', '', '', '', '', '', "Location Default Bin Selection"::" ", '', '');
        ModifyData(
          XWHITE, true, true, true, true, true, true, 2, true, XW110001, XSTD,
          XW080001, XW090001, XW070001, XW070002, XW070003, XW140001, "Location Default Bin Selection"::" ", XW070002, XW070003);

        ModifyData(XSILVER, false, false, false, false, true, false, 0, false, '', '', '', '', '', '', '', '', "Location Default Bin Selection"::"Fixed Bin", '', '');
    end;

    var
        Location: Record Location;
        XYELLOW: Label 'YELLOW';
        XGREEN: Label 'GREEN';
        XWHITE: Label 'WHITE';
        XSILVER: Label 'SILVER';
        XW110001: Label 'W-11-0001';
        XSTD: Label 'STD';
        XW080001: Label 'W-08-0001';
        XW090001: Label 'W-09-0001';
        XW070001: Label 'W-07-0001';
        XW070002: Label 'W-07-0002';
        XW070003: Label 'W-07-0003';
        XW140001: Label 'W-14-0001';

    procedure ModifyData("Location Code": Code[10]; RequirePutAway: Boolean; RequirePick: Boolean; UseReceive: Boolean; UseShipment: Boolean; UseBins: Boolean; UseWMS: Boolean; CheckBinCapacity: Option Never,"Allow excess","Prohibit excess"; AllowBreakBulk: Boolean; AdjmtBinCode: Code[20]; PutAwayTemplCode: Code[10]; ReceiptBinCode: Code[20]; ShipmentBinCode: Code[20]; OpenShopFloorBinCode: Code[20]; InbProdBinCode: Code[20]; OutbProdBinCode: Code[20]; CrossDockBinCode: Code[10]; DefaultBinSelection: Enum "Location Default Bin Selection"; InbAsmBinCode: Code[20]; OutbAsmBinCode: Code[20])
    begin
        Location.Get("Location Code");
        Location.Validate("Require Put-away", RequirePutAway);
        Location.Validate("Require Pick", RequirePick);
        Location.Validate("Require Receive", UseReceive);
        Location.Validate("Require Shipment", UseShipment);
        Location.Validate("Bin Mandatory", UseBins);
        Location.Validate("Directed Put-away and Pick", UseWMS);
        Location.Modify();
        Location.Validate("Bin Capacity Policy", CheckBinCapacity);
        Location.Validate("Allow Breakbulk", AllowBreakBulk);
        Location.Validate("Adjustment Bin Code", AdjmtBinCode);
        Location.Validate("Put-away Template Code", PutAwayTemplCode);
        Location.Validate("Receipt Bin Code", ReceiptBinCode);
        Location.Validate("Shipment Bin Code", ShipmentBinCode);
        Location.Validate("Open Shop Floor Bin Code", OpenShopFloorBinCode);
        Location.Validate("To-Production Bin Code", InbProdBinCode);
        Location.Validate("From-Production Bin Code", OutbProdBinCode);
        Location.Validate("To-Assembly Bin Code", InbAsmBinCode);
        Location.Validate("From-Assembly Bin Code", OutbAsmBinCode);
        Location.Validate("Cross-Dock Bin Code", CrossDockBinCode);
        Location."Default Bin Selection" := DefaultBinSelection;
        Location.Modify();
    end;
}

