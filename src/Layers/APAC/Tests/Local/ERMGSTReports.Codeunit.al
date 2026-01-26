codeunit 141006 "ERM GST Reports"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [GST] [Reporting] [UI]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        GSTEntriesPageValuesErr: Label 'GST Entries page contains wrong values';

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderGSTPurchaseEntriesPage()
    var
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Order]
        // [SCENARIO] GST Purchase Entries page for posted Purchase Order
        Initialize();

        // [GIVEN] Posted Purchase Order
        DocumentNo :=
          CreateAndPostPurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::Order, LibraryRandom.RandDate(5));
        // [WHEN] Open GST Purchase Entries page
        // GST Purchase Entries page is opened in verification

        // [THEN] Verify "GST Base", "Amount", "Total Purchase", "GST %" values
        VerifyGSTPurchaseEntriesPageValues(
          DocumentNo, PurchaseLine."VAT Base Amount", PurchaseLine."Amount Including VAT" - PurchaseLine."VAT Base Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseReturnOrderGSTPurchaseEntriesPage()
    var
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Return Order]
        // [SCENARIO] GST Purchase Entries page for posted Purchase Return Order
        Initialize();

        // [GIVEN] Posted Purchase Return Order
        DocumentNo :=
          CreateAndPostPurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::"Return Order", LibraryRandom.RandDate(5));
        // [WHEN] Open GST Purchase Entries page
        // GST Purchase Entries page is opened in verification

        // [THEN] Verify "GST Base", "Amount", "Total Purchase", "GST %" values
        VerifyGSTPurchaseEntriesPageValues(
          DocumentNo, -PurchaseLine."VAT Base Amount", -(PurchaseLine."Amount Including VAT" - PurchaseLine."VAT Base Amount"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceGSTPurchaseEntriesPage()
    var
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Invoice]
        // [SCENARIO] GST Purchase Entries page for posted Purchase Invoice
        Initialize();

        // [GIVEN] Posted Purchase Invoice
        DocumentNo :=
          CreateAndPostPurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::Invoice, LibraryRandom.RandDate(5));
        // [WHEN] Open GST Purchase Entries page
        // GST Purchase Entries page is opened in verification

        // [THEN] Verify "GST Base", "Amount", "Total Purchase", "GST %" values
        VerifyGSTPurchaseEntriesPageValues(
          DocumentNo, PurchaseLine."VAT Base Amount", PurchaseLine."Amount Including VAT" - PurchaseLine."VAT Base Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoGSTPurchaseEntriesPage()
    var
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Credit Memo]
        // [SCENARIO] GST Purchase Entries page for posted Purchase Credit Memo
        Initialize();

        // [GIVEN] Posted Purchase Credit Memo
        DocumentNo :=
          CreateAndPostPurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::"Credit Memo", LibraryRandom.RandDate(5));
        // [WHEN] Open GST Purchase Entries page
        // GST Purchase Entries page is opened in verification

        // [THEN] Verify "GST Base", "Amount", "Total Purchase", "GST %" values
        VerifyGSTPurchaseEntriesPageValues(
          DocumentNo, -PurchaseLine."VAT Base Amount", -(PurchaseLine."Amount Including VAT" - PurchaseLine."VAT Base Amount"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderGSTSalesEntriesPage()
    var
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales] [Order]
        // [SCENARIO] GST Sales Entries page for posted Sales Order
        Initialize();

        // [GIVEN] Posted Sales Order
        DocumentNo :=
          CreateAndPostSalesDocument(SalesLine, SalesLine."Document Type"::Order, LibraryRandom.RandDate(5));
        // [WHEN] Open GST Sales Entries page
        // GST Sales Entries page is opened in verification

        // [THEN] Verify "GST Base", "Amount", "Total Purchase", "GST %" values
        VerifyGSTSalesEntriesPageValues(
          DocumentNo, -SalesLine."VAT Base Amount", -(SalesLine."Amount Including VAT" - SalesLine."VAT Base Amount"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesReturnOrderGSTSalesEntriesPage()
    var
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales] [Return Order]
        // [SCENARIO] GST Sales Entries page for posted Sales Return Order
        Initialize();

        // [GIVEN] Posted Sales Return Order
        DocumentNo :=
          CreateAndPostSalesDocument(SalesLine, SalesLine."Document Type"::"Return Order", LibraryRandom.RandDate(5));
        // [WHEN] Open GST Sales Entries page
        // GST Sales Entries page is opened in verification

        // [THEN] Verify "GST Base", "Amount", "Total Purchase", "GST %" values
        VerifyGSTSalesEntriesPageValues(
          DocumentNo, SalesLine."VAT Base Amount", SalesLine."Amount Including VAT" - SalesLine."VAT Base Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceGSTSalesEntriesPage()
    var
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO] GST Sales Entries page for posted Sales Invoice
        Initialize();

        // [GIVEN] Posted Sales Invoice
        DocumentNo :=
          CreateAndPostSalesDocument(SalesLine, SalesLine."Document Type"::Invoice, LibraryRandom.RandDate(5));
        // [WHEN] Open GST Sales Entries page
        // GST Sales Entries page is opened in verification

        // [THEN] Verify "GST Base", "Amount", "Total Purchase", "GST %" values
        VerifyGSTSalesEntriesPageValues(
          DocumentNo, -SalesLine."VAT Base Amount", -(SalesLine."Amount Including VAT" - SalesLine."VAT Base Amount"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCreditMemoGSTSalesEntriesPage()
    var
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO] GST Sales Entries page for posted Sales Credit Memo
        Initialize();

        // [GIVEN] Posted Sales Credit Memo
        DocumentNo :=
          CreateAndPostSalesDocument(SalesLine, SalesLine."Document Type"::"Credit Memo", LibraryRandom.RandDate(5));
        // [WHEN] Open GST Sales Entries page
        // GST Sales Entries page is opened in verification

        // [THEN] Verify "GST Base", "Amount", "Total Purchase", "GST %" values
        VerifyGSTSalesEntriesPageValues(
          DocumentNo, SalesLine."VAT Base Amount", SalesLine."Amount Including VAT" - SalesLine."VAT Base Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderPrepaymentGSTSalesEntriesPage()
    var
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales] [Prepayment] [Order]
        // [SCENARIO] GST Sales Entries page for posted Prepayment Sales Order
        Initialize();

        // [GIVEN] Posted Prepayment Sales Order
        DocumentNo := CreateAndPostSalesPrepmtOrder(SalesLine);
        // [WHEN] Open GST Sales Entries page
        // GST Sales Entries page is opened in verification

        // [THEN] Verify "GST Base", "Amount", "Total Purchase", "GST %" values
        VerifyGSTSalesEntriesPageValues(
          DocumentNo, -SalesLine."VAT Base Amount", -(SalesLine."Amount Including VAT" - SalesLine."VAT Base Amount"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderPrepaymentGSTPurchaseEntriesPage()
    var
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Prepayment] [Order]
        // [SCENARIO] GST Purchase Entries page for posted Prepayment Purchase Order
        Initialize();

        // [GIVEN] Posted Prepayment Purchase Order
        DocumentNo := CreateAndPostPurchPrepmtOrder(PurchaseLine);
        // [WHEN] Open GST Purchase Entries page
        // GST Purchase Entries page is opened in verification

        // [THEN] Verify "GST Base", "Amount", "Total Purchase", "GST %" values
        VerifyGSTPurchaseEntriesPageValues(
          DocumentNo, PurchaseLine."VAT Base Amount", PurchaseLine."Amount Including VAT" - PurchaseLine."VAT Base Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceGenJournalGSTSalesEntriesPage()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Sales] [General Journal] [Invoice]
        // [SCENARIO] GST Sales Entries page for posted Sales Invoice throught the General Journal
        Initialize();

        // [GIVEN] Posted Sales Invoice through the General Journal
        CreateAndPostGeneralJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, LibraryRandom.RandDec(100, 2),
          GenJournalLine."Account Type"::Customer, CreateCustomer(), GenJournalLine."Bal. Gen. Posting Type"::Sale);
        // [WHEN] Open GST Sales Entries page
        // GST Sales Entries page is opened in verification

        // [THEN] Verify "GST Base", "Amount", "Total Purchase", "GST %" values
        VerifyGSTSalesEntriesPageValues(
          GenJournalLine."Document No.",
          GenJournalLine."Bal. VAT Base Amount",
          -(GenJournalLine.Amount + GenJournalLine."Bal. VAT Base Amount"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCreditMemoGenJournalGSTSalesEntriesPage()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Sales] [General Journal] [Credit Memo]
        // [SCENARIO] GST Sales Entries page for posted Sales Credit Memo throught the General Journal
        Initialize();

        // [GIVEN] Posted Sales Credit Memo through the General Journal
        CreateAndPostGeneralJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo", -LibraryRandom.RandDec(100, 2),
          GenJournalLine."Account Type"::Customer, CreateCustomer(), GenJournalLine."Bal. Gen. Posting Type"::Sale);
        // [WHEN] Open GST Sales Entries page
        // GST Sales Entries page is opened in verification

        // [THEN] Verify "GST Base", "Amount", "Total Purchase", "GST %" values
        VerifyGSTSalesEntriesPageValues(
          GenJournalLine."Document No.",
          GenJournalLine."Bal. VAT Base Amount",
          -(GenJournalLine.Amount + GenJournalLine."Bal. VAT Base Amount"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceGenJournalGSTPurchaseEntriesPage()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Purchase] [General Journal] [Invoice]
        // [SCENARIO] GST Purchase Entries page for posted Purchase Invoice throught the General Journal
        Initialize();

        // [GIVEN] Posted Purchase Invoice through the General Journal
        CreateAndPostGeneralJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, -LibraryRandom.RandDec(100, 2),
          GenJournalLine."Account Type"::Vendor, CreateVendor(), GenJournalLine."Bal. Gen. Posting Type"::Purchase);
        // [WHEN] Open GST Purchase Entries page
        // GST Purchase Entries page is opened in verification

        // [THEN] Verify "GST Base", "Amount", "Total Purchase", "GST %" values
        VerifyGSTPurchaseEntriesPageValues(
          GenJournalLine."Document No.",
          GenJournalLine."Bal. VAT Base Amount",
          -(GenJournalLine.Amount + GenJournalLine."Bal. VAT Base Amount"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoGenJournalGSTPurchaseEntriesPage()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Purchase] [General Journal] [Credit Memo]
        // [SCENARIO] GST Purchase Entries page for posted Purchase Credit Memo throught the General Journal
        Initialize();

        // [GIVEN] Posted Purchase Credit Memo through the General Journal
        CreateAndPostGeneralJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo", LibraryRandom.RandDec(100, 2),
          GenJournalLine."Account Type"::Vendor, CreateVendor(), GenJournalLine."Bal. Gen. Posting Type"::Purchase);
        // [WHEN] Open GST Purchase Entries page
        // GST Purchase Entries page is opened in verification

        // [THEN] Verify "GST Base", "Amount", "Total Purchase", "GST %" values
        VerifyGSTPurchaseEntriesPageValues(
          GenJournalLine."Document No.",
          GenJournalLine."Bal. VAT Base Amount",
          -(GenJournalLine.Amount + GenJournalLine."Bal. VAT Base Amount"));
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
        UpdateGeneralLedgerSetup();
    end;

    local procedure CreateAndPostPurchaseDocument(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; PostingDate: Date): Code[20]
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
    begin
        CreatePurchaseHeader(PurchaseHeader, DocumentType);
        PurchaseHeader.Validate("Posting Date", PostingDate);
        PurchaseHeader.Modify(true);
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(Item."Costing Method"::FIFO));
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateAndPostSalesDocument(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; PostingDate: Date): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CreateCustomer());
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Modify(true);
        CreateSalesLine(SalesLine, SalesHeader);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateAndPostGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; BalGenPostingType: Enum "General Posting Type")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
          AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", CreateGLAccount());
        GenJournalLine.Validate("Bal. Gen. Posting Type", BalGenPostingType);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndPostPurchPrepmtOrder(var PurchaseLine: Record "Purchase Line"): Code[20]
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
    begin
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order);
        ModifyPrepmtPctOnPurchaseHeader(PurchaseHeader);
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(Item."Costing Method"::FIFO));
        exit(LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader));
    end;

    local procedure CreateAndPostSalesPrepmtOrder(var SalesLine: Record "Sales Line"): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer());
        ModifyPrepmtPctOnSalesHeader(SalesHeader);
        CreateSalesLine(SalesLine, SalesHeader);
        exit(LibrarySales.PostSalesPrepaymentInvoice(SalesHeader));
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Modify(true);
        exit(Customer."No.");
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

    local procedure CreateItem(CostingMethod: Enum "Costing Method"): Code[20]
    var
        Item: Record Item;
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Validate("Costing Method", CostingMethod);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type")
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, CreateVendor());
        PurchaseHeader.Validate("Vendor Cr. Memo No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);
    end;

    local procedure CreatePurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; Type: Enum "Purchase Line Type"; No: Code[20])
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type, No, LibraryRandom.RandDec(10, 2));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
        UpdatePrepmtAccInGeneralPostingSetup(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
    end;

    local procedure CreateSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    var
        Item: Record Item;
    begin
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(Item."Costing Method"::FIFO), LibraryRandom.RandDec(10, 2));  // Using random for Quantity.
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
        UpdatePrepmtAccInGeneralPostingSetup(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
    end;

    local procedure CreateVendor(): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Vendor: Record Vendor;
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure ModifyPrepmtPctOnPurchaseHeader(var PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader.Validate("Prepayment %", LibraryRandom.RandInt(50));
        PurchaseHeader.Modify(true);
    end;

    local procedure ModifyPrepmtPctOnSalesHeader(var SalesHeader: Record "Sales Header")
    begin
        SalesHeader.Validate("Prepayment %", LibraryRandom.RandInt(50));
        SalesHeader.Modify(true);
    end;

    local procedure UpdateGeneralLedgerSetup()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Enable GST (Australia)", true);
        GeneralLedgerSetup.Validate("Adjustment Mandatory", true);
        GeneralLedgerSetup.Validate("GST Report", true);
        GeneralLedgerSetup.Validate("Full GST on Prepayment", true);
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

    local procedure VerifyGSTPurchaseEntriesPageValues(DocumentNo: Code[20]; Amount: Decimal; VATAmount: Decimal)
    var
        GSTPurchaseEntry: Record "GST Purchase Entry";
        GSTPurchaseEntries: TestPage "GST Purchase Entries";
    begin
        GSTPurchaseEntry.SetRange("Document No.", DocumentNo);
        GSTPurchaseEntry.FindFirst();

        GSTPurchaseEntries.OpenEdit();
        GSTPurchaseEntries.GotoRecord(GSTPurchaseEntry);
        Assert.AreEqual(Amount, GSTPurchaseEntries."GST Base".AsDecimal(), GSTEntriesPageValuesErr);
        Assert.AreEqual(VATAmount, GSTPurchaseEntries.Amount.AsDecimal(), GSTEntriesPageValuesErr);
        Assert.AreEqual(Amount + VATAmount, GSTPurchaseEntries.GSTTotalAmount.AsDecimal(), GSTEntriesPageValuesErr);
        Assert.AreEqual(VATAmount / Amount * 100, GSTPurchaseEntries.GSTPercentage.AsDecimal(), GSTEntriesPageValuesErr);
        Assert.AreNearlyEqual(VATAmount / Amount * 100, GSTPurchaseEntries.GSTPercentage.AsDecimal(), 0.01, GSTEntriesPageValuesErr);
    end;

    local procedure VerifyGSTSalesEntriesPageValues(DocumentNo: Code[20]; Amount: Decimal; VATAmount: Decimal)
    var
        GSTSalesEntry: Record "GST Sales Entry";
        GSTSalesEntries: TestPage "GST Sales Entries";
    begin
        GSTSalesEntry.SetRange("Document No.", DocumentNo);
        GSTSalesEntry.FindFirst();

        GSTSalesEntries.OpenEdit();
        GSTSalesEntries.GotoRecord(GSTSalesEntry);
        Assert.AreEqual(Amount, GSTSalesEntries."GST Base".AsDecimal(), GSTEntriesPageValuesErr);
        Assert.AreEqual(VATAmount, GSTSalesEntries.Amount.AsDecimal(), GSTEntriesPageValuesErr);
        Assert.AreEqual(Amount + VATAmount, GSTSalesEntries.GSTTotalAmount.AsDecimal(), GSTEntriesPageValuesErr);
        Assert.AreEqual(VATAmount / Amount * 100, GSTSalesEntries.GSTPercentage.AsDecimal(), GSTEntriesPageValuesErr);
        Assert.AreNearlyEqual(VATAmount / Amount * 100, GSTSalesEntries.GSTPercentage.AsDecimal(), 0.01, GSTEntriesPageValuesErr);
    end;
}

