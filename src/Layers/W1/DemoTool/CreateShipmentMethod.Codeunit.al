codeunit 101010 "Create Shipment Method"
{

    trigger OnRun()
    begin
        InsertData(XCFR, XCostandFreight);
        InsertData(XCIF, XCostInsuranceandFreight);
        InsertData(XCIP, XCarriageandInsurancePaid);
        InsertData(XCPT, XCarriagePaidto);
        InsertData(XDAF, XDeliveredatFrontier);
        InsertData(XDDP, XDeliveredDutyPaid);
        InsertData(XDDU, XDeliveredDutyUnpaid);
        InsertData(XDELIVERY, XDELIVERY);
        InsertData(XDEQ, XDeliveredexQuay);
        InsertData(XDES, XDeliveredexShip);
        InsertData(XEXW, XExWarehouse);
        InsertData(XFAS, XFreeAlongsideShip);
        InsertData(XFCA, XFreeCarrier);
        InsertData(XFOB, XFreeonBoard);
        InsertData(XPICKUP, XPickupatLocation);
    end;

    var
        "Shipment Method": Record "Shipment Method";
        XCFR: Label 'CFR';
        XCostandFreight: Label 'Cost and Freight';
        XCIF: Label 'CIF';
        XCostInsuranceandFreight: Label 'Cost Insurance and Freight';
        XCIP: Label 'CIP';
        XCarriageandInsurancePaid: Label 'Carriage and Insurance Paid';
        XCPT: Label 'CPT';
        XCarriagePaidto: Label 'Carriage Paid to';
        XDAF: Label 'DAF';
        XDeliveredatFrontier: Label 'Delivered at Frontier';
        XDDP: Label 'DDP';
        XDeliveredDutyPaid: Label 'Delivered Duty Paid';
        XDDU: Label 'DDU';
        XDeliveredDutyUnpaid: Label 'Delivered Duty Unpaid';
        XDELIVERY: Label 'DELIVERY';
        XDEQ: Label 'DEQ';
        XDeliveredexQuay: Label 'Delivered ex Quay';
        XDES: Label 'DES';
        XEXW: Label 'EXW';
        XExWarehouse: Label 'Ex Warehouse';
        XFAS: Label 'FAS';
        XFreeAlongsideShip: Label 'Free Alongside Ship';
        XFCA: Label 'FCA';
        XFreeCarrier: Label 'Free Carrier';
        XFOB: Label 'FOB';
        XFreeonBoard: Label 'Free on Board';
        XPICKUP: Label 'PICKUP';
        XPickupatLocation: Label 'Pickup at Location';
        XDeliveredexShip: Label 'Delivered ex Ship';

    procedure InsertData("Code": Code[10]; Description: Text[50])
    begin
        "Shipment Method".Init();
        "Shipment Method".Validate(Code, Code);
        "Shipment Method".Validate(Description, Description);
        "Shipment Method".Insert();
    end;
}

