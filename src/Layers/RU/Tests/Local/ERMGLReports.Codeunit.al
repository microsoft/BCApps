codeunit 144101 "ERM G/L Reports"
{
    // // [FEATURE] [Reports]

    TestPermissions = NonRestrictive;
    Subtype = Test;
    Permissions = tabledata "G/L Entry" = rimd;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRUReports: Codeunit "Library RU Reports";
        LibraryRandom: Codeunit "Library - Random";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryUtility: Codeunit "Library - Utility";
        IsInitialized: Boolean;

    [Test]
    [HandlerFunctions('GLCorrGLReportHandler,SelectPeriodPageHandler')]
    [Scope('OnPrem')]
    procedure GLCorrespGeneralLedgerReport()
    var
        GLAccount: Record "G/L Account";
        GLCorrGeneralLedger: Report "G/L Corresp. General Ledger";
        DebitGLAccNo: Code[20];
        Amount: Decimal;
    begin
        InitGLAccountWithBalance(DebitGLAccNo, Amount);

        SetGLAccountFilters(GLAccount, DebitGLAccNo);
        Clear(GLCorrGeneralLedger);
        GLCorrGeneralLedger.SetTableView(GLAccount);
        GLCorrGeneralLedger.Run();

        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('GLAcc_No_', DebitGLAccNo);
        LibraryReportDataset.AssertElementWithValueExists('NetChangeDebit', Amount);
    end;

    [Test]
    [HandlerFunctions('GLCorrJnlOrderReportHandler,SelectPeriodPageHandler')]
    [Scope('OnPrem')]
    procedure GLCorrespJournalOrderReport()
    var
        GLAccount: Record "G/L Account";
        GLCorrJournalOrder: Report "G/L Corresp. Journal Order";
        DebitGLAccNo: Code[20];
        Amount: Decimal;
    begin
        InitGLAccountWithBalance(DebitGLAccNo, Amount);

        SetGLAccountFilters(GLAccount, DebitGLAccNo);
        Clear(GLCorrJournalOrder);
        GLCorrJournalOrder.SetTableView(GLAccount);
        GLCorrJournalOrder.Run();

        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('GLAcc_No_', DebitGLAccNo);
        LibraryReportDataset.AssertElementWithValueExists('BalanceEnding', Amount);
    end;

    [Test]
    [HandlerFunctions('GLAccountTurnoverHandler')]
    [Scope('OnPrem')]
    procedure GLAccountTurnoverReport()
    var
        GLAccount: Record "G/L Account";
        GenJnlLine: Record "Gen. Journal Line";
        GLAccountTurnover: Report "G/L Account Turnover";
        DebitGLAccNo: Code[20];
        DebitAmount: Decimal;
        CreditAmount: Decimal;
    begin
        InitGLAccountWithBalance(DebitGLAccNo, DebitAmount);
        CreditAmount := CreatePostGenJnlLine(GenJnlLine."Account Type"::"G/L Account", DebitGLAccNo, -1);

        SetGLAccountFilters(GLAccount, DebitGLAccNo);
        Clear(GLAccountTurnover);
        GLAccountTurnover.SetTableView(GLAccount);
        GLAccountTurnover.Run();

        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('GLAccNo', DebitGLAccNo);
        LibraryReportDataset.AssertElementWithValueExists('LineText_3_', FormatValue(DebitAmount, 3));
        LibraryReportDataset.AssertElementWithValueExists('LineText_4_', FormatValue(CreditAmount, 3));
        LibraryReportDataset.AssertElementWithValueExists('LineText_5_', FormatValue(Abs(DebitAmount - CreditAmount), 3));
    end;

    [Test]
    [HandlerFunctions('GLAccountCardHandler')]
    [Scope('OnPrem')]
    procedure GLAccountCardReport()
    var
        GLAccount: Record "G/L Account";
        GenJnlLine: Record "Gen. Journal Line";
        GLAccountCard: Report "G/L Account Card";
        DebitGLAccNo: Code[20];
        DebitAmount: Decimal;
        CreditAmount: Decimal;
    begin
        InitGLAccountWithBalance(DebitGLAccNo, DebitAmount);
        CreditAmount := CreatePostGenJnlLine(GenJnlLine."Account Type"::"G/L Account", DebitGLAccNo, -1);

        SetGLAccountFilters(GLAccount, DebitGLAccNo);
        Clear(GLAccountCard);
        GLAccountCard.SetTableView(GLAccount);
        GLAccountCard.Run();

        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('GLAcc_No_', DebitGLAccNo);
        LibraryReportDataset.AssertElementWithValueExists('DebetAmount', DebitAmount);
        LibraryReportDataset.AssertElementWithValueExists('CreditAmount', CreditAmount);
        LibraryReportDataset.AssertElementWithValueExists('BalanceEnding', Abs(DebitAmount - CreditAmount));
    end;

    [Test]
    [HandlerFunctions('GLAccountEntriesAnalysisHandler')]
    [Scope('OnPrem')]
    procedure GLAccountEntriesAnalysisReport()
    var
        GLAccount: Record "G/L Account";
        GenJnlLine: Record "Gen. Journal Line";
        GLAccountEntriesAnalysis: Report "G/L Account Entries Analysis";
        DebitGLAccNo: Code[20];
        DebitAmount: Decimal;
        CreditAmount: Decimal;
    begin
        InitGLAccountWithBalance(DebitGLAccNo, DebitAmount);
        CreditAmount := CreatePostGenJnlLine(GenJnlLine."Account Type"::"G/L Account", DebitGLAccNo, -1);

        SetGLAccountFilters(GLAccount, DebitGLAccNo);
        Clear(GLAccountEntriesAnalysis);
        GLAccountEntriesAnalysis.SetTableView(GLAccount);
        GLAccountEntriesAnalysis.Run();

        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('G_L_Account_No_', DebitGLAccNo);
        LibraryReportDataset.AssertElementWithValueExists('DebitAmountText', FormatValue(DebitAmount, 3));
        LibraryReportDataset.AssertElementWithValueExists('CreditAmountText', FormatValue(CreditAmount, 3));
        LibraryReportDataset.AssertElementWithValueExists('BalanceEnding', Abs(DebitAmount - CreditAmount));
    end;

    [Test]
    [HandlerFunctions('BankAccountGLTurnoverHandler')]
    [Scope('OnPrem')]
    procedure BankAccGLTurnoverReport()
    var
        BankAccount: Record "Bank Account";
        BankAccountGLTurnover: Report "Bank Account G/L Turnover";
        Amount: Decimal;
    begin
        Amount := InitBankAccountForReport(BankAccount);

        Clear(BankAccountGLTurnover);
        BankAccountGLTurnover.SetTableView(BankAccount);
        BankAccountGLTurnover.Run();

        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Bank_Account__No__', BankAccount."No.");
        LibraryReportDataset.AssertElementWithValueExists('NetChangeDebit', Amount);
    end;

    [Test]
    [HandlerFunctions('CustomerGLTurnoverHandler')]
    [Scope('OnPrem')]
    procedure CustomerGLTurnoverReport()
    var
        Customer: Record Customer;
        CustomerGLTurnover: Report "Customer G/L Turnover";
        Amount: Decimal;
    begin
        Amount := InitCustomerForReport(Customer);

        Clear(CustomerGLTurnover);
        CustomerGLTurnover.SetTableView(Customer);
        CustomerGLTurnover.Run();

        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Customer__No__', Customer."No.");
        LibraryReportDataset.AssertElementWithValueExists('Customer__G_L_Debit_Amount_', Amount);
    end;

    [Test]
    [HandlerFunctions('VendorGLTurnoverHandler')]
    [Scope('OnPrem')]
    procedure VendorGLTurnoverReport()
    var
        Vendor: Record Vendor;
        VendorGLTurnover: Report "Vendor G/L Turnover";
        Amount: Decimal;
    begin
        Amount := InitVendorForReport(Vendor);

        Clear(VendorGLTurnover);
        VendorGLTurnover.SetTableView(Vendor);
        VendorGLTurnover.Run();

        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Vendor__No__', Vendor."No.");
        LibraryReportDataset.AssertElementWithValueExists('Vendor__G_L_Debit_Amount_', Amount);
    end;

    [Test]
    [HandlerFunctions('FAGLTurnoverHandler')]
    [Scope('OnPrem')]
    procedure FAGLTurnoverReport()
    var
        FixedAsset: Record "Fixed Asset";
        FAGLTurnover: Report "Fixed Asset G/L Turnover";
        Amount: Decimal;
    begin
        Amount := InitFixedAssetForReport(FixedAsset);

        Clear(FAGLTurnover);
        FAGLTurnover.SetTableView(FixedAsset);
        FAGLTurnover.Run();

        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Fixed_Asset__No__', FixedAsset."No.");
        LibraryReportDataset.AssertElementWithValueExists('LineText_3_', FormatValue(Amount, 3));
    end;

    [Test]
    [HandlerFunctions('CustomerTurnoverHandler')]
    [Scope('OnPrem')]
    procedure CustomerTurnoverReport()
    var
        Customer: Record Customer;
        CustomerTurnover: Report "Customer Turnover";
        Amount: Decimal;
    begin
        Amount := InitCustomerForReport(Customer);

        Clear(CustomerTurnover);
        CustomerTurnover.SetTableView(Customer);
        CustomerTurnover.Run();

        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Customer__No__', Customer."No.");
        LibraryReportDataset.AssertElementWithValueExists('LineText_3_', FormatValue(Amount, 3));
    end;

    [Test]
    [HandlerFunctions('CustomerPostGrTurnoverHandler')]
    [Scope('OnPrem')]
    procedure CustomerPostGrTurnoverReport()
    var
        Customer: Record Customer;
        CustomerPostGrTurnover: Report "Customer Post. Gr. Turnover";
        Amount: Decimal;
    begin
        Amount := InitCustomerForReport(Customer);

        Clear(CustomerPostGrTurnover);
        CustomerPostGrTurnover.SetTableView(Customer);
        CustomerPostGrTurnover.Run();

        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('Customer_Posting_Group_Code', Customer."Customer Posting Group");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('LineAmount_5_', Amount);
    end;

    [Test]
    [HandlerFunctions('VendorTurnoverHandler')]
    [Scope('OnPrem')]
    procedure VendorTurnoverReport()
    var
        Vendor: Record Vendor;
        VendorTurnover: Report "Vendor Turnover";
        Amount: Decimal;
    begin
        Amount := InitVendorForReport(Vendor);

        Clear(VendorTurnover);
        VendorTurnover.SetTableView(Vendor);
        VendorTurnover.Run();

        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Vendor__No__', Vendor."No.");
        LibraryReportDataset.AssertElementWithValueExists('LineText_3_', FormatValue(Amount, 3));
    end;

    [Test]
    [HandlerFunctions('VendorPostGrTurnoverHandler')]
    [Scope('OnPrem')]
    procedure VendorPostGrTurnoverReport()
    var
        Vendor: Record Vendor;
        VendorPostGrTurnover: Report "Vendor Post. Gr. Turnover";
        Amount: Decimal;
    begin
        Amount := InitVendorForReport(Vendor);

        Clear(VendorPostGrTurnover);
        VendorPostGrTurnover.SetTableView(Vendor);
        VendorPostGrTurnover.Run();

        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('VendorPostingGroup_Code', Vendor."Vendor Posting Group");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('LineAmount_3_', Amount);
    end;

    [Test]
    [HandlerFunctions('FATurnoverHandler')]
    [Scope('OnPrem')]
    procedure FATurnoverReport()
    var
        FixedAsset: Record "Fixed Asset";
        Amount: Decimal;
    begin
        // [FEATURE] [FA Turnover]
        // [SCENARIO] REP 12466 "FA Turnover" prints single Fixed Asset with Acquisition Cost value

        // [GIVEN] Fixed Asset with Acquisition = 1000
        Amount := InitFixedAssetForReport(FixedAsset);

        // [WHEN] Run "FA Turnover" report
        RunFATurnover(FixedAsset."No.", LibraryRUReports.GetFirstFADeprBook(FixedAsset."No."));

        // [THEN] Fixed Asset has been printed with: Acquisition = 1000, Book Value = 1000
        // [THEN] Total line has been printed with: Acquisition = 1000, Book Value = 1000
        LibraryReportValidation.OpenExcelFile();
        VerifyFATurnoverValues(21, FixedAsset."No.", Amount, Amount);
        VerifyFATurnoverTotalValues(22, Amount, Amount);
    end;

    [Test]
    [HandlerFunctions('FATurnoverHandler')]
    [Scope('OnPrem')]
    procedure FATurnoverReportThreeFAWhenSecondWithoutDeprBook()
    var
        FixedAsset: array[3] of Record "Fixed Asset";
        GenJournalLine: Record "Gen. Journal Line";
        Amount: array[2] of Decimal;
    begin
        // [FEATURE] [FA Turnover]
        // [SCENARIO 215339] REP 12466 "FA Turnover" correctly prints totals for three FAs when the first and third one has amounts and the second one doesn't have any FA Depreciation Book
        Initialize();

        // [GIVEN] Fixed Asset "FA1" with FA Depreciation Book and Acquisition = 1000
        LibraryFixedAsset.CreateFixedAssetWithSetup(FixedAsset[1]);
        Amount[1] := CreatePostGenJnlLine(GenJournalLine."Account Type"::"Fixed Asset", FixedAsset[1]."No.", 1);
        // [GIVEN] Fixed Asset "FA2" without any FA Depreciation Book setup (an empty FA)
        CreateFAWithoutBooks(FixedAsset[2]);
        // [GIVEN] Fixed Asset "FA3" with FA Depreciation Book and Acquisition = 2000
        LibraryFixedAsset.CreateFixedAssetWithSetup(FixedAsset[3]);
        Amount[2] := CreatePostGenJnlLine(GenJournalLine."Account Type"::"Fixed Asset", FixedAsset[3]."No.", 1);

        // [WHEN] Run "FA Turnover" report for the two given FAs using "Skip zero lines" = TRUE
        RunFATurnover(
          StrSubstNo('%1|%2|%3', FixedAsset[1]."No.", FixedAsset[2]."No.", FixedAsset[3]."No."),
          LibraryRUReports.GetFirstFADeprBook(FixedAsset[1]."No."));

        // [THEN] Fixed Asset "FA1" has been printed with: Acquisition = 1000, Book Value = 1000
        // [THEN] Fixed Asset "FA3" has been printed with: Acquisition = 2000, Book Value = 2000
        // [THEN] Total line has been printed with: Acquisition = 3000, Book Value = 3000
        LibraryReportValidation.OpenExcelFile();
        VerifyFATurnoverValues(21, FixedAsset[1]."No.", Amount[1], Amount[1]);
        VerifyFATurnoverValues(22, FixedAsset[3]."No.", Amount[2], Amount[2]);
        VerifyFATurnoverTotalValues(23, Amount[1] + Amount[2], Amount[1] + Amount[2]);
    end;

    [Test]
    [HandlerFunctions('ItemTurnoverHandler')]
    [Scope('OnPrem')]
    procedure ItemTurnoverReport()
    var
        Item: Record Item;
        ItemTurnover: Report "Item Turnover (Qty.)";
        Qty: Decimal;
    begin
        Initialize();
        LibraryInventory.CreateItem(Item);

        // TFS ID: 310217 (String Length error)
        Item.Validate(Description, CopyStr(LibraryUtility.GenerateRandomXMLText(MaxStrLen(Item.Description)), 1));
        Item.Validate("Description 2", CopyStr(LibraryUtility.GenerateRandomXMLText(MaxStrLen(Item."Description 2")), 1));
        Item.Modify(true);

        Qty := LibraryRandom.RandDecInRange(10, 20, 2);
        LibraryRUReports.CreateAndPostItemJournalLine('', Item."No.", Qty, false);

        Item.SetFilter("Date Filter", Format(WorkDate()));
        Item.SetRecFilter();
        Clear(ItemTurnover);
        ItemTurnover.SetTableView(Item);
        ItemTurnover.Run();

        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Item__No__', Item."No.");
        LibraryReportDataset.AssertElementWithValueExists('EndingQtyText', FormatValue(Qty, 4));
    end;

    [Test]
    [HandlerFunctions('CustomerAccountingCardHandler')]
    [Scope('OnPrem')]
    procedure CustomerAccountingCardReport()
    var
        Customer: Record Customer;
        CustomerAccountingCard: Report "Customer Accounting Card";
        Amount: Decimal;
    begin
        Amount := InitCustomerForReport(Customer);

        Clear(CustomerAccountingCard);
        CustomerAccountingCard.SetTableView(Customer);
        CustomerAccountingCard.Run();

        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Customer_No_', Customer."No.");
        LibraryReportDataset.AssertElementWithValueExists('Detailed_Cust__Ledg__Entry__Debit_Amount__LCY__', Amount);
    end;

    [Test]
    [HandlerFunctions('CustomerEntriesAnalysisHandler')]
    [Scope('OnPrem')]
    procedure CustomerEntriesAnalysisReport()
    var
        Customer: Record Customer;
        CustomerEntriesAnalysis: Report "Customer Entries Analysis";
        Amount: Decimal;
    begin
        Amount := InitCustomerForReport(Customer);

        Clear(CustomerEntriesAnalysis);
        CustomerEntriesAnalysis.SetTableView(Customer);
        CustomerEntriesAnalysis.Run();

        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Customer_No_', Customer."No.");
        LibraryReportDataset.AssertElementWithValueExists('DocAmount', Amount);
    end;

    [Test]
    [HandlerFunctions('VendorAccountingCardHandler')]
    [Scope('OnPrem')]
    procedure VendorAccountingCardReport()
    var
        Vendor: Record Vendor;
        VendorAccountingCard: Report "Vendor Accounting Card";
        Amount: Decimal;
    begin
        Amount := InitVendorForReport(Vendor);

        Clear(VendorAccountingCard);
        VendorAccountingCard.SetTableView(Vendor);
        VendorAccountingCard.Run();

        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Vendor_No_', Vendor."No.");
        LibraryReportDataset.AssertElementWithValueExists('Detailed_Vendor_Ledg__Entry__Debit_Amount__LCY__', Amount);
    end;

    [Test]
    [HandlerFunctions('VendorEntriesAnalysisHandler')]
    [Scope('OnPrem')]
    procedure VendorEntriesAnalysisReport()
    var
        Vendor: Record Vendor;
        VendorEntriesAnalysis: Report "Vendor Entries Analysis";
        Amount: Decimal;
    begin
        Amount := InitVendorForReport(Vendor);

        Clear(VendorEntriesAnalysis);
        VendorEntriesAnalysis.SetTableView(Vendor);
        VendorEntriesAnalysis.Run();

        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Vendor_No_', Vendor."No.");
        LibraryReportDataset.AssertElementWithValueExists('DocAmount', Amount);
    end;

    [Test]
    [HandlerFunctions('BankAccountCardHandler')]
    [Scope('OnPrem')]
    procedure BankAccountCardReport()
    var
        BankAccount: Record "Bank Account";
        BankAccountCard: Report "Bank Account Card";
        Amount: Decimal;
    begin
        Amount := InitBankAccountForReport(BankAccount);

        Clear(BankAccountCard);
        BankAccountCard.SetTableView(BankAccount);
        BankAccountCard.Run();

        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Bank_Account_No_', BankAccount."No.");
        LibraryReportDataset.AssertElementWithValueExists('Bank_Account_Ledger_Entry__Debit_Amount__LCY__', Amount);
    end;

    [Test]
    [HandlerFunctions('GLAccountCardHandler')]
    [Scope('OnPrem')]
    procedure MultilineGLAccountCardReport()
    var
        GLAccount: Record "G/L Account";
        GenJnlLine: Record "Gen. Journal Line";
        GLAccountCard: Report "G/L Account Card";
        DebitGLAccNo: Code[20];
        DebitAmount: Decimal;
        CreditAmount: Decimal;
    begin
        // [FEATURE] [Reports]
        // [SCENARIO 378113] Report G/L Account Card shows unexpected result in the Russian version
        // [GIVEN] Create Customer with positive balance = "P" and add the first entry with negative amount = "N"
        InitGLAccountWithBalance(DebitGLAccNo, DebitAmount);
        CreditAmount := CreatePostGenJnlLine(GenJnlLine."Account Type"::"G/L Account", DebitGLAccNo, -1);

        // [GIVEN] Add two entries: positive entry increases "P" and negative increases "N"
        CreditAmount += CreatePostGenJnlLine(GenJnlLine."Account Type"::"G/L Account", DebitGLAccNo, -1);
        DebitAmount += CreatePostGenJnlLine(GenJnlLine."Account Type"::"G/L Account", DebitGLAccNo, 1);

        // [WHEN] Print G/L Account Card
        SetGLAccountFilters(GLAccount, DebitGLAccNo);
        Clear(GLAccountCard);
        GLAccountCard.SetTableView(GLAccount);
        GLAccountCard.Run();

        // [THEN] 'TotalDebetAmount' = "P", 'TotalCreditAmount' = "N", BalanceEnding = "ABS(P-N)"
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('TotalDebetAmount', DebitAmount);
        LibraryReportDataset.AssertElementWithValueExists('TotalCreditAmount', CreditAmount);
        LibraryReportDataset.AssertElementWithValueExists('BalanceEnding', Abs(DebitAmount - CreditAmount));
    end;

    [Test]
    [HandlerFunctions('CustomerAccountingCardRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PositiveCustomerAccountingCardReport()
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
        GenJnlLine: Record "Gen. Journal Line";
        DebitAmount: Decimal;
        StartingBalance: Decimal;
    begin
        // [FEATURE] [Reports]
        // [SCENARIO 378116] Report Customer Accounting Card shows positive Balance Amounts in Russian version
        Initialize();

        // [GIVEN] Create Customer with positive balance "P" on it's Receivables Account "RA"
        DebitAmount := InitCustomerWithBalanceForReport(Customer, CustomerPostingGroup, 1);

        // [GIVEN] Add positive entry on previous date with amount "P0"
        StartingBalance := CreateStartingBalance(GenJnlLine."Account Type"::Customer, Customer."No.", DebitAmount / 2);
        LibraryVariableStorage.Enqueue(CustomerPostingGroup."Receivables Account");

        // [WHEN] Save Customer Accounting Card report with "G/L Account Filter" = "RA"
        RunCustomerAccountingCard(Customer."No.", CustomerPostingGroup."Receivables Account");

        // [THEN] 'Debit Starting Balance' = "P0", 'Credit Starting Balance' is empty, 'Debit Ending Balance' = "P0+P", 'Credit Ending Balance' is empty
        VerifyPositiveCustomerAccountingCardValues(StartingBalance, DebitAmount);
    end;

    [Test]
    [HandlerFunctions('CustomerAccountingCardRequestPageHandler')]
    [Scope('OnPrem')]
    procedure NegativeCustomerAccountingCardReport()
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
        GenJnlLine: Record "Gen. Journal Line";
        CreditAmount: Decimal;
        StartingBalance: Decimal;
    begin
        // [FEATURE] [Reports]
        // [SCENARIO 378116] Report Customer Accounting Card shows negative Balance Amounts in Russian version
        Initialize();

        // [GIVEN] Create Customer with negative balance "N" on it's Receivables Account "RA"
        CreditAmount := InitCustomerWithBalanceForReport(Customer, CustomerPostingGroup, -1);

        // [GIVEN] Add negative entry on previous date with amount "N0"
        StartingBalance := CreateStartingBalance(GenJnlLine."Account Type"::Customer, Customer."No.", -CreditAmount / 2);
        LibraryVariableStorage.Enqueue(CustomerPostingGroup."Receivables Account");

        // [WHEN] Save Customer Accounting Card report with "G/L Account Filter" = "RA"
        RunCustomerAccountingCard(Customer."No.", CustomerPostingGroup."Receivables Account");

        // [THEN] 'Debit Starting Balance' is empty, 'Credit Starting Balance' = "N0", 'Debit Ending Balance' is empty, 'Credit Ending Balance' = "N0+N"
        VerifyNegativeCustomerAccountingCardValues(StartingBalance, CreditAmount);
    end;

    [Test]
    [HandlerFunctions('CustomerGLTurnoverRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerGLTurnoverReportTotalsCheck()
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
        StartingDebitAmount: Decimal;
        StartingCreditAmount: Decimal;
        StartingTotalAmount: Decimal;
    begin
        // [FEATURE] [Reports]
        // [SCENARIO 379014] Report Customer G/L Turnover detailed total verification.
        // [SCENARIO 224554] Report Customer G/L Turnover beginning and ending period totals verification when customers does have entries with customer agreements.

        // [GIVEN] Customer Posting Group with Receivables Account "RA".
        LibrarySales.CreateCustomerPostingGroup(CustomerPostingGroup);

        // [GIVEN] Two Customer Ledger Entries with total debit amount = "A" on 10/01/2017.
        // [GIVEN] Additional Customer Ledger Entry is posted with Customer Agreement on 10/01/2017.
        CreatePostCustomerEntryWithPostingGroup(Customer, CustomerPostingGroup.Code, 1);
        CreatePostCustomerEntryWithPostingGroupAndAgreement(CustomerPostingGroup.Code, 1);

        // [GIVEN] Two Customer Ledger Entries with total credit amount = "B" on 10/01/2017.
        CreatePostCustomerEntryWithPostingGroup(Customer, CustomerPostingGroup.Code, -1);
        CreatePostCustomerEntryWithPostingGroup(Customer, CustomerPostingGroup.Code, -1);

        // [GIVEN] StartingDebitAmount = "A", StartingCreditAmount = "B" and StartingTotalAmount = "C" with "G/L Account Filter" = "RA".
        CalculateCustomerStartingBalance(
          Customer, StartingDebitAmount, StartingCreditAmount, StartingTotalAmount,
          CustomerPostingGroup."Receivables Account", WorkDate() + 1);

        // [WHEN] Run "Customer G/L Turnover" report with "G/L Account Filter" = "RA" on 11/01/2017.
        RunCustomerGLTurnover(CustomerPostingGroup."Receivables Account", WorkDate() + 1, true);

        // [THEN] The totaling fields in the report read "Starting Debit Amount" = "A", "Starting Credit Amount" = "B", "Starting Total Amount" = "C".
        // [THEN] "Ending Debit Amount" = "A", "Ending Credit Amount" = "B", "Ending Total Amount" = "C".
        VerifyGLTurnoverValues(StartingDebitAmount, StartingCreditAmount, StartingTotalAmount, 0);
    end;

    [Test]
    [HandlerFunctions('VendorGLTurnoverExcelPageHandler')]
    [Scope('OnPrem')]
    procedure VendorGLTurnoverReportTotalsCheck()
    var
        Vendor: Record Vendor;
        VendorPostingGroup: Record "Vendor Posting Group";
        StartingDebitAmount: Decimal;
        StartingCreditAmount: Decimal;
        StartingTotalAmount: Decimal;
    begin
        // [FEATURE] [Reports]
        // [SCENARIO 379014] Totaling starting debit and credit amounts in "Vendor G/L Turnover" report should be equal to the sum of vendors' debit and credit amounts posted until the starting date.
        // [SCENARIO 224554] Report Vendor G/L Turnover beginning and ending period totals verification when some vendors have entries with vendor agreements.

        // [GIVEN] Vendor has Vendor Posting Group with Payables Account "PA".
        LibraryPurchase.CreateVendorPostingGroup(VendorPostingGroup);

        // [GIVEN] Two Vendor Ledger Entries with total credit amount = "A".
        // [GIVEN] Additional Vendor Ledger Entry is posted with Vendor Agreement on 10/01/2017
        CreateAndPostVendorEntryWithPostingGroup(Vendor, VendorPostingGroup.Code, 1);
        CreateAndPostVendorEntryWithPostingGroupAndAgreement(VendorPostingGroup.Code, 1);

        // [GIVEN] Two Vendor Ledger Entries with total credit amount = "B".
        CreateAndPostVendorEntryWithPostingGroup(Vendor, VendorPostingGroup.Code, -1);
        CreateAndPostVendorEntryWithPostingGroup(Vendor, VendorPostingGroup.Code, -1);

        // [GIVEN] StartingDebitAmount = "A", StartingCreditAmount = "B" and StartingTotalAmount = "C" with "G/L Account Filter" = "PA"
        CalculateVendorStartingBalance(
          StartingDebitAmount, StartingCreditAmount, StartingTotalAmount,
          VendorPostingGroup."Payables Account", WorkDate());

        // [WHEN] Run "Vendor G/L Turnover" report with G/L account filter = "PA" on 11/01/2017.
        RunVendorGLTurnover(VendorPostingGroup."Payables Account", LibraryRandom.RandDate(10));

        // [THEN] The totaling fields in the report read "Starting Debit Amount" = "A", "Starting Credit Amount" = "B", "Starting Total Amount" = "C".
        // [THEN] "Ending Debit Amount" = "A", "Ending Credit Amount" = "B", "Ending Total Amount" = "C".
        VerifyGLTurnoverValues(StartingDebitAmount, StartingCreditAmount, StartingTotalAmount, 1);
    end;

    [Test]
    [HandlerFunctions('CustomerGLTurnoverHandler')]
    [Scope('OnPrem')]
    procedure CustomerWithCustomerAgreementsGLTurnoverReportTotalsCheck()
    var
        Item: Record Item;
        Customer: Record Customer;
        CustomerAgreement: Record "Customer Agreement";
        CustomerPostingGroup: Record "Customer Posting Group";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Reports] [Customer G/L Turnover]
        // [SCENARIO 233086] Customer G/L Turnover report detailed totals should be sum of all "customer lines", no matter how many agreements each of customers has.

        Initialize();

        // [GIVEN] Create customer with posting group and two customer agreements
        CreateCustomerWithPostingGroupAndAgreements(Customer, CustomerAgreement);

        // [GIVEN] Create item with some stock
        LibraryInventory.CreateItem(Item);
        LibraryRUReports.CreateAndPostItemJournalLine('', Item."No.", LibraryRandom.RandInt(100), false);

        // [GIVEN] Sell 1 pcs of the Item to the customer to obtain some Debit amount for the customer
        CreateAndPostSaleWithAgreement(CustomerAgreement, Item."No.", 1);

        // [GIVEN] Post random payment for the customer in order to obtain some Credit amount as well
        CreateAndPostCustomerPaymentWithAgreement(GenJournalLine, Customer."No.", CustomerAgreement."No.", -LibraryRandom.RandInt(100));

        // [WHEN] Run "Customer G/L Turnover" report for the single created above customer
        Customer.SetFilter("Date Filter", Format(WorkDate()));
        Customer.SetRecFilter();
        REPORT.Run(REPORT::"Customer G/L Turnover", true, false, Customer);

        // [THEN] Customer Debit Amount and Customer Credit Amount must be equal to the detailed totals respectively
        CustomerPostingGroup.Get(Customer."Customer Posting Group");
        Customer.SetFilter(
          "G/L Account Filter", '%1|%2',
          CustomerPostingGroup."Receivables Account", CustomerPostingGroup."Prepayment Account");
        Customer.CalcFields("G/L Debit Amount", "G/L Credit Amount");
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('TotalGLDebitAmount', Customer."G/L Debit Amount");
        LibraryReportDataset.AssertElementWithValueExists('TotalGLCreditAmount', Customer."G/L Credit Amount");
    end;

    [Test]
    [HandlerFunctions('VendorGLTurnoverHandler')]
    [Scope('OnPrem')]
    procedure VendorWithVendorAgreementsGLTurnoverReportTotalsCheck()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        VendorAgreement: Record "Vendor Agreement";
        VendorPostingGroup: Record "Vendor Posting Group";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Reports] [Vendor G/L Turnover]
        // [SCENARIO 233086] Vendor G/L Turnover report detailed totals should be sum of all "vendor lines", no matter how many agreements each of vendors has.

        Initialize();

        // [GIVEN] Create vendor with posting group and two vendor agreements
        CreateVendorWithPostingGroupAndAgreements(Vendor, VendorAgreement);

        // [GIVEN] Create item
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Purchase 1 pcs of the Item from the vendor to obtain some Credit amount
        CreateAndPostPurchWithAgreement(VendorAgreement, Item."No.", 1);

        // [GIVEN] Post random payment to the vendor in order to get some Debit amount
        CreateAndPostVendorPaymentWithAgreement(GenJournalLine, Vendor."No.", VendorAgreement."No.", LibraryRandom.RandInt(100));

        // [WHEN] Run "Vendor G/L Turnover" report for the single created above vendor
        Vendor.SetFilter("Date Filter", Format(WorkDate()));
        Vendor.SetRecFilter();
        REPORT.Run(REPORT::"Vendor G/L Turnover", true, false, Vendor);

        // [THEN] Vendor Debit Amount and Vendor Credit Amount must be equal to the detailed totals respectively
        VendorPostingGroup.Get(Vendor."Vendor Posting Group");
        Vendor.SetFilter(
          "G/L Account Filter", '%1|%2',
          VendorPostingGroup."Payables Account", VendorPostingGroup."Prepayment Account");
        Vendor.CalcFields("G/L Debit Amount", "G/L Credit Amount");
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('TotalGLDebitAmount', Vendor."G/L Debit Amount");
        LibraryReportDataset.AssertElementWithValueExists('TotalGLCreditAmount', Vendor."G/L Credit Amount");
    end;

    [Test]
    [HandlerFunctions('GLAccountCardHandler')]
    [Scope('OnPrem')]
    procedure GLAccountCardReportWithSourceTypeFilterCheck()
    var
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        GLEntry2: Record "G/L Entry";
        GLAccNo: Code[20];
        DebitAmount: Decimal;
        DebitAmount2: Decimal;
    begin
        // [FEATURE] [G/L Account Card]
        // [SCENARIO 275406] G/L Account Card report is affected by Source Type Filter
        Initialize();

        // [GIVEN] G/L Account with No equal to "Z"
        GLAccNo := LibraryERM.CreateGLAccountNo();
        // [GIVEN] G/L Entry with Debit Amount "X" and Source Type "Customer"
        DebitAmount := LibraryRandom.RandDec(100, 2);
        CreateGLEntryWithSourceTypeAndSourceNo(GLEntry, GLAccNo, DebitAmount, GLEntry."Source Type"::Customer, '');
        // [GIVEN] G/L Entry2 with Debit Amount "Y" and Source Type "Bank Account"
        DebitAmount2 := DebitAmount + LibraryRandom.RandDec(100, 2);
        CreateGLEntryWithSourceTypeAndSourceNo(GLEntry2, GLAccNo, DebitAmount2, GLEntry2."Source Type"::"Bank Account", '');

        // [WHEN] G/L Account Card report is run with Source Type Filter is set to "Customer"
        SetGLAccountSourceTypeAndSourceNoFilters(GLAccount, GLAccNo, GLEntry."Source Type"::Customer, '');
        RunGLAccountCardReport(GLAccount);

        // [THEN] In the report G/L Account No equals to "Z" and Balance Ending equals Debit Amount "X"
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('GLAcc_No_', GLAccNo);
        LibraryReportDataset.AssertElementWithValueExists('BalanceEnding', DebitAmount);
    end;

    [Test]
    [HandlerFunctions('GLAccountCardHandler')]
    [Scope('OnPrem')]
    procedure GLAccountCardReportWithSourceNoFilterCheck()
    var
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        GLEntry2: Record "G/L Entry";
        DebitAmount: Decimal;
        DebitAmount2: Decimal;
        GLAccNo: Code[20];
        CustomerNo: Code[20];
        CustomerNo2: Code[20];
    begin
        // [FEATURE] [G/L Account Card]
        // [SCENARIO 275406] G/L Account Card report is affected by Source No Filter
        Initialize();

        // [GIVEN] G/L Account with No equal to "Z"
        GLAccNo := LibraryERM.CreateGLAccountNo();
        // [GIVEN] G/L Entry with Debit Amount "X" and Source No "A"
        DebitAmount := LibraryRandom.RandDec(100, 2);
        CustomerNo := LibraryUtility.GenerateGUID();
        CreateGLEntryWithSourceTypeAndSourceNo(GLEntry, GLAccNo, DebitAmount, "Gen. Journal Source Type"::" ", CustomerNo);
        // [GIVEN] G/L Entry2 with Debit Amount "Y" and Source No "B"
        DebitAmount2 := DebitAmount + LibraryRandom.RandDec(100, 2);
        CustomerNo2 := LibraryUtility.GenerateGUID();
        CreateGLEntryWithSourceTypeAndSourceNo(GLEntry2, GLAccNo, DebitAmount2, "Gen. Journal Source Type"::" ", CustomerNo2);

        // [WHEN] G/L Account Card report is run with Source No Filter is set to "A"
        SetGLAccountSourceTypeAndSourceNoFilters(GLAccount, GLAccNo, "Gen. Journal Source Type"::" ", CustomerNo);
        RunGLAccountCardReport(GLAccount);

        // [THEN] In the report G/L Account No equals to "Z" and Balance Ending equals Debit Amount "X"
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('GLAcc_No_', GLAccNo);
        LibraryReportDataset.AssertElementWithValueExists('BalanceEnding', DebitAmount);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        Clear(LibraryReportValidation);

        if IsInitialized then
            exit;

        LibraryERMCountryData.UpdateGeneralPostingSetup();

        IsInitialized := true;
        Commit();
    end;

    local procedure InitCustomerForReport(var Customer: Record Customer) Amount: Decimal
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        Amount := CreatePostGenJnlLine(GenJnlLine."Account Type"::Customer, Customer."No.", 1);

        Customer.SetFilter("Date Filter", Format(WorkDate()));
        Customer.SetRecFilter();
    end;

    local procedure InitVendorForReport(var Vendor: Record Vendor) Amount: Decimal
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        Amount := CreatePostGenJnlLine(GenJnlLine."Account Type"::Vendor, Vendor."No.", 1);

        Vendor.SetFilter("Date Filter", Format(WorkDate()));
        Vendor.SetRecFilter();
    end;

    local procedure InitBankAccountForReport(var BankAccount: Record "Bank Account") Amount: Decimal
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        Initialize();
        LibraryERM.CreateBankAccount(BankAccount);
        Amount := CreatePostGenJnlLine(GenJnlLine."Account Type"::"Bank Account", BankAccount."No.", 1);

        BankAccount.SetRecFilter();
    end;

    local procedure InitFixedAssetForReport(var FixedAsset: Record "Fixed Asset") Amount: Decimal
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        Initialize();
        LibraryFixedAsset.CreateFixedAssetWithSetup(FixedAsset);
        Amount := CreatePostGenJnlLine(GenJnlLine."Account Type"::"Fixed Asset", FixedAsset."No.", 1);

        FixedAsset.SetFilter("Date Filter", Format(WorkDate()));
        FixedAsset.SetRecFilter();
    end;

    local procedure InitGLAccountWithBalance(var GLAccountNo: Code[20]; var Amount: Decimal)
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        Initialize();
        GLAccountNo := LibraryERM.CreateGLAccountNo();
        Amount := CreatePostGenJnlLine(GenJnlLine."Account Type"::"G/L Account", GLAccountNo, 1);
    end;

    local procedure PrepareGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; AccType: Enum "Gen. Journal Account Type"; AccNo: Code[20]; Sign: Integer)
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        Amount: Decimal;
    begin
        if Sign > 0 then // Debit Amount will always be greater than Credit Amount
            Amount := LibraryRandom.RandDecInRange(200, 300, 2)
        else
            Amount := LibraryRandom.RandDecInRange(100, 200, 2);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          "Gen. Journal Document Type"::" ", AccType, AccNo,
          GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), Amount * Sign);
        UpdateFAPostingType(GenJournalLine);
    end;

    local procedure CreatePostGenJnlLine(AccType: Enum "Gen. Journal Account Type"; AccNo: Code[20]; Sign: Integer): Decimal
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        PrepareGenJnlLine(GenJournalLine, AccType, AccNo, Sign);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine.Amount * Sign);
    end;

    local procedure CreatePostGenJnlLineWithAgreement(AccType: Enum "Gen. Journal Account Type"; AccNo: Code[20]; Sign: Integer; AgreementCode: Code[20]): Decimal
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        PrepareGenJnlLine(GenJournalLine, AccType, AccNo, Sign);
        UpdateAgreementCode(GenJournalLine, AgreementCode);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine.Amount * Sign);
    end;

    local procedure CreateCustomerWithPostingGroup(var Customer: Record Customer; CustomerPostingGroupCode: Code[20])
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Customer Posting Group", CustomerPostingGroupCode);
        Customer.Modify(true);
    end;

    local procedure CreateVendorWithPostingGroup(var Vendor: Record Vendor; VendorPostingGroupCode: Code[20])
    begin
        Vendor.Get(LibraryPurchase.CreateVendorNo());
        Vendor.Validate("Vendor Posting Group", VendorPostingGroupCode);
        Vendor.Modify(true);
    end;

    local procedure CreateCustomerWithPostingGroupAndAgreements(var Customer: Record Customer; var CustomerAgreement: Record "Customer Agreement")
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        LibrarySales.CreateCustomerPostingGroup(CustomerPostingGroup);
        CreateCustomerWithPostingGroup(Customer, CustomerPostingGroup.Code);
        Customer.Validate("Agreement Posting", Customer."Agreement Posting"::Mandatory);
        Customer.Modify(true);
        CreateCustomerAgreement(CustomerAgreement, Customer);
        CreateCustomerAgreement(CustomerAgreement, Customer);
    end;

    local procedure CreateVendorWithPostingGroupAndAgreements(var Vendor: Record Vendor; var VendorAgreement: Record "Vendor Agreement")
    var
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreateVendorPostingGroup(VendorPostingGroup);
        VendorPostingGroup.Validate("Payables Account", LibraryERM.CreateGLAccountNo());
        VendorPostingGroup.Modify(true);
        Vendor.Validate("Vendor Posting Group", VendorPostingGroup.Code);
        Vendor.Validate("Agreement Posting", Vendor."Agreement Posting"::Mandatory);
        Vendor.Modify(true);
        CreateVendorAgreement(VendorAgreement, Vendor);
        CreateVendorAgreement(VendorAgreement, Vendor);
    end;

    local procedure CreateAndPostCustomerPaymentWithAgreement(var GenJournalLine: Record "Gen. Journal Line"; CustomerNo: Code[20]; AgreementNo: Code[20]; Amount: Decimal)
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Customer, CustomerNo, Amount);
        GenJournalLine.Validate("Agreement No.", AgreementNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndPostVendorPaymentWithAgreement(var GenJournalLine: Record "Gen. Journal Line"; VendorNo: Code[20]; AgreementNo: Code[20]; Amount: Decimal)
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Vendor, VendorNo, Amount);
        GenJournalLine.Validate("Agreement No.", AgreementNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreatePostCustomerEntryWithPostingGroup(var Customer: Record Customer; CustomerPostingGroupCode: Code[20]; Sign: Integer)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateCustomerWithPostingGroup(Customer, CustomerPostingGroupCode);
        CreatePostGenJnlLine(GenJournalLine."Account Type"::Customer, Customer."No.", Sign);
    end;

    local procedure CreatePostCustomerEntryWithPostingGroupAndAgreement(CustomerPostingGroupCode: Code[20]; Sign: Integer)
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        CustomerAgreement: Record "Customer Agreement";
    begin
        CreatePostCustomerEntryWithPostingGroup(Customer, CustomerPostingGroupCode, Sign);
        Customer.Validate("Agreement Posting", Customer."Agreement Posting"::Mandatory);
        Customer.Modify(true);
        CreateCustomerAgreement(CustomerAgreement, Customer);
        CreatePostGenJnlLineWithAgreement(
          GenJournalLine."Account Type"::Customer, Customer."No.",
          Sign, CustomerAgreement."No.");
    end;

    local procedure CreateAndPostSaleWithAgreement(CustomerAgreement: Record "Customer Agreement"; ItemNo: Code[20]; Quantity: Decimal)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Order, CustomerAgreement."Customer No.");
        SalesHeader.Validate("Agreement No.", CustomerAgreement."No.");
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Unit Price", LibraryRandom.RandInt(100));
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreateAndPostPurchWithAgreement(VendorAgreement: Record "Vendor Agreement"; ItemNo: Code[20]; Quantity: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorAgreement."Vendor No.");
        PurchaseHeader.Validate("Agreement No.", VendorAgreement."No.");
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(100));
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreateAndPostVendorEntryWithPostingGroup(var Vendor: Record Vendor; VendorPostingGroupCode: Code[20]; Sign: Integer)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateVendorWithPostingGroup(Vendor, VendorPostingGroupCode);
        CreatePostGenJnlLine(GenJournalLine."Account Type"::Vendor, Vendor."No.", Sign);
    end;

    local procedure CreateAndPostVendorEntryWithPostingGroupAndAgreement(VendorPostingGroupCode: Code[20]; Sign: Integer)
    var
        Vendor: Record Vendor;
        VendorAgreement: Record "Vendor Agreement";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateAndPostVendorEntryWithPostingGroup(Vendor, VendorPostingGroupCode, Sign);
        Vendor.Validate("Agreement Posting", Vendor."Agreement Posting"::Mandatory);
        Vendor.Modify(true);
        CreateVendorAgreement(VendorAgreement, Vendor);
        CreatePostGenJnlLineWithAgreement(
          GenJournalLine."Account Type"::Vendor, Vendor."No.", Sign,
          VendorAgreement."No.");
    end;

    local procedure CreateFAWithoutBooks(var FixedAsset: Record "Fixed Asset")
    var
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        LibraryFixedAsset.CreateFixedAssetWithSetup(FixedAsset);
        FADepreciationBook.SetRange("FA No.", FixedAsset."No.");
        FADepreciationBook.DeleteAll(true);
    end;

    local procedure CreateVendorAgreement(var VendorAgreement: Record "Vendor Agreement"; Vendor: Record Vendor)
    begin
        VendorAgreement.Init();
        VendorAgreement."No." := LibraryUtility.GenerateGUID();
        VendorAgreement.Validate("Vendor No.", Vendor."No.");
        VendorAgreement.Validate("Expire Date", CalcDate('<1M>', WorkDate()));
        VendorAgreement.Validate("Vendor Posting Group", Vendor."Vendor Posting Group");
        VendorAgreement.Validate("VAT Bus. Posting Group", Vendor."VAT Bus. Posting Group");
        VendorAgreement.Validate("Gen. Bus. Posting Group", Vendor."Gen. Bus. Posting Group");
        VendorAgreement.Validate(Active, true);
        VendorAgreement.Insert(true);
    end;

    local procedure CreateCustomerAgreement(var CustomerAgreement: Record "Customer Agreement"; Customer: Record Customer)
    begin
        CustomerAgreement.Init();
        CustomerAgreement."No." := LibraryUtility.GenerateGUID();
        CustomerAgreement.Validate("Customer No.", Customer."No.");
        CustomerAgreement.Validate("Expire Date", CalcDate('<1M>', WorkDate()));
        CustomerAgreement.Validate("Customer Posting Group", Customer."Customer Posting Group");
        CustomerAgreement.Validate("VAT Bus. Posting Group", Customer."VAT Bus. Posting Group");
        CustomerAgreement.Validate("Gen. Bus. Posting Group", Customer."Gen. Bus. Posting Group");
        CustomerAgreement.Validate(Active, true);
        CustomerAgreement.Insert(true);
    end;

    local procedure CreateGLEntryWithSourceTypeAndSourceNo(var GLEntry: Record "G/L Entry"; GLAccNo: Code[20]; DebitAmount: Decimal; SourceType: Enum "Gen. Journal Source Type"; SourceNo: Code[20])
    begin
        GLEntry.Init();
        GLEntry."Entry No." := LibraryUtility.GetNewRecNo(GLEntry, GLEntry.FieldNo("Entry No."));
        GLEntry."Posting Date" := WorkDate();
        GLEntry."G/L Account No." := GLAccNo;
        GLEntry."Debit Amount" := DebitAmount;
        GLEntry."Source Type" := SourceType;
        GLEntry."Source No." := SourceNo;
        GLEntry.Insert();
    end;

    local procedure CalculateCustomerStartingBalance(var Customer: Record Customer; var StartingDebitAmount: Decimal; var StartingCreditAmount: Decimal; var StartTotalAmount: Decimal; GLAccountNo: Code[20]; StartingDate: Date)
    begin
        Customer.Reset();
        Customer.SetRange("Date Filter", 0D, StartingDate - 1);
        Customer.SetRange("G/L Account Filter", GLAccountNo);
        Customer.SetAutoCalcFields("G/L Credit Amount", "G/L Debit Amount", "G/L Starting Balance");
        Customer.FindSet();
        repeat
            StartingDebitAmount += Customer."G/L Debit Amount";
            StartingCreditAmount += Customer."G/L Credit Amount";
            StartTotalAmount += Customer."G/L Starting Balance";
        until Customer.Next() = 0;
    end;

    local procedure CalculateVendorStartingBalance(var StartingDebitAmount: Decimal; var StartingCreditAmount: Decimal; var StartingTotalAmount: Decimal; GLAccountNo: Code[20]; StartingDate: Date)
    var
        Vendor: Record Vendor;
    begin
        Vendor.SetRange("Date Filter", 0D, StartingDate);
        Vendor.SetRange("G/L Account Filter", GLAccountNo);
        Vendor.SetAutoCalcFields("G/L Debit Amount", "G/L Credit Amount", "G/L Balance to Date");
        Vendor.FindSet();
        repeat
            StartingDebitAmount += Vendor."G/L Debit Amount";
            StartingCreditAmount += Vendor."G/L Credit Amount";
            StartingTotalAmount += Vendor."G/L Balance to Date";
        until Vendor.Next() = 0;
    end;

    local procedure SetGLAccountFilters(var GLAccount: Record "G/L Account"; GLAccNo: Code[20])
    begin
        GLAccount.Get(GLAccNo);
        GLAccount.SetFilter("Date Filter", Format(WorkDate()));
        GLAccount.SetRecFilter();
    end;

    local procedure SetGLAccountSourceTypeAndSourceNoFilters(var GLAccount: Record "G/L Account"; GLAccNo: Code[20]; SourceType: Enum "Gen. Journal Source Type"; CustomerNo: Code[20])
    begin
        GLAccount.Get(GLAccNo);
        GLAccount.SetFilter("Date Filter", Format(WorkDate()));
        GLAccount.SetFilter("Source Type Filter", '%1', SourceType);
        GLAccount.SetFilter("Source No. Filter", '%1', CustomerNo);
        GLAccount.SetRecFilter();
    end;

    local procedure UpdateFAPostingType(var GenJnlLine: Record "Gen. Journal Line")
    begin
        if GenJnlLine."Account Type" <> GenJnlLine."Account Type"::"Fixed Asset" then
            exit;

        GenJnlLine.Validate("FA Posting Type", GenJnlLine."FA Posting Type"::"Acquisition Cost");
        GenJnlLine.Modify(true);
    end;

    local procedure UpdateAgreementCode(var GenJournalLine: Record "Gen. Journal Line"; AgreementCode: Code[20])
    begin
        GenJournalLine.Validate("Agreement No.", AgreementCode);
        GenJournalLine.Modify(true);
    end;

    local procedure FormatValue(Amount: Decimal; Decimals: Integer): Text
    begin
        exit(Format(Amount, 0, '<Sign><Integer Thousand><Decimals,' + Format(Decimals) + '>'));
    end;

    local procedure CreateStartingBalance(AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal): Decimal
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(GenJnlLine, GenJnlLine."Document Type"::" ", AccountType, AccountNo, Amount);
        GenJnlLine.Validate("Posting Date", GenJnlLine."Posting Date" - 1);
        GenJnlLine.Modify(true);

        LibraryERM.PostGeneralJnlLine(GenJnlLine);
        exit(Abs(GenJnlLine.Amount));
    end;

    local procedure InitCustomerWithBalanceForReport(var Customer: Record Customer; var CustomerPostingGroup: Record "Customer Posting Group"; Sign: Integer) Amount: Decimal
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        LibrarySales.CreateCustomerPostingGroup(CustomerPostingGroup);
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Customer Posting Group", CustomerPostingGroup.Code);
        Customer.Modify(true);

        Amount := CreatePostGenJnlLine(GenJnlLine."Account Type"::Customer, Customer."No.", Sign);

        Customer.SetFilter("Date Filter", Format(WorkDate()));
        Customer.SetRecFilter();
    end;

    local procedure RunCustomerAccountingCard(CustomerNo: Code[20]; GLAccountNo: Code[20])
    var
        Customer: Record Customer;
        CustomerAccountingCard: Report "Customer Accounting Card";
    begin
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());
        LibraryVariableStorage.Enqueue(LibraryReportValidation.GetFileName());
        Commit();

        Customer.SetRange("No.", CustomerNo);
        Customer.SetRange("Date Filter", WorkDate());
        Customer.SetRange("G/L Account Filter", GLAccountNo);
        Clear(CustomerAccountingCard);
        CustomerAccountingCard.SetTableView(Customer);
        CustomerAccountingCard.UseRequestPage(true);
        CustomerAccountingCard.Run();
    end;

    local procedure RunCustomerGLTurnover(GLAccountNo: Code[20]; ReportDate: Date; SkipZeroLines: Boolean)
    var
        Customer: Record Customer;
        CustomerGLTurnover: Report "Customer G/L Turnover";
    begin
        LibraryVariableStorage.Enqueue(SkipZeroLines);
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());
        LibraryVariableStorage.Enqueue(LibraryReportValidation.GetFileName());
        Commit();

        Customer.SetRange("Date Filter", ReportDate);
        Customer.SetRange("G/L Account Filter", GLAccountNo);
        CustomerGLTurnover.SetTableView(Customer);
        CustomerGLTurnover.UseRequestPage(true);
        CustomerGLTurnover.Run();
    end;

    local procedure RunGLAccountCardReport(var GLAccount: Record "G/L Account")
    var
        GLAccountCard: Report "G/L Account Card";
    begin
        Commit();
        Clear(GLAccountCard);
        GLAccountCard.SetTableView(GLAccount);
        GLAccountCard.Run();
    end;

    local procedure RunVendorGLTurnover(GLAccountNo: Code[20]; ReportDate: Date)
    var
        Vendor: Record Vendor;
    begin
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());
        LibraryVariableStorage.Enqueue(LibraryReportValidation.GetFileName());
        Commit();

        Vendor.SetRange("Date Filter", ReportDate);
        Vendor.SetRange("G/L Account Filter", GLAccountNo);
        REPORT.RunModal(REPORT::"Vendor G/L Turnover", true, false, Vendor);
    end;

    local procedure RunFATurnover(FANoFilter: Text; DepreciationBookCode: Code[10])
    var
        FixedAsset: Record "Fixed Asset";
        FATurnover: Report "FA Turnover";
    begin
        LibraryVariableStorage.Enqueue(DepreciationBookCode);
        FixedAsset.SetFilter("No.", FANoFilter);
        FixedAsset.FilterGroup(2); // need to prevent report's "No." filter reset
        Commit();
        Clear(FATurnover);
        FATurnover.SetTableView(FixedAsset);
        FATurnover.Run();
    end;

    local procedure VerifyPositiveCustomerAccountingCardValues(StartingBalance: Decimal; Amount: Decimal)
    begin
        LibraryReportValidation.OpenExcelFile();
        LibraryReportValidation.VerifyCellValue(11, 5, LibraryReportValidation.FormatDecimalValue(StartingBalance));
        LibraryReportValidation.VerifyCellValue(11, 6, '');
        LibraryReportValidation.VerifyCellValue(18, 5, LibraryReportValidation.FormatDecimalValue(StartingBalance + Amount));
        LibraryReportValidation.VerifyCellValue(18, 6, '');
    end;

    local procedure VerifyNegativeCustomerAccountingCardValues(StartingBalance: Decimal; Amount: Decimal)
    begin
        LibraryReportValidation.OpenExcelFile();
        LibraryReportValidation.VerifyCellValue(11, 5, '');
        LibraryReportValidation.VerifyCellValue(11, 6, LibraryReportValidation.FormatDecimalValue(StartingBalance));
        LibraryReportValidation.VerifyCellValue(18, 5, '');
        LibraryReportValidation.VerifyCellValue(18, 6, LibraryReportValidation.FormatDecimalValue(StartingBalance + Amount));
    end;

    local procedure VerifyFATurnoverValues(RowNo: Integer; FANo: Code[20]; Acquisition: Decimal; Depreciation: Decimal)
    begin
        LibraryReportValidation.VerifyCellValueByRef('C', RowNo, 1, FANo);
        LibraryReportValidation.VerifyCellValueByRef('X', RowNo, 1, LibraryReportValidation.FormatDecimalValue(Acquisition));
        LibraryReportValidation.VerifyCellValueByRef('Z', RowNo, 1, LibraryReportValidation.FormatDecimalValue(Depreciation));
    end;

    local procedure VerifyFATurnoverTotalValues(RowNo: Integer; Acquisition: Decimal; Depreciation: Decimal)
    begin
        LibraryReportValidation.VerifyCellValueByRef('X', RowNo, 1, LibraryReportValidation.FormatDecimalValue(Acquisition));
        LibraryReportValidation.VerifyCellValueByRef('Z', RowNo, 1, LibraryReportValidation.FormatDecimalValue(Depreciation));
    end;

    local procedure VerifyGLTurnoverValues(StartingDebitAmount: Decimal; StartingCreditAmount: Decimal; StartTotalAmount: Decimal; Offset: Integer)
    begin
        LibraryReportValidation.OpenExcelFile();

        // beginning period detailed total
        LibraryReportValidation.VerifyCellValue(16 + Offset, 9, LibraryReportValidation.FormatDecimalValue(StartingDebitAmount));
        LibraryReportValidation.VerifyCellValue(16 + Offset, 11, LibraryReportValidation.FormatDecimalValue(StartingCreditAmount));
        // beginning period total
        LibraryReportValidation.VerifyCellValue(17 + Offset, 9, LibraryReportValidation.FormatDecimalValue(StartTotalAmount));
        LibraryReportValidation.VerifyCellValue(17 + Offset, 11, '');

        // ending period detailed total
        LibraryReportValidation.VerifyCellValue(16 + Offset, 19, LibraryReportValidation.FormatDecimalValue(StartingDebitAmount));
        LibraryReportValidation.VerifyCellValue(16 + Offset, 24, LibraryReportValidation.FormatDecimalValue(StartingCreditAmount));
        // ending period total
        LibraryReportValidation.VerifyCellValue(17 + Offset, 19, LibraryReportValidation.FormatDecimalValue(StartTotalAmount));
        LibraryReportValidation.VerifyCellValue(17 + Offset, 24, '')
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GLCorrGLReportHandler(var GLCorrGeneralLedgerReport: TestRequestPage "G/L Corresp. General Ledger")
    begin
        GLCorrGeneralLedgerReport.PeriodBegining.Lookup();
        GLCorrGeneralLedgerReport.PeriodEnding.Lookup();
        GLCorrGeneralLedgerReport.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GLCorrJnlOrderReportHandler(var GLCorrJournalOrderReport: TestRequestPage "G/L Corresp. Journal Order")
    begin
        GLCorrJournalOrderReport.PeriodBegining.Lookup();
        GLCorrJournalOrderReport.PeriodEnding.Lookup();
        GLCorrJournalOrderReport.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GLCorrEntriesAnalysisReportHandler(var GLCorrEntriesAnalysisReport: TestRequestPage "G/L Corresp Entries Analysis")
    begin
        GLCorrEntriesAnalysisReport.PeriodBeginning.SetValue(WorkDate());
        GLCorrEntriesAnalysisReport.EndingOfPeriod.SetValue(WorkDate());
        GLCorrEntriesAnalysisReport.DebitCreditSeparately.SetValue(WorkDate());
        GLCorrEntriesAnalysisReport.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GLAccountTurnoverHandler(var GLAccountTurnoverReport: TestRequestPage "G/L Account Turnover")
    begin
        GLAccountTurnoverReport.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GLAccountCardHandler(var GLAccountCard: TestRequestPage "G/L Account Card")
    begin
        GLAccountCard.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GLAccountEntriesAnalysisHandler(var GLAccountEntriesAnalysis: TestRequestPage "G/L Account Entries Analysis")
    begin
        GLAccountEntriesAnalysis.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BankAccountGLTurnoverHandler(var BankAccountGLTurnover: TestRequestPage "Bank Account G/L Turnover")
    begin
        BankAccountGLTurnover."Starting Date".SetValue(WorkDate());
        BankAccountGLTurnover."Ending Date".SetValue(WorkDate());
        BankAccountGLTurnover.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerGLTurnoverHandler(var CustomerGLTurnover: TestRequestPage "Customer G/L Turnover")
    begin
        CustomerGLTurnover.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VendorGLTurnoverHandler(var VendorGLTurnover: TestRequestPage "Vendor G/L Turnover")
    begin
        VendorGLTurnover.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure FAGLTurnoverHandler(var FAGLTurnover: TestRequestPage "Fixed Asset G/L Turnover")
    begin
        FAGLTurnover.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SelectPeriodPageHandler(var SelectReportingPeriod: TestPage "Select Reporting Period")
    var
        DatePeriod: Record Date;
    begin
        SelectReportingPeriod.FILTER.SetFilter("Period Type", Format(DatePeriod."Period Type"::Month));
        SelectReportingPeriod.FILTER.SetFilter("Period End", Format(ClosingDate(CalcDate('<CM>', WorkDate()))));
        SelectReportingPeriod.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerTurnoverHandler(var CustomerTurnover: TestRequestPage "Customer Turnover")
    begin
        CustomerTurnover.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerPostGrTurnoverHandler(var CustomerPostGrTurnover: TestRequestPage "Customer Post. Gr. Turnover")
    begin
        CustomerPostGrTurnover.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VendorTurnoverHandler(var VendorTurnover: TestRequestPage "Vendor Turnover")
    begin
        VendorTurnover.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VendorPostGrTurnoverHandler(var VendorPostGrTurnover: TestRequestPage "Vendor Post. Gr. Turnover")
    begin
        VendorPostGrTurnover.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure FATurnoverHandler(var FATurnover: TestRequestPage "FA Turnover")
    begin
        FATurnover."Starting Date".SetValue(WorkDate());
        FATurnover."Ending Date".SetValue(WorkDate());
        FATurnover."Depreciation Book Code".SetValue(LibraryVariableStorage.DequeueText());
        FATurnover."Skip zero lines".SetValue(true);
        FATurnover.SaveAsExcel(LibraryReportValidation.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ItemTurnoverHandler(var ItemTurnover: TestRequestPage "Item Turnover (Qty.)")
    begin
        ItemTurnover.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerAccountingCardHandler(var CustomerAccountingCard: TestRequestPage "Customer Accounting Card")
    begin
        CustomerAccountingCard.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerEntriesAnalysisHandler(var CustomerEntriesAnalysis: TestRequestPage "Customer Entries Analysis")
    begin
        CustomerEntriesAnalysis.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VendorAccountingCardHandler(var VendorAccountingCard: TestRequestPage "Vendor Accounting Card")
    begin
        VendorAccountingCard.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VendorEntriesAnalysisHandler(var VendorEntriesAnalysis: TestRequestPage "Vendor Entries Analysis")
    begin
        VendorEntriesAnalysis.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BankAccountCardHandler(var BankAccountCard: TestRequestPage "Bank Account Card")
    begin
        BankAccountCard.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerAccountingCardRequestPageHandler(var CustomerAccountingCard: TestRequestPage "Customer Accounting Card")
    begin
        CustomerAccountingCard.Customer.SetFilter("Date Filter", Format(WorkDate()));
        CustomerAccountingCard.Customer.SetFilter("G/L Account Filter", LibraryVariableStorage.DequeueText());
        CustomerAccountingCard.SaveAsExcel(LibraryVariableStorage.DequeueText());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerGLTurnoverRequestPageHandler(var CustomerGLTurnover: TestRequestPage "Customer G/L Turnover")
    begin
        CustomerGLTurnover."Skip zero lines".SetValue(LibraryVariableStorage.DequeueBoolean());
        CustomerGLTurnover.SaveAsExcel(LibraryVariableStorage.DequeueText());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VendorGLTurnoverExcelPageHandler(var VendorGLTurnover: TestRequestPage "Vendor G/L Turnover")
    begin
        VendorGLTurnover."Skip zero lines".SetValue(true);
        VendorGLTurnover.SaveAsExcel(LibraryVariableStorage.DequeueText());
    end;
}

