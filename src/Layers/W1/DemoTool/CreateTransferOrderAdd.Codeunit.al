codeunit 118016 "Create Transfer Order Add."
{

    trigger OnRun()
    var
        TransferNo: Code[20];
    begin
        TransferNo := InsertHeader(XGREEN, XYELLOW, XOWNLOG,
            CA.AdjustDate(19030126D), CA.AdjustDate(19030126D),
            0D);
        InsertLine(TransferNo, 10000, '1906-S', 40, 40, 0);
        InsertLine(TransferNo, 20000, '1964-S', 25, 25, 0);
        ReleaseOrder(TransferHeader);
        PostShipment(TransferHeader);

        TransferNo := InsertHeader(XGREEN, XRED, XOWNLOG,
            CA.AdjustDate(19030126D), CA.AdjustDate(19030126D),
            0D);
        InsertLine(TransferNo, 10000, '80100', 1300, 1300, 0);
        ReleaseOrder(TransferHeader);
        PostShipment(TransferHeader);

        TransferNo := InsertHeader(XRED, XBLUE, XOUTLOG,
            CA.AdjustDate(19030126D), CA.AdjustDate(19030126D),
            0D);
        InsertLine(TransferNo, 10000, '1896-S', 25, 25, 0);
        InsertLine(TransferNo, 20000, '1936-S', 4, 4, 0);
        ReleaseOrder(TransferHeader);
        PostShipment(TransferHeader);
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
        CA: Codeunit "Make Adjustments";

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

    local procedure ReleaseOrder(var TransferHeader: Record "Transfer Header")
    var
        ReleaseTransferDoc: Codeunit "Release Transfer Document";
    begin
        ReleaseTransferDoc.Run(TransferHeader);
    end;
}

