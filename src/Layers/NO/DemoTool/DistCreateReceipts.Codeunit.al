codeunit 118825 "Dist. Create Receipts"
{

    trigger OnRun()
    begin
        InsertData(XGREEN);
        WhseReceiptHeader.Validate("Posting Date", CA.AdjustDate(19030123D)); // Date should not be in closed Settled VAT Period
        WhseReceiptHeader.Modify(true);
        InsertData(XGREEN);
        InsertData(XYELLOW);
        InsertData(XWHITE);
    end;

    var
        WhseReceiptHeader: Record "Warehouse Receipt Header";
        XGREEN: Label 'GREEN';
        XYELLOW: Label 'YELLOW';
        XWHITE: Label 'WHITE';
        CA: Codeunit "Make Adjustments";

    procedure InsertData(Location: Code[10])
    begin
        WhseReceiptHeader.Validate("No.", '');
        WhseReceiptHeader."Location Code" := Location;
        WhseReceiptHeader.Insert(true);
    end;
}

