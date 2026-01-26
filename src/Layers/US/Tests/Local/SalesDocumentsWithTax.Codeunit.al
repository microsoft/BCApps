codeunit 144013 "Sales Documents With Tax"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Sales Tax] [Sales]
    end;

    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        LibraryResource: Codeunit "Library - Resource";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        ValueMustEqual: Label 'Value must be equal.';
        LibraryPlanning: Codeunit "Library - Planning";
        Assert: Codeunit Assert;
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryUTUtility: Codeunit "Library UT Utility";
        RemainingPmtDiscountPossibleDoesNotHaveValueErr: Label 'Remaining Pmt. Discount Possible does not have a value';
        IncorrectBalanceErr: Label 'Balance in %1 is incorrect', Comment = '%1=Page Name';

    [Test]
    [Scope('OnPrem')]
    procedure SalesReturnOrderFullLineDiscountPctWithPartialPosting()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentNo: array[2] of Code[20];
    begin
        // Verify General Ledger Entries Amount with Partially Posted Sales Return Order with 100 % Line Discount Percentage.

        // Setup: Create Sales Return Order.
        Initialize();
        CreateSalesDocumentWithFullLineDiscount(SalesHeader, SalesHeader."Document Type"::"Return Order", SalesLine);

        // Excercise: Post Sales Return Order - Partially. Post Sales Return Order with remaining Quantity to Invoice.
        DocumentNo[1] := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        DocumentNo[2] := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify General Ledger Entry Amount with calculated Amount for filtered Posted Sales Credit Memo Line.
        VerifyGLEntryForPostedCreditMemo(DocumentNo[1], SalesLine);
        VerifyGLEntryForPostedCreditMemo(DocumentNo[2], SalesLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedSalesInvoiceResourceWithTax()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Verify General Ledger Entries, Post Sales Invoice with Type - Resource.
        // Setup.
        Initialize();
        PostedSalesDocumentResourceWithTax(SalesHeader."Document Type"::Invoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedCreditMemoResourceWithTax()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Verify General Ledger Entries, Post Sales Credit Memo with Type - Resource.
        // Setup.
        Initialize();
        PostedSalesDocumentResourceWithTax(SalesHeader."Document Type"::"Credit Memo");
    end;

    local procedure PostedSalesDocumentResourceWithTax(DocumentType: Enum "Sales Document Type")
    var
        Customer: Record Customer;
        TaxGroup: Record "Tax Group";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Resource: Record Resource;
        TaxJurisdiction: Record "Tax Jurisdiction";
        VATEntry: Record "VAT Entry";
        DocumentNo: Code[20];
        OldUnrealizedVAT: Boolean;
    begin
        // Create Tax Group, Tax Area Line, Tax Detail and Sales Document.
        UpdateGeneralLedgerSetup(OldUnrealizedVAT, true);
        LibraryResource.CreateResourceNew(Resource);  // Blank value for VAT Bus Posting Group.
        Resource."VAT Prod. Posting Group" := '';
        Resource.Modify();
        CreateCustomerWithDetailTax(Customer, TaxGroup, LibraryRandom.RandDec(10, 2));  // Random value for Tax Below Maximum.
        Resource.Validate("Tax Group Code", TaxGroup.Code);
        Resource.Modify(true);
        CreateSalesDocumentWithVAT(
          SalesHeader, SalesLine, DocumentType, Customer."No.", SalesLine.Type::Resource, Resource."No.", TaxGroup.Code);
        FindTaxJurisdiction(TaxJurisdiction, Customer."Tax Area Code");

        // Exercise: Post as Ship and Invoice Sales Document.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify General Ledger Entry Amount with VAT Entry Amount.
        FindVATEntry(DocumentNo, VATEntry);
        VerifyGLEntry(DocumentNo, TaxJurisdiction."Tax Account (Sales)", VATEntry.Amount);

        // TearDown.
        UpdateGeneralLedgerSetup(OldUnrealizedVAT, OldUnrealizedVAT);
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesModalPageHandler,CashAppliedRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PaymentAppliedEntriesWithoutVATCashAppliedReport()
    begin
        // Verify program will populates correct amount without tax on report - Cash Applied.
        // Setup.
        Initialize();
        PaymentAppliedEntriesCashAppliedReport(0);  // 0 value for Tax Below Maximum.
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesModalPageHandler,CashAppliedRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PaymentAppliedEntriesWithVATCashAppliedReport()
    begin
        // Verify program will populates correct amount without tax on report - Cash Applied.
        // Setup.
        Initialize();
        PaymentAppliedEntriesCashAppliedReport(LibraryRandom.RandDec(10, 2));  // Random value for Tax Below Maximum.
    end;

    local procedure PaymentAppliedEntriesCashAppliedReport(TaxBelowMaximum: Decimal)
    var
        VATEntry: Record "VAT Entry";
        Customer: Record Customer;
        TaxGroup: Record "Tax Group";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GenJournalLine: Record "Gen. Journal Line";
        AmountToApply: Decimal;
        LineAmount: Decimal;
        DocumentNo: Code[20];
    begin
        // Create Sales Order With VAT, Create and Post General Journal Line. Apply Customer Entries.
        AmountToApply := LibraryRandom.RandDec(10, 2);
        LibraryVariableStorage.Enqueue(AmountToApply);  // Enqueue value for ApplyCustomerEntriesPageHandler.
        CreateCustomerWithDetailTax(Customer, TaxGroup, TaxBelowMaximum);
        CreateSalesDocumentWithVAT(
          SalesHeader, SalesLine, SalesLine."Document Type"::Order, Customer."No.", SalesLine.Type::Item,
          CreateItemWithTaxGroup(TaxGroup.Code), TaxGroup.Code);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        LineAmount := GetSalesInvoiceLineAmount(DocumentNo);
        CreateAndApplyGeneralJournalLine(GenJournalLine, Customer."No.", LineAmount);
        UpdateAndPostGenJournalLine(GenJournalLine, LineAmount);

        // Exercise.
        RunCashAppliedReport(Customer."No.");

        // Verify: Verify Amount To Apply and Total Applied Customer Ledger Entry on Report - Cash Applied.
        FindVATEntry(DocumentNo, VATEntry);
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('TotalApplied', AmountToApply);
        LibraryReportDataset.AssertElementWithValueExists('TotalApplied_CustLedgEntry', LineAmount - AmountToApply);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SpecialOrdersAlwaysCombined()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        // Verify Generated Purchase Order from Requisition Work sheet with Get Sales Order functionality, Option Combine Special Orders Default as Always Combined in Purchases Payables Setup.
        // Setup.
        Initialize();
        SpecialOrdersCombined(PurchasesPayablesSetup."Combine Special Orders Default"::"Always Combine");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SpecialOrdersNeverCombined()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        // Verify Generated Purchase Order from Requisition Work sheet with Get Sales Order functionality, Option Combine Special Orders Default as Never Combined in Purchases Payables Setup.
        // Setup.
        Initialize();
        SpecialOrdersCombined(PurchasesPayablesSetup."Combine Special Orders Default"::"Never Combine");
    end;

    [Test]
    [HandlerFunctions('PartialApplyCustomerEntriesHandler')]
    [Scope('OnPrem')]
    procedure ApplyingPartialPaymentOnCrMemoShouldNotShowIncorrectBalanceOnApplyCustomerEntriesPage()
    var
        Customer: Record Customer;
        CustLedgEntry: Record "Cust. Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustomerLedgerEntriesPage: TestPage "Customer Ledger Entries";
        PaymentTermCode: array[2] of Code[20];
        SalesInvoiceNo: Code[20];
        DiscountPercent: Decimal;
    begin
        // [SCENARIO 561458] Balance must be correct in Apply Customer Entries page while applying Payment to Invoice with Payment Discount and Credit Memos (partially).
        Initialize();

        // [GIVEN] Create two Payment Terms with and without Discount.
        DiscountPercent := LibraryRandom.RandIntInRange(1, 10);
        PaymentTermCode[1] := CreatePaymentTermsWithDiscount(0);
        PaymentTermCode[2] := CreatePaymentTermsWithDiscount(DiscountPercent);

        // [GIVEN] Create a Customer.
        CreateCustomerWithGivenPaymentTerm(Customer, PaymentTermCode[1]);

        // [GIVEN] Post a Payment for the Customer.
        CreatePostBalancedPaymentJournalWithSpecifiedCustomerAndAmount(GenJournalLine, Customer."No.", LibraryRandom.RandInt(100));

        // [WHEN] Create and post a Sales Invoice with Payment Discount (Payment Term Code = PaymentTermCode[2]).
        Customer.Validate("Payment Terms Code", PaymentTermCode[2]);
        Customer.Modify(true);
        SalesInvoiceNo := CreateAndPostSalesDocument(SalesLine, WorkDate(),
            Customer."No.", LibraryInventory.CreateItemNo(), SalesHeader."Document Type"::Invoice,
            LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(1000, 2));

        // [THEN] Verify that the Customer Ledger Entry has "Remaining Pmt. Disc. Possible" > 0.
        Assert.IsTrue(GetRemainingPmtDiscForCustomer(CustLedgEntry."Document Type"::Invoice, Customer."No.", SalesInvoiceNo) > 0,
            RemainingPmtDiscountPossibleDoesNotHaveValueErr);

        // [GIVEN] Create and post three Sales Credit Memo with "Payment Terms Code" = PaymentTermCode[1] and Amount = 2000.
        Customer.Validate("Payment Terms Code", PaymentTermCode[1]);
        Customer.Modify(true);
        CreateAndPostSalesDocument(SalesLine, WorkDate(),
            Customer."No.", LibraryInventory.CreateItemNo(), SalesHeader."Document Type"::"Credit Memo",
            LibraryRandom.RandDec(10, 2), 2000);
        CreateAndPostSalesDocument(SalesLine, WorkDate(),
            Customer."No.", LibraryInventory.CreateItemNo(), SalesHeader."Document Type"::"Credit Memo",
            LibraryRandom.RandDec(10, 2), 2000);
        CreateAndPostSalesDocument(SalesLine, WorkDate(),
            Customer."No.", LibraryInventory.CreateItemNo(), SalesHeader."Document Type"::"Credit Memo",
            LibraryRandom.RandDec(10, 2), 2000);

        // [WHEN] Open Customer Ledger Entries page and execute the Apply Entries action.
        CustomerLedgerEntriesPage.OpenView();
        CustomerLedgerEntriesPage.Filter.SetFilter("Customer No.", Customer."No.");
        CustomerLedgerEntriesPage.Filter.SetFilter("Document Type", Format(CustLedgEntry."Document Type"::Payment));
        CustomerLedgerEntriesPage.First();
        LibraryVariableStorage.Enqueue(CustomerLedgerEntriesPage."Remaining Amount".AsDecimal());
        CustomerLedgerEntriesPage."Apply Entries".Invoke();

        // [THEN] Verify through the "PartialApplyCustomerEntriesHandler" that partially applied amount gets balanced in Apply Customer Entries page.
        CustomerLedgerEntriesPage.Close();
    end;

    local procedure SpecialOrdersCombined(CombineSpecialOrdersDefault: Option)
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesHeader2: Record "Sales Header";
        SalesLine2: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        OldCombineSpecialOrdersDefault: Option;
    begin
        // Update Purchases Payables Setup, Create two Sales Order, Create Requisition Line, Get Sales Orders.
        UpdatePurchasesPayablesSetup(OldCombineSpecialOrdersDefault, CombineSpecialOrdersDefault);
        CreateCustomer(Customer);
        CreateSalesDocumentWithShipToCode(SalesHeader, SalesLine, CreateLocation(''), Customer."No.", CreateItem(), CreatePurchasingCode());
        CreateSalesDocumentWithShipToCode(
          SalesHeader2, SalesLine2, SalesHeader."Location Code", SalesHeader."Sell-to Customer No.",
          SalesLine."No.", SalesLine."Purchasing Code");
        CreateRequisitionLine(RequisitionLine);
        RunGetSalesOrdersReport(RequisitionLine, SalesLine."Document No.");
        RunGetSalesOrdersReport(RequisitionLine, SalesLine2."Document No.");

        // Exercise: Create Purchase Order by Carry Out Action Message Action.
        LibraryPlanning.CarryOutReqWksh(RequisitionLine, WorkDate(), WorkDate(), WorkDate(), WorkDate(), '');  // Blank value for Your Reference.

        // Verify: Verify Purchase Order is created by Carry Out Action.
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        SalesLine2.Get(SalesLine2."Document Type", SalesLine2."Document No.", SalesLine2."Line No.");
        VerifyPurchaseLineCount(
          SalesLine."Special Order Purchase No.", SalesLine2."Special Order Purchase No.", CombineSpecialOrdersDefault);

        // TearDown.
        UpdatePurchasesPayablesSetup(PurchasesPayablesSetup."Combine Special Orders Default", OldCombineSpecialOrdersDefault);
    end;
#if not CLEAN27
    [Test]
    [HandlerFunctions('SalesInvoiceStatsTaxAmountPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsPostedSalesInvoiceWithPositiveAndNegativeAmounts()
    var
        Item: Record Item;
        GLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TaxDetail: Record "Tax Detail";
        PostedSalesInvoiceNo: Code[20];
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
    begin
        // [SCENARIO 325706] Statistics for Posted Sales Invoice with positive and negative Line Amounts shows correct Tax Amount.
        Initialize();

        // [GIVEN] Tax setup with Tax Detail having "Tax Below Maximum" := 1, "Maximum Amount/Qty." = 5000.
        CreateTaxDetailSimple(TaxDetail);
        TaxDetail."Tax Below Maximum" := 1;
        TaxDetail."Maximum Amount/Qty." := 5000;
        TaxDetail.Modify();
        TaxGroupCode := TaxDetail."Tax Group Code";
        TaxAreaCode := CreateTaxAreaWithLine(TaxDetail."Tax Jurisdiction Code");

        // [GIVEN] G/L Account.
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Tax Group Code", TaxGroupCode);
        GLAccount.Modify(true);

        // [GIVEN] Posted Sales Invoice posted with:
        // [GIVEN] Sales Line with Type = "Item", Qty = 1, Amount = 6000;
        // [GIVEN] Sales Line with Type = "G/L Account"", Qty = -1, Amount = 1000.
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, TaxAreaCode);
        LibraryInventory.CreateItemWithoutVAT(Item);
        Item.Validate("Tax Group Code", TaxGroupCode);
        Item.Modify(true);
        CreateSalesLineWithTaxSetup(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1, TaxGroupCode, TaxAreaCode, true, 0, 6000, 6000);
        CreateSalesLineWithTaxSetup(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccount."No.", -1, TaxGroupCode, TaxAreaCode, true, 0, 1000, -1000);
        PostedSalesInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Statistics opened for Posted Sales Invoice.
        // [THEN] On Statistics page: Tax Amount = 50 ((6000 - 1000) / 100 = 50)
        LibraryVariableStorage.Enqueue(50);
        OpenStatisticsPageForPostedSalesInvoice(PostedSalesInvoiceNo);
    end;
#endif
    [Test]
    [HandlerFunctions('SalesInvoiceStatsTaxAmountPageHandlerNM')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsPostedSalesInvoiceWithPositiveAndNegativeAmountsNM()
    var
        Item: Record Item;
        GLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TaxDetail: Record "Tax Detail";
        PostedSalesInvoiceNo: Code[20];
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
    begin
        // [SCENARIO 325706] Statistics for Posted Sales Invoice with positive and negative Line Amounts shows correct Tax Amount.
        Initialize();

        // [GIVEN] Tax setup with Tax Detail having "Tax Below Maximum" := 1, "Maximum Amount/Qty." = 5000.
        CreateTaxDetailSimple(TaxDetail);
        TaxDetail."Tax Below Maximum" := 1;
        TaxDetail."Maximum Amount/Qty." := 5000;
        TaxDetail.Modify();
        TaxGroupCode := TaxDetail."Tax Group Code";
        TaxAreaCode := CreateTaxAreaWithLine(TaxDetail."Tax Jurisdiction Code");

        // [GIVEN] G/L Account.
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Tax Group Code", TaxGroupCode);
        GLAccount.Modify(true);

        // [GIVEN] Posted Sales Invoice posted with:
        // [GIVEN] Sales Line with Type = "Item", Qty = 1, Amount = 6000;
        // [GIVEN] Sales Line with Type = "G/L Account"", Qty = -1, Amount = 1000.
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, TaxAreaCode);
        LibraryInventory.CreateItemWithoutVAT(Item);
        Item.Validate("Tax Group Code", TaxGroupCode);
        Item.Modify(true);
        CreateSalesLineWithTaxSetup(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1, TaxGroupCode, TaxAreaCode, true, 0, 6000, 6000);
        CreateSalesLineWithTaxSetup(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccount."No.", -1, TaxGroupCode, TaxAreaCode, true, 0, 1000, -1000);
        PostedSalesInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Statistics opened for Posted Sales Invoice.
        // [THEN] On Statistics page: Tax Amount = 50 ((6000 - 1000) / 100 = 50)
        LibraryVariableStorage.Enqueue(50);
        OpenStatsPageForPostedSalesInvoiceNM(PostedSalesInvoiceNo);
    end;

    local procedure Initialize()
    var
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        LibraryVariableStorage.Clear();
        LibraryApplicationArea.EnableFoundationSetup();
    end;

    local procedure CreateCustomer(var Customer: Record Customer)
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", '');  // Blank value is required for VAT Business Posting Group.
        Customer.Modify(true);
    end;

    local procedure CreateCustomerWithDetailTax(var Customer: Record Customer; var TaxGroup: Record "Tax Group"; TaxBelowMaximum: Decimal)
    var
        TaxAreaLine: Record "Tax Area Line";
        TaxDetail: Record "Tax Detail";
    begin
        CreateCustomer(Customer);
        LibraryERM.CreateTaxGroup(TaxGroup);
        CreateTaxAreaLine(TaxAreaLine);
        CreateTaxDetail(TaxDetail, TaxAreaLine."Tax Jurisdiction Code", TaxGroup.Code, TaxBelowMaximum);  // Random value for Tax Below Maximum.
        UpdateCustomer(Customer, TaxAreaLine."Tax Area");
    end;

    local procedure UpdateCustomer(var Customer: Record Customer; TaxAreaCode: Code[20])
    begin
        Customer.Validate("Tax Liable", true);
        Customer.Validate("Tax Area Code", TaxAreaCode);
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

    local procedure CreateItemWithTaxGroup(TaxGroupCode: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", '');  // Blank value required for creating Sales Line.
        Item.Validate("Tax Group Code", TaxGroupCode);
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

    local procedure CreateSalesDocumentWithShipToCode(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; LocationCode: Code[10]; CustomerNo: Code[20]; No: Code[20]; PurchasingCode: Code[10])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        SalesHeader.Validate("Location Code", LocationCode);
        SalesHeader.Validate("Ship-to Code", CreateShipToAddress(CustomerNo));
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, No, LibraryRandom.RandDec(10, 2));  // Random value for Quantity.
        SalesLine.Validate("Purchasing Code", PurchasingCode);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesDocumentWithVAT(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]; Type: Enum "Sales Line Type"; No: Code[20]; TaxGroupCode: Code[20])
    begin
        CreateSalesDocument(SalesHeader, SalesLine, DocumentType, CustomerNo, Type, No, LibraryRandom.RandDecInRange(1, 10, 2));  // Random value for Quantity.
        SalesLine.Validate("VAT Prod. Posting Group", '');
        SalesLine.Validate("Tax Group Code", TaxGroupCode);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(10, 100, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; TaxAreaCode: Code[20])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, LibrarySales.CreateCustomerNo());
        SalesHeader."VAT Bus. Posting Group" := '';
        SalesHeader."Tax Area Code" := TaxAreaCode;
        SalesHeader."Tax Liable" := true;
        SalesHeader.Modify();
    end;

    local procedure CreateSalesLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; Type: Enum "Sales Line Type"; No: Code[20]; Quantity: Decimal)
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Type, No, Quantity);
        SalesLine.Validate("Tax Group Code", '');
        SalesLine.Validate("Unit Price", LibraryRandom.RandInt(10));
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesLineWithTaxSetup(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; LineType: Enum "Sales Line Type"; No: Code[20]; Qty: Decimal; TaxGroupCode: Code[20]; TaxAreaCode: Code[20]; TaxLiable: Boolean; VATPct: Decimal; UnitPrice: Decimal; LineAmount: Decimal)
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, LineType, No, Qty);
        SalesLine."Tax Group Code" := TaxGroupCode;
        SalesLine."Tax Area Code" := TaxAreaCode;
        SalesLine."Tax Liable" := TaxLiable;
        SalesLine."VAT %" := VATPct;
        SalesLine."Unit Price" := UnitPrice;
        SalesLine."Line Amount" := LineAmount;
        SalesLine.Amount := LineAmount;
        SalesLine.Modify();
    end;

    local procedure CreateTaxDetail(var TaxDetail: Record "Tax Detail"; TaxJurisdictionCode: Code[10]; TaxGroupCode: Code[20]; TaxBelowMaximum: Decimal)
    begin
        LibraryERM.CreateTaxDetail(TaxDetail, TaxJurisdictionCode, TaxGroupCode, TaxDetail."Tax Type"::"Sales and Use Tax", WorkDate());
        TaxDetail.Validate("Tax Below Maximum", TaxBelowMaximum);
        TaxDetail.Modify(true);
    end;

    local procedure CreateTaxDetailSimple(var TaxDetail: Record "Tax Detail")
    begin
        TaxDetail."Tax Jurisdiction Code" := CreateTaxJurisdiction();
        TaxDetail."Tax Group Code" := CreateTaxGroup();
        TaxDetail."Tax Below Maximum" := LibraryRandom.RandDec(10, 2);
        TaxDetail.Insert();
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

    local procedure CreateTaxAreaWithLine(TaxJurisdictionCode: Code[10]): Code[10]
    var
        TaxArea: Record "Tax Area";
        TaxAreaLine: Record "Tax Area Line";
    begin
        LibraryERM.CreateTaxArea(TaxArea);
        TaxAreaLine.Init();
        TaxAreaLine."Tax Area" := TaxArea.Code;
        TaxAreaLine."Tax Jurisdiction Code" := TaxJurisdictionCode;
        TaxAreaLine.Insert();
        exit(TaxArea.Code);
    end;

    local procedure CreateTaxGroup(): Code[10]
    var
        TaxGroup: Record "Tax Group";
    begin
        TaxGroup.Code := LibraryUTUtility.GetNewCode10();
        TaxGroup.Insert();
        exit(TaxGroup.Code);
    end;

    local procedure CreateTaxJurisdiction(): Code[10]
    var
        TaxJurisdiction: Record "Tax Jurisdiction";
    begin
        TaxJurisdiction.Code := LibraryUTUtility.GetNewCode10();
        TaxJurisdiction."Tax Account (Sales)" := LibraryERM.CreateGLAccountNo();
        TaxJurisdiction.Insert();
        exit(TaxJurisdiction.Code);
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        exit(GLAccount."No.");
    end;

    local procedure CreatePurchasingCode(): Code[10]
    var
        Purchasing: Record Purchasing;
    begin
        LibraryPurchase.CreatePurchasingCode(Purchasing);
        Purchasing.Validate("Special Order", true);
        Purchasing.Modify(true);
        exit(Purchasing.Code);
    end;

    local procedure CreateRequisitionLine(var RequisitionLine: Record "Requisition Line")
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
    begin
        ReqWkshTemplate.SetRange(Type, ReqWkshTemplate.Type::"Req.");
        ReqWkshTemplate.SetRange(Recurring, false);
        ReqWkshTemplate.FindFirst();
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, ReqWkshTemplate.Name);
        LibraryPlanning.CreateRequisitionLine(RequisitionLine, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name);
    end;

    local procedure CreateShipToAddress(CustomerNo: Code[20]): Code[20]
    var
        ShipToAddress: Record "Ship-to Address";
    begin
        LibrarySales.CreateShipToAddress(ShipToAddress, CustomerNo);
        ShipToAddress.Validate(Address, LibraryUtility.GenerateRandomCode(ShipToAddress.FieldNo(Address), DATABASE::"Ship-to Address"));
        ShipToAddress.Modify(true);
        exit(ShipToAddress.Code);
    end;

    local procedure CreateAndApplyGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AccountNo: Code[20]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GeneralJournal: TestPage "General Journal";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Customer, AccountNo, -Amount);
        GeneralJournal.OpenEdit();
        GeneralJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);
        GeneralJournal."Apply Entries".Invoke();  // Opens handler - ApplyCustomerEntriesModalPageHandler.
        GeneralJournal.Close();
    end;

    local procedure FilterOnPurchaseLine(var PurchaseLine: Record "Purchase Line"; DocumentNo: Code[20])
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
    end;

    local procedure FindTaxJurisdiction(var TaxJurisdiction: Record "Tax Jurisdiction"; TaxArea: Code[20])
    var
        TaxAreaLine: Record "Tax Area Line";
    begin
        TaxAreaLine.SetRange("Tax Area", TaxArea);
        TaxAreaLine.FindFirst();
        TaxJurisdiction.Get(TaxAreaLine."Tax Jurisdiction Code");
    end;

    local procedure FindVATEntry(DocumentNo: Code[20]; var VATEntry: Record "VAT Entry")
    begin
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.FindFirst();
    end;

    local procedure GetSalesInvoiceLineAmount(DocumentNo: Code[20]): Decimal
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SalesInvoiceLine.SetRange("Document No.", DocumentNo);
        SalesInvoiceLine.FindFirst();
        exit(SalesInvoiceLine."Line Amount");
    end;
