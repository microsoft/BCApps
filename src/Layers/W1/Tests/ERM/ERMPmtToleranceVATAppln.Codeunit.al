codeunit 134041 "ERM Pmt. Tolerance VAT Appln."
{
    Permissions = TableData "Cust. Ledger Entry" = rimd,
                  TableData "Vendor Ledger Entry" = rimd;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Payment Tolerance]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPmtDiscSetup: Codeunit "Library - Pmt Disc Setup";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;
        PaymentToleranceLineErr: Label '%1 does not contain a line with payment tolerance VAT Amount';
        PostingAction: Option " ","Payment Tolerance Accounts","Remaining Amount";
        VATIdTok: Label 'VAT-%1%';
        UnappliedLineErr: Label '%1 must not contain entry for G/L account %2';
        WrongVATEntriesAmountErr: Label 'Wrong amount on VAT entries with filters %1.';

    [Test]
    [HandlerFunctions('ConfirmHandler,CustomerLedgerEntriesPageHandlerUnapply,UnapplyCustomerEntriesPageHandler,MessageHandler,PaymentToleranceWarningHandler,ApplyCustomerEntriesPageHandlerSelectLastDocument')]
    [Scope('OnPrem')]
    procedure PaymentToleranceUnapplyPartialPaymentNormalVATSales()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        CustomerPostingGroup: Record "Customer Posting Group";
        VATEntry: Record "VAT Entry";
        PaymentToleranceAmount: Decimal;
    begin
        Initialize();
        SetupUnapplyPaymentWithPaymentToleranceScenario(
          Customer,
          GeneralPostingSetup,
          VATPostingSetup,
          VATEntry."VAT Calculation Type"::"Normal VAT",
          LibraryRandom.RandIntInRange(10, 30));
        CustomerPostingGroup.Get(Customer."Customer Posting Group");

        // Excercise: Post invoice, Apply and post cash receipt
        CreateAndPostSalesInvoicePaymentTolerance(Customer."No.", GeneralPostingSetup, VATPostingSetup);
        PaymentToleranceAmount := CreateAndPostSalesCashReceipt(GenJournalLine, Customer."No.");

        // Verify GL and VAT entries for payment tolerance line existence
        VerifyVATEntryNormalVATSetup(GeneralPostingSetup, VATPostingSetup, GenJournalLine, PaymentToleranceAmount);
        VerifyGLEntryNormalVATSetup(
          GeneralPostingSetup, VATPostingSetup, PaymentToleranceAmount, GeneralPostingSetup."Sales Pmt. Disc. Debit Acc.");

        // Test unapply payment
        RunCustomerLedgerEntriesPageToUnapply(Customer."No.", GenJournalLine."Document No.");
        VerifyGLEntryOnUnapplyPartialPayment(CustomerPostingGroup."Payment Disc. Credit Acc.");
        LibraryPmtDiscSetup.ClearAdjustPmtDiscInVATSetup();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,ApplyVendorEntriesPageHandlerSelectLastDocument,PaymentToleranceWarningHandler,VendorLedgerEntriesPageHandlerUnapply,UnapplyVendorEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure PaymentToleranceUnapplyPartialPaymentNormalVATPurchase()
    var
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        VATEntry: Record "VAT Entry";
        VendorPostingGroup: Record "Vendor Posting Group";
        PaymentToleranceAmount: Decimal;
    begin
        Initialize();
        SetupPaymentWithPaymentToleranceAndFullVATScenario(
          Vendor,
          GeneralPostingSetup,
          VATPostingSetup,
          VATEntry."VAT Calculation Type"::"Normal VAT",
          LibraryRandom.RandIntInRange(10, 30));
        VendorPostingGroup.Get(Vendor."Vendor Posting Group");

        // Excercise: Post invoice, Apply and post payment
        CreateAndPostPurchaseInvoiceOnDiscountPaymentTerms(Vendor."No.", GeneralPostingSetup, VATPostingSetup);
        PaymentToleranceAmount := CreateAndPostPurchasePayment(GenJournalLine, Vendor."No.");

        // Verify GL and VAT entries for payment tolerance line existence
        VerifyVATEntryNormalVATSetup(GeneralPostingSetup, VATPostingSetup, GenJournalLine, PaymentToleranceAmount);
        VerifyGLEntryNormalVATSetup(
          GeneralPostingSetup, VATPostingSetup, PaymentToleranceAmount, GeneralPostingSetup."Purch. Pmt. Disc. Credit Acc.");

        // Test unapply payment
        RunVendorLedgerEntriesPageToUnapply(Vendor."No.", GenJournalLine."Document No.");
        VerifyGLEntryOnUnapplyPartialPayment(VendorPostingGroup."Payment Disc. Credit Acc.");
        LibraryPmtDiscSetup.ClearAdjustPmtDiscInVATSetup();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,CustomerLedgerEntriesPageHandlerUnapply,UnapplyCustomerEntriesPageHandler,MessageHandler,PaymentToleranceWarningHandler,ApplyCustomerEntriesPageHandlerSelectLastDocument')]
    [Scope('OnPrem')]
    procedure PaymentToleranceUnapplyPartialPaymentFullVATSales()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        VATEntry: Record "VAT Entry";
        CustomerPostingGroup: Record "Customer Posting Group";
        PaymentToleranceAmount: Decimal;
    begin
        Initialize();
        SetupUnapplyPaymentWithPaymentToleranceScenario(
          Customer,
          GeneralPostingSetup,
          VATPostingSetup,
          VATEntry."VAT Calculation Type"::"Full VAT",
          100);
        CustomerPostingGroup.Get(Customer."Customer Posting Group");

        // Excercise: Post invoice, Apply and post cash receipt
        CreateAndPostSalesInvoicePaymentTolerance(Customer."No.", GeneralPostingSetup, VATPostingSetup);
        PaymentToleranceAmount := CreateAndPostSalesCashReceipt(GenJournalLine, Customer."No.");

        // Verify GL and VAT entries for payment tolerance line existence
        VerifyVATEntryFullVATSetup(GeneralPostingSetup, VATPostingSetup, GenJournalLine, PaymentToleranceAmount);
        VerifyGLEntryFullVATSetup(
          GeneralPostingSetup, VATPostingSetup, PaymentToleranceAmount, GeneralPostingSetup."Sales Pmt. Disc. Debit Acc.");

        // Test unapply payment
        RunCustomerLedgerEntriesPageToUnapply(Customer."No.", GenJournalLine."Document No.");
        VerifyGLEntryOnUnapplyPartialPayment(CustomerPostingGroup."Payment Disc. Credit Acc.");
        LibraryPmtDiscSetup.ClearAdjustPmtDiscInVATSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnapplyVendorPmtWithMultipleToleranceEntries()
    var
        GenJnlLine: Record "Gen. Journal Line";
        VendLedgEntry: Record "Vendor Ledger Entry";
        DocNo: Code[20];
        TotalAmount: Decimal;
        PmtAmountExclTolerance: Decimal;
    begin
        // Verify that payment applied to invoice with multiple Pmt. Discount entries can be unapplied successfully.

        Initialize();
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(true);
        LibraryPmtDiscSetup.SetPmtTolerance(1);
        TotalAmount := PostPurchInvWithMultipleBalLines(GenJnlLine);
        LibraryERM.PostGeneralJnlLine(GenJnlLine);

        PmtAmountExclTolerance := -Round(TotalAmount * (1 - LibraryPmtDiscSetup.GetPmtTolerancePct() / 100));
        DocNo :=
          PostApplicationJnlLine(GenJnlLine, '', GenJnlLine."Document Type"::Payment, GenJnlLine."Account Type"::Vendor,
            PmtAmountExclTolerance, GenJnlLine."Posting Date");

        LibraryERM.FindVendorLedgerEntry(VendLedgEntry, VendLedgEntry."Document Type"::Payment, DocNo);
        LibraryERM.UnapplyVendorLedgerEntry(VendLedgEntry);

        VerifyUnappliedVendorVATEntries(
          VendLedgEntry."Document Type"::Payment, DocNo, Round(TotalAmount * GenJnlLine."Payment Discount %" / 100));

        // Tear Down.
        LibraryPmtDiscSetup.ClearAdjustPmtDiscInVATSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnapplyCustomerPmtWithMultipleToleranceEntries()
    var
        GenJnlLine: Record "Gen. Journal Line";
        CustLedgEntry: Record "Cust. Ledger Entry";
        DocNo: Code[20];
        TotalAmount: Decimal;
        PmtAmountExclTolerance: Decimal;
    begin
        // Verify that payment applied to invoice with multiple Pmt. Discount entries can be unapplied successfully.

        Initialize();
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(true);
        LibraryPmtDiscSetup.SetPmtTolerance(1);
        TotalAmount := PostSalesInvWithMultipleBalLines(GenJnlLine);
        LibraryERM.PostGeneralJnlLine(GenJnlLine);

        PmtAmountExclTolerance := -Round(TotalAmount * (1 - LibraryPmtDiscSetup.GetPmtTolerancePct() / 100));
        DocNo :=
          PostApplicationJnlLine(GenJnlLine, '', GenJnlLine."Document Type"::Payment, GenJnlLine."Account Type"::Customer,
            PmtAmountExclTolerance, GenJnlLine."Posting Date");

        LibraryERM.FindCustomerLedgerEntry(CustLedgEntry, CustLedgEntry."Document Type"::Payment, DocNo);
        LibraryERM.UnapplyCustomerLedgerEntry(CustLedgEntry);

        VerifyUnappliedCustomerVATEntries(
          CustLedgEntry."Document Type"::Payment, DocNo, -Round(TotalAmount * GenJnlLine."Payment Discount %" / 100));

        // Tear Down.
        LibraryPmtDiscSetup.ClearAdjustPmtDiscInVATSetup();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UnapplyCustWithEqualPmtToleranceAndPmtDiscToleranceMultipleInvoices()
    var
        Customer: Record Customer;
        GLAccount: Record "G/L Account";
        GenJnlLine: Record "Gen. Journal Line";
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        CustLedgEntry: Record "Cust. Ledger Entry";
        PmtPostingDate: Date;
    begin
        // [FEATURE] [Unapply] [Sales] [Payment Discount] [Payment Discount Tolerance]
        // [SCENARIO 376166] The equal VAT Amount from Payment Tolerance and Payment Discount should be adjusted correctly on unapplication with multiple invoices

        Initialize();
        SetupUnapplyPaymentWithPaymentToleranceScenario(
          Customer,
          GeneralPostingSetup,
          VATPostingSetup,
          VATPostingSetup."VAT Calculation Type"::"Normal VAT",
          10);

        PmtPostingDate := LibraryRandom.RandDate(10);
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.UpdateGLAccountWithPostingSetup(
          GLAccount, GLAccount."Gen. Posting Type"::Sale, GeneralPostingSetup, VATPostingSetup);

        // [GIVEN] Posted invoices with total amount of "Payment Tolerance" = 180 and "Payment Discount" = 180
        // "Payment Tolerance" = 30 + 60 + 90; "Payment Discount" = 60; "Payment Discount Tolerance" = 120
        CreateFixedSalesInvWithPmtDiscTol(Customer."No.", GLAccount."No.", PmtPostingDate + 1, PmtPostingDate + 2, 1200, 60, 10, false);
        CreateFixedSalesInvWithPmtDiscTol(Customer."No.", GLAccount."No.", PmtPostingDate - 1, PmtPostingDate + 1, 2400, 120, 10, true);
        CreateFixedSalesInvWithPmtDiscTol(Customer."No.", GLAccount."No.", PmtPostingDate - 1, PmtPostingDate - 1, 3600, 180, 200, false);

        // [GIVEN] Posted payment applied to all invoices
        CreateFixedGenJnlLinePaymentWithApplToMultipleInvoices(
          GenJnlLine, PmtPostingDate, GenJnlLine."Account Type"::Customer, Customer."No.", -6840);
        ApplyAndPostPmtToMultipleSalesInvoices(CustLedgEntry, GenJnlLine);

        // [WHEN] Unapply payment
        LibraryERM.UnapplyCustomerLedgerEntry(CustLedgEntry);

        // [THEN] Total VAT Amount of adjusted VAT on "Payment Tolerance" and "Payment Discount" = -360
        VerifyUnappliedCustomerVATEntries(GenJnlLine."Document Type", GenJnlLine."Document No.", -360);

        LibraryPmtDiscSetup.ClearAdjustPmtDiscInVATSetup();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UnapplyVendWithEqualPmtToleranceAndPmtDiscToleranceMultipleInvoices()
    var
        Vendor: Record Vendor;
        GLAccount: Record "G/L Account";
        GenJnlLine: Record "Gen. Journal Line";
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        VendLedgEntry: Record "Vendor Ledger Entry";
        PmtPostingDate: Date;
    begin
        // [FEATURE] [Unapply] [Purchase] [Payment Discount] [Payment Discount Tolerance]
        // [SCENARIO 376166] The equal VAT Amount from Payment Tolerance and Payment Discount should be adjusted correctly on unapplication with multiple invoices

        Initialize();
        SetupPaymentWithPaymentToleranceAndFullVATScenario(
          Vendor,
          GeneralPostingSetup,
          VATPostingSetup,
          VATPostingSetup."VAT Calculation Type"::"Normal VAT",
          10);

        PmtPostingDate := LibraryRandom.RandDate(10);
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.UpdateGLAccountWithPostingSetup(
          GLAccount, GLAccount."Gen. Posting Type"::Purchase, GeneralPostingSetup, VATPostingSetup);

        // [GIVEN] Posted invoices with total amount of "Payment Tolerance" = 180 and "Payment Discount" = 180
        // "Payment Tolerance" = 30 + 60 + 90; "Payment Discount" = 60; "Payment Discount Tolerance" = 120
        CreateFixedPurchInvWithPmtDiscTol(Vendor."No.", GLAccount."No.", PmtPostingDate + 1, PmtPostingDate + 2, 1200, 60, 10, false);
        CreateFixedPurchInvWithPmtDiscTol(Vendor."No.", GLAccount."No.", PmtPostingDate - 1, PmtPostingDate + 1, 2400, 120, 10, true);
        CreateFixedPurchInvWithPmtDiscTol(Vendor."No.", GLAccount."No.", PmtPostingDate - 1, PmtPostingDate - 1, 3600, 180, 200, false);

        // [GIVEN] Posted payment applied to all invoices
        CreateFixedGenJnlLinePaymentWithApplToMultipleInvoices(
          GenJnlLine, PmtPostingDate, GenJnlLine."Account Type"::Vendor, Vendor."No.", 6840);
        ApplyAndPostPmtToMultiplePurchInvoices(VendLedgEntry, GenJnlLine);

        // [WHEN] Unapply payment
        LibraryERM.UnapplyVendorLedgerEntry(VendLedgEntry);

        // [THEN] Total VAT Amount of adjusted VAT on "Payment Tolerance" and "Payment Discount" = 360
        VerifyUnappliedVendorVATEntries(GenJnlLine."Document Type", GenJnlLine."Document No.", -360);

        LibraryPmtDiscSetup.ClearAdjustPmtDiscInVATSetup();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UnapplyCustWithEqualPmtToleranceAndPmtDiscToleranceSingleInvoice()
    var
        Customer: Record Customer;
        GLAccount: Record "G/L Account";
        GenJnlLine: Record "Gen. Journal Line";
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        CustLedgEntry: Record "Cust. Ledger Entry";
        VATEntry: Record "VAT Entry";
        PmtPostingDate: Date;
        PmtDisc: Decimal;
        InvAmount: Decimal;
        PmtAmount: Decimal;
    begin
        // [FEATURE] [Unapply] [Sales] [Payment Discount]
        // [SCENARIO 378504] The equal VAT Amount from Payment Tolerance and Payment Discount should be adjusted correctly on unapplication with single invoice

        Initialize();
        SetupUnapplyPaymentWithPaymentToleranceScenario(
          Customer,
          GeneralPostingSetup,
          VATPostingSetup,
          VATEntry."VAT Calculation Type"::"Normal VAT",
          10);

        PmtPostingDate := LibraryRandom.RandDate(10);
        InvAmount := LibraryRandom.RandDec(100, 2);
        PmtDisc := Round(InvAmount / LibraryRandom.RandIntInRange(3, 10));
        PmtAmount := InvAmount - PmtDisc;
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.UpdateGLAccountWithPostingSetup(
          GLAccount, GLAccount."Gen. Posting Type"::Sale, GeneralPostingSetup, VATPostingSetup);

        // [GIVEN] Posted invoice with total amount of "Payment Tolerance" = 50 and "Payment Discount" = 50
        CreateFixedSalesInvWithPmtDiscAndTolerance(
          Customer."No.", GLAccount."No.", PmtPostingDate + 1, PmtPostingDate + 2, InvAmount, PmtDisc);

        // [GIVEN] Posted payment applied to invoice
        CreateFixedGenJnlLinePaymentWithApplToMultipleInvoices(
          GenJnlLine, PmtPostingDate, GenJnlLine."Account Type"::Customer, Customer."No.", -PmtAmount);
        ApplyAndPostPmtToMultipleSalesInvoices(CustLedgEntry, GenJnlLine);

        // [WHEN] Unapply payment
        LibraryERM.UnapplyCustomerLedgerEntry(CustLedgEntry);

        // [THEN] Total VAT Amount of adjusted VAT on "Payment Tolerance" and "Payment Discount" = -100
        VerifyUnappliedCustomerVATEntries(GenJnlLine."Document Type", GenJnlLine."Document No.", -PmtDisc * 2);

        // Tear down
        LibraryPmtDiscSetup.ClearAdjustPmtDiscInVATSetup();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UnapplyVendWithEqualPmtToleranceAndPmtDiscToleranceSingleInvoice()
    var
        Vendor: Record Vendor;
        GLAccount: Record "G/L Account";
        GenJnlLine: Record "Gen. Journal Line";
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        VATEntry: Record "VAT Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        PmtPostingDate: Date;
        PmtDisc: Decimal;
        InvAmount: Decimal;
        PmtAmount: Decimal;
    begin
        // [FEATURE] [Unapply] [Purchase] [Payment Discount]
        // [SCENARIO 378504] The equal VAT Amount from Payment Tolerance and Payment Discount should be adjusted correctly on unapplication with single invoice

        Initialize();
        SetupPaymentWithPaymentToleranceAndFullVATScenario(
          Vendor,
          GeneralPostingSetup,
          VATPostingSetup,
          VATEntry."VAT Calculation Type"::"Normal VAT",
          10);

        PmtPostingDate := LibraryRandom.RandDate(10);
        InvAmount := LibraryRandom.RandDec(100, 2);
        PmtDisc := Round(InvAmount / LibraryRandom.RandIntInRange(3, 10));
        PmtAmount := InvAmount - PmtDisc;

        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.UpdateGLAccountWithPostingSetup(
          GLAccount, GLAccount."Gen. Posting Type"::Purchase, GeneralPostingSetup, VATPostingSetup);

        // [GIVEN] Posted invoices with total amount of "Payment Tolerance" = 50 and "Payment Discount" = 50
        CreateFixedPurchInvWithPmtDiscAndTolerance(Vendor."No.", GLAccount."No.", PmtPostingDate + 1, PmtPostingDate + 2, InvAmount, PmtDisc);

        // [GIVEN] Posted payment applied to invoice
        CreateFixedGenJnlLinePaymentWithApplToMultipleInvoices(
          GenJnlLine, PmtPostingDate, GenJnlLine."Account Type"::Vendor, Vendor."No.", PmtAmount);
        ApplyAndPostPmtToMultiplePurchInvoices(VendLedgEntry, GenJnlLine);

        // [WHEN] Unapply payment
        LibraryERM.UnapplyVendorLedgerEntry(VendLedgEntry);

        // [THEN] Total VAT Amount of adjusted VAT on "Payment Tolerance" and "Payment Discount" = 100
        VerifyUnappliedVendorVATEntries(GenJnlLine."Document Type", GenJnlLine."Document No.", -PmtDisc * 2);

        // Tear down
        LibraryPmtDiscSetup.ClearAdjustPmtDiscInVATSetup();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PaymentTolerancePatmentDiscountUnapplyPaymentMultipleLinesSales()
    var
        Customer: Record Customer;
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        CustLedgerEntry: array[10] of Record "Cust. Ledger Entry";
        CustLedgerEntryPmt: Record "Cust. Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        VATEntry: Record "VAT Entry";
        PaymentAmount: Decimal;
        VATBase: Decimal;
        EntriesQty: Integer;
        i: Integer;
    begin
        // [FEATURE] [Unapply] [Payment Discount] [Sales]
        // [SCENARIO 304555] Unapply VAT Entries for Payment with Payment Discount and Payment Tolerance applied to more than four sales invoices
        Initialize();

        // [GIVEN] Payment Tolerance in turned on in G/L setup
        SetupUnapplyPaymentWithPaymentToleranceScenario(
          Customer,
          GeneralPostingSetup,
          VATPostingSetup,
          VATEntry."VAT Calculation Type"::"Normal VAT",
          LibraryRandom.RandIntInRange(10, 30));

        // [GIVEN] 5 posted Sales Invoices with Normal VAT
        EntriesQty := LibraryRandom.RandIntInRange(4, ArrayLen(CustLedgerEntry));
        CreateAndPostMultipleInvoicesSales(CustLedgerEntry, VATPostingSetup, Customer."No.", EntriesQty);
        for i := 1 to EntriesQty do begin
            CustLedgerEntry[i].Validate("Remaining Pmt. Disc. Possible", CustLedgerEntry[i]."Original Pmt. Disc. Possible");
            CustLedgerEntry[i].Validate("Accepted Payment Tolerance", CustLedgerEntry[i]."Max. Payment Tolerance" / 2);
            CustLedgerEntry[i].Modify(true);
            PaymentAmount +=
              -CustLedgerEntry[i].Amount +
              CustLedgerEntry[i]."Remaining Pmt. Disc. Possible" + CustLedgerEntry[i]."Accepted Payment Tolerance";
        end;

        // [GIVEN] Payment is applied to all invoices at one time with Payment Discount and Payment Tolerance
        CreateFixedGenJnlLinePaymentWithApplToMultipleInvoices(
          GenJournalLine, WorkDate(), GenJournalLine."Account Type"::Customer, Customer."No.", PaymentAmount);
        ApplyAndPostPmtToMultipleSalesInvoices(CustLedgerEntryPmt, GenJournalLine);

        // [GIVEN] Two VAT Entries posted per each invoice from Payment Discount and Payment Tolerance, 10 in total of Base = "VATExclBase"
        VATEntry.SetRange("Transaction No.", CustLedgerEntryPmt."Transaction No.");
        GetVATEntryBase(VATEntry, CustLedgerEntryPmt."Document No.", Customer."No.");
        Assert.RecordCount(VATEntry, EntriesQty * 2);
        VATBase := VATEntry.Base;

        // [WHEN] Unapply payment
        LibraryERM.UnapplyCustomerLedgerEntry(CustLedgerEntryPmt);

        // [THEN] 10 VAT entries created in total of Base = -"VATExclBase"
        VATEntry.SetFilter("Transaction No.", '>%1', CustLedgerEntryPmt."Transaction No.");
        GetVATEntryBase(VATEntry, CustLedgerEntryPmt."Document No.", Customer."No.");
        Assert.RecordCount(VATEntry, EntriesQty * 2);
        VATEntry.TestField(Base, -VATBase);

        LibraryPmtDiscSetup.ClearAdjustPmtDiscInVATSetup();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PaymentTolerancePatmentDiscountUnapplyPaymentMultipleLinesPurchase()
    var
        Vendor: Record Vendor;
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        VendorLedgerEntry: array[10] of Record "Vendor Ledger Entry";
        VendorLedgerEntryPmt: Record "Vendor Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        VATEntry: Record "VAT Entry";
        PaymentAmount: Decimal;
        VATBase: Decimal;
        EntriesQty: Integer;
        i: Integer;
    begin
        // [FEATURE] [Unapply] [Payment Discount] [Purchase]
        // [SCENARIO 304555] Unapply VAT Entries for Payment with Payment Discount and Payment Tolerance applied to more than four purchase invoices
        Initialize();

        // [GIVEN] Payment Tolerance in turned on in G/L setup
        SetupPaymentWithPaymentToleranceAndFullVATScenario(
          Vendor,
          GeneralPostingSetup,
          VATPostingSetup,
          VATEntry."VAT Calculation Type"::"Normal VAT",
          LibraryRandom.RandIntInRange(10, 30));

        // [GIVEN] 5 posted Purchase Invoices with Normal VAT
        EntriesQty := LibraryRandom.RandIntInRange(4, ArrayLen(VendorLedgerEntry));
        CreateAndPostMultipleInvoicesPurchase(VendorLedgerEntry, VATPostingSetup, Vendor."No.", EntriesQty);
        for i := 1 to EntriesQty do begin
            VendorLedgerEntry[i].Validate("Remaining Pmt. Disc. Possible", VendorLedgerEntry[i]."Original Pmt. Disc. Possible");
            VendorLedgerEntry[i].Validate("Accepted Payment Tolerance", VendorLedgerEntry[i]."Max. Payment Tolerance" / 2);
            VendorLedgerEntry[i].Modify(true);
            PaymentAmount +=
              -VendorLedgerEntry[i].Amount +
              VendorLedgerEntry[i]."Remaining Pmt. Disc. Possible" + VendorLedgerEntry[i]."Accepted Payment Tolerance";
        end;

        // [GIVEN] Payment is applied to all invoices at one time with Payment Discount and Payment Tolerance
        CreateFixedGenJnlLinePaymentWithApplToMultipleInvoices(
          GenJournalLine, WorkDate(), GenJournalLine."Account Type"::Vendor, Vendor."No.", PaymentAmount);
        ApplyAndPostPmtToMultiplePurchInvoices(VendorLedgerEntryPmt, GenJournalLine);

        // [GIVEN] Two VAT Entries posted per each invoice from Payment Discount and Payment Tolerance, 10 in total of Base = "VATExclBase"
        VATEntry.SetRange("Transaction No.", VendorLedgerEntryPmt."Transaction No.");
        GetVATEntryBase(VATEntry, VendorLedgerEntryPmt."Document No.", Vendor."No.");
        Assert.RecordCount(VATEntry, EntriesQty * 2);
        VATBase := VATEntry.Base;

        // [WHEN] Unapply payment
        LibraryERM.UnapplyVendorLedgerEntry(VendorLedgerEntryPmt);

        // [THEN] 10 VAT entries created in total of Base = -"VATExclBase"
        VATEntry.SetFilter("Transaction No.", '>%1', VendorLedgerEntryPmt."Transaction No.");
        GetVATEntryBase(VATEntry, VendorLedgerEntryPmt."Document No.", Vendor."No.");
        Assert.RecordCount(VATEntry, EntriesQty * 2);
        VATEntry.TestField(Base, -VATBase);

        LibraryPmtDiscSetup.ClearAdjustPmtDiscInVATSetup();
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Pmt. Tolerance VAT Appln.");
        LibraryApplicationArea.EnableFoundationSetup();
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();
        // Setup demo data.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Pmt. Tolerance VAT Appln.");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateAccountInCustomerPostingGroup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.RemoveBlankGenJournalTemplate();

        isInitialized := true;
        Commit();
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Pmt. Tolerance VAT Appln.");
    end;

    local procedure ApplyAndPostPaymentToSalesInvoice(GenJournalLine: Record "Gen. Journal Line") PaymentToleranceAmount: Decimal
    var
        CashReceiptJournal: TestPage "Cash Receipt Journal";
    begin
        CashReceiptJournal.OpenEdit();
        CashReceiptJournal.CurrentJnlBatchName.SetValue(GenJournalLine."Journal Batch Name");
        CashReceiptJournal.FILTER.SetFilter("Document Type", Format(GenJournalLine."Document Type"));
        CashReceiptJournal.FILTER.SetFilter("Document No.", GenJournalLine."Document No.");
        CashReceiptJournal."Applies-to Doc. No.".Lookup();
        PaymentToleranceAmount := LibraryRandom.RandDec(99, 2);
        CashReceiptJournal.Amount.SetValue(CashReceiptJournal.Amount.AsDecimal() + PaymentToleranceAmount);
        CashReceiptJournal.Post.Invoke();
        CashReceiptJournal.OK().Invoke();
        exit(PaymentToleranceAmount);
    end;

    local procedure ApplyAndPostPaymentToPurchaseInvoice(GenJournalLine: Record "Gen. Journal Line") PaymentToleranceAmount: Decimal
    var
        PaymentJournal: TestPage "Payment Journal";
    begin
        PaymentJournal.OpenEdit();
        PaymentJournal.CurrentJnlBatchName.SetValue := GenJournalLine."Journal Batch Name";
        PaymentJournal.FILTER.SetFilter("Document Type", Format(GenJournalLine."Document Type"));
        PaymentJournal.FILTER.SetFilter("Document No.", GenJournalLine."Document No.");
        PaymentJournal.AppliesToDocNo.Lookup();
        PaymentToleranceAmount := -LibraryRandom.RandDec(99, 2);
        PaymentJournal.Amount.SetValue(PaymentJournal.Amount.AsDecimal() + PaymentToleranceAmount);
        PaymentJournal.Post.Invoke();
        PaymentJournal.OK().Invoke();
        exit(PaymentToleranceAmount);
    end;

    local procedure ApplyAndPostPmtToMultipleSalesInvoices(var CustLedgEntry: Record "Cust. Ledger Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
        CustLedgEntry.SetRange("Customer No.", GenJournalLine."Account No.");
        LibraryERM.SetAppliestoIdCustomer(CustLedgEntry);
        GenJournalLine.Validate("Applies-to ID", UserId);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        LibraryERM.FindCustomerLedgerEntry(CustLedgEntry, GenJournalLine."Document Type", GenJournalLine."Document No.");
    end;

    local procedure ApplyAndPostPmtToMultiplePurchInvoices(var VendLedgEntry: Record "Vendor Ledger Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
        VendLedgEntry.SetRange("Vendor No.", GenJournalLine."Account No.");
        LibraryERM.SetAppliestoIdVendor(VendLedgEntry);
        GenJournalLine.Validate("Applies-to ID", UserId);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        LibraryERM.FindVendorLedgerEntry(VendLedgEntry, GenJournalLine."Document Type", GenJournalLine."Document No.");
    end;

    local procedure CreateAndPostSalesInvoicePaymentTolerance(CustomerNo: Code[20]; GeneralPostingSetup: Record "General Posting Setup"; VATPostingSetup: Record "VAT Posting Setup") PostedDocumentNo: Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        CreateSalesLine(SalesHeader, GeneralPostingSetup, VATPostingSetup);
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, false, true);
        exit(PostedDocumentNo);
    end;

    local procedure CreateVendorWithPaymentTerms(PaymentTermsCode: Code[10]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Payment Terms Code", PaymentTermsCode);
        Vendor.Modify(true);

        exit(Vendor."No.");
    end;

    local procedure CreateAndPostPurchasePayment(var GenJournalLine: Record "Gen. Journal Line"; VendorNo: Code[20]): Decimal
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        CreateGeneralJournalLinePayment(
          GenJournalLine,
          GenJournalTemplate.Type::Payments,
          GenJournalLine."Account Type"::Vendor,
          VendorNo);

        exit(ApplyAndPostPaymentToPurchaseInvoice(GenJournalLine));
    end;

    local procedure CreateAndPostPurchaseInvoiceOnDiscountPaymentTerms(VendorNo: Code[20]; GeneralPostingSetup: Record "General Posting Setup"; VATPostingSetup: Record "VAT Posting Setup"): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        CreatePurchaseLine(PurchaseHeader, GeneralPostingSetup, VATPostingSetup);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true));
    end;

    local procedure CreateAndPostMultipleInvoicesSales(var CustLedgerEntry: array[10] of Record "Cust. Ledger Entry"; VATPostingSetup: Record "VAT Posting Setup"; CustomerNo: Code[20]; EntriesQty: Integer)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GLAccountNo: Code[20];
        InvoiceNo: array[10] of Code[20];
        i: Integer;
    begin
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        GLAccountNo := LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GenJournalLine."Gen. Posting Type"::Sale);
        for i := 1 to EntriesQty do begin
            LibraryJournals.CreateGenJournalLine(
              GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
              GenJournalLine."Account Type"::Customer, CustomerNo, GenJournalLine."Bal. Account Type"::"G/L Account", GLAccountNo,
              LibraryRandom.RandDecInRange(1000, 2000, 2));
            InvoiceNo[i] := GenJournalLine."Document No.";
        end;
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        for i := 1 to EntriesQty do
            LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry[i], CustLedgerEntry[1]."Document Type"::Invoice, InvoiceNo[i]);
    end;

    local procedure CreateAndPostMultipleInvoicesPurchase(var VendorLedgerEntry: array[10] of Record "Vendor Ledger Entry"; VATPostingSetup: Record "VAT Posting Setup"; VendorNo: Code[20]; EntriesQty: Integer)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GLAccountNo: Code[20];
        InvoiceNo: array[10] of Code[20];
        i: Integer;
    begin
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        GLAccountNo := LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GenJournalLine."Gen. Posting Type"::Purchase);
        for i := 1 to EntriesQty do begin
            LibraryJournals.CreateGenJournalLine(
              GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
              GenJournalLine."Account Type"::Vendor, VendorNo, GenJournalLine."Bal. Account Type"::"G/L Account", GLAccountNo,
              -LibraryRandom.RandDecInRange(1000, 2000, 2));
            InvoiceNo[i] := GenJournalLine."Document No.";
        end;
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        for i := 1 to EntriesQty do
            LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry[i], VendorLedgerEntry[1]."Document Type"::Invoice, InvoiceNo[i]);
    end;

    local procedure CreateSalesLine(SalesHeader: Record "Sales Header"; GeneralPostingSetup: Record "General Posting Setup"; VATPostingSetup: Record "VAT Posting Setup")
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", VATPostingSetup."Sales VAT Account", 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(10000, 20000, 2));
        SalesLine.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        SalesLine.Modify(true);
    end;

    local procedure CreateAndPostSalesCashReceipt(var GenJournalLine: Record "Gen. Journal Line"; CustomerNo: Code[20]): Decimal
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        CreateGeneralJournalLinePayment(
          GenJournalLine,
          GenJournalTemplate.Type::"Cash Receipts",
          GenJournalLine."Account Type"::Customer,
          CustomerNo);

        exit(ApplyAndPostPaymentToSalesInvoice(GenJournalLine));
    end;

    local procedure CreatePurchaseLine(var PurchaseHeader: Record "Purchase Header"; GeneralPostingSetup: Record "General Posting Setup"; VATPostingSetup: Record "VAT Posting Setup")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", VATPostingSetup."Purchase VAT Account", 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10000, 20000, 2));
        PurchaseLine.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        PurchaseLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        PurchaseLine.Modify(true);
    end;

    local procedure CreateCustomer(PaymentTermsCode: Code[10]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Payment Terms Code", PaymentTermsCode);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreatePaymentTerms(var PaymentTerms: Record "Payment Terms")
    var
        DiscountDateCalculation: DateFormula;
    begin
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        Evaluate(DiscountDateCalculation, Format(LibraryRandom.RandInt(5)) + 'D');
        PaymentTerms.Validate("Discount Date Calculation", DiscountDateCalculation);
        PaymentTerms.Validate("Discount %", LibraryRandom.RandInt(10));
        PaymentTerms.Modify(true);
    end;

    local procedure CreateUpdatePaymentToleranceSetup(var GeneralPostingSetup: Record "General Posting Setup"; var VATPostingSetup: Record "VAT Posting Setup"; VATPercent: Integer; VATCalculationType: Enum "Tax Calculation Type")
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
    begin
        LibraryVariableStorage.Enqueue(PostingAction::"Payment Tolerance Accounts");

        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(true);
        LibraryPmtDiscSetup.SetPmtTolerance(0);
        RunChangePaymentTolerance(true, LibraryRandom.RandDec(10, 2), LibraryRandom.RandDecInRange(100, 200, 2));

        LibraryERM.FindGeneralPostingSetupInvtFull(GeneralPostingSetup);
        LibraryERM.CreateGenProdPostingGroup(GenProductPostingGroup);
        LibraryERM.CreateGeneralPostingSetup(
          GeneralPostingSetup, GeneralPostingSetup."Gen. Bus. Posting Group", GenProductPostingGroup.Code);
        UpdateGeneralPostingSetupSalesPmtAccounts(GeneralPostingSetup);
        UpdateGeneralPostingSetupPurchPmtAccounts(GeneralPostingSetup);
        GeneralPostingSetup.Validate("COGS Account", LibraryERM.CreateGLAccountNo());
        GeneralPostingSetup.Validate("Sales Account", LibraryERM.CreateGLAccountNo());
        GeneralPostingSetup.Modify(true);

        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup.Code, VATProductPostingGroup.Code);
        UpdateVATPostingSetup(VATPostingSetup, VATPercent, VATCalculationType);

        GenProductPostingGroup.Validate("Def. VAT Prod. Posting Group", VATProductPostingGroup.Code);
        GenProductPostingGroup.Modify(true);
    end;

    local procedure CreateGeneralJournalTemplate(var GenJournalTemplate: Record "Gen. Journal Template"; GenJournalTemplateType: Enum "Gen. Journal Template Type")
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate(Type, GenJournalTemplateType);
        GenJournalTemplate.Modify(true);
    end;

    local procedure CreateGeneralJournalLinePayment(var GenJournalLine: Record "Gen. Journal Line"; GenJournalTemplateType: Enum "Gen. Journal Template Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20])
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        GenJournalTemplate.SetRange(Type, GenJournalTemplateType);
        if not GenJournalTemplate.FindFirst() then
            CreateGeneralJournalTemplate(GenJournalTemplate, GenJournalTemplateType);

        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);

        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
            GenJournalLine."Document Type"::Payment, AccountType, AccountNo, 0);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNo());
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Modify(true);

        Commit();
    end;

    local procedure CreateFixedGenJnlLinePaymentWithApplToMultipleInvoices(var GenJnlLine: Record "Gen. Journal Line"; PostingDate: Date; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal)
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(GenJnlLine, GenJnlLine."Document Type"::Payment, AccountType, AccountNo, Amount);
        GenJnlLine.Validate("Posting Date", PostingDate);
        GenJnlLine.Validate("Applies-to ID", GenJnlLine."Document No.");
        GenJnlLine.Modify(true);
        Commit();
    end;

    local procedure FindGLEntry(var GLEntry: Record "G/L Entry"; GeneralPostingSetup: Record "General Posting Setup"; VATPostingSetup: Record "VAT Posting Setup"; AccountNo: Code[20])
    begin
        GLEntry.SetRange("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        GLEntry.SetRange("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLEntry.SetRange("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLEntry.SetRange("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLEntry.SetRange("G/L Account No.", AccountNo);
        GLEntry.FindFirst();
    end;

    local procedure FindVATEntry(var VATEntry: Record "VAT Entry"; GeneralPostingSetup: Record "General Posting Setup"; VATPostingSetup: Record "VAT Posting Setup"; GenJournalLine: Record "Gen. Journal Line")
    begin
        VATEntry.SetRange("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        VATEntry.SetRange("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        VATEntry.SetRange("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        VATEntry.SetRange("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        VATEntry.SetRange("Document Type", GenJournalLine."Document Type");
        VATEntry.SetRange("Document No.", GenJournalLine."Document No.");
        VATEntry.FindFirst();
    end;

    local procedure SetupUnapplyPaymentWithPaymentToleranceScenario(var Customer: Record Customer; var GeneralPostingSetup: Record "General Posting Setup"; var VATPostingSetup: Record "VAT Posting Setup"; VATCalculationType: Enum "Tax Calculation Type"; VATPercent: Integer)
    var
        PaymentTerms: Record "Payment Terms";
    begin
        CreateUpdatePaymentToleranceSetup(GeneralPostingSetup, VATPostingSetup, VATPercent, VATCalculationType);

        CreatePaymentTerms(PaymentTerms);
        Customer.Get(CreateCustomer(PaymentTerms.Code));
        Customer.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Validate("Application Method", Customer."Application Method"::Manual);
        Customer.Modify(true);

        // Update General Posting Setup
        UpdateCustomerPostingGroupSalesDiscAccounts(Customer."Customer Posting Group");
    end;

    local procedure SetupPaymentWithPaymentToleranceAndFullVATScenario(var Vendor: Record Vendor; var GeneralPostingSetup: Record "General Posting Setup"; var VATPostingSetup: Record "VAT Posting Setup"; VATCalculationType: Enum "Tax Calculation Type"; VATPercent: Integer)
    var
        PaymentTerms: Record "Payment Terms";
    begin
        CreateUpdatePaymentToleranceSetup(GeneralPostingSetup, VATPostingSetup, VATPercent, VATCalculationType);

        CreatePaymentTerms(PaymentTerms);
        Vendor.Get(CreateVendorWithPaymentTerms(PaymentTerms.Code));
        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Vendor.Validate("Application Method", Vendor."Application Method"::Manual);
        Vendor.Modify(true);

        // Update General Posting Setup
        UpdateVendorPostingGroupPaymentDiscAccounts(Vendor."Vendor Posting Group");
    end;

    local procedure RunChangePaymentTolerance(AllCurrency: Boolean; PaymentTolerance: Decimal; MaxPaymentToleranceAmount: Decimal)
    var
        ChangePaymentTolerance: Report "Change Payment Tolerance";
    begin
        Clear(ChangePaymentTolerance);
        ChangePaymentTolerance.InitializeRequest(AllCurrency, '', PaymentTolerance, MaxPaymentToleranceAmount);
        ChangePaymentTolerance.UseRequestPage(false);
        ChangePaymentTolerance.Run();
    end;

    local procedure RunCustomerLedgerEntriesPageToUnapply(CustomerNo: Code[20]; DocumentNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        PAGE.Run(PAGE::"Customer Ledger Entries", CustLedgerEntry);
    end;

    local procedure RunVendorLedgerEntriesPageToUnapply(VendorNo: Code[20]; DocumentNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.SetRange("Document No.", DocumentNo);
        PAGE.Run(PAGE::"Vendor Ledger Entries", VendorLedgerEntry);
    end;

    local procedure UpdateGeneralPostingSetupSalesPmtAccounts(var GeneralPostingSetup: Record "General Posting Setup")
    begin
        GeneralPostingSetup.Validate("Sales Pmt. Disc. Credit Acc.", LibraryERM.CreateGLAccountNo());
        GeneralPostingSetup.Validate("Sales Pmt. Disc. Debit Acc.", LibraryERM.CreateGLAccountNo());
        GeneralPostingSetup.Validate("Sales Pmt. Tol. Credit Acc.", LibraryERM.CreateGLAccountNo());
        GeneralPostingSetup.Validate("Sales Pmt. Tol. Debit Acc.", LibraryERM.CreateGLAccountNo());
        GeneralPostingSetup.Modify(true);
    end;

    local procedure UpdateGeneralPostingSetupPurchPmtAccounts(var GeneralPostingSetup: Record "General Posting Setup")
    begin
        GeneralPostingSetup.Validate("Purch. Pmt. Disc. Credit Acc.", LibraryERM.CreateGLAccountNo());
        GeneralPostingSetup.Validate("Purch. Pmt. Disc. Debit Acc.", LibraryERM.CreateGLAccountNo());
        GeneralPostingSetup.Validate("Purch. Pmt. Tol. Credit Acc.", LibraryERM.CreateGLAccountNo());
        GeneralPostingSetup.Validate("Purch. Pmt. Tol. Debit Acc.", LibraryERM.CreateGLAccountNo());
        GeneralPostingSetup.Modify(true);
    end;

    local procedure UpdateCustomerPostingGroupSalesDiscAccounts(CustomerPostingGroupCode: Code[20])
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        CustomerPostingGroup.Get(CustomerPostingGroupCode);
        CustomerPostingGroup.Validate("Payment Disc. Debit Acc.", LibraryERM.CreateGLAccountNo());
        CustomerPostingGroup.Validate("Payment Disc. Credit Acc.", LibraryERM.CreateGLAccountNo());
        CustomerPostingGroup.Modify();
    end;

    local procedure UpdateVendorPostingGroupPaymentDiscAccounts(VendorPostingGroupCode: Code[20])
    var
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        VendorPostingGroup.Get(VendorPostingGroupCode);
        VendorPostingGroup.Validate("Payment Disc. Debit Acc.", LibraryERM.CreateGLAccountNo());
        VendorPostingGroup.Validate("Payment Disc. Credit Acc.", LibraryERM.CreateGLAccountNo());
        VendorPostingGroup.Modify();
    end;

    local procedure UpdateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; VATPercent: Integer; VATCalculcationType: Enum "Tax Calculation Type")
    var
        GLAccount: Record "G/L Account";
    begin
        VATPostingSetup.Validate("VAT Identifier", StrSubstNo(VATIdTok, VATPercent));
        VATPostingSetup.Validate("VAT %", VATPercent);
        VATPostingSetup.Validate("VAT Calculation Type", VATCalculcationType);
        VATPostingSetup.Validate("Adjust for Payment Discount", true);
        VATPostingSetup.Validate("Sales VAT Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale));
        VATPostingSetup.Validate("Purchase VAT Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase));
        VATPostingSetup.Modify(true);
    end;

    local procedure SetAdjForPmtDiscInVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        VATPostingSetup.Validate("Adjust for Payment Discount", true);
        VATPostingSetup.Validate("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::" ");
        VATPostingSetup.Modify();
    end;

    local procedure UpdatePmtDiscAccountsInGenPostingSetup(var GenPostingSetup: Record "General Posting Setup"; GenBusPostingGroupCode: Code[20])
    begin
        GenPostingSetup.FilterGroup(2);
        GenPostingSetup.SetRange("Gen. Bus. Posting Group", GenBusPostingGroupCode);
        GenPostingSetup.FilterGroup(0);
        LibraryERM.FindGeneralPostingSetup(GenPostingSetup);
        // Using assignment to avoid error in ES.
        GenPostingSetup."Purch. Pmt. Disc. Debit Acc." := LibraryERM.CreateGLAccountNo();
        GenPostingSetup."Purch. Pmt. Disc. Credit Acc." := LibraryERM.CreateGLAccountNo();
        GenPostingSetup."Purch. Pmt. Tol. Debit Acc." := LibraryERM.CreateGLAccountNo();
        GenPostingSetup."Purch. Pmt. Tol. Credit Acc." := LibraryERM.CreateGLAccountNo();
        GenPostingSetup."Sales Pmt. Disc. Debit Acc." := LibraryERM.CreateGLAccountNo();
        GenPostingSetup."Sales Pmt. Disc. Credit Acc." := LibraryERM.CreateGLAccountNo();
        GenPostingSetup."Sales Pmt. Tol. Debit Acc." := LibraryERM.CreateGLAccountNo();
        GenPostingSetup."Sales Pmt. Tol. Credit Acc." := LibraryERM.CreateGLAccountNo();
        GenPostingSetup.Modify(true);
    end;

    local procedure UpdatePmtTolInCustomerPostingGroup(PostingGroupCode: Code[20])
    var
        CustomerPostingGroup: Record "Customer Posting Group";
        GLAccount: Record "G/L Account";
    begin
        CustomerPostingGroup.Get(PostingGroupCode);
        GLAccount.SetRange("Account Type", GLAccount."Account Type"::Posting);
        GLAccount.SetRange(Blocked, false);
        GLAccount.FindSet();
        CustomerPostingGroup.Validate("Payment Disc. Debit Acc.", GLAccount."No.");
        CustomerPostingGroup.Validate("Payment Disc. Credit Acc.", GLAccount."No.");
        GLAccount.Next();
        CustomerPostingGroup.Validate("Payment Tolerance Debit Acc.", GLAccount."No.");
        CustomerPostingGroup.Validate("Payment Tolerance Credit Acc.", GLAccount."No.");
        CustomerPostingGroup.Modify(true);
    end;

    local procedure UpdateVendorPostingGroup(PostingGroupCode: Code[20])
    var
        VendorPostingGroup: Record "Vendor Posting Group";
        GLAccount: Record "G/L Account";
    begin
        VendorPostingGroup.Get(PostingGroupCode);
        GLAccount.SetRange("Account Type", GLAccount."Account Type"::Posting);
        GLAccount.SetRange(Blocked, false);
        GLAccount.FindSet();
        VendorPostingGroup.Validate("Payment Disc. Debit Acc.", GLAccount."No.");
        VendorPostingGroup.Validate("Payment Disc. Credit Acc.", GLAccount."No.");
        GLAccount.Next();
        VendorPostingGroup.Validate("Payment Tolerance Debit Acc.", GLAccount."No.");
        VendorPostingGroup.Validate("Payment Tolerance Credit Acc.", GLAccount."No.");
        VendorPostingGroup.Modify(true);
    end;

    local procedure GetPaymentTerms(): Code[10]
    var
        PaymentTerms: Record "Payment Terms";
    begin
        LibraryERM.CreatePaymentTermsDiscount(PaymentTerms, true);
        exit(PaymentTerms.Code);
    end;

    local procedure CreateGLAccountWithSetup(GenProdPostingGroupCode: Code[20]; VATBusPostingGroupCode: Code[20]; GenPostType: Option): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Posting Type", GenPostType);
        GLAccount.Validate("Gen. Prod. Posting Group", GenProdPostingGroupCode);
        GLAccount.Validate("VAT Prod. Posting Group", VATBusPostingGroupCode);
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateVendorWithSetup(VATBusPostingGroup: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
        LibraryPurchase: Codeunit "Library - Purchase";
    begin
        LibraryPurchase.CreateVendor(Vendor);

        Vendor.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Vendor.Validate("Application Method", Vendor."Application Method"::Manual);
        Vendor.Validate("Payment Terms Code", GetPaymentTerms());
        Vendor.Modify(true);

        UpdateVendorPostingGroup(Vendor."Vendor Posting Group");
        exit(Vendor."No.");
    end;

    local procedure CreateCustomerWithSetup(VATBusPostingGroup: Code[20]): Code[20]
    var
        Customer: Record Customer;
        LibrarySales: Codeunit "Library - Sales";
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Customer.Validate("Payment Terms Code", GetPaymentTerms());
        Customer.Modify(true);
        UpdatePmtTolInCustomerPostingGroup(Customer."Customer Posting Group");
        exit(Customer."No.");
    end;

    local procedure CreateFixedSalesInvWithPmtDiscTol(CustNo: Code[20]; GLAccNo: Code[20]; PmtDiscDate: Date; PmtDiscTolDate: Date; Amount: Decimal; RemPmtDiscPossible: Decimal; MaxPmtTol: Decimal; AcceptedPmtDiscTolerance: Boolean)
    var
        GenJnlLine: Record "Gen. Journal Line";
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        PostInvGenJnlLineWithPmtDiscDate(GenJnlLine, PmtDiscDate, GLAccNo, GenJnlLine."Account Type"::Customer, CustNo, Amount);
        LibraryERM.FindCustomerLedgerEntry(CustLedgEntry, CustLedgEntry."Document Type"::Invoice, GenJnlLine."Document No.");
        CustLedgEntry.Validate("Pmt. Disc. Tolerance Date", PmtDiscTolDate);
        CustLedgEntry.Validate("Remaining Pmt. Disc. Possible", RemPmtDiscPossible);
        CustLedgEntry.Validate("Accepted Payment Tolerance", Round(RemPmtDiscPossible / 2));
        CustLedgEntry.Validate("Accepted Pmt. Disc. Tolerance", AcceptedPmtDiscTolerance);
        CustLedgEntry.Validate("Max. Payment Tolerance", MaxPmtTol);
        CustLedgEntry.Modify();
    end;

    local procedure CreateFixedSalesInvWithPmtDiscAndTolerance(CustNo: Code[20]; GLAccNo: Code[20]; PmtDiscDate: Date; PmtDiscTolDate: Date; Amount: Decimal; RemPmtDiscPossible: Decimal)
    var
        GenJnlLine: Record "Gen. Journal Line";
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        PostInvGenJnlLineWithPmtDiscDate(GenJnlLine, PmtDiscDate, GLAccNo, GenJnlLine."Account Type"::Customer, CustNo, Amount);
        LibraryERM.FindCustomerLedgerEntry(CustLedgEntry, CustLedgEntry."Document Type"::Invoice, GenJnlLine."Document No.");
        CustLedgEntry.Validate("Pmt. Disc. Tolerance Date", PmtDiscTolDate);
        CustLedgEntry.Validate("Remaining Pmt. Disc. Possible", RemPmtDiscPossible);
        CustLedgEntry.Validate("Accepted Payment Tolerance", RemPmtDiscPossible);
        CustLedgEntry.Modify();
    end;

    local procedure CreateFixedPurchInvWithPmtDiscTol(VendNo: Code[20]; GLAccNo: Code[20]; PmtDiscDate: Date; PmtDiscTolDate: Date; Amount: Decimal; RemPmtDiscPossible: Decimal; MaxPmtTol: Decimal; AcceptedPmtDiscTolerance: Boolean)
    var
        GenJnlLine: Record "Gen. Journal Line";
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        PostInvGenJnlLineWithPmtDiscDate(GenJnlLine, PmtDiscDate, GLAccNo, GenJnlLine."Account Type"::Vendor, VendNo, -Amount);
        LibraryERM.FindVendorLedgerEntry(VendLedgEntry, VendLedgEntry."Document Type"::Invoice, GenJnlLine."Document No.");
        VendLedgEntry.Validate("Pmt. Disc. Tolerance Date", PmtDiscTolDate);
        VendLedgEntry.Validate("Remaining Pmt. Disc. Possible", -RemPmtDiscPossible);
        VendLedgEntry.Validate("Accepted Payment Tolerance", Round(-RemPmtDiscPossible / 2));
        VendLedgEntry.Validate("Accepted Pmt. Disc. Tolerance", AcceptedPmtDiscTolerance);
        VendLedgEntry.Validate("Max. Payment Tolerance", -MaxPmtTol);
        VendLedgEntry.Modify();
    end;

    local procedure CreateFixedPurchInvWithPmtDiscAndTolerance(VendNo: Code[20]; GLAccNo: Code[20]; PmtDiscDate: Date; PmtDiscTolDate: Date; Amount: Decimal; RemPmtDiscPossible: Decimal)
    var
        GenJnlLine: Record "Gen. Journal Line";
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        PostInvGenJnlLineWithPmtDiscDate(GenJnlLine, PmtDiscDate, GLAccNo, GenJnlLine."Account Type"::Vendor, VendNo, -Amount);
        LibraryERM.FindVendorLedgerEntry(VendLedgEntry, VendLedgEntry."Document Type"::Invoice, GenJnlLine."Document No.");
        VendLedgEntry.Validate("Pmt. Disc. Tolerance Date", PmtDiscTolDate);
        VendLedgEntry.Validate("Remaining Pmt. Disc. Possible", -RemPmtDiscPossible);
        VendLedgEntry.Validate("Accepted Payment Tolerance", Round(-RemPmtDiscPossible));
        VendLedgEntry.Modify();
    end;

    local procedure PostInvGenJnlLineWithPmtDiscDate(var GenJnlLine: Record "Gen. Journal Line"; PmtDiscDate: Date; GLAccNo: Code[20]; AccType: Enum "Gen. Journal Account Type"; AccNo: Code[20]; Amount: Decimal)
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJnlLine, GenJnlLine."Document Type"::Invoice, AccType, AccNo, Amount);
        GenJnlLine.Validate("Pmt. Discount Date", PmtDiscDate);
        GenJnlLine.Validate("Bal. Account No.", GLAccNo);
        GenJnlLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJnlLine);
    end;

    local procedure PostPurchInvWithMultipleBalLines(var InvGenJnlLine: Record "Gen. Journal Line") InvAmount: Decimal
    var
        GenPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        Vendor: Record Vendor;
        GenJnlLine: Record "Gen. Journal Line";
        BalGLAccNo: Code[20];
        LinesCount: Integer;
        LineAmount: array[10] of Decimal;
        i: Integer;
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        Vendor.Get(CreateVendorWithSetup(VATPostingSetup."VAT Bus. Posting Group"));
        UpdatePmtDiscAccountsInGenPostingSetup(GenPostingSetup, Vendor."Gen. Bus. Posting Group");
        SetAdjForPmtDiscInVATPostingSetup(VATPostingSetup);

        InitGenJnlLine(GenJnlLine);
        LibraryERM.CreateGeneralJnlLine(
            GenJnlLine, GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name", GenJnlLine."Document Type"::Invoice, GenJnlLine."Account Type"::Vendor,
            Vendor."No.", -LibraryRandom.RandIntInRange(3, 10) * LibraryRandom.RandDec(100, 2));
        InvGenJnlLine := GenJnlLine;
        InvAmount := InvGenJnlLine.Amount;

        BalGLAccNo :=
          CreateGLAccountWithSetup(
            GenPostingSetup."Gen. Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group", 1);
        // 1 as for Purchase
        InitBalGenJnlLineSetup(LinesCount, LineAmount, -InvAmount);
        for i := 1 to LinesCount do begin
            LibraryERM.CreateGeneralJnlLine(
              GenJnlLine, GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name", GenJnlLine."Document Type"::Invoice, GenJnlLine."Account Type"::"G/L Account",
              BalGLAccNo, LineAmount[i]);
            GenJnlLine.Validate("Document No.", InvGenJnlLine."Document No.");
            GenJnlLine.Validate("Gen. Bus. Posting Group", GenPostingSetup."Gen. Bus. Posting Group");
            GenJnlLine.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
            GenJnlLine.Modify(true);
        end;
        exit(InvAmount);
    end;

    local procedure PostSalesInvWithMultipleBalLines(var InvGenJnlLine: Record "Gen. Journal Line") InvAmount: Decimal
    var
        GenPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        Customer: Record Customer;
        GenJnlLine: Record "Gen. Journal Line";
        BalGLAccNo: Code[20];
        LinesCount: Integer;
        LineAmount: array[10] of Decimal;
        i: Integer;
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        Customer.Get(CreateCustomerWithSetup(VATPostingSetup."VAT Bus. Posting Group"));
        UpdatePmtDiscAccountsInGenPostingSetup(GenPostingSetup, Customer."Gen. Bus. Posting Group");
        SetAdjForPmtDiscInVATPostingSetup(VATPostingSetup);

        InitGenJnlLine(GenJnlLine);
        LibraryERM.CreateGeneralJnlLine(
            GenJnlLine, GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name", GenJnlLine."Document Type"::Invoice, GenJnlLine."Account Type"::Customer,
            Customer."No.", LibraryRandom.RandIntInRange(3, 10) * LibraryRandom.RandDec(100, 2));
        InvGenJnlLine := GenJnlLine;
        InvAmount := InvGenJnlLine.Amount;

        BalGLAccNo :=
          CreateGLAccountWithSetup(
            GenPostingSetup."Gen. Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group", 2);
        // 2 as for Sale
        InitBalGenJnlLineSetup(LinesCount, LineAmount, -InvAmount);
        for i := 1 to LinesCount do begin
            LibraryERM.CreateGeneralJnlLine(
              GenJnlLine, GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name", GenJnlLine."Document Type"::Invoice, GenJnlLine."Account Type"::"G/L Account",
              BalGLAccNo, LineAmount[i]);
            GenJnlLine.Validate("Document No.", InvGenJnlLine."Document No.");
            GenJnlLine.Validate("Gen. Bus. Posting Group", GenPostingSetup."Gen. Bus. Posting Group");
            GenJnlLine.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
            GenJnlLine.Validate("Bill-to/Pay-to No.", Customer."No.");
            GenJnlLine.Modify(true);
        end;
        exit(InvAmount);
    end;

    local procedure PostApplicationJnlLine(GenJournalLine: Record "Gen. Journal Line"; CurrencyCode: Code[10]; GenJnlDocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; Amount2: Decimal; DueDate: Date): Code[20]
    var
        GenJournalLine2: Record "Gen. Journal Line";
    begin
        // Set Amount and Posting Date with Payment Terms for Payment Tolerance Discount.
        CreateDocumentLine(GenJournalLine2, GenJnlDocumentType, AccountType, GenJournalLine."Account No.", Amount2, CurrencyCode, DueDate);

        // Exercise: Apply Document with Gen. Journal Line and Post it.
        UpdateAndPostGenJnlLine(GenJournalLine2, GenJournalLine."Document Type", GenJournalLine."Document No.");
        exit(GenJournalLine2."Document No.");
    end;

    local procedure CreateDocumentLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal; CurrencyCode: Code[10]; PostingDate: Date)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // Select Journal Batch Name and Template Name.
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
          AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Modify(true);
    end;

    local procedure InitGenJnlLine(var GenJnlLine: Record "Gen. Journal Line")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJnlLine.Init();
        GenJnlLine."Journal Template Name" := GenJournalBatch."Journal Template Name";
        GenJnlLine."Journal Batch Name" := GenJournalBatch.Name;
    end;

    local procedure InitBalGenJnlLineSetup(var LinesCount: Integer; var LineAmount: array[10] of Decimal; InvAmount: Decimal)
    var
        BaseLineAmount: Decimal;
        TotalLineAmount: Decimal;
        i: Integer;
    begin
        LinesCount := LibraryRandom.RandIntInRange(3, 10);
        BaseLineAmount := Round(InvAmount / LinesCount);
        TotalLineAmount := 0;
        for i := 1 to LinesCount do begin
            LineAmount[i] := BaseLineAmount;
            TotalLineAmount += LineAmount[i];
        end;
        if TotalLineAmount <> InvAmount then
            LineAmount[LinesCount] += InvAmount - TotalLineAmount;
    end;

    local procedure UpdateAndPostGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; AppliestoDocType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    begin
        GenJournalLine.Validate("Applies-to Doc. Type", AppliestoDocType);
        GenJournalLine.Validate("Applies-to Doc. No.", DocumentNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure GetTransactionNoFromUnappliedVendorDtldEntry(DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20]): Integer
    var
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        DtldVendLedgEntry.SetRange("Document Type", DocType);
        DtldVendLedgEntry.SetRange("Document No.", DocNo);
        DtldVendLedgEntry.SetRange(Unapplied, true);
        DtldVendLedgEntry.FindFirst();
        exit(DtldVendLedgEntry."Transaction No.");
    end;

    local procedure GetTransactionNoFromUnappliedCustomerDtldEntry(DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20]): Integer
    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DtldCustLedgEntry.SetRange("Document Type", DocType);
        DtldCustLedgEntry.SetRange("Document No.", DocNo);
        DtldCustLedgEntry.SetRange(Unapplied, true);
        DtldCustLedgEntry.FindLast();
        exit(DtldCustLedgEntry."Transaction No.");
    end;

    local procedure GetVATEntryBase(var VATEntry: Record "VAT Entry"; DocumentNo: Code[20]; AccountNo: Code[20])
    begin
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Payment);
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.SetRange("Bill-to/Pay-to No.", AccountNo);
        VATEntry.CalcSums(Base);
    end;

    local procedure VerifyVATEntryFullVATSetup(GeneralPostingSetup: Record "General Posting Setup"; VATPostingSetup: Record "VAT Posting Setup"; GenJournalLine: Record "Gen. Journal Line"; PaymentToleranceAmount: Decimal)
    var
        VATEntry: Record "VAT Entry";
    begin
        FindVATEntry(VATEntry, GeneralPostingSetup, VATPostingSetup, GenJournalLine);
        Assert.AreEqual(0, VATEntry.Base, StrSubstNo(PaymentToleranceLineErr, VATEntry.TableCaption));
        Assert.AreEqual(PaymentToleranceAmount, VATEntry.Amount, StrSubstNo(PaymentToleranceLineErr, VATEntry.TableCaption));
    end;

    local procedure VerifyGLEntryFullVATSetup(GeneralPostingSetup: Record "General Posting Setup"; VATPostingSetup: Record "VAT Posting Setup"; PaymentToleranceAmount: Decimal; AccountNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        FindGLEntry(GLEntry, GeneralPostingSetup, VATPostingSetup, AccountNo);
        Assert.AreEqual(0, GLEntry.Amount, StrSubstNo(PaymentToleranceLineErr, GLEntry.TableCaption));
        Assert.AreEqual(PaymentToleranceAmount, GLEntry."VAT Amount", StrSubstNo(PaymentToleranceLineErr, GLEntry.TableCaption));
    end;

    local procedure VerifyVATEntryNormalVATSetup(GeneralPostingSetup: Record "General Posting Setup"; VATPostingSetup: Record "VAT Posting Setup"; GenJournalLine: Record "Gen. Journal Line"; PaymentToleranceAmount: Decimal)
    var
        VATEntry: Record "VAT Entry";
        BaseAmount: Decimal;
    begin
        FindVATEntry(VATEntry, GeneralPostingSetup, VATPostingSetup, GenJournalLine);
        BaseAmount := Round(PaymentToleranceAmount / (1 + VATPostingSetup."VAT %" / 100));
        Assert.AreEqual(BaseAmount, VATEntry.Base, StrSubstNo(PaymentToleranceLineErr, VATEntry.TableCaption));
        Assert.AreEqual(Round(BaseAmount * VATPostingSetup."VAT %" / 100), VATEntry.Amount, StrSubstNo(PaymentToleranceLineErr, VATEntry.TableCaption));
    end;

    local procedure VerifyGLEntryNormalVATSetup(GeneralPostingSetup: Record "General Posting Setup"; VATPostingSetup: Record "VAT Posting Setup"; PaymentToleranceAmount: Decimal; AccountNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
        BaseAmount: Decimal;
    begin
        FindGLEntry(GLEntry, GeneralPostingSetup, VATPostingSetup, AccountNo);
        BaseAmount := Round(PaymentToleranceAmount / (1 + VATPostingSetup."VAT %" / 100));
        Assert.AreEqual(BaseAmount, GLEntry.Amount, StrSubstNo(PaymentToleranceLineErr, GLEntry.TableCaption));
        Assert.AreEqual(
          Round(BaseAmount * VATPostingSetup."VAT %" / 100), GLEntry."VAT Amount", StrSubstNo(PaymentToleranceLineErr, GLEntry.TableCaption));
    end;

    local procedure VerifyGLEntryOnUnapplyPartialPayment(AccountNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("G/L Account No.", AccountNo);
        Assert.IsTrue(GLEntry.IsEmpty, StrSubstNo(UnappliedLineErr, GLEntry.TableCaption(), AccountNo));
    end;

    local procedure VerifyUnappliedVendorVATEntries(DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20]; ExpectedAmount: Decimal)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document Type", DocType);
        VATEntry.SetRange("Document No.", DocNo);
        VATEntry.SetRange("Transaction No.", GetTransactionNoFromUnappliedVendorDtldEntry(DocType, DocNo));
        VATEntry.CalcSums(Base, Amount);
        Assert.AreEqual(
          ExpectedAmount, VATEntry.Base + VATEntry.Amount, StrSubstNo(WrongVATEntriesAmountErr, VATEntry.GetFilters));
    end;

    local procedure VerifyUnappliedCustomerVATEntries(DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20]; ExpectedAmount: Decimal)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document Type", DocType);
        VATEntry.SetRange("Document No.", DocNo);
        VATEntry.SetRange("Transaction No.", GetTransactionNoFromUnappliedCustomerDtldEntry(DocType, DocNo));
        VATEntry.CalcSums(Base, Amount);
        Assert.AreEqual(
          ExpectedAmount, VATEntry.Base + VATEntry.Amount, StrSubstNo(WrongVATEntriesAmountErr, VATEntry.GetFilters));
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyCustomerEntriesPageHandlerSelectLastDocument(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    begin
        ApplyCustomerEntries.Last();
        ApplyCustomerEntries.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure VendorLedgerEntriesPageHandlerUnapply(var VendorLedgerEntries: TestPage "Vendor Ledger Entries")
    begin
        VendorLedgerEntries.UnapplyEntries.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure UnapplyVendorEntriesPageHandler(var UnapplyVendorEntries: TestPage "Unapply Vendor Entries")
    begin
        UnapplyVendorEntries.Unapply.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PaymentToleranceWarningHandler(var PaymentToleranceWarning: Page "Payment Tolerance Warning"; var Response: Action)
    begin
        // Modal Page Handler for Payment Tolerance Warning.
        PaymentToleranceWarning.InitializeOption(LibraryVariableStorage.DequeueInteger());
        Response := ACTION::Yes;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // This is a dummy Handler
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure CustomerLedgerEntriesPageHandlerUnapply(var CustomerLedgerEntries: TestPage "Customer Ledger Entries")
    begin
        CustomerLedgerEntries.UnapplyEntries.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure UnapplyCustomerEntriesPageHandler(var UnapplyCustomerEntries: TestPage "Unapply Customer Entries")
    begin
        UnapplyCustomerEntries.Unapply.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyVendorEntriesPageHandlerSelectLastDocument(var ApplyVendorEntries: TestPage "Apply Vendor Entries")
    begin
        ApplyVendorEntries.Last();
        ApplyVendorEntries.OK().Invoke();
    end;
}

