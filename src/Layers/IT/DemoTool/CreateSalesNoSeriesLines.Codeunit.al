codeunit 161345 "Create Sales No. Series Lines"
{

    trigger OnRun()
    var
        CreateNoSeries: Codeunit "Create No. Series";
        NoSeries: Record "No. Series";
        TempSeriesCode: Code[10];
        MakeAdj: Codeunit "Make Adjustments";
    begin
        CreateNoSeries.InsertSeries(TempSeriesCode, XxEUVNSLS, XInvCrMemoVATNoForEUCust, XxC010001, '', '', '', 1, true,
                                           NoSeries."No. Series Type"::Sales, XxEUSALES, 0, '', true);
        CreateNoSeries.InsertSeries(TempSeriesCode, XxITVNSLS, XInvCrMemoVATNoForItalianCust, '102001', '', '', '', 1, true,
                                           NoSeries."No. Series Type"::Sales, XxNATSALES, 0, '', true);
        CreateNoSeries.InsertSeries(TempSeriesCode, XxEXTVNSLS, XInvCrMemoVATNoForExtraEUCust, XxCX010001, '', '', '', 1,
                                           true, NoSeries."No. Series Type"::Sales, XxEXTSALES, 0, '', true);

        InsertData(XxEUVNSLS, 10000, XxC010001, 1, true, MakeAdj.AdjustDate(DMY2Date(1, 1, 1901)));
        InsertData(XxITVNSLS, 10000, '102001', 1, true, MakeAdj.AdjustDate(DMY2Date(1, 1, 1901)));
        InsertData(XxEXTVNSLS, 10000, XxCX010001, 1, true, MakeAdj.AdjustDate(DMY2Date(1, 1, 1901)));

        InsertData(XxEUVNSLS, 20000, XxC010001, 1, true, MakeAdj.AdjustDate(DMY2Date(1, 1, 1902)));
        InsertData(XxITVNSLS, 20000, '102001', 1, true, MakeAdj.AdjustDate(DMY2Date(1, 1, 1902)));
        InsertData(XxEXTVNSLS, 20000, XxCX010001, 1, true, MakeAdj.AdjustDate(DMY2Date(1, 1, 1902)));

        InsertData(XxEUVNSLS, 30000, XxC010001, 1, true, MakeAdj.AdjustDate(DMY2Date(1, 1, 1903)));
        InsertData(XxITVNSLS, 30000, '102001', 1, true, MakeAdj.AdjustDate(DMY2Date(1, 1, 1903)));
        InsertData(XxEXTVNSLS, 30000, XxCX010001, 1, true, MakeAdj.AdjustDate(DMY2Date(1, 1, 1903)));

        InsertData(XxEUVNSLS, 40000, XxC010001, 1, true, MakeAdj.AdjustDate(DMY2Date(1, 1, 1904)));
        InsertData(XxITVNSLS, 40000, '102001', 1, true, MakeAdj.AdjustDate(DMY2Date(1, 1, 1904)));
        InsertData(XxEXTVNSLS, 40000, XxCX010001, 1, true, MakeAdj.AdjustDate(DMY2Date(1, 1, 1904)));
    end;

    var
        XxEUVNSLS: Label 'EU-VN-SLS';
        XInvCrMemoVATNoForEUCust: Label 'Inv./Cr. Memo VAT No. for EU Cust.';
        XxC010001: Label 'C010001';
        XxEUSALES: Label 'EUSALES';
        XxITVNSLS: Label 'IT-VN-SLS';
        XInvCrMemoVATNoForItalianCust: Label 'Inv./Cr. Memo VAT No. for Italian Cust.';
        XxNATSALES: Label 'NATSALES';
        XxEXTVNSLS: Label 'EXT-VN-SLS';
        XInvCrMemoVATNoForExtraEUCust: Label 'Inv./Cr. Memo VAT No. for ExtraEU Customers';
        XxCX010001: Label 'CX010001';
        XxEXTSALES: Label 'EXTSALES';

    procedure InsertData(SeriesCode: Code[10]; LineNo: Integer; StartingNo: Code[20]; IncrementByNo: Integer; Open: Boolean; StartDate: Date)
    var
        NoSeriesLineSales: Record "No. Series Line";
    begin
        NoSeriesLineSales.Init();
        NoSeriesLineSales.Validate("Series Code", SeriesCode);
        NoSeriesLineSales.Validate("Line No.", LineNo);
        //NoSeriesLineSales.VALIDATE("Starting No.",StartingNo);
        NoSeriesLineSales.Validate("Starting No.", CopyStr(Format(StartDate, 0, '<year4>'), 3, 2) + '-' + StartingNo);
        NoSeriesLineSales.Validate("Increment-by No.", IncrementByNo);
        NoSeriesLineSales.Validate(Open, Open);
        NoSeriesLineSales.Validate("Starting Date", StartDate); // IT
        NoSeriesLineSales.Insert();
    end;
}

