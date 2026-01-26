codeunit 144012 "Purchase Documents With Tax"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Sales Tax] [Purchase]
    end;

    var
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        Assert: Codeunit Assert;
        AmountErr: Label '%1 must be %2 in %3.';
        FieldValueErr: Label '%1 must have value %2';
        CalcSumErr: Label 'CALCSUM for Additional Currency fields must be evaluated';
        FieldDifferenceErr: Label 'Fields %1 and %2 must have equal values';

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseOrderStatisticsModalPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderWithTypeGLAccount()
    var
        PurchaseLine: Record "Purchase Line";
        TaxGroup: Record "Tax Group";
    begin
        // Verify Tax Amount on Statistics Page, Purchase Order with Type - G/L Account.

        // Setup: Create Purchase Order with Type - G/L Account.
        Initialize();
        LibraryERM.CreateTaxGroup(TaxGroup);
        PurchaseOrderWithType(PurchaseLine.Type::"G/L Account", CreateGLAccount(), TaxGroup.Code);
    end;
#endif

    [Test]
    [HandlerFunctions('PurchaseOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure PurchOrderWithTypeGLAccount()
    var
        PurchaseLine: Record "Purchase Line";
        TaxGroup: Record "Tax Group";
    begin
        // Verify Tax Amount on Statistics Page, Purchase Order with Type - G/L Account.

        // Setup: Create Purchase Order with Type - G/L Account.
        Initialize();
        LibraryERM.CreateTaxGroup(TaxGroup);
        PurchOrderWithType(PurchaseLine.Type::"G/L Account", CreateGLAccount(), TaxGroup.Code);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseOrderStatisticsModalPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderWithTypeItem()
    var
        PurchaseLine: Record "Purchase Line";
        TaxGroup: Record "Tax Group";
    begin
        // Verify Tax Amount on Statistics Page, Purchase Order with Type - Item.

        // Setup: Create Purchase Order with Type - Item.
        Initialize();
        LibraryERM.CreateTaxGroup(TaxGroup);
        PurchaseOrderWithType(PurchaseLine.Type::Item, CreateItem(TaxGroup.Code), TaxGroup.Code);
    end;
#endif

    [Test]
    [HandlerFunctions('PurchaseOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure PurchOrderWithTypeItem()
    var
        PurchaseLine: Record "Purchase Line";
        TaxGroup: Record "Tax Group";
    begin
        // Verify Tax Amount on Statistics Page, Purchase Order with Type - Item.

        // Setup: Create Purchase Order with Type - Item.
        Initialize();
        LibraryERM.CreateTaxGroup(TaxGroup);
        PurchOrderWithType(PurchaseLine.Type::Item, CreateItem(TaxGroup.Code), TaxGroup.Code);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    local procedure PurchaseOrderWithType(Type: Enum "Purchase Line Type"; No: Code[20]; TaxGroupCode: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
        TaxAreaLine: Record "Tax Area Line";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // Create Tax Group, Tax Area Line, Tax Detail and Purchase Order.
        CreateTaxAreaLine(TaxAreaLine);
        CreateTaxDetail(TaxAreaLine."Tax Jurisdiction Code", TaxGroupCode);
        CreatePurchaseDocument(PurchaseLine, TaxAreaLine."Tax Area", Type, No, TaxGroupCode, CreateVendor());
        LibraryVariableStorage.Enqueue(
          Round((PurchaseLine."VAT %" * PurchaseLine."Line Amount") / 100, LibraryERM.GetAmountRoundingPrecision()));  // Enqueue value required in PurchaseOrderStatisticsModalPageHandler.

        // Exercise And Verify: Open Purchase Order Statistics page. Verify VAT Amount on PurchaseOrderStatsPageHandler.
        PurchaseOrder.OpenView();
        PurchaseOrder.FILTER.SetFilter("No.", PurchaseLine."Document No.");
        PurchaseOrder.Statistics.Invoke();
        PurchaseOrder.Close();
    end;
#endif

    local procedure PurchOrderWithType(Type: Enum "Purchase Line Type"; No: Code[20]; TaxGroupCode: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
        TaxAreaLine: Record "Tax Area Line";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // Create Tax Group, Tax Area Line, Tax Detail and Purchase Order.
        CreateTaxAreaLine(TaxAreaLine);
        CreateTaxDetail(TaxAreaLine."Tax Jurisdiction Code", TaxGroupCode);
        CreatePurchaseDocument(PurchaseLine, TaxAreaLine."Tax Area", Type, No, TaxGroupCode, CreateVendor());
        LibraryVariableStorage.Enqueue(
          Round((PurchaseLine."VAT %" * PurchaseLine."Line Amount") / 100, LibraryERM.GetAmountRoundingPrecision()));  // Enqueue value required in PurchaseOrderStatisticsPageHandler.

        // Exercise And Verify: Open Purchase Order Statistics page. Verify VAT Amount on PurchaseOrderStatsPageHandler.
        PurchaseOrder.OpenView();
        PurchaseOrder.FILTER.SetFilter("No.", PurchaseLine."Document No.");
        PurchaseOrder.PurchaseOrderStats.Invoke();
        PurchaseOrder.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseOrderTypeGLAccount()
    var
        PurchaseLine: Record "Purchase Line";
        TaxGroup: Record "Tax Group";
    begin
        // Verify General Ledger Entries and Tax Entries, Post Purchase Order with Type - G/L Account.

        // Setup: Create Purchase Order with Type - G/L Account.
        Initialize();
        LibraryERM.CreateTaxGroup(TaxGroup);
        PostPurchaseOrderWithType(PurchaseLine.Type::"G/L Account", CreateGLAccount(), TaxGroup.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseOrderWithTypeItem()
    var
        PurchaseLine: Record "Purchase Line";
        TaxGroup: Record "Tax Group";
    begin
        // Verify General Ledger Entries and Tax Entries, Post Purchase Order with Type - Item.

        // Setup: Create Purchase Order with Type - Item.
        Initialize();
        LibraryERM.CreateTaxGroup(TaxGroup);
        PostPurchaseOrderWithType(PurchaseLine.Type::Item, CreateItem(TaxGroup.Code), TaxGroup.Code);
    end;

    local procedure PostPurchaseOrderWithType(Type: Enum "Purchase Line Type"; No: Code[20]; TaxGroupCode: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
        TaxJurisdiction: Record "Tax Jurisdiction";
        TaxAreaLine: Record "Tax Area Line";
        VATAmount: Decimal;
        DocumentNo: Code[20];
    begin
        // Create Tax Group, Tax Area Line, Tax Detail and Purchase Order.
        CreateTaxAreaLine(TaxAreaLine);
        CreateTaxDetail(TaxAreaLine."Tax Jurisdiction Code", TaxGroupCode);
        CreatePurchaseDocument(PurchaseLine, TaxAreaLine."Tax Area", Type, No, TaxGroupCode, CreateVendor());
        VATAmount := Round((PurchaseLine."VAT %" * PurchaseLine."Line Amount") / 100, LibraryERM.GetAmountRoundingPrecision());

        // Exercise: Post as Receive and Invoice Purchase Order.
        DocumentNo := PostPurchaseOrder(PurchaseLine."Document No.", true, true);

        // Verify: Verify General Ledger Entry Amount and VAT Entry Amount with calculated VATAmount.
        TaxJurisdiction.Get(TaxAreaLine."Tax Jurisdiction Code");
        VerifyGeneralLedgerEntry(DocumentNo, TaxJurisdiction."Tax Account (Purchases)", VATAmount, PurchaseLine.Quantity);
        VerifyVATEntry(DocumentNo, PurchaseLine."Buy-from Vendor No.", PurchaseLine."Line Amount", VATAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderWithoutTaxAreaCode()
    var
        PurchaseLine: Record "Purchase Line";
        TaxGroup: Record "Tax Group";
        TaxAreaLine: Record "Tax Area Line";
    begin
        // Verify Amount Received Not Invoiced on Purchase Line, Post Purchase Order as receive and Tax Area code as blank on line.

        // Setup: Create Tax Group, Tax Area Line and Purchase Order.
        Initialize();
        LibraryERM.CreateTaxGroup(TaxGroup);
        CreateTaxAreaLine(TaxAreaLine);
        CreatePurchaseDocument(PurchaseLine, '', PurchaseLine.Type::Item, CreateItem(TaxGroup.Code), TaxGroup.Code, CreateVendor());  // Blank value for Tax Area Code.

        // Exercise: Post as ship Purchase Order.
        PostPurchaseOrder(PurchaseLine."Document No.", true, false);

        // Verify: Verify Amount Received Not Invoiced in Purchase Line.
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        PurchaseLine.TestField("Amt. Rcd. Not Invoiced", PurchaseLine.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckLineDiscAmountWithPartiallyPosting()
    var
        PurchaseLine: Record "Purchase Line";
        TaxGroup: Record "Tax Group";
        TaxAreaLine: Record "Tax Area Line";
        DocumentNo: Code[20];
        PartialLineAmount: Decimal;
    begin
        // Verify that amount on posted invoice whent purchase order post partially with line discount percentage.

        // Setup: Create purchase order with Line Discount.
        Initialize();
        LibraryERM.CreateTaxGroup(TaxGroup);
        CreateTaxAreaLine(TaxAreaLine);
        CreateTaxDetail(TaxAreaLine."Tax Jurisdiction Code", TaxGroup.Code);
        CreateAndPostPurchaseDocumentWithLineDiscount(PurchaseLine, TaxAreaLine."Tax Area", TaxGroup.Code);

        // Exercise: Post partially Purchase Order.
        PartialLineAmount := ModifyAndUpdatePurchaseLine(PurchaseLine);
        DocumentNo := PostPurchaseOrder(PurchaseLine."Document No.", true, true);

        // Verify: verifying discount amount on posted invoice.
        VerifyAmountOnPostedInvoice(PartialLineAmount, DocumentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderWithCAVendorAndAdditionalReportingCurrency()
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchOrderWithAdditionalReportingCurrencyOrForeignVendor(true, false, LibraryRandom.RandDec(100, 2), LibraryRandom.RandDec(100, 2), PurchaseLine.Type::"G/L Account", CreateGLAccount(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderWithProvincialTaxAreaCode()
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchOrderWithAdditionalReportingCurrencyOrForeignVendor(true, true, LibraryRandom.RandDec(100, 2), LibraryRandom.RandDec(100, 2), PurchaseLine.Type::"G/L Account", CreateGLAccount(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderWithAdditionalReportingCurrency()
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchOrderWithAdditionalReportingCurrencyOrForeignVendor(false, false, 100, 98.95, PurchaseLine.Type::Item, CreateItem(''), 1060.1, 5);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
        LibraryApplicationArea.EnableFoundationSetup();
    end;

    local procedure CreateAndPostPurchaseDocumentWithLineDiscount(var PurchaseLine: Record "Purchase Line"; TaxAreaCode: Code[20]; TaxGroupCode: Code[20])
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", '');  // Blank value required for creating Sales Line.
        Item.Validate("Tax Group Code", TaxGroupCode);
        Item.Modify(true);
        CreatePurchaseDocument(
          PurchaseLine, TaxAreaCode, PurchaseLine.Type::Item, Item."No.", TaxGroupCode, CreateVendor());
        PurchaseLine.Validate("Line Discount %", LibraryRandom.RandDec(10, 2));
        PurchaseLine.Modify(true);
        PostPurchaseOrder(PurchaseLine."Document No.", true, false);
    end;

    local procedure InitializeVendorAndTaxSettings(var VendorNo: Code[20]; var PostingDate: Date; var LocationCode: Code[10]; var TaxGroupCode: Code[20]; var TaxAreaCode: Code[20]; CurrencyExchangeRate: Decimal; RelationalCurrencyExchangeRate: Decimal; Foreign: Boolean; TaxBelowMaximum: Decimal; SetProvincialTaxAreaCode: Boolean)
    var
        Currency: Record Currency;
        TaxJurisdictionCode: Code[20];
        GLAccountRealized: Code[20];
        GLAccountResidual: Code[20];
        GLAccountTax: Code[20];
        SetupDate: Date;
        IncrementDateExpr: Text;
    begin
        LibraryERM.CreateCurrency(Currency);

        GLAccountRealized := CreateGLAccount();
        GLAccountResidual := CreateGLAccount();

        SetupDate := CalcDate('<CY-1Y+1D>', WorkDate());
        IncrementDateExpr := StrSubstNo('<+%1D>', LibraryRandom.RandInt(20));
        PostingDate := CalcDate(IncrementDateExpr, SetupDate);

        SetCurrencyGLAccounts(Currency.Code, GLAccountRealized, GLAccountResidual);
        CreateExchangeRate(Currency.Code, SetupDate, CurrencyExchangeRate, RelationalCurrencyExchangeRate);
        UpdateAdditionalReportingCurrency(Currency.Code);

        GLAccountTax := CreateGLAccount();
        TaxJurisdictionCode := CreateTaxJurisdiction(GLAccountTax, Foreign);

        TaxAreaCode := CreateTaxAreaGroupDetail(TaxGroupCode, TaxJurisdictionCode, SetupDate, Foreign, TaxBelowMaximum);
        LocationCode := CreateLocation(TaxAreaCode, SetProvincialTaxAreaCode);
        VendorNo := CreateVendorWithTaxSettings(Currency.Code, LocationCode, TaxAreaCode);
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", '');  // Blank value for VAT Business Posting Group required.
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateItem(TaxGroupCode: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", '');  // Blank value for VAT Product Posting Group required.
        Item.Validate("Tax Group Code", TaxGroupCode);
        Item.Modify(true);
        exit(Item."No.")
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        exit(GLAccount."No.");
    end;

    local procedure CreatePurchaseDocument(var PurchaseLine: Record "Purchase Line"; TaxArea: Code[20]; Type: Enum "Purchase Line Type"; No: Code[20]; TaxGroupCode: Code[20]; VendorCode: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreatePurchaseHeader(PurchaseHeader, TaxArea, VendorCode);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type, No, LibraryRandom.RandDec(10, 2));  // Used Random value for Quantity.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));
        PurchaseLine.Validate("Tax Group Code", TaxGroupCode);
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseDocumentWithTaxes(var PurchaseLine: Record "Purchase Line"; TaxAreaCode: Code[20]; TaxGroupCode: Code[20]; LocationCode: Code[10]; VendorNo: Code[20]; PostingDate: Date; LineType: Enum "Purchase Line Type"; No: Code[20]; Cost: Decimal; SetProvincialTaxAreaCode: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreatePurchaseHeader(PurchaseHeader, TaxAreaCode, VendorNo);
        PurchaseHeader.Validate("Posting Date", PostingDate);
        PurchaseHeader.Validate("Location Code", LocationCode);
        if SetProvincialTaxAreaCode then
            PurchaseHeader.Validate("Provincial Tax Area Code", TaxAreaCode);
        PurchaseHeader.Modify(true);

        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, LineType, No, PurchaseLine.Quantity);
        // Used Random value for Quantity.
        if LocationCode <> '' then
            PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Validate(Quantity, Cost);
        PurchaseLine.Validate("Direct Unit Cost", Cost);
        PurchaseLine.Validate("Tax Group Code", TaxGroupCode);
        if SetProvincialTaxAreaCode then
            PurchaseLine.Validate("Provincial Tax Area Code", TaxAreaCode);
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; TaxAreaCode: Code[20]; VendorCode: Code[20])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorCode);
        PurchaseHeader.Validate("Tax Liable", true);
        PurchaseHeader.Validate("Tax Area Code", TaxAreaCode);
        PurchaseHeader.Modify(true);
    end;

    local procedure CreateTaxDetail(TaxJurisdictionCode: Code[10]; TaxGroupCode: Code[20])
    var
        TaxDetail: Record "Tax Detail";
    begin
        LibraryERM.CreateTaxDetail(TaxDetail, TaxJurisdictionCode, TaxGroupCode, TaxDetail."Tax Type"::"Sales and Use Tax", WorkDate());
        TaxDetail.Validate("Tax Below Maximum", LibraryRandom.RandDec(10, 2));
        TaxDetail.Modify(true);
    end;

    local procedure CreateTaxAreaLine(var TaxAreaLine: Record "Tax Area Line")
    var
        TaxArea: Record "Tax Area";
        TaxJurisdiction: Record "Tax Jurisdiction";
    begin
        LibraryERM.CreateTaxJurisdiction(TaxJurisdiction);
        TaxJurisdiction."Tax Account (Purchases)" := CreateGLAccount();
        TaxJurisdiction.Modify(true);
        LibraryERM.CreateTaxArea(TaxArea);
        LibraryERM.CreateTaxAreaLine(TaxAreaLine, TaxArea.Code, TaxJurisdiction.Code);
    end;

    local procedure ModifyAndUpdatePurchaseLine(var PurchaseLine: Record "Purchase Line") Amount: Decimal
    begin
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        PurchaseLine.Validate("Qty. to Invoice", PurchaseLine."Qty. to Invoice" / LibraryRandom.RandIntInRange(2, 5));
        PurchaseLine.Modify(true);
        Amount := PurchaseLine."Qty. to Invoice" * PurchaseLine."Direct Unit Cost" * (1 - PurchaseLine."Line Discount %" / 100);
        exit(Amount);
    end;

    local procedure CreateTaxJurisdiction(GLAccountTaxCode: Code[20]; Foreign: Boolean): Code[20]
    var
        TaxJurisdiction: Record "Tax Jurisdiction";
    begin
        LibraryERM.CreateTaxJurisdiction(TaxJurisdiction);
        TaxJurisdiction.Validate("Tax Account (Purchases)", GLAccountTaxCode);
        TaxJurisdiction.Validate("Reverse Charge (Purchases)", GLAccountTaxCode);
        TaxJurisdiction.Validate("Report-to Jurisdiction", '');
        if Foreign then
            TaxJurisdiction.Validate("Country/Region", TaxJurisdiction."Country/Region"::CA)
        else
            TaxJurisdiction.Validate("Country/Region", TaxJurisdiction."Country/Region"::US);
        TaxJurisdiction.Modify(true);
        exit(TaxJurisdiction.Code);
    end;

    local procedure CreateTaxAreaGroupDetail(var TaxGroupCode: Code[20]; TaxJurisdictionCode: Code[20]; SetupDate: Date; Foreign: Boolean; TaxBelowMaximum: Decimal): Code[20]
    var
        TaxArea: Record "Tax Area";
        TaxGroup: Record "Tax Group";
        TaxDetail: Record "Tax Detail";
        TaxAreaLine: Record "Tax Area Line";
    begin
        LibraryERM.CreateTaxArea(TaxArea);
        if Foreign then
            TaxArea.Validate("Country/Region", TaxArea."Country/Region"::CA)
        else
            TaxArea.Validate("Country/Region", TaxArea."Country/Region"::US);
        TaxArea.Modify(true);
        LibraryERM.CreateTaxAreaLine(TaxAreaLine, TaxArea.Code, TaxJurisdictionCode);

        LibraryERM.CreateTaxGroup(TaxGroup);
        TaxGroupCode := TaxGroup.Code;

        LibraryERM.CreateTaxDetail(TaxDetail, TaxJurisdictionCode, TaxGroupCode, TaxDetail."Tax Type"::"Sales and Use Tax", SetupDate);
        TaxDetail.Validate("Tax Below Maximum", TaxBelowMaximum);
        TaxDetail.Modify(true);

        exit(TaxArea.Code);
    end;

    local procedure CreateExchangeRate(CurrencyCode: Code[10]; StartingDate: Date; ExchangeRateValue: Decimal; RelationalExchangeRate: Decimal)
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        LibraryERM.CreateExchRate(CurrencyExchangeRate, CurrencyCode, StartingDate);
        CurrencyExchangeRate.Validate("Exchange Rate Amount", ExchangeRateValue);
        CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", ExchangeRateValue);
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", RelationalExchangeRate);
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", RelationalExchangeRate);
        CurrencyExchangeRate.Modify(true);
    end;

    local procedure CreateVendorWithTaxSettings(CurrencyCode: Code[10]; LocationCode: Code[10]; TaxAreaCode: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
        VendorNo: Code[20];
    begin
        VendorNo := CreateVendor();
        Vendor.Get(VendorNo);
        Vendor.Validate("Tax Liable", true);
        Vendor.Validate("Tax Area Code", TaxAreaCode);
        Vendor.Validate("Location Code", LocationCode);
        Vendor.Validate("Currency Code", CurrencyCode);
        Vendor.Modify(true);
        exit(VendorNo);
    end;

    local procedure CreateLocation(TaxAreaCode: Code[20]; SetProvincialTaxAreaCode: Boolean): Code[10]
    var
        Location: Record Location;
    begin
        LibraryWarehouse.CreateLocation(Location);
        Location.Validate("Tax Area Code", TaxAreaCode);
        if SetProvincialTaxAreaCode then
            Location.Validate("Provincial Tax Area Code", TaxAreaCode);
        Location.Modify(true);
        exit(Location.Code);
    end;

    local procedure SetCurrencyGLAccounts(CurrencyCode: Code[10]; GLAccountRealized: Code[20]; GLAccountResidual: Code[20])
    var
        Currency: Record Currency;
    begin
        Currency.Get(CurrencyCode);
        Currency.Validate("Realized Gains Acc.", GLAccountRealized);
        Currency.Validate("Realized Losses Acc.", GLAccountRealized);
        Currency.Validate("Residual Gains Account", GLAccountResidual);
        Currency.Validate("Residual Losses Account", GLAccountResidual);
        Currency.Modify(true);
    end;

    local procedure PurchOrderWithAdditionalReportingCurrencyOrForeignVendor(Foreign: Boolean; SetProvincialTaxAreaCode: Boolean; ExchangeRate: Decimal; RelationalExchangeRate: Decimal; LineType: Enum "Purchase Line Type"; LineItemNo: Code[20]; Price: Decimal; TaxBelowMaximum: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
        LocationCode: Code[10];
        VendorNo: Code[20];
        TaxGroupCode: Code[20];
        PostingDate: Date;
        TaxAreaCode: Code[20];
        DocNo: Code[20];
    begin
        Initialize();

        InitializeVendorAndTaxSettings(
          VendorNo, PostingDate, LocationCode, TaxGroupCode, TaxAreaCode,
          ExchangeRate, RelationalExchangeRate, Foreign, TaxBelowMaximum, SetProvincialTaxAreaCode);

        // Exercise
        CreatePurchaseDocumentWithTaxes(
          PurchaseLine, TaxAreaCode, TaxGroupCode, '', VendorNo, PostingDate,
          LineType, LineItemNo, Price, SetProvincialTaxAreaCode);
        DocNo := PostPurchaseOrder(PurchaseLine."Document No.", true, true);

        // Verify.
        VerifyGLEntryConsistent(DocNo);
    end;

    local procedure PostPurchaseOrder(DocumentNo: Code[20]; ToShipReceive: Boolean; ToInvoice: Boolean): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, DocumentNo);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, ToShipReceive, ToInvoice));
    end;

    local procedure VerifyAmountOnPostedInvoice(ExpectedAmount: Decimal; DocumentNo: Code[20])
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        Assert: Codeunit Assert;
    begin
        PurchInvHeader.Get(DocumentNo);
        PurchInvHeader.CalcFields(Amount);
        Assert.AreNearlyEqual(
          ExpectedAmount, PurchInvHeader.Amount, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountErr, PurchInvHeader.FieldCaption(Amount), ExpectedAmount, PurchInvHeader.TableCaption()));
    end;

    local procedure VerifyGeneralLedgerEntry(DocumentNo: Code[20]; GLAccountNo: Code[20]; Amount: Decimal; Quantity: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Invoice);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindFirst();
        GLEntry.TestField(Amount, Amount);
        GLEntry.TestField(Quantity, Quantity);
    end;

    local procedure VerifyVATEntry(DocumentNo: Code[20]; BillToPayToNo: Code[20]; Base: Decimal; Amount: Decimal)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Invoice);
        VATEntry.SetRange(Type, VATEntry.Type::Purchase);
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.SetRange("Bill-to/Pay-to No.", BillToPayToNo);
        VATEntry.FindFirst();
        VATEntry.TestField(Base, Base);
        VATEntry.TestField(Amount, Amount);
    end;

    local procedure VerifyGLEntryConsistent(DocNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
        PurchaseHeader: Record "Purchase Header";
    begin
        GLEntry.SetRange("Document Type", PurchaseHeader."Document Type"::Order.AsInteger());
        GLEntry.SetRange("Document No.", DocNo);

        Assert.IsTrue(
          GLEntry.CalcSums(
            "Additional-Currency Amount",
            "Add.-Currency Debit Amount",
            "Add.-Currency Credit Amount"),
          CalcSumErr);
        Assert.AreEqual(
          0,
          GLEntry."Additional-Currency Amount",
          StrSubstNo(FieldValueErr, GLEntry.FieldCaption("Additional-Currency Amount"), 0));
        Assert.AreEqual(
          0,
          GLEntry."Add.-Currency Debit Amount" - GLEntry."Add.-Currency Credit Amount",
          StrSubstNo(
            FieldDifferenceErr,
            GLEntry.FieldCaption("Add.-Currency Debit Amount"),
            GLEntry.FieldCaption("Add.-Currency Credit Amount")));
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseOrderStatisticsModalPageHandler(var PurchaseOrderStats: TestPage "Purchase Order Stats.")
    var
        VATAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(VATAmount);
        PurchaseOrderStats."VATAmount[2]".AssertEquals(VATAmount);
        PurchaseOrderStats.OK().Invoke();
    end;
#endif

    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchaseOrderStatisticsPageHandler(var PurchaseOrderStats: TestPage "Purchase Order Stats.")
    var
        VATAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(VATAmount);
        PurchaseOrderStats."VATAmount[2]".AssertEquals(VATAmount);
        PurchaseOrderStats.OK().Invoke();
    end;

    local procedure UpdateAdditionalReportingCurrency(AdditionalReportingCurrency: Code[10])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Additional Reporting Currency" := AdditionalReportingCurrency;
        GeneralLedgerSetup.Modify(true);
    end;
}

