codeunit 134014 "ERM Unreal VAT Option First"
{
    Permissions = TableData "Cust. Ledger Entry" = rimd,
                  TableData "Vendor Ledger Entry" = rimd;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Unrealized VAT] [First]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        AmountError: Label '%1 must be %2 in %3 No. %4.';

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Unreal VAT Option First");
        LibraryApplicationArea.EnableFoundationSetup();
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Unreal VAT Option First");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERM.SetUnrealizedVAT(true);

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Unreal VAT Option First");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartialVATFirstSales()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // Check that correct VAT Amount Applied after posting Sales Invoice and making Payment against it.
        Initialize();
        LibraryERM.FindUnrealVATPostingSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::First);
        PartialUnrealizedVATSales(GenJournalLine, SalesInvoiceHeader, VATPostingSetup);

        // Verify: Verify the Amount in VAT Entry.
        VerifyVATEntry(GenJournalLine, '', GenJournalLine.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure HalfVATFirstSales()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check that Half VAT Amount Applied after posting Sales Invoice and making Payment against it.
        Initialize();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        HalfUnrealizedVATSales(GenJournalLine, VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::First);

        // Verify: Verify the Amount in VAT Entry.
        VerifyVATEntry(GenJournalLine, '', GenJournalLine.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RemainingVATFirstSales()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // Check that correct VAT Amount Applied after posting Sales Invoice and making Payment against it.
        Initialize();
        LibraryERM.FindUnrealVATPostingSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::First);
        PartialUnrealizedVATSales(GenJournalLine, SalesInvoiceHeader, VATPostingSetup);

        // Make Payment again for the Invoice and Apply the Payment on Invoice.
        CreateAndPostJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::Customer, SalesInvoiceHeader."Sell-to Customer No.", GenJournalLine.Amount, '');
        ApplyAndPostCustomerEntry(CustLedgerEntry."Document Type"::Payment, GenJournalLine."Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceHeader.CalcFields("Amount Including VAT", Amount);

        // Verify: Verify the Remaining VAT Amount in VAT Entry.
        VerifyVATEntry(
          GenJournalLine, '', -(SalesInvoiceHeader."Amount Including VAT" - SalesInvoiceHeader.Amount) - GenJournalLine.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartialVATFirstPurchase()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        // Check that correct VAT Amount Applied after posting Purchase Invoice and making Payment against it.
        Initialize();
        LibraryERM.FindUnrealVATPostingSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::First);
        PartialUnrealizedVATPurchase(GenJournalLine, PurchInvHeader, VATPostingSetup, '');

        // Verify: Verify the VAT Amount in VAT Entry.
        VerifyVATEntry(GenJournalLine, '', GenJournalLine.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure HalfVATFirstPurchase()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check that Half VAT Amount Applied after posting Purchase Invoice and making Payment against it.
        Initialize();
        LibraryERM.FindUnrealVATPostingSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::First);
        HalfUnrealizedVATPurchase(GenJournalLine, VATPostingSetup);

        // Verify: Verify the VAT Amount in VAT Entry.
        VerifyVATEntry(GenJournalLine, '', GenJournalLine.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RemainingVATFirstPurchase()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // Check that correct VAT Amount Applied after posting Purchase Invoice and making Payment against it.
        Initialize();
        LibraryERM.FindUnrealVATPostingSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::First);
        PartialUnrealizedVATPurchase(GenJournalLine, PurchInvHeader, VATPostingSetup, '');

        // Make Payment again for the Invoice and Apply the Payment on Invoice.
        CreateAndPostJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, PurchInvHeader."Buy-from Vendor No.", GenJournalLine.Amount, '');
        ApplyAndPostVendorEntry(VendorLedgerEntry."Document Type"::Payment, GenJournalLine."Document No.", PurchInvHeader."No.");
        PurchInvHeader.CalcFields("Amount Including VAT", Amount);

        // Verify: Verify the Remaining VAT Amount in VAT Entry.
        VerifyVATEntry(GenJournalLine, '', (PurchInvHeader."Amount Including VAT" - PurchInvHeader.Amount) - GenJournalLine.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartialVATFirstPurchaseFCY()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        // Check that correct VAT Amount Applied after posting Purchase Invoice with Currency and making Payment against it.
        Initialize();
        LibraryERM.FindUnrealVATPostingSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::First);
        PartialUnrealizedVATPurchase(GenJournalLine, PurchInvHeader, VATPostingSetup, CreateCurrency());

        // Verify: Verify the VAT Amount in VAT Entry.
        VerifyVATEntry(GenJournalLine, PurchInvHeader."Currency Code", GenJournalLine.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RemainingVATPurchaseFCY()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // Check that correct VAT Amount Applied after posting Purchase Invoice with Currency and making Payment against it.
        Initialize();
        LibraryERM.FindUnrealVATPostingSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::First);
        PartialUnrealizedVATPurchase(GenJournalLine, PurchInvHeader, VATPostingSetup, CreateCurrency());

        // Make Payment again for the Invoice with Currency and Apply the Payment on Invoice.
        CreateAndPostJournalLine(GenJournalLine, GenJournalLine."Account Type"::Vendor, PurchInvHeader."Buy-from Vendor No.",
          GenJournalLine.Amount, PurchInvHeader."Currency Code");
        ApplyAndPostVendorEntry(VendorLedgerEntry."Document Type"::Payment, GenJournalLine."Document No.", PurchInvHeader."No.");

        // Verify: Verify the Remaining VAT Amount in VAT Entry.
        PurchInvLine.SetRange("Document No.", PurchInvHeader."No.");
        PurchInvLine.FindFirst();
        VerifyVATEntry(
          GenJournalLine, PurchInvHeader."Currency Code",
          (PurchInvLine."Amount Including VAT" - PurchInvLine.Amount) - GenJournalLine.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoVATFullyPaidSales()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // Check that no VAT Entry exists after posting Sales Invoice and Applying Payment over it.
        Initialize();
        LibraryERM.FindUnrealVATPostingSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::"First (Fully Paid)");
        PartialUnrealizedVATSales(GenJournalLine, SalesInvoiceHeader, VATPostingSetup);

        // Verify: Verify that no VAT Entry exists.
        VerifyNoVATEntry(GenJournalLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FullVATFullyPaidSales()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // Check that Full VAT Amount exists in VAT Entry after posting Sales Invoice and Applying Payment over it.
        Initialize();
        LibraryERM.FindUnrealVATPostingSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::"First (Fully Paid)");
        PartialUnrealizedVATSales(GenJournalLine, SalesInvoiceHeader, VATPostingSetup);

        // Make Payment again for the Invoice and Apply the Payment on Invoice.
        CreateAndPostJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::Customer, SalesInvoiceHeader."Sell-to Customer No.", GenJournalLine.Amount, '');
        ApplyAndPostCustomerEntry(CustLedgerEntry."Document Type"::Payment, GenJournalLine."Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceHeader.CalcFields("Amount Including VAT", Amount);

        // Verify: Verify that Full VAT Amount exists in VAT Entry.
        VerifyVATEntry(GenJournalLine, '', -(SalesInvoiceHeader."Amount Including VAT" - SalesInvoiceHeader.Amount));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoVATFullyPaidPurchase()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        // Check that no VAT Entry exists after posting Purchase Invoice and Applying Payment over it.
        Initialize();
        LibraryERM.FindUnrealVATPostingSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::"First (Fully Paid)");
        PartialUnrealizedVATPurchase(GenJournalLine, PurchInvHeader, VATPostingSetup, '');

        // Verify: Verify that no VAT Entry exists.
        VerifyNoVATEntry(GenJournalLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FullVATFullyPurchase()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // Check that full VAT Amount exists in VAT Entry after posting Purchase Invoice and Applying Payment over it.
        Initialize();
        LibraryERM.FindUnrealVATPostingSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::"First (Fully Paid)");
        PartialUnrealizedVATPurchase(GenJournalLine, PurchInvHeader, VATPostingSetup, '');

        // Make Payment again for the Invoice and Apply the Payment on Invoice.
        CreateAndPostJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, PurchInvHeader."Buy-from Vendor No.", GenJournalLine.Amount, '');
        ApplyAndPostVendorEntry(VendorLedgerEntry."Document Type"::Payment, GenJournalLine."Document No.", PurchInvHeader."No.");
        PurchInvHeader.CalcFields("Amount Including VAT", Amount);

        // Verify: Verify that Full VAT Amount exists in VAT Entry.
        VerifyVATEntry(GenJournalLine, '', PurchInvHeader."Amount Including VAT" - PurchInvHeader.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FullPaymentUnrealizedVATFirst()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        InvoiceAmount: Decimal;
    begin
        // Check that correct Amount,VAT Amount, Additional-Currency Amount Applied after posting General Journal with Document Type
        // Invoice and making Payment.
        Initialize();
        LibraryERM.FindUnrealVATPostingSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::First);
        InvoiceAmount := LibraryRandom.RandDec(1000, 2);  // Using Random Number Generator for Amount.
        UnrealizedVATDocument(VATPostingSetup, InvoiceAmount, -InvoiceAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartialPaymentVATFirstFully()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Check that correct Amount,VAT Amount, Additional-Currency Amount Applied after posting General Journal with Document Type
        // Invoice and making Payment below VAT Amount.
        Initialize();
        PartialPaymentWithVAT(VATPostingSetup."Unrealized VAT Type"::"First (Fully Paid)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartialPaymentVATTypeFirst()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Check that correct Amount,VAT Amount, Additional-Currency Amount Applied after posting General Journal with Document Type
        // Invoice and Partial making Payment.

        Initialize();
        PartialPaymentWithVAT(VATPostingSetup."Unrealized VAT Type"::First);
    end;

    local procedure PartialPaymentWithVAT(UnrealizedVATType: Option)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PaymentAmount: Decimal;
        InvoiceAmount: Decimal;
    begin
        // Find VAT Posting Setup and
        LibraryERM.FindUnrealVATPostingSetup(VATPostingSetup, UnrealizedVATType);
        InvoiceAmount := LibraryRandom.RandDec(1000, 2);  // Using Random Number Generator for Amount.
        PaymentAmount := InvoiceAmount * VATPostingSetup."VAT %" / (100 + VATPostingSetup."VAT %") - LibraryRandom.RandDec(1, 2);
        UnrealizedVATDocument(VATPostingSetup, InvoiceAmount, -PaymentAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartialVATSalesCreditMemo()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Amount: Decimal;
        DocumentNo: Code[20];
    begin
        // Test VAT Entry after Apply Refund on Credit Memo for Customer with Unrealized VAT Type as First.

        // 1. Setup: Update Unrealized VAT as True on General Ledger Setup, VAT Posting Setup with Unrealized VAT Type First, Create and
        // Post Sales Credit Memo.Take Random Quantity greater than 100 to avoid rounding issues.
        Initialize();
        LibraryERM.FindUnrealVATPostingSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::First);
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::"Credit Memo", CreateCustomer(VATPostingSetup."VAT Bus. Posting Group"));
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group"),
          100 + LibraryRandom.RandDec(100, 2));
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        Amount := (SalesLine.Quantity * SalesLine."Unit Price") * (1 + VATPostingSetup."VAT %" / 100);

        // 2. Exercise: Create and Post General Journal Line with Document Type as Refund and Apply it on Credit Memo.
        // 2 is required for Partial Refund.
        CreateAndPostGeneralJournal(
          GenJournalLine, GenJournalLine."Account Type"::Customer, SalesHeader."Sell-to Customer No.", '', Amount / 2);
        ApplyAndPostCustomerEntry(CustLedgerEntry."Document Type"::Refund, GenJournalLine."Document No.", DocumentNo);

        // 3. Verify: Verify VAT Entry for Unrealized VAT.
        VerifyVATEntry(GenJournalLine, '', Amount * VATPostingSetup."VAT %" / (100 + VATPostingSetup."VAT %"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplySalesCreditMemoTwice()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Amount: Decimal;
        DocumentNo: Code[20];
    begin
        // Test Customer Ledger Entry after Apply Refund on Credit Memo Twice for Customer with Unrealized VAT Type as First.

        // 1. Setup: Update Unrealized VAT as True on General Ledger Setup, VAT Posting Setup with Unrealized VAT Type First, Create and
        // Post Sales Credit Memo, Create and Post General Journal Line with Document Type as Refund and Apply it on Credit Memo.
        // Take Random Quantity greater than 100 to avoid rounding issues.
        Initialize();
        LibraryERM.FindUnrealVATPostingSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::First);
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::"Credit Memo", CreateCustomer(VATPostingSetup."VAT Bus. Posting Group"));
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group"),
          100 + LibraryRandom.RandDec(100, 2));
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        Amount := SalesLine.Quantity * SalesLine."Unit Price" * (1 + VATPostingSetup."VAT %" / 100);

        // 2 is required for Partial Refund.
        CreateAndPostGeneralJournal(
          GenJournalLine, GenJournalLine."Account Type"::Customer, SalesHeader."Sell-to Customer No.", '', Amount / 2);
        ApplyAndPostCustomerEntry(CustLedgerEntry."Document Type"::Refund, GenJournalLine."Document No.", DocumentNo);

        // 2. Exercise: Again Create and Post General Journal Line with Document Type as Refund for Remaining Amount and Apply it on
        // Credit Memo.
        CreateAndPostGeneralJournal(
          GenJournalLine, GenJournalLine."Account Type"::Customer, SalesHeader."Sell-to Customer No.", '', Amount - GenJournalLine.Amount);
        ApplyAndPostCustomerEntry(CustLedgerEntry."Document Type"::Refund, GenJournalLine."Document No.", DocumentNo);

        // 3. Verify: Verify Remaining Amount on Customer Ledger Entry.
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo", DocumentNo);
        CustLedgerEntry.CalcFields("Remaining Amount");
        Assert.AreNearlyEqual(
          0, CustLedgerEntry."Remaining Amount", LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountError, CustLedgerEntry.FieldCaption("Remaining Amount"), 0,
            CustLedgerEntry.TableCaption(), CustLedgerEntry."Entry No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartialVATPurchaseCreditMemo()
    begin
        // Test VAT Entry after Apply Refund on Credit Memo for Vendor with Unrealized VAT Type as First.

        PartialApplyCreditMemo('');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartialCreditMemoWithCurrency()
    begin
        // Test VAT Entry after Apply Refund on Credit Memo for Vendor with Unrealized VAT Type as First and Currency.

        PartialApplyCreditMemo(CreateCurrency());
    end;

    local procedure PartialApplyCreditMemo(CurrencyCode: Code[10])
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Amount: Decimal;
        DocumentNo: Code[20];
    begin
        // 1. Setup: Update Unrealized VAT as True on General Ledger Setup, VAT Posting Setup with Unrealized VAT Type First, Create and
        // Post Purchase Credit Memo with Currency.Take Random Quantity greater than 100 to avoid rounding issues.
        Initialize();
        LibraryERM.FindUnrealVATPostingSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::First);
        CreateAndUpdatePurchaseHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", CurrencyCode, VATPostingSetup."VAT Bus. Posting Group");
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group"),
          100 + LibraryRandom.RandDec(100, 2));
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        Amount := PurchaseLine.Quantity * PurchaseLine."Direct Unit Cost" * (1 + PurchaseLine."VAT %" / 100);

        // 2. Exercise: Create and Post General Journal Line with Document Type as Refund and Apply it on Credit Memo.
        // 2 is required for Partial Refund.
        CreateAndPostGeneralJournal(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, PurchaseHeader."Buy-from Vendor No.", CurrencyCode, -Amount / 2);
        ApplyAndPostVendorEntry(VendorLedgerEntry."Document Type"::Refund, GenJournalLine."Document No.", DocumentNo);

        // 3. Verify: Verify VAT Entry for Unrealized VAT.
        VerifyVATEntry(GenJournalLine, CurrencyCode, -Amount * VATPostingSetup."VAT %" / (100 + VATPostingSetup."VAT %"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyPurchaseCreditMemoTwice()
    begin
        // Test Vendor Ledger Entry after Apply Refund on Credit Memo for Vendor Twice with Unrealized VAT Type as First.

        ApplyCreditMemoTwice('');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreditMemoApplyTwiceCurrency()
    begin
        // Test Vendor Ledger Entry after Apply Refund on Credit Memo for Vendor Twice with Unrealized VAT Type as First and Currency.

        ApplyCreditMemoTwice(CreateCurrency());
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesHandler,PostApplicationHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure UnrealizedVATHalfFirstSales()
    var
        GenJournalLine: Record "Gen. Journal Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
        HalfVATAmount: Decimal;
    begin
        // Test GL and VAT Entry after apply Half VAT amount to Invoice for Customer with Unrealized VAT Type as First
        // using page testability.

        // Setup: Update General Ledger Setup and VAT Setup, Create and Post Sales Invoice.
        Initialize();
        DocumentNo := PostSalesInvoiceWithUnrealVAT(VATPostingSetup);
        HalfVATAmount := CalculateHalfSalesVATAmount(DocumentNo);
        SalesInvoiceHeader.Get(DocumentNo);

        // Exercise: Make Payment against Invoice with Half VAT Amount and Apply the Payment over Invoice.
        ApplyPostJournalLineCustomer(
          GenJournalLine, SalesInvoiceHeader."Sell-to Customer No.", '', -HalfVATAmount);

        // Verify: Verify the Amount in VAT Entry and Amount in G/L Entry.
        VerifyGLEntryVATAmount(GenJournalLine, '', -GenJournalLine.Amount);
        VerifyVATEntry(GenJournalLine, '', GenJournalLine.Amount);
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesHandler,PostApplicationHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure UnrealVATFirstRemainingSales()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        DocumentNo: Code[20];
        HalfVATAmount: Decimal;
    begin
        // Test GL and VAT Entry after apply Remaining amount to Invoice for Customer with Unrealized VAT Type as First
        // using page testability.

        // Setup: Update General Ledger Setup and VAT Setup, Create and Post Sales Invoice.
        // Payment against Invoice with Half VAT Amount and Apply the Payment over Invoice.
        Initialize();
        DocumentNo := PostSalesInvoiceWithUnrealVAT(VATPostingSetup);
        SalesInvoiceHeader.Get(DocumentNo);

        HalfVATAmount := CalculateHalfSalesVATAmount(DocumentNo);
        FindSalesInvoiceLine(SalesInvoiceLine, SalesInvoiceHeader."No.");
        ApplyPostJournalLineCustomer(GenJournalLine, SalesInvoiceHeader."Sell-to Customer No.", '', -HalfVATAmount);

        // Exercise: Make Payment against Invoice with Remaining Amount and Apply the Payment over Invoice.
        ApplyPostJournalLineCustomer(
          GenJournalLine, SalesInvoiceHeader."Sell-to Customer No.", '', -(SalesInvoiceLine."Amount Including VAT" - HalfVATAmount));

        // Verify: Verify the Amount in VAT Entry and Amount in G/L Entry.
        VerifyGLEntryVATAmount(GenJournalLine, '', -GenJournalLine.Amount);
        VerifyVATEntry(GenJournalLine, '', -Round(SalesInvoiceLine.Amount * VATPostingSetup."VAT %" / 100 - HalfVATAmount));
    end;

    [Test]
    [HandlerFunctions('ApplyVendorEntriesHandler,PostApplicationHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure UnrealizedVATHalfFirstPurch()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        PurchInvLine: Record "Purch. Inv. Line";
        PostedDocumentNo: Code[20];
        HalfVATAmount: Decimal;
    begin
        // Test GL and VAT Entry after apply Half VAT amount to Invoice for Vendor with Unrealized VAT Type as First
        // using page testability.

        // Setup: Update General Ledger Setup and VAT Setup, Create and Post Purchase Invoice.
        Initialize();
        PostedDocumentNo := PostPurchInvoiceWithUnrealVAT(VATPostingSetup, '');
        FindPurchaseInvoiceLine(PurchInvLine, PostedDocumentNo);
        HalfVATAmount := CalculateHalfPurchaseVATAmount(PostedDocumentNo);

        // Exercise: Make Payment against Invoice with Half VAT Amount and Apply the Payment over Invoice.
        ApplyPostJournalLineVendor(GenJournalLine, PurchInvLine."Buy-from Vendor No.", '', HalfVATAmount);

        // Verify: Verify the Amount in VAT Entry and Amount in G/L Entry.
        VerifyGLEntryVATAmount(GenJournalLine, '', -GenJournalLine.Amount);
        VerifyVATEntry(GenJournalLine, '', GenJournalLine.Amount);
    end;

    [Test]
    [HandlerFunctions('ApplyVendorEntriesHandler,PostApplicationHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure UnrealVATFirstRemainingPurch()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        PurchInvLine: Record "Purch. Inv. Line";
        PostedDocumentNo: Code[20];
        HalfVATAmount: Decimal;
    begin
        // Test GL and VAT Entry after apply Remaining amount to Invoice for Vendor with Unrealized VAT Type as First
        // using page testability.

        // Setup: Update General Ledger Setup and VAT Setup, Create and Post Sales Invoice.
        // Payment against Invoice with Half VAT Amount and Apply the Payment over Invoice.
        Initialize();
        PostedDocumentNo := PostPurchInvoiceWithUnrealVAT(VATPostingSetup, '');
        FindPurchaseInvoiceLine(PurchInvLine, PostedDocumentNo);
        HalfVATAmount := CalculateHalfPurchaseVATAmount(PostedDocumentNo);
        ApplyPostJournalLineVendor(GenJournalLine, PurchInvLine."Buy-from Vendor No.", '', HalfVATAmount);

        // Exercise: Make Payment against Invoice with Remaining Amount and Apply the Payment over Invoice.
        ApplyPostJournalLineVendor(
          GenJournalLine, PurchInvLine."Buy-from Vendor No.", '', PurchInvLine."Amount Including VAT" - HalfVATAmount);

        // Verify: Verify the Amount in VAT Entry and Amount in G/L Entry.
        VerifyGLEntryVATAmount(GenJournalLine, '', -GenJournalLine.Amount);
        VerifyVATEntry(GenJournalLine, '', Round(PurchInvLine.Amount * VATPostingSetup."VAT %" / 100 - HalfVATAmount));
    end;

    [Test]
    [HandlerFunctions('ApplyVendorEntriesHandler,PostApplicationHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure HalfVATFirstPurchaseFCY()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        PurchInvLine: Record "Purch. Inv. Line";
        PostedDocumentNo: Code[20];
        CurrencyCode: Code[10];
        HalfVATAmount: Decimal;
    begin
        // Test GL and VAT Entry after apply Half VAT amount to Invoice for Vendor with Currency and Unrealized VAT Type as First
        // using page testability.

        // Setup: Update General Ledger Setup and VAT Setup, Create Currency, Create and Post Purchase Invoice.
        Initialize();
        CurrencyCode := CreateCurrency();
        PostedDocumentNo := PostPurchInvoiceWithUnrealVAT(VATPostingSetup, CurrencyCode);
        FindPurchaseInvoiceLine(PurchInvLine, PostedDocumentNo);
        HalfVATAmount := CalculateHalfPurchaseVATAmount(PostedDocumentNo);

        // Exercise: Make Payment against Invoice with Half VAT Amount and Apply the Payment over Invoice.
        ApplyPostJournalLineVendor(GenJournalLine, PurchInvLine."Buy-from Vendor No.", CurrencyCode, HalfVATAmount);

        // Verify: Verify the Amount in VAT Entry and Amount in G/L Entry.
        VerifyGLEntryVATAmount(GenJournalLine, CurrencyCode, -GenJournalLine.Amount);
        VerifyVATEntry(GenJournalLine, CurrencyCode, GenJournalLine.Amount);
    end;

    [Test]
    [HandlerFunctions('ApplyVendorEntriesHandler,PostApplicationHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure RemainingVATFirstPurchaseFCY()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        PurchInvLine: Record "Purch. Inv. Line";
        PostedDocumentNo: Code[20];
        CurrencyCode: Code[10];
        HalfVATAmount: Decimal;
    begin
        // Test GL and VAT Entry after apply Remaining amount to Invoice for Vendor with Currency and Unrealized VAT Type as First
        // using page testability.

        // Setup: Update General Ledger Setup and VAT Setup, Create and Post Sales Invoice.
        // Payment against Invoice with Half VAT Amount and Apply the Payment over Invoice.
        Initialize();
        CurrencyCode := CreateCurrency();
        PostedDocumentNo := PostPurchInvoiceWithUnrealVAT(VATPostingSetup, CurrencyCode);
        FindPurchaseInvoiceLine(PurchInvLine, PostedDocumentNo);
        HalfVATAmount := CalculateHalfPurchaseVATAmount(PostedDocumentNo);
        ApplyPostJournalLineVendor(GenJournalLine, PurchInvLine."Buy-from Vendor No.", CurrencyCode, HalfVATAmount);

        // Exercise: Make Payment against Invoice with Remaining Amount and Apply the Payment over Invoice.
        ApplyPostJournalLineVendor(
          GenJournalLine, PurchInvLine."Buy-from Vendor No.", CurrencyCode, PurchInvLine."Amount Including VAT" - HalfVATAmount);

        // Verify: Verify the Amount in VAT Entry and Amount in G/L Entry.
        VerifyGLEntryVATAmount(GenJournalLine, CurrencyCode, -GenJournalLine.Amount);
        VerifyVATEntry(GenJournalLine, CurrencyCode, Round(PurchInvLine.Amount * VATPostingSetup."VAT %" / 100 - HalfVATAmount));
    end;

    local procedure ApplyCreditMemoTwice(CurrencyCode: Code[10])
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Amount: Decimal;
        DocumentNo: Code[20];
    begin
        // 1. Setup: Update Unrealized VAT as True on General Ledger Setup, VAT Posting Setup with Unrealized VAT Type First, Create and
        // Post Purchase Credit Memo.Take Random Quantity greater than 100 to avoid rounding issues.
        Initialize();
        LibraryERM.FindUnrealVATPostingSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::First);
        CreateAndUpdatePurchaseHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", CurrencyCode, VATPostingSetup."VAT Bus. Posting Group");
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group"),
          100 + LibraryRandom.RandDec(100, 2));
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        Amount := PurchaseLine.Quantity * PurchaseLine."Direct Unit Cost" * (1 + PurchaseLine."VAT %" / 100);

        // 2 is required for Partial Refund.
        CreateAndPostGeneralJournal(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, PurchaseHeader."Buy-from Vendor No.", CurrencyCode, -Amount / 2);
        ApplyAndPostVendorEntry(VendorLedgerEntry."Document Type"::Refund, GenJournalLine."Document No.", DocumentNo);

        // 2. Exercise: Again Create and Post General Journal Line with Document Type as Refund for Remaining Amount and Apply it on
        // Credit Memo.
        CreateAndPostGeneralJournal(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, PurchaseHeader."Buy-from Vendor No.", CurrencyCode,
          -(Amount - GenJournalLine.Amount));
        ApplyAndPostVendorEntry(VendorLedgerEntry."Document Type"::Refund, GenJournalLine."Document No.", DocumentNo);

        // 3. Verify: Verify Remaining Amount on Vendor Ledger Entry.
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::"Credit Memo", DocumentNo);
        VendorLedgerEntry.CalcFields("Remaining Amount");
        Assert.AreNearlyEqual(
          0, VendorLedgerEntry."Remaining Amount", LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(
            AmountError, VendorLedgerEntry.FieldCaption("Remaining Amount"),
            0, VendorLedgerEntry.TableCaption(), VendorLedgerEntry."Entry No."));
    end;

    local procedure PartialUnrealizedVATSales(var GenJournalLine: Record "Gen. Journal Line"; var SalesInvoiceHeader: Record "Sales Invoice Header"; VATPostingSetup: Record "VAT Posting Setup")
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        PostedDocumentNo: Code[20];
    begin
        // Setup: Update General Ledger Setup and VAT Setup, Create and Post Sales Invoice.
        CreateSalesInvoice(SalesHeader, VATPostingSetup);
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Exercise: Make Payment against Invoice and Apply the Payment over Invoice.
        CreateAndPostJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::Customer, SalesHeader."Sell-to Customer No.",
          -FindPostedSalesAmount(PostedDocumentNo), '');
        ApplyAndPostCustomerEntry(CustLedgerEntry."Document Type"::Payment, GenJournalLine."Document No.", PostedDocumentNo);
        SalesInvoiceHeader.Get(PostedDocumentNo);
    end;

    local procedure PartialUnrealizedVATPurchase(var GenJournalLine: Record "Gen. Journal Line"; var PurchInvHeader: Record "Purch. Inv. Header"; VATPostingSetup: Record "VAT Posting Setup"; CurrencyCode: Code[10])
    var
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PostedDocumentNo: Code[20];
    begin
        // Setup: Update General Ledger Setup and VAT Setup, Create and Post Purchase Invoice.
        CreatePurchaseInvoice(PurchaseHeader, VATPostingSetup, CurrencyCode);
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Exercise: Make Payment against Invoice and Apply the Payment over Invoice.
        CreateAndPostJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, PurchaseHeader."Buy-from Vendor No.",
          FindPostedPurchaseAmount(PostedDocumentNo), CurrencyCode);
        ApplyAndPostVendorEntry(VendorLedgerEntry."Document Type"::Payment, GenJournalLine."Document No.", PostedDocumentNo);
        PurchInvHeader.Get(PostedDocumentNo);
    end;

    local procedure HalfUnrealizedVATSales(var GenJournalLine: Record "Gen. Journal Line"; VATPostingSetup: Record "VAT Posting Setup"; UnrealizedVATType: Option)
    var
        SalesHeader: Record "Sales Header";
        GLAccount: Record "G/L Account";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        PostedDocumentNo: Code[20];
    begin
        // Setup: Update General Ledger Setup and VAT Setup, Create and Post Sales Invoice.
        LibraryERM.FindGLAccount(GLAccount);
        UpdateUnrealizedVATSetup(VATPostingSetup, UnrealizedVATType, GLAccount."No.", GLAccount."No.");
        CreateSalesInvoice(SalesHeader, VATPostingSetup);
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Exercise: Make Payment against Invoice and Apply the Payment over Invoice.
        CreateAndPostJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::Customer, SalesHeader."Sell-to Customer No.",
          -CalculateHalfSalesVATAmount(PostedDocumentNo), '');
        ApplyAndPostCustomerEntry(CustLedgerEntry."Document Type"::Payment, GenJournalLine."Document No.", PostedDocumentNo);
    end;

    local procedure HalfUnrealizedVATPurchase(var GenJournalLine: Record "Gen. Journal Line"; VATPostingSetup: Record "VAT Posting Setup")
    var
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PostedDocumentNo: Code[20];
    begin
        // Setup: Update General Ledger Setup and VAT Setup, Create and Post Purchase Invoice.
        CreatePurchaseInvoice(PurchaseHeader, VATPostingSetup, '');
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Exercise: Make Payment against Invoice and Apply the Payment over Invoice.
        CreateAndPostJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, PurchaseHeader."Buy-from Vendor No.",
          CalculateHalfPurchaseVATAmount(PostedDocumentNo), '');
        ApplyAndPostVendorEntry(VendorLedgerEntry."Document Type"::Payment, GenJournalLine."Document No.", PostedDocumentNo);
    end;

    local procedure ApplyCustomerLedgerEntries(CustomerNo: Code[20]; DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    var
        CustomerLedgerEntries: TestPage "Customer Ledger Entries";
    begin
        CustomerLedgerEntries.OpenView();
        CustomerLedgerEntries.FILTER.SetFilter("Customer No.", CustomerNo);
        CustomerLedgerEntries.FILTER.SetFilter("Document No.", DocumentNo);
        CustomerLedgerEntries.FILTER.SetFilter("Document Type", Format(DocumentType));
        CustomerLedgerEntries."Apply Entries".Invoke();
    end;

    local procedure ApplyVendorLedgerEntries(VendorNo: Code[20]; DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    var
        VendorLedgerEntries: TestPage "Vendor Ledger Entries";
    begin
        VendorLedgerEntries.OpenView();
        VendorLedgerEntries.FILTER.SetFilter("Vendor No.", VendorNo);
        VendorLedgerEntries.FILTER.SetFilter("Document No.", DocumentNo);
        VendorLedgerEntries.FILTER.SetFilter("Document Type", Format(DocumentType));
        VendorLedgerEntries.ActionApplyEntries.Invoke();
    end;

    local procedure ApplyAndPostCustomerEntry(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; DocumentNo2: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
    begin
        // Apply Payment Entry on Posted Invoice.
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocumentType, DocumentNo);
        CustLedgerEntry.CalcFields("Remaining Amount");
        LibraryERM.SetApplyCustomerEntry(CustLedgerEntry, CustLedgerEntry."Remaining Amount");

        // Set Applies-to ID.
        CustLedgerEntry2.SetRange("Document No.", DocumentNo2);
        CustLedgerEntry2.FindFirst();
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry2);

        // Post Application Entries.
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry);
    end;

    local procedure ApplyAndPostVendorEntry(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; DocumentNo2: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
    begin
        // Apply Payment Entry on Posted Invoice.
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, DocumentType, DocumentNo);
        VendorLedgerEntry.CalcFields("Remaining Amount");
        LibraryERM.SetApplyVendorEntry(VendorLedgerEntry, VendorLedgerEntry."Remaining Amount");

        // Set Applies-to ID.
        VendorLedgerEntry2.SetRange("Document No.", DocumentNo2);
        VendorLedgerEntry2.FindFirst();
        LibraryERM.SetAppliestoIdVendor(VendorLedgerEntry2);

        // Post Application Entries.
        LibraryERM.PostVendLedgerApplication(VendorLedgerEntry);
    end;

    local procedure CreateAndPostGeneralJournal(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; CurrencyCode: Code[10]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGeneralJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Refund,
          AccountType, AccountNo, Amount);

        GenJournalLine.Validate(
          "Document No.", LibraryUtility.GenerateRandomCode(GenJournalLine.FieldNo("Document No."), DATABASE::"Gen. Journal Line"));
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNo());
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure ApplyPostJournalLineCustomer(var GenJournalLine: Record "Gen. Journal Line"; CustomerNo: Code[20]; CurrencyCode: Code[10]; Amount: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CreateAndPostJournalLine(GenJournalLine, GenJournalLine."Account Type"::Customer, CustomerNo, Amount, CurrencyCode);
        ApplyCustomerLedgerEntries(CustomerNo, GenJournalLine."Document No.", CustLedgerEntry."Document Type"::Payment);
    end;

    local procedure ApplyPostJournalLineVendor(var GenJournalLine: Record "Gen. Journal Line"; VendorNo: Code[20]; CurrencyCode: Code[10]; Amount: Decimal)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        CreateAndPostJournalLine(GenJournalLine, GenJournalLine."Account Type"::Vendor, VendorNo, Amount, CurrencyCode);
        ApplyVendorLedgerEntries(VendorNo, GenJournalLine."Document No.", VendorLedgerEntry."Document Type"::Payment);
    end;

    local procedure CreateAndUpdatePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; CurrencyCode: Code[10]; VATBusPostingGroup: Code[20])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, CreateVendor(VATBusPostingGroup));
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Validate("Currency Code", CurrencyCode);
        PurchaseHeader.Modify(true);
    end;

    local procedure CreateGeneralJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Recurring, false);
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::General);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure CreateSalesInvoice(var SalesHeader: Record "Sales Header"; VATPostingSetup: Record "VAT Posting Setup")
    var
        SalesLine: Record "Sales Line";
    begin
        // Take Random Quantity greater than 100 to avoid rounding issues.
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomer(VATPostingSetup."VAT Bus. Posting Group"));
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group"),
          100 + LibraryRandom.RandDec(10, 2));
    end;

    local procedure CreatePurchaseInvoice(var PurchaseHeader: Record "Purchase Header"; VATPostingSetup: Record "VAT Posting Setup"; CurrencyCode: Code[10])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Create Purchase Invoice and update Currency Code on Purchase Header if option selected.
        // Take Random Quantity greater than 100 to avoid rounding issues.
        CreateAndUpdatePurchaseHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice, CurrencyCode, VATPostingSetup."VAT Bus. Posting Group");
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group"),
          100 + LibraryRandom.RandDec(10, 2));
    end;

    local procedure CreateAndPostJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal; CurrencyCode: Code[10])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        SelectGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
    begin
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.FindVATBusinessPostingGroup(VATBusinessPostingGroup);

        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup.Code, VATProductPostingGroup.Code);
        VATPostingSetup.Validate("VAT Identifier", VATPostingSetup."VAT Prod. Posting Group");
        VATPostingSetup.Validate("VAT %", LibraryRandom.RandDec(10, 2));
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.Validate("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::First);
        VATPostingSetup.Validate("Purchase VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("Purch. VAT Unreal. Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("Sales VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("Sales VAT Unreal. Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Modify(true);
    end;

    local procedure FindPostedSalesAmount(DocumentNo: Code[20]): Decimal
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        SalesInvoiceLine.SetRange("Document No.", DocumentNo);
        SalesInvoiceLine.FindFirst();

        // Return Payment Amount less than VAT Amount to use it as partial Amount.
        GeneralLedgerSetup.Get();
        exit(
          Round(
            (SalesInvoiceLine.Amount * SalesInvoiceLine."VAT %") - LibraryRandom.RandInt(5),
            GeneralLedgerSetup."Amount Rounding Precision") / 100);  // Need integer value to avoid rounding issue.
    end;

    local procedure CalculateHalfSalesVATAmount(DocumentNo: Code[20]): Decimal
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SalesInvoiceLine.SetRange("Document No.", DocumentNo);
        SalesInvoiceLine.FindFirst();

        // Return Payment Amount Half of the VAT Amount.
        exit((SalesInvoiceLine."Amount Including VAT" - SalesInvoiceLine.Amount) / 2);
    end;

    local procedure FindPostedPurchaseAmount(DocumentNo: Code[20]): Decimal
    var
        PurchInvLine: Record "Purch. Inv. Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        PurchInvLine.SetRange("Document No.", DocumentNo);
        PurchInvLine.FindFirst();

        // Return Payment Amount less than VAT Amount to use it as partial Amount.
        GeneralLedgerSetup.Get();
        exit(
          Round(
            (PurchInvLine.Amount * PurchInvLine."VAT %") - LibraryRandom.RandInt(5),
            GeneralLedgerSetup."Amount Rounding Precision") / 100);  // Need integer value to avoid rounding issue.
    end;

    local procedure FindSalesInvoiceLine(var SalesInvoiceLine: Record "Sales Invoice Line"; DocumentNo: Code[20])
    begin
        SalesInvoiceLine.SetRange("Document No.", DocumentNo);
        SalesInvoiceLine.FindFirst();
    end;

    local procedure FindPurchaseInvoiceLine(var PurchInvLine: Record "Purch. Inv. Line"; DocumentNo: Code[20])
    begin
        PurchInvLine.SetRange("Document No.", DocumentNo);
        PurchInvLine.FindFirst();
    end;

    local procedure FindGLEntry(var GLEntry: Record "G/L Entry"; DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("Document Type", DocumentType);
        GLEntry.FindFirst();
    end;

    local procedure CalculateHalfPurchaseVATAmount(DocumentNo: Code[20]): Decimal
    var
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        PurchInvLine.SetRange("Document No.", DocumentNo);
        PurchInvLine.FindFirst();

        // Return Payment Amount Half of the VAT Amount.
        exit((PurchInvLine."Amount Including VAT" - PurchInvLine.Amount) / 2);
    end;

    local procedure CreateItem(VATProdPostingGroup: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        Item.Validate("Unit Price", 1000 + LibraryRandom.RandDec(100, 2));  // Take Random Unit Price greater than 1000 to avoid rounding issues.
        Item.Validate("Last Direct Cost", Item."Unit Price");
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateCustomerApplyToOldest(VATBusPostingGroup: Code[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        Customer.Get(CreateCustomer(VATBusPostingGroup));
        Customer.Validate("Application Method", Customer."Application Method"::"Apply to Oldest");
        Customer.Modify(true);
        exit(Customer."No.");
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

    local procedure CreateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; VATPostingSetup: Record "VAT Posting Setup"; CustomerNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal)
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
          GenJournalLine."Account Type"::Customer, CustomerNo, Amount);
        GenJournalLine.Validate(
          "Bal. Account No.", LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GenJournalLine."Gen. Posting Type"::Sale));
        GenJournalLine.Modify(true);
    end;

    local procedure CreateVendor(VATBusPostingGroup: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        LibraryERM.FindGLAccount(GLAccount);
        Currency.Validate("Realized Gains Acc.", GLAccount."No.");
        Currency.Validate("Unrealized Gains Acc.", GLAccount."No.");
        Currency.Validate("Residual Gains Account", GLAccount."No.");
        Currency.Validate("Residual Losses Account", GLAccount."No.");
        Currency.Validate("Invoice Rounding Precision", LibraryERM.GetInvoiceRoundingPrecisionLCY());
        Currency.Modify(true);
        exit(Currency.Code);
    end;

    local procedure PostSalesInvoiceWithUnrealVAT(var VATPostingSetup: Record "VAT Posting Setup"): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateVATPostingSetup(VATPostingSetup);
        CreateSalesInvoice(SalesHeader, VATPostingSetup);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure PostPurchInvoiceWithUnrealVAT(var VATPostingSetup: Record "VAT Posting Setup"; CurrencyCode: Code[10]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreateVATPostingSetup(VATPostingSetup);
        CreatePurchaseInvoice(PurchaseHeader, VATPostingSetup, CurrencyCode);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure SelectGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
    end;

    local procedure UpdateGeneralLedgerSetup(CurrencyCode: Code[10]; UnrealizedVAT: Boolean)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // As there is no need to run Ajdust Add. Reporting Currency Batch Job so we are not validating Additional Reporting Currency field.
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Additional Reporting Currency" := CurrencyCode;
        GeneralLedgerSetup.Validate("Unrealized VAT", UnrealizedVAT);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdateUnrealizedVATSetup(VATPostingSetup: Record "VAT Posting Setup"; UnrealizedVATType: Option; SalesVATUnrealAccount: Code[20]; PurchVATUnrealAccount: Code[20])
    begin
        VATPostingSetup.Get(VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        VATPostingSetup.Validate("Unrealized VAT Type", UnrealizedVATType);
        VATPostingSetup.Validate("Sales VAT Unreal. Account", SalesVATUnrealAccount);
        VATPostingSetup.Validate("Purch. VAT Unreal. Account", PurchVATUnrealAccount);
        VATPostingSetup.Modify(true);
    end;

    local procedure UnrealizedVATDocument(VATPostingSetup: Record "VAT Posting Setup"; InvoiceAmount: Decimal; PaymentAmount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        CustomerNo: Code[20];
        VATAmount: Decimal;
        Amount: Decimal;
    begin
        // Check that correct Amount,VAT Amount, Additional-Currency AmouApplied after posting General Journal with Document Type
        // Invoice and making  partial Payment below VAT.

        // Setup: Update General Ledger Setup and VAT Posting Setup, Create General Journal Template and General Journal Batch.
        UpdateGeneralLedgerSetup(CreateCurrency(), true);

        SelectGenJournalBatch(GenJournalBatch);
        CustomerNo := CreateCustomerApplyToOldest(VATPostingSetup."VAT Bus. Posting Group");

        VATAmount := Round(PaymentAmount * VATPostingSetup."VAT %" / (100 + VATPostingSetup."VAT %"));
        Amount := Round(PaymentAmount - VATAmount);

        // Exercise: Make Payment against Invoice and Apply the Payment over Invoice.
        CreateGenJournalLine(
          GenJournalLine, GenJournalBatch, VATPostingSetup, CustomerNo, GenJournalLine."Document Type"::Invoice, InvoiceAmount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        CreateGenJournalLine(
          GenJournalLine, GenJournalBatch, VATPostingSetup, CustomerNo, GenJournalLine."Document Type"::Payment, PaymentAmount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify the Amount, VAT Amount and additional Currency Amount in G/L Entry and VAT Amount in VAT Entry.
        VerifyGLAndVATEntry(GenJournalLine, -Amount, -VATAmount);
    end;

    local procedure VerifyGLAndVATEntry(GenJournalLine: Record "Gen. Journal Line"; Amount: Decimal; VATAmount: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GLEntry: Record "G/L Entry";
        AdditionalCurrencyAmount: Decimal;
    begin
        GeneralLedgerSetup.Get();
        AdditionalCurrencyAmount :=
          Round(LibraryERM.ConvertCurrency(Amount, '', GeneralLedgerSetup."Additional Reporting Currency", WorkDate()));
        FindGLEntry(GLEntry, GenJournalLine."Document No.", GenJournalLine."Document Type"::Payment);

        Assert.AreNearlyEqual(
          Amount, GLEntry.Amount, GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(AmountError, GLEntry.FieldCaption(Amount), Amount, GLEntry.TableCaption(), GLEntry."Entry No."));
        Assert.AreNearlyEqual(
          VATAmount, GLEntry."VAT Amount", GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(AmountError, GLEntry.FieldCaption("VAT Amount"), VATAmount, GLEntry.TableCaption(), GLEntry."Entry No."));
        Assert.AreNearlyEqual(
          AdditionalCurrencyAmount, GLEntry."Additional-Currency Amount", GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(AmountError, GLEntry.FieldCaption("Additional-Currency Amount"), AdditionalCurrencyAmount,
            GLEntry.TableCaption(), GLEntry."Entry No."));

        VerifyVATEntry(GenJournalLine, '', VATAmount);
    end;

    local procedure VerifyGLEntryVATAmount(GenJournalLine: Record "Gen. Journal Line"; CurrencyCode: Code[10]; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        FindGLEntry(GLEntry, GenJournalLine."Document No.", GenJournalLine."Document Type"::Payment);
        Amount := LibraryERM.ConvertCurrency(Amount, CurrencyCode, '', WorkDate());
        Assert.AreNearlyEqual(
          Amount, GLEntry.Amount, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountError, GLEntry.Amount, Amount, GLEntry.TableCaption(), GLEntry."Entry No."));
    end;

    local procedure VerifyVATEntry(GenJournalLine: Record "Gen. Journal Line"; CurrencyCode: Code[10]; Amount: Decimal)
    var
        VATEntry: Record "VAT Entry";
        Currency: Record Currency;
    begin
        VATEntry.SetRange("Bill-to/Pay-to No.", GenJournalLine."Account No.");
        VATEntry.SetRange("Document No.", GenJournalLine."Document No.");
        VATEntry.SetRange("Document Type", GenJournalLine."Document Type");
        VATEntry.FindFirst();
        Currency.InitRoundingPrecision();
        if CurrencyCode <> '' then
            Amount := Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode, '', WorkDate()));
        Assert.AreNearlyEqual(
          Amount, VATEntry.Amount, Currency."Amount Rounding Precision",
          StrSubstNo(AmountError, VATEntry.Amount, Amount, VATEntry.TableCaption(), VATEntry."Entry No."));
    end;

    local procedure VerifyNoVATEntry(GenJournalLine: Record "Gen. Journal Line")
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Bill-to/Pay-to No.", GenJournalLine."Account No.");
        VATEntry.SetRange("Document No.", GenJournalLine."Document No.");
        VATEntry.SetRange("Document Type", GenJournalLine."Document Type");
        Assert.IsFalse(VATEntry.FindFirst(), 'VAT Entries must not exist.');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyCustomerEntriesHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    begin
        ApplyCustomerEntries."Set Applies-to ID".Invoke();
        ApplyCustomerEntries."Post Application".Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyVendorEntriesHandler(var ApplyVendorEntries: TestPage "Apply Vendor Entries")
    begin
        ApplyVendorEntries.ActionSetAppliesToID.Invoke();
        ApplyVendorEntries.ActionPostApplication.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostApplicationHandler(var PostApplication: TestPage "Post Application")
    begin
        PostApplication.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Message Handler.
    end;
}

