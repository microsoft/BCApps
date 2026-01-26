codeunit 161346 "Create Purch. No. Series Lines"
{

    trigger OnRun()
    var
        CreateNoSeries: Codeunit "Create No. Series";
        NoSeries: Record "No. Series";
        TempSeriesCode: Code[10];
        MakeAdj: Codeunit "Make Adjustments";
    begin
        CreateNoSeries.InsertSeries(TempSeriesCode, XxEUVNPUR, XInvCrMemoVATNoForEUVend, XxV010001, '', '', '', 1, true,
                                         NoSeries."No. Series Type"::Purchase, XxEUPURCH, 0, XxEUVNSLS, true, Enum::"No. Series Implementation"::Sequence);
        CreateNoSeries.InsertSeries(TempSeriesCode, XxITVNPUR, XInvCrMemoVATNoForItalianVend, '108001', '', '', '', 1, true,
                                         NoSeries."No. Series Type"::Purchase, XxNATPURCH, 0, '', true, Enum::"No. Series Implementation"::Sequence);
        CreateNoSeries.InsertSeries(TempSeriesCode, XxEXTVNPUR, XInvCrMemoVATNoForExtraEUVend, XxFX010001, '', '', '', 1,
                                         true, NoSeries."No. Series Type"::Purchase, XxEXTPURCH, 0, '', true, Enum::"No. Series Implementation"::Sequence);

        InsertData(XxEUVNPUR, 10000, XxV010001, 1, true, MakeAdj.AdjustDate(DMY2Date(1, 1, 1901)));
        InsertData(XxITVNPUR, 10000, '108001', 1, true, MakeAdj.AdjustDate(DMY2Date(1, 1, 1901)));
        InsertData(XxEXTVNPUR, 10000, XxFX010001, 1, true, MakeAdj.AdjustDate(DMY2Date(1, 1, 1901)));

        InsertData(XxEUVNPUR, 20000, XxV010001, 1, true, MakeAdj.AdjustDate(DMY2Date(1, 1, 1902)));
        InsertData(XxITVNPUR, 20000, '108001', 1, true, MakeAdj.AdjustDate(DMY2Date(1, 1, 1902)));
        InsertData(XxEXTVNPUR, 20000, XxFX010001, 1, true, MakeAdj.AdjustDate(DMY2Date(1, 1, 1902)));

        InsertData(XxEUVNPUR, 30000, XxV010001, 1, true, MakeAdj.AdjustDate(DMY2Date(1, 1, 1903)));
        InsertData(XxITVNPUR, 30000, '108001', 1, true, MakeAdj.AdjustDate(DMY2Date(1, 1, 1903)));
        InsertData(XxEXTVNPUR, 30000, XxFX010001, 1, true, MakeAdj.AdjustDate(DMY2Date(1, 1, 1903)));

        InsertData(XxEUVNPUR, 40000, XxV010001, 1, true, MakeAdj.AdjustDate(DMY2Date(1, 1, 1904)));
        InsertData(XxITVNPUR, 40000, '108001', 1, true, MakeAdj.AdjustDate(DMY2Date(1, 1, 1904)));
        InsertData(XxEXTVNPUR, 40000, XxFX010001, 1, true, MakeAdj.AdjustDate(DMY2Date(1, 1, 1904)));
    end;

    var
        XxEUVNPUR: Label 'EU-VN-PUR';
        XInvCrMemoVATNoForEUVend: Label 'Inv./Cr. Memo VAT No. for EU Vend.';
        XxV010001: Label 'V010001';
        XxEUPURCH: Label 'EUPURCH';
        XxEUVNSLS: Label 'EU-VN-SLS';
        XxITVNPUR: Label 'IT-VN-PUR';
        XInvCrMemoVATNoForItalianVend: Label 'Inv./Cr. Memo VAT No. for Italian Vend.';
        XxNATPURCH: Label 'NATPURCH';
        XxEXTVNPUR: Label 'EXT-VN-PUR';
        XInvCrMemoVATNoForExtraEUVend: Label 'Inv./Cr. Memo VAT No. for ExtraEU Vendors';
        XxFX010001: Label 'FX010001';
        XxEXTPURCH: Label 'EXTPURCH';

    procedure InsertData(SeriesCode: Code[10]; LineNo: Integer; StartingNo: Code[20]; IncrementByNo: Integer; Open: Boolean; StartDate: Date)
    var
        NoSeriesLinePurchase: Record "No. Series Line";
    begin
        NoSeriesLinePurchase.Init();
        NoSeriesLinePurchase.Validate("Series Code", SeriesCode);
        NoSeriesLinePurchase.Validate("Line No.", LineNo);
        //NoSeriesLinePurchase.VALIDATE("Starting No.",StartingNo);
        NoSeriesLinePurchase.Validate("Starting No.", CopyStr(Format(StartDate, 0, '<year4>'), 3, 2) + '-' + StartingNo);
        NoSeriesLinePurchase.Validate("Increment-by No.", IncrementByNo);
        NoSeriesLinePurchase.Validate(Open, Open);
        NoSeriesLinePurchase.Validate("Starting Date", StartDate); // IT
        NoSeriesLinePurchase.Insert();
    end;
}

