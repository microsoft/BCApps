codeunit 144353 "Test ESR Reports"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryService: Codeunit "Library - Service";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibrarySales: Codeunit "Library - Sales";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        Assert: Codeunit Assert;
        isInitialized: Boolean;

    [Test]
    [HandlerFunctions('ServiceInvoiceESRHandler')]
    [Scope('OnPrem')]
    procedure ServiceInvoiceESRReportInternalTrueBasedOnESRTest()
    var
        ESRSystem: Option "Based on ESR Bank",ESR,"ESR+";
    begin
        ServiceInvoiceESRReportTest(true, ESRSystem::"Based on ESR Bank");
    end;

    [Test]
    [HandlerFunctions('ServiceInvoiceESRHandler')]
    [Scope('OnPrem')]
    procedure ServiceInvoiceESRReportInternalFalseESRTest()
    var
        ESRSystem: Option "Based on ESR Bank",ESR,"ESR+";
    begin
        ServiceInvoiceESRReportTest(false, ESRSystem::ESR);
    end;

    [Test]
    [HandlerFunctions('SalesInvoiceESRHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceESRReportLogInteractionTrueBasedOnESRTest()
    var
        ESRSystem: Option "Based on ESR Bank",ESR,"ESR+";
    begin
        SalesInvoiceESRReportTest(true, ESRSystem::"Based on ESR Bank");
    end;

    [Test]
    [HandlerFunctions('SalesInvoiceESRHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceESRReportLogInteractionFalseESRTest()
    var
        ESRSystem: Option "Based on ESR Bank",ESR,"ESR+";
    begin
        SalesInvoiceESRReportTest(false, ESRSystem::ESR);
    end;

    [Test]
    [HandlerFunctions('ESRCouponHandler')]
    [Scope('OnPrem')]
    procedure ESRCouponReportBasedOnESRTest()
    var
        ESRSystem: Option "Based on ESR Bank",ESR,"ESR+";
    begin
        ESRCouponReportTest(ESRSystem::"Based on ESR Bank");
    end;

    [Test]
    [HandlerFunctions('ESRCouponHandler')]
    [Scope('OnPrem')]
    procedure ESRCouponReportESRTest()
    var
        ESRSystem: Option "Based on ESR Bank",ESR,"ESR+";
    begin
        ESRCouponReportTest(ESRSystem::ESR);
    end;

    [Test]
    [HandlerFunctions('ESRServiceCouponHandler')]
    [Scope('OnPrem')]
    procedure ESRServiceCouponReportBasedOnESRTest()
    var
        ESRSystem: Option "Based on ESR Bank",ESR,"ESR+";
    begin
        ESRServiceCouponReportTest(ESRSystem::"Based on ESR Bank");
    end;

    [Test]
    [HandlerFunctions('ESRServiceCouponHandler')]
    [Scope('OnPrem')]
    procedure ESRServiceCouponReportESRTest()
    var
        ESRSystem: Option "Based on ESR Bank",ESR,"ESR+";
    begin
        ESRServiceCouponReportTest(ESRSystem::ESR);
    end;

    local procedure ServiceInvoiceESRReportTest(ShowInternal: Boolean; ESRSystem: Option "Based on ESR Bank",ESR,"ESR+")
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceInvoiceLine: Record "Service Invoice Line";
    begin
        // Test that value of Amount in Service Invoice matches the value of Line Amount in corresponding Service Line.

        // 1. Setup: Create and Post Service Invoice.
        Initialize();
        CreateAndPostServiceInvoice(ServiceInvoiceHeader);

        // 2. Exercise: Generate the Service Invoice report.
        LibraryVariableStorage.Enqueue(ShowInternal); // Show Internal Information
        LibraryVariableStorage.Enqueue(ESRSystem); // ESR System

        REPORT.Run(REPORT::"Service - Invoice ESR", true, false, ServiceInvoiceHeader);

        // 3. Verify
        LibraryReportDataset.LoadDataSetFile();

        // hardcoded values!
        // Assert.AreEqual(ExpectedNumberOfRows,LibraryReportDataset.RowCount(),'Wrong number of rows.');

        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('No_ServiceInvHdr', ServiceInvoiceHeader."No.");

        ServiceInvoiceLine.SetRange("Document No.", ServiceInvoiceHeader."No.");
        ServiceInvoiceLine.FindFirst();
        LibraryReportDataset.AssertElementWithValueExists('No_ServiceInvLine', ServiceInvoiceLine."No.");
        LibraryReportDataset.AssertElementWithValueExists('UnitPrice_ServiceInvLine', ServiceInvoiceLine."Unit Price");
        LibraryReportDataset.AssertElementWithValueExists('Qty_ServiceInvLine', ServiceInvoiceLine.Quantity);
    end;

    local procedure SalesInvoiceESRReportTest(LogInteraction: Boolean; ESRSystem: Option "Based on ESR Bank",ESR,"ESR+")
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        ExpectedNumberOfRows: Integer;
    begin
        // Test that value of Amount in Sales Invoice matches the value of Line Amount in corresponding Sales Line.

        // 1. Setup: Create and Post Sales Invoice.
        Initialize();
        CreateAndPostSalesInvoice(SalesInvoiceHeader);

        LibraryVariableStorage.Enqueue(LogInteraction); // Log Interaction
        LibraryVariableStorage.Enqueue(ESRSystem); // ESR System

        // 2. Exercise: Generate the Sales Invoice report
        REPORT.Run(REPORT::"Sales Invoice ESR", true, false, SalesInvoiceHeader);

        // 3. Verify
        LibraryReportDataset.LoadDataSetFile();

        ExpectedNumberOfRows := 3;

        Assert.AreEqual(ExpectedNumberOfRows, LibraryReportDataset.RowCount(), 'Wrong number of rows.');

        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('No_Head', SalesInvoiceHeader."No.");

        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.FindFirst();
        LibraryReportDataset.AssertCurrentRowValueEquals('No_Line', SalesInvoiceLine."No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('UnitPrice_Line', SalesInvoiceLine."Unit Price");
        LibraryReportDataset.AssertCurrentRowValueEquals('Quantity_Line', SalesInvoiceLine.Quantity);
    end;

    local procedure ESRCouponReportTest(ESRSystem: Option "Based on ESR Bank",ESR,"ESR+")
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ESRSetup: Record "ESR Setup";
        ExpectedNumberOfRows: Integer;
    begin
        // 1. Setup: Create and Post Sales Invoice.
        Initialize();
        CreateAndPostSalesInvoice(SalesInvoiceHeader);

        // 2. Exercise: Generate the ESR Coupon report
        LibraryVariableStorage.Enqueue(ESRSystem); // ESR System
        REPORT.Run(REPORT::"ESR Coupon", true, false, SalesInvoiceHeader);

        // 3. Verify
        LibraryReportDataset.LoadDataSetFile();

        ExpectedNumberOfRows := 1;

        Assert.AreEqual(ExpectedNumberOfRows, LibraryReportDataset.RowCount(), 'Wrong number of rows.');

        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('HeadNo', SalesInvoiceHeader."No.");

        ESRSetup.Reset();
        ESRSetup.SetRange("ESR Main Bank", true);
        ESRSetup.FindFirst();

        LibraryReportDataset.AssertCurrentRowValueEquals('EsrSetupESRMemberName1', ESRSetup."ESR Member Name 1");
        LibraryReportDataset.AssertCurrentRowValueEquals('EsrSetupESRMemberName2', ESRSetup."ESR Member Name 2");
        LibraryReportDataset.AssertCurrentRowValueEquals('EsrSetupESRMemberName3', ESRSetup."ESR Member Name 3");
    end;

    local procedure ESRServiceCouponReportTest(ESRSystem: Option "Based on ESR Bank",ESR,"ESR+")
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ESRSetup: Record "ESR Setup";
        ExpectedNumberOfRows: Integer;
    begin
        // 1. Setup: Create and Post Sales Invoice.
        Initialize();
        CreateAndPostServiceInvoice(ServiceInvoiceHeader);

        // 2. Exercise: Generate the ESR Coupon report
        LibraryVariableStorage.Enqueue(ESRSystem); // ESR System
        REPORT.Run(REPORT::"Service - ESR Coupon", true, false, ServiceInvoiceHeader);

        // 3. Verify
        LibraryReportDataset.LoadDataSetFile();

        ExpectedNumberOfRows := 1;

        Assert.AreEqual(ExpectedNumberOfRows, LibraryReportDataset.RowCount(), 'Wrong number of rows.');

        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('No_Head', ServiceInvoiceHeader."No.");

        ESRSetup.Reset();
        ESRSetup.SetRange("ESR Main Bank", true);
        ESRSetup.FindFirst();

        LibraryReportDataset.AssertCurrentRowValueEquals('EsrSetupESRMemberName1', ESRSetup."ESR Member Name 1");
        LibraryReportDataset.AssertCurrentRowValueEquals('EsrSetupESRMemberName2', ESRSetup."ESR Member Name 2");
        LibraryReportDataset.AssertCurrentRowValueEquals('EsrSetupESRMemberName3', ESRSetup."ESR Member Name 3");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATPctInVATLinesAfterServiceInvoicePosting()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceInvoiceLine: Record "Service Invoice Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VATEntry: Record "VAT Entry";
    begin
        // [FEATURE] [Service] [VAT %]
        // [SCENARIO 235524] On posting a Service Order field 11500 - VAT % in TAB 254 VAT Entries contains VAT % of corresponding VAT Setup

        Initialize();

        // [GIVEN] Service Order with 1 line with 25% VAT
        // [WHEN] Post Service Order
        CreateAndPostServiceInvoice(ServiceInvoiceHeader);
        ServiceInvoiceLine.SetRange("Document No.", ServiceInvoiceHeader."No.");
        ServiceInvoiceLine.FindFirst();
        VATPostingSetup.Get(ServiceInvoiceHeader."VAT Bus. Posting Group", ServiceInvoiceLine."VAT Prod. Posting Group");
        VATPostingSetup.TestField("VAT %");

        // [THEN] Created VAT Entry has "VAT %" = 25
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Invoice);
        VATEntry.SetRange("Document No.", ServiceInvoiceHeader."No.");
        VATEntry.FindFirst();
        Assert.AreEqual(VATPostingSetup."VAT %", VATEntry."VAT %", 'Wrong VAT % in VAT Entry.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CurrencyFactorInVATLinesAfterServiceInvoicePosting()
    var
        Currency: Record Currency;
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        VATEntry: Record "VAT Entry";
        ExchRate: Decimal;
    begin
        // [FEATURE] [Service] [Currency Factor]
        // [SCENARIO 235524] On posting a Service Order, field "Currency Factor" in TAB 254 VAT Entries contains "Currency Factor" of Service Invoice

        Initialize();

        // [GIVEN] Service Order with 5.5 "Currency Factor"
        // [WHEN] Post Service Order
        LibraryERM.CreateCurrency(Currency);
        ExchRate := LibraryRandom.RandDec(10, 2);
        LibraryERM.CreateExchangeRate(Currency.Code, WorkDate(), ExchRate, ExchRate);
        CreateAndPostServiceInvoiceWithCurrency(ServiceInvoiceHeader, ServiceHeader, Currency.Code, ExchRate);

        // [THEN] Created VAT Entry has "Currency Factor" = 5.5
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Invoice);
        VATEntry.SetRange("Document No.", ServiceInvoiceHeader."No.");
        VATEntry.FindFirst();
        VATEntry.TestField("Currency Code", Currency.Code);
        VATEntry.TestField("Currency Factor", ServiceHeader."Currency Factor");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CurrencyFactorForBlankCurrencyInVATLinesAfterServiceInvoicePosting()
    var
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        VATEntry: Record "VAT Entry";
    begin
        // [FEATURE] [Service] [Currency Factor]
        // [SCENARIO 235524] On posting a Service Order, field "Currency Factor" in TAB 254 VAT Entries contains 1 if Service Invoice has blank "Currency Code"

        Initialize();

        // [GIVEN] Service Order with blank "Currency Code"
        // [WHEN] Post Service Order
        CreateAndPostServiceInvoiceWithCurrency(ServiceInvoiceHeader, ServiceHeader, '', 0);

        // [THEN] Created VAT Entry has "Currency Factor" = 1
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Invoice);
        VATEntry.SetRange("Document No.", ServiceInvoiceHeader."No.");
        VATEntry.FindFirst();
        VATEntry.TestField("Currency Code", ServiceHeader."Currency Code");
        VATEntry.TestField("Currency Factor", 1);
    end;

    [Test]
    [HandlerFunctions('ServiceInvoiceESRToExcelRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ServiceInvoiceESRSaveToExcel()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        // [SCENARIO 337173] Run report "Service - Invoice ESR" with saving results to Excel file.
        Initialize();
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());

        // [GIVEN] Posted Service Invoice.
        CreateAndPostServiceInvoice(ServiceInvoiceHeader);

        // [WHEN] Run report "Service - Invoice ESR", save report output to Excel file.
        ServiceInvoiceHeader.SetRecFilter();
        REPORT.Run(REPORT::"Service - Invoice ESR", true, false, ServiceInvoiceHeader);

        // [THEN] Report output is saved to Excel file.
        LibraryReportValidation.OpenExcelFile();
        LibraryReportValidation.VerifyCellValue(1, 28, '1'); // page number
        Assert.AreNotEqual(0, LibraryReportValidation.FindColumnNoFromColumnCaption('Service - Invoice'), '');
    end;

    local procedure Initialize()
    var
        ServiceMgtSetup: Record "Service Mgt. Setup";
        NoSeriesLine: Record "No. Series Line";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Test ESR Reports");
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Test ESR Reports");

        // Setup number series for Posted Service Invoice.
        ServiceMgtSetup.Get();
        NoSeriesLine.SetRange("Series Code", ServiceMgtSetup."Posted Service Invoice Nos.");
        NoSeriesLine.SetRange(Open, true);
        NoSeriesLine.FindFirst();
        NoSeriesLine."Starting No." := '0000000';
        NoSeriesLine.Modify(true);

        LibraryService.SetupServiceMgtNoSeries();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Test ESR Reports");
    end;

    local procedure CreateAndPostSalesInvoice(var SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomer(VATPostingSetup."VAT Bus. Posting Group"));
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item,
          CreateItem(VATPostingSetup."VAT Prod. Posting Group"), LibraryRandom.RandDec(100, 2));  // Using Random ofr Quantity.

        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        SalesInvoiceHeader.SetRange("Pre-Assigned No.", SalesHeader."No.");
        SalesInvoiceHeader.FindFirst();
        SalesInvoiceHeader.Validate("Order No.", SalesHeader."No.");
        SalesInvoiceHeader.Modify(true);
        Commit();
    end;

    local procedure CreateAndPostServiceInvoice(var ServiceInvoiceHeader: Record "Service Invoice Header")
    var
        DummyServiceHeader: Record "Service Header";
    begin
        CreateAndPostServiceInvoiceWithCurrency(ServiceInvoiceHeader, DummyServiceHeader, '', 0);
    end;

    local procedure CreateAndPostServiceInvoiceWithCurrency(var ServiceInvoiceHeader: Record "Service Invoice Header"; var ServiceHeader: Record "Service Header"; CurrencyCode: Code[10]; ExchRate: Decimal)
    var
        ServiceLine: Record "Service Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryService.CreateServiceHeader(
          ServiceHeader, ServiceHeader."Document Type"::Invoice, CreateCustomer(VATPostingSetup."VAT Bus. Posting Group"));

        ServiceHeader."Currency Code" := CurrencyCode;
        ServiceHeader."Currency Factor" := ExchRate;
        ServiceHeader.Modify(true);

        LibraryService.CreateServiceLine(
          ServiceLine, ServiceHeader, ServiceLine.Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group"));
        UpdateQuantityServiceLine(ServiceLine);

        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        ServiceInvoiceHeader.SetRange("Pre-Assigned No.", ServiceHeader."No.");
        ServiceInvoiceHeader.FindFirst();
        ServiceInvoiceHeader.Validate("Order No.", ServiceHeader."No.");
        ServiceInvoiceHeader.Modify(true);
        Commit();
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

    local procedure CreateItem(VATProdPostingGroup: Code[20]): Code[20]
    var
        Item: Record Item;
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Price", LibraryRandom.RandDecInRange(100, 200, 2));  // Use Random because value is not important.
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure UpdateQuantityServiceLine(var ServiceLine: Record "Service Line")
    begin
        ServiceLine.Validate(Quantity, LibraryRandom.RandDecInRange(10, 20, 2));  // Use Random because value is not important.
        ServiceLine.Modify(true);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ServiceInvoiceESRHandler(var ServiceInvoice: TestRequestPage "Service - Invoice ESR")
    var
        ShowInternal: Variant;
        ESRSystem: Variant;
    begin
        LibraryVariableStorage.Dequeue(ShowInternal);
        LibraryVariableStorage.Dequeue(ESRSystem);

        ServiceInvoice.ShowInternalInfo.SetValue(ShowInternal);
        ServiceInvoice.EsrType.SetValue(ESRSystem);

        LibraryReportDataset.Reset();
        ServiceInvoice.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName())
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ServiceInvoiceESRToExcelRequestPageHandler(var ServiceInvoiceESR: TestRequestPage "Service - Invoice ESR")
    begin
        ServiceInvoiceESR.SaveAsExcel(LibraryReportValidation.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesInvoiceESRHandler(var SalesInvoice: TestRequestPage "Sales Invoice ESR")
    var
        LogInteraction: Variant;
        ESRSystem: Variant;
    begin
        LibraryVariableStorage.Dequeue(LogInteraction);
        LibraryVariableStorage.Dequeue(ESRSystem);

        SalesInvoice.LogInteraction.SetValue(LogInteraction);
        SalesInvoice.EsrType.SetValue(ESRSystem);

        LibraryReportDataset.Reset();
        SalesInvoice.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName())
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ESRCouponHandler(var ESRCoupon: TestRequestPage "ESR Coupon")
    var
        ESRSystem: Variant;
    begin
        LibraryVariableStorage.Dequeue(ESRSystem);

        ESRCoupon.EsrType.SetValue(ESRSystem);

        LibraryReportDataset.Reset();
        ESRCoupon.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName())
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ESRServiceCouponHandler(var ESRCoupon: TestRequestPage "Service - ESR Coupon")
    var
        ESRSystem: Variant;
    begin
        LibraryVariableStorage.Dequeue(ESRSystem);

        ESRCoupon.EsrType.SetValue(ESRSystem);

        LibraryReportDataset.Reset();
        ESRCoupon.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName())
    end;
}

