codeunit 144010 "Service Documents With Tax"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Service] [Test Report]
    end;

    var
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";

    [Test]
    [HandlerFunctions('ServiceDocumentTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ServiceOrderInvalidFunctionError()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Setup: Create Service Order.
        Initialize();
        ServiceDocumentTestError(ServiceHeader."Document Type"::Order);
    end;

    [Test]
    [HandlerFunctions('ServiceDocumentTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ServiceInvoiceInvalidFunctionError()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Setup: Create Service Invoice.
        Initialize();
        ServiceDocumentTestError(ServiceHeader."Document Type"::Invoice);
    end;

    [Test]
    [HandlerFunctions('ServiceDocumentTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ServiceCreditMemoInvalidFunctionError()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Setup: Create Service Credit Memo.
        Initialize();
        ServiceDocumentTestError(ServiceHeader."Document Type"::"Credit Memo");
    end;

    local procedure ServiceDocumentTestError(DocumentType: Enum "Service Document Type")
    var
        Customer: Record Customer;
        TaxArea: Record "Tax Area";
        ServiceLine: Record "Service Line";
        Item: Record Item;
    begin
        // Create Item, Customer, Service Document and Tax Area with Use External Tax Engine.
        LibrarySales.CreateCustomer(Customer);
        CreateTaxArea(TaxArea, true);  // Use External Tax Engine - TRUE.
        CreateServiceDocument(ServiceLine, DocumentType, Customer."No.", LibraryInventory.CreateItem(Item), TaxArea.Code);

        // Exercise: Run report Service Document - Test for different Document Type of Service Documents.
        asserterror DocumentServiceTestReport();  // Opens ServiceDocumentTestRequestPageHandler.

        // Verify: Verify Error Code, Actual error - Invalid function call. Function reserved for external tax engines only.
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [HandlerFunctions('ServiceDocumentTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ServiceOrderCustomerWithCurrency()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Setup: Create Service Order.
        Initialize();
        ServiceDocumentTestCustomerWithCurrency(ServiceHeader."Document Type"::Order);
    end;

    [Test]
    [HandlerFunctions('ServiceDocumentTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ServiceInvoiceCustomerWithCurrency()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Setup: Create Service Invoice.
        Initialize();
        ServiceDocumentTestCustomerWithCurrency(ServiceHeader."Document Type"::Invoice);
    end;

    [Test]
    [HandlerFunctions('ServiceDocumentTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ServiceCreditMemoCustomerWithCurrency()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Setup: Create Service Credit Memo.
        Initialize();
        ServiceDocumentTestCustomerWithCurrency(ServiceHeader."Document Type"::"Credit Memo");
    end;

    local procedure ServiceDocumentTestCustomerWithCurrency(DocumentType: Enum "Service Document Type")
    var
        Customer: Record Customer;
        TaxArea: Record "Tax Area";
        ServiceLine: Record "Service Line";
        TaxGroup: Code[10];
    begin
        // Create Item, Customer with Currency, Service Document with Tax Area.
        LibrarySales.CreateCustomer(Customer);
        UpdateCustomerCurrency(Customer);
        Customer.Validate("VAT Bus. Posting Group", '');
        Customer.Modify(true);
        TaxGroup := CreateTaxAreaAndDetailSetup(TaxArea);
        CreateServiceDocument(ServiceLine, DocumentType, Customer."No.", CreateItem(TaxGroup), TaxArea.Code);

        // Exercise: Run report Service Document - Test for different Document Type of Service Documents.
        DocumentServiceTestReport();  // Opens ServiceDocumentTestRequestPageHandler.

        // Verify: Verify VAT Base Amount, Quantity and Currency Code on Report Service Document - Test for customer with Currency.
        VerifyServiceDocumentTestReport(ServiceLine, TaxArea.Code);
    end;

    [Test]
    [HandlerFunctions('ServiceDocumentTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ServiceOrderCustomerWithoutCurrency()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Setup: Create Service Order.
        Initialize();
        ServiceDocumentTestCustomerWithoutCurrency(ServiceHeader."Document Type"::Order);
    end;

    [Test]
    [HandlerFunctions('ServiceDocumentTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ServiceInvoiceCustomerWithoutCurrency()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Setup: Create Service Invoice.
        Initialize();
        ServiceDocumentTestCustomerWithoutCurrency(ServiceHeader."Document Type"::Invoice);
    end;

    [Test]
    [HandlerFunctions('ServiceDocumentTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ServiceCreditMemoCustomerWithoutCurrency()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Setup: Create Service Credit Memo.
        Initialize();
        ServiceDocumentTestCustomerWithoutCurrency(ServiceHeader."Document Type"::"Credit Memo");
    end;

    local procedure ServiceDocumentTestCustomerWithoutCurrency(DocumentType: Enum "Service Document Status")
    var
        Customer: Record Customer;
        TaxArea: Record "Tax Area";
        ServiceLine: Record "Service Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        TaxGroup: Code[10];
        OldCalcInvDiscount: Boolean;
    begin
        // Create Item, Customer without Currency, Service Document with Tax Area.
        UpdateSalesReceivablesSetup(OldCalcInvDiscount, true);
        LibrarySales.CreateCustomer(Customer);
        TaxGroup := CreateTaxAreaAndDetailSetup(TaxArea);
        CreateServiceDocument(ServiceLine, DocumentType, Customer."No.", CreateItem(TaxGroup), TaxArea.Code);

        // Exercise: Run report Service Document - Test for different Document Type of Service Documents.
        DocumentServiceTestReport();  // Opens ServiceDocumentTestRequestPageHandler.

        // Verify: Verify VAT Base Amount, Quantity and Currency Code and Allow Invoice Discount on Report Service Document - Test for customer without Currency.
        GeneralLedgerSetup.Get();
        VerifyServiceDocumentTestReport(ServiceLine, TaxArea.Code);
        LibraryReportDataset.AssertElementWithValueExists('Service_Line___Allow_Invoice_Disc__', true);

        // Teardown.
        UpdateSalesReceivablesSetup(OldCalcInvDiscount, OldCalcInvDiscount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TaxAmtOnReleasedServiceOrderWithMultipleTaxGroups()
    var
        TaxArea: Record "Tax Area";
        TaxGroup: array[2] of Record "Tax Group";
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        TaxJurisdiction: array[2] of Record "Tax Jurisdiction";
        TaxDetail: Record "Tax Detail";
        TaxAreaLine: Record "Tax Area Line";
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
        ServiceItem: Record "Service Item";
        ServiceLine: Record "Service Line";
        TotalAmtInclVATFromLines: Decimal;
        TotalAmtInclVATFromStatistics: Decimal;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 618546] Sum of line "Amount Including VAT" matches total when multiple tax groups exist under a multi-jurisdiction tax area

        Initialize();

        // [GIVEN] Tax area "TA" with two tax jurisdictions "TJ1" and "TJ2"
        LibraryERM.CreateTaxArea(TaxArea);
        LibraryERM.CreateTaxJurisdiction(TaxJurisdiction[1]);
        LibraryERM.CreateTaxJurisdiction(TaxJurisdiction[2]);
        LibraryERM.CreateTaxAreaLine(TaxAreaLine, TaxArea.Code, TaxJurisdiction[1].Code);
        LibraryERM.CreateTaxAreaLine(TaxAreaLine, TaxArea.Code, TaxJurisdiction[2].Code);

        // [GIVEN] Two tax groups "TG1" and "TG2" with tax details for each jurisdiction
        LibraryERM.CreateTaxGroup(TaxGroup[1]);
        LibraryERM.CreateTaxGroup(TaxGroup[2]);
        LibraryERM.CreateTaxDetail(TaxDetail, TaxJurisdiction[1].Code, TaxGroup[1].Code, TaxDetail."Tax Type"::"Sales and Use Tax", WorkDate());
        TaxDetail.Validate("Tax Below Maximum", 6.5);
        TaxDetail.Modify(true);
        LibraryERM.CreateTaxDetail(TaxDetail, TaxJurisdiction[2].Code, TaxGroup[1].Code, TaxDetail."Tax Type"::"Sales and Use Tax", WorkDate());
        TaxDetail.Validate("Tax Below Maximum", 3.8);
        TaxDetail.Modify(true);
        LibraryERM.CreateTaxDetail(TaxDetail, TaxJurisdiction[1].Code, TaxGroup[2].Code, TaxDetail."Tax Type"::"Sales and Use Tax", WorkDate());
        TaxDetail.Validate("Tax Below Maximum", 6.5);
        TaxDetail.Modify(true);
        LibraryERM.CreateTaxDetail(TaxDetail, TaxJurisdiction[2].Code, TaxGroup[2].Code, TaxDetail."Tax Type"::"Sales and Use Tax", WorkDate());
        TaxDetail.Validate("Tax Below Maximum", 3.8);
        TaxDetail.Modify(true);

        // [GIVEN] Customer "C" with Tax Area "TA" and Tax Liable
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Tax Area Code", TaxArea.Code);
        Customer.Validate("Tax Liable", true);
        Customer.Validate("VAT Bus. Posting Group", '');
        Customer.Modify(true);

        // [GIVEN] Service Order "SO" with service lines using different tax groups
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");
        ServiceHeader.Validate("Tax Area Code", TaxArea.Code);
        ServiceHeader.Validate("Tax Liable", true);
        ServiceHeader.Modify(true);
        LibraryService.CreateServiceItem(ServiceItem, Customer."No.");

        CreateServiceLineWithTaxGroup(ServiceLine, ServiceHeader, CreateItem(TaxGroup[1].Code), TaxArea.Code, 1, 500);
        CreateServiceLineWithTaxGroup(ServiceLine, ServiceHeader, CreateItem(TaxGroup[2].Code), TaxArea.Code, 2, 750);
        CreateServiceLineWithTaxGroup(ServiceLine, ServiceHeader, CreateItem(TaxGroup[1].Code), TaxArea.Code, 3, 1800);

        // [WHEN] Release the Service Order
        LibraryService.ReleaseServiceDocument(ServiceHeader);

        // [WHEN] Calculating per-line sum and statistics total
        TotalAmtInclVATFromLines := CalcSumAmtInclVATFromServiceLines(ServiceHeader);
        ServiceLine.CalcVATAmountLines(0, ServiceHeader, ServiceLine, TempVATAmountLine, false);
        TotalAmtInclVATFromStatistics := TempVATAmountLine.GetTotalAmountInclVAT();

        // [THEN] Sum of per-line "Amount Including VAT" equals statistics "Total Incl. Tax"
        Assert.AreEqual(
            TotalAmtInclVATFromStatistics, TotalAmtInclVATFromLines,
            'Sum of per-line Amount Including VAT must match statistics Total Incl. Tax');
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Service Documents With Tax");
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateItem(TaxGroupCode: Code[10]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Tax Group Code", TaxGroupCode);
        Item.Validate("VAT Prod. Posting Group", '');
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateServiceHeader(var ServiceHeader: Record "Service Header"; DocumentType: Enum "Service Document Type"; CustomerNo: Code[20]; TaxAreaCode: Code[20])
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, DocumentType, CustomerNo);
        ServiceHeader.Validate("Posting Date", WorkDate());
        ServiceHeader.Validate("Tax Area Code", TaxAreaCode);
        ServiceHeader.Validate("Tax Liable", true);
        ServiceHeader.Modify(true);

        // Enqueue Required inside ServiceDocumentTestRequestPageHandler.
        LibraryVariableStorage.Enqueue(DocumentType);
        LibraryVariableStorage.Enqueue(ServiceHeader."No.");
    end;

    local procedure CreateServiceLine(var ServiceLine: Record "Service Line"; var ServiceHeader: Record "Service Header"; ItemNo: Code[20]; TaxAreaCode: Code[20])
    begin
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, ItemNo);
        ServiceLine.Validate("Tax Area Code", TaxAreaCode);
        ServiceLine.Validate(Quantity, LibraryRandom.RandDec(10, 2));
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDec(10, 2));
        ServiceLine.Modify(true);
    end;

    local procedure CreateServiceLineWithTaxGroup(var ServiceLine: Record "Service Line"; var ServiceHeader: Record "Service Header"; ItemNo: Code[20]; TaxAreaCode: Code[20]; Quantity: Decimal; UnitPrice: Decimal)
    begin
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, ItemNo);
        ServiceLine.Validate("Tax Area Code", TaxAreaCode);
        ServiceLine.Validate(Quantity, Quantity);
        ServiceLine.Validate("Unit Price", UnitPrice);
        ServiceLine.Modify(true);
    end;

   local procedure CalcSumAmtInclVATFromServiceLines(ServiceHeader: Record "Service Header"): Decimal
    var
        ServiceLine: Record "Service Line";
        TotalAmtInclVAT: Decimal;
    begin
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.SetFilter(Type, '>0');
        ServiceLine.SetFilter(Quantity, '<>0');
        ServiceLine.CalcSums("Amount Including VAT");
        TotalAmtInclVAT := ServiceLine."Amount Including VAT";
        exit(TotalAmtInclVAT);
    end;
    
    local procedure CreateTaxArea(var TaxArea: Record "Tax Area"; UseExternalTaxEngine: Boolean)
    begin
        LibraryERM.CreateTaxArea(TaxArea);
        TaxArea.Validate("Use External Tax Engine", UseExternalTaxEngine);
        TaxArea.Modify(true);
    end;

    local procedure CreateTaxAreaAndDetailSetup(var TaxArea: Record "Tax Area"): Code[10]
    var
        TaxGroup: Record "Tax Group";
        TaxJurisdiction: Record "Tax Jurisdiction";
        TaxDetail: Record "Tax Detail";
        TaxAreaLine: Record "Tax Area Line";
    begin
        // Create Tax Group, Tax Area, Tax Jurisdiction and Tax Area Line for calculating Tax.
        LibraryERM.CreateTaxGroup(TaxGroup);
        CreateTaxArea(TaxArea, false);
        LibraryERM.CreateTaxJurisdiction(TaxJurisdiction);
        LibraryERM.CreateTaxDetail(TaxDetail, TaxJurisdiction.Code, TaxGroup.Code, TaxDetail."Tax Type"::"Sales and Use Tax", WorkDate());
        TaxDetail.Validate("Tax Below Maximum", LibraryRandom.RandDec(10, 2));
        TaxDetail.Validate("Tax Above Maximum", TaxDetail."Tax Below Maximum" + LibraryRandom.RandDec(10, 2));
        TaxDetail.Modify(true);
        LibraryERM.CreateTaxAreaLine(TaxAreaLine, TaxArea.Code, TaxJurisdiction.Code);
        exit(TaxGroup.Code);
    end;

    local procedure CreateServiceDocument(var ServiceLine: Record "Service Line"; DocumentType: Enum "Service Document Type"; CustomerNo: Code[20]; ItemNo: Code[20]; TaxAreaCode: Code[20])
    var
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
    begin
        CreateServiceHeader(ServiceHeader, DocumentType, CustomerNo, TaxAreaCode);
        LibraryService.CreateServiceItem(ServiceItem, CustomerNo);
        ServiceItem.Validate("Item No.", ItemNo);
        ServiceItem.Modify(true);
        CreateServiceLine(ServiceLine, ServiceHeader, ItemNo, TaxAreaCode);
    end;

    local procedure CreateCurrencyWithExchangeRate(): Code[10]
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateExchRate(CurrencyExchangeRate, Currency.Code, WorkDate());
        CurrencyExchangeRate.Validate("Exchange Rate Amount", LibraryRandom.RandDec(10, 2));
        CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", CurrencyExchangeRate."Exchange Rate Amount");
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", LibraryRandom.RandDec(10, 2));
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", CurrencyExchangeRate."Relational Exch. Rate Amount");
        CurrencyExchangeRate.Modify(true);
        exit(CurrencyExchangeRate."Currency Code");
    end;

    local procedure UpdateCustomerCurrency(var Customer: Record Customer)
    begin
        Customer.Validate("Currency Code", CreateCurrencyWithExchangeRate());
        Customer.Modify(true);
    end;

    local procedure UpdateSalesReceivablesSetup(var OldCalcInvDiscount: Boolean; NewCalcInvDiscount: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        OldCalcInvDiscount := SalesReceivablesSetup."Calc. Inv. Discount";
        SalesReceivablesSetup.Validate("Calc. Inv. Discount", NewCalcInvDiscount);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure DocumentServiceTestReport()
    begin
        Commit(); // Commit required, because explicit commit is called by CustomerNo - OnValidate Trigger of Table Sales Header.
        REPORT.Run(REPORT::"Service Document - Test");
    end;

    local procedure VerifyServiceDocumentTestReport(ServiceLine: Record "Service Line"; TaxAreaCode: Code[20])
    var
        SalesTaxAmountLine: Record "Sales Tax Amount Line";
    begin
        SalesTaxAmountLine.SetRange("Tax Area Code", TaxAreaCode);
        SalesTaxAmountLine.FindFirst();
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('VATBaseAmount', SalesTaxAmountLine."Line Amount");
        LibraryReportDataset.AssertElementWithValueExists('SumLineAmount', ServiceLine."Line Amount");
        LibraryReportDataset.AssertElementWithValueExists('Service_Line__Quantity', ServiceLine.Quantity);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ServiceDocumentTestRequestPageHandler(var ServiceDocumentTest: TestRequestPage "Service Document - Test")
    var
        DocumentType: Variant;
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentType);
        LibraryVariableStorage.Dequeue(No);
        ServiceDocumentTest."Service Header".SetFilter("Document Type", Format(DocumentType));
        ServiceDocumentTest."Service Header".SetFilter("No.", No);
        ServiceDocumentTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

