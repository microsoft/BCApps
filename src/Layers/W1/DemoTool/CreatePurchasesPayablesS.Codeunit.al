codeunit 101312 "Create Purchases & Payables S."
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        "Purchases & Payables Setup".Get();
        "Purchases & Payables Setup".Validate("Receipt on Invoice", true);
        "Purchases & Payables Setup".Validate("Return Shipment on Credit Memo", true);
        "Purchases & Payables Setup".Validate("Discount Posting", "Purchases & Payables Setup"."Discount Posting"::"All Discounts");
        "Purchases & Payables Setup".Validate("Invoice Rounding", true);
        "Purchases & Payables Setup"."Copy Vendor Name to Entries" := true;
        "Create No. Series".InitBaseSeries("Purchases & Payables Setup"."Vendor Nos.", XVEND, XVendor, XV10, XV99990, '', '', 10, Enum::"No. Series Implementation"::Sequence);
        "Create No. Series".InitTempSeries("Purchases & Payables Setup"."Quote Nos.", XPQUO, XPurchaseQuote);
        "Create No. Series".InitTempSeries("Purchases & Payables Setup"."Blanket Order Nos.", XPBLK, XBlanketPurchaseOrder);
        "Create No. Series".InitFinalSeries("Purchases & Payables Setup"."Order Nos.", XPORD, XPurchaseOrder, 6);
        "Create No. Series".InitTempSeries("Purchases & Payables Setup"."Return Order Nos.", XPRETORD, XPurchaseReturnOrder);
        "Create No. Series".InitFinalSeries("Purchases & Payables Setup"."Posted Receipt Nos.", XPRCPT, XPurchaseReceipt, 7);
        "Create No. Series".InitTempSeries("Purchases & Payables Setup"."Invoice Nos.", XPINV, XPurchaseInvoice);
        "Create No. Series".InitFinalSeries("Purchases & Payables Setup"."Posted Invoice Nos.", XPINVPLUS, XPostedPurchaseInvoice, 8);
        "Create No. Series".InitTempSeries("Purchases & Payables Setup"."Credit Memo Nos.", XPCR, XPurchaseCreditMemo);
        "Create No. Series".InitBaseSeries("Purchases & Payables Setup"."Price List Nos.", XPPL, XPurchasePriceList, XP00001, XP99999, '', '', 1, Enum::"No. Series Implementation"::Sequence);
        "Create No. Series".InitFinalSeries("Purchases & Payables Setup"."Posted Return Shpt. Nos.", XPShpt, XPostedPurchaseShipment, 5);
        "Create No. Series".InitFinalSeries("Purchases & Payables Setup"."Posted Credit Memo Nos.", XPCRPLUS, XPostedPurchaseCreditMemo, 9);
        "Purchases & Payables Setup"."Invoice Nos." := "Purchases & Payables Setup"."Posted Invoice Nos.";
        "Purchases & Payables Setup"."Credit Memo Nos." := "Purchases & Payables Setup"."Posted Credit Memo Nos.";
        "Purchases & Payables Setup"."Appln. between Currencies" := "Purchases & Payables Setup"."Appln. between Currencies"::All;
        "Purchases & Payables Setup"."Document Default Line Type" := "Purchases & Payables Setup"."Document Default Line Type"::Item;
        "Purchases & Payables Setup".Modify();
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        "Purchases & Payables Setup": Record "Purchases & Payables Setup";
        "Create No. Series": Codeunit "Create No. Series";
        XVEND: Label 'VEND';
        XVendor: Label 'Vendor';
        XV10: Label 'V10';
        XV99990: Label 'V99990';
        XPQUO: Label 'P-QUO';
        XPurchaseQuote: Label 'Purchase Quote';
        XPBLK: Label 'P-BLK';
        XBlanketPurchaseOrder: Label 'Blanket Purchase Order';
        XPORD: Label 'P-ORD';
        XPurchaseOrder: Label 'Purchase Order';
        XPRETORD: Label 'P-RETORD';
        XPurchaseReturnOrder: Label 'Purchase Return Order';
        XPRCPT: Label 'P-RCPT';
        XPurchaseReceipt: Label 'Purchase Receipt';
        XPINV: Label 'P-INV';
        XPurchaseInvoice: Label 'Purchase Invoice';
        XPPL: Label 'P-PL';
        XPurchasePriceList: Label 'Purchase Price List';
        XP00001: Label 'P00001';
        XP99999: Label 'P99999';
        XPINVPLUS: Label 'P-INV+';
        XPostedPurchaseInvoice: Label 'Posted Purchase Invoice';
        XPCR: Label 'P-CR';
        XPurchaseCreditMemo: Label 'Purchase Credit Memo';
        XPShpt: Label 'P-Shpt';
        XPostedPurchaseShipment: Label 'Posted Purchase Shipment';
        XPCRPLUS: Label 'P-CR+';
        XPostedPurchaseCreditMemo: Label 'Posted Purchase Credit Memo';

    procedure InsertMiniAppData()
    begin
        DemoDataSetup.Get();
        "Purchases & Payables Setup".Get();
        "Purchases & Payables Setup".Validate("Discount Posting", "Purchases & Payables Setup"."Discount Posting"::"All Discounts");
        "Purchases & Payables Setup".Validate("Invoice Rounding", true);
        "Purchases & Payables Setup".Validate("Receipt on Invoice", true);
        "Purchases & Payables Setup"."Copy Vendor Name to Entries" := true;
        "Create No. Series".InitBaseSeries("Purchases & Payables Setup"."Vendor Nos.", XVEND, XVendor, XV10, XV99990, '', '', 10, Enum::"No. Series Implementation"::Sequence);
        "Create No. Series".InitTempSeries("Purchases & Payables Setup"."Quote Nos.", XPQUO, XPurchaseQuote);
        "Create No. Series".InitFinalSeries("Purchases & Payables Setup"."Order Nos.", XPORD, XPurchaseOrder, 6);
        "Create No. Series".InitFinalSeries("Purchases & Payables Setup"."Posted Receipt Nos.", XPRCPT, XPurchaseReceipt, 7);
        "Create No. Series".InitFinalSeries("Purchases & Payables Setup"."Invoice Nos.", XPINV, XPurchaseInvoice, 7);
        "Create No. Series".InitFinalSeries("Purchases & Payables Setup"."Posted Invoice Nos.", XPINVPLUS, XPostedPurchaseInvoice, 8);
        "Create No. Series".InitTempSeries("Purchases & Payables Setup"."Credit Memo Nos.", XPCR, XPurchaseCreditMemo);
        "Create No. Series".InitFinalSeries("Purchases & Payables Setup"."Posted Credit Memo Nos.", XPCRPLUS, XPostedPurchaseCreditMemo, 9);
        "Create No. Series".InitBaseSeries("Purchases & Payables Setup"."Price List Nos.", XPPL, XPurchasePriceList, XP00001, XP99999, '', '', 1, Enum::"No. Series Implementation"::Sequence);
        "Create No. Series".InitTempSeries("Purchases & Payables Setup"."Blanket Order Nos.", XPBLK, XBlanketPurchaseOrder);
        "Create No. Series".InitTempSeries("Purchases & Payables Setup"."Return Order Nos.", XPRETORD, XPurchaseReturnOrder);
        "Create No. Series".InitFinalSeries("Purchases & Payables Setup"."Posted Return Shpt. Nos.", XPShpt, XPostedPurchaseShipment, 5);
        "Purchases & Payables Setup"."Appln. between Currencies" := "Purchases & Payables Setup"."Appln. between Currencies"::All;
        "Purchases & Payables Setup"."Discount Posting" := "Purchases & Payables Setup"."Discount Posting"::"All Discounts";
        "Purchases & Payables Setup"."Ext. Doc. No. Mandatory" := true;
        "Purchases & Payables Setup"."Document Default Line Type" := "Purchases & Payables Setup"."Document Default Line Type"::Item;
        "Purchases & Payables Setup".Modify();
    end;

    procedure Finalize()
    begin
        DemoDataSetup.Get();
        "Purchases & Payables Setup".Get();
        "Purchases & Payables Setup"."Invoice Nos." := XPINV;
        "Purchases & Payables Setup"."Credit Memo Nos." := XPCR;
        "Purchases & Payables Setup"."Posted Prepmt. Inv. Nos." := XPINVPLUS;
        "Purchases & Payables Setup"."Posted Prepmt. Cr. Memo Nos." := XPCRPLUS;
        "Purchases & Payables Setup".Modify();
    end;
}

