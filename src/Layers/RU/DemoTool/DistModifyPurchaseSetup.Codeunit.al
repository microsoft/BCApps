codeunit 118821 "Dist. Modify Purchase Setup"
{

    trigger OnRun()
    begin
        "Purchases & Payables Setup".Get();
        "Create No. Series".InsertSeriesOnly("Purchases & Payables Setup"."Order Nos.", XPUR + '-12-1', XPurchaseOrderDist, true, false, true);
        "Create No. Series".InsertSeriesLine("Purchases & Payables Setup"."Order Nos.", XPORDD, 10000, 0D, 1);
        "Purchases & Payables Setup"."Order Nos." := XPUR + '-12-1';
        "Purchases & Payables Setup".Modify();
    end;

    var
        "Purchases & Payables Setup": Record "Purchases & Payables Setup";
        "Create No. Series": Codeunit "Create No. Series";
        XPORDD: Label 'POD';
        XPurchaseOrderDist: Label 'Purchase Order (Dist)';
        XPUR: Label 'PUR';

    procedure Finalize()
    begin
        "Purchases & Payables Setup".Get();
        "Purchases & Payables Setup"."Order Nos." := XPUR + '-12';
        "Purchases & Payables Setup".Modify();
    end;
}

