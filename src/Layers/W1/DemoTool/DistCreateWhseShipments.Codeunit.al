codeunit 118815 "Dist. Create Whse. Shipments"
{

    trigger OnRun()
    begin
        WhseShptHeader.DeleteAll();
        WhseShptLine.DeleteAll();
        InsertData(XGREEN);
        InsertData(XGREEN);
        InsertData(XWHITE);
        InsertData(XWHITE);
    end;

    var
        WhseShptHeader: Record "Warehouse Shipment Header";
        WhseShptLine: Record "Warehouse Shipment Line";
        XGREEN: Label 'GREEN';
        XWHITE: Label 'WHITE';
        XSH000004: Label 'SH000004';
        XW090002: Label 'W-09-0002';

    procedure InsertData(Location: Code[10])
    begin
        WhseShptHeader.Validate("No.", '');
        WhseShptHeader."Location Code" := Location;
        WhseShptHeader.Insert(true);
        if WhseShptHeader."No." = XSH000004 then begin
            WhseShptHeader."Bin Code" := XW090002;
            WhseShptHeader.Modify();
        end;
    end;
}

