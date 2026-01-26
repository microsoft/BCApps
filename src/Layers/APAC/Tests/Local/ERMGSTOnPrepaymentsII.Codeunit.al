codeunit 141027 "ERM GST On Prepayments II"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [GST] [Prepayment]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        NoSeriesBatch: Codeunit "No. Series - Batch";
        LibraryRandom: Codeunit "Library - Random";
        AmountMustMatchMsg: Label 'Amount must match.';

    [Test]
    [Scope('OnPrem')]
    procedure GSTSalesEntryAfterPostSalesOrderWithPrepayment()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GSTSalesEntry: Record "GST Sales Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        // [SCENARIO] GST Sales Entries after posting Sales Order with Prices Including VAT as False with Prepayment.

        // [GIVEN] Create Sales Order, post Sales Prepayment Invoice.
        Initialize();
        GeneralLedgerSetup.Get();
        UpdateLocalFunctionalitiesOnGeneralLedgerSetup(true, true, true);  // TRUE for Enable GST, GST Reports and Full GST On Prepayment.
        CreateSalesOrderAndUpdateGeneralPostingSetup(SalesLine, '', LibraryRandom.RandDec(10, 2), false);  // Taking blank value for Currency Code, random for Prepayment Pct, FALSE for Price Including VAT.
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // Exercise.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Verify Amount on GST Sales Entry.
        FindAndVerifyGSTSalesEntry(
          DocumentNo, SalesLine."No.", GSTSalesEntry."Document Line Type"::Item,
          -SalesLine."Line Amount" * SalesLine."VAT %" / 100, -SalesLine."Line Amount");

        // Tear Down.
        UpdateLocalFunctionalitiesOnGeneralLedgerSetup(
          GeneralLedgerSetup."Enable GST (Australia)", GeneralLedgerSetup."GST Report", GeneralLedgerSetup."Full GST on Prepayment");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderStatisticsFullGSTPrepaymentTRUE()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATAmountLine: Record "VAT Amount Line";
        QtyType: Option General,Invoicing,Shipping;
    begin
        // [SCENARIO] VAT Amount Lines after creating Purchase Order with Prices Including VAT as True, Full GST on Prepayment on G/L Setup TRUE.

        // [GIVEN] Create Purchase Order with multiple Lines.
        Initialize();
        CreatePurchaseOrderAndUpdateGeneralPostingSetup(PurchaseLine, '', 100, true);  // Taking blank value for Currency Code, 100 for Prepayment Pct. as required for Test case, TRUE for Prices Including VAT.
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, LibraryInventory.CreateItem(Item), LibraryRandom.RandDec(10, 2));  // Taking random for Quantity.
        PurchaseHeader.CalcFields("Amount Including VAT");

        // Exercise.
        PurchaseLine.CalcVATAmountLines(QtyType::Invoicing, PurchaseHeader, PurchaseLine, VATAmountLine);

        // [THEN] Verify VAT Amount on VAT Amount Line.
        Assert.AreNearlyEqual(
          PurchaseHeader."Amount Including VAT" * PurchaseLine."VAT %" / (100 + PurchaseLine."VAT %"), VATAmountLine."VAT Amount",
          LibraryERM.GetAmountRoundingPrecision(), AmountMustMatchMsg);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GSTPurchEntryAfterPostPurchOrderWithPricesInclVATTRUE()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GSTPurchaseEntry: Record "GST Purchase Entry";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        DocumentNo: Code[20];
    begin
        // [SCENARIO] GST Purchase Entry after posting Purchase Order with Prices Including VAT as True, Full GST on Prepayment on G/L Setup TRUE.

        // [GIVEN] Create Purchase Order with multiple Lines and post Prepayment Invoice.
        Initialize();
        GeneralLedgerSetup.Get();
        UpdateLocalFunctionalitiesOnGeneralLedgerSetup(true, true, true);  // TRUE for Enable GST, GST Reports and Full GST On Prepayment.
        CreatePurchaseOrderAndUpdateGeneralPostingSetup(PurchaseLine, '', 100, true);  // Taking blank value for Currency Code, 100 for Prepayment Pct. as required for Test case, TRUE for Prices Including VAT.
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        CreatePurchaseLine(PurchaseLine2, PurchaseHeader, LibraryInventory.CreateItem(Item), LibraryRandom.RandDec(10, 2));  // Taking random for Quantity.
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);
        UpdateVendorInvoiceNoOnPurchaseHeader(PurchaseHeader);

        // Exercise.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Verify Amount on GST Purchase Entries.
        FindAndVerifyGSTPurchaseEntry(
          DocumentNo, PurchaseLine."No.", GSTPurchaseEntry."Document Line Type"::Item,
          PurchaseLine."Amount Including VAT" * PurchaseLine."VAT %" / (100 + PurchaseLine."VAT %"), PurchaseLine.Amount);
        FindAndVerifyGSTPurchaseEntry(
          DocumentNo, PurchaseLine2."No.", GSTPurchaseEntry."Document Line Type"::Item,
          PurchaseLine2."Amount Including VAT" * PurchaseLine2."VAT %" / (100 + PurchaseLine2."VAT %"), PurchaseLine2.Amount);

        // Tear Down.
        UpdateLocalFunctionalitiesOnGeneralLedgerSetup(
          GeneralLedgerSetup."Enable GST (Australia)", GeneralLedgerSetup."GST Report", GeneralLedgerSetup."Full GST on Prepayment");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GSTPurchEntryAfterPostPurchOrderWithPricesInclVATFALSE()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GSTPurchaseEntry: Record "GST Purchase Entry";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
    begin
        // [SCENARIO] GST Purchase Entry after posting Purchase Order with Prices Including VAT as FALSE, Full GST on Prepayment on G/L Setup TRUE.

        // [GIVEN] Create Purchase Order and post Prepayment Invoice.
        Initialize();
        GeneralLedgerSetup.Get();
        UpdateLocalFunctionalitiesOnGeneralLedgerSetup(true, true, true);  // TRUE for Enable GST, GST Reports and Full GST On Prepayment.
        CreatePurchaseOrderAndUpdateGeneralPostingSetup(PurchaseLine, '', LibraryRandom.RandDec(10, 2), false);  // Taking blank value for Currency Code, random for Prepayment Pct., FALSE for Prices Including VAT.
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);
        UpdateVendorInvoiceNoOnPurchaseHeader(PurchaseHeader);

        // Exercise.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Verify Amount and GST Base on GST Purchase Entries.
        FindAndVerifyGSTPurchaseEntry(
          DocumentNo, PurchaseLine."No.", GSTPurchaseEntry."Document Line Type"::Item,
          PurchaseLine.Amount * PurchaseLine."VAT %" / 100, PurchaseLine.Amount);

        // Tear Down.
        UpdateLocalFunctionalitiesOnGeneralLedgerSetup(
          GeneralLedgerSetup."Enable GST (Australia)", GeneralLedgerSetup."GST Report", GeneralLedgerSetup."Full GST on Prepayment");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GSTSalesEntryAfterPostSalesOrderWithPricesInclVATFALSE()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GSTSalesEntry: Record "GST Sales Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        // [SCENARIO] GST Sales Entries after posting Sales Order with Prices Including VAT as False without Prepayment.

        // [GIVEN] Create Sales Order.
        Initialize();
        GeneralLedgerSetup.Get();
        UpdateLocalFunctionalitiesOnGeneralLedgerSetup(true, true, true);  // TRUE for Enable GST, GST Reports and Full GST On Prepayment.
        CreateSalesOrderAndUpdateGeneralPostingSetup(SalesLine, '', 0, false);  // Taking blank value for Currency Code, 0 for Prepayment Pct, FALSE for Price Including VAT.
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");

        // Exercise.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Verify Amount and GST Base on GST Sales Entries.
        FindAndVerifyGSTSalesEntry(
          DocumentNo, SalesLine."No.", GSTSalesEntry."Document Line Type"::Item,
          -SalesLine."Line Amount" * SalesLine."VAT %" / 100, -SalesLine."Line Amount");

        // Tear Down.
        UpdateLocalFunctionalitiesOnGeneralLedgerSetup(
          GeneralLedgerSetup."Enable GST (Australia)", GeneralLedgerSetup."GST Report", GeneralLedgerSetup."Full GST on Prepayment");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedSalesInvStatisticsFullGSTPrepaymentTRUE()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        VATAmountLine: Record "VAT Amount Line";
        DocumentNo: Code[20];
    begin
        // [SCENARIO] VAT Amount Line after posting Sales Order with Prices including VAT TRUE and full Prepayment.

        // [GIVEN] Create Sales order, post Prepayment Invoice.
        Initialize();
        CreateSalesOrderAndUpdateGeneralPostingSetup(SalesLine, '', 100, true);  // Taking blank value for Currency Code, 100 for Prepayment Pct, TRUE for Price Including VAT.
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, SalesLine."No.", LibraryRandom.RandDec(10, 2));  // Taking random for Quantity.
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
        SalesHeader.CalcFields(Amount);

        // Exercise.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Verify VAT Base and VAT Amount on VAT Amount Line.
        SalesInvoiceHeader.Get(DocumentNo);
        SalesInvoiceLine.CalcVATAmountLines(SalesInvoiceHeader, VATAmountLine);
        Assert.AreNearlyEqual(
          -SalesHeader.Amount * SalesLine."VAT %" / 100, VATAmountLine."VAT Amount", LibraryERM.GetAmountRoundingPrecision(),
          AmountMustMatchMsg);
        Assert.AreNearlyEqual(-SalesHeader.Amount, VATAmountLine."VAT Base", LibraryERM.GetAmountRoundingPrecision(), AmountMustMatchMsg);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesPrePmtInvWithDiffVATProdPostingGroup()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        NoSeries: Codeunit "No. Series";
        DocumentNo: Code[20];
        OldUnrealizedVAT: Boolean;
    begin
        // [SCENARIO] G/L Entry after posting Sales Prepayment Invoice with two Items having different VAT Product Posting Group.

        // [GIVEN] Create Sales Order with multiple Lines.
        Initialize();
        OldUnrealizedVAT := UpdateUnrealizedVATGeneralLedgerSetup(true);  // TRUE for Unrealized VAT.
        CreateSalesOrderAndUpdateGeneralPostingSetup(SalesLine, '', 100, true);  // Taking blank value for Currency Code, 100 for Prepayment Pct, TRUE for Price Including VAT.
        CreateVATPostingSetup(VATPostingSetup, SalesLine."VAT Bus. Posting Group");
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, CreateItemWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"),
          LibraryRandom.RandDec(10, 2));  // Taking random for Quantity.
        SalesHeader.CalcFields("Amount Including VAT");
        DocumentNo := NoSeries.PeekNextNo(SalesHeader."Posting No. Series");

        // Exercise.
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [THEN] Verify Amount on G/L entry.
        VerifyAmountOnGLEntry(DocumentNo, GetReceivableAccount(SalesHeader."Sell-to Customer No."), SalesHeader."Amount Including VAT");

        // Tear Down:
        VATPostingSetup.Delete(true);
        UpdateUnrealizedVATGeneralLedgerSetup(OldUnrealizedVAT);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GSTSalesEntryAfterPostSalesOrderWithNegativeLine()
    var
        Customer: Record Customer;
        GeneralLedgerSetup: Record "General Ledger Setup";
        GSTSalesEntry: Record "GST Sales Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        // [SCENARIO] GST Sales Entry after posting Sales Invoice with negative Lines, when GST on full payment is applicable.

        // [GIVEN] Create Sales Invoice with multiple lines.
        Initialize();
        GeneralLedgerSetup.Get();
        UpdateLocalFunctionalitiesOnGeneralLedgerSetup(true, true, true);  // TRUE for Enable GST, GST Reports and Full GST ON Prepayment.
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", CreateGLAccount(), LibraryRandom.RandDecInRange(10, 50, 2));  // Taking random for Quantity.
        CreateSalesLine(SalesLine2, SalesHeader, SalesLine.Type::"G/L Account", SalesLine."No.", -LibraryRandom.RandDec(5, 2));  // Taking random for Quantity.

        // Exercise.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Verify Amount, GST Base on GST Sales Entry.
        GSTSalesEntry.SetRange("Document Line No.", SalesLine."Line No.");
        FindGSTSalesEntry(GSTSalesEntry, DocumentNo, SalesLine."No.", GSTSalesEntry."Document Line Type"::"G/L Account");
        Assert.AreNearlyEqual(
          -SalesLine."Line Amount" * SalesLine."VAT %" / 100, GSTSalesEntry.Amount, LibraryERM.GetAmountRoundingPrecision(),
          AmountMustMatchMsg);
        FindAndVerifyGSTSalesEntry(
          DocumentNo, SalesLine2."No.", GSTSalesEntry."Document Line Type"::"G/L Account",
          -SalesLine2."Line Amount" * SalesLine2."VAT %" / 100, -SalesLine2."Line Amount");

        // Tear Down.
        UpdateLocalFunctionalitiesOnGeneralLedgerSetup(
          GeneralLedgerSetup."Enable GST (Australia)", GeneralLedgerSetup."GST Report", GeneralLedgerSetup."Full GST on Prepayment");
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseOrderStatisticsModalPageHandler,VATAmountLinesModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostPurchaseOrderAfterUpdatingVATAmtonVATAmtLine()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        Vendor: Record Vendor;
        DocumentNo: Code[20];
        OldAllowVATDifference: Boolean;
        VATAmount: Decimal;
    begin
        // [SCENARIO] G/L Entries after posting Purchase Order with Negative Lines and Update VAT Amount on VAT Amount Lines.

        // [GIVEN] Update Purchases & Payable Setup, create Vendor.
        Initialize();
        OldAllowVATDifference := UpdateAllowVATDifferencePurchasesPayablesSetup(true);  // TRUE for Allow VAT Difference.
        UpdateMaxVATDifferenceAllowedGeneralLedgerSetup();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryPurchase.CreateVendor(Vendor);

        // Create Purchase Order with multiple lines and update Quantity to Receive.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, LibraryInventory.CreateItem(Item), LibraryRandom.RandDec(10, 2));  // Taking random for Quantity.
        CreatePurchaseLine(PurchaseLine2, PurchaseHeader, PurchaseLine."No.", -LibraryRandom.RandDec(10, 2));  // Taking random for Quantity.
        PurchaseLine2.Validate("Qty. to Receive", 0);
        PurchaseLine2.Modify(true);
        VATAmount := (PurchaseLine.Amount * PurchaseLine."VAT %" / 100) + LibraryRandom.RandDec(1, 2);  // Added random value to VAT Amount.
        LibraryVariableStorage.Enqueue(VATAmount);  // Enqueue for VATAmountLinesPageHandler.
        OpenPurchaseOrderStatisticsPage(PurchaseHeader."No.");

        // Exercise.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Verify VAT Amount on G/L Entry.
        VerifyAmountOnGLEntry(DocumentNo, VATPostingSetup."Purchase VAT Account", VATAmount);

        // Tear Down.
        UpdateAllowVATDifferencePurchasesPayablesSetup(OldAllowVATDifference);
    end;
