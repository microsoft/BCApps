codeunit 118822 "Dist. Create Purchase Header"
{

    trigger OnRun()
    begin
        DocNo := CreatePurchaseHeader.InsertData("Purchase Document Type"::Order, '45858585', 19030123D, XD010, '', XAcquisitionOfGoods, false, 0, '');
        CreatePurchaseLine.InsertData("Purchase Document Type"::Order, DocNo, 2, '1908-S', '', XGREEN, 20, 0, 0, '', '', '', '');
        CreatePurchaseLine.InsertData("Purchase Document Type"::Order, DocNo, 2, '1906-S', '', XGREEN, 20, 0, 0, '', '', '', '');
        CreatePurchaseLine.InsertData("Purchase Document Type"::Order, DocNo, 2, '80100', '', XGREEN, 200, 0, 0, '', '', '', '');

        DocNo := CreatePurchaseHeader.InsertData("Purchase Document Type"::Order, '45858585', 19030126D, XD101, '', XAcquisitionOfGoods, false, 0, '');
        CreatePurchaseLine.InsertData("Purchase Document Type"::Order, DocNo, 2, '1964-S', '', XGREEN, 100, 0, 0, '', '', '', '');
        CreatePurchaseLine.InsertData("Purchase Document Type"::Order, DocNo, 2, '1996-S', '', XGREEN, 110, 0, 0, '', '', '', '');
        CreatePurchaseLine.InsertData("Purchase Document Type"::Order, DocNo, 2, '80100', '', XGREEN, 140, 0, 0, '', '', '', '');

        DocNo := CreatePurchaseHeader.InsertData("Purchase Document Type"::Order, '47586622', 19030128D, XD100, '', XAcquisitionOfGoods, false, 0, '');
        CreatePurchaseLine.InsertData("Purchase Document Type"::Order, DocNo, 2, '1964-S', '', XGREEN, 110, 0, 0, '', '', '', '');
        CreatePurchaseLine.InsertData("Purchase Document Type"::Order, DocNo, 2, '1968-S', '', XGREEN, 110, 0, 0, '', '', '', '');
        CreatePurchaseLine.InsertData("Purchase Document Type"::Order, DocNo, 2, '80100', '', XGREEN, 300, 0, 0, '', '', '', '');
        CreatePurchaseLine.InsertData("Purchase Document Type"::Order, DocNo, 2, '80100', '', XGREEN, 60, 0, 0, '', '', '', '');

        DocNo := CreatePurchaseHeader.InsertData("Purchase Document Type"::Order, '47586622', 19030129D, XD120, '', XAcquisitionOfGoods, false, 0, '');
        CreatePurchaseLine.InsertData("Purchase Document Type"::Order, DocNo, 2, '1906-S', '', XGREEN, 50, 0, 0, '', '', '', '');
        CreatePurchaseLine.InsertData("Purchase Document Type"::Order, DocNo, 2, '1908-S', '', XGREEN, 50, 0, 0, '', '', '', '');
        CreatePurchaseLine.InsertData("Purchase Document Type"::Order, DocNo, 2, '80100', '', XGREEN, 20, 0, 0, '', '', '', '');
        CreatePurchaseLine.InsertData("Purchase Document Type"::Order, DocNo, 2, '1964-S', '', XGREEN, 30, 0, 0, '', '', '', '');
        CreatePurchaseLine.InsertData("Purchase Document Type"::Order, DocNo, 2, '1968-S', '', XGREEN, 50, 0, 0, '', '', '', '');
        CreatePurchaseLine.InsertData("Purchase Document Type"::Order, DocNo, 2, '1996-S', '', XGREEN, 50, 0, 0, '', '', '', '');

        DocNo := CreatePurchaseHeader.InsertData("Purchase Document Type"::Order, '30000', 19030103D, '', '', XAcquisitionOfGoods, false, 0, '');
        CreatePurchaseLine.InsertData("Purchase Document Type"::Order, DocNo, 2, '1896-S', '', XBLUE, 100, 0, 0, '', '', '', '');

        "Purchases & Payables Setup".Get();
        "Create No. Series".InsertSeriesOnly("Purchases & Payables Setup"."Order Nos.", XPUR + '-12-4', XPurchaseOrderDist, true, false, true);
        "Create No. Series".InsertSeriesLine("Purchases & Payables Setup"."Order Nos.", XPORDD1, 10000, 0D, 1);
        "Purchases & Payables Setup"."Order Nos." := XPUR + '-12-4';
        "Purchases & Payables Setup".Modify();

        DocNo := CreatePurchaseHeader.InsertData("Purchase Document Type"::Order, '30000', 19030123D, XD303, '', XAcquisitionOfGoods, false, 0, '');
        CreatePurchaseLine.InsertData("Purchase Document Type"::Order, DocNo, 2, 'LS-Man-10', '', XWHITE, 100, 0, 0, '', '', '', '');
        CreatePurchaseLine.InsertData("Purchase Document Type"::Order, DocNo, 2, 'LS-75', '', XWHITE, 10, 0, 0, '', '', '', '');

        DocNo := CreatePurchaseHeader.InsertData("Purchase Document Type"::Order, '40000', 19030126D, XD304, '', XAcquisitionOfGoods, false, 0, '');
        CreatePurchaseLine.InsertData("Purchase Document Type"::Order, DocNo, 2, 'LS-120', '', XWHITE, 10, 0, 0, '', '', '', '');
        CreatePurchaseLine.InsertData("Purchase Document Type"::Order, DocNo, 2, 'LS-10PC', '', XWHITE, 22, 0, 0, '', '', '', '');

        DocNo := CreatePurchaseHeader.InsertData("Purchase Document Type"::Order, '50000', 19030128D, XD305, '', XAcquisitionOfGoods, false, 0, '');
        CreatePurchaseLine.InsertData("Purchase Document Type"::Order, DocNo, 2, 'LS-150', '', XWHITE, 8, 0, 0, '', '', '', '');

        DocNo := CreatePurchaseHeader.InsertData("Purchase Document Type"::Order, '40000', 19030129D, XD306, '', XAcquisitionOfGoods, false, 0, '');
        CreatePurchaseLine.InsertData("Purchase Document Type"::Order, DocNo, 2, 'LS-10PC', '', XWHITE, 40, 0, 0, '', '', '', '');
        CreatePurchaseLine.InsertData("Purchase Document Type"::Order, DocNo, 2, 'LS-150', '', XWHITE, 20, 0, 0, '', '', '', '');

        DocNo := CreatePurchaseHeader.InsertData("Purchase Document Type"::Order, '50000', 19030103D, XD307, '', XAcquisitionOfGoods, false, 0, '');
        CreatePurchaseLine.InsertData("Purchase Document Type"::Order, DocNo, 2, 'LS-150', '', XWHITE, 12, 0, 0, '', '', '', '');

        DocNo := CreatePurchaseHeader.InsertData("Purchase Document Type"::Order, '30000', 19030123D, XD308, '', XAcquisitionOfGoods, false, 0, '');
        CreatePurchaseLine.InsertData("Purchase Document Type"::Order, DocNo, 2, 'LS-Man-10', '', XWHITE, 50, 0, 0, '', '', '', '');
        CreatePurchaseLine.InsertData("Purchase Document Type"::Order, DocNo, 2, 'LS-2', '', XWHITE, 100, 0, 0, '', '', '', '');

        DocNo := CreatePurchaseHeader.InsertData("Purchase Document Type"::Order, '40000', 19030126D, XD309, '', XAcquisitionOfGoods, false, 0, '');
        CreatePurchaseLine.InsertData("Purchase Document Type"::Order, DocNo, 2, 'LS-S15', '', XWHITE, 20, 0, 0, '', '', '', '');

        DocNo := CreatePurchaseHeader.InsertData("Purchase Document Type"::Order, '60000', 19030126D, XD310, '', XAcquisitionOfGoods, false, 0, '');
        CreatePurchaseLine.InsertData("Purchase Document Type"::Order, DocNo, 2, 'LS-75', '', XWHITE, 20, 0, 0, '', '', '', '');
        CreatePurchaseLine.InsertData("Purchase Document Type"::Order, DocNo, 2, 'LS-120', '', XWHITE, 10, 0, 0, '', '', '', '');
        CreatePurchaseLine.InsertData("Purchase Document Type"::Order, DocNo, 2, 'LS-150', '', XWHITE, 12, 0, 0, '', '', '', '');

        DocNo := CreatePurchaseHeader.InsertData("Purchase Document Type"::Order, '61000', 19030126D, XD311, '', XAcquisitionOfGoods, false, 0, '');
        CreatePurchaseLine.InsertData("Purchase Document Type"::Order, DocNo, 2, 'LS-Man-10', '', XWHITE, 100, 0, 0, '', '', '', '');
        CreatePurchaseLine.InsertData("Purchase Document Type"::Order, DocNo, 2, 'LS-10PC', '', XWHITE, 60, 0, 0, '', '', '', '');

        DocNo := CreatePurchaseHeader.InsertData("Purchase Document Type"::Order, '62000', 19030126D, XD312, '', XAcquisitionOfGoods, false, 0, '');
        CreatePurchaseLine.InsertData("Purchase Document Type"::Order, DocNo, 2, 'LS-2', '', XWHITE, 40, 0, 0, '', '', '', '');
        CreatePurchaseLine.InsertData("Purchase Document Type"::Order, DocNo, 2, 'LS-10PC', '', XWHITE, 100, 0, 0, '', '', '', '');

        DocNo := CreatePurchaseHeader.InsertData("Purchase Document Type"::Order, '50000', 19030131D, XD305, '', XAcquisitionOfGoods, false, 0, '');
        CreatePurchaseLine.InsertData("Purchase Document Type"::Order, DocNo, 2, 'LS-MAN-10', '', XWHITE, 100, 0, 0, '', '', '', '');
        CreatePurchaseLine.InsertData("Purchase Document Type"::Order, DocNo, 2, 'LS-75', '', XWHITE, 10, 0, 0, '', '', '', '');
        CreatePurchaseLine.InsertData("Purchase Document Type"::Order, DocNo, 2, 'LS-120', '', XWHITE, 10, 0, 0, '', '', '', '');
        CreatePurchaseLine.InsertData("Purchase Document Type"::Order, DocNo, 2, 'LS-10PC', '', XWHITE, 22, 0, 0, '', '', '', '');
        CreatePurchaseLine.InsertData("Purchase Document Type"::Order, DocNo, 2, 'LS-150', '', XWHITE, 8, 0, 0, '', '', '', '');

        DocNo := CreatePurchaseHeader.InsertData("Purchase Document Type"::Order, '62000', 19030131D, XD315, '', XAcquisitionOfGoods, false, 0, '');
        CreatePurchaseLine.InsertData("Purchase Document Type"::Order, DocNo, 2, 'LS-81', '', XWHITE, 10, 0, 0, '', '', '', '');
    end;

    var
        CreatePurchaseHeader: Codeunit "Create Purchase Header";
        CreatePurchaseLine: Codeunit "Create Purchase Line";
        "Purchases & Payables Setup": Record "Purchases & Payables Setup";
        "Create No. Series": Codeunit "Create No. Series";
        XD010: Label 'D-010';
        XD101: Label 'D-101';
        XD100: Label 'D-100';
        XD120: Label 'D-120';
        XPORDD1: Label 'POD1';
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
        XGREEN: Label 'GREEN';
        XBLUE: Label 'BLUE';
        XWHITE: Label 'WHITE';
        DocNo: Code[20];
        XPUR: Label 'PUR';
        XAcquisitionOfGoods: Label 'Acquisition of goods %1 %2 from %3';
}

