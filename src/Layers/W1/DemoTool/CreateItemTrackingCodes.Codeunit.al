codeunit 118651 "Create Item Tracking Codes"
{

    trigger OnRun()
    begin
        InsertData(XFREEENTRY, XFreeentryoftracking, false, false, false, false);
        InsertData(XLOTALL, XLotspecifictracking, false, true, false, false);
        InsertData(XLOTALLEXP, XLotspecifictrackingmanExp, false, true, false, true);
        InsertData(XLOTSNSALES, XLotspecificSNSalesTracking, false, true, false, false);
        InsertData(XSNALL, XSNspecifictracking, true, false, false, false);
        InsertData(XSNSALES, XSNSalestracking, false, false, false, false);

        LastNoSeriesCode := '';
        "Create No. Series".InitBaseSeries(
          LastNoSeriesCode, XLOT, XLotNumbering, XLOT0001, XLOT9999, '', '', 1, Enum::"No. Series Implementation"::Sequence);
        "Create No. Series".InitBaseSeries(
          LastNoSeriesCode, XSN1, XSNNumbering, XSN00001, XSN99999, '', '', 1, Enum::"No. Series Implementation"::Sequence);
        "Create No. Series".InitBaseSeries(
          LastNoSeriesCode, XSN2, XSNNumbering, XXYZ00001, XXYZ99999, '', '', 1, Enum::"No. Series Implementation"::Sequence);
    end;

    var
        "Item Tracking Code": Record "Item Tracking Code";
        "Create No. Series": Codeunit "Create No. Series";
        LastNoSeriesCode: Code[20];
        XFREEENTRY: Label 'FREEENTRY';
        XFreeentryoftracking: Label 'Free entry of tracking';
        XLOTALL: Label 'LOTALL';
        XLotspecifictracking: Label 'Lot specific tracking';
        XLOTALLEXP: Label 'LOTALLEXP';
        XLotspecifictrackingmanExp: Label 'Lot specific tracking, manual Expiration';
        XLOTSNSALES: Label 'LOTSNSALES';
        XLotspecificSNSalesTracking: Label 'Lot specific SN Sales Tracking';
        XSNALL: Label 'SNALL';
        XSNspecifictracking: Label 'SN specific tracking';
        XSNSALES: Label 'SNSALES';
        XSNSalestracking: Label 'SN Sales tracking';
        XLOT: Label 'LOT';
        XLotNumbering: Label 'Lot Numbering';
        XLOT0001: Label 'LOT0001';
        XLOT9999: Label 'LOT9999';
        XSN1: Label 'SN1';
        XSNNumbering: Label 'SN Numbering';
        XSN00001: Label 'SN00001';
        XSN99999: Label 'SN99999';
        XSN2: Label 'SN2';
        XXYZ00001: Label 'XYZ00001';
        XXYZ99999: Label 'XYZ99999';

    procedure InsertData("Code": Code[10]; Description: Text[50]; "SN Specific Tracking": Boolean; "Lot Specific Tracking": Boolean; "Man. Warranty Date Entry Reqd.": Boolean; "Man. Expir. Date Entry Reqd.": Boolean)
    begin
        "Item Tracking Code".Init();
        "Item Tracking Code".Validate(Code, Code);
        "Item Tracking Code".Validate(Description, Description);
        "Item Tracking Code".Validate("SN Specific Tracking", "SN Specific Tracking");
        "Item Tracking Code".Validate("Lot Specific Tracking", "Lot Specific Tracking");
        "Item Tracking Code".Validate("Use Expiration Dates", true);
        "Item Tracking Code".Validate("Man. Warranty Date Entry Reqd.", "Man. Warranty Date Entry Reqd.");
        "Item Tracking Code".Validate("Man. Expir. Date Entry Reqd.", "Man. Expir. Date Entry Reqd.");
        case "Item Tracking Code".Code of
            'LOTSNSALES':
                begin
                    "Item Tracking Code".Validate("SN Sales Inbound Tracking", true);
                    "Item Tracking Code".Validate("SN Sales Outbound Tracking", true);
                end;
            'SNSALES':
                begin
                    "Item Tracking Code".Validate("SN Sales Inbound Tracking", true);
                    "Item Tracking Code".Validate("SN Sales Outbound Tracking", true);
                end;
        end;
        "Item Tracking Code".Insert();
    end;
}

