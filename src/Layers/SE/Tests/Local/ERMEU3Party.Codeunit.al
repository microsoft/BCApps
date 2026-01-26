codeunit 144003 "ERM EU 3-Party"
{
    // // [FEATURE] [EU 3-Party]
    //
    // 1.  Test to verify EU 3-Party Trade True after posting Purchase Invoice.
    // 2.  Test to verify EU 3-Party Trade True after posting Purchase Order.
    // 3.  Test to verify EU 3-Party Trade False after posting Purchase Order.
    // 4.  Test to verify EU 3-Party Trade on Purchase Order, When EU 3-Party Trade True on Sales Header, True on Purchase Header and confirm message Yes.
    // 5.  Test to verify EU 3-Party Trade on Purchase Order, When EU 3-Party Trade True on Sales Header, False on Purchase Header and confirm message No.
    // 6.  Test to verify EU 3-Party Trade on Purchase Order, When EU 3-Party Trade False on Sales Header, True on Purchase Header and confirm message Yes.
    // 7.  Test to verify EU 3-Party Trade on Purchase Order, When EU 3-Party Trade False on Sales Header, True on Purchase Header and confirm message No.
    // 8.  Test to verify EU 3-Party Trade on Purchase Order, When EU 3-Party Trade False on Sales Header, False on Purchase Header.
    // 9.  Test to verify EU 3-Party Trade on Purchase Order, When EU 3-Party Trade True on Sales Header, True on Purchase Header.
    // 10. Test to verify EU 3-Party Trade True after posting Sales Invoice.
    // 11. Test to verify EU 3-Party Trade False after posting Sales Invoice.
    // 12. Test to verify EU 3-Party Trade True after posting Sales Order.
    // 13. Test to verify EU 3-Party Trade False after posting Sales Credit Memo.
    // 14. Test to verify EU 3-Party Trade True after posting Sales Credit Memo.
    // 15. Test to verify EU 3-Party Trade False after posting Service Invoice.
    // 16. Test to verify EU 3-Party Trade True after posting Service Invoice.
    // 17. Test to verify EU 3-Party Trade False after posting Service Order.
    // 18. Test to verify EU 3-Party Trade False after posting Service Credit Memo.
    // 19. Test to verify EU 3-Party Trade True after posting Service Credit Memo.
    // 20. Test to verify Amount on VAT Statement Preview page for Purchase Invoice with EUThirdPartyTrade and without Currency.
    // 21. Test to verify Amount on VAT Statement Preview page for Purchase Invoice with EUThirdPartyTrade and Currency.
    // 22. Test to verify Amount on VAT Statement Preview page for Sales Invoice with EUThirdPartyTrade and without Currency.
    // 23. Test to verify Amount on VAT Statement Preview page for Sales Invoice with EUThirdPartyTrade and Currency.
    // 24. Test to verify Total Amount on VAT Statement report with EUThirdPartyTrade.
    // 25. Test to verify values on VAT - VIES Declaration Tax Authority report with EUThirdPartyTrade.
    // 26. Test to verify values on VAT - VIES Declaration Tax Authority report with EUService.
    //
    // Covers Test Cases for WI - 350532.
    // -----------------------------------------------------------
    // Test Function Name                                   TFS ID
    // -----------------------------------------------------------
    // PurchaseInvoiceEUThirdPartyTradeTrue                 154959
    // PurchaseOrderEUThirdPartyTradeTrue                   154974
    // PurchaseOrderEUThirdPartyTradeFalse                  154975
    // EUThirdPartyTrueOnSalesFalseOnPurchase               154962
    // EUThirdPartyFalseOnPurchaseTrueOnSales               154963
    // EUThirdPartyFalseOnSalesTrueOnPurchase               154964
    // EUThirdPartyTrueOnPurchaseFalseOnSales               154965
    // EUThirdPartyFalseOnPurchaseFalseOnSales              154976
    // EUThirdPartyTrueOnPurchaseTrueOnSales                154977
    //
    // Covers Test Cases for WI - 350540.
    // -----------------------------------------------------------
    // Test Function Name                                   TFS ID
    // -----------------------------------------------------------
    // SalesInvoiceEUThirdPartyTradeTrue                    156927
    // SalesInvoiceEUThirdPartyTradeFalse                   156929
    // SalesOrderEUThirdPartyTradeTrue                      156928
    // SalesCrMemoEUThirdPartyTradeFalse                    156936
    // SalesCrMemoEUThirdPartyTradeTrue                     156935
    // ServiceInvoiceEUThirdPartyTradeFalse                 156946
    // ServiceInvoiceEUThirdPartyTradeTrue                  156945
    // ServiceOrderEUThirdPartyTradeFalse                   156952
    // ServiceCrMemoEUThirdPartyTradeFalse                  156958
    // ServiceCrMemoEUThirdPartyTradeTrue                   156957
    //
    // Covers Test Cases for WI - 350533
    // -----------------------------------------------------------------------------
    // Test Function Name                                                     TFS ID
    // -----------------------------------------------------------------------------
    // VATStatementPreviewForPurchaseInvWithoutCurrency
    // VATStatementPreviewForPurchaseInvoiceWithCurrency
    // VATStatementPreviewForSalesInvoiceWithoutCurrency
    // VATStatementPreviewForSalesInvoiceWithCurrency
    // VATStatementReportWithEUThirdPartyTrade                         154986,154987
    // VATVIESDeclarationTaxAuthRptWithEUThirdPartyTrade                      153968
    //
    // Covers Test Cases for WI - 351052
    // -----------------------------------------------------------------------------
    // Test Function Name                                                     TFS ID
    // -----------------------------------------------------------------------------
    // VATVIESDeclarationTaxAuthorityReportWithEUService                      157317
    //
    // Covers Test Cases for WI - 461741
    // -----------------------------------------------------------------------------
    // Test Function Name                                                     TFS ID
    // -----------------------------------------------------------------------------
    // S461741_EUThirdPartyTradeCopiedOnPurchaseOrderFromDropShipmentSalesOrder 461741
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        EUThirdPartyItemTradeAmtCap: Label 'EU3PartyItemTradeAmt';
        EUThirdPartyServiceTradeAmtCap: Label 'EU3PartyServiceTradeAmt';
        TotalAmountCap: Label 'TotalAmount';
        TotalValueofItemSuppliesCap: Label 'TotalValueofItemSupplies';
        TotalValueOfServiceSuppliesCap: Label 'TotalValueofServiceSupplies';

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceEUThirdPartyTradeTrue()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Test to verify EU 3-Party Trade True after posting Sales Invoice.
        PostSalesDocumentWithEUThirdParty(SalesHeader."Document Type"::Invoice, true);  // EU 3-Party Trade as True.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderEUThirdPartyTradeFalse()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Test to verify EU 3-Party Trade False after posting Sales Order.
        PostSalesDocumentWithEUThirdParty(SalesHeader."Document Type"::Order, false);  // EU 3-Party Trade as False.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderEUThirdPartyTradeTrue()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Test to verify EU 3-Party Trade True after posting Sales Order.
        PostSalesDocumentWithEUThirdParty(SalesHeader."Document Type"::Order, true);  // EU 3-Party Trade as True.
    end;

    local procedure PostSalesDocumentWithEUThirdParty(DocumentType: Enum "Sales Document Type"; EUThirdPartyTrade: Boolean)
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // Setup.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CreateSalesDocument(SalesHeader, DocumentType, Customer."No.", LibraryInventory.CreateItem(Item), '', EUThirdPartyTrade);  // Using Blank for Currency Code.

        // Exercise.
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));  // Post as ship and invoice.

        // Verify.
        SalesInvoiceHeader.TestField("EU 3-Party Trade", EUThirdPartyTrade);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemoEUThirdPartyTradeFalse()
    begin
        // Test to verify EU 3-Party Trade False after posting Sales Credit Memo.
        PostSalesCrMemoWithEUThirdParty(false);  // EU 3-Party Trade as False.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemoEUThirdPartyTradeTrue()
    begin
        // Test to verify EU 3-Party Trade True after posting Sales Credit Memo.
        PostSalesCrMemoWithEUThirdParty(true);  // EU 3-Party Trade as True.
    end;

    local procedure PostSalesCrMemoWithEUThirdParty(EUThirdPartyTrade: Boolean)
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesHeader: Record "Sales Header";
    begin
        // Setup.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CreateSalesDocument(
          SalesHeader, SalesHeader."Document Type"::"Credit Memo", Customer."No.", LibraryInventory.CreateItem(Item), '', EUThirdPartyTrade);  // Using Blank for Currency Code.

        // Exercise.
        SalesCrMemoHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));  // Post as ship and invoice.

        // Verify.
        SalesCrMemoHeader.TestField("EU 3-Party Trade", EUThirdPartyTrade);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceInvoiceEUThirdPartyTradeFalse()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Test to verify EU 3-Party Trade False after posting Service Invoice.
        PostServiceInvoiceWithEUThirdParty(ServiceHeader."Document Type"::Invoice, false);  // EU 3-Party Trade as False.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceInvoiceEUThirdPartyTradeTrue()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Test to verify EU 3-Party Trade True after posting Service Invoice.
        PostServiceInvoiceWithEUThirdParty(ServiceHeader."Document Type"::Invoice, true);  // EU 3-Party Trade as True.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceOrderEUThirdPartyTradeFalse()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Test to verify EU 3-Party Trade False after posting Service Order.
        PostServiceInvoiceWithEUThirdParty(ServiceHeader."Document Type"::Order, false);  // EU 3-Party Trade as False.
    end;

    local procedure PostServiceInvoiceWithEUThirdParty(DocumentType: Enum "Service Document Type"; EUThirdPartyTrade: Boolean)
    var
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        // Setup.
        Initialize();
        CreateServiceDocument(ServiceHeader, DocumentType, EUThirdPartyTrade);

        // Exercise.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);  // Post as ship and invoice.

        // Verify.
        ServiceInvoiceHeader.SetRange("Customer No.", ServiceHeader."Customer No.");
        ServiceInvoiceHeader.FindFirst();
        ServiceInvoiceHeader.TestField("EU 3-Party Trade", EUThirdPartyTrade);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceCrMemoEUThirdPartyTradeFalse()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Test to verify EU 3-Party Trade False after posting Service Credit Memo.
        PostServiceCrMemoWithEUThirdParty(ServiceHeader."Document Type"::"Credit Memo", false);  // EU 3-Party Trade as False.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceCrMemoEUThirdPartyTradeTrue()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Test to verify EU 3-Party Trade True after posting Service Credit Memo.
        PostServiceCrMemoWithEUThirdParty(ServiceHeader."Document Type"::"Credit Memo", true);  // EU 3-Party Trade as True.
    end;

    local procedure PostServiceCrMemoWithEUThirdParty(DocumentType: Enum "Service Document Type"; EUThirdPartyTrade: Boolean)
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ServiceHeader: Record "Service Header";
    begin
        // Setup.
        Initialize();
        CreateServiceCreditMemo(ServiceHeader, DocumentType, EUThirdPartyTrade);

        // Exercise.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);  // Post as ship and invoice.

        // Verify.
        ServiceCrMemoHeader.SetRange("Pre-Assigned No.", ServiceHeader."No.");
        ServiceCrMemoHeader.FindFirst();
        ServiceCrMemoHeader.TestField("EU 3-Party Trade", EUThirdPartyTrade);
    end;

    [Test]
    [HandlerFunctions('VATStatementPreviewPageHandler,VATStatementTemplateListModalPageHandler')]
    [Scope('OnPrem')]
    procedure VATStatementPreviewForSalesInvoiceWithoutCurrency()
    begin
        // Test to verify Amount on VAT Statement Preview page for Sales Invoice with EUThirdPartyTrade and without Currency.

        // Setup.
        Initialize();
        VATStatementPreviewForSalesInvoiceWithEUThirdPartyTrade('');  // Using Blank for Currency Code.
    end;

    [Test]
    [HandlerFunctions('VATStatementPreviewPageHandler,VATStatementTemplateListModalPageHandler')]
    [Scope('OnPrem')]
    procedure VATStatementPreviewForSalesInvoiceWithCurrency()
    var
        CurrencyCode: Code[10];
    begin
        // Test to verify Amount on VAT Statement Preview page for Sales Invoice with EUThirdPartyTrade and Currency.

        // Setup: Create Currency with Exchange rate and update Additional Reporting Currency on General Ledger Setup.
        Initialize();
        CurrencyCode := CreateCurrencyWithExchangeRate();
        UpdateAdditionalReportingCurrOnGeneralLedgerSetup(CurrencyCode);
        VATStatementPreviewForSalesInvoiceWithEUThirdPartyTrade(CurrencyCode);
    end;

    [HandlerFunctions('VATStatementPreviewPageHandler,VATStatementTemplateListModalPageHandler')]
    local procedure VATStatementPreviewForSalesInvoiceWithEUThirdPartyTrade(CurrencyCode: Code[10])
    var
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VATStatementLine: Record "VAT Statement Line";
        VATStatement: TestPage "VAT Statement";
        OldInvoiceRounding: Boolean;
    begin
        // Create and Post Sales Invoice with EUThirdPartyTrade. Create VAT Statement Line. Open VAT Statement page.
        OldInvoiceRounding := UpdateSalesReceivablesSetup(false);  // False for Invoice Rounding.
        CreateVATPostingSetup(VATPostingSetup, false);
        CreateAndPostSalesInvoice(
          SalesLine, CreateCustomer(VATPostingSetup."VAT Bus. Posting Group"), CurrencyCode, VATPostingSetup."VAT Prod. Posting Group",
          true);  // Using True for EUThirdPartyTrade.
        CreateVATStatementLine(
          VATStatementLine, VATStatementLine."Gen. Posting Type"::Sale, SalesLine."VAT Bus. Posting Group",
          SalesLine."VAT Prod. Posting Group");
        LibraryVariableStorage.Enqueue(VATStatementLine."Statement Template Name");  // Enqueue for VATStatementTemplateListModalPageHandler.
        LibraryVariableStorage.Enqueue(
          LibraryERM.ConvertCurrency(-SalesLine."Line Amount" * SalesLine."VAT %" / 100, CurrencyCode, '', WorkDate()));  // Enqueue for VATStatementPreviewPageHandler.  Using Blank for ToCurrency.
        VATStatement.OpenEdit();
        VATStatement.CurrentStmtName.SetValue(VATStatementLine."Statement Name");

        // Exercise.
        VATStatement."P&review".Invoke();  // Opens VATStatementTemplateListModalPageHandler and VATStatementPreviewPageHandler.

        // Verify: Verification of Column Value is done in VATStatementPreviewPageHandler.
        VATStatement.Close();

        // Tear Down.
        UpdateSalesReceivablesSetup(OldInvoiceRounding);
        DeleteVATStatementTemplate(VATStatementLine."Statement Template Name");
    end;

    [Test]
    [HandlerFunctions('VATStatementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VATStatementReportWithEUThirdPartyTrade()
    var
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VATStatementLine: Record "VAT Statement Line";
    begin
        // Test to verify Total Amount on VAT Statement report with EUThirdPartyTrade.

        // Setup: Create and Post Sales Invoice with EUThirdPartyTrade. Create VAT Statement Line.
        Initialize();
        CreateVATPostingSetup(VATPostingSetup, false);
        CreateAndPostSalesInvoice(
          SalesLine, CreateCustomer(VATPostingSetup."VAT Bus. Posting Group"), '', VATPostingSetup."VAT Prod. Posting Group", true);  // Using Blank for Currency Code and True for EUThirdPartyTrade.
        CreateVATStatementLine(
          VATStatementLine, VATStatementLine."Gen. Posting Type"::Sale, SalesLine."VAT Bus. Posting Group",
          SalesLine."VAT Prod. Posting Group");
        LibraryVariableStorage.Enqueue(VATStatementLine."Statement Name");  // Enqueue value for VATStatementRequestPageHandler.
        Commit();  // Commit required to run the Report.

        // Exercise.
        REPORT.Run(REPORT::"VAT Statement");  // Opens VATStatementRequestPageHandler.

        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(TotalAmountCap, -SalesLine."Line Amount" * SalesLine."VAT %" / 100);

        // Tear Down.
        DeleteVATStatementTemplate(VATStatementLine."Statement Template Name");
    end;

    [Test]
    [HandlerFunctions('VATVIESDeclarationTaxAuthRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VATVIESDeclarationTaxAuthRptWithEUThirdPartyTrade()
    begin
        // Test to verify values on VAT - VIES Declaration Tax Authority report with EUThirdPartyTrade.
        PostSalesInvoiceWiithEUThirdPartyTrade(false, TotalValueofItemSuppliesCap, EUThirdPartyItemTradeAmtCap);  // EUService as False.
    end;

    [Test]
    [HandlerFunctions('VATVIESDeclarationTaxAuthRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VATVIESDeclarationTaxAuthorityReportWithEUService()
    begin
        // Test to verify values on VAT - VIES Declaration Tax Authority report with EUService.
        PostSalesInvoiceWiithEUThirdPartyTrade(true, TotalValueOfServiceSuppliesCap, EUThirdPartyServiceTradeAmtCap);  // EUService as True.
    end;

    local procedure PostSalesInvoiceWiithEUThirdPartyTrade(EUService: Boolean; Caption: Text; Caption2: Text)
    var
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        CurrencyCode: Code[10];
        OldAdditionalReportingCurrency: Code[10];
        OldInvoiceRounding: Boolean;
    begin
        // Setup: Create Customer with VAT Registration No. Create a Sales Invoice with EUThirdParty Trade.
        Initialize();
        OldInvoiceRounding := UpdateSalesReceivablesSetup(false);  // False for Invoice Rounding.
        CurrencyCode := CreateCurrencyWithExchangeRate();
        OldAdditionalReportingCurrency := UpdateAdditionalReportingCurrOnGeneralLedgerSetup(CurrencyCode);
        CreateVATPostingSetup(VATPostingSetup, EUService);
        CreateCustomerWithVATRegistrationNo(Customer, VATPostingSetup."VAT Bus. Posting Group");
        CreateAndPostSalesInvoice(SalesLine, Customer."No.", CurrencyCode, VATPostingSetup."VAT Prod. Posting Group", true);  // EUThirdParty as True.
        LibraryVariableStorage.Enqueue(Customer."VAT Registration No.");  // Enqueue value for VATVIESDeclarationTaxAuthRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"VAT- VIES Declaration Tax Auth");  // Opens VATVIESDeclarationTaxAuthRequestPageHandler.

        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(Caption, SalesLine."Line Amount");
        LibraryReportDataset.AssertElementWithValueExists(Caption2, SalesLine."Line Amount");

        // Tear Down.
        UpdateSalesReceivablesSetup(OldInvoiceRounding);
        UpdateAdditionalReportingCurrOnGeneralLedgerSetup(OldAdditionalReportingCurrency);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateAndPostSalesInvoice(var SalesLine: Record "Sales Line"; CustomerNo: Code[20]; CurrencyCode: Code[10]; VATProdPostingGroup: Code[20]; EUThirdPartyTrade: Boolean)
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesDocument(
          SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo, CreateItem(VATProdPostingGroup), CurrencyCode, EUThirdPartyTrade);
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);  // Post as Ship and Invoice.
    end;

    local procedure CreateCurrencyWithExchangeRate(): Code[10]
    var
        Currency: Record Currency;
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateCurrency(Currency);
        Currency.Validate("Residual Gains Account", GLAccount."No.");
        Currency.Validate("Residual Losses Account", GLAccount."No.");
        Currency.Modify(true);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
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

    local procedure CreateCustomerWithVATRegistrationNo(var Customer: Record Customer; VATBusPostingGroup: Code[20])
    var
        CountryRegion: Record "Country/Region";
        VATRegistrationNoFormat: Record "VAT Registration No. Format";
    begin
        LibraryERM.CreateCountryRegion(CountryRegion);
        CountryRegion.Validate("EU Country/Region Code", CountryRegion.Code);
        CountryRegion.Modify(true);
        LibraryERM.CreateVATRegistrationNoFormat(VATRegistrationNoFormat, CountryRegion.Code);
        VATRegistrationNoFormat.Validate(Format, CountryRegion.Code + LibraryUtility.GenerateGUID());
        VATRegistrationNoFormat.Modify(true);
        Customer.Get(CreateCustomer(VATBusPostingGroup));
        Customer.Validate("Country/Region Code", CountryRegion.Code);
        Customer.Validate("VAT Registration No.", LibraryERM.GenerateVATRegistrationNo(CountryRegion.Code));
        Customer.Modify(true);
    end;

    local procedure CreateItem(VATProdPostingGroup: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20];
                                                                                                  ItemNo: Code[20];
                                                                                                  CurrencyCode: Code[10];
                                                                                                  EUThirdPartyTrade: Boolean)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        SalesHeader.Validate("EU 3-Party Trade", EUThirdPartyTrade);
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandDec(10, 2));  // Take random Quantity.
    end;

    local procedure CreateServiceCreditMemo(var ServiceHeader: Record "Service Header"; DocumentType: Enum "Service Document Type"; EUThirdPartyTrade: Boolean)
    var
        Item: Record Item;
        ServiceLine: Record "Service Line";
    begin
        CreateServiceHeader(ServiceHeader, DocumentType, EUThirdPartyTrade);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItem(Item));
        ServiceLine.Validate(Quantity, LibraryRandom.RandDec(10, 2));
        ServiceLine.Modify(true);
    end;

    local procedure CreateServiceDocument(var ServiceHeader: Record "Service Header"; DocumentType: Enum "Service Document Type"; EUThirdPartyTrade: Boolean)
    var
        Item: Record Item;
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        CreateServiceHeader(ServiceHeader, DocumentType, EUThirdPartyTrade);
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItem(Item));
        ServiceLine.Validate(Quantity, LibraryRandom.RandDec(10, 2));
        ServiceLine.Validate("Service Item No.", ServiceItemLine."Item No.");
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Modify(true);
    end;

    local procedure CreateServiceHeader(var ServiceHeader: Record "Service Header"; DocumentType: Enum "Service Document Type"; EUThirdPartyTrade: Boolean)
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceHeader(ServiceHeader, DocumentType, Customer."No.");
        ServiceHeader.Validate("EU 3-Party Trade", EUThirdPartyTrade);
        ServiceHeader.Modify(true);
    end;

    local procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; EUService: Boolean)
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup.Code, VATProductPostingGroup.Code);
        VATPostingSetup.Validate("EU Service", EUService);
        VATPostingSetup.Modify(true);
    end;

    local procedure CreateVATStatementLine(var VATStatementLine: Record "VAT Statement Line"; GenPostingType: Enum "General Posting Type"; VATBusPostingGroup: Code[20];
                                                                                                                  VATProdPostingGroup: Code[20])
    var
        VATStatementName: Record "VAT Statement Name";
        VATStatementTemplate: Record "VAT Statement Template";
    begin
        LibraryERM.CreateVATStatementTemplate(VATStatementTemplate);
        LibraryERM.CreateVATStatementName(VATStatementName, VATStatementTemplate.Name);
        LibraryERM.CreateVATStatementLine(VATStatementLine, VATStatementName."Statement Template Name", VATStatementName.Name);
        VATStatementLine.Validate("Row No.", Format(LibraryRandom.RandInt(100)));
        VATStatementLine.Validate(Type, VATStatementLine.Type::"VAT Entry Totaling");
        VATStatementLine.Validate("Amount Type", VATStatementLine."Amount Type"::Amount);
        VATStatementLine.Validate("Gen. Posting Type", GenPostingType);
        VATStatementLine.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        VATStatementLine.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        VATStatementLine.Modify(true);
    end;

    local procedure DeleteVATStatementTemplate(VATStatementTemplateName: Code[10])
    var
        VATStatementTemplate: Record "VAT Statement Template";
    begin
        VATStatementTemplate.Get(VATStatementTemplateName);
        VATStatementTemplate.Delete(true);
    end;

    local procedure UpdateAdditionalReportingCurrOnGeneralLedgerSetup(CurrencyCode: Code[10]) OldAdditionalReportingCurrency: Code[10]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        OldAdditionalReportingCurrency := GeneralLedgerSetup."Additional Reporting Currency";
        GeneralLedgerSetup."Additional Reporting Currency" := CurrencyCode;
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdateSalesReceivablesSetup(InvoiceRounding: Boolean) OldInvoiceRounding: Boolean
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        OldInvoiceRounding := SalesReceivablesSetup."Invoice Rounding";
        SalesReceivablesSetup.Validate("Invoice Rounding", InvoiceRounding);
        SalesReceivablesSetup.Modify(true);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure VATStatementPreviewPageHandler(var VATStatementPreview: TestPage "VAT Statement Preview")
    var
        ColumnValue: Variant;
    begin
        LibraryVariableStorage.Dequeue(ColumnValue);
        VATStatementPreview.VATStatementLineSubForm.ColumnValue.AssertEquals(ColumnValue);
        VATStatementPreview.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesListModalPageHandler(var SalesList: TestPage "Sales List")
    begin
        SalesList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VATStatementTemplateListModalPageHandler(var VATStatementTemplateList: TestPage "VAT Statement Template List")
    var
        VATStatementTemplateName: Variant;
    begin
        LibraryVariableStorage.Dequeue(VATStatementTemplateName);
        VATStatementTemplateList.FILTER.SetFilter(Name, VATStatementTemplateName);
        VATStatementTemplateList.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VATStatementRequestPageHandler(var VATStatement: TestRequestPage "VAT Statement")
    var
        VATStatementName: Variant;
    begin
        LibraryVariableStorage.Dequeue(VATStatementName);
        VATStatement."VAT Statement Name".SetFilter(Name, VATStatementName);
        VATStatement.StartingDate.SetValue(WorkDate());
        VATStatement.EndingDate.SetValue(WorkDate());
        VATStatement.ShowAmtInAddCurrency.SetValue(true);
        VATStatement.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VATVIESDeclarationTaxAuthRequestPageHandler(var VATVIESDeclarationTaxAuth: TestRequestPage "VAT- VIES Declaration Tax Auth")
    var
        VATRegistrationNoFilter: Variant;
    begin
        LibraryVariableStorage.Dequeue(VATRegistrationNoFilter);
        VATVIESDeclarationTaxAuth.ShowAmountsInAddReportingCurrency.SetValue(true);
        VATVIESDeclarationTaxAuth.StartingDate.SetValue(WorkDate());
        VATVIESDeclarationTaxAuth.EndingDate.SetValue(WorkDate());
        VATVIESDeclarationTaxAuth.VATRegistrationNoFilter.SetValue(VATRegistrationNoFilter);
        VATVIESDeclarationTaxAuth.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Message: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerFalse(Message: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;
}
