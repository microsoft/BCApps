codeunit 118012 "Create Transfer Order"
{

    trigger OnRun()
    var
        TransferNo: Code[20];
    begin
        TransferHeader.DeleteAll();
        TransferLine.DeleteAll();

        TransferNo := InsertHeader(XYELLOW, XRED, XOWNLOG,
            CA.AdjustDate(19030126D), CA.AdjustDate(19030129D),
            CalcDate('<+3D>', CA.AdjustDate(19030129D)));
        InsertLine(TransferNo, 10000, '1928-S', 25, 25, 25);
        InsertLine(TransferNo, 20000, '1972-S', 19, 19, 19);

        TransferNo := InsertHeader(XBLUE, XYELLOW, XOUTLOG,
            CA.AdjustDate(19030126D), CA.AdjustDate(19030126D),
            0D);
        InsertLine(TransferNo, 10000, '70001', 45, 15, 0);
        InsertLine(TransferNo, 20000, '70002', 22, 3, 0);
        InsertLine(TransferNo, 30000, '70003', 31, 31, 0);
        ReleaseOrder(TransferHeader);
        PostShipment(TransferHeader);

        TransferNo := InsertHeader(XGREEN, XRED, XOWNLOG,
            CA.AdjustDate(19030126D), CA.AdjustDate(19030126D),
            CA.AdjustDate(19030129D));
        InsertLine(TransferNo, 10000, '1908-S', 10, 10, 10);
        InsertLine(TransferNo, 20000, '1936-S', 4, 4, 4);
        ReleaseOrder(TransferHeader);
        PostShipment(TransferHeader);
        PostReceipt(TransferHeader);

        TransferNo := InsertHeader(XBLUE, XWHITE, XOWNLOG,
            CA.AdjustDate(19030126D), CA.AdjustDate(19030126D),
            CA.AdjustDate(19030129D));
        InsertLine(TransferNo, 10000, 'LS-75', 11, 0, 0);
        ReleaseOrder(TransferHeader);

        TransferNo := InsertHeader(XGREEN, XWHITE, XOWNLOG,
            CA.AdjustDate(19030126D), CA.AdjustDate(19030126D),
            CA.AdjustDate(19030129D));
        InsertLine(TransferNo, 10000, 'LS-120', 13, 0, 0);
        ReleaseOrder(TransferHeader);

        TransferNo := InsertHeader(XWHITE, XRED, XOWNLOG,
            CA.AdjustDate(19030126D), CA.AdjustDate(19030126D),
            CA.AdjustDate(19030129D));
        InsertLine(TransferNo, 10000, 'LS-150', 12, 0, 0);
        ReleaseOrder(TransferHeader);

        TransferNo := InsertHeader(XWHITE, XYELLOW, XOWNLOG,
            CA.AdjustDate(19030126D), CA.AdjustDate(19030126D),
            CA.AdjustDate(19030129D));
        InsertLine(TransferNo, 10000, 'LS-10PC', 14, 0, 0);
        ReleaseOrder(TransferHeader);
    end;

    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        XBLUE: Label 'BLUE';
        XYELLOW: Label 'YELLOW';
        XOUTLOG: Label 'OUT. LOG.';
        XRED: Label 'RED';
        XOWNLOG: Label 'OWN LOG.';
        XGREEN: Label 'GREEN';
        XWHITE: Label 'WHITE';
        CA: Codeunit "Make Adjustments";
        XMAIN: Label 'MAIN';
        XEAST: Label 'EAST';
        XWEST: Label 'WEST';

    local procedure InsertHeader(TransferFromCode: Code[20]; TransferToCode: Code[20]; InTransitCode: Code[20]; PostingDate: Date; ShipmentDate: Date; ReceiptDate: Date): Code[20]
    var
        InventorySetup: Record "Inventory Setup";
        NoSeries: Codeunit "No. Series";
        TransferNo: Code[20];
    begin
        InventorySetup.Get();

        TransferNo := NoSeries.GetNextNo(InventorySetup."Transfer Order Nos.");
        TransferHeader.Init();
        TransferHeader."No." := TransferNo;
        TransferHeader."No. Series" := InventorySetup."Transfer Order Nos.";
        TransferHeader.Insert();
        TransferHeader.Validate("Posting Date", PostingDate);
        TransferHeader.Validate("Transfer-from Code", TransferFromCode);
        TransferHeader.Validate("Transfer-to Code", TransferToCode);
        TransferHeader.Validate("In-Transit Code", InTransitCode);
        if ShipmentDate <> 0D then
            TransferHeader.Validate("Shipment Date", ShipmentDate);
        if ReceiptDate <> 0D then
            TransferHeader.Validate("Receipt Date", ReceiptDate);
        TransferHeader.Modify();
        exit(TransferNo);
    end;

    local procedure InsertLine(DocumentNo: Code[20]; LineNo: Integer; ItemNo: Code[20]; Quantity: Decimal; QtyToShip: Decimal; QtyToReceive: Decimal)
    begin
        TransferLine.Init();
        TransferLine."Document No." := DocumentNo;
        TransferLine."Line No." := LineNo;
        TransferLine.Validate("Item No.", ItemNo);
        TransferLine.Validate(Quantity, Quantity);

        TransferLine."Qty. to Ship" := QtyToShip;
        TransferLine."Qty. to Ship (Base)" :=
          Round(QtyToShip * TransferLine."Qty. per Unit of Measure", 0.00001);

        TransferLine."Qty. to Receive" := QtyToReceive;
        TransferLine."Qty. to Receive (Base)" :=
          Round(QtyToReceive * TransferLine."Qty. per Unit of Measure", 0.00001);

        TransferLine.Insert();
    end;

    local procedure PostShipment(var TransferHeader: Record "Transfer Header")
    var
        TransferOrderPostShipment: Codeunit "TransferOrder-Post Shipment";
    begin
        TransferOrderPostShipment.SetHideValidationDialog(true);
        TransferOrderPostShipment.Run(TransferHeader);
    end;

    local procedure PostReceipt(var TransferHeader: Record "Transfer Header")
    var
        TransferOrderPostReceipt: Codeunit "TransferOrder-Post Receipt";
    begin
        TransferOrderPostReceipt.SetHideValidationDialog(true);
        TransferOrderPostReceipt.Run(TransferHeader);
    end;

    local procedure ReleaseOrder(var TransferHeader: Record "Transfer Header")
    var
        ReleaseTransferDoc: Codeunit "Release Transfer Document";
    begin
        ReleaseTransferDoc.Run(TransferHeader);
    end;

    procedure CreateEvaluationData(OpenDocMarker: Text[35])
    var
        InterfaceEvaluationData: Codeunit "Interface Evaluation Data";
        TransferNo: Code[20];
    begin
        TransferHeader.DeleteAll();
        TransferLine.DeleteAll();

        TransferNo := InsertHeader(XMAIN, XWEST, XOUTLOG,
            CA.AdjustDate(InterfaceEvaluationData.GetCurrentDay()),
            CA.AdjustDate(InterfaceEvaluationData.GetCurrentDay()),
            CalcDate('<+3D>', CA.AdjustDate(InterfaceEvaluationData.GetCurrentDay())));
        InsertLine(TransferNo, 10000, '1968-S', 1, 1, 0);

        TransferNo := InsertHeader(XWEST, XEAST, XOWNLOG,
            CA.AdjustDate(InterfaceEvaluationData.GetCurrentDay()),
            CA.AdjustDate(InterfaceEvaluationData.GetCurrentDay()),
            CalcDate('<+3D>', CA.AdjustDate(InterfaceEvaluationData.GetCurrentDay())));
        TransferHeader."External Document No." := OpenDocMarker;
        TransferHeader.Modify(true);
        InsertLine(TransferNo, 10000, '1968-S', 3, 3, 0);

        TransferNo := InsertHeader(XEAST, XMAIN, XOWNLOG,
            CA.AdjustDate(InterfaceEvaluationData.GetCurrentDay()),
            CA.AdjustDate(InterfaceEvaluationData.GetCurrentDay()),
            CalcDate('<+3D>', CA.AdjustDate(InterfaceEvaluationData.GetCurrentDay())));
        InsertLine(TransferNo, 10000, '1968-S', 2, 1, 0);
        TransferHeader."External Document No." := OpenDocMarker;
        TransferHeader.Modify(true);
    end;
}

