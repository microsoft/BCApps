codeunit 134976 "ERM Sales Report"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Sales] [Report]
        isInitialized := false;
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySales: Codeunit "Library - Sales";
        LibraryERM: Codeunit "Library - ERM";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemReference: Codeunit "Library - Item Reference";
        LibraryAssembly: Codeunit "Library - Assembly";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryRandom: Codeunit "Library - Random";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryMarketing: Codeunit "Library - Marketing";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryJournals: Codeunit "Library - Journals";
        isInitialized: Boolean;
        ColumnTotalLbl: Label 'Total';
        SuccessfullyReversedMessageMsg: Label 'The entries were successfully reversed.';
        UnexpectedMessageMsg: Label 'Unexpected message.';
        TotalCaptionLbl: Label 'Total (LCY)';
        DocumentNoLbl: Label 'Cust_Ledger_Entry_Document_No_';
        DueDateLbl: Label 'Cust_Ledger_Entry_Posting_Date_';
        RemAmountLbl: Label 'Cust_Ledger_Entry_Remaining_Amount_';
        RowNotFoundMsg: Label 'Row does not exist.';
        OverdueEntriesLbl: Label 'Overdue Entries';
        PhoneNoLbl: Label 'Customer_Phone_No_';
        RowNotFoundErr: Label 'There is no dataset row corresponding to Element Name %1 with value %2.', Comment = '%1=Field Caption,%2=Field Value;';
        ExcelCountWorksheetsErr: Label 'Saved Excel file has incorrect number of worksheets.';
        InvoiceTxt: Label 'Invoice';
        TaxInvoiceTxt: Label 'Tax Invoice';
        EmptyReportDatasetTxt: Label 'There is nothing to print for the selected filters.';
        WrongDecimalErr: Label 'Wrong count of decimals', Locked = true;
        DescriptionVATClauseLineLbl: Label 'Description_VATClauseLine';

    [Test]
    [HandlerFunctions('CustomerTrialBalanceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerTrialBalanceReport()
    var
        CustomerNo: Code[20];
        DebitAmount: Decimal;
        CreditAmount: Decimal;
    begin
        // [FEATURE] [Customer - Trial Balance]
        // [SCENARIO] Debit and Credit amounts in Customer - Trial Balance report
        Initialize();

        // [GIVEN] Post Customer ledger entries with Debit Amount = "X", Credit Amount = "Y"
        CustomerNo := CreatePostDebitCreditJournalLines(DebitAmount, CreditAmount, CreateCustomer());

        // [WHEN] Run Customer - Trial Balance report
        RunCustomerTrialBalanceReportForCY(CustomerNo, '', '');

        // [THEN] Reported Debit Amount = "X", Credit Amount  = "Y"
        VerifyCustomerTrialBalanceDCAmounts(CustomerNo, DebitAmount, Abs(CreditAmount));
    end;

    [Test]
    [HandlerFunctions('CustomerTrialBalanceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerTrialBalanceReportWithDimensions()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustomerNo: Code[20];
        GlobalDim1Value: Code[20];
        GlobalDim2Value: Code[20];
        DebitAmount: Decimal;
        CreditAmount: Decimal;
        DebitAmountDim: Decimal;
        CreditAmountDim: Decimal;
    begin
        // [FEATURE] [Customer - Trial Balance]
        // [SCENARIO 122717] Run Customer - Trial Balance report with dimension filters
        Initialize();

        // [GIVEN] New Dimension Values for Global Dimension: "G1","G2"
        CreateGlobalDimValues(GlobalDim1Value, GlobalDim2Value);
        // [GIVEN] Post Customer ledger entries with Debit Amount = "D" and Credit Amount = "C" without dimensions
        CustomerNo := CreatePostDebitCreditJournalLines(DebitAmount, CreditAmount, CreateCustomer());
        // [GIVEN] Post Customer ledger entries with Debit Amount = "D1" and Credit Amount = "C1" and dimensions "G1","G2"
        DebitAmountDim := LibraryRandom.RandDec(1000, 2);
        CreditAmountDim := -LibraryRandom.RandDec(1000, 2);
        CreateDebitCreditJournalLinesWithDimensions(
          GenJournalLine, CustomerNo, DebitAmountDim, CreditAmountDim, GlobalDim1Value, GlobalDim2Value);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Run Customer - Trial Balance report with filters by dimensions "G1","G2"
        RunCustomerTrialBalanceReportForCY(CustomerNo, GlobalDim1Value, GlobalDim2Value);

        // [THEN] Debit and Credit Amounts = "D1", "C1" are filtered and shown in report.
        VerifyCustomerTrialBalanceDCAmounts(CustomerNo, DebitAmountDim, Abs(CreditAmountDim));
        // [THEN] Sums of Debit and Credit Amounts = "D" + "D1", "C" + "C1" are not shown in report
        LibraryReportDataset.AssertElementWithValueNotExist('PeriodDebitAmt', DebitAmount + DebitAmountDim);
        LibraryReportDataset.AssertElementWithValueNotExist('PeriodDebitAmt', Abs(CreditAmount + CreditAmountDim));
    end;

    [Test]
    [HandlerFunctions('CustomerOrderDetailRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OrderDetail()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LineAmount: Decimal;
    begin
        // Create a Sales Order with Currency for New Customer and Verify data showing in Customer Order Detail Report.

        // Setup.
        Initialize();
        CreateSalesOrder(SalesHeader, SalesLine, CreateCurrency(), CreateCustomer());
        LineAmount := Round(LibraryERM.ConvertCurrency(SalesLine."Line Amount", SalesHeader."Currency Code", '', WorkDate()));

        // Exercise: Generate the Customer Order Detail Report.
        RunCustomerOrderDetailReport(SalesLine."Sell-to Customer No.", true);

        // Verify: Check that the value of Amount in Customer Order Detail equal to the value of Amount in corresponding Sales Line.
        VerifyLineAmtCustomerOrderDetailReport(SalesLine."No.", LineAmount);
    end;

    [Test]
    [HandlerFunctions('CustomerOrderDetailRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OrderDetailInLCY()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Create a Sales Order for New Customer and Verify data showing in Customer Order Detail Report.

        // Setup.
        Initialize();
        CreateSalesOrder(SalesHeader, SalesLine, '', CreateCustomer());

        // Exercise: Generate the Customer Order Detail Report.
        RunCustomerOrderDetailReport(SalesLine."Sell-to Customer No.", false);

        // Run Customer Order Detail and Verify Order value showing in Report.
        VerifyLineAmtCustomerOrderDetailReport(SalesLine."No.", SalesLine."Line Amount");
    end;

    [Test]
    [HandlerFunctions('CustomerOrderSummaryRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OrderSummary()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Create a Sales Order for New Customer and Verify value of Balance in Order Summary is equal to the value of Amount
        // in corresponding Sales Line.

        // Setup.
        Initialize();
        CreateSalesOrder(SalesHeader, SalesLine, '', CreateCustomer());

        // Exercise: Generate the Customer Order Summary Report.
        RunCustOrderSummaryReport(SalesLine."Sell-to Customer No.", true);

        // Verify: Check that the value of Balance in Order Summary is equal to the value of Amount in corresponding Sales Line.
        VerifyCustOrderSummary(SalesLine, SalesHeader."Currency Factor");
    end;

    [Test]
    [HandlerFunctions('CustomerOrderSummaryRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OrderSummaryLCY()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Create a Sales Order using Currency for New Customer and Verify value of Balance in Order Summary is equal to the value of Amount
        // in corresponding Sales Line.

        // Setup.
        Initialize();
        CreateSalesOrder(SalesHeader, SalesLine, CreateCurrency(), CreateCustomer());

        // Exercise: Generate the Customer Order Summary Report.
        RunCustOrderSummaryReport(SalesLine."Sell-to Customer No.", false);

        // Verify: Check that the value of Balance in Order Summary is equal to the value of Amount in corresponding Sales Line.
        VerifyCustOrderSummary(SalesLine, SalesHeader."Currency Factor");
    end;

    [Test]
    [HandlerFunctions('CustomerSummaryAgingSimpRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SummaryAgingSimp()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        InvoiceAmount: Decimal;
        NoOfDays: Integer;
    begin
        // Setup: Create Customer, Make and Post Invoice Entry from General Journal Line.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        NoOfDays := 30 * LibraryRandom.RandInt(4);
        InvoiceAmount := LibraryRandom.RandDec(1000, 2);
        CreatePostGeneralJournalLine(GenJournalLine, GenJournalLine."Document Type"::Invoice, Customer."No.", '', InvoiceAmount, WorkDate());
        CreatePostGeneralJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, Customer."No.", '', InvoiceAmount,
          CalcDate('<' + Format(-NoOfDays) + 'D>', WorkDate()));

        // Exercise: Generate Customer Summary Aging Simp Report as Output file and save as XML.
        LibraryVariableStorage.Enqueue(WorkDate());
        LibraryVariableStorage.Enqueue(Customer."No.");
        REPORT.Run(REPORT::"Customer - Summary Aging Simp.");

        // Verify: Verify Customer Summary Aging Simp Values.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('Customer__No__', Customer."No.");
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFoundErr, 'No_Customer', Customer."No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('CustBalanceDueLCY_5__Control25', InvoiceAmount);
        LibraryReportDataset.AssertCurrentRowValueEquals('CustBalanceDueLCY_5__Control37', InvoiceAmount);
    end;

    [Test]
    [HandlerFunctions('CustomerTopTenListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TopTenListSalesLCY()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        ShowType: Option "Sales (LCY)","Balance (LCY)";
        SalesLCY: Decimal;
    begin
        // Setup: Create Customer, Make and Post Invoice Entry from General Journal Line.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        SalesLCY := GetCustomerSalesLCY() + LibraryRandom.RandDec(100, 2);
        CreatePostGeneralJournalLine(GenJournalLine, GenJournalLine."Document Type"::Invoice, Customer."No.", '', SalesLCY, WorkDate());

        // Exercise: Generate Customer Summary Aging Simp Report as Output file and save as XML.
        LibraryVariableStorage.Enqueue(ShowType::"Sales (LCY)");
        LibraryVariableStorage.Enqueue(Customer."No.");
        REPORT.Run(REPORT::"Customer - Top 10 List");

        // Verify: Verify Customer Top 10 List Report for Sales LCY.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_Customer', Customer."No.");
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFoundErr, 'No_Customer', Customer."No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('SalesLCY_Customer', SalesLCY);
    end;

    [Test]
    [HandlerFunctions('CustomerTopTenListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TopTenListBalanceLCY()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        ShowType: Option "Sales (LCY)","Balance (LCY)";
        BalanceLCY: Decimal;
    begin
        // Setup: Create Customer, Make and Post Invoice Entry from General Journal Line.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        BalanceLCY := GetCustomerBalanceLCY() + LibraryRandom.RandDec(100, 2);
        CreatePostGeneralJournalLine(GenJournalLine, GenJournalLine."Document Type"::Invoice, Customer."No.", '', BalanceLCY, WorkDate());

        // Exercise: Generate Customer Summary Aging Simp Report as Output file and save as XML.
        LibraryVariableStorage.Enqueue(ShowType::"Balance (LCY)");
        LibraryVariableStorage.Enqueue(Customer."No.");
        REPORT.Run(REPORT::"Customer - Top 10 List");

        // Verify: Verify Customer Top 10 List Report for Balance LCY.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_Customer', Customer."No.");
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFoundErr, 'No_Customer', Customer."No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('BalanceLCY_Customer', BalanceLCY);
    end;

    [Test]
    [HandlerFunctions('CustomerListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerList()
    var
        Customer: Record Customer;
    begin
        // [FEATURE] [Customer - List]
        // [SCENARIO] Value of Credit Limit LCY in Customer List matches the value of Credit Limit LCY in corresponding Customer.

        // [GIVEN] Customer with Credit Limit LCY field.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Credit Limit (LCY)", LibraryRandom.RandInt(10));
        Customer.Modify(true);

        // [WHEN] Generate the Customer-List report.
        RunCustomerListReport(Customer);

        // [THEN] Value of Credit Limit LCY in Customer List is equal to the value of Credit Limit LCY in corresponding Customer.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('Customer__No__', Customer."No.");
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFoundErr, 'No_Customer', Customer."No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('Customer__Credit_Limit__LCY__', Customer."Credit Limit (LCY)");
    end;

    [Test]
    [HandlerFunctions('CustomerListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerListFilterStringWithGlobalDimCaptions()
    var
        Customer: Record Customer;
        DimValueCode: array[2] of Code[20];
        ExpectedFilterString: Text;
    begin
        // [FEATURE] [Customer - List]
        // [SCENARIO 376798] "Customer - List" report prints global dimension captions in case of customer dimension filters
        Initialize();
        UpdateGlobalDims();

        // [GIVEN] General Ledger Setup with two global dimensions: "Department", "Project".
        // [GIVEN] Customer "C" with two default dimensions: Code = "Department", Value = "ADM"; Code = "Project", Value = "VW".
        CreateCustomerWithDefaultGlobalDimValues(Customer, DimValueCode);

        // [WHEN] Run "Customer - List" report with following filters: "No." = "C"; "Department Code" = "ADM", "Project Code" = "VW"
        Customer.SetFilter("Global Dimension 1 Code", DimValueCode[1]);
        Customer.SetFilter("Global Dimension 2 Code", DimValueCode[2]);
        RunCustomerListReport(Customer);

        // [THEN] Report prints customer "C" with following filter string: "No.: <"C">, Department Code: ADM, Project Code: VW"
        ExpectedFilterString :=
          StrSubstNo('%1: %2, %3: %4, %5: %6',
            Customer.FieldName("No."), Customer."No.",
            Customer.FieldCaption("Global Dimension 1 Code"), DimValueCode[1],
            Customer.FieldCaption("Global Dimension 2 Code"), DimValueCode[2]);

        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('Customer__No__', Customer."No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('CustFilter', ExpectedFilterString);
    end;

    [Test]
    [HandlerFunctions('CustomerRegisterRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerRegister()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // Check value of Original Amount in Customer Register matches the value of Amount in corresponding General Journal Line without
        // Currency.

        // Setup: Create a Customer and Post General Journal Line with Invoice.
        Initialize();
        CreatePostGeneralJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, CreateCustomer(), '', LibraryRandom.RandDec(100, 2), WorkDate());

        // Excercise: Generate the Customer Register report and Verify Data on it without LCY Amount.
        CustLedgerEntry.SetRange("Document No.", GenJournalLine."Document No.");
        CustLedgerEntry.FindLast();
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(CustLedgerEntry."Entry No.");
        RunAndVerifyCustomerRegister(GenJournalLine."Document No.", GenJournalLine.Amount);
    end;

    [Test]
    [HandlerFunctions('CustomerRegisterRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerRegisterWithLCY()
    var
        Currency: Record Currency;
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        OriginalAmountLCY: Decimal;
    begin
        // Check value of Original Amount in Customer Register matches the value of Amount in corresponding General Journal Line with
        // Currency.

        // Setup: Create a Customer and Post General Journal Line with Invoice.
        Initialize();
        LibraryERM.FindCurrency(Currency);
        CreatePostGeneralJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, CreateCustomer(), Currency.Code, LibraryRandom.RandDec(100, 2),
          WorkDate());
        OriginalAmountLCY :=
          Round(LibraryERM.ConvertCurrency(GenJournalLine.Amount, GenJournalLine."Currency Code", '', GenJournalLine."Posting Date"));

        // Excercise: Generate the Customer Register report and Verify Data on it with LCY Amount.
        CustLedgerEntry.SetRange("Document No.", GenJournalLine."Document No.");
        CustLedgerEntry.FindLast();
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(CustLedgerEntry."Entry No.");
        RunAndVerifyCustomerRegister(GenJournalLine."Document No.", OriginalAmountLCY);
    end;

    [Test]
    [HandlerFunctions('CustomerDetailTrialBalanceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerDetailTrialBalance()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check value of Amount in Customer Detail Trial Balance matches the value of Amount in corresponding General Journal Line
        // without Currency.

        // Setup: Create a Customer and Post General Journal Line with Invoice.
        Initialize();
        CreatePostGeneralJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, CreateCustomer(), '', LibraryRandom.RandDec(100, 2), WorkDate());

        // Exercise: Generate the Customer Detail Trial Balance Report.
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(GenJournalLine."Account No.");
        RunAndVerifyCustomerTrialBal(GenJournalLine, GenJournalLine.Amount);
    end;

    [Test]
    [HandlerFunctions('CustomerDetailTrialBalanceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerDetailTrialBalanceLCY()
    var
        Currency: Record Currency;
        GenJournalLine: Record "Gen. Journal Line";
        AmountLCY: Decimal;
    begin
        // Check value of Amount in Customer Detail Trial Balance matches the value of Amount in corresponding General Journal Line
        // With Currency.

        // Setup: Create a Customer and Post General Journal Line with Invoice.
        Initialize();
        LibraryERM.FindCurrency(Currency);
        CreatePostGeneralJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, CreateCustomer(), Currency.Code, LibraryRandom.RandDec(100, 2),
          WorkDate());
        AmountLCY :=
          Round(LibraryERM.ConvertCurrency(GenJournalLine.Amount, GenJournalLine."Currency Code", '', GenJournalLine."Posting Date"));

        // Exercise: Generate the Customer Detail Trial Balance Report.
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(GenJournalLine."Account No.");
        RunAndVerifyCustomerTrialBal(GenJournalLine, AmountLCY);
    end;

    [Test]
    [HandlerFunctions('CustomerSummaryAgingRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerSummaryAging()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check value of Balance in Customer Summary Aging matches the value of Amount in corresponding General Journal Line
        // without Currency.

        // Setup: Create a Customer and Post General Journal Line with Invoice.
        Initialize();
        CreatePostGeneralJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, CreateCustomer(), '', LibraryRandom.RandDec(100, 2), WorkDate());

        // Generate the Customer Summary Aging Report and Verify without LCY Amount.
        RunAndVerifyCustSummaryAging(GenJournalLine."Account No.", false, GenJournalLine.Amount);
    end;

    [Test]
    [HandlerFunctions('CustomerSummaryAgingRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerSummaryAgingWithLCY()
    var
        Currency: Record Currency;
        GenJournalLine: Record "Gen. Journal Line";
        AmountLCY: Decimal;
    begin
        // Check value of Balance in Customer Summary Aging matches the value of Amount in corresponding General Journal Line
        // with Currency.

        // Setup: Create a Customer and Post General Journal Line with Invoice.
        Initialize();
        LibraryERM.FindCurrency(Currency);
        CreatePostGeneralJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, CreateCustomer(), Currency.Code, LibraryRandom.RandDec(100, 2),
          WorkDate());
        AmountLCY :=
          Round(LibraryERM.ConvertCurrency(GenJournalLine.Amount, GenJournalLine."Currency Code", '', GenJournalLine."Posting Date"));

        // Generate the Customer Summary Aging Report and Verify with LCY Amount.
        RunAndVerifyCustSummaryAging(GenJournalLine."Account No.", true, AmountLCY);
    end;

    [Test]
    [HandlerFunctions('CustomerDetailedAgingRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerDetailedAging()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        PaymentTerms: Record "Payment Terms";
    begin
        // Check value of Remaining Amount in Customer Detailed Aging matches the value of Amount in corresponding General Journal Line.

        // Setup: Create a Customer and Post General Journal Line with Invoice.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        PaymentTerms.Get(Customer."Payment Terms Code");  // Added fix to make test world ready.
        CreatePostGeneralJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, CreateCustomer(), '', LibraryRandom.RandDec(100, 2), WorkDate());

        // Exercise: Generate the Customer Detailed Aging Report.
        RunCustomerDetailedAging(GenJournalLine);

        // Verify: Check that the value of Remaining Amount in Customer Detailed Aging is equal to the value of Amount in
        // corresponding General Journal Line.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('Cust_Ledger_Entry_Posting_Date_', Format(GenJournalLine."Posting Date"));
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFoundErr, 'Cust_Ledger_Entry_Posting_Date_', Format(GenJournalLine."Posting Date"));
        LibraryReportDataset.AssertCurrentRowValueEquals('Cust_Ledger_Entry_Remaining_Amount_', GenJournalLine.Amount);
    end;

    [Test]
    [HandlerFunctions('CustomerItemSalesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerItemSales()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
        PostedDocumentNo: Code[20];
        RequestPageXML: Text;
    begin
        // [SCENARIO] Check that correct Amount is available on Customer Item Sales Report after posting Sales Order.
        Initialize();

        // [GIVEN] Create Customer "C1" and post two Sales Headers
        PostedDocumentNo := CreateAndPostSalesOrder(SalesHeader, SalesLine);

        Commit();
        Customer.SetRange("No.", SalesHeader."Sell-to Customer No.");
        
        // [WHEN] Run report "Customer/Item Sales"
        RequestPageXML := Report.RunRequestPage(Report::"Customer/Item Sales", RequestPageXML);
        LibraryReportDataset.RunReportAndLoad(Report::"Customer/Item Sales", Customer, RequestPageXML);

        // [THEN] The Item and Amounts referenced on the Sales Line exist in the report data
        LibraryReportDataset.AssertElementWithValueExists('ValueEntryBuffer__Item_No__', SalesLine."No.");
        LibraryReportDataset.AssertElementWithValueExists('ValueEntryBuffer__Sales_Amount__Actual___Control44', SalesLine.Amount);

        // [THEN] The correct Amount is available on Posted Sales Invoice Line.
        SalesInvoiceLine.SetRange("Document No.", PostedDocumentNo);
        SalesInvoiceLine.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        SalesInvoiceLine.FindFirst();
        SalesInvoiceLine.TestField("Line Amount", SalesLine.Amount);

        Clear(LibraryReportDataset);
    end;

    [Test]
    [HandlerFunctions('CustomerItemSalesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerItemSalesTotals()
    var
        Customer: Record Customer;
        Customer2: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequestPageXML: Text;
    begin
        // [SCENARIO] Check that correct Sub Totals and Grand Totals are showing on the Customer Item Sales Report after posting several Sales Orders.
        Initialize();
        
        // [GIVEN] Create Customer "C1" and post two Sales Headers
        LibrarySales.CreateCustomer(Customer);
        CreateSalesDocumentWithLine(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, Customer."No.");
        SalesLine.Validate("Unit Cost", LibraryRandom.RandDecInRange(500, 1000, 2));
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        Clear(SalesHeader);
        Clear(SalesLine);
        CreateSalesDocumentWithLine(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, Customer."No.");
        SalesLine.Validate("Unit Cost", LibraryRandom.RandDecInRange(500, 1000, 2));
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        
        // [GIVEN] Create Customer "C2" and post one Sales Header
        LibrarySales.CreateCustomer(Customer2);
        Clear(SalesHeader);
        Clear(SalesLine);
        CreateSalesDocumentWithLine(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, Customer2."No.");
        SalesLine.Validate("Unit Cost", LibraryRandom.RandDecInRange(500, 1000, 2));
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        Commit();
        Customer.SetFilter("No.", '%1|%2', Customer."No.", Customer2."No.");
        
        // [WHEN] Run report "Customer/Item Sales"
        RequestPageXML := Report.RunRequestPage(Report::"Customer/Item Sales", RequestPageXML);
        LibraryReportDataset.RunReportAndLoad(Report::"Customer/Item Sales", Customer, RequestPageXML);

        // [THEN] Totals elements exist and their values match those in the associated "Value Entry" records for "C1" & "C2"
        VerifyReportItemTotals(Customer."No.", Customer2."No.");

        Clear(LibraryReportDataset);
    end;

    [Test]
    [HandlerFunctions('CustomerSalesListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerSalesListWithAmount()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesLine: Record "Sales Line";
        PostedDocumentNo: Code[20];
    begin
        // Check that correct Amount is Available on Customer Sales List Report after posting Sales Order.

        // Create and Post Sales Order, Save Customer Sales List Report in XML with Hide Address TRUE.
        Initialize();
        PostedDocumentNo := CreateAndPostSalesOrder(SalesHeader, SalesLine);

        // Exercise.
        LibraryVariableStorage.Enqueue(SalesHeader."Sell-to Customer No.");
        REPORT.Run(REPORT::"Customer - Sales List");

        // Verify: Verify that Amount Fetched from the Report is matching with Posted Sales Invoice Amount.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('Customer__No__', SalesHeader."Sell-to Customer No.");
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFoundErr, 'Customer__No__', SalesHeader."Sell-to Customer No.");

        SalesInvoiceHeader.Get(PostedDocumentNo);
        SalesInvoiceHeader.CalcFields(Amount);
        LibraryReportDataset.AssertCurrentRowValueEquals('AmtSalesLCY', SalesInvoiceHeader.Amount);
    end;

    [Test]
    [HandlerFunctions('CustomerSalesListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerSalesListWithAddress()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PostedDocumentNo: Code[20];
    begin
        // Check that correct Address is Available on Customer Sales List Report after posting Sales Order.

        // Create and Post Sales Order, Save Customer Sales List Report in XML with Hide Address FALSE.
        Initialize();
        PostedDocumentNo := CreateAndPostSalesOrder(SalesHeader, SalesLine);

        // Verify: Verify that Address fetched from Report is matching with Address on Posted Sales Invoice.
        LibraryVariableStorage.Enqueue(SalesHeader."Sell-to Customer No.");
        REPORT.Run(REPORT::"Customer - Sales List");
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('Customer_Name', SalesHeader."Sell-to Customer No.");
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFoundErr, 'Customer_Name', SalesHeader."Sell-to Customer No.");

        // Verify: Verify that Amount Fetched from the Report is matching with Posted Sales Invoice Amount.
        SalesInvoiceHeader.Get(PostedDocumentNo);
        LibraryReportDataset.AssertCurrentRowValueEquals('CustAddr_2_', SalesInvoiceHeader."Sell-to Address");
    end;

    [Test]
    [HandlerFunctions('StatementReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OverdueEntriesStatementReport()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
        PeriodLength: DateFormula;
    begin
        // Verify Overdue Entries in Statement Report when Print Overdue Entries option is True.

        // Setup: Create and post General Journal Line, apply partial Payment over the Invoice with Random Values.
        Initialize();
        Amount := LibraryRandom.RandDec(1000, 2);
        PostJournalLines(GenJournalLine, CreateCustomer(), Amount, -Amount / 2);
        Evaluate(PeriodLength, '<' + Format(LibraryRandom.RandInt(5)) + 'M>');

        // Exercise: Save Statement Report for the Customer Created.
        SaveStatementReport(GenJournalLine."Account No.", WorkDate(), true, false, false, false, PeriodLength);

        // Verify Remaining Amount in Statement Report in Overdue Entries.
        LibraryReportDataset.LoadDataSetFile();
        VerifyOverDueEntry(GenJournalLine."Posting Date", Round(Amount / 2, 0.01, '<'));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,StatementReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ReversedEntriesStatementReport()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
        PeriodLength: DateFormula;
    begin
        // Verify Reversed Entries in Statement Report When Print Reversed Entries option is True.

        // Setup: Create and post General Journal Line with Random Values and Reverse the Entry.
        Initialize();
        Amount := LibraryRandom.RandDec(1000, 2);
        CreatePostGeneralJournalLine(GenJournalLine, GenJournalLine."Document Type"::Invoice, CreateCustomer(), '', Amount, GetPostingDate());
        ReverseTransaction(FindGLEntry(GenJournalLine."Document No."));
        Evaluate(PeriodLength, '<' + Format(LibraryRandom.RandInt(5)) + 'M>');

        // Exercise: Save Statement Report for the Customer Created.
        SaveStatementReport(GenJournalLine."Account No.", GenJournalLine."Posting Date", false, true, false, false, PeriodLength);

        // Verify: Verify Amount in Statement Report after Entries has been Reversed.
        LibraryReportDataset.LoadDataSetFile();
        VerifyAmountInMultipleRows(GenJournalLine."Document No.", Amount);
    end;

    [Test]
    [HandlerFunctions('StatementReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure UnappliedEntryStatementReport()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
        PeriodLength: DateFormula;
    begin
        // Verify Unapplied Entries in Statement Report when Print Unapplied Entries option is True.

        // Setup: Create and post General Journal Line,apply and Unapply Invoice and Payment with Random Values.
        Initialize();
        Amount := LibraryRandom.RandDec(1000, 2);
        PostJournalLines(GenJournalLine, CreateCustomer(), Amount, -Amount);
        UnapplyCustLedgerEntry(GenJournalLine."Document Type"::Payment, GenJournalLine."Document No.");
        Evaluate(PeriodLength, '<' + Format(LibraryRandom.RandInt(5)) + 'M>');

        // Exercise: Save Statement Report for the Customer Created.
        SaveStatementReport(GenJournalLine."Account No.", WorkDate(), false, false, true, false, PeriodLength);

        // Verify: Verify Remaining Amount in Statement Report after Entries has been Unapplied.
        LibraryReportDataset.LoadDataSetFile();
        VerifyAmountInMultipleRows(GenJournalLine."Document No.", Amount);
    end;

    [Test]
    [HandlerFunctions('StatementReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PrintAgingBandStatementReport()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
        PeriodLength: DateFormula;
        PostingDate: Date;
    begin
        // Verify Statement Report when Include Aging Band option is True.

        // Setup: Create and post General Journal Line with Random Value.
        Initialize();
        Amount := LibraryRandom.RandDec(1000, 2);
        Evaluate(PeriodLength, '<' + Format(LibraryRandom.RandInt(5)) + 'M>');
        PostingDate := CalcDate(PeriodLength, WorkDate());
        CreatePostGeneralJournalLine(GenJournalLine, GenJournalLine."Document Type"::Invoice, CreateCustomer(), '', Amount, PostingDate);

        // Exercise: Save Statement Report for the Customer Created.
        SaveStatementReport(GenJournalLine."Account No.", WorkDate(), false, false, false, true, PeriodLength);

        // Verify Remaining Amount in Statement Report.
        LibraryReportDataset.LoadDataSetFile();
        VerifyRemainAmtInCustLedgEntry(PostingDate, Amount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,StatementReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerStatementReport()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
        PeriodLength: DateFormula;
        PostingDate: Date;
    begin
        // Verify Statement Report when Print Overdue Entries, Print Reversed Entries, Print Unapplied Entries and Include Aging Band
        // Option are all set to True.

        // Setup: Create and post General Journal Line, Reverse the Entry, Unapply Payment Over the Invoice with Random Values.
        Initialize();
        Amount := LibraryRandom.RandDec(100, 2);
        Evaluate(PeriodLength, '<' + Format(LibraryRandom.RandInt(5)) + 'M>');
        PostingDate := CalcDate(PeriodLength, WorkDate());
        CreatePostGeneralJournalLine(GenJournalLine, GenJournalLine."Document Type"::Invoice, CreateCustomer(), '', Amount, PostingDate);
        ReverseTransaction(FindGLEntry(GenJournalLine."Document No."));
        PostJournalLines(GenJournalLine, GenJournalLine."Account No.", Amount, -Amount);
        UnapplyCustLedgerEntry(GenJournalLine."Document Type"::Payment, GenJournalLine."Document No.");

        // Exercise: Save Statement Report for the Customer Created.
        SaveStatementReport(GenJournalLine."Account No.", WorkDate(), true, true, true, true, PeriodLength);

        // Verify: Verify Amount in Statement Report in Overdue Entries and Amount after Unapplied Entries.
        LibraryReportDataset.LoadDataSetFile();
        VerifyOverDueEntry(GenJournalLine."Posting Date", -Amount);
    end;

    [Test]
    [HandlerFunctions('CustomerSummaryAgingRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerSummaryAgingWithShowAmountInLCYTrue()
    begin
        // Check the Value of Total(LCY) in Customer Summary Aging Report when Show Amounts In LCY is TRUE.
        CustomerSummaryAgingReport(true);
    end;

    [Test]
    [HandlerFunctions('CustomerSummaryAgingRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerSummaryAgingWithShowAmountInLCYFalse()
    begin
        // Check the Value of Total(LCY) in Customer Summary Aging Report when Show Amounts In LCY is FALSE.
        CustomerSummaryAgingReport(false);
    end;

    local procedure CustomerSummaryAgingReport(ShowAmountsInLCY: Boolean)
    var
        Customer: Record Customer;
        Amount: Decimal;
    begin
        // Setup: Create a Customer and Post General Journal Lines without Currency and with Currency.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        Amount := LibraryRandom.RandDec(1000, 2);
        CreateAndPostInvoice(Customer."No.", '', Amount);
        CreateAndPostInvoice(Customer."No.", CreateCurrency(), Amount);

        // Exercise: Run the Customer Summary Aging Report.
        RunCustomerSummaryAgingReport(Customer."No.", ShowAmountsInLCY);

        // Verify: Check that the value of Total(LCY) in Customer Summary Aging Report is equal to Customer."Balance (LCY)".
        LibraryReportDataset.LoadDataSetFile();
        VerifyTotalLCYOnCustomerSummaryAgingReport(Customer);
    end;

    [Test]
    [HandlerFunctions('CustomerOrderSummaryRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerOrderSummaryWithoutCurrencyFilter()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
    begin
        // Check the Value of Total(LCY) in Customer Order Report when Show Amount LCY is FALSE and Currency Filter is blank.

        // Setup: Create Customer with currency and then create a sales order.
        Initialize();
        CreateCustomerWithCurrencyCode(Customer);
        CreateSalesOrder(SalesHeader, SalesLine, Customer."Currency Code", Customer."No.");

        // Exercise: Run Customer Order Summary Report with currency filter blank and Show Amount LCY is FALSE.
        LibraryVariableStorage.Enqueue(WorkDate());
        LibraryVariableStorage.Enqueue(false);
        RunCustomerOrderSummaryReport(Customer);

        // Verify: Verify that Totoal (LCY) shows the correct value in local currency and check that currency code does not exist in the report.
        LibraryReportDataset.LoadDataSetFile();
        VerifyTotalLCYOnCustomerOrderSummary(SalesLine."Line Amount" / SalesHeader."Currency Factor");
        asserterror LibraryReportDataset.AssertElementWithValueExists('', SalesHeader."Currency Code");
    end;

    [Test]
    [HandlerFunctions('CustomerOrderSummaryRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerOrderSummaryWithCurrencyFilter()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
    begin
        // Check the Value of Total(LCY) in Customer Order Report when Show Amount LCY is FALSE and Currency Filter is not blank.

        // Setup: Create Customer with currency and then create a sales order.
        Initialize();
        CreateCustomerWithCurrencyCode(Customer);
        CreateSalesOrder(SalesHeader, SalesLine, Customer."Currency Code", Customer."No.");

        // Exercise: Run Customer Order Summary Report with currency filter not blank and Show Amount LCY is FALSE.
        LibraryVariableStorage.Enqueue(WorkDate());
        LibraryVariableStorage.Enqueue(false);
        Customer.SetRange("Currency Filter", SalesHeader."Currency Code");
        RunCustomerOrderSummaryReport(Customer);

        // Verify: Verify that Totoal (LCY) shows the correct value in local currency and check that Currency Code is showing in the report.
        LibraryReportDataset.LoadDataSetFile();
        VerifyTotalLCYOnCustomerOrderSummary(SalesLine."Line Amount" / SalesHeader."Currency Factor");
        LibraryReportDataset.Reset();
        LibraryReportDataset.AssertElementWithValueExists('CurrencyCode_SalesLine', SalesHeader."Currency Code");
    end;

    [Test]
    [HandlerFunctions('CustomerDetailedAgingRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerDetailedAgingReportForSorting()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLinePayment: Record "Gen. Journal Line";
    begin
        // Verify that the entries are sorted according to Due Date in Customer Detailed Aging.

        // Setup: Create a Customer and Post General Journal Lines with Random and different Amounts.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CreatePostGeneralJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, Customer."No.", '', LibraryRandom.RandDec(100, 2), WorkDate());
        CreatePostGeneralJournalLine(
          GenJournalLinePayment, GenJournalLinePayment."Document Type"::Payment, GenJournalLine."Account No.", '',
          2 * -LibraryRandom.RandDec(100, 2), CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()));

        // Exercise: Run Customer Detailed Aging Report.
        RunCustomerDetailedAging(GenJournalLinePayment);

        // Verify: Check that the entries are sorted according to Due Date in Customer Detailed Aging.
        LibraryReportDataset.LoadDataSetFile();
        VerifyCustomerDetailedAging(GenJournalLine."Document No.", GenJournalLine."Due Date");
        VerifyCustomerDetailedAging(GenJournalLinePayment."Document No.", GenJournalLinePayment."Due Date");
    end;

    [Test]
    [HandlerFunctions('CustomerDetailedAgingRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerDetailedAgingReportForDuplicateRow()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLinePayment: Record "Gen. Journal Line";
    begin
        // Verify that the first line in detailed entries displays only once.

        // Setup: Create a Customer and Post General Journal Lines with Random and different Amounts. Run Customer Detailed Aging Report.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CreatePostGeneralJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, Customer."No.", '', LibraryRandom.RandDec(100, 2), WorkDate());
        CreatePostGeneralJournalLine(
          GenJournalLinePayment, GenJournalLinePayment."Document Type"::Payment, GenJournalLine."Account No.", '',
          2 * -LibraryRandom.RandDec(100, 2), CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()));
        RunCustomerDetailedAging(GenJournalLinePayment);
        LibraryReportDataset.SetRange(DocumentNoLbl, '');
        LibraryReportDataset.GetNextRow();

        // Exercise.
        asserterror LibraryReportDataset.AssertCurrentRowValueEquals(RemAmountLbl, GenJournalLine.Amount);

        // Verify: Check that the first line in detailed entries displays only once.
        Assert.ExpectedError(RowNotFoundMsg);
    end;

    [Test]
    [HandlerFunctions('CustomerDetailedAgingRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustInfoInCustomerDetailedAgingReport()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Verify that the Phone No. displayed correctly in Customer Detailed Aging Report.

        // Setup: Create a Customer and Post General Journal Line with Random Amount.
        Initialize();
        Customer.Get(CreateCustomer());
        CreatePostGeneralJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, Customer."No.", '', LibraryRandom.RandDec(100, 2), WorkDate());

        // Exercise: Run Customer Detailed Aging Report.
        RunCustomerDetailedAging(GenJournalLine);

        // Verify: Verify that the Phone No. displayed correctly in Customer Detailed Aging.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(PhoneNoLbl, Customer."Phone No.");
    end;

    [Test]
    [HandlerFunctions('CustOrderSummaryRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TotalValueInCustomerOrderSummaryReport()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        Customer: Record Customer;
        RequestPageXML: Text;
    begin
        // Verify the value of Total in Customer Order Summary Report is equal to the total value of Amount in corresponding Sales Lines.

        // Setup: Create Customer, create Sales Order with one Sales Line
        Initialize();
        CreateSalesOrder(SalesHeader, SalesLine, '', CreateCustomer());

        // Create one more Sales Line
        LibrarySales.CreateSalesLine(SalesLine2, SalesHeader, SalesLine.Type::Item, SalesLine."No.", LibraryRandom.RandDec(100, 2));

        // Exercise: Generate the Customer Order Summary Report.
        LibraryVariableStorage.Enqueue(WorkDate());
        LibraryVariableStorage.Enqueue(false);
        Customer.SetRange("No.", SalesLine."Sell-to Customer No.");
        Commit();  // Due to limitation in page testability, commit is needed in this test case.
        RequestPageXML := Report.RunRequestPage(Report::"Customer - Order Summary", RequestPageXML);
        LibraryReportDataset.RunReportAndLoad(Report::"Customer - Order Summary", Customer, RequestPageXML);

        // Verify: Check that the value of Total in Customer Order Summary is equal to the total value of Amount in corresponding Sales Lines.
        LibraryReportDataset.AssertElementWithValueExists('SalesLineBuffer_SalesOrderAmount', SalesLine."Line Amount" + SalesLine2."Line Amount");
        Clear(LibraryReportDataset);
    end;

    [Test]
    [HandlerFunctions('CustOrderSummaryRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TotalValueForLCYInCustomerOrderSummaryReport()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        Customer: Record Customer;
        RequestPageXML: Text;
    begin
        // Verify the value of Total LCY in Customer Order Summary Report is equal to the total LCY value of Amount in corresponding Sales Lines.

        // Setup: Create Customer with currency code, create Sales Order with one Sales Line
        Initialize();
        CreateCustomerWithCurrencyCode(Customer);
        CreateSalesOrder(SalesHeader, SalesLine, CreateCurrency(), Customer."No.");
        // Create one more Sales Line
        LibrarySales.CreateSalesLine(SalesLine2, SalesHeader, SalesLine.Type::Item, SalesLine."No.", LibraryRandom.RandDec(100, 2));
        // Exercise: Generate the Customer Order Summary Report.
        LibraryVariableStorage.Enqueue(WorkDate());
        LibraryVariableStorage.Enqueue(true);
        Customer.SetRange("No.", SalesLine."Sell-to Customer No.");
        Commit();  // Due to limitation in page testability, commit is needed in this test case.
        RequestPageXML := Report.RunRequestPage(Report::"Customer - Order Summary", RequestPageXML);
        LibraryReportDataset.RunReportAndLoad(Report::"Customer - Order Summary", Customer, RequestPageXML);

        // Verify: Check that the value of Total LCY in Customer Order Summary is equal to the total LCY value of Amount in corresponding Sales Lines.
        LibraryReportDataset.AssertElementWithValueExists('SalesLineBuffer_SalesOrderAmount', ConvertCurrency(SalesLine."Line Amount", SalesHeader."Currency Code") +
          ConvertCurrency(SalesLine2."Line Amount", SalesHeader."Currency Code"));
        Clear(LibraryReportDataset);
    end;

    [Test]
    [HandlerFunctions('CustomerOrderDetailRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerOrderDetailReportWithTotal()
    var
        CustomerNo: Code[20];
        ExpectedTotal: Decimal;
    begin
        // Verify Total displayed correctly in Customer Order Detail Report.

        // Setup: Create a Customer, create one Sales Order with two Lines.
        Initialize();
        CreateSalesOrderWithTwoLines(CustomerNo, ExpectedTotal);

        // Exercise: Generate the Customer Order Detail report.
        RunCustomerOrderDetailReport(CustomerNo, true);

        // Verify: verify Total displayed correctly in Customer Order Detail report.
        VerifyTotalOnCustomerOrderDetailReport(CustomerNo, ExpectedTotal);
    end;

    [Test]
    [HandlerFunctions('CustOrderSummaryRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerOrderSummaryReportWithShowAmountTrue()
    var
        Customer: Record Customer;
        RequestPageXML: Text;
        CustomerNo: Code[20];
        ExpectedAmount: Decimal;
    begin
        // Verify Amount of a duration displayed correctly in Customer Order Summary Report.

        // Setup: Create a Customer, create one Sales Order with two Lines.
        Initialize();
        CreateSalesOrderWithTwoLines(CustomerNo, ExpectedAmount);

        // Exercise: Generate the Customer Order Summary Report.
        LibraryVariableStorage.Enqueue(WorkDate());
        LibraryVariableStorage.Enqueue(true);
        Customer.SetRange("No.", CustomerNo);
        Commit();  // Due to limitation in page testability, commit is needed in this test case.
        RequestPageXML := Report.RunRequestPage(Report::"Customer - Order Summary", RequestPageXML);
        LibraryReportDataset.RunReportAndLoad(Report::"Customer - Order Summary", Customer, RequestPageXML);


        // Verify: Check that the value of Balance in Order Summary is equal to the value of Amount in corresponding duration.
        LibraryReportDataset.AssertElementWithValueExists('SalesLineBuffer_SalesAmtOnOrder2', ExpectedAmount);
        Clear(LibraryReportDataset);
    end;

    [Test]
    [HandlerFunctions('CustomerOrderDetailRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerOrderDetailReportWithReleasedDocument()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustomerNo: Code[20];
        ExpectedTotal: Decimal;
    begin
        // Verify Outstanding Orders and Total for released order displayed correctly in Customer Order Detail Report.

        // Setup: Create a Customer, create one Sales Order with two Lines.
        Initialize();
        CreateSalesOrderWithTwoLines(CustomerNo, ExpectedTotal);

        // Release the Sales Order.
        ReleaseSalesOrder(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);

        // Exercise: Generate the Customer - Order Detail report.
        RunCustomerOrderDetailReport(CustomerNo, true);

        // Verify: Verify Outstanding Orders and Total displayed correctly in Customer Order Detail report.
        FindSalesLine(SalesLine, SalesHeader."Document Type", SalesHeader."No.");
        VerifyOutstandingOrdersAndTotalOnCustomerOrderDetailReport(SalesLine, CustomerNo, ExpectedTotal);
    end;

    [Test]
    [HandlerFunctions('CustOrderSummaryRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomeOrderSummaryReportWithReleasedDocument()
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        CustomerNo: Code[20];
        ExpectedAmount: Decimal;
        RequestPageXML: Text;
    begin
        // Verify Amount of a duration displayed correctly in Customer Order Summary Report.

        // Setup: Create a Customer, create one Sales Order with two Lines.
        Initialize();
        CreateSalesOrderWithTwoLines(CustomerNo, ExpectedAmount);

        // Release the Sales Order.
        ReleaseSalesOrder(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);

        // Exercise: Generate the Customer Order Summary report.
        LibraryVariableStorage.Enqueue(WorkDate());
        LibraryVariableStorage.Enqueue(true);
        Customer.SetRange("No.", CustomerNo);
        Commit();  // Due to limitation in page testability, commit is needed in this test case.
        RequestPageXML := Report.RunRequestPage(Report::"Customer - Order Summary", RequestPageXML);
        LibraryReportDataset.RunReportAndLoad(Report::"Customer - Order Summary", Customer, RequestPageXML);
        // Verify: Check that the value of Balance in Order Summary is equal to the value of Amount in corresponding duration.
        LibraryReportDataset.AssertElementWithValueExists('SalesLineBuffer_SalesAmtOnOrder2', ExpectedAmount);
        Clear(LibraryReportDataset);
    end;

    [Test]
    [HandlerFunctions('CustomerOrderSummaryRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerOrderSummaryLCY()
    var
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [FCY] [Report]
        // [SCENARIO 381014] Print "Customer - Order Summary" when sales order has a currency code different from the customer's currency code and different from the LCY.

        // [GIVEN] Customer with LCY
        // [GIVEN] Sales Order with Amount = "X", "Amount (LCY)" = "Y" invoiced in foreign currency
        LibrarySales.CreateFCYSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order,
          LibrarySales.CreateCustomerNo(), LibraryInventory.CreateItemNo(), 1, '', 0D,
          LibraryERM.CreateCurrencyWithRandomExchRates());
        Commit();

        // [WHEN] Run "Customer - Order Summary" report with "Print in LCY" option
        RunCustOrderSummaryReport(SalesHeader."Sell-to Customer No.", true);

        // [THEN] Printed Sales Amount is equal to "Y"
        VerifyCustomerOrderSummarySalesAmount(SalesHeader, SalesLine);
    end;

    [Test]
    [HandlerFunctions('StandardSalesOrderConfRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StandardSalesOrderConfExternalDocumentNoIsPrinted()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [UI] [Order] [Confirmation]
        // [SCENARIO 225794] "External Document No." is shown with its caption when report "Standard Sales - Order Conf." is printed for Sales Order
        Initialize();

        // [GIVEN] Sales Order with "External Document No." = "XXX"
        MockSalesOrderWithExternalDocumentNo(SalesHeader);

        // [WHEN] Export report "Standard Sales - Order Conf." to XML file
        RunStandardSalesOrderConfirmationReport(SalesHeader."No.");
        LibraryReportDataset.LoadDataSetFile();

        // [THEN] Value "XXX" is displayed under Tag <ExtDocNo_SalesHeader> in export XML file
        LibraryReportDataset.AssertElementTagWithValueExists('ExtDocNo_SalesHeader', SalesHeader."External Document No.");

        // [THEN] Value "External Document No." is displayed under Tag <ExtDocNo_SalesHeader_Lbl> in export XML file
        LibraryReportDataset.AssertElementTagWithValueExists(
          'ExtDocNo_SalesHeader_Lbl', SalesHeader.FieldCaption("External Document No."));
    end;

    [Test]
    [HandlerFunctions('StandardSalesInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StandardSalesInvoiceExternalDocumentNoIsPrinted()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO 233670] Value of "External Document No." is shown with its caption when report "Standard Sales - Invoce" is printed for posted Sales Invoice with "External Document No."
        Initialize();

        // [GIVEN] Posted Sales Invoice with "External Document No." = "ExtDocNo001"
        MockSalesInvoiceHeaderWithExternalDocumentNo(SalesInvoiceHeader);

        // [WHEN] Export report "Standard Sales - Invoice" to XML file
        RunStandardSalesInvoiceReport(SalesInvoiceHeader."No.");
        LibraryReportDataset.LoadDataSetFile();

        // [THEN] Value "ExtDocNo001" is displayed under tag <LeftHeaderValue> in export XML file
        LibraryReportDataset.AssertElementTagWithValueExists('LeftHeaderValue', SalesInvoiceHeader."External Document No.");

        // [THEN] Value "External Document No." is displayed under tag <LeftHeaderName> in export XML file
        LibraryReportDataset.AssertElementTagWithValueExists('LeftHeaderName', SalesInvoiceHeader.FieldCaption("External Document No."));
    end;

    [Test]
    [HandlerFunctions('StandardSalesInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StandardSalesInvoiceExternalDocumentNoIsNotPrinted()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO 233670] Value of "External Document No." is not shown with its caption when report "Standard Sales - Invoce" is printed for posted Sales Invoice without "External Document No."
        Initialize();

        // [GIVEN] Posted Sales Invoice without "External Document No."
        SalesInvoiceHeader."No." := LibraryUtility.GenerateGUID();
        SalesInvoiceHeader.Insert();

        // [WHEN] Export report "Standard Sales - Invoice" to XML file
        RunStandardSalesInvoiceReport(SalesInvoiceHeader."No.");
        LibraryReportDataset.LoadDataSetFile();

        // [THEN] Value "External Document No." is not displayed under tag <LeftHeaderName> in export XML file
        LibraryReportDataset.AssertElementTagWithValueNotExist(
          'LeftHeaderName', SalesInvoiceHeader.FieldCaption("External Document No."));
    end;

    [Test]
    [HandlerFunctions('BlanketSalesOrderADChangeRequestPageHandler')]
    [Scope('OnPrem')]
    procedure BlanketSalesOrderArchiveDocFlagStateIsSavedAfterRun()
    var
        ArchiveDocValue: Text;
    begin
        // [FEATURE] [Blanket Sales Order]
        // [SCENARIO 256827] "Archive Document" flag state is saved when Stan runs the "Blanket Sales Order" report for the second time, i.e. "Saved setting" feature works for this flag.
        Initialize();

        // [GIVEN] Report "Blanket Sales Order" was run for the first time, "Archive Document" flag state was changed before the report was run.
        Commit();
        LibraryVariableStorage.Enqueue(false);
        REPORT.Run(REPORT::"Blanket Sales Order");
        ArchiveDocValue := LibraryVariableStorage.DequeueText();

        // [WHEN] Report "Blanket Sales Order" is run for the second time.
        LibraryVariableStorage.Enqueue(true);
        REPORT.Run(REPORT::"Blanket Sales Order");

        // [THEN] "Archive Document" flag state is saved after the first run.
        Assert.AreEqual(
          ArchiveDocValue, LibraryVariableStorage.DequeueText(), 'Unexpected value for ArchiveDocument field');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StdSalesQuoteADChangeRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StdSalesQuoteArchiveDocFlagStateIsSavedAfterRun()
    var
        ArchiveDocValue: Text;
    begin
        // [FEATURE] [Sales Quote]
        // [SCENARIO 256827] "Archive Document" flag state is saved when Stan runs the "Standard Sales - Quote" report for the second time, i.e. "Saved setting" feature works for this flag.
        Initialize();

        // [GIVEN] Report "Standard Sales - Quote" was run for the first time, "Archive Document" flag state was changed before the report was run.
        Commit();
        LibraryVariableStorage.Enqueue(false);
        REPORT.Run(REPORT::"Standard Sales - Quote");
        ArchiveDocValue := LibraryVariableStorage.DequeueText();

        // [WHEN] Report "Standard Sales - Quote" is run for the second time.
        LibraryVariableStorage.Enqueue(true);
        REPORT.Run(REPORT::"Standard Sales - Quote");

        // [THEN] "Archive Document" flag state is saved after the first run.
        Assert.AreEqual(
          ArchiveDocValue, LibraryVariableStorage.DequeueText(), 'Unexpected value for ArchiveDocument field');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StdSalesOrderConfADChangeRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StdSalesOrderConfArchiveDocFlagStateIsSavedAfterRun()
    var
        ArchiveDocValue: Text;
    begin
        // [FEATURE] [Order Confirmation]
        // [SCENARIO 256827] "Archive Document" flag state is saved when Stan runs the "Standard Sales - Order Conf." report for the second time, i.e. "Saved setting" feature works for this flag.
        Initialize();

        // [GIVEN] Report "Standard Sales - Order Conf." was run for the first time, "Archive Document" flag state was changed before the report was run.
        Commit();
        LibraryVariableStorage.Enqueue(false);
        REPORT.Run(REPORT::"Standard Sales - Order Conf.");
        ArchiveDocValue := LibraryVariableStorage.DequeueText();

        // [WHEN] Report "Standard Sales - Order Conf." is run for the second time.
        LibraryVariableStorage.Enqueue(true);
        REPORT.Run(REPORT::"Standard Sales - Order Conf.");

        // [THEN] "Archive Document" flag state is saved after the first run.
        Assert.AreEqual(
          ArchiveDocValue, LibraryVariableStorage.DequeueText(), 'Unexpected value for ArchiveDocument field');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('DraftSalesInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DraftSalesInvoiceWithExternalDocNo()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO 257521] External Document Number exists in report "Standard Sales - Draft Invoice" dataset.
        Initialize();

        // [GIVEN] Sales Invoice with "External Doc No.".
        CreateSalesInvoiceWithExternalDocNo(SalesHeader);
        Commit();

        // [WHEN] Run report "Standard Sales - Draft Invoice".
        SalesHeader.SetRecFilter();
        REPORT.Run(REPORT::"Standard Sales - Draft Invoice", true, false, SalesHeader);

        // [THEN] Report dataset contains "External Doc No.".
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('DocumentNo', SalesHeader."No.");
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), '');
        LibraryReportDataset.AssertCurrentRowValueEquals('ExternalDocumentNo', SalesHeader."External Document No.");
    end;

    [Test]
    [HandlerFunctions('DraftSalesInvoiceExcelRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PrintExternalDocNoOnDraftSalesInvoiceReport()
    var
        SalesHeader: Record "Sales Header";
        ExtDocNoRowNo: Integer;
        ExtDocColNo: Integer;
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO 257521] External Document Number is printed in report "Standard Sales - Draft Invoice".
        Initialize();
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());
        SetRDLCReportLayout(REPORT::"Standard Sales - Draft Invoice");

        // [GIVEN] Sales Invoice with "External Doc No.".
        CreateSalesInvoiceWithExternalDocNo(SalesHeader);
        Commit();

        // [WHEN] Print report "Standard Sales - Draft Invoice" as Excel.
        SalesHeader.SetRecFilter();
        REPORT.Run(REPORT::"Standard Sales - Draft Invoice", true, false, SalesHeader);

        // [THEN] Saved Excel file contains "External Doc No.".
        LibraryReportValidation.OpenExcelFile();
        LibraryReportValidation.FindRowNoColumnNoByValueOnWorksheet('External Document No.', 1, ExtDocNoRowNo, ExtDocColNo);
        LibraryReportValidation.VerifyCellValue(ExtDocNoRowNo, ExtDocColNo + 4, SalesHeader."External Document No.");
    end;

    [Test]
    [HandlerFunctions('StdSalesInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ShipmentsExistsWhenSaveAsXMLStandardSalesInvoiceReport()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // [SCENARIO 257602] "Quantity_ShipmentLine" xml node exists when "Standard Sales - Invoice" report saves as XML

        Initialize();

        // [GIVEN] Post shipment from Order
        PostShipReceiveOrder(SalesHeader, SalesLine, SalesHeader."Document Type"::Order);

        // [GIVEN] Post Invoice from Order
        SalesInvoiceHeader.SetRange("No.", LibrarySales.PostSalesDocument(SalesHeader, false, true));
        SalesInvoiceHeader.FindFirst();
        Commit();

        // [WHEN] Run "Save as Xml" for "Standard Sales - Invoice" with option "Show Shipments"
        SalesInvoiceHeader.SetRecFilter();
        REPORT.Run(REPORT::"Standard Sales - Invoice", true, false, SalesInvoiceHeader);

        // [THEN] "Quantity_ShipmentLine" xml node exists in exported file
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('DocumentNo', SalesInvoiceHeader."No.");
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFoundErr, 'DocumentNo', SalesInvoiceHeader."No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('Quantity_ShipmentLine', SalesLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('StdSalesCrMemoRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ReceiptsExistsWhenSaveAsXMLStandardSalesCrMemoReport()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        // [SCENARIO 257602] "Quantity_ShipmentLine" xml node exists when "Standard Sales - Credit Memo" Report saves as XML

        Initialize();

        // [GIVEN] Post receive from Return Order
        PostShipReceiveOrder(SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order");

        // [GIVEN] Post Cr. Memo from Return Order
        SalesCrMemoHeader.SetRange("No.", LibrarySales.PostSalesDocument(SalesHeader, false, true));
        SalesCrMemoHeader.FindFirst();
        Commit();

        // [WHEN] Run "Save as Xml" for "Standard Sales - Credit Memo" with option "Show Shipments"
        SalesCrMemoHeader.SetRecFilter();
        REPORT.Run(REPORT::"Standard Sales - Credit Memo", true, false, SalesCrMemoHeader);

        // [THEN] "Quantity_ShipmentLine" xml node exists in exported file
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('DocumentNo', SalesCrMemoHeader."No.");
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFoundErr, 'DocumentNo', SalesCrMemoHeader."No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('Quantity_ShipmentLine', SalesLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('CustomerDetailTrialBalanceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerDetailTrialBalanceExtDocNo()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Customer - Detail Trial Bal.]
        // [SCENARIO 262729] External Document No. is included in report Customer - Detail Trial Bal.

        // [GIVEN] Create and Post General Journal Line with External Document No.
        Initialize();
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, CreateCustomer(), '', LibraryRandom.RandDec(100, 2), WorkDate());
        GenJournalLine.Validate("External Document No.", CopyStr(LibraryUtility.GenerateRandomXMLText(35), 1, 35));
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Generate the Customer Detail Trial Balance Report.
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(GenJournalLine."Account No.");
        REPORT.Run(REPORT::"Customer - Detail Trial Bal.");

        // [THEN] Verify External Document No. on the Customer Detail Trial Balance Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('DocNo_CustLedgEntry', GenJournalLine."Document No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('ExtDocNo_CustLedgEntry', GenJournalLine."External Document No.");
    end;

    [Test]
    [HandlerFunctions('StdSalesQuoteExcelRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StdSalesQuoteDoesNotHaveEmptyPage()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Standard] [Quote]
        // [SCENARIO 266011] "Standard Sales - Quote" report do not have extra blank pages.
        Initialize();
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());
        SetRDLCReportLayout(REPORT::"Standard Sales - Quote");

        // [GIVEN] Create Sales Quote with one line.
        CreateSalesQuoteWithLine(SalesHeader, SalesLine, CreateCustomer());

        // [WHEN] Run report "Standard Sales - Quote".
        Commit();
        SalesHeader.SetRecFilter();
        REPORT.Run(REPORT::"Standard Sales - Quote", true, false, SalesHeader);

        // [THEN] Saved Excel file has only one sheet.
        VerifyNoOfWorksheetsInExcel(1);
    end;

    [Test]
    [HandlerFunctions('StdSalesDraftInvoiceExcelRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StdSalesDraftInvoiceDoesNotHaveEmptyPage()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Standard] [Draft] [Invoice]
        // [SCENARIO 266011] "Standard Sales - Draft Invoice" report do not have extra blank pages.
        Initialize();
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());
        SetRDLCReportLayout(REPORT::"Standard Sales - Draft Invoice");

        // [GIVEN] Create Sales Invoice with one line.
        CreateSalesInvoiceWithLine(SalesHeader, SalesLine, CreateCustomer());

        // [WHEN] Run report "Standard Sales - Draft Invoice".
        Commit();
        SalesHeader.SetRecFilter();
        REPORT.Run(REPORT::"Standard Sales - Draft Invoice", true, false, SalesHeader);

        // [THEN] Saved Excel file has only one sheet.
        VerifyNoOfWorksheetsInExcel(1);
    end;

    [Test]
    [HandlerFunctions('StdSalesInvoiceExcelRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StdSalesInvoiceDoesNotHaveEmptyPage()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // [FEATURE] [Standard] [Invoice]
        // [SCENARIO 266011] "Standard Sales - Invoice" report do not have extra blank pages.
        Initialize();
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());
        SetRDLCReportLayout(REPORT::"Standard Sales - Invoice");

        // [GIVEN] Create Sales Invoice with one line.
        CreateSalesInvoiceWithLine(SalesHeader, SalesLine, CreateCustomer());
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Run report "Standard Sales - Invoice".
        Commit();
        SalesInvoiceHeader.SetRecFilter();
        REPORT.Run(REPORT::"Standard Sales - Invoice", true, false, SalesInvoiceHeader);

        // [THEN] Saved Excel file has only one sheet.
        LibraryReportValidation.OpenExcelFile();
        Assert.AreEqual(1, LibraryReportValidation.CountWorksheets(), ExcelCountWorksheetsErr);
        // [THEN] Report title is 'Invoice'
        LibraryReportValidation.VerifyCellValue(7, 24, InvoiceTxt);
    end;

    [Test]
    [HandlerFunctions('StdSalesCreditMemoExcelRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StdSalesCreditMemoDoesNotHaveEmptyPage()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        // [FEATURE] [Standard] [Credit Memo]
        // [SCENARIO 266011] "Standard Sales - Credit Memo" report do not have extra blank pages.
        Initialize();
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());
        SetRDLCReportLayout(REPORT::"Standard Sales - Credit Memo");

        // [GIVEN] Create Sales Quote with one line.
        CreateSalesCreditMemoWithLine(SalesHeader, SalesLine, CreateCustomer());
        SalesCrMemoHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Run report "Standard Sales - Quote".
        Commit();
        SalesCrMemoHeader.SetRecFilter();
        REPORT.Run(REPORT::"Standard Sales - Credit Memo", true, false, SalesCrMemoHeader);

        // [THEN] Saved Excel file has only one sheet.
        VerifyNoOfWorksheetsInExcel(1);
    end;

    [Test]
    [HandlerFunctions('StdSalesInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StdSalesInvoiceDocumentCustomCaption()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReportCaptionSubscriber: Codeunit "Report Caption Subscriber";
    begin
        // [FEATURE] [Invoice] [Report Caption]
        Initialize();
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());
        SetRDLCReportLayout(REPORT::"Standard Sales - Invoice");

        // [GIVEN] Create Sales Invoice with one line.
        CreateSalesInvoiceWithLine(SalesHeader, SalesLine, CreateCustomer());
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        // [GIVEN] Redefined report title as 'Sales - Tax Invoice'
        ReportCaptionSubscriber.SetCaption(TaxInvoiceTxt);
        BindSubscription(ReportCaptionSubscriber);

        // [WHEN] Run report "Standard Sales - Invoice".
        Commit();
        SalesInvoiceHeader.SetRecFilter();
        REPORT.Run(REPORT::"Standard Sales - Invoice", true, false, SalesInvoiceHeader);

        // [THEN] Report title is 'Invoice'
        LibraryReportDataset.LoadDataSetFile();
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), 'Cannot find first row.');
        LibraryReportDataset.AssertCurrentRowValueEquals('DocumentTitle_Lbl', TaxInvoiceTxt);
    end;

    [Test]
    [HandlerFunctions('DraftSalesInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StdSalesDraftInvoicePmtMethodTranslation()
    var
        PaymentMethod: Record "Payment Method";
        PaymentMethodTranslation: Record "Payment Method Translation";
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales] [Invoice] [Payment Method Translation]
        // [SCENARIO 278606] Payment Method is Translated in report "Standard Sales - Draft Invoice"
        Initialize();

        // [GIVEN] Payment Method "CASH" with Description
        LibraryERM.CreatePaymentMethod(PaymentMethod);

        // [GIVEN] Payment Method Translation with Language Code "DEU" and Description
        PaymentMethodTranslation.Get(PaymentMethod.Code, LibraryERM.CreatePaymentMethodTranslation(PaymentMethod.Code));

        // [GIVEN] Sales Invoice with Payment Method "CASH" for Customer with Language Code = "DEU"
        CreateSalesDocumentWithPaymentMethod(
          SalesHeader, SalesHeader."Document Type"::Invoice, PaymentMethod.Code,
          CreateCustomerWithLanguageCode(PaymentMethodTranslation."Language Code"));
        SalesHeader.SetRecFilter();
        Commit();

        // [WHEN] Run report "Standard Sales - Draft Invoice"
        REPORT.Run(REPORT::"Standard Sales - Draft Invoice", true, false, SalesHeader);

        // [THEN] Report Dataset has Payment Method Translation Description under tag '<PaymentMethodDescription>'
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementTagWithValueExists('PaymentMethodDescription', PaymentMethodTranslation.Description);
    end;

    [Test]
    [HandlerFunctions('StandardSalesQuoteRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StdSalesQuotePmtMethodTranslation()
    var
        PaymentMethod: Record "Payment Method";
        PaymentMethodTranslation: Record "Payment Method Translation";
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales] [Quote] [Payment Method Translation]
        // [SCENARIO 278606] Payment Method is Translated in report "Standard Sales - Quote"
        Initialize();

        // [GIVEN] Payment Method "CASH" with Description
        LibraryERM.CreatePaymentMethod(PaymentMethod);

        // [GIVEN] Payment Method Translation with Language Code "DEU" and Description
        PaymentMethodTranslation.Get(PaymentMethod.Code, LibraryERM.CreatePaymentMethodTranslation(PaymentMethod.Code));

        // [GIVEN] Sales Quote with Payment Method "CASH" for Customer with Language Code = "DEU"
        CreateSalesDocumentWithPaymentMethod(
          SalesHeader, SalesHeader."Document Type"::Quote, PaymentMethod.Code,
          CreateCustomerWithLanguageCode(PaymentMethodTranslation."Language Code"));
        SalesHeader.SetRecFilter();
        Commit();

        // [WHEN] Run report "Standard Sales - Quote"
        REPORT.Run(REPORT::"Standard Sales - Quote", true, false, SalesHeader);

        // [THEN] Report Dataset has Payment Method Translation Description under tag '<PaymentMethodDescription>'
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementTagWithValueExists('PaymentMethodDescription', PaymentMethodTranslation.Description);
    end;

    [Test]
    [HandlerFunctions('StandardSalesOrderConfRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StdSalesOrderConfPmtMethodTranslation()
    var
        PaymentMethod: Record "Payment Method";
        PaymentMethodTranslation: Record "Payment Method Translation";
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales] [Order] [Payment Method Translation]
        // [SCENARIO 278606] Payment Method is Translated in report "Standard Sales - Order Conf."
        Initialize();

        // [GIVEN] Payment Method "CASH" with Description
        LibraryERM.CreatePaymentMethod(PaymentMethod);

        // [GIVEN] Payment Method Translation with Language Code "DEU" and Description
        PaymentMethodTranslation.Get(PaymentMethod.Code, LibraryERM.CreatePaymentMethodTranslation(PaymentMethod.Code));

        // [GIVEN] Sales Order with Payment Method "CASH" for Customer with Language Code = "DEU"
        CreateSalesDocumentWithPaymentMethod(
          SalesHeader, SalesHeader."Document Type"::Order, PaymentMethod.Code,
          CreateCustomerWithLanguageCode(PaymentMethodTranslation."Language Code"));
        SalesHeader.SetRecFilter();
        Commit();

        // [WHEN] Run report "Standard Sales - Order Conf."
        REPORT.Run(REPORT::"Standard Sales - Order Conf.", true, false, SalesHeader);

        // [THEN] Report Dataset has Payment Method Translation Description under tag '<PaymentMethodDescription>'
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementTagWithValueExists('PaymentMethodDescription', PaymentMethodTranslation.Description);
    end;

    [Test]
    [HandlerFunctions('StandardSalesInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StdSalesInvoicePmtMethodTranslation()
    var
        PaymentMethod: Record "Payment Method";
        PaymentMethodTranslation: Record "Payment Method Translation";
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // [FEATURE] [Sales] [Invoice] [Payment Method Translation]
        // [SCENARIO 278606] Payment Method is Translated in report "Standard Sales - Invoice"
        Initialize();

        // [GIVEN] Payment Method "CASH" with Description
        LibraryERM.CreatePaymentMethod(PaymentMethod);

        // [GIVEN] Payment Method Translation with Language Code "DEU" and Description
        PaymentMethodTranslation.Get(PaymentMethod.Code, LibraryERM.CreatePaymentMethodTranslation(PaymentMethod.Code));

        // [GIVEN] Posted Sales Invoice with Payment Method "CASH" for Customer with Language Code = "DEU"
        CreateSalesDocumentWithPaymentMethod(
          SalesHeader, SalesHeader."Document Type"::Invoice, PaymentMethod.Code,
          CreateCustomerWithLanguageCode(PaymentMethodTranslation."Language Code"));
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesInvoiceHeader.SetRecFilter();

        // [WHEN] Run report "Standard Sales - Invoice"
        REPORT.Run(REPORT::"Standard Sales - Invoice", true, false, SalesInvoiceHeader);

        // [THEN] Report DataSet has Payment Method Translation Description under tag '<PaymentMethodDescription>'
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementTagWithValueExists('PaymentMethodDescription', PaymentMethodTranslation.Description);
    end;

    [Test]
    [HandlerFunctions('StdSalesCrMemoRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StdSalesCrMemoPmtMethodTranslation()
    var
        PaymentMethod: Record "Payment Method";
        PaymentMethodTranslation: Record "Payment Method Translation";
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        // [FEATURE] [Sales] [Credit Memo] [Payment Method Translation]
        // [SCENARIO 278606] Payment Method is Translated in report "Standard Sales - Credit Memo"
        Initialize();

        // [GIVEN] Payment Method "CASH" with Description
        LibraryERM.CreatePaymentMethod(PaymentMethod);

        // [GIVEN] Payment Method Translation with Language Code "DEU" and Description
        PaymentMethodTranslation.Get(PaymentMethod.Code, LibraryERM.CreatePaymentMethodTranslation(PaymentMethod.Code));

        // [GIVEN] Posted Sales Cr. Memo with Payment Method "CASH" for Customer with Language Code = "DEU"
        CreateSalesDocumentWithPaymentMethod(
          SalesHeader, SalesHeader."Document Type"::"Credit Memo", PaymentMethod.Code,
          CreateCustomerWithLanguageCode(PaymentMethodTranslation."Language Code"));
        SalesCrMemoHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesCrMemoHeader.SetRecFilter();

        // [WHEN] Run report "Standard Sales - Credit Memo"
        REPORT.Run(REPORT::"Standard Sales - Credit Memo", true, false, SalesCrMemoHeader);

        // [THEN] Report DataSet has Payment Method Translation Description under tag '<PaymentMethodDescription>'
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementTagWithValueExists('PaymentMethodDescription', PaymentMethodTranslation.Description);
    end;

    [Test]
    [HandlerFunctions('StandardSalesInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StandardSalesInvoiceShowsVATClausesFromLines()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        VATClause: array[2] of Record "VAT Clause";
        VATPostingSetup: array[3] of Record "VAT Posting Setup";
    begin
        // [FEATURE] [Sales] [Invoice] [VAT Clause]
        // [SCENARIO 279173] Report 1306 "Standard Sales - Invoice" shows VAT Clause information for each VAT Clause used: VAT Clause Description, VAT Clause Description 2
        Initialize();

        // [GIVEN] Three VATPostingSetup records with VAT % = 20, 10 and 0.
        // [GIVEN] Two VAT Clauses records assigned for VATPostingSetup[1] and VATPostingSetup[2]
        CreateThreeVATPostingSetupsWithTwoVATClauses(VATPostingSetup, VATClause);

        // [GIVEN] Sales Invoice with 3 lines where Line1 has VATPostingSetup[1], Line2 has VATPostingSetup[2], Line3 has VATPostingSetup[3]
        CreateSalesInvoiceWithThreeLinesWithVATBusPostingSetup(SalesHeader, VATPostingSetup);

        // [GIVEN] Posted Sales Invoice
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesInvoiceHeader.SetRecFilter();

        // [WHEN] Run report "Standard Sales - Invoice" for Posted Sales Invoice
        REPORT.Run(REPORT::"Standard Sales - Invoice", true, false, SalesInvoiceHeader);

        // [THEN] Report DataSet contains VAT Clause fields: "VAT Identifier","VAT Clause Description", "VAT Clause Description 2" for each VAT Clause used
        VerifySalesInvoiceMultipleVATClausesPrinted(VATPostingSetup, VATClause);
    end;

    [Test]
    [HandlerFunctions('CustomerDetailTrialBalanceExcelRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerDetailTrialBalanceCorrOfRemainingAmount()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CurrencyCode: Code[10];
        CustNo: Code[20];
        i: Integer;
    begin
        // [FEATURE] [Customer - Detail Trial Bal.]
        // [SCENARIO 280971] "Correction of remaining amount" does not affect totals in Customer - Detail Trial Bal. report

        Initialize();

        // [GIVEN] Currency with exchange rate 1 to 0.33333
        CurrencyCode := CreateCurrencyWithFixedExchRates(0.33333);

        // [GIVEN] Post two invoices with currency and amount = 1 (LCY Amount = 0.33)
        CustNo := LibrarySales.CreateCustomerNo();
        for i := 1 to 2 do
            CreatePostGeneralJournalLine(GenJournalLine, GenJournalLine."Document Type"::Invoice, CustNo, CurrencyCode, 1, WorkDate());

        // [GIVEN] Post payment with currency and amount = 2 (LCY Amount = 0.67)
        CreatePostGeneralJournalLine(GenJournalLine, GenJournalLine."Document Type"::Payment, CustNo, CurrencyCode, -2, WorkDate());

        // [GIVEN] Applied payment to both invoices
        ApplyPaymentToAllOpenInvoices(GenJournalLine."Document No.", CustNo);

        // [GIVEN] Post invoice with currency and amount = 400 (LCY Amount = 133.33)
        CreatePostGeneralJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, CustNo, CurrencyCode, LibraryRandom.RandDec(100, 2), WorkDate());

        // [WHEN] Generate the Customer Detail Trial Balance Report.
        RunDtldCustTrialBalanceReportWithDateFilter(GenJournalLine."Account No.");

        // [THEN] Verify start balance is zero and customer balance is 133.33
        LibraryReportValidation.OpenExcelFile();
        LibraryReportValidation.VerifyCellValue(27, 5, Format(GenJournalLine."Amount (LCY)", 0, 9));
        LibraryReportValidation.VerifyCellValue(27, 9, Format(GenJournalLine."Amount (LCY)", 0, 9));
    end;

    [Test]
    [HandlerFunctions('DraftSalesInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StandardSalesDraftInvoiceShowsVATClausesFromLines()
    var
        SalesHeader: Record "Sales Header";
        VATClause: array[2] of Record "VAT Clause";
        VATPostingSetup: array[3] of Record "VAT Posting Setup";
    begin
        // [FEATURE] [Sales] [Invoice] [VAT Clause]
        // [SCENARIO 280820] Report 1303 "Standard Sales - Draft Invoice" shows VAT Clause information for each VAT Clause used: VAT Clause Description, VAT Clause Description 2
        Initialize();

        // [GIVEN] Three VATPostingSetup records with VAT % = 20, 10 and 0.
        // [GIVEN] Two VAT Clauses records assigned for VATPostingSetup[1] and VATPostingSetup[2]
        CreateThreeVATPostingSetupsWithTwoVATClauses(VATPostingSetup, VATClause);

        // [GIVEN] Sales Invoice with 3 lines where Line1 has VATPostingSetup[1], Line2 has VATPostingSetup[2], Line3 has VATPostingSetup[3]
        CreateSalesInvoiceWithThreeLinesWithVATBusPostingSetup(SalesHeader, VATPostingSetup);
        SalesHeader.SetRecFilter();
        Commit();

        // [WHEN] Run report "Standard Sales - Draft Invoice" for Sales Invoice
        REPORT.Run(REPORT::"Standard Sales - Draft Invoice", true, false, SalesHeader);

        // [THEN] Report DataSet contains VAT Clause fields: "VAT Identifier","VAT Clause Description", "VAT Clause Description 2" for each VAT Clause used
        VerifySalesInvoiceMultipleVATClausesPrinted(VATPostingSetup, VATClause);
    end;

    [Test]
    [HandlerFunctions('CustOrderSummaryRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerOrderSummaryMultipleCurrencies()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
        CustomerNo: Code[20];
        CurrencyCode: array[2] of Code[10];
        Amount: array[2] of Decimal;
        I: Integer;
        RequestPageXML: Text;
    begin
        // [FEATURE] [Customer Order Summary]
        // [SCENARIO 286863] Customer Order Summary splits lines for orders in different currencies
        Initialize();

        // [GIVEN] Created Customer
        CustomerNo := CreateCustomer();

        // [GIVEN] Currency "CUR01" with Exchange Rate created
        // [GIVEN] Sales Order "SO01" for Customer with Amount = 100 in Currency "CUR01"
        // [GIVEN] Currency "CUR02" with Exchange Rate created
        // [GIVEN] Sales Order "SO02" for Customer with Amount = 200 in Currency "CUR02"
        for I := 1 to ArrayLen(CurrencyCode) do begin
            CurrencyCode[I] := CreateCurrency();
            CreateSalesOrder(SalesHeader, SalesLine, CurrencyCode[I], CustomerNo);
            Amount[I] := SalesLine."Line Amount";
        end;

        // [WHEN] Run Report "Customer Order Summary"
        LibraryReportValidation.SetFileName(CustomerNo);
        LibraryVariableStorage.Enqueue(WorkDate());
        LibraryVariableStorage.Enqueue(false);
        Customer.SetRange("No.", CustomerNo);
        Commit();  // Due to limitation in page testability, commit is needed in this test case.
        RequestPageXML := Report.RunRequestPage(Report::"Customer - Order Summary", RequestPageXML);
        LibraryReportDataset.RunReportAndLoad(Report::"Customer - Order Summary", Customer, RequestPageXML);

        // [THEN] Amount = 100 for Currency "CUR01"
        // [THEN] Amount = 200 for Currency "CUR02"
        for I := 1 to ArrayLen(CurrencyCode) do
            LibraryReportDataset.AssertElementWithValueExists('SalesLineBuffer_SalesAmtOnOrder2', LibraryReportValidation.FormatDecimalValue(Amount[I]));
        Clear(LibraryReportDataset);
    end;

    [Test]
    [HandlerFunctions('CustOrderSummaryRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerOrderSummaryMultipleCurrenciesTotals()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
        RequestPageXML: Text;
        CustomerNo: Code[20];
        CustomerNo2: Code[20];
        CurrencyCode: array[4] of Code[10];
        Amount: array[4] of Decimal;
        PeriodStartDate: array[5] of Date;
        I: Integer;
        SalesOrderAmountLCY1: Decimal;
        SalesOrderAmountLCY2: Decimal;
        SalesOrderAmountLCY3: Decimal;
        SalesOrderAmountLCY4: Decimal;
        SalesOrderAmountLCY5: Decimal;
    begin
        // [SCENARIO] Report "Customer Order Summary" should correctly represent Totals values
        Initialize();

        // [GIVEN] Created Customer "C1"
        CustomerNo := CreateCustomer();

        // [GIVEN] Currency "CUR01" with Exchange Rate created
        // [GIVEN] Sales Order "SO01" for Customer with Amount = 100 in Currency "CUR01"
        // [GIVEN] Currency "CUR02" with Exchange Rate created
        // [GIVEN] Sales Order "SO02" for Customer with Amount = 200 in Currency "CUR02"
        for I := 1 to 2 do begin
            CurrencyCode[I] := CreateCurrency();
            CreateSalesOrder(SalesHeader, SalesLine, CurrencyCode[I], CustomerNo);
            Amount[I] := SalesLine."Line Amount";
        end;

        // [GIVEN] Created Customer "C2"
        CustomerNo2 := CreateCustomer();

        // [GIVEN] Currency "CUR03" with Exchange Rate created
        // [GIVEN] Sales Order "SO03" for Customer with Amount = 100 in Currency "CUR03"
        // [GIVEN] Currency "CUR04" with Exchange Rate created
        // [GIVEN] Sales Order "SO04" for Customer with Amount = 200 in Currency "CUR04"
        for I := 3 to ArrayLen(CurrencyCode) do begin
            CurrencyCode[I] := CreateCurrency();
            CreateSalesOrder(SalesHeader, SalesLine, CurrencyCode[I], CustomerNo2);
            Amount[I] := SalesLine."Line Amount";
        end;

        Commit();

        // [GIVEN] Generate the periods[1-5] for calculating the customer order amounts 
        if PeriodStartDate[1] = 0D then
            PeriodStartDate[1] := WorkDate();
        for i := 1 to 3 do
            PeriodStartDate[i + 1] := CalcDate('<1M>', PeriodStartDate[i]);
        PeriodStartDate[5] := DMY2Date(31, 12, 9999);

        // [GIVEN] Calculate the Total Sales Order Amount (LCY) from the Sales Lines for Period "P1"
        SalesLine.SetFilter("Bill-to Customer No.", '%1|%2', CustomerNo, CustomerNo2);
        SalesLine.SetFilter("Shipment Date", '<%1', PeriodStartDate[1]);
        if SalesLine.FindSet() then
            repeat
                CalculateCustomerOrderAmountLCY(SalesLine, SalesOrderAmountLCY1);
            until SalesLine.Next() = 0;

        // [GIVEN] Calculate the Total Sales Order Amount (LCY) from the Sales Lines for Period "P2"
        SalesLine.SetFilter("Sell-to Customer No.", '%1|%2', CustomerNo, CustomerNo2);
        SalesLine.SetFilter("Shipment Date", '%1..%2', PeriodStartDate[1], PeriodStartDate[2] - 1);
        if SalesLine.FindSet() then
            repeat
                CalculateCustomerOrderAmountLCY(SalesLine, SalesOrderAmountLCY2);
            until SalesLine.Next() = 0;

        // [GIVEN] Calculate the Total Sales Order Amount (LCY) from the Sales Lines for Period "P3"
        SalesLine.SetFilter("Bill-to Customer No.", '%1|%2', CustomerNo, CustomerNo2);
        SalesLine.SetFilter("Shipment Date", '%1..%2', PeriodStartDate[2], PeriodStartDate[3] - 1);
        if SalesLine.FindSet() then
            repeat
                CalculateCustomerOrderAmountLCY(SalesLine, SalesOrderAmountLCY3);
            until SalesLine.Next() = 0;

        // [GIVEN] Calculate the Total Sales Order Amount (LCY) from the Sales Lines for Period "P4"
        SalesLine.SetFilter("Bill-to Customer No.", '%1|%2', CustomerNo, CustomerNo2);
        SalesLine.SetFilter("Shipment Date", '%1..%2', PeriodStartDate[3], PeriodStartDate[4] - 1);
        if SalesLine.FindSet() then
            repeat
                CalculateCustomerOrderAmountLCY(SalesLine, SalesOrderAmountLCY4);
            until SalesLine.Next() = 0;

        // [GIVEN] Calculate the Total Sales Order Amount (LCY) from the Sales Lines for Period "P5"
        SalesLine.SetFilter("Bill-to Customer No.", '%1|%2', CustomerNo, CustomerNo2);
        SalesLine.SetFilter("Shipment Date", '%1..', PeriodStartDate[3]);
        if SalesLine.FindSet() then
            repeat
                CalculateCustomerOrderAmountLCY(SalesLine, SalesOrderAmountLCY5);
            until SalesLine.Next() = 0;

        // [WHEN] Run Report "Customer Order Summary"
        LibraryVariableStorage.Enqueue(WorkDate());
        LibraryVariableStorage.Enqueue(false);
        Customer.SetFilter("No.", '%1|%2', CustomerNo, CustomerNo2);
        RequestPageXML := Report.RunRequestPage(Report::"Customer - Order Summary", RequestPageXML);
        LibraryReportDataset.RunReportAndLoad(Report::"Customer - Order Summary", Customer, RequestPageXML);

        // [THEN] Totals elements exist and their values match those in the associated "Sales Line" records for "C1" & "C2"
        LibraryReportDataset.AssertElementWithValueExists('Totals_Sales_Amt_On_Order1', SalesOrderAmountLCY1);
        LibraryReportDataset.AssertElementWithValueExists('Totals_Sales_Amt_On_Order2', SalesOrderAmountLCY2);
        LibraryReportDataset.AssertElementWithValueExists('Totals_Sales_Amt_On_Order3', SalesOrderAmountLCY3);
        LibraryReportDataset.AssertElementWithValueExists('Totals_Sales_Amt_On_Order4', SalesOrderAmountLCY4);
        LibraryReportDataset.AssertElementWithValueExists('Totals_Sales_Amt_On_Order5', SalesOrderAmountLCY5);
        Clear(LibraryReportDataset);
    end;

    local procedure CalculateCustomerOrderAmountLCY(SalesLine: Record "Sales Line"; var SalesOrderAmountLCY: Decimal)
    var
        SalesHeader: Record "Sales Header";
        Currency: Record Currency;
        CurrExchRate: Record "Currency Exchange Rate";
        SalesOrderAmount: Decimal;
    begin
        Currency.InitRoundingPrecision();
        if SalesLine."VAT Calculation Type" in [SalesLine."VAT Calculation Type"::"Normal VAT", SalesLine."VAT Calculation Type"::"Reverse Charge VAT"] then
            SalesOrderAmount :=
              Round(
                (SalesLine.Amount + SalesLine."VAT Base Amount" * SalesLine."VAT %" / 100) * SalesLine."Outstanding Quantity" / SalesLine.Quantity / (1 + SalesLine."VAT %" / 100),
                Currency."Amount Rounding Precision")
        else
            SalesOrderAmount :=
              Round(
                SalesLine."Outstanding Amount" / (1 + SalesLine."VAT %" / 100),
                Currency."Amount Rounding Precision");

        if SalesLine."Currency Code" <> '' then begin
            SalesHeader.Get(SalesHeader."Document Type"::Order, SalesLine."Document No.");
            if SalesHeader."Currency Factor" <> 0 then
                SalesOrderAmountLCY +=
                  Round(
                    CurrExchRate.ExchangeAmtFCYToLCY(
                      WorkDate(), SalesHeader."Currency Code",
                      SalesOrderAmount, SalesHeader."Currency Factor"));
        end;
    end;

    [Test]
    [HandlerFunctions('StandardSalesInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StandardSalesInvoiceHasPhoneAndFaxInDataset()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Customer: Record Customer;
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 299029] Report 1306 "Standard Sales - Invoice" has Phone and Fax of Sell-to Customer in dataset
        Initialize();

        // [GIVEN] A Customer with a phone number and a fax number
        CreateCustomerWithPhoneAndFaxNo(Customer);

        // [GIVEN] A Sales Invoice for this Customer
        LibrarySales.CreateSalesInvoiceForCustomerNo(SalesHeader, Customer."No.");

        // [GIVEN] Posted Sales Invoice
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesInvoiceHeader.SetRecFilter();

        // [WHEN] Run report "Standard Sales - Invoice" for Posted Sales Invoice
        REPORT.Run(REPORT::"Standard Sales - Invoice", true, false, SalesInvoiceHeader);

        // [THEN] Report DataSet contains Customer."Phone No."
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementTagWithValueExists('SellToPhoneNo', Customer."Phone No.");

        // [THEN] Report DataSet contains Customer."Fax No."
        LibraryReportDataset.AssertElementTagWithValueExists('SellToFaxNo', Customer."Fax No.");
    end;

    [Test]
    [HandlerFunctions('StandardSalesOrderConfRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StandardSalesOrderHasPhoneAndFaxInDataset()
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 299029] Report 1305 "Standard Sales - Order Conf." has Phone and Fax of Sell-to Customer in dataset
        Initialize();

        // [GIVEN] A Customer with a phone number and a fax number
        CreateCustomerWithPhoneAndFaxNo(Customer);

        // [GIVEN] A Sales Order for this Customer
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        SalesHeader.SetRecFilter();

        Commit();

        // [WHEN] Run report "Standard Sales - Order Conf." for Sales Order
        REPORT.Run(REPORT::"Standard Sales - Order Conf.", true, false, SalesHeader);

        // [THEN] Report DataSet contains Customer."Phone No."
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementTagWithValueExists('SellToPhoneNo', Customer."Phone No.");

        // [THEN] Report DataSet contains Customer."Fax No."
        LibraryReportDataset.AssertElementTagWithValueExists('SellToFaxNo', Customer."Fax No.");
    end;

    [Test]
    [HandlerFunctions('StandardSalesOrderConfRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StandardSalesOrderConfYourReference()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [UI] [Order] [Confirmation]
        // [SCENARIO 299822] "Your Reference" is in dataset of report "Standard Sales - Order Conf."
        Initialize();

        // [GIVEN] Sales Order with "Your Reference" = "XXX"
        MockSalesOrderWithExternalDocumentNo(SalesHeader);
        SalesHeader."Your Reference" := LibraryUtility.GenerateGUID();
        SalesHeader.Modify();

        // [WHEN] Export report "Standard Sales - Order Conf." to XML file
        RunStandardSalesOrderConfirmationReport(SalesHeader."No.");
        LibraryReportDataset.LoadDataSetFile();

        // [THEN] Value "XXX" is displayed under Tag <YourReference> in export XML file
        LibraryReportDataset.AssertElementTagWithValueExists('YourReference', SalesHeader."Your Reference");

        // [THEN] Value "External Document No." is displayed under Tag <YourReference_Lbl> in export XML file
        LibraryReportDataset.AssertElementTagWithValueExists('YourReference_Lbl', SalesHeader.FieldCaption("Your Reference"));
    end;

    [Test]
    [HandlerFunctions('StdSalesInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StdSalesInvoicePaymentTerms()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PaymentTerms: Record "Payment Terms";
        PostedSalesInvoiceNo: Code[20];
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO 304263] Report "Standard Sales - Invoice" shows Payment Terms Desription.
        Initialize();

        // [GIVEN] Using RDLC.
        SetRDLCReportLayout(REPORT::"Standard Sales - Invoice");

        // [GIVEN] Posted Sales Invoice with Payment Terms with Description "X".
        LibrarySales.CreateSalesInvoice(SalesHeader);

        LibraryERM.CreatePaymentTerms(PaymentTerms);
        PaymentTerms.Validate(Description, LibraryUtility.GenerateGUID());
        PaymentTerms.Modify(true);
        SalesHeader.Validate("Payment Terms Code", PaymentTerms.Code);
        SalesHeader.Modify(true);

        PostedSalesInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, false, false);

        // [WHEN] Report Standard Sales - Invoice is run for Posted Sales Invoice.
        SalesInvoiceHeader.Get(PostedSalesInvoiceNo);
        SalesInvoiceHeader.SetRecFilter();
        REPORT.Run(REPORT::"Standard Sales - Invoice", true, false, SalesInvoiceHeader);

        // [THEN] Payment Terms Description "X" is shown in report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementTagWithValueExists('PaymentTermsDescription', PaymentTerms.Description);
    end;

    [Test]
    [HandlerFunctions('StdSalesInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StdSalesInvoiceShippingMethod()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ShipmentMethod: Record "Shipment Method";
        PostedSalesInvoiceNo: Code[20];
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO 304263] Report "Standard Sales - Invoice" shows Shipment Method Desription.
        Initialize();

        // [GIVEN] Using RDLC.
        SetRDLCReportLayout(REPORT::"Standard Sales - Invoice");

        // [GIVEN] Posted Sales Invoice with Shipment Method with Description "X".
        LibrarySales.CreateSalesInvoice(SalesHeader);

        CreateShipmentMethod(ShipmentMethod);
        SalesHeader.Validate("Shipment Method Code", ShipmentMethod.Code);
        SalesHeader.Modify(true);

        PostedSalesInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, false, false);

        // [WHEN] Report Standard Sales - Invoice is run for Posted Sales Invoice.
        SalesInvoiceHeader.Get(PostedSalesInvoiceNo);
        SalesInvoiceHeader.SetRecFilter();
        REPORT.Run(REPORT::"Standard Sales - Invoice", true, false, SalesInvoiceHeader);

        // [THEN] Shipment Method Description "X" is shown in report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementTagWithValueExists('ShipmentMethodDescription', ShipmentMethod.Description);
    end;

    [Test]
    [HandlerFunctions('CustomerOrderSummaryRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerOrderSummaryForSalesLineWithDimension()
    var
        Customer: Record Customer;
        DimensionValue: Record "Dimension Value";
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Dimensions] [Customer - Order Summary]
        // [SCENARIO 313866] Report "Customer - Order Summary" doesn't ignore Sales Lines with Dimension in "Shortcut Dimension 1 Code"
        Initialize();

        // [GIVEN] Sales Order with Sales Line with "Dimesnion Value" in "Shortcut Dimension 1 Code"
        LibrarySales.CreateCustomer(Customer);
        CreateSalesDocumentWithLine(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, Customer."No.");
        GeneralLedgerSetup.Get();
        LibraryDimension.FindDimensionValue(DimensionValue, GeneralLedgerSetup."Shortcut Dimension 1 Code");
        SalesLine.Validate("Shortcut Dimension 1 Code", DimensionValue.Code);
        SalesLine.Modify(true);

        // [WHEN] Customer - Order Summary is run.
        LibraryVariableStorage.Enqueue(WorkDate());
        LibraryVariableStorage.Enqueue(false);
        Commit();
        REPORT.Run(REPORT::"Customer - Order Summary", true, false, Customer);

        // [THEN] Sales Order Amount equal to Sales Line's "Quantity" * "Unit Price".
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('SalesOrderAmount', SalesLine.Quantity * SalesLine."Unit Price");
    end;

    [Test]
    [HandlerFunctions('StandardSalesOrderConfExcelRequestPageHandler,SimpleMessageHandler')]
    [Scope('OnPrem')]
    procedure StdSalesOrderConfAssemblyComponentsRDLC()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemComponentCode: array[3] of Code[20];
    begin
        // [FEATURE] [Order] [Confirmation] [Excel] [Layout]
        // [SCENARIO 323241] Report "Standard Sales - Order Conf." show assembly components when printed with RDLC layout
        Initialize();
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());

        // [GIVEN] Report "Standard Sales - Order Conf." RDLC layout selected
        SetRDLCReportLayout(REPORT::"Standard Sales - Order Conf.");

        // [GIVEN] Parent "Item" with setup for assembly to order policy with 3 components
        CreateItemWithAssemblyComponents(Item, ItemComponentCode);

        // [GIVEN] Sales Order with "Item" in the line
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));

        // [WHEN] Run "Standard Sales - Order Conf." report with "Show Assembly Components" checkbox enabled
        LibraryVariableStorage.Enqueue(true);
        RunStandardSalesOrderConfirmationReport(SalesHeader."No.");

        // [THEN] Assembly Components are printed
        VerifyExcelWithItemAssemblyComponents(ItemComponentCode);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StandardSalesInvoiceExcelRequestPageHandler,SimpleMessageHandler')]
    [Scope('OnPrem')]
    procedure StdSalesInvoiceAssemblyComponentsRDLC()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemComponentCode: array[3] of Code[20];
        PostedDocumentNo: Code[20];
    begin
        // [FEATURE] [Posted] [Invoice] [Excel] [Layout]
        // [SCENARIO 323241] Report "Standard Sales - Invoice" show assembly components when printed with RDLC layout
        Initialize();
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());

        // [GIVEN] Report "Standard Sales - Invoice" RDLC layout selected
        SetRDLCReportLayout(REPORT::"Standard Sales - Invoice");

        // [GIVEN] Parent "Item" with setup for assembly to order policy with 3 components
        CreateItemWithAssemblyComponents(Item, ItemComponentCode);

        // [GIVEN] Sales Order with "Item" in the line
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Run "Standard Sales - Order Conf." report with "Show Assembly Components" checkbox enabled
        LibraryVariableStorage.Enqueue(true);
        RunStandardSalesInvoiceReport(PostedDocumentNo);

        // [THEN] Assembly Components are printed
        VerifyExcelWithItemAssemblyComponents(ItemComponentCode);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StdSalesInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StdSalesInvoiceCustomerItemReferenceNo()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        DummySalesInvoiceLine: Record "Sales Invoice Line";
        ItemReferenceNo: Code[50];
    begin
        // [FEATURE] [Posted] [Invoice] [Item Reference]
        // [SCENARIO 345453] "Item Reference No." is included in "Standard Sales - Invoice" Report
        Initialize();

        // [GIVEN] Item Reference "ITC" for Customer "C" and Item "I"
        ItemReferenceNo := CreateCustomerItemReferenceNo(Customer, Item);

        // [GIVEN] Posted Sales Invoice for Customer "C" and Item "I"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, false, true));

        // [WHEN] Run "Standard Sales - Invoice" Report
        RunStandardSalesInvoiceReport(SalesInvoiceHeader."No.");
        LibraryReportDataset.LoadDataSetFile();

        // [THEN] Value "ITC" is displayed under tag <ItemReferenceNo_Line> in export XML file
        LibraryReportDataset.AssertElementTagWithValueExists('ItemReferenceNo_Line', ItemReferenceNo);

        // [THEN] Value "Item Reference No." is displayed under tag <ItemReferenceNo_Line_Lbl> in export XML file
        LibraryReportDataset.AssertElementTagWithValueExists(
          'ItemReferenceNo_Line_Lbl', DummySalesInvoiceLine.FieldCaption("Item Reference No."));
    end;

    [Test]
    [HandlerFunctions('StdSalesCrMemoRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StdSalesCreditMemoCustomerItemReferenceNo()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        DummySalesCrMemoLine: Record "Sales Cr.Memo Line";
        ItemReferenceNo: Code[50];
    begin
        // [FEATURE] [Posted] [Credit Memo] [Item Reference]
        // [SCENARIO 345453] "Item Reference No." is included in "Standard Sales - Credit Memo" Report
        Initialize();

        // [GIVEN] Item Reference "ITC" for Customer "C" and Item "I"
        ItemReferenceNo := CreateCustomerItemReferenceNo(Customer, Item);

        // [GIVEN] Posted Sales Credit Memo for Customer "C" and Item "I"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));
        SalesCrMemoHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, false, true));

        // [WHEN] Run "Standard Sales - Credit Memo" Report
        Commit();
        SalesCrMemoHeader.SetRecFilter();
        REPORT.Run(REPORT::"Standard Sales - Credit Memo", true, false, SalesCrMemoHeader);
        LibraryReportDataset.LoadDataSetFile();

        // [THEN] Value "ITC" is displayed under tag <ItemReferenceNo_Line> in export XML file
        LibraryReportDataset.AssertElementTagWithValueExists('ItemReferenceNo_Line', ItemReferenceNo);

        // [THEN] Value "Item Reference No." is displayed under tag <ItemReferenceNo_Line_Lbl> in export XML file
        LibraryReportDataset.AssertElementTagWithValueExists(
          'ItemReferenceNo_Line_Lbl', DummySalesCrMemoLine.FieldCaption("Item Reference No."));
    end;

    [Test]
    [HandlerFunctions('StandardSalesQuoteRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StdSalesQuoteCustomerItemReferenceNo()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemReferenceNo: Code[50];
    begin
        // [FEATURE] [Quote] [Item Reference]
        // [SCENARIO 345453] "Item Reference No." is included in "Standard Sales - Quote" Report
        Initialize();

        // [GIVEN] Item Reference "ITC" for Customer "C" and Item "I"
        ItemReferenceNo := CreateCustomerItemReferenceNo(Customer, Item);

        // [GIVEN] Sales Quote for Customer "C" and Item "I"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Quote, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));

        // [WHEN] Run report "Standard Sales - Quote".
        Commit();
        SalesHeader.SetRecFilter();
        REPORT.Run(REPORT::"Standard Sales - Quote", true, false, SalesHeader);
        LibraryReportDataset.LoadDataSetFile();

        // [THEN] Value "ITC" is displayed under tag <ItemReferenceNo_Line> in export XML file
        LibraryReportDataset.AssertElementTagWithValueExists('ItemReferenceNo_Line', ItemReferenceNo);

        // [THEN] Value "Item Reference No." is displayed under tag <ItemReferenceNo_Line_Lbl> in export XML file
        LibraryReportDataset.AssertElementTagWithValueExists('ItemReferenceNo_Line_Lbl', SalesLine.FieldCaption("Item Reference No."));
    end;

    [Test]
    [HandlerFunctions('DraftSalesInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DraftSalesInvoiceCustomerItemReferenceNo()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemReferenceNo: Code[50];
    begin
        // [FEATURE] [Invoice] [Item Reference]
        // [SCENARIO 345453] "Item Reference No." is included in "Standard Sales - Draft Invoice" Report
        Initialize();

        // [GIVEN] Item Reference "ITC" for Customer "C" and Item "I"
        ItemReferenceNo := CreateCustomerItemReferenceNo(Customer, Item);

        // [GIVEN] Sales Invoice for Customer "C" and Item "I"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));

        // [WHEN] Run report "Standard Sales - Draft Invoice".
        Commit();
        SalesHeader.SetRecFilter();
        REPORT.Run(REPORT::"Standard Sales - Draft Invoice", true, false, SalesHeader);
        LibraryReportDataset.LoadDataSetFile();

        // [THEN] Value "ITC" is displayed under tag <ItemReferenceNo_Line> in export XML file
        LibraryReportDataset.AssertElementTagWithValueExists('ItemReferenceNo_Line', ItemReferenceNo);

        // [THEN] Value "Item Reference No." is displayed under tag <ItemReferenceNo_Line_Lbl> in export XML file
        LibraryReportDataset.AssertElementTagWithValueExists('ItemReferenceNo_Line_Lbl', SalesLine.FieldCaption("Item Reference No."));
    end;

    [Test]
    [HandlerFunctions('CustomerDetailedAgingRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerDetailedAgingHasProperCaption()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
    begin
        // [FEATURE] [Customer] [Customer Detailed Aging]
        // [SCENARIO 349053] Report "Customer Detailed Aging" shows proper caption text for Customer when running with a filter.
        Initialize();

        // [GIVEN] Customer was created
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] An invoice was posted for the Customer
        CreatePostGeneralJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, Customer."No.", '', LibraryRandom.RandDec(100, 2), WorkDate());

        // [WHEN] The Customer Detailed Aging report is ran with a filter
        RunCustomerDetailedAging(GenJournalLine);
        // UI handled by CustomerDetailedAgingRequestPageHandler

        // [THEN] Resulting dataset has Customer table caption in it
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Customer_TABLECAPTION_CustFilter',
          StrSubstNo('%1: %2: %3', Customer.TableCaption(), Customer.FieldCaption("No."), Customer."No."));
    end;

    [Test]
    [HandlerFunctions('StdSalesInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StandardSalesInvoiceVATAmountSpecification()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO 360359] Report "Standard Sales - Invoice" contains "VAT Amount Specification", when
        // [SCENARIO 360359] "VAT %" = 0, "VAT Clause Code" = '', and Amount = "Amount Including VAT"
        Initialize();

        // [GIVEN] Using RDLC layout for "Standard Sales - Invoice" report

        SetRDLCReportLayout(REPORT::"Standard Sales - Invoice");

        // [GIVEN] Posted Sales Invoice with Sales Line, for which
        // [GIVEN] "VAT %" = 0, "VAT Clause Code" = '', and Amount = "Amount Including VAT"
        LibrarySales.CreateSalesInvoice(SalesHeader);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
        SalesLine.Validate("VAT %", 0);
        SalesLine.Validate("VAT Clause Code", '');
        SalesLine.Modify(true);
        SalesLine.TestField(Amount, SalesLine."Amount Including VAT");

        // [WHEN] Report "Standard Sales - Invoice" is run for Posted Sales Invoice
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, false, false));
        SalesInvoiceHeader.SetRecFilter();
        REPORT.Run(REPORT::"Standard Sales - Invoice", true, false, SalesInvoiceHeader);

        // [THEN] Report contains "VAT Amount Specification" section
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementTagExists('VATAmountSpecification_Lbl');
    end;

    [Test]
    [HandlerFunctions('StdSalesCrMemoRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StandardSalesCreditMemoVATAmountSpecification()
    var
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Credit Memo]
        // [SCENARIO 360359] Report "Standard Sales - Credit Memo" contains "VAT Amount Specification", when
        // [SCENARIO 360359] "VAT %" = 0, "VAT Clause Code" = '', and Amount = "Amount Including VAT"
        Initialize();

        // [GIVEN] Using RDLC layout for "Standard Sales - Credit Memo" report
        SetRDLCReportLayout(REPORT::"Standard Sales - Credit Memo");

        // [GIVEN] Posted Sales Credit Memo with Sales Line, for which
        // [GIVEN] "VAT %" = 0, "VAT Clause Code" = '', and Amount = "Amount Including VAT"
        LibrarySales.CreateSalesCreditMemo(SalesHeader);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
        SalesLine.Validate("VAT %", 0);
        SalesLine.Validate("VAT Clause Code", '');
        SalesLine.Modify(true);
        SalesLine.TestField(Amount, SalesLine."Amount Including VAT");

        // [WHEN] Report "Standard Sales - Credit Memo" is run for Posted Sales Credit Memo
        SalesCrMemoHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesCrMemoHeader.SetRecFilter();
        REPORT.Run(REPORT::"Standard Sales - Credit Memo", true, false, SalesCrMemoHeader);

        // [THEN] Report contains "VAT Amount Specification" section
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementTagExists('VATAmountSpecification_Lbl');
    end;

    [Test]
    [HandlerFunctions('CustomerDetailedAgingRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerDetailedAgingDueMonthsCalculation()
    var
        GenJournalLine: array[4] of Record "Gen. Journal Line";
        Customer: Record Customer;
        DueDate: array[4] of Date;
        EndingDate: Date;
        i: Integer;
        Year: Integer;
        Month: Integer;
        Day: Integer;
    begin
        // [FEATURE] [Customer] [Customer Detailed Aging]
        // [SCENARIO 360075] Report "Customer Detailed Aging" shows consistent Due Months when dates are set in months with different amount of days
        Initialize();

        // [GIVEN] Customer was created
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Ending Date = 20/7/2022
        Year := Date2DMY(WorkDate(), 3) + LibraryRandom.RandInt(5);
        Month := LibraryRandom.RandIntInRange(5, 10);
        Day := LibraryRandom.RandIntInRange(10, 25);
        EndingDate := DMY2Date(Day, Month, Year);

        // [GIVEN] Due Date 1 = 01/03/2022
        DueDate[1] := DMY2Date(1, Month - 4, Year);

        // [GIVEN] Due Date 2 = 25/03/2022
        DueDate[2] := DMY2Date(Day + LibraryRandom.RandIntInRange(2, 9), Month - 4, Year);

        // [GIVEN] Due Date 3 = 15/04/2022
        DueDate[3] := DMY2Date(Day - LibraryRandom.RandIntInRange(2, 8), Month - 3, Year);

        // [GIVEN] Due Date 4 = 30/04/2021
        DueDate[4] := CalcDate('<CM>', DMY2Date(1, Month - 3, Year - 1));

        // [GIVEN] 4 invoices were posted for the Customer with Due Dates 1 to 4
        for i := 1 to ArrayLen(GenJournalLine) do
            CreatePostGeneralJournalLineWithDueDate(
              GenJournalLine[i], GenJournalLine[i]."Document Type"::Invoice,
              Customer."No.", '', LibraryRandom.RandDec(100, 2), WorkDate(), DueDate[i]);

        // [WHEN] The Customer Detailed Aging report is ran for customer with Ending Date
        LibraryVariableStorage.Enqueue(EndingDate);
        LibraryVariableStorage.Enqueue(Customer."No.");
        REPORT.Run(REPORT::"Customer Detailed Aging");
        // UI handled by CustomerDetailedAgingRequestPageHandler

        LibraryReportDataset.LoadDataSetFile();
        // [THEN] DueMonths for Due Date 1 is 4
        VerifyDueMonthsForDueDate(DueDate[1], 4);

        // [THEN] DueMonths for Due Date 2 is 3
        VerifyDueMonthsForDueDate(DueDate[2], 3);

        // [THEN] DueMonths for Due Date 3 is 3
        VerifyDueMonthsForDueDate(DueDate[3], 3);

        // [THEN] DueMonths for Due Date 4 is 14
        VerifyDueMonthsForDueDate(DueDate[4], 14);
    end;

    [Test]
    [HandlerFunctions('SalesStatisticsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesStatisticsReportForNonInventoryItem()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Non-Inventory Item]
        // [SCENARIO 359883] Cost of a non-inventory item in Sales Statistics report.
        Initialize();
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Non-inventory item with "Unit Cost" = 10 and "Unit Price" = 30.
        LibraryInventory.CreateNonInventoryTypeItem(Item);
        Item.Validate("Unit Cost", LibraryRandom.RandDec(100, 2));
        Item.Validate("Unit Price", LibraryRandom.RandDecInRange(200, 400, 2));
        Item.Modify(true);

        // [GIVEN] Sales order for 1 pc of the non-inventory item.
        // [GIVEN] Ship and invoice the sales order.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Run "Sales Statistics" report.
        Commit();
        Customer.SetRecFilter();
        REPORT.Run(REPORT::"Sales Statistics", true, false, Customer);

        // [THEN] The report shows "Profit" = 20, and "Adjusted Cost" = 10.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('CustProfitLCY2', Item."Unit Price" - Item."Unit Cost");
        LibraryReportDataset.AssertElementWithValueExists('CustSalProfAdjmtCostLCY2', Item."Unit Cost");
    end;

    [Test]
    [HandlerFunctions('CustomerItemSalesEmptyRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerItemSalesEmptyDataset()
    var
        Customer: Record Customer;
    begin
        // [SCENARIO 364816] Report "Customer/Item Sales" shows message 'There is nothing to print for the selected filters.' when resulting dataset is empty.
        Initialize();

        // [WHEN] Report "Customer/Item Sales" is run for non-existing Customer.
        LibraryVariableStorage.Enqueue(LibraryRandom.RandText(MaxStrLen(Customer."No.")));
        Commit();
        asserterror REPORT.Run(REPORT::"Customer/Item Sales");

        // [THEN] Report dataset is empty and error 'There is nothing to print for the selected filters.' is shown.
        Assert.ExpectedError(EmptyReportDatasetTxt);
        Assert.ExpectedErrorCode('Dialog');
        LibraryReportDataset.LoadDataSetFile();
        Assert.AreEqual(0, LibraryReportDataset.RowCount(), '');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StandardSalesInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StandardSalesInvoiceJobNoAndJobTaskNo()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        // [SCENARIO 370287] "Standard Sales - Invoice" report dataset has "Job No" and "Job Task No" from Sales Invoice line.
        Initialize();

        // [GIVEN] Sales Invoice with Sales Invoice Line with Job No and Job Task No.
        MockSalesInvoiceHeaderWithExternalDocumentNo(SalesInvoiceHeader);
        MockSalesInvoiceLineWithJobNoAndJobTaskNo(SalesInvoiceLine, SalesInvoiceHeader."No.");

        // [WHEN] Report "Standard Sales - Invoice" is run for Sales Invoice.
        RunStandardSalesInvoiceReport(SalesInvoiceHeader."No.");

        // [THEN] Resulting dataset has Job No and Job Task No.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('JobNo', SalesInvoiceLine."Job No.");
        LibraryReportDataset.AssertElementWithValueExists('JobTaskNo', SalesInvoiceLine."Job Task No.");
    end;

    [Test]
    [HandlerFunctions('CustomerDetailedAgingRequestPageHandler')]
    procedure CustomerDetailedAgingShowsEntriesWithZeroRemainingAmount()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // [SCENARIO 389943] Report "Customer Detailed Aging" with "Show Only Open Entries" = False shows ledger entries with Remaining Amount = 0.
        Initialize();

        // [GIVEN] Customer has closed Customer Ledger Entry with "Remaining Amount" = 0.
        LibrarySales.MockCustLedgerEntryWithZeroBalance(CustLedgerEntry, LibrarySales.CreateCustomerNo());
        CustLedgerEntry.Open := false;
        CustLedgerEntry.Modify();

        // [WHEN] Customer Detailed Aging Report is run for Customer.
        LibraryVariableStorage.Enqueue(WorkDate());
        LibraryVariableStorage.Enqueue(CustLedgerEntry."Customer No.");
        Commit();
        REPORT.Run(REPORT::"Customer Detailed Aging");

        // [THEN] Report shows Customer Ledger Entry with "Remaining Amount" = 0.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Cust_Ledger_Entry_Remaining_Amount_', 0);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StandardSalesOrderConfRequestPageHandler')]
    procedure StandardSalesOrderConfPlannedShipmentDateIsPrinted()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [UI] [Order] [Confirmation]
        // [SCENARIO 391390] "Planned Shipment Date" is shown with its caption when report "Standard Sales - Order Conf." is printed for Sales Order
        Initialize();

        // [GIVEN] Sales Order
        CreateSalesOrder(SalesHeader, SalesLine, '', LibrarySales.CreateCustomerNo());

        // [WHEN] Export report "Standard Sales - Order Conf." to XML file
        RunStandardSalesOrderConfirmationReport(SalesHeader."No.");
        LibraryReportDataset.LoadDataSetFile();

        // [THEN] Planned Shipment Date for the line is exported, along with its label
        LibraryReportDataset.AssertElementTagWithValueExists('PlannedShipmentDate_Line_Lbl', SalesLine.FieldCaption("Planned Shipment Date"));
        LibraryReportDataset.AssertElementTagWithValueExists('PlannedShipmentDate_Line', Format(SalesLine."Planned Shipment Date"));
    end;

    [Test]
    procedure ReportTotalsBufferFormatAmountFormatted()
    var
        ReportTotalsBuffer: Record "Report Totals Buffer" temporary;
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 393753] Correct formatting of "Report Totals Buffer"."Amount Formatted" when pass AutoFormatExp in function Add(...)
        Initialize();

        // [GIVEN] Currency "C" with "Amount Decimal Places" = '3:3' and "Amount Rounding Precision" = '0.001'
        CurrencyCode := CreateCurrencyWithDecimalPlaces();

        // [WHEN] Invoke "Report Totals Buffer".Add(...) with AutoFormatExp and Amount = 123.123
        ReportTotalsBuffer.Add('', 123.123, true, true, true, CurrencyCode);

        // [THEN] "Amount Formatted" = 123.123
        ReportTotalsBuffer.FindFirst();
        Assert.IsTrue(ReportTotalsBuffer."Amount Formatted".EndsWith('.123'), WrongDecimalErr);
    end;

    [Test]
    [HandlerFunctions('CustSummaryAgingSimpRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerSummaryAgingSimp()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        Customer2: Record Customer;
    begin
        // [FEATURE] [Customer - Summary Aging Simp.]
        // [SCENARIO 393623] Customer - Summary Aging Simp. must show only corresponding Customers when user set custom filters
        Initialize();

        // [GIVEN] Customer "C1" with customer ledger entries
        // [GIVEN] "CLE1" with "Amount" = 1000 and "Due Date" = 01/01/21
        // [GIVEN] "CLE2" with "Amount" = 1000 and "Due Date" = 01/31/21
        LibrarySales.CreateCustomer(Customer);
        CreatePostGeneralJournalLine(GenJournalLine, GenJournalLine."Document Type"::Invoice, Customer."No.", '', 1000, WorkDate());
        CreatePostGeneralJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, Customer."No.", '', 1000, CalcDate('<10D>', WorkDate()));

        // [GIVEN] Customer "C2" with customer ledger entry
        // [GIVEN] "CLE3" with "Amount" = 3000 and "Due Date" = 01/01/21
        LibrarySales.CreateCustomer(Customer2);
        CreatePostGeneralJournalLine(GenJournalLine, GenJournalLine."Document Type"::Invoice, Customer2."No.", '', 3000, WorkDate());

        LibraryVariableStorage.Enqueue(CalcDate('<5D>', WorkDate()));
        LibraryVariableStorage.Enqueue('>1500');

        // [WHEN] Run "Customer - Summary Aging Simp."
        // [WHEN] Start date = "01/15/21" and filter for Customer "Balance Due" > 1500
        Report.Run(Report::"Customer - Summary Aging Simp.");

        // [THEN] Report contains only Customer "C2"
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueNotExist('Customer__No__', Customer."No.");
        LibraryReportDataset.AssertElementWithValueExists('Customer__No__', Customer2."No.");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CustSummaryAgingRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustSummaryAging()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        Customer2: Record Customer;
    begin
        // [FEATURE] [Customer - Summary Aging]
        // [SCENARIO 393623] Customer - Summary Aging must show only corresponding Customers when user set custom filters
        Initialize();

        // [GIVEN] Customer "C1" with customer ledger entries
        // [GIVEN] "CLE1" with "Amount" = 1000 and "Due Date" = 01/01/21
        // [GIVEN] "CLE2" with "Amount" = 1000 and "Due Date" = 01/31/21
        LibrarySales.CreateCustomer(Customer);
        CreatePostGeneralJournalLine(GenJournalLine, GenJournalLine."Document Type"::Invoice, Customer."No.", '', 1000, WorkDate());
        CreatePostGeneralJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, Customer."No.", '', 1000, CalcDate('<10D>', WorkDate()));

        // [GIVEN] Customer "C2" with customer ledger entry
        // [GIVEN] "CLE3" with "Amount" = 3000 and "Due Date" = 01/01/21
        LibrarySales.CreateCustomer(Customer2);
        CreatePostGeneralJournalLine(GenJournalLine, GenJournalLine."Document Type"::Invoice, Customer2."No.", '', 3000, WorkDate());

        LibraryVariableStorage.Enqueue(CalcDate('<5D>', WorkDate()));
        LibraryVariableStorage.Enqueue('>1500');

        // [WHEN] Run "Customer - Summary Aging Simp."
        // [WHEN] Start date = "01/15/21" and filter for Customer "Balance Due" > 1500
        Report.Run(Report::"Customer - Summary Aging");

        // [THEN] Report contains only Customer "C2"
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueNotExist('Customer_No_', Customer."No.");
        LibraryReportDataset.AssertElementWithValueExists('Customer_No_', Customer2."No.");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StandardSalesInvoiceRequestPageHandler,StandardSalesQuoteRequestPageHandler,StdSalesCrMemoRequestPageHandler,StandardSalesOrderConfRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StandardSalesInvoiceCurrDataSalesHeaderCurrency()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCreditMemoHeader: Record "Sales Cr.Memo Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Currency: Record Currency;
        Customer: Record Customer;
    begin

        // [SCENARIO 424803]
        Initialize();

        // [GIVEN] Currency with Code "Curr" and currency symbol = "$"
        Currency.Get(LibraryERM.CreateCurrencyWithRandomExchRates());
        Currency.Validate(Symbol, Format(LibraryRandom.RandIntInRange(1, 9)));
        Currency.Modify();
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Currency Code", Currency.Code);
        Customer.Modify();
        // [GIVEN] Posted Sales Invoice with Currency "Curr"
        CreateSalesInvoiceWithLine(SalesHeader, SalesLine, Customer."No.");
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Export report "Standard Sales - Invoice" to XML file
        RunStandardSalesInvoiceReport(SalesInvoiceHeader."No.");
        LibraryReportDataset.LoadDataSetFile();

        // [THEN] Value "Curr" is displayed under tag <CurrencyCode> in export XML file
        LibraryReportDataset.AssertElementTagWithValueExists('CurrencyCode', Currency.Code);

        // [THEN] Value "$" is displayed under tag <CurrencySymbol> in export XML file
        LibraryReportDataset.AssertElementTagWithValueExists('CurrencySymbol', Currency.Symbol);

        // [GIVEN] Posted Sales Credit Memo with Currency "Curr"
        CreateSalesCreditMemoWithLine(SalesHeader, SalesLine, Customer."No.");
        SalesCreditMemoHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Export report "Standard Sales - Credit Memo" to XML file
        RunStandardSalesCreditMemoReport(SalesCreditMemoHeader."No.");
        LibraryReportDataset.LoadDataSetFile();

        // [THEN] Value "Curr" is displayed under tag <CurrencyCode> in export XML file
        LibraryReportDataset.AssertElementTagWithValueExists('CurrencyCode', Currency.Code);

        // [THEN] Value "$" is displayed under tag <CurrencySymbol> in export XML file
        LibraryReportDataset.AssertElementTagWithValueExists('CurrencySymbol', Currency.Symbol);

        // [GIVEN] Posted Sales Quote with Currency "Curr"
        CreateSalesQuoteWithLine(SalesHeader, SalesLine, Customer."No.");

        // [WHEN] Export report "Standard Sales - Quote" to XML file
        RunStandardSalesQuoteReport(SalesHeader."No.");
        LibraryReportDataset.LoadDataSetFile();

        // [THEN] Value "Curr" is displayed under tag <CurrencyCode> in export XML file
        LibraryReportDataset.AssertElementTagWithValueExists('CurrencyCode', Currency.Code);

        // [THEN] Value "$" is displayed under tag <CurrencySymbol> in export XML file
        LibraryReportDataset.AssertElementTagWithValueExists('CurrencySymbol', Currency.Symbol);

        // [GIVEN] Sales Order with Currency "Curr"
        CreateSalesOrder(SalesHeader, SalesLine, Currency.Code, Customer."No.");

        // [WHEN] Export report "Standard Sales - Order Conf." to XML file
        RunStandardSalesOrderConfirmationReport(SalesHeader."No.");
        LibraryReportDataset.LoadDataSetFile();

        // [THEN] Value "Curr" is displayed under tag <CurrencyCode> in export XML file
        LibraryReportDataset.AssertElementTagWithValueExists('CurrencyCode', Currency.Code);

        // [THEN] Value "$" is displayed under tag <CurrencySymbol> in export XML file
        LibraryReportDataset.AssertElementTagWithValueExists('CurrencySymbol', Currency.Symbol);
    end;

    [Test]
    [HandlerFunctions('StandardSalesInvoiceRequestPageHandler,StandardSalesQuoteRequestPageHandler,StdSalesCrMemoRequestPageHandler,StandardSalesOrderConfRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StandardSalesInvoiceCurrDataGLSetup()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin

        // [SCENARIO 424803]
        Initialize();

        // [GIVEN] General Ledger Setup "LCY Code" = "Curr", "Local Currency Symbol" = "$"
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."LCY Code" := '';        // to avoid error on updating LCY Code
        GeneralLedgerSetup.Validate("LCY Code", 'Curr');
        GeneralLedgerSetup.Validate("Local Currency Symbol", '$');
        GeneralLedgerSetup.Modify();

        // [GIVEN] Posted Sales Invoice with Currency "Curr"
        CreateSalesInvoiceWithLine(SalesHeader, SalesLine, CreateCustomer());
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Export report "Standard Sales - Invoice" to XML file
        RunStandardSalesInvoiceReport(SalesInvoiceHeader."No.");
        LibraryReportDataset.LoadDataSetFile();

        // [THEN] Value "Curr" is displayed under tag <CurrencyCode> in export XML file
        LibraryReportDataset.AssertElementTagWithValueExists(
            'CurrencyCode', GeneralLedgerSetup."LCY Code");

        // [THEN] Value "$" is displayed under tag <CurrencySymbol> in export XML file
        LibraryReportDataset.AssertElementTagWithValueExists(
            'CurrencySymbol', GeneralLedgerSetup."Local Currency Symbol");

        // [GIVEN] Posted Sales Credit Memo with Currency "Curr"
        CreateSalesCreditMemoWithLine(SalesHeader, SalesLine, SalesHeader."Sell-to Customer No.");
        SalesCrMemoHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Export report "Standard Sales - Credit Memo" to XML file
        RunStandardSalesCreditMemoReport(SalesCrMemoHeader."No.");
        LibraryReportDataset.LoadDataSetFile();

        // [THEN] Value "Curr" is displayed under tag <CurrencyCode> in export XML file
        LibraryReportDataset.AssertElementTagWithValueExists(
            'CurrencyCode', GeneralLedgerSetup."LCY Code");

        // [THEN] Value "$" is displayed under tag <CurrencySymbol> in export XML file
        LibraryReportDataset.AssertElementTagWithValueExists(
            'CurrencySymbol', GeneralLedgerSetup."Local Currency Symbol");

        // [GIVEN] Posted Sales Quote with Currency "Curr"
        CreateSalesQuoteWithLine(SalesHeader, SalesLine, SalesCrMemoHeader."Sell-to Customer No.");

        // [WHEN] Export report "Standard Sales - Quote" to XML file
        RunStandardSalesQuoteReport(SalesHeader."No.");
        LibraryReportDataset.LoadDataSetFile();

        // [THEN] Value "Curr" is displayed under tag <CurrencyCode> in export XML file
        LibraryReportDataset.AssertElementTagWithValueExists(
            'CurrencyCode', GeneralLedgerSetup."LCY Code");

        // [THEN] Value "$" is displayed under tag <CurrencySymbol> in export XML file
        LibraryReportDataset.AssertElementTagWithValueExists(
            'CurrencySymbol', GeneralLedgerSetup."Local Currency Symbol");

        // [GIVEN] Sales Order with Currency "Curr"
        CreateSalesOrder(SalesHeader, SalesLine, '', SalesCrMemoHeader."Sell-to Customer No.");

        // [WHEN] Export report "Standard Sales - Order Conf." to XML file
        RunStandardSalesOrderConfirmationReport(SalesHeader."No.");
        LibraryReportDataset.LoadDataSetFile();

        // [THEN] Value "Curr" is displayed under tag <CurrencyCode> in export XML file
        LibraryReportDataset.AssertElementTagWithValueExists(
            'CurrencyCode', GeneralLedgerSetup."LCY Code");

        // [THEN] Value "$" is displayed under tag <CurrencySymbol> in export XML file
        LibraryReportDataset.AssertElementTagWithValueExists(
            'CurrencySymbol', GeneralLedgerSetup."Local Currency Symbol");
    end;

    [Test]
    [HandlerFunctions('StandardSalesInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StandardSalesInvoiceShowsTranslatedVATClause()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        VATClause: Record "VAT Clause";
        VATPostingSetup: Record "VAT Posting Setup";
        VATClauseTranslation: Record "VAT Clause Translation";
        Customer: Record Customer;
        Language: Record Language;
    begin
        // [FEATURE] [Sales] [Invoice] [VAT Clause]
        // [SCENARIO 450385] Report 1306 "Standard Sales - Invoice" shows the translated VAT Clause

        Initialize();

        // [GIVEN] Language code "DEU"
        Language.Validate(Code, LibraryUtility.GenerateGUID());
        Language.Insert(true);

        // [GIVEN] VAT Posting Setup with the VAT clause that has a translation for the language code "X". Description = "Beschreibung 1", "Description 2" ="Beschreibung 2"
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 0);
        LibraryERM.CreateVATClause(VATClause);
        VATPostingSetup.Validate("VAT Clause Code", VATClause.Code);
        VATPostingSetup.Modify(true);

        CreateVATClauseTranslation(VATClauseTranslation, VATClause.Code, Language.Code);

        // [GIVEN] Sales Invoice with the VAT Posting setup associated with the VAT Clause
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Language Code", Language.Code);
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Modify(true);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        CreateSalesLineWithItemWithVATPostingSetup(SalesHeader, VATPostingSetup);

        // [GIVEN] Posted Sales Invoice
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesInvoiceHeader.SetRecFilter();

        // [WHEN] Run report "Standard Sales - Invoice" for Posted Sales Invoice
        REPORT.Run(REPORT::"Standard Sales - Invoice", true, false, SalesInvoiceHeader);

        // [THEN] Report DataSet contains VAT Clause fields: "Beschreibung 1" and "Beschreibung 2"
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementTagWithValueExists(
          'Description_VATClauseLine', VATClauseTranslation.Description + ' ' + VATClauseTranslation."Description 2");
    end;

    [Test]
    [HandlerFunctions('DraftSalesInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StandardSalesDraftInvoiceShowsTranslatedVATClause()
    var
        SalesHeader: Record "Sales Header";
        VATClause: Record "VAT Clause";
        VATPostingSetup: Record "VAT Posting Setup";
        VATClauseTranslation: Record "VAT Clause Translation";
        Customer: Record Customer;
        Language: Record Language;
    begin
        // [FEATURE] [Sales] [Invoice] [VAT Clause]
        // [SCENARIO 450385] Report 1303 "Standard Sales - Draft Invoice" shows the translated VAT Clause

        Initialize();

        // [GIVEN] Language code "DEU"
        Language.Validate(Code, LibraryUtility.GenerateGUID());
        Language.Insert(true);

        // [GIVEN] VAT Posting Setup with the VAT clause that has a translation for the language code "X". Description = "Beschreibung 1", "Description 2" ="Beschreibung 2"
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 0);
        LibraryERM.CreateVATClause(VATClause);
        VATPostingSetup.Validate("VAT Clause Code", VATClause.Code);
        VATPostingSetup.Modify(true);
        CreateVATClauseTranslation(VATClauseTranslation, VATClause.Code, Language.Code);

        // [GIVEN] Sales Invoice with the VAT Posting setup associated with the VAT Clause
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Language Code", Language.Code);
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Modify(true);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        CreateSalesLineWithItemWithVATPostingSetup(SalesHeader, VATPostingSetup);
        SalesHeader.SetRecFilter();
        Commit();

        // [WHEN] Run report "Standard Sales - Draft Invoice" for Sales Invoice
        REPORT.Run(REPORT::"Standard Sales - Draft Invoice", true, false, SalesHeader);

        // [THEN] Report DataSet contains VAT Clause fields: "Beschreibung 1" and "Beschreibung 2"
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementTagWithValueExists(
          'Description_VATClauseLine', VATClauseTranslation.Description + ' ' + VATClauseTranslation."Description 2");
    end;

    [Test]
    [HandlerFunctions('ReportStandardSalesDraftInvoiceRequestPageHandlerForLogInteractionEnabled')]
    [Scope('OnPrem')]
    procedure TestReportStandardSalesDraftInvoice_NotDefinedInteractionTemplate()
    var
        InteractionTemplateSetup: Record "Interaction Template Setup";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Sales Invoice] [Draft Invoice]
        // [SCENARIO 438090] Test Report "Standard Sales - Draft Invoice" without Interaction Template defined.
        Initialize();

        // [GIVEN] Purge "Interaction Template Setup" for "Draft Sales Invoices"
        InteractionTemplateSetup.Get();
        if InteractionTemplateSetup."Sales Draft Invoices" <> '' then begin
            InteractionTemplateSetup.Validate("Sales Draft Invoices", '');
            InteractionTemplateSetup.Modify(true);
        end;

        // [GIVEN] Create Sales Invoice
        CreateSalesDocumentWithLine(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, Customer."No.");
        Commit();

        // [WHEN] Run report "Standard Sales - Draft Invoice"
        SalesHeader.SetRecFilter();
        Report.Run(Report::"Standard Sales - Draft Invoice", true, false, SalesHeader);

        // [THEN] Verify in Report Request Page that "Log Interaction" is disabled
        // Tested in ReportStandardSalesDraftInvoiceRequestPageHandlerForLogInteractionEnabled handler function
    end;

    [Test]
    [HandlerFunctions('ReportStandardSalesDraftInvoiceRequestPageHandlerForLogInteractionExecute')]
    [Scope('OnPrem')]
    procedure TestReportStandardSalesDraftInvoice_DefinedInteractionTemplate_WithLogInteraction()
    var
        InteractionTemplateSetup: Record "Interaction Template Setup";
        InteractionTemplate: Record "Interaction Template";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        InteractionLogEntry: Record "Interaction Log Entry";
        LogInteraction: Boolean;
    begin
        // [FEATURE] [Sales Invoice] [Draft Invoice]
        // [SCENARIO 438090] Test Report "Standard Sales - Draft Invoice" with Log Interaction option enabled.
        Initialize();

        // [GIVEN] Setup "Interaction Template Setup" for "Draft Sales Invoices"
        InteractionTemplateSetup.Get();
        if InteractionTemplateSetup."Sales Draft Invoices" = '' then begin
            LibraryMarketing.CreateInteractionTemplate(InteractionTemplate);
            InteractionTemplateSetup.Validate("Sales Draft Invoices", InteractionTemplate."Code");
            InteractionTemplateSetup.Modify(true);
        end;

        // [GIVEN] Create Sales Invoice
        CreateSalesDocumentWithLine(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, Customer."No.");
        Commit();

        // [WHEN] Run report "Standard Sales - Draft Invoice" with Log Interaction
        LogInteraction := true;
        LibraryVariableStorage.Enqueue(LogInteraction);
        SalesHeader.SetRecFilter();
        Report.Run(Report::"Standard Sales - Draft Invoice", true, false, SalesHeader);

        // [THEN] Verify that "Interaction Log Entry" is created. Then verify that "Interaction Log Entry" has "Interaction Template Setup"."Draft Sales Invoices" as "Interaction Template Code" value
        InteractionLogEntry.SetRange("Document Type", "Interaction Log Entry Document Type"::"Sales Draft Invoice");
        InteractionLogEntry.SetRange("Document No.", SalesHeader."No.");
        InteractionLogEntry.FindFirst();
        InteractionLogEntry.TestField("Interaction Template Code", InteractionTemplateSetup."Sales Draft Invoices");
    end;

    [Test]
    [HandlerFunctions('ReportStandardSalesDraftInvoiceRequestPageHandlerForLogInteractionExecute')]
    [Scope('OnPrem')]
    procedure TestReportStandardSalesDraftInvoice_DefinedInteractionTemplate_WithoutLogInteraction()
    var
        InteractionTemplateSetup: Record "Interaction Template Setup";
        InteractionTemplate: Record "Interaction Template";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        InteractionLogEntry: Record "Interaction Log Entry";
        LogInteraction: Boolean;
    begin
        // [FEATURE] [Sales Invoice] [Draft Invoice]
        // [SCENARIO 438090] Test Report "Standard Sales - Draft Invoice" with Log Interaction option disabled.
        Initialize();

        // [GIVEN] Setup "Interaction Template Setup" for "Draft Sales Invoices"
        InteractionTemplateSetup.Get();
        if InteractionTemplateSetup."Sales Draft Invoices" = '' then begin
            LibraryMarketing.CreateInteractionTemplate(InteractionTemplate);
            InteractionTemplateSetup.Validate("Sales Draft Invoices", InteractionTemplate."Code");
            InteractionTemplateSetup.Modify(true);
        end;

        // [GIVEN] Create Sales Invoice
        CreateSalesDocumentWithLine(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, Customer."No.");
        Commit();

        // [WHEN] Run report "Standard Sales - Draft Invoice" without Log Interaction
        LogInteraction := false;
        LibraryVariableStorage.Enqueue(LogInteraction);
        SalesHeader.SetRecFilter();
        Report.Run(Report::"Standard Sales - Draft Invoice", true, false, SalesHeader);

        // [THEN] Verify that Interaction Log Entry does not exists
        InteractionLogEntry.SetRange("Document Type", "Interaction Log Entry Document Type"::"Sales Draft Invoice");
        InteractionLogEntry.SetRange("Document No.", SalesHeader."No.");
        Assert.RecordIsEmpty(InteractionLogEntry);
    end;


    [Test]
    [HandlerFunctions('ReportStandardSalesShipmentRequestPageHandlerForLogInteractionExecute')]
    [Scope('OnPrem')]
    procedure TestReportStandardSalesShipment_DefinedInteractionTemplate_WithLogInteraction()
    var
        InteractionTemplateSetup: Record "Interaction Template Setup";
        InteractionTemplate: Record "Interaction Template";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesLine: Record "Sales Line";
        PostedDocumentNo: Code[20];
        InteractionLogEntry: Record "Interaction Log Entry";
        LogInteraction: Boolean;
        ParametersXml: Text;
    begin
        // [FEATURE] [Sales Shipment]
        // [SCENARIO] Test Report "Standard Sales - Shipment" with Log Interaction option enabled.
        Initialize();

        // [GIVEN] Setup "Interaction Template Setup" for "Sales Shpt. Note"
        InteractionTemplateSetup.Get();
        if InteractionTemplateSetup."Sales Shpt. Note" = '' then begin
            LibraryMarketing.CreateInteractionTemplate(InteractionTemplate);
            InteractionTemplateSetup.Validate("Sales Shpt. Note", InteractionTemplate."Code");
            InteractionTemplateSetup.Modify(true);
        end;

        // [GIVEN] Sales Shipment Header
        CreateSalesDocumentWithLine(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, Customer."No.");
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, false);
        SalesShipmentHeader.Get(PostedDocumentNo);
        Commit();

        // [WHEN] Run report "Standard Sales - Shipment" with Log Interaction
        LogInteraction := true;
        LibraryVariableStorage.Enqueue(LogInteraction);
        SalesShipmentHeader.SetRecFilter();
        ParametersXml := Report.RunRequestPage(Report::"Standard Sales - Shipment");
        LibraryReportDataset.RunReportAndLoad(Report::"Standard Sales - Shipment", SalesShipmentHeader, ParametersXml);

        // [THEN] Verify that "Interaction Log Entry" is created. Then verify that "Interaction Log Entry" has "Interaction Template Setup"."Sales Shpt. Note" as "Interaction Template Code" value
        InteractionLogEntry.SetRange("Document Type", Enum::"Interaction Log Entry Document Type"::"Sales Shpt. Note");
        InteractionLogEntry.SetRange("Document No.", SalesShipmentHeader."No.");
        InteractionLogEntry.FindFirst();
        InteractionLogEntry.TestField("Interaction Template Code", InteractionTemplateSetup."Sales Shpt. Note");
    end;

    [Test]
    [HandlerFunctions('StandardSalesInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StandardSalesInvoiceShowsSingleVATClausesForMultipleLineWithSameVATPostingSetup()
    var
        Item: Record Item;
        Customer: Record Customer;
        VATClause: Record "VAT Clause";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        // [SCENARIO 477998] The VAT clause should be printed once, having the same VAT Posting Setup and zero VAT when there are two lines.
        // The first line has +ve quantity, and the second line has -ve quantity.
        Initialize();

        // [GIVEN] Create a VAT Clause.
        LibraryERM.CreateVATClause(VATClause);

        // [GIVEN] Create a VAT Posting Setup with a VAT rate of zero.
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 0);
        VATPostingSetup.Validate("VAT Clause Code", VATClause.Code);
        VATPostingSetup.Modify(true);

        // [GIVEN] Create a VAT Product Posting Setup.
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);

        // [GIVEN] Create a Customer and update the VAT Bus. Posting Group.
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Modify(true);

        // [GIVEN] Create an Item and update the VAT Prod. Posting Group.
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Modify(true);

        // [GIVEN] Create a Sales Invoice.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");

        // [GIVEN] Create a sales line "A" with +ve quantity.
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(100));
        SalesLine.Validate("Unit Price", LibraryRandom.RandInt(300));
        SalesLine.Modify(true);

        // [GIVEN] Create a sales line "B" with -ve quantity.
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", -LibraryRandom.RandInt(20));
        SalesLine.Validate("Unit Price", LibraryRandom.RandInt(100));
        SalesLine.Modify(true);

        // [GIVEN] Post a Sales Invoice.
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesInvoiceHeader.SetRecFilter();

        // [WHEN] Run the report "Standard Sales—Invoice" for the posted sales invoice.
        Clear(LibraryReportDataset);
        Report.Run(Report::"Standard Sales - Invoice", true, false, SalesInvoiceHeader);

        // [VERIFY] VAT clause should be printed only once after running the report "Standard Sales—Invoice".
        VerifyVATClauseShouldBePrintOnlyOnce(VATClause);
    end;

    [Test]
    [HandlerFunctions('CustBalanceToDateRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerBalanceToDateShowsCorrectInvoicesWhenInvoicehasUnappliedAndReapplied()
    var
        Customer: Record Customer;
        InvoiceAmount: array[3] of Decimal;
        InvoiceNo: array[3] of Code[20];
        PaymentDocumentNo: array[2] of Code[20];
    begin
        // [SCENARIO 543032] When Stan Unapply and Apply again Invoice and Payment Customer Ledger Entries
        // On same Posting Date then Invoice Customer Ledger Entry exists in Customer - Balance to Date report.
        Initialize();

        // [GIVEN] Create a Customer.
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Generate and save Invoice Amount [1] in a Variable.
        InvoiceAmount[1] := LibraryRandom.RandDecInRange(100, 200, 2);

        // [GIVEN] Create and Post Sales Invoice.
        InvoiceNo[1] := CreateAndPostInvoice(WorkDate(), Customer."No.", InvoiceAmount[1]);

        // [GIVEN] Generate and save Invoice Amount [2] in a Variable.
        InvoiceAmount[2] := LibraryRandom.RandDecInRange(100, 200, 2);

        // [GIVEN] Create and Post Sales Invoice.
        InvoiceNo[2] := CreateAndPostInvoice(WorkDate() + 10, Customer."No.", InvoiceAmount[2]);

        // [GIVEN] Generate and save Invoice Amount [3] in a Variable.
        InvoiceAmount[3] := LibraryRandom.RandDecInRange(100, 200, 2);

        // [GIVEN] Create and Post Sales Invoice.
        InvoiceNo[3] := CreateAndPostInvoice(WorkDate() + 35, Customer."No.", InvoiceAmount[3]);

        // [GIVEN] Create Payment, Apply and Post.
        PaymentDocumentNo[1] := CreatePaymentApplyAndPost(WorkDate() + 30, Customer."No.", InvoiceAmount[1], InvoiceNo[1]);

        // [GIVEN] Create another Payment, Apply and Post.
        PaymentDocumentNo[2] := CreatePaymentApplyAndPost(WorkDate() + 40, Customer."No.", InvoiceAmount[2], InvoiceNo[2]);

        // [GIVEN] Unapply Customer ledger Entry.
        UnapplyCustLedgerEntry("Gen. Journal Document Type"::Payment, PaymentDocumentNo[2]);

        // [GIVEN] Apply and Post Customer Ledger Entry.
        ApplyAndPostCustomerEntry(InvoiceNo[2], PaymentDocumentNo[2], InvoiceAmount[2], "Gen. Journal Document Type"::Invoice, "Gen. Journal Document Type"::Payment);

        // [WHEN] Run Customer Balance To Date with Customer.
        RunCustomerBalanceToDateWithCustomer(Customer."No.", false, WorkDate() + 20);

        // [THEN] Two entries exist in Customer Balance To Date report.
        VerifyCustomerBalanceToDateTwoEntriesExist(Customer."No.", InvoiceAmount[1], InvoiceAmount[1], InvoiceAmount[1] + InvoiceAmount[2]);
    end;

    local procedure Initialize()
    begin
        LibraryApplicationArea.DisableApplicationAreaSetup();
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Sales Report");
        LibrarySetupStorage.Restore();
        LibraryVariableStorage.Clear();

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Sales Report");

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibrarySales.SetInvoiceRounding(false);

        isInitialized := true;
        Commit();

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Sales Report");
    end;

    local procedure ClearGenJournalLine(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
    end;

    local procedure CreateAndPostInvoice(AccountNo: Code[20]; CurrencyCode: Code[10]; Amount: Decimal): Code[20]
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        ClearGenJournalLine(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Customer, AccountNo, Amount);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine."Document No.");
    end;

    local procedure CreateAndPostSalesOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"): Code[20]
    begin
        // Create Sales Order with Random Quantity.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer());
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateAndPostItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; EntryType: Enum "Item Ledger Entry Type"; ItemNo: Code[20])
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        SelectItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Type::Item);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, EntryType, ItemNo,
          LibraryRandom.RandDecInRange(50, 100, 2)); // Use random Quantity.
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreateAssemblyComponent(ParentItemNo: Code[20]): Code[20]
    var
        AssemblyItem: Record Item;
        BOMComponent: Record "BOM Component";
    begin
        LibraryAssembly.CreateItem(AssemblyItem, AssemblyItem."Costing Method"::FIFO, AssemblyItem."Replenishment System"::Purchase, '', '');
        LibraryInventory.CreateBOMComponent(
          BOMComponent, ParentItemNo, BOMComponent.Type::Item,
          AssemblyItem."No.", LibraryRandom.RandDec(2, 4), AssemblyItem."Base Unit of Measure");
        BOMComponent.Validate(Description, AssemblyItem."No.");
        BOMComponent.Modify(true);
        exit(AssemblyItem."No.");
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        // Create a new Customer with Address and Application Method : Apply to Oldest.
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate(Address, 'Address: ' + Customer."No.");
        Customer.Validate("Phone No.", Format(LibraryRandom.RandIntInRange(100000000, 999999999)));
        Customer.Validate("Application Method", Customer."Application Method"::"Apply to Oldest");
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateCustomerWithLanguageCode(LanguageCode: Code[10]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Language Code", LanguageCode);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateCustomerWithDefaultGlobalDimValues(var Customer: Record Customer; var DimValueCode: array[2] of Code[20])
    var
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        i: Integer;
    begin
        LibrarySales.CreateCustomer(Customer);
        for i := 1 to 2 do begin
            LibraryDimension.CreateDimensionValue(DimensionValue, LibraryERM.GetGlobalDimensionCode(i));
            LibraryDimension.CreateDefaultDimensionCustomer(
              DefaultDimension, Customer."No.", DimensionValue."Dimension Code", DimensionValue.Code);
            DimValueCode[i] := DimensionValue.Code;
        end;
    end;

    local procedure CreateCustomerItemReferenceNo(var Customer: Record Customer; var Item: Record Item): Code[20]
    var
        ItemReference: Record "Item Reference";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateItem(Item);
        LibraryItemReference.CreateItemReference(
          ItemReference, Item."No.", ItemReference."Reference Type"::Customer, Customer."No.");
        exit(ItemReference."Reference No.");
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; CustomerNo: Code[20]; CurrencyCode: Code[10]; Amount: Decimal; PostingDate: Date)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        LibraryERM: Codeunit "Library - ERM";
    begin
        ClearGenJournalLine(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
          GenJournalLine."Account Type"::Customer, CustomerNo, Amount);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Modify(true);
    end;

    local procedure CreatePostGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; CustomerNo: Code[20]; CurrencyCode: Code[10]; Amount: Decimal; PostingDate: Date)
    var
        LibraryERM: Codeunit "Library - ERM";
    begin
        CreateGeneralJournalLine(GenJournalLine, DocumentType, CustomerNo, CurrencyCode, Amount, PostingDate);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure MockSalesOrderWithExternalDocumentNo(var SalesHeader: Record "Sales Header")
    begin
        SalesHeader."No." := LibraryUtility.GenerateGUID();
        SalesHeader."Document Type" := SalesHeader."Document Type"::Order;
        SalesHeader."External Document No." := LibraryUtility.GenerateGUID();
        SalesHeader.Insert();
    end;

    local procedure MockSalesInvoiceHeaderWithExternalDocumentNo(var SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        SalesInvoiceHeader."No." := LibraryUtility.GenerateGUID();
        SalesInvoiceHeader."External Document No." := LibraryUtility.GenerateGUID();
        SalesInvoiceHeader.Insert();
    end;

    local procedure MockSalesInvoiceLineWithJobNoAndJobTaskNo(var SalesInvoiceLine: Record "Sales Invoice Line"; SalesInvoiceHeaderNo: Code[20])
    begin
        SalesInvoiceLine."Document No." := SalesInvoiceHeaderNo;
        SalesInvoiceLine."Line No." := 10000;
        SalesInvoiceLine.Description := SalesInvoiceLine."Document No.";
        SalesInvoiceLine."Job No." := LibraryUtility.GenerateGUID();
        SalesInvoiceLine."Job Task No." := LibraryUtility.GenerateGUID();
        SalesInvoiceLine.Insert();
    end;

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; CurrencyCode: Code[10]; CustomerNo: Code[20])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Modify(true);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; CurrencyCode: Code[10]; CustomerNo: Code[20])
    begin
        CreateSalesHeader(SalesHeader, CurrencyCode, CustomerNo);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(1000, 2000, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesDocumentWithPaymentMethod(var SalesHeader: Record "Sales Header"; DocType: Enum "Sales Document Type"; PaymentMethodCode: Code[10]; CustNo: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesDocumentWithLine(SalesHeader, SalesLine, DocType, CustNo);
        SalesHeader.Validate("Payment Method Code", PaymentMethodCode);
        SalesHeader.Modify(true);
    end;

    local procedure CreateSalesDocumentWithLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Gen. Journal Document Type"; CustomerNo: Code[20])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(1000, 2000, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesQuoteWithLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; CustomerNo: Code[20])
    begin
        CreateSalesDocumentWithLine(SalesHeader, SalesLine, SalesHeader."Document Type"::Quote, CustomerNo);
    end;

    local procedure CreateSalesInvoiceWithLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; CustomerNo: Code[20])
    begin
        CreateSalesDocumentWithLine(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, CustomerNo);
    end;

    local procedure CreateSalesInvoiceWithThreeLinesWithVATBusPostingSetup(var SalesHeader: Record "Sales Header"; VATPostingSetup: array[3] of Record "VAT Posting Setup")
    var
        Customer: Record Customer;
        i: Integer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup[3]."VAT Bus. Posting Group");
        Customer.Modify(true);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        for i := 1 to ArrayLen(VATPostingSetup) do
            CreateSalesLineWithItemWithVATPostingSetup(SalesHeader, VATPostingSetup[i]);
    end;

    local procedure CreateSalesCreditMemoWithLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; CustomerNo: Code[20])
    begin
        CreateSalesDocumentWithLine(SalesHeader, SalesLine, SalesHeader."Document Type"::"Credit Memo", CustomerNo);
    end;

    local procedure CreateSalesOrderWithTwoLines(var CustomerNo: Code[20]; var ExpectedAmount: Decimal)
    var
        SalesHeader: Record "Sales Header";
        SalesLine1: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        ItemNo: Code[20];
    begin
        // Line Amount Incl. VAT = Line Amount Excl. VAT * (1 + VAT%).
        // Using hardcode of VAT% to leave out the third decimal places of Line Amount Incl. VAT
        CreateVATPostingGroup(VATPostingSetup, 19.6);
        CustomerNo := LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group");
        ItemNo := CreateItemWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group");
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);

        // Outstanding Order = Line Amount Incl. VAT(##0.00) / (1 + VAT%).
        // Using hardcode of Unit Price to leave out the third decimal places of Line Amount Incl. VAT when calculate Outstanding Order with VAT.
        CreateSalesLineWithVAT(SalesHeader, SalesLine1, ItemNo, 129);
        CreateSalesLineWithVAT(SalesHeader, SalesLine2, ItemNo, 79);
        ExpectedAmount := Round(SalesLine1.Amount * SalesLine1."Outstanding Quantity" / SalesLine1.Quantity) +
          Round(SalesLine2.Amount * SalesLine2."Outstanding Quantity" / SalesLine2.Quantity);
    end;

    local procedure CreateSalesInvoiceWithExternalDocNo(var SalesHeader: Record "Sales Header")
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomer());
        SalesHeader.Validate("External Document No.", CopyStr(LibraryUtility.GenerateRandomXMLText(35), 1, 35));
        SalesHeader.Modify(true);
    end;

    local procedure CreateSalesLineWithVAT(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ItemNo: Code[20]; UnitPrice: Decimal)
    begin
        // Using hardcode to make sure the third decimal places of Line Amount Incl. VAT can be left out
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, 1);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesLineWithItemWithVATPostingSetup(SalesHeader: Record "Sales Header"; VATPostingSetup: Record "VAT Posting Setup")
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDec(100, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreateCustomerWithCurrencyCode(var Customer: Record Customer)
    var
        Currency: Record Currency;
    begin
        LibraryERM.FindCurrency(Currency);
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Currency Code", Currency.Code);
        Customer.Modify(true);
    end;

    local procedure CreateCustomerWithPhoneAndFaxNo(var Customer: Record Customer)
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Phone No.", LibraryUtility.GenerateRandomNumericText(10));
        Customer.Validate("Fax No.", LibraryUtility.GenerateRandomNumericText(10));
        Customer.Modify(true);
    end;

    local procedure CreateVATPostingGroup(var VATPostingSetup: Record "VAT Posting Setup"; VATPercent: Decimal)
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
    begin
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        CreateVATPostingSetupWithAccountsForBusPostingGroup(VATPostingSetup, VATBusinessPostingGroup.Code, VATPercent);
    end;

    local procedure CreateVATPostingSetupWithAccountsForBusPostingGroup(var VATPostingSetup: Record "VAT Posting Setup"; VATBusPostingGroupCode: Code[20]; VATPercent: Decimal)
    var
        VATProdPostingGroup: Record "VAT Product Posting Group";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateVATProductPostingGroup(VATProdPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostingGroupCode, VATProdPostingGroup.Code);
        VATPostingSetup.Init();
        VATPostingSetup.Validate("VAT Identifier", 'VAT' + Format(VATPercent));
        VATPostingSetup.Validate("VAT %", VATPercent);
        VATPostingSetup.Validate("Sales VAT Account", GLAccount."No.");
        VATPostingSetup.Validate("Purchase VAT Account", GLAccount."No.");
        VATPostingSetup.Modify(true);
    end;

    local procedure CreateThreeVATPostingSetupsWithTwoVATClauses(var VATPostingSetup: array[3] of Record "VAT Posting Setup"; var VATClause: array[2] of Record "VAT Clause")
    var
        VATProductPostingGroup: array[2] of Record "VAT Product Posting Group";
        i: Integer;
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup[3], VATPostingSetup[3]."VAT Calculation Type"::"Normal VAT", 0);
        for i := 1 to ArrayLen(VATClause) do begin
            LibraryERM.CreateVATClause(VATClause[i]);
            LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup[i]);
            VATPostingSetup[i].Init();
            VATPostingSetup[i] := VATPostingSetup[3];
            VATPostingSetup[i].Validate("VAT Identifier", LibraryUtility.GenerateGUID());
            VATPostingSetup[i].Validate("VAT Prod. Posting Group", VATProductPostingGroup[i].Code);
            VATPostingSetup[i].Validate("VAT %", LibraryRandom.RandInt(10));
            VATPostingSetup[i].Validate("VAT Clause Code", VATClause[i].Code);
            VATPostingSetup[i].Insert(true);
        end;
    end;

    local procedure CreateItemWithVATProdPostingGroup(VATProdPostingGroupCode: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroupCode);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateItemWithAssemblyComponents(var Item: Record Item; var ItemComponentCode: array[3] of Code[20])
    var
        ItemJournalLine: Record "Item Journal Line";
        Index: Integer;
    begin
        LibraryAssembly.CreateItem(Item, Item."Costing Method"::FIFO, Item."Replenishment System"::Assembly, '', '');
        Item.Validate("Assembly Policy", Item."Assembly Policy"::"Assemble-to-Order");
        Item.Validate(Description, LibraryUtility.GenerateGUID());
        Item.Modify(true);
        for Index := 1 to ArrayLen(ItemComponentCode) do begin
            ItemComponentCode[Index] := CreateAssemblyComponent(Item."No.");
            CreateAndPostItemJournalLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemComponentCode[Index]);
        end;
    end;

    local procedure CreateGlobalDimValues(var GlobalDim1Value: Code[20]; var GlobalDim2Value: Code[20])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        DimensionValue: Record "Dimension Value";
    begin
        GeneralLedgerSetup.Get();
        LibraryDimension.CreateDimensionValue(DimensionValue, GeneralLedgerSetup."Global Dimension 1 Code");
        GlobalDim1Value := DimensionValue.Code;
        LibraryDimension.CreateDimensionValue(DimensionValue, GeneralLedgerSetup."Global Dimension 2 Code");
        GlobalDim2Value := DimensionValue.Code;
    end;

    local procedure CreatePostGeneralJournalLineWithDueDate(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; CustomerNo: Code[20]; CurrencyCode: Code[10]; Amount: Decimal; PostingDate: Date; DueDate: Date)
    var
        LibraryERM: Codeunit "Library - ERM";
    begin
        CreateGeneralJournalLine(GenJournalLine, DocumentType, CustomerNo, CurrencyCode, Amount, PostingDate);
        GenJournalLine.Validate("Due Date", DueDate);
        GenJournalLine.Modify();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateCurrencyWithFixedExchRates(RelExchRateAmount: Decimal): Code[10]
    var
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.SetCurrencyGainLossAccounts(Currency);
        LibraryERM.CreateExchRate(CurrencyExchangeRate, Currency.Code, WorkDate());
        CurrencyExchangeRate.Validate("Exchange Rate Amount", 1);
        CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", 1);
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", RelExchRateAmount);
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", RelExchRateAmount);
        CurrencyExchangeRate.Modify(true);
        exit(Currency.Code);
    end;

    local procedure CreateShipmentMethod(var ShipmentMethod: Record "Shipment Method")
    begin
        ShipmentMethod.Init();
        ShipmentMethod.Code := LibraryUtility.GenerateRandomCode(ShipmentMethod.FieldNo(Code), DATABASE::"Shipment Method");
        ShipmentMethod.Description := LibraryUtility.GenerateGUID();
        ShipmentMethod.Insert(true);
    end;

    local procedure ReleaseSalesOrder(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20])
    begin
        SalesHeader.SetRange("Document Type", DocumentType);
        SalesHeader.SetRange("Sell-to Customer No.", CustomerNo);
        SalesHeader.FindFirst();
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure ConvertCurrency(Amount: Decimal; CurrencyCode: Code[10]): Decimal
    begin
        exit(Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode, '', WorkDate())));
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20])
    begin
        SalesLine.SetRange("Document Type", DocumentType);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.FindFirst();
    end;

    local procedure FindGLEntry(DocumentNo: Code[20]): Integer
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.FindLast();
        exit(GLEntry."Transaction No.");
    end;

    local procedure GetCustomerBalanceLCY() TotalBalance: Decimal
    var
        Customer: Record Customer;
    begin
        TotalBalance := 0;
        Customer.SetFilter("Balance (LCY)", '>0');
        if Customer.FindSet() then
            repeat
                Customer.CalcFields("Balance (LCY)");
                TotalBalance += Customer."Balance (LCY)";
            until Customer.Next() = 0;
    end;

    local procedure GetCustomerSalesLCY() TotalSalesLCY: Decimal
    var
        Customer: Record Customer;
    begin
        TotalSalesLCY := 0;
        Customer.SetFilter("Sales (LCY)", '>0');
        if Customer.FindSet() then
            repeat
                Customer.CalcFields("Sales (LCY)");
                TotalSalesLCY += Customer."Sales (LCY)";
            until Customer.Next() = 0;
    end;

    local procedure GetPostingDate(): Date
    var
        DateComprRegister: Record "Date Compr. Register";
    begin
        DateComprRegister.SetCurrentKey("Table ID", "Ending Date");
        DateComprRegister.SetRange("Table ID", DATABASE::"G/L Entry");
        if DateComprRegister.FindLast() then
            exit(CalcDate('<1D>', DateComprRegister."Ending Date")); // Next Day
        exit(WorkDate());
    end;

    local procedure CreatePostDebitCreditJournalLines(var DebitAmount: Decimal; var CreditAmount: Decimal; CustomerNo: Code[20]): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        DebitAmount := LibraryRandom.RandDec(1000, 2);
        CreditAmount := -LibraryRandom.RandDec(1000, 2);
        PostJournalLines(GenJournalLine, CustomerNo, DebitAmount, CreditAmount);
        exit(GenJournalLine."Account No.");
    end;

    local procedure CreateDebitCreditJournalLines(var GenJournalLine: Record "Gen. Journal Line"; CustomerNo: Code[20]; DebitAmount: Decimal; CreditAmount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        ClearGenJournalLine(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Customer, CustomerNo, DebitAmount);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Customer, CustomerNo, CreditAmount);
    end;

    local procedure CreateDebitCreditJournalLinesWithDimensions(var GenJournalLine: Record "Gen. Journal Line"; CustomerNo: Code[20]; DebitAmount: Decimal; CreditAmount: Decimal; Dimension1Value: Code[20]; Dimension2Value: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        ClearGenJournalLine(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Customer, CustomerNo, DebitAmount);
        UpdateGenJnlLineDim(GenJournalLine, Dimension1Value, Dimension2Value);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Customer, CustomerNo, CreditAmount);
        UpdateGenJnlLineDim(GenJournalLine, Dimension1Value, Dimension2Value);
    end;

    local procedure CreateVATClauseTranslation(var VATClauseTranslation: Record "VAT Clause Translation"; VATClauseCode: Code[20]; LanguageCode: Code[10])
    begin
        VATClauseTranslation.Validate("VAT Clause Code", VATClauseCode);
        VATClauseTranslation.Validate("Language Code", LanguageCode);
        VATClauseTranslation.Validate(Description, LibraryUtility.GenerateGUID());
        VATClauseTranslation.Validate("Description 2", LibraryUtility.GenerateGUID());
        VATClauseTranslation.Insert(true);
    end;

    local procedure UpdateGenJnlLineDim(var GenJournalLine: Record "Gen. Journal Line"; Dimension1Value: Code[20]; Dimension2Value: Code[20])
    begin
        GenJournalLine.Validate("Shortcut Dimension 1 Code", Dimension1Value);
        GenJournalLine.Validate("Shortcut Dimension 2 Code", Dimension2Value);
        GenJournalLine.Modify();
    end;

    local procedure UpdateGlobalDims()
    var
        Dimension: array[2] of Record Dimension;
    begin
        if (LibraryERM.GetGlobalDimensionCode(1) = '') or (LibraryERM.GetGlobalDimensionCode(2) = '') then begin
            LibraryDimension.CreateDimension(Dimension[1]);
            LibraryDimension.CreateDimension(Dimension[2]);
            LibraryDimension.RunChangeGlobalDimensions(Dimension[1].Code, Dimension[2].Code);
        end;
    end;

    local procedure PostJournalLines(var GenJournalLine: Record "Gen. Journal Line"; CustomerNo: Code[20]; DebitAmount: Decimal; CreditAmount: Decimal)
    begin
        CreateDebitCreditJournalLines(GenJournalLine, CustomerNo, DebitAmount, CreditAmount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure PostShipReceiveOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocType: Enum "Sales Document Type")
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocType, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(100));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
    end;

    local procedure ReverseTransaction(TransactionNo: Integer)
    var
        ReversalEntry: Record "Reversal Entry";
    begin
        LibraryVariableStorage.Enqueue(SuccessfullyReversedMessageMsg);
        ReversalEntry.SetHideDialog(true);
        ReversalEntry.ReverseTransaction(TransactionNo);
    end;

    local procedure ApplyPaymentToAllOpenInvoices(PmtNo: Code[20]; CustNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
        ApplyingCustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(
          ApplyingCustLedgerEntry, GenJournalLine."Document Type"::Payment, PmtNo);
        ApplyingCustLedgerEntry.CalcFields("Remaining Amount");
        LibraryERM.SetApplyCustomerEntry(ApplyingCustLedgerEntry, ApplyingCustLedgerEntry."Remaining Amount");
        CustLedgerEntry.SetRange("Customer No.", CustNo);
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
        CustLedgerEntry.SetRange(Open, true);
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry);
        LibraryERM.PostCustLedgerApplication(ApplyingCustLedgerEntry);
    end;

    local procedure RunAndVerifyCustomerRegister(DocumentNo: Code[20]; OriginalAmountLCY: Decimal)
    begin
        // Exercise: Generate the Customer Register report.
        REPORT.Run(REPORT::"Customer Register");

        // Verify: Check that the value of Original Amount in Customer Register is equal to the value of Amount in
        // corresponding General Journal Line.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('Cust__Ledger_Entry__Document_No__', DocumentNo);
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFoundErr, 'Cust__Ledger_Entry__Document_No__', DocumentNo);
        LibraryReportDataset.AssertCurrentRowValueEquals('CustAmount', OriginalAmountLCY);
    end;

    local procedure RunAndVerifyCustomerTrialBal(GenJournalLine: Record "Gen. Journal Line"; AmountLCY: Decimal)
    begin
        // Exercise: Generate the Customer Detail Trial Balance Report.
        REPORT.Run(REPORT::"Customer - Detail Trial Bal.");

        // Verify: Check that the value of Amount in Customer Detail Trial Balance is equal to the value of Amount in
        // corresponding General Journal Line.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('DocNo_CustLedgEntry', GenJournalLine."Document No.");
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFoundErr, 'DocNo_CustLedgEntry', GenJournalLine."Document No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('CustLedgerEntryAmtLCY', AmountLCY);
        LibraryReportDataset.AssertCurrentRowValueEquals('CustBalanceLCY', AmountLCY);
    end;

    local procedure RunCustomerDetailedAging(GenJournalLine: Record "Gen. Journal Line")
    begin
        // Enqueue values for CustomerDetailedAgingRequestPageHandler.
        LibraryVariableStorage.Enqueue(GenJournalLine."Due Date");
        LibraryVariableStorage.Enqueue(GenJournalLine."Account No.");

        // Run Customer Detailed Aging Report.
        REPORT.Run(REPORT::"Customer Detailed Aging");
    end;

    local procedure RunCustomerSummaryAgingReport(CustomerNo: Code[20]; ShowAmountInLCY: Boolean)
    var
        Customer: Record Customer;
        CustomerSummaryAging: Report "Customer - Summary Aging";
    begin
        Customer.SetRange("No.", CustomerNo);
        CustomerSummaryAging.SetTableView(Customer);
        CustomerSummaryAging.InitializeRequest(WorkDate(), StrSubstNo('<%1M>', LibraryRandom.RandInt(5)), ShowAmountInLCY);
        Commit();
        CustomerSummaryAging.RunModal();
    end;

    local procedure RunAndVerifyCustSummaryAging(CustomerNo: Code[20]; ShowAmountLCY: Boolean; BalanceLCY: Decimal)
    begin
        // Exercise: Generate the Customer Summary Aging Report.
        RunCustomerSummaryAgingReport(CustomerNo, ShowAmountLCY);

        // Verify: Check that the value of Balance in Customer Summary Aging is equal to the value of Amount in
        // corresponding General Journal Line.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('Customer_No_', CustomerNo);
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFoundErr, 'Customer_No_', CustomerNo);
        LibraryReportDataset.AssertCurrentRowValueEquals('TotalCustBalanceLCY', BalanceLCY);
        LibraryReportDataset.AssertCurrentRowValueEquals('CustBalanceDueLCY_3_', 0);
    end;

    local procedure RunCustomerOrderDetailReport(SellToCustomerNo: Code[20]; ShowAmountInLCY: Boolean)
    var
        Customer: Record Customer;
    begin
        LibraryVariableStorage.Enqueue(ShowAmountInLCY);
        LibraryVariableStorage.Enqueue(false);
        Customer.SetRange("No.", SellToCustomerNo);
        Commit();  // Due to limitation in page testability, commit is needed in this test case.
        REPORT.Run(REPORT::"Customer - Order Detail", true, false, Customer);
    end;

    local procedure RunCustomerOrderSummaryReport(var Customer: Record Customer)
    begin
        Customer.SetRange("No.", Customer."No.");
        Commit(); // Due to limitation in page testability, commit is needed in this test case.
        REPORT.Run(REPORT::"Customer - Order Summary", true, false, Customer);
    end;

    local procedure RunCustOrderSummaryReport(SellToCustomerNo: Code[20]; ShowAmountLCY: Boolean)
    var
        Customer: Record Customer;
    begin
        LibraryVariableStorage.Enqueue(WorkDate());
        LibraryVariableStorage.Enqueue(ShowAmountLCY);
        Customer.SetRange("No.", SellToCustomerNo);
        Commit();  // Due to limitation in page testability, commit is needed in this test case.
        REPORT.Run(REPORT::"Customer - Order Summary", true, false, Customer);
    end;

    local procedure RunCustomerTrialBalanceReportForCY(CustomerNo: Code[20]; Dim1Filter: Code[20]; Dim2Filter: Code[20])
    var
        Customer: Record Customer;
    begin
        Customer.SetRange("No.", CustomerNo);
        Customer.SetRange("Date Filter", CalcDate('<-CY>', WorkDate()), CalcDate('<CY>', WorkDate()));
        Customer.SetFilter("Global Dimension 1 Filter", Dim1Filter);
        Customer.SetFilter("Global Dimension 2 Filter", Dim2Filter);
        REPORT.Run(REPORT::"Customer - Trial Balance", true, false, Customer);
    end;

    local procedure RunCustomerListReport(var Customer: Record Customer)
    begin
        Commit();
        Customer.SetRange("No.", Customer."No.");
        REPORT.Run(REPORT::"Customer - List", true, false, Customer);
    end;

    local procedure RunStandardSalesOrderConfirmationReport(SalesHeaderNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        Commit();
        SalesHeader.SetRange("No.", SalesHeaderNo);
        REPORT.Run(REPORT::"Standard Sales - Order Conf.", true, false, SalesHeader);
    end;

    local procedure RunStandardSalesInvoiceReport(PostedSalesInvoiceNo: Code[20])
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        Commit();
        SalesInvoiceHeader.SetRange("No.", PostedSalesInvoiceNo);
        REPORT.Run(REPORT::"Standard Sales - Invoice", true, false, SalesInvoiceHeader);
    end;

    local procedure RunStandardSalesCreditMemoReport(PostedSalesCrMemoNo: Code[20])
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        Commit();
        SalesCrMemoHeader.SetRange("No.", PostedSalesCrMemoNo);
        REPORT.Run(REPORT::"Standard Sales - Credit Memo", true, false, SalesCrMemoHeader);
    end;

    local procedure RunStandardSalesQuoteReport(SalesQuoteNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        Commit();
        SalesHeader.SetRange("No.", SalesQuoteNo);
        REPORT.Run(REPORT::"Standard Sales - Quote", true, false, SalesHeader);
    end;

    local procedure RunDtldCustTrialBalanceReportWithDateFilter(CustNo: Code[20])
    var
        Customer: Record Customer;
    begin
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(CustNo);
        Commit();
        Customer.Get(CustNo);
        Customer.SetRecFilter();
        Customer.SetFilter("Date Filter", '%1..', WorkDate());
        REPORT.Run(REPORT::"Customer - Detail Trial Bal.", true, false, Customer);
    end;

    local procedure SelectItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch"; ItemJournalTemplateType: Enum "Item Journal Template Type")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplateType);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplateType, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
    end;

    local procedure SaveStatementReport(CustomerNo: Code[20]; PostingDate: Date; PrintOverdueEntries: Boolean; PrintReversedEntries: Boolean; PrintUnappliedEntries: Boolean; IncludeAgingBand: Boolean; PeriodLength: DateFormula)
    var
        Customer: Record Customer;
        Statement: Report Statement;
        DateChoice: Option "Due Date","Posting Date";
    begin
        Clear(Statement);
        Customer.SetRange("No.", CustomerNo);

        // Using 1 because Date Filter has to be set for two consecutive Years.
        Statement.SetTableView(Customer);
        Statement.InitializeRequest(
          PrintOverdueEntries, true, false, PrintReversedEntries, PrintUnappliedEntries, IncludeAgingBand,
          Format(PeriodLength), DateChoice::"Posting Date", false, DMY2Date(1, 1, Date2DMY(PostingDate, 3)),
          DMY2Date(31, 12, Date2DMY(CalcDate('<1Y>', PostingDate), 3)));
        Commit();
        Statement.Run();
    end;

    local procedure SetRDLCReportLayout(ReportID: Integer)
    var
        ReportLayoutSelection: Record "Report Layout Selection";
        TenantReportLayoutSelection: Record "Tenant Report Layout Selection";
    begin
        ReportLayoutSelection.SetRange("Report ID", ReportID);
        ReportLayoutSelection.SetRange("Company Name", CompanyName);
        if ReportLayoutSelection.FindFirst() then begin
            ReportLayoutSelection.Type := ReportLayoutSelection.Type::"RDLC (built-in)";
            ReportLayoutSelection."Custom Report Layout Code" := '';
            ReportLayoutSelection.Modify();
        end else begin
            ReportLayoutSelection."Report ID" := ReportID;
            ReportLayoutSelection."Company Name" := CompanyName;
            ReportLayoutSelection.Type := ReportLayoutSelection.Type::"RDLC (built-in)";
            ReportLayoutSelection."Custom Report Layout Code" := '';
            ReportLayoutSelection.Insert();
        end;

        TenantReportLayoutSelection.Init();
        TenantReportLayoutSelection."Company Name" := CompanyName();
        TenantReportLayoutSelection."Layout Name" := ReportLayoutSelection."Report Name";
        TenantReportLayoutSelection."Report ID" := ReportID;
        if not TenantReportLayoutSelection.Insert(true) then
            TenantReportLayoutSelection.Modify(true);
    end;

    local procedure UnapplyCustLedgerEntry(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocumentType, DocumentNo);
        LibraryERM.UnapplyCustomerLedgerEntry(CustLedgerEntry);
    end;

    local procedure CreateCurrencyWithDecimalPlaces(): Code[10]
    var
        Currency: Record Currency;
        CurrencyCode: Code[10];
    begin
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 1, 1);
        Currency.Get(CurrencyCode);
        Currency.Validate("Amount Decimal Places", '3:3');
        Currency.Validate("Amount Rounding Precision", 0.001);
        Currency.Modify(true);
        exit(CurrencyCode);
    end;

    local procedure VerifyAmtInDtldCustLedgEntries(RowCaption: Text; RowValue: Text; Amount: Decimal)
    begin
        LibraryReportDataset.SetRange(RowCaption, RowValue);
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFoundErr, RowCaption, RowValue);
        LibraryReportDataset.AssertCurrentRowValueEquals('Amt_DtldCustLedgEntries', Amount);
    end;

    local procedure VerifyAmountInMultipleRows(DocumentNo: Code[20]; Amount: Decimal)
    begin
        VerifyAmtInDtldCustLedgEntries('DocNo_DtldCustLedgEntries', DocumentNo, Amount);
        VerifyAmtInDtldCustLedgEntries('CustBalance', '0', -Amount);
    end;

    local procedure VerifyLineAmtCustomerOrderDetailReport(SalesLineNo: Code[20]; LineAmount: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_SalesLine', SalesLineNo);
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFoundErr, 'No_SalesLine', SalesLineNo);
        LibraryReportDataset.AssertCurrentRowValueEquals('SalesOrderAmount', LineAmount);
    end;

    local procedure VerifyTotalLCYOnCustomerSummaryAgingReport(Customer: Record Customer)
    begin
        Customer.CalcFields("Balance (LCY)");
        LibraryReportDataset.SetRange('Total_LCY_Caption', TotalCaptionLbl);
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFoundErr, 'Total_LCY_Caption', TotalCaptionLbl);
        LibraryReportDataset.AssertCurrentRowValueEquals('TotalCustBalanceLCY', Customer."Balance (LCY)");
    end;

    local procedure VerifyTotalLCYOnCustomerOrderSummary(ExpectedTotalLCY: Decimal)
    begin
        LibraryReportDataset.SetRange('TotalCaption', ColumnTotalLbl);
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFoundErr, 'TotalCaption', ColumnTotalLbl);
        LibraryReportDataset.AssertCurrentRowValueEquals('SalesOrderAmountLCY', Round(ExpectedTotalLCY, 0.01));
    end;

    local procedure VerifyCustomerDetailedAging(DocumentNo: Code[20]; DueDate: Date)
    begin
        LibraryReportDataset.SetRange(DocumentNoLbl, DocumentNo);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals(DueDateLbl, Format(DueDate));
    end;

    local procedure VerifyCustOrderSummary(SalesLine: Record "Sales Line"; CurrencyFactor: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_Cust', SalesLine."Sell-to Customer No.");
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFoundErr, 'No_Cust', SalesLine."Sell-to Customer No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('SalesAmtOnOrderLCY1', 0);
        if CurrencyFactor = 0 then
            CurrencyFactor := 1;
        LibraryReportDataset.AssertCurrentRowValueEquals('SalesOrderAmountLCY', Round(SalesLine."Line Amount" / CurrencyFactor));
    end;

    local procedure VerifyOverDueEntry(PostingDate: Date; Amount: Decimal)
    begin
        LibraryReportDataset.SetRange('OverDueEntries', OverdueEntriesLbl);
        VerifyRemainAmtInCustLedgEntry(PostingDate, Amount);
    end;

    local procedure VerifyRemainAmtInCustLedgEntry(PostingDate: Date; Amount: Decimal)
    begin
        LibraryReportDataset.SetRange('PostDate_CustLedgEntry2', Format(PostingDate));
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFoundErr, 'PostDate_CustLedgEntry2', Format(PostingDate));
        LibraryReportDataset.AssertCurrentRowValueEquals('RemainAmt_CustLedgEntry2', Amount);
    end;

    local procedure VerifyTotalOnCustomerOrderDetailReport(CustomerNo: Code[20]; ExpectedTotal: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_Customer', CustomerNo);
        LibraryReportDataset.AssertElementWithValueExists('TotalAmt_CurrTotalBuff', ExpectedTotal);
    end;

    local procedure VerifyOutstandingOrdersAndTotalOnCustomerOrderDetailReport(SalesLine: Record "Sales Line"; CustomerNo: Code[20]; ExpectedTotal: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_Customer', CustomerNo);
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFoundErr, 'No_Customer', CustomerNo);
        LibraryReportDataset.AssertCurrentRowValueEquals('SalesOrderAmount', SalesLine.Amount);
        LibraryReportDataset.GetNextRow();
        SalesLine.Next();
        LibraryReportDataset.AssertCurrentRowValueEquals('SalesOrderAmount', SalesLine.Amount);
        LibraryReportDataset.AssertElementWithValueExists('TotalAmt_CurrTotalBuff', ExpectedTotal);
    end;

    local procedure VerifyCustomerTrialBalanceDCAmounts(CustomerNo: Code[20]; DebitAmount: Decimal; CreditAmount: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_Customer', CustomerNo);
        Assert.IsTrue(
          LibraryReportDataset.GetNextRow(),
          StrSubstNo(RowNotFoundErr, 'No_Customer', CustomerNo));
        LibraryReportDataset.AssertCurrentRowValueEquals('PeriodDebitAmt', DebitAmount);
        LibraryReportDataset.AssertCurrentRowValueEquals('PeriodCreditAmt', CreditAmount);
    end;

    local procedure VerifyCustomerOrderSummarySalesAmount(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        ExpectedAmount: Decimal;
    begin
        ExpectedAmount := CurrencyExchangeRate.ExchangeAmtFCYToLCY(
            WorkDate(), SalesLine."Currency Code", SalesLine."Unit Price", SalesHeader."Currency Factor");

        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_Cust', SalesHeader."Sell-to Customer No.");

        Assert.IsTrue(LibraryReportDataset.GetNextRow(), StrSubstNo(RowNotFoundErr, 'No_Cust', SalesHeader."Sell-to Customer No."));
        LibraryReportDataset.AssertCurrentRowValueEquals('SalesOrderAmountLCY', ExpectedAmount);
    end;

    local procedure VerifyNoOfWorksheetsInExcel(WorksheetsNumber: Integer)
    begin
        LibraryReportValidation.OpenExcelFile();
        Assert.AreEqual(WorksheetsNumber, LibraryReportValidation.CountWorksheets(), ExcelCountWorksheetsErr);
    end;

    local procedure VerifyDueMonthsForDueDate(DueDate: Date; DueMonths: Integer)
    begin
        LibraryReportDataset.MoveToRow(LibraryReportDataset.FindRow('Cust_Ledger_Entry_Due_Date_', Format(DueDate)) + 1);
        LibraryReportDataset.AssertCurrentRowValueEquals('OverDueMonths', DueMonths);
    end;

    local procedure VerifyVATClauseShouldBePrintOnlyOnce(VATClause: Record "VAT Clause")
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementTagWithValueExists(
            DescriptionVATClauseLineLbl, VATClause.Description + ' ' + VATClause."Description 2");

        LibraryReportDataset.GetNextRow();
        asserterror LibraryReportDataset.AssertElementTagWithValueExists(
            DescriptionVATClauseLineLbl, VATClause.Description + ' ' + VATClause."Description 2");
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        // Handler for confirmation messages, always send positive reply.
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    var
        ActualMessage: Variant;
    begin
        LibraryVariableStorage.Dequeue(ActualMessage);
        Assert.AreEqual(Message, Format(ActualMessage), UnexpectedMessageMsg);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure SimpleMessageHandler(Message: Text[1024])
    begin
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerDetailedAgingRequestPageHandler(var CustomerDetailedAging: TestRequestPage "Customer Detailed Aging")
    var
        CustomerNo: Variant;
        EndDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(EndDate);  // Dequeue variable.
        LibraryVariableStorage.Dequeue(CustomerNo);  // Dequeue variable.
        CustomerDetailedAging."Ending Date".SetValue(EndDate);
        CustomerDetailedAging.ShowOpenEntriesOnly.SetValue(false);  // Setting Show Open Entries Only boolean.
        CustomerDetailedAging.Customer.SetFilter("No.", CustomerNo);
        CustomerDetailedAging.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerListRequestPageHandler(var CustomerList: TestRequestPage "Customer - List")
    begin
        CustomerList.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerSummaryAgingSimpRequestPageHandler(var CustomerSummaryAgingSimp: TestRequestPage "Customer - Summary Aging Simp.")
    var
        CustomerNo: Variant;
        WorkingDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(WorkingDate);
        LibraryVariableStorage.Dequeue(CustomerNo);
        CustomerSummaryAgingSimp.StartingDate.SetValue(WorkingDate);
        CustomerSummaryAgingSimp.Customer.SetFilter("No.", CustomerNo);
        CustomerSummaryAgingSimp.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustSummaryAgingSimpRequestPageHandler(var CustomerSummaryAgingSimp: TestRequestPage "Customer - Summary Aging Simp.")
    var
        StartDate: Variant;
        BalanceDue: Variant;
    begin
        LibraryVariableStorage.Dequeue(StartDate);
        LibraryVariableStorage.Dequeue(BalanceDue);
        CustomerSummaryAgingSimp.StartingDate.SetValue(StartDate);
        CustomerSummaryAgingSimp.Customer.SetFilter("Balance Due", BalanceDue);
        CustomerSummaryAgingSimp.Customer.SetFilter("No.", '');
        CustomerSummaryAgingSimp.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerTopTenListRequestPageHandler(var CustomerTop10List: TestRequestPage "Customer - Top 10 List")
    var
        CustomerNo: Variant;
        ShowType: Variant;
    begin
        LibraryVariableStorage.Dequeue(ShowType);
        LibraryVariableStorage.Dequeue(CustomerNo);
        CustomerTop10List.Show.SetValue(ShowType);
        CustomerTop10List.Customer.SetFilter("No.", CustomerNo);
        CustomerTop10List.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerTrialBalanceRequestPageHandler(var CustomerTrialBalance: TestRequestPage "Customer - Trial Balance")
    begin
        CustomerTrialBalance.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerOrderDetailRequestPageHandler(var CustomerOrderDetail: TestRequestPage "Customer - Order Detail")
    var
        ShowAmountInLCY: Variant;
        PrintOnlyPerPage: Variant;
    begin
        LibraryVariableStorage.Dequeue(ShowAmountInLCY);
        LibraryVariableStorage.Dequeue(PrintOnlyPerPage);
        CustomerOrderDetail.ShowAmountsInLCY.SetValue(ShowAmountInLCY);
        CustomerOrderDetail.NewPagePerCustomer.SetValue(PrintOnlyPerPage);
        CustomerOrderDetail.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerOrderSummaryRequestPageHandler(var CustomerOrderSummary: TestRequestPage "Customer - Order Summary")
    var
        StartingDate: Variant;
        ShowAmountLCY: Variant;
    begin
        LibraryVariableStorage.Dequeue(StartingDate);
        LibraryVariableStorage.Dequeue(ShowAmountLCY);
        CustomerOrderSummary.StartingDate.SetValue(StartingDate);
        CustomerOrderSummary.ShwAmtinLCY.SetValue(ShowAmountLCY);
        CustomerOrderSummary.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustOrderSummaryRequestPageHandler(var CustomerOrderSummary: TestRequestPage "Customer - Order Summary")
    var
        StartingDate: Variant;
        ShowAmountLCY: Variant;
    begin
        LibraryVariableStorage.Dequeue(StartingDate);
        LibraryVariableStorage.Dequeue(ShowAmountLCY);
        CustomerOrderSummary.StartingDate.SetValue(StartingDate);
        CustomerOrderSummary.ShwAmtinLCY.SetValue(ShowAmountLCY);
        CustomerOrderSummary.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerOrderSummaryExcelRequestPageHandler(var CustomerOrderSummary: TestRequestPage "Customer - Order Summary")
    var
        StartingDate: Variant;
        ShowAmountLCY: Variant;
    begin
        LibraryVariableStorage.Dequeue(StartingDate);
        LibraryVariableStorage.Dequeue(ShowAmountLCY);
        CustomerOrderSummary.StartingDate.SetValue(StartingDate);
        CustomerOrderSummary.ShwAmtinLCY.SetValue(ShowAmountLCY);
        CustomerOrderSummary.SaveAsExcel(LibraryReportValidation.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerRegisterRequestPageHandler(var CustomerRegister: TestRequestPage "Customer Register")
    var
        ShowAmountLCY: Variant;
        EntryNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(ShowAmountLCY);
        LibraryVariableStorage.Dequeue(EntryNo);
        CustomerRegister.ShowAmountsInLCY.SetValue(ShowAmountLCY);
        CustomerRegister."G/L Register".SetFilter("To Entry No.", Format(EntryNo));
        CustomerRegister.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerDetailTrialBalanceRequestPageHandler(var CustomerDetailTrialBal: TestRequestPage "Customer - Detail Trial Bal.")
    var
        ShowAmountLCY: Variant;
        SetPrintOnlyOnePerPage: Variant;
        SetExcludeBalanceOnly: Variant;
        AccountNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(ShowAmountLCY);
        LibraryVariableStorage.Dequeue(SetPrintOnlyOnePerPage);
        LibraryVariableStorage.Dequeue(SetExcludeBalanceOnly);
        LibraryVariableStorage.Dequeue(AccountNo);
        CustomerDetailTrialBal.ShowAmountsInLCY.SetValue(ShowAmountLCY);
        CustomerDetailTrialBal.NewPageperCustomer.SetValue(SetPrintOnlyOnePerPage);
        CustomerDetailTrialBal.ExcludeCustHaveaBalanceOnly.SetValue(SetExcludeBalanceOnly);
        CustomerDetailTrialBal.Customer.SetFilter("No.", AccountNo);
        CustomerDetailTrialBal.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerDetailTrialBalanceExcelRequestPageHandler(var CustomerDetailTrialBal: TestRequestPage "Customer - Detail Trial Bal.")
    begin
        CustomerDetailTrialBal.ShowAmountsInLCY.SetValue(LibraryVariableStorage.DequeueDecimal());
        CustomerDetailTrialBal.NewPageperCustomer.SetValue(LibraryVariableStorage.DequeueBoolean());
        CustomerDetailTrialBal.ExcludeCustHaveaBalanceOnly.SetValue(LibraryVariableStorage.DequeueBoolean());
        CustomerDetailTrialBal.Customer.SetFilter("No.", LibraryVariableStorage.DequeueText());
        CustomerDetailTrialBal.SaveAsExcel(LibraryReportValidation.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerItemSalesEmptyRequestPageHandler(var CustomerItemSales: TestRequestPage "Customer/Item Sales")
    var
        SellToCustomerNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(SellToCustomerNo);
        CustomerItemSales.Customer.SetFilter("No.", SellToCustomerNo);
        CustomerItemSales.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerItemSalesRequestPageHandler(var CustomerItemSales: TestRequestPage "Customer/Item Sales")
    begin
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerSalesListRequestPageHandler(var CustomerSalesList: TestRequestPage "Customer - Sales List")
    var
        CustomerNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(CustomerNo);
        CustomerSalesList.Customer.SetFilter("No.", CustomerNo);
        CustomerSalesList.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerSummaryAgingRequestPageHandler(var CustomerSummaryAging: TestRequestPage "Customer - Summary Aging")
    begin
        CustomerSummaryAging.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustSummaryAgingRequestPageHandler(var CustomerSummaryAging: TestRequestPage "Customer - Summary Aging")
    var
        StartDate: Variant;
        BalanceDue: Variant;
    begin
        LibraryVariableStorage.Dequeue(StartDate);
        LibraryVariableStorage.Dequeue(BalanceDue);
        CustomerSummaryAging.StartingDate.SetValue(StartDate);
        CustomerSummaryAging.Customer.SetFilter("Balance Due", BalanceDue);
        CustomerSummaryAging.Customer.SetFilter("No.", '');
        CustomerSummaryAging.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StatementReportRequestPageHandler(var Statement: TestRequestPage Statement)
    begin
        Statement.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName())
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure DraftSalesInvoiceRequestPageHandler(var StandardSalesDraftInvoice: TestRequestPage "Standard Sales - Draft Invoice")
    begin
        StandardSalesDraftInvoice.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure DraftSalesInvoiceExcelRequestPageHandler(var StandardSalesDraftInvoice: TestRequestPage "Standard Sales - Draft Invoice")
    begin
        StandardSalesDraftInvoice.SaveAsExcel(LibraryReportValidation.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StandardSalesOrderConfRequestPageHandler(var StandardSalesOrderConf: TestRequestPage "Standard Sales - Order Conf.")
    begin
        StandardSalesOrderConf.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StandardSalesOrderConfExcelRequestPageHandler(var StandardSalesOrderConf: TestRequestPage "Standard Sales - Order Conf.")
    var
        ShowAssemblyComponents: Boolean;
    begin
        ShowAssemblyComponents := LibraryVariableStorage.DequeueBoolean();
        StandardSalesOrderConf.DisplayAsmInformation.SetValue(ShowAssemblyComponents);
        StandardSalesOrderConf.SaveAsExcel(LibraryReportValidation.GetFileName());
    end;

    local procedure VerifySalesInvoiceMultipleVATClausesPrinted(VATPostingSetup: array[3] of Record "VAT Posting Setup"; VATClause: array[2] of Record "VAT Clause")
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementTagWithValueExists('VATClauses_Lbl', 'VAT Clause');
        LibraryReportDataset.AssertElementTagWithValueExists('VATIdentifier_Lbl', 'VAT Identifier');

        LibraryReportDataset.AssertElementTagWithValueExists('VATIdentifier_Line', VATPostingSetup[1]."VAT Identifier");
        LibraryReportDataset.AssertElementTagWithValueExists(
          'Description_VATClauseLine', VATClause[1].Description + ' ' + VATClause[1]."Description 2");

        LibraryReportDataset.AssertElementTagWithValueExists('VATIdentifier_Line', VATPostingSetup[2]."VAT Identifier");
        LibraryReportDataset.AssertElementTagWithValueExists(
          'Description_VATClauseLine', VATClause[2].Description + ' ' + VATClause[2]."Description 2");
    end;

    local procedure VerifyExcelWithItemAssemblyComponents(ItemComponentCode: array[3] of Code[20])
    var
        RowNo: Integer;
        ColNo: Integer;
        Index: Integer;
    begin
        LibraryReportValidation.OpenExcelFile();
        for Index := 1 to ArrayLen(ItemComponentCode) do begin
            LibraryReportValidation.FindRowNoColumnNoByValueOnWorksheet(ItemComponentCode[Index], 1, RowNo, ColNo);
            Assert.IsTrue(RowNo > 0, 'Expected to find a row with assembly component');
            Assert.IsTrue(ColNo > 0, 'Expected to find a column with assembly component');
        end;
    end;

    local procedure CreateGenJnlLineWithBalAccount(var GenJournalLine: Record "Gen. Journal Line"; DocType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; BalAccountType: Enum "Gen. Journal Account Type"; BalAccountNo: Code[20]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocType, AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Bal. Account Type", BalAccountType);
        GenJournalLine.Validate("Bal. Account No.", BalAccountNo);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateAndPostInvoice(PostingDate: Date; CustomerNo: Code[20]; InvoiceAmount: Decimal) InvoiceNo: Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateGenJnlLineWithBalAccount(
            GenJournalLine,
            GenJournalLine."Document Type"::Invoice,
            GenJournalLine."Account Type"::Customer,
            CustomerNo,
            GenJournalLine."Bal. Account Type"::"G/L Account",
            LibraryERM.CreateGLAccountNo(),
            InvoiceAmount);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Modify(true);

        InvoiceNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreatePaymentApplyAndPost(PostingDate: Date; CustomerNo: Code[20]; InvoiceAmount: Decimal; InvoiceNo: Code[20]) DocumentNo: Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateGenJnlLineWithBalAccount(
            GenJournalLine,
            GenJournalLine."Document Type"::Payment,
            GenJournalLine."Account Type"::Customer,
            CustomerNo,
            GenJournalLine."Bal. Account Type"::"G/L Account",
            LibraryERM.CreateGLAccountNo(),
            -InvoiceAmount);

        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("Applies-to Doc. Type", "Gen. Journal Document Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", InvoiceNo);
        GenJournalLine.Modify();
        DocumentNo := GenJournalLine."Document No.";

        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure ApplyAndPostCustomerEntry(DocumentNo: Code[20]; DocumentNo2: Code[20]; AmountToApply: Decimal; DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocumentType, DocumentNo);
        LibraryERM.SetApplyCustomerEntry(CustLedgerEntry, AmountToApply);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry2, DocumentType2, DocumentNo2);
        CustLedgerEntry2.FindSet();
        repeat
            CustLedgerEntry2.CalcFields("Remaining Amount");
            CustLedgerEntry2.Validate("Amount to Apply", CustLedgerEntry2."Remaining Amount");
            CustLedgerEntry2.Modify(true);
        until CustLedgerEntry2.Next() = 0;

        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry2);
        Commit();
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry);
    end;

    local procedure RunCustomerBalanceToDateWithCustomer(CustomerNo: Code[20]; Unapplied: Boolean; ReportDate: Date)
    var
        Customer: Record Customer;
        CustomerBalanceToDate: Report "Customer - Balance to Date";
    begin
        Commit();
        Clear(CustomerBalanceToDate);
        Customer.SetRange("No.", CustomerNo);
        CustomerBalanceToDate.SetTableView(Customer);
        CustomerBalanceToDate.InitializeRequest(false, false, Unapplied, ReportDate);
        CustomerBalanceToDate.Run();
    end;

    local procedure VerifyCustomerBalanceToDateTwoEntriesExist(CustomerNo: Code[20]; PmtAmount: Decimal; Amount: Decimal; TotalAmount: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_Customer', CustomerNo);
        LibraryReportDataset.AssertElementWithValueExists('OriginalAmt', Format(PmtAmount));
        LibraryReportDataset.AssertElementWithValueExists('OriginalAmt', Format(Amount));
        LibraryReportDataset.AssertElementWithValueExists('TtlAmtCurrencyTtlBuff', TotalAmount);
        LibraryReportDataset.AssertElementWithValueNotExist('postDt_DtldCustLedgEntry', Format(WorkDate() + 1));
    end;

    local procedure VerifyReportItemTotals(CustomerNo: Code[20]; CustomerNo2: Code[20])
    var
        ValueEntry: Record "Value Entry";
        // Customer 1
        SubtotalsAmount: Decimal;
        SubtotalsProfit: Decimal;
        // Customer 2
        SubtotalsAmount2: Decimal;
        SubtotalsProfit2: Decimal;
    begin
        // [THEN] Retrieve totals for "C1" from the Value Entry table
        ValueEntry.SetRange("Source No.", CustomerNo);
        ValueEntry.CalcSums("Sales Amount (Actual)", ValueEntry."Discount Amount", "Cost Amount (Actual)", "Cost Amount (Non-Invtbl.)");
        SubtotalsAmount := ValueEntry."Sales Amount (Actual)";
        SubtotalsProfit := ValueEntry."Sales Amount (Actual)" + ValueEntry."Cost Amount (Actual)" + ValueEntry."Cost Amount (Non-Invtbl.)";

        // [THEN] Retrieve totals for "C2" from the Value Entry table
        ValueEntry.SetRange("Source No.", CustomerNo2);
        ValueEntry.CalcSums("Sales Amount (Actual)", ValueEntry."Discount Amount", "Cost Amount (Actual)", "Cost Amount (Non-Invtbl.)");
        SubtotalsAmount2 := ValueEntry."Sales Amount (Actual)";
        SubtotalsProfit2 := ValueEntry."Sales Amount (Actual)" + ValueEntry."Cost Amount (Actual)" + ValueEntry."Cost Amount (Non-Invtbl.)";

        // [THEN] The Subtotals on the Report match those in the value Entries table for Customer "C1"
        LibraryReportDataset.AssertElementWithValueExists('Subtotals_Amount', SubtotalsAmount);
        LibraryReportDataset.AssertElementWithValueExists('Subtotals_Profit', SubtotalsProfit);

        // [THEN] The Subtotals on the Report match those in the value Entries table for Customer "C2"
        LibraryReportDataset.AssertElementWithValueExists('Subtotals_Amount', SubtotalsAmount2);
        LibraryReportDataset.AssertElementWithValueExists('Subtotals_Profit', SubtotalsProfit2);

        // [THEN] The Grand Totals on the Report match those in the Value Entries table for Customers "C1" & "C2"
        LibraryReportDataset.AssertElementWithValueExists('Totals_Amount', (SubtotalsAmount + SubtotalsAmount2));
        LibraryReportDataset.AssertElementWithValueExists('Totals_Profit', (SubtotalsProfit + SubtotalsProfit2));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StandardSalesInvoiceRequestPageHandler(var StandardSalesInvoice: TestRequestPage "Standard Sales - Invoice")
    begin
        StandardSalesInvoice.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StandardSalesInvoiceExcelRequestPageHandler(var StandardSalesInvoice: TestRequestPage "Standard Sales - Invoice")
    var
        ShowAssemblyComponents: Boolean;
    begin
        ShowAssemblyComponents := LibraryVariableStorage.DequeueBoolean();
        StandardSalesInvoice.DisplayAsmInformation.SetValue(ShowAssemblyComponents);
        StandardSalesInvoice.SaveAsExcel(LibraryReportValidation.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StandardSalesQuoteRequestPageHandler(var StandardSalesQuote: TestRequestPage "Standard Sales - Quote")
    begin
        StandardSalesQuote.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BlanketSalesOrderADChangeRequestPageHandler(var BlanketSalesOrder: TestRequestPage "Blanket Sales Order")
    begin
        if not LibraryVariableStorage.DequeueBoolean() then
            BlanketSalesOrder.ArchiveDocument.SetValue(not BlanketSalesOrder.ArchiveDocument.AsBoolean());

        LibraryVariableStorage.Enqueue(BlanketSalesOrder.ArchiveDocument.Value);
        BlanketSalesOrder.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StdSalesDraftInvoiceADChangeRequestPageHandler(var StandardSalesDraftInvoice: TestRequestPage "Standard Sales - Draft Invoice")
    begin
        StandardSalesDraftInvoice.Header.SetFilter("No.", '<>''''');
        StandardSalesDraftInvoice.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StdSalesQuoteADChangeRequestPageHandler(var StandardSalesQuote: TestRequestPage "Standard Sales - Quote")
    begin
        if not LibraryVariableStorage.DequeueBoolean() then
            StandardSalesQuote.ArchiveDocument.SetValue(not StandardSalesQuote.ArchiveDocument.AsBoolean());

        LibraryVariableStorage.Enqueue(StandardSalesQuote.ArchiveDocument.Value);

        StandardSalesQuote.Header.SetFilter("No.", '<>''''');
        StandardSalesQuote.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StdSalesOrderConfADChangeRequestPageHandler(var StandardSalesOrderConf: TestRequestPage "Standard Sales - Order Conf.")
    begin
        if not LibraryVariableStorage.DequeueBoolean() then
            StandardSalesOrderConf.ArchiveDocument.SetValue(not StandardSalesOrderConf.ArchiveDocument.AsBoolean());

        LibraryVariableStorage.Enqueue(StandardSalesOrderConf.ArchiveDocument.Value);

        StandardSalesOrderConf.Header.SetFilter("No.", '<>''''');
        StandardSalesOrderConf.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StdSalesInvoiceRequestPageHandler(var StandardSalesInvoice: TestRequestPage "Standard Sales - Invoice")
    begin
        if StandardSalesInvoice.Editable then;
        StandardSalesInvoice.DisplayShipmentInformation.SetValue(true);
        StandardSalesInvoice.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
        Sleep(200);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StdSalesCrMemoRequestPageHandler(var StandardSalesCreditMemo: TestRequestPage "Standard Sales - Credit Memo")
    begin
        if StandardSalesCreditMemo.Editable then;
        StandardSalesCreditMemo.DisplayShipmentInformation.SetValue(true);
        StandardSalesCreditMemo.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
        Sleep(200);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StdSalesQuoteExcelRequestPageHandler(var StandardSalesQuote: TestRequestPage "Standard Sales - Quote")
    begin
        StandardSalesQuote.SaveAsExcel(LibraryReportValidation.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StdSalesDraftInvoiceExcelRequestPageHandler(var StandardSalesDraftInvoice: TestRequestPage "Standard Sales - Draft Invoice")
    begin
        StandardSalesDraftInvoice.SaveAsExcel(LibraryReportValidation.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StdSalesInvoiceExcelRequestPageHandler(var StandardSalesInvoice: TestRequestPage "Standard Sales - Invoice")
    begin
        StandardSalesInvoice.SaveAsExcel(LibraryReportValidation.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StdSalesCreditMemoExcelRequestPageHandler(var StandardSalesCreditMemo: TestRequestPage "Standard Sales - Credit Memo")
    begin
        StandardSalesCreditMemo.SaveAsExcel(LibraryReportValidation.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesStatisticsRequestPageHandler(var SalesStatistics: TestRequestPage "Sales Statistics")
    begin
        SalesStatistics.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReportStandardSalesDraftInvoiceRequestPageHandlerForLogInteractionEnabled(var StandardSalesDraftInvoice: TestRequestPage "Standard Sales - Draft Invoice")
    begin
        Assert.IsFalse(StandardSalesDraftInvoice.LogInteractionField.Enabled(), 'Log Interaction option is enabled.');
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReportStandardSalesDraftInvoiceRequestPageHandlerForLogInteractionExecute(var StandardSalesDraftInvoice: TestRequestPage "Standard Sales - Draft Invoice")
    var
        LogInteraction: Variant;
    begin
        LibraryVariableStorage.Dequeue(LogInteraction);
        StandardSalesDraftInvoice.LogInteractionField.SetValue(LogInteraction);

        StandardSalesDraftInvoice.SaveAsPdf(Format(CreateGuid()));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReportStandardSalesShipmentRequestPageHandlerForLogInteractionExecute(var StandardSalesShipment: TestRequestPage "Standard Sales - Shipment")
    var
        LogInteraction: Variant;
    begin
        LibraryVariableStorage.Dequeue(LogInteraction);
        StandardSalesShipment.LogInteractionControl.SetValue(LogInteraction);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustBalanceToDateRequestPageHandler(var CustomerBalanceToDate: TestRequestPage "Customer - Balance to Date")
    begin
        CustomerBalanceToDate.ShowEntriesWithZeroBalance.SetValue(true);
        CustomerBalanceToDate.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}