#if not CLEAN27
    local procedure OpenStatisticsPageForPostedSalesInvoice(No: Code[20])
    var
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
    begin
        PostedSalesInvoice.OpenEdit();
        PostedSalesInvoice.FILTER.SetFilter("No.", No);
        PostedSalesInvoice.Statistics.Invoke();
        PostedSalesInvoice.Close();
    end;
#endif
    local procedure OpenStatsPageForPostedSalesInvoiceNM(No: Code[20])
    var
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
    begin
        PostedSalesInvoice.OpenEdit();
        PostedSalesInvoice.FILTER.SetFilter("No.", No);
        PostedSalesInvoice.SalesInvoiceStats.Invoke();
        PostedSalesInvoice.Close();
    end;

    local procedure UpdateGeneralLedgerSetup(var OldUnrealizedVAT: Boolean; NewUnrealizedVAT: Boolean)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        OldUnrealizedVAT := GeneralLedgerSetup."Unrealized VAT";
        GeneralLedgerSetup.Validate("Unrealized VAT", NewUnrealizedVAT);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure RunGetSalesOrdersReport(var RequisitionLine: Record "Requisition Line"; DocumentNo: Code[20])
    var
        SalesLine: Record "Sales Line";
        GetSalesOrders: Report "Get Sales Orders";
        RetrieveDimensionsFrom: Option Item,"Sales Line";
    begin
        Clear(GetSalesOrders);
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", DocumentNo);
        GetSalesOrders.SetTableView(SalesLine);
        GetSalesOrders.InitializeRequest(RetrieveDimensionsFrom::"Sales Line");
        GetSalesOrders.SetReqWkshLine(RequisitionLine, 1);  // Value 1 for Special Order.
        GetSalesOrders.UseRequestPage(false);
        GetSalesOrders.Run();
    end;

    local procedure RunCashAppliedReport(CustomerNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CashApplied: Report "Cash Applied";
    begin
        Clear(CashApplied);
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CashApplied.SetTableView(CustLedgerEntry);
        CashApplied.Run();
    end;

    local procedure UpdateAndPostGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; Amount: Decimal)
    begin
        GenJournalLine.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", GenJournalLine."Line No.");
        GenJournalLine.Amount := -Amount;
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure UpdatePurchasesPayablesSetup(var OldCombineSpecialOrdersDefault: Option; CombineSpecialOrdersDefault: Option)
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        OldCombineSpecialOrdersDefault := PurchasesPayablesSetup."Combine Special Orders Default";
        PurchasesPayablesSetup.Validate("Combine Special Orders Default", CombineSpecialOrdersDefault);
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure UpdateSalesLineInvoiceToQtyAndLineDiscountPct(SalesLine: Record "Sales Line")
    begin
        SalesLine.Validate("Line Discount %", 100);  // Line discount percentage as 100 required - full line discount.
        SalesLine.Validate("Qty. to Invoice", SalesLine.Quantity / 2);  // Partial Quantity to Invoice.
        SalesLine.Modify(true);
    end;

    local procedure SelectPostedSalesCreditMemoLine(var SalesCrMemoLine: Record "Sales Cr.Memo Line"; DocumentNo: Code[20]; No: Code[20])
    begin
        SalesCrMemoLine.SetRange("Document No.", DocumentNo);
        SalesCrMemoLine.SetRange(Type, SalesCrMemoLine.Type::Item);
        SalesCrMemoLine.SetRange("No.", No);
        SalesCrMemoLine.FindFirst();
    end;

    local procedure VerifyPurchaseLineCount(SpecialOrderPurchaseNo: Code[20]; SpecialOrderPurchaseNo2: Code[20]; CombineSpecialOrdersDefault: Option)
    var
        PurchaseLine: Record "Purchase Line";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        // Using 2 for creating 2 Purchase Lines and 1 for single purchase Line created from Sales Order.
        PurchasesPayablesSetup.Get();
        FilterOnPurchaseLine(PurchaseLine, SpecialOrderPurchaseNo);
        if CombineSpecialOrdersDefault = PurchasesPayablesSetup."Combine Special Orders Default"::"Always Combine" then
            Assert.AreEqual(2, PurchaseLine.Count, ValueMustEqual)
        else begin
            Assert.AreEqual(1, PurchaseLine.Count, ValueMustEqual);
            FilterOnPurchaseLine(PurchaseLine, SpecialOrderPurchaseNo2);
            Assert.AreEqual(1, PurchaseLine.Count, ValueMustEqual);
        end;
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

    local procedure VerifyGLEntryForPostedCreditMemo(DocumentNo: Code[20]; SalesLine: Record "Sales Line")
    var
        GeneralPostingSetup: Record "General Posting Setup";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        GeneralPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        SelectPostedSalesCreditMemoLine(SalesCrMemoLine, DocumentNo, SalesLine."No.");
        VerifyGLEntry(DocumentNo, GeneralPostingSetup."Sales Account", SalesCrMemoLine.Quantity * SalesCrMemoLine."Unit Price");
        VerifyGLEntry(
          DocumentNo, GeneralPostingSetup."Sales Line Disc. Account", -SalesCrMemoLine.Quantity * SalesCrMemoLine."Unit Price");
    end;

    local procedure CreatePostBalancedPaymentJournalWithSpecifiedCustomerAndAmount(var GenJournalLine: Record "Gen. Journal Line"; CustomerNo: Code[20]; PaymentAmount: Decimal)
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
            GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer, CustomerNo,
            GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), -PaymentAmount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    Local procedure GetRemainingPmtDiscForCustomer(DocumentType: enum "Gen. Journal Document Type"; CustomerNo: Code[20]; DocumentNo: Code[20]): Decimal
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgEntry.SetRange("Customer No.", CustomerNo);
        CustLedgEntry.SetRange("Document Type", DocumentType);
        CustLedgEntry.SetRange("Document No.", DocumentNo);
        CustLedgEntry.FindFirst();
        exit(CustLedgEntry."Remaining Pmt. Disc. Possible");
    end;

    local procedure CreatePaymentTermsWithDiscount(DiscountPercent: Decimal): Code[10]
    var
        PaymentTerms: Record "Payment Terms";
    begin
        LibraryERM.CreatePaymentTermsDiscount(PaymentTerms, true);
        PaymentTerms.Validate("Discount %", DiscountPercent);
        PaymentTerms.Modify(true);
        exit(PaymentTerms.Code);
    end;

    local procedure CreateAndPostSalesDocument(var SalesLine: Record "Sales Line"; PostingDate: Date; CustomerNo: Code[20]; ItemNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; Quantity: Decimal; UnitPrice: Decimal): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateCustomerWithGivenPaymentTerm(var Customer: Record Customer; PaymentTermsCode: Code[10])
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Payment Terms Code", PaymentTermsCode);
        Customer.Modify(true);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyCustomerEntriesModalPageHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    var
        AmountToApply: Variant;
    begin
        LibraryVariableStorage.Dequeue(AmountToApply);
        ApplyCustomerEntries."Set Applies-to ID".Invoke();
        ApplyCustomerEntries."Amount to Apply".SetValue(AmountToApply);
        ApplyCustomerEntries.OK().Invoke();
    end;
