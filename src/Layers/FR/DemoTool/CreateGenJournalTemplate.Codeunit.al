codeunit 101080 "Create Gen. Journal Template"
{

    trigger OnRun()
    begin
        InsertData(
          XSTART, XOpeningentries, "Gen. Journal Template".Type::General, false, XSTART,
          XGJNLGEN, XGeneralJournal, '1', 'G01000');
        InsertData(
          XGENERAL, XGENERAL, "Gen. Journal Template".Type::General, false, '',
          XGJNLGEN, '', '', '');
        InsertData(
          XSALES, XSALES, "Gen. Journal Template".Type::Sales, false, '',
          XGJNLSALES, XSalesJournal, '1001', 'G02000');

        InsertData(
          XCASHRCPT, XCashreceipts, "Gen. Journal Template".Type::"Cash Receipts", false, '',
          XGJNLRCPT, XCashReceiptsJournal, '2001', 'G03000');
        InsertData(
          XPURCH, XPurchases, "Gen. Journal Template".Type::Purchases, false, '',
          XGJNLPURCH, XPurchaseJournal, '3001', 'G04000');
        InsertData(
          XPAYMENT, XPayments, "Gen. Journal Template".Type::Payments, false, '',
          XGJNLPMT, XPaymentJournal, '4001', 'G05000');

        InsertData(
          XASSETS, XFixedAssetGLJournal, "Gen. Journal Template".Type::Assets, false, '',
          XFAJNL, XFixedAssetJournal, '5001', 'G06000');

        InsertData(
          XJOB, XJOBGLJournal, "Gen. Journal Template".Type::Jobs, false, '',
          XGJNLJOB, XJOBGLJournal, '7001', 'G08000');

        InsertData(
          XRECURRING, XRecurringGeneralJournal, "Gen. Journal Template".Type::General, true, '',
          XGJNLREC, XRecurringGeneralJournal, '6001', 'G07000');

        "Create No. Series".InitBaseSeries(SeriesCode, XBOR, XOrderReceipt, XLCR001, XLCR999, '', '', 1);
        SetManualNoSeries();
        "Create No. Series".InitBaseSeries(SeriesCode, XLCR, XBillOfExchange, XBOE001, XBOE999, '', '', 1);
        SetManualNoSeries();
        "Create No. Series".InitBaseSeries(SeriesCode, XPRE, XWithdraw, XWID001, XWID999, '', '', 1);
        SetManualNoSeries();
        "Create No. Series".InitBaseSeries(SeriesCode, XVIR, XDraft, XDRA001, XDRA999, '', '', 1);
        SetManualNoSeries();
        "Create No. Series".InitBaseSeries(SeriesCode, XLCRENCAIS, XLCRCollectionBill, XLCRCOLL001, XLCRCOLL999, '', '', 1);
        SetManualNoSeries();
        "Create No. Series".InitBaseSeries(SeriesCode, XLCRENTETE, XLCRHeader, XLCRENT001, XLCRENT999, '', '', 1);
        SetManualNoSeries();
        "Create No. Series".InitBaseSeries(SeriesCode, XLCRREM, XLCRDiscount, XLCRDISC001, XLCRDISC999, '', '', 1);
        SetManualNoSeries();
        "Create No. Series".InitBaseSeries(SeriesCode, XBORE, XOrderReceipt2, XBORE0001, XBORE9999, '', '', 1);
        SetManualNoSeries();
        "Create No. Series".InitBaseSeries(SeriesCode, XLCRE, XBillOfExchange2, XLCRE0001, XLCRE9999, '', '', 1);
        SetManualNoSeries();
    end;

    var
        "Gen. Journal Template": Record "Gen. Journal Template";
        "Create No. Series": Codeunit "Create No. Series";
        LastNoSeriesCode: Code[20];
        XSTART: Label 'START';
        XOpeningentries: Label 'Opening entries';
        XGJNLGEN: Label 'GJNL-GEN';
        XGeneralJournal: Label 'General Journal';
        XGENERAL: Label 'GENERAL';
        XSALES: Label 'Sales';
        XGJNLSALES: Label 'GJNL-SALES';
        XSalesJournal: Label 'Sales Journal';
        XCASHRCPT: Label 'CASHRCPT';
        XCashreceipts: Label 'Cash receipts';
        XGJNLRCPT: Label 'GJNL-RCPT';
        XCashReceiptsJournal: Label 'Cash Receipts Journal';
        XPURCH: Label 'PURCH';
        XPurchases: Label 'Purchases';
        XGJNLPURCH: Label 'GJNL-PURCH';
        XPurchaseJournal: Label 'Purchase Journal';
        XPAYMENT: Label 'PAYMENT';
        XPayments: Label 'Payments';
        XGJNLPMT: Label 'GJNL-PMT';
        XPaymentJournal: Label 'Payment Journal';
        XASSETS: Label 'ASSETS';
        XFixedAssetGLJournal: Label 'Fixed Asset G/L Journal';
        XFAJNL: Label 'FA-JNL';
        XFixedAssetJournal: Label 'Fixed Asset Journal';
        XRECURRING: Label 'RECURRING';
        XRecurringGeneralJournal: Label 'Recurring General Journal';
        XGJNLREC: Label 'GJNL-REC';
        XJOB: Label 'JOB';
        XJOBGLJournal: Label 'Job G/L Journal';
        XGJNLJOB: Label 'GJNL-JOB';
        SeriesCode: Code[10];
        XBOR: Label 'BOR', Locked = true;
        XLCR: Label 'LCR';
        XPRE: Label 'PRE';
        XVIR: Label 'VIR';
        XBORE: Label 'BORE';
        XLCRE: Label 'LCRE', Locked = true;
        XLCRENCAIS: Label 'LCR-ENCAIS';
        XLCRENTETE: Label 'LCR-ENTETE';
        XLCRREM: Label 'LCR-REM';
        XWithdraw: Label 'Withdraw';
        XDraft: Label 'Draft';
        XOrderReceipt: Label 'Order Receipt';
        XOrderReceipt2: Label 'Order Receipt 2';
        XBillOfExchange: Label 'Bill Of Exchange';
        XBillOfExchange2: Label 'Bill Of Exchange 2';
        XLCRCollectionBill: Label 'LCR Collection Bill';
        XLCRHeader: Label 'LCR Header';
        XLCRDiscount: Label 'LCR Discount';
        XLCR001: Label 'LCR001';
        XLCR999: Label 'LCR999';
        XBOE001: Label 'BOE001';
        XBOE999: Label 'BOE999';
        XWID001: Label 'WID001';
        XWID999: Label 'WID999';
        XDRA001: Label 'DRA001';
        XDRA999: Label 'DRA999';
        XLCRCOLL001: Label 'LCR-COLL001';
        XLCRCOLL999: Label 'LCR-COLL999';
        XLCRENT001: Label 'LCR-ENT001';
        XLCRENT999: Label 'LCR-ENT999';
        XLCRDISC001: Label 'LCR-DISC001';
        XLCRDISC999: Label 'LCR-DISC999';
        XBORE0001: Label 'BORE0001', Locked = true;
        XLCRE0001: Label 'LCRE0001', Locked = true;
        XBORE9999: Label 'BORE9999', Locked = true;
        XLCRE9999: Label 'LCRE9999', Locked = true;

    procedure InsertData(Name: Code[10]; Description: Text[80]; Type: Enum "Gen. Journal Template Type"; Recurring: Boolean; "Source Code": Code[10]; "No. Series": Code[10]; NoSeriesDescription: Text[30]; NoSeriesStartNo: Code[20]; NoSeriesEndNo: Code[20])
    var
        NoSeries: Record "No. Series";
    begin
        if ("No. Series" <> '') and ("No. Series" <> LastNoSeriesCode) then
            if not NoSeries.Get("No. Series") then
                "Create No. Series".InitBaseSeries(
                  "No. Series", "No. Series", NoSeriesDescription, NoSeriesStartNo, NoSeriesEndNo, '', '', 1);
        LastNoSeriesCode := "No. Series";

        "Gen. Journal Template".Init();
        "Gen. Journal Template".Validate(Name, Name);
        "Gen. Journal Template".Validate(Description, Description);
        "Gen. Journal Template".Insert(true);
        "Gen. Journal Template".Validate(Type, Type);
        "Gen. Journal Template".Validate(Recurring, Recurring);
        if Recurring then
            "Gen. Journal Template".Validate("Posting No. Series", "No. Series")
        else
            "Gen. Journal Template".Validate("No. Series", "No. Series");
        if "Source Code" <> '' then
            "Gen. Journal Template".Validate("Source Code", "Source Code");
        "Gen. Journal Template".Modify();
    end;

    procedure SetManualNoSeries()
    var
        NoSeries: Record "No. Series";
    begin
        NoSeries.Get(SeriesCode);
        NoSeries."Manual Nos." := false;
        NoSeries.Modify();
    end;

    procedure InsertMiniAppData()
    begin
        InsertData(
          XGENERAL, XGENERAL, "Gen. Journal Template".Type::General, false, '',
          XGJNLGEN, XGeneralJournal, '1', 'G01000');
        UpdateCopyToPostedGenJnlLines(XGENERAL, true);

        InsertData(
          XCASHRCPT, XCashreceipts, "Gen. Journal Template".Type::"Cash Receipts", false, '',
          XGJNLRCPT, XCashReceiptsJournal, '2001', 'G03000');
        InsertData(
          XPAYMENT, XPayments, "Gen. Journal Template".Type::Payments, false, '',
          XGJNLPMT, XPaymentJournal, '4001', 'G05000');
        InsertData(
          XASSETS, XFixedAssetGLJournal, "Gen. Journal Template".Type::Assets, false, '',
          XFAJNL, XFixedAssetJournal, '5001', 'G06000');
    end;

    local procedure UpdateCopyToPostedGenJnlLines(GenJnlTemplateName: Code[10]; CopyToPostedGenJnlLines: Boolean)
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.Get(GenJnlTemplateName);
        GenJournalTemplate.Validate("Copy to Posted Jnl. Lines", CopyToPostedGenJnlLines);
        GenJournalTemplate.Modify(true);
    end;
}

