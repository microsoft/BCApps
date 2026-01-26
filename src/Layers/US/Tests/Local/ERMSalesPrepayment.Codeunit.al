codeunit 141000 "ERM Sales Prepayment"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Sales] [Prepayment]
        isInitialized := false;
    end;

    var
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        isInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure SalesDocumentPostingAfterPrepaymentInvoice_ExistingTaxArea_NonLCY_PrepmtDontIncludeTax()
    var
        ForLCY: Boolean;
        ForNewTaxArea: Boolean;
    begin
        ForNewTaxArea := false;
        ForLCY := false;
        SalesDocumentPostingAfterPrepaymentInvoice_PrepmtDontIncludeTax(ForLCY, ForNewTaxArea);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesDocumentPostingAfterPrepaymentInvoice_ExistingTaxArea_LCY_PrepmtIncludeTax()
    var
        ForLCY: Boolean;
        ForNewTaxArea: Boolean;
    begin
        ForNewTaxArea := false;
        ForLCY := true;
        SalesDocumentPostingAfterPrepaymentInvoice_PrepmtIncludeTax(ForLCY, ForNewTaxArea);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesDocumentPostingAfterPrepaymentInvoice_ExistingTaxArea_LCY_PrepmtDontIncludeTax()
    var
        ForLCY: Boolean;
        ForNewTaxArea: Boolean;
    begin
        ForNewTaxArea := false;
        ForLCY := true;
        SalesDocumentPostingAfterPrepaymentInvoice_PrepmtDontIncludeTax(ForLCY, ForNewTaxArea);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesDocumentPostingAfterPrepaymentInvoice_NewTaxArea_NonLCY_PrepmtDontIncludeTax()
    var
        ForLCY: Boolean;
        ForNewTaxArea: Boolean;
    begin
        ForNewTaxArea := true;
        ForLCY := false;

        SalesDocumentPostingAfterPrepaymentInvoice_PrepmtDontIncludeTax(ForLCY, ForNewTaxArea);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesDocumentPostingAfterPrepaymentInvoice_NewTaxArea_LCY_PrepmtIncludeTax()
    var
        ForLCY: Boolean;
        ForNewTaxArea: Boolean;
    begin
        ForNewTaxArea := true;
        ForLCY := true;
        SalesDocumentPostingAfterPrepaymentInvoice_PrepmtIncludeTax(ForLCY, ForNewTaxArea);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesDocumentPostingAfterPrepaymentInvoice_NewTaxArea_LCY_PrepmtDontIncludeTax()
    var
        ForLCY: Boolean;
        ForNewTaxArea: Boolean;
    begin
        ForNewTaxArea := true;
        ForLCY := true;
        SalesDocumentPostingAfterPrepaymentInvoice_PrepmtDontIncludeTax(ForLCY, ForNewTaxArea);
    end;

    local procedure SalesDocumentPostingAfterPrepaymentInvoice_PrepmtIncludeTax(ForLCY: Boolean; ForNewTaxArea: Boolean)
    begin
        SalesDocumentPostingAfterPrepaymentInvoice(ForLCY, ForNewTaxArea, true);
    end;

    local procedure SalesDocumentPostingAfterPrepaymentInvoice_PrepmtDontIncludeTax(ForLCY: Boolean; ForNewTaxArea: Boolean)
    begin
        SalesDocumentPostingAfterPrepaymentInvoice(ForLCY, ForNewTaxArea, false);
    end;

    local procedure SalesDocumentPostingAfterPrepaymentInvoice(ForLCY: Boolean; ForNewTaxArea: Boolean; PrepmtIncludeTax: Boolean)
    var
        GenPostingSetup: Record "General Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesInvHeader: Record "Sales Invoice Header";
        TaxGroup: Record "Tax Group";
        SalesPostPrepayments: Codeunit "Sales-Post Prepayments";
        DocNo: Code[20];
        CurrencyCode: Code[10];
    begin
        Initialize();

        if not ForLCY then begin
            CurrencyCode := FindCurrency();
            CreateNewExchangeRate(CurrencyCode);
        end;

        FindGenPostingSetup(GenPostingSetup);
        CreateSalesDocumentWithRandomPrepaymentPercent
        (SalesHeader,
          CreateCustomerWithTaxAreaCode(TaxGroup, CurrencyCode, ForNewTaxArea),
          CreateItemWithTaxGroupCodeAndRandomUnitPrice(
            GenPostingSetup."Gen. Prod. Posting Group",
            TaxGroup.Code),
          PrepmtIncludeTax);

        // 2. Exercise: Post the Prepayment Sales Invoice and Sales Shipment & Invoice.
        SalesPostPrepayments.Invoice(SalesHeader);
        DocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // 3. Verify: Verify that, the Sales Invoice has been posted successfully.
        SalesInvHeader.Get(DocNo);
    end;

    local procedure CreateGLAccount(GenProdPostingGroup: Code[20]; Description: Code[50]): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Prod. Posting Group", GenProdPostingGroup);
        GLAccount.Validate(Name, Description); // add description for readability of the results.
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateItemWithTaxGroupCodeAndRandomUnitPrice(GenProdPostingGroupCode: Code[20]; TaxGroupCode: Code[20]): Code[20]
    var
        Item: Record Item;
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Price", LibraryRandom.RandDec(99, 5));
        Item.Validate("Gen. Prod. Posting Group", GenProdPostingGroupCode);
        Item.Validate("Tax Group Code", TaxGroupCode);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure FindGenPostingSetup(var GenPostingSetup: Record "General Posting Setup")
    begin
        GenPostingSetup.SetFilter("Gen. Bus. Posting Group", '<>''''');
        GenPostingSetup.SetFilter("Gen. Prod. Posting Group", '<>''''');
        GenPostingSetup.SetFilter("Sales Account", '<>''''');
        GenPostingSetup.SetFilter("Sales Prepayments Account", '<>''''');
        GenPostingSetup.FindLast();
    end;

    local procedure CreateSalesDocumentWithRandomPrepaymentPercent(var SalesHeader: Record "Sales Header"; SellToCustomerNo: Code[20]; No: Code[20]; PrepmtIncludeTax: Boolean)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, SellToCustomerNo);
        SalesHeader.Validate("Prepayment %", LibraryRandom.RandDec(10, 2));
        SalesHeader.Validate("Prepmt. Include Tax", PrepmtIncludeTax);
        SalesHeader.Modify(true);
        CreateVATPostingSetup(SalesHeader."VAT Bus. Posting Group");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, No, LibraryRandom.RandDec(100, 2));
    end;

    local procedure CreateSalesTaxJurisdiction(var TaxJurisdiction: Record "Tax Jurisdiction")
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateTaxJurisdiction(TaxJurisdiction);
        LibraryERM.CreateGLAccount(GLAccount);
        TaxJurisdiction.Validate("Tax Account (Sales)", GLAccount."No.");
        TaxJurisdiction.Modify(true);
    end;

    local procedure CreateSalesTaxDetail(var TaxDetail: Record "Tax Detail"; var TaxGroup: Record "Tax Group"; TaxJurisdictionCode: Code[10])
    begin
        LibraryERM.CreateTaxGroup(TaxGroup);
        LibraryERM.CreateTaxDetail(TaxDetail, TaxJurisdictionCode, TaxGroup.Code, TaxDetail."Tax Type"::"Sales Tax Only", WorkDate());
    end;

    local procedure CreateTaxArea(var TaxGroup: Record "Tax Group"): Code[20]
    var
        TaxArea: Record "Tax Area";
        TaxJurisdiction: Record "Tax Jurisdiction";
        TaxDetail: Record "Tax Detail";
        TaxAreaLine: Record "Tax Area Line";
    begin
        LibraryERM.CreateTaxArea(TaxArea);
        CreateSalesTaxJurisdiction(TaxJurisdiction);
        CreateSalesTaxDetail(TaxDetail, TaxGroup, TaxJurisdiction.Code);
        LibraryERM.CreateTaxAreaLine(TaxAreaLine, TaxArea.Code, TaxJurisdiction.Code);
        exit(TaxArea.Code);
    end;

    local procedure SelectTaxArea(var TaxGroup: Record "Tax Group"): Code[20]
    var
        TaxDetail: Record "Tax Detail";
        TaxAreaLine: Record "Tax Area Line";
    begin
        if not TaxAreaLine.FindFirst() then
            exit(CreateTaxArea(TaxGroup));

        TaxDetail.SetFilter("Tax Jurisdiction Code", TaxAreaLine."Tax Jurisdiction Code");
        if not TaxDetail.FindFirst() then
            exit(CreateTaxArea(TaxGroup));

        TaxGroup.Get(TaxDetail."Tax Group Code");
        exit(TaxAreaLine."Tax Area");
    end;

    local procedure CreateVATPostingSetup(VATBusPostingGroup: Code[20])
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATProdPostingGroup: Code[20];
    begin
        VATProdPostingGroup := '';
        if VATPostingSetup.Get(VATBusPostingGroup, VATProdPostingGroup) then
            exit;

        VATPostingSetup.Init();
        VATPostingSetup.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        VATPostingSetup.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        VATPostingSetup.Validate("Sales VAT Account", CreateGLAccount('', ''));
        VATPostingSetup.Insert();
    end;

    local procedure FindCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        Currency.FindFirst();
        exit(Currency.Code);
    end;

    local procedure CreateCustomerWithTaxAreaCode(var TaxGroup: Record "Tax Group"; CurrencyCode: Code[10]; ForNewTaxArea: Boolean): Code[20]
    var
        Customer: Record Customer;
        GeneralPostingSetup: Record "General Posting Setup";
        CustomerPostingGroup: Record "Customer Posting Group";
        GLAccount: Record "G/L Account";
    begin
        LibrarySales.CreateCustomer(Customer);

        FindGenPostingSetup(GeneralPostingSetup);
        Customer.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");

        CustomerPostingGroup.FindFirst();
        Customer.Validate("Customer Posting Group", CustomerPostingGroup.Code);
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Validate("Tax Group Code", TaxGroup.Code);
        GLAccount.Modify(true);
        CustomerPostingGroup.Validate("Invoice Rounding Account", GLAccount."No.");
        CustomerPostingGroup.Modify(true);
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Tax Group Code", TaxGroup.Code);
        GLAccount.Modify(true);
        GeneralPostingSetup.Validate("Sales Prepayments Account", GLAccount."No.");
        GeneralPostingSetup.Modify(true);

        Customer.Validate("Tax Liable", true);
        if ForNewTaxArea then
            Customer.Validate("Tax Area Code", CreateTaxArea(TaxGroup))
        else
            Customer.Validate("Tax Area Code", SelectTaxArea(TaxGroup));

        if CurrencyCode <> '' then
            Customer.Validate("Currency Code", CurrencyCode);

        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateNewExchangeRate(CurrencyCode: Code[10])
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        NewExchangeRateAmount: Decimal;
        NewRelationalExchRateAmount: Decimal;
    begin
        NewExchangeRateAmount := LibraryRandom.RandDecInRange(1, 100, 2);
        NewRelationalExchRateAmount := LibraryRandom.RandDecInRange(101, 200, 2);

        if not CurrencyExchangeRate.Get(CurrencyCode, WorkDate()) then
            LibraryERM.CreateExchRate(CurrencyExchangeRate, CurrencyCode, WorkDate());
        CurrencyExchangeRate.Validate("Exchange Rate Amount", NewExchangeRateAmount);
        CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", NewExchangeRateAmount);
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", NewRelationalExchRateAmount);
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", NewRelationalExchRateAmount);
        CurrencyExchangeRate.Modify(true);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        if isInitialized then
            exit;

        LibraryERMCountryData.CreateVATData();
        LibraryApplicationArea.EnableEssentialSetup();

        isInitialized := true;
        Commit();
    end;
}