#endif

    [Test]
    [HandlerFunctions('PurchaseOrderStatisticsPageHandler,VATAmountLinesModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostPurchaseOrderAfterUpdatingVATAmtonVATAmountLine()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        Vendor: Record Vendor;
        DocumentNo: Code[20];
        OldAllowVATDifference: Boolean;
        VATAmount: Decimal;
    begin
        // [SCENARIO] G/L Entries after posting Purchase Order with Negative Lines and Update VAT Amount on VAT Amount Lines.

        // [GIVEN] Update Purchases & Payable Setup, create Vendor.
        Initialize();
        OldAllowVATDifference := UpdateAllowVATDifferencePurchasesPayablesSetup(true);  // TRUE for Allow VAT Difference.
        UpdateMaxVATDifferenceAllowedGeneralLedgerSetup();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryPurchase.CreateVendor(Vendor);

        // Create Purchase Order with multiple lines and update Quantity to Receive.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, LibraryInventory.CreateItem(Item), LibraryRandom.RandDec(10, 2));  // Taking random for Quantity.
        CreatePurchaseLine(PurchaseLine2, PurchaseHeader, PurchaseLine."No.", -LibraryRandom.RandDec(10, 2));  // Taking random for Quantity.
        PurchaseLine2.Validate("Qty. to Receive", 0);
        PurchaseLine2.Modify(true);
        VATAmount := (PurchaseLine.Amount * PurchaseLine."VAT %" / 100) + LibraryRandom.RandDec(1, 2);  // Added random value to VAT Amount.
        LibraryVariableStorage.Enqueue(VATAmount);  // Enqueue for VATAmountLinesPageHandler.
        OpenPurchaseOrderStatsPage(PurchaseHeader."No.");

        // Exercise.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Verify VAT Amount on G/L Entry.
        VerifyAmountOnGLEntry(DocumentNo, VATPostingSetup."Purchase VAT Account", VATAmount);

        // Tear Down.
        UpdateAllowVATDifferencePurchasesPayablesSetup(OldAllowVATDifference);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesOrderStatisticsModalPageHandler,VATAmountLinesModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostSalesOrderAfterUpdatingVATAmtonVATAmtLine()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
        OldAllowVATDifference: Boolean;
        VATAmount: Decimal;
    begin
        // [SCENARIO] G/L Entries after posting Sales Order with Negative Lines and Update VAT Amount on VAT Amount Lines.

        // [GIVEN] Update Sales & Receivable Setup, create Item, create Customer.
        Initialize();
        OldAllowVATDifference := UpdateAllowVATDifferenceSalesReceivableSetup(true);  // TRUE for Allow VAT Difference.
        UpdateMaxVATDifferenceAllowedGeneralLedgerSetup();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibrarySales.CreateCustomer(Customer);

        // Create Sales Order with multiple lines and update Quantity to Receive.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItem(Item), LibraryRandom.RandDec(10, 2));  // Taking random for Quantity.
        CreateSalesLine(SalesLine2, SalesHeader, SalesLine2.Type::Item, SalesLine."No.", -LibraryRandom.RandDec(10, 2));  // Taking random for Quantity.
        SalesLine2.Validate("Qty. to Ship", 0);
        SalesLine2.Modify(true);
        VATAmount := (SalesLine.Amount * SalesLine."VAT %" / 100) + LibraryRandom.RandDec(1, 2);
        LibraryVariableStorage.Enqueue(VATAmount);  // Enqueue for VATAmountLinesPageHandler.
        OpenSalesOrderStatisticsPage(SalesHeader."No.");

        // Exercise.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Verify VAT Amount on G/L Entry.
        VerifyAmountOnGLEntry(DocumentNo, VATPostingSetup."Sales VAT Account", -VATAmount);

        // Tear Down.
        UpdateAllowVATDifferenceSalesReceivableSetup(OldAllowVATDifference);
    end;
#endif

    [Test]
    [HandlerFunctions('SalesOrderStatisticsPageHandler,VATAmountLinesModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostSalesOrderAfterUpdatingVATAmtonVATAmtLineNM()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
        OldAllowVATDifference: Boolean;
        VATAmount: Decimal;
    begin
        // [SCENARIO] G/L Entries after posting Sales Order with Negative Lines and Update VAT Amount on VAT Amount Lines.

        // [GIVEN] Update Sales & Receivable Setup, create Item, create Customer.
        Initialize();
        OldAllowVATDifference := UpdateAllowVATDifferenceSalesReceivableSetup(true);  // TRUE for Allow VAT Difference.
        UpdateMaxVATDifferenceAllowedGeneralLedgerSetup();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibrarySales.CreateCustomer(Customer);

        // Create Sales Order with multiple lines and update Quantity to Receive.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItem(Item), LibraryRandom.RandDec(10, 2));  // Taking random for Quantity.
        CreateSalesLine(SalesLine2, SalesHeader, SalesLine2.Type::Item, SalesLine."No.", -LibraryRandom.RandDec(10, 2));  // Taking random for Quantity.
        SalesLine2.Validate("Qty. to Ship", 0);
        SalesLine2.Modify(true);
        VATAmount := (SalesLine.Amount * SalesLine."VAT %" / 100) + LibraryRandom.RandDec(1, 2);
        LibraryVariableStorage.Enqueue(VATAmount);  // Enqueue for VATAmountLinesPageHandler.
        OpenSalesOrderStatisticsPageNM(SalesHeader."No.");

        // Exercise.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Verify VAT Amount on G/L Entry.
        VerifyAmountOnGLEntry(DocumentNo, VATPostingSetup."Sales VAT Account", -VATAmount);

        // Tear Down.
        UpdateAllowVATDifferenceSalesReceivableSetup(OldAllowVATDifference);
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesModalPageHandler')]
    [Scope('OnPrem')]
    procedure GSTSalesEntryWithPrepmtAndPmtAppliedToFinalInvoice()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalLine: Record "Gen. Journal Line";
        GSTSalesEntry: Record "GST Sales Entry";
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        // [SCENARIO] GL and GST Sales Entry after posting Prepayment Invoice and Payment is made to the final Invoice.

        // [GIVEN] Create Sales Order, Post Prepayment Invoice, Post Order and apply Payment to the two Invoices.
        Initialize();
        GeneralLedgerSetup.Get();
        UpdateGeneralLedgerSetup(true, true, true, true);  // TRUE for Enable GST, Full GST On Prepayment, GST Reports and Unrealized VAT.
        CreateSalesOrderAndPostPrepaymentInvoice(SalesLine, '');  // Taking blank value for Currency Code,
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        FindPrepaymentSalesInvoiceHeader(SalesInvoiceHeader, SalesHeader."Sell-to Customer No.");
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);  // Post as Ship and Invoice.
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::Customer, SalesHeader."Sell-to Customer No.", '',
          -(SalesInvoiceHeader."Amount Including VAT" + SalesLine."Amount Including VAT"));  // Using blank for DocumentNo.
        ApplyPaymentToInvoiceOnPaymentJournalPage(GenJournalLine."Journal Batch Name");

        // Exercise.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Verify GL Entries and GST Entries.
        VerifyAmountOnGLEntry(
          GenJournalLine."Document No.", GetReceivableAccount(SalesHeader."Sell-to Customer No."),
          -(SalesInvoiceHeader."Amount Including VAT" + SalesLine."Amount Including VAT"));
        FindAndVerifyGSTSalesEntry(
          DocumentNo, SalesLine."No.", GSTSalesEntry."Document Line Type"::Item,
          -SalesLine."Line Amount" * SalesLine."VAT %" / 100, -SalesLine."Line Amount");

        // Tear Down.
        UpdateGeneralLedgerSetup(
          GeneralLedgerSetup."Enable GST (Australia)", GeneralLedgerSetup."Full GST on Prepayment", GeneralLedgerSetup."GST Report",
          GeneralLedgerSetup."Unrealized VAT");
    end;

    [Test]
    [HandlerFunctions('ApplyVendorEntriesModalPageHandler')]
    [Scope('OnPrem')]
    procedure GSTPurchEntryWithPrepmtAndPmtAppliedToFinalInvoice()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalLine: Record "Gen. Journal Line";
        GSTPurchaseEntry: Record "GST Purchase Entry";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        DocumentNo: Code[20];
    begin
        // [SCENARIO] GL and GST Purchase Entry after posting Prepayment Invoice and Payment is made to the final Invoice.

        // [GIVEN] Create Purchase Order, Post Prepayment Invoice, Post Order and apply Payment to the two Invoices.
        Initialize();
        GeneralLedgerSetup.Get();
        UpdateGeneralLedgerSetup(true, true, true, true);  // TRUE for Enable GST, Full GST On Prepayment, GST Reports and Unrealized VAT.
        CreatePurchaseOrderAndPostPrepaymentInvoice(PurchaseLine, '');  // Using blank value for Currency Code.
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        FindPrepaymentPurchaseInvoiceHeader(PurchInvHeader, PurchaseHeader."Buy-from Vendor No.");
        UpdateVendorInvoiceNoOnPurchaseHeader(PurchaseHeader);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // Post as Receive and Invoice.
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, PurchaseHeader."Buy-from Vendor No.", '',
          PurchInvHeader."Amount Including VAT" + PurchaseLine."Amount Including VAT");  // Using blank for DocumentNo.
        ApplyPaymentToInvoiceOnPaymentJournalPage(GenJournalLine."Journal Batch Name");

        // Exercise.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Verify GL Entries and GST Entries.
        VerifyAmountOnGLEntry(
          GenJournalLine."Document No.", GetPayableAccount(PurchaseHeader."Buy-from Vendor No."),
          PurchInvHeader."Amount Including VAT" + PurchaseLine."Amount Including VAT");
        FindAndVerifyGSTPurchaseEntry(
          DocumentNo, PurchaseLine."No.", GSTPurchaseEntry."Document Line Type"::Item,
          PurchaseLine."Line Amount" * PurchaseLine."VAT %" / 100, PurchaseLine."Line Amount");

        // Tear Down.
        UpdateGeneralLedgerSetup(
          GeneralLedgerSetup."Enable GST (Australia)", GeneralLedgerSetup."Full GST on Prepayment", GeneralLedgerSetup."GST Report",
          GeneralLedgerSetup."Unrealized VAT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GSTPurchEntryWithTwoPrepaymentInvoicesPosted()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
    begin
        // [SCENARIO] GL and GST Purchase Entry after posting two Prepayment Invoices.

        // [GIVEN] Create Purchase Order and post two Prepayment Invoices.
        Initialize();
        GeneralLedgerSetup.Get();
        UpdateGeneralLedgerSetup(true, true, true, GeneralLedgerSetup."Unrealized VAT");  // TRUE for Enable GST, Full GST On Prepayment and GST Reports.
        CreatePurchaseOrderAndPostPrepaymentInvoice(PurchaseLine, '');  // Using blank value for Currency Code.
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        UpdateVendorInvoiceNoOnPurchaseHeader(PurchaseHeader);
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);
        PurchaseLine.Validate("Prepayment %", LibraryRandom.RandDec(20, 2));
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);
        UpdateVendorInvoiceNoOnPurchaseHeader(PurchaseHeader);

        // Exercise.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // Post as Receive and Invoice.

        // [THEN] Verify GL Entries and GST Entries.
        VerifyGLAndGSTPurchaseEntry(
          PurchaseLine."No.", DocumentNo, PurchaseLine."Amount Including VAT", PurchaseLine."Line Amount" * PurchaseLine."VAT %" / 100,
          PurchaseLine."Line Amount");

        // Tear Down.
        UpdateGeneralLedgerSetup(
          GeneralLedgerSetup."Enable GST (Australia)", GeneralLedgerSetup."Full GST on Prepayment", GeneralLedgerSetup."GST Report",
          GeneralLedgerSetup."Unrealized VAT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GSTSalesEntryWithTwoPrepaymentInvoicesPosted()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        // [SCENARIO] GL and GST Sales Entry after posting two Prepayment Invoices.

        // [GIVEN] Create Sales Order and post two Prepayment Invoices.
        Initialize();
        GeneralLedgerSetup.Get();
        UpdateGeneralLedgerSetup(true, true, true, GeneralLedgerSetup."Unrealized VAT");  // TRUE for Enable GST, Full GST On Prepayment and GST Reports.
        CreateSalesOrderAndPostPrepaymentInvoice(SalesLine, '');  // Taking blank value for Currency Code,
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        LibrarySales.ReopenSalesDocument(SalesHeader);
        SalesLine.Validate("Prepayment %", LibraryRandom.RandDec(20, 2));
        SalesLine.Modify(true);
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // Exercise.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);  // Post as Ship and Invoice.

        // [THEN] Verify GL Entries and GST Entries.
        VerifyGLAndGSTSalesEntry(
          SalesLine."No.", DocumentNo, SalesLine."Amount Including VAT",
          -SalesLine."Line Amount" * SalesLine."VAT %" / 100, -SalesLine."Line Amount");

        // Tear Down.
        UpdateGeneralLedgerSetup(
          GeneralLedgerSetup."Enable GST (Australia)", GeneralLedgerSetup."Full GST on Prepayment", GeneralLedgerSetup."GST Report",
          GeneralLedgerSetup."Unrealized VAT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchasePrepaymentInvoiceWithUnrealizedVAT()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
    begin
        // [SCENARIO] invoicing of Purchase in case of Unrealized GST when Full GST on Prepayment is applicable.

        // [GIVEN] Create Purchase Order, post Prepayment Invoice and apply Payment to Prepayment Invoice.
        Initialize();
        GeneralLedgerSetup.Get();
        UpdateGeneralLedgerSetup(true, true, true, true);  // TRUE for Enable GST, Full GST On Prepayment, GST Reports and Unrealized VAT.
        CreatePurchaseOrderAndPostPrepaymentInvoice(PurchaseLine, '');  // Using blank value for Currency Code.
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        FindPrepaymentPurchaseInvoiceHeader(PurchInvHeader, PurchaseHeader."Buy-from Vendor No.");
        CreateAndPostGeneralJournalLine(
          GenJournalLine, WorkDate(), GenJournalLine."Account Type"::Vendor, PurchaseHeader."Buy-from Vendor No.", PurchInvHeader."No.",
          PurchInvHeader."Amount Including VAT");
        UpdateVendorInvoiceNoOnPurchaseHeader(PurchaseHeader);

        // Exercise.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // Post as Receive and Invoice.

        // [THEN] Verify GL Entries and GST Entries.
        VerifyGLAndGSTPurchaseEntry(
          PurchaseLine."No.", DocumentNo, PurchaseLine."Amount Including VAT", PurchaseLine."Line Amount" * PurchaseLine."VAT %" / 100,
          PurchaseLine."Line Amount");

        // Tear Down.
        UpdateGeneralLedgerSetup(
          GeneralLedgerSetup."Enable GST (Australia)", GeneralLedgerSetup."Full GST on Prepayment", GeneralLedgerSetup."GST Report",
          GeneralLedgerSetup."Unrealized VAT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesPrepaymentInvoiceWithUnrealizedVAT()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalLine: Record "Gen. Journal Line";
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        // [SCENARIO] invoicing of Sales in case of Unrealized GST when Full GST on Prepayment is applicable.

        // [GIVEN] Create Sales Order, post Prepayment Invoice, post Order and apply Payment to two Invoices.
        Initialize();
        GeneralLedgerSetup.Get();
        UpdateGeneralLedgerSetup(true, true, true, true);  // TRUE for Enable GST, Full GST On Prepayment, GST Reports and Unrealized VAT.
        CreateSalesOrderAndPostPrepaymentInvoice(SalesLine, '');  // Taking blank value for Currency Code,
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        FindPrepaymentSalesInvoiceHeader(SalesInvoiceHeader, SalesHeader."Sell-to Customer No.");
        CreateAndPostGeneralJournalLine(
          GenJournalLine, WorkDate(), GenJournalLine."Account Type"::Customer, SalesHeader."Sell-to Customer No.", SalesInvoiceHeader."No.",
          -SalesInvoiceHeader."Amount Including VAT");
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);  // Post as Ship and Invoice.
        SalesInvoiceHeader.Get(DocumentNo);
        SalesInvoiceHeader.CalcFields("Amount Including VAT");
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::Customer, SalesHeader."Sell-to Customer No.", DocumentNo,
          -SalesInvoiceHeader."Amount Including VAT");

        // Exercise.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify.
        VerifyCreditAmountOnGLEntries(DocumentNo, SalesLine."Amount Including VAT");

        // Tear Down.
        UpdateGeneralLedgerSetup(
          GeneralLedgerSetup."Enable GST (Australia)", GeneralLedgerSetup."Full GST on Prepayment", GeneralLedgerSetup."GST Report",
          GeneralLedgerSetup."Unrealized VAT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GSTPrepaymentAmountAfterPostingFinalInvoice()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        // [SCENARIO] Prepayment Amount and GST Amount are reversed after posting final Invoice.

        // [GIVEN] Create Sales Order and post Prepayment Invoice
        Initialize();
        GeneralLedgerSetup.Get();
        UpdateGeneralLedgerSetup(true, true, true, GeneralLedgerSetup."Unrealized VAT");  // TRUE for Enable GST, Full GST On Prepayment, GST Reports and Unrealized VAT.
        CreateSalesOrderAndUpdateGeneralPostingSetup(SalesLine, '', 100, true);  // Taking blank value for Currency Code, 100 for Prepayment Pct. as required for Test case,TRUE for Price Including VAT.
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        CreateSalesLine(
          SalesLine2, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItem(Item), LibraryRandom.RandDec(10, 2));  // Taking random for Quantity.
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // Exercise.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);  // Post as Ship and Invoice.

        // [THEN] Verify GL Entries and GST Entries.
        VerifyGLAndGSTSalesEntry(
          SalesLine."No.", DocumentNo, SalesLine."Amount Including VAT" + SalesLine2."Amount Including VAT",
          -SalesLine."VAT Base Amount" * SalesLine."VAT %" / 100, -SalesLine."VAT Base Amount");

        // Tear Down.
        UpdateGeneralLedgerSetup(
          GeneralLedgerSetup."Enable GST (Australia)", GeneralLedgerSetup."Full GST on Prepayment", GeneralLedgerSetup."GST Report",
          GeneralLedgerSetup."Unrealized VAT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPaymentForPurchasePrepaymentInvoiceWithFCY()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        DocumentNo: Code[20];
        OldInvoiceRounding: Boolean;
        StartingDate: Date;
    begin
        // [SCENARIO] GL and GST Entries when GST on full payment is applicable on Prepayment transaction and Purchase Order is created in FCY.

        // [GIVEN] Create Purchase Order with FCY, Post Prepayment Invoice and apply Payment.
        Initialize();
        GeneralLedgerSetup.Get();
        UpdateGeneralLedgerSetup(true, true, true, GeneralLedgerSetup."Unrealized VAT");  // TRUE for Enable GST, Full GST On Prepayment, GST Reports and Unrealized VAT.
        OldInvoiceRounding := UpdateInvoiceRoundingOnPurchasesPayablesSetup(false);  // Using FALSE for Invoice Rounding.
        StartingDate := CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'M>', WorkDate());
        CreatePurchaseOrderAndPostPrepaymentInvoice(PurchaseLine, CreateCurrencyWithExchangeRate(StartingDate));
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        FindPrepaymentPurchaseInvoiceHeader(PurchInvHeader, PurchaseHeader."Buy-from Vendor No.");
        CreateAndPostGeneralJournalLine(
          GenJournalLine, StartingDate, GenJournalLine."Account Type"::Vendor, PurchaseHeader."Buy-from Vendor No.", PurchInvHeader."No.",
          PurchInvHeader."Amount Including VAT");
        UpdateVendorInvoiceNoOnPurchaseHeader(PurchaseHeader);

        // Exercise.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // Post as Receive and Invoice.

        // Verify.
        VerifyGLAndGSTPurchaseEntry(
          PurchaseLine."No.", DocumentNo, LibraryERM.ConvertCurrency(
            PurchaseLine."Amount Including VAT", PurchaseHeader."Currency Code", '', StartingDate),
          LibraryERM.ConvertCurrency(
            PurchaseLine."Line Amount" * PurchaseLine."VAT %" / 100, PurchaseHeader."Currency Code", '', StartingDate),
          LibraryERM.ConvertCurrency(PurchaseLine."Line Amount", PurchaseHeader."Currency Code", '', StartingDate));  // Using blank value for ToCurrency.

        // Tear Down.
        UpdateGeneralLedgerSetup(
          GeneralLedgerSetup."Enable GST (Australia)", GeneralLedgerSetup."Full GST on Prepayment", GeneralLedgerSetup."GST Report",
          GeneralLedgerSetup."Unrealized VAT");
        UpdateInvoiceRoundingOnPurchasesPayablesSetup(OldInvoiceRounding);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPaymentForSalesPrepaymentInvoiceWithFCY()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalLine: Record "Gen. Journal Line";
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
        OldInvoiceRounding: Boolean;
        StartingDate: Date;
    begin
        // [SCENARIO] GL and GST Entries when GST on full payment is applicable on Prepayment transaction and Sales Order is created in FCY.

        // [GIVEN] Create Sales Order with FCY, Post Prepayment Invoice and apply Payment.
        Initialize();
        GeneralLedgerSetup.Get();
        UpdateGeneralLedgerSetup(true, true, true, GeneralLedgerSetup."Unrealized VAT");  // TRUE for Enable GST, Full GST On Prepayment, GST Reports and Unrealized VAT.
        OldInvoiceRounding := UpdateInvoiceRoundingOnSalesReceivablesSetup(false);
        StartingDate := CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'M>', WorkDate());
        CreateSalesOrderAndPostPrepaymentInvoice(SalesLine, CreateCurrencyWithExchangeRate(StartingDate));
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        FindPrepaymentSalesInvoiceHeader(SalesInvoiceHeader, SalesHeader."Sell-to Customer No.");
        CreateAndPostGeneralJournalLine(
          GenJournalLine, StartingDate, GenJournalLine."Account Type"::Customer, SalesHeader."Sell-to Customer No.",
          SalesInvoiceHeader."No.", -SalesInvoiceHeader."Amount Including VAT");

        // Exercise.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);  // Post as Ship and Invoice.

        // Verify.
        VerifyGLAndGSTSalesEntry(
          SalesLine."No.", DocumentNo,
          LibraryERM.ConvertCurrency(SalesLine."Amount Including VAT", SalesHeader."Currency Code", '', StartingDate),
          -LibraryERM.ConvertCurrency(SalesLine."Line Amount" * SalesLine."VAT %" / 100, SalesHeader."Currency Code", '', StartingDate),
          -LibraryERM.ConvertCurrency(SalesLine."Line Amount", SalesHeader."Currency Code", '', StartingDate));  // Using blank value for ToCurrency.

        // Tear Down.
        UpdateGeneralLedgerSetup(
          GeneralLedgerSetup."Enable GST (Australia)", GeneralLedgerSetup."Full GST on Prepayment", GeneralLedgerSetup."GST Report",
          GeneralLedgerSetup."Unrealized VAT");
        UpdateInvoiceRoundingOnSalesReceivablesSetup(OldInvoiceRounding);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesInvWithInvRoundingAndFullGSTOnPrepmtTRUE()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GLEntry: Record "G/L Entry";
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
        OldInvoiceRounding: Boolean;
    begin
        // [SCENARIO] Amount on G/L Entry is rounded off when Invoice rounding on Sales & Receivables Setup is set to TRUE.

        // [GIVEN] Create Sales Order and post Prepayment Invoice.
        Initialize();
        GeneralLedgerSetup.Get();
        UpdateGeneralLedgerSetup(true, true, true, GeneralLedgerSetup."Unrealized VAT");  // TRUE for Enable GST, Full GST On Prepayment and GST Reports.
        OldInvoiceRounding := UpdateInvoiceRoundingOnSalesReceivablesSetup(true);  // TRUE for Invoice Rounding.
        UpdateInvRoundingPrecisionOnGeneralLedgerSetup(1);  // 1 for Invoice Rounding Precision as required for Test case.
        CreateSalesOrderAndPostPrepaymentInvoice(SalesLine, '');  // Blank value for Currency Code.
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        FindPrepaymentSalesInvoiceHeader(SalesInvoiceHeader, SalesHeader."Sell-to Customer No.");

        // Exercise.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);  // Post as Ship and Invoice.

        // Verify.
        FindGLEntry(GLEntry, DocumentNo, GetReceivableAccount(SalesHeader."Sell-to Customer No."));
        GLEntry.TestField(
          Amount, Round(SalesLine."Line Amount" - SalesLine."Prepmt. Line Amount", LibraryERM.GetInvoiceRoundingPrecisionLCY()));

        // Tear Down.
        UpdateGeneralLedgerSetup(
          GeneralLedgerSetup."Enable GST (Australia)", GeneralLedgerSetup."Full GST on Prepayment", GeneralLedgerSetup."GST Report",
          GeneralLedgerSetup."Unrealized VAT");
        UpdateInvoiceRoundingOnSalesReceivablesSetup(OldInvoiceRounding);
        UpdateInvRoundingPrecisionOnGeneralLedgerSetup(GeneralLedgerSetup."Inv. Rounding Precision (LCY)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLEntryAfterPostPurchPrepaymentAndUpdateLineAmt()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
    begin
        // [SCENARIO] G/L and GST Purchase Entry after posting Purchase Prepayment Invoice and Purchase Invoice and updating Line Amount.

        // [GIVEN] Create Purchase Order, post Prepayment Invoice and payment for Prepayment Invoice, Update Direct Unit Cost on Purchase Line.
        Initialize();
        GeneralLedgerSetup.Get();
        UpdateLocalFunctionalitiesOnGeneralLedgerSetup(true, true, true);  // TRUE for Enable GST, GST Reports, Full GST On Prepayment.
        CreatePurchaseOrderAndUpdateGeneralPostingSetup(PurchaseLine, '', LibraryRandom.RandDec(10, 2), false);  // Taking blank value for Currency Code, random value for Prepayment Pct. FALSE for Prices Including VAT.
        PostPaymentForPurchPrepaymentInvoice(PurchaseHeader, PurchaseLine);
        UpdateDirectUnitCostOnPurchaseLine(PurchaseLine);
        PostPaymentForPurchPrepaymentInvoice(PurchaseHeader, PurchaseLine);

        // Exercise.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // Post as Receive and Invoice.

        // [THEN] Verify GST Purchase Entry and Credit Amount on G/L Entry.
        VerifyGLAndGSTPurchaseEntry(
          PurchaseLine."No.", DocumentNo, PurchaseLine."Amount Including VAT", PurchaseLine.Amount * PurchaseLine."VAT %" / 100,
          PurchaseLine.Amount);

        // Tear Down.
        UpdateLocalFunctionalitiesOnGeneralLedgerSetup(
          GeneralLedgerSetup."Enable GST (Australia)", GeneralLedgerSetup."GST Report", GeneralLedgerSetup."Full GST on Prepayment");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLEntryAfterPostSalesPrepaymentAndUpdateLineAmt()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        // [SCENARIO] G/L and GST Sales Entry after posting Sales Prepayment Invoice and Sales Invoice and updating Line Amount.

        // [GIVEN] Create Sales Order, post Prepayment Invoice and payment for Prepayment Invoice, Update Unit Price on Sales Line.
        Initialize();
        GeneralLedgerSetup.Get();
        UpdateLocalFunctionalitiesOnGeneralLedgerSetup(true, true, true);  // TRUE for Enable GST, GST Reports, Full GST On Prepayment.
        CreateSalesOrderAndUpdateGeneralPostingSetup(SalesLine, '', LibraryRandom.RandDec(10, 2), false);  // Taking blank value for Currency Code, random value for Prepayment Pct., FALSE for Prices Including VAT.
        PostPaymentForSalesPrepaymentInvoice(SalesHeader, SalesLine);
        UpdateUnitPriceOnSalesLine(SalesLine);
        PostPaymentForSalesPrepaymentInvoice(SalesHeader, SalesLine);

        // Exercise.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);  // Post as Ship and Invoice.

        // [THEN] Verify GST Sales Entry and Credit Amount on G/L Entry.
        VerifyGLAndGSTSalesEntry(
          SalesLine."No.", DocumentNo, SalesLine."Amount Including VAT",
          -SalesLine."Line Amount" * SalesLine."VAT %" / 100, -SalesLine."Line Amount");

        // Tear Down.
        UpdateLocalFunctionalitiesOnGeneralLedgerSetup(
          GeneralLedgerSetup."Enable GST (Australia)", GeneralLedgerSetup."GST Report", GeneralLedgerSetup."Full GST on Prepayment");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLEntryAfterPaymentForSalesInvoiceAndPrepmtInv()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalLine: Record "Gen. Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        // [SCENARIO] G/L Entry after posting Payment for Sales Invoice and Sales Prepayment Invoice with Full GST On Prepayment TRUE.

        // [GIVEN] Create Sales Order, Post Sales Prepayment Invoice, and make Payment for the same.
        Initialize();
        GeneralLedgerSetup.Get();
        UpdateLocalFunctionalitiesOnGeneralLedgerSetup(true, true, true);  // TRUE for Enable GST, GST Reports, Full GST On Prepayment.
        CreateSalesOrderAndUpdateGeneralPostingSetup(SalesLine, '', LibraryRandom.RandDec(10, 2), true);  // Taking blank value for Currency Code, random value for Prepayment Pct., TRUE for Prices Including VAT.
        PostPaymentForSalesPrepaymentInvoice(SalesHeader, SalesLine);

        // Post Sales Invoice and create General Journal Line.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);  // Post as Ship and Invoice.
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::Customer, SalesHeader."Sell-to Customer No.",
          DocumentNo, -GetSalesInvoiceLineAmount(DocumentNo));

        // Exercise.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Verify Amount On GLEntry
        VerifyAmountOnGLEntry(GenJournalLine."Document No.", GetReceivableAccount(SalesLine."Sell-to Customer No."), -SalesLine.Amount);

        // Tear Down.
        UpdateLocalFunctionalitiesOnGeneralLedgerSetup(
          GeneralLedgerSetup."Enable GST (Australia)", GeneralLedgerSetup."GST Report", GeneralLedgerSetup."Full GST on Prepayment");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLEntryAfterPaymentForPurchInvoiceAndPrepmtInv()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
    begin
        // [SCENARIO] G/L Entry after posting Payment for Purchase Invoice and Purchase Prepayment Invoice with Full GST On Prepayment TRUE.

        // [GIVEN] Create Purchase Order, Post Purchase Prepayment Invoice, and make Payment for the same.
        Initialize();
        GeneralLedgerSetup.Get();
        UpdateLocalFunctionalitiesOnGeneralLedgerSetup(true, true, true);  // TRUE for Enable GST, GST Reports, Full GST On Prepayment.
        CreatePurchaseOrderAndUpdateGeneralPostingSetup(PurchaseLine, '', LibraryRandom.RandDec(10, 2), false);  // Taking blank value for Currency Code, random value for Prepayment Pct., FALSE for Prices Including VAT.
        PostPaymentForPurchPrepaymentInvoice(PurchaseHeader, PurchaseLine);

        // Post Purchase Invoice and create General Journal Line.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // Post as Receive and Invoice.
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, PurchaseHeader."Buy-from Vendor No.",
          DocumentNo, GetPurchaseInvoiceLineAmount(DocumentNo));

        // Exercise.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Verify Amount On GLEntry
        VerifyAmountOnGLEntry(GenJournalLine."Document No.", GetPayableAccount(PurchaseLine."Buy-from Vendor No."), PurchaseLine.Amount);

        // Tear Down.
        UpdateLocalFunctionalitiesOnGeneralLedgerSetup(
          GeneralLedgerSetup."Enable GST (Australia)", GeneralLedgerSetup."GST Report", GeneralLedgerSetup."Full GST on Prepayment");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLEntryAfterPostPurchInvAndPrepaymentCreditMemo()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchasePostPrepayments: Codeunit "Purchase-Post Prepayments";
        DocumentNo: Code[20];
    begin
        // [SCENARIO] GST Purchase Entry and G/L entry after posting Purchase Invoice and Purchase Prepayment Credit Memo.

        // [GIVEN] Create Purchase Order, post Purchase Prepayment Invoice and make payment for the same.
        Initialize();
        GeneralLedgerSetup.Get();
        UpdateLocalFunctionalitiesOnGeneralLedgerSetup(true, true, true);  // TRUE for Enable GST, GST Reports, Full GST On Prepayment.
        CreatePurchaseOrderAndUpdateGeneralPostingSetup(PurchaseLine, '', LibraryRandom.RandDec(10, 2), false);  // Taking blank value for Currency Code, random value for Prepayment Pct., FALSE for Prices Including VAT.
        PostPaymentForPurchPrepaymentInvoice(PurchaseHeader, PurchaseLine);
        PurchaseHeader.Validate("Vendor Cr. Memo No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);

        // Post Purchase Prepayment Credit Memo and Prepayment Invoice.
        PurchasePostPrepayments.CreditMemo(PurchaseHeader);
        PurchaseLine.Find();
        PurchaseLine.Validate("Prepayment %");
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);
        UpdateVendorInvoiceNoOnPurchaseHeader(PurchaseHeader);

        // Exercise.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // Post as Receive and Invoice.

        // [THEN] Verify Amount on GST Purchase Entry and G/L entry.
        VerifyGLAndGSTPurchaseEntry(
          PurchaseLine."No.", DocumentNo, PurchaseLine."Amount Including VAT", PurchaseLine.Amount * PurchaseLine."VAT %" / 100,
          PurchaseLine.Amount);

        // Tear Down.
        UpdateLocalFunctionalitiesOnGeneralLedgerSetup(
          GeneralLedgerSetup."Enable GST (Australia)", GeneralLedgerSetup."GST Report", GeneralLedgerSetup."Full GST on Prepayment");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLEntryAfterPostSalesInvAndPrepaymentCreditMemo()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        // [SCENARIO] GST Sales Entry and G/L entry after posting Sales Invoice and Sales Prepayment Credit Memo.

        // [GIVEN] Create Sales Order, post Sales Prepayment Invoice and make payment for the same.
        Initialize();
        GeneralLedgerSetup.Get();
        UpdateLocalFunctionalitiesOnGeneralLedgerSetup(true, true, true);  // TRUE for Enable GST, GST Reports, Full GST On Prepayment.
        CreateSalesOrderAndUpdateGeneralPostingSetup(SalesLine, '', LibraryRandom.RandDec(10, 2), false);  // Taking blank value for Currency Code, random value for Prepayment Pct., FALSE for Prices Including VAT.
        PostPaymentForSalesPrepaymentInvoice(SalesHeader, SalesLine);

        // Post Sales Prepayment Credit Memo and Prepayment Invoice.
        LibrarySales.PostSalesPrepaymentCrMemo(SalesHeader);
        LibrarySales.ReopenSalesDocument(SalesHeader);
        SalesHeader.Validate("Prepayment %", SalesHeader."Prepayment %" + LibraryRandom.RandDec(10, 2));
        SalesHeader.Modify(true);
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");

        // Exercise.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);  // Post as Ship and Invoice.

        // [THEN] Verify Amount on GST Sales Entry and G/L entry.
        VerifyGLAndGSTSalesEntry(
          SalesLine."No.", DocumentNo, SalesLine."Amount Including VAT",
          -SalesLine."Line Amount" * SalesLine."VAT %" / 100, -SalesLine."Line Amount");

        // Tear Down.
        UpdateLocalFunctionalitiesOnGeneralLedgerSetup(
          GeneralLedgerSetup."Enable GST (Australia)", GeneralLedgerSetup."GST Report", GeneralLedgerSetup."Full GST on Prepayment");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLEntryAfterPostPartialPurchInvAndPrepaymentInv()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
    begin
        // [SCENARIO] GST Purchase Entry and G/L Entry after posting partial Purchase Invoice with Full GST On Prepayment TRUE.

        // [GIVEN] Create and post Purchase Prepayment Invoice, Update Quantity To Invoice on Purchase Line.
        Initialize();
        GeneralLedgerSetup.Get();
        UpdateLocalFunctionalitiesOnGeneralLedgerSetup(true, true, true);  // TRUE for Enable GST, GST Reports, Full GST On Prepayment.
        CreatePurchaseOrderAndUpdateGeneralPostingSetup(PurchaseLine, '', LibraryRandom.RandDec(10, 2), false);  // Taking blank value for Currency Code, random value for Prepayment Pct, FALSE for Prices Including VAT.
        PostPaymentForPurchPrepaymentInvoice(PurchaseHeader, PurchaseLine);
        UpdateQuantityToInvoiceOnPurchaseLine(PurchaseLine);

        // Exercise.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // Post as Receive and Invoice.

        // [THEN] Verify Amount on GST Purchase and G/L Entry.
        VerifyGLAndGSTPurchaseEntry(
          PurchaseLine."No.", DocumentNo, PurchaseLine."Amount Including VAT" / 2, (PurchaseLine.Amount / 2) * PurchaseLine."VAT %" / 100,
          PurchaseLine.Amount / 2);  // Partial value required for Amount in test case.

        // Tear Down.
        UpdateLocalFunctionalitiesOnGeneralLedgerSetup(
          GeneralLedgerSetup."Enable GST (Australia)", GeneralLedgerSetup."GST Report", GeneralLedgerSetup."Full GST on Prepayment");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLEntryAfterPostPartialSalesInvAndPrepaymentInv()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        // [SCENARIO] GST Sales Entry and G/L Entry after posting partial Sales Invoice with Full GST On Prepayment TRUE.

        // [GIVEN] Create and post Sales Prepayment Invoice, Update Quantity To Invoice on Sales Line.
        Initialize();
        GeneralLedgerSetup.Get();
        UpdateLocalFunctionalitiesOnGeneralLedgerSetup(true, true, true);  // TRUE for Enable GST, GST Reports, Full GST On Prepayment.
        CreateSalesOrderAndUpdateGeneralPostingSetup(SalesLine, '', LibraryRandom.RandDec(10, 2), false);  // Taking blank value for Currency Code, random value for Prepayment Pct., FALSE for Prices Including VAT.
        PostPaymentForSalesPrepaymentInvoice(SalesHeader, SalesLine);
        UpdateQuantityToInvoiceOnSalesLine(SalesLine);

        // Exercise.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);  // Post as Ship and Invoice.

        // [THEN] Verify Amount on GST Sales and G/L Entry.
        VerifyGLAndGSTSalesEntry(
          SalesLine."No.", DocumentNo, SalesLine."Amount Including VAT" / 2,
          -(SalesLine.Amount / 2) * SalesLine."VAT %" / 100, -SalesLine.Amount / 2);  // Partial value required for Amount in test case.

        // Tear Down.
        UpdateLocalFunctionalitiesOnGeneralLedgerSetup(
          GeneralLedgerSetup."Enable GST (Australia)", GeneralLedgerSetup."GST Report", GeneralLedgerSetup."Full GST on Prepayment");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLEntryAfterPostSalesOrderWithPricesInclVATTRUE()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        // [SCENARIO] G/L Entry after posting Sales Order with Prices Including VAT as True, Full GST on Prepayment on G/L Setup TRUE.

        // [GIVEN] Create Sales Order and post Prepayment Invoice.
        Initialize();
        GeneralLedgerSetup.Get();
        UpdateLocalFunctionalitiesOnGeneralLedgerSetup(true, true, true);  // TRUE for Enable GST, GST Reports, Full GST On Prepayment.
        CreateSalesOrderAndUpdateGeneralPostingSetup(SalesLine, '', 100, true);  // Taking blank value for Currency Code, 100 for Prepayment Pct, TRUE for Price Including VAT.
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // Exercise.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);  // Post as Ship and Invoice.

        // [THEN] Verify Amount on G/L entry.
        VerifyCreditAmountOnGLEntries(DocumentNo, SalesLine."Amount Including VAT");

        // Tear Down:
        UpdateLocalFunctionalitiesOnGeneralLedgerSetup(
          GeneralLedgerSetup."Enable GST (Australia)", GeneralLedgerSetup."GST Report", GeneralLedgerSetup."Full GST on Prepayment");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchInvWithInvRoundingAndFullGSTOnPrepmtTRUE()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GLEntry: Record "G/L Entry";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
        OldInvoiceRounding: Boolean;
    begin
        // [SCENARIO] Amount on G/L Entry is rounded off when Invoice Rounding on Purchases & Payable Setup is set to TRUE.

        // [GIVEN] Create Purchase Order and post Prepayment Invoice.
        Initialize();
        GeneralLedgerSetup.Get();
        UpdateInvRoundingPrecisionOnGeneralLedgerSetup(1);  // 1 for Invoice Rounding Precision, as required for test case.
        OldInvoiceRounding := UpdateInvoiceRoundingOnPurchasesPayablesSetup(true);  // TRUE for Invoice Rounding.
        UpdateLocalFunctionalitiesOnGeneralLedgerSetup(true, true, true);  // TRUE for Enable GST, GST Reports, Full GST On Prepayment.
        CreatePurchaseOrderAndUpdateGeneralPostingSetup(PurchaseLine, '', LibraryRandom.RandDec(10, 2), false);  // Taking blank value for Currency Code, random for Prepayment Pct., FALSE for Prices Including VAT.
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);
        UpdateVendorInvoiceNoOnPurchaseHeader(PurchaseHeader);

        // Exercise.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // Post as Receive and Invoice.

        // [THEN] Verify AmountOn GL Entry.
        FindGLEntry(GLEntry, DocumentNo, GetPayableAccount(PurchaseLine."Buy-from Vendor No."));
        GLEntry.TestField(
          Amount, -Round(
            PurchaseLine."Line Amount" - PurchaseLine."Prepmt. Line Amount", LibraryERM.GetInvoiceRoundingPrecisionLCY()));

        // Tear Down.
        UpdateInvRoundingPrecisionOnGeneralLedgerSetup(GeneralLedgerSetup."Inv. Rounding Precision (LCY)");
        UpdateInvoiceRoundingOnPurchasesPayablesSetup(OldInvoiceRounding);
        UpdateLocalFunctionalitiesOnGeneralLedgerSetup(
          GeneralLedgerSetup."Enable GST (Australia)", GeneralLedgerSetup."GST Report", GeneralLedgerSetup."Full GST on Prepayment");
    end;

    [Test]
    procedure PurchaseOrder100PercentPrepaymentMultipleLinesWithTheSameGSTProdPostingGroup()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATEntry: Record "VAT Entry";
        GLAccountNo: array[5] of Code[20];
        DocumentNo: Code[20];
        Index: Integer;
    begin
        // [FEATURE] [Invoice] [Full GST] [Full GST on Prepayment] 
        // [SCEMARIO 391401] System does not combine VAT Base amounts in VAT Entries when it posts final invoice after 100% prepayment

        Initialize();
        UpdateLocalFunctionalitiesOnGeneralLedgerSetup(true, true, true);

        for Index := 1 to ArrayLen(GLAccountNo) do
            GLAccountNo[Index] := CreateGLAccount();

        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        GeneralPostingSetup."Purch. Prepayments Account" := GLAccountNo[ArrayLen(GLAccountNo)];
        GeneralPostingSetup.Modify(true);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        PurchaseHeader.Validate("Prepayment %", 100);
        PurchaseHeader.Modify(true);

        for Index := 1 to ArrayLen(GLAccountNo) - 1 do begin
            LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccountNo[Index], 1);
            PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(100, 200));
            PurchaseLine.Modify(true);
        end;

        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.CalcSums("Direct Unit Cost");

        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        PurchaseHeader.Find();
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);

        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.SetFilter(Base, '>%1', 0);
        VATEntry.CalcSums(Base);

        VATEntry.TestField(Base, PurchaseLine."Direct Unit Cost");
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseOrderStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure VerifyInvoiceRoundingOnAfterReleaseOrStats()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        Currency: Record Currency;
        Vendor: Record Vendor;
        PurchaseOrder: TestPage "Purchase Order";
        CurrencyCode: Code[10];
        DirectUnitCost: Decimal;
    begin
        // [SCENARIO 447990]  The Rounding down function is not working after clicking 'Statistics' or 'Release' in PO, because the amount will be rounded up after clicking 'Statics' or 'Release' .
        Initialize();

        // [GIVEN] Save direct unit cost 
        DirectUnitCost := 3082888;

        // [GIVEN] Update Gen ledger setup
        UpdateGenLedgerSetup();

        // [GIVEN] Create currency code and update Rounding type to down
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(
            DMY2Date(1, 1, 2000), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));
        Currency.Get(CurrencyCode);
        UpdateCurrency(Currency);

        // [THEN] Find vat posting setup and update percentage as 11
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup."VAT %" := 11;
        VATPostingSetup.Modify();

        // [GIVEN] Create vendor and upate VAT Bus posting group.
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Vendor.Modify();

        // [GIVEN] Create item and update VATProd posting group.
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Validate("VAT Bus. Posting Gr. (Price)", VATPostingSetup."VAT Bus. Posting Group");
        Item.Modify();

        // [GIVEN] Create Purchase Header and update currency code
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        PurchaseHeader.Validate("Currency Code", Currency.Code);
        PurchaseHeader.Modify();

        // [GIVEN] Create purchase line and update direct unit cost.
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, Item."No.", 1);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify();

        // [THEN] Open purchase order and enqueue Value 
        PurchaseOrder.OpenEdit();
        PurchaseOrder.GotoRecord(PurchaseHeader);
        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(PurchaseOrder.PurchLines."Invoice Discount Amount".AsDecimal());
        LibraryVariableStorage.Enqueue(PurchaseOrder.PurchLines."Total Amount Incl. VAT".AsDecimal());
        LibraryVariableStorage.Enqueue(PurchaseOrder.PurchLines."Total VAT Amount".AsDecimal());
        PurchaseOrder.Statistics.Invoke();

        // [VERIFY] Verify VAT Amount and all other value on Purchase Order Statistics handler page.
    end;
