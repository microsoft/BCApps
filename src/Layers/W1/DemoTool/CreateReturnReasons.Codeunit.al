codeunit 101852 "Create Return Reasons"
{

    trigger OnRun()
    begin
        DemoSetup.Get();
        InsertData(XDAMAGED, XDamagedinShipment, '', false);
        InsertData(XDEFECTIVE, XDefectiveItem, '', false);
        InsertData(XNONEED, XNoCurrentNeed, '', false);
        InsertData(XPREPAIR, XRepairPurchasedItem, '', false);
        InsertData(XSREPAIR, XRepairSoldItem, '', true);
        InsertData(XWRONG, XWrongItem, '', false);
    end;

    var
        DemoSetup: Record "Demo Data Setup";
        XDAMAGED: Label 'DAMAGED';
        XDamagedinShipment: Label 'Damaged in Shipment';
        XDEFECTIVE: Label 'DEFECTIVE';
        XDefectiveItem: Label 'Defective Item';
        XNONEED: Label 'NONEED';
        XNoCurrentNeed: Label 'No Current Need';
        XPREPAIR: Label 'P-REPAIR';
        XRepairPurchasedItem: Label 'Repair Purchased Item';
        XSREPAIR: Label 'S-REPAIR';
        XRepairSoldItem: Label 'Repair Sold Item';
        XWRONG: Label 'WRONG';
        XWrongItem: Label 'Wrong Item';

    procedure InsertData(ReturnReasonCode: Code[20]; Description: Text[50]; DefaultLocationCode: Code[10]; InvtValueZero: Boolean)
    var
        ReturnReason: Record "Return Reason";
    begin
        ReturnReason.Init();
        ReturnReason.Code := ReturnReasonCode;
        ReturnReason.Description := Description;
        ReturnReason."Default Location Code" := DefaultLocationCode;
        ReturnReason."Inventory Value Zero" := InvtValueZero;
        ReturnReason.Insert();
    end;
}

