codeunit 161012 "Create Cartera Setup"
{

    trigger OnRun()
    begin
        "Cartera Setup".Get();
        "Cartera Setup"."Bills Discount Limit Warnings" := true;
        "Cartera Setup"."CCC Ctrl Digits Check String" := X63791058421;
        "Create No. Series".InitFinalSeries("Cartera Setup"."Bill Group Nos.", XBREM, XBillGroup, 6);
        "Create No. Series".InitFinalSeries("Cartera Setup"."Payment Order Nos.", XBORDPAG, XPaymentOrder, 9);
        "Cartera Setup".Modify();
        "Source Code Setup".Get();
        "Source Code Setup"."Cartera Journal" := XCARJNL;
        "Source Code Setup".Modify();
    end;

    var
        "Cartera Setup": Record "Cartera Setup";
        "Create No. Series": Codeunit "Create No. Series";
        "Source Code Setup": Record "Source Code Setup";
        X63791058421: Label '63791058421';
        XBREM: Label 'B-REM';
        XBillGroup: Label 'Bill Group';
        XBORDPAG: Label 'B-ORDPAG';
        XPaymentOrder: Label 'PaymentOrder';
        XCARJNL: Label 'CARJNL';

    procedure Finalize()
    begin
        "Cartera Setup".Get();
        "Cartera Setup"."Bill Group Nos." := XBREM;
        "Cartera Setup"."Payment Order Nos." := XBORDPAG;
        "Cartera Setup".Modify();
    end;
}

