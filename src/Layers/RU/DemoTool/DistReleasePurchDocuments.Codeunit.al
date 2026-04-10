codeunit 118824 "Dist. Release Purch. Documents"
{

    trigger OnRun()
    begin
        ReleasePurchaseDoc(1, XPOD + '-00001');
        ReleasePurchaseDoc(1, XPOD + '-00002');
        ReleasePurchaseDoc(1, XPOD + '-00003');
        ReleasePurchaseDoc(1, XPOD + '-00004');
        ReleasePurchaseDoc(1, XPOD + '-00005');

        ReleasePurchaseDoc(1, XPOD + '1-00004');
        ReleasePurchaseDoc(1, XPOD + '1-00005');
        ReleasePurchaseDoc(1, XPOD + '1-00006');
        ReleasePurchaseDoc(1, XPOD + '1-00007');
        ReleasePurchaseDoc(1, XPOD + '1-00008');
        ReleasePurchaseDoc(1, XPOD + '1-00009');
        ReleasePurchaseDoc(1, XPOD + '1-00010');
        ReleasePurchaseDoc(1, XPOD + '1-00011');
        ReleasePurchaseDoc(1, XPOD + '1-00012');
    end;

    var
        PurchHeader: Record "Purchase Header";
        ReleasePurchaseDocument: Codeunit "Release Purchase Document";
        XPOD: Label 'POD';

    procedure ReleasePurchaseDoc(DocumentType: Option; DocumentNo: Code[20])
    begin
        if PurchHeader.Get(DocumentType, DocumentNo) then
            ReleasePurchaseDocument.Run(PurchHeader);
    end;
}

