codeunit 118814 "Dist. Release Sales Documents"
{

    trigger OnRun()
    begin
        ReleaseSalesDoc(1, '6001');
        ReleaseSalesDoc(1, '6002');
        ReleaseSalesDoc(1, '6003');
        ReleaseSalesDoc(1, '6004');

        ReleaseSalesDoc(1, '104008');
        ReleaseSalesDoc(1, '104009');
        ReleaseSalesDoc(1, '104010');
        ReleaseSalesDoc(1, '104011');
        ReleaseSalesDoc(1, '104012');
        ReleaseSalesDoc(1, '104013');
        ReleaseSalesDoc(1, '104014');
        ReleaseSalesDoc(1, '104015');
        ReleaseSalesDoc(1, '104019');
        ReleaseSalesDoc(1, '104020');
        ReleaseSalesDoc(1, '104021');

        PostSalesDoc(1, '6005', true, true);
    end;

    var
        SalesHeader: Record "Sales Header";
        SalesPost: Codeunit "Sales-Post";
        ReleaseSalesDocument: Codeunit "Release Sales Document";

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

