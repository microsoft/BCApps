codeunit 161382 "Create Exit Point (Intrastat)"
{

    trigger OnRun()
    begin
        InsertData(XxCFR, XCostAndFreight, XxC, false);
        InsertData(XxCIF, XCostInsuranceAndFreight, XxC, false);
        InsertData(XxCIP, XCarriageAndInsurancePaidTo, XxC, false);
        InsertData(XxCPT, XCarriagePaidTo, XxC, false);
        InsertData(XxDAF, XDeliveredAtFrontier, XxD, false);
        InsertData(XxDDP, XDeliveredDutyPaid, XxD, false);
        InsertData(XxDDU, XDeliveredDutyUnpaid, XxD, false);
        InsertData(XxDEQ, XDeliveredExQuay, XxD, false);
        InsertData(XxDES, XDeliveredExShip, XxD, false);
        InsertData(XxEXW, XExWorks, XxE, false);
        InsertData(XxFAS, XFreeAlongsideShip, XxF, false);
        InsertData(XxFCA, XFreeCarrier, XxF, false);
        InsertData(XxFOB, XFreeOnBoard, XxF, false);
    end;

    var
        XxCFR: Label 'CFR';
        XCostAndFreight: Label 'Cost and Freight';
        XxC: Label 'C';
        XxCIF: Label 'CIF';
        XCostInsuranceAndFreight: Label 'Cost Insurance and Freight';
        XxCIP: Label 'CIP';
        XCarriageAndInsurancePaidTo: Label 'Carriage and Insurance Paid to';
        XxCPT: Label 'CPT';
        XCarriagePaidTo: Label 'Carriage Paid To';
        XxDAF: Label 'DAF';
        XDeliveredAtFrontier: Label 'Delivered At Frontier';
        XxD: Label 'D';
        XxDDP: Label 'DDP';
        XDeliveredDutyPaid: Label 'Delivered Duty Paid';
        XxDDU: Label 'DDU';
        XDeliveredDutyUnpaid: Label 'Delivered Duty Unpaid';
        XxDEQ: Label 'DEQ';
        XDeliveredExQuay: Label 'Delivered Ex Quay';
        XxDES: Label 'DES';
        XDeliveredExShip: Label 'Delivered Ex Ship';
        XxEXW: Label 'EXW';
        XExWorks: Label 'Ex Works';
        XxE: Label 'E';
        XxFAS: Label 'FAS';
        XFreeAlongsideShip: Label 'Free Alongside Ship';
        XxF: Label 'F';
        XxFCA: Label 'FCA';
        XFreeCarrier: Label 'Free Carrier';
        XxFOB: Label 'FOB';
        XFreeOnBoard: Label 'Free on Board';

    procedure InsertData("Code": Code[10]; Description: Text[30]; GroupCode: Code[10]; ReduceStatisticalValue: Boolean)
    var
        EntryExitPoint: Record "Entry/Exit Point";
    begin
        EntryExitPoint.Init();
        EntryExitPoint.Code := Code;
        EntryExitPoint.Description := Description;
        EntryExitPoint."Group Code" := GroupCode;
        EntryExitPoint."Reduce Statistical Value" := ReduceStatisticalValue;
        EntryExitPoint.Insert();
    end;
}

