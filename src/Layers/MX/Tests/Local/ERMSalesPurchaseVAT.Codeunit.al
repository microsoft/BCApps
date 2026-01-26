codeunit 144051 "ERM Sales/Purchase VAT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [VAT]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        isInitialized: Boolean;
        AmountError: Label '%1 must be %2 in %3.';

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvWithoutCurr()
    begin
        // Verify VAT Entries and General Ledger Entries created from Purchase Invoice with out Currency.

        // Setup.
        Initialize();
        PurchInvSetup('');  // Blank value for Currency Code.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvUsingACY()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        CurrencyCode: Code[10];
    begin
        // Verify VAT Entries and General Ledger Entries created from Purchase Invoice using Additional Currency.

        // Setup: Update General Ledger Setup.
        Initialize();
        GeneralLedgerSetup.Get();
        CurrencyCode := CreateCurrencyACY();
        UpdateGeneralLedgerSetup(CurrencyCode, true);
        PurchInvSetup(CurrencyCode);

        // TearDown: Rollback General Ledger Setup.
        UpdateGeneralLedgerSetup(GeneralLedgerSetup."Additional Reporting Currency", GeneralLedgerSetup."Unrealized VAT");
    end;

    local procedure PurchInvSetup(CurrencyCode: Code[10])
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
        AmountACY: Decimal;
    begin
        // Setup: Create and post Purchase Invoice.
        DocumentNo := CreateAndPostPurchInv(PurchaseLine, CurrencyCode);

        // Exercise: Create and post Payment Journal.
        CreateAndPostGeneralJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Account Type"::Vendor,
          PurchaseLine."Buy-from Vendor No.", PurchaseLine."Amount Including VAT", DocumentNo);

        // Verify: Verify VAT Entries and General Ledger Entries.
        AmountACY := GetACYAmount(PurchaseLine."Amount Including VAT" - PurchaseLine."Line Amount", CurrencyCode);
        VATPostingSetup.Get(PurchaseLine."VAT Bus. Posting Group", PurchaseLine."VAT Prod. Posting Group");

        VerifyVATEntries(
          GenJournalLine."Document Type", GenJournalLine."Document No.", AmountACY, PurchaseLine."VAT Prod. Posting Group");
        VerifyGLEntries(GenJournalLine."Document Type", GenJournalLine."Document No.", VATPostingSetup."Purchase VAT Account", AmountACY);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnApplyPstdPurchInvWithoutCurr()
    begin
        // Verify VAT Entries and General Ledger Entries after Unapply Posted Purchase Invoice with out Currency.

        // Setup.
        Initialize();
        UnApplyPstdPurchInvSetup('');  // Blank value for Currency Code.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnApplyPstdPurchInvUsingACY()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        CurrencyCode: Code[10];
    begin
        // Verify VAT Entries and General Ledger Entries after Unapply Posted Purchase Invoice using Additional Currency.

        // Setup: Update General Ledger Setup.
        Initialize();
        GeneralLedgerSetup.Get();
        CurrencyCode := CreateCurrencyACY();
        UpdateGeneralLedgerSetup(CurrencyCode, true);
        UnApplyPstdPurchInvSetup(CurrencyCode);

        // TearDown: Rollback General Ledger Setup.
        UpdateGeneralLedgerSetup(GeneralLedgerSetup."Additional Reporting Currency", GeneralLedgerSetup."Unrealized VAT");
    end;

    local procedure UnApplyPstdPurchInvSetup(CurrencyCode: Code[10])
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
        AmountACY: Decimal;
    begin
        // Setup: Create and post Purchase Invoice. Create and post Payment Journal.
        DocumentNo := CreateAndPostPurchInv(PurchaseLine, CurrencyCode);
        CreateAndPostGeneralJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Account Type"::Vendor,
          PurchaseLine."Buy-from Vendor No.", PurchaseLine."Amount Including VAT", DocumentNo);

        // Exercise: Unapply Vendor Ledger Entries.
        UnApplyVendorLedgerEntries(GenJournalLine."Document Type", GenJournalLine."Document No.");

        // Verify: Verify VAT Entries and General Ledger Entries.
        AmountACY := GetACYAmount(PurchaseLine."Amount Including VAT" - PurchaseLine."Line Amount", CurrencyCode);
        VATPostingSetup.Get(PurchaseLine."VAT Bus. Posting Group", PurchaseLine."VAT Prod. Posting Group");
        VerifyVATEntries(
          GenJournalLine."Document Type", GenJournalLine."Document No.", AmountACY, PurchaseLine."VAT Prod. Posting Group");
        VerifyGLEntries(GenJournalLine."Document Type", GenJournalLine."Document No.", VATPostingSetup."Purchase VAT Account", AmountACY);
    end;

    [Test]
    [HandlerFunctions('PostedPurchaseDocumentLinePageHandler')]
    [Scope('OnPrem')]
    procedure PurchCrMemoWithoutCurr()
    begin
        // Verify VAT Entries and General Ledger Entries created from Purchase Credit Memo with out Currency.

        // Setup.
        Initialize();
        PurchCrMemoSetup('');  // Blank value for Currency Code.
    end;

    [Test]
    [HandlerFunctions('PostedPurchaseDocumentLinePageHandler')]
    [Scope('OnPrem')]
    procedure PurchCrMemoUsingACY()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        CurrencyCode: Code[10];
    begin
        // Verify VAT Entries and General Ledger Entries created from Purchase Credit Memo using Additional Currency.

        // Setup: Update General Ledger Setup.
        Initialize();
        GeneralLedgerSetup.Get();
        CurrencyCode := CreateCurrencyACY();
        UpdateGeneralLedgerSetup(CurrencyCode, true);
        PurchCrMemoSetup(CurrencyCode);

        // TearDown: Rollback General Ledger Setup.
        UpdateGeneralLedgerSetup(GeneralLedgerSetup."Additional Reporting Currency", GeneralLedgerSetup."Unrealized VAT");
    end;

    local procedure PurchCrMemoSetup(CurrencyCode: Code[10])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
        AmountACY: Decimal;
    begin
        // Setup: Create and post Purchase Invoice. Create Purchase Credit Memo with Reverse function.
        DocumentNo := CreateAndPostPurchInv(PurchaseLine, CurrencyCode);
        CreatePuchCreditMemoWithRevFunction(PurchaseHeader, PurchaseLine."Buy-from Vendor No.", DocumentNo);
        VATPostingSetup.Get(PurchaseLine."VAT Bus. Posting Group", PurchaseLine."VAT Prod. Posting Group");

        // Exercise: Post Purchase Credit Memo Lines using Get Posted Document Lines to Reverse function.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify VAT Entries and General Ledger Entries.
        AmountACY := GetACYAmount(PurchaseLine."Amount Including VAT" - PurchaseLine."Line Amount", CurrencyCode);
        VerifyVATEntries(PurchaseHeader."Document Type", DocumentNo, AmountACY, PurchaseLine."VAT Prod. Posting Group");
        VerifyGLEntries(PurchaseHeader."Document Type", DocumentNo, VATPostingSetup."Purchase VAT Account", AmountACY);
    end;

    [Test]
    [HandlerFunctions('PostedPurchaseDocumentLinePageHandler')]
    [Scope('OnPrem')]
    procedure UnApplyPstdPurchCrMemoWithoutCurr()
    begin
        // Verify VAT Entries and General Ledger Entries after Unapply Posted Purchase Credit Memo with out Currency.

        // Setup.
        Initialize();
        UnApplyPstdPurchCrMemoSetup('');  // Blank value for Currency Code.
    end;

    [Test]
    [HandlerFunctions('PostedPurchaseDocumentLinePageHandler')]
    [Scope('OnPrem')]
    procedure UnApplyPstdPurchCrMemoUsingACY()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        CurrencyCode: Code[10];
    begin
        // Verify VAT Entries and General Ledger Entries after Unapply Posted Purchase Credit Memo using Additional Currency.

        // Setup: Update General Ledger Setup.
        Initialize();
        GeneralLedgerSetup.Get();
        CurrencyCode := CreateCurrencyACY();
        UpdateGeneralLedgerSetup(CurrencyCode, true);
        UnApplyPstdPurchCrMemoSetup(CurrencyCode);

        // TearDown: Rollback General Ledger Setup.
        UpdateGeneralLedgerSetup(GeneralLedgerSetup."Additional Reporting Currency", GeneralLedgerSetup."Unrealized VAT");
    end;

    local procedure UnApplyPstdPurchCrMemoSetup(CurrencyCode: Code[10])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
        AmountACY: Decimal;
    begin
        // Setup: Create and post Purchase Invoice. Create and post Purchase Credit Memo with Reverse function.
        DocumentNo := CreateAndPostPurchInv(PurchaseLine, CurrencyCode);
        CreatePuchCreditMemoWithRevFunction(PurchaseHeader, PurchaseLine."Buy-from Vendor No.", DocumentNo);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Exercise: Unapply Vendor Ledger Entries.
        UnApplyVendorLedgerEntries(PurchaseHeader."Document Type", DocumentNo);

        // Verify: Verify VAT Entries and General Ledger Entries.
        AmountACY := GetACYAmount(PurchaseLine."Amount Including VAT" - PurchaseLine."Line Amount", CurrencyCode);
        VATPostingSetup.Get(PurchaseLine."VAT Bus. Posting Group", PurchaseLine."VAT Prod. Posting Group");
        VerifyVATEntries(PurchaseHeader."Document Type", DocumentNo, AmountACY, PurchaseLine."VAT Prod. Posting Group");
        VerifyGLEntries(PurchaseHeader."Document Type", DocumentNo, VATPostingSetup."Purchase VAT Account", AmountACY);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvWithoutCurr()
    begin
        // Verify VAT Entries and General Ledger Entries created from Sales Invoice with out Currency.

        // Setup.
        Initialize();
        SalesInvSetup('');  // Blank value for Currency Code.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvUsingACY()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        CurrencyCode: Code[10];
    begin
        // Verify VAT Entries and General Ledger Entries created from Sales Invoice using Additional Currency.

        // Setup: Update General Ledger Setup.
        Initialize();
        GeneralLedgerSetup.Get();
        CurrencyCode := CreateCurrencyACY();
        UpdateGeneralLedgerSetup(CurrencyCode, true);
        SalesInvSetup(CurrencyCode);

        // TearDown: Rollback General Ledger Setup.
        UpdateGeneralLedgerSetup(GeneralLedgerSetup."Additional Reporting Currency", GeneralLedgerSetup."Unrealized VAT");
    end;

    local procedure SalesInvSetup(CurrencyCode: Code[10])
    var
        GenJournalLine: Record "Gen. Journal Line";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
        AmountACY: Decimal;
    begin
        // Setup: Create and post Sales Invoice.
        DocumentNo := CreateAndPostSalesInv(SalesLine, CurrencyCode);

        // Exercise: Create and post Cash Receipt Journal.
        CreateAndPostGeneralJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Account Type"::Customer,
          SalesLine."Bill-to Customer No.", -SalesLine."Amount Including VAT", DocumentNo);

        // Verify: Verify VAT Entries and General Ledger Entries.
        AmountACY := GetACYAmount(SalesLine."Amount Including VAT" - SalesLine."Line Amount", CurrencyCode);
        VATPostingSetup.Get(SalesLine."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group");
        VerifyVATEntries(
          GenJournalLine."Document Type", GenJournalLine."Document No.", -AmountACY, SalesLine."VAT Prod. Posting Group");
        VerifyGLEntries(
          GenJournalLine."Document Type", GenJournalLine."Document No.", VATPostingSetup."Sales VAT Account", -AmountACY);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnApplyPstdSalesInvWithoutCurr()
    begin
        // Verify VAT Entries and General Ledger Entries after Unapply Posted Sales Invoice with out Currency.

        // Setup.
        Initialize();
        UnApplyPstdSalesInvSetup('');  // Blank value for Currency Code.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnApplyPstdSalesInvUsingACY()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        CurrencyCode: Code[10];
    begin
        // Verify VAT Entries and General Ledger Entries after Unapply Posted Sales Invoice using Additional Currency.

        // Setup: Update General Ledger Setup.
        Initialize();
        GeneralLedgerSetup.Get();
        CurrencyCode := CreateCurrencyACY();
        UpdateGeneralLedgerSetup(CurrencyCode, true);
        UnApplyPstdSalesInvSetup(CurrencyCode);

        // TearDown: Rollback General Ledger Setup.
        UpdateGeneralLedgerSetup(GeneralLedgerSetup."Additional Reporting Currency", GeneralLedgerSetup."Unrealized VAT");
    end;

    local procedure UnApplyPstdSalesInvSetup(CurrencyCode: Code[10])
    var
        GenJournalLine: Record "Gen. Journal Line";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
        AmountACY: Decimal;
    begin
        // Setup: Create and post Sales Invoice. Create and post Case Receipt Journal.
        DocumentNo := CreateAndPostSalesInv(SalesLine, CurrencyCode);
        CreateAndPostGeneralJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Account Type"::Customer,
          SalesLine."Sell-to Customer No.", -SalesLine."Amount Including VAT", DocumentNo);

        // Exercise: Unapply Customer Ledger Entries.
        UnApplyCustomerLedgerEntries(GenJournalLine."Document Type", GenJournalLine."Document No.");

        // Verify: Verify VAT Entries and General Ledger Entries.
        AmountACY := GetACYAmount(SalesLine."Amount Including VAT" - SalesLine."Line Amount", CurrencyCode);
        VATPostingSetup.Get(SalesLine."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group");
        VerifyVATEntries(
          GenJournalLine."Document Type", GenJournalLine."Document No.", -AmountACY, SalesLine."VAT Prod. Posting Group");
        VerifyGLEntries(
          GenJournalLine."Document Type", GenJournalLine."Document No.", VATPostingSetup."Sales VAT Account", -AmountACY);
    end;

    [Test]
    [HandlerFunctions('PostedSalesDocumentLinesPageHandler')]
    [Scope('OnPrem')]
    procedure SalesCrMemoWithoutCurr()
    begin
        // Verify VAT Entries and General Ledger Entries created from Sales Credit Memo with out Currency.

        // Setup.
        Initialize();
        SalesCrMemoSetup('');  // Blank value for Currency Code.
    end;

    [Test]
    [HandlerFunctions('PostedSalesDocumentLinesPageHandler')]
    [Scope('OnPrem')]
    procedure SalesCrMemoUsingACY()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        CurrencyCode: Code[10];
    begin
        // Verify VAT Entries and General Ledger Entries created from Purchase Credit Memo using Additional Currency.

        // Setup: Update General Ledger Setup.
        Initialize();
        GeneralLedgerSetup.Get();
        CurrencyCode := CreateCurrencyACY();
        UpdateGeneralLedgerSetup(CurrencyCode, true);
        SalesCrMemoSetup(CurrencyCode);

        // TearDown: Rollback General Ledger Setup.
        UpdateGeneralLedgerSetup(GeneralLedgerSetup."Additional Reporting Currency", GeneralLedgerSetup."Unrealized VAT");
    end;

    local procedure SalesCrMemoSetup(CurrencyCode: Code[10])
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
        AmountACY: Decimal;
    begin
        // Setup: Create and post Sales Invoice. Create Sales Credit Memo with Reverse function.
        DocumentNo := CreateAndPostSalesInv(SalesLine, CurrencyCode);
        CreateSalesCreditMemoWithRevFunction(SalesHeader, SalesLine."Sell-to Customer No.", DocumentNo);

        // Exercise: Post Purchase Credit Memo Lines using Get Posted Document Lines to Reverse function.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify VAT Entries and General Ledger Entries.
        AmountACY := GetACYAmount(SalesLine."Amount Including VAT" - SalesLine."Line Amount", CurrencyCode);
        VATPostingSetup.Get(SalesLine."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group");
        VerifyVATEntries(SalesHeader."Document Type", DocumentNo, -AmountACY, SalesLine."VAT Prod. Posting Group");
        VerifyGLEntries(SalesHeader."Document Type", DocumentNo, VATPostingSetup."Sales VAT Account", -AmountACY);
    end;

    [Test]
    [HandlerFunctions('PostedSalesDocumentLinesPageHandler')]
    [Scope('OnPrem')]
    procedure UnApplyPstdSalesCrMemoWithoutCurr()
    begin
        // Verify VAT Entries and General Ledger Entries after Unapply Posted Sales Credit Memo with out Currency.

        // Setup.
        Initialize();
        UnApplyPstdSalesCrMemoSetup('');  // Blank value for Currency Code.
    end;

    [Test]
    [HandlerFunctions('PostedSalesDocumentLinesPageHandler')]
    [Scope('OnPrem')]
    procedure UnApplyPstdSalesCrMemoUsingACY()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        CurrencyCode: Code[10];
    begin
        // Verify VAT Entries and General Ledger Entries after Unapply Posted Sales Credit Memo using Additional Currency.

        // Setup: Update General Ledger Setup.
        Initialize();
        CurrencyCode := CreateCurrencyACY();
        GeneralLedgerSetup.Get();
        UpdateGeneralLedgerSetup(CurrencyCode, true);
        UnApplyPstdSalesCrMemoSetup(CurrencyCode);

        // TearDown: Rollback General Ledger Setup.
        UpdateGeneralLedgerSetup(GeneralLedgerSetup."Additional Reporting Currency", GeneralLedgerSetup."Unrealized VAT");
    end;

    local procedure UnApplyPstdSalesCrMemoSetup(CurrencyCode: Code[10])
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
        AmountACY: Decimal;
    begin
        // Setup: Create and post Sales Invoice. Create and post Sales Credit Memo with Reverse function.
        DocumentNo := CreateAndPostSalesInv(SalesLine, CurrencyCode);
        CreateSalesCreditMemoWithRevFunction(SalesHeader, SalesLine."Sell-to Customer No.", DocumentNo);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Exercise: Unapply Customer Ledger Entries.
        UnApplyCustomerLedgerEntries(SalesHeader."Document Type", DocumentNo);

        // Verify: Verify VAT Entries and General Ledger Entries.
        AmountACY := GetACYAmount(SalesLine."Amount Including VAT" - SalesLine."Line Amount", CurrencyCode);
        VATPostingSetup.Get(SalesLine."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group");
        VerifyVATEntries(SalesHeader."Document Type", DocumentNo, -AmountACY, SalesLine."VAT Prod. Posting Group");
        VerifyGLEntries(SalesHeader."Document Type", DocumentNo, VATPostingSetup."Sales VAT Account", -AmountACY);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartialApplyPstdSalesInvWithMultiplePayment()
    var
        GLEntry: Record "G/L Entry";
        SalesLine: Record "Sales Line";
        TotalVATAmount: Decimal;
        TotalVATAmount2: Decimal;
    begin
        // Verify General Ledger Entries after partial apply Posted Sales Invoice with Multiple Payment.

        // Setup.
        Initialize();

        // Exercise: Create multiple Payment and apply Customer Ledger Entries.
        ApplySalesInvWithPartialPayment(SalesLine, TotalVATAmount, TotalVATAmount2, CreateAndPostSalesInv(SalesLine, ''));

        // Verify: Verify General Ledger Entries Amount for Sales VAT Unreal. Account.
        Assert.AreEqual(TotalVATAmount, TotalVATAmount2,
          StrSubstNo(AmountError, GLEntry.FieldCaption(Amount), TotalVATAmount2, GLEntry.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FullyApplyPstdSalesInvWithMultiplePayment()
    var
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
        TotalVATAmount: Decimal;
        TotalVATAmount2: Decimal;
        RemainigAmount: Decimal;
        PaymentAmount: Decimal;
    begin
        // Verify General Ledger Entries after fully apply Posted Sales Invoice with Multiple Payment.

        // Setup.
        Initialize();
        DocumentNo := CreateAndPostSalesInv(SalesLine, '');
        VATPostingSetup.Get(SalesLine."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group");

        // Exercise: Create multiple Payment and fully apply Customer Ledger Entries.
        PaymentAmount := ApplySalesInvWithPartialPayment(SalesLine, TotalVATAmount, TotalVATAmount2, DocumentNo);
        RemainigAmount := SalesLine."Amount Including VAT" - PaymentAmount;
        TotalVATAmount +=
          TotalVATAmount2 + CreateAndApplyPaymentForCustomer(RemainigAmount, SalesLine."Sell-to Customer No.", DocumentNo);

        // Verify: Verify General Ledger Entries for Sales VAT Unreal. Account.
        VerifyGLEntryVATUnrealizedAmount(DocumentNo, VATPostingSetup."Sales VAT Unreal. Account", TotalVATAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartialApplyPstdPurchInvWithMultiplePayment()
    var
        GLEntry: Record "G/L Entry";
        PurchaseLine: Record "Purchase Line";
        TotalVATAmount: Decimal;
        TotalVATAmount2: Decimal;
    begin
        // Verify General Ledger Entries after partial apply Posted Purchase Invoice with Multiple Payment.

        // Setup.
        Initialize();

        // Exercise: Create multiple Payment and apply Vendor Ledger Entries.
        ApplyPurchaseInvWithPartialPayment(
          PurchaseLine, TotalVATAmount, TotalVATAmount2, CreateAndPostPurchInv(PurchaseLine, ''));

        // Verify: Verify General Ledger Entries Amount for Purch. VAT Unreal. Account.
        Assert.AreEqual(TotalVATAmount, TotalVATAmount2,
          StrSubstNo(AmountError, GLEntry.FieldCaption(Amount), TotalVATAmount2, GLEntry.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FullyApplyPstdPurchInvWithMultiplePayment()
    var
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
        TotalVATAmount: Decimal;
        TotalVATAmount2: Decimal;
        RemainigAmount: Decimal;
        PaymentAmount: Decimal;
    begin
        // Verify General Ledger Entries after fully apply Posted Purchase Invoice with Multiple Payment.

        // Setup.
        Initialize();
        DocumentNo := CreateAndPostPurchInv(PurchaseLine, '');
        VATPostingSetup.Get(PurchaseLine."VAT Bus. Posting Group", PurchaseLine."VAT Prod. Posting Group");

        // Exercise: Create multiple Payment and fully apply Vendor Ledger Entries.
        PaymentAmount := ApplyPurchaseInvWithPartialPayment(PurchaseLine, TotalVATAmount, TotalVATAmount2, DocumentNo);
        RemainigAmount := PurchaseLine."Amount Including VAT" - PaymentAmount;
        TotalVATAmount +=
          TotalVATAmount2 + CreateAndApplyPaymentForVendor(-RemainigAmount, PurchaseLine."Buy-from Vendor No.", DocumentNo);

        // Verify: Verify General Ledger Entries for Purch. VAT Unreal. Account.
        VerifyGLEntryVATUnrealizedAmount(DocumentNo, VATPostingSetup."Purch. VAT Unreal. Account", TotalVATAmount);
    end;

    local procedure Initialize()
    var
        InventorySetup: Record "Inventory Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        if isInitialized then
            exit;
        LibraryERMCountryData.CreateVATData();
        LibraryInventory.NoSeriesSetup(InventorySetup);
        isInitialized := true;
    end;

    local procedure CreateAndPostGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal; AppliesToDocNo: Code[20])
    var
        BankAccount: Record "Bank Account";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.FindGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
          AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Bal. Account No.", BankAccount."No.");
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", AppliesToDocNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndPostPurchInv(var PurchaseLine: Record "Purchase Line"; CurrencyCode: Code[10]) DocumentNo: Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindUnrealVATPostingSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::"Cash Basis");
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice, CreateVendor(VATPostingSetup."VAT Bus. Posting Group", CurrencyCode));
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group"),
          LibraryRandom.RandDec(10, 2)); // Random value use for Quantity.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));  // Random value for Direct Unit Cost.
        PurchaseLine.Modify(true);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreateAndPostSalesInv(var SalesLine: Record "Sales Line"; CurrencyCode: Code[10]) DocumentNo: Code[20]
    var
        SalesHeader: Record "Sales Header";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindUnrealVATPostingSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::"Cash Basis");
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomer(VATPostingSetup."VAT Bus. Posting Group", CurrencyCode));
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group"),
          LibraryRandom.RandDec(10, 2)); // Random value use for Quantity.
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));  // Random value for Direct Unit Price.
        SalesLine.Modify(true);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreatePuchCreditMemoWithRevFunction(var PurchaseHeader: Record "Purchase Header"; BuyFromVendorNo: Code[20]; AppliesToDocNo: Code[20])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", BuyFromVendorNo);
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Validate("Applies-to Doc. Type", PurchaseHeader."Applies-to Doc. Type"::Invoice);
        PurchaseHeader.Validate("Applies-to Doc. No.", AppliesToDocNo);
        PurchaseHeader.Modify(true);
        PurchaseHeader.GetPstdDocLinesToReverse();
    end;

    local procedure CreateSalesCreditMemoWithRevFunction(var SalesHeader: Record "Sales Header"; SellToCustomerNo: Code[20]; AppliesToDocNo: Code[20])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", SellToCustomerNo);
        SalesHeader.Validate("External Document No.", SalesHeader."No.");
        SalesHeader.Validate("Applies-to Doc. Type", SalesHeader."Applies-to Doc. Type"::Invoice);
        SalesHeader.Validate("Applies-to Doc. No.", AppliesToDocNo);
        SalesHeader.Modify(true);
        SalesHeader.GetPstdDocLinesToReverse();
    end;

    local procedure CreateCurrencyACY(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        LibraryERM.SetCurrencyGainLossAccounts(Currency);
        Currency.Validate("Residual Gains Account", Currency."Realized Gains Acc.");
        Currency.Validate("Residual Losses Account", Currency."Realized Losses Acc.");
        Currency.Modify(true);
        exit(Currency.Code);
    end;

    local procedure CreateCustomer(VATBusPostingGroup: Code[20]; CurrencyCode: Code[10]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Customer.Validate("Currency Code", CurrencyCode);
        Customer.Modify(true);
        exit(Customer."No.");
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

    local procedure CreateVendor(VATBusPostingGroup: Code[20]; CurrencyCode: Code[10]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Vendor.Validate("Currency Code", CurrencyCode);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateAndApplyPaymentForCustomer(PaymentAmount: Decimal; AccountNo: Code[20]; DocumentNo: Code[20]): Decimal
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateAndPostGeneralJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer, AccountNo, -PaymentAmount,
          DocumentNo);
        exit(GetVATAmount(GenJournalLine."Document No."));
    end;

    local procedure CreateAndApplyPaymentForVendor(PaymentAmount: Decimal; AccountNo: Code[20]; DocumentNo: Code[20]): Decimal
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateAndPostGeneralJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, AccountNo, -PaymentAmount,
          DocumentNo);
        exit(GetVATAmount(GenJournalLine."Document No."));
    end;

    local procedure GetVATAmount(DocumentNo: Code[20]): Decimal
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Payment);
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.SetFilter(Base, '<>0');
        VATEntry.FindFirst();
        exit(VATEntry.Amount);
    end;

    local procedure GetGLEntryAmount(DocumentNo: Code[20]; SalesVATUnrealAccount: Code[20]): Decimal
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", SalesVATUnrealAccount);
        GLEntry.FindFirst();
        exit(GLEntry.Amount);
    end;

    local procedure GetACYAmount(Amount: Decimal; CurrencyCode: Code[10]): Decimal
    begin
        if CurrencyCode <> '' then  // Blank value for Currency Code.
            exit(Amount);
        exit(0);
    end;

    local procedure UnApplyCustomerLedgerEntries(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    var
        CustomerLedgerEntry: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustomerLedgerEntry, DocumentType, DocumentNo);
        LibraryERM.UnapplyCustomerLedgerEntry(CustomerLedgerEntry);
    end;

    local procedure UnApplyVendorLedgerEntries(DocumentType: Enum "Purchase Document Type"; DocumentNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, DocumentType, DocumentNo);
        LibraryERM.UnapplyVendorLedgerEntry(VendorLedgerEntry);
    end;

    local procedure UpdateGeneralLedgerSetup(AdditionalReportingCurrency: Code[10]; UnrealizedVAT: Boolean)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Additional Reporting Currency" := AdditionalReportingCurrency;
        GeneralLedgerSetup.Validate("Unrealized VAT", UnrealizedVAT);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure ApplySalesInvWithPartialPayment(SalesLine: Record "Sales Line"; var TotalVATAmount: Decimal; var TotalVATAmount2: Decimal; DocumentNo: Code[20]): Decimal
    var
        PaymentAmount: Decimal;
    begin
        PaymentAmount := Round(SalesLine."Amount Including VAT" / LibraryRandom.RandIntInRange(3, 5));
        TotalVATAmount := CreateAndApplyPaymentForCustomer(PaymentAmount, SalesLine."Sell-to Customer No.", DocumentNo);
        TotalVATAmount2 := CreateAndApplyPaymentForCustomer(PaymentAmount, SalesLine."Sell-to Customer No.", DocumentNo);
        exit(PaymentAmount * 2);
    end;

    local procedure ApplyPurchaseInvWithPartialPayment(PurchaseLine: Record "Purchase Line"; var TotalVATAmount: Decimal; var TotalVATAmount2: Decimal; DocumentNo: Code[20]): Decimal
    var
        PaymentAmount: Decimal;
    begin
        PaymentAmount := Round(PurchaseLine."Amount Including VAT" / LibraryRandom.RandIntInRange(3, 5));
        TotalVATAmount := CreateAndApplyPaymentForVendor(-PaymentAmount, PurchaseLine."Buy-from Vendor No.", DocumentNo);
        TotalVATAmount2 := CreateAndApplyPaymentForVendor(-PaymentAmount, PurchaseLine."Buy-from Vendor No.", DocumentNo);
        exit(PaymentAmount * 2);
    end;

    local procedure VerifyVATEntries(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; AdditionalCurrencyAmount: Decimal; VATProdPostingGroup: Code[20])
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document Type", DocumentType);
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.SetRange("VAT Prod. Posting Group", VATProdPostingGroup);
        VATEntry.SetFilter(Base, '<>0');
        VATEntry.FindFirst();
        Assert.AreNearlyEqual(
          AdditionalCurrencyAmount, VATEntry."Additional-Currency Amount", LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(
            AmountError, VATEntry.FieldCaption("Additional-Currency Amount"), VATEntry."Additional-Currency Amount", VATEntry.TableCaption()));
    end;

    local procedure VerifyGLEntries(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; GLAccountNo: Code[20]; AdditionalCurrencyAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document Type", DocumentType);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindFirst();
        Assert.AreNearlyEqual(
          AdditionalCurrencyAmount, GLEntry."Additional-Currency Amount", LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(
            AmountError, GLEntry.FieldCaption("Additional-Currency Amount"), GLEntry."Additional-Currency Amount", GLEntry.TableCaption()));
    end;

    local procedure VerifyGLEntryVATUnrealizedAmount(DocumentNo: Code[20]; VATUnrealAccount: Code[20]; TotalVATAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
        SalesVATUnrealAmount: Decimal;
    begin
        SalesVATUnrealAmount := GetGLEntryAmount(DocumentNo, VATUnrealAccount);
        Assert.AreEqual(SalesVATUnrealAmount, TotalVATAmount,
          StrSubstNo(AmountError, GLEntry.FieldCaption(Amount), TotalVATAmount, GLEntry.TableCaption()));
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchaseDocumentLinePageHandler(var PostedPurchaseDocumentLines: TestPage "Posted Purchase Document Lines")
    begin
        PostedPurchaseDocumentLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesDocumentLinesPageHandler(var PostedSalesDocumentLines: TestPage "Posted Sales Document Lines")
    begin
        PostedSalesDocumentLines.OK().Invoke();
    end;
}

