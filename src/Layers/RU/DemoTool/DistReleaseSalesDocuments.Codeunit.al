codeunit 118814 "Dist. Release Sales Documents"
{

    trigger OnRun()
    begin
        ReleaseSalesDoc(1, XSOD + '-00001');
        ReleaseSalesDoc(1, XSOD + '-00002');
        ReleaseSalesDoc(1, XSOD + '-00003');
        ReleaseSalesDoc(1, XSOD + '-00004');

        ReleaseSalesDoc(1, XSOD + '1-00008');
        ReleaseSalesDoc(1, XSOD + '1-00009');
        ReleaseSalesDoc(1, XSOD + '1-00010');
        ReleaseSalesDoc(1, XSOD + '1-00011');
        ReleaseSalesDoc(1, XSOD + '1-00012');
        ReleaseSalesDoc(1, XSOD + '1-00013');
        ReleaseSalesDoc(1, XSOD + '1-00014');
        ReleaseSalesDoc(1, XSOD + '1-00015');
        ReleaseSalesDoc(1, XSOD + '1-00019');
        ReleaseSalesDoc(1, XSOD + '1-00020');
        ReleaseSalesDoc(1, XSOD + '1-00021');

        PostSalesDoc(1, XSOD + '-00005', true, true);
    end;

    var
        SalesHeader: Record "Sales Header";
        SalesPost: Codeunit "Sales-Post";
        ReleaseSalesDocument: Codeunit "Release Sales Document";
        XSOD: Label 'SOD';

    procedure ReleaseSalesDoc(DocumentType: Option; DocumentNo: Code[20])
    begin
        SalesHeader.Get(DocumentType, DocumentNo);
        ReleaseSalesDocument.Run(SalesHeader);
    end;

    procedure PostSalesDoc(DocumentType: Option; DocumentNo: Code[20]; Ship: Boolean; Invoice: Boolean)
    begin
        SalesHeader.Get(DocumentType, DocumentNo);
        SalesHeader.Ship := Ship;
        SalesHeader.Invoice := Invoice;
        SalesPost.Run(SalesHeader);
    end;
}

