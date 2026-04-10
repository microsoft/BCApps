codeunit 134064 "Sales Tax"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Sales Tax] [Tax Detail]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceSalesTaxBelow()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TaxDetail: Record "Tax Detail";
        TaxJurisdiction: Record "Tax Jurisdiction";
        DocumentNo: Code[20];
    begin
        // Create Sales Invoice.
        Initialize();
        CreateSalesDoc(SalesHeader, SalesLine, false);

        // Create Posting Setup for Sales Tax.
        SetupSalesTax(
              TaxDetail, TaxJurisdiction, SalesLine."Tax Area Code", SalesLine."Tax Group Code", TaxDetail."Tax Type"::"Sales Tax",
              SalesLine."Line Amount" + LibraryRandom.RandDec(1, 2));

        // Post Sales Invoice.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify G/L Entry.
        VerifyGLEntry(
          DocumentNo, TaxJurisdiction."Tax Account (Sales)", -Round(SalesLine."Line Amount" * TaxDetail."Tax Below Maximum" / 100));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceSalesTaxAbove()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TaxDetail: Record "Tax Detail";
        TaxJurisdiction: Record "Tax Jurisdiction";
        DocumentNo: Code[20];
    begin
        // Create Sales Invoice.
        Initialize();
        CreateSalesDoc(SalesHeader, SalesLine, false);

        // Create Posting Setup for Sales Tax.
        SetupSalesTax(
              TaxDetail, TaxJurisdiction, SalesLine."Tax Area Code", SalesLine."Tax Group Code", TaxDetail."Tax Type"::"Sales Tax",
              SalesLine."Line Amount" - LibraryRandom.RandDec(1, 2));

        // Post Sales Invoice.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify G/L Entry.
        VerifyGLEntry(
          DocumentNo, TaxJurisdiction."Tax Account (Sales)", -Round(TaxDetail."Maximum Amount/Qty." * TaxDetail."Tax Below Maximum" / 100 +
            (SalesLine."Line Amount" - TaxDetail."Maximum Amount/Qty.") * TaxDetail."Tax Above Maximum" / 100));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceExciseTaxBelow()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TaxDetail: Record "Tax Detail";
        TaxJurisdiction: Record "Tax Jurisdiction";
        DocumentNo: Code[20];
    begin
        // Create Sales Invoice.
        Initialize();
        CreateSalesDoc(SalesHeader, SalesLine, false);

        // Create Posting Setup for Sales Tax.
        SetupSalesTax(
              TaxDetail, TaxJurisdiction, SalesLine."Tax Area Code", SalesLine."Tax Group Code", TaxDetail."Tax Type"::"Excise Tax",
              SalesLine.Quantity + LibraryRandom.RandInt(5));

        // Post Sales Invoice.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify G/L Entry.
        VerifyGLEntry(DocumentNo, TaxJurisdiction."Tax Account (Sales)", -Round(SalesLine.Quantity * TaxDetail."Tax Below Maximum"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceExciseTaxAbove()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TaxDetail: Record "Tax Detail";
        TaxJurisdiction: Record "Tax Jurisdiction";
        DocumentNo: Code[20];
    begin
        // Create Sales Invoice.
        Initialize();
        CreateSalesDoc(SalesHeader, SalesLine, false);

        // Create Posting Setup for Sales Tax.
        SetupSalesTax(
              TaxDetail, TaxJurisdiction, SalesLine."Tax Area Code", SalesLine."Tax Group Code", TaxDetail."Tax Type"::"Excise Tax",
              SalesLine.Quantity - LibraryRandom.RandInt(SalesLine.Quantity));

        // Post Sales Invoice.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify G/L Entry.
        VerifyGLEntry(
          DocumentNo, TaxJurisdiction."Tax Account (Sales)", -Round(TaxDetail."Maximum Amount/Qty." * TaxDetail."Tax Below Maximum" +
            (SalesLine.Quantity - TaxDetail."Maximum Amount/Qty.") * TaxDetail."Tax Above Maximum"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceSalesTaxBelowReverse()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TaxDetail: Record "Tax Detail";
        TaxJurisdiction: Record "Tax Jurisdiction";
        DocumentNo: Code[20];
    begin
        // Create Sales Invoice.
        Initialize();
        CreateSalesDoc(SalesHeader, SalesLine, true);

        // Create Posting Setup for Sales Tax.
        SetupSalesTax(TaxDetail, TaxJurisdiction, SalesLine."Tax Area Code", SalesLine."Tax Group Code", TaxDetail."Tax Type"::"Sales Tax", 2 * SalesLine."Line Amount");

        // Post Sales Invoice.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify G/L Entry.
        VerifyGLEntry(
          DocumentNo, TaxJurisdiction."Tax Account (Sales)",
          -Round(SalesLine."Line Amount" * TaxDetail."Tax Below Maximum" / (100 + TaxDetail."Tax Below Maximum")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceSalesTaxNoMaxReverse()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TaxDetail: Record "Tax Detail";
        TaxJurisdiction: Record "Tax Jurisdiction";
        DocumentNo: Code[20];
    begin
        // Create Sales Invoice.
        Initialize();
        CreateSalesDoc(SalesHeader, SalesLine, true);

        // Create Posting Setup for Sales Tax.
        SetupSalesTax(TaxDetail, TaxJurisdiction, SalesLine."Tax Area Code", SalesLine."Tax Group Code", TaxDetail."Tax Type"::"Sales Tax", 0);

        // Post Sales Invoice.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify G/L Entry.
        VerifyGLEntry(
          DocumentNo, TaxJurisdiction."Tax Account (Sales)",
          -Round(SalesLine."Line Amount" * TaxDetail."Tax Below Maximum" / (100 + TaxDetail."Tax Below Maximum")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceSalesTaxAboveReverse()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TaxDetail: Record "Tax Detail";
        TaxJurisdiction: Record "Tax Jurisdiction";
        DocumentNo: Code[20];
    begin
        // Create Sales Invoice.
        Initialize();
        CreateSalesDoc(SalesHeader, SalesLine, true);

        // Create Posting Setup for Sales Tax.
        SetupSalesTax(
              TaxDetail, TaxJurisdiction, SalesLine."Tax Area Code", SalesLine."Tax Group Code", TaxDetail."Tax Type"::"Sales Tax", 0.5 * SalesLine."Line Amount");

        // Post Sales Invoice.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify G/L Entry.
        VerifyGLEntry(DocumentNo, TaxJurisdiction."Tax Account (Sales)", -Round(
            (SalesLine."Line Amount" *
             TaxDetail."Tax Above Maximum" -
             TaxDetail."Maximum Amount/Qty." * (TaxDetail."Tax Above Maximum" - TaxDetail."Tax Below Maximum")) /
            (100 + TaxDetail."Tax Above Maximum")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvoicePurchTaxBelow()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        TaxDetail: Record "Tax Detail";
        TaxJurisdiction: Record "Tax Jurisdiction";
        DocumentNo: Code[20];
    begin
        // Create Purch Invoice.
        Initialize();
        CreatePurchDoc(PurchHeader, PurchLine, false);

        // Create Posting Setup for Purch Tax.
        SetupSalesTax(
              TaxDetail, TaxJurisdiction, PurchLine."Tax Area Code", PurchLine."Tax Group Code", TaxDetail."Tax Type"::"Sales Tax",
              PurchLine."Line Amount" + LibraryRandom.RandDec(1, 2));

        // Post Purch Invoice.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        // Verify G/L Entry.
        VerifyGLEntry(
          DocumentNo, TaxJurisdiction."Tax Account (Purchases)", Round(PurchLine."Line Amount" * TaxDetail."Tax Below Maximum" / 100));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvoicePurchTaxAbove()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        TaxDetail: Record "Tax Detail";
        TaxJurisdiction: Record "Tax Jurisdiction";
        DocumentNo: Code[20];
    begin
        // Create Purch Invoice.
        Initialize();
        CreatePurchDoc(PurchHeader, PurchLine, false);

        // Create Posting Setup for Purch Tax.
        SetupSalesTax(
              TaxDetail, TaxJurisdiction, PurchLine."Tax Area Code", PurchLine."Tax Group Code", TaxDetail."Tax Type"::"Sales Tax",
              PurchLine."Line Amount" - LibraryRandom.RandDec(1, 2));

        // Post Purch Invoice.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        // Verify G/L Entry.
        VerifyGLEntry(
          DocumentNo, TaxJurisdiction."Tax Account (Purchases)",
          Round(TaxDetail."Maximum Amount/Qty." * TaxDetail."Tax Below Maximum" / 100 +
            (PurchLine."Line Amount" - TaxDetail."Maximum Amount/Qty.") * TaxDetail."Tax Above Maximum" / 100));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvoiceExciseTaxBelow()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        TaxDetail: Record "Tax Detail";
        TaxJurisdiction: Record "Tax Jurisdiction";
        DocumentNo: Code[20];
    begin
        // Create Purch Invoice.
        Initialize();
        CreatePurchDoc(PurchHeader, PurchLine, false);

        // Create Posting Setup for Purch Tax.
        SetupSalesTax(
              TaxDetail, TaxJurisdiction, PurchLine."Tax Area Code", PurchLine."Tax Group Code", TaxDetail."Tax Type"::"Excise Tax",
              PurchLine.Quantity + LibraryRandom.RandInt(5));

        // Post Purch Invoice.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        // Verify G/L Entry.
        VerifyGLEntry(DocumentNo, TaxJurisdiction."Tax Account (Purchases)", Round(PurchLine.Quantity * TaxDetail."Tax Below Maximum"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvoiceExciseTaxAbove()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        TaxDetail: Record "Tax Detail";
        TaxJurisdiction: Record "Tax Jurisdiction";
        DocumentNo: Code[20];
    begin
        // Create Purch Invoice.
        Initialize();
        CreatePurchDoc(PurchHeader, PurchLine, false);

        // Create Posting Setup for Purch Tax.
        SetupSalesTax(
              TaxDetail, TaxJurisdiction, PurchLine."Tax Area Code", PurchLine."Tax Group Code", TaxDetail."Tax Type"::"Excise Tax",
              PurchLine.Quantity - LibraryRandom.RandInt(PurchLine.Quantity));

        // Post Purch Invoice.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        // Verify G/L Entry.
        VerifyGLEntry(
          DocumentNo, TaxJurisdiction."Tax Account (Purchases)", Round(TaxDetail."Maximum Amount/Qty." * TaxDetail."Tax Below Maximum" +
            (PurchLine.Quantity - TaxDetail."Maximum Amount/Qty.") * TaxDetail."Tax Above Maximum"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvoiceSalesTaxBelowReverse()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        TaxDetail: Record "Tax Detail";
        TaxJurisdiction: Record "Tax Jurisdiction";
        DocumentNo: Code[20];
    begin
        // Create Sales Invoice.
        Initialize();
        CreatePurchDoc(PurchHeader, PurchLine, true);

        // Create Posting Setup for Sales Tax.
        SetupSalesTax(TaxDetail, TaxJurisdiction, PurchLine."Tax Area Code", PurchLine."Tax Group Code", TaxDetail."Tax Type"::"Sales Tax", 2 * PurchLine."Line Amount");

        // Post Sales Invoice.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        // Verify G/L Entry.
        VerifyGLEntry(
          DocumentNo, TaxJurisdiction."Tax Account (Purchases)",
          Round(PurchLine."Line Amount" * TaxDetail."Tax Below Maximum" / (100 + TaxDetail."Tax Below Maximum")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvoiceSalesTaxNoMaxReverse()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        TaxDetail: Record "Tax Detail";
        TaxJurisdiction: Record "Tax Jurisdiction";
        DocumentNo: Code[20];
    begin
        // Create Sales Invoice.
        Initialize();
        CreatePurchDoc(PurchHeader, PurchLine, true);

        // Create Posting Setup for Sales Tax.
        SetupSalesTax(TaxDetail, TaxJurisdiction, PurchLine."Tax Area Code", PurchLine."Tax Group Code", TaxDetail."Tax Type"::"Sales Tax", 0);

        // Post Sales Invoice.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        // Verify G/L Entry.
        VerifyGLEntry(
          DocumentNo, TaxJurisdiction."Tax Account (Purchases)",
          Round(PurchLine."Line Amount" * TaxDetail."Tax Below Maximum" / (100 + TaxDetail."Tax Below Maximum")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvoiceSalesTaxAboveReverse()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        TaxDetail: Record "Tax Detail";
        TaxJurisdiction: Record "Tax Jurisdiction";
        DocumentNo: Code[20];
    begin
        // Create Sales Invoice.
        Initialize();
        CreatePurchDoc(PurchHeader, PurchLine, true);

        // Create Posting Setup for Sales Tax.
        SetupSalesTax(
              TaxDetail, TaxJurisdiction, PurchLine."Tax Area Code", PurchLine."Tax Group Code", TaxDetail."Tax Type"::"Sales Tax", 0.5 * PurchLine."Line Amount");

        // Post Sales Invoice.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        // Verify G/L Entry.
        VerifyGLEntry(
          DocumentNo, TaxJurisdiction."Tax Account (Purchases)",
          Round(
            (PurchLine."Line Amount" *
             TaxDetail."Tax Above Maximum" -
             TaxDetail."Maximum Amount/Qty." * (TaxDetail."Tax Above Maximum" - TaxDetail."Tax Below Maximum")) /
            (100 + TaxDetail."Tax Above Maximum")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultAccountsAreSetOnJurisdictionCreation()
    var
        TaxSetup: Record "Tax Setup";
        TaxJurisdiction: Record "Tax Jurisdiction";
    begin
        // [GIVEN] System is set up to use default accounts on jurisdiction creation
        TaxSetup.Get();
        TaxSetup."Tax Account (Sales)" := LibraryERM.CreateGLAccountNo();
        TaxSetup.Modify();

        // [WHEN] A Jurisdiction is created
        TaxJurisdiction.Init();
        TaxJurisdiction.Validate(Code, LibraryUtility.GenerateRandomCode(TaxJurisdiction.FieldNo(Code), DATABASE::"Tax Jurisdiction"));
        TaxJurisdiction.Insert(true);

        // [THEN] The default account is set
        Assert.AreEqual(TaxSetup."Tax Account (Sales)", TaxJurisdiction."Tax Account (Sales)", 'Default Account not set.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultTaxDetailLinesAreCreatedOnJurisdictionCreation()
    var
        TaxSetup: Record "Tax Setup";
        TaxJurisdiction: Record "Tax Jurisdiction";
        TaxDetail: Record "Tax Detail";
    begin
        // [GIVEN] System is set up to create default tax detail lines on jurisdiction creation
        TaxSetup.Get();
        TaxSetup."Auto. Create Tax Details" := true;
        TaxSetup."Non-Taxable Tax Group Code" := CreateTaxGroup();
        TaxSetup.Modify();

        // [WHEN] A Jurisdiction is created
        CreateTaxJurisdiction(TaxJurisdiction);

        // [THEN] Two Tax Details are created for that jurisdiction
        TaxDetail.SetRange("Tax Jurisdiction Code", TaxJurisdiction.Code);
        Assert.RecordCount(TaxDetail, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultTaxDetailLinesAreNotCreatedByDefault()
    var
        TaxSetup: Record "Tax Setup";
        TaxJurisdiction: Record "Tax Jurisdiction";
        TaxDetail: Record "Tax Detail";
    begin
        // [GIVEN] System is not set up to create default tax detail lines on jurisdiction creation
        TaxSetup.Get();
        TaxSetup."Auto. Create Tax Details" := false;
        TaxSetup.Modify();

        // [WHEN] A Jurisdiction is created
        CreateTaxJurisdiction(TaxJurisdiction);

        // [THEN] No Tax Details are created for that jurisdiction
        TaxDetail.SetRange("Tax Jurisdiction Code", TaxJurisdiction.Code);
        Assert.RecordCount(TaxDetail, 0);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Sales Tax");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Sales Tax");
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Sales Tax");
    end;

    local procedure CreateCustomer(TaxLiable: Boolean; InclVAT: Boolean): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Tax Area Code", CreateTaxArea());
        Customer.Validate("Tax Liable", TaxLiable);
        Customer.Validate("Prices Including VAT", InclVAT);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateItem(VATProdPostingGroup: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        Item.Validate("Tax Group Code", CreateTaxGroup());
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreatePurchDoc(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; InclVAT: Boolean)
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, CreateVendor(true, InclVAT));
        CreateVATPostingSetup(VATPostingSetup, PurchHeader."VAT Bus. Posting Group");
        LibraryPurchase.CreatePurchaseLine(
          PurchLine, PurchHeader, PurchLine.Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group"),
          10 + LibraryRandom.RandInt(10));
        PurchLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchLine.Modify(true);
    end;

    local procedure CreateSalesDoc(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; InclVAT: Boolean)
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomer(true, InclVAT));
        CreateVATPostingSetup(VATPostingSetup, SalesHeader."VAT Bus. Posting Group");
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group"),
          10 + LibraryRandom.RandInt(10));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreateTaxArea(): Code[20]
    var
        TaxArea: Record "Tax Area";
    begin
        TaxArea.Init();
        TaxArea.Validate(Code, LibraryUtility.GenerateRandomCode(TaxArea.FieldNo(Code), DATABASE::"Tax Area"));
        TaxArea.Insert(true);
        exit(TaxArea.Code);
    end;

    local procedure CreateTaxAreaLine(TaxArea: Code[20]; TaxJurisdiction: Code[10])
    var
        TaxAreaLine: Record "Tax Area Line";
    begin
        TaxAreaLine.Init();
        TaxAreaLine.Validate("Tax Area", TaxArea);
        TaxAreaLine.Validate("Tax Jurisdiction Code", TaxJurisdiction);
        TaxAreaLine.Insert(true);
        TaxAreaLine.Validate("Calculation Order", GetNextCalcOrdTaxAreaLine(TaxArea));
        TaxAreaLine.Modify(true);
    end;

    local procedure CreateTaxDetail(var TaxDetail: Record "Tax Detail"; TaxJurisdictionCode: Code[10]; TaxGroupCode: Code[20]; TaxType: Option; EffectiveDate: Date; CalcTaxonTax: Boolean)
    begin
        TaxDetail.Init();
        TaxDetail.Validate("Tax Jurisdiction Code", TaxJurisdictionCode);
        TaxDetail.Validate("Tax Group Code", TaxGroupCode);
        TaxDetail.Validate("Tax Type", TaxType);
        TaxDetail.Validate("Effective Date", EffectiveDate);
        TaxDetail.Insert(true);
        TaxDetail.Validate("Maximum Amount/Qty.", 100 * LibraryRandom.RandDec(100, 2));
        TaxDetail.Validate("Tax Below Maximum", LibraryRandom.RandInt(5));
        TaxDetail.Validate("Tax Above Maximum", LibraryRandom.RandIntInRange(TaxDetail."Tax Below Maximum", 10));
        TaxDetail.Validate("Calculate Tax on Tax", CalcTaxonTax);
        TaxDetail.Modify(true);
    end;

    local procedure CreateTaxGroup(): Code[10]
    var
        TaxGroup: Record "Tax Group";
    begin
        TaxGroup.Init();
        TaxGroup.Validate(Code, LibraryUtility.GenerateRandomCode(TaxGroup.FieldNo(Code), DATABASE::"Tax Group"));
        TaxGroup.Insert(true);
        exit(TaxGroup.Code);
    end;

    local procedure CreateTaxJurisdiction(var TaxJurisdiction: Record "Tax Jurisdiction")
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount."Income/Balance" := GLAccount."Income/Balance"::"Balance Sheet";
        GLAccount.Modify();
        TaxJurisdiction.Init();
        TaxJurisdiction.Validate(Code, LibraryUtility.GenerateRandomCode(TaxJurisdiction.FieldNo(Code), DATABASE::"Tax Jurisdiction"));
        TaxJurisdiction.Insert(true);
        TaxJurisdiction.Validate("Tax Account (Sales)", GLAccount."No.");
        TaxJurisdiction.Validate("Tax Account (Purchases)", GLAccount."No.");
        TaxJurisdiction.Modify(true);
    end;

    local procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; VATBusPostingGroup: Code[20])
    var
        VATProdPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateVATProductPostingGroup(VATProdPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostingGroup, VATProdPostingGroup.Code);
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Sales Tax");
        VATPostingSetup.Modify(true);
    end;

    local procedure CreateVendor(TaxLiable: Boolean; InclVAT: Boolean): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Tax Area Code", CreateTaxArea());
        Vendor.Validate("Tax Liable", TaxLiable);
        Vendor.Validate("Prices Including VAT", InclVAT);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure GetNextCalcOrdTaxAreaLine(TaxArea: Code[20]): Integer
    var
        TaxAreaLine: Record "Tax Area Line";
    begin
        TaxAreaLine.SetFilter("Tax Area", TaxArea);
        TaxAreaLine.SetCurrentKey("Tax Area", "Calculation Order");
        TaxAreaLine.FindLast();
        exit(TaxAreaLine."Calculation Order" + 1);
    end;

    local procedure SetupSalesTax(var TaxDetail: Record "Tax Detail"; var TaxJurisdiction: Record "Tax Jurisdiction"; TaxAreaCode: Code[20]; TaxGroupCode: Code[20]; TaxType: Option; MaxAmountQty: Decimal)
    begin
        CreateTaxJurisdiction(TaxJurisdiction);
        CreateTaxAreaLine(TaxAreaCode, TaxJurisdiction.Code);
        CreateTaxDetail(TaxDetail, TaxJurisdiction.Code, TaxGroupCode, TaxType, WorkDate(), false);
        TaxDetail.Validate("Maximum Amount/Qty.", MaxAmountQty);
        if MaxAmountQty = 0 then
            TaxDetail.Validate("Tax Above Maximum", 0);
        TaxDetail.Modify(true);
    end;

    local procedure VerifyGLEntry(DocumentNo: Code[20]; GLAccountNo: Code[20]; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetFilter("Document No.", DocumentNo);
        GLEntry.SetFilter("G/L Account No.", GLAccountNo);
        GLEntry.FindFirst();
        GLEntry.TestField(Amount, Amount);
    end;
}

