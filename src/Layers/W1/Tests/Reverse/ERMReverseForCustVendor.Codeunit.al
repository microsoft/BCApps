codeunit 134129 "ERM Reverse For Cust/Vendor"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Reverse]
        isInitialized := false;
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPmtDiscSetup: Codeunit "Library - Pmt Disc Setup";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        Assert: Codeunit Assert;
        isInitialized: Boolean;
        ReversalErr: Label 'You cannot reverse G/L Register No. %1 because the register has already been involved in a reversal.';
        ReverseSignErr: Label 'Reversed Sign must be TRUE.';
        CustUnapplyErr: Label 'You cannot unapply Cust. Ledger Entry No. %1 because the entry';
        VendUnapplyErr: Label 'You cannot unapply Vendor Ledger Entry No. %1 because the entry';
        ReversalSuccessfulTxt: Label 'The entries were successfully reversed.';

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostAndReverseEntries()
    var
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        GLRegisterNo: Integer;
        DocumentNo: Code[20];
    begin
        // Create and Post General Journal Line and Reverse them and Check Reversed Entries.

        Initialize();
        LibraryERM.FindGLAccount(GLAccount);
        DocumentNo := PostGeneralLineAndReverse(GLRegisterNo, GenJournalLine."Account Type"::"G/L Account", GLAccount."No.");

        // Verify: Verify that Posted entry has been reversed successfully on G/L Entry, Bank Ledger Entry, G/L Register and VAT Entry.
        VerifyGLRegister(GLRegisterNo);
        VerifyGLEntry(DocumentNo);
        VerifyBankEntry(DocumentNo);
        VerifyVATEntry(DocumentNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostReverseAndReverseError()
    var
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        ReversalEntry: Record "Reversal Entry";
        GLRegisterNo: Integer;
    begin
        // Create and Post General Journal Line, Reverse them and check error when try to reverse again.

        Initialize();
        LibraryERM.FindGLAccount(GLAccount);
        PostGeneralLineAndReverse(GLRegisterNo, GenJournalLine."Account Type"::"G/L Account", GLAccount."No.");

        // Verify: Verify that after reversed successfully error raised when try to Reversed again.
        ReversalEntry.SetHideDialog(true);
        asserterror ReversalEntry.ReverseRegister(GLRegisterNo);
        Assert.AreEqual(StrSubstNo(ReversalErr, GLRegisterNo), GetLastErrorText, 'Unknown Error');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostAndUnapplyReverseForCust()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLRegisterNo: Integer;
        DocumentNo: Code[20];
    begin
        // Create and Post General Journal Line for Customer and Reverse them and check error while Unapply on Customer Ledger Entry.

        Initialize();
        DocumentNo :=
          PostGeneralLineAndReverse(
            GLRegisterNo, GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo());

        // Verify: Verify Customer Ledger Entry after reversed successfully and error raised when try to Unapply Reversed Entry.
        VerifyReversedCustLedgEntry(DocumentNo, GenJournalLine."Document Type"::" ");
        VerifyUnapplyCustLedgEntry(DocumentNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostAndUnapplyReverseForVendor()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLRegisterNo: Integer;
        DocumentNo: Code[20];
    begin
        // Create and Post General Journal Line for Vendor and Reverse them and check error while Unapply on Vendor Ledger Entry.

        Initialize();
        DocumentNo :=
          PostGeneralLineAndReverse(
            GLRegisterNo, GenJournalLine."Account Type"::Vendor, LibraryPurchase.CreateVendorNo());

        // Verify: Verify Vendor Ledger Entry after reversed successfully and error raised when try to Unapply Reversed Entry.
        VerifyReversedVendLedgEntry(DocumentNo, GenJournalLine."Document Type"::" ");
        VerifyUnapplyVendLedgEntry(DocumentNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ReversalMessageHandler')]
    [Scope('OnPrem')]
    procedure ReverseCustPmtTransactionWithUnrealizedVAT()
    var
        ReversalEntry: Record "Reversal Entry";
        VATEntry: Record "VAT Entry";
        CustNo: Code[20];
        DocNo: Code[20];
        PmtDocNo: Code[20];
        TransactionNo: Integer;
    begin
        // Setup: Set "Unrealized VAT", Create Customer, Create and Post Invoice, Create, Post, and Apply/Unapply Payment
        Initialize();
        LibraryERM.SetUnrealizedVAT(true);
        DocNo := CreateAndPostSalesDocumentUnrealizedVAT(CustNo);
        PmtDocNo := CreatePostAndApplyUnapplyCustPmt(CustNo, DocNo);
        TransactionNo := GetPmtVATTransactionNo(VATEntry, PmtDocNo);

        // Exercise: Reverse Posted Entry from Customer Legder.
        ReversalEntry.SetHideDialog(true);
        ReversalEntry.ReverseTransaction(TransactionNo);

        // [THEN] Validation of successful reversal in message handler
        ResetUnrealizedVATType();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ReversalMessageHandler')]
    [Scope('OnPrem')]
    procedure ReverseVendPmtTransactionWithUnrealizedVAT()
    var
        ReversalEntry: Record "Reversal Entry";
        VATEntry: Record "VAT Entry";
        VendNo: Code[20];
        DocNo: Code[20];
        PmtDocNo: Code[20];
        TransactionNo: Integer;
    begin
        // Setup: Set "Unrealized VAT", Create Vendor, Create and Post Invoice, Create, Post, and Apply/Unapply Payment
        Initialize();
        LibraryERM.SetUnrealizedVAT(true);
        DocNo := CreateAndPostPurchDocumentUnrealizedVAT(VendNo);
        PmtDocNo := CreatePostAndApplyUnapplyVendPmt(VendNo, DocNo);
        TransactionNo := GetPmtVATTransactionNo(VATEntry, PmtDocNo);

        // Exercise: Reverse Posted Entry from Customer Legder.
        ReversalEntry.SetHideDialog(true);
        ReversalEntry.ReverseTransaction(TransactionNo);

        // [THEN] Validation of successful reversal in message handler
        ResetUnrealizedVATType();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ReverseCustPmtTransactionWithPmtDisc()
    var
        ReversalEntry: Record "Reversal Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustNo: Code[20];
        DocNo: Code[20];
        PmtDocNo: Code[20];
        TransactionNo: Integer;
    begin
        // [SCENARIO 360351] It is not allowed to reverse unapplied Sales Payment transaction with associated Payment Discount
        Initialize();
        SetGLSetupAdjPmtDisc();
        // [GIVEN] Sales Invoice with Payment Term for possible discount
        DocNo := CreateAndPostSalesDocumentPmtDisc(CustNo);
        // [GIVEN] Payment with granted Payment Discount, applied to invoice, then unapplied
        PmtDocNo := CreatePostAndApplyUnapplyCustPmt(CustNo, DocNo);
        TransactionNo := GetCustPmtTransactionNo(CustLedgerEntry, PmtDocNo);
        // [WHEN] Reverse payment transaction
        ReversalEntry.SetHideDialog(true);
        ReversalEntry.ReverseTransaction(TransactionNo);

        // [THEN] Reversed entries for unapply transaction are created
        VerifyReversedCustLedgEntry(PmtDocNo, CustLedgerEntry."Document Type"::Payment);

        // [THEN] Two reversed VAT Entries with zero balance are created
        VerifyReversedVATEntryZeroBalanceCount(PmtDocNo, CustLedgerEntry."Document Type", CustNo, 2);

        // [THEN] 7 reversed G/L Entries wil zero balance are created
        VerifyReversedGLEntryZeroBalanceCount(PmtDocNo, CustLedgerEntry."Document Type", 7);

        ReSetGLSetupAdjPmtDisc();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ReverseVendPmtTransactionWithPmtDisc()
    var
        ReversalEntry: Record "Reversal Entry";
        VendLedgerEntry: Record "Vendor Ledger Entry";
        VendNo: Code[20];
        DocNo: Code[20];
        PmtDocNo: Code[20];
        TransactionNo: Integer;
    begin
        // [SCENARIO 360351] It is not allowed to reverse unapplied Purchase Payment transaction with associated Payment Discount
        Initialize();
        SetGLSetupAdjPmtDisc();
        // [GIVEN] Purchase Invoice with Payment Term for possible discount
        DocNo := CreateAndPostPurchDocumentPmtDisc(VendNo);
        // [GIVEN] Payment with granted Payment Discount, applied to invoice, then unapplied
        PmtDocNo := CreatePostAndApplyUnapplyVendPmt(VendNo, DocNo);
        TransactionNo := GetVendPmtTransactionNo(VendLedgerEntry, PmtDocNo);
        // [WHEN] Reverse payment transaction
        ReversalEntry.SetHideDialog(true);
        ReversalEntry.ReverseTransaction(TransactionNo);

        // [THEN] Reversed entries for unapply transaction are created
        VerifyReversedVendLedgEntry(PmtDocNo, VendLedgerEntry."Document Type"::Payment);

        // [THEN] Two reversed VAT Entries are created
        VerifyReversedVATEntryZeroBalanceCount(PmtDocNo, VendLedgerEntry."Document Type", VendNo, 2);

        // [THEN] 7 reversed G/L Entries wil zero balance are created
        VerifyReversedGLEntryZeroBalanceCount(PmtDocNo, VendLedgerEntry."Document Type", 7);

        ReSetGLSetupAdjPmtDisc();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ReverseUnappliedPurchasePaymentFromInvoices()
    var
        Vendor: Record Vendor;
        ReversalEntry: Record "Reversal Entry";
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PaymentNo: Code[20];
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 380984] Reverse unapplied Purchase Payment transaction when some Purchase Invoices were applied
        Initialize();

        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Application Method", Vendor."Application Method"::"Apply to Oldest");
        Vendor.Modify(true);

        // [GIVEN] Posted Purchase Invoice "Inv1" (of Amount -10), Payment (of Amount 100) and Invoice "Inv2" (of Amount -100) using Apply to Oldest method.
        CreatePostGenJnlLinesWithApplyToOldest(GenJournalLine."Account Type"::Vendor, Vendor."No.", 1, PaymentNo, InvoiceNo);

        // [GIVEN] All documents are unapplied
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, GenJournalLine."Document Type"::Invoice, InvoiceNo);
        LibraryERM.UnapplyVendorLedgerEntry(VendorLedgerEntry);
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, GenJournalLine."Document Type"::Payment, PaymentNo);
        LibraryERM.UnapplyVendorLedgerEntry(VendorLedgerEntry);

        // [WHEN] Reverse Payment transaction
        ReversalEntry.SetHideDialog(true);
        ReversalEntry.ReverseTransaction(VendorLedgerEntry."Transaction No.");

        // [THEN] Payment's G/L Entries reversed, Invoice's "Inv2" G/L Entries are not reversed
        VerifyGLEntryReversed(PaymentNo);
        VerifyGLEntryNotReversed(InvoiceNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ReverseUnappliedSalesPaymentFromInvoices()
    var
        Customer: Record Customer;
        ReversalEntry: Record "Reversal Entry";
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        PaymentNo: Code[20];
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 380984] Reverse unapplied Sales Payment transaction when some Sales Invoices were applied
        Initialize();

        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Application Method", Customer."Application Method"::"Apply to Oldest");
        Customer.Modify(true);

        // [GIVEN] Posted Sales Invoice "Inv1" (of Amount 10), Payment (of Amount -100) and Invoice "Inv2" (of Amount 100) using Apply to Oldest method.
        CreatePostGenJnlLinesWithApplyToOldest(GenJournalLine."Account Type"::Customer, Customer."No.", -1, PaymentNo, InvoiceNo);

        // [GIVEN] All documents are unapplied
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, GenJournalLine."Document Type"::Invoice, InvoiceNo);
        LibraryERM.UnapplyCustomerLedgerEntry(CustLedgerEntry);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, GenJournalLine."Document Type"::Payment, PaymentNo);
        LibraryERM.UnapplyCustomerLedgerEntry(CustLedgerEntry);

        // [WHEN] Reverse Payment transaction
        ReversalEntry.SetHideDialog(true);
        ReversalEntry.ReverseTransaction(CustLedgerEntry."Transaction No.");

        // [THEN] Payment's G/L Entries reversed, Invoices "Inv2" G/L Entries are not reversed
        VerifyGLEntryReversed(PaymentNo);
        VerifyGLEntryNotReversed(InvoiceNo);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"ERM Reverse For Cust/Vendor");

        LibrarySetupStorage.Restore();
        if isInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"ERM Reverse For Cust/Vendor");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        isInitialized := true;
        Commit();

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"ERM Reverse For Cust/Vendor");
    end;

    local procedure PostGeneralLineAndReverse(var GLRegisterNo: Integer; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]) DocumentNo: Code[20]
    begin
        // Setup: Create General Journal Line and Post it.
        DocumentNo := CreatePostGeneralJournalLine(AccountType, AccountNo);

        // Exercise: Reverse Posted Entry.
        GLRegisterNo := ReverseEntry();
    end;

    local procedure CreatePostGeneralJournalLine(AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
        BankAccount: Record "Bank Account";
    begin
        BankAccount.SetRange(Blocked, false);
        BankAccount.FindFirst();
        CreateGeneralJournalLine(GenJournalLine, AccountType, AccountNo);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Bal. Account No.", BankAccount."No.");
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine."Document No.");
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          AccountType, AccountNo, LibraryRandom.RandInt(100)); // Take Random Amount for General Journal Line.
    end;

    local procedure UpdateVATPostingSetupPmtDisc(GLAccount: Record "G/L Account")
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.Get(GLAccount."VAT Bus. Posting Group", GLAccount."VAT Prod. Posting Group");
        VATPostingSetup.Validate("Adjust for Payment Discount", true);
        VATPostingSetup.Modify(true);
    end;

    local procedure UpdateVATPostingSetupUnrealizedVAT(GLAccount: Record "G/L Account")
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.Get(GLAccount."VAT Bus. Posting Group", GLAccount."VAT Prod. Posting Group");
        VATPostingSetup.Validate("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::Percentage);
        VATPostingSetup.Validate("Sales VAT Unreal. Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("Purch. VAT Unreal. Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Modify(true);
    end;

    local procedure UpdateGenPostingSetupPmtDisc(GLAccount: Record "G/L Account")
    var
        GenPostingSetup: Record "General Posting Setup";
    begin
        GenPostingSetup.Get(GLAccount."Gen. Bus. Posting Group", GLAccount."Gen. Prod. Posting Group");
        GenPostingSetup."Sales Pmt. Disc. Debit Acc." := LibraryERM.CreateGLAccountNo();
        GenPostingSetup."Sales Pmt. Disc. Credit Acc." := LibraryERM.CreateGLAccountNo();
        GenPostingSetup."Purch. Pmt. Disc. Debit Acc." := LibraryERM.CreateGLAccountNo();
        GenPostingSetup."Purch. Pmt. Disc. Credit Acc." := LibraryERM.CreateGLAccountNo();
        GenPostingSetup.Modify(true);
    end;

    local procedure CreateCustomer(GenBusPostingGroupCode: Code[20]; VATBusPostingGroupCode: Code[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);

        Customer.Validate("Gen. Bus. Posting Group", GenBusPostingGroupCode);
        Customer.Validate("VAT Bus. Posting Group", VATBusPostingGroupCode);
        Customer.Validate("Payment Terms Code", CreatePaymentTerm());
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateVendor(GenBusPostingGroupCode: Code[20]; VATBusPostingGroupCode: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);

        Vendor.Validate("Gen. Bus. Posting Group", GenBusPostingGroupCode);
        Vendor.Validate("VAT Bus. Posting Group", VATBusPostingGroupCode);
        Vendor.Validate("Payment Terms Code", CreatePaymentTerm());
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreatePaymentTerm(): Code[10]
    var
        PaymentTerms: Record "Payment Terms";
    begin
        LibraryERM.CreatePaymentTermsDiscount(PaymentTerms, false);
        exit(PaymentTerms.Code);
    end;

    local procedure CreatePostingSetupPmtDisc(GLAccount: Record "G/L Account")
    begin
        UpdateGenPostingSetupPmtDisc(GLAccount);
        UpdateVATPostingSetupPmtDisc(GLAccount);
    end;

    local procedure GetPmtVATTransactionNo(var VATEntry: Record "VAT Entry"; DocumentNo: Code[20]): Integer
    begin
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Payment);
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.FindFirst();
        exit(VATEntry."Transaction No.");
    end;

    local procedure GetCustPmtTransactionNo(var CustLedgerEntry: Record "Cust. Ledger Entry"; DocumentNo: Code[20]): Integer
    begin
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Payment);
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        CustLedgerEntry.FindFirst();
        exit(CustLedgerEntry."Transaction No.");
    end;

    local procedure GetVendPmtTransactionNo(var VendLedgerEntry: Record "Vendor Ledger Entry"; DocumentNo: Code[20]): Integer
    begin
        VendLedgerEntry.SetRange("Document Type", VendLedgerEntry."Document Type"::Payment);
        VendLedgerEntry.SetRange("Document No.", DocumentNo);
        VendLedgerEntry.FindFirst();
        exit(VendLedgerEntry."Transaction No.");
    end;

    local procedure ReverseEntry(): Integer
    var
        ReversalEntry: Record "Reversal Entry";
        GLRegister: Record "G/L Register";
    begin
        GLRegister.FindLast();
        ReversalEntry.SetHideDialog(true);
        ReversalEntry.ReverseRegister(GLRegister."No.");
        exit(GLRegister."No.");
    end;

    local procedure SetGLSetupAdjPmtDisc()
    begin
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(true);
        LibraryERM.SetInvRoundingPrecisionLCY(0.01);
    end;

    local procedure ResetGLSetupAdjPmtDisc()
    begin
        LibraryPmtDiscSetup.ClearAdjustPmtDiscInVATSetup();
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(false);
    end;

    local procedure ResetUnrealizedVATType()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.SetFilter("Unrealized VAT Type", '<>%1', VATPostingSetup."Unrealized VAT Type"::" ");
        VATPostingSetup.ModifyAll("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::" ");
    end;

    local procedure VerifyGLEntry(DocumentNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
        Assert: Codeunit Assert;
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::" ");
        GLEntry.FindSet();
        repeat
            Assert.AreEqual(true, GLEntry.Reversed, ReverseSignErr);
        until GLEntry.Next() = 0;
    end;

    local procedure VerifyGLRegister(GLRegisterNo: Integer)
    var
        GLRegister: Record "G/L Register";
    begin
        GLRegister.SetRange("No.", GLRegisterNo);
        GLRegister.FindFirst();
        Assert.AreEqual(true, GLRegister.Reversed, ReverseSignErr);
    end;

    local procedure VerifyBankEntry(DocumentNo: Code[20])
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        Assert: Codeunit Assert;
    begin
        BankAccountLedgerEntry.SetRange("Document No.", DocumentNo);
        BankAccountLedgerEntry.SetRange("Document Type", BankAccountLedgerEntry."Document Type"::" ");
        BankAccountLedgerEntry.FindSet();
        repeat
            Assert.AreEqual(true, BankAccountLedgerEntry.Reversed, ReverseSignErr);
        until BankAccountLedgerEntry.Next() = 0;
    end;

    local procedure VerifyVATEntry(DocumentNo: Code[20])
    var
        VATEntry: Record "VAT Entry";
        Assert: Codeunit Assert;
    begin
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::" ");
        VATEntry.FindSet();
        repeat
            Assert.AreEqual(true, VATEntry.Reversed, ReverseSignErr);
        until VATEntry.Next() = 0;
    end;

    local procedure VerifyUnapplyCustLedgEntry(DocumentNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Assert: Codeunit Assert;
        CustEntryApplyPostedEntries: Codeunit "CustEntry-Apply Posted Entries";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::" ", DocumentNo);
        asserterror CustEntryApplyPostedEntries.UnApplyCustLedgEntry(CustLedgerEntry."Entry No.");
        Assert.ExpectedError(StrSubstNo(CustUnapplyErr, CustLedgerEntry."Entry No."));
    end;

    local procedure VerifyReversedCustLedgEntry(DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Assert: Codeunit Assert;
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocumentType, DocumentNo);
        CustLedgerEntry.FindSet();
        repeat
            Assert.AreEqual(true, CustLedgerEntry.Reversed, ReverseSignErr);
        until CustLedgerEntry.Next() = 0;
    end;

    local procedure VerifyUnapplyVendLedgEntry(DocumentNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Assert: Codeunit Assert;
        VendEntryApplyPostedEntries: Codeunit "VendEntry-Apply Posted Entries";
    begin
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::" ", DocumentNo);
        asserterror VendEntryApplyPostedEntries.UnApplyVendLedgEntry(VendorLedgerEntry."Entry No.");
        Assert.ExpectedError(StrSubstNo(VendUnapplyErr, VendorLedgerEntry."Entry No."));
    end;

    local procedure VerifyReversedVendLedgEntry(DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Assert: Codeunit Assert;
    begin
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, DocumentType, DocumentNo);
        VendorLedgerEntry.FindSet();
        repeat
            Assert.AreEqual(true, VendorLedgerEntry.Reversed, ReverseSignErr);
        until VendorLedgerEntry.Next() = 0;
    end;

    local procedure VerifyGLEntryReversed(DocumentNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange(Reversed, true);
        GLEntry.SetRange("Reversed by Entry No.", 0);
        Assert.RecordIsNotEmpty(GLEntry);
    end;

    local procedure VerifyGLEntryNotReversed(DocumentNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange(Reversed, true);
        Assert.RecordIsEmpty(GLEntry);
    end;

    local procedure VerifyReversedVATEntryZeroBalanceCount(DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; AccountNo: Code[20]; ExpectedCount: Integer)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document Type", DocumentType);
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.SetRange("Bill-to/Pay-to No.", AccountNo);
        VATEntry.SetRange(Reversed, true);
        VATEntry.SetRange("Reversed by Entry No.", 0);
        Assert.RecordCount(VATEntry, ExpectedCount);
        VATEntry.CalcSums(Amount);
        VATEntry.TestField(Amount, 0);
    end;

    local procedure VerifyReversedGLEntryZeroBalanceCount(DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; ExpectedCount: Integer)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetFilter("Document Type", '%1|%2', DocumentType, GLEntry."Document Type"::" "); // payment discount entries posted with blank "Document Type"
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange(Reversed, true);
        GLEntry.SetRange("Reversed by Entry No.", 0);
        Assert.RecordCount(GLEntry, ExpectedCount);
        GLEntry.CalcSums(Amount);
        GLEntry.TestField(Amount, 0);
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; GLAccountNo: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccountNo, LibraryRandom.RandDec(10, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(100, 200, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreateAndPostSalesDocumentPmtDisc(var CustNo: Code[20]): Code[20]
    var
        GLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
    begin
        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        CreatePostingSetupPmtDisc(GLAccount);

        CustNo :=
          CreateCustomer(GLAccount."Gen. Bus. Posting Group", GLAccount."VAT Bus. Posting Group");
        CreateSalesDocument(SalesHeader, CustNo, GLAccount."No.");
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateAndPostSalesDocumentUnrealizedVAT(var CustNo: Code[20]): Code[20]
    var
        GLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
    begin
        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        UpdateVATPostingSetupUnrealizedVAT(GLAccount);

        CustNo :=
          CreateCustomer(
            GLAccount."Gen. Bus. Posting Group", GLAccount."VAT Bus. Posting Group");

        CreateSalesDocument(SalesHeader, CustNo, GLAccount."No.");
        SalesHeader.Validate("Payment Discount %", 0);
        SalesHeader.Modify(true);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreatePostAndApplyUnapplyCustPmt(CustNo: Code[20]; DocNo: Code[20]): Code[20]
    var
        GenJnlLine: Record "Gen. Journal Line";
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgEntry, CustLedgEntry."Document Type"::Invoice, DocNo);
        CustLedgEntry.CalcFields(Amount);

        CreateGeneralJournalLine(GenJnlLine, GenJnlLine."Account Type"::Customer, CustNo);
        ModifyGeneralJournalLine(GenJnlLine, DocNo, -CustLedgEntry.Amount);
        LibraryERM.PostGeneralJnlLine(GenJnlLine);

        LibraryERM.FindCustomerLedgerEntry(
          CustLedgEntry, CustLedgEntry."Document Type"::Payment, GenJnlLine."Document No.");
        LibraryERM.UnapplyCustomerLedgerEntry(CustLedgEntry);
        exit(GenJnlLine."Document No.");
    end;

    local procedure ModifyGeneralJournalLine(var GenJnlLine: Record "Gen. Journal Line"; DocNo: Code[20]; DocAmount: Decimal)
    begin
        GenJnlLine.Validate("Document Type", GenJnlLine."Document Type"::Payment);
        GenJnlLine.Validate("Bal. Account Type", GenJnlLine."Bal. Account Type"::"G/L Account");
        GenJnlLine.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNo());
        GenJnlLine.Validate("Applies-to Doc. Type", GenJnlLine."Applies-to Doc. Type"::Invoice);
        GenJnlLine.Validate("Applies-to Doc. No.", DocNo);
        GenJnlLine.Validate(Amount, DocAmount);
        GenJnlLine.Modify(true);
    end;

    local procedure CreatePurchDocument(var PurchHeader: Record "Purchase Header"; VendorNo: Code[20]; GLAccountNo: Code[20])
    var
        PurchLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, VendorNo);
        LibraryPurchase.CreatePurchaseLine(
          PurchLine, PurchHeader, PurchLine.Type::"G/L Account", GLAccountNo, LibraryRandom.RandDec(10, 2));
        PurchLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(100, 200, 2));
        PurchLine.Modify(true);
    end;

    local procedure CreateAndPostPurchDocumentUnrealizedVAT(var VendNo: Code[20]): Code[20]
    var
        GLAccount: Record "G/L Account";
        PurchHeader: Record "Purchase Header";
    begin
        GLAccount.Get(LibraryERM.CreateGLAccountWithPurchSetup());
        UpdateVATPostingSetupUnrealizedVAT(GLAccount);
        VendNo :=
          CreateVendor(
            GLAccount."Gen. Bus. Posting Group", GLAccount."VAT Bus. Posting Group");

        CreatePurchDocument(PurchHeader, VendNo, GLAccount."No.");
        PurchHeader.Validate("Payment Discount %", 0);
        PurchHeader.Modify(true);
        exit(LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true));
    end;

    local procedure CreateAndPostPurchDocumentPmtDisc(var VendNo: Code[20]): Code[20]
    var
        GLAccount: Record "G/L Account";
        PurchHeader: Record "Purchase Header";
    begin
        GLAccount.Get(LibraryERM.CreateGLAccountWithPurchSetup());
        CreatePostingSetupPmtDisc(GLAccount);
        VendNo :=
          CreateVendor(
            GLAccount."Gen. Bus. Posting Group", GLAccount."VAT Bus. Posting Group");

        CreatePurchDocument(PurchHeader, VendNo, GLAccount."No.");
        exit(LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true));
    end;

    local procedure CreatePostAndApplyUnapplyVendPmt(VendNo: Code[20]; DocNo: Code[20]): Code[20]
    var
        GenJnlLine: Record "Gen. Journal Line";
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(
          VendLedgEntry, VendLedgEntry."Document Type"::Invoice, DocNo);
        VendLedgEntry.CalcFields(Amount);

        CreateGeneralJournalLine(GenJnlLine, GenJnlLine."Account Type"::Vendor, VendNo);
        ModifyGeneralJournalLine(GenJnlLine, DocNo, -VendLedgEntry.Amount);
        LibraryERM.PostGeneralJnlLine(GenJnlLine);

        LibraryERM.FindVendorLedgerEntry(
          VendLedgEntry, VendLedgEntry."Document Type"::Payment, GenJnlLine."Document No.");
        LibraryERM.UnapplyVendorLedgerEntry(VendLedgEntry);
        exit(GenJnlLine."Document No.");
    end;

    local procedure CreatePostGenJnlLinesWithApplyToOldest(AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Sign: Integer; var PaymentNo: Code[20]; var InvoiceNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, AccountType, AccountNo,
          -Sign * LibraryRandom.RandDecInRange(10, 20, 2));
        LibraryJournals.CreateGenJournalLine(
          GenJournalLine, GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name",
          GenJournalLine."Document Type"::Payment, AccountType, AccountNo,
          GenJournalLine."Bal. Account Type", GenJournalLine."Bal. Account No.",
          Sign * LibraryRandom.RandDecInRange(100, 200, 2));
        PaymentNo := GenJournalLine."Document No.";
        LibraryJournals.CreateGenJournalLine(
          GenJournalLine, GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name",
          GenJournalLine."Document Type"::Invoice, AccountType, AccountNo,
          GenJournalLine."Bal. Account Type", GenJournalLine."Bal. Account No.", -GenJournalLine.Amount);
        InvoiceNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Message Handler.
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure ReversalMessageHandler(Message: Text[1024])
    begin
        Assert.ExpectedMessage(ReversalSuccessfulTxt, Message);
    end;
}

