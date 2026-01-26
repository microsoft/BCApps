codeunit 134987 "ERM Financial Reports III"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [ERM]
        IsInitialized := false;
    end;

    var
        LibraryJournals: Codeunit "Library - Journals";
        LibraryPmtDiscSetup: Codeunit "Library - Pmt Disc Setup";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryAccSchedule: Codeunit "Library - Account Schedule";
        LibraryRandom: Codeunit "Library - Random";
        LibraryCFHelper: Codeunit "Library - Cash Flow Helper";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        ReportSaveErr: Label 'Enter the starting date for the first period.';
        ValidateErr: Label 'Error must be Same.';
        ValidationErr: Label '%1 must be %2 in Report.', Comment = '%1 FieldName, %2 Value';
        RoundingFactor: Option "None","1","1000","1000000";
        DocEntryTableNameLbl: Label 'DocEntryTableName';
        DocEntryNoofRecordsLbl: Label 'DocEntryNoofRecords';
        PostingDateLbl: Label 'PstDate_BankAccLedgEntry';
        CreditAmtBankAccLedgEntryLbl: Label 'CreditAmt_BankAccLedgEntry';
        CreditAmtLCYBankAccLedgEntryLbl: Label 'CreditAmtLCY_BankAccLedgEntry';
        RowNotFoundErr: Label 'There is no dataset row corresponding to Element Name %1 with value %2.', Comment = '%1=Field Caption;%2=Field Value;';
        IndentationLevelLbl: Label 'Indentation Level : %1', Comment = '%1 the amount of indentation.';
        IsInitialized: Boolean;
        AmountTextMsg: Label 'Amount text must be same in Check Preview.';
        AppToDocTypeToUpdate: Option Invoice,"Credit Memo";
        CustVendNameLbl: Label 'Cust_Vend_Name';
        AmountLcyCapTxt: Label 'AmountLcy';
        AmountPmtToleranceCapTxt: Label 'AmountPmtTolerance';
        AmountBalLcyCapTxt: Label 'AmountBalLcy';
        EntryType: Option " ",Invoice,"Credit Memo",Payment;
        AmountToApplyDiscTolSalesTxt: Label 'Amount_to_Apply____AmountDiscounted___AmountPmtDiscTolerance___AmountPmtTolerance_';
        AmountToApplyDiscTolPurchTxt: Label 'Amount_to_Apply____AmountDiscounted___AmountPmtDiscTolerance___AmountPmtTolerance__Control3036';
        AmountTotalDiscTolAppliedTxt: Label 'Amount___TotalAmountDiscounted___TotalAmountPmtDiscTolerance___TotalAmountPmtTolerance___AmountApplied';
        TotalAmountDiscountedMustBeAvailableErr: Label 'TotalAmountDiscounted must be available';
        NoOfCheckLinesErr: Label 'No. of check lines printed must be equal to %1.', Comment = '%1 Expected check lines';

    [Test]
    [HandlerFunctions('BalanceCompPrevYearReqPageHandler')]
    [Scope('OnPrem')]
    procedure BalCompPrevYearNoOption()
    var
        BalanceCompPrevYear: Report "Balance Comp. - Prev. Year";
    begin
        // Check Balance Compare Previous Year Report without any option selected.

        // Setup.
        Initialize();
        Clear(BalanceCompPrevYear);

        // Exercise.
        Commit();
        asserterror BalanceCompPrevYear.Run();

        // Verify: Verify Error Raised during Save Report.
        Assert.AreEqual(StrSubstNo(ReportSaveErr), GetLastErrorText, ValidateErr);
    end;

    [Test]
    [HandlerFunctions('BalanceCompPrevYearReqPageHandler')]
    [Scope('OnPrem')]
    procedure BalCompPrevYearNoneRounding()
    begin
        // Check Balance Compare Previous Year Report with None Rounding Factor. Take 1 for Devinding Amount.
        Initialize();
        SetupAndVerifyBalCompPrevYear(RoundingFactor::None, 1, GetGLDecimals());
    end;

    [Test]
    [HandlerFunctions('BalanceCompPrevYearReqPageHandler')]
    [Scope('OnPrem')]
    procedure BalCompPrevYear1Rounding()
    begin
        // Check Balance Compare Previous Year Report with 1 Rounding Factor. Take 1 for Deviding Amount.
        Initialize();
        SetupAndVerifyBalCompPrevYear(RoundingFactor::"1", 1, '0');
    end;

    [Test]
    [HandlerFunctions('BalanceCompPrevYearReqPageHandler')]
    [Scope('OnPrem')]
    procedure BalCompPrevYear1000Rounding()
    begin
        // Check Balance Compare Previous Year Report with 1000 Rounding Factor. Take 1000 for Deviding Amount.
        Initialize();
        SetupAndVerifyBalCompPrevYear(RoundingFactor::"1000", 1000, '1');
    end;

    [Test]
    [HandlerFunctions('BalanceCompPrevYearReqPageHandler')]
    [Scope('OnPrem')]
    procedure BalCompPrevYear1000000Rounding()
    begin
        // Check Balance Compare Previous Year Report with 1000000 Rounding Factor. Take 1000000 for Deviding Amount.
        Initialize();
        SetupAndVerifyBalCompPrevYear(RoundingFactor::"1000000", 1000000, '1');
    end;

    local procedure SetupAndVerifyBalCompPrevYear(RoundingFactor2: Option; RoundingFactorAmount: Decimal; Decimals: Text[5])
    var
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        BalanceCompPrevYear: Report "Balance Comp. - Prev. Year";
        Indent: Option "None","0","1","2","3","4","5";
        PeriodEndingDate: Date;
    begin
        // Setup.
        PostGenLinesCustomPostingDate(GenJournalLine);
        FindGLAccount(GLAccount, GenJournalLine."Account No.", WorkDate(), WorkDate());
        Indent := GetIndentValue(GLAccount.Indentation);  // Get Indentation Value According to Report's Indent Option.

        // Exercise.
        Clear(BalanceCompPrevYear);
        GLAccount.SetRange("No.", GenJournalLine."Account No.");
        BalanceCompPrevYear.SetTableView(GLAccount);
        BalanceCompPrevYear.InitializeRequest(WorkDate(), 0D, 0D, 0D, RoundingFactor2, Indent); // Take OD for all fields as workdate will flow.
        Commit();
        BalanceCompPrevYear.Run();

        // Verify: Verify Saved Report with Different Fields value.
        FindGLAccount(GLAccount, GenJournalLine."Account No.", WorkDate(), WorkDate());
        GLAccount.CalcFields("Debit Amount", "Credit Amount");
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('G_L_Account___No__', GenJournalLine."Account No.");
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFoundErr, 'G_L_Account___No__', GenJournalLine."Account No.");
        VerifyTextAmountInXMLFile(
          'ColumnValuesAsText_1_', FormatAmount(Round(GLAccount."Debit Amount" / RoundingFactorAmount, 0.1), Decimals));

        PeriodEndingDate := CalcDate('<-1D>', CalcDate('<+1M>', DMY2Date(1, Date2DMY(WorkDate(), 2), Date2DMY(WorkDate(), 3))));

        FindGLAccount(GLAccount, GenJournalLine."Account No.", 0D, PeriodEndingDate);
        GLAccount.CalcFields("Balance at Date");
        LibraryReportDataset.Reset();
        LibraryReportDataset.AssertElementWithValueExists('PeriodEndingDate', Format(PeriodEndingDate));
        LibraryReportDataset.AssertElementWithValueExists('PreviousEndingDate', Format(CalcDate('<-1Y>', PeriodEndingDate)));
        LibraryReportDataset.AssertElementWithValueExists(
          'STRSUBSTNO___1___2__PreviousStartingDate_PreviousEndingDate_',
          StrSubstNo('%1..%2', Format(CalcDate('<-1Y>', WorkDate())), Format(CalcDate('<-1Y>', PeriodEndingDate))));
        LibraryReportDataset.AssertElementWithValueExists(
          'STRSUBSTNO___1___2__PeriodStartingDate_PeriodEndingDate_',
          StrSubstNo('%1..%2', Format(WorkDate()), Format(PeriodEndingDate)));

        LibraryReportDataset.SetRange('G_L_Account___No__', GenJournalLine."Account No.");
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFoundErr, 'G_L_Account___No__', GenJournalLine."Account No.");
        VerifyTextAmountInXMLFile(
          'ColumnValuesAsText_3_', FormatAmount(Round(GLAccount."Balance at Date" / RoundingFactorAmount, 0.1), Decimals));

        FindGLAccount(GLAccount, GenJournalLine."Account No.", CalcDate('<-1Y>', WorkDate()), CalcDate('<-1Y>', PeriodEndingDate));
        GLAccount.CalcFields("Debit Amount", "Credit Amount");
        VerifyTextAmountInXMLFile(
          'ColumnValuesAsText_7_', FormatAmount(Round(GLAccount."Debit Amount" / RoundingFactorAmount, 0.1), Decimals));

        FindGLAccount(GLAccount, GenJournalLine."Account No.", 0D, CalcDate('<-1Y>', PeriodEndingDate));
        GLAccount.CalcFields("Balance at Date");
        VerifyTextAmountInXMLFile(
          'ColumnValuesAsText_5_', FormatAmount(Round(GLAccount."Balance at Date" / RoundingFactorAmount, 0.1), Decimals));
    end;

    [Test]
    [HandlerFunctions('TrialBalanceByPeriodReqPageHandler')]
    [Scope('OnPrem')]
    procedure TrialBalByPeriodNoOption()
    var
        TrialBalanceByPeriod: Report "Trial Balance by Period";
    begin
        // Check Trial Balance By Period without any option Selected.

        // Setup.
        Initialize();
        Clear(TrialBalanceByPeriod);

        // Exercise.
        Commit();
        asserterror TrialBalanceByPeriod.Run();

        // Verify: Verify Error Raised during Save Report.
        Assert.AreEqual(StrSubstNo(ReportSaveErr), GetLastErrorText, ValidateErr);
    end;

    [Test]
    [HandlerFunctions('TrialBalanceByPeriodReqPageHandler')]
    [Scope('OnPrem')]
    procedure TrialBalByPeriodNoneOption()
    begin
        // Check Trial Balance By Period with None Rounding Factor. Take 1 for Deviding Amount.
        Initialize();
        SetupAndVerifyTrialBalByPeriod(RoundingFactor::None, 1, GetGLDecimals());
    end;

    [Test]
    [HandlerFunctions('TrialBalanceByPeriodReqPageHandler')]
    [Scope('OnPrem')]
    procedure TrialBalByPeriod1Rounding()
    begin
        // Check Trial Balance By Period with 1 Rounding Factor. Take 1 for Deviding Amount.
        Initialize();
        SetupAndVerifyTrialBalByPeriod(RoundingFactor::"1", 1, '0');
    end;

    [Test]
    [HandlerFunctions('TrialBalanceByPeriodReqPageHandler')]
    [Scope('OnPrem')]
    procedure TrialBalByPeriod1000Rounding()
    begin
        // Check Trial Balance By Period with 1000 Rounding Factor. Take 1000 for Deviding Amount.
        Initialize();
        SetupAndVerifyTrialBalByPeriod(RoundingFactor::"1000", 1000, '1');
    end;

    [Test]
    [HandlerFunctions('TrialBalanceByPeriodReqPageHandler')]
    [Scope('OnPrem')]
    procedure TrialBalByPeriod100000Rounding()
    begin
        // Check Trial Balance By Period with 1000000 Rounding Factor. Take 1000000 for Deviding Amount.
        Initialize();
        SetupAndVerifyTrialBalByPeriod(RoundingFactor::"1000000", 1000000, '1');
    end;

    local procedure SetupAndVerifyTrialBalByPeriod(RoundingFactor2: Option; RoundingFactorAmount: Decimal; Decimals: Text[5])
    var
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        TrialBalanceByPeriod: Report "Trial Balance by Period";
        Indent: Option "None","0","1","2","3","4","5";
        StartingDate: Date;
    begin
        // Setup.
        PostGenLinesCustomPostingDate(GenJournalLine);
        StartingDate := LibraryFiscalYear.GetAccountingPeriodDate(GenJournalLine."Posting Date");
        FindGLAccount(GLAccount, GenJournalLine."Account No.", GenJournalLine."Posting Date", GenJournalLine."Posting Date");
        Indent := GetIndentValue(GLAccount.Indentation);  // Get Indentation Value According to GLAccount.

        // Exercise. Take Starting Date with 1 Month Back.
        Clear(TrialBalanceByPeriod);
        GLAccount.SetRange("No.", GenJournalLine."Account No.");
        TrialBalanceByPeriod.SetTableView(GLAccount);
        TrialBalanceByPeriod.InitializeRequest(CalcDate('<-1M>', StartingDate), RoundingFactor2, Indent);
        Commit();
        TrialBalanceByPeriod.Run();

        // Verify: Verify Saved Report with Different Fields value.
        FindGLAccount(GLAccount, GenJournalLine."Account No.", GenJournalLine."Posting Date", GenJournalLine."Posting Date");
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('G_L_Account___No__', GLAccount."No.");
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFoundErr, 'G_L_Account___No__', GLAccount."No.");
        VerifyTextAmountInXMLFile(
          'ColumnValuesAsText_3_', FormatAmount(Round(GenJournalLine.Amount / RoundingFactorAmount, 0.1), Decimals));
        LibraryReportDataset.Reset();
        LibraryReportDataset.AssertElementWithValueExists('G_L_Account__TABLECAPTION__________GLFilter',
          GLAccount.TableCaption + ': ' + GLAccount.GetFilters);
        LibraryReportDataset.AssertElementWithValueExists('Text015___FORMAT_Indent_', StrSubstNo(IndentationLevelLbl, Indent));
    end;

    [Test]
    [HandlerFunctions('ForeignCurrencyBalanceReqPageHandler')]
    [Scope('OnPrem')]
    procedure ForeignCurrencyBalance()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        GLAccount: Record "G/L Account";
        Currency: Record Currency;
        BankAccount: Record "Bank Account";
        ForeignCurrencyBalance: Report "Foreign Currency Balance";
        BankAccountNo: Code[20];
        CurrencyCode: Code[10];
        CurrentValueLCY: Decimal;
    begin
        // Verify Balance in G/L Account after Posting General Journal Line.

        // 1. Setup: Create Currency and Post the General Journal Line with Foreign Currency.
        Initialize();
        CurrencyCode := CreateCurrencyAndExchangeRate();
        BankAccountNo := CreateBankAccountWithCurrency(CurrencyCode);
        LibraryERM.CreateGLAccount(GLAccount);
        ClearGeneralJournalLines(GenJournalBatch);

        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", GLAccount."No.", LibraryRandom.RandDec(100, 2));
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Bal. Account No.", BankAccountNo);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Exercise: Save the Previewed report.
        Clear(ForeignCurrencyBalance);
        Currency.SetRange(Code, CurrencyCode);
        ForeignCurrencyBalance.SetTableView(Currency);
        Commit();
        ForeignCurrencyBalance.Run();

        // Verify: Verify Saved Report with Field value.
        GLAccount.CalcFields(Balance);
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('StrsubNototalCurrCode', 'Total ' + CurrencyCode);
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFoundErr, 'StrsubNototalCurrCode', 'Total ' + CurrencyCode);
        LibraryReportDataset.AssertCurrentRowValueEquals('CalcTotalBalanceLCY', -GLAccount.Balance);

        Currency.Get(CurrencyCode);
        Currency.CalcFields("Customer Balance (LCY)", "Vendor Balance (LCY)");
        BankAccount.Get(BankAccountNo);
        BankAccount.CalcFields("Balance (LCY)");
        CurrentValueLCY := Currency."Customer Balance (LCY)" - Currency."Vendor Balance (LCY)" + BankAccount."Balance (LCY)";
        LibraryReportDataset.AssertCurrentRowValueEquals('CalcTotalCurrBalanceLCY', CurrentValueLCY);
    end;

    [Test]
    [HandlerFunctions('BankAccountStatementReportReqPageHandler')]
    [Scope('OnPrem')]
    procedure CheckBankAccountStatementReport()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccount: Record "Bank Account";
        BankAccountStatementLine: Record "Bank Account Statement Line";
        BankAccountStatementReport: Report "Bank Account Statement";
        DocumentNo: Code[20];
    begin
        // Verify Statement Amount in Bank Account Statement Report.

        // Setup: Post a General Journal Line for payment with Manual Check and Bank AccReconciliation.
        Initialize();
        DocumentNo := PostJournalGeneralLineForManualCheck(BankAccount);
        CreateSuggestedBankReconciliation(BankAccReconciliation, BankAccount."No.");
        LibraryERM.PostBankAccReconciliation(BankAccReconciliation);

        // Exercise: Save Bank Account Statement Report.
        Clear(BankAccountStatementReport);
        BankAccountStatementLine.SetRange("Document No.", DocumentNo);
        BankAccountStatementReport.SetTableView(BankAccountStatementLine);
        Commit();
        BankAccountStatementReport.Run();

        // Verify: Verify Bank Account Statement Report.
        BankAccountStatementLine.FindFirst();
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('TrnsctnDte_BnkAcStmtLin', Format(BankAccountStatementLine."Transaction Date"));
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFoundErr, 'TrnsctnDte_BnkAcStmtLin', Format(BankAccountStatementLine."Transaction Date"));
        LibraryReportDataset.AssertCurrentRowValueEquals('Amt_BankAccStmtLineStmt', BankAccountStatementLine."Statement Amount");
    end;

    // [Test]
    [Scope('OnPrem')]
    procedure AmountTextOnCheckPreview()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        Check: Report Check;
        PaymentJournal: TestPage "Payment Journal";
        PaymentDiscountAmount: Decimal;
        AppliedToDocNo: Code[20];
        NumberText: array[2] of Text[80];
        VendorNo: Code[20];
        ActualValue: Text;
    begin
        // Check Amount Text on Check Preview Page after Calculating Payment discount on Payment Journal.

        // Setup: Create General Journal Line with Invoice and Payment.
        Initialize();
        CreatePaymentTerms(PaymentTerms);
        VendorNo := CreateVendorWithPaymentTerms(PaymentTerms.Code);

        // Random Values Required to make amount more than 100;
        CreateGenJournalLine(GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Vendor,
          VendorNo, -(LibraryRandom.RandDec(100, 2) + 100), GenJournalLine."Bank Payment Type"::"Computer Check");
        AppliedToDocNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        PaymentDiscountAmount := Round(GenJournalLine.Amount - (GenJournalLine.Amount * PaymentTerms."Discount %" / 100));

        CreateGenJournalLine(GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor,
          VendorNo, 0, GenJournalLine."Bank Payment Type"::"Computer Check");
        ModifyGenJournalLine(GenJournalLine, -PaymentDiscountAmount, AppliedToDocNo);

        // Below function required for changing the Amount in Text.
        Check.InitTextVariable();
        Check.FormatNoText(NumberText, -PaymentDiscountAmount, '');

        // Exercise: Open Check Preview Page through Payment Journal.
        Commit();
        PaymentJournal.OpenEdit();
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalLine."Journal Batch Name");
        ActualValue := LibraryERM.CheckPreview(PaymentJournal);

        // Verify: Verify Amount Text on Check Preview Page.
        Assert.AreEqual(NumberText[1], ActualValue, 'Amount message should be same.');
    end;

    [Test]
    [HandlerFunctions('DocumentEntriesReqPageHandler,NavigatePageHandler')]
    [Scope('OnPrem')]
    procedure AmountInLCYOnDocumentEntriesReport()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // Verify Document Entries Report with Bank Account Ledger Entry and Check Ledger Entry with LCY Amount
        DocumentEntriesWithBankAndCheckLedger(VendorLedgerEntry, true);
        LibraryReportDataset.AssertCurrentRowValueEquals(CreditAmtLCYBankAccLedgEntryLbl, VendorLedgerEntry."Amount (LCY)");
    end;

    [Test]
    [HandlerFunctions('DocumentEntriesReqPageHandler,NavigatePageHandler')]
    [Scope('OnPrem')]
    procedure AmountInFCYOnDocumentEntriesReport()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // Verify Document Entries Report with Bank Account Ledger Entry and Check Ledger Entry with FCY Amount
        DocumentEntriesWithBankAndCheckLedger(VendorLedgerEntry, false);
        LibraryReportDataset.AssertCurrentRowValueEquals(CreditAmtBankAccLedgEntryLbl, VendorLedgerEntry.Amount);
    end;

    local procedure DocumentEntriesWithBankAndCheckLedger(var VendorLedgerEntry: Record "Vendor Ledger Entry"; AmountInLCY: Boolean)
    var
        GenJournalLine: Record "Gen. Journal Line";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        CheckLedgerEntry: Record "Check Ledger Entry";
        PaymentTerms: Record "Payment Terms";
        BankAccountLedgerEntries: TestPage "Bank Account Ledger Entries";
        VendorNo: Code[20];
    begin
        // Setup: Create vendor payment General Journal Line with Bank Account No. with Currency Code as Balancing Account.
        Initialize();
        LibraryERM.FindPaymentTerms(PaymentTerms);
        VendorNo := CreateVendorWithPaymentTerms(PaymentTerms.Code);
        CreateGenJournalLine(GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor,
          VendorNo, LibraryRandom.RandDec(100, 2), GenJournalLine."Bank Payment Type"::"Manual Check");  // Using Random value for Amount.
        GenJournalLine.Validate("Bal. Account No.", CreateBankAccountWithCurrency(CreateCurrencyAndExchangeRate()));
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        LibraryVariableStorage.Enqueue(AmountInLCY);  // Enqueue for DocumentEntriesReqPageHandler.
        BankAccountLedgerEntries.OpenView();
        BankAccountLedgerEntries.FILTER.SetFilter("Bal. Account No.", VendorNo);

        // Exercise.
        BankAccountLedgerEntries."&Navigate".Invoke();  // Navigate();

        // Verify:
        BankAccountLedgerEntry.SetRange("Bal. Account No.", VendorNo);
        LibraryReportDataset.LoadDataSetFile();
        VerifyDocumentEntries(BankAccountLedgerEntry.TableCaption(), BankAccountLedgerEntry.Count);
        CheckLedgerEntry.SetRange("Bal. Account No.", VendorNo);
        VerifyDocumentEntries(CheckLedgerEntry.TableCaption(), CheckLedgerEntry.Count);
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VerifyDocumentEntries(VendorLedgerEntry.TableCaption(), VendorLedgerEntry.Count);
        VendorLedgerEntry.FindFirst();
        VendorLedgerEntry.CalcFields("Amount (LCY)", Amount);
        LibraryReportDataset.SetRange(PostingDateLbl, Format(VendorLedgerEntry."Posting Date"));
        LibraryReportDataset.GetNextRow();
    end;

    // [Test]
    [HandlerFunctions('MessageHandler,SuggestVendorPaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure AmountTextOnCheckPreviewWithCurrency()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        Check: Report Check;
        PaymentJournal: TestPage "Payment Journal";
        VendorNo: Code[20];
        CurrencyCode: Code[10];
        PaymentAmount: Decimal;
        NumberText: array[2] of Text[80];
        ActualValue: Text;
    begin
        // Check Amount Text on Check Preview Page after Suggest Vendor Payment on Payment Journal.

        // Setup: Create and Post General Journal Line with Invoice and Suggest Vendor Payment.
        Initialize();
        CurrencyCode := CreateCurrencyAndExchangeRate();
        VendorNo := LibraryPurchase.CreateVendorNo();
        CreateGenJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Vendor,
          VendorNo, -LibraryRandom.RandDec(100, 2), GenJournalLine."Bank Payment Type"::"Computer Check");
        UpdateGenJornalLineCurrency(GenJournalLine, CurrencyCode);
        PaymentAmount := Round(GenJournalLine.Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        CreatePaymentGeneralBatch(GenJournalBatch);
        SuggestVendorPayment(GenJournalLine, GenJournalBatch, VendorNo, CreateBankAccountWithCurrency(CurrencyCode), true);

        // Below function required for changing the Amount in Text.
        Check.InitTextVariable();
        Check.FormatNoText(NumberText, -PaymentAmount, CurrencyCode);

        // Exercise: Open Check Preview Page through Payment Journal.
        PaymentJournal.OpenEdit();
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalLine."Journal Batch Name");
        ActualValue := LibraryERM.CheckPreview(PaymentJournal);

        // Verify: Check Amount Text on Check Preview Page after Suggest Vendor Payment on Payment Journal.
        Assert.AreEqual(NumberText[1], ActualValue, AmountTextMsg);
    end;

    [Test]
    [HandlerFunctions('PrintCheckReqPageHandler')]
    [Scope('OnPrem')]
    procedure PrintVendCheckForAmountLessThanAppliedAmountSum()
    var
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseHeader: Record "Purchase Header";
        PaymentMethod: Record "Payment Method";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DocumentPrint: Codeunit "Document-Print";
        GLAccountNo: Code[20];
        AmountInvoice: Decimal;
        AmountCreditMemo: Decimal;
    begin
        // [FEATURE] [Payment Journal] [Check] [Vendor]
        // [SCEANRIO 317529] Check with correct amounts printed when GenJournalLine amount is less than applied Credit Memo amount.
        Initialize();

        // [GIVEN] Vendor and G/L Account
        LibraryPurchase.CreateVendor(Vendor);
        GLAccountNo := LibraryERM.CreateGLAccountWithPurchSetup();
        LibraryERM.CreatePaymentMethodWithBalAccount(PaymentMethod);

        // [GIVEN] Posted Invoice for Vendor for G/L Account with Amount = 100
        AmountInvoice :=
          PostPurchaseDocumentWithAmount(
            PurchaseHeader."Document Type"::Invoice, Vendor."No.",
            GLAccountNo, LibraryRandom.RandDecInRange(100, 110, 2), 1);

        // [GIVEN] Posted Credit Memo for Vendor for G/L Account with Amount = 90
        AmountCreditMemo :=
          PostPurchaseDocumentWithAmount(
            PurchaseHeader."Document Type"::"Credit Memo", Vendor."No.",
            GLAccountNo, LibraryRandom.RandDecInRange(90, 99, 2), 1);

        // [GIVEN] Payment Journal line for Vendor for printing check
        CreateGenJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Vendor, Vendor."No.", 0,
          GenJournalLine."Bank Payment Type"::"Computer Check");
        GenJournalLine.Validate("Payment Method Code", PaymentMethod.Code);
        GenJournalLine.Validate(Amount, AmountInvoice - AmountCreditMemo);
        GenJournalLine.Validate("Applies-to ID", UserId);
        GenJournalLine.Modify(true);

        // [GIVEN] Apply 100 for Invoice and 90 for Credit Memo with a total sum = 10
        VendorLedgerEntry.SetRange("Vendor No.", Vendor."No.");
        LibraryERM.SetAppliestoIdVendor(VendorLedgerEntry);

        // [WHEN] Print Payment Check
        UpdateLastCheckNoAndEnqueueValues(GenJournalLine."Bal. Account No.");
        Commit();
        DocumentPrint.PrintCheck(GenJournalLine);

        // [THEN] Verify check has two lines for 100 for Invoice and -90 for Credit Memo and a Total amount = 10
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('LineAmt', -AmountCreditMemo);
        LibraryReportDataset.AssertElementWithValueExists('LineAmt', AmountInvoice);
        LibraryReportDataset.AssertElementWithValueExists('TotalLineAmount', AmountInvoice - AmountCreditMemo);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,SuggestVendorPaymentsRequestPageHandler,PrintCheckReqPageHandler')]
    [Scope('OnPrem')]
    procedure PrintVendCheckForUpdatedAppToCrMemoAmount()
    begin
        // [FEATURE] [Report] [Check] [Rounding]
        // [SCENARIO] Run report "Check" for Invoice applied to Credit Memo where total amount is decimal value
        PrintVendCheckForUpdatedAmount(AppToDocTypeToUpdate::"Credit Memo", 2);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,SuggestVendorPaymentsRequestPageHandler,PrintCheckReqPageHandler')]
    [Scope('OnPrem')]
    procedure PrintVendCheckForUpdatedAppToInvoiceAmount()
    begin
        // [FEATURE] [Report] [Check] [Rounding]
        // [SCENARIO] Run report "Check" for Credit Memo applied to Invoice where total amount is decimal value
        PrintVendCheckForUpdatedAmount(AppToDocTypeToUpdate::Invoice, 2);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,SuggestVendorPaymentsRequestPageHandler,PrintCheckReqPageHandler')]
    [Scope('OnPrem')]
    procedure PrintVendCheckForUpdatedAppToCrMemoAmountRounded()
    begin
        // [FEATURE] [Report] [Check] [Rounding]
        // [SCENARIO 156205] Run report "Check" for Invoice applied to Credit Memo where total amount is integer value
        // [GIVEN] Total Amount = 34;
        // [GIVEN] GLSetup."Amount Rounding Precision" = 0.01
        // [WHEN] Run "Check" report
        // [THEN] CheckAmountText = 34.00
        PrintVendCheckForUpdatedAmount(AppToDocTypeToUpdate::"Credit Memo", 0);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,SuggestVendorPaymentsRequestPageHandler,PrintCheckReqPageHandler')]
    [Scope('OnPrem')]
    procedure PrintVendCheckForUpdatedAppToInvoiceAmountRounded()
    begin
        // [FEATURE] [Report] [Check] [Rounding]
        // [SCENARIO 156205] Run report "Check" for Credit Memo applied to Invoice where total amount is integer value
        // [GIVEN] Total Amount = 34;
        // [GIVEN] GLSetup."Amount Rounding Precision" = 0.01
        // [WHEN] Run "Check" report
        // [THEN] CheckAmountText = 34.00
        PrintVendCheckForUpdatedAmount(AppToDocTypeToUpdate::Invoice, 0);
    end;

    [Test]
    [HandlerFunctions('VendorPrePaymentJournalHandler')]
    [Scope('OnPrem')]
    procedure VendorPrePmtOnSalesInvWithPmtDiscAndCrMemo()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustomerNo: Code[20];
        AppliesToID: Code[20];
        EntryAmount: array[3] of Decimal;
        PmtDiscPossible: Decimal;
    begin
        // [FEATURE] [Report] [Vendor Pre-Payment Journal] [Customer]
        // [SCENARIO 359950.1] Payment Journal - Pre-Check Report shows payment discount correctly when printing invoice and credit memo.
        Initialize();

        CustomerNo := LibrarySales.CreateCustomerNo();
        AppliesToID := LibraryUTUtility.GetNewCode();
        // [GIVEN] Invoice with amount X and payment discount P less then X
        CreateCustLedgerEntryWithSpecificAmountAndAppliesToID(
          CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, CustomerNo, LibraryRandom.RandDec(100, 2), AppliesToID);
        PmtDiscPossible := Round(CustLedgerEntry."Amount (LCY)" / LibraryRandom.RandIntInRange(3, 5));
        UpdateCustLedgEntryWithPmtDisc(CustLedgerEntry, PmtDiscPossible);

        // [GIVEN] Credit memo with amount Y less then X
        // [GIVEN] Payment with amount Z less then (X - Y - P)
        CalcEntriesAmount(EntryAmount, CustLedgerEntry."Amount (LCY)", CustLedgerEntry."Remaining Pmt. Disc. Possible");
        CreateCustLedgerEntryWithSpecificAmountAndAppliesToID(
          CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo",
          CustomerNo, EntryAmount[EntryType::"Credit Memo"], AppliesToID);
        CreateGenJournalLineWithAppliesToID(
          GenJournalLine, GenJournalLine."Account Type"::Customer, CustomerNo, EntryAmount[EntryType::Payment], AppliesToID);

        // [WHEN] Run Payment PreCheck report on both invoice with pmt. discount and credit memo
        RunVendorPrePaymentJournal(GenJournalLine);

        // [THEN] Payment discount P is not show in report as separate amount (unapplied amount) but include to invoice amount
        VerifyInvAndPmtDiscInPreCheckReport(
          AmountToApplyDiscTolSalesTxt, -(EntryAmount[EntryType::Invoice] - PmtDiscPossible), PmtDiscPossible);
    end;

    [Test]
    [HandlerFunctions('VendorPrePaymentJournalHandler')]
    [Scope('OnPrem')]
    procedure VendorPrePmtOnPurchInvWithPmtDiscAndCrMemo()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendLedgEntry: Record "Vendor Ledger Entry";
        VendorNo: Code[20];
        AppliesToID: Code[20];
        EntryAmount: array[3] of Decimal;
        PmtDiscPossible: Decimal;
    begin
        // [FEATURE] [Report] [Vendor Pre-Payment Journal] [Vendor]
        // [SCENARIO 359950.2]  Test to verify the Payment Journal - Pre-Check Report shows payment discount correctly when printing invoice and credit memo.
        Initialize();

        VendorNo := LibraryPurchase.CreateVendorNo();
        AppliesToID := LibraryUTUtility.GetNewCode();
        // [GIVEN] Invoice with amount X and payment discount P less then X
        CreateVendLedgerEntryWithSpecificAmountAndAppliesToID(
          VendLedgEntry, VendLedgEntry."Document Type"::Invoice, VendorNo, -LibraryRandom.RandDec(100, 2), AppliesToID);
        PmtDiscPossible := Round(VendLedgEntry."Amount (LCY)" / LibraryRandom.RandIntInRange(3, 5));
        UpdateVendLedgEntryWithPmtDisc(VendLedgEntry, PmtDiscPossible);

        // [GIVEN] Credit memo with amount Y less then X
        // [GIVEN] Payment with amount Z less then (X - Y - P)
        CalcEntriesAmount(EntryAmount, VendLedgEntry."Amount (LCY)", VendLedgEntry."Remaining Pmt. Disc. Possible");
        CreateVendLedgerEntryWithSpecificAmountAndAppliesToID(
          VendLedgEntry, VendLedgEntry."Document Type"::"Credit Memo", VendorNo, EntryAmount[EntryType::"Credit Memo"], AppliesToID);
        CreateGenJournalLineWithAppliesToID(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, VendorNo, EntryAmount[EntryType::Payment], AppliesToID);

        // [WHEN] Run Payment PreCheck report on both invoice with pmt. discount and credit memo
        RunVendorPrePaymentJournal(GenJournalLine);

        // [THEN] Payment discount P is not show in report as separate amount (unapplied amount) but include to invoice amount
        VerifyInvAndPmtDiscInPreCheckReport(
          AmountToApplyDiscTolPurchTxt, -(EntryAmount[EntryType::Invoice] - PmtDiscPossible), PmtDiscPossible);
    end;

    [Test]
    [HandlerFunctions('VendorPrePaymentJournalHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordGenJnlLineCustPaymentJnlPreCheck()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // [FEATURE] [Report] [Vendor Pre-Payment Journal] [Customer]
        // [SCENARIO] Gen. Journal Line - OnAfterGetRecord trigger of the Report ID: 10087, Payment Journal - Pre-Check Report for Amount and Description for Gen. Journal Line Account Type Customer.
        Initialize();

        CreateCustomer(Customer);
        CreateCustLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, Customer."No.");
        UpdateCustLedgEntryWithPmtDisc(CustLedgerEntry, LibraryRandom.RandDec(10, 2));
        CreateGenJournalLineWithAppliesToDocType(
          GenJournalLine, GenJournalLine."Account Type"::Customer, Customer."No.", GenJournalLine."Document Type"::Invoice);

        // Exercise.
        RunVendorPrePaymentJournal(GenJournalLine);

        // Verify: Verify the Customer Description and Amount LCY after running Payment Journal Pre Check Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(CustVendNameLbl, Customer.Name);
        LibraryReportDataset.AssertElementWithValueExists(AmountLcyCapTxt, GenJournalLine."Amount (LCY)");
    end;

    [Test]
    [HandlerFunctions('VendorPrePaymentJournalHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordGenJnlLineVendPaymentJnlPreCheck()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Vendor: Record Vendor;
    begin
        // [FEATURE] [Report] [Vendor Pre-Payment Journal] [Vendor]
        // [SCENARIO] Gen. Journal Line - OnAfterGetRecord trigger of the Report ID: 10087, Payment Journal - Pre-Check Report for Amount and Description for Gen. Journal Line Account Type Vendor.
        Initialize();

        CreateVendor(Vendor);
        CreateVendorLedgerEntry(VendorLedgerEntry, Vendor."No.", '');  // Blank Purchaser Code.
        CreateGenJournalLineWithAppliesToDocType(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, Vendor."No.", GenJournalLine."Document Type"::Invoice);

        // Exercise.
        RunVendorPrePaymentJournal(GenJournalLine);

        // Verify: Verify the Vendor Description and Amount LCY after running Payment Journal Pre Check Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(CustVendNameLbl, Vendor.Name);
        LibraryReportDataset.AssertElementWithValueExists(AmountLcyCapTxt, GenJournalLine."Amount (LCY)");
    end;

    [Test]
    [HandlerFunctions('VendorPrePaymentJournalHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordGenJnlLineCustPaymtToleranceJnlPreChk()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Report] [Vendor Pre-Payment Journal] [Customer]
        // [SCENARIO] Gen. Journal Line - OnAfterGetRecord trigger of the Report ID: 10087, Payment Journal - Pre-Check Report for Accepted Payment Tolerance of Account Type Customer.
        Initialize();

        CustomerNo := LibrarySales.CreateCustomerNo();
        CreateCustLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, CustomerNo);
        UpdateCustLedgEntryWithPmtDisc(CustLedgerEntry, LibraryRandom.RandDec(10, 2));
        CreateGenJournalLineWithAppliesToDocType(
          GenJournalLine, GenJournalLine."Account Type"::Customer, CustomerNo, GenJournalLine."Document Type"::Invoice);
        UpdateAppliesToDocumentNoOnGenJournalLine(GenJournalLine, CustLedgerEntry."Document No.");

        // Exercise.
        RunVendorPrePaymentJournal(GenJournalLine);

        // Verify: Verify the Customer Accepted Payment Tolerance and Amount Bal. LCY after running Payment Journal Pre Check Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(AmountPmtToleranceCapTxt, -CustLedgerEntry."Accepted Payment Tolerance");
        LibraryReportDataset.AssertElementWithValueExists(AmountBalLcyCapTxt, GenJournalLine."Balance (LCY)");
    end;

    [Test]
    [HandlerFunctions('VendorPrePaymentJournalHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordGenJnlLineVendPaymtToleranceJnlPreChk()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorNo: Code[20];
    begin
        // [FEATURE] [Report] [Vendor Pre-Payment Journal] [Vendor]
        // [SCENARIO] Gen. Journal Line - OnAfterGetRecord trigger of the Report ID: 10087, Payment Journal - Pre-Check Report for Accepted Payment Tolerance of Account Type Vendor.
        Initialize();

        VendorNo := LibraryPurchase.CreateVendorNo();
        CreateVendorLedgerEntry(VendorLedgerEntry, VendorNo, '');  // Blank Purchaser Code.
        CreateGenJournalLineWithAppliesToDocType(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, VendorNo, GenJournalLine."Document Type"::Invoice);
        UpdateAppliesToDocumentNoOnGenJournalLine(GenJournalLine, VendorLedgerEntry."Document No.");

        // Exercise.
        RunVendorPrePaymentJournal(GenJournalLine);

        // Verify: Verify the Vendor Accepted Payment Tolerance as Zero and Amount Bal. LCY after running Payment Journal Pre Check Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(AmountPmtToleranceCapTxt, 0);  // Zero Accepted Payment Tolerance.
        LibraryReportDataset.AssertElementWithValueExists(AmountBalLcyCapTxt, GenJournalLine."Balance (LCY)");
    end;

    [Test]
    [HandlerFunctions('PaymentDiscToleranceWarning_MPH,PaymentToleranceWarning_MPH,VendorPrePaymentJournalHandler')]
    [Scope('OnPrem')]
    procedure VendorPreReportPrintsPmtDiscAndPmtToleranceForVendorPayment()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PaymentTermsCode: Code[10];
        VendorNo: Code[20];
        InvoiceNo: Code[20];
        InvoiceAmt: Decimal;
        DiscountAmt: Decimal;
        ToleranceAmt: Decimal;
        PaymentAmt: Decimal;
        PaymentDate: Date;
    begin
        // [FEATURE] [Report] [Vendor Pre-Payment Journal] [Vendor]
        // [SCENARIO 252025] REP 317 "Vendor Pre-Payment Journal" prints both "Payment Discount Tolerance" and "Payment Tolerance" amounts in case of vendor payment
        Initialize();

        // [GIVEN] Enabled payment discount tolerance setup with Grace Period = 3D, Tolerance % = 10
        // [GIVEN] Payment terms with Discount Date Calculation = 8D, Discount % = 2
        PreparePmtDiscAndToleranceSetupAndAmounts(PaymentTermsCode, InvoiceAmt, DiscountAmt, ToleranceAmt, PaymentDate);

        // [GIVEN] Posted purchase invoice on "Posting Date" = 01-01-2018 with Amount = 1000
        // [GIVEN] Invoice discount due date = 09-01-2018, discount possible amount = 20, tolerance date = 12-01-2018, possible tolerance amount = 100
        VendorNo := LibraryPurchase.CreateVendorNo();
        InvoiceNo := CreatePostGenJnlInvoiceWithPmtTerms(GenJournalLine."Account Type"::Vendor, VendorNo, PaymentTermsCode, -InvoiceAmt);

        // [GIVEN] Payment applied to the posted invoice on "Posting Date" = 12-01-2018 with Amount = 880 (accept "Post as Payment Discount Tolerance", "Post the Balance as Payment Tolerance")
        PaymentAmt := InvoiceAmt - DiscountAmt - ToleranceAmt;
        CreatePmtJournalLineWithAppliesToID(GenJournalLine, PaymentDate, GenJournalLine."Account Type"::Vendor, VendorNo, PaymentAmt);
        UpdateVendorInvoiceLedgerEntryAppliesToID(VendorNo, InvoiceNo);
        UpdatePmtToleranceOnGenJnlLine(GenJournalLine);

        // [WHEN] Print REP 317 "Vendor Pre-Payment Journal"
        RunVendorPrePaymentJournal(GenJournalLine);

        // [THEN] Report prints:
        // [THEN] Pmt. Discount Tolerance = 20
        // [THEN] Payment Tolerance = 100
        // [THEN] Amount Due = 1000
        // [THEN] Total Amount = 880
        VerifyVendorPreReportDiscAndTolAmounts(DiscountAmt, ToleranceAmt, InvoiceAmt, PaymentAmt);
    end;

    [Test]
    [HandlerFunctions('PaymentDiscToleranceWarning_MPH,PaymentToleranceWarning_MPH,VendorPrePaymentJournalHandler')]
    [Scope('OnPrem')]
    procedure VendorPreReportPrintsPmtDiscAndPmtToleranceForCustomerPayment()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PaymentTermsCode: Code[10];
        CustomerNo: Code[20];
        InvoiceNo: Code[20];
        InvoiceAmt: Decimal;
        DiscountAmt: Decimal;
        ToleranceAmt: Decimal;
        PaymentAmt: Decimal;
        PaymentDate: Date;
    begin
        // [FEATURE] [Report] [Vendor Pre-Payment Journal] [Customer]
        // [SCENARIO 252025] REP 317 "Vendor Pre-Payment Journal" prints both "Payment Discount Tolerance" and "Payment Tolerance" amounts in case of customer payment
        Initialize();

        // [GIVEN] Enabled payment discount tolerance setup with Grace Period = 3D, Tolerance % = 10
        // [GIVEN] Payment terms with Discount Date Calculation = 8D, Discount % = 2
        PreparePmtDiscAndToleranceSetupAndAmounts(PaymentTermsCode, InvoiceAmt, DiscountAmt, ToleranceAmt, PaymentDate);

        // [GIVEN] Posted sales invoice on "Posting Date" = 01-01-2018 with Amount = 1000
        // [GIVEN] Invoice discount due date = 09-01-2018, discount possible amount = 20, tolerance date = 12-01-2018, possible tolerance amount = 100
        CustomerNo := LibrarySales.CreateCustomerNo();
        InvoiceNo := CreatePostGenJnlInvoiceWithPmtTerms(GenJournalLine."Account Type"::Customer, CustomerNo, PaymentTermsCode, InvoiceAmt);

        // [GIVEN] Payment applied to the posted invoice on "Posting Date" = 12-01-2018 with Amount = 880 (accept "Post as Payment Discount Tolerance", "Post the Balance as Payment Tolerance")
        PaymentAmt := InvoiceAmt - DiscountAmt - ToleranceAmt;
        CreatePmtJournalLineWithAppliesToID(GenJournalLine, PaymentDate, GenJournalLine."Account Type"::Customer, CustomerNo, -PaymentAmt);
        UpdateCustomerInvoiceLedgerEntryAppliesToID(CustomerNo, InvoiceNo);
        UpdatePmtToleranceOnGenJnlLine(GenJournalLine);

        // [WHEN] Print REP 317 "Vendor Pre-Payment Journal"
        RunVendorPrePaymentJournal(GenJournalLine);

        // [THEN] Report prints:
        // [THEN] Pmt. Discount Tolerance = 20
        // [THEN] Payment Tolerance = 100
        // [THEN] Amount Due = 1000
        // [THEN] Total Amount = 880
        VerifyVendorPreReportDiscAndTolAmounts(-DiscountAmt, -ToleranceAmt, -InvoiceAmt, -PaymentAmt);
    end;

    [Test]
    [HandlerFunctions('PrintCheckReqPageHandler')]
    [Scope('OnPrem')]
    procedure VendorCheckForPaymentExceedingSumOfMaxIterationsInvoices()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PaymentJournal: TestPage "Payment Journal";
        MaxEntries: Integer;
        PaymentAmount: Integer;
        PurchaseAmount: Integer;
    begin
        // [FEATURE] [Report] [Check] [Vendor]
        // [SCENARIO 294940] Vendor Check total is equal to Payment Amount, when Payment Amount is larger than sum of 30 Purchases
        Initialize();

        // [GIVEN] "External Document No Mandatory" set to false
        LibraryPurchase.SetExtDocNo(false);
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Maximum amount of entries on one page of REP1401 Check is 30
        MaxEntries := 30;
        PurchaseAmount := -LibraryRandom.RandInt(10);

        // [GIVEN] Payment Gen. Jnl Line with Payment amount larger than sum of posted Purchases
        PaymentAmount := LibraryRandom.RandIntInRange(-(MaxEntries + 1) * PurchaseAmount, -(MaxEntries + 10) * PurchaseAmount);
        CreateGenJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor,
          Vendor."No.", PaymentAmount, GenJournalLine."Bank Payment Type"::"Computer Check");
        GenJournalLine.Validate("Applies-to ID", UserId);
        GenJournalLine.Modify(true);
        // [GIVEN] MaxEntries number of Purchases Gen. Jnl Lines posted
        CreateAndPostGenJournalLines(
          GenJournalTemplate.Type::Purchases, PAGE::"Purchase Journal",
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Vendor, Vendor."No.", MaxEntries, PurchaseAmount);

        // [GIVEN] Ledger Entries "Applies-to ID" is set to Paymet Gen. Jnl. Line "Document No."
        VendorLedgerEntry.SetRange("Vendor No.", Vendor."No.");
        LibraryERM.SetAppliestoIdVendor(VendorLedgerEntry);

        // [WHEN] Check printed from Payment Journal page
        UpdateLastCheckNoAndEnqueueValues(GenJournalLine."Bal. Account No.");
        Commit();

        PaymentJournal.OpenEdit();
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalLine."Journal Batch Name");
        PaymentJournal.PrintCheck.Invoke();

        // [THEN] Check Total is equal to Payment ammount
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('TotalLineAmount', PaymentAmount);
    end;

    [Test]
    [HandlerFunctions('PrintCheckReqPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerCheckForPaymentExceedingSumOfMaxIterationsInvoices()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        PaymentJournal: TestPage "Payment Journal";
        MaxEntries: Integer;
        PaymentAmount: Integer;
        PurchaseAmount: Integer;
    begin
        // [FEATURE] [Report] [Check] [Customer]
        // [SCENARIO 294940] Customer Check total is equal to Payment Amount, when Payment Amount is larger than sum of 30 Purchases
        Initialize();

        // [GIVEN] "External Document No Mandatory" set to false
        LibraryPurchase.SetExtDocNo(false);
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Maximum amount of entries on one page of REP1401 Check is 30
        MaxEntries := 30;
        PurchaseAmount := LibraryRandom.RandInt(10);

        // [GIVEN] Payment Gen. Jnl Line with Payment amount larger than sum of posted Purchases
        PaymentAmount := LibraryRandom.RandIntInRange((MaxEntries + 1) * PurchaseAmount, (MaxEntries + 10) * PurchaseAmount);
        CreateGenJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer,
          Customer."No.", PaymentAmount, GenJournalLine."Bank Payment Type"::"Computer Check");
        GenJournalLine.Validate("Applies-to ID", UserId);
        GenJournalLine.Modify(true);

        // [GIVEN] MaxEntries number of Purchases Gen. Jnl Lines posted
        CreateAndPostGenJournalLines(
          GenJournalTemplate.Type::Purchases, PAGE::"Purchase Journal",
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, Customer."No.", MaxEntries, PurchaseAmount);

        // [GIVEN] Ledger Entries "Applies-to ID" is set to Paymet Gen. Jnl. Line "Document No."
        CustLedgerEntry.SetRange("Customer No.", Customer."No.");
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry);

        // [WHEN] Check printed from Payment Journal page
        UpdateLastCheckNoAndEnqueueValues(GenJournalLine."Bal. Account No.");
        Commit();

        PaymentJournal.OpenEdit();
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalLine."Journal Batch Name");
        PaymentJournal.PrintCheck.Invoke();

        // [THEN] Check Total is equal to Payment ammount
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('TotalLineAmount', PaymentAmount);
    end;

    [Test]
    [HandlerFunctions('VendorPrePaymentJournalHandler')]
    [Scope('OnPrem')]
    procedure VendorPrePaymentJournalPrintTwoDifferentWithOneDocumentNo()
    var
        GenJournalLine: array[2] of Record "Gen. Journal Line";
        Vendor: array[2] of Record Vendor;
        GenJournalBatch: Record "Gen. Journal Batch";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Report] [Vendor Pre-Payment Journal] [Vendor]
        // [SCENARIO] "Vendor Pre-Payment Journal" report print separately 2 Gen. Journal lines for different vendors, but with one "Document No".
        Initialize();

        // [GIVEN] "Document No." was generated
        DocumentNo := CopyStr(LibraryRandom.RandText(10), 1, MaxStrLen(DocumentNo));
        ClearGeneralJournalLines(GenJournalBatch);

        // [GIVEN] Created first Vendor and related "Gen. Journal Line"
        CreateVendor(Vendor[1]);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine[1], GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine[1]."Document Type"::Payment,
          GenJournalLine[1]."Account Type"::Vendor, Vendor[1]."No.", LibraryRandom.RandDec(100, 2));
        GenJournalLine[1]."Document No." := DocumentNo;
        GenJournalLine[1].Modify(true);

        // [GIVEN] Created second Vendor and related "Gen. Journal Line"
        CreateVendor(Vendor[2]);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine[2], GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine[2]."Document Type"::Payment,
          GenJournalLine[2]."Account Type"::Vendor, Vendor[2]."No.", LibraryRandom.RandDec(100, 2));
        GenJournalLine[2]."Document No." := DocumentNo;
        GenJournalLine[2].Modify(true);

        // [WHEN] Run report 317 "Vendor Pre-Payment Journal"
        RunVendorPrePaymentJournal(GenJournalLine[1]);

        // [THEN] Verify both "Gen. Journal Line" are printed
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Gen__Journal_Line__Account_No__', Vendor[1]."No.");
        LibraryReportDataset.AssertElementWithValueExists('Gen__Journal_Line__Account_No__', Vendor[2]."No.");
        LibraryReportDataset.AssertElementWithValueExists('TotalAmount', GenJournalLine[1].Amount);
        LibraryReportDataset.AssertElementWithValueExists('TotalAmount', GenJournalLine[2].Amount);
        LibraryReportDataset.AssertElementWithValueExists('Gen__Journal_Line_Amount', GenJournalLine[1].Amount);
        LibraryReportDataset.AssertElementWithValueExists('Gen__Journal_Line_Amount', GenJournalLine[2].Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrintVendorPrePaymentJournal_SameDocumentNoAndOneVendor_WithoutApplications()
    var
        Vendor: Record Vendor;
        GenJournalLine: array[3] of Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        VendorPrePaymentJournal: Report "Vendor Pre-Payment Journal";
        DocumentNo: Code[20];
        RequestPageXML: Text;
    begin
        // [FEATURE] [Report] [Vendor Pre-Payment Journal]
        // [SCENARIO 448581] "Vendor Pre-Payment Journal" report prints one line with combined amounts when there are three lines with the same ("Document No", "Account Type", "Account No.") combination.
        Initialize();

        // [GIVEN] Generate "Document No."
        DocumentNo := CopyStr(LibraryRandom.RandText(10), 1, MaxStrLen(DocumentNo));

        // [GIVEN] Create Vendor
        CreateVendor(Vendor);

        // Clear "Gen. Journal Lines"
        ClearGeneralJournalLines(GenJournalBatch);

        // [GIVEN] Create 1st "Gen. Journal Line"
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine[1], GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine[1]."Document Type"::Payment,
          GenJournalLine[1]."Account Type"::Vendor, Vendor."No.", LibraryRandom.RandDec(100, 2));
        GenJournalLine[1]."Document No." := DocumentNo;
        GenJournalLine[1].Modify(true);

        // [GIVEN] Create 2nd "Gen. Journal Line"
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine[2], GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine[2]."Document Type"::Payment,
          GenJournalLine[2]."Account Type"::Vendor, Vendor."No.", LibraryRandom.RandDec(100, 2));
        GenJournalLine[2]."Document No." := DocumentNo;
        GenJournalLine[2].Modify(true);

        // [GIVEN] Create 3rd "Gen. Journal Line"
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine[3], GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine[3]."Document Type"::Payment,
          GenJournalLine[3]."Account Type"::Vendor, Vendor."No.", LibraryRandom.RandDec(100, 2));
        GenJournalLine[3]."Document No." := DocumentNo;
        GenJournalLine[3].Modify(true);

        // [WHEN] Run report 317 "Vendor Pre-Payment Journal"
        Commit();
        GenJournalBatch.SetRange("Journal Template Name", GenJournalLine[1]."Journal Template Name");
        GenJournalBatch.SetRange(Name, GenJournalLine[1]."Journal Batch Name");
        Clear(VendorPrePaymentJournal);
        LibraryReportDataset.RunReportAndLoad(Report::"Vendor Pre-Payment Journal", GenJournalBatch, RequestPageXML);

        // [THEN] Verify vales in DataSet
        LibraryReportDataset.AssertElementWithValueExists('Gen__Journal_Line__Account_No__', Vendor."No.");
        // 'Gen__Journal_Line_Amount' must have values of all Amounts from "Gen. Journal Line"
        LibraryReportDataset.AssertElementWithValueExists('Gen__Journal_Line_Amount', GenJournalLine[1].Amount);
        LibraryReportDataset.AssertElementWithValueExists('Gen__Journal_Line_Amount', GenJournalLine[2].Amount);
        LibraryReportDataset.AssertElementWithValueExists('Gen__Journal_Line_Amount', GenJournalLine[3].Amount);
        // 'TotalAmount' must have have values of cumulative sum of Amounts from "Gen. Journal Line"
        LibraryReportDataset.AssertElementWithValueExists('TotalAmount', GenJournalLine[1].Amount);
        LibraryReportDataset.AssertElementWithValueExists('TotalAmount', GenJournalLine[1].Amount + GenJournalLine[2].Amount);
        LibraryReportDataset.AssertElementWithValueExists('TotalAmount', GenJournalLine[1].Amount + GenJournalLine[2].Amount + GenJournalLine[3].Amount);
        // 'Amount___TotalAmountDiscounted___TotalAmountPmtDiscTolerance___TotalAmountPmtTolerance___AmountApplied' must also have have values of cumulative sum of Amounts from "Gen. Journal Line"
        LibraryReportDataset.AssertElementWithValueExists('Amount___TotalAmountDiscounted___TotalAmountPmtDiscTolerance___TotalAmountPmtTolerance___AmountApplied', GenJournalLine[1].Amount);
        LibraryReportDataset.AssertElementWithValueExists('Amount___TotalAmountDiscounted___TotalAmountPmtDiscTolerance___TotalAmountPmtTolerance___AmountApplied', GenJournalLine[1].Amount + GenJournalLine[2].Amount);
        LibraryReportDataset.AssertElementWithValueExists('Amount___TotalAmountDiscounted___TotalAmountPmtDiscTolerance___TotalAmountPmtTolerance___AmountApplied', GenJournalLine[1].Amount + GenJournalLine[2].Amount + GenJournalLine[3].Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrintVendorPrePaymentJournal_SameDocumentNoAndTwoVendors_WithApplications()
    var
        Vendor: array[2] of Record Vendor;
        GenJournalLine: array[5] of Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        VendorLedgerEntry: array[4] of Record "Vendor Ledger Entry";
        VendorPrePaymentJournal: Report "Vendor Pre-Payment Journal";
        DocumentNo: Code[20];
        RequestPageXML: Text;
    begin
        // [FEATURE] [Report] [Vendor Pre-Payment Journal]
        // [SCENARIO 448581] "Vendor Pre-Payment Journal" report prints two lines with combined amounts when there are five lines with two ("Document No", "Account Type", "Account No.") combinations. Some lines have Vendor Ledger Entries Applied.
        Initialize();

        // [GIVEN] Generate "Document No."
        DocumentNo := CopyStr(LibraryRandom.RandText(10), 1, MaxStrLen(DocumentNo));
        ClearGeneralJournalLines(GenJournalBatch);

        // [GIVEN] Create Vendor[1]
        CreateVendor(Vendor[1]);

        // [GIVEN] Create Vendor[2]
        CreateVendor(Vendor[2]);

        // [GIVEN] Post 1st Purchase Invoice, for Vendor[1]
        ReturnVendorLedgerEntryForCreatedAndPostedPurchaseInvoice(VendorLedgerEntry[1], Vendor[1]."No.");

        // [GIVEN] Post 2nd Purchase Invoice, for Vendor[1]
        ReturnVendorLedgerEntryForCreatedAndPostedPurchaseInvoice(VendorLedgerEntry[2], Vendor[1]."No.");

        // [GIVEN] Post 3rd Purchase Invoice, for Vendor[1]
        ReturnVendorLedgerEntryForCreatedAndPostedPurchaseInvoice(VendorLedgerEntry[3], Vendor[1]."No.");

        // [GIVEN] Post 4th Purchase Invoice, for Vendor[2]
        ReturnVendorLedgerEntryForCreatedAndPostedPurchaseInvoice(VendorLedgerEntry[4], Vendor[2]."No.");

        // [GIVEN] Create 1st "Gen. Journal Line", for Vendor[1]
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine[1], GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine[1]."Document Type"::Payment,
          GenJournalLine[1]."Account Type"::Vendor, Vendor[1]."No.", LibraryRandom.RandDec(100, 2));
        GenJournalLine[1]."Document No." := DocumentNo;
        GenJournalLine[1].Modify(true);

        // [GIVEN] Create 2nd "Gen. Journal Line", for Vendor[2]
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine[2], GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine[2]."Document Type"::Payment,
          GenJournalLine[2]."Account Type"::Vendor, Vendor[2]."No.", LibraryRandom.RandDec(100, 2));
        GenJournalLine[2]."Document No." := DocumentNo;
        GenJournalLine[2].Modify(true);

        // [GIVEN] Apply created GenJournalLine[2] to VendorLedgerEntry[4] in full "Amount"
        LibraryERM.SetAppliestoIdVendor(VendorLedgerEntry[4]);
        VendorLedgerEntry[4].Validate("Amount to Apply", -GenJournalLine[2].Amount);
        VendorLedgerEntry[4].Modify(true);
        GenJournalLine[2].Validate("Applies-to ID", UserId());
        GenJournalLine[2].Modify(true);

        // [GIVEN] Create 3rd "Gen. Journal Line", for Vendor[1]
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine[3], GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine[3]."Document Type"::Payment,
          GenJournalLine[3]."Account Type"::Vendor, Vendor[1]."No.", LibraryRandom.RandDec(100, 2));
        GenJournalLine[3]."Document No." := DocumentNo;
        GenJournalLine[3].Modify(true);

        // [GIVEN] Apply created GenJournalLine[3] to VendorLedgerEntry[1] using "Applies-to Doc. Type" and "Applies-to Doc. No." in "Gen. Journal Line".
        GenJournalLine[3].Validate("Applies-to Doc. Type", GenJournalLine[3]."Applies-to Doc. Type"::Invoice);
        GenJournalLine[3].Validate("Applies-to Doc. No.", VendorLedgerEntry[1]."Document No.");
        GenJournalLine[3].Modify(true);

        // [GIVEN] Create 4th "Gen. Journal Line", for Vendor[1]
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine[4], GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine[4]."Document Type"::Payment,
          GenJournalLine[4]."Account Type"::Vendor, Vendor[1]."No.", LibraryRandom.RandDec(100, 2));
        GenJournalLine[4]."Document No." := DocumentNo;
        GenJournalLine[4].Modify(true);

        // [GIVEN] Apply created GenJournalLine[4] to VendorLedgerEntry[2] in 1/2 of "Amount"
        LibraryERM.SetAppliestoIdVendor(VendorLedgerEntry[2]);
        VendorLedgerEntry[2].Validate("Amount to Apply", -(GenJournalLine[4].Amount - Round(GenJournalLine[4].Amount / 2)));
        VendorLedgerEntry[2].Modify(true);
        GenJournalLine[4].Validate("Applies-to ID", UserId());
        GenJournalLine[4].Modify(true);

        // [GIVEN] Create 5th "Gen. Journal Line", for Vendor[1]
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine[5], GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine[5]."Document Type"::Payment,
          GenJournalLine[5]."Account Type"::Vendor, Vendor[1]."No.", LibraryRandom.RandDec(100, 2));
        GenJournalLine[5]."Document No." := DocumentNo;
        GenJournalLine[5].Modify(true);

        // [GIVEN] Apply created GenJournalLine[5] to VendorLedgerEntry[3] 3/4 of "Amount"
        LibraryERM.SetAppliestoIdVendor(VendorLedgerEntry[3]);
        VendorLedgerEntry[3].Validate("Amount to Apply", -(GenJournalLine[5].Amount - Round(GenJournalLine[5].Amount / 4)));
        VendorLedgerEntry[3].Modify(true);
        GenJournalLine[5].Validate("Applies-to ID", UserId());
        GenJournalLine[5].Modify(true);

        // [WHEN] Run report 317 "Vendor Pre-Payment Journal"
        Commit();
        GenJournalBatch.SetRange("Journal Template Name", GenJournalLine[1]."Journal Template Name");
        GenJournalBatch.SetRange(Name, GenJournalLine[1]."Journal Batch Name");
        Clear(VendorPrePaymentJournal);
        LibraryReportDataset.RunReportAndLoad(Report::"Vendor Pre-Payment Journal", GenJournalBatch, RequestPageXML);

        // [THEN] Verify vales in DataSet
        LibraryReportDataset.AssertElementWithValueExists('Gen__Journal_Line__Account_No__', Vendor[1]."No.");
        LibraryReportDataset.AssertElementWithValueExists('Gen__Journal_Line__Account_No__', Vendor[2]."No.");
        // 'Gen__Journal_Line_Amount' must have values of all Amounts from "Gen. Journal Line"
        LibraryReportDataset.AssertElementWithValueExists('Gen__Journal_Line_Amount', GenJournalLine[1].Amount);
        LibraryReportDataset.AssertElementWithValueExists('Gen__Journal_Line_Amount', GenJournalLine[2].Amount);
        LibraryReportDataset.AssertElementWithValueExists('Gen__Journal_Line_Amount', GenJournalLine[3].Amount);
        LibraryReportDataset.AssertElementWithValueExists('Gen__Journal_Line_Amount', GenJournalLine[4].Amount);
        LibraryReportDataset.AssertElementWithValueExists('Gen__Journal_Line_Amount', GenJournalLine[5].Amount);
        // 'TotalAmount' must have have values of cumulative sum of Amounts from "Gen. Journal Line" per ("Document No", "Account Type", "Account No.") combinations
        LibraryReportDataset.AssertElementWithValueExists('TotalAmount', GenJournalLine[1].Amount);
        LibraryReportDataset.AssertElementWithValueExists('TotalAmount', GenJournalLine[1].Amount + GenJournalLine[3].Amount);
        LibraryReportDataset.AssertElementWithValueExists('TotalAmount', GenJournalLine[1].Amount + GenJournalLine[3].Amount + GenJournalLine[4].Amount);
        LibraryReportDataset.AssertElementWithValueExists('TotalAmount', GenJournalLine[1].Amount + GenJournalLine[3].Amount + GenJournalLine[4].Amount + GenJournalLine[5].Amount);
        LibraryReportDataset.AssertElementWithValueExists('TotalAmount', GenJournalLine[2].Amount);
        // 'Amount___TotalAmountDiscounted___TotalAmountPmtDiscTolerance___TotalAmountPmtTolerance___AmountApplied' must have have values of cumulative sum of unapplied Amounts from "Gen. Journal Line" per ("Document No", "Account Type", "Account No.") combinations
        LibraryReportDataset.AssertElementWithValueExists('Amount___TotalAmountDiscounted___TotalAmountPmtDiscTolerance___TotalAmountPmtTolerance___AmountApplied', GenJournalLine[1].Amount);
        LibraryReportDataset.AssertElementWithValueExists('Amount___TotalAmountDiscounted___TotalAmountPmtDiscTolerance___TotalAmountPmtTolerance___AmountApplied', GenJournalLine[1].Amount + (GenJournalLine[4].Amount + VendorLedgerEntry[2]."Amount to Apply") + (GenJournalLine[5].Amount + VendorLedgerEntry[3]."Amount to Apply"));
        LibraryReportDataset.AssertElementWithValueExists('Amount___TotalAmountDiscounted___TotalAmountPmtDiscTolerance___TotalAmountPmtTolerance___AmountApplied', GenJournalLine[2].Amount);
    end;

    [Test]
    [HandlerFunctions('VendorPrePaymentJournalHandler')]
    [Scope('OnPrem')]
    procedure PrintVendorPrePaymentJournalTwoPurchaseInvoiceandCrMemoWithSameVendorWithApplications()
    var
        PaymentTerms: Record "Payment Terms";
        PurchaseHeader: Record "Purchase Header";
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        RemainingPmtDiscPossible: Decimal;
        VendorNo: Code[20];
        GLAccountNo: Code[20];
        RowNo: Integer;
    begin
        // Test to verify values on the Report - Vendor Pre-Payment Journal Report.
        // [SCENARIO 547685] [All-E] [IT] Vendor Pre-Payment Journal Report does not show values in Payment Discount.
        Initialize();

        // [GIVEN] Create Payment Term with Dicount % 2
        libraryerm.CreatePaymentTerms(PaymentTerms);
        Evaluate(PaymentTerms."Due Date Calculation", '<1M>');
        Evaluate(PaymentTerms."Discount Date Calculation", '<8D>');
        PaymentTerms.Validate("Due Date Calculation", PaymentTerms."Due Date Calculation");
        PaymentTerms.Validate("Discount Date Calculation", PaymentTerms."Discount Date Calculation");
        PaymentTerms.Validate("Discount %", 2);
        PaymentTerms.Modify(true);

        // [GIVEN] Create New Vendor with that Payment Term
        VendorNo := CreateVendorWithPaymentTerms(PaymentTerms.Code);

        // [GIVEN] Create New G/L Account
        GLAccountNo := LibraryERM.CreateGLAccountWithPurchSetup();

        // [GIVEN] Posted Invoice for Vendor for G/L Account with Amount = 10
        PostPurchaseDocumentWithAmount(
          PurchaseHeader."Document Type"::Invoice, VendorNo,
          GLAccountNo, 10, 1);

        // [GIVEN] Posted Invoice 2 for Vendor for G/L Account with Amount = 10
        PostPurchaseDocumentWithAmount(
          PurchaseHeader."Document Type"::Invoice, VendorNo,
          GLAccountNo, 10, 1);

        // [GIVEN] Posted Credit Memo for Vendor for G/L Account with Amount = 15
        PostPurchaseDocumentWithAmount(
          PurchaseHeader."Document Type"::"Credit Memo", VendorNo,
          GLAccountNo, 15, 1);

        // [GIVEN] Create Payment Journal line for Vendor with Amount= 4.6 as it should be less than Remaining Amount
        CreateGenJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Vendor, VendorNo, 4.6,
          GenJournalLine."Bank Payment Type"::"Computer Check");
        GenJournalLine."Applies-to ID" := UserId;
        GenJournalLine.Modify();

        // [GIVEN] Set Applied to ID to Vendor Ledger Entries
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        LibraryERM.SetAppliestoIdVendor(VendorLedgerEntry);

        // [WHEN] Run report 317 "Vendor Pre-Payment Journal"
        Clear(LibraryReportDataset);
        RunVendorPrePaymentJournal(GenJournalLine);

        // Verify: Verify the Payment Discount amount
        VendorLedgerEntry.Reset();
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        if VendorLedgerEntry.FindSet() then
            repeat
                RemainingPmtDiscPossible += VendorLedgerEntry."Remaining Pmt. Disc. Possible";
            until VendorLedgerEntry.Next() = 0;

        LibraryReportDataset.LoadDataSetFile();
        RowNo := LibraryReportDataset.FindRow('TotalAmountDiscounted', abs(RemainingPmtDiscPossible));

        Assert.IsTrue(RowNo >= 0, TotalAmountDiscountedMustBeAvailableErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,PrintCheckWithReprintReqPageHandler,SuggestVendorPaymentsNewDocPerLineRequestPageHandler')]
    procedure ReprintCheckUsingOneCheckPerVendorPerDoc()
    var
        BankAccount: Record "Bank Account";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseHeader: array[4] of Record "Purchase Header";
        Vendor: array[2] of Record Vendor;
    begin
        // [SCENARIO 578572] Print Checks followed by a Reprint Checks using the "One check per vendor per doc number".
        Initialize();

        // [GIVEN] Create two Vendors.
        LibraryPurchase.CreateVendor(Vendor[1]);
        LibraryPurchase.CreateVendor(Vendor[2]);

        // [GIVEN] Create two Purchase Invoices for both Vendors.
        CreatePurchaseInvoice(PurchaseHeader[1], Vendor[1]."No.");
        CreatePurchaseInvoice(PurchaseHeader[2], Vendor[1]."No.");
        CreatePurchaseInvoice(PurchaseHeader[3], Vendor[2]."No.");
        CreatePurchaseInvoice(PurchaseHeader[4], Vendor[2]."No.");

        // [GIVEN] Create Bank Account.
        BankAccount.Get(CreateBankAccount());

        // [GIVEN] Create Payment Journal using suggested payments.
        CreatePaymentGeneralBatch(GenJournalBatch);

        SuggestVendorPayment(GenJournalLine, GenJournalBatch, Vendor[1]."No.", BankAccount."No.", false);
        SuggestVendorPayment(GenJournalLine, GenJournalBatch, Vendor[2]."No.", BankAccount."No.", false);

        // [GIVEN] Open Payment Journal and Print Check.
        OpenPaymentJournalAndPrintCheck(BankAccount, GenJournalBatch.Name);

        // [WHEN] Reprint Check using "One check per vendor per doc number"
        BankAccount.Get(BankAccount."No.");
        OpenPaymentJournalAndPrintCheck(BankAccount, GenJournalBatch.Name);

        // [THEN] Four Check lines should be printed 
        VerifyNoOfCheckLinesPrinted(GenJournalBatch, 4);
    end;

    [Test]
    [HandlerFunctions('ApplyVendorEntriesModalPageHandler,VendorPrePaymentJournalHandler')]
    procedure PrintVendorPrePaymentJournalWithPmtDisc()
    var
        PaymentTerms: Record "Payment Terms";
        PurchaseHeader: Record "Purchase Header";
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PaymentJournal: TestPage "Payment Journal";
        RemainingPmtDiscPossible: Decimal;
        VendorNo: Code[20];
        GLAccountNo: Code[20];
        RowNo: Integer;
    begin
        // [SCENARIO 556952] Verify values on Vendor Pre-Payment Journal for Payment Discount.
        Initialize();

        // [GIVEN] Create Payment Term with Discount % 2
        libraryerm.CreatePaymentTermsDiscount(PaymentTerms, false);

        // [GIVEN] Create New Vendor with that Payment Term
        VendorNo := CreateVendorWithPaymentTerms(PaymentTerms.Code);
        LibraryVariableStorage.Enqueue(VendorNo);

        // [GIVEN] Create New G/L Account
        GLAccountNo := LibraryERM.CreateGLAccountWithPurchSetup();

        // [GIVEN] Post Purchase Invoice with G/L Account and Workdate as 07042025.
        WorkDate(DMY2Date(7, 4, 2025));
        PostPurchaseDocumentWithAmount(
          PurchaseHeader."Document Type"::Invoice, VendorNo,
          GLAccountNo, LibraryRandom.RandDec(10, 2), 1);

        // [GIVEN] Post Purchase Invoice with G/L Account and Workdate as 04062025.
        WorkDate(DMY2Date(4, 6, 2025));
        PostPurchaseDocumentWithAmount(
          PurchaseHeader."Document Type"::Invoice, VendorNo,
          GLAccountNo, LibraryRandom.RandDec(10, 2), 1);

        // [GIVEN] Create Payment Journal line for Vendor.
        CreateGenJournalLine(
            GenJournalLine, GenJournalLine."Document Type"::Payment,
            GenJournalLine."Account Type"::Vendor, VendorNo, 0,
            GenJournalLine."Bank Payment Type"::"Computer Check");
        GenJournalLine.Modify();

        // [GIVEN] Open Payment Journal and Apply Entries.
        PaymentJournal.OpenEdit();
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalLine."Journal Batch Name");
        PaymentJournal.ApplyEntries.Invoke();

        // [WHEN] Run report 317 "Vendor Pre-Payment Journal"
        Clear(LibraryReportDataset);
        RunVendorPrePaymentJournal(GenJournalLine);

        // [THEN] Verify the Payment Discount amount
        VendorLedgerEntry.Reset();
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.SetFilter("Pmt. Discount Date", '>=%1', GenJournalLine."Posting Date");
        if VendorLedgerEntry.FindSet() then
            repeat
                RemainingPmtDiscPossible += VendorLedgerEntry."Remaining Pmt. Disc. Possible";
            until VendorLedgerEntry.Next() = 0;

        LibraryReportDataset.LoadDataSetFile();
        RowNo := LibraryReportDataset.FindRow('TotalAmountDiscounted', abs(RemainingPmtDiscPossible));

        Assert.IsTrue(RowNo >= 0, TotalAmountDiscountedMustBeAvailableErr);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Financial Reports III");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Financial Reports III");

        LibraryERMCountryData.DisableActivateChequeNoOnGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGenJournalTemplate();
        LibraryERMCountryData.RemoveBlankGenJournalTemplate();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateLocalData();
        UpdateIntrastatCountryCode(); // Required for Intrastat.
        LibraryERMCountryData.UpdateLocalPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();

        IsInitialized := true;

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Financial Reports III");
    end;

    local procedure PreparePmtDiscAndToleranceSetupAndAmounts(var PaymentTermsCode: Code[10]; var InvoiceAmt: Decimal; var DiscountAmt: Decimal; var ToleranceAmt: Decimal; var PaymentDate: Date)
    var
        PaymentTerms: Record "Payment Terms";
    begin
        UpdateGLSetupToleranceDiscount();
        CreatePaymentTerms(PaymentTerms);
        PaymentTermsCode := PaymentTerms.Code;
        InvoiceAmt := LibraryRandom.RandDecInRange(1000, 2000, 2) * 100; // rounding issue in dach
        DiscountAmt := Round(InvoiceAmt * LibraryERM.GetPaymentTermsDiscountPct(PaymentTerms) / 100);
        ToleranceAmt := Round(InvoiceAmt * LibraryPmtDiscSetup.GetPmtTolerancePct() / 100);
        PaymentDate :=
          CalcDate(
            StrSubstNo('<%1>', LibraryPmtDiscSetup.GetPmtDiscGracePeriod()),
            CalcDate(PaymentTerms."Discount Date Calculation", WorkDate()));
    end;

    local procedure BankAccountSum(BankAccReconciliation: Record "Bank Acc. Reconciliation") "Sum": Decimal
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        BankAccReconciliationLine.SetRange("Statement Type", BankAccReconciliation."Statement Type");
        BankAccReconciliationLine.SetRange("Bank Account No.", BankAccReconciliation."Bank Account No.");
        BankAccReconciliationLine.SetRange("Statement No.", BankAccReconciliation."Statement No.");
        BankAccReconciliationLine.FindSet();
        repeat
            Sum += BankAccReconciliationLine."Statement Amount";
        until BankAccReconciliationLine.Next() = 0;
    end;

    local procedure CreateBankAccount(): Code[20]
    var
        BankAccount: Record "Bank Account";
        BankAccountPostingGroup: Record "Bank Account Posting Group";
    begin
        // Create Bank Account with Random Last Statement No.
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccountPostingGroup.FindFirst();
        BankAccount.Validate("Bank Acc. Posting Group", BankAccountPostingGroup.Code);
        BankAccount.Validate("Last Statement No.", Format(LibraryRandom.RandInt(10)));
        BankAccount.Validate("Last Check No.", Format(LibraryRandom.RandInt(10)));
        BankAccount.Modify(true);
        exit(BankAccount."No.");
    end;

    local procedure CreateSuggestedBankReconciliation(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; BankAccountNo: Code[20])
    begin
        CreateBankReconciliation(BankAccReconciliation, BankAccountNo);
        SuggestBankReconciliationLines(BankAccReconciliation);

        // Balance Bank Account Reconciliation.
        BankAccReconciliation.Validate(
          "Statement Ending Balance", BankAccReconciliation."Balance Last Statement" + BankAccountSum(BankAccReconciliation));
        BankAccReconciliation.Modify(true);
    end;

    local procedure CreateVendorWithPaymentTerms(PaymentTermsCode: Code[10]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Payment Terms Code", PaymentTermsCode);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal; BankPaymentType: Enum "Bank Payment Type")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        BankAccount: Record "Bank Account";
    begin
        CreatePaymentGeneralBatch(GenJournalBatch);
        LibraryERM.CreateBankAccount(BankAccount);
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
          AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Bal. Account No.", BankAccount."No.");
        GenJournalLine.Validate("Bank Payment Type", BankPaymentType);
        GenJournalLine.Modify(true);
    end;

    local procedure ClearGeneralJournalLines(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
    end;

    local procedure CreateBankAccountWithCurrency(CurrencyCode: Code[10]): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Currency Code", CurrencyCode);
        BankAccount.Modify(true);
        exit(BankAccount."No.");
    end;

    local procedure CreateBankReconciliation(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; BankAccountNo: Code[20])
    begin
        LibraryERM.CreateBankAccReconciliation(BankAccReconciliation, BankAccountNo,
          BankAccReconciliation."Statement Type"::"Bank Reconciliation");
        BankAccReconciliation.Validate("Statement Date", WorkDate());
        BankAccReconciliation.Modify(true);
    end;

    local procedure CreateCurrencyAndExchangeRate(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        Currency.Validate("Residual Gains Account", FindGLAccountNo());
        Currency.Validate("Residual Losses Account", Currency."Residual Gains Account");
        Currency.Validate("Realized G/L Gains Account", FindGLAccountNo());
        Currency.Validate("Realized G/L Losses Account", Currency."Realized G/L Gains Account");
        Currency.Modify(true);

        // Create Currency Exchange Rate.
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreatePaymentTerms(var PaymentTerms: Record "Payment Terms")
    begin
        // Take Random Values for Discount %.
        LibraryERM.CreatePaymentTermsDiscount(PaymentTerms, true);
    end;

    local procedure CreatePaymentGeneralBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Payments);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure CreatePostVendorInvCrMemoSuggestPayments(var VendorNo: Code[20]; var InvoiceAmount: Decimal; var CrMemoAmount: Decimal; var BankAccount: Record "Bank Account"; var BatchName: Code[10]; Precision: Integer)
    var
        PaymentTerms: Record "Payment Terms";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryCFHelper.CreateDefaultPaymentTerms(PaymentTerms);
        VendorNo := CreateVendorWithPaymentTerms(PaymentTerms.Code);

        InvoiceAmount := LibraryRandom.RandDecInDecimalRange(50, 100, Precision) * 2;
        CrMemoAmount := LibraryRandom.RandDecInDecimalRange(10, 50, Precision) * 2;
        // credit memo amount should be less then invoice's
        CreateGenJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Vendor, VendorNo, -InvoiceAmount, GenJournalLine."Bank Payment Type"::" ");
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        CreateGenJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Account Type"::Vendor, VendorNo, CrMemoAmount, GenJournalLine."Bank Payment Type"::" ");
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        BankAccount.Get(CreateBankAccount());
        CreatePaymentGeneralBatch(GenJournalBatch);
        SuggestVendorPayment(GenJournalLine, GenJournalBatch, VendorNo, BankAccount."No.", false);
        BatchName := GenJournalLine."Journal Batch Name";
    end;

    local procedure CreateCustomer(var Customer: Record Customer)
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate(Name, LibraryUtility.GenerateGUID());
        Customer.Modify(true);
    end;

    local procedure CreateVendor(var Vendor: Record Vendor)
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate(Name, LibraryUtility.GenerateGUID());
        Vendor.Modify(true);
    end;

    local procedure CreateGenJournalLineWithAppliesToDocType(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; AppliesToDocType: Enum "Gen. Journal Document Type")
    begin
        CreateGenJournalLine2(GenJournalLine, AccountType, AccountNo, LibraryRandom.RandDec(10, 2));
        GenJournalLine."Applies-to Doc. Type" := AppliesToDocType;
        GenJournalLine.Modify();
    end;

    local procedure CreateGenJournalLineWithAppliesToID(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; AmountLCY: Decimal; AppliesToID: Code[20])
    begin
        CreateGenJournalLine2(GenJournalLine, AccountType, AccountNo, AmountLCY);
        GenJournalLine."Applies-to ID" := AppliesToID;
        GenJournalLine.Modify();
    end;

    local procedure CreateCustLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; DocType: Enum "Gen. Journal Document Type"; CustNo: Code[20])
    begin
        CustLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(CustLedgerEntry, CustLedgerEntry.FieldNo("Entry No."));
        CustLedgerEntry."Document Type" := DocType;
        CustLedgerEntry."Document No." := LibraryUTUtility.GetNewCode();
        CustLedgerEntry."Customer No." := CustNo;
        CustLedgerEntry.Insert();
    end;

    local procedure CreateVendLedgerEntry(var VendLedgerEntry: Record "Vendor Ledger Entry"; DocType: Enum "Gen. Journal Document Type"; VendNo: Code[20])
    begin
        VendLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(VendLedgerEntry, VendLedgerEntry.FieldNo("Entry No."));
        VendLedgerEntry."Document Type" := DocType;
        VendLedgerEntry."Document No." := LibraryUTUtility.GetNewCode();
        VendLedgerEntry."Vendor No." := VendNo;
        VendLedgerEntry.Insert();
    end;

    local procedure CreateVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; VendorNo: Code[20]; PurchaserCode: Code[10])
    begin
        VendorLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(VendorLedgerEntry, VendorLedgerEntry.FieldNo("Entry No."));
        VendorLedgerEntry."Vendor No." := VendorNo;
        VendorLedgerEntry."Posting Date" := WorkDate();
        VendorLedgerEntry."Due Date" := WorkDate();
        VendorLedgerEntry."Pmt. Discount Date" := WorkDate();
        VendorLedgerEntry."Purchase (LCY)" := LibraryRandom.RandDec(10, 2);
        VendorLedgerEntry."Accepted Payment Tolerance" := LibraryRandom.RandDec(10, 2);
        VendorLedgerEntry."Original Pmt. Disc. Possible" := -LibraryRandom.RandDec(10, 2);
        VendorLedgerEntry.Open := true;
        VendorLedgerEntry."Document Type" := VendorLedgerEntry."Document Type"::Invoice;
        VendorLedgerEntry."Purchaser Code" := PurchaserCode;
        VendorLedgerEntry.Insert();
    end;

    local procedure CreateGenJournalLine2(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; GenJnlLineAmount: Decimal)
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        GenJournalTemplate.Init();
        GenJournalTemplate.Name := LibraryUTUtility.GetNewCode10();
        GenJournalTemplate.Insert();
        GenJournalBatch.Init();
        GenJournalBatch."Journal Template Name" := GenJournalTemplate.Name;
        GenJournalBatch.Name := LibraryUTUtility.GetNewCode10();
        GenJournalBatch.Insert();

        GenJournalLine."Journal Template Name" := GenJournalBatch."Journal Template Name";
        GenJournalLine."Journal Batch Name" := GenJournalBatch.Name;
        GenJournalLine."Line No." := 1;
        GenJournalLine."Account Type" := AccountType;
        GenJournalLine."Account No." := AccountNo;
        GenJournalLine."Document No." := LibraryUTUtility.GetNewCode();
        GenJournalLine.Amount := GenJnlLineAmount;
        GenJournalLine."Amount (LCY)" := GenJnlLineAmount;
        GenJournalLine."Balance (LCY)" := GenJournalLine."Amount (LCY)";
        GenJournalLine.Insert();
    end;

    local procedure CreateCustLedgerEntryWithSpecificAmountAndAppliesToID(var CustLedgerEntry: Record "Cust. Ledger Entry"; DocType: Enum "Gen. Journal Account Type"; CustNo: Code[20]; EntryAmount: Decimal; AppliesToID: Code[20])
    begin
        CustLedgerEntry.Init();
        CreateCustLedgerEntry(CustLedgerEntry, DocType, CustNo);
        CustLedgerEntry.Validate("Amount (LCY)", EntryAmount);
        CustLedgerEntry.Validate("Remaining Amount", EntryAmount);
        CustLedgerEntry.Positive := CustLedgerEntry."Amount (LCY)" > 0;
        CustLedgerEntry."Applies-to ID" := AppliesToID;
        CustLedgerEntry."Amount to Apply" := CustLedgerEntry."Remaining Amount";
        CustLedgerEntry."Accepted Pmt. Disc. Tolerance" := true;
        CustLedgerEntry.Modify();
    end;

    local procedure CreateVendLedgerEntryWithSpecificAmountAndAppliesToID(var VendLedgerEntry: Record "Vendor Ledger Entry"; DocType: Enum "Gen. Journal Document Type"; VendNo: Code[20]; EntryAmount: Decimal; AppliesToID: Code[20])
    begin
        VendLedgerEntry.Init();
        CreateVendLedgerEntry(VendLedgerEntry, DocType, VendNo);
        VendLedgerEntry.Validate("Amount (LCY)", EntryAmount);
        VendLedgerEntry.Validate("Remaining Amount", EntryAmount);
        VendLedgerEntry.Positive := VendLedgerEntry."Amount (LCY)" > 0;
        VendLedgerEntry."Applies-to ID" := AppliesToID;
        VendLedgerEntry."Amount to Apply" := VendLedgerEntry."Remaining Amount";
        VendLedgerEntry."Accepted Pmt. Disc. Tolerance" := true;
        VendLedgerEntry.Modify();
    end;

    local procedure CreatePostGenJnlInvoiceWithPmtTerms(AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; PaymentTermsCode: Code[10]; LineAmount: Decimal): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(GenJournalLine, GenJournalLine."Document Type"::Invoice, AccountType, AccountNo, LineAmount);
        GenJournalLine.Validate("Payment Terms Code", PaymentTermsCode);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine."Document No.");
    end;

    local procedure CreatePmtJournalLineWithAppliesToID(var GenJournalLine: Record "Gen. Journal Line"; PostingDate: Date; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; LineAmount: Decimal)
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(GenJournalLine, GenJournalLine."Document Type"::Payment, AccountType, AccountNo, LineAmount);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("Applies-to ID", UserId);
        GenJournalLine.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateAndPostGenJournalLines(GenJnlTemplateType: Enum "Gen. Journal Template Type"; "Page": Option; DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; GenJnlLinesCount: Integer; PurchaseAmount: Integer)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        GLAccount: Record "G/L Account";
        i: Integer;
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GenJournalTemplate.Get(LibraryJournals.SelectGenJournalTemplate(GenJnlTemplateType, Page));
        LibraryJournals.SelectGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        for i := 1 to GenJnlLinesCount do
            LibraryJournals.CreateGenJournalLine2(
              GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name, DocumentType,
              AccountType, AccountNo, GenJournalLine."Account Type"::"G/L Account", GLAccount."No.", PurchaseAmount);

        GenJournalLine.SetRange("Account No.", AccountNo);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure SuggestVendorPayment(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; VendorNo: Code[20]; BalAccountNo: Code[20]; SummarizePerVend: Boolean)
    var
        SuggestVendorPayments: Report "Suggest Vendor Payments";
    begin
        GenJournalLine."Journal Template Name" := GenJournalBatch."Journal Template Name";
        GenJournalLine."Journal Batch Name" := GenJournalBatch.Name;
        SuggestVendorPayments.SetGenJnlLine(GenJournalLine);
        LibraryVariableStorage.Enqueue(VendorNo);
        LibraryVariableStorage.Enqueue(BalAccountNo);
        LibraryVariableStorage.Enqueue(SummarizePerVend);
        Commit();  // Commit required to run report.
        SuggestVendorPayments.Run();
    end;

    local procedure FindGLAccountNo(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.FindGLAccount(GLAccount);
        exit(GLAccount."No.");
    end;

    local procedure ModifyGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; Amount: Decimal; AppliedToDocNo: Code[20])
    begin
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", AppliedToDocNo);
        GenJournalLine.Validate(Amount, Amount);
        GenJournalLine.Modify(true);
    end;

    local procedure PostGenLinesCustomPostingDate(var GenJournalLine: Record "Gen. Journal Line")
    var
        GLAccount: Record "G/L Account";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        ClearGeneralJournalLines(GenJournalBatch);
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate(Indentation, LibraryRandom.RandInt(5));  // Set Random for Indendation.
        GLAccount.Modify(true);

        // Taking 1000 for multiplication with Devinding Rounding Factor.
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", GLAccount."No.", LibraryRandom.RandDec(1000, 2) * 1000);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", GLAccount."No.", LibraryRandom.RandDec(1000, 2) * 1000);
        GenJournalLine.Validate("Posting Date", CalcDate('<-1Y>', WorkDate()));  // Take Previous Year Date.
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure PostJournalGeneralLineForManualCheck(var BankAccount: Record "Bank Account"): Code[20]
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Find General Journal Template and Batch for posting Manual check.
        ClearGeneralJournalLines(GenJournalBatch);
        BankAccount.Get(CreateBankAccount());

        // Generate a journal line.
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::"Bank Account", CreateBankAccount(), LibraryRandom.RandDec(1000, 2));
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Bal. Account No.", BankAccount."No.");
        GenJournalLine.Validate("Bank Payment Type", GenJournalLine."Bank Payment Type"::"Manual Check");
        GenJournalLine.Modify(true);

        // Post the Journal General Line for Payment through check.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine."Document No.");
    end;

    local procedure PostPurchaseDocumentWithAmount(DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20]; GLAccountNo: Code[20]; DirectUnitCost: Decimal; Quantity: Decimal): Decimal
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccountNo, Quantity);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        exit(PurchaseLine."Amount Including VAT");
    end;

    local procedure OpenPaymentJournalAndPrintCheck(BankAccount: Record "Bank Account"; BatchName: Code[10])
    var
        PaymentJournal: TestPage "Payment Journal";
    begin
        LibraryVariableStorage.Enqueue(BankAccount."No.");
        LibraryVariableStorage.Enqueue(BankAccount."Last Check No.");
        LibraryVariableStorage.Enqueue(true);

        Commit();

        PaymentJournal.OpenEdit();
        PaymentJournal.CurrentJnlBatchName.SetValue := BatchName;
        Commit();
        PaymentJournal.PrintCheck.Invoke();
    end;

    local procedure FindGLAccount(var GLAccount: Record "G/L Account"; No: Code[20]; DateFilter: Date; DateFilter2: Date)
    begin
        GLAccount.SetRange("No.", No);
        GLAccount.SetRange("Date Filter", DateFilter, DateFilter2);
        GLAccount.FindFirst();
    end;

    local procedure FindUpdateGenJnlLine(AccountNo: Code[20]; AppToDocType: Enum "Gen. Journal Account Type"; NewAmount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetRange("Account No.", AccountNo);
        GenJournalLine.SetRange("Applies-to Doc. Type", AppToDocType);
        GenJournalLine.FindFirst();
        GenJournalLine.Validate(Amount, NewAmount);
        GenJournalLine.Modify(true);
    end;

    local procedure GetIndentValue(Indentation: Integer) IndentValue: Integer
    var
        Indent: Option "None","0","1","2","3","4","5";
    begin
        // Get Indent Option according to Random Parameter's Value.
        case Indentation of
            1:
                IndentValue := Indent::"1";
            2:
                IndentValue := Indent::"2";
            3:
                IndentValue := Indent::"3";
            4:
                IndentValue := Indent::"4";
            5:
                IndentValue := Indent::"5";
        end;
    end;

    local procedure GetGLDecimals(): Text[5]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        exit(GeneralLedgerSetup."Amount Decimal Places");
    end;

    local procedure SuggestBankReconciliationLines(var BankAccReconciliation: Record "Bank Acc. Reconciliation")
    var
        BankAccount: Record "Bank Account";
        SuggestBankAccReconLines: Report "Suggest Bank Acc. Recon. Lines";
    begin
        Clear(SuggestBankAccReconLines);
        SuggestBankAccReconLines.SetStmt(BankAccReconciliation);
        SuggestBankAccReconLines.SetTableView(BankAccount);
        SuggestBankAccReconLines.InitializeRequest(WorkDate(), WorkDate(), false);
        SuggestBankAccReconLines.UseRequestPage(false);
        SuggestBankAccReconLines.Run();
    end;

    local procedure UpdateIntrastatCountryCode()
    var
        CompanyInformation: Record "Company Information";
        CountryRegion: Record "Country/Region";
    begin
        CompanyInformation.Get();
        CountryRegion.Get(CompanyInformation."Country/Region Code");
        if CountryRegion."Intrastat Code" = '' then begin
            CountryRegion."Intrastat Code" := CountryRegion.Code;
            CountryRegion.Modify(true);
        end;
    end;

    local procedure UpdateGenJornalLineCurrency(GenJournalLine: Record "Gen. Journal Line"; CurrencyCode: Code[10])
    begin
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Modify(true);
    end;

    local procedure UpdateCustLedgEntryWithPmtDisc(var CustLedgerEntry: Record "Cust. Ledger Entry"; RemPmtDiscPossible: Decimal)
    begin
        CustLedgerEntry."Remaining Pmt. Disc. Possible" := RemPmtDiscPossible;
        CustLedgerEntry.Modify();
    end;

    local procedure UpdateVendLedgEntryWithPmtDisc(var VendLedgerEntry: Record "Vendor Ledger Entry"; RemPmtDiscPossible: Decimal)
    begin
        VendLedgerEntry."Remaining Pmt. Disc. Possible" := RemPmtDiscPossible;
        VendLedgerEntry.Modify();
    end;

    local procedure UpdateAppliesToDocumentNoOnGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AppliesToDocNo: Code[20])
    begin
        GenJournalLine."Applies-to Doc. No." := AppliesToDocNo;
        GenJournalLine.Modify();
    end;

    local procedure UpdateGLSetupToleranceDiscount()
    var
        GLSetup: Record "General Ledger Setup";
        PmtDiscGracePeriod: DateFormula;
    begin
        LibraryPmtDiscSetup.SetPmtToleranceWarning(true);
        LibraryPmtDiscSetup.SetPmtDiscToleranceWarning(true);
        Evaluate(PmtDiscGracePeriod, '<' + Format(LibraryRandom.RandIntInRange(10, 20)) + 'D>');
        LibraryPmtDiscSetup.SetPmtDiscGracePeriod(PmtDiscGracePeriod);
        GLSetup.Get();
        GLSetup.Validate("Pmt. Disc. Tolerance Posting", GLSetup."Pmt. Disc. Tolerance Posting"::"Payment Discount Accounts");
        GLSetup.Validate("Payment Tolerance Posting", GLSetup."Payment Tolerance Posting"::"Payment Tolerance Accounts");
        GLSetup.Validate("Payment Tolerance %", LibraryRandom.RandIntInRange(10, 20));
        GLSetup.Modify(true);
    end;

    local procedure UpdatePmtToleranceOnGenJnlLine(var GenJournalLine: Record "Gen. Journal Line")
    var
        PaymentToleranceMgt: Codeunit "Payment Tolerance Management";
    begin
        PaymentToleranceMgt.PmtTolGenJnl(GenJournalLine);
    end;

    local procedure UpdateVendorInvoiceLedgerEntryAppliesToID(VendorNo: Code[20]; InvoiceNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Invoice);
        VendorLedgerEntry.SetRange("Document No.", InvoiceNo);
        LibraryERM.SetAppliestoIdVendor(VendorLedgerEntry);
    end;

    local procedure UpdateCustomerInvoiceLedgerEntryAppliesToID(CustomerNo: Code[20]; InvoiceNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
        CustLedgerEntry.SetRange("Document No.", InvoiceNo);
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry);
    end;

    local procedure UpdateBankAccountLastCheckNo(var BankAccount: Record "Bank Account"; BankAccountNo: Code[20])
    begin
        BankAccount.Get(BankAccountNo);
        BankAccount.Validate("Last Check No.", Format(LibraryRandom.RandInt(10)));
        BankAccount.Modify(true);
    end;

    local procedure UpdateLastCheckNoAndEnqueueValues(BankAccountNo: Code[20])
    var
        BankAccount: Record "Bank Account";
    begin
        UpdateBankAccountLastCheckNo(BankAccount, BankAccountNo);
        LibraryVariableStorage.Enqueue(BankAccount."No.");
        LibraryVariableStorage.Enqueue(BankAccount."Last Check No.");
        LibraryVariableStorage.Enqueue(false);
    end;

    local procedure RunVendorPrePaymentJournal(GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        VendorPrePaymentJournal: Report "Vendor Pre-Payment Journal";
    begin
        Commit();
        GenJournalBatch.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJournalBatch.SetRange(Name, GenJournalLine."Journal Batch Name");
        Clear(VendorPrePaymentJournal);
        VendorPrePaymentJournal.SetTableView(GenJournalBatch);
        VendorPrePaymentJournal.Run();  // Invokes VendorPrePaymentJournalHandler.
    end;

    local procedure PrintVendCheckForUpdatedAmount(AppToDocTypeToUpd: Option; Precision: Integer)
    var
        BankAccount: Record "Bank Account";
        VendorNo: Code[20];
        BatchName: Code[10];
        InvoiceAmount: Decimal;
        CrMemoAmount: Decimal;
    begin
        // Setup: create and post invoice and credit memo, suggest vendor payment, decrease amount
        Initialize();

        LibraryERM.SetAmountRoundingPrecision(0.01);
        CreatePostVendorInvCrMemoSuggestPayments(VendorNo, InvoiceAmount, CrMemoAmount, BankAccount, BatchName, Precision);

        case AppToDocTypeToUpd of
            AppToDocTypeToUpdate::Invoice:
                // decrease invoice amount (less than before, but grater that credit memo)
                DecreaseVendorAppToInvoiceAmount(InvoiceAmount, CrMemoAmount, VendorNo);
            AppToDocTypeToUpdate::"Credit Memo":
                // decrease credit memo amount
                DecreaseVendorAppToCrMemoAmount(CrMemoAmount, VendorNo);
        end;

        // Excercise: open payment journal and print check
        OpenPaymentJournalAndPrintCheck(BankAccount, BatchName);

        // Verify: total amount should be equal to difference between invoice and credit memo
        VerifyCheckTotalAmount(InvoiceAmount, CrMemoAmount);
    end;

    local procedure DecreaseVendorAppToCrMemoAmount(var CrMemoAmount: Decimal; VendorNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CrMemoAmount := Round(CrMemoAmount / 2);
        FindUpdateGenJnlLine(VendorNo, GenJournalLine."Applies-to Doc. Type"::"Credit Memo", -CrMemoAmount);
    end;

    local procedure DecreaseVendorAppToInvoiceAmount(var InvoiceAmount: Decimal; CrMemoAmount: Decimal; VendorNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        InvoiceAmount := Round((InvoiceAmount + CrMemoAmount) / 2);
        FindUpdateGenJnlLine(VendorNo, GenJournalLine."Applies-to Doc. Type"::Invoice, InvoiceAmount);
    end;

    local procedure FormatAmount(Amount: Decimal; Decimals: Text[5]) ValueAsText: Text
    var
        ZeroValue: Decimal;
    begin
        if Amount = 0 then
            exit('');

        ValueAsText := Format(Amount, 0, LibraryAccSchedule.GetCustomFormatString(Format(Decimals)));
        if Evaluate(ZeroValue, ValueAsText) and (ZeroValue = 0) then
            exit('');
    end;

    local procedure CalcEntriesAmount(var EntryAmount: array[3] of Decimal; InvAmount: Decimal; PmtDiscPossible: Decimal)
    begin
        EntryAmount[EntryType::Invoice] := InvAmount;
        EntryAmount[EntryType::"Credit Memo"] :=
          -Round(EntryAmount[EntryType::Invoice] / LibraryRandom.RandIntInRange(3, 5));
        EntryAmount[EntryType::Payment] :=
          -(EntryAmount[EntryType::Invoice] + EntryAmount[EntryType::"Credit Memo"] - PmtDiscPossible);
    end;

    local procedure VerifyDocumentEntries(DocEntryTableName: Text[50]; RowValue: Integer)
    begin
        LibraryReportDataset.SetRange(DocEntryTableNameLbl, DocEntryTableName);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals(DocEntryNoofRecordsLbl, RowValue)
    end;

    local procedure VerifyTextAmountInXMLFile(ElementName: Text[250]; ExpectedValue: Text)
    var
        TextAmount: Variant;
        TextValue: Text;
    begin
        LibraryReportDataset.FindCurrentRowValue(ElementName, TextAmount);
        Evaluate(TextValue, TextAmount);
        Assert.AreEqual(ExpectedValue, TextValue, ValidationErr);
    end;

    local procedure VerifyCheckTotalAmount(InvoiceAmount: Decimal; CrMemoAmount: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('TotalText', 'Total');
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), StrSubstNo(RowNotFoundErr, 'TotalText', 'Total'));
        LibraryReportDataset.AssertCurrentRowValueEquals('TotalLineAmount', InvoiceAmount - CrMemoAmount);
    end;

    local procedure VerifyInvAndPmtDiscInPreCheckReport(AmountToApplyDiscTolCap: Text; InvAmount: Decimal; PmtDiscAmount: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(AmountToApplyDiscTolCap, InvAmount);
        LibraryReportDataset.AssertElementWithValueNotExist(AmountTotalDiscTolAppliedTxt, PmtDiscAmount);
    end;

    local procedure VerifyVendorPreReportDiscAndTolAmounts(DiscountAmount: Decimal; ToleranceAmount: Decimal; AmountDue: Decimal; TotalAmount: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('AmountPmtDiscTolerance', DiscountAmount);
        LibraryReportDataset.AssertElementWithValueExists(AmountPmtToleranceCapTxt, ToleranceAmount);
        LibraryReportDataset.AssertElementWithValueExists('AmountDue', AmountDue);
        LibraryReportDataset.AssertElementWithValueExists('TotalAmount', TotalAmount);
    end;

    local procedure ReturnVendorLedgerEntryForCreatedAndPostedPurchaseInvoice(var VendorLedgerEntry: Record "Vendor Ledger Entry"; VendorNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(), LibraryRandom.RandInt(100));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(1000, 2));
        PurchaseLine.Modify(true);

        LibraryERM.FindVendorLedgerEntry(
          VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreatePurchaseInvoice(PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20])
    begin
        LibraryPurchase.CreatePurchaseInvoiceForVendorNo(PurchaseHeader, VendorNo);
        PurchaseHeader.Validate("Posting Date", Today);
        PurchaseHeader.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);
    end;
    
    local procedure VerifyNoOfCheckLinesPrinted(GenJournalBatch: Record "Gen. Journal Batch"; ExpectedCheckLines: Integer)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.SetRange("Document Type", GenJournalLine."Document Type"::Payment);
        GenJournalLine.SetRange("Bank Payment Type", GenJournalLine."Bank Payment Type"::"Computer Check");
        Assert.AreEqual(ExpectedCheckLines, GenJournalLine.Count(), NoOfCheckLinesErr);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure DocumentEntriesReqPageHandler(var DocumentEntries: TestRequestPage "Document Entries")
    var
        CurrecnyInLcy: Variant;
    begin
        LibraryVariableStorage.Dequeue(CurrecnyInLcy);
        DocumentEntries.PrintAmountsInLCY.SetValue(CurrecnyInLcy);  // Boolean Show Amount in LCY
        DocumentEntries.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure NavigatePageHandler(var Navigate: TestPage Navigate)
    begin
        Navigate."No. of Records".Value();
        Navigate.Print.Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BalanceCompPrevYearReqPageHandler(var BalanceCompPrevYear: TestRequestPage "Balance Comp. - Prev. Year")
    begin
        BalanceCompPrevYear.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BankAccountStatementReportReqPageHandler(var BankAccountStatement: TestRequestPage "Bank Account Statement")
    begin
        BankAccountStatement.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ForeignCurrencyBalanceReqPageHandler(var ForeignCurrencyBalance: TestRequestPage "Foreign Currency Balance")
    begin
        ForeignCurrencyBalance.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure TrialBalanceByPeriodReqPageHandler(var TrialBalanceByPeriod: TestRequestPage "Trial Balance by Period")
    begin
        TrialBalanceByPeriod.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PrintCheckReqPageHandler(var Check: TestRequestPage Check)
    var
        FileName: Text;
        ParametersFileName: Text;
        Value: Variant;
    begin
        LibraryVariableStorage.Dequeue(Value);
        Check.BankAccount.SetValue(Value);
        LibraryVariableStorage.Dequeue(Value);
        Check.LastCheckNo.SetValue(Value);
        LibraryVariableStorage.Dequeue(Value);
        Check.OneCheckPerVendorPerDocumentNo.SetValue(Value);

        ParametersFileName := LibraryReportDataset.GetParametersFileName();
        FileName := LibraryReportDataset.GetFileName();
        Check.SaveAsXml(ParametersFileName, FileName);
        Sleep(200)
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentsRequestPageHandler(var SuggestVendorPayments: TestRequestPage "Suggest Vendor Payments")
    var
        VendorNo: Variant;
        BankAccountNo: Variant;
        SummarizePerVend: Variant;
        BalAccountType: Option "G/L Account",,,"Bank Account";
        BankPmtType: Option " ","Computer Check","Manual Check";
    begin
        LibraryVariableStorage.Dequeue(VendorNo);
        LibraryVariableStorage.Dequeue(BankAccountNo);
        LibraryVariableStorage.Dequeue(SummarizePerVend);
        SuggestVendorPayments.Vendor.SetFilter("No.", VendorNo);
        SuggestVendorPayments.SummarizePerVendor.SetValue(SummarizePerVend);
        SuggestVendorPayments.BalAccountType.SetValue(BalAccountType::"Bank Account");
        SuggestVendorPayments.BalAccountNo.SetValue(BankAccountNo);
        SuggestVendorPayments.BankPaymentType.SetValue(BankPmtType::"Computer Check");
        SuggestVendorPayments.LastPaymentDate.SetValue(WorkDate());
        SuggestVendorPayments.StartingDocumentNo.SetValue(LibraryRandom.RandInt(10));
        SuggestVendorPayments.OK().Invoke();
        Sleep(200);
    end;

    [RequestPageHandler]
    procedure SuggestVendorPaymentsNewDocPerLineRequestPageHandler(var SuggestVendorPayments: TestRequestPage "Suggest Vendor Payments")
    var
        VendorNo: Variant;
        BankAccountNo: Variant;
        SummarizePerVend: Variant;
        BalAccountType: Option "G/L Account",,,"Bank Account";
        BankPmtType: Option " ","Computer Check","Manual Check";
    begin
        LibraryVariableStorage.Dequeue(VendorNo);
        LibraryVariableStorage.Dequeue(BankAccountNo);
        LibraryVariableStorage.Dequeue(SummarizePerVend);
        SuggestVendorPayments.Vendor.SetFilter("No.", VendorNo);
        SuggestVendorPayments.SummarizePerVendor.SetValue(SummarizePerVend);
        SuggestVendorPayments.BalAccountType.SetValue(BalAccountType::"Bank Account");
        SuggestVendorPayments.BalAccountNo.SetValue(BankAccountNo);
        SuggestVendorPayments.BankPaymentType.SetValue(BankPmtType::"Computer Check");
        SuggestVendorPayments.LastPaymentDate.SetValue(WorkDate());
        SuggestVendorPayments.NewDocNoPerLine.SetValue(true);
        SuggestVendorPayments.StartingDocumentNo.SetValue(LibraryRandom.RandInt(10));
        SuggestVendorPayments.OK().Invoke();
        Sleep(200);
    end;

    [RequestPageHandler]
    procedure PrintCheckWithReprintReqPageHandler(var Check: TestRequestPage Check)
    var
        FileName: Text;
        ParametersFileName: Text;
        Value: Variant;
    begin
        LibraryVariableStorage.Dequeue(Value);
        Check.BankAccount.SetValue(Value);
        LibraryVariableStorage.Dequeue(Value);
        Check.LastCheckNo.SetValue(Value);
        LibraryVariableStorage.Dequeue(Value);
        Check.OneCheckPerVendorPerDocumentNo.SetValue(Value);
        Check.ReprintChecks.SetValue(true);

        ParametersFileName := LibraryReportDataset.GetParametersFileName();
        FileName := LibraryReportDataset.GetFileName();
        Check.SaveAsXml(ParametersFileName, FileName);
        Sleep(200)
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VendorPrePaymentJournalHandler(var VendorPrePaymentJournal: TestRequestPage "Vendor Pre-Payment Journal")
    begin
        if VendorPrePaymentJournal.Editable() then;
        VendorPrePaymentJournal.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PaymentToleranceWarning_MPH(var PaymentToleranceWarning: TestPage "Payment Tolerance Warning")
    var
        PostingOption: Option ,"Post the Balance as Payment Tolerance","Leave a Remaining Amount";
    begin
        PaymentToleranceWarning.AppliedAmount.Value();
        PaymentToleranceWarning.Posting.SetValue(PostingOption::"Post the Balance as Payment Tolerance");
        PaymentToleranceWarning.Yes().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PaymentDiscToleranceWarning_MPH(var PaymentDiscToleranceWarning: TestPage "Payment Disc Tolerance Warning")
    var
        PostingOption: Option ,"Post as Payment Discount Tolerance","Do Not Accept the Late Payment Discount";
    begin
        PaymentDiscToleranceWarning.AppliedAmount.Value();
        PaymentDiscToleranceWarning.Posting.SetValue(PostingOption::"Post as Payment Discount Tolerance");
        PaymentDiscToleranceWarning.Yes().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyVendorEntriesModalPageHandler(var ApplyVendorEntries: TestPage "Apply Vendor Entries")
    begin
        ApplyVendorEntries.ActionSetAppliesToID.Invoke();
        ApplyVendorEntries.Next();
        ApplyVendorEntries.ActionSetAppliesToID.Invoke();
        ApplyVendorEntries.OK().Invoke();
    end;
}