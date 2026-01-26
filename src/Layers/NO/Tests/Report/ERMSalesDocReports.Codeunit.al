codeunit 134390 "ERM Sales Doc. Reports"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Reports] [Sales]
        isInitialized := false;
    end;

    var
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySales: Codeunit "Library - Sales";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        isInitialized: Boolean;
        SameAmountErrorTxt: Label 'Amount must be same.';
        HeaderDimensionTxt: Label '%1 %2', Comment = '%1 = Dimension Code, %2 = Dimension Value Code';

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Sales Doc. Reports");
        LibraryVariableStorage.Clear();
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Sales Doc. Reports");

        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateLocalData();
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Sales Doc. Reports");
    end;

    [Test]
    [HandlerFunctions('ReportHandlerBlanketSalesOrder')]
    [Scope('OnPrem')]
    procedure BlanketSalesOrderWithoutOption()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Verify Blanket Sales Order Report when no option is set.

        // Setup
        Initialize();
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::"Blanket Order");

        // Exercise: Save Blanket Sales Order Report
        BlanketSalesOrderReport(SalesHeader."No.", false);

        // Verify: Verify Amount on Blanket Sales Order Report when no option is set.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('LineAmountRL_SalesLine', SalesLine."Line Amount");
    end;

    [Test]
    [HandlerFunctions('ReportHandlerBlanketSalesOrder')]
    [Scope('OnPrem')]
    procedure BlanketSalesOrderCheckVAT()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Verify VAT Amount on Blanket Sales Order Report when no option is set.

        // Setup
        Initialize();
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::"Blanket Order");

        // Exercise: Save Blanket Sales Order Report.
        BlanketSalesOrderReport(SalesHeader."No.", false);

        // Verify: Verify VAT Amount on Blanket Sales Order Report when no option is set.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('VATAmount', Round(SalesLine."Line Amount" * SalesLine."VAT %" / 100));
    end;

    [Test]
    [HandlerFunctions('ReportHandlerBlanketSalesOrder')]
    [Scope('OnPrem')]
    procedure BlanketSalesOrderInternalInfo()
    var
        DefaultDimension: Record "Default Dimension";
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RowValueSet: Text[250];
    begin
        // Verify Dimension on Blanket Sales Order Report when Show Internal Information option is True.

        // Setup.
        Initialize();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreateCustomerWithDimension(DefaultDimension, VATPostingSetup."VAT Bus. Posting Group");
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Blanket Order", DefaultDimension."No.");

        // Use Random Number Generator for Quantity.
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group"),
          LibraryRandom.RandDec(10, 2));

        // Exercise: Save Blanket Sales Order Report.
        BlanketSalesOrderReport(SalesHeader."No.", true);

        // Verify: Verify Dimension on Blanket Sales Order Report when Show Internal Information option is True.
        LibraryReportDataset.LoadDataSetFile();
        RowValueSet := StrSubstNo(HeaderDimensionTxt, DefaultDimension."Dimension Code", DefaultDimension."Dimension Value Code");
        LibraryReportDataset.AssertElementWithValueExists('DimText', RowValueSet);
    end;

    [Test]
    [HandlerFunctions('ReportHandlerReturnOrderConfirmation')]
    [Scope('OnPrem')]
    procedure SalesReturnOrderConfirmation()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        QtyType: Option General,Invoicing,Shipping;
    begin
        // Test Sales Line and VAT Amount Line Values on Return Order Confirmation Report.

        // 1. Setup: Create Sales Header with Document Type as Return Order, Sales Line and calculate VAT Amount Lines.
        Initialize();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::"Return Order", CreateCustomer(VATPostingSetup."VAT Bus. Posting Group"));
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group"),
          LibraryRandom.RandDec(10, 2));  // Use Random for Quantity.
        SalesLine.CalcVATAmountLines(QtyType, SalesHeader, SalesLine, TempVATAmountLine);

        // 2. Exercise: Run Return Order Confirmation Report.
        RunReturnOrderConfirmation(SalesHeader, false, false);

        // 3. Verify: Verify Sales Line and VAT Amount Line Values on Return Order Confirmation Report.
        LibraryReportDataset.LoadDataSetFile();
        VerifySalesLineOnReport(SalesLine);
        VerifyVATAmountLineOnReport(TempVATAmountLine);
    end;

    [Test]
    [HandlerFunctions('ReportHandlerReturnOrderConfirmation')]
    [Scope('OnPrem')]
    procedure SalesReturnOrderWithInternal()
    var
        DefaultDimension: Record "Default Dimension";
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Test Dimension on Return Order Confirmation Report when Show Internal Information option as True.

        // 1. Setup: Create Sales Header with Document Type as Return Order and Sales Line.
        Initialize();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreateCustomerWithDimension(DefaultDimension, VATPostingSetup."VAT Bus. Posting Group");
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", DefaultDimension."No.");
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group"),
          LibraryRandom.RandDec(10, 2));  // Use Random for Quantity.

        // 2. Exercise: Run Return Order Confirmation Report with show Internal Information as True.
        RunReturnOrderConfirmation(SalesHeader, true, false);

        // Verify: Verify Dimension on Return Order Confirmation Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('DimText',
          StrSubstNo(HeaderDimensionTxt, DefaultDimension."Dimension Code", DefaultDimension."Dimension Value Code"));
    end;

    [Test]
    [HandlerFunctions('ReportHandlerReturnOrderConfirmation')]
    [Scope('OnPrem')]
    procedure SalesReturnOrderLogInteraction()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        InteractionLogEntry: Record "Interaction Log Entry";
    begin
        // Test Interaction Log Entry after running Return Order Confirmation Report with Log Interaction as True.

        // 1. Setup: Create Sales Header with Document Type as Return Order and Sales Line.
        Initialize();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::"Return Order", CreateCustomer(VATPostingSetup."VAT Bus. Posting Group"));
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group"),
          LibraryRandom.RandDec(10, 2));  // Use Random for Quantity.

        // 2. Exercise: Run Return Order Confirmation Report with Log Iteraction as True.
        RunReturnOrderConfirmation(SalesHeader, false, true);

        // 3. Verify: Verify Interaction Log Entry.
        InteractionLogEntry.SetRange("Document Type", InteractionLogEntry."Document Type"::"Sales Return Order");
        InteractionLogEntry.SetRange("Document No.", SalesHeader."No.");
        InteractionLogEntry.FindFirst();
        InteractionLogEntry.TestField("Information Flow", InteractionLogEntry."Information Flow"::Outbound);
    end;

    [Test]
    [HandlerFunctions('ReportHandlerCustomerSummaryAging')]
    [Scope('OnPrem')]
    procedure CustomerSummaryAgingWithMultipleSalesOrder()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        GenJournalLine: Record "Gen. Journal Line";
        CustomerSummaryAging: Report "Customer - Summary Aging";
        ReportValue: Variant;
        CustomerNo: Code[20];
        CustomerNo2: Code[20];
        Amount: Decimal;
        Amount2: Decimal;
        Amount3: Decimal;
        PostingDate: Date;
        PostingDate2: Date;
    begin
        // Check Customer Summary Aging Report with Multiple Posted Sales Order and with partially Payment.

        // Setup: Create and Post Three Sales Order with Due Date. Take difference with 1 Month on Due Date.
        Initialize();
        PostingDate := CalculatePostingDate(WorkDate());
        PostingDate2 := CalculatePostingDate(PostingDate);
        Amount := CreateAndPostSalesOrder(SalesLine, WorkDate());
        CustomerNo := SalesLine."Sell-to Customer No.";
        Amount2 := CreateAndPostSalesOrder(SalesLine, PostingDate);
        CustomerNo2 := SalesLine."Sell-to Customer No.";
        Amount3 := CreateAndPostSalesOrder(SalesLine, PostingDate2);

        // Partial Payment of Posted Invoice through General Line with Due Date same as Posted Sales order.
        SelectGenJournalBatch(GenJournalBatch);
        CreateAndModifyGeneralLine(GenJournalLine, GenJournalBatch, CustomerNo, WorkDate(), -Amount);
        CreateAndModifyGeneralLine(GenJournalLine, GenJournalBatch, CustomerNo2, PostingDate, -Amount2 / 2);
        CreateAndModifyGeneralLine(GenJournalLine, GenJournalBatch, SalesLine."Sell-to Customer No.", PostingDate2, -Amount3 / 2);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Exercise: Run and Save Report for Customer Summary Aging. 1M is required to generate Date for 1 month difference.
        Clear(CustomerSummaryAging);
        Customer.SetFilter("No.", '%1|%2|%3', CustomerNo, CustomerNo2, SalesLine."Sell-to Customer No.");
        CustomerSummaryAging.SetTableView(Customer);
        CustomerSummaryAging.InitializeRequest(GenJournalLine."Due Date", '<1M>', false);
        CustomerSummaryAging.Run();

        // Verify: Verify Saved Report Data.
        LibraryReportDataset.LoadDataSetFile();
        Amount2 := FindDetailedCustomerLedgerEntry(CustomerNo2);
        Amount3 := FindDetailedCustomerLedgerEntry(SalesLine."Sell-to Customer No.");

        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.FindCurrentRowValue('CustBalanceDueLCY_1_', ReportValue);
        Assert.AreNearlyEqual(-Amount2, ReportValue, LibraryERM.GetAmountRoundingPrecision(), SameAmountErrorTxt);

        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.FindCurrentRowValue('CustBalanceDueLCY_2_', ReportValue);
        Assert.AreNearlyEqual(-Amount3, ReportValue, LibraryERM.GetAmountRoundingPrecision(), SameAmountErrorTxt);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler,MessageHandler,ReportHandlerArchivedSalesOrder')]
    [Scope('OnPrem')]
    procedure VerifyVATAmountOnArchiveSalesOrderReport()
    var
        SalesHeader: Record "Sales Header";
        SalesHeaderArchive: Record "Sales Header Archive";
        ArchiveManagement: Codeunit ArchiveManagement;
        VATAmount: Decimal;
    begin
        // 1. Setup: Create Sales Order with Multiple Lines.
        Initialize();
        VATAmount := CreateSalesDocumentWithMultipleLines(SalesHeader);

        // 2. Exercise: Archive the Sales Document and Run Report Archived Sales Order.
        ArchiveManagement.ArchiveSalesDocument(SalesHeader);
        Commit();
        SalesHeaderArchive.SetRange("No.", SalesHeader."No.");
        REPORT.Run(REPORT::"Archived Sales Order", true, false, SalesHeaderArchive);

        // Verify: VAT Amount is correct.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('VATAmount_Control134', Round(VATAmount, LibraryERM.GetAmountRoundingPrecision()));
    end;

    [Test]
    [HandlerFunctions('ReportHandlerPurchCreditMemo')]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoReport()
    var
        PurchaseHeader: Record "Purchase Header";
        VATPostingSetup: Record "VAT Posting Setup";
        VATIdentifier: Code[20];
        VendorCrMemoNo: Code[35];
        OldPrintVATSpecInLCY: Boolean;
    begin
        // Test that "VAT Amount Specification" and  "VAT Amount Specification in (Local Currency)" in Purchase - Credit Memo Report
        // should be shown when VAT Amount = 0.

        // Setup: Create and post Purchase Return Order and find Posted Purchase Return Order.
        Initialize();
        VendorCrMemoNo := LibraryUtility.GenerateGUID();
        VATIdentifier := CreateAndPostPurchDocumentWithCurrency(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order",
            VATPostingSetup."VAT Calculation Type"::"Normal VAT", VendorCrMemoNo);
        OldPrintVATSpecInLCY := UpdateGeneralLedgerSetup(true); // Check "Print VAT specification in LCY" option in General Ledger Setup.

        // Exercise: Generate Purchase Credit Memo Report.
        RunPurchCreditMemo(VendorCrMemoNo);

        // Verify: verify that "VAT Amount Specification" and  "VAT Amount Specification in (Local Currency)" in Purchase - Credit Memo Report
        // should be shown when VAT Amount = 0.
        VerifyPurchaseCreditMemoReport(VATIdentifier, 0); // 0 means VAT Amount = 0.

        // Tear Down: Set Print VAT Specification in LCY as default in General Ledger Setup.
        UpdateGeneralLedgerSetup(OldPrintVATSpecInLCY);
    end;

    [Test]
    [HandlerFunctions('ReportHandlerReturnOrderConfirmation')]
    [Scope('OnPrem')]
    procedure SalesReturnOrderConfirmationWithSingleVATAmountLine()
    begin
        // Verify VAT Amount Specifiction on Sales Return Order Confirmation With Single Line.
        VerifySalesReturnOrderConfirmationWithVATAmountLine(1); // 1 indicates single sales line
    end;

    [Test]
    [HandlerFunctions('ReportHandlerReturnOrderConfirmation')]
    [Scope('OnPrem')]
    procedure SalesReturnOrderConfirmationWithMultipleVATAmountLines()
    begin
        // Verify VAT Amount Specifiction on Sales Return Order Confirmation With Multiple Lines.
        VerifySalesReturnOrderConfirmationWithVATAmountLine(LibraryRandom.RandIntInRange(2, 10));
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler,RepHandlerReturnOrderConfirmation')]
    [Scope('OnPrem')]
    procedure SellToCustomerCaptionInShiptoReturnOrderConfirmation()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Return Order Confirmation]
        // [SCENARIO 223056] Report "Return Order Confirmation" must show caption of "Sales Header"."Sell-to Customer No." in section Ship-to Address
        Initialize();

        // [GIVEN] Sales return order with "Sell-to Customer No." = "Cust1" and "Bill-to Customer No." = "Cust2"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("Bill-to Customer No.", LibrarySales.CreateCustomerNo());
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandIntInRange(10, 100));
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());

        // [WHEN] Run "Return Order Confirmation"
        RunReturnOrderConfirmation(SalesHeader, false, false);

        // [THEN] Caption of Sell-to Customer No. = "Sell-to Customer No."
        LibraryReportValidation.OpenExcelFile();
        LibraryReportValidation.VerifyCellValueOnWorksheet(80, 1, SalesHeader.FieldCaption("Sell-to Customer No."), '1');
    end;

    local procedure VerifySalesReturnOrderConfirmationWithVATAmountLine(LineCount: Integer)
    var
        SalesHeader: Record "Sales Header";
        VATAmount: array[10] of Decimal;
        i: Integer;
    begin
        // Setup: Create Sales Return Order With Multiple Lines.
        Initialize();
        CreateSalesReturnOrderWithMultipleLines(SalesHeader, VATAmount, LineCount);

        // Exercise: Run Report Return Order Confirmation.
        RunReturnOrderConfirmation(SalesHeader, false, false);

        // Verify: Check VAT Amount on Sales Return Order Confirmation Report.
        LibraryReportDataset.LoadDataSetFile();
        for i := 1 to LineCount do
            LibraryReportDataset.AssertElementWithValueExists('VATAmtLineVATAmt', VATAmount[i]);
    end;

    [Test]
    [HandlerFunctions('ReportHandlerCustomerBalanceToDate')]
    [Scope('OnPrem')]
    procedure CustomerBalanceToDateMultipleCurrenciesWithTheSameAmount()
    var
        SalesHeaderCrMemo: Record "Sales Header";
        SalesHeaderInvoice: Record "Sales Header";
        CustLedgerEntryInvoice: Record "Cust. Ledger Entry";
        CustLedgerEntryCrMemo: Record "Cust. Ledger Entry";
        InvoiceDocumentNo: Code[20];
        CrMemoDocumentNo: Code[20];
        Amount: Decimal;
        ItemsCount: Integer;
    begin
        // [SCENARIO 341358] Check Customer Balance To Date with two lines with the same Amount in different Currency

        Initialize();
        ItemsCount := LibraryRandom.RandInt(10);
        Amount := LibraryRandom.RandDecInRange(100, 1000, 2);

        // [GIVEN] Created Sales Credit Memo with Currency for Customer
        CreateSalesDocumentWithAmount(
          SalesHeaderCrMemo,
          SalesHeaderCrMemo."Document Type"::"Credit Memo",
          CreateCurrencyAndExchangeRate(),
          LibraryInventory.CreateItemNo(),
          LibrarySales.CreateCustomerNo(),
          Amount,
          ItemsCount);
        CrMemoDocumentNo := LibrarySales.PostSalesDocument(SalesHeaderCrMemo, true, true);

        // [GIVEN] Created Sales Invoice for Customer
        CreateSalesDocumentWithAmount(
          SalesHeaderInvoice,
          SalesHeaderInvoice."Document Type"::Invoice,
          '',
          LibraryInventory.CreateItemNo(),
          SalesHeaderCrMemo."Sell-to Customer No.",
          Amount,
          ItemsCount);
        InvoiceDocumentNo := LibrarySales.PostSalesDocument(SalesHeaderInvoice, true, true);

        // [GIVEN] Found Customer Ledger Entries for created Documents
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntryCrMemo, CustLedgerEntryCrMemo."Document Type"::"Credit Memo", CrMemoDocumentNo);
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntryInvoice, CustLedgerEntryInvoice."Document Type"::Invoice, InvoiceDocumentNo);
        CustLedgerEntryCrMemo.CalcFields("Original Amount");
        CustLedgerEntryInvoice.CalcFields("Original Amount");

        // [WHEN]  Save Report "Customer Balance to Date".
        SaveCustomerBalanceToDate(SalesHeaderCrMemo, false, false, false);

        // [THEN] Report was created
        LibraryReportDataset.LoadDataSetFile();

        // [THEN] Original Amount was filled correctly
        LibraryReportDataset.AssertElementWithValueExists('OriginalAmt', Format(CustLedgerEntryCrMemo."Original Amount"));
        LibraryReportDataset.AssertElementWithValueExists('OriginalAmt', Format(CustLedgerEntryInvoice."Original Amount"));
    end;

    [Test]
    [HandlerFunctions('ReportHandlerCustomerBalanceToDate')]
    [Scope('OnPrem')]
    procedure CustomerBalanceToDateMultipleCurrenciesWithTheSameAmountWithShowEntriesWithZeroBalance()
    var
        SalesHeaderCrMemo: Record "Sales Header";
        SalesHeaderInvoice: Record "Sales Header";
        CustLedgerEntryInvoice: Record "Cust. Ledger Entry";
        CustLedgerEntryCrMemo: Record "Cust. Ledger Entry";
        InvoiceDocumentNo: Code[20];
        CrMemoDocumentNo: Code[20];
        Amount: Decimal;
        ItemsCount: Integer;
    begin
        // [SCENARIO 341358] Check Customer Balance To Date with two lines with the same Amount in different Currency

        Initialize();
        ItemsCount := LibraryRandom.RandInt(10);
        Amount := LibraryRandom.RandDecInRange(100, 1000, 2);

        // [GIVEN] Created Sales Credit Memo with Currency for Customer
        CreateSalesDocumentWithAmount(
          SalesHeaderCrMemo,
          SalesHeaderCrMemo."Document Type"::"Credit Memo",
          CreateCurrencyAndExchangeRate(),
          LibraryInventory.CreateItemNo(),
          LibrarySales.CreateCustomerNo(),
          Amount,
          ItemsCount);
        CrMemoDocumentNo := LibrarySales.PostSalesDocument(SalesHeaderCrMemo, true, true);

        // [GIVEN] Created Sales Invoice for Customer
        CreateSalesDocumentWithAmount(
          SalesHeaderInvoice,
          SalesHeaderInvoice."Document Type"::Invoice,
          '',
          LibraryInventory.CreateItemNo(),
          SalesHeaderCrMemo."Sell-to Customer No.",
          Amount,
          ItemsCount);
        InvoiceDocumentNo := LibrarySales.PostSalesDocument(SalesHeaderInvoice, true, true);

        // [GIVEN] Found Customer Ledger Entries for created Documents
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntryCrMemo, CustLedgerEntryCrMemo."Document Type"::"Credit Memo", CrMemoDocumentNo);
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntryInvoice, CustLedgerEntryInvoice."Document Type"::Invoice, InvoiceDocumentNo);
        CustLedgerEntryCrMemo.CalcFields("Original Amount");
        CustLedgerEntryInvoice.CalcFields("Original Amount");

        // [WHEN] Run Report "Customer Balance to Date" with Show Entries with Zero Balance = 'No'
        SaveCustomerBalanceToDate(SalesHeaderCrMemo, false, false, true);

        // [THEN] Report was created
        LibraryReportDataset.LoadDataSetFile();

        // [THEN] Original Amount was filled correctly
        LibraryReportDataset.AssertElementWithValueExists('OriginalAmt', Format(CustLedgerEntryCrMemo."Original Amount"));
        LibraryReportDataset.AssertElementWithValueExists('OriginalAmt', Format(CustLedgerEntryInvoice."Original Amount"));
    end;

    [Test]
    [HandlerFunctions('ReportHandlerCustomerBalanceToDate')]
    [Scope('OnPrem')]
    procedure CustomerBalanceToDateWithTheSameAmountSkipReport()
    var
        SalesHeaderCrMemo: Record "Sales Header";
        SalesHeaderInvoice: Record "Sales Header";
        CustLedgerEntryInvoice: Record "Cust. Ledger Entry";
        CustLedgerEntryCrMemo: Record "Cust. Ledger Entry";
        InvoiceDocumentNo: Code[20];
        CrMemoDocumentNo: Code[20];
        Amount: Decimal;
        ItemsCount: Integer;
    begin
        // [SCENARIO 341358] Check Customer Balance To Date skip with two lines with the same Amount

        Initialize();
        ItemsCount := LibraryRandom.RandInt(10);
        Amount := LibraryRandom.RandDecInRange(100, 1000, 2);

        // [GIVEN] Created Sales Credit Memo for Customer
        CreateSalesDocumentWithAmount(
          SalesHeaderCrMemo,
          SalesHeaderCrMemo."Document Type"::"Credit Memo",
          '',
          LibraryInventory.CreateItemNo(),
          LibrarySales.CreateCustomerNo(),
          Amount,
          ItemsCount);
        CrMemoDocumentNo := LibrarySales.PostSalesDocument(SalesHeaderCrMemo, true, true);

        // [GIVEN] Created Sales Invoice for Customer
        CreateSalesDocumentWithAmount(
          SalesHeaderInvoice,
          SalesHeaderInvoice."Document Type"::Invoice,
          '',
          LibraryInventory.CreateItemNo(),
          SalesHeaderCrMemo."Sell-to Customer No.",
          Amount,
          ItemsCount);
        InvoiceDocumentNo := LibrarySales.PostSalesDocument(SalesHeaderInvoice, true, true);

        // [GIVEN] Found Customer Ledger Entries for created Documents
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntryCrMemo, CustLedgerEntryCrMemo."Document Type"::"Credit Memo", CrMemoDocumentNo);
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntryInvoice, CustLedgerEntryInvoice."Document Type"::Invoice, InvoiceDocumentNo);
        CustLedgerEntryCrMemo.CalcFields("Original Amount");
        CustLedgerEntryInvoice.CalcFields("Original Amount");

        // [WHEN]  Save Report "Customer Balance to Date".
        SaveCustomerBalanceToDate(SalesHeaderCrMemo, false, false, false);

        // [THEN] Report was created
        LibraryReportDataset.LoadDataSetFile();

        // [THEN] Documents are not exported
        LibraryReportDataset.AssertElementWithValueNotExist('DocNo_CustLedgEntry', CustLedgerEntryCrMemo."Document No.");
        LibraryReportDataset.AssertElementWithValueNotExist('DocNo_CustLedgEntry', CustLedgerEntryInvoice."Document No.");
    end;

    [Test]
    [HandlerFunctions('ReportHandlerCustomerBalanceToDate')]
    [Scope('OnPrem')]
    procedure CustomerBalanceToDateForZeroAmountInvoiceWithShowEntriesWithZeroBalance()
    var
        SalesHeaderInvoice: Record "Sales Header";
        CustLedgerEntryInvoice: Record "Cust. Ledger Entry";
        InvoiceDocumentNo: Code[20];
    begin
        // [SCENARIO 442479] Check Customer Balance To Date for zero amount invoice
        Initialize();

        // [GIVEN] Create Sales Invoice with GL and Amount will be 0.
        CreateSalesDocumentWithZeroAmount(SalesHeaderInvoice, SalesHeaderInvoice."Document Type"::Invoice, '', LibrarySales.CreateCustomerNo(), 1);

        // [THEN] Post Sale Invoice of 0 amount
        InvoiceDocumentNo := LibrarySales.PostSalesDocument(SalesHeaderInvoice, true, true);

        // [GIVEN] Found Customer Ledger Entries for created Documents
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntryInvoice, CustLedgerEntryInvoice."Document Type"::Invoice, InvoiceDocumentNo);
        CustLedgerEntryInvoice.CalcFields("Original Amount");

        // [WHEN] Run Report "Customer Balance to Date" with Show Entries with Zero Balance = 'No'
        SaveCustomerBalanceToDate(SalesHeaderInvoice, false, false, true);

        // [THEN] Report was created
        LibraryReportDataset.LoadDataSetFile();

        // [VERIFY] Original Amount was filled correctly
        LibraryReportDataset.AssertElementWithValueExists('OriginalAmt', Format(CustLedgerEntryInvoice."Original Amount"));
    end;

    [Test]
    procedure VerifyLinesWithZeroQuantityAreHiddenWhenOptionSelected()
    var
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        FormatDocument: Codeunit "Format Document";
    begin
        // Test that the sales lines with zero quantity are hidden during printout

        // Setup: Create Sales Invoice
        Initialize();
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice);

        // Exercise: Set quantity to 0 for sales line
        SalesLine.Validate(Quantity, 0);

        // Verify: The function HideDocumentLine should either hide or display the line depending on the HideLinesWithZeroQuantity int the report request page
        Assert.IsTrue(FormatDocument.HideDocumentLine(true, SalesLine, SalesLine.FieldNo(Quantity)), 'The Line with zero quantity is displayed but should be hidden.');
        Assert.IsFalse(FormatDocument.HideDocumentLine(false, SalesLine, SalesLine.FieldNo(Quantity)), 'The Line with zero quantity should be displayed.');

        // Exercise: Set quantity to non zero value for sales line
        SalesLine.Validate(Quantity, LibraryRandom.RandDec(10, 2));

        // Verify: The function HideDocumentLine should never hide lines that contain the quantity
        Assert.IsFalse(FormatDocument.HideDocumentLine(true, SalesLine, SalesLine.FieldNo(Quantity)), 'The Line with quantity different from 0 should be displayed.');
        Assert.IsFalse(FormatDocument.HideDocumentLine(false, SalesLine, SalesLine.FieldNo(Quantity)), 'The Line with quantity different from 0 should be displayed.');
    end;

    local procedure FindDetailedCustomerLedgerEntry(CustomerNo: Code[20]): Decimal
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DetailedCustLedgEntry.SetRange("Document Type", DetailedCustLedgEntry."Document Type"::Payment);
        DetailedCustLedgEntry.SetRange("Customer No.", CustomerNo);
        DetailedCustLedgEntry.FindFirst();
        exit(DetailedCustLedgEntry.Amount);
    end;

    local procedure BlanketSalesOrderReport(No: Code[20]; ShowInternalInformation: Boolean)
    var
        SalesHeader: Record "Sales Header";
        BlanketSalesOrder: Report "Blanket Sales Order";
    begin
        Commit(); // Required to run report with request page.
        Clear(BlanketSalesOrder);
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::"Blanket Order");
        SalesHeader.SetRange("No.", No);
        BlanketSalesOrder.SetTableView(SalesHeader);

        // 0 is using for No. of Copies.
        BlanketSalesOrder.InitializeRequest(0, ShowInternalInformation, false, false);
        BlanketSalesOrder.Run();
    end;

    local procedure CreateAndPostSalesOrder(var SalesLine: Record "Sales Line"; DueDate: Date) Amount: Decimal
    var
        SalesHeader: Record "Sales Header";
    begin
        // Taken Random values for Quantity and Unit Price.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        SalesHeader.Validate("Due Date", DueDate);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandDec(10, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
        Amount := SalesLine."Amount Including VAT";
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreateAndPostPurchDocumentWithCurrency(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; VATCalType: Enum "General Posting Type"; VendorCrMemoNo: Code[35]): Code[10]
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATIdentifier: Code[20];
        OldVATPercent: Decimal;
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATCalType);
        UpdateVATPostingSetup(VATPostingSetup, OldVATPercent, 0);

        VATIdentifier := CreatePurchaseDocumentWithCurrency(VATPostingSetup, PurchaseHeader, DocumentType, VendorCrMemoNo);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        UpdateVATPostingSetup(VATPostingSetup, OldVATPercent, OldVATPercent);
        exit(VATIdentifier);
    end;

    local procedure CreatePurchaseDocumentWithCurrency(var VATPostingSetup: Record "VAT Posting Setup"; var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; VendorCrMemoNo: Code[35]): Code[10]
    var
        Currency: Record Currency;
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, CreateVendor(VATPostingSetup."VAT Bus. Posting Group"));
        Currency.Get(LibraryERM.CreateCurrencyWithRandomExchRates());
        UpdatePurchaseDocument(PurchaseHeader, Currency.Code, VendorCrMemoNo);

        // Use Random Number Generator for Quantity.
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group"),
          LibraryRandom.RandDec(10, 2));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 1000, 2));
        PurchaseLine.Modify(true);
        exit(VATPostingSetup."VAT Identifier");
    end;

    local procedure CreateAndModifyGeneralLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; AccountNo: Code[20]; DueDate: Date; Amount: Decimal)
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Customer, AccountNo, Amount);
        GenJournalLine.Validate("Due Date", DueDate);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateCurrencyAndExchangeRate(): Code[10]
    var
        Currency: Record Currency;
        LibraryERM: Codeunit "Library - ERM";
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type")
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreateSalesDocumentWithNormalVAT(VATPostingSetup, SalesHeader, SalesLine, DocumentType, '');
    end;

    local procedure CreateSalesDocumentWithAmount(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; CurrencyCode: Code[10]; ItemNo: Code[20]; CustomerNo: Code[20]; DirectUnitCost: Decimal; ItemQuantity: Integer)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, ItemQuantity);
        SalesLine.Validate("Unit Price", DirectUnitCost);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesDocumentWithNormalVAT(var VATPostingSetup: Record "VAT Posting Setup"; var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; CurrencyCode: Code[10]): Code[10]
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CreateCustomer(VATPostingSetup."VAT Bus. Posting Group"));
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Modify(true);

        // Use Random Number Generator for Quantity.
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group"),
          LibraryRandom.RandDec(10, 2));
        exit(VATPostingSetup."VAT Identifier");
    end;

    local procedure CreateSalesDocumentWithMultipleLines(var SalesHeader: Record "Sales Header"): Decimal
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesLine: Record "Sales Line";
        i: Integer;
        TotalAmount: Decimal;
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer(VATPostingSetup."VAT Bus. Posting Group"));
        for i := 1 to LibraryRandom.RandIntInRange(2, 5) do begin
            LibrarySales.CreateSalesLine(
              SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group"),
              LibraryRandom.RandInt(10));
            TotalAmount += Round((SalesLine.Amount * SalesLine."VAT %") / 100);
        end;
        exit(TotalAmount);
    end;

    local procedure CreateSalesReturnOrderWithMultipleLines(var SalesHeader: Record "Sales Header"; var VATAmount: array[10] of Decimal; LineCount: Integer)
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        i: Integer;
    begin
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::"Return Order", CreateCustomer(VATBusinessPostingGroup.Code));
        for i := 1 to LineCount do
            VATAmount[i] := CreateSalesLineAndCalcVATAmount(SalesHeader, VATBusinessPostingGroup.Code);
    end;

    local procedure CreateSalesLineAndCalcVATAmount(SalesHeader: Record "Sales Header"; VATBusinessPostingGroupCode: Code[20]): Decimal
    var
        SalesLine: Record "Sales Line";
        VATAmountLine: Record "VAT Amount Line";
        VATPostingSetup: Record "VAT Posting Setup";
        QtyType: Option General,Invoicing,Shipping;
    begin
        CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroupCode);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group"),
          LibraryRandom.RandInt(10));
        SalesLine.CalcVATAmountLines(QtyType::General, SalesHeader, SalesLine, VATAmountLine);
        exit(VATAmountLine."VAT Amount");
    end;

    local procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; VATBusinessPostingGroupCode: Code[20])
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroupCode, VATProductPostingGroup.Code);
        VATPostingSetup.Validate("VAT Identifier", VATProductPostingGroup.Code);
        VATPostingSetup.Validate("VAT %", LibraryRandom.RandInt(20));
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.Modify(true);
    end;

    local procedure CreateCustomer(VATBusPostingGroup: Code[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateVendor(VATBusPostingGroup: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateItem(VATProdPostingGroup: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        Item.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateCustomerWithDimension(var DefaultDimension: Record "Default Dimension"; VATBusPostingGroup: Code[20])
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        LibraryDimension: Codeunit "Library - Dimension";
    begin
        LibraryDimension.FindDimension(Dimension);
        LibraryDimension.FindDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, DATABASE::Customer, CreateCustomer(VATBusPostingGroup), DimensionValue."Dimension Code", DimensionValue.Code);
    end;

    local procedure CalculatePostingDate(DeltaDate: Date): Date
    begin
        exit(CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'M>', DeltaDate));
    end;

    local procedure UpdatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; CurrencyCode: Code[10]; VendorCrMemoNo: Code[35])
    begin
        PurchaseHeader.Validate("Currency Code", CurrencyCode);
        PurchaseHeader.Validate("Vendor Cr. Memo No.", VendorCrMemoNo);
        PurchaseHeader.Modify(true);
    end;

    local procedure UpdateGeneralLedgerSetup(PrintVATSpecInLCY: Boolean) OldPrintVATSpecInLCY: Boolean
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        OldPrintVATSpecInLCY := GeneralLedgerSetup."Print VAT specification in LCY";
        GeneralLedgerSetup."Print VAT specification in LCY" := PrintVATSpecInLCY;
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; var OldVATPercent: Decimal; VATPercent: Decimal)
    begin
        OldVATPercent := VATPostingSetup."VAT %";
        VATPostingSetup.Validate("VAT %", VATPercent);
        VATPostingSetup.Modify(true);
    end;

    local procedure RunReturnOrderConfirmation(SalesHeader: Record "Sales Header"; ShowInternalInformation: Boolean; LogInteraction: Boolean)
    var
        ReturnOrderConfirmation: Report "Return Order Confirmation";
    begin
        Commit(); // Required to run report with request page.
        Clear(ReturnOrderConfirmation);
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type");
        SalesHeader.SetRange("No.", SalesHeader."No.");
        ReturnOrderConfirmation.SetTableView(SalesHeader);
        ReturnOrderConfirmation.InitializeRequest(ShowInternalInformation, LogInteraction);
        ReturnOrderConfirmation.Run();
    end;

    local procedure RunPurchCreditMemo(VendorCrMemoNo: Code[35])
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchaseCreditMemo: Report "Purchase - Credit Memo";
    begin
        Commit();
        Clear(PurchaseCreditMemo);
        PurchCrMemoHdr.SetRange("Vendor Cr. Memo No.", VendorCrMemoNo);
        PurchCrMemoHdr.FindFirst();
        PurchaseCreditMemo.SetTableView(PurchCrMemoHdr);
        PurchaseCreditMemo.Run();
    end;

    local procedure SaveCustomerBalanceToDate(SalesHeader: Record "Sales Header"; AmountLCY: Boolean; Unapplied: Boolean; ShowEntriesWithZeroBalance: Boolean)
    var
        Customer: Record Customer;
        CustomerBalanceToDate: Report "Customer - Balance to Date";
    begin
        LibraryVariableStorage.Enqueue(AmountLCY);
        LibraryVariableStorage.Enqueue(Unapplied);
        LibraryVariableStorage.Enqueue(ShowEntriesWithZeroBalance);

        // Exercise.
        Commit(); // Required to run report with request page.
        Clear(CustomerBalanceToDate);
        Customer.SetRange("No.", SalesHeader."Bill-to Customer No.");
        Customer.SetRange("Date Filter", SalesHeader."Posting Date");
        CustomerBalanceToDate.SetTableView(Customer);
        CustomerBalanceToDate.InitializeRequest(AmountLCY, false, Unapplied, WorkDate());
        CustomerBalanceToDate.Run();
    end;

    local procedure SelectGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        // Select General Journal Batch and clear General Journal Lines to make sure that no line exist before creating
        // General Journal Lines.
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch)
    end;

    local procedure VerifySalesLineOnReport(SalesLine: Record "Sales Line")
    begin
        LibraryReportDataset.AssertElementWithValueExists('Qty_SalesLine', SalesLine.Quantity);
        LibraryReportDataset.AssertElementWithValueExists('UnitPrice_SalesLine', SalesLine."Unit Price");
        LibraryReportDataset.AssertElementWithValueExists('VATIdentifier_SalesLine', SalesLine."VAT Identifier");
        LibraryReportDataset.AssertElementWithValueExists('SalesLineLineAmt', SalesLine."Line Amount");
    end;

    local procedure VerifyVATAmountLineOnReport(VATAmountLine: Record "VAT Amount Line")
    begin
        LibraryReportDataset.AssertElementWithValueExists('VATAmtLineVATPercentage', VATAmountLine."VAT %");
        LibraryReportDataset.AssertElementWithValueExists('VATAmtLineInvDiscAmt', VATAmountLine."Invoice Discount Amount");
        LibraryReportDataset.AssertElementWithValueExists('VATAmtLineInvDiscBaseAmt', VATAmountLine."Inv. Disc. Base Amount");
        LibraryReportDataset.AssertElementWithValueExists('VATAmtLineVATBase', VATAmountLine."VAT Base");
        LibraryReportDataset.AssertElementWithValueExists('VATAmtLineVATAmt', VATAmountLine."VAT Amount");
    end;

    local procedure VerifyPurchaseCreditMemoReport(VATIdentifier: Code[20]; VATAmount: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('VATAmtLineVATIdentifier_VATCounter', VATIdentifier);
        LibraryReportDataset.AssertElementWithValueExists('VATAmountLineVATAmount', VATAmount);
        LibraryReportDataset.AssertElementWithValueExists('VATAmtLineVATIdentifier_VATCounterLCY', VATIdentifier);
        LibraryReportDataset.AssertElementWithValueExists('VALVATAmountLCY', VATAmount);
    end;

    local procedure CreateSalesDocumentWithZeroAmount(
       var SalesHeader: Record "Sales Header";
       DocumentType: Enum "Sales Document Type";
       CurrencyCode: Code[10];
       CustomerNo: Code[20];
       Quantity: Integer)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", '', Quantity);
        SalesLine.Modify(true);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmMessageHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReportHandlerBlanketSalesOrder(var BlanketSalesOrder: TestRequestPage "Blanket Sales Order")
    begin
        BlanketSalesOrder.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReportHandlerReturnOrderConfirmation(var ReturnOrderConfirmation: TestRequestPage "Return Order Confirmation")
    begin
        ReturnOrderConfirmation.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RepHandlerReturnOrderConfirmation(var ReturnOrderConfirmation: TestRequestPage "Return Order Confirmation")
    begin
        ReturnOrderConfirmation.SaveAsExcel(LibraryReportValidation.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReportHandlerCustomerSummaryAging(var CustomerSummaryAging: TestRequestPage "Customer - Summary Aging")
    begin
        CustomerSummaryAging.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReportHandlerArchivedSalesOrder(var ArchivedSalesOrder: TestRequestPage "Archived Sales Order")
    begin
        ArchivedSalesOrder.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReportHandlerPurchCreditMemo(var PurchaseCreditMemo: TestRequestPage "Purchase - Credit Memo")
    begin
        PurchaseCreditMemo.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReportHandlerCustomerBalanceToDate(var CustomerBalancetoDate: TestRequestPage "Customer - Balance to Date")
    var
        AmountLCY: Variant;
        Unapplied: Variant;
    begin
        LibraryVariableStorage.Dequeue(AmountLCY);
        LibraryVariableStorage.Dequeue(Unapplied);
        CustomerBalancetoDate.PrintAmountInLCY.SetValue(AmountLCY);
        CustomerBalancetoDate.PrintUnappliedEntries.SetValue(Unapplied);
        CustomerBalancetoDate.ShowEntriesWithZeroBalance.SetValue(LibraryVariableStorage.DequeueBoolean());
        CustomerBalancetoDate.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}
