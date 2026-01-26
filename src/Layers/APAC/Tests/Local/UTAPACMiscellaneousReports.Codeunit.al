codeunit 141077 "UT APAC Miscellaneous Reports"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Report]
    end;

    var
        Assert: Codeunit Assert;
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        BankAccountBalanceAtDateCap: Label 'Bank_Account__Balance_at_Date_';
        BankAccountBankBranchNoCap: Label 'BankAccount__Bank_Branch_No__';
        ColumnAmountOneCap: Label 'ColumnAmountText_1_';
        ColumnAmountSixCap: Label 'ColumnAmountText_6_';
        ColumnAmountThreeCap: Label 'ColumnAmountText_3_';
        ColumnAmountTwoCap: Label 'ColumnAmountText_2_';
        CurrentPeriodNetChangeCap: Label 'CurrentPeriodNetChange';
        CurrentYearToDateNetChangeCap: Label 'CurrentYTDNetChange';
        DateFilterTxt: Label '%1..%2';
        GenJournalLineBankAccountNoCap: Label 'Gen__Journal_Line__Bank_Account_No__';
        GenJournalLineCreditAmountCap: Label 'Gen__Journal_Line__Credit_Amount_';
        GenJournalLineDocumentNoCap: Label 'Gen__Journal_Line__Document_No__';
        LastYrCurrPeriodNetChangeCap: Label 'LastYrCurrPeriodNetChange';
        LastYearToDateNetChangeCap: Label 'LastYTDNetChange';
        LibraryReportValidation: Codeunit "Library - Report Validation";
        ReportManagement: Codeunit "Report Management APAC";
        PayToVendorNoCap: Label 'PaytoVendorNo_PurchRcptHeader';
        PayToVendorNoFilter: Label '%1|%2';
        TotalAmountCap: Label 'TotalAmount';
        TotalOneCap: Label 'Total1';
        TotalTwoCap: Label 'Total2';
        LibraryXMLRead: Codeunit "Library - XML Read";

    [Test]
    [HandlerFunctions('BalanceSheetRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecGLAccAmtsInWholeBlankBalanceSheetRpt()
    var
        GLAccount: Record "G/L Account";
        GLAccountNo: Code[20];
        AmountsInWhole: Option " ",Tens,Hundreds,Thousands,"Hundred Thousands",Millions;
        Amount: Decimal;
        BudgetAmount: Decimal;
    begin
        // [FEATURE] [Balance Sheet]
        // [SCENARIO] validate G/L Account - OnAfterGetRecord Trigger of Report - 28024 with Amounts In Whole as Blank and New Page as False.

        // Setup: Create G/L Account. G/L Budget entry and G/L Entry.
        Initialize();
        GLAccountNo := CreateGLAccount(GLAccount."Income/Balance"::"Balance Sheet", false);  // False for New Page.
        BudgetAmount := CreateGLBudgetEntry('', GLAccountNo, '', '', WorkDate());  // Blank used for Budget Name, Global Dimension 1 Code and Global Dimension 2 Code.
        Amount := LibraryRandom.RandDec(100, 2);
        CreateGLEntry(GLAccountNo, '', '', WorkDate(), Amount);  // Blank used for Global Dimension 1 Code and Global Dimension 2 Code.

        // Enqueue Values for BalanceSheetRequestPageHandler.
        EnqueueValuesForRequestPageHandler(GLAccountNo, '', '', AmountsInWhole::" ");  // Blank used for Global Dimension 1 Code and Global Dimension 2 Code.
        LibraryVariableStorage.Enqueue('');  // Blank used for Budget Name.

        // Exercise and Verify.
        RunBalanceSheetReportAndVerifyXmlValues(
          ColumnAmountThreeCap, Format(Amount, 0, '<Precision,2:><Standard Format,0>'),
          Format(BudgetAmount, 0, '<Precision,2:><Standard Format,0>'),
          Format(Round((BudgetAmount - Amount) / BudgetAmount * 100, 1)));  // Value 0 used for Length and 1 used for Precision as it is given in Report for calculation.
    end;

    [Test]
    [HandlerFunctions('BalanceSheetRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecGLAccBudgetBalanceSheetRpt()
    begin
        // [FEATURE] [Balance Sheet]
        // [SCENARIO] validate G/L Account - OnAfterGetRecord Trigger of Report - 28024 with Budget.
        OnAfterGetRecordGLAccountBalanceSheetReport('', '');  // Blank used for Global Dimension 1 Code and Global Dimension 2 Code.
    end;

    [Test]
    [HandlerFunctions('BalanceSheetRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecGLAccBudgetAndDimBalanceSheetRpt()
    begin
        // [FEATURE] [Balance Sheet]
        // [SCENARIO] validate G/L Account - OnAfterGetRecord Trigger of Report - 28024 with Budget and Dimensions.
        OnAfterGetRecordGLAccountBalanceSheetReport(LibraryUTUtility.GetNewCode(), LibraryUTUtility.GetNewCode());
    end;

    local procedure OnAfterGetRecordGLAccountBalanceSheetReport(GlobalDimensionOneCode: Code[20]; GlobalDimensionTwoCode: Code[20])
    var
        GLAccount: Record "G/L Account";
        BudgetName: Code[10];
        GLAccountNo: Code[20];
        AmountsInWhole: Option " ",Tens;
        Amount: Decimal;
        BudgetAmount: Decimal;
        BudgetAmount2: Decimal;
    begin
        // Setup: Create G/L Account. Create G/L Budget entries and G/L Entries.
        Initialize();
        BudgetName := LibraryUTUtility.GetNewCode10();
        GLAccountNo := CreateGLAccount(GLAccount."Income/Balance"::"Balance Sheet", true);  // True for New Page.
        BudgetAmount := CreateGLBudgetEntry(BudgetName, GLAccountNo, GlobalDimensionOneCode, GlobalDimensionTwoCode, WorkDate());
        Amount := LibraryRandom.RandDec(100, 2);
        CreateGLEntry(GLAccountNo, GlobalDimensionOneCode, GlobalDimensionTwoCode, WorkDate(), Amount);
        BudgetAmount2 :=
          CreateGLBudgetEntry(
            BudgetName, GLAccountNo, GlobalDimensionOneCode, GlobalDimensionTwoCode,
            CalcDate('<' + Format(-LibraryRandom.RandInt(5)) + 'Y>', WorkDate()));  // Using a date earlier than WORKDATE as EntryDate.
        CreateGLEntry(
          GLAccountNo, GlobalDimensionOneCode, GlobalDimensionTwoCode,
          CalcDate('<' + Format(-LibraryRandom.RandInt(5)) + 'Y>', WorkDate()), Amount);  // Using a date earlier than WORKDATE as EntryDate.

        // Enqueue Values for BalanceSheetRequestPageHandler.
        EnqueueValuesForRequestPageHandler(GLAccountNo, GlobalDimensionOneCode, GlobalDimensionTwoCode, AmountsInWhole::Tens);
        LibraryVariableStorage.Enqueue(BudgetName);

        // Exercise and Verify.
        RunBalanceSheetReportAndVerifyXmlValues(
          ColumnAmountSixCap,
          Format(
            ReportManagement.RoundAmount(Amount + Amount, AmountsInWhole::Tens), 0, '<Precision,1:><Standard Format,0>'),
          Format(ReportManagement.RoundAmount(BudgetAmount + BudgetAmount2, AmountsInWhole::Tens), 0, '<Precision,1:><Standard Format,0>'),
          Format(Round((BudgetAmount2 - Amount) / BudgetAmount2 * 100, 1)));  // Value 0 used for Length and 1 used for Precision as it is given in Report for calculation.
    end;

    [Test]
    [HandlerFunctions('IncomeStatementRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecGLAccAmtsInWholeBlankIncomeStmtRpt()
    var
        AmountsInWhole: Option " ",Tens,Hundreds,Thousands,"Hundred Thousands",Millions;
        Amount: Decimal;
    begin
        // [FEATURE] [Income Statement]
        // [SCENARIO 280565] Validate G/L Account - OnAfterGetRecord Trigger of Report - 28025 with Amounts In Whole as Blank and New Page as False and HideEmptyLines as True.
        Initialize();
        Amount := LibraryRandom.RandDec(100, 2);
        OnAfterGetRecordGLAccountIncomeStatementReport(AmountsInWhole::" ", '', '', false, false, Amount, Amount, true);  // Blank used for Global Dimension 1 Code and Global Dimension 2 Code. False for New Page and ShowAmountsInAddReportingCurrency.
    end;

    [Test]
    [HandlerFunctions('IncomeStatementRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecGLAccDimensionsIncomeStmtRpt()
    var
        AmountsInWhole: Option " ",Tens,Hundreds,Thousands,"Hundred Thousands",Millions;
        Amount: Decimal;
    begin
        // [FEATURE] [Income Statement]
        // [SCENARIO 280565] Validate G/L Account - OnAfterGetRecord Trigger of Report - 28025 with Dimensions and HideEmptyLines as True.
        Initialize();
        Amount := LibraryRandom.RandDec(100, 2);
        OnAfterGetRecordGLAccountIncomeStatementReport(
          AmountsInWhole::" ", LibraryUTUtility.GetNewCode(), LibraryUTUtility.GetNewCode(), false, false, Amount, Amount, true);  // False for New Page and ShowAmountsInAddReportingCurrency.
    end;

    [Test]
    [HandlerFunctions('IncomeStatementRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecGLAccShowAmtsInAddRptCurrIncomeStmtRpt()
    var
        AmountsInWhole: Option " ",Tens,Hundreds,Thousands,"Hundred Thousands",Millions;
        Amount: Decimal;
    begin
        // [FEATURE] [Income Statement]
        // [SCENARIO 280565] Validate G/L Account - OnAfterGetRecord Trigger of Report - 28025 with Dimensions and ShowAmountsInAddReportingCurrency and HideEmptyLines as False.
        Initialize();
        Amount := LibraryRandom.RandDec(100, 2);
        OnAfterGetRecordGLAccountIncomeStatementReport(
          AmountsInWhole::Tens, LibraryUTUtility.GetNewCode(), LibraryUTUtility.GetNewCode(), true, true, Amount,
          ReportManagement.RoundAmount(Amount, AmountsInWhole::Tens), false);  // True for New Page and ShowAmountsInAddReportingCurrency.
    end;

    local procedure OnAfterGetRecordGLAccountIncomeStatementReport(AmountsInWhole: Option; GlobalDimensionOneCode: Code[20]; GlobalDimensionTwoCode: Code[20]; NewPage: Boolean; ShowAmountsInAddReportingCurrency: Boolean; Amount: Decimal; ExpectedAmount: Decimal; HideEmptyLines: Boolean)
    var
        GLAccount: Record "G/L Account";
        GLAccountNo: Code[20];
    begin
        // Setup: Create G/L Account and G/L Entries.
        GLAccountNo := CreateGLAccount(GLAccount."Income/Balance"::"Income Statement", NewPage);
        CreateGLEntry(GLAccountNo, GlobalDimensionOneCode, GlobalDimensionTwoCode, WorkDate(), Amount);  // True for New Page.
        CreateGLEntry(GLAccountNo, GlobalDimensionOneCode, GlobalDimensionTwoCode, CalcDate('<-1Y>', WorkDate()), Amount);  // Using 1Y for Last Year as it is explicitly used in Report.

        // Enqueue Values for IncomeStatementRequestPageHandler.
        EnqueueValuesForRequestPageHandler(GLAccountNo, GlobalDimensionOneCode, GlobalDimensionTwoCode, AmountsInWhole);
        LibraryVariableStorage.Enqueue(HideEmptyLines);
        LibraryVariableStorage.Enqueue(ShowAmountsInAddReportingCurrency);

        // Exercise and Verify.
        RunIncomeStatementReportAndVerifyXmlValues(ExpectedAmount, HideEmptyLines);
    end;

    [Test]
    [HandlerFunctions('BankAccountReconciliationRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecBankAccLedgEntryOneBankAccReconRpt()
    var
        BankAccountNo: Code[20];
        Amount: Decimal;
        Amount2: Decimal;
    begin
        // [FEATURE] [Bank Account Reconciliation]
        // [SCENARIO] validate Bank Account Ledger Entry1 - OnAfterGetRecord Trigger of Report - 28021.

        // Setup: Create Bank Account Ledger entries for Customer and Vendor.
        Initialize();
        BankAccountNo := CreateBankAccount();
        Amount := -LibraryRandom.RandDec(10, 2);
        Amount2 := LibraryRandom.RandDecInRange(10, 50, 2);
        CreateBankAccLedgerEntryForCustAndVend(BankAccountNo, Amount, Amount2);
        LibraryVariableStorage.Enqueue(BankAccountNo);  // Enqueue value for BankAccountReconciliationRequestPageHandler.

        // Exercise and Verify.
        RunBankAccReconReportAndVerifyXmlValues(Abs(Amount), Amount2);
    end;

    [Test]
    [HandlerFunctions('BankAccountReconciliationRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecBankAccLedgEntryTwoBankAccReconRpt()
    var
        BankAccountNo: Code[20];
        Amount: Decimal;
        Amount2: Decimal;
    begin
        // [FEATURE] [Bank Account Reconciliation]
        // [SCENARIO] validate Bank Account Ledger Entry2 - OnAfterGetRecord Trigger of Report - 28021 with multiple Customer and Vendor.

        // Setup: Create Bank Account Ledger entries for multiple Customer and Vendor.
        Initialize();
        BankAccountNo := CreateBankAccount();
        Amount := -LibraryRandom.RandDec(10, 2);
        Amount2 := LibraryRandom.RandDecInRange(10, 50, 2);
        CreateBankAccLedgerEntryForCustAndVend(BankAccountNo, Amount, Amount2);
        CreateBankAccLedgerEntryForCustAndVend(BankAccountNo, Amount, Amount2);
        LibraryVariableStorage.Enqueue(BankAccountNo);  // Enqueue value for BankAccountReconciliationRequestPageHandler.

        // Exercise and Verify.
        RunBankAccReconReportAndVerifyXmlValues(Abs(Amount) + Abs(Amount), Amount2 + Amount2);
    end;

    [Test]
    [HandlerFunctions('DepositSlipRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecGenJnlLineSingleCustDepositSlipRpt()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Deposit Slip]
        // [SCENARIO] validate Gen. Journal Line - OnAfterGetRecord Trigger of Report - 28023 with single Customer.

        // Setup: Create General Journal line.
        Initialize();
        CreateGeneralJournalBatch(GenJournalBatch);
        CreateGeneralJournalLine(GenJournalLine, GenJournalBatch, LibraryRandom.RandInt(100));  // Random value used for Line No.

        // Enqueue values for DepositSlipRequestPageHandler.
        LibraryVariableStorage.Enqueue(GenJournalBatch."Journal Template Name");
        LibraryVariableStorage.Enqueue(GenJournalBatch.Name);

        // Exercise and Verify.
        RunDepositSlipReportAndVerifyXmlValues(
          GenJournalLine."Bank Account No.", GenJournalLineDocumentNoCap, BankAccountBankBranchNoCap, GenJournalLine."Credit Amount",
          GenJournalLine."Document No.", GenJournalLine."Bank Branch No.");
    end;

    [Test]
    [HandlerFunctions('DepositSlipRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecGenJnlLineMultipleCustDepositSlipRpt()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Deposit Slip]
        // [SCENARIO] validate Gen. Journal Line - OnAfterGetRecord Trigger of Report - 28023 with multiple Customer.

        // Setup: Create two General Journal lines for different Customers.
        Initialize();
        CreateGeneralJournalBatch(GenJournalBatch);
        CreateGeneralJournalLine(GenJournalLine, GenJournalBatch, LibraryRandom.RandInt(100));  // Random value used for Line No.
        CreateGeneralJournalLine(GenJournalLine2, GenJournalBatch, GenJournalLine."Line No." + LibraryRandom.RandInt(100));  // Random value added for Different Line No.

        // Enqueue values for DepositSlipRequestPageHandler.
        LibraryVariableStorage.Enqueue(GenJournalBatch."Journal Template Name");
        LibraryVariableStorage.Enqueue(GenJournalBatch.Name);

        // Exercise and Verify.
        RunDepositSlipReportAndVerifyXmlValues(
          GenJournalLine."Bank Account No.", GenJournalLineBankAccountNoCap, GenJournalLineCreditAmountCap, GenJournalLine."Credit Amount",
          GenJournalLine2."Bank Account No.", GenJournalLine2."Credit Amount");
    end;

    [Test]
    [HandlerFunctions('PurchaseReceiptsRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPurchRcptLinePurchaseReceiptsRpt()
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchRcptLine2: Record "Purch. Rcpt. Line";
    begin
        // [FEATURE] [Purchase Receipts]
        // [SCENARIO] validate Purch. Rcpt. Line - OnAfterGetRecord Trigger of Report - 28029 with multiple Vendors.

        // Setup: Create two Purchase Receipts.
        Initialize();
        CreatePurchaseReceipt(PurchRcptLine);
        CreatePurchaseReceipt(PurchRcptLine2);
        LibraryVariableStorage.Enqueue(PurchRcptLine."Pay-to Vendor No.");  // Enqueue for PurchaseReceiptsRequestPageHandler.
        LibraryVariableStorage.Enqueue(PurchRcptLine2."Pay-to Vendor No.");  // Enqueue for PurchaseReceiptsRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Purchase Receipts");  // Opens PurchaseReceiptsRequestPageHandler.

        // Verify.
        VerifyXmlValuesOnReport(
          TotalAmountCap, PayToVendorNoCap, TotalAmountCap, PurchRcptLine.Quantity * PurchRcptLine."Direct Unit Cost",
          PurchRcptLine."Pay-to Vendor No.", PurchRcptLine2.Quantity * PurchRcptLine2."Direct Unit Cost");
    end;

    [Test]
    [HandlerFunctions('CopyPurchaseDocumentRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportReplaceDocDateCopyPurchaseDocumentRpt()
    begin
        // [SCENARIO] validate OnPreReport Trigger of Report - 492 with Replace Document Date as True.
        Initialize();
        OnPreReportCopyPurchaseDocumentReport(
          false, true, CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'Y>', WorkDate()), WorkDate());  // False for ReplacePostDate and True for ReplaceDocDate.
    end;

    [Test]
    [HandlerFunctions('CopyPurchaseDocumentRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportReplacePostDateCopyPurchaseDocumentRpt()
    var
        PostingDate: Date;
    begin
        // [FEATURE] [Copy Purchase Document]
        // [SCENARIO] validate OnPreReport Trigger of Report - 492 with Replace Posting Date as True.
        Initialize();
        PostingDate := CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'Y>', WorkDate());
        OnPreReportCopyPurchaseDocumentReport(true, false, PostingDate, PostingDate);  // True for ReplacePostDate and False for ReplaceDocDate.
    end;

    local procedure OnPreReportCopyPurchaseDocumentReport(ReplacePostDate: Boolean; ReplaceDocDate: Boolean; PostingDate: Date; ExpectedPostingDate: Date)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        CopyPurchaseDocument: Report "Copy Purchase Document";
    begin
        // Setup: Create two Purchase Orders.
        CreatePurchaseOrder(PurchaseHeader);
        CreatePurchaseOrder(PurchaseHeader2);
        EnqueueValuesForRequestPageHandler(PurchaseHeader."No.", PostingDate, ReplacePostDate, ReplaceDocDate);  // Enqueue values for CopyPurchaseDocumentRequestPageHandler.
        CopyPurchaseDocument.SetPurchHeader(PurchaseHeader2);

        // Exercise.
        CopyPurchaseDocument.Run();  // Opens CopyPurchaseDocumentRequestPageHandler.

        // Verify: Posting Date and Document Date on Purchase Order.
        PurchaseHeader2.Get(PurchaseHeader2."Document Type", PurchaseHeader2."No.");
        PurchaseHeader2.TestField("Posting Date", ExpectedPostingDate);
        PurchaseHeader2.TestField("Document Date", PostingDate);
    end;

    [Test]
    [HandlerFunctions('CopySalesDocumentRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportReplaceDocDateCopySalesDocumentRpt()
    begin
        // [FEATURE] [Copy Sales Document]
        // [SCENARIO] validate OnPreReport Trigger of Report - 292 with Replace Document Date as True.
        Initialize();
        OnPreReportCopySalesDocumentReport(false, true, CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'Y>', WorkDate()), WorkDate());  // False for ReplacePostDate and True for ReplaceDocDate.
    end;

    [Test]
    [HandlerFunctions('CopySalesDocumentRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportReplacePostDateCopySalesDocumentRpt()
    var
        PostingDate: Date;
    begin
        // [FEATURE] [Copy Sales Document]
        // [SCENARIO] validate OnPreReport Trigger of Report - 292 with Replace Posting Date as True.
        Initialize();
        PostingDate := CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'Y>', WorkDate());
        OnPreReportCopySalesDocumentReport(true, false, PostingDate, PostingDate);  // True for ReplacePostDate and False for ReplaceDocDate.
    end;

    local procedure OnPreReportCopySalesDocumentReport(ReplacePostDate: Boolean; ReplaceDocDate: Boolean; PostingDate: Date; ExpectedPostingDate: Date)
    var
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        CopySalesDocument: Report "Copy Sales Document";
    begin
        // Setup: Create two Sales Orders.
        CreateSalesOrder(SalesHeader);
        CreateSalesOrder(SalesHeader2);
        EnqueueValuesForRequestPageHandler(SalesHeader."No.", PostingDate, ReplacePostDate, ReplaceDocDate);  // Enqueue values for CopySalesDocumentRequestPageHandler.
        CopySalesDocument.SetSalesHeader(SalesHeader2);

        // Exercise.
        CopySalesDocument.Run();  // Opens CopySalesDocumentRequestPageHandler.

        // Verify: Posting Date and Document Date on Sales Order.
        SalesHeader2.Get(SalesHeader2."Document Type", SalesHeader2."No.");
        SalesHeader2.TestField("Posting Date", ExpectedPostingDate);
        SalesHeader2.TestField("Document Date", PostingDate);
    end;

    [Test]
    [HandlerFunctions('IncomeStatementSimpleRequestPageHandler')]
    [Scope('OnPrem')]
    procedure IncomeStateReportShowsAccountsWithNegativeAmounts()
    var
        GLAccount: Record "G/L Account";
        GLAccountNo: Code[20];
        Amount: Decimal;
    begin
        // [FEATURE] [Income Statement]
        // [SCENARIO 295055] Income Statement report shows G/L accounts with negative current period net change
        Initialize();

        // [GIVEN] G/L Account with negative balance in period
        GLAccountNo := CreateGLAccount(GLAccount."Income/Balance"::"Income Statement", true);
        Amount := -LibraryRandom.RandDec(100, 2);
        CreateGLEntry(GLAccountNo, '', '', WorkDate(), Amount);

        // Enqueue G/L Account No. for IncomeStatementSimpleRequestPageHandler.
        LibraryVariableStorage.Enqueue(GLAccountNo);

        Commit();

        // [WHEN] Income Statement (28025) report is run
        REPORT.Run(REPORT::"Income Statement");
        // UI Handled by IncomeStatementSimpleRequestPageHandler.

        // [THEN] Report has the line with G/L Account and it's negative net change amount
        LibraryReportValidation.OpenFile();
        Assert.IsTrue(LibraryReportValidation.CheckIfValueExists(Format(Amount)), 'Amount cell not found');
        Assert.IsTrue(LibraryReportValidation.CheckIfDecimalValueExists(Amount), 'Amount cell not found');
    end;

    [Test]
    [HandlerFunctions('IncomeStatementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure IncomeStateReportShowsRoundedValueForThousands()
    var
        GLAccount: Record "G/L Account";
        GLAccountNo: Code[20];
        Amount: Decimal;
        AmountsInWhole: Option " ",Tens,Hundreds,Thousands,"Hundred Thousands",Millions;
    begin
        // [FEATURE] [Income Statement] [Rounnding]
        // [SCENARIO 332438] Income Statement report shows G/L accounts with rounded net change
        Initialize();

        // [GIVEN] G/L Account with positive balance in period was created and posted
        GLAccountNo := CreateGLAccount(GLAccount."Income/Balance"::"Income Statement", true);
        Amount := LibraryRandom.RandDec(100000, 2);
        CreateGLEntry(GLAccountNo, '', '', WorkDate(), Amount);

        // [GIVEN] Amounts In Whole set up to "Thousands"
        EnqueueValuesForIncomeStatementRequestPageHandler(GLAccountNo, '', '', AmountsInWhole::Thousands, false, false);
        Commit();

        // [WHEN] Income Statement (28025) report is run
        REPORT.Run(REPORT::"Income Statement");
        // UI Handled by IncomeStatementRequestPageHandler.

        // [THEN] Report has the line with G/L Account the value is rounded to integer
        LibraryXMLRead.Initialize(LibraryVariableStorage.DequeueText());
        Assert.AreNotEqual(Format(Amount / 1000), LibraryXMLRead.GetElementValue('CurrentYTDNetChange'), 'The value is rounded');
        Assert.AreEqual(Format(Round(Amount / 1000, 1)), LibraryXMLRead.GetElementValue('CurrentYTDNetChange'), 'The value is not rounded');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PurchaseReceiptsRequestPageHandlerSimple')]
    [Scope('OnPrem')]
    procedure PurchaseReceiptsFromVendorPage()
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        Vendor: Record Vendor;
        VendorCard: TestPage "Vendor Card";
    begin
        // [FEATURE] [Purchase Receipts] [UI]
        // [SCENARIO 374783] "Purchase Receipts" report can be run from Vendor Card action without error
        Initialize();

        // [GIVEN] Purchase Receipt posted for Vendor
        CreatePurchaseReceipt(PurchRcptLine);

        // [GIVEN] Vendor Card page was open
        Vendor.Get(PurchRcptLine."Pay-to Vendor No.");
        VendorCard.OpenView();
        VendorCard.Filter.SetFilter("No.", Vendor."No.");

        Commit();

        // [WHEN] Invoke "Purchase Receipts" action
        VendorCard."Purchase Receipts".Invoke();

        // [THEN] No error and "Purchase Receipts" report is ran for Vendor
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(TotalAmountCap, PurchRcptLine.Quantity * PurchRcptLine."Direct Unit Cost");
        LibraryReportDataset.AssertElementWithValueExists(PayToVendorNoCap, PurchRcptLine."Pay-to Vendor No.");
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
        Clear(LibraryReportValidation);
    end;

    local procedure CreateBankAccount(): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount."No." := LibraryUTUtility.GetNewCode();
        BankAccount."Bank Branch No." := LibraryUTUtility.GetNewCode();
        BankAccount."Bank Account No." := LibraryUTUtility.GetNewCode();
        BankAccount.Insert();
        exit(BankAccount."No.");
    end;

    local procedure CreateBankAccountLedgerEntry(BankAccountNo: Code[20]; BalAccountType: Enum "Gen. Journal Account Type"; Amount: Decimal)
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        BankAccountLedgerEntry2: Record "Bank Account Ledger Entry";
    begin
        BankAccountLedgerEntry2.FindLast();
        BankAccountLedgerEntry."Entry No." := BankAccountLedgerEntry2."Entry No." + 1;
        BankAccountLedgerEntry."Bank Account No." := BankAccountNo;
        BankAccountLedgerEntry."Posting Date" := WorkDate();
        BankAccountLedgerEntry."Bal. Account Type" := BalAccountType;
        BankAccountLedgerEntry2."Bal. Account No." := LibraryUTUtility.GetNewCode();
        BankAccountLedgerEntry.Amount := Amount;
        BankAccountLedgerEntry.Open := true;
        BankAccountLedgerEntry.Insert();
    end;

    local procedure CreateBankAccLedgerEntryForCustAndVend(BankAccountNo: Code[20]; Amount: Decimal; Amount2: Decimal)
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
    begin
        CreateBankAccountLedgerEntry(BankAccountNo, BankAccountLedgerEntry."Bal. Account Type"::Vendor, Amount);
        CreateBankAccountLedgerEntry(BankAccountNo, BankAccountLedgerEntry."Bal. Account Type"::Customer, Amount2);
    end;

    local procedure CreateGeneralJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        GenJournalBatch."Journal Template Name" := LibraryUTUtility.GetNewCode10();
        GenJournalBatch.Name := LibraryUTUtility.GetNewCode10();
        GenJournalBatch."Bal. Account Type" := GenJournalBatch."Bal. Account Type"::"Bank Account";
        GenJournalBatch."Bal. Account No." := CreateBankAccount();
        GenJournalBatch.Insert();
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; LineNo: Integer)
    var
        BankAccount: Record "Bank Account";
    begin
        GenJournalLine."Line No." := LineNo;
        GenJournalLine."Journal Template Name" := GenJournalBatch."Journal Template Name";
        GenJournalLine."Journal Batch Name" := GenJournalBatch.Name;
        GenJournalLine."Account Type" := GenJournalLine."Account Type"::Customer;
        GenJournalLine."Account No." := LibraryUTUtility.GetNewCode();
        GenJournalLine."Posting Date" := WorkDate();
        GenJournalLine."Source Code" := CreateSourceCode();
        GenJournalLine."Document No." := LibraryUTUtility.GetNewCode10();
        GenJournalLine."Credit Amount" := LibraryRandom.RandDec(100, 2);
        GenJournalLine.Amount := -GenJournalLine."Credit Amount";
        BankAccount.Get(GenJournalBatch."Bal. Account No.");
        GenJournalLine."Bank Branch No." := BankAccount."Bank Branch No.";
        GenJournalLine.Insert();
    end;

    local procedure CreateGLAccount(IncomeBalance: Enum "G/L Account Report Type"; NewPage: Boolean): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount."No." := LibraryUTUtility.GetNewCode();
        GLAccount."Income/Balance" := IncomeBalance;
        GLAccount."New Page" := NewPage;
        GLAccount.Insert();
        exit(GLAccount."No.");
    end;

    local procedure CreateGLBudgetEntry(BudgetName: Code[10]; GLAccountNo: Code[20]; GlobalDimensionOneCode: Code[20]; GlobalDimensionTwoCode: Code[20]; EntryDate: Date): Decimal
    var
        GLBudgetEntry: Record "G/L Budget Entry";
        GLBudgetEntry2: Record "G/L Budget Entry";
    begin
        GLBudgetEntry2.FindLast();
        GLBudgetEntry."Entry No." := GLBudgetEntry2."Entry No." + 1;
        GLBudgetEntry."Budget Name" := BudgetName;
        GLBudgetEntry."G/L Account No." := GLAccountNo;
        GLBudgetEntry."Global Dimension 1 Code" := GlobalDimensionOneCode;
        GLBudgetEntry."Global Dimension 2 Code" := GlobalDimensionTwoCode;
        GLBudgetEntry.Date := EntryDate;
        GLBudgetEntry.Amount := LibraryRandom.RandDec(100, 2);
        GLBudgetEntry.Insert();
        exit(GLBudgetEntry.Amount);
    end;

    local procedure CreateGLEntry(GLAccountNo: Code[20]; GlobalDimensionOneCode: Code[20]; GlobalDimensionTwoCode: Code[20]; PostingDate: Date; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
        GLEntry2: Record "G/L Entry";
    begin
        GLEntry2.FindLast();
        GLEntry."Entry No." := GLEntry2."Entry No." + 1;
        GLEntry."G/L Account No." := GLAccountNo;
        GLEntry."Global Dimension 1 Code" := GlobalDimensionOneCode;
        GLEntry."Global Dimension 2 Code" := GlobalDimensionTwoCode;
        GLEntry."Posting Date" := PostingDate;
        GLEntry.Amount := Amount;
        GLEntry."Additional-Currency Amount" := Amount;
        GLEntry.Insert();
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::Order;
        PurchaseHeader."No." := LibraryUTUtility.GetNewCode();
        PurchaseHeader."Buy-from Vendor No." := LibraryUTUtility.GetNewCode();
        PurchaseHeader."Posting Date" := WorkDate();
        PurchaseHeader."Document Date" := WorkDate();
        PurchaseHeader.Insert();
    end;

    local procedure CreatePurchaseReceipt(var PurchRcptLine: Record "Purch. Rcpt. Line")
    var
        PurchRcptHeader: Record "Purch. Rcpt. Header";
    begin
        PurchRcptHeader."No." := LibraryUTUtility.GetNewCode();
        PurchRcptHeader."Pay-to Vendor No." := LibraryPurchase.CreateVendorNo();
        PurchRcptHeader."Posting Date" := WorkDate();
        PurchRcptHeader.Insert();
        PurchRcptLine."Document No." := PurchRcptHeader."No.";
        PurchRcptLine."Pay-to Vendor No." := PurchRcptHeader."Pay-to Vendor No.";
        PurchRcptLine.Quantity := LibraryRandom.RandDec(100, 2);
        PurchRcptLine."Direct Unit Cost" := PurchRcptLine.Quantity;
        PurchRcptLine.Insert();
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header")
    begin
        SalesHeader."Document Type" := SalesHeader."Document Type"::Order;
        SalesHeader."No." := LibraryUTUtility.GetNewCode();
        SalesHeader."Sell-to Customer No." := LibraryUTUtility.GetNewCode();
        SalesHeader."Posting Date" := WorkDate();
        SalesHeader."Document Date" := WorkDate();
        SalesHeader.Insert();
    end;

    local procedure CreateSourceCode(): Code[10]
    var
        SourceCode: Record "Source Code";
    begin
        SourceCode.Code := LibraryUTUtility.GetNewCode10();
        SourceCode.Insert();
        exit(SourceCode.Code);
    end;

    local procedure EnqueueValuesForRequestPageHandler(Value: Code[20]; Value2: Variant; Value3: Variant; Value4: Variant)
    begin
        LibraryVariableStorage.Enqueue(Value);
        LibraryVariableStorage.Enqueue(Value2);
        LibraryVariableStorage.Enqueue(Value3);
        LibraryVariableStorage.Enqueue(Value4);
    end;

    local procedure RunBalanceSheetReportAndVerifyXmlValues(Caption: Text; ColumnAmountOne: Text; ColumnAmountTwo: Text; Amount: Text)
    begin
        // Exercise.
        REPORT.Run(REPORT::"Balance Sheet");  // Opens BalanceSheetRequestPageHandler.

        // Verify.
        VerifyXmlValuesOnReport(ColumnAmountOneCap, ColumnAmountTwoCap, Caption, ColumnAmountOne, ColumnAmountTwo, Amount);
    end;

    local procedure RunBankAccReconReportAndVerifyXmlValues(TotalOneAmount: Decimal; TotalTwoAmount: Decimal)
    begin
        // Exercise.
        REPORT.Run(REPORT::"Bank Account Reconciliation");  // Opens BankAccountReconciliationRequestPageHandler.

        // Verify.
        VerifyXmlValuesOnReport(
          TotalOneCap, TotalTwoCap, BankAccountBalanceAtDateCap, TotalOneAmount, TotalTwoAmount, TotalTwoAmount - TotalOneAmount);
    end;

    local procedure RunDepositSlipReportAndVerifyXmlValues(BankAccountNo: Code[20]; Caption: Text; Caption2: Text; CreditAmount: Decimal; Value: Variant; Value2: Variant)
    begin
        // Exercise.
        REPORT.Run(REPORT::"Deposit Slip");  // Opens DepositSlipRequestPageHandler.

        // Verify.
        VerifyXmlValuesOnReport(GenJournalLineBankAccountNoCap, GenJournalLineCreditAmountCap, Caption, BankAccountNo, CreditAmount, Value);
        LibraryReportDataset.AssertElementWithValueExists(Caption2, Value2);
    end;

    local procedure RunIncomeStatementReportAndVerifyXmlValues(ExpectedAmount: Decimal; HideEmptyLines: Boolean)
    begin
        // Exercise.
        REPORT.Run(REPORT::"Income Statement");  // Opens IncomeStatementRequestPageHandler.

        // Verify.
        VerifyXmlValuesOnReport(
          CurrentPeriodNetChangeCap, CurrentYearToDateNetChangeCap, LastYrCurrPeriodNetChangeCap, ExpectedAmount, ExpectedAmount,
          ExpectedAmount);
        LibraryReportDataset.AssertElementWithValueExists(LastYearToDateNetChangeCap, ExpectedAmount);
        LibraryReportDataset.AssertElementWithValueExists('HideEmptyLines', HideEmptyLines);
    end;

    local procedure VerifyXmlValuesOnReport(Caption: Text; Caption2: Text; Caption3: Text; Value: Variant; Value2: Variant; Value3: Variant)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(Caption, Value);
        LibraryReportDataset.AssertElementWithValueExists(Caption2, Value2);
        LibraryReportDataset.AssertElementWithValueExists(Caption3, Value3);
    end;

    local procedure EnqueueValuesForIncomeStatementRequestPageHandler(Value: Code[20]; Value2: Variant; Value3: Variant; Value4: Variant; Value5: Variant; Value6: Variant)
    begin
        LibraryVariableStorage.Enqueue(Value);
        LibraryVariableStorage.Enqueue(Value2);
        LibraryVariableStorage.Enqueue(Value3);
        LibraryVariableStorage.Enqueue(Value4);
        LibraryVariableStorage.Enqueue(Value5);
        LibraryVariableStorage.Enqueue(Value6);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BalanceSheetRequestPageHandler(var BalanceSheet: TestRequestPage "Balance Sheet")
    var
        AmountsInWhole: Variant;
        BudgetFilter: Variant;
        GlobalDimensionOneFilter: Variant;
        GlobalDimensionTwoFilter: Variant;
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(GlobalDimensionOneFilter);
        LibraryVariableStorage.Dequeue(GlobalDimensionTwoFilter);
        LibraryVariableStorage.Dequeue(AmountsInWhole);
        LibraryVariableStorage.Dequeue(BudgetFilter);
        BalanceSheet."G/L Account".SetFilter("No.", No);
        BalanceSheet."G/L Account".SetFilter("Date Filter", Format(CalcDate('<CY>', WorkDate())));
        BalanceSheet."G/L Account".SetFilter("Global Dimension 1 Filter", GlobalDimensionOneFilter);
        BalanceSheet."G/L Account".SetFilter("Global Dimension 2 Filter", GlobalDimensionTwoFilter);
        BalanceSheet."G/L Account".SetFilter("Budget Filter", BudgetFilter);
        BalanceSheet.AmountsInWhole.SetValue(AmountsInWhole);
        BalanceSheet.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BankAccountReconciliationRequestPageHandler(var BankAccountReconciliation: TestRequestPage "Bank Account Reconciliation")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        BankAccountReconciliation.NewPagePerBankAccount.SetValue(true);
        BankAccountReconciliation."Bank Account".SetFilter("No.", No);
        BankAccountReconciliation."Bank Account".SetFilter("Date Filter", Format(WorkDate()));
        BankAccountReconciliation.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CopyPurchaseDocumentRequestPageHandler(var CopyPurchaseDocument: TestRequestPage "Copy Purchase Document")
    var
        DocumentNo: Variant;
        PostingDate: Variant;
        ReplaceDocDate: Variant;
        ReplacePostDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNo);
        LibraryVariableStorage.Dequeue(PostingDate);
        LibraryVariableStorage.Dequeue(ReplacePostDate);
        LibraryVariableStorage.Dequeue(ReplaceDocDate);
        CopyPurchaseDocument.DocumentType.SetValue(CopyPurchaseDocument.DocumentType.GetOption(3));  // Option 3 is used for Order.
        CopyPurchaseDocument.DocumentNo.SetValue(DocumentNo);
        CopyPurchaseDocument.PostingDate.SetValue(PostingDate);
        CopyPurchaseDocument.ReplacePostingDate.SetValue(ReplacePostDate);
        CopyPurchaseDocument.ReplaceDocumentDate.SetValue(ReplaceDocDate);
        CopyPurchaseDocument.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CopySalesDocumentRequestPageHandler(var CopySalesDocument: TestRequestPage "Copy Sales Document")
    var
        DocumentNo: Variant;
        PostingDate: Variant;
        ReplaceDocDate: Variant;
        ReplacePostDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNo);
        LibraryVariableStorage.Dequeue(PostingDate);
        LibraryVariableStorage.Dequeue(ReplacePostDate);
        LibraryVariableStorage.Dequeue(ReplaceDocDate);
        CopySalesDocument.DocumentType.SetValue(CopySalesDocument.DocumentType.GetOption(3));  // Option 3 is used for Order.
        CopySalesDocument.DocumentNo.SetValue(DocumentNo);
        CopySalesDocument.PostingDate.SetValue(PostingDate);
        CopySalesDocument.ReplacePostDate.SetValue(ReplacePostDate);
        CopySalesDocument.ReplaceDocDate.SetValue(ReplaceDocDate);
        CopySalesDocument.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure DepositSlipRequestPageHandler(var DepositSlip: TestRequestPage "Deposit Slip")
    var
        JournalBatchName: Variant;
        JournalTemplateName: Variant;
    begin
        LibraryVariableStorage.Dequeue(JournalTemplateName);
        LibraryVariableStorage.Dequeue(JournalBatchName);
        DepositSlip."Gen. Journal Line".SetFilter("Journal Template Name", JournalTemplateName);
        DepositSlip."Gen. Journal Line".SetFilter("Journal Batch Name", JournalBatchName);
        DepositSlip.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure IncomeStatementRequestPageHandler(var IncomeStatement: TestRequestPage "Income Statement")
    var
        FileName: Text;
    begin
        IncomeStatement."G/L Account".SetFilter("No.", LibraryVariableStorage.DequeueText());
        IncomeStatement."G/L Account".SetFilter("Date Filter", StrSubstNo(DateFilterTxt, WorkDate(), CalcDate('<CY>', WorkDate())));
        IncomeStatement."G/L Account".SetFilter("Global Dimension 1 Filter", LibraryVariableStorage.DequeueText());
        IncomeStatement."G/L Account".SetFilter("Global Dimension 2 Filter", LibraryVariableStorage.DequeueText());
        IncomeStatement.AmountsInWhole.SetValue(LibraryVariableStorage.DequeueInteger());
        IncomeStatement.HideEmptyLines.SetValue(LibraryVariableStorage.DequeueBoolean());
        IncomeStatement.ShowAmountsInAddReportingCurrency.SetValue(LibraryVariableStorage.DequeueBoolean());
        FileName := LibraryReportDataset.GetFileName();
        LibraryVariableStorage.Enqueue(FileName);
        IncomeStatement.SaveAsXml(LibraryReportDataset.GetParametersFileName(), FileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure IncomeStatementSimpleRequestPageHandler(var IncomeStatement: TestRequestPage "Income Statement")
    begin
        IncomeStatement."G/L Account".SetFilter("No.", LibraryVariableStorage.DequeueText());
        IncomeStatement."G/L Account".SetFilter("Date Filter", StrSubstNo(DateFilterTxt, WorkDate(), CalcDate('<CY>', WorkDate())));
        IncomeStatement.SaveAsExcel(LibraryReportValidation.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseReceiptsRequestPageHandler(var PurchaseReceipts: TestRequestPage "Purchase Receipts")
    var
        PayToVendorNo: Variant;
        PayToVendorNo2: Variant;
    begin
        LibraryVariableStorage.Dequeue(PayToVendorNo);
        LibraryVariableStorage.Dequeue(PayToVendorNo2);
        PurchaseReceipts."Purch. Rcpt. Header".SetFilter(
          "Pay-to Vendor No.", StrSubstNo(PayToVendorNoFilter, PayToVendorNo, PayToVendorNo2));
        PurchaseReceipts."Purch. Rcpt. Header".SetFilter("Posting Date", Format(WorkDate()));
        PurchaseReceipts.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseReceiptsRequestPageHandlerSimple(var PurchaseReceipts: TestRequestPage "Purchase Receipts")
    begin
        PurchaseReceipts."Purch. Rcpt. Header".SetFilter("Posting Date", Format(WorkDate()));
        PurchaseReceipts.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

