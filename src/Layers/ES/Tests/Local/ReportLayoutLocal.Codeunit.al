codeunit 144002 "Report Layout - Local"
{
    // // [FEATURE] [Report]

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        isInitialized := false;
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        isInitialized: Boolean;
        GLAccountNoLbl: Label 'G_L_Entry__G_L_Account_No__';

    [Test]
    [HandlerFunctions('RHCustomerAnnualDeclaration')]
    [Scope('OnPrem')]
    procedure TestCustomerAnnualDeclaration()
    begin
        Initialize();
        REPORT.Run(REPORT::"Customer - Annual Declaration");
    end;

    [Test]
    [HandlerFunctions('RHVendorAnnualDeclaration')]
    [Scope('OnPrem')]
    procedure TestVendorAnnualDeclaration()
    begin
        Initialize();
        REPORT.Run(REPORT::"Vendor - Annual Declaration");
    end;

    [Test]
    [HandlerFunctions('RHAccountOfficialAccBook')]
    [Scope('OnPrem')]
    procedure TestAccountOfficialAccBook()
    begin
        // [FEATURE] [Account - Official Acc. Book]
        Initialize();
        REPORT.Run(REPORT::"Account - Official Acc. Book");
    end;

    [Test]
    [HandlerFunctions('RHAccountOfficialAccBookXML')]
    [Scope('OnPrem')]
    procedure TestAccountOfficialAccBookFirstPeriodXML()
    var
        GLAccFrom: Code[20];
        GLAccTo: Code[20];
        DateFrom: Date;
        DateTo: Date;
    begin
        // [FEATURE] [Account - Official Acc. Book]
        // [SCENARIO 377046] Print 'Account Official Acc.Book' for first period when G/L Register has G/L Entries in different periods
        Initialize();

        // [GIVEN] G/L Register with Posting Date = Date1 for two G/L Entries with G/L Account "A1" on Date1, "A2" on Date2
        MockRegisterWithGLEntries(GLAccFrom, GLAccTo, DateFrom, DateTo);

        // [WHEN] Run 'Account - Official Acc. Book' report on Date1
        RunAccountOfficialAccBookReport(Format(DateFrom));

        // [THEN] G/L Account "A1" is printed in the report
        // [THEN] G/L Account "A2" is not printed in the report
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(GLAccountNoLbl, GLAccFrom);
        LibraryReportDataset.AssertElementWithValueNotExist(GLAccountNoLbl, GLAccTo);
    end;

    [Test]
    [HandlerFunctions('RHAccountOfficialAccBookXML')]
    [Scope('OnPrem')]
    procedure TestAccountOfficialAccBookLastPeriodXML()
    var
        GLAccFrom: Code[20];
        GLAccTo: Code[20];
        DateFrom: Date;
        DateTo: Date;
    begin
        // [FEATURE] [Account - Official Acc. Book]
        // [SCENARIO 377046] Print 'Account Official Acc.Book' for last period when G/L Register has G/L Entries in different periods
        Initialize();

        // [GIVEN] G/L Register with Posting Date = Date1 for two G/L Entries with G/L Account "A1" on Date1, "A2" on Date2
        MockRegisterWithGLEntries(GLAccFrom, GLAccTo, DateFrom, DateTo);

        // [WHEN] Run 'Account - Official Acc. Book' report on Date2
        RunAccountOfficialAccBookReport(Format(DateTo));

        // [THEN] G/L Account "A1" is not printed in the report
        // [THEN] G/L Account "A2" is printed in the report
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueNotExist(GLAccountNoLbl, GLAccFrom);
        LibraryReportDataset.AssertElementWithValueExists(GLAccountNoLbl, GLAccTo);
    end;

    [Test]
    [HandlerFunctions('RHDetailAccountStatement')]
    [Scope('OnPrem')]
    procedure TestDetailAccountStatement()
    begin
        Initialize();
        REPORT.Run(REPORT::"Detail Account Statement");
    end;

    [Test]
    [HandlerFunctions('RHMainAccountingBook')]
    [Scope('OnPrem')]
    procedure TestMainAccountingBook()
    begin
        Initialize();
        REPORT.Run(REPORT::"Main Accounting Book");
    end;

    [Test]
    [HandlerFunctions('RHDetailAccStatCOEntries')]
    [Scope('OnPrem')]
    procedure TestDetailAccStatCOEntries()
    begin
        Initialize();
        REPORT.Run(REPORT::"Detail Acc. Stat.- C&O Entries");
    end;

    [Test]
    [HandlerFunctions('RHOfficialAccSummarizedBook')]
    [Scope('OnPrem')]
    procedure TestOfficialAccSummarizedBook()
    begin
        Initialize();
        REPORT.Run(REPORT::"Official Acc.Summarized Book");
    end;

    [Test]
    [HandlerFunctions('RHLongTermSalesInvoices')]
    [Scope('OnPrem')]
    procedure TestLongTermSalesInvoices()
    begin
        Initialize();
        REPORT.Run(REPORT::"Long Term Sales Invoices");
    end;

    [Test]
    [HandlerFunctions('RHLongTermPurchaseInvoices')]
    [Scope('OnPrem')]
    procedure TestLongTermPurchaseInvoices()
    begin
        Initialize();
        REPORT.Run(REPORT::"Long Term Purchase Invoices");
    end;

    [Test]
    [HandlerFunctions('RHTestVATRegistrationNumber')]
    [Scope('OnPrem')]
    procedure TestTestVATRegistrationNumber()
    begin
        Initialize();
        REPORT.Run(REPORT::"Test VAT Registration Number");
    end;

    [Test]
    [HandlerFunctions('RHNormalizedAccountSchedule')]
    [Scope('OnPrem')]
    procedure TestNormalizedAccountSchedule()
    begin
        Initialize();
        REPORT.Run(REPORT::"Normalized Account Schedule");
    end;

    [Test]
    [HandlerFunctions('RHStatement')]
    [Scope('OnPrem')]
    procedure StatementShowOverdue()
    var
        FileManagement: Codeunit "File Management";
    begin
        // [SCENARIO 377122] Run "Statement" report with "Show Overdue" option
        Initialize();
        LibraryVariableStorage.Enqueue(true);
        LibraryReportValidation.SetFullFileName(FileManagement.ServerTempFileName('xlsx'));
        REPORT.Run(REPORT::Statement);
        LibraryReportValidation.VerifyCellValueByRef('J', 42, 1, Format(LibraryVariableStorage.DequeueDate()));
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('VendorDetailTrialBalanceRPH')]
    [Scope('OnPrem')]
    procedure VendorDetailTrialBalance_AmountLCY()
    var
        VendorNo: Code[20];
        StartBalanceLCY: Decimal;
        DebitLCY: Decimal;
        CreditLCY: Decimal;
    begin
        // [FEATURE] [Vendor] [Detail Trial Balance]
        // [SCENARIO 379109] "Vendor - Detail Trial Balance" report shows correct Net and Total Debit/Credit in case of "Show Amounts in LCY" = TRUE
        Initialize();

        // [GIVEN] Vendor with Balance = "S" on date "D1". Net Debit LCY = "D", Net Credit LCY = "C" on date "D2"
        VendorNo := LibraryPurchase.CreateVendorNo();
        StartBalanceLCY := MockVendorLedgerEntry(VendorNo, WorkDate() - 1, 1);
        DebitLCY := MockVendorLedgerEntry(VendorNo, WorkDate(), 1);
        CreditLCY := MockVendorLedgerEntry(VendorNo, WorkDate(), -1);

        // [WHEN] Run REP 304 "Vendor - Detail Trial Balance" with "Show Amounts in LCY" = TRUE, date filter "D2.."
        RunVendorDetailTrialBalanceReport(VendorNo, WorkDate());

        // [THEN] StartBalance = "S"; NetDebit  = TotalDebit = "D"; NetCredit = TotalCredit = "C"; TotalBalance = "A" + "D" - "C"
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('StartBalanceLCY', StartBalanceLCY);
        LibraryReportDataset.AssertElementWithValueExists('VendDebitAmt', DebitLCY);
        LibraryReportDataset.AssertElementWithValueExists('VendCreditAmt', CreditLCY);
        LibraryReportDataset.AssertElementWithValueExists('VendBalLCY', StartBalanceLCY + DebitLCY - CreditLCY);
        LibraryReportDataset.AssertElementWithValueExists('VendBalLCYDebitAmtDebitAmtAdj', DebitLCY);
        LibraryReportDataset.AssertElementWithValueExists('VendBalLCYCreditAmtCreditAmtAdj', CreditLCY);
    end;

    [Test]
    [HandlerFunctions('CustomerDetailTrialBalanceRPH')]
    [Scope('OnPrem')]
    procedure CustomerDetailTrialBalance_AmountLCY()
    var
        CustomerNo: Code[20];
        StartBalanceLCY: Decimal;
        DebitLCY: Decimal;
        CreditLCY: Decimal;
    begin
        // [FEATURE] [Customer] [Detail Trial Bal.]
        // [SCENARIO 379109] "Customer - Detail Trial Bal." shows correct Net and Total Debit/Credit in case of "Show Amounts in LCY" = TRUE
        Initialize();

        // [GIVEN] Customer with Balance = "S" on date "D1". Net Debit LCY = "D", Net Credit LCY = "C" on date "D2"
        CustomerNo := LibrarySales.CreateCustomerNo();
        StartBalanceLCY := MockCustomerLedgerEntry(CustomerNo, WorkDate() - 1, 1);
        CreditLCY := MockCustomerLedgerEntry(CustomerNo, WorkDate(), 1);
        DebitLCY := MockCustomerLedgerEntry(CustomerNo, WorkDate(), -1);

        // [WHEN] Run REP 104 "Customer - Detail Trial Balance" with "Show Amounts in LCY" = TRUE, date filter "D2.."
        RunCustomerDetailTrialBalanceReport(CustomerNo, WorkDate());

        // [THEN] StartBalance = "S"; NetDebit  = TotalDebit = "D"; NetCredit = TotalCredit = "C"; TotalBalance = "A" - "D" + "C"
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('StartBalanceLCY', StartBalanceLCY);
        LibraryReportDataset.AssertElementWithValueExists('CustDebitAmount', CreditLCY);
        LibraryReportDataset.AssertElementWithValueExists('CustCreditAmount', DebitLCY);
    end;

    [Test]
    [HandlerFunctions('RHAccountOfficialAccBookXML,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestAccountOfficialAccBookStartOfClosedPeriodXML()
    var
        GLEntry: Record "G/L Entry";
        GLAccountNo: Code[20];
        PostingDate: Date;
        OpeningAmt: Decimal;
        StartPeriodAmt: Decimal;
        PeriodTransNo: Integer;
    begin
        // [FEATURE] [Account - Official Acc. Book]
        // [SCENARIO 206017] Print 'Account Official Acc.Book' for closed accounting period with G/L Entry posted on 1st date of the period
        Initialize();

        // [GIVEN] Starting balance of G/L Account "X" with Debit Amount = 10
        GLAccountNo := LibraryERM.CreateGLAccountNo();
        OpeningAmt := LibraryRandom.RandDec(100, 2);
        MockGLEntry(GLEntry, GLAccountNo, WorkDate(), OpeningAmt, 0);

        // [GIVEN] G/L Register has G/L Entry with Debit Amount = 20 and Posting Date = 01-01-25 in new Fiscal Year
        LibraryFiscalYear.CreateFiscalYear();
        PostingDate := LibraryFiscalYear.GetFirstPostingDate(false);
        StartPeriodAmt := LibraryRandom.RandDec(100, 2);
        PeriodTransNo := CreateRegisterWithGLEntry(GLAccountNo, PostingDate, StartPeriodAmt);

        // [GIVEN] Fiscal Year 2025 is closed
        LibraryFiscalYear.CloseFiscalYear();

        // [WHEN] Run 'Account - Official Acc. Book' report for closed fiscal year
        RunAccountOfficialAccBookReport(StrSubstNo('%1..%2', PostingDate, CalcDate('<CY>', PostingDate)));

        // [THEN] Opening transaction entry is exported for G/L Account "X" with Amount = 10
        LibraryReportDataset.LoadDataSetFile();
        VerifyAccountOfficialReportOpeningClosingDebitAmt(GLAccountNo, 1, true, OpeningAmt);
        // [THEN] Period entry is exported for G/L Account "X" with Amount = 20
        VerifyAccountOfficialReportPeriodEntry(GLAccountNo, PeriodTransNo, StartPeriodAmt);
        // [THEN] Closing transaction entry is exported for G/L Account "X" with Amount = 30
        VerifyAccountOfficialReportOpeningClosingDebitAmt(GLAccountNo, 2, false, OpeningAmt + StartPeriodAmt);
    end;

    [Test]
    [HandlerFunctions('RHAccountOfficialAccBookXML,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestAccountOfficialAccBookEntryInClosedPeriodXML()
    var
        GLEntry: Record "G/L Entry";
        GLAccountNo: Code[20];
        PostingDate: Date;
        OpeningAmt: Decimal;
        PeriodAmt: Decimal;
        StartDate: Date;
        EndDate: Date;
        PeriodTransNo: Integer;
    begin
        // [FEATURE] [Account - Official Acc. Book]
        // [SCENARIO 206017] Print 'Account Official Acc.Book' for closed accounting period with G/L Entry posted on the middle of the period
        Initialize();

        // [GIVEN] Starting balance of G/L Account "X" with Debit Amount = 10
        LibraryFiscalYear.CreateFiscalYear();
        GLAccountNo := LibraryERM.CreateGLAccountNo();
        OpeningAmt := LibraryRandom.RandDec(100, 2);
        MockGLEntry(GLEntry, GLAccountNo, LibraryFiscalYear.GetFirstPostingDate(false), OpeningAmt, 0);
        LibraryFiscalYear.CloseFiscalYear();

        // [GIVEN] G/L Register has G/L Entry with Debit Amount = 20 and Posting Date = 05-01-25 in new Fiscal Year
        LibraryFiscalYear.CreateFiscalYear();
        PostingDate := LibraryRandom.RandDateFrom(LibraryFiscalYear.GetFirstPostingDate(false), 10);
        PeriodAmt := LibraryRandom.RandDec(100, 2);
        PeriodTransNo := CreateRegisterWithGLEntry(GLAccountNo, PostingDate, PeriodAmt);

        // [GIVEN] Fiscal Year 2025 is closed
        StartDate := LibraryFiscalYear.GetFirstPostingDate(false);
        EndDate := LibraryFiscalYear.GetLastPostingDate(false);
        LibraryFiscalYear.CloseFiscalYear();

        // [WHEN] Run 'Account - Official Acc. Book' report for closed fiscal year
        RunAccountOfficialAccBookReport(StrSubstNo('%1..%2', StartDate, EndDate));

        // [THEN] Opening transaction entry is exported for G/L Account "X" with Amount = 10
        LibraryReportDataset.LoadDataSetFile();
        VerifyAccountOfficialReportOpeningClosingDebitAmt(GLAccountNo, 1, true, OpeningAmt);
        // [THEN] Period entry is exported for G/L Account "X" with Amount = 20
        VerifyAccountOfficialReportPeriodEntry(GLAccountNo, PeriodTransNo, PeriodAmt);
        // [THEN] Closing transaction entry is exported for G/L Account "X" with Amount = 30
        VerifyAccountOfficialReportOpeningClosingDebitAmt(GLAccountNo, 2, false, OpeningAmt + PeriodAmt);
    end;

    [Test]
    [HandlerFunctions('RHAccountOfficialAccBookSimpleXML')]
    [Scope('OnPrem')]
    procedure TestAccountOfficialAccBookEntryInFirstTransPeriodXML()
    var
        GLEntry: Record "G/L Entry";
        PeriodGLAccountNo: Code[20];
        OpeningGLAccountNo: Code[20];
        PeriodAmt: Decimal;
        OpeningAmt: Decimal;
        StartDate: Date;
        EndDate: Date;
        PeriodTransNo: Integer;
    begin
        // [FEATURE] [Account - Official Acc. Book]
        // [SCENARIO 215229] Print 'Account Official Acc.Book' for period which contains 1st transaction but entries exist in previous period
        Initialize();

        // [GIVEN] Take year of first transaction as period date 010117..311217
        GLEntry.FindFirst();
        StartDate := CalcDate('<-CY>', GLEntry."Posting Date");
        EndDate := CalcDate('<CY>', GLEntry."Posting Date");

        // [GIVEN] Posted entry for G/L Account "X" with Debit Amount = 10 on 05.01.2017
        PeriodGLAccountNo := LibraryERM.CreateGLAccountNo();
        PeriodAmt := LibraryRandom.RandDec(100, 2);
        PeriodTransNo := CreateRegisterWithGLEntry(PeriodGLAccountNo, LibraryRandom.RandDateFrom(StartDate, 5), PeriodAmt);

        // [GIVEN] Posted opening entry for G/L Account "Y" with Debit Amount = 20 on 05.01.2016
        OpeningGLAccountNo := LibraryERM.CreateGLAccountNo();
        OpeningAmt := LibraryRandom.RandDec(100, 2);
        CreateRegisterWithGLEntry(
          OpeningGLAccountNo, LibraryRandom.RandDateFrom(CalcDate('<-1Y>', StartDate), 10), OpeningAmt);

        // [WHEN] Run 'Account - Official Acc. Book' report for 010117..311217 period
        RunAccountOfficialAccBookReport(StrSubstNo('%1..%2', StartDate, EndDate));

        // [THEN] Opening transaction entry is exported for G/L Account "Y" with Amount = 20
        LibraryReportDataset.LoadDataSetFile();
        VerifyAccountOfficialReportOpeningDebitAmt(OpeningGLAccountNo, OpeningAmt);

        // [THEN] Period entry is exported for G/L Account "X" with Amount = 10
        VerifyAccountOfficialReportPeriodEntry(PeriodGLAccountNo, PeriodTransNo, PeriodAmt);
    end;

    [Test]
    [HandlerFunctions('SetPeriodTransNosRequestPageHandler,RHAccountOfficialAccBookSimpleXML')]
    [TestPermissions(TestPermissions::NonRestrictive)]
    [Scope('OnPrem')]
    procedure AccountOfficialAccBookEntryWithCombinedPostingDatesAndTransactionNos()
    var
        GLEntry: array[4] of Record "G/L Entry";
        i: Integer;
    begin
        // [FEATURE] [Account - Official Acc. Book]
        // [SCENARIO 266203] Report 10706 "Account - Official Acc. Book" in case of different "Transaction No." within the same "Posting Date"
        // [SCENARIO 266203] and different "Posting Date" within the same "Transaction No."
        Initialize();

        // [GIVEN] GLEntry1:  "Entry No." = 1  "Posting Date" = 03-01-2018, "Transaction No." = 3
        // [GIVEN] GLEntry2:  "Entry No." = 2  "Posting Date" = 02-01-2018, "Transaction No." = 3
        // [GIVEN] GLEntry3:  "Entry No." = 3  "Posting Date" = 01-01-2018, "Transaction No." = 2
        // [GIVEN] GLEntry4:  "Entry No." = 4  "Posting Date" = 01-01-2018, "Transaction No." = 1
        MockGLEntry(GLEntry[1], LibraryERM.CreateGLAccountNo(), WorkDate() + 3, LibraryRandom.RandDecInRange(1000, 2000, 2), 3);
        MockGLEntry(GLEntry[2], LibraryERM.CreateGLAccountNo(), WorkDate() + 2, LibraryRandom.RandDecInRange(1000, 2000, 2), 3);
        MockGLEntry(GLEntry[3], LibraryERM.CreateGLAccountNo(), WorkDate() + 1, LibraryRandom.RandDecInRange(1000, 2000, 2), 2);
        MockGLEntry(GLEntry[4], LibraryERM.CreateGLAccountNo(), WorkDate() + 1, LibraryRandom.RandDecInRange(1000, 2000, 2), 1);

        // [GIVEN] Run report 10700 "Set Period Trans. Nos." using Date Filter = 01-01-2018..03-01-2018
        LibraryLowerPermissions.SetO365BusFull();
        SetPeriodTransNos(StrSubstNo('%1..%2', WorkDate() + 1, WorkDate() + 3));
        for i := 1 to ArrayLen(GLEntry) do
            GLEntry[i].Find();

        // [WHEN] Run report 10706 "Account - Official Acc. Book" for 01-01-2018..03-01-2018 period
        RunAccountOfficialAccBookReport(StrSubstNo('%1..%2', WorkDate() + 1, WorkDate() + 3));

        // [THEN] G/L Entries has been printed with different Period Transaction Nos
        LibraryReportDataset.LoadDataSetFile();
        for i := 1 to ArrayLen(GLEntry) do
            VerifyAccountOfficialReportPeriodEntry(GLEntry[i]."G/L Account No.", GLEntry[i]."Period Trans. No.", GLEntry[i].Amount);
    end;

    [Test]
    [HandlerFunctions('StandardSalesDraftInvoiceRequestPageHandler,ConfirmHandlerNo,MessageHandler')]
    [Scope('OnPrem')]
    procedure StandardSalesDraftInvoiceShowsVATClause()
    var
        VATClause: Record "VAT Clause";
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales] [Invoice] [VAT Clause]
        // [SCENARIO 280820] Report "Standard Sales - Draft Invoice" shows VAT Clause
        Initialize();

        // [GIVEN] VAT Posting Setup with VAT Identifier and VAT Clause having Description and Description 2
        LibraryERM.CreateVATClause(VATClause);
        CreateVATPostingSetupWithVATClause(VATPostingSetup, VATClause.Code);

        // [GIVEN] Sales Invoice
        CreateSalesInvoiceWithVATPostingSetup(SalesHeader, VATPostingSetup);
        SalesHeader.SetRecFilter();
        Commit();

        // [WHEN] Run report "Standard Sales - Draft Invoice" for Sales Invoice
        REPORT.Run(REPORT::"Standard Sales - Draft Invoice", true, false, SalesHeader);

        // [THEN] Report DataSet contains VAT Clause fields: "VAT Identifier","VAT Clause Description", "VAT Clause Description 2"
        VerifySalesInvoiceDatasetVATClause(VATClause, VATPostingSetup."VAT Identifier");
    end;

    [Test]
    [HandlerFunctions('StandardSalesInvoiceRequestPageHandler,ConfirmHandlerNo,MessageHandler')]
    [Scope('OnPrem')]
    procedure StandardSalesInvoiceShowsVATClause()
    var
        VATClause: Record "VAT Clause";
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // [FEATURE] [Sales] [Invoice] [VAT Clause]
        // [SCENARIO 280820] Report "Standard Sales - Invoice" shows VAT Clause
        Initialize();

        // [GIVEN] VAT Posting Setup with VAT Identifier and VAT Clause having Description and Description 2
        LibraryERM.CreateVATClause(VATClause);
        CreateVATPostingSetupWithVATClause(VATPostingSetup, VATClause.Code);

        // [GIVEN] Posted Sales Invoice
        CreateSalesInvoiceWithVATPostingSetup(SalesHeader, VATPostingSetup);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesInvoiceHeader.SetRecFilter();

        // [WHEN] Run report "Standard Sales - Invoice" for Posted Sales Invoice
        REPORT.Run(REPORT::"Standard Sales - Invoice", true, false, SalesInvoiceHeader);

        // [THEN] Report DataSet contains VAT Clause fields: "VAT Identifier","VAT Clause Description", "VAT Clause Description 2"
        VerifySalesInvoiceDatasetVATClause(VATClause, VATPostingSetup."VAT Identifier");
    end;

    local procedure Initialize()
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        Clear(LibraryReportValidation);
        LibraryVariableStorage.Clear();
        if isInitialized then
            exit;

        // Setup logo to be printed by default
        SalesSetup.Get();
        SalesSetup.Validate("Logo Position on Documents", SalesSetup."Logo Position on Documents"::Center);
        SalesSetup.Modify(true);

        isInitialized := true;
        Commit();
    end;

    local procedure CreateVATPostingSetupWithVATClause(var VATPostingSetup: Record "VAT Posting Setup"; VATClauseCode: Code[20])
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandDecInRange(10, 20, 2));
        VATPostingSetup.Validate("VAT Clause Code", VATClauseCode);
        VATPostingSetup.Modify(true);
    end;

    local procedure CreateSalesInvoiceWithVATPostingSetup(var SalesHeader: Record "Sales Header"; VATPostingSetup: Record "VAT Posting Setup")
    var
        SalesLine: Record "Sales Line";
        Item: Record Item;
    begin
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Invoice,
          LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDecInRange(10, 20, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(1000, 2000, 2));
        SalesLine.Modify(true);
    end;

    local procedure MockRegisterWithGLEntries(var GLAccFrom: Code[20]; var GLAccTo: Code[20]; var DateFrom: Date; var DateTo: Date)
    var
        GLRegister: Record "G/L Register";
        GLEntryFrom: Record "G/L Entry";
        GLEntryTo: Record "G/L Entry";
    begin
        GLRegister.Init();
        GLRegister."No." := LibraryUtility.GetNewRecNo(GLRegister, GLRegister.FieldNo("No."));

        MockGLEntry(
          GLEntryFrom, LibraryUtility.GenerateRandomCode(GLEntryFrom.FieldNo("G/L Account No."), DATABASE::"G/L Entry"),
          CalcDate('<1M>', WorkDate()), LibraryRandom.RandDec(100, 2), GLRegister."No.");
        MockGLEntry(
          GLEntryTo, LibraryUtility.GenerateRandomCode(GLEntryFrom.FieldNo("G/L Account No."), DATABASE::"G/L Entry"),
          GLEntryFrom."Posting Date" + 1, LibraryRandom.RandDec(100, 2), GLRegister."No.");
        GLEntryTo."Period Trans. No." := GLEntryFrom."Entry No.";
        GLEntryTo.Modify();

        GLRegister."Posting Date" := GLEntryFrom."Posting Date";
        GLRegister."From Entry No." := GLEntryFrom."Entry No.";
        GLRegister."To Entry No." := GLEntryTo."Entry No.";
        GLRegister.Insert();
        GLAccFrom := GLEntryFrom."G/L Account No.";
        DateFrom := GLEntryFrom."Posting Date";
        GLAccTo := GLEntryTo."G/L Account No.";
        DateTo := GLEntryTo."Posting Date";
    end;

    local procedure CreateRegisterWithGLEntry(GLAccountNo: Code[20]; PostingDate: Date; DebitAmount: Decimal): Integer
    var
        GLRegister: Record "G/L Register";
        GLEntry: Record "G/L Entry";
    begin
        GLRegister.Init();
        GLRegister."No." := LibraryUtility.GetNewRecNo(GLRegister, GLRegister.FieldNo("No."));
        MockGLEntry(GLEntry, GLAccountNo, PostingDate, DebitAmount, GLRegister."No.");
        GLRegister."Posting Date" := GLEntry."Posting Date";
        GLRegister."From Entry No." := GLEntry."Entry No.";
        GLRegister."To Entry No." := GLEntry."Entry No.";
        GLRegister.Insert();
        exit(GLEntry."Entry No.");
    end;

    local procedure MockGLEntry(var GLEntry: Record "G/L Entry"; GLAccNo: Code[20]; PostingDate: Date; DebitAmount: Decimal; TransactionNo: Integer)
    begin
        GLEntry.Init();
        GLEntry."Entry No." := LibraryUtility.GetNewRecNo(GLEntry, GLEntry.FieldNo("Entry No."));
        GLEntry."G/L Account No." := GLAccNo;
        GLEntry."Posting Date" := PostingDate;
        GLEntry.Amount := DebitAmount;
        GLEntry."Debit Amount" := DebitAmount;
        GLEntry."Transaction No." := TransactionNo;
        GLEntry."Period Trans. No." := GLEntry."Entry No.";
        GLEntry.Insert();
    end;

    local procedure MockVendorLedgerEntry(VendorNo: Code[20]; PostingDate: Date; Sign: Integer): Decimal
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.Init();
        VendorLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(VendorLedgerEntry, VendorLedgerEntry.FieldNo("Entry No."));
        VendorLedgerEntry."Vendor No." := VendorNo;
        VendorLedgerEntry."Posting Date" := PostingDate;
        VendorLedgerEntry.Insert();
        exit(MockDetailedVendorLedgerEntry(VendorNo, VendorLedgerEntry."Entry No.", PostingDate, Sign));
    end;

    local procedure MockDetailedVendorLedgerEntry(VendorNo: Code[20]; VLENo: Integer; PostingDate: Date; Sign: Integer): Decimal
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        DetailedVendorLedgEntry.Init();
        DetailedVendorLedgEntry."Entry No." := LibraryUtility.GetNewRecNo(DetailedVendorLedgEntry, DetailedVendorLedgEntry.FieldNo("Entry No."));
        DetailedVendorLedgEntry."Vendor No." := VendorNo;
        DetailedVendorLedgEntry."Vendor Ledger Entry No." := VLENo;
        DetailedVendorLedgEntry."Posting Date" := PostingDate;
        DetailedVendorLedgEntry."Ledger Entry Amount" := true;
        DetailedVendorLedgEntry.Amount := Sign * LibraryRandom.RandDecInRange(1000, 2000, 2);
        DetailedVendorLedgEntry."Amount (LCY)" := Sign * LibraryRandom.RandDecInRange(1000, 2000, 2);
        if Sign > 0 then begin
            DetailedVendorLedgEntry."Debit Amount" := DetailedVendorLedgEntry.Amount;
            DetailedVendorLedgEntry."Debit Amount (LCY)" := DetailedVendorLedgEntry."Amount (LCY)";
        end else begin
            DetailedVendorLedgEntry."Credit Amount" := -DetailedVendorLedgEntry.Amount;
            DetailedVendorLedgEntry."Credit Amount (LCY)" := -DetailedVendorLedgEntry."Amount (LCY)";
        end;
        DetailedVendorLedgEntry.Insert();
        exit(Abs(DetailedVendorLedgEntry."Amount (LCY)"));
    end;

    local procedure MockCustomerLedgerEntry(CustomerNo: Code[20]; PostingDate: Date; Sign: Integer): Decimal
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.Init();
        CustLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(CustLedgerEntry, CustLedgerEntry.FieldNo("Entry No."));
        CustLedgerEntry."Customer No." := CustomerNo;
        CustLedgerEntry."Posting Date" := PostingDate;
        CustLedgerEntry.Insert();
        exit(MockDetailedCustomerLedgerEntry(CustomerNo, CustLedgerEntry."Entry No.", PostingDate, Sign));
    end;

    local procedure MockDetailedCustomerLedgerEntry(CustomerNo: Code[20]; CLENo: Integer; PostingDate: Date; Sign: Integer): Decimal
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DetailedCustLedgEntry.Init();
        DetailedCustLedgEntry."Entry No." := LibraryUtility.GetNewRecNo(DetailedCustLedgEntry, DetailedCustLedgEntry.FieldNo("Entry No."));
        DetailedCustLedgEntry."Customer No." := CustomerNo;
        DetailedCustLedgEntry."Cust. Ledger Entry No." := CLENo;
        DetailedCustLedgEntry."Posting Date" := PostingDate;
        DetailedCustLedgEntry."Ledger Entry Amount" := true;
        DetailedCustLedgEntry.Amount := Sign * LibraryRandom.RandDecInRange(1000, 2000, 2);
        DetailedCustLedgEntry."Amount (LCY)" := Sign * LibraryRandom.RandDecInRange(1000, 2000, 2);
        if Sign < 0 then begin
            DetailedCustLedgEntry."Debit Amount" := -DetailedCustLedgEntry.Amount;
            DetailedCustLedgEntry."Debit Amount (LCY)" := -DetailedCustLedgEntry."Amount (LCY)";
        end else begin
            DetailedCustLedgEntry."Credit Amount" := DetailedCustLedgEntry.Amount;
            DetailedCustLedgEntry."Credit Amount (LCY)" := DetailedCustLedgEntry."Amount (LCY)";
        end;
        DetailedCustLedgEntry.Insert();
        exit(Abs(DetailedCustLedgEntry."Amount (LCY)"));
    end;

    local procedure FormatFileName(ReportCaption: Text) ReportFileName: Text
    begin
        ReportFileName := DelChr(ReportCaption, '=', '/') + '.pdf'
    end;

    local procedure SetPeriodTransNos(DateFilter: Text)
    begin
        LibraryVariableStorage.Enqueue(DateFilter);
        Commit();
        REPORT.Run(REPORT::"Set Period Trans. Nos.");
    end;

    local procedure VerifySalesInvoiceDatasetVATClause(VATClause: Record "VAT Clause"; VATIdentifier: Code[20])
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementTagWithValueExists('VATClauses_Lbl', 'VAT Clause');
        LibraryReportDataset.AssertElementTagWithValueExists('VATIdentifier_Lbl', 'VAT Identifier');
        LibraryReportDataset.AssertElementTagWithValueExists('VATIdentifier_Line', VATIdentifier);
        LibraryReportDataset.AssertElementTagWithValueExists('Description_VATClauseLine', VATClause.Description);
        LibraryReportDataset.AssertElementTagWithValueExists('Description2_VATClauseLine', VATClause."Description 2");
    end;

    local procedure VerifyAccountOfficialReportOpeningClosingDebitAmt(GLAccountNo: Code[20]; IntNumber: Integer; ShowGLHeader: Boolean; Amount: Decimal)
    begin
        LibraryReportDataset.Reset();
        LibraryReportDataset.SetRange('G_L_Account__No__', GLAccountNo);
        LibraryReportDataset.SetRange('LineID', 1);
        LibraryReportDataset.SetRange('IntNumber', IntNumber);
        LibraryReportDataset.SetRange('ShowGLHeader1', ShowGLHeader);
        LibraryReportDataset.AssertElementWithValueExists('DebitAmt', Amount);
    end;

    local procedure VerifyAccountOfficialReportPeriodEntry(GLAccountNo: Code[20]; PeriodTransNo: Integer; Amount: Decimal)
    begin
        LibraryReportDataset.Reset();
        LibraryReportDataset.SetRange('G_L_Entry__G_L_Account_No__', GLAccountNo);
        LibraryReportDataset.SetRange('LineID', 2);
        LibraryReportDataset.SetRange('ShowGLEntryBody1', true);
        LibraryReportDataset.SetRange('G_L_Register__Period_Trans__No__', PeriodTransNo);
        LibraryReportDataset.AssertElementWithValueExists('G_L_Entry__Debit_Amount_', Amount);
    end;

    local procedure VerifyAccountOfficialReportOpeningDebitAmt(GLAccountNo: Code[20]; Amount: Decimal)
    begin
        LibraryReportDataset.Reset();
        LibraryReportDataset.SetRange('G_L_Account__No__', GLAccountNo);
        LibraryReportDataset.SetRange('LineID', 1);
        LibraryReportDataset.SetRange('ShowGLBody1', true);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('DebitAmt', Amount);
    end;

    local procedure RunVendorDetailTrialBalanceReport(VendorNo: Code[20]; FromDate: Date)
    var
        Vendor: Record Vendor;
        VendorDetailTrialBalance: Report "Vendor - Detail Trial Balance";
    begin
        Commit();
        Clear(VendorDetailTrialBalance);
        Vendor.SetRange("No.", VendorNo);
        Vendor.SetFilter("Date Filter", '%1..', FromDate);
        VendorDetailTrialBalance.SetTableView(Vendor);
        VendorDetailTrialBalance.InitializeRequest(true, false, false);
        VendorDetailTrialBalance.Run();
    end;

    local procedure RunCustomerDetailTrialBalanceReport(CustomerNo: Code[20]; FromDate: Date)
    var
        Customer: Record Customer;
        CustomerDetailTrialBal: Report "Customer - Detail Trial Bal.";
    begin
        Commit();
        Clear(CustomerDetailTrialBal);
        Customer.SetRange("No.", CustomerNo);
        Customer.SetFilter("Date Filter", '%1..', FromDate);
        CustomerDetailTrialBal.SetTableView(Customer);
        CustomerDetailTrialBal.InitializeRequest(true, false, false);
        CustomerDetailTrialBal.Run();
    end;

    local procedure RunAccountOfficialAccBookReport(PostingDateFilter: Text)
    begin
        Commit();
        LibraryVariableStorage.Enqueue(PostingDateFilter);
        REPORT.Run(REPORT::"Account - Official Acc. Book");
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StandardSalesDraftInvoiceRequestPageHandler(var StandardSalesDraftInvoice: TestRequestPage "Standard Sales - Draft Invoice")
    begin
        StandardSalesDraftInvoice.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StandardSalesInvoiceRequestPageHandler(var StandardSalesInvoice: TestRequestPage "Standard Sales - Invoice")
    begin
        StandardSalesInvoice.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHCustomerAnnualDeclaration(var CustomerAnnualDeclaration: TestRequestPage "Customer - Annual Declaration")
    begin
        CustomerAnnualDeclaration.Customer.SetFilter(
          "Date Filter", StrSubstNo('%1..%2', Format(CalcDate('<-1Y>', WorkDate())), Format(WorkDate())));
        CustomerAnnualDeclaration.SaveAsPdf(FormatFileName(CustomerAnnualDeclaration.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHVendorAnnualDeclaration(var VendorAnnualDeclaration: TestRequestPage "Vendor - Annual Declaration")
    begin
        VendorAnnualDeclaration.Vendor.SetFilter("Date Filter", Format(WorkDate()));
        VendorAnnualDeclaration.SaveAsPdf(FormatFileName(VendorAnnualDeclaration.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHAccountOfficialAccBook(var AccountOfficialAccBook: TestRequestPage "Account - Official Acc. Book")
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetFilter("Period Trans. No.", '<>%1', 0);
        GLEntry.FindFirst();
        AccountOfficialAccBook."G/L Entry Group".SetFilter("Posting Date", Format(GLEntry."Posting Date"));
        AccountOfficialAccBook.SaveAsPdf(FormatFileName(AccountOfficialAccBook.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHAccountOfficialAccBookXML(var AccountOfficialAccBook: TestRequestPage "Account - Official Acc. Book")
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.FindLast();
        AccountOfficialAccBook."G/L Entry Group".SetFilter("Period Trans. No.", Format(GLEntry."Period Trans. No."));
        AccountOfficialAccBook."G/L Entry Group".SetFilter("Posting Date", LibraryVariableStorage.DequeueText());
        AccountOfficialAccBook.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHAccountOfficialAccBookSimpleXML(var AccountOfficialAccBook: TestRequestPage "Account - Official Acc. Book")
    begin
        AccountOfficialAccBook."G/L Entry Group".SetFilter("Period Trans. No.", '');
        AccountOfficialAccBook."G/L Entry Group".SetFilter("Posting Date", LibraryVariableStorage.DequeueText());
        AccountOfficialAccBook.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHDetailAccountStatement(var DetailAccountStatement: TestRequestPage "Detail Account Statement")
    begin
        DetailAccountStatement."G/L Account".SetFilter("Date Filter", Format(WorkDate()));
        DetailAccountStatement.SaveAsPdf(FormatFileName(DetailAccountStatement.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHMainAccountingBook(var MainAccountingBook: TestRequestPage "Main Accounting Book")
    begin
        MainAccountingBook."G/L Account".SetFilter("Date Filter", Format(WorkDate()));
        MainAccountingBook.SaveAsPdf(FormatFileName(MainAccountingBook.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHDetailAccStatCOEntries(var DetailAccStatCOEntries: TestRequestPage "Detail Acc. Stat.- C&O Entries")
    begin
        DetailAccStatCOEntries."G/L Account".SetFilter("Date Filter", Format(WorkDate()));
        DetailAccStatCOEntries.SaveAsPdf(FormatFileName(DetailAccStatCOEntries.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHOfficialAccSummarizedBook(var OfficialAccSummarizedBook: TestRequestPage "Official Acc.Summarized Book")
    var
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
    begin
        OfficialAccSummarizedBook.FromDate.SetValue(Format(LibraryFiscalYear.GetFirstPostingDate(true)));
        OfficialAccSummarizedBook.ToDate.SetValue(DMY2Date(31, 12, Date2DMY(LibraryFiscalYear.GetFirstPostingDate(true), 3)));
        OfficialAccSummarizedBook.SaveAsPdf(FormatFileName(OfficialAccSummarizedBook.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHLongTermSalesInvoices(var LongTermSalesInvoices: TestRequestPage "Long Term Sales Invoices")
    begin
        LongTermSalesInvoices."Due Date Period Length".SetValue('<1M>');
        LongTermSalesInvoices.SaveAsPdf(FormatFileName(LongTermSalesInvoices.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHLongTermPurchaseInvoices(var LongTermPurchaseInvoices: TestRequestPage "Long Term Purchase Invoices")
    begin
        LongTermPurchaseInvoices."Due Date Period Length".SetValue('<1M>');
        LongTermPurchaseInvoices.SaveAsPdf(FormatFileName(LongTermPurchaseInvoices.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHTestVATRegistrationNumber(var VATRegistrationNumber: TestRequestPage "Test VAT Registration Number")
    begin
        VATRegistrationNumber.ShowCustomers.SetValue(true);
        VATRegistrationNumber.ShowVendors.SetValue(true);
        VATRegistrationNumber.ShowContacts.SetValue(true);
        VATRegistrationNumber.SaveAsPdf(FormatFileName(VATRegistrationNumber.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHNormalizedAccountSchedule(var NormalizedAccountSchedule: TestRequestPage "Normalized Account Schedule")
    var
        AccScheduleName: Record "Acc. Schedule Name";
    begin
        AccScheduleName.SetRange(Standardized, true);
        AccScheduleName.FindFirst();
        NormalizedAccountSchedule."Acc. Schedule Name".SetFilter(Name, AccScheduleName.Name);
        NormalizedAccountSchedule."Acc. Schedule Line".SetFilter("Date Filter", Format(WorkDate()));
        NormalizedAccountSchedule.SaveAsPdf(FormatFileName(NormalizedAccountSchedule.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHStatement(var Statement: TestRequestPage Statement)
    var
        EndDate: Date;
    begin
        EndDate := CalcDate('<CM>', WorkDate());
        LibraryVariableStorage.Enqueue(EndDate);

        Statement.ShowOverdueEntries.SetValue(LibraryVariableStorage.DequeueBoolean());
        Statement."Start Date".SetValue(CalcDate('<-CM+1D>', WorkDate()));
        Statement."End Date".SetValue(EndDate);
        Statement.SaveAsExcel(LibraryReportValidation.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VendorDetailTrialBalanceRPH(var VendorDetailTrialBalance: TestRequestPage "Vendor - Detail Trial Balance")
    begin
        VendorDetailTrialBalance.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerDetailTrialBalanceRPH(var CustomerDetailTrialBal: TestRequestPage "Customer - Detail Trial Bal.")
    begin
        CustomerDetailTrialBal.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerNo(Question: Text; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SetPeriodTransNosRequestPageHandler(var SetPeriodTransNos: TestRequestPage "Set Period Trans. Nos.")
    begin
        SetPeriodTransNos."G/L Entry".SetFilter("Posting Date", LibraryVariableStorage.DequeueText());
        SetPeriodTransNos.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;
}

