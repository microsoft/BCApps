codeunit 144022 "Sales Docs With Tax O365"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Sales] [O365]
    end;

    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        ValueMustEqualMsg: Label 'Value must be equal.';
        Assert: Codeunit Assert;
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        FieldValueErr: Label '%1 must have value %2';
        CalcSumErr: Label 'CALCSUM for Additional Currency fields must be evaluated';
        FieldDifferenceErr: Label 'Fields %1 and %2 must have equal values';
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderFullLineDiscountPctWithPartialPosting()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentNo: array[2] of Code[20];
    begin
        // Verify General Ledger Entries Amount with Partially Posted Sales Order with 100 % Line Discount Percentage.

        // Setup: Create Sales Order.
        Initialize();
        CreateSalesDocumentWithFullLineDiscount(SalesHeader, SalesHeader."Document Type"::Order, SalesLine);

        // Excercise: Post Sales Order - Partially. Post Sales Order with remaining Quantity to Invoice.
        LibraryLowerPermissions.SetSalesDocsPost();
        DocumentNo[1] := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        DocumentNo[2] := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify General Ledger Entry Amount with calculated Amount for filtered Posted Sales Invoice Line.
        VerifyGLEntryForPostedSalesInvoice(DocumentNo[1], SalesLine);
        VerifyGLEntryForPostedSalesInvoice(DocumentNo[2], SalesLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderWithoutTaxAreaCode()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Verify Shipped Not Invoiced on Sales Line, Post Sales Order as ship and Tax Area code as blank on line.

        // Setup: Create Sales Order with Tax Area Code as Blank.
        Initialize();
        CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        UpdateTaxAreaOnSalesHeader(SalesHeader);
        CreateSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, CreateItem(), LibraryRandom.RandInt(10));  // Random value for Quantity.
        SalesLine.Validate("Tax Area Code", '');  // Blank value is required for Tax Area Code.
        SalesLine.Modify(true);

        // Excercise: Post Ship as Sales Order.
        LibraryLowerPermissions.SetSalesDocsPost();
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // Verify: Verify field - Shipped Not Invoiced with field - Amount of Sales Line Table.
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        SalesLine.TestField("Shipped Not Invoiced", SalesLine.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerListOrderStatusAfterPostSalesOrderAsShip()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustomerListOrderStatus: TestPage "Customer List - Order Status";
        Amount: Decimal;
    begin
        // Verify Shipped Not Invoiced field on page Customer List Order Status after post Sales Order as Ship.

        // Setup: Create Sales Order.
        Initialize();
        CreateCustomer(Customer);
        CreateSalesDocument(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, Customer."No.", SalesLine.Type::Item,
          CreateItem(), LibraryRandom.RandDec(10, 2));  // Random value for Quantity.
        Amount := SalesLine.Quantity * SalesLine."Unit Price";

        // Excercise: Post Sales Order as ship.
        LibraryLowerPermissions.SetSalesDocsPost();
        LibrarySales.PostSalesDocument(SalesHeader, true, false);  // Post as Ship.

        // Verify: Verify Shipped Not Invoiced on Customer List Order Status.
        CustomerListOrderStatus.OpenEdit();
        CustomerListOrderStatus.FILTER.SetFilter("No.", SalesHeader."Sell-to Customer No.");
        Assert.AreEqual(
          Format(Amount), CustomerListOrderStatus.Control1902018507."Shipped Not Invoiced (LCY)".Value,
          ValueMustEqualMsg);
    end;

    [Test]
    [HandlerFunctions('CustomerSalesStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyInvAdjustValueOnCustomerSalesStatisticsReport()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        Location: Record Location;
        LibraryCosting: Codeunit "Library - Costing";
        NoSeries: Codeunit "No. Series";
        DocumentNo: Code[20];
        ItemNo: Code[20];
    begin
        // Verify Item Ledger Entry exist for values Cost of Sales and Profit Amount on Customer Sales Statistics report.

        // Setup: Create and Post Sales Order with purchase adjustment Item Journal.
        Initialize();
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        ItemNo := CreateAndPostItemJournalWithLocationCode(Location.Code);
        CreateSalesDocumentWithLocationCode(SalesHeader, Customer, ItemNo, Location.Code);
        DocumentNo := NoSeries.PeekNextNo(SalesHeader."Shipping No. Series", LibraryUtility.GetNextNoSeriesSalesDate(SalesHeader."Shipping No. Series"));
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        LibraryCosting.AdjustCostItemEntries(ItemNo, '');

        // Exercise: Run Customer Sales Statistics report.
        LibraryLowerPermissions.SetCustomerView();
        Customer.SetRange("No.", Customer."No.");
        Commit();
        REPORT.Run(REPORT::"Customer Sales Statistics", true, false, Customer);

        // Verify: Verify Item Ledger Entry exist for values Cost of Sales and Profit Amount on Customer Sales Statistics report.
        VerifyProfitAmountOnCustomerSalesStatistics(DocumentNo);
    end;

    [Test]
    [HandlerFunctions('SalespersonCommissionsPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyInvAdjustValueOnSalespersonCommissionsReport()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        Location: Record Location;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        LibraryCosting: Codeunit "Library - Costing";
        DocumentNo: Code[20];
        ItemNo: Code[20];
    begin
        // Verify Cust. Ledger Entry exist for values Profit Amount on Salesperson Commissions report.

        // Setup: Create and Post Sales Order with purchase adjustment Item Journal.
        Initialize();
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        ItemNo := CreateAndPostItemJournalWithLocationCode(Location.Code);
        CreateSalesDocumentWithLocationCode(SalesHeader, Customer, ItemNo, Location.Code);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        LibraryCosting.AdjustCostItemEntries(ItemNo, '');

        // Exercise: Run Salesperson Commissions report.
        LibraryLowerPermissions.SetCustomerView();
        CustLedgerEntry.SetRange("Salesperson Code", Customer."Salesperson Code");
        Commit();
        REPORT.Run(REPORT::"Salesperson Commissions", true, false, CustLedgerEntry);

        // Verify: Verify Cust. Ledger Entry exist for values Profit Amount on Salesperson Commissions report.
        VerifyCustLedgerEntryProfitAmt(DocumentNo);
    end;

    [Test]
    [HandlerFunctions('SalespersonStatisticsbyInvPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyInvAdjustValueOnSalespersonStatisticsByInvReport()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        Location: Record Location;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        LibraryCosting: Codeunit "Library - Costing";
        DocumentNo: Code[20];
        ItemNo: Code[20];
    begin
        // Verify Cust. Ledger Entry exist for values Profit Amount on Salesperson Statistics by Inv. report.

        // Setup: Create and Post Sales Order with purchase adjustment Item Journal.
        Initialize();
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        ItemNo := CreateAndPostItemJournalWithLocationCode(Location.Code);
        CreateSalesDocumentWithLocationCode(SalesHeader, Customer, ItemNo, Location.Code);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        LibraryCosting.AdjustCostItemEntries(ItemNo, '');

        // Exercise: Run Salesperson Statistics by Inv. report.
        LibraryLowerPermissions.SetCustomerView();
        CustLedgerEntry.SetRange("Salesperson Code", Customer."Salesperson Code");
        Commit();
        REPORT.Run(REPORT::"Salesperson Statistics by Inv.", true, false, CustLedgerEntry);

        // Verify: Verify Cust. Ledger Entry exist for values Profit Amount on Salesperson Statistics by Inv report.
        VerifyCustLedgerEntryProfitAmt(DocumentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderWithCAVendorAndAdditionalReportingCurrency()
    var
        SalesLine: Record "Sales Line";
    begin
        SalesOrderWithAdditionalReportingCurrencyOrForeignCustomer(
          true, LibraryRandom.RandDec(100, 2), LibraryRandom.RandDec(100, 2),
          SalesLine.Type::"G/L Account", CreateGLAccount(),
          LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderWithAdditionalReportingCurrency()
    var
        SalesLine: Record "Sales Line";
    begin
        SalesOrderWithAdditionalReportingCurrencyOrForeignCustomer(
          true, 100, 98.95, SalesLine.Type::Item, CreateItem(), 1, 1060.1, 5);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
        LibraryApplicationArea.EnableFoundationSetup();
    end;

    local procedure InitializeCustomerAndTaxSettings(var CustomerNo: Code[20]; var PostingDate: Date; var LocationCode: Code[10]; var TaxGroupCode: Code[20]; var TaxAreaCode: Code[20]; CurrencyExchangeRate: Decimal; RelationalCurrencyExchangeRate: Decimal; Foreign: Boolean; TaxBelowMaximum: Decimal)
    var
        Currency: Record Currency;
        TaxJurisdictionCode: Code[10];
        GLAccountRealized: Code[20];
        GLAccountResidual: Code[20];
        GLAccountTax: Code[20];
        SetupDate: Date;
        IncrementDateExpr: Text;
        DateFormula: DateFormula;
    begin
        LibraryERM.CreateCurrency(Currency);

        GLAccountRealized := CreateGLAccount();
        GLAccountResidual := CreateGLAccount();

        SetupDate := CalcDate('<CY-1Y+1D>', WorkDate());
        IncrementDateExpr := StrSubstNo('<+%1D>', LibraryRandom.RandInt(20));
        Evaluate(DateFormula, IncrementDateExpr);
        PostingDate := CalcDate(DateFormula, SetupDate);

        SetCurrencyGLAccounts(Currency.Code, GLAccountRealized, GLAccountResidual);
        CreateExchangeRate(Currency.Code, SetupDate, CurrencyExchangeRate, RelationalCurrencyExchangeRate);
        UpdateAdditionalReportingCurrency(Currency.Code);

        GLAccountTax := CreateGLAccount();
        TaxJurisdictionCode := CreateTaxJurisdiction(GLAccountTax, Foreign);

        TaxAreaCode := CreateTaxAreaGroupDetail(TaxGroupCode, TaxJurisdictionCode, SetupDate, Foreign, TaxBelowMaximum);
        LocationCode := CreateLocation(TaxAreaCode);
        CustomerNo := CreateCustomerWithTaxSettings(Currency.Code, LocationCode, TaxAreaCode);
    end;

    local procedure CreateAndPostItemJournalWithLocationCode(LocationCode: Code[10]): Code[20]
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemCount: Integer;
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        Item.Get(CreateItem());
        for ItemCount := 1 to LibraryRandom.RandInt(5) do begin
            LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
              ItemJournalLine."Entry Type"::Purchase, Item."No.", LibraryRandom.RandInt(10));
            ItemJournalLine.Validate("Location Code", LocationCode);
            ItemJournalLine.Validate("Unit Amount", LibraryRandom.RandDec(10, 2));
            ItemJournalLine.Modify();
        end;
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        exit(Item."No.");
    end;

    local procedure CreateCustomer(var Customer: Record Customer)
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", '');  // Blank value is required for VAT Business Posting Group.
        Customer.Modify(true);
    end;

    local procedure CreateCustomerWithSalesPersonAndLocation(var Customer: Record Customer; LocationCode: Code[10])
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
    begin
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        CreateCustomer(Customer);
        Customer.Validate("Salesperson Code", SalespersonPurchaser.Code);
        Customer.Validate("Location Code", LocationCode);
        Customer.Modify(true);
    end;

    local procedure CreateLocation(TaxAreaCode: Code[20]): Code[10]
    var
        Location: Record Location;
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Tax Area Code", TaxAreaCode);
        Location.Modify(true);
        exit(Location.Code);
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::Purchase);
        Item.Validate("VAT Prod. Posting Group", '');  // Blank value required for creating Sales Line.
        Item.Validate("Unit Cost", LibraryRandom.RandDec(10, 2));  // Take Random Unit Cost.
        Item.Validate("Vendor No.", CreateVendor());
        Item.Modify(true);
        exit(Item."No.");
    end;

    [Scope('OnPrem')]
    procedure CreateItemChargeNo(): Code[20]
    var
        ItemCharge: Record "Item Charge";
    begin
        LibraryInventory.CreateItemCharge(ItemCharge);
        ItemCharge.Validate("VAT Prod. Posting Group", '');
        ItemCharge.Modify(true);
        exit(ItemCharge."No.")
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", '');  // Blank value required for creating Purchase Line.
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]; Type: Enum "Sales Line Type"; No: Code[20]; Quantity: Decimal)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        CreateSalesLine(SalesHeader, SalesLine, Type, No, Quantity);
    end;

    local procedure CreateSalesDocumentWithFullLineDiscount(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; var SalesLine: Record "Sales Line")
    var
        Customer: Record Customer;
        Item: Record Item;
    begin
        CreateCustomer(Customer);
        Item.Get(CreateItem());
        CreateSalesDocument(
          SalesHeader, SalesLine, DocumentType, Customer."No.", SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));  // Random value for Quantity.
        UpdateSalesLineInvoiceToQtyAndLineDiscountPct(SalesLine);  // Update partially Quantity to Invoice and 100 % Line discount - full line discount.
    end;

    local procedure CreateSalesDocumentWithLocationCode(var SalesHeader: Record "Sales Header"; var Customer: Record Customer; ItemNo: Code[20]; LocationCode: Code[10])
    var
        SalesLine: Record "Sales Line";
    begin
        CreateCustomerWithSalesPersonAndLocation(Customer, LocationCode);
        CreateSalesDocument(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, Customer."No.", SalesLine.Type::Item,
          ItemNo, LibraryRandom.RandDec(10, 2));
    end;

    local procedure CreateSalesDocumentWithTaxLiable(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; CustomerNo: Code[20]; TaxAreaCode: Code[20]; PostingDate: Date; LocationCode: Code[10]; Type: Enum "Sales Line Type"; No: Code[20]; Quantity: Decimal)
    begin
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, CustomerNo, Type, No, Quantity);
        SalesHeader.Validate("Tax Liable", true);
        SalesHeader.Validate("Tax Area Code", TaxAreaCode);
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Validate("Location Code", LocationCode);
        SalesHeader.Modify(true);
    end;

    local procedure CreateSalesDocumentWithTaxes(var SalesLine: Record "Sales Line"; TaxAreaCode: Code[20]; TaxGroupCode: Code[20]; LocationCode: Code[10]; CustomerNo: Code[20]; PostingDate: Date; Quantity: Decimal; UnitPrice: Decimal; Type: Enum "Sales Line Type"; No: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesDocumentWithTaxLiable(SalesHeader, SalesLine, CustomerNo, TaxAreaCode, PostingDate, LocationCode, Type, No, Quantity);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Validate("Tax Liable", true);
        SalesLine.Validate("Tax Area Code", TaxAreaCode);
        SalesLine.Validate("Tax Group Code", TaxGroupCode);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; Type: Enum "Sales Line Type"; No: Code[20]; Quantity: Decimal)
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Type, No, Quantity);
        SalesLine.Validate("Unit Price", LibraryRandom.RandInt(10));
        SalesLine.Modify(true);
    end;

    local procedure CreateTaxAreaLine(var TaxAreaLine: Record "Tax Area Line")
    var
        TaxArea: Record "Tax Area";
        TaxJurisdiction: Record "Tax Jurisdiction";
    begin
        LibraryERM.CreateTaxJurisdiction(TaxJurisdiction);
        TaxJurisdiction."Tax Account (Sales)" := CreateGLAccount();
        TaxJurisdiction.Modify(true);
        LibraryERM.CreateTaxArea(TaxArea);
        LibraryERM.CreateTaxAreaLine(TaxAreaLine, TaxArea.Code, TaxJurisdiction.Code);
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        exit(GLAccount."No.");
    end;

    local procedure CreateTaxJurisdiction(GLAccountTaxCode: Code[20]; Foreign: Boolean): Code[10]
    var
        TaxJurisdiction: Record "Tax Jurisdiction";
    begin
        LibraryERM.CreateTaxJurisdiction(TaxJurisdiction);
        TaxJurisdiction.Validate("Tax Account (Sales)", GLAccountTaxCode);
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

    local procedure CreateTaxAreaGroupDetail(var TaxGroupCode: Code[20]; TaxJurisdictionCode: Code[10]; SetupDate: Date; Foreign: Boolean; TaxBelowMaximum: Decimal): Code[20]
    var
        TaxArea1: Record "Tax Area";
        TaxGroup: Record "Tax Group";
        TaxDetail: Record "Tax Detail";
        TaxAreaLine: Record "Tax Area Line";
    begin
        LibraryERM.CreateTaxArea(TaxArea1);
        if Foreign then
            TaxArea1.Validate("Country/Region", TaxArea1."Country/Region"::CA)
        else
            TaxArea1.Validate("Country/Region", TaxArea1."Country/Region"::US);
        TaxArea1.Modify(true);
        LibraryERM.CreateTaxAreaLine(TaxAreaLine, TaxArea1.Code, TaxJurisdictionCode);

        LibraryERM.CreateTaxGroup(TaxGroup);
        TaxGroupCode := TaxGroup.Code;

        LibraryERM.CreateTaxDetail(TaxDetail, TaxJurisdictionCode, TaxGroupCode, TaxDetail."Tax Type"::"Sales and Use Tax", SetupDate);
        TaxDetail.Validate("Tax Below Maximum", TaxBelowMaximum);
        TaxDetail.Modify(true);

        exit(TaxArea1.Code);
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

    local procedure CreateCustomerWithTaxSettings(CurrencyCode: Code[10]; LocationCode: Code[10]; TaxAreaCode: Code[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        CreateCustomer(Customer);
        Customer.Get(Customer."No.");
        Customer.Validate("Tax Liable", true);
        Customer.Validate("Tax Area Code", TaxAreaCode);
        Customer.Validate("Location Code", LocationCode);
        Customer.Validate("Currency Code", CurrencyCode);
        Customer.Modify(true);
        exit(Customer."No.");
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

    local procedure FindItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; DocumentNo: Code[20])
    begin
        ItemLedgerEntry.SetRange("Document Type", ItemLedgerEntry."Document Type"::"Sales Shipment");
        ItemLedgerEntry.SetRange("Document No.", DocumentNo);
        ItemLedgerEntry.FindFirst();
    end;

    local procedure GetCostAmountActualFromValueEntry(DocumentNo: Code[20]) CostAmountActual: Decimal
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Document No.", DocumentNo);
        ValueEntry.SetRange(Adjustment, true);
        if ValueEntry.FindSet() then
            repeat
                CostAmountActual += ValueEntry."Cost Amount (Actual)";
            until ValueEntry.Next() = 0;
        exit(CostAmountActual);
    end;

    local procedure UpdateSalesLineInvoiceToQtyAndLineDiscountPct(SalesLine: Record "Sales Line")
    begin
        SalesLine.Validate("Line Discount %", 100);  // Line discount percentage as 100 required - full line discount.
        SalesLine.Validate("Qty. to Invoice", SalesLine.Quantity / 2);  // Partial Quantity to Invoice.
        SalesLine.Modify(true);
    end;

    local procedure UpdateTaxAreaOnSalesHeader(var SalesHeader: Record "Sales Header")
    var
        TaxArea: Record "Tax Area";
        TaxAreaLine: Record "Tax Area Line";
    begin
        LibraryERM.CreateTaxArea(TaxArea);
        CreateTaxAreaLine(TaxAreaLine);
        SalesHeader.Validate("Tax Liable", true);
        SalesHeader.Validate("Tax Area Code", TaxAreaLine."Tax Area");
        SalesHeader.Modify(true);
    end;

    local procedure SelectPostedSalesInvoiceLine(var SalesInvoiceLine: Record "Sales Invoice Line"; DocumentNo: Code[20]; No: Code[20])
    begin
        SalesInvoiceLine.SetRange("Document No.", DocumentNo);
        SalesInvoiceLine.SetRange(Type, SalesInvoiceLine.Type::Item);
        SalesInvoiceLine.SetRange("No.", No);
        SalesInvoiceLine.FindFirst();
    end;

    [HandlerFunctions('MessageHandler')]
    local procedure SalesOrderWithAdditionalReportingCurrencyOrForeignCustomer(Foreign: Boolean; ExchangeRate: Decimal; RelationalExchangeRate: Decimal; LineType: Enum "Sales Line Type"; LineItemNo: Code[20]; Quantity: Decimal; Price: Decimal; TaxBelowMaximum: Decimal)
    var
        SalesLine: Record "Sales Line";
        LocationCode: Code[10];
        CustomerNo: Code[20];
        TaxGroupCode: Code[20];
        PostingDate: Date;
        TaxAreaCode: Code[20];
        DocNo: Code[20];
    begin
        Initialize();
        InitializeCustomerAndTaxSettings(
          CustomerNo, PostingDate, LocationCode, TaxGroupCode, TaxAreaCode,
          ExchangeRate, RelationalExchangeRate, Foreign, TaxBelowMaximum);

        LibraryLowerPermissions.SetSalesDocsPost();
        CreateSalesDocumentWithTaxes(
          SalesLine, TaxAreaCode, TaxGroupCode, LocationCode, CustomerNo, PostingDate,
          Quantity, Price, LineType, LineItemNo);
        DocNo := PostSalesOrder(SalesLine."Document No.");

        // Verify.
        VerifyGLEntryConsistent(DocNo);
    end;

    local procedure PostSalesOrder(DocumentNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get(SalesHeader."Document Type"::Order, DocumentNo);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure VerifyCustLedgerEntryProfitAmt(DocumentNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        ProfitAmt: Decimal;
    begin
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        CustLedgerEntry.FindFirst();
        ProfitAmt := GetCostAmountActualFromValueEntry(DocumentNo) + CustLedgerEntry."Profit (LCY)";
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('Cust__Ledger_Entry__Document_No__', DocumentNo);
        LibraryReportDataset.AssertElementWithValueExists('Cust__Ledger_Entry__Profit__LCY__', ProfitAmt);
    end;

    local procedure VerifyGLEntry(DocumentNo: Code[20]; GLAccountNo: Code[20]; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindFirst();
        GLEntry.TestField(Amount, Amount);
    end;

    local procedure VerifyGLEntryForPostedSalesInvoice(DocumentNo: Code[20]; SalesLine: Record "Sales Line")
    var
        GeneralPostingSetup: Record "General Posting Setup";
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        GeneralPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        SelectPostedSalesInvoiceLine(SalesInvoiceLine, DocumentNo, SalesLine."No.");
        VerifyGLEntry(DocumentNo, GeneralPostingSetup."Sales Account", -SalesInvoiceLine.Quantity * SalesInvoiceLine."Unit Price");
        VerifyGLEntry(
          DocumentNo, GeneralPostingSetup."Sales Line Disc. Account", SalesInvoiceLine.Quantity * SalesInvoiceLine."Unit Price");
    end;

    local procedure VerifyProfitAmountOnCustomerSalesStatistics(DocumentNo: Code[20])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        MarginProfit: Decimal;
    begin
        FindItemLedgerEntry(ItemLedgerEntry, DocumentNo);
        ItemLedgerEntry.CalcFields("Sales Amount (Actual)");
        ItemLedgerEntry.CalcFields("Cost Amount (Actual)");
        MarginProfit := ItemLedgerEntry."Sales Amount (Actual)" + ItemLedgerEntry."Cost Amount (Actual)";
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Sales___2_', ItemLedgerEntry."Sales Amount (Actual)");
        LibraryReportDataset.AssertElementWithValueExists('Profits___2_', MarginProfit);
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

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerSalesStatisticsPageHandler(var CustomerSalesStatisticspageHandler: TestRequestPage "Customer Sales Statistics")
    begin
        CustomerSalesStatisticspageHandler.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalespersonCommissionsPageHandler(var SalespersonCommissions: TestRequestPage "Salesperson Commissions")
    begin
        SalespersonCommissions.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalespersonStatisticsbyInvPageHandler(var SalespersonStatisticsbyInv: TestRequestPage "Salesperson Statistics by Inv.")
    begin
        SalespersonStatisticsbyInv.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    local procedure UpdateAdditionalReportingCurrency(AdditionalReportingCurrency: Code[10])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Additional Reporting Currency" := AdditionalReportingCurrency;
        GeneralLedgerSetup.Modify(true);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Message handler
    end;
}

