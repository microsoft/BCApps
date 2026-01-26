codeunit 144001 "Sales/Purchase Document"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Order] [FCY] [ACY]
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderWithAddReportingCurrency()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        DocumentNo: Code[20];
    begin
        // Verify Purchase Order posted successfully when Currency Code matches with the Additional Reporting Currency on General Ledger Setup.

        // Setup: Create Item and Vendor with Currency. Modify General Ledger Setup for Additional Reporting Currency. Create Purchase Order.
        Initialize();
        GeneralLedgerSetup.Get();
        CreateVendor(Vendor, CreateCurrency(), '');
        ModifyGeneralLedgerSetup(Vendor."Currency Code");
        CreatePurchaseOrder(PurchaseLine, Vendor."No.", '', false);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        // Exercise: Post Purchase Order.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify G/L Entry for Amount and Additional-Currency Amount.
        GeneralPostingSetup.Get(Vendor."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        VerifyGLEntry(Vendor."Currency Code", DocumentNo, GeneralPostingSetup."Purch. Account", PurchaseLine."Line Amount", PurchaseLine."Line Amount");

        // TearDown.
        ModifyGeneralLedgerSetup(GeneralLedgerSetup."Additional Reporting Currency");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderWithAddReportingCurrency()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
        DocumentNo: Code[20];
    begin
        // Verify Sales Order posted successfully when Currency Code matches with the Additional Reporting Currency on General Ledger Setup.

        // Setup: Create Item and Customer with Currency. Modify General Ledger Setup for Additional Reporting Currency. Create Sales Order.
        Initialize();
        CreateCustomerWithCurrency(Customer);
        GeneralLedgerSetup.Get();
        ModifyGeneralLedgerSetup(Customer."Currency Code");
        CreateSalesOrder(SalesLine, Customer."No.");
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");

        // Exercise: Post Purchase Order.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify G/L Entry for Amount and Additional-Currency Amount.
        GeneralPostingSetup.Get(Customer."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        VerifyGLEntry(Customer."Currency Code", DocumentNo, GeneralPostingSetup."Sales Account", -SalesLine."Line Amount", -SalesLine."Line Amount");

        // TearDown.
        ModifyGeneralLedgerSetup(GeneralLedgerSetup."Additional Reporting Currency");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchOrderWithVendorTaxAreaCodeTrue()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        TaxDetail: Record "Tax Detail";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
        TaxAreaCode: Code[20];
    begin
        // Verify G/L Entries after posting Purchase Order when Use Vendor's Tax Area Code is true on Purchase Payable Setup.

        // Setup: Update Purchase Payable Setup,
        Initialize();
        UpdatePurchasePayableSetup();
        TaxAreaCode := CreateTaxAreaLine(TaxDetail);
        CreateVendor(Vendor, '', TaxAreaCode);
        CreatePurchaseOrder(PurchaseLine, Vendor."No.", TaxDetail."Tax Group Code", true);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        // Exercise: Post Purchase Order.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify.
        VATPostingSetup.Get(Vendor."VAT Bus. Posting Group", PurchaseLine."VAT Prod. Posting Group");
        GeneralPostingSetup.Get(Vendor."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        VerifyGLEntry('', DocumentNo, GeneralPostingSetup."Purch. Account", PurchaseLine."Line Amount", 0);  // Taken 0 for Additional-Currency Amount.
        VerifyGLEntry(
          '', DocumentNo, VATPostingSetup."Purchase VAT Account",
          Round(PurchaseLine."Line Amount" * TaxDetail."Tax Below Maximum" / 100), 0);  // Taken 0 for Additional-Currency Amount.
    end;

    local procedure Initialize()
    begin
        LibraryERMCountryData.CreateVATData();
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.FindGLAccount(GLAccount);
        LibraryERM.CreateCurrency(Currency);
        Currency.Validate("Residual Gains Account", GLAccount."No.");
        Currency.Validate("Residual Losses Account", GLAccount."No.");
        Currency.Modify(true);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateCustomerWithCurrency(var Customer: Record Customer)
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Currency Code", CreateCurrency());
        Customer.Modify(true);
    end;

    local procedure CreateItem(TaxGroupCode: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Price", LibraryRandom.RandDec(100, 2));  // Taken Random Unit Price.
        Item.Validate("Last Direct Cost", LibraryRandom.RandDec(100, 2));  // Taken Random Last Direct Cost.
        Item.Validate("Tax Group Code", TaxGroupCode);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreatePurchaseOrder(var PurchaseLine: Record "Purchase Line"; VendorNo: Code[20]; TaxAreaCode: Code[20]; TaxLiable: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo);
        PurchaseHeader.Validate("Tax Liable", TaxLiable);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(TaxAreaCode), LibraryRandom.RandDec(10, 2));  // Taken Random Quantity.
    end;

    local procedure CreateSalesOrder(var SalesLine: Record "Sales Line"; CustomerNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(''), LibraryRandom.RandDec(10, 2));  // Taken Random Quantity.
    end;

    local procedure CreateVendor(var Vendor: Record Vendor; CurrencyCode: Code[10]; TaxAreaCode: Code[20])
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Currency Code", CurrencyCode);
        Vendor.Validate("Tax Area Code", TaxAreaCode);
        Vendor.Modify(true);
    end;

    local procedure CreateTaxAreaLine(var TaxDetail: Record "Tax Detail"): Code[20]
    var
        TaxArea: Record "Tax Area";
        TaxAreaLine: Record "Tax Area Line";
    begin
        CreateSalesTaxDetail(TaxDetail);
        LibraryERM.CreateTaxArea(TaxArea);
        LibraryERM.CreateTaxAreaLine(TaxAreaLine, TaxArea.Code, TaxDetail."Tax Jurisdiction Code");
        exit(TaxArea.Code);
    end;

    local procedure CreateSalesTaxJurisdiction(): Code[10]
    var
        GLAccount: Record "G/L Account";
        TaxJurisdiction: Record "Tax Jurisdiction";
    begin
        LibraryERM.CreateTaxJurisdiction(TaxJurisdiction);
        LibraryERM.CreateGLAccount(GLAccount);
        TaxJurisdiction.Validate("Tax Account (Sales)", GLAccount."No.");
        TaxJurisdiction.Validate("Tax Account (Purchases)", GLAccount."No.");
        TaxJurisdiction.Validate("Reverse Charge (Purchases)", GLAccount."No.");
        TaxJurisdiction.Validate("Report-to Jurisdiction", TaxJurisdiction.Code);
        TaxJurisdiction.Validate("Calculate Tax on Tax", true);
        TaxJurisdiction.Modify(true);
        exit(TaxJurisdiction.Code);
    end;

    local procedure CreateSalesTaxDetail(var TaxDetail: Record "Tax Detail")
    var
        TaxGroup: Record "Tax Group";
    begin
        LibraryERM.CreateTaxGroup(TaxGroup);
        LibraryERM.CreateTaxDetail(TaxDetail, CreateSalesTaxJurisdiction(), TaxGroup.Code, TaxDetail."Tax Type"::"Sales Tax Only", WorkDate());
        TaxDetail.Validate("Tax Below Maximum", LibraryRandom.RandInt(10));  // Using RANDOM value for Tax Below Maximum.
        TaxDetail.Modify(true);
    end;

    local procedure ModifyGeneralLedgerSetup(CurrencyCode: Code[10])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Additional Reporting Currency" := CurrencyCode;
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdatePurchasePayableSetup()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Use Vendor's Tax Area Code", true);
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure VerifyGLEntry(CurrencyCode: Code[10]; DocumentNo: Code[20]; GLAccountNo: Code[20]; Amount: Decimal; AdditionalCurrencyAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindFirst();
        GLEntry.TestField(Amount, LibraryERM.ConvertCurrency(Amount, CurrencyCode, '', WorkDate()));
        GLEntry.TestField("Additional-Currency Amount", AdditionalCurrencyAmount);
    end;
}

