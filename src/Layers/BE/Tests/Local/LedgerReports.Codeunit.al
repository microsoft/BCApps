codeunit 144044 "Ledger Reports"
{
    // // [FEATURES] [Reports]
    // Test BE documents reports datasets

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        isInitialized: Boolean;
        NegativeCounter: Integer;
        TemplateNotFoundErr: Label 'Expected %1 in row %2, column %3 on worksheet %4', Comment = '%1 - Template Name, %2 - RowNo, %3 - ColumnNo';
        PageOneTxt: Label '1';
        PageTwoTxt: Label '2';
        WrongWorksheetNumberErr: Label 'The number of pages in the report differs from the expected.';

    [Test]
    [HandlerFunctions('SalesLedgerReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesLedgerReportDocNoSorting()
    var
        Customer: Record Customer;
        GLEntry: Record "G/L Entry";
        PostedSalesDocumentNo1: Code[20];
        PostedSalesDocumentNo2: Code[20];
    begin
        // [SCENARIO 348748] In Sales Ledger report G/L Entries are sorted by the Document No. prior to Posting Date
        Initialize();

        // [GIVEN] Created and posted two invoices: "Inv1" with DocNo=1 and Posting Date=03.01.20, "Inv2" with DocNo=2 and Posting Date=02.01.20
        LibrarySales.CreateCustomer(Customer);
        CreateAndPostSalesInvoiceForCustomerWithDate(PostedSalesDocumentNo1, Customer."No.", LibraryInventory.CreateItemNo(), WorkDate() + 1);
        CreateAndPostSalesInvoiceForCustomerWithDate(PostedSalesDocumentNo2, Customer."No.", LibraryInventory.CreateItemNo(), WorkDate());

        // [WHEN] Run Sales Ledger report for 2 days period
        LibraryVariableStorage.Enqueue('<2D>');
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(false);
        REPORT.Run(REPORT::"Sales Ledger", true, false);

        // [THEN] In report G/L entry for "Inv1" is ordered before "Inv2"
        GLEntry.SetRange("Source No.", Customer."No.");
        GLEntry.FindFirst();
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('GLAccNo_GLEntry', GLEntry."G/L Account No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('PrnDocno', PostedSalesDocumentNo1);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('PrnDocno', PostedSalesDocumentNo2);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PurchaseLedgerReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseLedgerReportDocNoSorting()
    var
        GLEntry: Record "G/L Entry";
        Vendor: Record Vendor;
        PostedSalesDocumentNo1: Code[20];
        PostedSalesDocumentNo2: Code[20];
    begin
        // [SCENARIO 348748] In Purchase Ledger report G/L Entries are sorted by the Document No. prior to Posting Date
        Initialize();

        // [GIVEN] Created and posted two invoices: "Inv1" with DocNo=1 and Posting Date=03.01.20, "Inv2" with DocNo=2 and Posting Date=02.01.20
        LibraryPurchase.CreateVendor(Vendor);
        CreateAndPostPurchaseInvoiceForVendorWithDate(PostedSalesDocumentNo1, Vendor."No.", LibraryInventory.CreateItemNo(), WorkDate() + 1);
        CreateAndPostPurchaseInvoiceForVendorWithDate(PostedSalesDocumentNo2, Vendor."No.", LibraryInventory.CreateItemNo(), WorkDate());

        // [WHEN] Run Purchase Ledger report for 2 days period
        LibraryVariableStorage.Enqueue('<2D>');
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(false);
        REPORT.Run(REPORT::"Purchase Ledger", true, false);

        // [THEN] In report G/L entry for "Inv1" is ordered before "Inv2"
        GLEntry.SetRange("Source No.", Vendor."No.");
        GLEntry.FindFirst();
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('GLAccountNo_GLEntry', GLEntry."G/L Account No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('PrnDocno', PostedSalesDocumentNo1);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('PrnDocno', PostedSalesDocumentNo2);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SalesLedgerReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesLedgerReportTest()
    begin
        Initialize();

        RunSalesLedgerReportTest(false);
    end;

    [Test]
    [HandlerFunctions('SalesLedgerReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesLedgerReportInLcyTest()
    begin
        Initialize();

        RunSalesLedgerReportTest(true);
    end;

    [Test]
    [HandlerFunctions('PurchaseLedgerReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseLedgerReportTest()
    begin
        Initialize();

        RunPurchaseLedgerReportTest(false);
    end;

    [Test]
    [HandlerFunctions('PurchaseLedgerReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseLedgerReportLcyTest()
    begin
        Initialize();

        RunPurchaseLedgerReportTest(true);
    end;

    [Test]
    [HandlerFunctions('GenLedgerReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure GenJournalLedgerReportTest()
    begin
        Initialize();

        RunGenJournalLedgerReportTest(false);
    end;

    [Test]
    [HandlerFunctions('GenLedgerReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure GenJournalLedgerReportLcyTest()
    begin
        Initialize();

        RunGenJournalLedgerReportTest(true);
    end;

    [Test]
    [HandlerFunctions('CentralizationLedgerReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CentralizationLedgerReportTest()
    begin
        Initialize();

        RunCentralizationLedgerReportTest(false);
    end;

    [Test]
    [HandlerFunctions('CentralizationLedgerReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CentralizationLedgerReportWithDetailsTest()
    begin
        Initialize();

        RunCentralizationLedgerReportTest(true);
    end;

    [Test]
    [HandlerFunctions('FinancialLedgerReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure FinancialLedgerReportTest()
    begin
        Initialize();

        RunFinancialLedgerReportTest(false);
    end;

    [Test]
    [HandlerFunctions('FinancialLedgerReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure FinancialLedgerReportLcyTest()
    begin
        Initialize();

        RunFinancialLedgerReportTest(true);
    end;

    [Test]
    [HandlerFunctions('PHPurchaseLedger')]
    [Scope('OnPrem')]
    procedure PurchaseLedgerReportWithDiffJournalTemplates()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        TemplateName: array[2] of Code[10];
    begin
        // [SCENARIO 378797] Run Purchase Ledger Report with different Journal Templates
        Initialize();

        // [GIVEN] Create G/L Entry with "Journal Template Name" = "N1"
        // [GIVEN] Create G/L Entry with "Journal Template Name" = "N2"
        TemplateName[1] := CreateGLEntryWithGenJnlTemplate();
        TemplateName[2] := CreateGLEntryWithGenJnlTemplate();

        // [WHEN] Save Purchase Ledger Report on Workdate
        Commit();
        GenJournalTemplate.SetFilter(Name, TemplateName[1] + '|' + TemplateName[2]);
        REPORT.Run(REPORT::"Purchase Ledger", true, false, GenJournalTemplate);

        // [THEN] Verify "Journal Template Name" = "N1" on Sheet1 and "N2" on Sheet3
        VerifyPurchaseLedgerWithDiffJournalTemplate(TemplateName);
    end;

    [Test]
    [HandlerFunctions('PurchaseLedgerExcelReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseLedgerReportPrintsPageNumbers()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        TemplateName: array[2] of Code[10];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 310256] Purchase Ledger report prints correct page number for every page group.
        Initialize();

        // [GIVEN] Two G/L entries.
        TemplateName[1] := CreateGLEntryWithGenJnlTemplate();
        TemplateName[2] := CreateGLEntryWithGenJnlTemplate();
        Commit();

        // [WHEN] Run "Purchase Ledger" report (opens handler - PurchaseLedgerExcelReportRequestPageHandler).
        GenJournalTemplate.SetFilter(Name, TemplateName[1] + '|' + TemplateName[2]);
        REPORT.Run(REPORT::"Purchase Ledger", true, false, GenJournalTemplate);
        LibraryReportValidation.OpenExcelFile();

        // [THEN] Number of pages = 4.
        Assert.AreEqual(4, LibraryReportValidation.CountWorksheets(), WrongWorksheetNumberErr);
        // [THEN] The first page = 1.
        LibraryReportValidation.VerifyCellValueByRef('R', 8, 1, PageOneTxt);
        // [THEN] The second page = 2.
        LibraryReportValidation.VerifyCellValueByRef('R', 32, 2, PageTwoTxt);
        // [THEN] The third page = 1.
        LibraryReportValidation.VerifyCellValueByRef('R', 54, 3, PageOneTxt);
        // [THEN] The fourth page = 2.
        LibraryReportValidation.VerifyCellValueByRef('R', 78, 4, PageTwoTxt);
    end;

    [Test]
    [HandlerFunctions('SalesLedgerReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesLedgerReportWithDeferralEntries()
    var
        DeferralTemplate: Record "Deferral Template";
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [Sales] [Deferral]
        // [SCENARIO 422924] Print Sales Ledger report with deferral G/L Entries
        Initialize();

        // [GIVEN] Posted sales invoice with deferral entries
        LibraryERM.CreateDeferralTemplate(
          DeferralTemplate,
          DeferralTemplate."Calc. Method"::"Straight-Line", DeferralTemplate."Start Date"::"Beginning of Period", 2);
        CreateAndPostSalesInvoiceForCustomerWithDate(
          InvoiceNo, LibrarySales.CreateCustomerNo(), CreateItemWithDeferralCode(DeferralTemplate."Deferral Code"), WorkDate());

        // [WHEN] Run Sales Ledger report with ExcludeDeferralEntries = No
        LibraryVariableStorage.Enqueue('<2D>');
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(false); // ExcludeDeferralEntries
        REPORT.Run(REPORT::"Sales Ledger", true, false);

        // [THEN] Lines with deferral G/L account are exported
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('PrnDocno', InvoiceNo);
        LibraryReportDataset.AssertElementWithValueExists('GLAccNo_GLEntry', DeferralTemplate."Deferral Account");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SalesLedgerReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesLedgerReportExcludingDeferralEntries()
    var
        DeferralTemplate: Record "Deferral Template";
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [Sales] [Deferral]
        // [SCENARIO 422924] Print Sales Ledger report excluding deferral G/L Entries
        Initialize();

        // [GIVEN] Posted sales invoice with deferral entries
        LibraryERM.CreateDeferralTemplate(
          DeferralTemplate,
          DeferralTemplate."Calc. Method"::"Straight-Line", DeferralTemplate."Start Date"::"Beginning of Period", 2);
        CreateAndPostSalesInvoiceForCustomerWithDate(
          InvoiceNo, LibrarySales.CreateCustomerNo(), CreateItemWithDeferralCode(DeferralTemplate."Deferral Code"), WorkDate());

        // [WHEN] Run Sales Ledger report with ExcludeDeferralEntries = Yes
        LibraryVariableStorage.Enqueue('<2D>');
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(true); // ExcludeDeferralEntries
        REPORT.Run(REPORT::"Sales Ledger", true, false);

        // [THEN] Lines with deferral G/L account are not exported
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('PrnDocno', InvoiceNo);
        LibraryReportDataset.AssertElementWithValueNotExist('GLAccNo_GLEntry', DeferralTemplate."Deferral Account");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PurchaseLedgerReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseLedgerReportWithDeferralEntries()
    var
        DeferralTemplate: Record "Deferral Template";
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Deferral]
        // [SCENARIO 422924] Print Sales Ledger report with deferral G/L Entries
        Initialize();

        // [GIVEN] Posted purchase invoice with deferral entries
        LibraryERM.CreateDeferralTemplate(
          DeferralTemplate,
          DeferralTemplate."Calc. Method"::"Straight-Line", DeferralTemplate."Start Date"::"Beginning of Period", 2);
        CreateAndPostPurchaseInvoiceForVendorWithDate(
          InvoiceNo, LibraryPurchase.CreateVendorNo(), CreateItemWithDeferralCode(DeferralTemplate."Deferral Code"), WorkDate());

        // [WHEN] Run Purchase Ledger report with ExcludeDeferralEntries = No
        LibraryVariableStorage.Enqueue('<2D>');
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(false); // ExcludeDeferralEntries
        REPORT.Run(REPORT::"Purchase Ledger", true, false);

        // [THEN] Lines with deferral G/L account are exported
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('PrnDocno', InvoiceNo);
        LibraryReportDataset.AssertElementWithValueExists('GLAccountNo_GLEntry', DeferralTemplate."Deferral Account");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PurchaseLedgerReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseLedgerReportExcludingDeferralEntries()
    var
        DeferralTemplate: Record "Deferral Template";
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Deferral]
        // [SCENARIO 422924] Print Sales Ledger report excluding deferral G/L Entries
        Initialize();

        // [GIVEN] Posted purchase invoice with deferral entries
        LibraryERM.CreateDeferralTemplate(
          DeferralTemplate,
          DeferralTemplate."Calc. Method"::"Straight-Line", DeferralTemplate."Start Date"::"Beginning of Period", 2);
        CreateAndPostPurchaseInvoiceForVendorWithDate(
          InvoiceNo, LibraryPurchase.CreateVendorNo(), CreateItemWithDeferralCode(DeferralTemplate."Deferral Code"), WorkDate());

        // [WHEN] Run Purchase Ledger report with ExcludeDeferralEntries = Yes
        LibraryVariableStorage.Enqueue('<2D>');
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(true); // ExcludeDeferralEntries
        REPORT.Run(REPORT::"Purchase Ledger", true, false);

        // [THEN] Lines with deferral G/L account are not exported
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('PrnDocno', InvoiceNo);
        LibraryReportDataset.AssertElementWithValueNotExist('GLAccountNo_GLEntry', DeferralTemplate."Deferral Account");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PurchaseLedgerReportRequestPageHandler')]
    procedure PurchaseLedgerReportStartingDateAsGLSetupDefaultVATDate()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        VATReportingDate: Enum "VAT Reporting Date";
    begin
        // [SCENARIO 562005] Print Purchase Ledger report for Default VAT Date as "Document Date" on General Ledger Setup.
        Initialize();

        //[GIVEN] Update General Ledger Setup with Default VAT Date as "Document Date".
        UpdateVATReportingDateInGLSetup(VATReportingDate::"Document Date");

        // [GIVEN] Create Posting Setup.
        CreateGeneralPostingSetup(GeneralPostingSetup);
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandInt(20));

        // [GIVEN] Create Purchase Order.
        CreatePurchaseDocument(PurchaseHeader, PurchLine, GeneralPostingSetup, VATPostingSetup, PurchaseHeader."Document Type"::Invoice);

        //[GIVEN] Update Purchase Order "Posting Data" and "VAT Reporting Date".
        PurchaseHeader.Validate("Posting Date", WorkDate());
        PurchaseHeader.Validate("VAT Reporting Date", CalcDate('<-7D>', WorkDate()));
        PurchaseHeader.Modify(true);

        //[GIVEN] Post Purchase Order.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] Run Purchase Ledger report
        LibraryVariableStorage.Enqueue('<2M>');
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(false);
        Report.Run(Report::"Purchase Ledger", true, false);

        // [THEN] Verify "Starting Date" is "Posting Date" on Purchase Ledger report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('FormattedPrnDate', Format(WorkDate()));
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    var
        ObjectOptions: Record "Object Options";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Ledger Reports");

        ObjectOptions.SetRange("Object Type", ObjectOptions."Object Type"::Report);
        ObjectOptions.SetFilter("Object ID", '%1|%2', Report::"Sales Ledger", Report::"Purchase Ledger");
        ObjectOptions.Deleteall();

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Ledger Reports");

        LibrarySales.SetCreditWarningsToNoWarnings();
        LibrarySales.SetStockoutWarning(false);

        isInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Ledger Reports");
    end;

    local procedure CreateAndPostSalesInvoiceForCustomerWithDate(var DocumentNo: Code[20]; CustomerNo: Code[20]; ItemNo: Code[20]; PostingDate: Date)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, 1);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreateAndPostPurchaseInvoiceForVendorWithDate(var DocumentNo: Code[20]; VendorNo: Code[20]; ItemNo: Code[20]; PostingDate: Date)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        PurchaseHeader.Validate("Posting Date", PostingDate);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, 1);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure RunSalesLedgerReportTest(UseLocalCurrency: Boolean)
    var
        GLEntry: Record "G/L Entry";
        VATEntry: Record "VAT Entry";
        SalesSetup: Record "Sales & Receivables Setup";
        GenJournalTemplate: Record "Gen. Journal Template";
        VariantValue: Variant;
        PostedSalesDocumentNo: Code[20];
    begin
        // Setup: Post sales order for a customer with VAT Registration No. set.
        PostedSalesDocumentNo := CreateAndPostSalesInvoiceWithVAT();

        GLEntry.SetRange("Document No.", PostedSalesDocumentNo);
        Assert.AreEqual(3, GLEntry.Count, 'Expected to find 3 G/L Entries.');
        VATEntry.SetRange("Document No.", PostedSalesDocumentNo);
        Assert.AreEqual(1, VATEntry.Count, 'Expected to find 1 VAT Entry.');
        SalesSetup.Get();
        GenJournalTemplate.Get(SalesSetup."S. Invoice Template Name");
        GenJournalTemplate.SetRecFilter();
        // Excersise report
        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue('<1D>');
        LibraryVariableStorage.Enqueue(UseLocalCurrency); // Use local currency
        LibraryVariableStorage.Enqueue(false);
        Commit();
        REPORT.Run(REPORT::"Sales Ledger", true, false, GenJournalTemplate);

        // Validate:
        // - Check that the Local UseAmtsInAddCurr is set as expected.
        // - Validate the currency caption is present as expected
        // - Check the is one credit and one debit row pr. G/L Entry.
        // - Validate the credit and debit amount matches
        // - Check the used VAT Bus. Posting Group is in the report.
        LibraryReportDataset.LoadDataSetFile();

        LibraryReportDataset.Reset();
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.GetElementValueInCurrentRow('UseAmtsInAddCurr', VariantValue);
        Assert.AreEqual(UseLocalCurrency, VariantValue, 'Expected the UseAmtsInAddCurr to be set correctly.');
        LibraryReportDataset.Reset();
        LibraryReportDataset.MoveToRow(2);
        LibraryReportDataset.GetElementValueInCurrentRow('CurrCodeCaption', VariantValue);

        if UseLocalCurrency then
            Assert.AreNotEqual('', VariantValue, 'Expected currency code caption to be present.');

        GLEntry.FindSet();
        repeat
            LibraryReportDataset.Reset();
            LibraryReportDataset.SetRange('EntryNo_GLEntry', GLEntry."Entry No.");
            Assert.AreEqual(1, LibraryReportDataset.RowCount(), 'Expected to find one debit row pr. G/L Entry');
            LibraryReportDataset.GetNextRow();
            LibraryReportDataset.GetElementValueInCurrentRow('DebitAmt_GLEntry', VariantValue);

            LibraryReportDataset.Reset();
            LibraryReportDataset.SetRange('EntryNo_GLEntry2', GLEntry."Entry No.");
            Assert.AreEqual(1, LibraryReportDataset.RowCount(), 'Expected to find one cedit row pr. G/L Entry');
            LibraryReportDataset.GetNextRow();
            LibraryReportDataset.AssertCurrentRowValueEquals('DebitAmt_GLEntry2', VariantValue);
        until GLEntry.Next() = 0;

        VATEntry.FindSet();
        repeat
            LibraryReportDataset.Reset();
            LibraryReportDataset.SetRange('EntryNo_VATEntry', VATEntry."Entry No.");
            Assert.AreEqual(1, LibraryReportDataset.RowCount(), 'Expected to fund a row for each VATEntry');
            LibraryReportDataset.GetNextRow();
            LibraryReportDataset.AssertCurrentRowValueEquals('VATBusPostGroup_VATEntry', VATEntry."VAT Bus. Posting Group");
            LibraryReportDataset.AssertCurrentRowValueEquals('VATProdPostGroup_VATEntry', VATEntry."VAT Prod. Posting Group");
        until VATEntry.Next() = 0;
    end;

    local procedure RunPurchaseLedgerReportTest(UseLocalCurrency: Boolean)
    var
        GLEntry: Record "G/L Entry";
        VATEntry: Record "VAT Entry";
        SourceCodeSetup: Record "Source Code Setup";
        VariantValue: Variant;
        PostedPurchaseDocumentNo: Code[20];
        DebitSum: Decimal;
        CreditSum: Decimal;
        RowIndex: Integer;
    begin
        // Setup: Post purchase order and credit memo for a vendor with VAT Registration No. set.
        PostedPurchaseDocumentNo := CreateAndPostPurchaseInvoiceWithVAT();
        CreateAndPostPurchaseCreditMemoWithVAT();
        SourceCodeSetup.Get();
        GLEntry.SetRange("Document No.", PostedPurchaseDocumentNo);
        Assert.AreEqual(3, GLEntry.Count, 'Expected to find 3 G/L Entries.');
        VATEntry.SetRange("Document No.", PostedPurchaseDocumentNo);
        Assert.AreEqual(1, VATEntry.Count, 'Expected to find 1 VAT Entry.');

        // Excersise report
        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue('<1D>');
        LibraryVariableStorage.Enqueue(UseLocalCurrency); // Use local currency
        LibraryVariableStorage.Enqueue(false);
        Commit();
        REPORT.Run(REPORT::"Purchase Ledger", true, false);

        // Validate:
        // - Check that the Local UseAmtsInAddCurr is set as expected.
        // - Validate the currency caption is present as expected
        // - Check the sum if credit and debit is the same
        LibraryReportDataset.LoadDataSetFile();

        LibraryReportDataset.Reset();
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.GetElementValueInCurrentRow('UseAmtsInAddCurr', VariantValue);
        Assert.AreEqual(UseLocalCurrency, VariantValue, 'Expected the UseAmtsInAddCurr to be set correctly.');
        LibraryReportDataset.Reset();
        LibraryReportDataset.MoveToRow(2);
        LibraryReportDataset.GetElementValueInCurrentRow('CurrencyCodeCaption', VariantValue);
        if UseLocalCurrency then
            Assert.AreNotEqual('', VariantValue, 'Expected currency code caption to be present.');

        LibraryReportDataset.Reset();
        DebitSum := LibraryReportDataset.Sum('DebitAmount_GLEntry');
        CreditSum := LibraryReportDataset.Sum('CreditAmount_GLEntry');
        Assert.AreEqual(CreditSum, DebitSum, 'Expected sum of credit and debit to be the equal.');

        GLEntry.Reset();
        GLEntry.SetRange("Posting Date", WorkDate());
        GLEntry.SetRange("Source Code", SourceCodeSetup.Purchases);
        GLEntry.FindSet();
        repeat
            RowIndex := LibraryReportDataset.FindRow('GLEntry2EntryNo', GLEntry."Entry No.");
            if (GLEntry."Debit Amount" > 0) or (GLEntry."Credit Amount" > 0) or UseLocalCurrency then
                Assert.AreNotEqual(-1, RowIndex, 'Expected to find G/L Entry in dataset')
            else
                Assert.AreEqual(-1, RowIndex, 'Did not expect to find a G/L Entry with debit and credit amount 0 in the dataset');
        until GLEntry.Next() = 0;

        ValidateGLAccountDescription('GLEntry2GLAccountNo', 'GLEntry2Description');
    end;

    local procedure RunGenJournalLedgerReportTest(UseLocalCurrency: Boolean)
    var
        VATStatementLine: Record "VAT Statement Line";
        VATEntry: Record "VAT Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GenJnlLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        VariantValue: Variant;
        GLTotalDebit: Decimal;
        GLTotalCredit: Decimal;
        PostedSalesDocumentNo: Code[20];
        PostedPurchaseDocumentNo: Code[20];
        PostedPurchaseCreditMemoNo: Code[20];
        RowIndex: Integer;
    begin
        // Setup: Post Sales order, purchase order and purchase credit memo for a customer/vendor with VAT Registration No. set.
        PostedSalesDocumentNo := CreateAndPostSalesInvoiceWithVAT();
        FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, PostedSalesDocumentNo);
        CustLedgerEntry.CalcFields(Amount);
        CreateAndPostGenJnlLine(CustLedgerEntry."Customer No.", GenJnlLine."Account Type"::Customer, CustLedgerEntry.Amount);

        PostedPurchaseDocumentNo := CreateAndPostPurchaseInvoiceWithVAT();
        CreateAndPostReceivalForInvoice(PostedPurchaseDocumentNo);
        FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, PostedPurchaseDocumentNo);
        VendorLedgerEntry.CalcFields(Amount);
        CreateAndPostGenJnlLine(VendorLedgerEntry."Vendor No.", GenJnlLine."Account Type"::Vendor, VendorLedgerEntry.Amount);

        PostedPurchaseCreditMemoNo := CreateAndPostPurchaseCreditMemoWithVAT();
        FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::"Credit Memo", PostedPurchaseCreditMemoNo);
        VendorLedgerEntry.CalcFields(Amount);
        CreateAndPostGenJnlLine(VendorLedgerEntry."Vendor No.", GenJnlLine."Account Type"::Vendor, VendorLedgerEntry.Amount * -1);
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::General);
        GenJournalTemplate.FindFirst();
        // Fake Credit memo VAT Entry.
        VATEntry.Init();
        NegativeCounter := NegativeCounter - 1;
        VATEntry."Entry No." := NegativeCounter;
        VATEntry."Posting Date" := WorkDate();
        VATEntry.Amount := 10;
        VATEntry."Journal Templ. Name" := GenJournalTemplate.Name;
        VATEntry."Document Type" := VATEntry."Document Type"::"Credit Memo";
        VATEntry."Document No." := PostedSalesDocumentNo;
        VATEntry.Insert();

        // Excersise report
        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(UseLocalCurrency); // Use local currency
        Commit();
        REPORT.Run(REPORT::"General Ledger", true, false);

        // Validate:
        // - Check that the Local UseAmtsInAddCurr is set as expected.
        // - Validate the currency caption is present as expected
        // - Check the sum if credit and debit gl entry is the same
        LibraryReportDataset.LoadDataSetFile();

        LibraryReportDataset.Reset();
        LibraryReportDataset.SetRange('UseAmtsInAddCurr', UseLocalCurrency);
        Assert.AreNotEqual(0, LibraryReportDataset.RowCount(), 'Expected UseAmpsInAddCurr to be set correctly');
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.GetElementValueInCurrentRow('CurrencyCodeCaption', VariantValue);
        if UseLocalCurrency then
            Assert.AreNotEqual('', VariantValue, 'Expected currency code caption to be present.');

        LibraryReportDataset.Reset();
        GLTotalDebit := LibraryReportDataset.Sum('DebitAmt_GLEntry');
        GLTotalCredit := LibraryReportDataset.Sum('CreditAmt_GLEntry');
        Assert.AreEqual(GLTotalCredit, GLTotalDebit, 'Expected the sum of GL Entry credit and debit are equal');

        VATStatementLine.SetRange("Date Filter", WorkDate());
        VATStatementLine.FindSet();
        repeat
            RowIndex := LibraryReportDataset.FindRow('RowNo_VATStmtLine', VATStatementLine."Row No.");
            Assert.AreNotEqual(0, RowIndex, 'Expected to find VATStatementLine in dataset.');
        until VATStatementLine.Next() = 0;

        ValidateGLAccountDescription('GLAccNo_GLEntry2', 'Desc_GLEntry2');
    end;

    local procedure RunCentralizationLedgerReportTest(ShowGLDetails: Boolean)
    var
        GLEntry: Record "G/L Entry";
        GLAccount: Record "G/L Account";
        GenJournalTemplate: Record "Gen. Journal Template";
        TotalCreditAmount: Variant;
        TotalDebitAmount: Variant;
        TotalMessage: Variant;
        PostingDate: Date;
        FirstAmount: Decimal;
        SecondAmount: Decimal;
    begin
        // Setup: Create Fake GL Entries
        PostingDate := CalcDate('<CD>+<10Y>'); // Choose a date far out in the future where we do not expect any G/L Entries
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGLAccount(GLAccount);

        FirstAmount := LibraryRandom.RandDec(10000, 2);
        SecondAmount := LibraryRandom.RandDec(10000, 2);

        // Remove any entries
        GLEntry.SetRange("Posting Date", PostingDate);
        GLEntry.DeleteAll(true);

        // Create credit ledger entry split over two records with the same template name
        CreateMinimalGLEntry(PostingDate,
          GenJournalTemplate."Source Code",
          GenJournalTemplate.Name,
          GLAccount."No.",
          FirstAmount,
          0);
        CreateMinimalGLEntry(PostingDate,
          GenJournalTemplate."Source Code",
          GenJournalTemplate.Name,
          GLAccount."No.",
          SecondAmount,
          0);

        // Create the debit entry and change template + account
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGLAccount(GLAccount);
        CreateMinimalGLEntry(PostingDate,
          GenJournalTemplate."Source Code",
          GenJournalTemplate.Name,
          GLAccount."No.",
          0,
          FirstAmount + SecondAmount);

        // Create one G/L Entry with "unknown" G/L Account no.
        CreateMinimalGLEntry(PostingDate,
          GenJournalTemplate."Source Code",
          GenJournalTemplate.Name,
          'N/A',
          FirstAmount,
          FirstAmount);

        // Excersise report
        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(PostingDate); // Posting Date
        LibraryVariableStorage.Enqueue(ShowGLDetails); // Show GL details
        Commit();
        REPORT.Run(REPORT::"Centralization Ledger", true, false);

        // Validate:
        // - Check totals match and are as expected
        // - Check the total message changes when showing details
        LibraryReportDataset.LoadDataSetFile();

        LibraryReportDataset.GetLastRow();
        LibraryReportDataset.GetElementValueInCurrentRow('GrTotalCredit', TotalCreditAmount);
        LibraryReportDataset.GetElementValueInCurrentRow('GrTotalDebit', TotalDebitAmount);
        Assert.AreEqual(FirstAmount + SecondAmount + FirstAmount,
          TotalCreditAmount,
          'Total credit amount is outside the expected amount');
        Assert.AreEqual(TotalCreditAmount, TotalDebitAmount, 'Expected credit and debit totals to match');

        LibraryReportDataset.GetElementValueInCurrentRow('TotalMessage', TotalMessage);
        if ShowGLDetails then
            Assert.AreEqual('Total', TotalMessage, 'Expetec the total message to be "Total" when printing details.')
        else
            Assert.AreNotEqual('Total',
              TotalMessage,
              'Expected the total message to be the Gen. Journal Template Name when not printing details.');
    end;

    local procedure RunFinancialLedgerReportTest(UseLcy: Boolean)
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        Customer: Record Customer;
        Vendor: Record Vendor;
        BankAccount: Record "Bank Account";
        VATPostingSetup: Record "VAT Posting Setup";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        GLAccount: Record "G/L Account";
        VATGroupCode: Variant;
        CreditAmounts: array[2] of Decimal;
        DebitAmounts: array[2] of Decimal;
        RowIndex: Integer;
    begin
        // Setup:
        CreateGenJnlTemplate(GenJournalTemplate,
          GenJournalTemplate.Type::Financial, "Gen. Journal Template Type"::General, CreateGLAccount());

        DebitAmounts[1] := LibraryRandom.RandDec(10000, 2);
        DebitAmounts[2] := LibraryRandom.RandDec(10000, 2);
        CreditAmounts[1] := LibraryRandom.RandDec(10000, 2) * -1;
        CreditAmounts[2] := LibraryRandom.RandDec(10000, 2) * -1;

        // Create and post Customer finance gen. journal line.
        LibrarySales.CreateCustomer(Customer);
        CreateAndPostGeneralJournalBatch(GenJournalTemplate,
          GenJournalBatch."Template Type"::Sales,
          GenJournalBatch."Bal. Account Type"::"G/L Account",
          GenJournalLine."Document Type"::"Finance Charge Memo",
          GenJournalLine."Bal. Account Type"::Customer,
          Customer."No.",
          DebitAmounts[1], '', '', "General Posting Type"::" ");

        // Create and post Vendor finance gen. journal line.
        LibraryPurchase.CreateVendor(Vendor);
        CreateAndPostGeneralJournalBatch(GenJournalTemplate,
          GenJournalBatch."Template Type"::Purchases,
          GenJournalBatch."Bal. Account Type"::"G/L Account",
          GenJournalLine."Document Type"::"Finance Charge Memo",
          GenJournalLine."Bal. Account Type"::Vendor,
          Vendor."No.",
          CreditAmounts[1], '', '', "General Posting Type"::" ");

        // Create and post GL account finance gen. journal line with VAT entries.
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup.Code, VATProductPostingGroup.Code);

        LibraryERM.CreateGLAccount(GLAccount);
        CreateAndPostGeneralJournalBatch(GenJournalTemplate,
          GenJournalBatch."Template Type"::General,
          GenJournalBatch."Bal. Account Type"::"G/L Account",
          GenJournalLine."Document Type"::"Finance Charge Memo",
          GenJournalLine."Bal. Account Type"::"G/L Account",
          GLAccount."No.",
          0,
          VATBusinessPostingGroup.Code,
          VATProductPostingGroup.Code,
          GenJournalLine."Gen. Posting Type"::Settlement);

        CreateAndPostGeneralJournalBatch(GenJournalTemplate,
          GenJournalBatch."Template Type"::General,
          GenJournalBatch."Bal. Account Type"::"G/L Account",
          GenJournalLine."Document Type"::"Credit Memo",
          GenJournalLine."Bal. Account Type"::"G/L Account",
          GLAccount."No.",
          CreditAmounts[2],
          VATBusinessPostingGroup.Code,
          VATProductPostingGroup.Code,
          GenJournalLine."Gen. Posting Type"::Settlement);

        // Creat eand Post bank acocunt journal line
        LibraryERM.CreateBankAccount(BankAccount);
        Clear(GenJournalTemplate);
        CreateGenJnlTemplate(GenJournalTemplate,
          GenJournalTemplate.Type::Financial,
          GenJournalTemplate."Bal. Account Type"::"Bank Account",
          BankAccount."No.");

        CreateAndPostGeneralJournalBatch(GenJournalTemplate,
          GenJournalBatch."Template Type"::Sales,
          GenJournalBatch."Bal. Account Type"::"Bank Account",
          GenJournalLine."Document Type"::"Finance Charge Memo",
          GenJournalLine."Bal. Account Type"::Customer,
          Customer."No.",
          DebitAmounts[2], '', '', "General Posting Type"::" ");

        // Excersise report
        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(UseLcy); // Use Lcy
        Commit();
        REPORT.Run(REPORT::"Financial Ledger", true, false);

        // Validate:
        // - The created amounts exists in the report data
        // - There is at least one row with VAT Posting groups and amount 0
        // - There only the second credit amount posting has vat posting group specified
        LibraryReportDataset.LoadDataSetFile();

        RowIndex := LibraryReportDataset.FindRow('CrAmt_GLEntry', CreditAmounts[1] * -1);
        Assert.AreNotEqual(-1, RowIndex, 'Expected to find credit amount ' + Format(CreditAmounts[1] * -1) + ' in dataset.');
        LibraryReportDataset.MoveToRow(RowIndex + 1); // FindRow returns .NET index so we add one (0 vs. 1 start)
        LibraryReportDataset.AssertCurrentRowValueEquals('VATBusPostingGrp_GLEntry', '');

        LibraryReportDataset.Reset();
        RowIndex := LibraryReportDataset.FindRow('CrAmt_GLEntry', CreditAmounts[2] * -1);
        Assert.AreNotEqual(-1, RowIndex, 'Expected to find credit amount ' + Format(CreditAmounts[2] * -1) + ' in dataset.');
        LibraryReportDataset.MoveToRow(RowIndex + 1); // FindRow returns .NET index so we add one (0 vs. 1 start)
        LibraryReportDataset.GetElementValueInCurrentRow('VATBusPostingGrp_GLEntry', VATGroupCode);
        Assert.AreNotEqual('', VATGroupCode, 'Expected the VATBusPoistingGrp_GLEntry element to have a value.');
        LibraryReportDataset.GetElementValueInCurrentRow('VATProdPostingGrp_GLEntry', VATGroupCode);
        Assert.AreNotEqual('', VATGroupCode, 'Expected the VATProdPostingGrp_GLEntry element to have a value.');

        LibraryReportDataset.Reset();
        RowIndex := LibraryReportDataset.FindRow('DebitAmt_GLEntry', DebitAmounts[1]);
        Assert.AreNotEqual(-1, RowIndex, 'Expected to find debit amount ' + Format(DebitAmounts[1]) + ' in dataset.');
        LibraryReportDataset.MoveToRow(RowIndex + 1); // FindRow returns .NET index so we add one (0 vs. 1 start)
        LibraryReportDataset.AssertCurrentRowValueEquals('VATBusPostingGrp_GLEntry', '');

        LibraryReportDataset.Reset();
        RowIndex := LibraryReportDataset.FindRow('DebitAmt_GLEntry', DebitAmounts[2]);
        Assert.AreNotEqual(-1, RowIndex, 'Expected to find debit amount ' + Format(DebitAmounts[2]) + ' in dataset.');
        LibraryReportDataset.MoveToRow(RowIndex + 1); // FindRow returns .NET index so we add one (0 vs. 1 start)
        LibraryReportDataset.AssertCurrentRowValueEquals('VATBusPostingGrp_GLEntry', '');

        ValidateGLAccountDescription('GLAccNo_GLEntry2', 'Desc_GLEntry2');
    end;

    local procedure CreateAndPostSalesInvoiceWithVAT(): Code[20]
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Create customer includes VAT
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(Item, LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        SalesHeader.Validate("Posting Date", WorkDate());
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);

        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateAndPostPurchaseInvoiceWithVAT() DocNo: Code[20]
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        CreateGeneralPostingSetup(GeneralPostingSetup);
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 25);
        CreatePurchaseDocument(PurchHeader, PurchLine, GeneralPostingSetup, VATPostingSetup, PurchHeader."Document Type"::Invoice);

        PurchHeader.Validate("Posting Date", WorkDate());
        PurchHeader.Modify(true);

        DocNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);
        VATPostingSetup.Delete();
    end;

    local procedure CreateAndPostPurchaseCreditMemoWithVAT() DocNo: Code[20]
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        CreateGeneralPostingSetup(GeneralPostingSetup);
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 25);
        CreatePurchaseDocument(PurchHeader, PurchLine, GeneralPostingSetup, VATPostingSetup, PurchHeader."Document Type"::"Credit Memo");

        PurchHeader.Validate("Vendor Cr. Memo No.", PurchHeader."No.");
        PurchHeader.Validate("Posting Date", WorkDate());
        PurchHeader.Modify(true);

        DocNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);
        VATPostingSetup.Delete();
    end;

    local procedure CreateAndPostGenJnlLine(AccountNo: Code[20]; AccountType: Enum "Gen. Journal Account Type"; Amount: Decimal): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateGenJnlLine(GenJournalLine, AccountNo, AccountType, Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine."Document No.");
    end;

    local procedure CreatePurchaseDocument(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; GenPostingSetup: Record "General Posting Setup"; VATPostingSetup: Record "VAT Posting Setup"; DocumentType: Enum "Purchase Document Type")
    begin
        LibraryPurchase.CreatePurchHeader(
          PurchHeader, DocumentType, CreateVendor(GenPostingSetup."Gen. Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group"));

        PurchHeader."Vendor Invoice No." := LibraryUtility.GenerateGUID();
        PurchHeader.Modify();

        CreatePurchaseLine(PurchLine,
          PurchHeader,
          GenPostingSetup."Gen. Prod. Posting Group",
          VATPostingSetup,
          LibraryRandom.RandDec(100, 2) * 100,
          LibraryRandom.RandDec(100, 2));
    end;

    local procedure CreatePurchaseLine(var PurchLine: Record "Purchase Line"; PurchHeader: Record "Purchase Header"; GenProdPostGroupCode: Code[20]; VATPostingSetup: Record "VAT Posting Setup"; Quantity: Decimal; DirectUnitCost: Decimal)
    var
        GLAccNo: Code[20];
    begin
        GLAccNo := CreateGLAccWithSetup(GenProdPostGroupCode, VATPostingSetup."VAT Prod. Posting Group");

        LibraryPurchase.CreatePurchaseLine(
          PurchLine, PurchHeader, PurchLine.Type::"G/L Account", GLAccNo, Quantity);
        PurchLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchLine.Modify(true);
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        exit(GLAccount."No.");
    end;

    local procedure CreateGenJnlTemplate(var GenJournalTemplate: Record "Gen. Journal Template"; Type: Enum "Gen. Journal Template Type"; BalAccountType: Enum "Gen. Journal Account Type"; BalAccountNo: Code[20])
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Type := Type;
        if BalAccountType <> BalAccountType::"G/L Account" then
            GenJournalTemplate."Bal. Account Type" := BalAccountType;
        GenJournalTemplate."Bal. Account No." := BalAccountNo;
        GenJournalTemplate.Modify(true);
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

    local procedure CreateVendor(GenBusPostGroupCode: Code[20]; VATBusPostingGroupCode: code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Gen. Bus. Posting Group", GenBusPostGroupCode);
        Vendor.Validate("VAT Bus. Posting Group", VATBusPostingGroupCode);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateGLAccWithSetup(GenProdPostGroupCode: Code[20]; VATProdPostGroupCode: Code[20]) GLAccNo: Code[20]
    begin
        GLAccNo := CreateGLAccount();
        UpdateGLAccWithSetup(GLAccNo, GenProdPostGroupCode, VATProdPostGroupCode);
        exit(GLAccNo);
    end;

    local procedure CreateGeneralPostingSetup(var GeneralPostingSetup: Record "General Posting Setup")
    var
        GenBusPostingGroup: Record "Gen. Business Posting Group";
        GenProdPostingGroup: Record "Gen. Product Posting Group";
    begin
        LibraryERM.CreateGenBusPostingGroup(GenBusPostingGroup);
        LibraryERM.CreateGenProdPostingGroup(GenProdPostingGroup);
        LibraryERM.CreateGeneralPostingSetup(GeneralPostingSetup, GenBusPostingGroup.Code, GenProdPostingGroup.Code);
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

    local procedure FindCustomerLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    begin
        CustLedgerEntry.SetRange("Document Type", DocumentType);
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        CustLedgerEntry.FindLast();
    end;

    local procedure FindVendorLedgerEntry(var VendLedgerEntry: Record "Vendor Ledger Entry"; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    begin
        VendLedgerEntry.SetRange("Document Type", DocumentType);
        VendLedgerEntry.SetRange("Document No.", DocumentNo);
        VendLedgerEntry.FindLast();
    end;

    local procedure CreateAndPostReceivalForInvoice(InvoiceNo: Code[20]) PaymentNo: Code[20]
    var
        VendLedgerEntry: Record "Vendor Ledger Entry";
        GenJnlLine: Record "Gen. Journal Line";
    begin
        FindVendorLedgerEntry(VendLedgerEntry, VendLedgerEntry."Document Type"::Invoice, InvoiceNo);
        VendLedgerEntry.CalcFields(Amount);
        PaymentNo := CreateAndPostGenJnlLine(VendLedgerEntry."Vendor No.", GenJnlLine."Account Type"::Vendor, VendLedgerEntry.Amount);
        exit(PaymentNo);
    end;

    local procedure CreateAndPostGeneralJournalBatch(var GenJournalTemplate: Record "Gen. Journal Template"; BatchTemplateType: Enum "Gen. Journal Template Type"; BatchBalAccountType: Enum "Gen. Journal Account Type"; LineDocumentType: Enum "Gen. Journal Account Type"; LineBalAccountType: Enum "Gen. Journal Account Type"; LineAccountNo: Code[20]; LineAmount: Decimal; VATBusinessPostingGroupCode: Code[20]; VATProductPostingGroupCode: Code[20]; GenPostingType: Enum "General Posting Type")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch."Template Type" := BatchTemplateType;
        GenJournalBatch."Bal. Account Type" := BatchBalAccountType;
        GenJournalBatch."Bal. Account No." := GenJournalTemplate."Bal. Account No.";
        GenJournalBatch.Modify(true);

        LibraryERM.CreateGeneralJnlLine(GenJournalLine,
          GenJournalTemplate.Name,
          GenJournalBatch.Name,
          LineDocumentType,
          LineBalAccountType,
          LineAccountNo,
          LineAmount);
        GenJournalLine."Bal. Account No." := GenJournalTemplate."Bal. Account No.";
        if VATBusinessPostingGroupCode <> '' then begin
            GenJournalLine."VAT Bus. Posting Group" := VATBusinessPostingGroupCode;
            GenJournalLine."VAT Prod. Posting Group" := VATProductPostingGroupCode;
            GenJournalLine."Gen. Posting Type" := GenPostingType;
        end;
        if GenJournalLine."Gen. Posting Type" = GenJournalLine."Gen. Posting Type"::Settlement then
            GenJournalLine."System-Created Entry" := true;
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateMinimalGLEntry(PostingDate: Date; SourceCode: Code[10]; GenJournalTemplateName: Code[10]; GLAccountNo: Code[20]; CreditAmount: Decimal; DebitAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        NegativeCounter := NegativeCounter - 1;
        GLEntry.Init();
        GLEntry."Entry No." := NegativeCounter;
        GLEntry."Posting Date" := PostingDate;
        GLEntry.Description := 'Minimal GL Entry';
        GLEntry."Source Code" := SourceCode;
        GLEntry."Journal Templ. Name" := GenJournalTemplateName;
        GLEntry."G/L Account No." := GLAccountNo;
        GLEntry."Credit Amount" := CreditAmount;
        GLEntry."Debit Amount" := DebitAmount;
        GLEntry.Insert(true);
    end;

    local procedure CreateItemWithDeferralCode(DeferralCode: Code[10]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Default Deferral Template Code", DeferralCode);
        Item.Validate("Unit Price", LibraryRandom.RandIntInRange(100, 200));
        Item.Validate("Last Direct Cost", LibraryRandom.RandIntInRange(100, 200));
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure ValidateGLAccountDescription(NoElementName: Text; DescriptionElementName: Text)
    var
        GLAccount: Record "G/L Account";
        VariantValue: Variant;
        GLAccountFound: Boolean;
    begin
        LibraryReportDataset.Reset();

        while LibraryReportDataset.GetNextRow() do
            if LibraryReportDataset.CurrentRowHasElement(NoElementName) then begin
                LibraryReportDataset.GetElementValueInCurrentRow(NoElementName, VariantValue);
                if Format(VariantValue) <> '' then begin
                    GLAccount.Get(VariantValue);
                    GLAccountFound := true;
                    LibraryReportDataset.GetElementValueInCurrentRow(DescriptionElementName, VariantValue);
                    Assert.AreEqual(GLAccount.Name, Format(VariantValue), 'Expected the description to match G/L Account');
                end;
            end;

        Assert.IsTrue(GLAccountFound, 'Expected to find at least one GL Account Number');
    end;

    local procedure CreateGLEntryWithGenJnlTemplate(): Code[10]
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GLEntry: Record "G/L Entry";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Type := GenJournalTemplate.Type::Purchases;
        GenJournalTemplate.Modify();
        GLEntry.Init();
        GLEntry."Entry No." := LibraryUtility.GetNewRecNo(GLEntry, GLEntry.FieldNo("Entry No."));
        GLEntry."Posting Date" := WorkDate();
        GLEntry."VAT Reporting Date" := WorkDate();
        GLEntry."Journal Templ. Name" := GenJournalTemplate.Name;
        GLEntry."G/L Account No." := LibraryUtility.GenerateGUID();
        GLEntry.Amount := LibraryRandom.RandDec(100, 2);
        GLEntry."Debit Amount" := GLEntry.Amount;
        GLEntry.Insert();
        exit(GenJournalTemplate.Name);
    end;

    local procedure VerifyPurchaseLedgerWithDiffJournalTemplate(TemplateName: array[2] of Code[10])
    var
        ValueText: Text;
    begin
        LibraryReportValidation.OpenFile();
        ValueText := LibraryReportValidation.GetValueByRef('A', 13, 1);
        Assert.AreNotEqual(-1, StrPos(ValueText, TemplateName[1]), StrSubstNo(TemplateNotFoundErr, TemplateName[1], 6, 'A', 1));
        ValueText := LibraryReportValidation.GetValueByRef('A', 59, 3);
        Assert.AreNotEqual(-1, StrPos(ValueText, TemplateName[2]), StrSubstNo(TemplateNotFoundErr, TemplateName[2], 6, 'A', 3));
    end;

    local procedure UpdateVATReportingDateInGLSetup(VATReportingDate: Enum "VAT Reporting Date")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."VAT Reporting Date" := VATReportingDate;
        GeneralLedgerSetup.Modify();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesLedgerReportRequestPageHandler(var SalesLedgerReport: TestRequestPage "Sales Ledger")
    var
        StartDate: Variant;
        UseLcy: Variant;
        Period: Variant;
        PeriodLength: DateFormula;
    begin
        // Start Date
        StartDate := WorkDate(); // Setting this to 0D should initialize the value to WorkDate but will cause a failure when the end date is calculated
        SalesLedgerReport.StartDate.SetValue(StartDate);
        // No. of Periods
        SalesLedgerReport.NoOfPeriods.SetValue(1); // Causes default value initialization
        // Period Length
        LibraryVariableStorage.Dequeue(Period);
        Evaluate(PeriodLength, Period);
        SalesLedgerReport.PeriodLength.SetValue(PeriodLength);
        // Start Page Number
        SalesLedgerReport.Startpage.SetValue(1);
        // Show amounts in
        LibraryVariableStorage.Dequeue(UseLcy);
        SalesLedgerReport.UseAmtsInAddCurr.SetValue(UseLcy);

        SalesLedgerReport.ExcludeDeferralEntries.SetValue(LibraryVariableStorage.DequeueBoolean());

        SalesLedgerReport.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseLedgerReportRequestPageHandler(var PurchaseLedgerReport: TestRequestPage "Purchase Ledger")
    var
        StartDate: Variant;
        UseLcy: Variant;
        Period: Variant;
        PeriodLength: DateFormula;
    begin
        // Start Date
        StartDate := WorkDate(); // Setting this to 0D should initialize the value to WorkDate but will cause a failure when the end date is calculated
        PurchaseLedgerReport.StartDate.SetValue(StartDate);
        // No. of Periods
        PurchaseLedgerReport.NoOfPeriods.SetValue(1); // Causes default value initialization
        // Period Length
        LibraryVariableStorage.Dequeue(Period);
        Evaluate(PeriodLength, Period);
        PurchaseLedgerReport.PeriodLength.SetValue(PeriodLength);
        // Start Page Number
        PurchaseLedgerReport.Startpage.SetValue(1);
        // Show amounts in
        LibraryVariableStorage.Dequeue(UseLcy);
        PurchaseLedgerReport.UseAmtsInAddCurr.SetValue(UseLcy);

        PurchaseLedgerReport.ExcludeDeferralEntries.SetValue(LibraryVariableStorage.DequeueBoolean());

        PurchaseLedgerReport.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseLedgerExcelReportRequestPageHandler(var PurchaseLedger: TestRequestPage "Purchase Ledger");
    var
        PeriodLength: DateFormula;
    begin
        PurchaseLedger.StartDate.SetValue(WorkDate());
        PurchaseLedger.NoOfPeriods.SetValue(1);
        Evaluate(PeriodLength, '<1D>');
        PurchaseLedger.PeriodLength.SetValue(PeriodLength);
        PurchaseLedger.Startpage.SetValue(1);
        PurchaseLedger.UseAmtsInAddCurr.SetValue(false);
        PurchaseLedger.SaveAsExcel(LibraryReportValidation.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GenLedgerReportRequestPageHandler(var GenLedgerReport: TestRequestPage "General Ledger")
    var
        StartDate: Variant;
        UseLcy: Variant;
        PeriodLength: DateFormula;
    begin
        // Start Date
        StartDate := WorkDate(); // Setting this to 0D should initialize the value to WorkDate but will cause a failure when the end date is calculated
        GenLedgerReport.StartDate.SetValue(StartDate);
        // No. of Periods
        GenLedgerReport.NoOfPeriods.SetValue(1); // Causes default value initialization
        // Period Length
        Evaluate(PeriodLength, '<1D>');
        GenLedgerReport.PeriodLength.SetValue(PeriodLength);
        // Start Page Number
        GenLedgerReport.Startpage.SetValue(1);
        // Show amounts in
        LibraryVariableStorage.Dequeue(UseLcy);
        GenLedgerReport.UseAmtsInAddCurr.SetValue(UseLcy);

        GenLedgerReport.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CentralizationLedgerReportRequestPageHandler(var CentralizationLedgerReport: TestRequestPage "Centralization Ledger")
    var
        ShowDetails: Variant;
        StartDate: Variant;
        PeriodLength: DateFormula;
    begin
        // Start Date
        LibraryVariableStorage.Dequeue(StartDate); // Dequeue posting date
        CentralizationLedgerReport.StartDate.SetValue(StartDate);
        // No. of Periods
        CentralizationLedgerReport.NoOfPeriods.SetValue(1); // Causes default value initialization
        // Period Length
        Evaluate(PeriodLength, '<1D>');
        CentralizationLedgerReport.PeriodLength.SetValue(PeriodLength);
        // Start Page Number
        CentralizationLedgerReport.Startpage.SetValue(1);
        // Show G/L details
        LibraryVariableStorage.Dequeue(ShowDetails);
        CentralizationLedgerReport.PrintDetail.SetValue(ShowDetails);

        CentralizationLedgerReport.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure FinancialLedgerReportRequestPageHandler(var FinancialLedgerReport: TestRequestPage "Financial Ledger")
    var
        StartDate: Variant;
        UseLcy: Variant;
        PeriodLength: DateFormula;
    begin
        // Start Date
        StartDate := WorkDate();
        FinancialLedgerReport.StartDate.SetValue(StartDate);
        // No. of Periods
        FinancialLedgerReport.NoOfPeriods.SetValue(1); // Causes default value initialization
        // Period Length
        Evaluate(PeriodLength, '<1D>');
        FinancialLedgerReport.PeriodLength.SetValue(PeriodLength);
        // Start Page Number
        FinancialLedgerReport.Startpage.SetValue(1);
        // Show amounts in
        LibraryVariableStorage.Dequeue(UseLcy);
        FinancialLedgerReport.UseAmtsInAddCurr.SetValue(UseLcy);

        FinancialLedgerReport.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PHPurchaseLedger(var PurchaseLedger: TestRequestPage "Purchase Ledger")
    begin
        PurchaseLedger.SaveAsExcel(LibraryReportValidation.GetFileName());
    end;
}

