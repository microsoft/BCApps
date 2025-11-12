codeunit 118821 "Dist. Modify Purchase Setup"
{

    trigger OnRun()
    begin
        "Purchases & Payables Setup".Get();
        "Create No. Series".InitTempSeries("Purchases & Payables Setup"."Order Nos.", XPORDD, XPurchaseOrderDist, 6);
        "Purchases & Payables Setup"."Order Nos." := XPORDD;
        "Purchases & Payables Setup".Modify();
    end;

    var
        "Purchases & Payables Setup": Record "Purchases & Payables Setup";
        "Create No. Series": Codeunit "Create No. Series";
        XPORDD: Label 'P-ORD-D';
        XPurchaseOrderDist: Label 'Purchase Order (Dist)';
        XPORD: Label 'P-ORD';

    procedure Finalize()
    begin
        "Purchases & Payables Setup".Get();
        "Purchases & Payables Setup"."Order Nos." := XPORD;
        "Purchases & Payables Setup".Modify();
    end;
}

