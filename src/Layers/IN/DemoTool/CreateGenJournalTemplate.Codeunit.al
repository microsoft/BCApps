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

        InsertData(
          XBANKPYMTVSourceCodeLbl, XBANKPYMTV, "Gen. Journal Template".Type::"Bank Payment Voucher", false, XBANKPYMTVSourceCodeLbl,
          XBANKPYMTVSourceCodeLbl, XBANKPYMTV, 'BP-00001', 'BP-00700');

        InsertData(
          XBANKRCPTVSourceCodeLbl, XBANKRCPTV, "Gen. Journal Template".Type::"Bank Receipt Voucher", false, XBANKRCPTVSourceCodeLbl,
          XBANKRCPTVSourceCodeLbl, XBANKRCPTV, 'BR-00001', 'BR-00700');

        InsertData(
          XCASHPYMTVSourceCodeLbl, XCASHPYMTV, "Gen. Journal Template".Type::"Cash Payment Voucher", false, XCASHPYMTVSourceCodeLbl,
          XCASHPYMTVSourceCodeLbl, XCASHPYMTV, 'CP-00001', 'CP-00700');

        InsertData(
          XCASHRCPTVSourceCodeLbl, XCASHRCPTV, "Gen. Journal Template".Type::"Cash Receipt Voucher", false, XCASHRCPTVSourceCodeLbl,
          XCASHRCPTVSourceCodeLbl, XCASHRCPTV, 'CR-00001', 'CR-00700');

        InsertData(
          XCONTRAVSourceCodeLbl, XCONTRAV, "Gen. Journal Template".Type::"Contra Voucher", false, XCONTRAVSourceCodeLbl,
          XCONTRAVSourceCodeLbl, XCONTRAV, 'CV-00001', 'CV-00700');

        InsertData(
          XJOURNALVSourceCodeLbl, XJOURNALV, "Gen. Journal Template".Type::"Journal Voucher", false, XJOURNALVSourceCodeLbl,
          XJOURNALVSourceCodeLbl, XJOURNALV, 'JV-00001', 'JV-00700');

        UpdatePostingNoSeries(XBANKPYMTVSourceCodeLbl, XBNKPYVP, XPostedBankPaymentVoucher, 'PBP-00001', '');
        UpdatePostingNoSeries(XBANKRCPTVSourceCodeLbl, XBNKRCVP, XPostedBankReceiptVoucher, 'PBR-00001', '');
        UpdatePostingNoSeries(XCASHPYMTVSourceCodeLbl, XCSHPYVP, XPostedCashPaymentVoucher, 'PCP-00001', '');
        UpdatePostingNoSeries(XCASHRCPTVSourceCodeLbl, XCSHRCVP, XPostedCashReceiptVoucher, 'PCR-00001', '');
        UpdatePostingNoSeries(XCONTRAVSourceCodeLbl, XCNTRVP, XPostedContraVoucher, 'PCV-00001', '');
        UpdatePostingNoSeries(XJOURNALVSourceCodeLbl, XJRNLVP, XPostedJournalVoucher, 'PJV-00001', '');
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
        XBANKPYMTV: Label 'Bank Payment Voucher';
        XBANKRCPTV: Label 'Bank Receipt Voucher';
        XCASHPYMTV: Label 'Cash Payment Voucher';
        XCASHRCPTV: Label 'Cash Receipt Voucher';
        XCONTRAV: Label 'Contra Voucher';
        XJOURNALV: Label 'Journal Voucher';
        XBANKPYMTVSourceCodeLbl: Label 'BANKPYMTV';
        XBANKRCPTVSourceCodeLbl: Label 'BANKRCPTV';
        XCASHPYMTVSourceCodeLbl: Label 'CASHPYMTV';
        XCASHRCPTVSourceCodeLbl: Label 'CASHRCPTV';
        XCONTRAVSourceCodeLbl: Label 'CONTRAV';
        XJOURNALVSourceCodeLbl: Label 'JOURNALV';
        XBNKPYVP: Label 'BNKPYV-P';
        XBNKRCVP: Label 'BNKRCV-P';
        XCSHPYVP: Label 'CSHPYV-P';
        XCSHRCVP: Label 'CSHRCV-P';
        XCNTRVP: Label 'CNTRV-P';
        XJRNLVP: Label 'JRNLV-P';
        XPostedBankPaymentVoucher: Label 'Posted Bank Payment Voucher';
        XPostedBankReceiptVoucher: Label 'Posted Bank Receipt Voucher';
        XPostedCashPaymentVoucher: Label 'Posted Cash Payment Voucher';
        XPostedCashReceiptVoucher: Label 'Posted Cash Receipt Voucher';
        XPostedContraVoucher: Label 'Posted Contra Voucher';
        XPostedJournalVoucher: Label 'Posted Journal Voucher';

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

        InsertData(
          XBANKPYMTVSourceCodeLbl, XBANKPYMTV, "Gen. Journal Template".Type::"Bank Payment Voucher", false, XBANKPYMTVSourceCodeLbl,
          XBANKPYMTVSourceCodeLbl, XBANKPYMTV, 'BP-00001', 'BP-00700');

        InsertData(
          XBANKRCPTVSourceCodeLbl, XBANKRCPTV, "Gen. Journal Template".Type::"Bank Receipt Voucher", false, XBANKRCPTVSourceCodeLbl,
          XBANKRCPTVSourceCodeLbl, XBANKRCPTV, 'BR-00001', 'BR-00700');

        InsertData(
          XCASHPYMTVSourceCodeLbl, XCASHPYMTV, "Gen. Journal Template".Type::"Cash Payment Voucher", false, XCASHPYMTVSourceCodeLbl,
          XCASHPYMTVSourceCodeLbl, XCASHPYMTV, 'CP-00001', 'CP-00700');

        InsertData(
          XCASHRCPTVSourceCodeLbl, XCASHRCPTV, "Gen. Journal Template".Type::"Cash Receipt Voucher", false, XCASHRCPTVSourceCodeLbl,
          XCASHRCPTVSourceCodeLbl, XCASHRCPTV, 'CR-00001', 'CR-00700');

        InsertData(
          XCONTRAVSourceCodeLbl, XCONTRAV, "Gen. Journal Template".Type::"Contra Voucher", false, XCONTRAVSourceCodeLbl,
          XCONTRAVSourceCodeLbl, XCONTRAV, 'CV-00001', 'CV-00700');

        InsertData(
          XJOURNALVSourceCodeLbl, XJOURNALV, "Gen. Journal Template".Type::"Journal Voucher", false, XJOURNALVSourceCodeLbl,
          XJOURNALVSourceCodeLbl, XJOURNALV, 'JV-00001', 'JV-00700');

        UpdatePostingNoSeries(XBANKPYMTVSourceCodeLbl, XBNKPYVP, XPostedBankPaymentVoucher, 'PBP-00001', '');
        UpdatePostingNoSeries(XBANKRCPTVSourceCodeLbl, XBNKRCVP, XPostedBankReceiptVoucher, 'PBR-00001', '');
        UpdatePostingNoSeries(XCASHPYMTVSourceCodeLbl, XCSHPYVP, XPostedCashPaymentVoucher, 'PCP-00001', '');
        UpdatePostingNoSeries(XCASHRCPTVSourceCodeLbl, XCSHRCVP, XPostedCashReceiptVoucher, 'PCR-00001', '');
        UpdatePostingNoSeries(XCONTRAVSourceCodeLbl, XCNTRVP, XPostedContraVoucher, 'PCV-00001', '');
        UpdatePostingNoSeries(XJOURNALVSourceCodeLbl, XJRNLVP, XPostedJournalVoucher, 'PJV-00001', '');
    end;

    local procedure UpdatePostingNoSeries(Name: Code[10]; PostingNoSeries: Code[20]; NoSeriesDescription: Text[30]; NoSeriesStartNo: Code[20]; NoSeriesEndNo: Code[20])
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        "Create No. Series".InitBaseSeries(
              PostingNoSeries, PostingNoSeries, NoSeriesDescription, NoSeriesStartNo, NoSeriesEndNo, '', '', 1);

        if GenJournalTemplate.Get(Name) then begin
            GenJournalTemplate."Posting No. Series" := PostingNoSeries;
            GenJournalTemplate.Modify();
        end;
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

