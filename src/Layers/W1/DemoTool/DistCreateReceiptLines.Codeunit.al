codeunit 118826 "Dist. Create Receipt Lines"
{

    trigger OnRun()
    begin
        InsertData(XRE000001, 0, XGREEN, 39, 1, '6001');
        InsertData(XRE000002, 0, XGREEN, 39, 1, '6002');
        InsertData(XRE000002, 0, XGREEN, 39, 1, '6003');
        InsertData(XRE000003, 0, XYELLOW, 5741, 1, '1002');
        InsertData(XRE000004, 0, XWHITE, 39, 1, '104012');
    end;

    var
        WhseReceiptHeader: Record "Warehouse Receipt Header";
        WhseRequest: Record "Warehouse Request";
        XRE000001: Label 'RE000001';
        XRE000002: Label 'RE000002';
        XRE000003: Label 'RE000003';
        XRE000004: Label 'RE000004';
        XGREEN: Label 'GREEN';
        XYELLOW: Label 'YELLOW';
        XWHITE: Label 'WHITE';
        GetSourceDocuments: Report "Get Source Documents";

    procedure InsertData(WhseReceiptNo: Code[20]; Type: Option; Location: Code[10]; SourceType: Integer; SourceSubtype: Option; SourceNo: Code[20])
    begin
        Clear(GetSourceDocuments);

        WhseReceiptHeader.Get(WhseReceiptNo);
        GetSourceDocuments.SetOneCreatedReceiptHeader(WhseReceiptHeader);

        WhseRequest.Get(Type, Location, SourceType, SourceSubtype, SourceNo);
        WhseRequest.SetRecFilter();
        GetSourceDocuments.UseRequestPage(false);
        GetSourceDocuments.SetTableView(WhseRequest);
        GetSourceDocuments.RunModal();
    end;
}

