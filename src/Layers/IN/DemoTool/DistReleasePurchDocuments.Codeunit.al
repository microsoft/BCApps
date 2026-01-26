codeunit 118824 "Dist. Release Purch. Documents"
{

    trigger OnRun()
    begin
        ReleasePurchaseDoc(1, '6001');
        ReleasePurchaseDoc(1, '6002');
        ReleasePurchaseDoc(1, '6003');
        ReleasePurchaseDoc(1, '6004');
        ReleasePurchaseDoc(1, '6005');

        ReleasePurchaseDoc(1, '104004');
        ReleasePurchaseDoc(1, '104005');
        ReleasePurchaseDoc(1, '104006');
        ReleasePurchaseDoc(1, '104007');
        ReleasePurchaseDoc(1, '104008');
        ReleasePurchaseDoc(1, '104009');
        ReleasePurchaseDoc(1, '104010');
        ReleasePurchaseDoc(1, '104011');
        ReleasePurchaseDoc(1, '104012');
    end;

    var
        PurchHeader: Record "Purchase Header";
        ReleasePurchaseDocument: Codeunit "Release Purchase Document";

    procedure ReleasePurchaseDoc(DocumentType: Option; DocumentNo: Code[20])
    begin
        PurchHeader.Get(DocumentType, DocumentNo);
        ReleasePurchaseDocument.Run(PurchHeader);
    end;
}
