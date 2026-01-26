codeunit 101080 "Create Gen. Journal Template"
{

    trigger OnRun()
    begin
        "Create No. Series".InitFinalSeries(PostedInvoiceNos, XSINVPLUS, XPostedSalesInvoice, 3);
        "Create No. Series".InitFinalSeries(PostedInvoiceNos, XPINVPLUS, XPostedPurchaseInvoice, 8);
        "Create No. Series".InitFinalSeries(PostedCreditMemoNos, XSCRPLUS, XPostedSalesCreditMemo, 4);
        "Create No. Series".InitFinalSeries(PostedCreditMemoNos, XPCRPLUS, XPostedPurchaseCreditMemo, 9);
        "Create No. Series".InitFinalSeries(PostedInvoiceNos, XICSINVPLUS, XICPostedSalesInvoice, 3);
        "Create No. Series".InitFinalSeries(PostedInvoiceNos, XICPINVPLUS, XICPostedPurchaseInvoice, 8);
        "Create No. Series".InitFinalSeries(PostedCreditMemoNos, XICSCRPLUS, XICPostedSalesCreditMemo, 4);
        "Create No. Series".InitFinalSeries(PostedCreditMemoNos, XICPCRPLUS, XICPostedPurchaseCreditMemo, 9);

        InsertData(
          XSTART, XOpeningentries, "Gen. Journal Template".Type::General, false, XSTART,
          XGJNLGEN, XGeneralJournal, '1', 'G01000', '');
        InsertData(
          XGENERAL, XGENERAL, "Gen. Journal Template".Type::General, false, '',
          XGJNLGEN, '', '', '', '');
        InsertData(
          XSALES, XSALES, "Gen. Journal Template".Type::Sales, false, '',
          XGJNLSALES, XSalesJournal, '1001', 'G02000', XSINVPLUS);

        InsertData(
          XCASHRCPT, XCashreceipts, "Gen. Journal Template".Type::"Cash Receipts", false, '',
          XGJNLRCPT, XCashReceiptsJournal, '2001', 'G03000', '');
        InsertData(
          XPURCH, XPurchases, "Gen. Journal Template".Type::Purchases, false, '',
          XGJNLPURCH, XPurchaseJournal, '3001', 'G04000', XPINVPLUS);
        InsertData(
          XPAYMENT, XPayments, "Gen. Journal Template".Type::Payments, false, '',
          XGJNLPMT, XPaymentJournal, '4001', 'G05000', '');

        InsertData(
          XASSETS, XFixedAssetGLJournal, "Gen. Journal Template".Type::Assets, false, '',
          XFAJNL, XFixedAssetJournal, '5001', 'G06000', '');

        InsertData(
          XJOB, XJOBGLJournal, "Gen. Journal Template".Type::Jobs, false, '',
          XGJNLJOB, XJOBGLJournal, '7001', 'G08000', '');

        InsertData(
          XRECURRING, XRecurringGeneralJournal, "Gen. Journal Template".Type::General, true, '',
          XGJNLREC, XRecurringGeneralJournal, '6001', 'G07000', '');
        InsertData(
          XSALESCR, XSalesCreditMemo, "Gen. Journal Template".Type::Sales, false, '',
          XGJNLSCR, XSalesCreditMemoJournal, '1501', 'G02500', XSCRPLUS);
        InsertData(
          XPURCHCR, XPurchCreditMemo, "Gen. Journal Template".Type::Purchases, false, '',
          XGJNLPCR, XPurchCreditMemoJournal, '3501', 'G04500', XPCRPLUS);
        InsertData(
          XICSALES, XIntercompSales, "Gen. Journal Template".Type::Intercompany, false, '',
          XICGJNLSALES, XIntercompSalesJournal, '1001', 'G02000', XICSINVPLUS);
        InsertData(
          XICSALESCR, XIntercompSalesCrMemo, "Gen. Journal Template".Type::Intercompany, false, '',
          XICGJNLSALESCR, XIntercompSalesCrJournal, '1501', 'G02500', XICSCRPLUS);
        InsertData(
          XICPURCH, XIntercompPurch, "Gen. Journal Template".Type::Intercompany, false, '',
          XICGJNLPURCH, XIntercompPurchJournal, '3001', 'G04000', XICPINVPLUS);
        InsertData(
          XICPURCHCR, XIntercompPurchCrMemo, "Gen. Journal Template".Type::Intercompany, false, '',
          XICGJNLPURCHCR, XIntercompPurchCrJournal, '3501', 'G04500', XICPCRPLUS);

        InsertData(
          XFINANCE, XWWBOPERATING, "Gen. Journal Template".Type::Financial, false, '',
          XGJNLFIN, XFinancialJournal, '4001', 'G05000', '');
        InsertData(
          XWWBEUR, XWWBEUR, "Gen. Journal Template".Type::Financial, false, '',
          '', '', '', '', '');
        InsertData(
          XPERIODIC, XPeriodicPostings, "Gen. Journal Template".Type::General, false, '',
          XGJNLPER, XPeriodicPostings, '6501', 'G07500', '');

        InsertData(
          XSMINV, XServiceInvoice, "Gen. Journal Template".Type::Sales, false, '',
          '', '', '', '', XSMINVPLUS);
        InsertData(
          XSMCR, XServiceCreditMemo, "Gen. Journal Template".Type::Sales, false, '',
          '', '', '', '', XSMCRPLUS);
        InsertData(
          XSMCONINV, XServiceContractsInvoices, "Gen. Journal Template".Type::Sales, false, '',

          '', '', '', '', XSMINVPLUS);
        InsertData(
          XSMCONCM, XServiceContractsCM, "Gen. Journal Template".Type::Sales, false, '',
          '', '', '', '', XSMCRPLUS);
    end;

    var
        "Gen. Journal Template": Record "Gen. Journal Template";
        "Create No. Series": Codeunit "Create No. Series";
        LastNoSeriesCode: Code[20];
        PostedInvoiceNos: Code[20];
        PostedCreditMemoNos: Code[20];
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
        XSINVPLUS: Label 'S-INV+';
        XPostedSalesInvoice: Label 'Posted Sales Invoice';
        XPINVPLUS: Label 'P-INV+';
        XPostedPurchaseInvoice: Label 'Posted Purchase Invoice';
        XSCRPLUS: Label 'S-CR+';
        XPostedSalesCreditMemo: Label 'Posted Sales Credit Memo';
        XPCRPLUS: Label 'P-CR+';
        XPostedPurchaseCreditMemo: Label 'Posted Purchase Credit Memo';
        XSALESCR: Label 'SALES-CR';
        XSalesCreditMemo: Label 'Sales Credit Memo';
        XGJNLSCR: Label 'GJNL-S-CR';
        XSalesCreditMemoJournal: Label 'Sales Credit Memo Journal';
        XSMINV: Label 'SM-INV';
        XSMCONINV: Label 'SM-CON-INV';
        XServiceContractsInvoices: Label 'Service Contracts Invoices';
        XSMCONCM: Label 'SM-CON-CM';
        XServiceContractsCM: Label 'Service Contracts CM';
        XPURCHCR: Label 'PURCH-CR';
        XPurchCreditMemo: Label 'Purch. Credit Memo';
        XGJNLPCR: Label 'GJNL-P-CR';
        XPurchCreditMemoJournal: Label 'Purch. Credit Memo Journal';
        XFINANCE: Label 'FINANCE';
        XWWBOPERATING: Label 'WWB-OPERATING';
        XGJNLFIN: Label 'GJNL-FIN';
        XFinancialJournal: Label 'Financial Journal';
        XWWBEUR: Label 'WWB-EUR';
        XPERIODIC: Label 'PERIODIC';
        XPeriodicPostings: Label 'Periodic Postings';
        XGJNLPER: Label 'GJNL-PER';
        XSMCR: Label 'SM-CR';
        XServiceInvoice: Label 'Service Invoice';
        XServiceCreditMemo: Label 'Service Credit Memo';
        XSMINVPLUS: Label 'SM-INV+';
        XSMCRPLUS: Label 'SM-CR+';
        XICSALES: Label 'IC-SALES';
        XICSALESCR: Label 'IC-SALESCR';
        XICPURCH: Label 'IC-PURCH';
        XICPURCHCR: Label 'IC-PURCHCR';
        XIntercompSales: Label 'Intercompany Sales';
        XIntercompSalesCrMemo: Label 'Intercompany Sales Cr. Memo';
        XIntercompPurch: Label 'Intercompany Purchase';
        XIntercompPurchCrMemo: Label 'Intercompany Purch. Cr. Memo';
        XICGJNLSALES: Label 'IC-GJNL-S';
        XICGJNLSALESCR: Label 'IC-JNL-SCR';
        XICGJNLPURCH: Label 'IC-GJNL-P';
        XICGJNLPURCHCR: Label 'IC-JNL-PCR';
        XIntercompSalesJournal: Label 'Intercompany Sales Journal';
        XIntercompSalesCrJournal: Label 'IC. Sales Cr. Memo Journal';
        XIntercompPurchJournal: Label 'Intercompany Purch. Journal';
        XIntercompPurchCrJournal: Label 'IC Purch. Cr. Memo Journal';
        XICSINVPLUS: Label 'IC-S-INV+';
        XICSCRPLUS: Label 'IC-S-CR+';
        XICPINVPLUS: Label 'IC-P-INV+';
        XICPCRPLUS: Label 'IC-P-CR+';
        XICPostedSalesInvoice: Label 'IC Posted Sales Invoice';
        XICPostedSalesCreditMemo: Label 'IC Posted Sales Credit Memo';
        XICPostedPurchaseInvoice: Label 'IC Posted Purchase Invoice';
        XICPostedPurchaseCreditMemo: Label 'IC Posted Purchase Credit Memo';

    procedure InsertData(Name: Code[10]; Description: Text[80]; Type: Enum "Gen. Journal Template Type"; Recurring: Boolean; "Source Code": Code[10]; "No. Series": Code[10]; NoSeriesDescription: Text[30]; NoSeriesStartNo: Code[20]; NoSeriesEndNo: Code[20]; PostNoSeries: Code[20])
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
            if "Gen. Journal Template".Type <> "Gen. Journal Template".Type::Financial then
                "Gen. Journal Template".Validate("No. Series", "No. Series");
        if "Source Code" <> '' then
            "Gen. Journal Template".Validate("Source Code", "Source Code");
        if PostNoSeries <> '' then
            "Gen. Journal Template"."Posting No. Series" := PostNoSeries;
        if "Gen. Journal Template".Type = "Gen. Journal Template".Type::Financial then begin
            "Gen. Journal Template".Validate("Bal. Account Type", "Gen. Journal Template"."Bal. Account Type"::"Bank Account");
            "Gen. Journal Template"."Bal. Account No." := "Gen. Journal Template".Description;
        end;
        "Gen. Journal Template".Modify();
    end;

    procedure InsertMiniAppData()
    begin
        InsertData(
          XGENERAL, XGENERAL, "Gen. Journal Template".Type::General, false, '',
          XGJNLGEN, XGeneralJournal, '1', 'G01000', '');
        UpdateCopyToPostedGenJnlLines(XGENERAL, true);

        InsertData(
          XCASHRCPT, XCashreceipts, "Gen. Journal Template".Type::"Cash Receipts", false, '',
          XGJNLRCPT, XCashReceiptsJournal, '2001', 'G03000', '');
        InsertData(
          XPAYMENT, XPayments, "Gen. Journal Template".Type::Payments, false, '',
          XGJNLPMT, XPaymentJournal, '4001', 'G05000', '');
        InsertData(
          XASSETS, XFixedAssetGLJournal, "Gen. Journal Template".Type::Assets, false, '',
          XFAJNL, XFixedAssetJournal, '5001', 'G06000', '');

        InsertData(
          XPURCH, XPurchases, "Gen. Journal Template".Type::Purchases, false, '',
          XGJNLPURCH, XPurchaseJournal, '3001', 'G04000', XPINVPLUS);
        InsertData(
          XPURCHCR, XPurchCreditMemo, "Gen. Journal Template".Type::Purchases, false, '',
          XGJNLPCR, XPurchCreditMemoJournal, '3501', 'G04500', XPCRPLUS);
        InsertData(
          XSALES, XSALES, "Gen. Journal Template".Type::Sales, false, '',
          XGJNLSALES, XSalesJournal, '1001', 'G02000', XSINVPLUS);
        InsertData(
          XSALESCR, XSalesCreditMemo, "Gen. Journal Template".Type::Sales, false, '',
          XGJNLSCR, XSalesCreditMemoJournal, '1501', 'G02500', XSCRPLUS);
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

