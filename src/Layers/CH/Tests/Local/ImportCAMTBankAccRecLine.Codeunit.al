codeunit 144084 "Import CAMT Bank AccRecLine"
{
    // // [FEATURE] [Bank Reconciliation] [SEPA CAMT]

    EventSubscriberInstance = Manual;
    Permissions = TableData "Bank Export/Import Setup" = rimd,
                  TableData "Cust. Ledger Entry" = id;
    SingleInstance = true;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryCAMTFileMgt: Codeunit "Library - CAMT File Mgt.";
        TempBlobGlobal: Codeunit "Temp Blob";
        ImportTypeRef: Option camt05302,camt05304,camt054;
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure ImportCAMT_053_02()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLineTemplate: Record "Bank Acc. Reconciliation Line";
        BankAcc: Record "Bank Account";
        ImportCAMTBankAccRecLine: Codeunit "Import CAMT Bank AccRecLine";
    begin
        // [FEATURE] [CAMT 053-02]
        // [SCENARIO 221219] Import CAMT 053.001.02
        Initialize();

        // [GIVEN] CAMT 053.001.02 xml with statement header, balance node and one entry node
        SetupWriteCAMTFile05302();

        // [GIVEN] Setup of Bank Account with Bank Acc. Reconciliation for CAMT 053.001.02
        SetupBankAccWithBankReconciliation(BankAcc, BankAccReconciliation, BankAccReconciliationLineTemplate, GetCAMT05302DataExch());

        // [WHEN] Import Bank Statement
        BindSubscription(ImportCAMTBankAccRecLine);
        LibraryLowerPermissions.SetBanking();
        BankAccReconciliation.ImportBankStatement();
        UnbindSubscription(ImportCAMTBankAccRecLine);

        // [THEN] Two Bank Reconciliation lines created
        VerifyBankAccRecLineWithDataExchField(BankAccReconciliationLineTemplate, GetCAMT05302DataExch(), 1, 18);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ImportCAMT_053_04()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLineTemplate: Record "Bank Acc. Reconciliation Line";
        BankAcc: Record "Bank Account";
        ImportCAMTBankAccRecLine: Codeunit "Import CAMT Bank AccRecLine";
        ImpSEPACAMTBankRecLines: Codeunit "Imp. SEPA CAMT Bank Rec. Lines";
        StartBalAmt: Decimal;
        CreditAmt1: Decimal;
        CreditAmt2: Decimal;
        DebitAmt: Decimal;
    begin
        // [FEATURE] [CAMT 053-04]
        // [SCENARIO 221219] Import CAMT 053.001.04
        Initialize();

        // [GIVEN] CAMT 053.001.04 xml with statement header, balance node and one 2 entry nodes
        SetupWriteCAMTFile05304();

        // [GIVEN] Setup of Bank Account with Bank Acc. Reconciliation for CAMT 053.001.04
        SetupBankAccWithBankReconciliation(BankAcc, BankAccReconciliation, BankAccReconciliationLineTemplate, GetCAMT05304DataExch());

        // [WHEN] Import Bank Statement
        BindSubscription(ImportCAMTBankAccRecLine);
        LibraryLowerPermissions.SetBanking();
        BankAccReconciliation.ImportBankStatement();
        UnbindSubscription(ImportCAMTBankAccRecLine);

        // [THEN] Two Bank Reconciliation lines created
        VerifyBankAccRecLineWithDataExchField(BankAccReconciliationLineTemplate, GetCAMT05304DataExch(), 2, 27);

        // [THEN] Statement ending balance is correctly imported
        ImpSEPACAMTBankRecLines.InitNodeText();
        ImpSEPACAMTBankRecLines.InitBalTypeDescriptor();
        ImpSEPACAMTBankRecLines.RunPostProcess(BankAccReconciliationLineTemplate);
        BankAccReconciliation.Find();
        SetStatementValues(StartBalAmt, CreditAmt1, CreditAmt2, DebitAmt);
        Assert.AreEqual(StartBalAmt + CreditAmt1 + CreditAmt2 - DebitAmt, BankAccReconciliation."Statement Ending Balance", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ImportCAMT_054()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLineTemplate: Record "Bank Acc. Reconciliation Line";
        BankAcc: Record "Bank Account";
        ImportCAMTBankAccRecLine: Codeunit "Import CAMT Bank AccRecLine";
    begin
        // [FEATURE] [CAMT 054]
        // [SCENARIO 221219] Import CAMT 054.001.04
        Initialize();

        // [GIVEN] CAMT 054.001.04 xml with statement header, balance node and one entry node
        SetupWriteCAMTFile054();

        // [GIVEN] Setup of Bank Account with Bank Acc. Reconciliation for CAMT 054.001.04
        SetupBankAccWithBankReconciliation(BankAcc, BankAccReconciliation, BankAccReconciliationLineTemplate, GetCAMT054DataExch());

        // [WHEN] Import Bank Statement
        BindSubscription(ImportCAMTBankAccRecLine);
        LibraryLowerPermissions.SetBanking();
        BankAccReconciliation.ImportBankStatement();
        UnbindSubscription(ImportCAMTBankAccRecLine);

        // [THEN] One Bank Reconciliation line created
        VerifyBankAccRecLineWithDataExchField(BankAccReconciliationLineTemplate, GetCAMT054DataExch(), 1, 12);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ImportCAMT_053_02_GenJnl()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        ImportCAMTBankAccRecLine: Codeunit "Import CAMT Bank AccRecLine";
    begin
        // [FEATURE] [CAMT 053-02]
        // [SCENARIO 234534] Import CAMT 053.001.02 to General Journal
        Initialize();

        // [GIVEN] CAMT 053.001.02 xml with statement header, balance node and one entry node
        SetupWriteCAMTFile05302();

        // [GIVEN] Setup of Bank Statement Import Format for CAMT 053.001.02
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        GenJournalBatch.Validate(
          "Bank Statement Import Format",
          CreateBankExportImportSetup(GetCAMT05302DataExch(), GetCAMT053ProcCodID()));
        GenJournalBatch.Modify(true);

        // [WHEN] Import Bank Statement for Gen. Jnl. Line
        BindSubscription(ImportCAMTBankAccRecLine);
        GenJnlImportBankStatement(GenJournalBatch);
        UnbindSubscription(ImportCAMTBankAccRecLine);

        // [THEN] One Gen. Journal Line is created
        VerifyGenJnlLineWithDataExchField(GenJournalBatch, 1, 18);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ImportCAMT_053_04_GenJnl()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        ImportCAMTBankAccRecLine: Codeunit "Import CAMT Bank AccRecLine";
    begin
        // [FEATURE] [CAMT 053-04]
        // [SCENARIO 234534] Import CAMT 053.001.04 to Gen. Journal
        Initialize();

        // [GIVEN] CAMT 053.001.04 xml with statement header, balance node and one entry node
        SetupWriteCAMTFile05304();

        // [GIVEN] Setup of Bank Statement Import Format for CAMT 053.001.04
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        GenJournalBatch.Validate(
          "Bank Statement Import Format",
          CreateBankExportImportSetup(GetCAMT05304DataExch(), GetCAMT053ProcCodID()));
        GenJournalBatch.Modify(true);

        // [WHEN] Import Bank Statement for Gen. Jnl. Line
        BindSubscription(ImportCAMTBankAccRecLine);
        GenJnlImportBankStatement(GenJournalBatch);
        UnbindSubscription(ImportCAMTBankAccRecLine);

        // [THEN] Two Gen. Journal Lines are created
        VerifyGenJnlLineWithDataExchField(GenJournalBatch, 2, 27);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ImportCAMT_054_GenJnl()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        ImportCAMTBankAccRecLine: Codeunit "Import CAMT Bank AccRecLine";
    begin
        // [FEATURE] [CAMT 054]
        // [SCENARIO 234534] Import CAMT 054.001.04 to Gen. Journal
        Initialize();

        // [GIVEN] CAMT 054.001.04 xml with statement header, balance node and one entry node
        SetupWriteCAMTFile054();

        // [GIVEN] Setup of Bank Statement Import Format for CAMT 054.001.04
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        GenJournalBatch.Validate(
          "Bank Statement Import Format",
          CreateBankExportImportSetup(GetCAMT054DataExch(), GetCAMT054ProcCodID()));
        GenJournalBatch.Modify(true);

        // [WHEN] Import Bank Statement for Gen. Jnl. Line
        BindSubscription(ImportCAMTBankAccRecLine);
        GenJnlImportBankStatement(GenJournalBatch);
        UnbindSubscription(ImportCAMTBankAccRecLine);

        // [THEN] One Gen. Journal Line is created
        VerifyGenJnlLineWithDataExchField(GenJournalBatch, 1, 12);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ImportCAMT_054_OnePmtOneInv()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        ImportCAMTBankAccRecLine: Codeunit "Import CAMT Bank AccRecLine";
        PmtCurrency: Text;
        PmtAmount: Decimal;
        InvCurrency: Text;
        InvAmount: Decimal;
        InvDbtrName: Text;
        InvRefTxt: Text;
    begin
        // [FEATURE] [CAMT 054]
        // [SCENARIO 225918] Import CAMT 054.001.04 in case of one payment with one invoice (identical amounts and currencies)
        Initialize();
        PrepareValuesForImportCAMT054_OnePmtOneInv(PmtCurrency, PmtAmount, InvCurrency, InvAmount, InvDbtrName, InvRefTxt);

        // [GIVEN] CAMT 054.001.04 xml: one payment (Amount = 1234.56 CHF) with one invoice (Amount = 1234.56 CHF, Debitor Name = "DBTR_NAME", Ref. No. = "INV_REF")
        SetupBankAndWriteCAMTFile054_OnePmtOneInv(
          BankAccReconciliation, BankAccReconciliationLine, PmtCurrency, PmtAmount, InvCurrency, InvAmount, InvDbtrName, InvRefTxt);

        // [WHEN] Import bank statement
        BindSubscription(ImportCAMTBankAccRecLine);
        LibraryLowerPermissions.SetBanking();
        BankAccReconciliation.ImportBankStatement();
        UnbindSubscription(ImportCAMTBankAccRecLine);

        // [THEN] One bank reconciliation line has been created with following details:
        // [THEN] "Amount" = 1234.56, "Related-Party Name" = "DBTR_NAME", "Additional Transaction Info" = "INV_REF"
        VerifyImportCAMT054_OnePayment(BankAccReconciliationLine, PmtCurrency, PmtAmount, InvDbtrName, InvRefTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ImportCAMT_054_OnePmtOneInv_Diff_Amt_Higher()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        ImportCAMTBankAccRecLine: Codeunit "Import CAMT Bank AccRecLine";
        PmtCurrency: Text;
        PmtAmount: Decimal;
        InvCurrency: Text;
        InvAmount: Decimal;
        InvDbtrName: Text;
        InvRefTxt: Text;
    begin
        // [FEATURE] [CAMT 054]
        // [SCENARIO 225918] Import CAMT 054.001.04 in case of one payment with one invoice (identical currencies, invoice amount is higher than payment's)
        Initialize();
        PrepareValuesForImportCAMT054_OnePmtOneInv(PmtCurrency, PmtAmount, InvCurrency, InvAmount, InvDbtrName, InvRefTxt);

        // [GIVEN] CAMT 054.001.04 xml: one payment (Amount = 1234.56 CHF) with one invoice (Amount = 1234.57 CHF, Debitor Name = "DBTR_NAME", Ref. No. = "INV_REF")
        InvAmount += 0.01;
        SetupBankAndWriteCAMTFile054_OnePmtOneInv(
          BankAccReconciliation, BankAccReconciliationLine, PmtCurrency, PmtAmount, InvCurrency, InvAmount, InvDbtrName, InvRefTxt);

        // [WHEN] Import bank statement
        BindSubscription(ImportCAMTBankAccRecLine);
        LibraryLowerPermissions.SetBanking();
        BankAccReconciliation.ImportBankStatement();
        UnbindSubscription(ImportCAMTBankAccRecLine);

        // [THEN] One bank reconciliation line has been created with following details:
        // [THEN] "Amount" = 1234.56, "Related-Party Name" = "DBTR_NAME", "Additional Transaction Info" = "INV_REF"
        VerifyImportCAMT054_OnePayment(BankAccReconciliationLine, PmtCurrency, PmtAmount, InvDbtrName, InvRefTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ImportCAMT_054_OnePmtOneInv_Diff_Amt_Lower()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        ImportCAMTBankAccRecLine: Codeunit "Import CAMT Bank AccRecLine";
        PmtCurrency: Text;
        PmtAmount: Decimal;
        InvCurrency: Text;
        InvAmount: Decimal;
        InvDbtrName: Text;
        InvRefTxt: Text;
    begin
        // [FEATURE] [CAMT 054]
        // [SCENARIO 225918] Import CAMT 054.001.04 in case of one payment with one invoice (identical currencies, invoice amount is lower than payment's)
        Initialize();
        PrepareValuesForImportCAMT054_OnePmtOneInv(PmtCurrency, PmtAmount, InvCurrency, InvAmount, InvDbtrName, InvRefTxt);

        // [GIVEN] CAMT 054.001.04 xml: one payment (Amount = 1234.56 CHF) with one invoice (Amount = 1234.55 CHF, Debitor Name = "DBTR_NAME", Ref. No. = "INV_REF")
        InvAmount -= 0.01;
        SetupBankAndWriteCAMTFile054_OnePmtOneInv(
          BankAccReconciliation, BankAccReconciliationLine, PmtCurrency, PmtAmount, InvCurrency, InvAmount, InvDbtrName, InvRefTxt);

        // [WHEN] Import bank statement
        BindSubscription(ImportCAMTBankAccRecLine);
        LibraryLowerPermissions.SetBanking();
        BankAccReconciliation.ImportBankStatement();
        UnbindSubscription(ImportCAMTBankAccRecLine);

        // [THEN] One bank reconciliation line has been created with following details:
        // [THEN] "Amount" = 1234.56, "Related-Party Name" = "DBTR_NAME", "Additional Transaction Info" = "INV_REF"
        VerifyImportCAMT054_OnePayment(BankAccReconciliationLine, PmtCurrency, PmtAmount, InvDbtrName, InvRefTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ImportCAMT_054_OnePmtOneInv_Diff_Currency()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        ImportCAMTBankAccRecLine: Codeunit "Import CAMT Bank AccRecLine";
        PmtCurrency: Text;
        PmtAmount: Decimal;
        InvCurrency: Text;
        InvAmount: Decimal;
        InvDbtrName: Text;
        InvRefTxt: Text;
    begin
        // [FEATURE] [CAMT 054]
        // [SCENARIO 225918] Import CAMT 054.001.04 in case of one payment with one invoice (identical amounts, different currencies)
        Initialize();
        PrepareValuesForImportCAMT054_OnePmtOneInv(PmtCurrency, PmtAmount, InvCurrency, InvAmount, InvDbtrName, InvRefTxt);

        // [GIVEN] CAMT 054.001.04 xml: one payment (Amount = 1234.56 CHF) with one invoice (Amount = 1234.56 EUR, Debitor Name = "DBTR_NAME", Ref. No. = "INV_REF")
        InvCurrency := GetForeignCurrency();
        SetupBankAndWriteCAMTFile054_OnePmtOneInv(
          BankAccReconciliation, BankAccReconciliationLine, PmtCurrency, PmtAmount, InvCurrency, InvAmount, InvDbtrName, InvRefTxt);

        // [WHEN] Import bank statement
        BindSubscription(ImportCAMTBankAccRecLine);
        LibraryLowerPermissions.SetBanking();
        BankAccReconciliation.ImportBankStatement();
        UnbindSubscription(ImportCAMTBankAccRecLine);

        // [THEN] One bank reconciliation line has been created with following details:
        // [THEN] "Amount" = 1234.56, "Related-Party Name" = "DBTR_NAME", "Additional Transaction Info" = "INV_REF"
        VerifyImportCAMT054_OnePayment(BankAccReconciliationLine, PmtCurrency, PmtAmount, InvDbtrName, InvRefTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ImportCAMT_054_OnePmtTwoInv()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        ImportCAMTBankAccRecLine: Codeunit "Import CAMT Bank AccRecLine";
        PmtCurrency: Text;
        PmtAmount: Decimal;
        InvCurrency: array[2] of Text;
        InvAmount: array[2] of Decimal;
        InvDbtrName: array[2] of Text;
        InvRefTxt: array[2] of Text;
    begin
        // [FEATURE] [CAMT 054]
        // [SCENARIO 225918] Import CAMT 054.001.04 in case of one payment with two invoices (identical amounts and currencies)
        Initialize();
        PrepareValuesForImportCAMT054_OnePmtTwoInv(PmtCurrency, PmtAmount, InvCurrency, InvAmount, InvDbtrName, InvRefTxt);

        // [GIVEN] CAMT 054.001.04 xml: one payment (Amount = 1234.56 CHF) with two invoices:
        // [GIVEN] Invoice1: Amount = 617.29 CHF, Debitor Name = "DBTR_NAME1", Ref. No. = "INV_REF1"
        // [GIVEN] Invoice2: Amount = 617.27 CHF, Debitor Name = "DBTR_NAME2", Ref. No. = "INV_REF2"
        SetupBankAndWriteCAMTFile054_OnePmtTwoInv(
          BankAccReconciliation, BankAccReconciliationLine, PmtCurrency, PmtAmount, InvCurrency, InvAmount, InvDbtrName, InvRefTxt);

        // [WHEN] Import bank statement
        BindSubscription(ImportCAMTBankAccRecLine);
        LibraryLowerPermissions.SetBanking();
        BankAccReconciliation.ImportBankStatement();
        UnbindSubscription(ImportCAMTBankAccRecLine);

        // [THEN] Two bank reconciliation lines have been created with following details:
        // [THEN] line1: "Amount" = 617.29, "Related-Party Name" = "DBTR_NAME1", "Additional Transaction Info" = "INV_REF_1"
        // [THEN] line2: "Amount" = 617.27, "Related-Party Name" = "DBTR_NAME2", "Additional Transaction Info" = "INV_REF_2"
        VerifyImportCAMT054_TwoPayments(BankAccReconciliationLine, InvCurrency, InvAmount, InvDbtrName, InvRefTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ImportCAMT_054_OnePmtTwoInv_Diff_Amt_Higher()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        ImportCAMTBankAccRecLine: Codeunit "Import CAMT Bank AccRecLine";
        PmtCurrency: Text;
        PmtAmount: Decimal;
        InvCurrency: array[2] of Text;
        InvAmount: array[2] of Decimal;
        InvDbtrName: array[2] of Text;
        InvRefTxt: array[2] of Text;
    begin
        // [FEATURE] [CAMT 054]
        // [SCENARIO 225918] Import CAMT 054.001.04 in case of one payment with two invoices (identical currencies, total invoices amount is higher than payment's)
        Initialize();
        PrepareValuesForImportCAMT054_OnePmtTwoInv(PmtCurrency, PmtAmount, InvCurrency, InvAmount, InvDbtrName, InvRefTxt);

        // [GIVEN] CAMT 054.001.04 xml: one payment (Amount = 1234.56 CHF) with two invoices:
        // [GIVEN] Invoice1: Amount = 617.29 CHF, Debitor Name = "DBTR_NAME1", Ref. No. = "INV_REF1"
        // [GIVEN] Invoice2: Amount = 617.28 CHF, Debitor Name = "DBTR_NAME2", Ref. No. = "INV_REF2"
        InvAmount[2] += 0.01;
        SetupBankAndWriteCAMTFile054_OnePmtTwoInv(
          BankAccReconciliation, BankAccReconciliationLine, PmtCurrency, PmtAmount, InvCurrency, InvAmount, InvDbtrName, InvRefTxt);

        // [WHEN] Import bank statement
        BindSubscription(ImportCAMTBankAccRecLine);
        LibraryLowerPermissions.SetBanking();
        BankAccReconciliation.ImportBankStatement();
        UnbindSubscription(ImportCAMTBankAccRecLine);

        // [THEN] One bank reconciliation line has been created with following details:
        // [THEN] "Amount" = 1234.56, "Related-Party Name" = "DBTR_NAME1 DBTR_NAME2", "Additional Transaction Info" = "INV_REF1 INV_REF2"
        VerifyImportCAMT054_OnePaymentWithTwoDetails(BankAccReconciliationLine, PmtCurrency, PmtAmount, InvDbtrName, InvRefTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ImportCAMT_054_OnePmtTwoInv_Diff_Amt_Lower()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        ImportCAMTBankAccRecLine: Codeunit "Import CAMT Bank AccRecLine";
        PmtCurrency: Text;
        PmtAmount: Decimal;
        InvCurrency: array[2] of Text;
        InvAmount: array[2] of Decimal;
        InvDbtrName: array[2] of Text;
        InvRefTxt: array[2] of Text;
    begin
        // [FEATURE] [CAMT 054]
        // [SCENARIO 225918] Import CAMT 054.001.04 in case of one payment with two invoices (identical currencies, total invoices amount is lower than payment's)
        Initialize();
        PrepareValuesForImportCAMT054_OnePmtTwoInv(PmtCurrency, PmtAmount, InvCurrency, InvAmount, InvDbtrName, InvRefTxt);

        // [GIVEN] CAMT 054.001.04 xml: one payment (Amount = 1234.56 CHF) with two invoices:
        // [GIVEN] Invoice1: Amount = 617.29 CHF, Debitor Name = "DBTR_NAME1", Ref. No. = "INV_REF1"
        // [GIVEN] Invoice2: Amount = 617.26 CHF, Debitor Name = "DBTR_NAME2", Ref. No. = "INV_REF2"
        InvAmount[2] -= 0.01;
        SetupBankAndWriteCAMTFile054_OnePmtTwoInv(
          BankAccReconciliation, BankAccReconciliationLine, PmtCurrency, PmtAmount, InvCurrency, InvAmount, InvDbtrName, InvRefTxt);

        // [WHEN] Import bank statement
        BindSubscription(ImportCAMTBankAccRecLine);
        LibraryLowerPermissions.SetBanking();
        BankAccReconciliation.ImportBankStatement();
        UnbindSubscription(ImportCAMTBankAccRecLine);

        // [THEN] One bank reconciliation line has been created with following details:
        // [THEN] "Amount" = 1234.56, "Related-Party Name" = "DBTR_NAME1 DBTR_NAME2", "Additional Transaction Info" = "INV_REF1 INV_REF2"
        VerifyImportCAMT054_OnePaymentWithTwoDetails(BankAccReconciliationLine, PmtCurrency, PmtAmount, InvDbtrName, InvRefTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ImportCAMT_054_OnePmtTwoInv_Diff_Currency()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        ImportCAMTBankAccRecLine: Codeunit "Import CAMT Bank AccRecLine";
        PmtCurrency: Text;
        PmtAmount: Decimal;
        InvCurrency: array[2] of Text;
        InvAmount: array[2] of Decimal;
        InvDbtrName: array[2] of Text;
        InvRefTxt: array[2] of Text;
    begin
        // [FEATURE] [CAMT 054]
        // [SCENARIO 225918] Import CAMT 054.001.04 in case of one payment with two invoices (identical amounts, different currencies)
        Initialize();
        PrepareValuesForImportCAMT054_OnePmtTwoInv(PmtCurrency, PmtAmount, InvCurrency, InvAmount, InvDbtrName, InvRefTxt);

        // [GIVEN] CAMT 054.001.04 xml: one payment (Amount = 1234.56 CHF) with two invoices:
        // [GIVEN] Invoice1: Amount = 617.29 CHF, Debitor Name = "DBTR_NAME1", Ref. No. = "INV_REF1"
        // [GIVEN] Invoice2: Amount = 617.27 USD, Debitor Name = "DBTR_NAME2", Ref. No. = "INV_REF2"
        InvCurrency[2] := GetForeignCurrency();
        SetupBankAndWriteCAMTFile054_OnePmtTwoInv(
          BankAccReconciliation, BankAccReconciliationLine, PmtCurrency, PmtAmount, InvCurrency, InvAmount, InvDbtrName, InvRefTxt);

        // [WHEN] Import bank statement
        BindSubscription(ImportCAMTBankAccRecLine);
        LibraryLowerPermissions.SetBanking();
        BankAccReconciliation.ImportBankStatement();
        UnbindSubscription(ImportCAMTBankAccRecLine);

        // [THEN] One bank reconciliation line has been created with following details:
        // [THEN] "Amount" = 1234.56, "Related-Party Name" = "DBTR_NAME1 DBTR_NAME2", "Additional Transaction Info" = "INV_REF1 INV_REF2"
        VerifyImportCAMT054_OnePaymentWithTwoDetails(BankAccReconciliationLine, PmtCurrency, PmtAmount, InvDbtrName, InvRefTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ImportCAMT_054_TwoPmtOneInv()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        ImportCAMTBankAccRecLine: Codeunit "Import CAMT Bank AccRecLine";
        PmtCurrency: array[2] of Text;
        PmtAmount: array[2] of Decimal;
        InvCurrency: array[2] of Text;
        InvAmount: array[2] of Decimal;
        InvDbtrName: array[2] of Text;
        InvRefTxt: array[2] of Text;
    begin
        // [FEATURE] [CAMT 054]
        // [SCENARIO 225918] Import CAMT 054.001.04 in case of two payments each having one invoice (identical amounts and currencies within one payment)
        Initialize();
        PrepareValuesForImportCAMT054_TwoPmtOneInv(PmtCurrency, PmtAmount, InvCurrency, InvAmount, InvDbtrName, InvRefTxt);

        // [GIVEN] CAMT 054.001.04 xml: two payments:
        // [GIVEN] payment1: Amount = 1234.56 CHF with one invoice (Amount = 1234.56 CHF, Debitor Name = "CHF_DBTR_NAME", Ref. No. = "CHF_INV_REF")
        // [GIVEN] payment2: Amount = 3456.78 EUR with one invoice (Amount = 3456.78 EUR, Debitor Name = "EUR_DBTR_NAME", Ref. No. = "EUR_INV_REF")
        SetupBankAndWriteCAMTFile054_TwoPmtOneInv(
          BankAccReconciliation, BankAccReconciliationLine, PmtCurrency, PmtAmount, InvCurrency, InvAmount, InvDbtrName, InvRefTxt);

        // [WHEN] Import bank statement
        BindSubscription(ImportCAMTBankAccRecLine);
        LibraryLowerPermissions.SetBanking();
        BankAccReconciliation.ImportBankStatement();
        UnbindSubscription(ImportCAMTBankAccRecLine);

        // [THEN] Two bank reconciliation lines have been created with following details:
        // [THEN] line1: "Amount" = 1234.56, "Related-Party Name" = "CHF_DBTR_NAME", "Additional Transaction Info" = "CHF_INV_REF"
        // [THEN] line2: "Amount" = 3456.78, "Related-Party Name" = "EUR_DBTR_NAME", "Additional Transaction Info" = "EUR_INV_REF"
        VerifyImportCAMT054_TwoPayments(BankAccReconciliationLine, PmtCurrency, PmtAmount, InvDbtrName, InvRefTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ImportCAMT_054_TwoPmtOneInv_Diff_Amt1_Higher()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        ImportCAMTBankAccRecLine: Codeunit "Import CAMT Bank AccRecLine";
        PmtCurrency: array[2] of Text;
        PmtAmount: array[2] of Decimal;
        InvCurrency: array[2] of Text;
        InvAmount: array[2] of Decimal;
        InvDbtrName: array[2] of Text;
        InvRefTxt: array[2] of Text;
    begin
        // [FEATURE] [CAMT 054]
        // [SCENARIO 225918] Import CAMT 054.001.04 in case of two payments each having one invoice (identical currencies within one payment, invoice amount is higher tha payment's within first payment)
        Initialize();
        PrepareValuesForImportCAMT054_TwoPmtOneInv(PmtCurrency, PmtAmount, InvCurrency, InvAmount, InvDbtrName, InvRefTxt);

        // [GIVEN] CAMT 054.001.04 xml: two payments:
        // [GIVEN] payment1: Amount = 1234.56 CHF with one invoice (Amount = 1234.56 CHF, Debitor Name = "CHF_DBTR_NAME", Ref. No. = "CHF_INV_REF")
        // [GIVEN] payment2: Amount = 3456.78 EUR with one invoice (Amount = 2345.68 EUR, Debitor Name = "EUR_DBTR_NAME", Ref. No. = "EUR_INV_REF")
        InvAmount[1] += 0.01;
        SetupBankAndWriteCAMTFile054_TwoPmtOneInv(
          BankAccReconciliation, BankAccReconciliationLine, PmtCurrency, PmtAmount, InvCurrency, InvAmount, InvDbtrName, InvRefTxt);

        // [WHEN] Import bank statement
        BindSubscription(ImportCAMTBankAccRecLine);
        LibraryLowerPermissions.SetBanking();
        BankAccReconciliation.ImportBankStatement();
        UnbindSubscription(ImportCAMTBankAccRecLine);

        // [THEN] Two bank reconciliation lines have been created with following details:
        // [THEN] line1: "Amount" = 1234.56, "Related-Party Name" = "CHF_DBTR_NAME", "Additional Transaction Info" = "CHF_INV_REF"
        // [THEN] line2: "Amount" = 3456.78, "Related-Party Name" = "EUR_DBTR_NAME", "Additional Transaction Info" = "EUR_INV_REF"
        VerifyImportCAMT054_TwoPayments(BankAccReconciliationLine, PmtCurrency, PmtAmount, InvDbtrName, InvRefTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ImportCAMT_054_TwoPmtOneInv_Diff_Amt1_Lower()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        ImportCAMTBankAccRecLine: Codeunit "Import CAMT Bank AccRecLine";
        PmtCurrency: array[2] of Text;
        PmtAmount: array[2] of Decimal;
        InvCurrency: array[2] of Text;
        InvAmount: array[2] of Decimal;
        InvDbtrName: array[2] of Text;
        InvRefTxt: array[2] of Text;
    begin
        // [FEATURE] [CAMT 054]
        // [SCENARIO 225918] Import CAMT 054.001.04 in case of two payments each having one invoice (identical currencies within one payment, invoice amount is lower tha payment's within first payment)
        Initialize();
        PrepareValuesForImportCAMT054_TwoPmtOneInv(PmtCurrency, PmtAmount, InvCurrency, InvAmount, InvDbtrName, InvRefTxt);

        // [GIVEN] CAMT 054.001.04 xml: two payments:
        // [GIVEN] payment1: Amount = 1234.56 CHF with one invoice (Amount = 1234.56 CHF, Debitor Name = "CHF_DBTR_NAME", Ref. No. = "CHF_INV_REF")
        // [GIVEN] payment2: Amount = 3456.78 EUR with one invoice (Amount = 2345.66 EUR, Debitor Name = "EUR_DBTR_NAME", Ref. No. = "EUR_INV_REF")
        InvAmount[1] -= 0.01;
        SetupBankAndWriteCAMTFile054_TwoPmtOneInv(
          BankAccReconciliation, BankAccReconciliationLine, PmtCurrency, PmtAmount, InvCurrency, InvAmount, InvDbtrName, InvRefTxt);

        // [WHEN] Import bank statement
        BindSubscription(ImportCAMTBankAccRecLine);
        LibraryLowerPermissions.SetBanking();
        BankAccReconciliation.ImportBankStatement();
        UnbindSubscription(ImportCAMTBankAccRecLine);

        // [THEN] Two bank reconciliation lines have been created with following details:
        // [THEN] line1: "Amount" = 1234.56, "Related-Party Name" = "CHF_DBTR_NAME", "Additional Transaction Info" = "CHF_INV_REF"
        // [THEN] line2: "Amount" = 3456.78, "Related-Party Name" = "EUR_DBTR_NAME", "Additional Transaction Info" = "EUR_INV_REF"
        VerifyImportCAMT054_TwoPayments(BankAccReconciliationLine, PmtCurrency, PmtAmount, InvDbtrName, InvRefTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ImportCAMT_054_TwoPmtOneInv_Diff_Amt2_Higher()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        ImportCAMTBankAccRecLine: Codeunit "Import CAMT Bank AccRecLine";
        PmtCurrency: array[2] of Text;
        PmtAmount: array[2] of Decimal;
        InvCurrency: array[2] of Text;
        InvAmount: array[2] of Decimal;
        InvDbtrName: array[2] of Text;
        InvRefTxt: array[2] of Text;
    begin
        // [FEATURE] [CAMT 054]
        // [SCENARIO 225918] Import CAMT 054.001.04 in case of two payments each having one invoice (identical currencies within one payment, invoice amount is higher tha payment's within second payment)
        Initialize();
        PrepareValuesForImportCAMT054_TwoPmtOneInv(PmtCurrency, PmtAmount, InvCurrency, InvAmount, InvDbtrName, InvRefTxt);

        // [GIVEN] CAMT 054.001.04 xml: two payments:
        // [GIVEN] payment1: Amount = 1234.56 CHF with one invoice (Amount = 1234.56 CHF, Debitor Name = "CHF_DBTR_NAME", Ref. No. = "CHF_INV_REF")
        // [GIVEN] payment2: Amount = 3456.78 EUR with one invoice (Amount = 2345.68 EUR, Debitor Name = "EUR_DBTR_NAME", Ref. No. = "EUR_INV_REF")
        InvAmount[2] += 0.01;
        SetupBankAndWriteCAMTFile054_TwoPmtOneInv(
          BankAccReconciliation, BankAccReconciliationLine, PmtCurrency, PmtAmount, InvCurrency, InvAmount, InvDbtrName, InvRefTxt);

        // [WHEN] Import bank statement
        BindSubscription(ImportCAMTBankAccRecLine);
        LibraryLowerPermissions.SetBanking();
        BankAccReconciliation.ImportBankStatement();
        UnbindSubscription(ImportCAMTBankAccRecLine);

        // [THEN] Two bank reconciliation lines have been created with following details:
        // [THEN] line1: "Amount" = 1234.56, "Related-Party Name" = "CHF_DBTR_NAME", "Additional Transaction Info" = "CHF_INV_REF"
        // [THEN] line2: "Amount" = 3456.78, "Related-Party Name" = "EUR_DBTR_NAME", "Additional Transaction Info" = "EUR_INV_REF"
        VerifyImportCAMT054_TwoPayments(BankAccReconciliationLine, PmtCurrency, PmtAmount, InvDbtrName, InvRefTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ImportCAMT_054_TwoPmtOneInv_Diff_Amt2_Lower()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        ImportCAMTBankAccRecLine: Codeunit "Import CAMT Bank AccRecLine";
        PmtCurrency: array[2] of Text;
        PmtAmount: array[2] of Decimal;
        InvCurrency: array[2] of Text;
        InvAmount: array[2] of Decimal;
        InvDbtrName: array[2] of Text;
        InvRefTxt: array[2] of Text;
    begin
        // [FEATURE] [CAMT 054]
        // [SCENARIO 225918] Import CAMT 054.001.04 in case of two payments each having one invoice (identical currencies within one payment, invoice amount is lower tha payment's within second payment)
        Initialize();
        PrepareValuesForImportCAMT054_TwoPmtOneInv(PmtCurrency, PmtAmount, InvCurrency, InvAmount, InvDbtrName, InvRefTxt);

        // [GIVEN] CAMT 054.001.04 xml: two payments:
        // [GIVEN] payment1: Amount = 1234.56 CHF with one invoice (Amount = 1234.56 CHF, Debitor Name = "CHF_DBTR_NAME", Ref. No. = "CHF_INV_REF")
        // [GIVEN] payment2: Amount = 3456.78 EUR with one invoice (Amount = 2345.66 EUR, Debitor Name = "EUR_DBTR_NAME", Ref. No. = "EUR_INV_REF")
        InvAmount[2] -= 0.01;
        SetupBankAndWriteCAMTFile054_TwoPmtOneInv(
          BankAccReconciliation, BankAccReconciliationLine, PmtCurrency, PmtAmount, InvCurrency, InvAmount, InvDbtrName, InvRefTxt);

        // [WHEN] Import bank statement
        BindSubscription(ImportCAMTBankAccRecLine);
        LibraryLowerPermissions.SetBanking();
        BankAccReconciliation.ImportBankStatement();
        UnbindSubscription(ImportCAMTBankAccRecLine);

        // [THEN] Two bank reconciliation lines have been created with following details:
        // [THEN] line1: "Amount" = 1234.56, "Related-Party Name" = "CHF_DBTR_NAME", "Additional Transaction Info" = "CHF_INV_REF"
        // [THEN] line2: "Amount" = 3456.78, "Related-Party Name" = "EUR_DBTR_NAME", "Additional Transaction Info" = "EUR_INV_REF"
        VerifyImportCAMT054_TwoPayments(BankAccReconciliationLine, PmtCurrency, PmtAmount, InvDbtrName, InvRefTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ImportCAMT_054_TwoPmtOneInv_Diff_Currency1()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        ImportCAMTBankAccRecLine: Codeunit "Import CAMT Bank AccRecLine";
        PmtCurrency: array[2] of Text;
        PmtAmount: array[2] of Decimal;
        InvCurrency: array[2] of Text;
        InvAmount: array[2] of Decimal;
        InvDbtrName: array[2] of Text;
        InvRefTxt: array[2] of Text;
    begin
        // [FEATURE] [CAMT 054]
        // [SCENARIO 225918] Import CAMT 054.001.04 in case of two payments each having one invoice (identical amounts within one payment, different currencies within first payment)
        Initialize();
        PrepareValuesForImportCAMT054_TwoPmtOneInv(PmtCurrency, PmtAmount, InvCurrency, InvAmount, InvDbtrName, InvRefTxt);

        // [GIVEN] CAMT 054.001.04 xml: two payments:
        // [GIVEN] payment1: Amount = 1234.56 CHF with one invoice (Amount = 1234.56 USD, Debitor Name = "CHF_DBTR_NAME", Ref. No. = "CHF_INV_REF")
        // [GIVEN] payment2: Amount = 3456.78 EUR with one invoice (Amount = 3456.78 EUR, Debitor Name = "EUR_DBTR_NAME", Ref. No. = "EUR_INV_REF")
        InvCurrency[1] := GetForeignCurrency();
        SetupBankAndWriteCAMTFile054_TwoPmtOneInv(
          BankAccReconciliation, BankAccReconciliationLine, PmtCurrency, PmtAmount, InvCurrency, InvAmount, InvDbtrName, InvRefTxt);

        // [WHEN] Import bank statement
        BindSubscription(ImportCAMTBankAccRecLine);
        LibraryLowerPermissions.SetBanking();
        BankAccReconciliation.ImportBankStatement();
        UnbindSubscription(ImportCAMTBankAccRecLine);

        // [THEN] Two bank reconciliation lines have been created with following details:
        // [THEN] line1: "Amount" = 1234.56, "Related-Party Name" = "CHF_DBTR_NAME", "Additional Transaction Info" = "CHF_INV_REF"
        // [THEN] line2: "Amount" = 3456.78, "Related-Party Name" = "EUR_DBTR_NAME", "Additional Transaction Info" = "EUR_INV_REF"
        VerifyImportCAMT054_TwoPayments(BankAccReconciliationLine, PmtCurrency, PmtAmount, InvDbtrName, InvRefTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ImportCAMT_054_TwoPmtOneInv_Diff_Currency2()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        ImportCAMTBankAccRecLine: Codeunit "Import CAMT Bank AccRecLine";
        PmtCurrency: array[2] of Text;
        PmtAmount: array[2] of Decimal;
        InvCurrency: array[2] of Text;
        InvAmount: array[2] of Decimal;
        InvDbtrName: array[2] of Text;
        InvRefTxt: array[2] of Text;
    begin
        // [FEATURE] [CAMT 054]
        // [SCENARIO 225918] Import CAMT 054.001.04 in case of two payments each having one invoice (identical amounts within one payment, different currencies within second payment)
        Initialize();
        PrepareValuesForImportCAMT054_TwoPmtOneInv(PmtCurrency, PmtAmount, InvCurrency, InvAmount, InvDbtrName, InvRefTxt);

        // [GIVEN] CAMT 054.001.04 xml: two payments:
        // [GIVEN] payment1: Amount = 1234.56 CHF with one invoice (Amount = 1234.56 CHF, Debitor Name = "CHF_DBTR_NAME", Ref. No. = "CHF_INV_REF")
        // [GIVEN] payment2: Amount = 3456.78 EUR with one invoice (Amount = 3456.78 USD, Debitor Name = "EUR_DBTR_NAME", Ref. No. = "EUR_INV_REF")
        InvCurrency[2] := GetForeignCurrency();
        SetupBankAndWriteCAMTFile054_TwoPmtOneInv(
          BankAccReconciliation, BankAccReconciliationLine, PmtCurrency, PmtAmount, InvCurrency, InvAmount, InvDbtrName, InvRefTxt);

        // [WHEN] Import bank statement
        BindSubscription(ImportCAMTBankAccRecLine);
        LibraryLowerPermissions.SetBanking();
        BankAccReconciliation.ImportBankStatement();
        UnbindSubscription(ImportCAMTBankAccRecLine);

        // [THEN] Two bank reconciliation lines have been created with following details:
        // [THEN] line1: "Amount" = 1234.56, "Related-Party Name" = "CHF_DBTR_NAME", "Additional Transaction Info" = "CHF_INV_REF"
        // [THEN] line2: "Amount" = 3456.78, "Related-Party Name" = "EUR_DBTR_NAME", "Additional Transaction Info" = "EUR_INV_REF"
        VerifyImportCAMT054_TwoPayments(BankAccReconciliationLine, PmtCurrency, PmtAmount, InvDbtrName, InvRefTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ImportCAMT_054_TwoPmtTwoInv()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        ImportCAMTBankAccRecLine: Codeunit "Import CAMT Bank AccRecLine";
        PmtCurrency: array[2] of Text;
        PmtAmount: array[2] of Decimal;
        InvCurrency: array[4] of Text;
        InvAmount: array[4] of Decimal;
        InvDbtrName: array[4] of Text;
        InvRefTxt: array[4] of Text;
    begin
        // [FEATURE] [CAMT 054]
        // [SCENARIO 225918] Import CAMT 054.001.04 in case of two payments each having two invoices (identical amounts and currencies within one payment)
        Initialize();
        PrepareValuesForImportCAMT054_TwoPmtTwoInv(PmtCurrency, PmtAmount, InvCurrency, InvAmount, InvDbtrName, InvRefTxt);

        // [GIVEN] CAMT 054.001.04 xml: two payments:
        // [GIVEN] payment1: Amount = 1234.56 CHF with two invoices:
        // [GIVEN] Invoice1-1: Amount = 617.29 CHF, Debitor Name = "CHF_DBTR_NAME1", Ref. No. = "CHF_INV_REF1"
        // [GIVEN] Invoice1-2: Amount = 617.27 CHF, Debitor Name = "CHF_DBTR_NAME2", Ref. No. = "CHF_INV_REF2"
        // [GIVEN] payment2: Amount = 3456.78 EUR with two invoices:
        // [GIVEN] Invoice2-1: Amount = 1728.40 EUR, Debitor Name = "EUR_DBTR_NAME1", Ref. No. = "EUR_INV_REF1"
        // [GIVEN] Invoice2-2: Amount = 1728.38 EUR, Debitor Name = "EUR_DBTR_NAME2", Ref. No. = "EUR_INV_REF2"
        SetupBankAndWriteCAMTFile054_TwoPmtTwoInv(
          BankAccReconciliation, BankAccReconciliationLine, PmtCurrency, PmtAmount, InvCurrency, InvAmount, InvDbtrName, InvRefTxt);

        // [WHEN] Import bank statement
        BindSubscription(ImportCAMTBankAccRecLine);
        LibraryLowerPermissions.SetBanking();
        BankAccReconciliation.ImportBankStatement();
        UnbindSubscription(ImportCAMTBankAccRecLine);

        // [THEN] Four bank reconciliation lines have been created with following details:
        // [THEN] line1: "Amount" = 617.29, "Related-Party Name" = "CHF_DBTR_NAME1", "Additional Transaction Info" = "CHF_INV_REF1"
        // [THEN] line2: "Amount" = 617.27, "Related-Party Name" = "CHF_DBTR_NAME2", "Additional Transaction Info" = "CHF_INV_REF2"
        // [THEN] line3: "Amount" = 1728.40, "Related-Party Name" = "EUR_DBTR_NAME1", "Additional Transaction Info" = "EUR_INV_REF1"
        // [THEN] line4: "Amount" = 1728.38, "Related-Party Name" = "EUR_DBTR_NAME2", "Additional Transaction Info" = "EUR_INV_REF2"
        VerifyImportCAMT054_FourPayments(BankAccReconciliationLine, InvCurrency, InvAmount, InvDbtrName, InvRefTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ImportCAMT_054_TwoPmtTwoInv_Diff_Amt1_Higher()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        ImportCAMTBankAccRecLine: Codeunit "Import CAMT Bank AccRecLine";
        PmtCurrency: array[2] of Text;
        PmtAmount: array[2] of Decimal;
        InvCurrency: array[4] of Text;
        InvAmount: array[4] of Decimal;
        InvDbtrName: array[4] of Text;
        InvRefTxt: array[4] of Text;
    begin
        // [FEATURE] [CAMT 054]
        // [SCENARIO 225918] Import CAMT 054.001.04 in case of two payments each having two invoices (identical currencies, invoices amount is higher than first payment)
        Initialize();
        PrepareValuesForImportCAMT054_TwoPmtTwoInv(PmtCurrency, PmtAmount, InvCurrency, InvAmount, InvDbtrName, InvRefTxt);

        // [GIVEN] CAMT 054.001.04 xml: two payments:
        // [GIVEN] payment1: Amount = 1234.56 CHF with two invoices:
        // [GIVEN] Invoice1-1: Amount = 617.29 CHF, Debitor Name = "CHF_DBTR_NAME1", Ref. No. = "CHF_INV_REF1"
        // [GIVEN] Invoice1-2: Amount = 617.28 CHF, Debitor Name = "CHF_DBTR_NAME2", Ref. No. = "CHF_INV_REF2"
        // [GIVEN] payment2: Amount = 3456.78 EUR with two invoices:
        // [GIVEN] Invoice2-1: Amount = 1728.40 EUR, Debitor Name = "EUR_DBTR_NAME1", Ref. No. = "EUR_INV_REF1"
        // [GIVEN] Invoice2-2: Amount = 1728.38 EUR, Debitor Name = "EUR_DBTR_NAME2", Ref. No. = "EUR_INV_REF2"
        InvAmount[2] += 0.01;
        SetupBankAndWriteCAMTFile054_TwoPmtTwoInv(
          BankAccReconciliation, BankAccReconciliationLine, PmtCurrency, PmtAmount, InvCurrency, InvAmount, InvDbtrName, InvRefTxt);

        // [WHEN] Import bank statement
        BindSubscription(ImportCAMTBankAccRecLine);
        LibraryLowerPermissions.SetBanking();
        BankAccReconciliation.ImportBankStatement();
        UnbindSubscription(ImportCAMTBankAccRecLine);

        // [THEN] Three bank reconciliation lines have been created with following details:
        // [THEN] line1: "Amount" = 1234.56, "Related-Party Name" = "CHF_DBTR_NAME1 CHF_DBTR_NAME2", "Additional Transaction Info" = "CHF_INV_REF1 CHF_INV_REF2"
        // [THEN] line2: "Amount" = 1728.40, "Related-Party Name" = "EUR_DBTR_NAME1", "Additional Transaction Info" = "EUR_INV_REF1"
        // [THEN] line3: "Amount" = 1728.38, "Related-Party Name" = "EUR_DBTR_NAME2", "Additional Transaction Info" = "EUR_INV_REF2"
        VerifyImportCAMT054_OnePmtWithTwoDtlsAndTwoMorePmts(
          BankAccReconciliationLine, PmtCurrency, PmtAmount, InvCurrency, InvAmount, InvDbtrName, InvRefTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ImportCAMT_054_TwoPmtTwoInv_Diff_Amt1_Lower()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        ImportCAMTBankAccRecLine: Codeunit "Import CAMT Bank AccRecLine";
        PmtCurrency: array[2] of Text;
        PmtAmount: array[2] of Decimal;
        InvCurrency: array[4] of Text;
        InvAmount: array[4] of Decimal;
        InvDbtrName: array[4] of Text;
        InvRefTxt: array[4] of Text;
    begin
        // [FEATURE] [CAMT 054]
        // [SCENARIO 225918] Import CAMT 054.001.04 in case of two payments each having two invoices (identical currencies, invoices amount is lower than first payment)
        Initialize();
        PrepareValuesForImportCAMT054_TwoPmtTwoInv(PmtCurrency, PmtAmount, InvCurrency, InvAmount, InvDbtrName, InvRefTxt);

        // [GIVEN] CAMT 054.001.04 xml: two payments:
        // [GIVEN] payment1: Amount = 1234.56 CHF with two invoices:
        // [GIVEN] Invoice1-1: Amount = 617.29 CHF, Debitor Name = "CHF_DBTR_NAME1", Ref. No. = "CHF_INV_REF1"
        // [GIVEN] Invoice1-2: Amount = 617.26 CHF, Debitor Name = "CHF_DBTR_NAME2", Ref. No. = "CHF_INV_REF2"
        // [GIVEN] payment2: Amount = 3456.78 EUR with two invoices:
        // [GIVEN] Invoice2-1: Amount = 1728.40 EUR, Debitor Name = "EUR_DBTR_NAME1", Ref. No. = "EUR_INV_REF1"
        // [GIVEN] Invoice2-2: Amount = 1728.38 EUR, Debitor Name = "EUR_DBTR_NAME2", Ref. No. = "EUR_INV_REF2"
        InvAmount[2] -= 0.01;
        SetupBankAndWriteCAMTFile054_TwoPmtTwoInv(
          BankAccReconciliation, BankAccReconciliationLine, PmtCurrency, PmtAmount, InvCurrency, InvAmount, InvDbtrName, InvRefTxt);

        // [WHEN] Import bank statement
        BindSubscription(ImportCAMTBankAccRecLine);
        LibraryLowerPermissions.SetBanking();
        BankAccReconciliation.ImportBankStatement();
        UnbindSubscription(ImportCAMTBankAccRecLine);

        // [THEN] Three bank reconciliation lines have been created with following details:
        // [THEN] line1: "Amount" = 1234.56, "Related-Party Name" = "CHF_DBTR_NAME1 CHF_DBTR_NAME2", "Additional Transaction Info" = "CHF_INV_REF1 CHF_INV_REF2"
        // [THEN] line2: "Amount" = 1728.40, "Related-Party Name" = "EUR_DBTR_NAME1", "Additional Transaction Info" = "EUR_INV_REF1"
        // [THEN] line3: "Amount" = 1728.38, "Related-Party Name" = "EUR_DBTR_NAME2", "Additional Transaction Info" = "EUR_INV_REF2"
        VerifyImportCAMT054_OnePmtWithTwoDtlsAndTwoMorePmts(
          BankAccReconciliationLine, PmtCurrency, PmtAmount, InvCurrency, InvAmount, InvDbtrName, InvRefTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ImportCAMT_054_TwoPmtTwoInv_Diff_Amt2_Higher()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        ImportCAMTBankAccRecLine: Codeunit "Import CAMT Bank AccRecLine";
        PmtCurrency: array[2] of Text;
        PmtAmount: array[2] of Decimal;
        InvCurrency: array[4] of Text;
        InvAmount: array[4] of Decimal;
        InvDbtrName: array[4] of Text;
        InvRefTxt: array[4] of Text;
    begin
        // [FEATURE] [CAMT 054]
        // [SCENARIO 225918] Import CAMT 054.001.04 in case of two payments each having two invoices (identical currencies, invoices amount is higher than second payment)
        Initialize();
        PrepareValuesForImportCAMT054_TwoPmtTwoInv(PmtCurrency, PmtAmount, InvCurrency, InvAmount, InvDbtrName, InvRefTxt);

        // [GIVEN] CAMT 054.001.04 xml: two payments:
        // [GIVEN] payment1: Amount = 1234.56 CHF with two invoices:
        // [GIVEN] Invoice1-1: Amount = 617.29 CHF, Debitor Name = "CHF_DBTR_NAME1", Ref. No. = "CHF_INV_REF1"
        // [GIVEN] Invoice1-2: Amount = 617.27 CHF, Debitor Name = "CHF_DBTR_NAME2", Ref. No. = "CHF_INV_REF2"
        // [GIVEN] payment2: Amount = 3456.78 EUR with two invoices:
        // [GIVEN] Invoice2-1: Amount = 1728.40 EUR, Debitor Name = "EUR_DBTR_NAME1", Ref. No. = "EUR_INV_REF1"
        // [GIVEN] Invoice2-2: Amount = 1728.39 EUR, Debitor Name = "EUR_DBTR_NAME2", Ref. No. = "EUR_INV_REF2"
        InvAmount[4] += 0.01;
        SetupBankAndWriteCAMTFile054_TwoPmtTwoInv(
          BankAccReconciliation, BankAccReconciliationLine, PmtCurrency, PmtAmount, InvCurrency, InvAmount, InvDbtrName, InvRefTxt);

        // [WHEN] Import bank statement
        BindSubscription(ImportCAMTBankAccRecLine);
        LibraryLowerPermissions.SetBanking();
        BankAccReconciliation.ImportBankStatement();
        UnbindSubscription(ImportCAMTBankAccRecLine);

        // [THEN] Three bank reconciliation lines have been created with following details:
        // [THEN] line1: "Amount" = 617.29, "Related-Party Name" = "CHF_DBTR_NAME1", "Additional Transaction Info" = "CHF_INV_REF1"
        // [THEN] line2: "Amount" = 617.27, "Related-Party Name" = "CHF_DBTR_NAME2", "Additional Transaction Info" = "CHF_INV_REF2"
        // [THEN] line3: "Amount" = 3456.78, "Related-Party Name" = "EUR_DBTR_NAME1 EUR_DBTR_NAME2", "Additional Transaction Info" = "EUR_INV_REF1 EUR_INV_REF2"
        VerifyImportCAMT054_TwoPmtsAndPmtWithTwoDtls(
          BankAccReconciliationLine, PmtCurrency, PmtAmount, InvCurrency, InvAmount, InvDbtrName, InvRefTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ImportCAMT_054_TwoPmtTwoInv_Diff_Amt2_Lower()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        ImportCAMTBankAccRecLine: Codeunit "Import CAMT Bank AccRecLine";
        PmtCurrency: array[2] of Text;
        PmtAmount: array[2] of Decimal;
        InvCurrency: array[4] of Text;
        InvAmount: array[4] of Decimal;
        InvDbtrName: array[4] of Text;
        InvRefTxt: array[4] of Text;
    begin
        // [FEATURE] [CAMT 054]
        // [SCENARIO 225918] Import CAMT 054.001.04 in case of two payments each having two invoices (identical currencies, invoices amount is lower than second payment)
        Initialize();
        PrepareValuesForImportCAMT054_TwoPmtTwoInv(PmtCurrency, PmtAmount, InvCurrency, InvAmount, InvDbtrName, InvRefTxt);

        // [GIVEN] CAMT 054.001.04 xml: two payments:
        // [GIVEN] payment1: Amount = 1234.56 CHF with two invoices:
        // [GIVEN] Invoice1-1: Amount = 617.29 CHF, Debitor Name = "CHF_DBTR_NAME1", Ref. No. = "CHF_INV_REF1"
        // [GIVEN] Invoice1-2: Amount = 617.27 CHF, Debitor Name = "CHF_DBTR_NAME2", Ref. No. = "CHF_INV_REF2"
        // [GIVEN] payment2: Amount = 3456.78 EUR with two invoices:
        // [GIVEN] Invoice2-1: Amount = 1728.40 EUR, Debitor Name = "EUR_DBTR_NAME1", Ref. No. = "EUR_INV_REF1"
        // [GIVEN] Invoice2-2: Amount = 1728.37 EUR, Debitor Name = "EUR_DBTR_NAME2", Ref. No. = "EUR_INV_REF2"
        InvAmount[4] -= 0.01;
        SetupBankAndWriteCAMTFile054_TwoPmtTwoInv(
          BankAccReconciliation, BankAccReconciliationLine, PmtCurrency, PmtAmount, InvCurrency, InvAmount, InvDbtrName, InvRefTxt);

        // [WHEN] Import bank statement
        BindSubscription(ImportCAMTBankAccRecLine);
        LibraryLowerPermissions.SetBanking();
        BankAccReconciliation.ImportBankStatement();
        UnbindSubscription(ImportCAMTBankAccRecLine);

        // [THEN] Three bank reconciliation lines have been created with following details:
        // [THEN] line1: "Amount" = 617.29, "Related-Party Name" = "CHF_DBTR_NAME1", "Additional Transaction Info" = "CHF_INV_REF1"
        // [THEN] line2: "Amount" = 617.27, "Related-Party Name" = "CHF_DBTR_NAME2", "Additional Transaction Info" = "CHF_INV_REF2"
        // [THEN] line3: "Amount" = 3456.78, "Related-Party Name" = "EUR_DBTR_NAME1 EUR_DBTR_NAME2", "Additional Transaction Info" = "EUR_INV_REF1 EUR_INV_REF2"
        VerifyImportCAMT054_TwoPmtsAndPmtWithTwoDtls(
          BankAccReconciliationLine, PmtCurrency, PmtAmount, InvCurrency, InvAmount, InvDbtrName, InvRefTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ImportCAMT_054_TwoPmtTwoInv_Diff_Currency1()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        ImportCAMTBankAccRecLine: Codeunit "Import CAMT Bank AccRecLine";
        PmtCurrency: array[2] of Text;
        PmtAmount: array[2] of Decimal;
        InvCurrency: array[4] of Text;
        InvAmount: array[4] of Decimal;
        InvDbtrName: array[4] of Text;
        InvRefTxt: array[4] of Text;
    begin
        // [FEATURE] [CAMT 054]
        // [SCENARIO 225918] Import CAMT 054.001.04 in case of two payments each having two invoices (identical amounts within one payment, different currencies in first payment)
        Initialize();
        PrepareValuesForImportCAMT054_TwoPmtTwoInv(PmtCurrency, PmtAmount, InvCurrency, InvAmount, InvDbtrName, InvRefTxt);

        // [GIVEN] CAMT 054.001.04 xml: two payments:
        // [GIVEN] payment1: Amount = 1234.56 CHF with two invoices:
        // [GIVEN] Invoice1-1: Amount = 617.29 CHF, Debitor Name = "CHF_DBTR_NAME1", Ref. No. = "CHF_INV_REF1"
        // [GIVEN] Invoice1-2: Amount = 617.27 USD, Debitor Name = "CHF_DBTR_NAME2", Ref. No. = "CHF_INV_REF2"
        // [GIVEN] payment2: Amount = 3456.78 EUR with two invoices:
        // [GIVEN] Invoice2-1: Amount = 1728.40 EUR, Debitor Name = "EUR_DBTR_NAME1", Ref. No. = "EUR_INV_REF1"
        // [GIVEN] Invoice2-2: Amount = 1728.38 EUR, Debitor Name = "EUR_DBTR_NAME2", Ref. No. = "EUR_INV_REF2"
        InvCurrency[2] := GetForeignCurrency();
        SetupBankAndWriteCAMTFile054_TwoPmtTwoInv(
          BankAccReconciliation, BankAccReconciliationLine, PmtCurrency, PmtAmount, InvCurrency, InvAmount, InvDbtrName, InvRefTxt);

        // [WHEN] Import bank statement
        BindSubscription(ImportCAMTBankAccRecLine);
        LibraryLowerPermissions.SetBanking();
        BankAccReconciliation.ImportBankStatement();
        UnbindSubscription(ImportCAMTBankAccRecLine);

        // [THEN] Three bank reconciliation lines have been created with following details:
        // [THEN] line1: "Amount" = 1234.56, "Related-Party Name" = "CHF_DBTR_NAME1 CHF_DBTR_NAME2", "Additional Transaction Info" = "CHF_INV_REF1 CHF_INV_REF2"
        // [THEN] line2: "Amount" = 1728.40, "Related-Party Name" = "EUR_DBTR_NAME1", "Additional Transaction Info" = "EUR_INV_REF1"
        // [THEN] line3: "Amount" = 1728.38, "Related-Party Name" = "EUR_DBTR_NAME2", "Additional Transaction Info" = "EUR_INV_REF2"
        VerifyImportCAMT054_OnePmtWithTwoDtlsAndTwoMorePmts(
          BankAccReconciliationLine, PmtCurrency, PmtAmount, InvCurrency, InvAmount, InvDbtrName, InvRefTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ImportCAMT_054_TwoPmtTwoInv_Diff_Currency2()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        ImportCAMTBankAccRecLine: Codeunit "Import CAMT Bank AccRecLine";
        PmtCurrency: array[2] of Text;
        PmtAmount: array[2] of Decimal;
        InvCurrency: array[4] of Text;
        InvAmount: array[4] of Decimal;
        InvDbtrName: array[4] of Text;
        InvRefTxt: array[4] of Text;
    begin
        // [FEATURE] [CAMT 054]
        // [SCENARIO 225918] Import CAMT 054.001.04 in case of two payments each having two invoices (identical amounts within one payment, different currencies in second payment)
        Initialize();
        PrepareValuesForImportCAMT054_TwoPmtTwoInv(PmtCurrency, PmtAmount, InvCurrency, InvAmount, InvDbtrName, InvRefTxt);

        // [GIVEN] CAMT 054.001.04 xml: two payments:
        // [GIVEN] payment1: Amount = 1234.56 CHF with two invoices:
        // [GIVEN] Invoice1-1: Amount = 617.29 CHF, Debitor Name = "CHF_DBTR_NAME1", Ref. No. = "CHF_INV_REF1"
        // [GIVEN] Invoice1-2: Amount = 617.27 CHF, Debitor Name = "CHF_DBTR_NAME2", Ref. No. = "CHF_INV_REF2"
        // [GIVEN] payment2: Amount = 3456.78 EUR with two invoices:
        // [GIVEN] Invoice2-1: Amount = 1728.40 EUR, Debitor Name = "EUR_DBTR_NAME1", Ref. No. = "EUR_INV_REF1"
        // [GIVEN] Invoice2-2: Amount = 1728.38 USD, Debitor Name = "EUR_DBTR_NAME2", Ref. No. = "EUR_INV_REF2"
        InvCurrency[4] := GetForeignCurrency();
        SetupBankAndWriteCAMTFile054_TwoPmtTwoInv(
          BankAccReconciliation, BankAccReconciliationLine, PmtCurrency, PmtAmount, InvCurrency, InvAmount, InvDbtrName, InvRefTxt);

        // [WHEN] Import bank statement
        BindSubscription(ImportCAMTBankAccRecLine);
        LibraryLowerPermissions.SetBanking();
        BankAccReconciliation.ImportBankStatement();
        UnbindSubscription(ImportCAMTBankAccRecLine);

        // [THEN] Three bank reconciliation lines have been created with following details:
        // [THEN] line1: "Amount" = 617.29, "Related-Party Name" = "CHF_DBTR_NAME1", "Additional Transaction Info" = "CHF_INV_REF1"
        // [THEN] line2: "Amount" = 617.27, "Related-Party Name" = "CHF_DBTR_NAME2", "Additional Transaction Info" = "CHF_INV_REF2"
        // [THEN] line3: "Amount" = 3456.78, "Related-Party Name" = "EUR_DBTR_NAME1 EUR_DBTR_NAME2", "Additional Transaction Info" = "EUR_INV_REF1 EUR_INV_REF2"
        VerifyImportCAMT054_TwoPmtsAndPmtWithTwoDtls(
          BankAccReconciliationLine, PmtCurrency, PmtAmount, InvCurrency, InvAmount, InvDbtrName, InvRefTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ImportCAMT_054_OnePmtOneInv_ExtraSpacesBeforeTags()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        ImportCAMTBankAccRecLine: Codeunit "Import CAMT Bank AccRecLine";
        PmtCurrency: Text;
        PmtAmount: Decimal;
        InvCurrency: Text;
        InvAmount: Decimal;
        InvDbtrName: Text;
        InvRefTxt: Text;
    begin
        // [FEATURE] [CAMT 054]
        // [SCENARIO 275421] Import CAMT 054.001.04 in case of extra spaces before <BkToCstmrDbtCdtNtfctn> and <Ntfctn> tags.
        Initialize();
        PrepareValuesForImportCAMT054_OnePmtOneInv(PmtCurrency, PmtAmount, InvCurrency, InvAmount, InvDbtrName, InvRefTxt);

        // [GIVEN] CAMT 054.001.04 xml: <BkToCstmrDbtCdtNtfctn> and <Ntfctn> tags has indentation 3 and 6 spaces respectively; one payment with one invoice.
        SetupBankAndWriteCAMTFile054_OnePmtOneInv_ExtraSpaces(
          BankAccReconciliation, BankAccReconciliationLine, PmtCurrency, PmtAmount, InvCurrency, InvAmount, InvDbtrName, InvRefTxt);

        // [WHEN] Import bank statement
        BindSubscription(ImportCAMTBankAccRecLine);
        LibraryLowerPermissions.SetBanking();
        BankAccReconciliation.ImportBankStatement();
        UnbindSubscription(ImportCAMTBankAccRecLine);

        // [THEN] One bank reconciliation line has been created.
        VerifyImportCAMT054_OnePayment(BankAccReconciliationLine, PmtCurrency, PmtAmount, InvDbtrName, InvRefTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ImportCAMT_053_02_BankAccountID()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccount: Record "Bank Account";
        ImportCAMTBankAccRecLine: Codeunit "Import CAMT Bank AccRecLine";
    begin
        // [FEATURE] [CAMT 053-02] [Bank Account ID]
        // [SCENARIO 273063] Import CAMT 053-02 when only Bank Account Id is specified in Stmt/Acct/Id/Othr/Id
        Initialize();

        // [GIVEN] Bank account with SEPA CAMT 053-02 setup
        SetupBankAccWithBankReconciliation(BankAccount, BankAccReconciliation, BankAccReconciliationLine, GetCAMT05302DataExch());

        // [GIVEN] XML file with Bank Account Id specified in Stmt/Acct/Id/Othr/Id
        WriteCAMTFile_BankAccID(GetNamespace05302(), 'camt.053.001.02.xsd', 'BkToCstmrStmt', 'Stmt', BankAccount."Bank Account No.");

        // [WHEN] Import bank statement
        BindSubscription(ImportCAMTBankAccRecLine);
        LibraryLowerPermissions.SetBanking();
        BankAccReconciliation.ImportBankStatement();
        UnbindSubscription(ImportCAMTBankAccRecLine);

        // [THEN] The file has been imported and a line has been created
        BankAccReconciliationLine.SetRange("Bank Account No.", BankAccount."No.");
        BankAccReconciliationLine.FindFirst();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ImportCAMT_053_04_BankAccountID()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccount: Record "Bank Account";
        ImportCAMTBankAccRecLine: Codeunit "Import CAMT Bank AccRecLine";
    begin
        // [FEATURE] [CAMT 053-04] [Bank Account ID]
        // [SCENARIO 273063] Import CAMT 053-04 when only Bank Account Id is specified in Stmt/Acct/Id/Othr/Id
        Initialize();

        // [GIVEN] Bank account with SEPA CAMT 053-04 setup
        SetupBankAccWithBankReconciliation(BankAccount, BankAccReconciliation, BankAccReconciliationLine, GetCAMT05304DataExch());

        // [GIVEN] XML file with Bank Account Id specified in Stmt/Acct/Id/Othr/Id
        WriteCAMTFile_BankAccID(GetNamespace05304(), 'camt.053.001.04.xsd', 'BkToCstmrStmt', 'Stmt', BankAccount."Bank Account No.");

        // [WHEN] Import bank statement
        BindSubscription(ImportCAMTBankAccRecLine);
        LibraryLowerPermissions.SetBanking();
        BankAccReconciliation.ImportBankStatement();
        UnbindSubscription(ImportCAMTBankAccRecLine);

        // [THEN] The file has been imported and a line has been created
        BankAccReconciliationLine.SetRange("Bank Account No.", BankAccount."No.");
        BankAccReconciliationLine.FindFirst();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ImportCAMT_054_BankAccountID()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccount: Record "Bank Account";
        ImportCAMTBankAccRecLine: Codeunit "Import CAMT Bank AccRecLine";
    begin
        // [FEATURE] [CAMT 054] [Bank Account ID]
        // [SCENARIO 273063] Import CAMT 054 when only Bank Account Id is specified in Stmt/Acct/Id/Othr/Id
        Initialize();

        // [GIVEN] Bank account with SEPA CAMT 054 setup
        SetupBankAccWithBankReconciliation(BankAccount, BankAccReconciliation, BankAccReconciliationLine, GetCAMT054DataExch());

        // [GIVEN] XML file with Bank Account Id specified in Stmt/Acct/Id/Othr/Id
        WriteCAMTFile_BankAccID(GetNamespace054(), 'camt.054.001.04.xsd', 'BkToCstmrDbtCdtNtfctn', 'Ntfctn', BankAccount."Bank Account No.");

        // [WHEN] Import bank statement
        BindSubscription(ImportCAMTBankAccRecLine);
        LibraryLowerPermissions.SetBanking();
        BankAccReconciliation.ImportBankStatement();
        UnbindSubscription(ImportCAMTBankAccRecLine);

        // [THEN] The file has been imported and a line has been created
        BankAccReconciliationLine.SetRange("Bank Account No.", BankAccount."No.");
        BankAccReconciliationLine.FindFirst();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MatchDocNoWithAdditionalTextForCAMT05302()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        BankAccount: Record "Bank Account";
        TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary;
        Customer: Record Customer;
        Amount: Decimal;
        DocumentNo: Code[20];
    begin
        // [FEATURE] [CAMT 053-02]
        // [SCENARIO 252679] Match CAMT 053-02 in case of "Additional Transaction Info" contains "Document No." of the existing sales document with concatenation of alphanumeric symbols.
        Initialize();

        // [GIVEN] Posted Sales Invoice with "Document No." = "103001".
        LibrarySales.CreateCustomer(Customer);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        DocumentNo := LibraryUtility.GenerateGUID();
        CreateAndPostSalesInvoice(Customer."No.", DocumentNo, '', Amount);

        // [GIVEN] Reconciliation Line with "Additional Transaction Info" = "xxxxxxxxx103001x", where "x" is an alphanumeric symbol (0-9,a-z,A-Z).
        CreateBankReconciliation(BankAccReconciliation);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, Amount / 2, '',
          GetCAMT_053_054_RmtInfStrdCdtrRef(DocumentNo), '');

        // [GIVEN] Bank Account of the Reconciliation Line has "Bank Statement Import Format" = "SEPA CAMT 053-02"
        BankAccount.Get(BankAccReconciliation."Bank Account No.");
        BankAccount."Bank Statement Import Format" := CreateBankExportImportSetup(GetCAMT05302DataExch(), GetCAMT053ProcCodID());
        BankAccount.Modify();

        // [WHEN] Run matching procedure.
        RunMatch(BankAccReconciliation, TempBankStatementMatchingBuffer, true);

        // [THEN] A match found for "Document No.".
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes, BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");
        VerifyReconciliation(BankPmtApplRule, TempBankStatementMatchingBuffer, BankAccReconciliationLine."Statement Line No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MatchDocNoWithAdditionalTextForCAMT05304()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        BankAccount: Record "Bank Account";
        TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary;
        Customer: Record Customer;
        Amount: Decimal;
        DocumentNo: Code[20];
    begin
        // [FEATURE] [CAMT 053-04]
        // [SCENARIO 252679] Match CAMT 053-04 in case of "Additional Transaction Info" contains "Document No." of the existing sales document with concatenation of alphanumeric symbols.
        Initialize();

        // [GIVEN] Posted Sales Invoice with "Document No." = "103001".
        LibrarySales.CreateCustomer(Customer);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        DocumentNo := LibraryUtility.GenerateGUID();
        CreateAndPostSalesInvoice(Customer."No.", DocumentNo, '', Amount);

        // [GIVEN] Reconciliation Line with "Additional Transaction Info" = "xxxxxxxxx103001x", where "x" is an alphanumeric symbol (0-9,a-z,A-Z).
        CreateBankReconciliation(BankAccReconciliation);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, Amount / 2, '',
          GetCAMT_053_054_RmtInfStrdCdtrRef(DocumentNo), '');

        // [GIVEN] Bank Account of the Reconciliation Line has "Bank Statement Import Format" = "SEPA CAMT 053-04"
        BankAccount.Get(BankAccReconciliation."Bank Account No.");
        BankAccount."Bank Statement Import Format" := CreateBankExportImportSetup(GetCAMT05304DataExch(), GetCAMT053ProcCodID());
        BankAccount.Modify();

        // [WHEN] Run matching procedure.
        RunMatch(BankAccReconciliation, TempBankStatementMatchingBuffer, true);

        // [THEN] A match found for "Document No.".
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes, BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");
        VerifyReconciliation(BankPmtApplRule, TempBankStatementMatchingBuffer, BankAccReconciliationLine."Statement Line No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MatchDocNoWithAdditionalTextForCAMT054()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        BankAccount: Record "Bank Account";
        TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary;
        Customer: Record Customer;
        Amount: Decimal;
        DocumentNo: Code[20];
    begin
        // [FEATURE] [CAMT 054]
        // [SCENARIO 252679] Match CAMT 054 in case of "Additional Transaction Info" contains "Document No." of the existing sales document with concatenation of alphanumeric symbols.
        Initialize();

        // [GIVEN] Posted sales invoice with "Document No." = "103001"
        LibrarySales.CreateCustomer(Customer);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        DocumentNo := LibraryUtility.GenerateGUID();
        CreateAndPostSalesInvoice(Customer."No.", DocumentNo, '', Amount);

        // [GIVEN] Reconciliation Line with "Additional Transaction Info" = "xxxxxxxxx103001x", where "x" is an alphanumeric symbol (0-9,a-z,A-Z).
        CreateBankReconciliation(BankAccReconciliation);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, Amount / 2, '',
          GetCAMT_053_054_RmtInfStrdCdtrRef(DocumentNo), '');

        // [GIVEN] Bank Account of the Reconciliation Line has "Bank Statement Import Format" = "SEPA CAMT 054"
        BankAccount.Get(BankAccReconciliation."Bank Account No.");
        BankAccount."Bank Statement Import Format" := CreateBankExportImportSetup(GetCAMT054DataExch(), GetCAMT054ProcCodID());
        BankAccount.Modify();

        // [WHEN] Run matching procedure.
        RunMatch(BankAccReconciliation, TempBankStatementMatchingBuffer, true);

        // [THEN] A match found for "Document No.".
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes, BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");
        VerifyReconciliation(BankPmtApplRule, TempBankStatementMatchingBuffer, BankAccReconciliationLine."Statement Line No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MatchingRuleWithMultipleAmountAndOneDocNoAndNoRelatedPartyExists()
    var
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 264899] Bank Payment Application Rule with with "Related Party Matched" = "No", "Doc No. Matched" = "Yes" and "Amount Matched" = "Multiple Matches" is created by default.
        Initialize();

        // [WHEN] Restore default set of matching rules.
        InsertDefaultMatchingRules();

        // [THEN] Bank Application Rule with "Related Party Matched" = "No", "Doc No. Matched" = "Yes" and "Amount Matched" = "Multiple Matches" exists.
        VerifyBankPmtApplRuleExists(
          BankPmtApplRule."Match Confidence"::High, 10, BankPmtApplRule."Related Party Matched"::No,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes,
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"Multiple Matches");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CHMgt_IsESRFormat_UT()
    var
        CHMgt: Codeunit CHMgt;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 272865] COD 11503 CHMgt.IsESRFormat() returns TRUE only in case of 27-chars length numeric "ESR Reference No." with check digit.
        Initialize();

        // IsESRFormat returns FALSE, when set text with alphabetic chars as input.
        Assert.IsFalse(
          CHMgt.IsESRFormat(LibraryUtility.GenerateRandomAlphabeticText(27, 0)), 'ESR Reference No. must contain digits only');

        // IsESRFormat returns FALSE, when set numeric text with length = 26 and correct check digit as input.
        Assert.IsFalse(CHMgt.IsESRFormat('30041985300000000000000001'), 'ESR Reference No. must have 27 digits.');

        // IsESRFormat returns FALSE, when set numeric text with length = 27 and incorrect check digit as input.
        Assert.IsFalse(CHMgt.IsESRFormat(IncStr(GetESRReferenceNo())), 'Wrong check digit of ESR Reference No.');

        // IsESRFormat returns TRUE, when set numeric text with length = 27 and correct check digit as input.
        Assert.IsTrue(CHMgt.IsESRFormat(GetESRReferenceNo()), 'The text is not in ESR format.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MatchAllWhenESRRefNoHasNotESRFormatForCAMT054()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        BankAccount: Record "Bank Account";
        TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary;
        Amount: Decimal;
        DocumentNo: Code[20];
    begin
        // [FEATURE] [CAMT 054]
        // [SCENARIO 272865] Match "Doc No.", Amount, Customer Name for CAMT054 in case of "ESR Reference No." is not in ESR format, but contains "Document No.".
        Initialize();

        // [GIVEN] Posted Sales Invoice with "Document No." = "D1", Amount = "A1" for Customer with Name = "CN1".
        CreateCustomerWithAddress(Customer, LibraryUtility.GenerateGUID(), '', '', '');
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        DocumentNo := LibraryUtility.GenerateGUID();
        CreateAndPostSalesInvoice(Customer."No.", DocumentNo, '', Amount);

        // [GIVEN] Reconciliation Line with Amount = "A1", "Transaction Text" = "CN1". "ESR Reference No." contains "D1" and alphabetic characters.
        CreateBankReconciliation(BankAccReconciliation);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, Amount, Customer.Name, '',
          GetCAMT_053_054_RmtInfStrdCdtrRef(DocumentNo));

        // [GIVEN] Bank Account of the Reconciliation Line has "Bank Statement Import Format" = "SEPA CAMT 054"
        BankAccount.Get(BankAccReconciliation."Bank Account No.");
        BankAccount."Bank Statement Import Format" := CreateBankExportImportSetup(GetCAMT054DataExch(), GetCAMT054ProcCodID());
        BankAccount.Modify();

        // [WHEN] Run matching procedure.
        RunMatch(BankAccReconciliation, TempBankStatementMatchingBuffer, true);

        // [THEN] A match found for "Document No.", Amount and Customer Name.
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes, BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match");
        VerifyReconciliation(BankPmtApplRule, TempBankStatementMatchingBuffer, BankAccReconciliationLine."Statement Line No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MatchDocNoWithESRRefNoWhenWrongDocNoPositionAndTextHasESRFormatForCAMT054()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
        BankAccount: Record "Bank Account";
        TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary;
        Amount: Decimal;
        DocumentNo: Code[20];
    begin
        // [FEATURE] [CAMT 054]
        // [SCENARIO 272865] Match "Doc No.", Amount, Customer Name for CAMT054 in case of "ESR Reference No." is in ESR format and it contains "Document No." not in "xxxxxxxxx103001x" position.
        Initialize();

        // [GIVEN] Posted Sales Invoice with "Document No." = "103001", Amount = "A1" for Customer with Name = "CN1".
        CreateCustomerWithAddress(Customer, LibraryUtility.GenerateGUID(), '', '', '');
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        DocumentNo := GenerateNumericDocNo();
        CreateAndPostSalesInvoice(Customer."No.", DocumentNo, '', Amount);

        // [GIVEN] Reconciliation Line with "ESR Reference No." = "xxxxxx103001xxxx", where "x" is a numeric symbol (0-9). Amount = "A1", "Transaction Text" = "CN1".
        CreateBankReconciliation(BankAccReconciliation);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, Amount, Customer.Name, '',
          GetCAMT_053_054_ESRReferenceNoFromDocNo(DocumentNo + CopyStr(LibraryUtility.GenerateRandomNumericText(3), 1, 3)));

        // [GIVEN] Bank Account of the Reconciliation Line has "Bank Statement Import Format" = "SEPA CAMT 054"
        BankAccount.Get(BankAccReconciliation."Bank Account No.");
        BankAccount."Bank Statement Import Format" := CreateBankExportImportSetup(GetCAMT054DataExch(), GetCAMT054ProcCodID());
        BankAccount.Modify();

        // [WHEN] Run matching procedure.
        RunMatch(BankAccReconciliation, TempBankStatementMatchingBuffer, true);

        // [THEN] No matches found for either Amount or Customer Name or "Document No.".
        Assert.RecordIsEmpty(TempBankStatementMatchingBuffer);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MatchDocNoWithESRRefNoWhenTextHasESRFormatForCAMT05302()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        BankAccount: Record "Bank Account";
        TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary;
        Amount: Decimal;
        DocumentNo: Code[20];
    begin
        // [FEATURE] [CAMT 053-02]
        // [SCENARIO 272865] Match "Doc No." for CAMT053-02 in case of "ESR Reference No." is in ESR format and it contains "Document No." in "xxxxxxxxx103001x" position.
        Initialize();

        // [GIVEN] Posted Sales Invoice with "Document No." = "103001".
        LibrarySales.CreateCustomer(Customer);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        DocumentNo := GenerateNumericDocNo();
        CreateAndPostSalesInvoice(Customer."No.", DocumentNo, '', Amount);

        // [GIVEN] Reconciliation Line with "ESR Reference No." = "xxxxxxxxx103001x", where "x" is a numeric symbol (0-9).
        CreateBankReconciliation(BankAccReconciliation);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, Amount / 2, '', '',
          GetCAMT_053_054_ESRReferenceNoFromDocNo(DocumentNo));

        // [GIVEN] Bank Account of the Reconciliation Line has "Bank Statement Import Format" = "SEPA CAMT 053-02"
        BankAccount.Get(BankAccReconciliation."Bank Account No.");
        BankAccount."Bank Statement Import Format" := CreateBankExportImportSetup(GetCAMT05302DataExch(), GetCAMT053ProcCodID());
        BankAccount.Modify();

        // [WHEN] Run matching procedure.
        RunMatch(BankAccReconciliation, TempBankStatementMatchingBuffer, true);

        // [THEN] A match found for "Document No.".
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes, BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");
        VerifyReconciliation(BankPmtApplRule, TempBankStatementMatchingBuffer, BankAccReconciliationLine."Statement Line No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MatchDocNoWithESRRefNoWhenTextHasESRFormatForCAMT05304()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        BankAccount: Record "Bank Account";
        TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary;
        Amount: Decimal;
        DocumentNo: Code[20];
    begin
        // [FEATURE] [CAMT 053-04]
        // [SCENARIO 272865] Match "Doc No." for CAMT053-04 in case of "ESR Reference No." is in ESR format and it contains "Document No." in "xxxxxxxxx103001x" position.
        Initialize();

        // [GIVEN] Posted Sales Invoice with "Document No." = "103001".
        LibrarySales.CreateCustomer(Customer);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        DocumentNo := GenerateNumericDocNo();
        CreateAndPostSalesInvoice(Customer."No.", DocumentNo, '', Amount);

        // [GIVEN] Reconciliation Line with "ESR Reference No." = "xxxxxxxxx103001x", where "x" is a numeric symbol (0-9).
        CreateBankReconciliation(BankAccReconciliation);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, Amount / 2, '', '',
          GetCAMT_053_054_ESRReferenceNoFromDocNo(DocumentNo));

        // [GIVEN] Bank Account of the Reconciliation Line has "Bank Statement Import Format" = "SEPA CAMT 053-04"
        BankAccount.Get(BankAccReconciliation."Bank Account No.");
        BankAccount."Bank Statement Import Format" := CreateBankExportImportSetup(GetCAMT05304DataExch(), GetCAMT053ProcCodID());
        BankAccount.Modify();

        // [WHEN] Run matching procedure.
        RunMatch(BankAccReconciliation, TempBankStatementMatchingBuffer, true);

        // [THEN] A match found for "Document No.".
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes, BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");
        VerifyReconciliation(BankPmtApplRule, TempBankStatementMatchingBuffer, BankAccReconciliationLine."Statement Line No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MatchDocNoWithESRRefNoWhenTextHasESRFormatForCAMT054()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        BankAccount: Record "Bank Account";
        TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary;
        Amount: Decimal;
        DocumentNo: Code[20];
    begin
        // [FEATURE] [CAMT 054]
        // [SCENARIO 272865] Match "Doc No." for CAMT054 in case of "ESR Reference No." is in ESR format and it contains "Document No." in "xxxxxxxxx103001x" position.
        Initialize();

        // [GIVEN] Posted Sales Invoice with "Document No." = "103001".
        LibrarySales.CreateCustomer(Customer);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        DocumentNo := GenerateNumericDocNo();
        CreateAndPostSalesInvoice(Customer."No.", DocumentNo, '', Amount);

        // [GIVEN] Reconciliation Line with "ESR Reference No." = "xxxxxxxxx103001x", where "x" is a numeric symbol (0-9).
        CreateBankReconciliation(BankAccReconciliation);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, Amount / 2, '', '',
          GetCAMT_053_054_ESRReferenceNoFromDocNo(DocumentNo));

        // [GIVEN] Bank Account of the Reconciliation Line has "Bank Statement Import Format" = "SEPA CAMT 054"
        BankAccount.Get(BankAccReconciliation."Bank Account No.");
        BankAccount."Bank Statement Import Format" := CreateBankExportImportSetup(GetCAMT054DataExch(), GetCAMT054ProcCodID());
        BankAccount.Modify();

        // [WHEN] Run matching procedure.
        RunMatch(BankAccReconciliation, TempBankStatementMatchingBuffer, true);

        // [THEN] A match found for "Document No.".
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes, BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");
        VerifyReconciliation(BankPmtApplRule, TempBankStatementMatchingBuffer, BankAccReconciliationLine."Statement Line No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MatchAllWithESRRefNoWhenTextHasESRFormatForCAMT05302()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        BankAccount: Record "Bank Account";
        TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary;
        Amount: Decimal;
        DocumentNo: Code[20];
    begin
        // [FEATURE] [CAMT 053-02]
        // [SCENARIO 272865] Match "Doc No.", Amount, Customer Name for CAMT053-02 in case of "ESR Reference No." is in ESR format and it contains "Document No." in "xxxxxxxxx103001x" position.
        Initialize();

        // [GIVEN] Posted Sales Invoice with "Document No." = "103001", Amount = "A1" for Customer with Name = "CN1".
        CreateCustomerWithAddress(Customer, LibraryUtility.GenerateGUID(), '', '', '');
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        DocumentNo := GenerateNumericDocNo();
        CreateAndPostSalesInvoice(Customer."No.", DocumentNo, '', Amount);

        // [GIVEN] Reconciliation Line with "ESR Reference No." = "xxxxxxxxx103001x", where "x" is a numeric symbol (0-9). Amount = "A1", "Transaction Text" = "CN1".
        CreateBankReconciliation(BankAccReconciliation);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, Amount, Customer.Name, '',
          GetCAMT_053_054_ESRReferenceNoFromDocNo(DocumentNo));

        // [GIVEN] Bank Account of the Reconciliation Line has "Bank Statement Import Format" = "SEPA CAMT 053-02"
        BankAccount.Get(BankAccReconciliation."Bank Account No.");
        BankAccount."Bank Statement Import Format" := CreateBankExportImportSetup(GetCAMT05302DataExch(), GetCAMT053ProcCodID());
        BankAccount.Modify();

        // [WHEN] Run matching procedure.
        RunMatch(BankAccReconciliation, TempBankStatementMatchingBuffer, true);

        // [THEN] A match found for "Document No.", Amount and Customer Name.
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes, BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match");
        VerifyReconciliation(BankPmtApplRule, TempBankStatementMatchingBuffer, BankAccReconciliationLine."Statement Line No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MatchAllWithESRRefNoWhenTextHasESRFormatForCAMT05304()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        BankAccount: Record "Bank Account";
        TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary;
        Amount: Decimal;
        DocumentNo: Code[20];
    begin
        // [FEATURE] [CAMT 053-04]
        // [SCENARIO 272865] Match "Doc No.", Amount, Customer Name for CAMT053-04 in case of "ESR Reference No." is in ESR format and it contains "Document No." in "xxxxxxxxx103001x" position.
        Initialize();

        // [GIVEN] Posted Sales Invoice with "Document No." = "103001", Amount = "A1" for Customer with Name = "CN1".
        CreateCustomerWithAddress(Customer, LibraryUtility.GenerateGUID(), '', '', '');
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        DocumentNo := GenerateNumericDocNo();
        CreateAndPostSalesInvoice(Customer."No.", DocumentNo, '', Amount);

        // [GIVEN] Reconciliation Line with "ESR Reference No." = "xxxxxxxxx103001x", where "x" is a numeric symbol (0-9). Amount = "A1", "Transaction Text" = "CN1".
        CreateBankReconciliation(BankAccReconciliation);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, Amount, Customer.Name, '',
          GetCAMT_053_054_ESRReferenceNoFromDocNo(DocumentNo));

        // [GIVEN] Bank Account of the Reconciliation Line has "Bank Statement Import Format" = "SEPA CAMT 053-04"
        BankAccount.Get(BankAccReconciliation."Bank Account No.");
        BankAccount."Bank Statement Import Format" := CreateBankExportImportSetup(GetCAMT05304DataExch(), GetCAMT053ProcCodID());
        BankAccount.Modify();

        // [WHEN] Run matching procedure.
        RunMatch(BankAccReconciliation, TempBankStatementMatchingBuffer, true);

        // [THEN] A match found for "Document No.", Amount and Customer Name.
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes, BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match");
        VerifyReconciliation(BankPmtApplRule, TempBankStatementMatchingBuffer, BankAccReconciliationLine."Statement Line No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MatchAllWithESRRefNoWhenTextHasESRFormatForCAMT054()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        BankAccount: Record "Bank Account";
        TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary;
        Amount: Decimal;
        DocumentNo: Code[20];
    begin
        // [FEATURE] [CAMT 054]
        // [SCENARIO 272865] Match "Doc No.", Amount, Customer Name for CAMT054 in case of "ESR Reference No." is in ESR format and it contains "Document No." in "xxxxxxxxx103001x" position.
        Initialize();

        // [GIVEN] Posted Sales Invoice with "Document No." = "103001", Amount = "A1" for Customer with Name = "CN1".
        CreateCustomerWithAddress(Customer, LibraryUtility.GenerateGUID(), '', '', '');
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        DocumentNo := GenerateNumericDocNo();
        CreateAndPostSalesInvoice(Customer."No.", DocumentNo, '', Amount);

        // [GIVEN] Reconciliation Line with "ESR Reference No." = "xxxxxxxxx103001x", where "x" is a numeric symbol (0-9). Amount = "A1", "Transaction Text" = "CN1".
        CreateBankReconciliation(BankAccReconciliation);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, Amount, Customer.Name, '',
          GetCAMT_053_054_ESRReferenceNoFromDocNo(DocumentNo));

        // [GIVEN] Bank Account of the Reconciliation Line has "Bank Statement Import Format" = "SEPA CAMT 054"
        BankAccount.Get(BankAccReconciliation."Bank Account No.");
        BankAccount."Bank Statement Import Format" := CreateBankExportImportSetup(GetCAMT054DataExch(), GetCAMT054ProcCodID());
        BankAccount.Modify();

        // [WHEN] Run matching procedure.
        RunMatch(BankAccReconciliation, TempBankStatementMatchingBuffer, true);

        // [THEN] A match found for "Document No.", Amount and Customer Name.
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes, BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match");
        VerifyReconciliation(BankPmtApplRule, TempBankStatementMatchingBuffer, BankAccReconciliationLine."Statement Line No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MatchWhenDocNoNotContainsInESRRefNoWhenTextHasESRFormatForCAMT054()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
        BankAccount: Record "Bank Account";
        TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary;
        Amount: Decimal;
        DocumentNo: Code[20];
    begin
        // [FEATURE] [CAMT 054]
        // [SCENARIO 272865] Match "Doc No.", Amount, Customer Name for CAMT054 in case of "ESR Reference No." is in ESR format, but it does not contain "Document No.".
        Initialize();

        // [GIVEN] Posted Sales Invoice with "Document No." = "D1", Amount = "A1" for Customer with Name = "CN1".
        CreateCustomerWithAddress(Customer, LibraryUtility.GenerateGUID(), '', '', '');
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        DocumentNo := LibraryUtility.GenerateGUID();
        CreateAndPostSalesInvoice(Customer."No.", DocumentNo, '', Amount);

        // [GIVEN] Reconciliation Line with Amount = "A1", "Transaction Text" = "CN1", "Additional Transaction Info" = "D1". "ESR Reference No." is in ESR format and does not contain "D1".
        CreateBankReconciliation(BankAccReconciliation);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, Amount, Customer.Name, DocumentNo,
          GetCAMT_053_054_ESRReferenceNoFromDocNo(CopyStr(LibraryUtility.GenerateRandomNumericText(10), 1, 10)));

        // [GIVEN] Bank Account of the Reconciliation Line has "Bank Statement Import Format" = "SEPA CAMT 054"
        BankAccount.Get(BankAccReconciliation."Bank Account No.");
        BankAccount."Bank Statement Import Format" := CreateBankExportImportSetup(GetCAMT054DataExch(), GetCAMT054ProcCodID());
        BankAccount.Modify();

        // [WHEN] Run matching procedure.
        RunMatch(BankAccReconciliation, TempBankStatementMatchingBuffer, true);

        // [THEN] No matches found for either Amount or Customer Name.
        Assert.RecordIsEmpty(TempBankStatementMatchingBuffer);
    end;

    local procedure Initialize()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Import CAMT Bank AccRecLine");

        CustLedgerEntry.DeleteAll();
        InsertDefaultMatchingRules();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Import CAMT Bank AccRecLine");

        LibraryERM.SetLCYCode(GetEURCurrency());
        Commit();

        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Import CAMT Bank AccRecLine");
    end;

    local procedure PrepareValuesForImportCAMT054_OnePmtOneInv(var PmtCurrency: Text; var PmtAmount: Decimal; var InvCurrency: Text; var InvAmount: Decimal; var InvDbtrName: Text; var InvRefTxt: Text)
    begin
        PmtCurrency := GetDomesticCurrency();
        PmtAmount := 1234.56;
        InvCurrency := GetDomesticCurrency();
        InvAmount := 1234.56;
        InvDbtrName := GetDomesticCurrency() + '_DBTR_NAME';
        InvRefTxt := GetDomesticCurrency() + '_INV_REF';
    end;

    local procedure PrepareValuesForImportCAMT054_OnePmtOneInv_EUR(var PmtCurrency: Text; var PmtAmount: Decimal; var InvCurrency: Text; var InvAmount: Decimal; var InvDbtrName: Text; var InvRefTxt: Text)
    begin
        PmtCurrency := GetEURCurrency();
        PmtAmount := 3456.78;
        InvCurrency := GetEURCurrency();
        InvAmount := 3456.78;
        InvDbtrName := GetEURCurrency() + '_DBTR_NAME';
        InvRefTxt := GetEURCurrency() + '_INV_REF';
    end;

    local procedure PrepareValuesForImportCAMT054_OnePmtTwoInv(var PmtCurrency: Text; var PmtAmount: Decimal; var InvCurrency: array[2] of Text; var InvAmount: array[2] of Decimal; var InvDbtrName: array[2] of Text; var InvRefTxt: array[2] of Text)
    var
        i: Integer;
    begin
        PmtCurrency := GetDomesticCurrency();
        PmtAmount := 1234.56;
        for i := 1 to ArrayLen(InvCurrency) do begin
            InvCurrency[i] := GetDomesticCurrency();
            InvDbtrName[i] := GetDomesticCurrency() + '_DBTR_NAME' + Format(i);
            InvRefTxt[i] := GetDomesticCurrency() + '_INV_REF' + Format(i);
        end;
        InvAmount[1] := 617.29;
        InvAmount[2] := 617.27;
    end;

    local procedure PrepareValuesForImportCAMT054_OnePmtTwoInv_EUR(var PmtCurrency: Text; var PmtAmount: Decimal; var InvCurrency: array[2] of Text; var InvAmount: array[2] of Decimal; var InvDbtrName: array[2] of Text; var InvRefTxt: array[2] of Text)
    var
        i: Integer;
    begin
        PmtCurrency := GetEURCurrency();
        PmtAmount := 3456.78;
        for i := 1 to ArrayLen(InvCurrency) do begin
            InvCurrency[i] := GetEURCurrency();
            InvDbtrName[i] := GetEURCurrency() + '_DBTR_NAME' + Format(i);
            InvRefTxt[i] := GetEURCurrency() + '_INV_REF' + Format(i);
        end;
        InvAmount[1] := 1728.4;
        InvAmount[2] := 1728.38;
    end;

    local procedure PrepareValuesForImportCAMT054_TwoPmtOneInv(var PmtCurrency: array[2] of Text; var PmtAmount: array[2] of Decimal; var InvCurrency: array[2] of Text; var InvAmount: array[2] of Decimal; var InvDbtrName: array[2] of Text; var InvRefTxt: array[2] of Text)
    begin
        PrepareValuesForImportCAMT054_OnePmtOneInv(
          PmtCurrency[1], PmtAmount[1], InvCurrency[1], InvAmount[1], InvDbtrName[1], InvRefTxt[1]);
        PrepareValuesForImportCAMT054_OnePmtOneInv_EUR(
          PmtCurrency[2], PmtAmount[2], InvCurrency[2], InvAmount[2], InvDbtrName[2], InvRefTxt[2]);
    end;

    local procedure PrepareValuesForImportCAMT054_TwoPmtTwoInv(var PmtCurrency: array[2] of Text; var PmtAmount: array[2] of Decimal; var InvCurrency: array[4] of Text; var InvAmount: array[4] of Decimal; var InvDbtrName: array[4] of Text; var InvRefTxt: array[4] of Text)
    var
        TempInvCurrency: array[2] of Text;
        TempInvAmount: array[2] of Decimal;
        TempInvDbtrName: array[2] of Text;
        TempInvRefTxt: array[2] of Text;
    begin
        PrepareValuesForImportCAMT054_OnePmtTwoInv(
          PmtCurrency[1], PmtAmount[1], TempInvCurrency, TempInvAmount, TempInvDbtrName, TempInvRefTxt);
        Copy2DimBufTo4DimBuf(InvCurrency, InvAmount, InvDbtrName, InvRefTxt, TempInvCurrency, TempInvAmount, TempInvDbtrName, TempInvRefTxt, 0);
        PrepareValuesForImportCAMT054_OnePmtTwoInv_EUR(
          PmtCurrency[2], PmtAmount[2], TempInvCurrency, TempInvAmount, TempInvDbtrName, TempInvRefTxt);
        Copy2DimBufTo4DimBuf(InvCurrency, InvAmount, InvDbtrName, InvRefTxt, TempInvCurrency, TempInvAmount, TempInvDbtrName, TempInvRefTxt, 2);
    end;

    local procedure GetCAMT05302DataExch(): Code[20]
    var
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchMapping: Record "Data Exch. Mapping";
    begin
        DataExchLineDef.SetFilter(Namespace, GetNamespace05302());
        DataExchLineDef.FindSet();
        DataExchMapping.SetRange("Mapping Codeunit", CODEUNIT::"SEPA CAMT 053 Bank Rec. Lines");
        repeat
            DataExchMapping.SetRange("Data Exch. Def Code", DataExchLineDef."Data Exch. Def Code");
            if not DataExchMapping.IsEmpty() then
                exit(DataExchLineDef."Data Exch. Def Code");
        until DataExchLineDef.Next() = 0;
        Assert.Fail('Data Exchange Definition is not found');
    end;

    local procedure GetCAMT05304DataExch(): Code[20]
    var
        DataExchLineDef: Record "Data Exch. Line Def";
    begin
        DataExchLineDef.SetFilter(Namespace, GetNamespace05304());
        DataExchLineDef.FindFirst();
        exit(DataExchLineDef."Data Exch. Def Code");
    end;

    local procedure GetCAMT054DataExch(): Code[20]
    var
        DataExchLineDef: Record "Data Exch. Line Def";
    begin
        DataExchLineDef.SetFilter(Namespace, GetNamespace054());
        DataExchLineDef.FindFirst();
        exit(DataExchLineDef."Data Exch. Def Code");
    end;

    local procedure GetIBANTxt(): Code[50]
    begin
        exit('CH9581320000001998736');
    end;

    local procedure GetEURCurrency(): Code[10]
    begin
        exit('EUR');
    end;

    local procedure GetDomesticCurrency(): Code[10]
    begin
        exit('CHF');
    end;

    local procedure GetForeignCurrency(): Code[10]
    begin
        exit('USD');
    end;

    local procedure GetNamespace05302(): Text
    begin
        exit('urn:iso:std:iso:20022:tech:xsd:camt.053.001.02');
    end;

    local procedure GetNamespace05304(): Text
    begin
        exit('urn:iso:std:iso:20022:tech:xsd:camt.053.001.04');
    end;

    local procedure GetNamespace054(): Text
    begin
        exit('urn:iso:std:iso:20022:tech:xsd:camt.054.001.04');
    end;

    local procedure GetDate(): Text
    begin
        exit(StrSubstNo('%1-05-05', Format(Date2DMY(WorkDate(), 3))));
    end;

    local procedure GetDateTime(): Text
    begin
        exit(StrSubstNo('%1-05-05T09:00:00+01:00', Format(Date2DMY(WorkDate(), 3))));
    end;

    local procedure GetAmountText(Amount: Decimal): Text
    begin
        exit(Format(Amount, 0, 9));
    end;

    local procedure GetCAMT053ProcCodID(): Integer
    begin
        exit(CODEUNIT::"SEPA CAMT 053 Bank Rec. Lines");
    end;

    local procedure GetCAMT054ProcCodID(): Integer
    begin
        exit(CODEUNIT::"SEPA CAMT 054 Bank Rec. Lines");
    end;

    local procedure GetESRReferenceNo(): Text[27]
    begin
        exit('300419853000000000000000005');
    end;

    local procedure GenJnlImportBankStatement(GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.Init();
        GenJournalLine."Journal Template Name" := GenJournalBatch."Journal Template Name";
        GenJournalLine."Journal Batch Name" := GenJournalBatch.Name;
        GenJournalLine.ImportBankStatement();
    end;

    local procedure SetStatementValues(var StartBalAmt: Decimal; var CreditAmt1: Decimal; var CreditAmt2: Decimal; var DebitAmt: Decimal)
    begin
        StartBalAmt := 2501.5;
        CreditAmt1 := 100;
        CreditAmt2 := 45.7;
        DebitAmt := 250.0;
    end;

    local procedure GetCAMT054DataExchPmtCurrencyColumnNo(): Integer
    var
        DataExchColumnDef: Record "Data Exch. Column Def";
    begin
        DataExchColumnDef.SetRange("Data Exch. Def Code", GetCAMT054DataExch());
        DataExchColumnDef.SetRange(Name, 'Ntfctn/Ntry/Amt[@Ccy]');
        DataExchColumnDef.FindFirst();
        exit(DataExchColumnDef."Column No.");
    end;

    local procedure GetCAMT054DataExchInvRefColumnNo(): Integer
    var
        DataExchColumnDef: Record "Data Exch. Column Def";
    begin
        DataExchColumnDef.SetRange("Data Exch. Def Code", GetCAMT054DataExch());
        DataExchColumnDef.SetRange(Name, 'Ntfctn/Ntry/NtryDtls/TxDtls/RmtInf/Strd/CdtrRefInf/Ref');
        DataExchColumnDef.FindFirst();
        exit(DataExchColumnDef."Column No.");
    end;

    local procedure GetCAMT_053_054_RmtInfStrdCdtrRef(DocumentNo: Code[20]): Text[35]
    begin
        // Max length of "Ref" tag of Creditor Reference Information is 35. Source: "Credit Transfer Scheme Interbank Implementation Guidelines 2017 version 2.0"
        exit(InsStr(LibraryUtility.GenerateRandomXMLText(33 - StrLen(DocumentNo)), ' ' + DocumentNo + ' ', 33 - StrLen(DocumentNo)));
    end;

    local procedure GetCAMT_053_054_ESRReferenceNoFromDocNo(DocumentNo: Code[20]): Text[27]
    var
        BankMgt: Codeunit BankMgt;
        RefNo: Text[26];
    begin
        RefNo := CopyStr(PadStr(GetESRReferenceNo(), 27 - StrLen(DocumentNo) - 1) + DocumentNo, 1, MaxStrLen(RefNo));
        exit(RefNo + BankMgt.CalcCheckDigit(RefNo));
    end;

    local procedure WriteCAMTFile_BankAccID(NamespaceTxt: Text; XSDTxt: Text; HeaderName: Text; StatementName: Text; BankAccID: Text)
    var
        OutStream: OutStream;
        PmtAmount: Decimal;
        InvAmount: Decimal;
        PmtCurrency: Text;
        InvCurrency: Text;
        InvDbtrName: Text;
        InvRefTxt: Text;
    begin
        PrepareValuesForImportCAMT054_OnePmtOneInv(PmtCurrency, PmtAmount, InvCurrency, InvAmount, InvDbtrName, InvRefTxt);
        Clear(TempBlobGlobal);
        TempBlobGlobal.CreateOutStream(OutStream, TEXTENCODING::UTF8);
        WriteCAMTHeaderWithBankID(OutStream, NamespaceTxt, XSDTxt, HeaderName, StatementName, BankAccID);
        LibraryCAMTFileMgt.WriteCAMTStmtHeaderBal(OutStream, 'OPBD', GetEURCurrency(), GetAmountText(0), GetDate());
        LibraryCAMTFileMgt.WriteCAMTStmtHeaderBal(OutStream, 'CLBD', GetEURCurrency(), GetAmountText(PmtAmount), GetDate());
        WriteCAMTPmtHeader(OutStream, PmtCurrency, PmtAmount, true);
        WriteCAMTInvoice(OutStream, 'TEST', InvCurrency, InvAmount, InvDbtrName, InvRefTxt);
        WriteCAMTPmtFooter(OutStream);
        WriteCAMTFooter(OutStream, HeaderName, StatementName);
    end;

    local procedure WriteCAMTFile05302(OutStream: OutStream)
    begin
        WriteCAMTFileSwiss(
          OutStream, ImportTypeRef::camt05302, GetNamespace05302(), 'camt.053.001.02.xsd', 'BkToCstmrStmt', 'Stmt');
    end;

    local procedure WriteCAMTFile05304(OutStream: OutStream)
    begin
        WriteCAMTFileSwiss(
          OutStream, ImportTypeRef::camt05304, GetNamespace05304(), 'camt.053.001.04.xsd', 'BkToCstmrStmt', 'Stmt');
    end;

    local procedure WriteCAMTFile054(OutStream: OutStream)
    begin
        WriteCAMTFileSwiss(
          OutStream, ImportTypeRef::camt054, GetNamespace054(), 'camt.054.001.04.xsd', 'BkToCstmrDbtCdtNtfctn', 'Ntfctn');
    end;

    local procedure WriteCAMTFileSwiss(OutStream: OutStream; ImportType: Option; NamespaceTxt: Text; XSDTxt: Text; HeaderName: Text; StatementName: Text)
    var
        StartBalAmt: Decimal;
        CreditAmt1: Decimal;
        CreditAmt2: Decimal;
        DebitAmt: Decimal;
    begin
        SetStatementValues(StartBalAmt, CreditAmt1, CreditAmt2, DebitAmt);

        // Statement Header
        WriteCAMTHeader(OutStream, NamespaceTxt, XSDTxt, HeaderName, StatementName);

        // Statement Balance
        if ImportType in [ImportTypeRef::camt05302, ImportTypeRef::camt05304] then begin
            LibraryCAMTFileMgt.WriteCAMTStmtHeaderBal(OutStream, 'OPBD', GetEURCurrency(), GetAmountText(StartBalAmt), GetDate());
            LibraryCAMTFileMgt.WriteCAMTStmtHeaderBal(
              OutStream, 'CLBD', GetEURCurrency(), GetAmountText(StartBalAmt + CreditAmt1 + CreditAmt2 - DebitAmt), GetDate());
        end;

        // Credit Entry for multy payment statement
        if ImportType = ImportTypeRef::camt05304 then begin
            WriteCAMTPmtHeader(OutStream, 'CHF', CreditAmt1 + CreditAmt2, true);
            WriteCAMTInvoice(OutStream, 'P001.01.00.01-110718163809-01', 'CHF', CreditAmt1, '', '123456789012345678901234567');
            WriteCAMTInvoice(OutStream, 'P001.01.00.01-110718163809-02', 'CHF', CreditAmt2, '', '210000000003139471430009017');
            WriteCAMTPmtFooter(OutStream);
        end;

        // Debit/Credit Entry
        WriteCAMTPmtHeader(OutStream, 'CHF', DebitAmt, ImportType = ImportTypeRef::camt054);

        WriteLine(OutStream, '<TxDtls>');
        WriteNtryDtlsEndToEndID(OutStream);
        if ImportType = ImportTypeRef::camt05302 then
            WriteNtryDtlsRltdPtiesCdtr(OutStream);
        if ImportType = ImportTypeRef::camt054 then begin
            WriteNtryDtlsRltdPtiesDbtr(OutStream);
            WriteLine(OutStream, '<RmtInf>');
            WriteNtryDtlsRmtInfStrd(OutStream, '210000000003139471430009017');
            WriteLine(OutStream, '</RmtInf>');
        end;
        WriteLine(OutStream, '</TxDtls>');
        WriteCAMTPmtFooter(OutStream);

        WriteCAMTFooter(OutStream, HeaderName, StatementName);
    end;

    local procedure WriteCAMTHeader(OutStream: OutStream; NamespaceTxt: Text; XSDTxt: Text; HeaderName: Text; StatementName: Text)
    begin
        WriteCAMTNamespace(OutStream, NamespaceTxt, XSDTxt);
        WriteLine(OutStream, '  <' + HeaderName + '>');
        WriteCAMTGrpHdr(OutStream);
        WriteLine(OutStream, '    <' + StatementName + '>');
        WriteLine(OutStream, '      <Id>STMID-01</Id>');
        WriteLine(OutStream, '      <CreDtTm>' + GetDateTime() + '</CreDtTm>');
        LibraryCAMTFileMgt.WriteCAMTStmtHeaderBankAccIBAN(OutStream, GetIBANTxt());
    end;

    local procedure WriteCAMTHeaderWithBankID(OutStream: OutStream; NamespaceTxt: Text; XSDTxt: Text; HeaderName: Text; StatementName: Text; BankAccID: Text)
    begin
        WriteCAMTNamespace(OutStream, NamespaceTxt, XSDTxt);
        WriteLine(OutStream, '  <' + HeaderName + '>');
        WriteCAMTGrpHdr(OutStream);
        WriteLine(OutStream, '    <' + StatementName + '>');
        WriteLine(OutStream, '      <Id>STMID-01</Id>');
        WriteLine(OutStream, '      <CreDtTm>' + GetDateTime() + '</CreDtTm>');
        LibraryCAMTFileMgt.WriteCAMTStmtHeaderBankAccID(OutStream, BankAccID);
    end;

    local procedure WriteCAMTHeaderWithExtraSpaces(OutStream: OutStream; NamespaceTxt: Text; XSDTxt: Text; HeaderName: Text; StatementName: Text)
    begin
        WriteCAMTNamespace(OutStream, NamespaceTxt, XSDTxt);
        WriteLine(OutStream, '   <' + HeaderName + '>');
        WriteCAMTGrpHdr(OutStream);
        WriteLine(OutStream, '      <' + StatementName + '>');
        WriteLine(OutStream, '         <Id>STMID-01</Id>');
        WriteLine(OutStream, '         <CreDtTm>' + GetDateTime() + '</CreDtTm>');
        LibraryCAMTFileMgt.WriteCAMTStmtHeaderBankAccIBAN(OutStream, GetIBANTxt());
    end;

    local procedure WriteCAMTFooter(OutStream: OutStream; HeaderName: Text; StatementName: Text)
    begin
        WriteLine(OutStream, '    </' + StatementName + '>');
        WriteLine(OutStream, '  </' + HeaderName + '>');
        WriteLine(OutStream, '</Document>');
    end;

    local procedure WriteCAMTFooterWithExtraSpaces(OutStream: OutStream; HeaderName: Text; StatementName: Text)
    begin
        WriteLine(OutStream, '      </' + StatementName + '>');
        WriteLine(OutStream, '   </' + HeaderName + '>');
        WriteLine(OutStream, '</Document>');
    end;

    local procedure WriteCAMTPmtHeader(OutStream: OutStream; Currency: Text; Amount: Decimal; Creditor: Boolean)
    begin
        WriteLine(OutStream, '      <Ntry>');
        WriteLine(OutStream, '        <Amt Ccy="' + Currency + '">' + GetAmountText(Amount) + '</Amt>');
        if Creditor then
            WriteLine(OutStream, '        <CdtDbtInd>CRDT</CdtDbtInd>')
        else
            WriteLine(OutStream, '        <CdtDbtInd>DBIT</CdtDbtInd>');
        WriteLine(OutStream, '        <Sts>BOOK</Sts>');
        WriteDtForBookgValItems(OutStream, 'BookgDt');
        WriteDtForBookgValItems(OutStream, 'ValDt');
        WriteLine(OutStream, '        <NtryDtls>');
    end;

    local procedure WriteCAMTPmtFooter(OutStream: OutStream)
    begin
        WriteLine(OutStream, '        </NtryDtls>');
        WriteLine(OutStream, '      </Ntry>');
    end;

    local procedure WriteCAMTInvoice(OutStream: OutStream; AcctSvcrRef: Text; Currency: Text; Amount: Decimal; Name: Text; RefTxt: Text)
    begin
        WriteLine(OutStream, '          <TxDtls>');
        WriteLine(OutStream, '            <Refs>');
        WriteLine(OutStream, '              <AcctSvcrRef>' + AcctSvcrRef + '</AcctSvcrRef>');
        WriteLine(OutStream, '            </Refs>');
        WriteLine(OutStream, '            <Amt Ccy="' + Currency + '">' + GetAmountText(Amount) + '</Amt>');
        WriteLine(OutStream, '            <CdtDbtInd>CRDT</CdtDbtInd>');
        WriteNtryDtlsRltdPtiesDbtrName(OutStream, Name);
        WriteLine(OutStream, '            <RmtInf>');
        WriteNtryDtlsRmtInfStrd(OutStream, RefTxt);
        WriteLine(OutStream, '            </RmtInf>');
        WriteLine(OutStream, '          </TxDtls>');
    end;

    local procedure WriteCAMT054PmtWithOneInv(OutStream: OutStream; PmtCurrency: Text; PmtAmount: Decimal; InvCurrency: Text; InvAmount: Decimal; InvDbtrName: Text; InvRefTxt: Text)
    begin
        WriteCAMTPmtHeader(OutStream, PmtCurrency, PmtAmount, true);
        WriteCAMTInvoice(OutStream, 'TEST', InvCurrency, InvAmount, InvDbtrName, InvRefTxt);
        WriteCAMTPmtFooter(OutStream);
    end;

    local procedure WriteCAMT054PmtWithTwoInv(OutStream: OutStream; PmtCurrency: Text; PmtAmount: Decimal; InvCurrency: array[2] of Text; InvAmount: array[2] of Decimal; InvDbtrName: array[2] of Text; InvRefTxt: array[2] of Text)
    var
        i: Integer;
    begin
        WriteCAMTPmtHeader(OutStream, PmtCurrency, PmtAmount, true);
        for i := 1 to ArrayLen(InvCurrency) do
            WriteCAMTInvoice(OutStream, 'TEST', InvCurrency[i], InvAmount[i], InvDbtrName[i], InvRefTxt[i]);
        WriteCAMTPmtFooter(OutStream);
    end;

    local procedure WriteCAMTNamespace(OutStream: OutStream; NamespaceTxt: Text; XSDName: Text)
    begin
        WriteLine(OutStream, '<?xml version="1.0" encoding="UTF-8"?>');
        WriteLine(OutStream,
          '<Document xsi:schemaLocation="' + NamespaceTxt + ' ' + XSDName + '" xmlns="' + NamespaceTxt +
          '" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">');
    end;

    local procedure WriteCAMTGrpHdr(OutStream: OutStream)
    begin
        WriteLine(OutStream, '    <GrpHdr>');
        WriteLine(OutStream, '      <MsgId>MSGID-01</MsgId>');
        WriteLine(OutStream, '      <CreDtTm>' + GetDateTime() + '</CreDtTm>');
        WriteLine(OutStream, '    </GrpHdr>');
    end;

    local procedure WriteDtForBookgValItems(OutStream: OutStream; NodeName: Text)
    begin
        WriteLine(OutStream, '        <' + NodeName + '>');
        WriteLine(OutStream, '          <Dt>' + GetDate() + '</Dt>');
        WriteLine(OutStream, '        </' + NodeName + '>');
    end;

    local procedure WriteNtryDtlsRmtInfStrd(OutStream: OutStream; RefTxt: Text)
    begin
        WriteLine(OutStream, '              <Strd>');
        WriteLine(OutStream, '                <CdtrRefInf>');
        WriteLine(OutStream, '                  <Ref>' + RefTxt + '</Ref>');
        WriteLine(OutStream, '                </CdtrRefInf>');
        WriteLine(OutStream, '              </Strd>');
    end;

    local procedure WriteNtryDtlsEndToEndID(OutStream: OutStream)
    begin
        WriteLine(OutStream, '<Refs>');
        WriteLine(OutStream, '<EndToEndId>ENDTOENDID-001</EndToEndId>');
        WriteLine(OutStream, '<AcctSvcrRef>P001.01.00.02-110718163809-01</AcctSvcrRef>');
        WriteLine(OutStream, '</Refs>');
    end;

    local procedure WriteNtryDtlsRltdPtiesCdtr(OutStream: OutStream)
    begin
        WriteLine(OutStream, '<RltdPties>');
        WriteLine(OutStream, '<Cdtr>');
        WriteLine(OutStream, '<Nm>Robert Schneider SA</Nm>');
        WriteLine(OutStream, '</Cdtr>');
        WriteLine(OutStream, '</RltdPties>');
    end;

    local procedure WriteNtryDtlsRltdPtiesDbtr(OutStream: OutStream)
    begin
        WriteLine(OutStream, '<RltdPties>');
        WriteLine(OutStream, '<Dbtr>');
        WriteLine(OutStream, '<Nm>Pia Rutschmann</Nm>');
        WriteLine(OutStream, '<PstlAdr>');
        WriteNtryDtlsRltdPtiesDbtrDetails(OutStream);
        WriteLine(OutStream, '</PstlAdr>');
        WriteLine(OutStream, '</Dbtr>');
        WriteLine(OutStream, '</RltdPties>');
    end;

    local procedure WriteNtryDtlsRltdPtiesDbtrName(OutStream: OutStream; Name: Text)
    begin
        WriteLine(OutStream, '            <RltdPties>');
        WriteLine(OutStream, '              <Dbtr>');
        WriteLine(OutStream, '                <Nm>' + Name + '</Nm>');
        WriteLine(OutStream, '              </Dbtr>');
        WriteLine(OutStream, '            </RltdPties>');
    end;

    local procedure WriteNtryDtlsRltdPtiesDbtrDetails(OutStream: OutStream)
    begin
        WriteLine(OutStream, '<StrtNm>Marktgasse</StrtNm>');
        WriteLine(OutStream, '<BldgNb>28</BldgNb>');
        WriteLine(OutStream, '<PstCd>9400</PstCd>');
        WriteLine(OutStream, '<TwnNm>Rorschach</TwnNm>');
    end;

    local procedure WriteLine(OutStream: OutStream; Text: Text)
    begin
        OutStream.WriteText(Text);
        OutStream.WriteText();
    end;

    local procedure WriteCAMTFile054_OnePmtOneInv(OutStream: OutStream; PmtCurrency: Text; PmtAmount: Decimal; InvCurrency: Text; InvAmount: Decimal; InvDbtrName: Text; InvRefTxt: Text)
    var
        HeaderName: Text;
        StatementName: Text;
    begin
        HeaderName := 'BkToCstmrDbtCdtNtfctn';
        StatementName := 'Ntfctn';
        WriteCAMTHeader(OutStream, GetNamespace054(), 'camt.054.001.04.xsd', HeaderName, StatementName);
        WriteCAMT054PmtWithOneInv(OutStream, PmtCurrency, PmtAmount, InvCurrency, InvAmount, InvDbtrName, InvRefTxt);
        WriteCAMTFooter(OutStream, HeaderName, StatementName);
    end;

    local procedure WriteCAMTFile054_OnePmtOneInvExtraSpaces(OutStream: OutStream; PmtCurrency: Text; PmtAmount: Decimal; InvCurrency: Text; InvAmount: Decimal; InvDbtrName: Text; InvRefTxt: Text)
    var
        HeaderName: Text;
        StatementName: Text;
    begin
        HeaderName := 'BkToCstmrDbtCdtNtfctn';
        StatementName := 'Ntfctn';
        WriteCAMTHeaderWithExtraSpaces(OutStream, GetNamespace054(), 'camt.054.001.04.xsd', HeaderName, StatementName);
        WriteCAMT054PmtWithOneInv(OutStream, PmtCurrency, PmtAmount, InvCurrency, InvAmount, InvDbtrName, InvRefTxt);
        WriteCAMTFooterWithExtraSpaces(OutStream, HeaderName, StatementName);
    end;

    local procedure WriteCAMTFile054_OnePmtTwoInv(OutStream: OutStream; PmtCurrency: Text; PmtAmount: Decimal; InvCurrency: array[2] of Text; InvAmount: array[2] of Decimal; InvDbtrName: array[2] of Text; InvRefTxt: array[2] of Text)
    var
        HeaderName: Text;
        StatementName: Text;
    begin
        HeaderName := 'BkToCstmrDbtCdtNtfctn';
        StatementName := 'Ntfctn';
        WriteCAMTHeader(OutStream, GetNamespace054(), 'camt.054.001.04.xsd', HeaderName, StatementName);
        WriteCAMT054PmtWithTwoInv(OutStream, PmtCurrency, PmtAmount, InvCurrency, InvAmount, InvDbtrName, InvRefTxt);
        WriteCAMTFooter(OutStream, HeaderName, StatementName);
    end;

    local procedure WriteCAMTFile054_TwoPmtOneInv(OutStream: OutStream; PmtCurrency: array[2] of Text; PmtAmount: array[2] of Decimal; InvCurrency: array[2] of Text; InvAmount: array[2] of Decimal; InvDbtrName: array[2] of Text; InvRefTxt: array[2] of Text)
    var
        HeaderName: Text;
        StatementName: Text;
        i: Integer;
    begin
        HeaderName := 'BkToCstmrDbtCdtNtfctn';
        StatementName := 'Ntfctn';
        WriteCAMTHeader(OutStream, GetNamespace054(), 'camt.054.001.04.xsd', HeaderName, StatementName);
        for i := 1 to ArrayLen(PmtCurrency) do
            WriteCAMT054PmtWithOneInv(OutStream, PmtCurrency[i], PmtAmount[i], InvCurrency[i], InvAmount[i], InvDbtrName[i], InvRefTxt[i]);
        WriteCAMTFooter(OutStream, HeaderName, StatementName);
    end;

    local procedure WriteCAMTFile054_TwoPmtTwoInv(OutStream: OutStream; PmtCurrency: array[2] of Text; PmtAmount: array[2] of Decimal; InvCurrency: array[4] of Text; InvAmount: array[4] of Decimal; InvDbtrName: array[4] of Text; InvRefTxt: array[4] of Text)
    var
        HeaderName: Text;
        StatementName: Text;
        TempInvCurrency: array[2] of Text;
        TempInvAmount: array[2] of Decimal;
        TempInvDbtrName: array[2] of Text;
        TempInvRefTxt: array[2] of Text;
    begin
        HeaderName := 'BkToCstmrDbtCdtNtfctn';
        StatementName := 'Ntfctn';
        WriteCAMTHeader(OutStream, GetNamespace054(), 'camt.054.001.04.xsd', HeaderName, StatementName);
        Copy4DimBufTo2DimBuf(TempInvCurrency, TempInvAmount, TempInvDbtrName, TempInvRefTxt, InvCurrency, InvAmount, InvDbtrName, InvRefTxt, 0);
        WriteCAMT054PmtWithTwoInv(OutStream, PmtCurrency[1], PmtAmount[1], TempInvCurrency, TempInvAmount, TempInvDbtrName, TempInvRefTxt);
        Copy4DimBufTo2DimBuf(TempInvCurrency, TempInvAmount, TempInvDbtrName, TempInvRefTxt, InvCurrency, InvAmount, InvDbtrName, InvRefTxt, 2);
        WriteCAMT054PmtWithTwoInv(OutStream, PmtCurrency[2], PmtAmount[2], TempInvCurrency, TempInvAmount, TempInvDbtrName, TempInvRefTxt);
        WriteCAMTFooter(OutStream, HeaderName, StatementName);
    end;

    local procedure SetupWriteCAMTFile05302()
    var
        OutStream: OutStream;
    begin
        Clear(TempBlobGlobal);
        TempBlobGlobal.CreateOutStream(OutStream, TEXTENCODING::UTF8);
        WriteCAMTFile05302(OutStream);
    end;

    local procedure SetupWriteCAMTFile05304()
    var
        OutStream: OutStream;
    begin
        Clear(TempBlobGlobal);
        TempBlobGlobal.CreateOutStream(OutStream, TEXTENCODING::UTF8);
        WriteCAMTFile05304(OutStream);
    end;

    local procedure SetupWriteCAMTFile054()
    var
        OutStream: OutStream;
    begin
        Clear(TempBlobGlobal);
        TempBlobGlobal.CreateOutStream(OutStream, TEXTENCODING::UTF8);
        WriteCAMTFile054(OutStream);
    end;

    local procedure SetupBankAccWithBankReconciliation(var BankAccount: Record "Bank Account"; var BankAccReconciliation: Record "Bank Acc. Reconciliation"; var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; DataExchDefCode: Code[20])
    begin
        CreateBankAccWithBankStatementSetup(BankAccount, DataExchDefCode);
        LibraryERM.CreateBankAccReconciliation(BankAccReconciliation, BankAccount."No.",
          BankAccReconciliation."Statement Type"::"Bank Reconciliation");
        CreateBankAccReconTemplateWithFilter(BankAccReconciliationLine, BankAccReconciliation);
    end;

    local procedure SetupBankAndWriteCAMTFile054_OnePmtOneInv(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; PmtCurrency: Text; PmtAmount: Decimal; InvCurrency: Text; InvAmount: Decimal; InvDbtrName: Text; InvRefTxt: Text)
    var
        BankAccount: Record "Bank Account";
        OutStream: OutStream;
    begin
        Clear(TempBlobGlobal);
        TempBlobGlobal.CreateOutStream(OutStream, TEXTENCODING::UTF8);
        WriteCAMTFile054_OnePmtOneInv(OutStream, PmtCurrency, PmtAmount, InvCurrency, InvAmount, InvDbtrName, InvRefTxt);
        SetupBankAccWithBankReconciliation(BankAccount, BankAccReconciliation, BankAccReconciliationLine, GetCAMT054DataExch());
    end;

    local procedure SetupBankAndWriteCAMTFile054_OnePmtOneInv_ExtraSpaces(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; PmtCurrency: Text; PmtAmount: Decimal; InvCurrency: Text; InvAmount: Decimal; InvDbtrName: Text; InvRefTxt: Text)
    var
        BankAccount: Record "Bank Account";
        OutStream: OutStream;
    begin
        Clear(TempBlobGlobal);
        TempBlobGlobal.CreateOutStream(OutStream, TEXTENCODING::UTF8);
        WriteCAMTFile054_OnePmtOneInvExtraSpaces(OutStream, PmtCurrency, PmtAmount, InvCurrency, InvAmount, InvDbtrName, InvRefTxt);
        SetupBankAccWithBankReconciliation(BankAccount, BankAccReconciliation, BankAccReconciliationLine, GetCAMT054DataExch());
    end;

    local procedure SetupBankAndWriteCAMTFile054_OnePmtTwoInv(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; PmtCurrency: Text; PmtAmount: Decimal; InvCurrency: array[2] of Text; InvAmount: array[2] of Decimal; InvDbtrName: array[2] of Text; InvRefTxt: array[2] of Text)
    var
        BankAccount: Record "Bank Account";
        OutStream: OutStream;
    begin
        Clear(TempBlobGlobal);
        TempBlobGlobal.CreateOutStream(OutStream, TEXTENCODING::UTF8);
        WriteCAMTFile054_OnePmtTwoInv(OutStream, PmtCurrency, PmtAmount, InvCurrency, InvAmount, InvDbtrName, InvRefTxt);
        SetupBankAccWithBankReconciliation(BankAccount, BankAccReconciliation, BankAccReconciliationLine, GetCAMT054DataExch());
    end;

    local procedure SetupBankAndWriteCAMTFile054_TwoPmtOneInv(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; PmtCurrency: array[2] of Text; PmtAmount: array[2] of Decimal; InvCurrency: array[2] of Text; InvAmount: array[2] of Decimal; InvDbtrName: array[2] of Text; InvRefTxt: array[2] of Text)
    var
        BankAccount: Record "Bank Account";
        OutStream: OutStream;
    begin
        Clear(TempBlobGlobal);
        TempBlobGlobal.CreateOutStream(OutStream, TEXTENCODING::UTF8);
        WriteCAMTFile054_TwoPmtOneInv(OutStream, PmtCurrency, PmtAmount, InvCurrency, InvAmount, InvDbtrName, InvRefTxt);
        SetupBankAccWithBankReconciliation(BankAccount, BankAccReconciliation, BankAccReconciliationLine, GetCAMT054DataExch());
    end;

    local procedure SetupBankAndWriteCAMTFile054_TwoPmtTwoInv(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; PmtCurrency: array[2] of Text; PmtAmount: array[2] of Decimal; InvCurrency: array[4] of Text; InvAmount: array[4] of Decimal; InvDbtrName: array[4] of Text; InvRefTxt: array[4] of Text)
    var
        BankAccount: Record "Bank Account";
        OutStream: OutStream;
    begin
        Clear(TempBlobGlobal);
        TempBlobGlobal.CreateOutStream(OutStream, TEXTENCODING::UTF8);
        WriteCAMTFile054_TwoPmtTwoInv(OutStream, PmtCurrency, PmtAmount, InvCurrency, InvAmount, InvDbtrName, InvRefTxt);
        SetupBankAccWithBankReconciliation(BankAccount, BankAccReconciliation, BankAccReconciliationLine, GetCAMT054DataExch());
    end;

    local procedure CreateBankAccReconTemplateWithFilter(var BankAccReconciliationLineTemplate: Record "Bank Acc. Reconciliation Line"; BankAccReconciliation: Record "Bank Acc. Reconciliation")
    begin
        LibraryERM.CreateBankAccReconciliationLn(BankAccReconciliationLineTemplate, BankAccReconciliation);

        BankAccReconciliationLineTemplate.Delete(true); // The template needs to removed to not skew when comparing testresults.
        BankAccReconciliationLineTemplate.SetRange("Statement Type", BankAccReconciliation."Statement Type");
        BankAccReconciliationLineTemplate.SetRange("Bank Account No.", BankAccReconciliation."Bank Account No.");
        BankAccReconciliationLineTemplate.SetRange("Statement No.", BankAccReconciliation."Statement No.");
    end;

    local procedure CreateBankAccWithBankStatementSetup(var BankAccount: Record "Bank Account"; DataExchDefCode: Code[20])
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        BankExportImportSetup.Init();
        BankExportImportSetup.Code :=
          LibraryUtility.GenerateRandomCode(BankExportImportSetup.FieldNo(Code), DATABASE::"Bank Export/Import Setup");
        BankExportImportSetup.Direction := BankExportImportSetup.Direction::Import;
        BankExportImportSetup."Data Exch. Def. Code" := DataExchDefCode;
        BankExportImportSetup.Insert();

        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Last Statement No.",
          LibraryUtility.GenerateRandomCode(BankAccount.FieldNo("Last Statement No."), DATABASE::"Bank Account"));
        BankAccount."Bank Statement Import Format" := BankExportImportSetup.Code;
        BankAccount.IBAN := GetIBANTxt();
        BankAccount."Bank Account No." := LibraryUtility.GenerateGUID();
        BankAccount.Modify(true);
    end;

    local procedure CreateBankExportImportSetup(DataExchDefCode: Code[20]; ProcessingCodeunitId: Integer): Code[20]
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        BankExportImportSetup.Init();
        BankExportImportSetup.Code :=
          LibraryUtility.GenerateRandomCode(BankExportImportSetup.FieldNo(Code), DATABASE::"Bank Export/Import Setup");
        BankExportImportSetup.Direction := BankExportImportSetup.Direction::Import;
        BankExportImportSetup."Data Exch. Def. Code" := DataExchDefCode;
        BankExportImportSetup."Processing Codeunit ID" := ProcessingCodeunitId;
        BankExportImportSetup.Insert();
        exit(BankExportImportSetup.Code);
    end;

    local procedure CreateBankReconciliation(var BankAccReconciliation: Record "Bank Acc. Reconciliation")
    var
        BankAccount: Record "Bank Account";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        LibraryERM.CreateBankAccReconciliation(
          BankAccReconciliation, BankAccount."No.",
          BankAccReconciliation."Statement Type"::"Payment Application");
    end;

    local procedure CreateBankReconciliationLine(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; Amount: Decimal; TransactionText: Text[140]; AdditionalTransactionInfo: Text[100]; ESRReferenceNo: Text[100])
    begin
        LibraryERM.CreateBankAccReconciliationLn(BankAccReconciliationLine, BankAccReconciliation);
        BankAccReconciliationLine.Validate("Transaction Text", TransactionText);
        BankAccReconciliationLine.Validate("Additional Transaction Info", AdditionalTransactionInfo);
        BankAccReconciliationLine.Validate("ESR Reference No.", ESRReferenceNo);
        BankAccReconciliationLine.Validate("Transaction Date", WorkDate());
        BankAccReconciliationLine.Validate("Statement Amount", Amount);
        BankAccReconciliationLine.Modify(true);
    end;

    local procedure CreateCustomerWithAddress(var Customer: Record Customer; Name: Text[50]; Address: Text[50]; Address2: Text[50]; City: Text[30])
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Name := Name;
        Customer.Address := Address;
        Customer."Address 2" := Address2;
        Customer.City := City;
        Customer.Modify();
    end;

    local procedure CreateAndPostSalesInvoice(CustomerNo: Code[20]; DocNo: Code[20]; ExtDocNo: Code[20]; Amount: Decimal): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Customer, CustomerNo, Amount);

        GenJournalLine."Document No." := DocNo;
        GenJournalLine."External Document No." := ExtDocNo;
        GenJournalLine.Modify();

        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine."Document No.");
    end;

    local procedure Copy2DimBufTo4DimBuf(var TargetCurrency: array[4] of Text; var TargetAmount: array[4] of Decimal; var TargetInvDbtrName: array[4] of Text; var TargetInvRefTxt: array[4] of Text; SourceCurrency: array[2] of Text; SourceTargetAmount: array[2] of Decimal; SourceInvDbtrName: array[2] of Text; SourceInvRefTxt: array[2] of Text; Offset: Integer)
    var
        i: Integer;
    begin
        for i := 1 to ArrayLen(SourceCurrency) do begin
            TargetCurrency[i + Offset] := SourceCurrency[i];
            TargetAmount[i + Offset] := SourceTargetAmount[i];
            TargetInvDbtrName[i + Offset] := SourceInvDbtrName[i];
            TargetInvRefTxt[i + Offset] := SourceInvRefTxt[i];
        end;
    end;

    local procedure Copy4DimBufTo2DimBuf(var TargetCurrency: array[2] of Text; var TargetAmount: array[2] of Decimal; var TargetInvDbtrName: array[2] of Text; var TargetInvRefTxt: array[2] of Text; SourceCurrency: array[4] of Text; SourceTargetAmount: array[4] of Decimal; SourceInvDbtrName: array[4] of Text; SourceInvRefTxt: array[4] of Text; Offset: Integer)
    var
        i: Integer;
    begin
        for i := 1 to ArrayLen(TargetCurrency) do begin
            TargetCurrency[i] := SourceCurrency[i + Offset];
            TargetAmount[i] := SourceTargetAmount[i + Offset];
            TargetInvDbtrName[i] := SourceInvDbtrName[i + Offset];
            TargetInvRefTxt[i] := SourceInvRefTxt[i + Offset];
        end;
    end;

    local procedure FilterDataExchField(var DataExchField: Record "Data Exch. Field"; BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    begin
        DataExchField.SetRange("Data Exch. No.", BankAccReconciliationLine."Data Exch. Entry No.");
        DataExchField.SetRange("Line No.", BankAccReconciliationLine."Data Exch. Line No.");
    end;

    local procedure GenerateNumericDocNo(): Text[10]
    begin
        exit(ConvertStr(LibraryUtility.GenerateGUID(), 'GU', Format(LibraryRandom.RandIntInRange(10, 99))));
    end;

    local procedure InsertDefaultMatchingRules()
    var
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
    begin
        BankPmtApplRule.DeleteAll();
        BankPmtApplRule.InsertDefaultMatchingRules();
    end;

    local procedure SetRule(var BankPmtApplRule: Record "Bank Pmt. Appl. Rule"; RelatedPartyMatched: Option; DocNoMatched: Option; AmountInclToleranceMatched: Option)
    begin
        BankPmtApplRule.Init();
        BankPmtApplRule."Related Party Matched" := RelatedPartyMatched;
        BankPmtApplRule."Doc. No./Ext. Doc. No. Matched" := DocNoMatched;
        BankPmtApplRule."Amount Incl. Tolerance Matched" := AmountInclToleranceMatched;
    end;

    local procedure RunMatch(BankAccReconciliation: Record "Bank Acc. Reconciliation"; var TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary; ApplyEntries: Boolean)
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        MatchBankPayments: Codeunit "Match Bank Payments";
    begin
        if ApplyEntries then
            LibraryVariableStorage.Enqueue('are applied');

        BankAccReconciliationLine.SetRange("Statement Type", BankAccReconciliation."Statement Type");
        BankAccReconciliationLine.SetRange("Statement No.", BankAccReconciliation."Statement No.");
        BankAccReconciliationLine.SetRange("Bank Account No.", BankAccReconciliation."Bank Account No.");
        BankAccReconciliationLine.FindFirst();
        MatchBankPayments.SetApplyEntries(ApplyEntries);
        MatchBankPayments.Run(BankAccReconciliationLine);

        MatchBankPayments.GetBankStatementMatchingBuffer(TempBankStatementMatchingBuffer);
    end;

    local procedure VerifyBankAccRecLineWithDataExchField(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; DataExchDefCode: Code[20]; BankAccRecLineCount: Integer; DataExchFieldCount: Integer)
    begin
        Assert.RecordCount(BankAccReconciliationLine, BankAccRecLineCount);
        BankAccReconciliationLine.Find();
        VerifyDefExchField(DataExchDefCode, BankAccReconciliationLine."Data Exch. Entry No.", DataExchFieldCount);
    end;

    local procedure VerifyDefExchField(DataExchDefCode: Code[20]; DataExchEntryNo: Integer; ExpCount: Integer)
    var
        DataExchField: Record "Data Exch. Field";
    begin
        DataExchField.SetRange("Data Exch. Def Code", DataExchDefCode);
        DataExchField.SetRange("Data Exch. No.", DataExchEntryNo);
        Assert.RecordCount(DataExchField, ExpCount);
    end;

    local procedure VerifyGenJnlLineWithDataExchField(GenJournalBatch: Record "Gen. Journal Batch"; GenJnlLineCount: Integer; DataExchFieldCount: Integer)
    var
        GenJournalLine: Record "Gen. Journal Line";
        DataExchField: Record "Data Exch. Field";
    begin
        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        Assert.RecordCount(GenJournalLine, GenJnlLineCount);
        GenJournalLine.FindFirst();
        DataExchField.SetRange("Data Exch. No.", GenJournalLine."Data Exch. Entry No.");
        Assert.RecordCount(DataExchField, DataExchFieldCount);
    end;

    local procedure VerifyImportCAMT054_PmtWithDetails(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; Currency: Text; Amount: Decimal; InvDbtrName: Text; InvRefTxt: Text)
    begin
        BankAccReconciliationLine.TestField("Statement Amount", Amount);
        BankAccReconciliationLine.TestField("Related-Party Name", InvDbtrName);
        BankAccReconciliationLine.TestField("ESR Reference No.", InvRefTxt);
        VerifyImportCAMT054_PmtDetails(BankAccReconciliationLine, Currency, InvRefTxt);
    end;

    local procedure VerifyImportCAMT054_PmtWithTwoDetails(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; Currency: Text; Amount: Decimal; InvDbtrName: array[2] of Text; InvRefTxt: array[2] of Text)
    begin
        BankAccReconciliationLine.TestField("Statement Amount", Amount);
        BankAccReconciliationLine.TestField("Related-Party Name", InvDbtrName[1] + ' ' + InvDbtrName[2]);
        BankAccReconciliationLine.TestField("ESR Reference No.", InvRefTxt[1] + ' ' + InvRefTxt[2]);
        VerifyImportCAMT054_TwoPmtDetails(BankAccReconciliationLine, Currency, InvRefTxt);
    end;

    local procedure VerifyImportCAMT054_PmtDetails(BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; PmtCurrency: Text; InvRef: Text)
    var
        DataExchField: Record "Data Exch. Field";
    begin
        FilterDataExchField(DataExchField, BankAccReconciliationLine);
        VerifyImportCAMT054_PmtCurrency(DataExchField, PmtCurrency);
        VerifyImportCAMT054_InvRef(DataExchField, InvRef);
        Assert.RecordCount(DataExchField, 1);
    end;

    local procedure VerifyImportCAMT054_TwoPmtDetails(BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; PmtCurrency: Text; InvRef: array[2] of Text)
    var
        DataExchField: Record "Data Exch. Field";
    begin
        FilterDataExchField(DataExchField, BankAccReconciliationLine);
        VerifyImportCAMT054_PmtCurrency(DataExchField, PmtCurrency);

        VerifyImportCAMT054_InvRef(DataExchField, InvRef[1]);
        DataExchField.Next();
        DataExchField.TestField(Value, InvRef[2]);
        Assert.RecordCount(DataExchField, 2);
    end;

    local procedure VerifyImportCAMT054_PmtCurrency(var DataExchField: Record "Data Exch. Field"; ExpetedValue: Text)
    begin
        DataExchField.SetRange("Column No.", GetCAMT054DataExchPmtCurrencyColumnNo());
        Assert.RecordCount(DataExchField, 1);
        DataExchField.FindFirst();
        DataExchField.TestField(Value, ExpetedValue);
    end;

    local procedure VerifyImportCAMT054_InvRef(var DataExchField: Record "Data Exch. Field"; ExpetedValue: Text)
    begin
        DataExchField.SetRange("Column No.", GetCAMT054DataExchInvRefColumnNo());
        DataExchField.FindFirst();
        DataExchField.TestField(Value, ExpetedValue);
    end;

    local procedure VerifyImportCAMT054_PmtCount(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; ExpectedCount: Integer)
    begin
        Assert.RecordCount(BankAccReconciliationLine, ExpectedCount);
        BankAccReconciliationLine.FindFirst();
    end;

    local procedure VerifyImportCAMT054_OnePayment(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; Currency: Text; Amount: Decimal; InvDbtrName: Text; InvRefTxt: Text)
    begin
        VerifyImportCAMT054_PmtCount(BankAccReconciliationLine, 1);
        VerifyImportCAMT054_PmtWithDetails(BankAccReconciliationLine, Currency, Amount, InvDbtrName, InvRefTxt);
    end;

    local procedure VerifyImportCAMT054_OnePaymentWithTwoDetails(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; Currency: Text; Amount: Decimal; InvDbtrName: array[2] of Text; InvRefTxt: array[2] of Text)
    begin
        VerifyImportCAMT054_PmtCount(BankAccReconciliationLine, 1);
        VerifyImportCAMT054_PmtWithTwoDetails(BankAccReconciliationLine, Currency, Amount, InvDbtrName, InvRefTxt);
    end;

    local procedure VerifyImportCAMT054_TwoPayments(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; Currency: array[2] of Text; Amount: array[2] of Decimal; InvDbtrName: array[2] of Text; InvRefTxt: array[2] of Text)
    var
        i: Integer;
    begin
        VerifyImportCAMT054_PmtCount(BankAccReconciliationLine, 2);
        for i := 1 to ArrayLen(Currency) do begin
            VerifyImportCAMT054_PmtWithDetails(BankAccReconciliationLine, Currency[i], Amount[i], InvDbtrName[i], InvRefTxt[i]);
            BankAccReconciliationLine.Next();
        end;
    end;

    local procedure VerifyImportCAMT054_FourPayments(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; Currency: array[4] of Text; Amount: array[4] of Decimal; InvDbtrName: array[4] of Text; InvRefTxt: array[4] of Text)
    var
        i: Integer;
    begin
        VerifyImportCAMT054_PmtCount(BankAccReconciliationLine, 4);
        for i := 1 to ArrayLen(Currency) do begin
            VerifyImportCAMT054_PmtWithDetails(BankAccReconciliationLine, Currency[i], Amount[i], InvDbtrName[i], InvRefTxt[i]);
            BankAccReconciliationLine.Next();
        end;
    end;

    local procedure VerifyImportCAMT054_OnePmtWithTwoDtlsAndTwoMorePmts(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; PmtCurrency: array[2] of Text; PmtAmount: array[2] of Decimal; InvCurrency: array[4] of Text; InvAmount: array[4] of Decimal; InvDbtrName: array[4] of Text; InvRefTxt: array[4] of Text)
    var
        TempInvCurrency: array[2] of Text;
        TempInvAmount: array[2] of Decimal;
        TempInvDbtrName: array[2] of Text;
        TempInvRefTxt: array[2] of Text;
        i: Integer;
    begin
        VerifyImportCAMT054_PmtCount(BankAccReconciliationLine, 3);
        Copy4DimBufTo2DimBuf(TempInvCurrency, TempInvAmount, TempInvDbtrName, TempInvRefTxt, InvCurrency, InvAmount, InvDbtrName, InvRefTxt, 0);
        VerifyImportCAMT054_PmtWithTwoDetails(BankAccReconciliationLine, PmtCurrency[1], PmtAmount[1], TempInvDbtrName, TempInvRefTxt);

        Copy4DimBufTo2DimBuf(TempInvCurrency, TempInvAmount, TempInvDbtrName, TempInvRefTxt, InvCurrency, InvAmount, InvDbtrName, InvRefTxt, 2);
        for i := 1 to ArrayLen(TempInvCurrency) do begin
            BankAccReconciliationLine.Next();
            VerifyImportCAMT054_PmtWithDetails(
              BankAccReconciliationLine, TempInvCurrency[i], TempInvAmount[i], TempInvDbtrName[i], TempInvRefTxt[i]);
        end;
    end;

    local procedure VerifyImportCAMT054_TwoPmtsAndPmtWithTwoDtls(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; PmtCurrency: array[2] of Text; PmtAmount: array[2] of Decimal; InvCurrency: array[4] of Text; InvAmount: array[4] of Decimal; InvDbtrName: array[4] of Text; InvRefTxt: array[4] of Text)
    var
        TempInvCurrency: array[2] of Text;
        TempInvAmount: array[2] of Decimal;
        TempInvDbtrName: array[2] of Text;
        TempInvRefTxt: array[2] of Text;
        i: Integer;
    begin
        VerifyImportCAMT054_PmtCount(BankAccReconciliationLine, 3);
        Copy4DimBufTo2DimBuf(TempInvCurrency, TempInvAmount, TempInvDbtrName, TempInvRefTxt, InvCurrency, InvAmount, InvDbtrName, InvRefTxt, 0);
        for i := 1 to ArrayLen(TempInvCurrency) do begin
            VerifyImportCAMT054_PmtWithDetails(
              BankAccReconciliationLine, TempInvCurrency[i], TempInvAmount[i], TempInvDbtrName[i], TempInvRefTxt[i]);
            BankAccReconciliationLine.Next();
        end;

        Copy4DimBufTo2DimBuf(TempInvCurrency, TempInvAmount, TempInvDbtrName, TempInvRefTxt, InvCurrency, InvAmount, InvDbtrName, InvRefTxt, 2);
        VerifyImportCAMT054_PmtWithTwoDetails(BankAccReconciliationLine, PmtCurrency[2], PmtAmount[2], TempInvDbtrName, TempInvRefTxt);
    end;

    local procedure VerifyReconciliation(ExpectedBankPmtApplRule: Record "Bank Pmt. Appl. Rule"; var TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary; StatementLineNo: Integer)
    var
        TempBankPmtApplRule: Record "Bank Pmt. Appl. Rule" temporary;
        Score: Integer;
    begin
        TempBankPmtApplRule.LoadRules();
        Score := TempBankPmtApplRule.GetBestMatchScore(ExpectedBankPmtApplRule);

        TempBankStatementMatchingBuffer.Reset();
        TempBankStatementMatchingBuffer.SetRange("Line No.", StatementLineNo);
        TempBankStatementMatchingBuffer.SetRange(Quality, Score);
        Assert.RecordIsNotEmpty(TempBankStatementMatchingBuffer);

        TempBankStatementMatchingBuffer.SetFilter(Quality, '>%1', Score);
        Assert.RecordIsEmpty(TempBankStatementMatchingBuffer);
    end;

    local procedure VerifyBankPmtApplRuleExists(MatchConfidence: Option; Priority: Integer; RelatedPartyMatched: Option; DocNoMatched: Option; AmountInclToleranceMatched: Option)
    var
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
    begin
        BankPmtApplRule.SetRange("Match Confidence", MatchConfidence);
        BankPmtApplRule.SetRange(Priority, Priority);
        BankPmtApplRule.SetRange("Related Party Matched", RelatedPartyMatched);
        BankPmtApplRule.SetRange("Doc. No./Ext. Doc. No. Matched", DocNoMatched);
        BankPmtApplRule.SetRange("Amount Incl. Tolerance Matched", AmountInclToleranceMatched);
        Assert.RecordIsNotEmpty(BankPmtApplRule);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Read Data Exch. from File", 'OnBeforeFileImport', '', false, false)]
    local procedure OnBeforeFileImport(var TempBlob: Codeunit "Temp Blob"; var FileName: Text)
    begin
        TempBlob := TempBlobGlobal;
        FileName := 'CH_TEST144084_ImportCAMT';
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    var
        ExpectedMsg: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMsg);
        Assert.IsTrue(StrPos(Message, ExpectedMsg) > 0, Message);
    end;
}

