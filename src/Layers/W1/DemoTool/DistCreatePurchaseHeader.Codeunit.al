codeunit 118822 "Dist. Create Purchase Header"
{

    trigger OnRun()
    begin
        CreatePurchaseHeader.InsertData(1, '45858585', 19030123D, XD010, '');
        CreatePurchaseHeader.InsertData(1, '45858585', 19030126D, XD101, '');
        CreatePurchaseHeader.InsertData(1, '47586622', 19030128D, XD100, '');
        CreatePurchaseHeader.InsertData(1, '47586622', 19030129D, XD120, '');
        CreatePurchaseHeader.InsertData(1, '30000', 19030103D, '', '');

        "Purchases & Payables Setup".Get();
        "Create No. Series".InitTempSeries("Purchases & Payables Setup"."Order Nos.", XPORDD1, XPurchaseOrderDist, 104);
        "Purchases & Payables Setup"."Order Nos." := XPORDD1;
        "Purchases & Payables Setup".Modify();

        CreatePurchaseHeader.InsertData(1, '30000', 19030123D, XD303, '');
        CreatePurchaseHeader.InsertData(1, '40000', 19030126D, XD304, '');
        CreatePurchaseHeader.InsertData(1, '50000', 19030128D, XD305, '');
        CreatePurchaseHeader.InsertData(1, '40000', 19030129D, XD306, '');
        CreatePurchaseHeader.InsertData(1, '50000', 19030103D, XD307, '');
        CreatePurchaseHeader.InsertData(1, '30000', 19030123D, XD308, '');
        CreatePurchaseHeader.InsertData(1, '40000', 19030126D, XD309, '');
        CreatePurchaseHeader.InsertData(1, '60000', 19030126D, XD310, '');
        CreatePurchaseHeader.InsertData(1, '61000', 19030126D, XD311, '');
        CreatePurchaseHeader.InsertData(1, '62000', 19030126D, XD312, '');
        CreatePurchaseHeader.InsertData(1, '50000', 19030131D, XD305, '');

        CreatePurchaseHeader.InsertData(1, '62000', 19030131D, XD315, '');
    end;

    var
        CreatePurchaseHeader: Codeunit "Create Purchase Header";
        "Purchases & Payables Setup": Record "Purchases & Payables Setup";
        "Create No. Series": Codeunit "Create No. Series";
        XD010: Label 'D-010';
        XD101: Label 'D-101';
        XD100: Label 'D-100';
        XD120: Label 'D-120';
        XPORDD1: Label 'P-ORD-D1';
        XPurchaseOrderDist: Label 'Purchase Order (Dist)';
        XD303: Label 'D-303';
        XD304: Label 'D-304';
        XD305: Label 'D-305';
        XD306: Label 'D-306';
        XD307: Label 'D-307';
        XD308: Label 'D-308';
        XD309: Label 'D-309';
        XD310: Label 'D-310';
        XD312: Label 'D-312';
        XD315: Label 'D-315';
        XD311: Label 'D-311';
}

