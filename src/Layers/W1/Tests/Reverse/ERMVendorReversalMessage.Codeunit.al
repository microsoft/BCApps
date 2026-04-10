codeunit 134128 "ERM Vendor Reversal Message"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Reverse] [Purchase]
    end;

    var
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        IsInitialized: Boolean;
        ReversalFromLedgerErr: Label 'You cannot create this type of document when Vendor %1 is blocked with type %2';
        ReversalFromRegisterErr: Label 'You cannot reverse register number %1 because it contains customer or vendor or employee ledger entries';
        ReversalFromGLEntryErr: Label 'The transaction cannot be reversed, because the Vendor Ledger Entry has been compressed.';
        ReversalFromLedgerPrivacyBlockedErr: Label 'You cannot create this type of document when Vendor %1 is blocked for privacy.';

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PaymentBlockedTypePayment()
    var
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Create Vendor and Post Payment from General Journal Line, update Vendor Blocked field for Payment and
        // verify Reversal Error from Vendor Ledger and GL Register.
        Initialize();
        ReverseFromLedger(GenJournalLine."Document Type"::Payment, Vendor.Blocked::Payment, LibraryRandom.RandDec(100, 2));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure InvoiceBlockedTypeAll()
    var
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Create Vendor and Post Invoice from General Journal Line, update Vendor Blocked field for Payment and
        // verify Reversal Error from Vendor Ledger.
        Initialize();
        ReverseFromLedger(GenJournalLine."Document Type"::Invoice, Vendor.Blocked::All, -LibraryRandom.RandDec(100, 2));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PaymentBlockedTypeAll()
    var
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Create Vendor and Post Payment from General Journal Line, update Vendor Blocked field for Payment and
        // verify Reversal Error from Vendor Ledger.
        Initialize();
        ReverseFromLedger(GenJournalLine."Document Type"::Payment, Vendor.Blocked::All, LibraryRandom.RandDec(100, 2));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoBlockedTypeAll()
    var
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Create Vendor and Post Credit Memo from General Journal Line, update Vendor Blocked field for Payment and
        // verify Reversal Error from Vendor Ledger.
        Initialize();
        ReverseFromLedger(GenJournalLine."Document Type"::"Credit Memo", Vendor.Blocked::All, LibraryRandom.RandDec(100, 2));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure RefundBlockedTypeAll()
    var
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Create Vendor and Post Refund from General Journal Line, update Vendor Blocked field for Payment and
        // verify Reversal Error from Vendor Ledger.
        Initialize();
        ReverseFromLedger(GenJournalLine."Document Type"::Refund, Vendor.Blocked::All, -LibraryRandom.RandDec(100, 2));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure FinChargeMemoBlockedTypeAll()
    var
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Create Vendor and Post Finance Charge Memo from General Journal Line, update Vendor Blocked field for Payment and
        // verify Reversal Error from Vendor Ledger.
        Initialize();
        ReverseFromLedger(
          GenJournalLine."Document Type"::"Finance Charge Memo", Vendor.Blocked::All, -LibraryRandom.RandDec(100, 2));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ReminderBlockedTypeAll()
    var
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Create Vendor and Post Reminder from General Journal Line, update Vendor Blocked field for Payment and
        // verify Reversal Error from Vendor Ledger.
        Initialize();
        ReverseFromLedger(GenJournalLine."Document Type"::Reminder, Vendor.Blocked::All, -LibraryRandom.RandDec(100, 2));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure InvoicePrivacyBlocked()
    var
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Create Vendor and Post Invoice from General Journal Line, update Vendor Blocked field for Payment and
        // verify Reversal Error from Vendor Ledger.
        Initialize();
        ReverseFromLedgerPrivacyBlocked(GenJournalLine."Document Type"::Invoice, Vendor.Blocked::All, -LibraryRandom.RandDec(100, 2));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PaymentPrivacyBlocked()
    var
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Create Vendor and Post Payment from General Journal Line, update Vendor Blocked field for Payment and
        // verify Reversal Error from Vendor Ledger.
        Initialize();
        ReverseFromLedgerPrivacyBlocked(GenJournalLine."Document Type"::Payment, Vendor.Blocked::All, LibraryRandom.RandDec(100, 2));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoPrivacyBlocked()
    var
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Create Vendor and Post Credit Memo from General Journal Line, update Vendor Blocked field for Payment and
        // verify Reversal Error from Vendor Ledger.
        Initialize();
        ReverseFromLedgerPrivacyBlocked(
          GenJournalLine."Document Type"::"Credit Memo", Vendor.Blocked::All, LibraryRandom.RandDec(100, 2));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure RefundPrivacyBlocked()
    var
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Create Vendor and Post Refund from General Journal Line, update Vendor Blocked field for Payment and
        // verify Reversal Error from Vendor Ledger.
        Initialize();
        ReverseFromLedgerPrivacyBlocked(GenJournalLine."Document Type"::Refund, Vendor.Blocked::All, -LibraryRandom.RandDec(100, 2));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure FinChargeMemoPrivacyBlocked()
    var
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Create Vendor and Post Finance Charge Memo from General Journal Line, update Vendor Blocked field for Payment and
        // verify Reversal Error from Vendor Ledger.
        Initialize();
        ReverseFromLedgerPrivacyBlocked(
          GenJournalLine."Document Type"::"Finance Charge Memo", Vendor.Blocked::All, -LibraryRandom.RandDec(100, 2));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ReminderPrivacyBlocked()
    var
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Create Vendor and Post Reminder from General Journal Line, update Vendor Blocked field for Payment and
        // verify Reversal Error from Vendor Ledger.
        Initialize();
        ReverseFromLedgerPrivacyBlocked(GenJournalLine."Document Type"::Reminder, Vendor.Blocked::All, -LibraryRandom.RandDec(100, 2));
    end;

    local procedure ReverseFromLedgerPrivacyBlocked(DocumentType: Enum "Gen. Journal Document Type"; BlockedType: Enum "Vendor Blocked"; Amount: Decimal)
    var
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        ReversalEntry: Record "Reversal Entry";
    begin
        // Setup: Create Vendor, Make document line and Post from General Journal and Block the same Vendor.
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, DocumentType, ReversalSetup(DocumentType, BlockedType, Amount));
        Vendor.Get(VendorLedgerEntry."Vendor No.");
        Vendor.Validate("Privacy Blocked", true);
        Vendor.Modify();

        // Exercise: Reverse Invoice entries for Blocked Vendor.
        ReversalEntry.SetHideDialog(true);
        asserterror ReversalEntry.ReverseTransaction(VendorLedgerEntry."Transaction No.");

        // Verify: Verifying Blocked Error Message.
        Assert.ExpectedError(StrSubstNo(ReversalFromLedgerPrivacyBlockedErr, Vendor."No."));
    end;

    local procedure ReverseFromLedger(DocumentType: Enum "Gen. Journal Document Type"; BlockedType: Enum "Vendor Blocked"; Amount: Decimal)
    var
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        ReversalEntry: Record "Reversal Entry";
    begin
        // Setup: Create Vendor, Make document line and Post from General Journal and Block the same Vendor.
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, DocumentType, ReversalSetup(DocumentType, BlockedType, Amount));
        Vendor.Get(VendorLedgerEntry."Vendor No.");

        // Exercise: Reverse Invoice entries for Blocked Vendor.
        ReversalEntry.SetHideDialog(true);
        asserterror ReversalEntry.ReverseTransaction(VendorLedgerEntry."Transaction No.");

        // Verify: Verifying Blocked Error Message.
        Assert.ExpectedError(StrSubstNo(ReversalFromLedgerErr, Vendor."No.", Vendor.Blocked));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ReverseFromRegister()
    var
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GLRegister: Record "G/L Register";
        ReversalEntry: Record "Reversal Entry";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Setup: Create Vendor, Make Invoice and Post from General Journal and Block the same Vendor.
        Initialize();
        LibraryERM.FindVendorLedgerEntry(
          VendorLedgerEntry, GenJournalLine."Document Type"::Payment, ReversalSetup(GenJournalLine."Document Type"::Payment,
            Vendor.Blocked::Payment, LibraryRandom.RandDec(100, 2)));
        Vendor.Get(VendorLedgerEntry."Vendor No.");

        // Exercise: Reverse Payment entries for Blocked Vendor.
        GLRegister.FindLast();
        ReversalEntry.SetHideDialog(true);
        asserterror ReversalEntry.ReverseRegister(GLRegister."No.");

        // Verify: Verifying Blocked Error Message.
        Assert.ExpectedError(StrSubstNo(ReversalFromLedgerErr, Vendor."No.", Vendor.Blocked));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure FullyAppliedInvoiceFrmLedger()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        ReversalEntry: Record "Reversal Entry";
    begin
        // Create Vendor and Post Invoice from General Journal Line, Fully apply payment on Invoice and
        // verify Reversal Error from Vendor Ledger.

        // Setup: Create Vendor, Make Invoice and Post from General Journal and Block the same Vendor.
        Initialize();
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, CreateAndPostApplnEntry());

        // Exercise: Reverse Fully Applied Invoice from Ledger.
        ReversalEntry.SetHideDialog(true);
        asserterror ReversalEntry.ReverseTransaction(VendorLedgerEntry."Transaction No.");

        // Verify: Verify Reversal Error for Fully Applied Entries.
        Assert.ExpectedError(ReversalEntry.ReversalErrorForChangedEntry(VendorLedgerEntry.TableCaption(), VendorLedgerEntry."Entry No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FullyAppliedInvoiceFrmRegister()
    var
        GLRegister: Record "G/L Register";
        ReversalEntry: Record "Reversal Entry";
    begin
        // Create Vendor and Post Invoice from General Journal Line, Fully apply payment on Invoice and
        // verify Reversal Error from GL Register.

        // Setup: Create Vendor, Make Invoice and Post from General Journal and Block the same Vendor.
        Initialize();
        CreateAndPostApplnEntry();

        // Exercise: Reverse Fully Applied Invoice from Ledger.
        GLRegister.FindLast();
        ReversalEntry.SetHideDialog(true);
        asserterror ReversalEntry.ReverseRegister(GLRegister."No.");

        // Verify: Verify Reversal Error for Fully Applied Entries.
        Assert.ExpectedError(StrSubstNo(ReversalFromRegisterErr, GLRegister."No."));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CurrencyAdjustEntryFrmLedger()
    var
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        ReversalEntry: Record "Reversal Entry";
    begin
        // Create Vendor and Post Credit entry using Currency from General Journal Line, Update Exchange Rate and Run Adjust
        // Exchange Rate batch job. Verify Reversal Error from Vendor Ledger.

        // Setup: Create and Post General Journal Line and Modify Exchange Rate.Run Adjust Exchange Rate Batch Job
        // and calculate Realized Gain/Loss Amount.
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        CreateGenJnlLine(GenJournalLine, GenJournalLine."Document Type"::" ", Vendor."No.", -LibraryRandom.RandDec(100, 2));
        GenJournalLine.Validate("Currency Code", CreateCurrency());
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        UpdateExchangeRate(GenJournalLine."Currency Code");
        LibraryERM.RunExchRateAdjustment(
          GenJournalLine."Currency Code", 0D, WorkDate(), 'Test', WorkDate(), GenJournalLine."Document No.", false);

        // Exercise: Reverse Posted Entry from Vendor Ledger.
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::" ", GenJournalLine."Document No.");
        ReversalEntry.SetHideDialog(true);
        asserterror ReversalEntry.ReverseTransaction(VendorLedgerEntry."Transaction No.");

        // Verify: Verify Detailed Ledger Entry for Unrealized Loss/Gain entry.
        Assert.ExpectedError(ReversalEntry.ReversalErrorForChangedEntry(VendorLedgerEntry.TableCaption(), VendorLedgerEntry."Entry No."));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure DateCompressForGLAccount()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
    begin
        // Setup: Create General Ledger Account and Vendor, Make Invoice and Post from General Journal and Close Fiscal Year.
        Initialize();
        LibraryFiscalYear.CreateClosedAccountingPeriods();
        LibraryPurchase.CreateVendor(Vendor);
        CreateGenJnlLineForInvoice(
          GenJournalLine, GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), Vendor."No.");
        CreateAndPostApplnDateCompress(
          GenJournalLine."Document No.", GenJournalLine."Bal. Account Type"::"G/L Account", GenJournalLine."Bal. Account No.",
          GenJournalLine."Account No.", GenJournalLine.Amount);

        // Date Compress Vendor Ledger Batch Report as per the option selected and Reverse and Verify the Transaction.
        DateCompressAndReverse(GenJournalLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure DateCompressForBankAccount()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
    begin
        // Setup: Create Vendor, Make Invoice and Post from General Journal and Close Fiscal Year.
        Initialize();
        LibraryFiscalYear.CreateClosedAccountingPeriods();
        LibraryPurchase.CreateVendor(Vendor);
        CreateGenJnlLineForInvoice(
          GenJournalLine, GenJournalLine."Bal. Account Type"::"Bank Account", CreateBankAccount(), Vendor."No.");
        CreateAndPostApplnDateCompress(
          GenJournalLine."Document No.", GenJournalLine."Bal. Account Type"::"Bank Account", GenJournalLine."Bal. Account No.",
          GenJournalLine."Account No.", GenJournalLine.Amount);

        // Date Compress Vendor Ledger Batch Report as per the option selected and Reverse and Verify the Transaction.
        DateCompressAndReverse(GenJournalLine);
    end;

    [Normal]
    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateLocalData();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        IsInitialized := true;
        Commit();

        LibrarySetupStorage.SaveGeneralLedgerSetup();
    end;

    local procedure CreateAndPostApplnEntry() DocumentNo: Code[20]
    var
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Create and Post Invoice and apply Payment on Invoice.
        LibraryPurchase.CreateVendor(Vendor);
        CreateGenJnlLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, Vendor."No.", -LibraryRandom.RandDec(100, 2));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        DocumentNo := GenJournalLine."Document No.";
        CreateGenJnlLine(
          GenJournalLine, GenJournalLine."Document Type"::Payment, Vendor."No.", -GenJournalLine.Amount);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", DocumentNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndPostApplnDateCompress(DocumentNo: Code[20]; BalAccountType: Enum "Gen. Journal Account Type"; BalAccountNo: Code[20]; AccountNo: Code[20]; Amount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateGenJnlLineForBalAccount(
          GenJournalLine, GenJournalLine."Document Type"::Payment, BalAccountType, BalAccountNo, AccountNo, -Amount);
        GenJournalLine.Validate("Posting Date", LibraryFiscalYear.GetFirstPostingDate(true));
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", DocumentNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateBankAccount(): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        exit(BankAccount."No.");
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.SetCurrencyGainLossAccounts(Currency);
        Currency.Validate("Realized G/L Gains Account", Currency."Realized Gains Acc.");
        Currency.Validate("Realized G/L Losses Account", Currency."Realized Losses Acc.");
        Currency.Modify(true);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; VendorNo: Code[20]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // Select Journal Batch Name and Template Name.
        SelectGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
          GenJournalLine."Account Type"::Vendor, VendorNo, Amount);
    end;

    local procedure CreateGenJnlLineForBalAccount(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; BalAccountType: Enum "Gen. Journal Account Type"; BalAccountNo: Code[20]; AccountNo: Code[20]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        SelectGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType, GenJournalLine."Account Type"::Vendor,
          AccountNo, Amount);
        GenJournalLine.Validate("Bal. Account Type", BalAccountType);
        GenJournalLine.Validate("Bal. Account No.", BalAccountNo);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateGenJnlLineForInvoice(var GenJournalLine: Record "Gen. Journal Line"; BalAccountType: Enum "Gen. Journal Account Type"; BalAccountNo: Code[20]; AccountNo: Code[20])
    begin
        CreateGenJnlLineForBalAccount(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, BalAccountType, BalAccountNo, AccountNo,
          -LibraryRandom.RandInt(100));
        GenJournalLine.Validate("Posting Date", LibraryFiscalYear.GetFirstPostingDate(true));
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure DateCompressAndReverse(GenJournalLine: Record "Gen. Journal Line")
    begin
        // Exercise: Run the Date Compress Vendor Ledger Batch Report as per the option selected.
        VendorDateCompress(GenJournalLine."Account No.");
        ReverseEntryBalancingAccount(GenJournalLine."Bal. Account No.");

        // Verify: Verify Balancing Account in General Ledger Entry.
        Assert.ExpectedError(ReversalFromGLEntryErr);
    end;

    local procedure ReversalSetup(DocumentType: Enum "Gen. Journal Document Type"; BlockedType: Enum "Vendor Blocked"; Amount: Decimal): Code[20]
    var
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Create Vendor, make Entries from General Journal Line and Update Vendor Blocked field.
        LibraryPurchase.CreateVendor(Vendor);
        CreateGenJnlLine(GenJournalLine, DocumentType, Vendor."No.", Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        Vendor.Validate(Blocked, BlockedType);
        Vendor.Modify(true);
        exit(GenJournalLine."Document No.")
    end;

    local procedure ReverseEntryBalancingAccount(BalAccountNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
        ReversalEntry: Record "Reversal Entry";
    begin
        GLEntry.SetRange("Bal. Account No.", BalAccountNo);
        GLEntry.FindLast();
        ReversalEntry.SetHideDialog(true);
        asserterror ReversalEntry.ReverseTransaction(GLEntry."Transaction No.");
    end;

    local procedure SelectGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
    end;

    local procedure UpdateExchangeRate(CurrencyCode: Code[10])
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        // Using Random value to update Currency Exchange Rate.
        CurrencyExchangeRate.SetRange("Currency Code", CurrencyCode);
        CurrencyExchangeRate.FindFirst();
        CurrencyExchangeRate.Validate(
          "Relational Exch. Rate Amount", CurrencyExchangeRate."Relational Exch. Rate Amount" + LibraryRandom.RandInt(50));
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", CurrencyExchangeRate."Relational Exch. Rate Amount");
        CurrencyExchangeRate.Modify(true);
    end;

    local procedure VendorDateCompress(VendorNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DateComprRegister: Record "Date Compr. Register";
        DateComprRetainFields: Record "Date Compr. Retain Fields";
        DateCompressVendorLedger: Report "Date Compress Vendor Ledger";
    begin
        // Run the Date Compress Vendor Ledger Report. Take End Date a Day before Last Posted Entry's Posting Date.
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.FindFirst();
        DateCompressVendorLedger.SetTableView(VendorLedgerEntry);
        DateComprRetainFields."Retain Document No." := false;
        DateComprRetainFields."Retain Buy-from Vendor No." := false;
        DateComprRetainFields."Retain Purchaser Code" := false;
        DateComprRetainFields."Retain Journal Template Name" := false;
        DateCompressVendorLedger.InitializeRequest(
          LibraryFiscalYear.GetFirstPostingDate(true), LibraryFiscalYear.GetFirstPostingDate(true),
          DateComprRegister."Period Length"::Week, '', DateComprRetainFields, '', false);
        DateCompressVendorLedger.UseRequestPage(false);
        DateCompressVendorLedger.Run();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        // Handler for confirmation messages, always send positive reply.
        Reply := true;
    end;
}