#endif

    [Test]
    [HandlerFunctions('PurchaseOrderStatsPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyInvRoundingOnAfterReleaseOrStats()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        Currency: Record Currency;
        Vendor: Record Vendor;
        PurchaseOrder: TestPage "Purchase Order";
        CurrencyCode: Code[10];
        DirectUnitCost: Decimal;
    begin
        // [SCENARIO 447990]  The Rounding down function is not working after clicking 'Statistics' or 'Release' in PO, because the amount will be rounded up after clicking 'Statics' or 'Release' .
        Initialize();

        // [GIVEN] Save direct unit cost 
        DirectUnitCost := 3082888;

        // [GIVEN] Update Gen ledger setup
        UpdateGenLedgerSetup();

        // [GIVEN] Create currency code and update Rounding type to down
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(
            DMY2Date(1, 1, 2000), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));
        Currency.Get(CurrencyCode);
        UpdateCurrency(Currency);

        // [THEN] Find vat posting setup and update percentage as 11
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup."VAT %" := 11;
        VATPostingSetup.Modify();

        // [GIVEN] Create vendor and upate VAT Bus posting group.
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Vendor.Modify();

        // [GIVEN] Create item and update VATProd posting group.
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Validate("VAT Bus. Posting Gr. (Price)", VATPostingSetup."VAT Bus. Posting Group");
        Item.Modify();

        // [GIVEN] Create Purchase Header and update currency code
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        PurchaseHeader.Validate("Currency Code", Currency.Code);
        PurchaseHeader.Modify();

        // [GIVEN] Create purchase line and update direct unit cost.
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, Item."No.", 1);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify();

        // [THEN] Open purchase order and enqueue Value 
        PurchaseOrder.OpenEdit();
        PurchaseOrder.GotoRecord(PurchaseHeader);
        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(PurchaseOrder.PurchLines."Invoice Discount Amount".AsDecimal());
        LibraryVariableStorage.Enqueue(PurchaseOrder.PurchLines."Total Amount Incl. VAT".AsDecimal());
        LibraryVariableStorage.Enqueue(PurchaseOrder.PurchLines."Total VAT Amount".AsDecimal());
        PurchaseOrder.PurchaseOrderStatistics.Invoke();

        // [VERIFY] Verify VAT Amount and all other value on Purchase Order Statistics handler page.
    end;

    local procedure Initialize()
    begin
        Clear(NoSeriesBatch);
        LibraryVariableStorage.Clear();
    end;

    local procedure ApplyPaymentToInvoiceOnPaymentJournalPage(CurrentJnlBatchName: Code[10])
    var
        PaymentJournal: TestPage "Payment Journal";
    begin
        PaymentJournal.OpenEdit();
        PaymentJournal.CurrentJnlBatchName.SetValue(CurrentJnlBatchName);
        PaymentJournal.ApplyEntries.Invoke();  // Opens ApplyVendorEntriesModalPageHandler or ApplyCustomerEntriesModalPageHandler.
        PaymentJournal.OK().Invoke();
    end;

    local procedure CreateAndPostGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; PostingDate: Date; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; AppliesToDocNo: Code[20]; Amount: Decimal)
    begin
        CreateGeneralJournalLine(GenJournalLine, AccountType, AccountNo, AppliesToDocNo, Amount);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateCurrencyExchangeRate(var CurrencyExchangeRate: Record "Currency Exchange Rate"; CurrencyCode: Code[10]; StartingDate: Date)
    begin
        LibraryERM.CreateExchRate(CurrencyExchangeRate, CurrencyCode, StartingDate);

        // Using RANDOM Exchange Rate Amount and Relational Exch. Rate Amount.
        CurrencyExchangeRate.Validate("Exchange Rate Amount", LibraryRandom.RandInt(100));
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", CurrencyExchangeRate."Exchange Rate Amount");
        CurrencyExchangeRate.Modify(true);
    end;

    local procedure CreateCurrencyWithExchangeRate(StartingDate: Date): Code[10]
    var
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateCurrency(Currency);
        Currency.Validate("Realized Gains Acc.", GLAccount."No.");
        Currency.Validate("Realized Losses Acc.", GLAccount."No.");
        Currency.Modify(true);
        CreateCurrencyExchangeRate(CurrencyExchangeRate, Currency.Code, WorkDate());
        CreateCurrencyExchangeRate(CurrencyExchangeRate, Currency.Code, StartingDate);
        exit(Currency.Code);
    end;

    local procedure CreateGeneralJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Payments);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; AppliesToDocNo: Code[20]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        CreateGeneralJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", GLAccount."No.");
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", AppliesToDocNo);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateItemWithVATProdPostingGroup(VATProdPostingGroup: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreatePurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; Quantity: Decimal)
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseOrderAndPostPrepaymentInvoice(var PurchaseLine: Record "Purchase Line"; CurrencyCode: Code[10])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreatePurchaseOrderAndUpdateGeneralPostingSetup(PurchaseLine, CurrencyCode, LibraryRandom.RandDec(20, 2), false);  // Taking blank value for CurrencyCode, random for Prepayment Pct, FALSE for Price Including VAT.
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);
    end;

    local procedure CreatePurchaseOrderAndUpdateGeneralPostingSetup(var PurchaseLine: Record "Purchase Line"; CurrencyCode: Code[10]; PrepaymentPct: Decimal; PricesIncludingVAT: Boolean)
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        VATPostingSetup: Record "VAT Posting Setup";
        Vendor: Record Vendor;
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);
        UpdatePrepmtAccInGeneralPostingSetup(Vendor."Gen. Bus. Posting Group", Item."Gen. Prod. Posting Group");
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        PurchaseHeader.Validate("Prices Including VAT", PricesIncludingVAT);
        PurchaseHeader.Validate("Prepayment %", PrepaymentPct);
        PurchaseHeader.Validate("Currency Code", CurrencyCode);
        PurchaseHeader.Modify(true);
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, Item."No.", LibraryRandom.RandDec(10, 2));  // Taking random for Quantity.
    end;

    local procedure CreateSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; Type: Enum "Sales Line Type"; No: Code[20]; Quantity: Decimal)
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Type, No, Quantity);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(10, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesOrderAndPostPrepaymentInvoice(var SalesLine: Record "Sales Line"; CurrencyCode: Code[10])
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesOrderAndUpdateGeneralPostingSetup(SalesLine, CurrencyCode, LibraryRandom.RandDec(20, 2), false);  // Taking random for Prepayment Pct, FALSE for Price Including VAT.
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
    end;

    local procedure CreateSalesOrderAndUpdateGeneralPostingSetup(var SalesLine: Record "Sales Line"; CurrencyCode: Code[10]; PrepaymentPct: Decimal; PricesIncludingVAT: Boolean)
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateItem(Item);
        UpdatePrepmtAccInGeneralPostingSetup(Customer."Gen. Bus. Posting Group", Item."Gen. Prod. Posting Group");
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        SalesHeader.Validate("Prepayment %", PrepaymentPct);
        SalesHeader.Validate("Prices Including VAT", PricesIncludingVAT);
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Modify(true);
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));  // Taking random for Quantity.
    end;

    local procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; VATBusPostingGroup: Code[20])
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostingGroup, VATProductPostingGroup.Code);
        VATPostingSetup.Validate("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::Percentage);
        VATPostingSetup.Modify(true);
    end;

    local procedure FindAndVerifyGSTPurchaseEntry(DocumentNo: Code[20]; DocumentLineDescription: Text[50]; DocumentLineType: Enum "Purchase Line Type"; Amount: Decimal; GSTBase: Decimal)
    var
        GSTPurchaseEntry: Record "GST Purchase Entry";
    begin
        GSTPurchaseEntry.SetRange("Document No.", DocumentNo);
        GSTPurchaseEntry.SetRange("Document Line Type", DocumentLineType);
        GSTPurchaseEntry.SetRange("Document Line Description", DocumentLineDescription);
        GSTPurchaseEntry.FindFirst();
        Assert.AreNearlyEqual(Amount, GSTPurchaseEntry.Amount, LibraryERM.GetAmountRoundingPrecision(), AmountMustMatchMsg);
        Assert.AreNearlyEqual(GSTBase, GSTPurchaseEntry."GST Base", LibraryERM.GetAmountRoundingPrecision(), AmountMustMatchMsg);
    end;

    local procedure FindAndVerifyGSTSalesEntry(DocumentNo: Code[20]; DocumentLineDescription: Text[50]; DocumentLineType: Enum "Sales Line Type"; Amount: Decimal; GSTBase: Decimal)
    var
        GSTSalesEntry: Record "GST Sales Entry";
    begin
        FindGSTSalesEntry(GSTSalesEntry, DocumentNo, DocumentLineDescription, DocumentLineType);
        Assert.AreNearlyEqual(Amount, GSTSalesEntry.Amount, LibraryERM.GetAmountRoundingPrecision(), AmountMustMatchMsg);
        Assert.AreNearlyEqual(GSTBase, GSTSalesEntry."GST Base", LibraryERM.GetAmountRoundingPrecision(), AmountMustMatchMsg);
    end;

    local procedure FindGLEntry(var GLEntry: Record "G/L Entry"; DocumentNo: Code[20]; GLAccountNo: Code[20])
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindFirst();
    end;

    local procedure FindGSTSalesEntry(var GSTSalesEntry: Record "GST Sales Entry"; DocumentNo: Code[20]; DocumentLineDescription: Text[50]; DocumentLineType: Enum "Sales Line Type")
    begin
        GSTSalesEntry.SetRange("Document No.", DocumentNo);
        GSTSalesEntry.SetRange("Document Line Type", DocumentLineType);
        GSTSalesEntry.SetRange("Document Line Description", DocumentLineDescription);
        GSTSalesEntry.FindFirst();
    end;

    local procedure FindPrepaymentPurchaseInvoiceHeader(var PurchInvHeader: Record "Purch. Inv. Header"; BuyFromVendorNo: Code[20])
    begin
        PurchInvHeader.SetRange("Buy-from Vendor No.", BuyFromVendorNo);
        PurchInvHeader.FindFirst();
        PurchInvHeader.CalcFields("Amount Including VAT");
    end;

    local procedure FindPrepaymentSalesInvoiceHeader(var SalesInvoiceHeader: Record "Sales Invoice Header"; SellToCustomerNo: Code[20])
    begin
        SalesInvoiceHeader.SetRange("Sell-to Customer No.", SellToCustomerNo);
        SalesInvoiceHeader.FindFirst();
        SalesInvoiceHeader.CalcFields("Amount Including VAT");
    end;

    local procedure GetPayableAccount(No: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        Vendor.Get(No);
        VendorPostingGroup.Get(Vendor."Vendor Posting Group");
        exit(VendorPostingGroup."Payables Account");
    end;

    local procedure GetPurchaseInvoiceLineAmount(DocumentNo: Code[20]): Decimal
    var
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        PurchInvLine.SetRange("Document No.", DocumentNo);
        PurchInvLine.FindFirst();
        exit(PurchInvLine.Amount);
    end;

    local procedure GetReceivableAccount(No: Code[20]): Code[20]
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        Customer.Get(No);
        CustomerPostingGroup.Get(Customer."Customer Posting Group");
        exit(CustomerPostingGroup."Receivables Account");
    end;

    local procedure GetSalesInvoiceLineAmount(DocumentNo: Code[20]): Decimal
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SalesInvoiceLine.SetRange("Document No.", DocumentNo);
        SalesInvoiceLine.FindFirst();
        exit(SalesInvoiceLine.Amount);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    local procedure OpenPurchaseOrderStatisticsPage(No: Code[20])
    var
        PurchaseOrder: TestPage "Purchase Order";
    begin
        PurchaseOrder.OpenEdit();
        PurchaseOrder.FILTER.SetFilter("No.", No);
        PurchaseOrder.Statistics.Invoke();  // Invokes PurchaseOrderStatisticsModalPageHandler.
        PurchaseOrder.Close();
    end;
#endif

    local procedure OpenPurchaseOrderStatsPage(No: Code[20])
    var
        PurchaseOrder: TestPage "Purchase Order";
    begin
        PurchaseOrder.OpenEdit();
        PurchaseOrder.FILTER.SetFilter("No.", No);
        PurchaseOrder.PurchaseOrderStatistics.Invoke();  // Invokes PurchaseOrderStatisticsPageHandler.
        PurchaseOrder.Close();
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    local procedure OpenSalesOrderStatisticsPage(No: Code[20])
    var
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", No);
        SalesOrder.Statistics.Invoke();  // Invokes SalesOrderStatisticsModalPageHandler.
        SalesOrder.Close();
    end;
#endif
    local procedure OpenSalesOrderStatisticsPageNM(No: Code[20])
    var
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", No);
        SalesOrder.SalesOrderStatistics.Invoke();  // Invokes SalesOrderStatisticsModalPageHandlerNM.
        SalesOrder.Close();
    end;

    local procedure PostPaymentForPurchPrepaymentInvoice(var PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line")
    var
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
    begin
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        DocumentNo := NoSeriesBatch.GetNextNo(PurchaseHeader."Posting No. Series");
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);
        UpdateVendorInvoiceNoOnPurchaseHeader(PurchaseHeader);
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, PurchaseHeader."Buy-from Vendor No.",
          DocumentNo, GetPurchaseInvoiceLineAmount(DocumentNo));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure PostPaymentForSalesPrepaymentInvoice(var SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line")
    var
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
    begin
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        DocumentNo := NoSeriesBatch.GetNextNo(SalesHeader."Posting No. Series");
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::Customer,
          SalesHeader."Sell-to Customer No.", DocumentNo, -GetSalesInvoiceLineAmount(DocumentNo));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure UpdateAllowVATDifferencePurchasesPayablesSetup(AllowVATDifference: Boolean) OldAllowVATDifference: Boolean
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        OldAllowVATDifference := PurchasesPayablesSetup."Allow VAT Difference";
        PurchasesPayablesSetup.Validate("Allow VAT Difference", AllowVATDifference);
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure UpdateAllowVATDifferenceSalesReceivableSetup(AllowVATDifference: Boolean) OldAllowVATDifference: Boolean
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        OldAllowVATDifference := SalesReceivablesSetup."Allow VAT Difference";
        SalesReceivablesSetup.Validate("Allow VAT Difference", AllowVATDifference);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure UpdateDirectUnitCostOnPurchaseLine(var PurchaseLine: Record "Purchase Line")
    begin
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        PurchaseLine.Validate("Direct Unit Cost", PurchaseLine."Direct Unit Cost" + LibraryRandom.RandDec(100, 2));  // Added random value to Direct Unit Case.
        PurchaseLine.Modify(true);
    end;

    local procedure UpdateGeneralLedgerSetup(EnableGST: Boolean; FullGSTOnPrepayment: Boolean; GSTReport: Boolean; UnrealizedVAT: Boolean)
    begin
        UpdateLocalFunctionalitiesOnGeneralLedgerSetup(EnableGST, GSTReport, FullGSTOnPrepayment);
        UpdateUnrealizedVATGeneralLedgerSetup(UnrealizedVAT);
    end;

    local procedure UpdateInvoiceRoundingOnPurchasesPayablesSetup(InvoiceRounding: Boolean): Boolean
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Invoice Rounding", InvoiceRounding);
        PurchasesPayablesSetup.Modify(true);
        exit(PurchasesPayablesSetup."Invoice Rounding");
    end;

    local procedure UpdateInvoiceRoundingOnSalesReceivablesSetup(InvoiceRounding: Boolean): Boolean
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Invoice Rounding", InvoiceRounding);
        SalesReceivablesSetup.Modify(true);
        exit(SalesReceivablesSetup."Invoice Rounding");
    end;

    local procedure UpdateInvRoundingPrecisionOnGeneralLedgerSetup(InvRoundingPrecisionLCY: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Inv. Rounding Precision (LCY)", InvRoundingPrecisionLCY);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdateLocalFunctionalitiesOnGeneralLedgerSetup(EnableGST: Boolean; GSTReport: Boolean; FullGSTOnPrepayment: Boolean)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Enable GST (Australia)", EnableGST);
        GeneralLedgerSetup.Validate("GST Report", GSTReport);
        GeneralLedgerSetup.Validate("Full GST on Prepayment", FullGSTOnPrepayment);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdateMaxVATDifferenceAllowedGeneralLedgerSetup()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Max. VAT Difference Allowed", LibraryRandom.RandDecInRange(1, 10, 2));
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdatePrepmtAccInGeneralPostingSetup(GenBusPostingGroup: Code[20]; GenProdPostingGroup: Code[20])
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GeneralPostingSetup.Get(GenBusPostingGroup, GenProdPostingGroup);
        GeneralPostingSetup."Sales Prepayments Account" := CreateGLAccount();
        GeneralPostingSetup."Purch. Prepayments Account" := CreateGLAccount();
        GeneralPostingSetup.Modify(true);
    end;

    local procedure UpdateQuantityToInvoiceOnPurchaseLine(var PurchaseLine: Record "Purchase Line")
    begin
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        PurchaseLine.Validate("Qty. to Invoice", PurchaseLine."Qty. to Invoice" / 2);  // Partial Quantity required.
        PurchaseLine.Modify(true);
    end;

    local procedure UpdateQuantityToInvoiceOnSalesLine(var SalesLine: Record "Sales Line")
    begin
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        SalesLine.Validate("Qty. to Invoice", SalesLine."Qty. to Invoice" / 2);  // Partial Quantity required.
        SalesLine.Modify(true);
    end;

    local procedure UpdateUnitPriceOnSalesLine(var SalesLine: Record "Sales Line")
    begin
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        SalesLine.Validate("Unit Price", SalesLine."Unit Price" + LibraryRandom.RandDec(100, 2));  // Added random value to Unit Price.
        SalesLine.Modify(true);
    end;

    local procedure UpdateUnrealizedVATGeneralLedgerSetup(UnrealizedVAT: Boolean) OldUnrealizedVAT: Boolean
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        OldUnrealizedVAT := GeneralLedgerSetup."Unrealized VAT";
        GeneralLedgerSetup.Validate("Unrealized VAT", UnrealizedVAT);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdateVendorInvoiceNoOnPurchaseHeader(var PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);
    end;

    local procedure VerifyAmountOnGLEntry(DocumentNo: Code[20]; GLAccountNo: Code[20]; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        FindGLEntry(GLEntry, DocumentNo, GLAccountNo);
        Assert.AreNearlyEqual(Amount, GLEntry.Amount, LibraryERM.GetAmountRoundingPrecision(), AmountMustMatchMsg);
    end;

    local procedure VerifyCreditAmountOnGLEntries(DocumentNo: Code[20]; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.CalcSums("Credit Amount");
        Assert.AreNearlyEqual(Amount, GLEntry."Credit Amount", LibraryERM.GetAmountRoundingPrecision(), AmountMustMatchMsg);
    end;

    local procedure VerifyGLAndGSTPurchaseEntry(DocumentLineDescription: Code[20]; DocumentNo: Code[20]; Amount: Decimal; GSTAmount: Decimal; GSTBase: Decimal)
    var
        GSTPurchaseEntry: Record "GST Purchase Entry";
    begin
        VerifyCreditAmountOnGLEntries(DocumentNo, Amount);
        FindAndVerifyGSTPurchaseEntry(DocumentNo, DocumentLineDescription, GSTPurchaseEntry."Document Line Type"::Item, GSTAmount, GSTBase);
    end;

    local procedure VerifyGLAndGSTSalesEntry(DocumentLineDescription: Code[20]; DocumentNo: Code[20]; Amount: Decimal; GSTAmount: Decimal; GSTBase: Decimal)
    var
        GSTSalesEntry: Record "GST Sales Entry";
    begin
        VerifyCreditAmountOnGLEntries(DocumentNo, Amount);
        FindAndVerifyGSTSalesEntry(DocumentNo, DocumentLineDescription, GSTSalesEntry."Document Line Type"::Item, GSTAmount, GSTBase);
    end;

    local procedure UpdateGenLedgerSetup()
    var
        GenLedgerSetup: Record "General Ledger Setup";
    begin
        GenLedgerSetup.Get();
        // GenLedgerSetup.Validate("Amount Rounding Precision", 0.01);
        GenLedgerSetup.Validate("VAT Rounding Type", GenLedgerSetup."VAT Rounding Type"::Down);
        GenLedgerSetup.Modify(true);
    end;

    local procedure UpdateCurrency(var Currency: Record Currency)
    begin
        Currency.Validate("Amount Rounding Precision", 1);
        Currency.Validate("VAT Rounding Type", Currency."VAT Rounding Type"::Down);
        Currency.Validate("Invoice Rounding Type", Currency."Invoice Rounding Type"::Down);
        Currency.Modify();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyCustomerEntriesModalPageHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    begin
        ApplyCustomerEntries."Set Applies-to ID".Invoke();
        ApplyCustomerEntries.Next();
        ApplyCustomerEntries."Set Applies-to ID".Invoke();
        ApplyCustomerEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyVendorEntriesModalPageHandler(var ApplyVendorEntries: TestPage "Apply Vendor Entries")
    begin
        ApplyVendorEntries.ActionSetAppliesToID.Invoke();
        ApplyVendorEntries.Next();
        ApplyVendorEntries.ActionSetAppliesToID.Invoke();
        ApplyVendorEntries.OK().Invoke();
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseOrderStatisticsModalPageHandler(var PurchaseOrderStatistics: TestPage "Purchase Order Statistics")
    begin
        PurchaseOrderStatistics.NoOfVATLines_Invoicing.DrillDown();  // Invokes VATAmountLinesHandler.
    end;
#endif

    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchaseOrderStatisticsPageHandler(var PurchaseOrderStatistics: TestPage "Purchase Order Statistics")
    begin
        PurchaseOrderStatistics.NoOfVATLines_Invoicing.DrillDown();  // Invokes VATAmountLinesHandler.
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderStatisticsModalPageHandler(var SalesOrderStatistics: TestPage "Sales Order Statistics")
    begin
        SalesOrderStatistics.NoOfVATLines_Invoicing.DrillDown();  // Invokes VATAmountLinesHandler.
    end;
#endif
    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderStatisticsPageHandler(var SalesOrderStatistics: TestPage "Sales Order Statistics")
    begin
        SalesOrderStatistics.NoOfVATLines_Invoicing.DrillDown();  // Invokes VATAmountLinesHandler.
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VATAmountLinesModalPageHandler(var VATAmountLines: TestPage "VAT Amount Lines")
    var
        VATAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(VATAmount);
        VATAmountLines."VAT Amount".SetValue(VATAmount);
        VATAmountLines.OK().Invoke();
    end;

#if not CLEAN26 
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseOrderStatisticsModalHandler(var PurchaseOrderStatistics: TestPage "Purchase Order Statistics")
    var
        VATApplied: Variant;
        TotalAmountInclVAT: Variant;
        InvDiscAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(InvDiscAmount);
        LibraryVariableStorage.Dequeue(TotalAmountInclVAT);
        LibraryVariableStorage.Dequeue(VATApplied);

        Assert.AreEqual(InvDiscAmount, PurchaseOrderStatistics.InvDiscountAmount_General.AsDecimal(),
          'Invoice Discount Amount is not correct');
        Assert.AreEqual(TotalAmountInclVAT, PurchaseOrderStatistics.TotalInclVAT_General.AsDecimal(),
          'Total Amount Incl. VAT is not correct');
        Assert.AreEqual(VATApplied, PurchaseOrderStatistics."VATAmount[1]".AsDecimal(),
          'VAT Amount is not correct');
    end;
#endif

    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchaseOrderStatsPageHandler(var PurchaseOrderStatistics: TestPage "Purchase Order Statistics")
    var
        VATApplied: Variant;
        TotalAmountInclVAT: Variant;
        InvDiscAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(InvDiscAmount);
        LibraryVariableStorage.Dequeue(TotalAmountInclVAT);
        LibraryVariableStorage.Dequeue(VATApplied);

        Assert.AreEqual(InvDiscAmount, PurchaseOrderStatistics.InvDiscountAmount_General.AsDecimal(),
          'Invoice Discount Amount is not correct');
        Assert.AreEqual(TotalAmountInclVAT, PurchaseOrderStatistics.TotalInclVAT_General.AsDecimal(),
          'Total Amount Incl. VAT is not correct');
        Assert.AreEqual(VATApplied, PurchaseOrderStatistics."VATAmount[1]".AsDecimal(),
          'VAT Amount is not correct');
    end;
}

