codeunit 118827 "Dist. Post Receipt"
{

    trigger OnRun()
    begin
        InsertData(XRE000001, 10000);
        InsertData(XRE000003, 10000);
    end;

    var
        XRE000001: Label 'RE000001';
        XRE000003: Label 'RE000003';

    procedure InsertData(WhseReceiptNo: Code[20]; WhseReceiptLineNo: Integer)
    var
        WhseReceiptLine: Record "Warehouse Receipt Line";
        WhseReceiptPost: Codeunit "Whse.-Post Receipt";
    begin
        WhseReceiptLine.Get(WhseReceiptNo, WhseReceiptLineNo);
        WhseReceiptLine.SetRange("No.", WhseReceiptNo);
        WhseReceiptLine.AutofillQtyToReceive(WhseReceiptLine);
        WhseReceiptPost.Run(WhseReceiptLine);
    end;
}