#if not CLEAN27
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesInvoiceStatsTaxAmountPageHandler(var SalesInvoiceStats: TestPage "Sales Invoice Stats.")
    var
        TaxAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(TaxAmount);
        SalesInvoiceStats.TaxAmount.AssertEquals(TaxAmount);
        SalesInvoiceStats.OK().Invoke();
    end;
#endif
    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesInvoiceStatsTaxAmountPageHandlerNM(var SalesInvoiceStats: TestPage "Sales Invoice Stats.")
    var
        TaxAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(TaxAmount);
        SalesInvoiceStats.TaxAmount.AssertEquals(TaxAmount);
        SalesInvoiceStats.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CashAppliedRequestPageHandler(var CashApplied: TestRequestPage "Cash Applied")
    begin
        CashApplied.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PartialApplyCustomerEntriesHandler(var PartialApplyCustomerEntries: TestPage "Apply Customer Entries")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        BalanceAmount: Decimal;
        PaymentDiscountAmt: Decimal;
    begin
        PartialApplyCustomerEntries.Filter.SetFilter("Document Type", Format(CustLedgerEntry."Document Type"::Invoice));
        PartialApplyCustomerEntries.First();
        PartialApplyCustomerEntries."Set Applies-to ID".Invoke();

        BalanceAmount := PartialApplyCustomerEntries.ControlBalance.AsDecimal();
        Assert.IsTrue(BalanceAmount > 0, StrSubstNo(IncorrectBalanceErr, PartialApplyCustomerEntries.Caption()));  // because payment is less than the invoice balance will be positive

        PartialApplyCustomerEntries.Filter.SetFilter("Document Type", Format(CustLedgerEntry."Document Type"::"Credit Memo"));
        PartialApplyCustomerEntries.First();
        PartialApplyCustomerEntries."Amount to Apply".SetValue(-Round(BalanceAmount / 2, 0.01, '='));  //apply half of balance to the first credit memo

        BalanceAmount := PartialApplyCustomerEntries.ControlBalance.AsDecimal();
        PartialApplyCustomerEntries.Next();
        PartialApplyCustomerEntries."Amount to Apply".SetValue(-BalanceAmount);  // apply remaining balance

        BalanceAmount := PartialApplyCustomerEntries.ControlBalance.AsDecimal();
        PaymentDiscountAmt := PartialApplyCustomerEntries.PmtDiscountAmount.AsDecimal();

        Assert.IsTrue(PaymentDiscountAmt <> 0, RemainingPmtDiscountPossibleDoesNotHaveValueErr);  //Pmt. Discount amount should have a value.
        Assert.AreEqual(0, BalanceAmount, StrSubstNo(IncorrectBalanceErr, PartialApplyCustomerEntries.Caption()));  // and Balance should be zero
    end;
}
