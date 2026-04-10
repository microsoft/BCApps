codeunit 101232 "Create Gen. Journal Batch"
{

    trigger OnRun()
    begin
        InsertData(XSTART, XCUSTOPEN, XCustomers, "Gen. Journal Account Type"::"G/L Account", '', true, '', false, false);
        InsertData(XSTART, XGLOPEN, XGLAccounts, "Gen. Journal Account Type"::"G/L Account", '', true, '', false, false);
        InsertData(XSTART, XPERIODIC, XPERIODIC, "Gen. Journal Account Type"::"G/L Account", '', true, '', false, false);
        InsertData(XSTART, XVENDOPEN, XVendors, "Gen. Journal Account Type"::"G/L Account", '', true, '', false, false);
        InsertData(XSTART, XBANKOPEN, XBank, "Gen. Journal Account Type"::"G/L Account", '', true, '', false, false);
        InsertData(XSTART, XDEFAULT, XOther, "Gen. Journal Account Type"::"G/L Account", '', true, '', false, false);

        InsertData(XSTART, XDEPR, XPeriodicDepr, "Gen. Journal Account Type"::"G/L Account", '', true, '', false, false);
        InsertData(XASSETS, XDEFAULT, XDefaultJournalBatch, "Gen. Journal Account Type"::"G/L Account", '', true, '', false, false);
        InsertData(XJOB, XDEFAULT, XDefaultJournalBatch, "Gen. Journal Account Type"::"G/L Account", '', true, '', false, false);

        InsertData(XGENERAL, XDEFAULT, XDefaultJournalBatch, "Gen. Journal Account Type"::"G/L Account", '', true, '', true, false);
        InsertData(XSALES, XDEFAULT, XDefaultJournalBatch, "Gen. Journal Account Type"::"G/L Account", '', true, '', false, false);
        InsertData(XPURCH, XDEFAULT, XDefaultJournalBatch, "Gen. Journal Account Type"::"G/L Account", '', true, '', false, false);

        InsertData(
          XCASHRCPT, XWWBUSD, XWorldWideBank + ' USD',
          "Gen. Journal Batch"."Bal. Account Type"::"Bank Account", XWWBUSD, false, '', false, false);
        InsertData(
          XCASHRCPT, XWWBEUR, XWorldWideBank + ' EUR',
          "Gen. Journal Batch"."Bal. Account Type"::"Bank Account", XWWBEUR, false, '', false, false);
        InsertData(
          XCASHRCPT, XWWBRUR, XWorldWideBank + ' RUR',
          "Gen. Journal Batch"."Bal. Account Type"::"Bank Account", XWWBRUR, false, '', false, false);

        InsertData(
          XPAYMENT, XWWBUSD, XWorldWideBank + ' USD',
          "Gen. Journal Batch"."Bal. Account Type"::"Bank Account", XWWBUSD, false, '', false, false);
        InsertData(
          XPAYMENT, XWWBEUR, XWorldWideBank + ' EUR',
          "Gen. Journal Batch"."Bal. Account Type"::"Bank Account", XWWBEUR, false, '', false, false);
        InsertData(
          XPAYMENT, XWWBRUR, XWorldWideBank + ' RUR',
          "Gen. Journal Batch"."Bal. Account Type"::"Bank Account", XWWBRUR, false, '', false, false);
        InsertData(
          XPAYMENT, XNBL, XNewBankofLondon,
          "Gen. Journal Batch"."Bal. Account Type"::"Bank Account", XNBL, false, '', false, false);

        InsertData(
          XCASHORDER, XCASHRUR + '1', XCashOrderPayments,
          "Gen. Journal Batch"."Bal. Account Type"::"Bank Account", XCASH + '1', false, '', false, false);

        InsertData(
          XCASHORDER, XCASHRUR + '2', XCashOrderPayments,
          "Gen. Journal Batch"."Bal. Account Type"::"Bank Account", XCASH + '2', false, '', false, false);

        InsertData(XVATSET, XDEFAULT, XVATSettlement, "Gen. Journal Account Type"::"G/L Account", '', false, '', false, false);
        InsertData(XASSETS, XFUTEXP, XFutureExpences, "Gen. Journal Account Type"::"G/L Account", '', false, '', false, false);

        InsertData(XRECURRING, XDEFAULT, XDefaultJournalBatch, "Gen. Journal Account Type"::"G/L Account", '', false, '', false, false);

        InsertData(XRECURRING, XDIVIDENDS, XDividendOperations, "Gen. Journal Account Type"::"G/L Account", '', false, '', false, false);
        InsertData(XRECURRING, XLOANS, XLoansGiven, "Gen. Journal Account Type"::"G/L Account", '', false, '', false, false);
        InsertData(XRECURRING, XCLOSE + '_20', XClosingAccount + ' 20', "Gen. Journal Account Type"::"G/L Account", '', false, '', false, false);
        InsertData(XRECURRING, XCLOSE + '_26', XClosingAccount + ' 26', "Gen. Journal Account Type"::"G/L Account", '', false, '', false, false);
        InsertData(XRECURRING, XCLOSE + '_44', XClosingAccount + ' 44', "Gen. Journal Account Type"::"G/L Account", '', false, '', false, false);
        InsertData(XRECURRING, XCLOSE + '_9091', XClosingAccount + ' 90,91', "Gen. Journal Account Type"::"G/L Account", '', false, '', false, false);
        InsertData(XRECURRING, XTAXDIFF, XTaxDifferences, "Gen. Journal Account Type"::"G/L Account", '', false, '', false, false);
        InsertData(XRECURRING, XPROPTAX, XPropertyTax, "Gen. Journal Account Type"::"G/L Account", '', false, '', false, false);
        InsertData(XRECURRING, XBALREFORM, XBalanceReformation, "Gen. Journal Account Type"::"G/L Account", '', false, '', false, false);
        InsertData(XRECURRING, XINSURANCE, XInsurance2, "Gen. Journal Account Type"::"G/L Account", '', false, '', false, false);
        InsertData(XRECURRING, XCURCREDPR, XInterestsfromCurrencyCredits, "Gen. Journal Account Type"::"G/L Account", '', false, '', false, false);
        InsertData(XRECURRING, XCREDPR, XInterestsfromRubleCredits, "Gen. Journal Account Type"::"G/L Account", '', false, '', false, false);
        InsertData(XRECURRING, XDEPOSITPR, XInterestsfromDeposits, "Gen. Journal Account Type"::"G/L Account", '', false, '', false, false);
        InsertData(XRECURRING, XLOANPR + '_66', XInterestsfromLoans, "Gen. Journal Account Type"::"G/L Account", '', false, '', false, false);
        InsertData(XRECURRING, XLOANPR + '_67', XInterestsfromLoans, "Gen. Journal Account Type"::"G/L Account", '', false, '', false, false);

        InsertData(XPAYROLL, XDEFAULT, XPayrollPosting, "Gen. Journal Account Type"::"G/L Account", '', false, '', false, false);

        InsertData(XPAYROLL, XWWBRUR, XWorldWideBank + ' RUR',
          "Gen. Journal Batch"."Bal. Account Type"::"Bank Account", XWWBRUR, false, '', false, false);
        InsertData(XPAYMENT, XPmtRegTxt, XBankReconciliationTxt,
          "Gen. Journal Batch"."Bal. Account Type"::"Bank Account", XWWBRUR, true, '', false, true);
        InsertData(
          XPAYMENT, XBankConvTxt, XBankConvDescTxt,
          "Gen. Journal Batch"."Bal. Account Type"::"Bank Account", XWWBTRANSFERSTxt, false, '', true, true);
    end;

    var
        "Gen. Journal Batch": Record "Gen. Journal Batch";
        CA: Codeunit "Make Adjustments";
        XSTART: Label 'START';
        XCUSTOPEN: Label 'CUST OPEN';
        XCustomers: Label 'Customers';
        XGLOPEN: Label 'G/L OPEN';
        XGLAccounts: Label 'G/L Accounts';
        XPERIODIC: Label 'PERIODIC';
        XVendors: Label 'Vendors';
        XBANKOPEN: Label 'BANK OPEN';
        XVENDOPEN: Label 'VEND OPEN';
        XBank: Label 'Bank';
        XDEFAULT: Label 'DEFAULT';
        XOther: Label 'Other';
        XDEPR: Label 'DEPR';
        XPeriodicDepr: Label 'Periodic Depr.';
        XASSETS: Label 'ASSETS';
        XDefaultJournalBatch: Label 'Default Journal Batch';
        XGENERAL: Label 'GENERAL', MaxLength = 10;
        XCASH: Label 'CASH';
        XCashreceiptsandpayments: Label 'Cash receipts and payments';
        XSALES: Label 'SALES';
        XPURCH: Label 'PURCH';
        XCASHRCPT: Label 'CASHRCPT';
        XPAYMENT: Label 'PAYMENT';
        XJOB: Label 'JOB';
        XPmtRegTxt: Label 'PMT REG', Comment = 'Payment Registration';
        XBankReconciliationTxt: Label 'Bank Reconciliation';
        XCASHORDER: Label 'CASHORDER';
        XCashOrderPayments: Label 'Cash Order Payments';
        XVATSET: Label 'VATSET';
        XVATSettlement: Label 'VAT Settlement';
        XCASHRUR: Label 'CASHRUR';
        XWorldWideBank: Label 'World Wide Bank';
        XNBL: Label 'NBL';
        XNewBankofLondon: Label 'NewBankofLondon';
        XFUTEXP: Label 'FUTEXP';
        XFutureExpences: Label 'Future Expences';
        XRECURRING: Label 'RECURRING';
        XDIVIDENDS: Label 'DIVIDENDS';
        XLOANS: Label 'LOANS';
        XCLOSE: Label 'CLOSE';
        XDividendOperations: Label 'Dividend Operations';
        XLoansGiven: Label 'Loans Given';
        XClosingAccount: Label 'Closing Account';
        XTAXDIFF: Label 'TAXDIFF';
        XTaxDifferences: Label 'Tax Differences';
        XPROPTAX: Label 'PROPTAX';
        XPropertyTax: Label 'Property Tax';
        XBALREFORM: Label 'BALREFORM';
        XBalanceReformation: Label 'Balance Reformation';
        XINSURANCE: Label 'INSURANCE';
        XInsurance2: Label 'Insurance';
        XInterestsfromCurrencyCredits: Label 'Interests from Currency Credits';
        XCURCREDPR: Label 'CURCREDPR';
        XCREDPR: Label 'CREDPR';
        XInterestsfromRubleCredits: Label 'Interests from Ruble Credits';
        XDEPOSITPR: Label 'DEPOSITPR';
        XInterestsfromDeposits: Label 'Interests from Deposits';
        XLOANPR: Label 'LOANPR';
        XInterestsfromLoans: Label 'Interests from Loans';
        XWWBUSD: Label 'WWB-USD';
        XWWBEUR: Label 'WWB-EUR';
        XWWBRUR: Label 'WWB-RUR';
        XPAYROLL: Label 'PAYROLL';
        XPayrollPosting: Label 'Payroll Posting';
        XBankConvTxt: Label 'BANK CONV', Locked = true;
        XBankConvDescTxt: Label 'Payment Export using Bank Data Conversion Service';
        XWWBTRANSFERSTxt: Label 'WWB-TRANSFERS', Locked = true;
        XMONTHLY: Label 'Monthly';
        XDAILY: Label 'DAILY', MaxLength = 10;
        XMonthlyJournalEntries: Label 'Monthly Journal Entries';
        XDailyJournalEntries: Label 'Daily Journal Entries';

    procedure InsertData("Journal Template Name": Code[10]; Name: Code[10]; Description: Text[50]; "Bal. Account Type": Enum "Gen. Journal Account Type"; "Bal. Account No.": Code[20]; InsertNoSeries: Boolean; NoSeries: Code[20]; CopyVATSetup: Boolean; AllowPaymentExport: Boolean)
    begin
        "Gen. Journal Batch".Init();
        "Gen. Journal Batch".Validate("Journal Template Name", "Journal Template Name");
        "Gen. Journal Batch".SetupNewBatch();
        "Gen. Journal Batch".Validate(Name, Name);
        "Gen. Journal Batch".Insert(true);
        "Gen. Journal Batch".Validate(Description, Description);
        "Gen. Journal Batch".Validate("Bal. Account Type", "Bal. Account Type");
        if "Bal. Account Type" = "Gen. Journal Batch"."Bal. Account Type"::"G/L Account" then
            "Bal. Account No." := CA.Convert("Bal. Account No.");
        "Gen. Journal Batch".Validate("Bal. Account No.", "Bal. Account No.");
        if not InsertNoSeries then
            "Gen. Journal Batch"."No. Series" := '';
        if NoSeries <> '' then
            "Gen. Journal Batch".Validate("No. Series", NoSeries);
        "Gen. Journal Batch"."Allow VAT Difference" := "Gen. Journal Batch"."Journal Template Name" = XVATSET;
        "Gen. Journal Batch"."Copy VAT Setup to Jnl. Lines" := false;
        "Gen. Journal Batch".Validate("Allow Payment Export", AllowPaymentExport);
        "Gen. Journal Batch".Modify();
    end;

    procedure InsertMiniAppData()
    begin
        InsertData(XGENERAL, XDEFAULT, XDefaultJournalBatch, "Gen. Journal Account Type"::"G/L Account", '', true, '', false, false);
        UpdateCopyToPostedGenJnlLines(XGENERAL, XDEFAULT, true);
        InsertData(XGENERAL, XMONTHLY, XMonthlyJournalEntries, "Gen. Journal Batch"."Bal. Account Type"::"G/L Account",
          '50-1000', true, '', false, false);
        InsertData(XGENERAL, XDAILY, XDailyJournalEntries, "Gen. Journal Account Type"::"Bank Account", '', true, '', false, false);
        UpdateCopyToPostedGenJnlLines(XGENERAL, XMONTHLY, true);
        InsertData(XCASHRCPT, XGENERAL, XGENERAL, "Gen. Journal Batch"."Bal. Account Type"::"G/L Account", '50-1000', true, '', false, false);
        InsertData(XPAYMENT, XGENERAL, XGENERAL, "Gen. Journal Batch"."Bal. Account Type"::"G/L Account", '50-1000', true, '', false, false);
        InsertData(XPAYMENT, XPmtRegTxt, XBankReconciliationTxt,
          "Gen. Journal Batch"."Bal. Account Type"::"Bank Account", '', true, '', false, true);
        InsertData(XPAYMENT, XCASH, XCashreceiptsandpayments,
          "Gen. Journal Batch"."Bal. Account Type"::"G/L Account", '50-1000', true, '', false, false);
        InsertData(XASSETS, XDEFAULT, XDefaultJournalBatch, "Gen. Journal Account Type"::"G/L Account", '', true, '', false, false);
    end;

    procedure GetGeneralDefaultBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        GenJournalBatch."Journal Template Name" := XGENERAL;
        GenJournalBatch.Name := XDEFAULT;
    end;

    internal procedure GetGeneralJournalTemplateName(): Code[10]
    begin
        exit(XGENERAL);
    end;

    internal procedure GetDailyJournalBatchName(): Code[10]
    begin
        exit(XDAILY);
    end;

    local procedure UpdateCopyToPostedGenJnlLines(GenJnlTemplateName: Code[10]; GenJnlBatchName: Code[10]; CopyToPostedGenJnlLines: Boolean)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        GenJournalBatch.Get(GenJnlTemplateName, GenJnlBatchName);
        GenJournalBatch.Validate("Copy to Posted Jnl. Lines", CopyToPostedGenJnlLines);
        GenJournalBatch.Modify(true);
    end;
}

