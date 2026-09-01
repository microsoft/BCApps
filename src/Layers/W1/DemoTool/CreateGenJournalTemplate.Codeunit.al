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

