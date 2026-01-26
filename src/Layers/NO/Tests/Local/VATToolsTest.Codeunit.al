codeunit 144001 "VAT Tools Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [VAT]
    end;

    var
        GenJnlLine: Record "Gen. Journal Line";
        Assert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurch: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryCosting: Codeunit "Library - Costing";
        LibraryVATReport: Codeunit "Library - VAT Report";
        NorwegianVATTools: Codeunit "Norwegian VAT Tools";
        Selection: Enum "VAT Statement Report Selection";
        PeriodSelection: Enum "VAT Statement Report Period Selection";
        SettledAndClosedVATPeriodErr: Label 'is in a settled and closed VAT period (%1 period %2)';
        IsInitialized: Boolean;
        OpenClosedSelection: Enum "VAT Statement Report Selection";

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostingInClosedVATPeriodAfterCalcAndPostVATSettlementIsNotAllowed()
    begin
        // [FEATURE] [Settled VAT Period]
        Initialize();

        // Verify that Settled VAT Periods are updated when the VAT is settled through Calc. and Post VAT Settlement report
        CreateAndPostSalesInvoice(WorkDate());
        CalcAndPostVATSettlement(WorkDate(), WorkDate(), WorkDate(), true);

        asserterror CreateAndPostSalesInvoice(WorkDate());

        Assert.ExpectedError(StrSubstNo(SettledAndClosedVATPeriodErr, Date2DMY(WorkDate(), 3), NorwegianVATTools.VATPeriodNo(WorkDate())));
    end;

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ApplicationInClosedVATPeriodWithApplnAlwaysAllowedFalse()
    var
        InvoiceNo: Code[20];
        PaymentNo: Code[20];
    begin
        // [FEATURE] [Settled VAT Period] [Application Always Allowed] [General Ledger Setup]
        Initialize();

        // Verify error on posting application (apply invoice with payment) in a closed VAT period with Application always Allowed = false
        SetApplicationAlwaysAllowedInGLSetup(false);

        asserterror ApplicationInClosedVATPeriodAfterCalcAndPostVATSettlement(InvoiceNo, PaymentNo);
        Assert.ExpectedError(StrSubstNo(SettledAndClosedVATPeriodErr, Date2DMY(WorkDate(), 3), NorwegianVATTools.VATPeriodNo(WorkDate())));
    end;

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ApplicationInClosedVATPeriodUserSetupAlwaysAllowedTrueOverridesGLSetupValueFalse()
    var
        InvoiceNo: Code[20];
        PaymentNo: Code[20];
        UserSetupCreated: Boolean;
    begin
        // [FEATURE] [Settled VAT Period] [Application Always Allowed] [User Setup]
        Initialize();

        // Verify posting application (apply invoice with payment) in a closed VAT period with Application always Allowed = true in the User Setup, thus overriding GL setting
        UserSetupCreated := SetUserSetupApplicationAlwaysAllowed(true);

        SetApplicationAlwaysAllowedInGLSetup(false);
        ApplicationInClosedVATPeriodAfterCalcAndPostVATSettlement(InvoiceNo, PaymentNo);

        VerifyApplication(InvoiceNo, PaymentNo);

        DeleteSettledVATPeriods();

        if UserSetupCreated then
            DeleteUserSetup();
    end;

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ApplicationInClosedVATPeriodWithApplnAlwaysAllowedTrue()
    var
        InvoiceNo: Code[20];
        PaymentNo: Code[20];
    begin
        // [FEATURE] [Settled VAT Period] [Application Always Allowed] [General Ledger Setup]
        Initialize();

        // Verify posting application (apply invoice with payment) in a closed VAT period with Application always Allowed = true
        SetApplicationAlwaysAllowedInGLSetup(true);
        ApplicationInClosedVATPeriodAfterCalcAndPostVATSettlement(InvoiceNo, PaymentNo);

        VerifyApplication(InvoiceNo, PaymentNo);

        DeleteSettledVATPeriods();
    end;

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CalcAndPostVATSettlementReportSettlesVatPeriods()
    var
        SettledVATPeriod: Record "Settled VAT Period";
        OneYearAhead: Date;
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [Settled VAT Period]
        Initialize();

        // post invoice and payment
        OneYearAhead := CalcDate('<1Y>', WorkDate());

        InvoiceNo := CreateAndPostSalesInvoice(OneYearAhead);
        CreateAndPostPaymentForInvoice(InvoiceNo);

        CreateOrUpdateSettledVATPeriod(SettledVATPeriod, OneYearAhead);
        Assert.IsTrue(SettledVATPeriod.Closed, 'Expected VAT Period to be closed');

        DeleteSettledVATPeriods();
    end;

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementHandler,ConfirmHandler,TradeSettementReportHandler')]
    [Scope('OnPrem')]
    procedure SalesVATSettlementReportWithOutTax()
    var
        SettledVATPeriod: Record "Settled VAT Period";
        VATEntry: Record "VAT Entry";
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [Settled VAT Period] [Trade Settlement] [Sales]
        // [SCENARIO] Validate the content of the "Trade Settlement" report when there is no tax in the invoice
        Initialize();

        // [GIVEN] Posted sales invoice and payment
        InvoiceNo := CreateAndPostSalesInvoice(WorkDate());
        CreateAndPostPaymentForInvoice(InvoiceNo);

        // [WHEN] run "Trade Settlement" report on open settlements
        ExecuteTradeSettlementReport(InvoiceNo, OpenClosedSelection::Open); // Open
        // [THEN] Should be only one open VAT entry
        LibraryReportDataset.LoadDataSetFile();
        Assert.AreEqual(1, LibraryReportDataset.RowCount(), 'There should be only one open VAT entry.');
        LibraryReportDataset.Reset();

        // [GIVEN] Close open settlements
        CreateOrUpdateSettledVATPeriod(SettledVATPeriod, WorkDate());
        Assert.IsTrue(SettledVATPeriod.Closed, 'Expected VAT Period to be closed');

        // [WHEN] run "Trade Settlement" report on open settlements
        ExecuteTradeSettlementReport(InvoiceNo, OpenClosedSelection::Open); // Open
        // [THEN] Should be zero open VAT entries
        LibraryReportDataset.LoadDataSetFile();
        Assert.AreEqual(0, LibraryReportDataset.RowCount(), 'There should be zero open VAT entries.');
        LibraryReportDataset.Reset();

        // [WHEN] run "Trade Settlement" report on closed settlements
        ExecuteTradeSettlementReport(InvoiceNo, OpenClosedSelection::Closed); // Closed
        // [THEN] Should be only one closed VAT entry
        LibraryReportDataset.LoadDataSetFile();
        Assert.AreEqual(1, LibraryReportDataset.RowCount(), 'There should be only one closed VAT entry.');

        // Load the current VAT entry
        VATEntry.Init();
        VATEntry.SetFilter("Document No.", InvoiceNo);
        VATEntry.FindFirst();

        // [THEN] Validate the values: BaseWithoutVAT, TotalSale that are generated in the report OnAfterGetRecord
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('DocNo_VATEntry', VATEntry."Document No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('VATBusPostGroup_VATEntry', VATEntry."VAT Bus. Posting Group");
        LibraryReportDataset.AssertCurrentRowValueEquals('VATProdPostGroup_VATEntry', VATEntry."VAT Prod. Posting Group");
        LibraryReportDataset.AssertCurrentRowValueEquals('BaseWithVAT', 0.0);
        LibraryReportDataset.AssertCurrentRowValueEquals('BaseWithoutVAT', VATEntry.Base);
        LibraryReportDataset.AssertCurrentRowValueEquals('BaseOutside', 0.0);
        LibraryReportDataset.AssertCurrentRowValueEquals('TotalSale', -VATEntry.Base);
        LibraryReportDataset.AssertCurrentRowValueEquals('SalesTaxLow', 0.0);
        LibraryReportDataset.AssertCurrentRowValueEquals('SalesTaxMedium', 0.0);
        LibraryReportDataset.AssertCurrentRowValueEquals('SalesTaxHigh', 0.0);

        DeleteSettledVATPeriods();
    end;

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementHandler,ConfirmHandler,TradeSettementReportHandler')]
    [Scope('OnPrem')]
    procedure SalesVATSettlementReportWithTax()
    var
        SettledVATPeriod: Record "Settled VAT Period";
        VATEntry: Record "VAT Entry";
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [Settled VAT Period] [Trade Settlement] [Sales]
        // [SCENARIO] Validate the content of the "Trade Settlement" report when there is tax in the invoice
        Initialize();

        // [GIVEN] Posted sales invoice and payment
        InvoiceNo := CreateAndPostSalesInvoiceWithVAT(WorkDate());
        CreateAndPostPaymentForInvoice(InvoiceNo);

        // [WHEN] run "Trade Settlement" report on open settlements
        ExecuteTradeSettlementReport(InvoiceNo, OpenClosedSelection::Open); // Open
        // [THEN] Should be only one open VAT entry
        LibraryReportDataset.LoadDataSetFile();
        Assert.AreEqual(1, LibraryReportDataset.RowCount(), 'There should be only one open VAT entry.');
        LibraryReportDataset.Reset();

        // [GIVEN] Close opened settlements.
        CreateOrUpdateSettledVATPeriod(SettledVATPeriod, WorkDate());
        Assert.IsTrue(SettledVATPeriod.Closed, 'Expected VAT Period to be closed');

        // [WHEN] run "Trade Settlement" report on open settlements
        ExecuteTradeSettlementReport(InvoiceNo, OpenClosedSelection::Open); // Open
        // [THEN] Should be zero open VAT entries
        LibraryReportDataset.LoadDataSetFile();
        Assert.AreEqual(0, LibraryReportDataset.RowCount(), 'There should be zero open VAT entries.');
        LibraryReportDataset.Reset();

        // [WHEN] run "Trade Settlement" report on closed settlements
        ExecuteTradeSettlementReport(InvoiceNo, OpenClosedSelection::Closed); // Closed
        // [THEN] Should be only one closed VAT entry
        LibraryReportDataset.LoadDataSetFile();
        Assert.AreEqual(1, LibraryReportDataset.RowCount(), 'There should be only one closed VAT entry.');

        // Load the current VAT entry
        VATEntry.Init();
        VATEntry.SetFilter("Document No.", InvoiceNo);
        VATEntry.FindFirst();

        // [THEN] Validate the values: BaseWithVAT, TotalSale, SalesTaxHigh that are generated in the report OnAfterGetRecord
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('DocNo_VATEntry', VATEntry."Document No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('VATBusPostGroup_VATEntry', VATEntry."VAT Bus. Posting Group");
        LibraryReportDataset.AssertCurrentRowValueEquals('VATProdPostGroup_VATEntry', VATEntry."VAT Prod. Posting Group");
        LibraryReportDataset.AssertCurrentRowValueEquals('BaseWithVAT', VATEntry.Base);
        LibraryReportDataset.AssertCurrentRowValueEquals('BaseWithoutVAT', 0.0);
        LibraryReportDataset.AssertCurrentRowValueEquals('BaseOutside', 0.0);
        LibraryReportDataset.AssertCurrentRowValueEquals('TotalSale', -VATEntry.Base);
        LibraryReportDataset.AssertCurrentRowValueEquals('SalesTaxLow', 0.0);
        LibraryReportDataset.AssertCurrentRowValueEquals('SalesTaxMedium', 0.0);
        LibraryReportDataset.AssertCurrentRowValueEquals('SalesTaxHigh', -VATEntry.Amount);

        DeleteSettledVATPeriods();
    end;

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementHandler,ConfirmHandler,TradeSettementReportHandler')]
    [Scope('OnPrem')]
    procedure PurchVATSettlementReportWithTax()
    var
        SettledVATPeriod: Record "Settled VAT Period";
        VATEntry: Record "VAT Entry";
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [Settled VAT Period] [Trade Settlement] [Purchase]
        // [SCENARIO] Validate the content of the "Trade Settlement" report when there is tax in the purchase invoice
        Initialize();

        // [GIVEN] Posted invoice and payment
        InvoiceNo := CreateAndPostPurchaseInvoiceWithVAT(WorkDate());
        CreateAndPostReceivalForInvoice(InvoiceNo);

        // [WHEN] run "Trade Settlement" report on open settlements
        ExecuteTradeSettlementReport(InvoiceNo, OpenClosedSelection::Open); // Open
        // [THEN] Should be only one open VAT entry
        LibraryReportDataset.LoadDataSetFile();
        Assert.AreEqual(1, LibraryReportDataset.RowCount(), 'There should be only one open VAT entry.');
        LibraryReportDataset.Reset();

        // [GIVEN] Close opened settlements.
        CreateOrUpdateSettledVATPeriod(SettledVATPeriod, WorkDate());
        Assert.IsTrue(SettledVATPeriod.Closed, 'Expected VAT Period to be closed');

        // [WHEN] run "Trade Settlement" report on open settlements
        ExecuteTradeSettlementReport(InvoiceNo, OpenClosedSelection::Open); // Open
        // [THEN] Should be zero open VAT entries
        LibraryReportDataset.LoadDataSetFile();
        Assert.AreEqual(0, LibraryReportDataset.RowCount(), 'There should be zero open VAT entries.');
        LibraryReportDataset.Reset();

        // [WHEN] run "Trade Settlement" report on closed settlements
        ExecuteTradeSettlementReport(InvoiceNo, OpenClosedSelection::Closed); // Closed
        // [THEN] Should be only one closed VAT entry
        LibraryReportDataset.LoadDataSetFile();
        Assert.AreEqual(1, LibraryReportDataset.RowCount(), 'There should be only one closed VAT entry.');

        // Load the current VAT entry
        VATEntry.Init();
        VATEntry.SetFilter("Document No.", InvoiceNo);
        VATEntry.FindFirst();

        // [THEN] Validate the values: BaseWithVAT, PurchaseTaxHigh that are generated in the report OnAfterGetRecord
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('DocNo_VATEntry', VATEntry."Document No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('VATBusPostGroup_VATEntry', VATEntry."VAT Bus. Posting Group");
        LibraryReportDataset.AssertCurrentRowValueEquals('VATProdPostGroup_VATEntry', VATEntry."VAT Prod. Posting Group");
        LibraryReportDataset.AssertCurrentRowValueEquals('BaseWithVAT', VATEntry.Base);
        LibraryReportDataset.AssertCurrentRowValueEquals('BaseWithoutVAT', 0.0);
        LibraryReportDataset.AssertCurrentRowValueEquals('BaseOutside', 0.0);
        LibraryReportDataset.AssertCurrentRowValueEquals('TotalSale', 0.0);
        LibraryReportDataset.AssertCurrentRowValueEquals('PurchaseTaxLow', 0.0);
        LibraryReportDataset.AssertCurrentRowValueEquals('PurchaseTaxMedium', 0.0);
        LibraryReportDataset.AssertCurrentRowValueEquals('PurchaseTaxHigh', VATEntry.Amount);

        DeleteSettledVATPeriods();
    end;

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ApplyEntriesIsAllowedInSettledVATPeriodThatIsReopened()
    var
        SettledVATPeriod: Record "Settled VAT Period";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        InvoiceNo: Code[20];
        PaymentNo: Code[20];
    begin
        // [FEATURE] [Settled VAT Period]
        // [SCENARIO] posting is allowed if Settled VAT period has "Closed" set to false
        Initialize();

        CreateOrUpdateSettledVATPeriod(SettledVATPeriod, WorkDate());

        SettledVATPeriod.Validate(Closed, false);
        SettledVATPeriod.Modify(true);

        InvoiceNo := CreateAndPostSalesInvoice(WorkDate());
        FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, InvoiceNo);
        CustLedgerEntry.CalcFields(Amount);
        PaymentNo := CreateAndPostGenJnlLine(CustLedgerEntry."Customer No.", GenJnlLine."Account Type"::Customer, CustLedgerEntry.Amount);

        ApplyCustomerEntries(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, PaymentNo);
        VerifyApplication(InvoiceNo, PaymentNo);
    end;

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CalcAndPostVATSettlementUpdatesSettledDateOnExsitingSettledVATPeriod()
    var
        SettledVATPeriod: Record "Settled VAT Period";
        FirstDate: Date;
        SecondDate: Date;
    begin
        // [FEATURE] [Settled VAT Period]
        Initialize();

        // In NO VAT periods are defined as 2 month periods
        // If we use end of the month minus one and two days
        // It will always be the same period even if workdate changes
        // We need to verify that the Settlement Date will change
        FirstDate := CalcDate('<CM + 3M - 2D>', WorkDate());
        SecondDate := CalcDate('<CM + 3M - 1D>', WorkDate());

        CreateOrUpdateSettledVATPeriod(SettledVATPeriod, FirstDate);
        Assert.AreEqual(FirstDate, SettledVATPeriod."Settlement Date", 'Wrong settlement date has been set');

        CreateOrUpdateSettledVATPeriod(SettledVATPeriod, SecondDate);
        Assert.AreEqual(SecondDate, SettledVATPeriod."Settlement Date", 'Settlement date should be udpated');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CloseTheVATSettlementPeriodManually()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SettledVATPeriods: TestPage "Settled VAT Periods";
        InvoiceNo: Code[20];
        PaymentNo: Code[20];
        PeriodNo: Integer;
    begin
        // [FEATURE] [Settled VAT Period] [UI]
        Initialize();

        InvoiceNo := CreateAndPostSalesInvoice(WorkDate());
        FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, InvoiceNo);
        CustLedgerEntry.CalcFields(Amount);
        PaymentNo := CreateAndPostGenJnlLine(CustLedgerEntry."Customer No.", GenJnlLine."Account Type"::Customer, CustLedgerEntry.Amount);

        SettledVATPeriods.OpenNew();
        SettledVATPeriods.Year.SetValue(Date2DMY(WorkDate(), 3));

        // In norway PeriodNo are based on 2 month periods
        PeriodNo := Round((Date2DMY(WorkDate(), 2) - 1) / 2, 1, '<') + 1;
        SettledVATPeriods."Period No.".SetValue(PeriodNo);
        SettledVATPeriods."Settlement Date".SetValue(WorkDate());
        SettledVATPeriods.Close();

        // Posting should not be allowed on manually created VAT period
        asserterror CreateAndPostSalesInvoice(WorkDate());

        Assert.ExpectedError(StrSubstNo(SettledAndClosedVATPeriodErr, Date2DMY(WorkDate(), 3), NorwegianVATTools.VATPeriodNo(WorkDate())));

        // Exceptions should be allowed on manually created VAT period
        SetApplicationAlwaysAllowedInGLSetup(true);

        ApplyCustomerEntries(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, PaymentNo);
        VerifyApplication(InvoiceNo, PaymentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateStdVATPeriods()
    var
        VATPeriod: Record "VAT Period";
        PeriodNo: Integer;
        NoOfNorwegianVATPeriods: Integer;
    begin
        // [FEATURE] [VAT Period]
        VATPeriod.DeleteAll();

        NorwegianVATTools.CreateStdVATPeriods(false);
        VATPeriod.Find('-');

        NoOfNorwegianVATPeriods := 6;
        for PeriodNo := 1 to NoOfNorwegianVATPeriods do begin
            Assert.AreEqual(VATPeriod."Start Month", 2 * PeriodNo - 1, 'Periods should be two months long.');
            Assert.AreEqual(VATPeriod."Start Day", 1, 'Day should be the first in the month.');
            VATPeriod.Next();
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CloseIncomeStatementIsNotAllowed()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PostingDate: Date;
    begin
        // [FEATURE] [Settled VAT Period] [Close Income Statement] [Application Always Allowed]
        // [SCENARIO 210143] Posting of Close Income Statement is restricted when 'Application always Allowed' is No on both G/L Setup and User Setup
        Initialize();

        // [GIVEN] 'Application always Allowed' is No on G/L Setup and No on User Setup
        // [GIVEN] Close Income Statement Journal Lines for closed Settled VAT period
        PostingDate := LibraryRandom.RandDate(10);
        PrepareSettledVATPeriodWithApplicationAlwaysAllowed(PostingDate, false, false);
        CreateCloseIncomeStatementGenJnlLines(GenJournalLine, LibraryUtility.GenerateGUID(), PostingDate);

        // [WHEN] Post gen. journal lines
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Error raised 'Posting Date is in a settled and closed VAT period'
        Assert.ExpectedError(
          StrSubstNo(SettledAndClosedVATPeriodErr, Date2DMY(PostingDate, 3), NorwegianVATTools.VATPeriodNo(PostingDate)));

        DeleteUserSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CloseIncomeStatementIsAllowedWhenGLSetupWithAppAlwaysAllowed()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
        PostingDate: Date;
    begin
        // [FEATURE] [Settled VAT Period] [Close Income Statement] [Application Always Allowed]
        // [SCENARIO 210143] Posting of Close Income Statement is allowed when 'Application always Allowed' is Yes on G/L Setup and No on User Setup
        Initialize();

        // [GIVEN] 'Application always Allowed' is Yes on G/L Setup and No on User Setup
        // [GIVEN] Close Income Statement Journal Lines for closed Settled VAT period
        DocumentNo := LibraryUtility.GenerateGUID();
        PostingDate := LibraryRandom.RandDate(10);
        PrepareSettledVATPeriodWithApplicationAlwaysAllowed(PostingDate, true, false);
        CreateCloseIncomeStatementGenJnlLines(GenJournalLine, DocumentNo, PostingDate);

        // [WHEN] Post gen. journal lines
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Gen. journal are posted
        VerifyGLEntriesExist(DocumentNo);

        DeleteUserSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CloseIncomeStatementIsAllowedWhenUserSetupWithAppAlwaysAllowed()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
        PostingDate: Date;
    begin
        // [FEATURE] [Settled VAT Period] [Close Income Statement] [Application Always Allowed]
        // [SCENARIO 210143] Posting of Close Income Statement is allowed when 'Application always Allowed' is No on G/L Setup and Yes on User Setup
        Initialize();

        // [GIVEN] 'Application always Allowed' is No on G/L Setup and Yes on User Setup
        // [GIVEN] Close Income Statement Journal Lines for closed Settled VAT period
        DocumentNo := LibraryUtility.GenerateGUID();
        PostingDate := LibraryRandom.RandDate(10);
        PrepareSettledVATPeriodWithApplicationAlwaysAllowed(PostingDate, false, true);
        CreateCloseIncomeStatementGenJnlLines(GenJournalLine, DocumentNo, PostingDate);

        // [WHEN] Post gen. journal lines
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Gen. journal are posted
        VerifyGLEntriesExist(DocumentNo);

        DeleteUserSetup();
    end;

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementHandler,ConfirmHandler')]
    procedure DoNotCheckVATPeriodsForCostAdjustment()
    var
        SettledVATPeriod: Record "Settled VAT Period";
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ValueEntry: Record "Value Entry";
        i: Integer;
    begin
        // [FEATURE] [Adjust Cost] [VAT Period]
        // [SCENARIO 413851] Posting in closed VAT period is allowed for cost adjustment.
        Initialize();
        LibraryInventory.SetAutomaticCostPosting(true);

        // [GIVEN] Closed settled VAT period = current month.
        CreateOrUpdateSettledVATPeriod(SettledVATPeriod, WorkDate());

        // [GIVEN] Item with FIFO costing method.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Costing Method", Item."Costing Method"::FIFO);
        Item.Modify(true);

        // [GIVEN] Post 3 pcs to inventory, amount = 10 (1 pc = 3.33333), posting date = WORKDATE.
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", '', '', 3);
        ItemJournalLine.Validate(Amount, 10);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Post three negative inventory adjustments, each for 1 pc, amount = 3.33, posting date = WorkDate() + 1 month.
        for i := 1 to 3 do begin
            LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", '', '', -1);
            ItemJournalLine.Validate("Posting Date", CalcDate('<1M>', WorkDate()));
            ItemJournalLine.Modify(true);
            LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
        end;

        // [WHEN] Run the cost adjustment.
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [THEN] No error is raised.
        // [THEN] The cost adjustment completes successfully - the system posts a rounding value entry for the positive item entry in closed VAT period.
        ValueEntry.SetRange("Item No.", Item."No.");
        ValueEntry.CalcSums("Cost Amount (Actual)");
        ValueEntry.TestField("Cost Amount (Actual)", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATDataForYear2022()
    var
        TempVATSpecification: Record "VAT Specification" temporary;
        TempVATNote: Record "VAT Note" temporary;
        VATSpecification: Record "VAT Specification";
        VATNote: Record "VAT Note";
        TempVATReportingCode: Record "VAT Reporting Code" temporary;
        NorwegianVATTools: Codeunit "Norwegian VAT Tools";
    begin
        // [FEATURE] [DEMO]
        // [SCENARIO 418697] Stan can use the VAT data (specification, notes, codes) for year 2022

        Initialize();
        NorwegianVATTools.GetVATSpecifications2022(TempVATSpecification);
        Assert.RecordCount(TempVATSpecification, 6);
        TempVATSpecification.FindSet();
        repeat
            VATSpecification := TempVATSpecification;
            VATSpecification.Insert();
        until TempVATSpecification.Next() = 0;
        NorwegianVATTools.GetVATNotes2022(TempVATNote);
        Assert.RecordCount(TempVATNote, 27);
        TempVATNote.FindSet();
        repeat
            VATNote := TempVATNote;
            VATNote.Insert();
        until TempVATNote.Next() = 0;
        NorwegianVATTools.GetVATReportingCodes2022(TempVATReportingCode);
        Assert.RecordCount(TempVATReportingCode, 13);
    end;

    [Test]
    [HandlerFunctions('SuggestLinesCustomVATStatementRPH')]
    [Scope('OnPrem')]
    procedure CalcVATBaseAndAmountWithVATCodeFilter()
    var
        VATStatementLine: Record "VAT Statement Line";
        VATReportHeader: Record "VAT Report Header";
        VATEntry: Record "VAT Entry";
        VATReportingCode: Code[20];
        PostingDate: Date;
    begin
        // [FEATURE] [VAT Return] [Suggest Lines]
        // [SCENARIO 418697] Both VAT base and VAT amount are calculated when VAT Statement has "VAT Code" specified

        Initialize();
        SetReportVATBaseInVATReportSetup(true);
        LibraryVATReport.CreateVATReportConfigurationNo(Codeunit::"VAT Report Suggest Lines", 0, 0, 0, 0);
        PostingDate := FindPostingDateWithNoVATEntries();
        CreateVATReturn(VATReportHeader, DATE2DMY(PostingDate, 3));
        VATReportingCode := CreateVATReportingCode();
        SetupSingleVATStatementLineForVATCode(VATStatementLine);
        MockVATEntryWithVATCode(VATEntry, PostingDate, VATReportingCode);
        LibraryVariableStorage.Enqueue(VATStatementLine."Statement Template Name");
        LibraryVariableStorage.Enqueue(VATStatementLine."Statement Name");
        SuggestLinesWithPeriod(
          VATReportHeader, Selection::Open, PeriodSelection::"Within Period", VATReportHeader."Period Year", Date2DMY(PostingDate, 2), false);
        VerifyVATStatementReportLineBaseAndAmount(VATReportHeader, VATStatementLine."Box No.", VATEntry.Base, VATEntry.Amount);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('TradeSettlementReportHandler')]
    [Scope('OnPrem')]
    procedure NoVATPeriodTradeSettlementError()
    var
        VATPeriod: Record "VAT Period";
    begin
        // [SCENARIO 430755] Running report "Trade Settlement" request page with no VAT periods does not cause error message
        Initialize();

        // [GIVEN] No VAT Periods exist
        VATPeriod.DeleteAll();

        // [WHEN] Run "Trade Settlement" report request page
        REPORT.Run(REPORT::"Trade Settlement");

        // [THEN] No errors shown, the report can be closed
    end;

    [Test]
    [HandlerFunctions('TradeSettlement2017ReportHandler')]
    [Scope('OnPrem')]
    procedure NoVATPeriodTradeSettlement2017Error()
    var
        VATPeriod: Record "VAT Period";
    begin
        // [SCENARIO 430755] Running report "Trade Settlement 2017" request page with no VAT periods does not cause error message
        Initialize();

        // [GIVEN] No VAT Periods exist
        VATPeriod.DeleteAll();

        // [WHEN] Run "Trade Settlement 2017" report request page
        REPORT.Run(REPORT::"Trade Settlement 2017");

        // [THEN] No errors shown, the report can be closed
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATBaseAndAmountInclNonDeductibleVATInVATReturnWithPropDed50()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATStmtLine: Record "VAT Statement Line";
        VATEntry: Record "VAT Entry";
        VATReportSetup: Record "VAT Report Setup";
        VATStatement: Report "VAT Statement";
        TotalAmount: Decimal;
        TotalBase: Decimal;
    begin
        // [FEATURE] [VAT Return] [UT]
        // [SCENARIO 433702] Both VAT Base and VAT Amount includes Non-Deductible VAT when "Proportional Deduction %" is 50

        Initialize();
        VATReportSetup.Get();
        VATReportSetup.Validate("Report VAT Base", true);
        VATReportSetup.Modify(true);

        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandIntInRange(10, 20));
        VATPostingSetup.Validate("Calc. Prop. Deduction VAT", true);
        VATPostingSetup.Validate("Proportional Deduction VAT %", 50);
        VATPostingSetup.Modify(true);
        MockSalesVATEntryFromVATPostingSetup(VATEntry, VATPostingSetup, LibraryRandom.RandDec(100, 2), LibraryRandom.RandDec(100, 2));

        VATStmtLine."VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
        VATStmtLine."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
        VATStmtLine.Type := VATStmtLine.Type::"VAT Entry Totaling";
        VATStmtLine."Gen. Posting Type" := VATStmtLine."Gen. Posting Type"::Sale;
        VATStmtLine."Amount Type" := VATStmtLine."Amount Type"::Amount;
        VATStmtLine."Incl. Non Deductible VAT" := true;
        VATStatement.CalcLineTotalWithBase(VATStmtLine, TotalAmount, TotalBase, 0);
        Assert.AreEqual(VATEntry.Base * 2, TotalBase, 'Incorrect base');
        Assert.AreEqual(VATEntry.Amount * 2, TotalAmount, 'Incorrect amount');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnlyVATAmountInclNonDeductibleVATInVATReturnWithPropDed50()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATStmtLine: Record "VAT Statement Line";
        VATEntry: Record "VAT Entry";
        VATReportSetup: Record "VAT Report Setup";
        VATStatement: Report "VAT Statement";
        TotalAmount: Decimal;
        TotalBase: Decimal;
    begin
        // [FEATURE] [VAT Return] [UT]
        // [SCENARIO 433702] Only VAT Amount includes Non-Deductible VAT when "Proportional Deduction %" is 50

        Initialize();
        VATReportSetup.Get();
        VATReportSetup.Validate("Report VAT Base", false);
        VATReportSetup.Modify(true);

        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandIntInRange(10, 20));
        VATPostingSetup.Validate("Calc. Prop. Deduction VAT", true);
        VATPostingSetup.Validate("Proportional Deduction VAT %", 50);
        VATPostingSetup.Modify(true);
        MockSalesVATEntryFromVATPostingSetup(VATEntry, VATPostingSetup, LibraryRandom.RandDec(100, 2), LibraryRandom.RandDec(100, 2));

        VATStmtLine."VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
        VATStmtLine."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
        VATStmtLine.Type := VATStmtLine.Type::"VAT Entry Totaling";
        VATStmtLine."Gen. Posting Type" := VATStmtLine."Gen. Posting Type"::Sale;
        VATStmtLine."Amount Type" := VATStmtLine."Amount Type"::Amount;
        VATStmtLine."Incl. Non Deductible VAT" := true;
        VATStatement.CalcLineTotalWithBase(VATStmtLine, TotalAmount, TotalBase, 0);
        Assert.AreEqual(0, TotalBase, 'Incorrect base');
        Assert.AreEqual(VATEntry.Amount * 2, TotalAmount, 'Incorrect amount');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnlyVATBaseInclNonDeductibleVATInVATReturnWithPropDed50()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATStmtLine: Record "VAT Statement Line";
        VATEntry: Record "VAT Entry";
        VATStatement: Report "VAT Statement";
        TotalAmount: Decimal;
        TotalBase: Decimal;
    begin
        // [FEATURE] [VAT Return] [UT]
        // [SCENARIO 433702] Only VAT base includes Non-Deductible VAT when "Proportional Deduction %" is 50

        Initialize();

        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandIntInRange(10, 20));
        VATPostingSetup.Validate("Calc. Prop. Deduction VAT", true);
        VATPostingSetup.Validate("Proportional Deduction VAT %", 50);
        VATPostingSetup.Modify(true);
        MockSalesVATEntryFromVATPostingSetup(VATEntry, VATPostingSetup, LibraryRandom.RandDec(100, 2), LibraryRandom.RandDec(100, 2));

        VATStmtLine."VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
        VATStmtLine."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
        VATStmtLine.Type := VATStmtLine.Type::"VAT Entry Totaling";
        VATStmtLine."Gen. Posting Type" := VATStmtLine."Gen. Posting Type"::Sale;
        VATStmtLine."Amount Type" := VATStmtLine."Amount Type"::Base;
        VATStmtLine."Incl. Non Deductible VAT" := true;
        VATStatement.CalcLineTotalWithBase(VATStmtLine, TotalAmount, TotalBase, 0);
        Assert.AreEqual(VATEntry.Base * 2, TotalAmount, 'Incorrect base');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATBaseAndAmountInclNonDeductibleVATInVATReturnWithPropDed0()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATStmtLine: Record "VAT Statement Line";
        VATEntry: Record "VAT Entry";
        VATReportSetup: Record "VAT Report Setup";
        VATStatement: Report "VAT Statement";
        TotalAmount: Decimal;
        TotalBase: Decimal;
    begin
        // [FEATURE] [VAT Return] [UT]
        // [SCENARIO 433702] Both VAT Base and VAT Amount includes Non-Deductible VAT when "Proportional Deduction %" is 0

        Initialize();
        VATReportSetup.Get();
        VATReportSetup.Validate("Report VAT Base", true);
        VATReportSetup.Modify(true);

        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandIntInRange(10, 20));
        VATPostingSetup.Validate("Calc. Prop. Deduction VAT", true);
        VATPostingSetup.Validate("Proportional Deduction VAT %", 0);
        VATPostingSetup.Modify(true);
        MockSalesVATEntryFromVATPostingSetup(VATEntry, VATPostingSetup, LibraryRandom.RandDec(100, 2), 0);

        VATStmtLine."VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
        VATStmtLine."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
        VATStmtLine.Type := VATStmtLine.Type::"VAT Entry Totaling";
        VATStmtLine."Gen. Posting Type" := VATStmtLine."Gen. Posting Type"::Sale;
        VATStmtLine."Amount Type" := VATStmtLine."Amount Type"::Amount;
        VATStmtLine."Incl. Non Deductible VAT" := true;
        VATStatement.CalcLineTotalWithBase(VATStmtLine, TotalAmount, TotalBase, 0);
        Assert.AreEqual(VATEntry.Base, TotalBase, 'Incorrect base');
        Assert.AreEqual(Round(VATEntry.Base * VATPostingSetup."VAT %" / 100), TotalAmount, 'Incorrect amount');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnlyVATAmountInclNonDeductibleVATInVATReturnWithPropDed0()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATStmtLine: Record "VAT Statement Line";
        VATEntry: Record "VAT Entry";
        VATReportSetup: Record "VAT Report Setup";
        VATStatement: Report "VAT Statement";
        TotalAmount: Decimal;
        TotalBase: Decimal;
    begin
        // [FEATURE] [VAT Return] [UT]
        // [SCENARIO 433702] Only VAT Amount includes Non-Deductible VAT when "Proportional Deduction %" is 0

        Initialize();
        VATReportSetup.Get();
        VATReportSetup.Validate("Report VAT Base", false);
        VATReportSetup.Modify(true);

        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandIntInRange(10, 20));
        VATPostingSetup.Validate("Calc. Prop. Deduction VAT", true);
        VATPostingSetup.Validate("Proportional Deduction VAT %", 50);
        VATPostingSetup.Modify(true);
        MockSalesVATEntryFromVATPostingSetup(VATEntry, VATPostingSetup, LibraryRandom.RandDec(100, 2), 0);

        VATStmtLine."VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
        VATStmtLine."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
        VATStmtLine.Type := VATStmtLine.Type::"VAT Entry Totaling";
        VATStmtLine."Gen. Posting Type" := VATStmtLine."Gen. Posting Type"::Sale;
        VATStmtLine."Amount Type" := VATStmtLine."Amount Type"::Amount;
        VATStatement.CalcLineTotalWithBase(VATStmtLine, TotalAmount, TotalBase, 0);
        Assert.AreEqual(0, TotalBase, 'Incorrect base');
        Assert.AreEqual(Round(TotalBase * VATPostingSetup."VAT %" / 100), TotalAmount, 'Incorrect amount');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnlyVATBaseInclNonDeductibleVATInVATReturnWithPropDed0()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATStmtLine: Record "VAT Statement Line";
        VATEntry: Record "VAT Entry";
        VATStatement: Report "VAT Statement";
        TotalAmount: Decimal;
        TotalBase: Decimal;
    begin
        // [FEATURE] [VAT Return] [UT]
        // [SCENARIO 433702] Only VAT base includes Non-Deductible VAT when "Proportional Deduction %" is 0

        Initialize();

        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandIntInRange(10, 20));
        VATPostingSetup.Validate("Calc. Prop. Deduction VAT", true);
        VATPostingSetup.Validate("Proportional Deduction VAT %", 0);
        VATPostingSetup.Modify(true);
        MockSalesVATEntryFromVATPostingSetup(VATEntry, VATPostingSetup, LibraryRandom.RandDec(100, 2), 0);

        VATStmtLine."VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
        VATStmtLine."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
        VATStmtLine.Type := VATStmtLine.Type::"VAT Entry Totaling";
        VATStmtLine."Gen. Posting Type" := VATStmtLine."Gen. Posting Type"::Sale;
        VATStmtLine."Amount Type" := VATStmtLine."Amount Type"::Base;
        VATStatement.CalcLineTotalWithBase(VATStmtLine, TotalAmount, TotalBase, 0);
        Assert.AreEqual(VATEntry.Base, TotalAmount, 'Incorrect base');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATBaseAndAmountDoesNotInclNonDeductible()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATStmtLine: Record "VAT Statement Line";
        VATEntry: Record "VAT Entry";
        VATReportSetup: Record "VAT Report Setup";
        VATStatement: Report "VAT Statement";
        TotalAmount: Decimal;
        TotalBase: Decimal;
    begin
        // [FEATURE] [VAT Return] [UT]
        // [SCENARIO 433702] Both VAT Base and VAT Amount does not include Non-Deductible VAT when "Calc. Prop. Deduction VAT" option is disabled in the VAT Posting Setup

        Initialize();
        VATReportSetup.Get();
        VATReportSetup.Validate("Report VAT Base", true);
        VATReportSetup.Modify(true);

        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandIntInRange(10, 20));
        VATPostingSetup.Validate("Calc. Prop. Deduction VAT", false);
        VATPostingSetup.Validate("Proportional Deduction VAT %", 50);
        VATPostingSetup.Modify(true);
        MockSalesVATEntryFromVATPostingSetup(VATEntry, VATPostingSetup, LibraryRandom.RandDec(100, 2), LibraryRandom.RandDec(100, 2));

        VATStmtLine."VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
        VATStmtLine."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
        VATStmtLine.Type := VATStmtLine.Type::"VAT Entry Totaling";
        VATStmtLine."Gen. Posting Type" := VATStmtLine."Gen. Posting Type"::Sale;
        VATStmtLine."Amount Type" := VATStmtLine."Amount Type"::Amount;
        VATStatement.CalcLineTotalWithBase(VATStmtLine, TotalAmount, TotalBase, 0);
        Assert.AreEqual(VATEntry.Base, TotalBase, 'Incorrect base');
        Assert.AreEqual(VATEntry.Amount, TotalAmount, 'Incorrect amount');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NonDedAmountsInVATReturnWhenVATStatementCombineBothNormalAndNonDedLines()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATStatementName: Record "VAT Statement Name";
        VATStmtLine: Record "VAT Statement Line";
        VATEntry: Record "VAT Entry";
        VATReportSetup: Record "VAT Report Setup";
        VATStatement: Report "VAT Statement";
        RowNo: array[2] of Code[10];
        TotalAmount: Decimal;
        TotalBase: Decimal;
        TotalNDAmount: Decimal;
        TotalNDBase: Decimal;
    begin
        // [FEATURE] [VAT Return] [UT]
        // [SCENARIO 450351] Non-Deductible amount are correct in the VAT return then the VAT statement contains both normal and Non-Deductible lines

        Initialize();
        VATReportSetup.Get();
        VATReportSetup.Validate("Report VAT Base", true);
        VATReportSetup.Modify(true);

        // Norml VAT. No Non-Deductible Setup. No VAT Entry
        LibraryERM.CreateVATStatementNameWithTemplate(VATStatementName);
        VATStmtLine."Statement Template Name" := VATStatementName."Statement Template Name";
        VATStmtLine."Statement Name" := VATStatementName.Name;
        VATStmtLine.Type := VATStmtLine.Type::"VAT Entry Totaling";
        VATStmtLine."Gen. Posting Type" := VATStmtLine."Gen. Posting Type"::Sale;
        VATStmtLine."Amount Type" := VATStmtLine."Amount Type"::Amount;
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandIntInRange(10, 20));

        VATStmtLine."VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
        VATStmtLine."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
        VATStmtLine.Type := VATStmtLine.Type::"VAT Entry Totaling";
        VATStmtLine."Gen. Posting Type" := VATStmtLine."Gen. Posting Type"::Sale;
        VATStmtLine."Amount Type" := VATStmtLine."Amount Type"::Amount;
        VATStmtLine."Row No." := LibraryUtility.GenerateGUID();
        VATStmtLine.Insert();
        RowNo[1] := VATStmtLine."Row No.";

        // Normal VAT. Non-Deductible Setup. VAT Entry
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandIntInRange(10, 20));
        VATPostingSetup.Validate("Calc. Prop. Deduction VAT", true);
        VATPostingSetup.Validate("Proportional Deduction VAT %", 30);
        VATPostingSetup.Modify(true);
        MockSalesVATEntryFromVATPostingSetup(VATEntry, VATPostingSetup, LibraryRandom.RandDec(100, 2), LibraryRandom.RandDec(100, 2));
        VATStmtLine."VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
        VATStmtLine."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
        VATStmtLine."Line No." += 10000;
        VATStmtLine."Row No." := LibraryUtility.GenerateGUID();
        VATStmtLine.Insert();
        RowNo[2] := VATStmtLine."Row No.";

        // Row Totaling line combaining two above
        VATStmtLine.Type := VATStmtLine.Type::"Row Totaling";
        VATStmtLine."Row No." := '';
        VATStmtLine."Row Totaling" := RowNo[1] + '|' + RowNo[2];
        VATStmtLine."Line No." += 10000;
        VATStmtLine.Insert();

        VATStatement.CalcLineTotalWithNonDeductiblePart(VATStmtLine, TotalAmount, TotalBase, TotalNDAmount, TotalNDBase, 0);
        Assert.AreEqual(
            Round(VATEntry.Base * (100 / VATPostingSetup."Proportional Deduction VAT %" - 1)), TotalNDBase, 'Incorrect base');
        Assert.AreEqual(
            Round(VATEntry.Amount * (100 / VATPostingSetup."Proportional Deduction VAT %" - 1)), TotalNDAmount, 'Incorrect amount');
    end;

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementHandler,ConfirmHandler')]
    procedure VATCalculationFromReverseChargeAndWithNormalVAT()
    var
        VATPostingSetup, VATPostingSetup1 : Record "VAT Posting Setup";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        DocNo, SettlementDocNo : Code[20];
    begin
        // [SCENARIO 575707] Issue with VAT Calculation from Reverse Charge and Partial Deduction on Mixed-Invoice Scenarios in Norwegian version
        Initialize();

        // [GIVEN] Setup VAT Posting Setup with Reverse Charge as 25 VAT %, Calc. Prop. Deduction VAT as true and Proportional Deduction VAT % as 10.63
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT", LibraryRandom.RandIntInRange(25, 25));
        VATPostingSetup.Validate("Reverse Chrg. VAT Acc.", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("Calc. Prop. Deduction VAT", true);
        VATPostingSetup.Validate("Proportional Deduction VAT %", 10.63);
        VATPostingSetup.Modify(true);

        // [GIVEN] Setup VAT Posting Setup with Normal VAT and 0 VAT %
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup1, VATPostingSetup1."VAT Calculation Type"::"Normal VAT", 0);

        // [GIVEN] Create General Journal line with first line as account type vendor
        DocNo := LibraryRandom.RandText(15);
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        CreateGenJournalLine(GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice, DocNo, GenJournalLine."Account Type"::Vendor, LibraryPurch.CreateVendor(Vendor), -257632.33, GenJournalLine."Gen. Posting Type"::" ", '', '');

        // [GIVEN] Create General Journal line with second line as account type G/L Account and VAT as normal charge
        CreateGenJournalLine(GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice, DocNo, GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), 5360.33, GenJournalLine."Gen. Posting Type"::Purchase, VATPostingSetup1."VAT Bus. Posting Group", VATPostingSetup1."VAT Prod. Posting Group");

        // [GIVEN] Create General Journal line with third line as account type G/L Account and VAT as reverse charge
        CreateGenJournalLine(GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice, DocNo, GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), 252272.00, GenJournalLine."Gen. Posting Type"::Purchase, VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group");

        // [GIVEN] Post General Journal Line
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Run the Calculate and Post VAT Settlement report and Post the VAT Settlement
        SettlementDocNo := LibraryRandom.RandText(20);
        CalcAndPostVATSettlementWithDocumentNo(WorkDate(), WorkDate(), WorkDate(), SettlementDocNo, true);

        // [THEN] The amount deducted from Reverse Charge VAT Posting G/L account should match the actual VAT calculated.
        Assert.AreEqual(GetGLEntryAmount(DocNo, VATPostingSetup."Reverse Chrg. VAT Acc."), GetGLEntryAmount(SettlementDocNo, VATPostingSetup."Reverse Chrg. VAT Acc."), 'Incorrect Amount');
    end;

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementHandler,ConfirmHandler')]
    procedure VATCalculationFromReverseChargeAndPartialDeduction()
    var
        VATPostingSetup, VATPostingSetup1 : Record "VAT Posting Setup";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        DocNo, SettlementDocNo : Code[20];
    begin
        // [SCENARIO 605569] Issue with VAT Calculation from Reverse Charge and Partial Deduction on Mixed-Invoice Scenarios in Norwegian version
        Initialize();

        // [GIVEN] Setup VAT Posting Setup with Reverse Charge as 25 VAT %, Calc. Prop. Deduction VAT as true and Proportional Deduction VAT % as 10.63
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT", LibraryRandom.RandIntInRange(25, 25));
        VATPostingSetup.Validate("Reverse Chrg. VAT Acc.", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("Calc. Prop. Deduction VAT", true);
        VATPostingSetup.Validate("Proportional Deduction VAT %", 10.63);
        VATPostingSetup.Modify(true);

        // [GIVEN] Setup VAT Posting Setup with Normal VAT and 0 VAT %
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup1, VATPostingSetup1."VAT Calculation Type"::"Normal VAT", 0);

        // [GIVEN] Create General Journal line with first line as account type vendor
        DocNo := LibraryRandom.RandText(15);
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        CreateGenJournalLine(GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice, DocNo, GenJournalLine."Account Type"::Vendor, LibraryPurch.CreateVendor(Vendor), -257632.33, GenJournalLine."Gen. Posting Type"::" ", '', '');

        // [GIVEN] Create General Journal line with second line as account type G/L Account and VAT as normal charge
        CreateGenJournalLine(GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice, DocNo, GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), 5360.33, GenJournalLine."Gen. Posting Type"::Purchase, VATPostingSetup1."VAT Bus. Posting Group", VATPostingSetup1."VAT Prod. Posting Group");

        // [GIVEN] Create General Journal line with third line as account type G/L Account and VAT as reverse charge
        CreateGenJournalLine(GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice, DocNo, GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), 252272.00, GenJournalLine."Gen. Posting Type"::Purchase, VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group");

        // [GIVEN] Post General Journal Line
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Run the Calculate and Post VAT Settlement report and Post the VAT Settlement
        SettlementDocNo := LibraryRandom.RandText(20);
        CalcAndPostVATSettlementWithDocumentNo(WorkDate(), WorkDate(), WorkDate(), SettlementDocNo, true);

        // [THEN] The amount deducted from Reverse Charge VAT Posting G/L account should match the actual VAT calculated.
        Assert.AreEqual(GetGLEntryAmount(DocNo, VATPostingSetup."Reverse Chrg. VAT Acc."), GetGLEntryAmount(SettlementDocNo, VATPostingSetup."Reverse Chrg. VAT Acc."), 'Incorrect Amount');
    end;

    local procedure Initialize()
    begin
        LibraryReportDataset.Reset();
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();
        DeleteSettledVATPeriods();

        LibraryRandom.SetSeed(1);

        if IsInitialized then
            exit;

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Inventory Setup");
        LibrarySetupStorage.Save(Database::"VAT Report Setup");
        IsInitialized := true;
        Commit();
    end;

    local procedure ApplicationInClosedVATPeriodAfterCalcAndPostVATSettlement(var InvoiceNo: Code[20]; var PaymentNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        InvoiceNo := CreateAndPostSalesInvoice(WorkDate());
        FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, InvoiceNo);
        CustLedgerEntry.CalcFields(Amount);
        PaymentNo := CreateAndPostGenJnlLine(CustLedgerEntry."Customer No.", GenJnlLine."Account Type"::Customer, CustLedgerEntry.Amount);

        CalcAndPostVATSettlement(WorkDate(), WorkDate(), WorkDate(), true);

        ApplyCustomerEntries(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, PaymentNo);
    end;

    local procedure CreateAndPostSalesInvoice(PostingDate: Date): Code[20]
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Find customer does not include VAT
        FindCustomer(Customer);
        FindItem(Item);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateAndPostSalesInvoiceWithVAT(PostingDate: Date): Code[20]
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Create customer includes VAT
        LibrarySales.CreateCustomer(Customer);
        FindItem(Item);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateAndPostPurchaseInvoiceWithVAT(PostingDate: Date): Code[20]
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        VATBusPostingGroup: Record "VAT Business Posting Group";
        VATProdPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        LibraryERM.FindVATBusinessPostingGroup(VATBusPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProdPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostingGroup.Code, VATProdPostingGroup.Code);
        VATPostingSetup."Purchase VAT Account" := CreateGLAccount();
        VATPostingSetup."VAT %" := 25;
        VATPostingSetup.Modify();
        CreatePurchDoc(PurchHeader, PurchLine, GeneralPostingSetup, VATPostingSetup);

        PurchHeader.Validate("Posting Date", PostingDate);
        PurchHeader.Modify(true);

        exit(LibraryPurch.PostPurchaseDocument(PurchHeader, true, true));
    end;

    [Normal]
    local procedure CreateAndPostPaymentForInvoice(InvoiceNo: Code[20]) PaymentNo: Code[20]
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, InvoiceNo);
        CustLedgerEntry.CalcFields(Amount);
        PaymentNo := CreateAndPostGenJnlLine(CustLedgerEntry."Customer No.", GenJnlLine."Account Type"::Customer, CustLedgerEntry.Amount);
        exit(PaymentNo);
    end;

    [Normal]
    local procedure CreateAndPostReceivalForInvoice(InvoiceNo: Code[20]) PaymentNo: Code[20]
    var
        VendLedgerEntry: Record "Vendor Ledger Entry";
    begin
        FindVendorLedgerEntry(VendLedgerEntry, VendLedgerEntry."Document Type"::Invoice, InvoiceNo);
        VendLedgerEntry.CalcFields(Amount);
        PaymentNo := CreateAndPostGenJnlLine(VendLedgerEntry."Vendor No.", GenJnlLine."Account Type"::Vendor, VendLedgerEntry.Amount);
        exit(PaymentNo);
    end;

    local procedure CalcAndPostVATSettlement(StartingDate: Date; EndingDate: Date; PostingDate: Date; Post: Boolean)
    var
        GLAccount: Record "G/L Account";
        CalcPostVATSettlement: Report "Calc. and Post VAT Settlement";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        CalcPostVATSettlement.InitializeRequest(
          StartingDate, EndingDate, PostingDate, LibraryUtility.GenerateGUID(), GLAccount."No.", false, Post);
        CalcPostVATSettlement.SetInitialized(false);
        Commit();
        CalcPostVATSettlement.Run();
    end;

    local procedure CreatePurchDoc(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; GenPostingSetup: Record "General Posting Setup"; VATPostingSetup: Record "VAT Posting Setup")
    begin
        LibraryPurch.CreatePurchHeader(
          PurchHeader, PurchHeader."Document Type"::Invoice, CreateVendor(GenPostingSetup."Gen. Bus. Posting Group"));

        PurchHeader."Vendor Invoice No." := LibraryUtility.GenerateGUID();
        PurchHeader.Modify();

        CreatePurchLine(PurchLine, PurchHeader, GenPostingSetup."Gen. Prod. Posting Group", VATPostingSetup, 3, 23.12);
    end;

    local procedure CreatePurchLine(var PurchLine: Record "Purchase Line"; PurchHeader: Record "Purchase Header"; GenProdPostGroupCode: Code[20]; VATPostingSetup: Record "VAT Posting Setup"; Quantity: Decimal; DirectUnitCost: Decimal)
    var
        GLAccNo: Code[20];
    begin
        GLAccNo := CreateGLAccWithSetup(GenProdPostGroupCode, VATPostingSetup."VAT Prod. Posting Group");

        LibraryPurch.CreatePurchaseLine(
          PurchLine, PurchHeader, PurchLine.Type::"G/L Account", GLAccNo, Quantity);
        PurchLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchLine.Modify(true);
    end;

    local procedure CreateVendor(GenBusPostGroupCode: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
        VATBusPostingGroup: Record "VAT Business Posting Group";
    begin
        LibraryPurch.CreateVendor(Vendor);
        Vendor.Validate("Gen. Bus. Posting Group", GenBusPostGroupCode);
        LibraryERM.FindVATBusinessPostingGroup(VATBusPostingGroup);
        Vendor.Validate("VAT Bus. Posting Group", VATBusPostingGroup.Code);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateGLAccWithSetup(GenProdPostGroupCode: Code[20]; VATProdPostGroupCode: Code[20]) GLAccNo: Code[20]
    begin
        GLAccNo := CreateGLAccount();
        UpdateGLAccWithSetup(GLAccNo, GenProdPostGroupCode, VATProdPostGroupCode);
        exit(GLAccNo);
    end;

    local procedure UpdateGLAccWithSetup(GLAccNo: Code[20]; GenProdPostGroupCode: Code[20]; VATProdPostGroupCode: Code[20])
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Get(GLAccNo);
        GLAccount.Validate("Gen. Prod. Posting Group", GenProdPostGroupCode);
        GLAccount.Validate("VAT Prod. Posting Group", VATProdPostGroupCode);
        GLAccount.Modify(true);
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        exit(GLAccount."No.");
    end;

    local procedure CreateGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; AccountNo: Code[20]; AccountType: Enum "Gen. Journal Account Type"; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          AccountType, AccountNo, -Amount);
    end;

    local procedure CreateAndPostGenJnlLine(AccountNo: Code[20]; AccountType: Enum "Gen. Journal Account Type"; Amount: Decimal): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateGenJnlLine(GenJournalLine, AccountNo, AccountType, Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine."Document No.");
    end;

    local procedure CreateCloseIncomeStatementGenJnlLines(var GenJournalLine: Record "Gen. Journal Line"; DocumentNo: Code[20]; PostingDate: Date)
    var
        SourceCodeSetup: Record "Source Code Setup";
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), LibraryRandom.RandDec(100, 2));
        SourceCodeSetup.Get();
        UpdateGenJnlLine(GenJournalLine, DocumentNo, PostingDate, SourceCodeSetup."Close Income Statement");
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), -GenJournalLine.Amount);
        UpdateGenJnlLine(GenJournalLine, DocumentNo, PostingDate, SourceCodeSetup."Close Income Statement");
    end;

    local procedure MockSalesVATEntryFromVATPostingSetup(var VATEntry: Record "VAT Entry"; VATPostingSetup: Record "VAT Posting Setup"; VATBase: Decimal; VATAmount: Decimal)
    begin
        VATEntry.Init();
        VATEntry."Entry No." := LibraryUtility.GetNewRecNo(VATEntry, VATEntry.FieldNo("Entry No."));
        VATEntry."VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
        VATEntry."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
        VATEntry.Base := VATBase;
        VATEntry.Amount := VATAmount;
        VATEntry.Type := VATEntry.Type::Sale;
        VATEntry.Insert();
    end;

    local procedure UpdateGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentNo: Code[20]; PostingDate: Date; SourceCode: Code[10])
    begin
        GenJournalLine."Document No." := DocumentNo;
        GenJournalLine."Posting Date" := PostingDate;
        GenJournalLine."Source Code" := SourceCode;
        GenJournalLine."Bal. Account Type" := GenJournalLine."Bal. Account Type"::"G/L Account";
        GenJournalLine."Bal. Account No." := '';
        GenJournalLine.Modify();
    end;

    local procedure ApplyCustomerEntries(var CustLedgerEntry: Record "Cust. Ledger Entry"; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    var
        CustLedgerEntry2: Record "Cust. Ledger Entry";
    begin
        LibraryERM.SetApplyCustomerEntry(CustLedgerEntry, CustLedgerEntry.Amount);
        FindCustomerLedgerEntry(CustLedgerEntry2, DocumentType, DocumentNo);
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry2);
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry);
    end;

    local procedure FindCustomer(var Customer: Record Customer)
    begin
        // Filter Customer so that errors are not generated due to mandatory fields.
        Customer.SetFilter("Customer Posting Group", '<>''''');
        Customer.SetFilter("Gen. Bus. Posting Group", '<>''''');
        Customer.SetFilter("Payment Terms Code", '<>''''');
        Customer.SetRange(Blocked, Customer.Blocked::" ");
        // For Complete Shipping Advice, partial shipments are disallowed, hence select Partial.
        Customer.SetRange("Shipping Advice", Customer."Shipping Advice"::Partial);

        Customer.FindSet();
    end;

    local procedure FindCustomerLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    begin
        CustLedgerEntry.SetRange("Document Type", DocumentType);
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        CustLedgerEntry.FindLast();
    end;

    local procedure FindItem(var Item: Record Item)
    begin
        // Filter Item so that errors are not generated due to mandatory fields or Item Tracking.
        Item.SetFilter("Inventory Posting Group", '<>''''');
        Item.SetFilter("Gen. Prod. Posting Group", '<>''''');
        Item.SetRange("Item Tracking Code", '');
        Item.SetRange(Blocked, false);
        Item.SetFilter("Unit Price", '<>0');
        Item.SetFilter(Reserve, '<>%1', Item.Reserve::Always);

        Item.FindSet();
    end;

    local procedure FindVendorLedgerEntry(var VendLedgerEntry: Record "Vendor Ledger Entry"; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    begin
        VendLedgerEntry.SetRange("Document Type", DocumentType);
        VendLedgerEntry.SetRange("Document No.", DocumentNo);
        VendLedgerEntry.FindLast();
    end;

    [Normal]
    local procedure SetApplicationAlwaysAllowedInGLSetup(ApplnAlwaysAllowed: Boolean)
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        GLSetup."Application always Allowed" := ApplnAlwaysAllowed;
        GLSetup.Modify(true);
    end;

    local procedure SetUserSetupApplicationAlwaysAllowed(AlwaysAllow: Boolean): Boolean
    var
        UserSetup: Record "User Setup";
        UserCreated: Boolean;
    begin
        if not UserSetup.Get(UserId) then begin
            UserSetup.Init();
            UserSetup."User ID" := UserId;
            UserSetup.Insert();
            UserCreated := true;
        end;

        UserSetup."Application always Allowed" := AlwaysAllow;
        UserSetup.Modify();
        exit(UserCreated);
    end;

    local procedure SetReportVATBaseInVATReportSetup(NewReportVATBase: Boolean)
    var
        VATReportSetup: Record "VAT Report Setup";
    begin
        VATReportSetup.Get();
        VATReportSetup.Validate("Report VAT Base", NewReportVATBase);
        VATReportSetup.Modify(true);
    end;

    local procedure SetupSingleVATStatementLineForVATCode(var VATStatementLine: Record "VAT Statement Line")
    var
        VATStatementTemplate: Record "VAT Statement Template";
        VATStatementName: Record "VAT Statement Name";
    begin
        LibraryERM.CreateVATStatementTemplate(VATStatementTemplate);
        LibraryERM.CreateVATStatementName(VATStatementName, VATStatementTemplate.Name);
        LibraryERM.CreateVATStatementLine(VATStatementLine, VATStatementName."Statement Template Name", VATStatementName.Name);
        VATStatementLine.Validate(Type, VATStatementLine.Type::"VAT Entry Totaling");
        VATStatementLine.Validate("Amount Type", VATStatementLine."Amount Type"::Amount);
        VATStatementLine.Validate("Box No.", LibraryUtility.GenerateGUID());
        VATStatementLine.Modify(true);
    end;

    local procedure FindPostingDateWithNoVATEntries(): Date
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetCurrentKey("Posting Date");
        if VATEntry.FindLast() then
            exit(CalcDate('<1Y>', VATEntry."Posting Date"));
        exit(WorkDate());
    end;

    local procedure CreateVATReportingCode(): Code[20]
    var
        VATReportingCode: Record "VAT Reporting Code";
    begin
        VATReportingCode.Code := LibraryUtility.GenerateGUID();
        VATReportingCode.Insert();
        exit(VATReportingCode.Code)
    end;

    local procedure CreateVATReturn(var VATReportHeader: Record "VAT Report Header"; PeriodYear: Integer);
    begin
        VATReportHeader."VAT Report Config. Code" := VATReportHeader."VAT Report Config. Code"::"VAT Return";
        VATReportHeader.Insert(true);
        VATReportHeader.Validate("Period Year", PeriodYear);
        VATReportHeader.Modify();
    end;

    local procedure MockVATEntryWithVATCode(var VATEntry: Record "VAT Entry"; PostingDate: Date; VATReportingCode: Code[20])
    begin
        VATEntry."Entry No." := LibraryUtility.GetNewRecNo(VATEntry, VATEntry.FIELDNO("Entry No."));
        VATEntry."Posting Date" := PostingDate;
        VATEntry."VAT Reporting Date" := PostingDate;
        VATEntry.Closed := FALSE;
        VATEntry."VAT Number" := VATReportingCode;
        VATEntry.Amount := LibraryRandom.RandDec(1000, 2);
        VATEntry.Base := LibraryRandom.RandDec(1000, 2);
        VATEntry."Remaining Unrealized Amount" := LibraryRandom.RandDec(1000, 2);
        VATEntry."Remaining Unrealized Base" := LibraryRandom.RandDec(1000, 2);
        VATEntry."Additional-Currency Amount" := LibraryRandom.RandDec(1000, 2);
        VATEntry."Additional-Currency Base" := LibraryRandom.RandDec(1000, 2);
        VATEntry."Add.-Curr. Rem. Unreal. Amount" := LibraryRandom.RandDec(1000, 2);
        VATEntry."Add.-Curr. Rem. Unreal. Base" := LibraryRandom.RandDec(1000, 2);
        VATEntry.Insert();
    end;

    local procedure SuggestLinesWithPeriod(VATReportHeader: Record "VAT Report Header"; Selection: Enum "VAT Statement Report Selection"; PeriodSelection: Enum "VAT Statement Report Period Selection"; PeriodYear: Integer; PeriodNo: Integer; AmountInACY: Boolean);
    var
        VATReportMediator: Codeunit "VAT Report Mediator";
    begin
        Commit();
        LibraryVariableStorage.Enqueue(Selection);
        LibraryVariableStorage.Enqueue(PeriodSelection);
        LibraryVariableStorage.Enqueue(PeriodYear);
        LibraryVariableStorage.Enqueue(PeriodNo);
        LibraryVariableStorage.Enqueue(AmountInACY);
        VATReportMediator.GetLines(VATReportHeader);
    end;

    local procedure CreateOrUpdateSettledVATPeriod(var SettledVATPeriod: Record "Settled VAT Period"; PeriodDate: Date)
    begin
        CalcAndPostVATSettlement(PeriodDate, PeriodDate, PeriodDate, true);

        // Validate that settled VAT periods is updated
        SettledVATPeriod.SetRange(Year, Date2DMY(PeriodDate, 3));
        Assert.AreEqual(1, SettledVATPeriod.Count, 'Expected exactly one Settled VAT Period');
        SettledVATPeriod.FindFirst();
    end;

    local procedure PrepareSettledVATPeriodWithApplicationAlwaysAllowed(PostingDate: Date; AllowedOnGL: Boolean; AllowedOnUser: Boolean)
    var
        SettledVATPeriod: Record "Settled VAT Period";
    begin
        SettledVATPeriod.Init();
        SettledVATPeriod.Year := Date2DMY(PostingDate, 3);
        SettledVATPeriod."Period No." := (Date2DMY(PostingDate, 2) + 1) div 2;
        SettledVATPeriod."Settlement Date" := PostingDate;
        SettledVATPeriod.Closed := true;
        SettledVATPeriod.Insert();

        SetApplicationAlwaysAllowedInGLSetup(AllowedOnGL);
        SetUserSetupApplicationAlwaysAllowed(AllowedOnUser);
    end;

    local procedure VerifyApplication(InvoiceNo: Code[20]; PaymentNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
    begin
        FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, InvoiceNo);
        FindCustomerLedgerEntry(CustLedgerEntry2, CustLedgerEntry2."Document Type"::Payment, PaymentNo);
        CustLedgerEntry.TestField(Open, false);
        CustLedgerEntry2.TestField(Open, false);
        CustLedgerEntry2.TestField("Closed by Entry No.", CustLedgerEntry."Entry No.");
    end;

    local procedure VerifyGLEntriesExist(DocumentNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.Init();
        GLEntry.SetRange("Document No.", DocumentNo);
        Assert.RecordIsNotEmpty(GLEntry);
    end;

    local procedure VerifyVATStatementReportLineBaseAndAmount(VATReportHeader: Record "VAT Report Header"; BoxNo: Text[30]; ExpectedBase: Decimal; ExpectedAmount: Decimal)
    var
        VATStatementReportLine: Record "VAT Statement Report Line";
    begin
        VATStatementReportLine.SetRange("VAT Report No.", VATReportHeader."No.");
        VATStatementReportLine.SetRange("VAT Report Config. Code", VATReportHeader."VAT Report Config. Code");
        VATStatementReportLine.SetRange("Box No.", BoxNo);
        VATStatementReportLine.FindFirst();
        VATStatementReportLine.TestField(Base, ExpectedBase);
        VATStatementReportLine.TestField(Amount, ExpectedAmount);
    end;

    local procedure DeleteSettledVATPeriods()
    var
        SettledVATPeriod: Record "Settled VAT Period";
    begin
        SettledVATPeriod.DeleteAll();
    end;

    local procedure DeleteUserSetup()
    var
        UserSetup: Record "User Setup";
    begin
        if UserSetup.Get(UserId) then
            UserSetup.Delete();
    end;

    local procedure CreateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; JournalTemplateName: Code[10]; JournalBatchName: Code[10]; DocumentType: Enum "Gen. Journal Document Type"; DocNo: Code[20]; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal; GenPostingType: Enum "General Posting Type"; VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20])
    begin
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, JournalTemplateName, JournalBatchName, DocumentType, AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Document No.", DocNo);
        GenJournalLine.Validate("Gen. Posting Type", GenPostingType);
        GenJournalLine.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        GenJournalLine.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        GenJournalLine.Modify(true);
    end;

    local procedure CalcAndPostVATSettlementWithDocumentNo(StartingDate: Date; EndingDate: Date; PostingDate: Date; SettlementDocNo: Code[20]; Post: Boolean)
    var
        GLAccount: Record "G/L Account";
        CalcPostVATSettlement: Report "Calc. and Post VAT Settlement";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        CalcPostVATSettlement.InitializeRequest(
          StartingDate, EndingDate, PostingDate, SettlementDocNo, GLAccount."No.", false, Post);
        CalcPostVATSettlement.SetInitialized(false);
        Commit();
        CalcPostVATSettlement.Run();
    end;

    local procedure GetGLEntryAmount(DocumentNo: Code[20]; GLAccountNo: Code[20]): Decimal
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        if GLEntry.FindFirst() then
            exit(Abs(GLEntry.Amount));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CalcAndPostVATSettlementHandler(var CalcAndPostVATSettlement: TestRequestPage "Calc. and Post VAT Settlement")
    begin
        CalcAndPostVATSettlement.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Message: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    local procedure ExecuteTradeSettlementReport(DocumentNoFiltering: Text; SelectionOption: Enum "VAT Statement Report Selection")
    begin
        LibraryVariableStorage.Enqueue(DocumentNoFiltering);
        LibraryVariableStorage.Enqueue(SelectionOption);
        REPORT.Run(REPORT::"Trade Settlement");
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure TradeSettementReportHandler(var TradeSettlement: TestRequestPage "Trade Settlement")
    var
        VATPeriod: Record "VAT Period";
        DocumentNoFiltering: Text;
        ExpectedYear: Integer;
        SelectionOption: Enum "VAT Statement Report Selection";
    begin
        DocumentNoFiltering := LibraryVariableStorage.DequeueText();
        SelectionOption := "VAT Statement Report Selection".FromInteger(LibraryVariableStorage.DequeueInteger());
        // SettlementPeriod
        VATPeriod.Reset();
        VATPeriod.FindFirst();
        TradeSettlement.SettlementPeriod.SetValue(VATPeriod."Period No.");
        // SettlementYear
        ExpectedYear := Date2DMY(WorkDate(), 3);
        Assert.AreEqual(ExpectedYear, TradeSettlement.SettlementYear.AsInteger(), 'The settlement year should be from current workdate');
        TradeSettlement.SettlementYear.SetValue(ExpectedYear);
        // StartDate
        // TradeSettlement.Control1080117
        // EndDate
        // TradeSettlement.Control1080119
        // ShowVATEntries
        // TradeSettlement.Control1080121
        // Selection
        TradeSettlement.Selection.SetValue(SelectionOption); // TradeSettlement.Control1080123::"Open and Closed");

        TradeSettlement."VAT Entry".SetFilter("Document No.", DocumentNoFiltering);
        TradeSettlement.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure TradeSettlementReportHandler(var TradeSettlement: TestRequestPage "Trade Settlement")
    begin
        TradeSettlement.Cancel().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure TradeSettlement2017ReportHandler(var TradeSettlement2017: TestRequestPage "Trade Settlement 2017")
    begin
        TradeSettlement2017.Cancel().Invoke();
    end;


    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestLinesCustomVATStatementRPH(var VATReportRequestPage: TestRequestPage "VAT Report Request Page")
    begin
        VATReportRequestPage.VATStatementTemplate.SETVALUE(LibraryVariableStorage.DequeueText());
        VATReportRequestPage.VATStatementName.SETVALUE(LibraryVariableStorage.DequeueText());

        Selection := "VAT Statement Report Selection".FromInteger(LibraryVariableStorage.DequeueInteger());
        VATReportRequestPage.Selection.SETVALUE(Format(Selection));

        PeriodSelection := "VAT Statement Report Period Selection".FromInteger(LibraryVariableStorage.DequeueInteger());
        VATReportRequestPage.PeriodSelection.SETVALUE(Format(PeriodSelection));

        VATReportRequestPage."Period Year".SETVALUE(LibraryVariableStorage.DequeueInteger());
        VATReportRequestPage."Period No.".SetValue(LibraryVariableStorage.DequeueInteger());
        VATReportRequestPage."Amounts in ACY".SETVALUE(LibraryVariableStorage.DequeueBoolean());
        VATReportRequestPage.OK().Invoke();
    end;
}
