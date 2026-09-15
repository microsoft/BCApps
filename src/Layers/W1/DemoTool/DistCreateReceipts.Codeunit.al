codeunit 118825 "Dist. Create Receipts"
{

    trigger OnRun()
    begin
        InsertData(XGREEN);
        InsertData(XGREEN);
        InsertData(XYELLOW);
        InsertData(XWHITE);
    end;

    var
        WhseReceiptHeader: Record "Warehouse Receipt Header";
        XGREEN: Label 'GREEN';
        XYELLOW: Label 'YELLOW';
        XWHITE: Label 'WHITE';

    procedure InsertData(Location: Code[10])
    begin
        WhseReceiptHeader.Validate("No.", '');
        WhseReceiptHeader."Location Code" := Location;
        WhseReceiptHeader.Insert(true);
    end;
}

