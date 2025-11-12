codeunit 118816 "Dist. Create Whse. Shpt. Lines"
{

    trigger OnRun()
    begin
        InsertData(XSH000001, 1, XGREEN, 37, 1, '6001');
        InsertData(XSH000002, 1, XGREEN, 37, 1, '6002');
        InsertData(XSH000002, 1, XGREEN, 37, 1, '6003');
        InsertData(XSH000003, 1, XWHITE, 37, 1, '104019');
        InsertData(XSH000004, 1, XWHITE, 37, 1, '104020');
    end;

    var
        WhseShptHeader: Record "Warehouse Shipment Header";
        WhseRequest: Record "Warehouse Request";
        GetSourceDocuments: Report "Get Source Documents";
        XGREEN: Label 'GREEN';
        XWHITE: Label 'WHITE';
        XSH000001: Label 'SH000001';
        XSH000002: Label 'SH000002';
        XSH000003: Label 'SH000003';
        XSH000004: Label 'SH000004';

    procedure InsertData(WhseDocNo: Code[20]; Type: Option; Location: Code[10]; SourceType: Integer; SourceSubtype: Option; SourceNo: Code[20])
    begin
        Clear(GetSourceDocuments);

        WhseShptHeader.Get(WhseDocNo);
        GetSourceDocuments.SetOneCreatedShptHeader(WhseShptHeader);

        WhseRequest.Get(Type, Location, SourceType, SourceSubtype, SourceNo);
        WhseRequest.SetRecFilter();
        GetSourceDocuments.UseRequestPage(false);
        GetSourceDocuments.SetTableView(WhseRequest);
        GetSourceDocuments.RunModal();
    end;
}

