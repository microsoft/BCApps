codeunit 101010 "Create Shipment Method"
{

    trigger OnRun()
    begin
        InsertData(XCFR, XCostandFreight, InsertTransSpec(XCFR, XCostandFreight));
        InsertData(XCIF, XCostInsuranceandFreight, InsertTransSpec(XCIF, XCostInsuranceandFreight));
        InsertData(XCIP, XCarriageandInsurancePaid, InsertTransSpec(XCIP, XCarriageandInsurancePaid));
        InsertData(XCPT, XCarriagePaidto, InsertTransSpec(XCPT, XCarriagePaidto));
        InsertData(XDAF, XDeliveredatFrontier, InsertTransSpec(XDAF, XDeliveredatFrontier));
        InsertData(XDDP, XDeliveredDutyPaid, InsertTransSpec(XDDP, XDeliveredDutyPaid));
        InsertData(XDDU, XDeliveredDutyUnpaid, InsertTransSpec(XDDU, XDeliveredDutyUnpaid));
        InsertData(XDELIVERY, XDELIVERY, InsertTransSpec(XXXX, XOtherShipmentCondition));
        InsertData(XDEQ, XDeliveredexQuay, InsertTransSpec(XDEQ, XDeliveredexQuay));
        InsertData(XDES, XDeliveredexShip, InsertTransSpec(XDES, XDeliveredexShip));
        InsertData(XEXW, XExWarehouse, InsertTransSpec(XEXW, XExWarehouse));
        InsertData(XFAS, XFreeAlongsideShip, InsertTransSpec(XFAS, XFreeAlongsideShip));
        InsertData(XFCA, XFreeCarrier, InsertTransSpec(XFCA, XFreeCarrier));
        InsertData(XFOB, XFreeonBoard, InsertTransSpec(XFOB, XFreeonBoard));
        InsertData(XPICKUP, XPickupatLocation, XXXX);

        InsertArea('1', XFlemishRegion);
        InsertArea('2', XWalloonRegion);
        InsertArea('3', XBrusselsCapitalRegion);
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
        XXXX: Label 'XXX';
        XOtherShipmentCondition: Label 'Other Shipment Condition';
        XFlemishRegion: Label 'Flemish Region';
        XWalloonRegion: Label 'Walloon Region';
        XBrusselsCapitalRegion: Label 'Brussels Capital Region';

    procedure InsertData("Code": Code[10]; Description: Text[50]; Incoterm: Code[10])
    begin
        "Shipment Method".Init();
        "Shipment Method".Validate(Code, Code);
        "Shipment Method".Validate(Description, Description);
        "Shipment Method".Validate("Incoterm in Intrastat Decl.", Incoterm);
        "Shipment Method".Insert();
    end;

    procedure InsertTransSpec("Code": Code[10]; Description: Text[50]) TS: Code[10]
    var
        TransactionSpecification: Record "Transaction Specification";
    begin
        TransactionSpecification.Init();
        TransactionSpecification.Validate(Code, Code);
        TransactionSpecification.Validate(Text, Description);
        TransactionSpecification.Insert();
        exit(TransactionSpecification.Code);
    end;

    procedure InsertArea("Code": Code[10]; Description: Text[30])
    var
        "Area": Record "Area";
    begin
        Area.Init();
        Area.Validate(Code, Code);
        Area.Validate(Text, Description);
        Area.Insert();
    end;
}

