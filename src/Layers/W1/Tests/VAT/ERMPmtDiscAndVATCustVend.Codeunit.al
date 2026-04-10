codeunit 134090 "ERM Pmt Disc And VAT Cust/Vend"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Payment Discount] [General Ledger] [VAT]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryJournals: Codeunit "Library - Journals";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryPmtDiscSetup: Codeunit "Library - Pmt Disc Setup";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;
        AmountError: Label '%1 should be %2 in %3.';

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithVAT()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Check GL and VAT Entries for Posted Sales Invoice with Item and GL Account Sales Lines.
        Initialize();
        SalesDocumentWithVAT(SalesHeader."Document Type"::Invoice, -1);  // Passing -1 to make Verification Amounts Negative.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCreditMemoWithVAT()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Check GL and VAT Entries for Posted Sales Credit Memo with Item and GL Account Sales Lines.
        Initialize();
        SalesDocumentWithVAT(SalesHeader."Document Type"::"Credit Memo", 1);  // Passing 1 to make Verification Amounts Positive.
    end;

    local procedure SalesDocumentWithVAT(DocumentType: Enum "Sales Document Type"; SignFactor: Integer)
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        VATPostingSetup: Record "VAT Posting Setup";
        LineAmount: Decimal;
        VATAmount: Decimal;
        DocumentNo: Code[20];
    begin
        // Setup: Update Item, GL Account, Customer with VAT Posting Setup. Create and Post Sales Document for Item, GL Account.
        FindVATPostingSetup(VATPostingSetup);
        CreateCustomerAndItem(Customer, Item, VATPostingSetup);
        LineAmount := CreateSalesDocument(SalesHeader, Customer."No.", Item."No.", DocumentType);
        LineAmount := Round(SignFactor * LineAmount);
        VATAmount := Round(LineAmount * VATPostingSetup."VAT %" / 100);

        // Exercise.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify GL Entry and VAT Entries for Posted Sales Document.
        VerifyGLEntry(DocumentNo, Customer."Gen. Bus. Posting Group", Item."Gen. Prod. Posting Group", LineAmount, VATAmount);
        VerifyVATEntry(DocumentNo, LineAmount, VATAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPmtDiscountWithVAT()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        Item: Record Item;
        VATPostingSetup: Record "VAT Posting Setup";
        VATEntry: Record "VAT Entry";
        GLAccountNo: Code[20];
        OldPmtDiscDebitAcc: Code[20];
        DiscountAmountExclVAT: Decimal;
        VATAmountForDiscount: Decimal;
    begin
        // Check Payment Discount Amount and VAT Amount on GL and VAT Entry after posting a Payment for Sales Invoice.

        // Update General Ledger, VAT Posting Setup. Post Sales Invoice and make Payment for it.
        Initialize();
        VATEntry.DeleteAll();
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(true);
        GLAccountNo := LibraryERM.CreateGLAccountNo();
        FindVATPostingSetup(VATPostingSetup);
        CreateCustomerAndItem(Customer, Item, VATPostingSetup);
        OldPmtDiscDebitAcc :=
          UpdateGeneralPostingSetupSales(Customer."Gen. Bus. Posting Group", Item."Gen. Prod. Posting Group", GLAccountNo);
        DiscountAmountExclVAT := SalesPaymentDiscount(GenJournalLine, VATPostingSetup, Customer."No.", Item."No.");
        VATAmountForDiscount := Round(DiscountAmountExclVAT * VATPostingSetup."VAT %" / 100);

        // Verify: Verify VAT Amount and Amount for Payment Discount Entries in GL Entry and VAT Entry.
        VerifyPmtDiscEntryInGLEntry(
          GenJournalLine."Document No.", GLAccountNo, GenJournalLine."Document Type", DiscountAmountExclVAT, VATAmountForDiscount);
        VerifyVATEntry(GenJournalLine."Document No.", DiscountAmountExclVAT, VATAmountForDiscount);
        VerifyVATEntryVatDate(GenJournalLine."Document No.", GenJournalLine."VAT Reporting Date");


        // Tear Down: Rollback modified setups.
        UpdateGeneralPostingSetupSales(Customer."Gen. Bus. Posting Group", Item."Gen. Prod. Posting Group", OldPmtDiscDebitAcc);
        UpdateVATPostingSetup(
          VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group",
          VATPostingSetup."Adjust for Payment Discount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPmtDiscountWithVATUnapply()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        Item: Record Item;
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccountNo: Code[20];
        OldPmtDiscDebitAcc: Code[20];
        DiscountAmountExclVAT: Decimal;
        VATAmountForDiscount: Decimal;
    begin
        // Check Payment Discount Amount and VAT Amount on GL and VAT Entry after Unapplying posted Payment for Sales Invoice.

        // Setup: Update General Ledger, VAT Posting Setup. Post Sales Invoice and make Payment for it.
        Initialize();
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(true);
        GLAccountNo := LibraryERM.CreateGLAccountNo();
        FindVATPostingSetup(VATPostingSetup);
        CreateCustomerAndItem(Customer, Item, VATPostingSetup);
        OldPmtDiscDebitAcc :=
          UpdateGeneralPostingSetupSales(Customer."Gen. Bus. Posting Group", Item."Gen. Prod. Posting Group", GLAccountNo);
        DiscountAmountExclVAT := SalesPaymentDiscount(GenJournalLine, VATPostingSetup, Customer."No.", Item."No.");
        VATAmountForDiscount := Round(DiscountAmountExclVAT * VATPostingSetup."VAT %" / 100);

        // Exercise.
        UnapplySalesDocument(GenJournalLine."Document No.");

        // Verify: Verify Amount and VAT Amount for Payment Discount in GL Entry and VAT Entry after unapplying entries.
        VerifyPmtDiscEntryInGLEntry(
          GenJournalLine."Document No.", GLAccountNo, GenJournalLine."Document Type"::" ", -DiscountAmountExclVAT,
          -VATAmountForDiscount);
        VerifyVATEntry(GenJournalLine."Document No.", 0, 0);

        // Tear Down: Rollback modified setups.
        UpdateGeneralPostingSetupSales(Customer."Gen. Bus. Posting Group", Item."Gen. Prod. Posting Group", OldPmtDiscDebitAcc);
        UpdateVATPostingSetup(
          VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group",
          VATPostingSetup."Adjust for Payment Discount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvoiceWithVAT()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Check GL and VAT Entries for Posted Purchase Invoice with Item and GL Account Purchase Lines.
        Initialize();
        PurchaseDocumentWithVAT(PurchaseHeader."Document Type"::Invoice, 1);  // Passing 1 to make Verification Amounts Positive.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCreditMemoWithVAT()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Check GL and VAT Entries for Posted Purchase Credit Memo with Item and GL Account Purchase Lines.
        Initialize();
        PurchaseDocumentWithVAT(PurchaseHeader."Document Type"::"Credit Memo", -1);  // Passing -1 to make Verification Amounts Negative.
    end;

    local procedure PurchaseDocumentWithVAT(DocumentType: Enum "Purchase Document Type"; SignFactor: Integer)
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
        LineAmount: Decimal;
        VATAmount: Decimal;
    begin
        // Setup: Update Item, GL Account, Vendor with VAT Posting Setup. Create and Post Purchase Document for Item, GL Account.
        FindVATPostingSetup(VATPostingSetup);
        CreateVendorAndItem(Vendor, Item, VATPostingSetup);
        LineAmount := CreatePurchaseDocument(PurchaseHeader, Vendor."No.", Item."No.", DocumentType);
        LineAmount := Round(SignFactor * LineAmount);
        VATAmount := Round(LineAmount * VATPostingSetup."VAT %" / 100);

        // Exercise.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify GL Entry and VAT Entries for Posted Purchase Document.
        VerifyGLEntry(DocumentNo, Vendor."Gen. Bus. Posting Group", Item."Gen. Prod. Posting Group", LineAmount, VATAmount);
        VerifyVATEntry(DocumentNo, LineAmount, VATAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchPmtDiscountWithVAT()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Item: Record Item;
        Vendor: Record Vendor;
        VATPostingSetup: Record "VAT Posting Setup";
        VATEntry: Record "VAT Entry";
        GLAccountNo: Code[20];
        OldPmtDiscCreditAcc: Code[20];
        DiscountAmountExclVAT: Decimal;
        VATAmountForDiscount: Decimal;
    begin
        // Check Payment Discount Amount and VAT Amount on GL and VAT Entry after posting a Payment for Purchase Invoice.

        // Update General Ledger Setup, VAT Posting Setup. Post Purchase Invoice and make Payment for it.
        Initialize();
        VATEntry.DeleteAll();
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(true);
        GLAccountNo := LibraryERM.CreateGLAccountNo();
        FindVATPostingSetup(VATPostingSetup);
        CreateVendorAndItem(Vendor, Item, VATPostingSetup);
        OldPmtDiscCreditAcc :=
          UpdateGeneralPostingSetupPurch(Vendor."Gen. Bus. Posting Group", Item."Gen. Prod. Posting Group", GLAccountNo);
        DiscountAmountExclVAT := PurchasePaymentDiscount(GenJournalLine, VATPostingSetup, Vendor."No.", Item."No.");
        VATAmountForDiscount := Round(DiscountAmountExclVAT * VATPostingSetup."VAT %" / 100);

        // Verify: Verify Amount, VAT Amount for Posted Payment Discount in GL Entry and VAT Entry.
        VerifyPmtDiscEntryInGLEntry(
          GenJournalLine."Document No.", GLAccountNo, GenJournalLine."Document Type", -DiscountAmountExclVAT, -VATAmountForDiscount);
        VerifyVATEntry(GenJournalLine."Document No.", -DiscountAmountExclVAT, -VATAmountForDiscount);
        VerifyVATEntryVatDate(GenJournalLine."Document No.", GenJournalLine."VAT Reporting Date");

        // Tear Down.
        UpdateGeneralPostingSetupPurch(Vendor."Gen. Bus. Posting Group", Item."Gen. Prod. Posting Group", OldPmtDiscCreditAcc);
        UpdateVATPostingSetup(
          VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group",
          VATPostingSetup."Adjust for Payment Discount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchPmtDiscountWithVATUnapply()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Item: Record Item;
        Vendor: Record Vendor;
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccountNo: Code[20];
        OldPmtDiscCreditAcc: Code[20];
        DiscountAmountExclVAT: Decimal;
        VATAmountForDiscount: Decimal;
    begin
        // Check Payment Discount Amount and VAT Amount on GL and VAT Entry after Unapplying posted Payment for Purchase Invoice.

        // Setup: Update General Ledger Setup, VAT Posting Setup. Post Purchase Invoice and make Payment for it.
        Initialize();
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(true);
        GLAccountNo := LibraryERM.CreateGLAccountNo();
        FindVATPostingSetup(VATPostingSetup);
        CreateVendorAndItem(Vendor, Item, VATPostingSetup);
        OldPmtDiscCreditAcc :=
          UpdateGeneralPostingSetupPurch(Vendor."Gen. Bus. Posting Group", Item."Gen. Prod. Posting Group", GLAccountNo);
        DiscountAmountExclVAT := PurchasePaymentDiscount(GenJournalLine, VATPostingSetup, Vendor."No.", Item."No.");
        VATAmountForDiscount := Round(DiscountAmountExclVAT * VATPostingSetup."VAT %" / 100);

        // Exercise.
        UnapplyPurchaseDocument(GenJournalLine."Document No.");

        // Verify: Verify Amount, VAT Amount in GL Entry, VAT Entry after unapplying Payment.
        VerifyPmtDiscEntryInGLEntry(
          GenJournalLine."Document No.", GLAccountNo, GenJournalLine."Document Type"::" ", DiscountAmountExclVAT, VATAmountForDiscount);
        VerifyVATEntry(GenJournalLine."Document No.", 0, 0);

        // Tear Down:
        UpdateGeneralPostingSetupPurch(Vendor."Gen. Bus. Posting Group", Item."Gen. Prod. Posting Group", OldPmtDiscCreditAcc);
        UpdateVATPostingSetup(
          VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group",
          VATPostingSetup."Adjust for Payment Discount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FULLVATVendorPmtToInvApplWithAdjustForPmtDisc()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        VendorNo: Code[20];
        DiscountPct: Decimal;
        Amounts: array[2] of Decimal;
        PmtAmount: Decimal;
        i: Integer;
    begin
        // [FEATURE] [FULL VAT] [Purchase]
        // [SCENARIO 377970] Two VAT Entries are created from vendor Payment to two Invoices application with Full VAT setup in case of adjust for payment discount
        Initialize();

        // [GIVEN] GLSetup."Adjust for Payment Disc." = TRUE
        // [GIVEN] G/L Account "Acc" with FULL VAT posting setup
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(true);
        CreateFULLVATPostingSetup(VATPostingSetup);
        // [GIVEN] Vendor "V" with payment terms with possible discount = 2%, "Application Method" = "Apply to Oldest"
        VendorNo := CreateVendor(VATPostingSetup."VAT Bus. Posting Group", DiscountPct);
        // [GIVEN] Posted four general journal lines (all "Document Type" = Invoice):
        // [GIVEN] Line1: "Document No." = "Inv1", "Account Type" = Vendor, "Account No." = "V", "Amount" = -1250
        // [GIVEN] Line2: "Document No." = "Inv1", "Account Type" = G/L Account, "Account No." = "Acc", "Amount" = 1250
        // [GIVEN] Line3: "Document No." = "Inv2", "Account Type" = Vendor, "Account No." = "V", "Amount" = -2500
        // [GIVEN] Line4: "Document No." = "Inv2", "Account Type" = G/L Account, "Account No." = "Acc", "Amount" = 2500
        PrepareGenJnlLine(GenJournalLine);
        for i := 1 to ArrayLen(Amounts) do begin
            Amounts[i] := LibraryRandom.RandDecInRange(1000, 2000, 2);
            CreateVendorInvoiceGenJnlLine(GenJournalLine, VendorNo, -Amounts[i]);
            CreateGLAccountInvoiceGenJnlLine(GenJournalLine, VATPostingSetup."Purchase VAT Account", Amounts[i]);
            PmtAmount += Amounts[i];
        end;
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Post vendor payment with Amount = 3675 (3750 - 2% discount) which is automatically applies to posted invoices "Inv1", "Inv2"
        CreatePostVendorPaymentGenJnlLine(GenJournalLine, VendorNo, Round(PmtAmount * (1 - DiscountPct / 100)));

        // [THEN] Two VAT Entries are created (from adjust for payment discount with Amount = 75):
        // [THEN] Base = 0, Amount = -25 (1250 * 2%)
        // [THEN] Base = 0, Amount = -50 (2500 * 2%)
        VerifyVATEntryCount(GenJournalLine."Document No.", ArrayLen(Amounts));
        VerifyVATEntry(GenJournalLine."Document No.", 0, -Round(PmtAmount * DiscountPct / 100));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FULLVATCustomerPmtToInvApplWithAdjustForPmtDisc()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        CustomerNo: Code[20];
        DiscountPct: Decimal;
        Amounts: array[2] of Decimal;
        PmtAmount: Decimal;
        i: Integer;
    begin
        // [FEATURE] [FULL VAT] [Sale]
        // [SCENARIO 377970] Four VAT Entries are created from customer Payment to two Invoices application with two VAT Setups (NOVAT and FULLVAT) in case of adjust for payment discount
        Initialize();

        // [GIVEN] GLSetup."Adjust for Payment Disc." = TRUE
        // [GIVEN] G/L Account "Acc" with FULL VAT posting setup
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(true);
        CreateFULLVATPostingSetup(VATPostingSetup);
        // [GIVEN] Customer "C" with payment terms with possible discount = 2%, "Application Method" = "Apply to Oldest"
        CustomerNo := CreateCustomer(VATPostingSetup."VAT Bus. Posting Group", DiscountPct);
        // [GIVEN] Posted six general journal lines (all "Document Type" = Invoice):
        // [GIVEN] Line1: "Document No." = "Inv1", "Account Type" = Customer, "Account No." = "C", "Amount" = -1250
        // [GIVEN] Line2: "Document No." = "Inv1", "Account Type" = G/L Account, "Account No." = "Acc", "Amount" = 1250
        // [GIVEN] Line3: "Document No." = "Inv2", "Account Type" = Customer, "Account No." = "C", "Amount" = -2500
        // [GIVEN] Line4: "Document No." = "Inv2", "Account Type" = G/L Account, "Account No." = "Acc", "Amount" = 2500
        PrepareGenJnlLine(GenJournalLine);
        for i := 1 to ArrayLen(Amounts) do begin
            Amounts[i] := LibraryRandom.RandDecInRange(1000, 2000, 2);
            CreateCustomerInvoiceGenJnlLine(GenJournalLine, CustomerNo, Amounts[i]);
            CreateGLAccountInvoiceGenJnlLine(GenJournalLine, VATPostingSetup."Sales VAT Account", -Amounts[i]);
            PmtAmount += Amounts[i];
        end;
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Post customer payment with Amount = 3675 (3750 - 2% discount) which is automatically applies to posted invoices "Inv1", "Inv2"
        CreatePostCustomerPaymentGenJnlLine(GenJournalLine, CustomerNo, -Round(PmtAmount * (1 - DiscountPct / 100)));

        // [THEN] Four VAT Entries are created (from adjust for payment discount with Amount = 75):
        // [THEN] Base = 0, Amount = -25
        // [THEN] Base = 0, Amount = -50
        VerifyVATEntryCount(GenJournalLine."Document No.", ArrayLen(Amounts));
        VerifyVATEntry(GenJournalLine."Document No.", 0, Round(PmtAmount * DiscountPct / 100));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FullVATCustomerInvoiceWithPmtApplWithAdjustForPmtDisc()
    var
        GLAccount: Record "G/L Account";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        NormalVATPostingSetup: Record "VAT Posting Setup";
        FullVATPostingSetup: Record "VAT Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLinePmt: Record "Gen. Journal Line";
        CustomerNo: Code[20];
        DiscountPct: Decimal;
        PmtAmount: Decimal;
        Amount: Decimal;
        AmountFullVAT: Decimal;
    begin
        // [FEATURE] [FULL VAT] [Sale]
        // [SCENARIO 379704] VAT Entries are created from Customer Payment to one Invoice application with two VAT Setups (NormalVAT and FullVAT) in case of payment discount

        Initialize();

        // [GIVEN] GLSetup."Adjust for Payment Disc." = TRUE
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(true);

        // [GIVEN] NormalVAT Posting Setup
        // [GIVEN] G/L Account "Acc25" for Normal VAT
        CreateNormalVATPostingSetupWithPmtDiscount(NormalVATPostingSetup);
        GLAccount.Get(
          LibraryERM.CreateGLAccountWithVATPostingSetup(NormalVATPostingSetup, GLAccount."Gen. Posting Type"::Sale));

        // [GIVEN] FullVAT Posting Setup with G/L Account "AccFull"
        CreateFULLVATPostingSetup(FullVATPostingSetup);

        // [GIVEN] Customer "C" with Payment Terms with possible discount
        CustomerNo := CreateCustomerWithoutVATBusPostGroup(DiscountPct);

        // [GIVEN] Posted 5 Journal Lines (all "Document Type" = Invoice) where lines 1-2 are represented twice.
        // [GIVEN] Line1: "Document No." = "Inv1", "Account Type" = G/L Account, "Account No." = "Acc25", "Amount" = -1000, NormalVAT
        // [GIVEN] Line2: "Document No." = "Inv1", "Account Type" = G/L Account, "Account No." = "AccFull", "Amount" = -100, FullVAT
        // [GIVEN] Line3: "Document No." = "Inv1", "Account Type" = G/L Account, "Account No." = "Acc25", "Amount" = -1000, NormalVAT
        // [GIVEN] Line4: "Document No." = "Inv1", "Account Type" = G/L Account, "Account No." = "AccFull", "Amount" = -100, FullVAT
        // [GIVEN] Line5: "Document No." = "Inv1", "Account Type" = Customer, "Account No." = "C", "Amount" = 2200
        CreatePostGenJnlLinesInvoiceCustomer(
          GenJournalLine, FullVATPostingSetup, GLAccount."No.", CustomerNo, PmtAmount, Amount, AmountFullVAT);

        // [GIVEN] Posted customer payment of Inv1 total amount minus discount
        CreatePostCustomerPaymentGenJnlLine(GenJournalLinePmt, CustomerNo, -Round(PmtAmount * (1 - DiscountPct / 100)));

        // [WHEN] Apply payment to invoice "Inv1"
        LibraryERM.ApplyCustomerLedgerEntries(
          CustLedgerEntry."Document Type"::Payment, CustLedgerEntry."Document Type"::Invoice,
          GenJournalLinePmt."Document No.", GenJournalLine."Document No.");

        // [THEN] 4 VAT Entries created for payment discount applied to Invoice "Inv1" Lines
        VerifyVATEntryCount(GenJournalLinePmt."Document No.", 4);
        VerifyVATEntry(
          GenJournalLinePmt."Document No.",
          2 * Round(Round(Amount / (1 + NormalVATPostingSetup."VAT %" / 100)) * DiscountPct / 100),
          2 * (Round(Round(Amount - Round(Amount / (1 + NormalVATPostingSetup."VAT %" / 100))) * DiscountPct / 100) +
               Round(AmountFullVAT * DiscountPct / 100)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FullVATVendorInvoiceWithPmtApplWithAdjustForPmtDisc()
    var
        GLAccount: Record "G/L Account";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        NormalVATPostingSetup: Record "VAT Posting Setup";
        FullVATPostingSetup: Record "VAT Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLinePmt: Record "Gen. Journal Line";
        VendorNo: Code[20];
        DiscountPct: Decimal;
        PmtAmount: Decimal;
        Amount: Decimal;
        AmountFullVAT: Decimal;
    begin
        // [FEATURE] [FULL VAT] [Purchase]
        // [SCENARIO 379704] VAT Entries are created from Vendor Payment to one Invoice application with two VAT Setups (NormalVAT and FullVAT) in case of payment discount

        Initialize();

        // [GIVEN] GLSetup."Adjust for Payment Disc." = TRUE
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(true);

        // [GIVEN] NormalVAT Posting Setup
        // [GIVEN] G/L Account "Acc25" for NormalVAT
        CreateNormalVATPostingSetupWithPmtDiscount(NormalVATPostingSetup);
        GLAccount.Get(
          LibraryERM.CreateGLAccountWithVATPostingSetup(NormalVATPostingSetup, GLAccount."Gen. Posting Type"::Purchase));

        // [GIVEN] FullVAT Posting Setup with G/L Account "AccFull"
        CreateFULLVATPostingSetup(FullVATPostingSetup);

        // [GIVEN] Vendor "V" with Payment Terms with possible discount
        VendorNo := CreateVendorWithoutVATBusPostGroup(NormalVATPostingSetup."VAT Bus. Posting Group", DiscountPct);

        // [GIVEN] Posted 5 Journal Lines (all "Document Type" = Invoice) where lines 1-2 are represented twice.
        // [GIVEN] Line1: "Document No." = "Inv1", "Account Type" = G/L Account, "Account No." = "Acc25", "Amount" = 1000, NormalVAT
        // [GIVEN] Line2: "Document No." = "Inv1", "Account Type" = G/L Account, "Account No." = "AccFull", "Amount" = 100, FullVAT
        // [GIVEN] Line3: "Document No." = "Inv1", "Account Type" = G/L Account, "Account No." = "Acc25", "Amount" = 1000, NormalVAT
        // [GIVEN] Line4: "Document No." = "Inv1", "Account Type" = G/L Account, "Account No." = "AccFull", "Amount" = 100, FullVAT
        // [GIVEN] Line5: "Document No." = "Inv1", "Account Type" = Vendor, "Account No." = "V", "Amount" = -2200
        CreatePostGenJnlLinesInvoiceVendor(
          GenJournalLine, FullVATPostingSetup, GLAccount."No.", VendorNo, PmtAmount, Amount, AmountFullVAT);

        // [GIVEN] Posted vendor payment of Inv1 total amount minus discount
        CreatePostVendorPaymentGenJnlLine(GenJournalLinePmt, VendorNo, Round(PmtAmount * (1 - DiscountPct / 100)));

        // [WHEN] Apply payment to invoice "Inv1"
        LibraryERM.ApplyVendorLedgerEntries(
          VendorLedgerEntry."Document Type"::Payment, VendorLedgerEntry."Document Type"::Invoice,
          GenJournalLinePmt."Document No.", GenJournalLine."Document No.");

        // [THEN] 4 VAT Entries created for payment discount applied to Invoice "Inv1" Lines
        VerifyVATEntryCount(GenJournalLinePmt."Document No.", 4);
        VerifyVATEntry(
          GenJournalLinePmt."Document No.",
          -2 * Round(Round(Amount / (1 + NormalVATPostingSetup."VAT %" / 100)) * DiscountPct / 100),
          -2 * (Round(Round(Amount - Round(Amount / (1 + NormalVATPostingSetup."VAT %" / 100))) * DiscountPct / 100) +
                Round(AmountFullVAT * DiscountPct / 100)));
    end;

    [Test]
    [HandlerFunctions('PaymentToleranceWarning_MPH')]
    [Scope('OnPrem')]
    procedure SalesVATPaymentToleranceWithVATDifferenceNegativeLinesAndRounding()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustomerNo: Code[20];
        GLAccountNo: Code[20];
        InvoiceNo: array[3] of Code[20];
        i: Integer;
    begin
        // [FEATURE] [Payment Tolerance] [Rounding] [VAT Difference] [Sales]
        // [SCENARIO 227380] Post customer payment journal applied to several invoices
        // [SCENARIO 227380] in case of Payment Tolerance, VAT Difference, negative invoice lines and rounding
        Initialize();

        // [GIVEN] "Payment Tolerance %" = 5, "Max. Paym. Tol. Amount" = 20, "Max. VAT Difference Allowed" = 0.01
        SetupPmtTolAndVATDifference(5, 20, 0.01);

        // [GIVEN] VAT Posting Setup with "VAT %" = 19
        CreateCustomerAndGLAccount(CustomerNo, GLAccountNo, 19);

        // [GIVEN] Posted journal with 3 customer invoices (total Amount = 3924,21) each with several lines:
        // [GIVEN] Invoice1: 2852.93 = 2231.96 + 620.97
        // [GIVEN] Invoice2: 535.64 = 743.99 - 252.97 + 74.39 - 29.77 (where 74.39 has VAT Amount = 11.87, VAT Difference = 0.01)
        // [GIVEN] Invoice3: 535.64 = 743.99 - 252.97 + 74.39 - 29.77 (where 74.39 has VAT Amount = 11.87, VAT Difference = 0.01)
        CreatePostCustomerThreeInvoicesFromTheJournal_227380(GenJournalLine, InvoiceNo, CustomerNo, GLAccountNo);

        // [GIVEN] Create customer payment with Amount = 3924.03
        CreateCustomerPaymentGenJnlLine(GenJournalLine, CustomerNo, -3924.03);
        // [GIVEN] Apply payment to 3 posted invoices
        UpdateGenJnlLineAppliesToID(GenJournalLine);
        for i := 1 to ArrayLen(InvoiceNo) do
            SetApplyIDCustLedgEntry(InvoiceNo[i]);
        // [GIVEN] Confirm process difference = 0.18 as Payment Tolerance
        SetGenJnlLineProcessWithPmtTol(GenJournalLine);

        // [WHEN] Post the payment
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] There are several G/L Entries, including:
        // [THEN] "G/L Account No." = <Receivables Account>, "Amount" = -3924.21, "VAT Amount" = 0
        // [THEN] "G/L Account No." = <payment balance account>, "Amount" = 3924.03, "VAT Amount" = 0
        // [THEN] "G/L Account No." = <Sales Pmt. Tol. Debit Acc.>, "Amount" = 0.16, "VAT Amount" = 0.02
        // [THEN] several "G/L Account No." = <Sales VAT Account> with total "Amount" = 0.02, "VAT Amount" = 0
        VerifyGLEntryCount(GenJournalLine."Document No.", 13);
        VerifyGLEntryForAccount(GenJournalLine."Document No.", GetReceivablesAccountNo(CustomerNo), -3924.21, 0);
        VerifyGLEntryForAccount(GenJournalLine."Document No.", GenJournalLine."Bal. Account No.", 3924.03, 0);
        VerifyGLEntryForAccount(GenJournalLine."Document No.", GetSalesPmtTolDebitAcc(GLAccountNo), 0.16, 0.02);
        VerifyGLEntryForAccount(GenJournalLine."Document No.", GetSalesVATAccountNo(GLAccountNo), 0.02, 0);

        // [THEN] There are several VAT Enties with total "Base" = 0.16, "Amount" = 0.02
        VerifyVATEntryCount(GenJournalLine."Document No.", 8);
        VerifyVATEntry(GenJournalLine."Document No.", 0.16, 0.02);
    end;

    [Test]
    [HandlerFunctions('PaymentToleranceWarning_MPH')]
    [Scope('OnPrem')]
    procedure PurchVATPaymentToleranceWithVATDifferenceNegativeLinesAndRounding()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorNo: Code[20];
        GLAccountNo: Code[20];
        InvoiceNo: array[3] of Code[20];
        i: Integer;
    begin
        // [FEATURE] [Payment Tolerance] [Rounding] [VAT Difference] [Purchase]
        // [SCENARIO 227380] Post vendor payment journal applied to several invoices
        // [SCENARIO 227380] in case of Payment Tolerance, VAT Difference, negative invoice lines and rounding
        Initialize();

        // [GIVEN] "Payment Tolerance %" = 5, "Max. Paym. Tol. Amount" = 20, "Max. VAT Difference Allowed" = 0.01
        SetupPmtTolAndVATDifference(5, 20, 0.01);

        // [GIVEN] VAT Posting Setup with "VAT %" = 19
        CreateVendorAndGLAccount(VendorNo, GLAccountNo, 19);

        // [GIVEN] Posted journal with 3 vendor invoices (total Amount = 3924,21) each with several lines:
        // [GIVEN] Invoice1: 2852.93 = 2231.96 + 620.97
        // [GIVEN] Invoice2: 535.64 = 743.99 - 252.97 + 74.39 - 29.77 (where 74.39 has VAT Amount = 11.87, VAT Difference = 0.01)
        // [GIVEN] Invoice3: 535.64 = 743.99 - 252.97 + 74.39 - 29.77 (where 74.39 has VAT Amount = 11.87, VAT Difference = 0.01)
        CreatePostVendorThreeInvoicesFromTheJournal_227380(GenJournalLine, InvoiceNo, VendorNo, GLAccountNo);

        // [GIVEN] Create vendor payment with Amount = 3924.03
        CreateVendorPaymentGenJnlLine(GenJournalLine, VendorNo, 3924.03);
        // [GIVEN] Apply payment to 3 posted invoices
        UpdateGenJnlLineAppliesToID(GenJournalLine);
        for i := 1 to ArrayLen(InvoiceNo) do
            SetApplyIDVendLedgEntry(InvoiceNo[i]);
        // [GIVEN] Confirm process difference = 0.18 as Payment Tolerance
        SetGenJnlLineProcessWithPmtTol(GenJournalLine);

        // [WHEN] Post the payment
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] There are several G/L Entries, including:
        // [THEN] "G/L Account No." = <Payables Account>, "Amount" = 3924.21, "VAT Amount" = 0
        // [THEN] "G/L Account No." = <payment balance account>, "Amount" = -3924.03, "VAT Amount" = 0
        // [THEN] "G/L Account No." = <Purch. Pmt. Tol. Credit Acc.>, "Amount" = -0.16, "VAT Amount" = -0.02
        // [THEN] several "G/L Account No." = <Purchase VAT Account> with total "Amount" = -0.02, "VAT Amount" = 0
        VerifyGLEntryCount(GenJournalLine."Document No.", 13);
        VerifyGLEntryForAccount(GenJournalLine."Document No.", GetPayablesAccountNo(VendorNo), 3924.21, 0);
        VerifyGLEntryForAccount(GenJournalLine."Document No.", GenJournalLine."Bal. Account No.", -3924.03, 0);
        VerifyGLEntryForAccount(GenJournalLine."Document No.", GetPurchPmtTolCreditAcc(GLAccountNo), -0.16, -0.02);
        VerifyGLEntryForAccount(GenJournalLine."Document No.", GetPurchaseVATAccountNo(GLAccountNo), -0.02, 0);

        // [THEN] There are several VAT Enties with total "Base" = 0.16, "Amount" = 0.02
        VerifyVATEntryCount(GenJournalLine."Document No.", 8);
        VerifyVATEntry(GenJournalLine."Document No.", -0.16, -0.02);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Pmt Disc And VAT Cust/Vend");
        LibrarySetupStorage.Restore();
        if isInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Pmt Disc And VAT Cust/Vend");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryPmtDiscSetup.ClearAdjustPmtDiscInVATSetup();
        UpdateDefaultVATSetupPct();
        isInitialized := true;
        Commit();
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Pmt Disc And VAT Cust/Vend");
    end;

    local procedure SetupPmtTolAndVATDifference(PmtTolPct: Decimal; MaxPmtTolAmount: Decimal; MaxVATDifferenceAllowed: Decimal)
    begin
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(true);
        LibraryPmtDiscSetup.SetPmtToleranceWarning(true);
        SetPmtTolPctAndAmount(PmtTolPct, MaxPmtTolAmount);
        LibraryERM.SetMaxVATDifferenceAllowed(MaxVATDifferenceAllowed);
        LibraryERM.SetVATRoundingType('=');
    end;

    local procedure PrepareGenJnlLine(var GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        GenJournalLine."Journal Template Name" := GenJournalBatch."Journal Template Name";
        GenJournalLine."Journal Batch Name" := GenJournalBatch.Name;
    end;

    local procedure CreatePostCustomerThreeInvoicesFromTheJournal_227380(var GenJournalLine: Record "Gen. Journal Line"; var InvoiceNo: array[3] of Code[20]; CustomerNo: Code[20]; GLAccountNo: Code[20])
    begin
        PrepareGenJnlLine(GenJournalLine);
        UpdateGenJnlTemplateAllowVATDifference(GenJournalLine."Journal Template Name", true);

        CreateCustomerInvoiceGenJnlLine(GenJournalLine, CustomerNo, 2852.93);
        CreateGLAccountInvoiceGenJnlLine(GenJournalLine, GLAccountNo, -2231.96);
        CreateGLAccountInvoiceGenJnlLine(GenJournalLine, GLAccountNo, -620.97);
        InvoiceNo[1] := GenJournalLine."Document No.";

        CreateCustomerInvoiceGenJnlLine(GenJournalLine, CustomerNo, 535.64);
        CreateGLAccountInvoiceGenJnlLine(GenJournalLine, GLAccountNo, -743.99);
        CreateGLAccountInvoiceGenJnlLine(GenJournalLine, GLAccountNo, 252.97);
        CreateGLAccountInvoiceGenJnlLine(GenJournalLine, GLAccountNo, -74.39);
        UpdateGenJnlLineVATAmount(GenJournalLine, -11.87);
        CreateGLAccountInvoiceGenJnlLine(GenJournalLine, GLAccountNo, 29.77);
        InvoiceNo[2] := GenJournalLine."Document No.";

        CreateCustomerInvoiceGenJnlLine(GenJournalLine, CustomerNo, 535.64);
        CreateGLAccountInvoiceGenJnlLine(GenJournalLine, GLAccountNo, -743.99);
        CreateGLAccountInvoiceGenJnlLine(GenJournalLine, GLAccountNo, 252.97);
        CreateGLAccountInvoiceGenJnlLine(GenJournalLine, GLAccountNo, -74.39);
        UpdateGenJnlLineVATAmount(GenJournalLine, -11.87);
        CreateGLAccountInvoiceGenJnlLine(GenJournalLine, GLAccountNo, 29.77);
        InvoiceNo[3] := GenJournalLine."Document No.";

        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreatePostVendorThreeInvoicesFromTheJournal_227380(var GenJournalLine: Record "Gen. Journal Line"; var InvoiceNo: array[3] of Code[20]; VendorNo: Code[20]; GLAccountNo: Code[20])
    begin
        PrepareGenJnlLine(GenJournalLine);
        UpdateGenJnlTemplateAllowVATDifference(GenJournalLine."Journal Template Name", true);

        CreateVendorInvoiceGenJnlLine(GenJournalLine, VendorNo, -2852.93);
        CreateGLAccountInvoiceGenJnlLine(GenJournalLine, GLAccountNo, 2231.96);
        CreateGLAccountInvoiceGenJnlLine(GenJournalLine, GLAccountNo, 620.97);
        InvoiceNo[1] := GenJournalLine."Document No.";

        CreateVendorInvoiceGenJnlLine(GenJournalLine, VendorNo, -535.64);
        CreateGLAccountInvoiceGenJnlLine(GenJournalLine, GLAccountNo, 743.99);
        CreateGLAccountInvoiceGenJnlLine(GenJournalLine, GLAccountNo, -252.97);
        CreateGLAccountInvoiceGenJnlLine(GenJournalLine, GLAccountNo, 74.39);
        UpdateGenJnlLineVATAmount(GenJournalLine, 11.87);
        CreateGLAccountInvoiceGenJnlLine(GenJournalLine, GLAccountNo, -29.77);
        InvoiceNo[2] := GenJournalLine."Document No.";

        CreateVendorInvoiceGenJnlLine(GenJournalLine, VendorNo, -535.64);
        CreateGLAccountInvoiceGenJnlLine(GenJournalLine, GLAccountNo, 743.99);
        CreateGLAccountInvoiceGenJnlLine(GenJournalLine, GLAccountNo, -252.97);
        CreateGLAccountInvoiceGenJnlLine(GenJournalLine, GLAccountNo, 74.39);
        UpdateGenJnlLineVATAmount(GenJournalLine, 11.87);
        CreateGLAccountInvoiceGenJnlLine(GenJournalLine, GLAccountNo, -29.77);
        InvoiceNo[3] := GenJournalLine."Document No.";

        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateFULLVATPostingSetup(var VATPostingSetup_FULLVAT: Record "VAT Posting Setup")
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup_FULLVAT, VATPostingSetup_FULLVAT."VAT Calculation Type"::"Full VAT", 100);
        VATPostingSetup_FULLVAT.Validate("Sales VAT Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup_FULLVAT, GLAccount."Gen. Posting Type"::Sale));
        VATPostingSetup_FULLVAT.Validate("Purchase VAT Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup_FULLVAT, GLAccount."Gen. Posting Type"::Purchase));
        VATPostingSetup_FULLVAT.Validate("Adjust for Payment Discount", true);
        VATPostingSetup_FULLVAT.Modify(true);

        GLAccount.Get(VATPostingSetup_FULLVAT."Purchase VAT Account");
        UpdateGeneralPostingSetupPurch(GLAccount."Gen. Bus. Posting Group", GLAccount."Gen. Prod. Posting Group", LibraryERM.CreateGLAccountNo());
        GLAccount.Get(VATPostingSetup_FULLVAT."Sales VAT Account");
        UpdateGeneralPostingSetupSales(GLAccount."Gen. Bus. Posting Group", GLAccount."Gen. Prod. Posting Group", LibraryERM.CreateGLAccountNo());
    end;

    local procedure CreateNormalVATPostingSetupWithAdjPmtDisc(var VATPostingSetup: Record "VAT Posting Setup"; VATPct: Decimal)
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", VATPct);
        VATPostingSetup.Validate("Adjust for Payment Discount", true);
        VATPostingSetup.Modify(true);
    end;

    local procedure CreateGeneralPostingSetup(var GeneralPostingSetup: Record "General Posting Setup")
    var
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
    begin
        LibraryERM.CreateGenBusPostingGroup(GenBusinessPostingGroup);
        LibraryERM.CreateGenProdPostingGroup(GenProductPostingGroup);
        LibraryERM.CreateGeneralPostingSetup(GeneralPostingSetup, GenBusinessPostingGroup.Code, GenProductPostingGroup.Code);
        GeneralPostingSetup."Sales Pmt. Tol. Debit Acc." := LibraryERM.CreateGLAccountNo();
        GeneralPostingSetup."Purch. Pmt. Tol. Credit Acc." := LibraryERM.CreateGLAccountNo();
        GeneralPostingSetup.Modify(true);
    end;

    local procedure CreateCustomer(VATBusPostingGroup: Code[20]; var DiscountPct: Decimal): Code[20]
    var
        Customer: Record Customer;
        PaymentTerms: Record "Payment Terms";
    begin
        LibraryERM.GetDiscountPaymentTerm(PaymentTerms);
        DiscountPct := PaymentTerms."Discount %";
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Application Method", Customer."Application Method"::"Apply to Oldest");
        Customer.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Customer.Validate("Payment Terms Code", PaymentTerms.Code);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateCustomerAndItem(var Customer: Record Customer; var Item: Record Item; VATPostingSetup: Record "VAT Posting Setup")
    var
        DiscountPct: Decimal;
    begin
        Customer.Get(CreateCustomer(VATPostingSetup."VAT Bus. Posting Group", DiscountPct));
        Item.Get(CreateItemWithVATProdPostGroup(VATPostingSetup."VAT Prod. Posting Group"));
    end;

    local procedure CreateCustomerWithoutVATBusPostGroup(var DiscountPct: Decimal): Code[20]
    var
        Customer: Record Customer;
        PaymentTerms: Record "Payment Terms";
    begin
        LibraryERM.GetDiscountPaymentTerm(PaymentTerms);
        DiscountPct := PaymentTerms."Discount %";
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Application Method", Customer."Application Method"::Manual);
        Customer.Validate("Payment Terms Code", PaymentTerms.Code);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateCustomerAndGLAccount(var CustomerNo: Code[20]; var GLAccountNo: Code[20]; VATPct: Decimal)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        GLAccount: Record "G/L Account";
    begin
        CreateNormalVATPostingSetupWithAdjPmtDisc(VATPostingSetup, VATPct);
        CreateGeneralPostingSetup(GeneralPostingSetup);

        CustomerNo :=
          LibrarySales.CreateCustomerWithBusPostingGroups(
            GeneralPostingSetup."Gen. Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.UpdateGLAccountWithPostingSetup(
          GLAccount, GLAccount."Gen. Posting Type"::Sale, GeneralPostingSetup, VATPostingSetup);
        GLAccountNo := GLAccount."No.";
    end;

    local procedure CreateGLAccount(GenProdPostingGroup: Code[20]; VATProdPostingGroup: Code[20]): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Prod. Posting Group", GenProdPostingGroup);
        GLAccount.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateItemWithVATProdPostGroup(VATProdPostingGroup: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreatePostGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          AccountType, AccountNo, Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateVendorInvoiceGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; VendorNo: Code[20]; LineAmount: Decimal)
    begin
        CreateGenJnlLine(GenJournalLine, '', GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Vendor, VendorNo, LineAmount);
    end;

    local procedure CreateVendorInvoiceGenJnlLineWithDocumentNo(var GenJournalLine: Record "Gen. Journal Line"; VendorNo: Code[20]; LineAmount: Decimal)
    begin
        CreateGenJnlLine(GenJournalLine, GenJournalLine."Document No.", GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Vendor, VendorNo, LineAmount);
    end;

    local procedure CreateCustomerInvoiceGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; CustomerNo: Code[20]; LineAmount: Decimal)
    begin
        CreateGenJnlLine(GenJournalLine, '', GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, CustomerNo, LineAmount);
    end;

    local procedure CreateCustomerInvoiceGenJnlLineWithDocumentNo(var GenJournalLine: Record "Gen. Journal Line"; CustomerNo: Code[20]; LineAmount: Decimal)
    begin
        CreateGenJnlLine(
              GenJournalLine, GenJournalLine."Document No.", GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, CustomerNo, LineAmount);
    end;

    local procedure CreatePostVendorPaymentGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; VendorNo: Code[20]; LineAmount: Decimal)
    begin
        CreateVendorPaymentGenJnlLine(GenJournalLine, VendorNo, LineAmount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateVendorPaymentGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; VendorNo: Code[20]; LineAmount: Decimal)
    begin
        PrepareGenJnlLine(GenJournalLine);
        LibraryJournals.CreateGenJournalLine(
              GenJournalLine, GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name",
              GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, VendorNo,
              GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), LineAmount);
    end;

    local procedure CreatePostCustomerPaymentGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; CustomerNo: Code[20]; LineAmount: Decimal)
    begin
        CreateCustomerPaymentGenJnlLine(GenJournalLine, CustomerNo, LineAmount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateCustomerPaymentGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; CustomerNo: Code[20]; LineAmount: Decimal)
    begin
        PrepareGenJnlLine(GenJournalLine);
        LibraryJournals.CreateGenJournalLine(
              GenJournalLine, GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name",
              GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer, CustomerNo,
              GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), LineAmount);
    end;

    local procedure CreateGLAccountInvoiceGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; GLAccountNo: Code[20]; LineAmount: Decimal)
    begin
        CreateGenJnlLine(GenJournalLine, GenJournalLine."Document No.", GenJournalLine."Document Type"::Invoice,
              GenJournalLine."Account Type"::"G/L Account", GLAccountNo, LineAmount);
    end;

    local procedure CreateGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; UseDocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; GenJnlAmount: Decimal): Code[20]
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name",
          DocumentType, AccountType, AccountNo, GenJnlAmount);
        if UseDocumentNo <> '' then begin
            GenJournalLine.Validate("Document No.", UseDocumentNo);
            GenJournalLine.Modify(true);
        end;
        exit(GenJournalLine."Document No.");
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20]; ItemNo: Code[20]; DocumentType: Enum "Purchase Document Type") LineAmount: Decimal
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseHeader(PurchaseHeader, DocumentType, VendorNo);
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo);
        LineAmount := PurchaseLine."Line Amount";
        CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
          CreateGLAccount(PurchaseLine."Gen. Prod. Posting Group", PurchaseLine."VAT Prod. Posting Group"));
        LineAmount := LineAmount + PurchaseLine."Line Amount";
    end;

    local procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
    end;

    local procedure CreatePurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; Type: Enum "Purchase Line Type"; No: Code[20])
    begin
        // Take Random Quantity and Direct Unit Cost.
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type, No, LibraryRandom.RandDecInRange(10, 20, 2));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(1000, 2000, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; ItemNo: Code[20]; DocumentType: Enum "Sales Document Type") LineAmount: Decimal
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo);
        LineAmount := SalesLine."Line Amount";
        CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account",
          CreateGLAccount(SalesLine."Gen. Prod. Posting Group", SalesLine."VAT Prod. Posting Group"));
        LineAmount := LineAmount + SalesLine."Line Amount";
    end;

    local procedure CreateSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; Type: Enum "Sales Line Type"; No: Code[20])
    begin
        // Take Random Quantity and Unit Price.
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Type, No, LibraryRandom.RandDecInRange(10, 20, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(1000, 2000, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreateVendor(UseVATBusPostingGroup: Code[20]; var DiscountPct: Decimal): Code[20]
    var
        PaymentTerms: Record "Payment Terms";
        Vendor: Record Vendor;
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.SetRange("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::" ");
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        if UseVATBusPostingGroup = '' then
            UseVATBusPostingGroup := VATPostingSetup."VAT Bus. Posting Group";
        LibraryERM.GetDiscountPaymentTerm(PaymentTerms);
        DiscountPct := PaymentTerms."Discount %";
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Application Method", Vendor."Application Method"::"Apply to Oldest");
        Vendor.Validate("VAT Bus. Posting Group", UseVATBusPostingGroup);
        Vendor.Validate("Payment Terms Code", PaymentTerms.Code);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateVendorAndItem(var Vendor: Record Vendor; var Item: Record Item; VATPostingSetup: Record "VAT Posting Setup")
    var
        DiscountPct: Decimal;
    begin
        Vendor.Get(CreateVendor('', DiscountPct));
        Item.Get(CreateItemWithVATProdPostGroup(VATPostingSetup."VAT Prod. Posting Group"));
    end;

    local procedure CreateVendorWithoutVATBusPostGroup(UseVATBusPostingGroup: Code[20]; var DiscountPct: Decimal): Code[20]
    var
        PaymentTerms: Record "Payment Terms";
        Vendor: Record Vendor;
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.SetRange("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::" ");
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        if UseVATBusPostingGroup = '' then
            UseVATBusPostingGroup := VATPostingSetup."VAT Bus. Posting Group";
        LibraryERM.GetDiscountPaymentTerm(PaymentTerms);
        DiscountPct := PaymentTerms."Discount %";
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Application Method", Vendor."Application Method"::Manual);
        Vendor.Validate("Payment Terms Code", PaymentTerms.Code);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateVendorAndGLAccount(var VendorNo: Code[20]; var GLAccountNo: Code[20]; VATPct: Decimal)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        GLAccount: Record "G/L Account";
    begin
        CreateNormalVATPostingSetupWithAdjPmtDisc(VATPostingSetup, VATPct);
        CreateGeneralPostingSetup(GeneralPostingSetup);

        VendorNo :=
          LibraryPurchase.CreateVendorWithBusPostingGroups(
            GeneralPostingSetup."Gen. Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.UpdateGLAccountWithPostingSetup(
          GLAccount, GLAccount."Gen. Posting Type"::Purchase, GeneralPostingSetup, VATPostingSetup);
        GLAccountNo := GLAccount."No.";
    end;

    local procedure CreateNormalVATPostingSetupWithPmtDiscount(var NormalVATPostingSetup: Record "VAT Posting Setup")
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(
          NormalVATPostingSetup, NormalVATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandIntInRange(1, 25));
        NormalVATPostingSetup.Validate("Sales VAT Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(NormalVATPostingSetup, GLAccount."Gen. Posting Type"::Sale));
        NormalVATPostingSetup.Validate("Purchase VAT Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(NormalVATPostingSetup, GLAccount."Gen. Posting Type"::Purchase));
        NormalVATPostingSetup.Validate("Adjust for Payment Discount", true);
        NormalVATPostingSetup.Modify(true);

        GLAccount.Get(NormalVATPostingSetup."Purchase VAT Account");
        UpdateGeneralPostingSetupPurch(GLAccount."Gen. Bus. Posting Group", GLAccount."Gen. Prod. Posting Group", LibraryERM.CreateGLAccountNo());
        GLAccount.Get(NormalVATPostingSetup."Sales VAT Account");
        UpdateGeneralPostingSetupSales(GLAccount."Gen. Bus. Posting Group", GLAccount."Gen. Prod. Posting Group", LibraryERM.CreateGLAccountNo());
    end;

    local procedure CreatePostGenJnlLinesInvoiceVendor(var GenJournalLine: Record "Gen. Journal Line"; FullVATPostingSetup: Record "VAT Posting Setup"; GLAccountNo: Code[20]; VendorNo: Code[20]; var PmtAmount: Decimal; var Amount: Decimal; var AmountFullVAT: Decimal)
    begin
        Amount := LibraryRandom.RandDecInRange(1000, 10000, 2);
        AmountFullVAT := LibraryRandom.RandDecInRange(100, 500, 2);
        PmtAmount := 2 * (Amount + AmountFullVAT);

        PrepareGenJnlLine(GenJournalLine);
        CreateGLAccountInvoiceGenJnlLine(GenJournalLine, GLAccountNo, Amount);
        CreateGLAccountInvoiceGenJnlLine(GenJournalLine, FullVATPostingSetup."Purchase VAT Account", AmountFullVAT);
        CreateGLAccountInvoiceGenJnlLine(GenJournalLine, GLAccountNo, Amount);
        CreateGLAccountInvoiceGenJnlLine(GenJournalLine, FullVATPostingSetup."Purchase VAT Account", AmountFullVAT);
        CreateVendorInvoiceGenJnlLineWithDocumentNo(GenJournalLine, VendorNo, -PmtAmount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreatePostGenJnlLinesInvoiceCustomer(var GenJournalLine: Record "Gen. Journal Line"; FullVATPostingSetup: Record "VAT Posting Setup"; GLAccountNo: Code[20]; CustomerNo: Code[20]; var PmtAmount: Decimal; var Amount: Decimal; var AmountFullVAT: Decimal)
    begin
        Amount := LibraryRandom.RandDecInRange(1000, 10000, 2);
        AmountFullVAT := LibraryRandom.RandDecInRange(100, 500, 2);
        PmtAmount := 2 * (Amount + AmountFullVAT);

        PrepareGenJnlLine(GenJournalLine);
        CreateGLAccountInvoiceGenJnlLine(GenJournalLine, GLAccountNo, -Amount);
        CreateGLAccountInvoiceGenJnlLine(GenJournalLine, FullVATPostingSetup."Sales VAT Account", -AmountFullVAT);
        CreateGLAccountInvoiceGenJnlLine(GenJournalLine, GLAccountNo, -Amount);
        CreateGLAccountInvoiceGenJnlLine(GenJournalLine, FullVATPostingSetup."Sales VAT Account", -AmountFullVAT);
        CreateCustomerInvoiceGenJnlLineWithDocumentNo(GenJournalLine, CustomerNo, PmtAmount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure GLEntriesVerification(var GLEntry: Record "G/L Entry"; ExpectedAmount: Decimal; ExpectedVATAmount: Decimal)
    var
        ActualAmount: Decimal;
        ActualVATAmount: Decimal;
    begin
        GLEntry.FindSet();
        GLEntry.CalcSums(Amount, "VAT Amount");
        ActualAmount := GLEntry.Amount;
        ActualVATAmount := GLEntry."VAT Amount";

        Assert.AreNearlyEqual(
          ExpectedAmount, ActualAmount, LibraryERM.GetInvoiceRoundingPrecisionLCY(),
          StrSubstNo(AmountError, GLEntry.FieldCaption(Amount), ExpectedAmount, GLEntry.TableCaption()));

        Assert.AreNearlyEqual(
          ExpectedVATAmount, ActualVATAmount, LibraryERM.GetInvoiceRoundingPrecisionLCY(),
          StrSubstNo(AmountError, GLEntry.FieldCaption("VAT Amount"), ExpectedVATAmount, GLEntry.TableCaption()));
    end;

    local procedure FindVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        VATPostingSetup.SetRange("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::" ");
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
    end;

    local procedure PurchasePaymentDiscount(var GenJournalLine: Record "Gen. Journal Line"; VATPostingSetup: Record "VAT Posting Setup"; VendorNo: Code[20]; ItemNo: Code[20]) DiscountAmountExclVAT: Decimal
    var
        PurchaseHeader: Record "Purchase Header";
        LineAmount: Decimal;
        VATAmount: Decimal;
        DiscountAmount: Decimal;
    begin
        // Setup: Update VAT Posting Setup, Create and Post Purchase Invoice.
        UpdateVATPostingSetup(VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group", true);
        LineAmount := CreatePurchaseDocument(PurchaseHeader, VendorNo, ItemNo, PurchaseHeader."Document Type"::Invoice);
        VATAmount := LineAmount * VATPostingSetup."VAT %" / 100;
        DiscountAmount := Round((LineAmount + VATAmount) * PurchaseHeader."Payment Discount %" / 100);
        DiscountAmountExclVAT := Round(LineAmount * PurchaseHeader."Payment Discount %" / 100);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Exercise: Make Payment for the Posted Purchase Invoice.
        CreatePostGeneralJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, VendorNo, LineAmount + VATAmount - DiscountAmount);
    end;

    local procedure SalesPaymentDiscount(var GenJournalLine: Record "Gen. Journal Line"; VATPostingSetup: Record "VAT Posting Setup"; CustomerNo: Code[20]; ItemNo: Code[20]) DiscountAmountExclVAT: Decimal
    var
        SalesHeader: Record "Sales Header";
        LineAmount: Decimal;
        VATAmount: Decimal;
        DiscountAmount: Decimal;
    begin
        // Setup: Update VAT Posting Setup, Create and Post Sales Invoice.
        UpdateVATPostingSetup(VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group", true);
        LineAmount := CreateSalesDocument(SalesHeader, CustomerNo, ItemNo, SalesHeader."Document Type"::Invoice);
        VATAmount := LineAmount * VATPostingSetup."VAT %" / 100;
        DiscountAmount := Round((LineAmount + VATAmount) * SalesHeader."Payment Discount %" / 100);
        DiscountAmountExclVAT := Round(LineAmount * SalesHeader."Payment Discount %" / 100);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Exercise: Make Payment for the Posted Sales Invoice.
        CreatePostGeneralJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::Customer, CustomerNo, -(LineAmount + VATAmount - DiscountAmount));
    end;

    local procedure SetApplyIDCustLedgEntry(InvoiceNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, InvoiceNo);
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry);
    end;

    local procedure SetApplyIDVendLedgEntry(InvoiceNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, InvoiceNo);
        LibraryERM.SetAppliestoIdVendor(VendorLedgerEntry);
    end;

    local procedure SetPmtTolPctAndAmount(PmtTolPct: Decimal; MaxPmtTolAmount: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Payment Tolerance %", PmtTolPct);
        GeneralLedgerSetup.Validate("Max. Payment Tolerance Amount", MaxPmtTolAmount);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure SetGenJnlLineProcessWithPmtTol(var GenJournalLine: Record "Gen. Journal Line")
    var
        PaymentToleranceMgt: Codeunit "Payment Tolerance Management";
    begin
        PaymentToleranceMgt.PmtTolGenJnl(GenJournalLine);
    end;

    local procedure GetReceivablesAccountNo(CustomerNo: Code[20]): Code[20]
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        Customer.Get(CustomerNo);
        CustomerPostingGroup.Get(Customer."Customer Posting Group");
        exit(CustomerPostingGroup.GetReceivablesAccount());
    end;

    local procedure GetPayablesAccountNo(VendorNo: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        Vendor.Get(VendorNo);
        VendorPostingGroup.Get(Vendor."Vendor Posting Group");
        exit(VendorPostingGroup.GetPayablesAccount());
    end;

    local procedure GetSalesVATAccountNo(GLAccountNo: Code[20]): Code[20]
    var
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        GLAccount.Get(GLAccountNo);
        VATPostingSetup.Get(GLAccount."VAT Bus. Posting Group", GLAccount."VAT Prod. Posting Group");
        exit(VATPostingSetup."Sales VAT Account");
    end;

    local procedure GetPurchaseVATAccountNo(GLAccountNo: Code[20]): Code[20]
    var
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        GLAccount.Get(GLAccountNo);
        VATPostingSetup.Get(GLAccount."VAT Bus. Posting Group", GLAccount."VAT Prod. Posting Group");
        exit(VATPostingSetup."Purchase VAT Account");
    end;

    local procedure GetSalesPmtTolDebitAcc(GLAccountNo: Code[20]): Code[20]
    var
        GLAccount: Record "G/L Account";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GLAccount.Get(GLAccountNo);
        GeneralPostingSetup.Get(GLAccount."Gen. Bus. Posting Group", GLAccount."Gen. Prod. Posting Group");
        exit(GeneralPostingSetup."Sales Pmt. Tol. Debit Acc.");
    end;

    local procedure GetPurchPmtTolCreditAcc(GLAccountNo: Code[20]): Code[20]
    var
        GLAccount: Record "G/L Account";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GLAccount.Get(GLAccountNo);
        GeneralPostingSetup.Get(GLAccount."Gen. Bus. Posting Group", GLAccount."Gen. Prod. Posting Group");
        exit(GeneralPostingSetup."Purch. Pmt. Tol. Credit Acc.");
    end;

    local procedure UnapplyPurchaseDocument(DocumentNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Payment, DocumentNo);
        LibraryERM.UnapplyVendorLedgerEntry(VendorLedgerEntry);
    end;

    local procedure UnapplySalesDocument(DocumentNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, DocumentNo);
        LibraryERM.UnapplyCustomerLedgerEntry(CustLedgerEntry);
    end;

    local procedure UpdateGeneralPostingSetupPurch(GenBusPostingGroup: Code[20]; GenProdPostingGroup: Code[20]; PurchPmtDiscCreditAcc: Code[20]) OldPurchPmtDiscCreditAcc: Code[20]
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GeneralPostingSetup.Get(GenBusPostingGroup, GenProdPostingGroup);
        OldPurchPmtDiscCreditAcc := GeneralPostingSetup."Purch. Pmt. Disc. Credit Acc.";
        GeneralPostingSetup."Purch. Pmt. Disc. Credit Acc." := PurchPmtDiscCreditAcc;  // Using assignment to avoid error in ES.
        GeneralPostingSetup.Modify(true);
    end;

    local procedure UpdateGeneralPostingSetupSales(GenBusPostingGroup: Code[20]; GenProdPostingGroup: Code[20]; SalesPmtDiscDebitAcc: Code[20]) OldSalesPmtDiscDebitAcc: Code[20]
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GeneralPostingSetup.Get(GenBusPostingGroup, GenProdPostingGroup);
        OldSalesPmtDiscDebitAcc := GeneralPostingSetup."Sales Pmt. Disc. Debit Acc.";
        GeneralPostingSetup."Sales Pmt. Disc. Debit Acc." := SalesPmtDiscDebitAcc;  // Using assignment to avoid error in ES.
        GeneralPostingSetup.Modify(true);
    end;

    local procedure UpdateVATPostingSetup(VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20]; AdjustforPaymentDiscount: Boolean)
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.Get(VATBusPostingGroup, VATProdPostingGroup);
        VATPostingSetup.Validate("Adjust for Payment Discount", AdjustforPaymentDiscount);
        VATPostingSetup.Modify(true);
    end;

    local procedure UpdateDefaultVATSetupPct()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.SetRange("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::" ");
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.Validate("VAT %", 25);
        VATPostingSetup.Modify(true);
    end;

    local procedure UpdateGenJnlLineVATAmount(var GenJournalLine: Record "Gen. Journal Line"; NewVATAmount: Decimal)
    begin
        GenJournalLine.Validate("VAT Amount", NewVATAmount);
        GenJournalLine.Modify(true);
    end;

    local procedure UpdateGenJnlLineAppliesToID(var GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine.Validate("Applies-to ID", UserId);
        GenJournalLine.Modify(true);
    end;

    local procedure UpdateGenJnlTemplateAllowVATDifference(GenJournalTemplateName: Code[10]; AllowVATDifference: Boolean)
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.Get(GenJournalTemplateName);
        GenJournalTemplate.Validate("Allow VAT Difference", AllowVATDifference);
        GenJournalTemplate.Modify(true);
    end;

    local procedure VerifyGLEntry(DocumentNo: Code[20]; GenBusPostingGroup: Code[20]; GenProdPostingGroup: Code[20]; ExpectedAmount: Decimal; ExpectedVATAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("Gen. Bus. Posting Group", GenBusPostingGroup);
        GLEntry.SetRange("Gen. Prod. Posting Group", GenProdPostingGroup);
        GLEntriesVerification(GLEntry, ExpectedAmount, ExpectedVATAmount);
    end;

    local procedure VerifyGLEntryForAccount(DocumentNo: Code[20]; GLAccountNo: Code[20]; ExpectedAmount: Decimal; ExpectedVATAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.CalcSums(Amount, "VAT Amount");
        GLEntry.TestField(Amount, ExpectedAmount);
        GLEntry.TestField("VAT Amount", ExpectedVATAmount);
    end;

    local procedure VerifyPmtDiscEntryInGLEntry(DocumentNo: Code[20]; GLAccountNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; ExpectedAmount: Decimal; ExpectedVATAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("Document Type", DocumentType);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntriesVerification(GLEntry, ExpectedAmount, ExpectedVATAmount);
    end;

    local procedure VerifyVATEntry(DocumentNo: Code[20]; ExpectedBase: Decimal; ExpectedAmount: Decimal)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.CalcSums(Base, Amount);
        Assert.AreEqual(
          ExpectedBase, VATEntry.Base,
          StrSubstNo(AmountError, VATEntry.FieldCaption(Base), ExpectedBase, VATEntry.TableCaption));
        Assert.AreEqual(
          ExpectedAmount, VATEntry.Amount,
          StrSubstNo(AmountError, VATEntry.FieldCaption(Amount), ExpectedAmount, VATEntry.TableCaption));
    end;

    local procedure VerifyVATEntryVatDate(DocumentNo: Code[20]; ExpectedVATDate: Date)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.FindFirst();
        Assert.AreEqual(
            ExpectedVATDate, VATEntry."VAT Reporting Date", StrSubstNo(AmountError, VATEntry.FieldCaption("VAT Reporting Date"), ExpectedVATDate, VATEntry.TableCaption)
        );
    end;

    local procedure VerifyVATEntryCount(DocumentNo: Code[20]; ExpectedCount: Integer)
    var
        DummyVATEntry: Record "VAT Entry";
    begin
        DummyVATEntry.SetRange("Document No.", DocumentNo);
        Assert.RecordCount(DummyVATEntry, ExpectedCount);
    end;

    local procedure VerifyGLEntryCount(DocumentNo: Code[20]; ExpectedCount: Integer)
    var
        DummyGLEntry: Record "G/L Entry";
    begin
        DummyGLEntry.SetRange("Document No.", DocumentNo);
        Assert.RecordCount(DummyGLEntry, ExpectedCount);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PaymentToleranceWarning_MPH(var PaymentToleranceWarning: TestPage "Payment Tolerance Warning")
    var
        Posting: Option " ","Payment Tolerance Accounts","Remaining Amount";
    begin
        PaymentToleranceWarning.Posting.SetValue(Posting::"Payment Tolerance Accounts");
        PaymentToleranceWarning.Yes().Invoke();
    end;
}

