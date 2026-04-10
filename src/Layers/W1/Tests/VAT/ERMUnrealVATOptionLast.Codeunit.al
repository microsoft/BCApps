codeunit 134015 "ERM Unreal VAT Option Last"
{
    Permissions = TableData "Cust. Ledger Entry" = rimd;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Unrealized VAT] [Last (Fully Paid)]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryPmtDiscSetup: Codeunit "Library - Pmt Disc Setup";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        AmountError: Label '%1 not updated correctly in %2, %3: %4.';
        CumulativeVATAmount: Label 'CumulativeVATAmount must be equal to %1';

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Unreal VAT Option Last");
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Unreal VAT Option Last");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERM.SetUnrealizedVAT(true);

        IsInitialized := true;
        Commit();
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Unreal VAT Option Last");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartialVATLastSales()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        // Check the Partial VAT Amount Applied after posting Sales Credit Memo and making Refund against it.

        // Create Sales Credit Memo and make Refund against it. Apply the Refund over Credit Memo.
        Initialize();
        LibraryERM.FindUnrealVATPostingSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::Last);
        UnrealizedVATSalesCrMemo(GenJournalLine, SalesCrMemoLine, VATPostingSetup);

        // Verify: Verify that correct VAT Amount Applied in VAT Entry.
        VerifyVATEntry(GenJournalLine, GenJournalLine.Amount - SalesCrMemoLine.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RemainingVATLastSales()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        // Check the Remaining VAT Amount Applied after posting Sales Credit Memo and making Refund twice against it.

        // Create Sales Credit Memo and make Refund against it. Apply the Refund over Credit Memo.
        Initialize();
        LibraryERM.FindUnrealVATPostingSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::Last);
        UnrealizedVATSalesCrMemo(GenJournalLine, SalesCrMemoLine, VATPostingSetup);

        // Make Refund again for the Credit Memo and then Apply Refund over Credit Memo.
        CreateAndPostJournalLine(GenJournalLine, GenJournalLine."Account Type"::Customer, GenJournalLine."Document Type"::Refund,
          SalesCrMemoLine."Sell-to Customer No.", GenJournalLine.Amount);
        ApplyAndPostCustomerEntry(GenJournalLine."Document Type"::Refund, SalesCrMemoLine."Document No.", GenJournalLine."Document No.");

        // Verify: Verify VAT Entries for Amount.
        VerifyVATEntry(GenJournalLine, (SalesCrMemoLine."Amount Including VAT" - GenJournalLine.Amount));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartialVATLastPurchase()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
    begin
        // Check the Partial VAT Amount Applied after posting Purchase Credit Memo and making Refund against it.

        // Create Purchase Credit Memo and make Refund against it. Apply the Refund over Credit Memo.
        Initialize();

        LibraryERM.FindUnrealVATPostingSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::Last);
        UnrealizedVATPurchaseCrMemo(GenJournalLine, PurchCrMemoLine, VATPostingSetup);

        // Verify: Verify that correct VAT Amount Applied in VAT Entry.
        VerifyVATEntry(GenJournalLine, GenJournalLine.Amount + PurchCrMemoLine.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RemainingVATLastPurchase()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
    begin
        // Check the Remaining VAT Amount Applied after posting Purchase Credit Memo and making Refund twice against it.

        // Create Purchase Credit Memo and make Refund against it. Apply the Refund over Credit Memo.
        Initialize();

        LibraryERM.FindUnrealVATPostingSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::Last);
        UnrealizedVATPurchaseCrMemo(GenJournalLine, PurchCrMemoLine, VATPostingSetup);

        // Make Refund again for the Purchase Credit Memo and then Apply Refund over Credit Memo.
        CreateAndPostJournalLine(GenJournalLine, GenJournalLine."Account Type"::Vendor, GenJournalLine."Document Type"::Refund,
          PurchCrMemoLine."Buy-from Vendor No.", GenJournalLine.Amount);
        ApplyAndPostVendorEntry(GenJournalLine."Document Type"::Refund, PurchCrMemoLine."Document No.", GenJournalLine."Document No.");

        // Verify: Verify VAT Entries for Amount.
        VerifyVATEntry(GenJournalLine, -(PurchCrMemoLine."Amount Including VAT" + GenJournalLine.Amount));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoVATLastFullyPaidSales()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        // Check that no VAT Amount Applied after posting Sales Invoice and making Payment against it.

        // Create Sales Invoice and make Payment against it. Apply the Payment over Invoice.
        Initialize();
        LibraryERM.FindUnrealVATPostingSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::"Last (Fully Paid)");
        UnrealizedVATSalesInvoice(GenJournalLine, SalesInvoiceLine, VATPostingSetup);

        // Verify: Verify that correct VAT Amount Applied in VAT Entry.
        VerifyNoVATEntry(GenJournalLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FullVATLastFullyPaidSales()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        // Check that Full VAT Amount Applied after posting Sales Invoice and making Payment twice against it.

        // Create Sales Invoice and make Payment against it. Apply the Payment over Invoice.
        Initialize();
        LibraryERM.FindUnrealVATPostingSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::"Last (Fully Paid)");
        UnrealizedVATSalesInvoice(GenJournalLine, SalesInvoiceLine, VATPostingSetup);

        // Make Payment again for the Sales Invoice and then Apply Payment over Invoice.
        CreateAndPostJournalLine(GenJournalLine, GenJournalLine."Account Type"::Customer, GenJournalLine."Document Type"::Payment,
          SalesInvoiceLine."Sell-to Customer No.", GenJournalLine.Amount);
        ApplyAndPostCustomerEntry(GenJournalLine."Document Type"::Payment, SalesInvoiceLine."Document No.", GenJournalLine."Document No.");

        // Verify: Verify VAT Entries for Amount.
        VerifyVATEntry(GenJournalLine, -(SalesInvoiceLine."Amount Including VAT" - SalesInvoiceLine.Amount));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoVATLastFullyPaidPurchase()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        // Check that no VAT Amount Applied after posting Purchase Invoice and making Payment against it.

        // Create Purchase Invoice and make Payment against it. Apply the Payment over Invoice.
        Initialize();

        LibraryERM.FindUnrealVATPostingSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::"Last (Fully Paid)");
        UnrealizedVATPurchaseInvoice(GenJournalLine, PurchInvLine, VATPostingSetup);

        // Verify: Verify that no VAT Amount Applied in VAT Entry.
        VerifyNoVATEntry(GenJournalLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FullVATLastFullyPaidPurchase()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        // Covers Test Case: 125641, 125642.
        // Check that Full VAT Amount Applied after posting Purchase Invoice and making Payment twice against it.

        // Create Purchase Invoice and make Payment against it. Apply the Payment over Invoice.
        Initialize();
        LibraryERM.FindUnrealVATPostingSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::"Last (Fully Paid)");
        UnrealizedVATPurchaseInvoice(GenJournalLine, PurchInvLine, VATPostingSetup);

        // Make Payment again for the Purchase Invoice and then Apply Payment over Invoice.
        CreateAndPostJournalLine(GenJournalLine, GenJournalLine."Account Type"::Vendor, GenJournalLine."Document Type"::Payment,
          PurchInvLine."Buy-from Vendor No.", GenJournalLine.Amount);
        ApplyAndPostVendorEntry(GenJournalLine."Document Type"::Payment, PurchInvLine."Document No.", GenJournalLine."Document No.");

        // Verify: Verify the VAT Entries for Amount.
        VerifyVATEntry(GenJournalLine, PurchInvLine."Amount Including VAT" - PurchInvLine.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartialPaymentLastFully()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        PaymentAmount: Decimal;
        InvoiceAmount: Decimal;
    begin
        // Check that no VAT Amount applied in VAT Entry after Posting General Journal Line with Document Type Invoice and
        // making Partial Payment for Customer with Unrealized VAT Type - Last (Fully Paid).

        // Create General Journal Line with document type Invoice and making partial payment against it.
        Initialize();

        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        InvoiceAmount := LibraryRandom.RandDec(1000, 2);  // Use Random Number Generator for Amount.
        PaymentAmount := InvoiceAmount * VATPostingSetup."VAT %" / (100 + VATPostingSetup."VAT %");
        SetupAndCreateGenJournalLine(GenJournalLine, VATPostingSetup, InvoiceAmount, PaymentAmount);

        // Verify: Verify that no VAT Amount Applied in VAT Entry.
        VerifyNoVATEntry(GenJournalLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OverVATPaymentLastFully()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        PaymentAmount: Decimal;
        InvoiceAmount: Decimal;
        VATAmount: Decimal;
    begin
        // Check that correct VAT Amount applied in VAT Entry after Posting General Journal Line with Document Type Invoice
        // making Payment for Customer with Unrealized VAT Type - Last (Fully Paid).

        // Create General Journal Line with document type Invoice and making partial Over Vat payment against it.
        Initialize();
        LibraryERM.FindUnrealVATPostingSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::"Last (Fully Paid)");
        InvoiceAmount := 100 + LibraryRandom.RandDec(1000, 2);  // Use Random Number Generator for Amount.
        VATAmount := Round(InvoiceAmount * VATPostingSetup."VAT %") / (100 + VATPostingSetup."VAT %");
        PaymentAmount := VATAmount + InvoiceAmount + LibraryRandom.RandDec(10, 2);
        SetupAndCreateGenJournalLine(GenJournalLine, VATPostingSetup, InvoiceAmount, PaymentAmount);

        // Verify: Verify that correct VAT Amount Applied in VAT Entry.
        VerifyVATEntry(GenJournalLine, -VATAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ClosePaymentUnrealVATLast()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        VATPostingSetup: Record "VAT Posting Setup";
        GLEntry: Record "G/L Entry";
        PostedDocumentNo: Code[20];
        CustomerNo: Code[20];
        InvoiceAmount: Decimal;
        PaymentAmount: Decimal;
        CummulativeVATAmount: Decimal;
        DiscountAmount: Decimal;
    begin
        // Check that correct Amount applied in Customer Ledger Entry and G/L Entry and VAT Amount in VAT Entry after Posting General
        // Journal Line with Document Type Invoice and making Full Payment for Customer with Unrealized VAT Type - Last.

        // Setup: Update General Ledger and VAT Setup, and Create and post a General Journal Line.
        Initialize();

        LibraryERM.FindUnrealVATPostingSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::Last);
        LibraryERM.SetAddReportingCurrency(CreateCurrency());
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(true);
        UpdateVATPostingSetup(VATPostingSetup, true);
        CustomerNo := CreateCustomerPaymentTermCode(PaymentTerms, VATPostingSetup."VAT Bus. Posting Group");
        InvoiceAmount := LibraryRandom.RandDec(1000, 2);  // Use Random Number Generator for Amount.
        DiscountAmount := Round(InvoiceAmount * PaymentTerms."Discount %" / 100);
        PaymentAmount := InvoiceAmount - DiscountAmount;
        CummulativeVATAmount :=
          DiscountAmount * VATPostingSetup."VAT %" / (100 + VATPostingSetup."VAT %") -
          InvoiceAmount * VATPostingSetup."VAT %" / (100 + VATPostingSetup."VAT %");
        SelectGenJournalBatch(GenJournalBatch);
        CreateGenJournalLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Account Type"::Customer, CustomerNo,
          GenJournalLine."Document Type"::Invoice, InvoiceAmount);
        GenJournalLine.Validate("Bal. Account No.", FindGLAccountWithVAT(VATPostingSetup));
        GenJournalLine.Modify(true);
        UpdateGeneralPostingSetup(GenJournalLine."Bal. Gen. Bus. Posting Group", GenJournalLine."Bal. Gen. Prod. Posting Group");
        PostedDocumentNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Exercise: Making payment against the invoice.
        CreateGenJournalLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Account Type"::Customer, CustomerNo,
          GenJournalLine."Document Type"::Payment, -PaymentAmount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify that correct Amount, Amount(LCY), Remaining Amount, Remaining Amount(LCY) in Customer Ledger Entry, correct
        // VAT Amount Applied in VAT Entry and correct Amount is posted in G/L Entry.
        VerifyCustomerLedgerEntry(PostedDocumentNo, GenJournalLine."Document Type"::Invoice, InvoiceAmount, 0);
        VerifyGLEntry(
          GLEntry, GenJournalLine."Document No.", GLEntry."Document Type"::Payment, PaymentAmount,
          FindAdditionalCurrencyAmount(PaymentAmount));
        VerifyCumulativeVATEntry(GenJournalLine, Round(CummulativeVATAmount));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BelowVATPaymentUnrealVATLast()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VATPostingSetup: Record "VAT Posting Setup";
        GLEntry: Record "G/L Entry";
        PostedDocumentNo: Code[20];
        InvoiceAmount: Decimal;
        PaymentAmount: Decimal;
    begin
        // Check that correct Amount applied in Customer Ledger Entry and G/L Entry and no VAT Amount applied in VAT Entry after Posting
        // General Journal Line with Document Type Invoice and making Payment(Below VAT) for Customer with Unrealized VAT Type - Last.
        Initialize();
        LibraryPmtDiscSetup.ClearAdjustPmtDiscInVATSetup();

        LibraryERM.FindUnrealVATPostingSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::Last);

        InvoiceAmount := LibraryRandom.RandDec(1000, 2);  // Use Random Number Generator for Amount.
        PaymentAmount := Round(InvoiceAmount * VATPostingSetup."VAT %" / (100 + VATPostingSetup."VAT %"));
        PostedDocumentNo := SetupAndCreateGenJournalLine(GenJournalLine, VATPostingSetup, InvoiceAmount, PaymentAmount);

        // Verify: Verify that correct Amount, Amount(LCY), Remaining Amount, Remaining Amount(LCY) in Customer Ledger Entry and correct
        // VAT Amount Applied in VAT Entry and correct Amount is posted in G/L Entry.
        VerifyCustomerLedgerEntry(PostedDocumentNo, GenJournalLine."Document Type"::Invoice, InvoiceAmount, InvoiceAmount - PaymentAmount);
        VerifyGLEntry(
          GLEntry, GenJournalLine."Document No.", GLEntry."Document Type"::Payment, PaymentAmount,
          FindAdditionalCurrencyAmount(PaymentAmount));
        VerifyNoVATEntry(GenJournalLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OverVATPaymentUnrealVATLast()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
        PostedDocumentNo: Code[20];
        PaymentAmount: Decimal;
        InvoiceAmount: Decimal;
        VATAmount: Decimal;
    begin
        // Check that correct Amount applied in Customer Ledger Entry and G/L Entry and VAT Amount applied in VAT Entry after Posting
        // General Journal Line with Document Type Invoice and making Payment(Above VAT) for Customer with Unrealized VAT Type - Last.
        Initialize();
        LibraryPmtDiscSetup.ClearAdjustPmtDiscInVATSetup();
        LibraryERM.FindUnrealVATPostingSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::Last);
        InvoiceAmount := LibraryRandom.RandDec(1000, 2);  // Use Random Number Generator for Amount.
        VATAmount := InvoiceAmount * VATPostingSetup."VAT %" / (100 + VATPostingSetup."VAT %");
        PaymentAmount := VATAmount + InvoiceAmount + LibraryRandom.RandDec(10, 2);
        PostedDocumentNo := SetupAndCreateGenJournalLine(GenJournalLine, VATPostingSetup, InvoiceAmount, PaymentAmount);

        // Verify: Verify that correct Amount, Amount(LCY), Remaining Amount, Remaining Amount(LCY) in Customer Ledger Entry and correct
        // VAT Amount Applied in VAT Entry and correct Amount is posted in G/L Entry.
        VerifyCustomerLedgerEntry(PostedDocumentNo, GenJournalLine."Document Type"::Invoice, InvoiceAmount, 0);
        VerifyGLEntry(
          GLEntry, GenJournalLine."Document No.", GLEntry."Document Type"::Payment, Round(PaymentAmount),
          FindAdditionalCurrencyAmount(PaymentAmount));
        VerifyVATEntry(GenJournalLine, -VATAmount);
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
        DocumentNo: Code[20];
        Amount: Decimal;
    begin
        // Test VAT Entry after apply refund on Credit Memo twice for Customer with Unrealized VAT Type as Last.

        // 1. Setup: Update Unrealized VAT as True on General Ledger Setup, VAT Posting Setup with Unrealized VAT Type Last.
        // Create and post Sales Credit Memo, General Journal Line with Document Type as Refund and apply it on Credit Memo.
        Initialize();
        LibraryERM.FindUnrealVATPostingSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::Last);
        UpdateVATPostingSetup(VATPostingSetup, false);

        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::"Credit Memo", CreateCustomer(VATPostingSetup."VAT Bus. Posting Group"));
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group"),
          LibraryRandom.RandDec(10, 2));

        Amount := SalesLine.Quantity * SalesLine."Unit Price" * (1 + SalesLine."VAT %" / 100);

        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // 2 is required for Partial Refund.
        CreateAndPostGeneralJournal(
          GenJournalLine, GenJournalLine."Account Type"::Customer, SalesHeader."Sell-to Customer No.", '', Amount / 2);
        ApplyAndPostCustomerEntry(CustLedgerEntry."Document Type"::Refund, DocumentNo, GenJournalLine."Document No.");

        // 2. Exercise: Again create and post General Journal Line with Document Type as Refund for Remaining Amount and apply it on
        // Credit Memo.
        CreateAndPostGeneralJournal(
          GenJournalLine, GenJournalLine."Account Type"::Customer, SalesHeader."Sell-to Customer No.", '', Amount - GenJournalLine.Amount);
        ApplyAndPostCustomerEntry(CustLedgerEntry."Document Type"::Refund, DocumentNo, GenJournalLine."Document No.");

        // 3. Verify: Verify VAT Entry for Unrealized VAT.
        VerifyVATEntry(GenJournalLine, Amount * VATPostingSetup."VAT %" / (100 + VATPostingSetup."VAT %"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartialVATPurchaseCreditMemo()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Test G/L Entry after Apply Refund on Credit Memo for Vendor with Unrealized VAT Type as Last.

        PartialApplyCreditMemo('', '', VATPostingSetup."Unrealized VAT Type"::Last);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure PartialCreditMemoWithCurrency()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Test G/L Entry after Apply Refund on Credit Memo for Vendor with Unrealized VAT Type as Last and Currency.

        PartialApplyCreditMemo(CreateCurrency(), CreateCurrency(), VATPostingSetup."Unrealized VAT Type"::Last);
    end;

    local procedure PartialApplyCreditMemo(CurrencyCode: Code[10]; CurrencyCode2: Code[10]; UnrealizedVATType: Option)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GenJournalLine: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Amount: Decimal;
        DocumentNo: Code[20];
    begin
        // 1. Setup: Update Unrealized VAT as True on General Ledger Setup, VAT Posting Setup with Unrealized VAT Type Last.
        // Create and post Purchase Credit Memo with currency.
        Initialize();
        LibraryERM.FindUnrealVATPostingSetup(VATPostingSetup, UnrealizedVATType);
        UpdateVATPostingSetup(VATPostingSetup, false);

        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", CreateVendor(VATPostingSetup."VAT Bus. Posting Group"));

        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group"),
          LibraryRandom.RandDec(10, 2));

        UpdatePurchaseHeader(PurchaseHeader, CurrencyCode);

        Amount := PurchaseLine.Quantity * PurchaseLine."Direct Unit Cost" * (1 + PurchaseLine."VAT %" / 100);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // 2. Exercise: Create and post General Journal Line with Document Type as Refund with different Currency and apply it on Credit
        // Memo. 2 is required for partial Refund.
        CreateAndPostGeneralJournal(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, PurchaseHeader."Buy-from Vendor No.", CurrencyCode2,
          -LibraryERM.ConvertCurrency(Amount, '', CurrencyCode, WorkDate()) / 2);
        ApplyAndPostVendorEntry(VendorLedgerEntry."Document Type"::Refund, DocumentNo, GenJournalLine."Document No.");

        // 3. Verify: Verify Dtld Vendor Ledger Entry after apply Refund on Credit Memo.
        LibraryERM.VerifyVendApplnWithZeroTransNo(
          GenJournalLine."Document No.", GLEntry."Document Type"::Refund, -GenJournalLine."Amount (LCY)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyPurchaseCreditMemoTwice()
    begin
        // Test VAT Entry after Apply Refund on Credit Memo for Vendor Twice with Unrealized VAT Type as Last.

        ApplyCreditMemoTwice('', '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure CreditMemoApplyTwiceCurrency()
    begin
        // Test VAT Entry after Apply Refund on Credit Memo for Vendor Twice with Unrealized VAT Type as Last and Currency.

        ApplyCreditMemoTwice(CreateCurrency(), CreateCurrency());
    end;

    local procedure ApplyCreditMemoTwice(CurrencyCode: Code[10]; CurrencyCode2: Code[10])
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Amount: Decimal;
        DocumentNo: Code[20];
    begin
        // 1. Setup: Update Unrealized VAT as True on General Ledger Setup, VAT Posting Setup with Unrealized VAT Type Last. Create and
        // post Purchase Credit Memo with Currency, General Journal Line with Document Type as Refund and apply it on Credit Memo.
        Initialize();
        LibraryERM.FindUnrealVATPostingSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::Last);
        UpdateVATPostingSetup(VATPostingSetup, false);
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", CreateVendor(VATPostingSetup."VAT Bus. Posting Group"));

        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group"),
          LibraryRandom.RandDec(10, 2));

        UpdatePurchaseHeader(PurchaseHeader, CurrencyCode);

        Amount := PurchaseLine.Quantity * PurchaseLine."Direct Unit Cost" * (1 + PurchaseLine."VAT %" / 100);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // 2 is required for partial Refund.
        CreateAndPostGeneralJournal(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, PurchaseHeader."Buy-from Vendor No.", CurrencyCode2,
          -LibraryERM.ConvertCurrency(Amount, '', CurrencyCode, WorkDate()) / 2);
        ApplyAndPostVendorEntry(VendorLedgerEntry."Document Type"::Refund, DocumentNo, GenJournalLine."Document No.");

        // 2. Exercise: Again create and post General Journal Line with Document Type as Refund for Remaining Amount with different
        // Currency and apply it on Credit Memo.
        CreateAndPostGeneralJournal(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, PurchaseHeader."Buy-from Vendor No.", CurrencyCode2,
          GenJournalLine."Amount (LCY)" - LibraryERM.ConvertCurrency(Amount, '', CurrencyCode, WorkDate()));
        ApplyAndPostVendorEntry(VendorLedgerEntry."Document Type"::Refund, DocumentNo, GenJournalLine."Document No.");

        // 3. Verify: Verify VAT Entry for Unrealized VAT.
        VerifyVATEntry(
          GenJournalLine,
          -Round(
            LibraryERM.ConvertCurrency(Amount, CurrencyCode, CurrencyCode2, WorkDate()) *
            VATPostingSetup."VAT %" / (100 + VATPostingSetup."VAT %")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartialVATSalesCreditMemo()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Test G/L Entry after apply refund on Credit Memo for Customer with Unrealized VAT Type as Last.

        PartialRefundSalesCreditMemo(VATPostingSetup."Unrealized VAT Type"::Last);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartialFullyVATSalesCreditMemo()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Test G/L Entry after apply Refund on Credit Memo for Customer with Unrealized VAT Type as Last (Fully Paid).

        PartialRefundSalesCreditMemo(VATPostingSetup."Unrealized VAT Type"::"Last (Fully Paid)");
    end;

    local procedure PartialRefundSalesCreditMemo(UnrealizedVATType: Option)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GLEntry: Record "G/L Entry";
        DocumentNo: Code[20];
        Amount: Decimal;
    begin
        // 1. Setup: Update Unrealized VAT as True on General Ledger Setup, VAT Posting Setup with Unrealized VAT Type as parameter.
        // Create and post Sales Credit Memo.
        Initialize();
        LibraryERM.FindUnrealVATPostingSetup(VATPostingSetup, UnrealizedVATType);
        UpdateVATPostingSetup(VATPostingSetup, false);

        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::"Credit Memo", CreateCustomer(VATPostingSetup."VAT Bus. Posting Group"));
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group"),
          LibraryRandom.RandDec(10, 2));  // Use Random for Quantity.

        Amount := SalesLine.Quantity * SalesLine."Unit Price" * (1 + SalesLine."VAT %" / 100);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // 2. Exercise: Create and post General Journal Line with Document Type as Refund and apply it on Credit Memo.
        // 2 is required for partial Refund.
        CreateAndPostGeneralJournal(
          GenJournalLine, GenJournalLine."Account Type"::Customer, SalesHeader."Sell-to Customer No.", '', Amount / 2);
        ApplyAndPostCustomerEntry(CustLedgerEntry."Document Type"::Refund, DocumentNo, GenJournalLine."Document No.");

        // 3. Verify: Verify Dtld Customer Ledger Entry after apply Refund on Credit Memo.
        LibraryERM.VerifyCustApplnWithZeroTransNo(
          GenJournalLine."Document No.", GLEntry."Document Type"::Refund, -GenJournalLine."Amount (LCY)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyPartialVATSalesCreditMemo()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GLEntry: Record "G/L Entry";
        DocumentNo: Code[20];
        Amount: Decimal;
    begin
        // Test G/L Entry after apply Refund posted with partial VAT Amount covering on Credit Memo for Customer with Unrealized VAT
        // Type as Last (Fully Paid).

        // 1. Setup: Update Unrealized VAT as True on General Ledger Setup, VAT Posting Setup with Unrealized VAT Type Last
        // (Fully Paid). Create and post Sales Credit Memo, General Journal Line with Document Type as Refund
        // and apply it on Credit Memo.
        Initialize();
        LibraryERM.FindUnrealVATPostingSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::"Last (Fully Paid)");
        UpdateVATPostingSetup(VATPostingSetup, false);

        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::"Credit Memo", CreateCustomer(VATPostingSetup."VAT Bus. Posting Group"));
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group"),
          LibraryRandom.RandDec(10, 2));  // Use Random for Quantity.

        Amount := SalesLine.Quantity * SalesLine."Unit Price" * (1 + SalesLine."VAT %" / 100);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // 2 is required for partial Refund.
        CreateAndPostGeneralJournal(
          GenJournalLine, GenJournalLine."Account Type"::Customer, SalesHeader."Sell-to Customer No.", '', Amount / 2);
        ApplyAndPostCustomerEntry(CustLedgerEntry."Document Type"::Refund, DocumentNo, GenJournalLine."Document No.");

        // 2. Exercise: Again create and post General Journal Line with Document Type as Refund with partial VAT Amount covering
        // and apply it on Credit Memo.
        CreateAndPostGeneralJournal(
          GenJournalLine, GenJournalLine."Account Type"::Customer, SalesHeader."Sell-to Customer No.", '',
          Amount - GenJournalLine.Amount - LibraryUtility.GenerateRandomFraction());
        ApplyAndPostCustomerEntry(CustLedgerEntry."Document Type"::Refund, DocumentNo, GenJournalLine."Document No.");

        // 3. Verify: Verify Dtld Customer Ledger Entry after apply Refund on Credit Memo.
        LibraryERM.VerifyCustApplnWithZeroTransNo(
          GenJournalLine."Document No.", GLEntry."Document Type"::Refund, -GenJournalLine."Amount (LCY)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyFullyVATSalesCreditMemo()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        DocumentNo: Code[20];
        Amount: Decimal;
        RefundAmount: Decimal;
    begin
        // Test G/L Entry after apply Refund posted with Full VAT Amount covering on Credit Memo for Customer with Unrealized VAT
        // Type as Last (Fully Paid).

        // 1. Setup: Update Unrealized VAT as True on General Ledger Setup, VAT Posting Setup with Unrealized VAT Type Last (Fully Paid).
        // Create and post Sales Credit Memo, General Journal Line with Document Type as Refund twice firstly with
        // partial Sales Credit Memo amount and secondly with partial VAT amount covering and apply both on Credit Memo.
        Initialize();
        LibraryERM.FindUnrealVATPostingSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::"Last (Fully Paid)");
        UpdateVATPostingSetup(VATPostingSetup, false);

        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::"Credit Memo", CreateCustomer(VATPostingSetup."VAT Bus. Posting Group"));
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group"),
          LibraryRandom.RandDec(10, 2));  // Use Random for Quantity.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        SalesCrMemoHeader.Get(DocumentNo);
        SalesCrMemoHeader.CalcFields("Amount Including VAT");
        Amount := SalesCrMemoHeader."Amount Including VAT";

        // 2 is required for partial Refund.
        CreateAndPostGeneralJournal(
          GenJournalLine, GenJournalLine."Account Type"::Customer, SalesHeader."Sell-to Customer No.", '', Amount / 2);
        ApplyAndPostCustomerEntry(CustLedgerEntry."Document Type"::Refund, DocumentNo, GenJournalLine."Document No.");
        RefundAmount := GenJournalLine.Amount;

        CreateAndPostGeneralJournal(
          GenJournalLine, GenJournalLine."Account Type"::Customer, SalesHeader."Sell-to Customer No.", '',
          Amount - RefundAmount - LibraryUtility.GenerateRandomFraction());
        ApplyAndPostCustomerEntry(CustLedgerEntry."Document Type"::Refund, DocumentNo, GenJournalLine."Document No.");

        // 2. Exercise: Create and post General Journal Line with Document Type as Refund with Full VAT amount covering and
        // apply it on Credit Memo.
        CreateAndPostGeneralJournal(
          GenJournalLine, GenJournalLine."Account Type"::Customer, SalesHeader."Sell-to Customer No.", '',
          Amount - RefundAmount - GenJournalLine.Amount);
        ApplyAndPostCustomerEntry(CustLedgerEntry."Document Type"::Refund, DocumentNo, GenJournalLine."Document No.");

        // 3. Verify: Verify VAT Entry after apply Refund on Credit Memo.
        VerifyVATEntry(GenJournalLine, Amount * VATPostingSetup."VAT %" / (100 + VATPostingSetup."VAT %"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartialFullyPurchaseCreditMemo()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Test G/L Entry after Apply Refund on Credit Memo for Vendor with Unrealized VAT Type as Last (Fully Paid).

        PartialApplyCreditMemo('', '', VATPostingSetup."Unrealized VAT Type"::"Last (Fully Paid)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyPartialPurchaseCreditMemo()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GLEntry: Record "G/L Entry";
        Amount: Decimal;
        DocumentNo: Code[20];
    begin
        // Test G/L Entry after apply Refund posted with partial VAT Amount covering on Credit Memo for Vendor with Unrealized VAT
        // Type as Last (Fully Paid).

        // 1. Setup: Update Unrealized VAT as True on General Ledger Setup, VAT Posting Setup with Unrealized VAT Type as Last
        // (Fully Paid). Create and post Purchase Credit Memo, General Journal Line with Document Type as Refund
        // and apply it on Credit Memo.
        Initialize();
        LibraryERM.FindUnrealVATPostingSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::"Last (Fully Paid)");
        UpdateVATPostingSetup(VATPostingSetup, false);
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", CreateVendor(VATPostingSetup."VAT Bus. Posting Group"));

        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group"),
          LibraryRandom.RandDec(10, 2));  // Use Random for Quantity.
        UpdatePurchaseHeader(PurchaseHeader, '');
        Amount := PurchaseLine.Quantity * PurchaseLine."Direct Unit Cost" * (1 + PurchaseLine."VAT %" / 100);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // 2 is required for partial Refund.
        CreateAndPostGeneralJournal(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, PurchaseHeader."Buy-from Vendor No.", '', -Amount / 2);
        ApplyAndPostVendorEntry(VendorLedgerEntry."Document Type"::Refund, DocumentNo, GenJournalLine."Document No.");

        // 2. Exercise: Again create and post General Journal Line with Document Type as Refund with partial VAT amount covering
        // and apply it on Credit Memo.
        CreateAndPostGeneralJournal(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, PurchaseHeader."Buy-from Vendor No.", '',
          LibraryUtility.GenerateRandomFraction() - Amount - GenJournalLine.Amount);
        ApplyAndPostVendorEntry(VendorLedgerEntry."Document Type"::Refund, DocumentNo, GenJournalLine."Document No.");

        // 3. Verify: Verify Dtld Vendor Ledger Entry after apply Refund on Credit Memo.
        LibraryERM.VerifyVendApplnWithZeroTransNo(
          GenJournalLine."Document No.", GLEntry."Document Type"::Refund, -GenJournalLine."Amount (LCY)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyFullyPurchaseCreditMemo()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        Amount: Decimal;
        RefundAmount: Decimal;
        DocumentNo: Code[20];
    begin
        // Test G/L Entry after apply Refund posted with Full VAT Amount covering on Credit Memo for Vendor with Unrealized VAT
        // Type as Last (Fully Paid).

        // 1. Setup: Update Unrealized VAT as True on General Ledger Setup, VAT Posting Setup with Unrealized VAT Type as Last
        // (Fully Paid). Create and post Purchase Credit Memo, General Journal Line with Document Type as Refund twice
        // firstly with partial Sales Credit Memo amount and secondly with partial VAT amount covering and apply both on Credit Memo.
        Initialize();
        LibraryERM.FindUnrealVATPostingSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::"Last (Fully Paid)");
        UpdateVATPostingSetup(VATPostingSetup, false);
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", CreateVendor(VATPostingSetup."VAT Bus. Posting Group"));

        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group"),
          LibraryRandom.RandDec(10, 2));  // Use Random for Quantity.
        UpdatePurchaseHeader(PurchaseHeader, '');
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        PurchCrMemoHdr.Get(DocumentNo);
        PurchCrMemoHdr.CalcFields("Amount Including VAT");
        Amount := PurchCrMemoHdr."Amount Including VAT";

        // 2 is required for partial Refund.
        CreateAndPostGeneralJournal(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, PurchaseHeader."Buy-from Vendor No.", '', -Amount / 2);
        ApplyAndPostVendorEntry(VendorLedgerEntry."Document Type"::Refund, DocumentNo, GenJournalLine."Document No.");
        RefundAmount := GenJournalLine.Amount;

        CreateAndPostGeneralJournal(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, PurchaseHeader."Buy-from Vendor No.", '',
          LibraryUtility.GenerateRandomFraction() - Amount - RefundAmount);
        ApplyAndPostVendorEntry(VendorLedgerEntry."Document Type"::Refund, DocumentNo, GenJournalLine."Document No.");

        // 2. Exercise: Again create and post General Journal Line with Document Type as Refund with Full VAT amount covering
        // and apply it on Credit Memo.
        CreateAndPostGeneralJournal(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, PurchaseHeader."Buy-from Vendor No.", '',
          -Amount - RefundAmount - GenJournalLine.Amount);
        ApplyAndPostVendorEntry(VendorLedgerEntry."Document Type"::Refund, DocumentNo, GenJournalLine."Document No.");

        // 3. Verify: Verify VAT Entry for Unrealized VAT.
        VerifyVATEntry(GenJournalLine, -Amount * VATPostingSetup."VAT %" / (100 + VATPostingSetup."VAT %"));
    end;

    local procedure ApplyAndPostCustomerEntry(DocumentType: Enum "Gen. Journal Document Type"; PostedDocumentNo: Code[20]; DocumentNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
    begin
        // Apply Refund Entry on Posted Credit Memo.
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocumentType, DocumentNo);
        CustLedgerEntry.CalcFields("Remaining Amount");
        LibraryERM.SetApplyCustomerEntry(CustLedgerEntry, CustLedgerEntry."Remaining Amount");

        // Set Applies-to ID.
        CustLedgerEntry2.SetRange("Document No.", PostedDocumentNo);
        CustLedgerEntry2.FindFirst();
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry2);

        // Post Application Entries.
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry);
    end;

    local procedure CreateAndPostGeneralJournal(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; CurrencyCode: Code[10]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGeneralJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Refund,
          AccountType, AccountNo, Amount);

        // Value of Document No. is not important.
        GenJournalLine.Validate("Document No.", GenJournalLine."Journal Batch Name" + Format(GenJournalLine."Line No."));
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNo());
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure ApplyAndPostVendorEntry(DocumentType: Enum "Gen. Journal Document Type"; PostedDocumentNo: Code[20]; DocumentNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
    begin
        // Apply Refund Entry on Posted Credit Memo.
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, DocumentType, DocumentNo);
        VendorLedgerEntry.CalcFields("Remaining Amount");
        LibraryERM.SetApplyVendorEntry(VendorLedgerEntry, VendorLedgerEntry."Remaining Amount");

        // Set Applies-to ID.
        VendorLedgerEntry2.SetRange("Document No.", PostedDocumentNo);
        VendorLedgerEntry2.FindFirst();
        LibraryERM.SetAppliestoIdVendor(VendorLedgerEntry2);

        // Post Application Entries.
        LibraryERM.PostVendLedgerApplication(VendorLedgerEntry);
    end;

    local procedure CreateCustomerApplyToOldest(VATBusPostingGroup: Code[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Customer.Validate("Application Method", Customer."Application Method"::"Apply to Oldest");
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateCustomerPaymentTermCode(var PaymentTerms: Record "Payment Terms"; VATBusPostingGroup: Code[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        Customer.Get(CreateCustomerApplyToOldest(VATBusPostingGroup));
        LibraryERM.GetDiscountPaymentTerm(PaymentTerms);
        Customer.Validate("Payment Terms Code", PaymentTerms.Code);
        Customer.Validate("Gen. Bus. Posting Group", FindGeneralPostingSetup());
        Customer.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateItem(VATProdPostingGroup: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        Item.Validate("Unit Price", 10 * LibraryRandom.RandDec(100, 2));  // Take Unit Price greater than 9 (Standard Value).
        Item.Validate("Last Direct Cost", Item."Unit Price");
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateCustomer(VATBusPostingGroup: Code[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Customer."Block Payment Tolerance" := true;
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        Currency.Get(LibraryERM.CreateCurrencyWithGLAccountSetup());
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal)
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType, AccountType, AccountNo, Amount);
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

    local procedure CreateVendor(VATBusPostingGroup: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Vendor."Block Payment Tolerance" := true;
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; VATPostingSetup: Record "VAT Posting Setup"; DocumentType: Enum "Sales Document Type")
    var
        SalesLine: Record "Sales Line";
    begin
        // Create Sales Document with Random Quantity.
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CreateCustomer(VATPostingSetup."VAT Bus. Posting Group"));
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group"),
          LibraryRandom.RandDec(10, 2));
        if DocumentType = SalesHeader."Document Type"::"Credit Memo" then
            SalesLine.Validate("Qty. to Ship", 0);  // Qty. to Ship must be Zero in case of Sales Credit Memo Line.
        SalesLine.Modify(true);
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; VATPostingSetup: Record "VAT Posting Setup"; DocumentType: Enum "Purchase Document Type")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Create Purchase Document with Random Quantity.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, CreateVendor(VATPostingSetup."VAT Bus. Posting Group"));
        UpdatePurchaseHeader(PurchaseHeader, '');

        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group"),
          LibraryRandom.RandDec(10, 2));
        if DocumentType = PurchaseHeader."Document Type"::"Credit Memo" then
            PurchaseLine.Validate("Qty. to Receive", 0);  // Qty. to Receive must be Zero in case of Purchase Credit Memo Line.
        PurchaseLine.Modify(true);
    end;

    local procedure CreateAndPostJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; DocumentType: Enum "Gen. Journal Document Type"; AccountNo: Code[20]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        SelectGenJournalBatch(GenJournalBatch);
        CreateGenJournalLine(GenJournalLine, GenJournalBatch, AccountType, AccountNo, DocumentType, Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure FindAdditionalCurrencyAmount(Amount: Decimal): Decimal
    begin
        exit(Round(LibraryERM.ConvertCurrency(Round(Amount), '', LibraryERM.GetAddReportingCurrency(), WorkDate())));
    end;

    local procedure FindAmountSalesCrMemo(var SalesCrMemoLine: Record "Sales Cr.Memo Line"; DocumentNo: Code[20]): Decimal
    begin
        // Return Amount less than Sales Credit Memo VAT Amount to use it as partial Amount.
        SalesCrMemoLine.SetRange("Document No.", DocumentNo);
        SalesCrMemoLine.FindFirst();
        exit(((SalesCrMemoLine.Amount * SalesCrMemoLine."VAT %") / 100) - LibraryRandom.RandDec(10, 2));
    end;

    local procedure FindAmountPurchaseCrMemo(var PurchCrMemoLine: Record "Purch. Cr. Memo Line"; DocumentNo: Code[20]): Decimal
    begin
        // Return Amount less than Purchase Credit Memo VAT Amount to use it as partial Amount.
        PurchCrMemoLine.SetRange("Document No.", DocumentNo);
        PurchCrMemoLine.FindFirst();
        exit(((PurchCrMemoLine.Amount * PurchCrMemoLine."VAT %") / 100) - LibraryRandom.RandDec(10, 2));
    end;

    local procedure FindAmountSalesInvoice(var SalesInvoiceLine: Record "Sales Invoice Line"; DocumentNo: Code[20]): Decimal
    begin
        // Return Amount less than Sales Invoice VAT Amount to use it as partial Amount.
        SalesInvoiceLine.SetRange("Document No.", DocumentNo);
        SalesInvoiceLine.FindFirst();
        exit(((SalesInvoiceLine.Amount * SalesInvoiceLine."VAT %") / 100) - LibraryRandom.RandDec(10, 2));
    end;

    local procedure FindAmountPurchaseInvoice(var PurchInvLine: Record "Purch. Inv. Line"; DocumentNo: Code[20]): Decimal
    begin
        // Return Amount less than Purchase Invoice VAT Amount to use it as partial Amount.
        PurchInvLine.SetRange("Document No.", DocumentNo);
        PurchInvLine.FindFirst();
        exit(((PurchInvLine.Amount * PurchInvLine."VAT %") / 100) - LibraryRandom.RandDec(10, 2));
    end;

    local procedure FindGLAccountWithVAT(VATPostingSetup: Record "VAT Posting Setup"): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        exit(LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale));
    end;

    local procedure FindGeneralPostingSetup(): Code[10]
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        GeneralPostingSetup."Sales Pmt. Disc. Debit Acc." := LibraryERM.CreateGLAccountNo();  // Using assignment to avoid error in ES.
        GeneralPostingSetup.Modify(true);
        exit(GeneralPostingSetup."Gen. Bus. Posting Group");
    end;

    local procedure UpdateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; AdjustForPaymentDisc: Boolean)
    begin
        VATPostingSetup.Validate("Sales VAT Unreal. Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("Purch. VAT Unreal. Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup."Adjust for Payment Discount" := AdjustForPaymentDisc;  // Using assignment to avoid error in ES.
        VATPostingSetup.Modify(true);
    end;

    local procedure SelectGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
    end;

    local procedure SetupAndCreateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; VATPostingSetup: Record "VAT Posting Setup"; InvoiceAmount: Decimal; PaymentAmount: Decimal) PostedDocumentNo: Code[20]
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        CustomerNo: Code[20];
    begin
        // Setup: Update General Ledger Setup and VAT Setup, Create and Post General Journal Line.
        LibraryERM.SetAddReportingCurrency(CreateCurrency());
        CustomerNo := CreateCustomerApplyToOldest(VATPostingSetup."VAT Bus. Posting Group");
        SelectGenJournalBatch(GenJournalBatch);
        CreateGenJournalLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Account Type"::Customer, CustomerNo,
          GenJournalLine."Document Type"::Invoice, InvoiceAmount);
        GenJournalLine.Validate("Bal. Account No.", FindGLAccountWithVAT(VATPostingSetup));
        GenJournalLine.Modify(true);
        PostedDocumentNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Exercise: Making payment against the invoice.
        CreateAndPostJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::Customer, GenJournalLine."Document Type"::Payment, CustomerNo, -PaymentAmount);
    end;

    local procedure UnrealizedVATSalesCrMemo(var GenJournalLine: Record "Gen. Journal Line"; var SalesCrMemoLine: Record "Sales Cr.Memo Line"; VATPostingSetup: Record "VAT Posting Setup")
    var
        SalesHeader: Record "Sales Header";
        PartialVATAmount: Decimal;
        PostedDocumentNo: Code[20];
    begin
        // Setup: Update General Ledger Setup and VAT Setup, Create and Post Sales Credit Memo.
        CreateSalesDocument(SalesHeader, VATPostingSetup, SalesHeader."Document Type"::"Credit Memo");
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Exercise: Make Refund against Credit Memo and Apply the Refund over Credit Memo.
        PartialVATAmount := FindAmountSalesCrMemo(SalesCrMemoLine, PostedDocumentNo);
        CreateAndPostJournalLine(GenJournalLine, GenJournalLine."Account Type"::Customer, GenJournalLine."Document Type"::Refund,
          SalesHeader."Sell-to Customer No.", SalesCrMemoLine.Amount + PartialVATAmount);
        ApplyAndPostCustomerEntry(GenJournalLine."Document Type"::Refund, PostedDocumentNo, GenJournalLine."Document No.");
    end;

    local procedure UnrealizedVATPurchaseCrMemo(var GenJournalLine: Record "Gen. Journal Line"; var PurchCrMemoLine: Record "Purch. Cr. Memo Line"; VATPostingSetup: Record "VAT Posting Setup")
    var
        PurchaseHeader: Record "Purchase Header";
        PartialVATAmount: Decimal;
        PostedDocumentNo: Code[20];
    begin
        // Setup: Update General Ledger Setup and VAT Setup, Create and Post Purchase Credit Memo.
        CreatePurchaseDocument(PurchaseHeader, VATPostingSetup, PurchaseHeader."Document Type"::"Credit Memo");
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Exercise: Make Refund against Purchase Credit Memo and Apply the Refund over Purchase Credit Memo.
        PartialVATAmount := FindAmountPurchaseCrMemo(PurchCrMemoLine, PostedDocumentNo);
        CreateAndPostJournalLine(GenJournalLine, GenJournalLine."Account Type"::Vendor, GenJournalLine."Document Type"::Refund,
          PurchaseHeader."Buy-from Vendor No.", -(PurchCrMemoLine.Amount + PartialVATAmount));
        ApplyAndPostVendorEntry(GenJournalLine."Document Type"::Refund, PostedDocumentNo, GenJournalLine."Document No.");
    end;

    local procedure UnrealizedVATSalesInvoice(var GenJournalLine: Record "Gen. Journal Line"; var SalesInvoiceLine: Record "Sales Invoice Line"; VATPostingSetup: Record "VAT Posting Setup")
    var
        SalesHeader: Record "Sales Header";
        PartialVATAmount: Decimal;
        PostedDocumentNo: Code[20];
    begin
        // Setup: Update General Ledger Setup and VAT Setup, Create and Post Sales Invoice.
        CreateSalesDocument(SalesHeader, VATPostingSetup, SalesHeader."Document Type"::Invoice);
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Exercise: Make Payment against Sales Invoice and Apply the Payment over Sales Invoice.
        PartialVATAmount := FindAmountSalesInvoice(SalesInvoiceLine, PostedDocumentNo);
        CreateAndPostJournalLine(GenJournalLine, GenJournalLine."Account Type"::Customer, GenJournalLine."Document Type"::Payment,
          SalesHeader."Sell-to Customer No.", -(SalesInvoiceLine.Amount + PartialVATAmount));
        ApplyAndPostCustomerEntry(GenJournalLine."Document Type"::Payment, PostedDocumentNo, GenJournalLine."Document No.");
    end;

    local procedure UnrealizedVATPurchaseInvoice(var GenJournalLine: Record "Gen. Journal Line"; var PurchInvLine: Record "Purch. Inv. Line"; VATPostingSetup: Record "VAT Posting Setup")
    var
        PurchaseHeader: Record "Purchase Header";
        PartialVATAmount: Decimal;
        PostedDocumentNo: Code[20];
    begin
        // Setup: Update General Ledger Setup and VAT Setup, Create and Post Purchase Invoice.
        CreatePurchaseDocument(PurchaseHeader, VATPostingSetup, PurchaseHeader."Document Type"::Invoice);
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Exercise: Make Payment against Purchase Invoice and Apply the Payment over Purchase Invoice.
        PartialVATAmount := FindAmountPurchaseInvoice(PurchInvLine, PostedDocumentNo);
        CreateAndPostJournalLine(GenJournalLine, GenJournalLine."Account Type"::Vendor, GenJournalLine."Document Type"::Payment,
          PurchaseHeader."Buy-from Vendor No.", PurchInvLine.Amount + PartialVATAmount);
        ApplyAndPostVendorEntry(GenJournalLine."Document Type"::Payment, PostedDocumentNo, GenJournalLine."Document No.");
    end;

    local procedure UpdatePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; CurrencyCode: Code[10])
    begin
        PurchaseHeader.Validate("Currency Code", CurrencyCode);

        // Use Vendor Cr. Memo No. and Vendor Invoice No. as No. value is not important.
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
    end;

    local procedure UpdateGeneralPostingSetup(GenBusPostingGroupCode: Code[20]; GenProdPostingGroupCode: Code[20])
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GeneralPostingSetup.Get(GenBusPostingGroupCode, GenProdPostingGroupCode);
        // Using assignment to avoid error in ES.
        GeneralPostingSetup."Sales Pmt. Disc. Debit Acc." := LibraryERM.CreateGLAccountNo();
        GeneralPostingSetup."Sales Pmt. Disc. Credit Acc." := LibraryERM.CreateGLAccountNo();
        GeneralPostingSetup.Modify(true);
    end;

    local procedure VerifyVATEntry(GenJournalLine: Record "Gen. Journal Line"; Amount: Decimal)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Bill-to/Pay-to No.", GenJournalLine."Account No.");
        VATEntry.SetRange("Document No.", GenJournalLine."Document No.");
        VATEntry.SetRange("Document Type", GenJournalLine."Document Type");
        VATEntry.FindFirst();
        Assert.AreNearlyEqual(
          Amount, VATEntry.Amount, LibraryERM.GetAmountRoundingPrecision(), StrSubstNo(AmountError, VATEntry.FieldCaption(Amount),
            VATEntry.TableCaption(), VATEntry.FieldCaption("Entry No."), VATEntry."Entry No."));
        VATEntry.TestField("G/L Acc. No.", '');
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

    local procedure VerifyCustomerLedgerEntry(DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal; RemainingAmount: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocumentType, DocumentNo);
        CustLedgerEntry.CalcFields(Amount, "Amount (LCY)", "Remaining Amount", "Remaining Amt. (LCY)");
        CustLedgerEntry.TestField(Amount, Amount);
        CustLedgerEntry.TestField("Amount (LCY)", Amount);
        CustLedgerEntry.TestField("Remaining Amount", RemainingAmount);
        CustLedgerEntry.TestField("Remaining Amt. (LCY)", RemainingAmount);
    end;

    local procedure VerifyGLEntry(var GLEntry: Record "G/L Entry"; DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal; AdditionalCurrencyAmount: Decimal)
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("Document Type", DocumentType);
        GLEntry.FindFirst();
        GLEntry.TestField(Amount, Amount);
        GLEntry.TestField("Additional-Currency Amount", AdditionalCurrencyAmount);
    end;

    local procedure VerifyCumulativeVATEntry(GenJournalLine: Record "Gen. Journal Line"; Amount: Decimal)
    var
        VATEntry: Record "VAT Entry";
        VATAmount: Decimal;
    begin
        VATEntry.SetRange("Document No.", GenJournalLine."Document No.");
        VATEntry.SetRange("Document Type", GenJournalLine."Document Type"::Payment);
        VATEntry.FindSet();
        repeat
            VATAmount += VATEntry.Amount;
        until VATEntry.Next() = 0;
        Assert.AreNearlyEqual(
          Amount, VATAmount, LibraryERM.GetAmountRoundingPrecision(), StrSubstNo(CumulativeVATAmount, VATAmount));
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

