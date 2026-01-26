codeunit 141000 "Report Layout - Local"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Report]
        isInitialized := false;
    end;

    var
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        isInitialized: Boolean;

    [Test]
    [HandlerFunctions('RHFinancialAnalysisReport')]
    [Scope('OnPrem')]
    procedure TestFinancialAnalysisReport()
    begin
        // [FEATURE] [Financial Analysis Report]
        Initialize();
        REPORT.Run(REPORT::"Financial Analysis Report");
    end;

    [Test]
    [HandlerFunctions('RHStockCard')]
    [Scope('OnPrem')]
    procedure TestStockCard()
    begin
        // [FEATURE] [Stock Card]
        Initialize();
        REPORT.Run(REPORT::"Stock Card");
    end;

    [Test]
    [HandlerFunctions('RHAUNZStatement')]
    [Scope('OnPrem')]
    procedure TestAUNZStatement()
    begin
        // [FEATURE] [AU/NZ Statement]
        Initialize();
        REPORT.Run(REPORT::"AU/NZ Statement");
    end;

    [HandlerFunctions('RHAnnualInformationReturnWHT')]
    [Scope('OnPrem')]
    procedure TestAnnualInformationReturnWHT()
    begin
        // [FEATURE] [Annual Information Return  WHT]
        Initialize();
        REPORT.Run(REPORT::"Annual Information Return  WHT");
    end;

    [Test]
    [HandlerFunctions('RHBalanceSheet')]
    [Scope('OnPrem')]
    procedure TestBalanceSheet()
    begin
        // [FEATURE] [Balance Sheet]
        Initialize();
        REPORT.Run(REPORT::"Balance Sheet");
    end;

    [Test]
    [HandlerFunctions('RHIncomeStatement')]
    [Scope('OnPrem')]
    procedure TestIncomeStatement()
    begin
        // [FEATURE] [Income Statement]
        Initialize();
        REPORT.Run(REPORT::"Income Statement");
    end;

    [Test]
    [HandlerFunctions('RHGLJournal')]
    [Scope('OnPrem')]
    procedure TestGLJournal()
    begin
        // [FEATURE] [G/L Journal]
        Initialize();
        REPORT.Run(REPORT::"G/L Journal");
    end;

    [Test]
    [HandlerFunctions('RHJournals')]
    [Scope('OnPrem')]
    procedure TestJournals()
    begin
        // [FEATURE] [Journals]
        Initialize();
        REPORT.Run(REPORT::Journals);
    end;

    [Test]
    [HandlerFunctions('StockCardRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StockCardReportShowsZeroAmountForNonInvoicedReceiveAndShip()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Quantity: Integer;
        InboundDocNo: Code[20];
        OutboundDocNo: Code[20];
    begin
        // [FEATURE] [Stock Card]
        // [SCENARIO 374875] "Stock Card" report shows 0 amount and quantity for receipts and shipments that have not been invoiced

        // [GIVEN] Post purchase order as received only
        LibraryInventory.CreateItem(Item);
        Quantity := LibraryRandom.RandInt(100);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", Quantity);
        InboundDocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Post sales order as shipped only
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", Quantity);
        OutboundDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [WHEN] Run report "Stock Card"
        LibraryVariableStorage.Enqueue(Item."No.");
        REPORT.Run(REPORT::"Stock Card");

        // [THEN] Fields "ReceivedQty", "ReceivedCost" in purchase receipt and "IssuedQty", "IssuedCost" in sales shipment are 0
        LibraryReportDataset.LoadDataSetFile();
        VerifyReportElement(InboundDocNo, 'ReceivedQty', 0);
        VerifyReportElement(InboundDocNo, 'ReceivedCost', 0);
        VerifyReportElement(OutboundDocNo, 'IssuedQty', 0);
        VerifyReportElement(OutboundDocNo, 'IssuedCost', 0);
    end;

    local procedure Initialize()
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        if isInitialized then
            exit;

        // Setup logo to be printed by default
        SalesSetup.Get();
        SalesSetup.Validate("Logo Position on Documents", SalesSetup."Logo Position on Documents"::Center);
        SalesSetup.Modify(true);

        isInitialized := true;
        Commit();
    end;

    local procedure FormatFileName(ReportCaption: Text) ReportFileName: Text
    begin
        ReportFileName := DelChr(ReportCaption, '=', '/') + '.pdf'
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHFinancialAnalysisReport(var FinancialAnalysisReport: TestRequestPage "Financial Analysis Report")
    var
        ReportType: Option " ",,"Net Change/Budget","Net Change (This Year/Last Year)","Balance (This Year/Last Year)";
    begin
        FinancialAnalysisReport.ReportType.SetValue(ReportType::"Net Change/Budget");
        FinancialAnalysisReport."G/L Account".SetFilter("Date Filter", Format(WorkDate()));
        FinancialAnalysisReport.SaveAsPdf(FormatFileName(FinancialAnalysisReport.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHStockCard(var StockCard: TestRequestPage "Stock Card")
    begin
        StockCard."Item Ledger Entry".SetFilter("Posting Date", Format(WorkDate()));
        StockCard.SaveAsPdf(FormatFileName(StockCard.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StockCardRequestPageHandler(var StockCard: TestRequestPage "Stock Card")
    begin
        StockCard."Item Ledger Entry".SetFilter("Item No.", LibraryVariableStorage.DequeueText());
        StockCard."Item Ledger Entry".SetFilter("Posting Date", Format(WorkDate()));
        StockCard.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHAUNZStatement(var AUNZStatement: TestRequestPage "AU/NZ Statement")
    begin
        AUNZStatement.PrintAllWithEntries.SetValue(true);
        AUNZStatement.PrintCompanyAddress.SetValue(true);
        AUNZStatement.Customer.SetFilter("Date Filter", Format(WorkDate()));
        AUNZStatement.SaveAsPdf(FormatFileName(AUNZStatement.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHAnnualInformationReturnWHT(var AnnualInformationReturnWHT: TestRequestPage "Annual Information Return  WHT")
    begin
        AnnualInformationReturnWHT.ForYear.SetValue(Date2DMY(WorkDate(), 3));
        AnnualInformationReturnWHT.SaveAsPdf(FormatFileName(AnnualInformationReturnWHT.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHBalanceSheet(var BalanceSheet: TestRequestPage "Balance Sheet")
    begin
        BalanceSheet."G/L Account".SetFilter("Date Filter", Format(WorkDate()));
        BalanceSheet.SaveAsPdf(FormatFileName(BalanceSheet.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHIncomeStatement(var IncomeStatement: TestRequestPage "Income Statement")
    begin
        IncomeStatement."G/L Account".SetFilter("Date Filter", Format(WorkDate()));
        IncomeStatement.SaveAsPdf(FormatFileName(IncomeStatement.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHGLJournal(var GLJournal: TestRequestPage "G/L Journal")
    var
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
    begin
        GLJournal.Date.SetFilter("Period Start", Format(LibraryFiscalYear.GetAccountingPeriodDate(WorkDate())));
        GLJournal.SaveAsPdf(FormatFileName(GLJournal.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHJournals(var Journals: TestRequestPage Journals)
    var
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        PeriodType: Option Day,Week,Month,Quarter,year;
    begin
        Journals.Date.SetFilter("Period Type", Format(PeriodType::Month));
        Journals.Date.SetFilter("Period Start", Format(LibraryFiscalYear.GetAccountingPeriodDate(WorkDate())));
        Journals.SaveAsPdf(FormatFileName(Journals.Caption));
    end;

    local procedure VerifyReportElement(DocumentNo: Code[20]; ElementName: Text; ExpectedValue: Decimal)
    begin
        LibraryReportDataset.Reset();
        LibraryReportDataset.MoveToRow(LibraryReportDataset.FindRow('DocumentNo_ItemLedgerEntry', DocumentNo) + 1);
        LibraryReportDataset.AssertCurrentRowValueEquals(ElementName, ExpectedValue);
    end;
}

