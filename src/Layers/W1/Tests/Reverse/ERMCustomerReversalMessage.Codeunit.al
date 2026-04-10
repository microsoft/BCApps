codeunit 134127 "ERM Customer Reversal Message"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Reverse] [Sales]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        IsInitialized: Boolean;
        ReversalFromLedgerErr: Label 'You cannot create this type of document when Customer %1 is blocked with type %2';
        ReversalFromRegisterErr: Label 'You cannot reverse register number %1 because it contains customer or vendor or employee ledger entries';
        ReversalFromGLEntryErr: Label 'The transaction cannot be reversed, because the Cust. Ledger Entry has been compressed.';
        ReversalFromLedgerPrivacyBlockedErr: Label 'You cannot create this type of document when Customer %1 is blocked for privacy.';

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure InvoiceBlockedTypeInvoice()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Create Customer and Post Invoice with Random Amount from General Journal Line, update Customer Blocked field for Invoice and
        // verify Reversal Error from Customer Ledger.
        Initialize();
        ReverseFromLedger(GenJournalLine."Document Type"::Invoice, Customer.Blocked::Invoice, LibraryRandom.RandDec(100, 2));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure InvoiceBlockedTypeAll()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Create Customer and Post Invoice with Random Amount from General Journal Line, update Customer Blocked field for All and
        // verify Reversal Error from Customer Ledger.
        Initialize();
        ReverseFromLedger(GenJournalLine."Document Type"::Invoice, Customer.Blocked::All, LibraryRandom.RandDec(100, 2));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PaymentBlockedTypeAll()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Create Customer and Post Payment with Random Amount from General Journal Line, update Customer Blocked field for All and
        // verify Reversal Error from Customer Ledger.
        Initialize();
        ReverseFromLedger(GenJournalLine."Document Type"::Payment, Customer.Blocked::All, -LibraryRandom.RandDec(100, 2));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoBlockedTypeAll()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Create Customer and Post Credit Memo with Random Amount from General Journal Line, update Customer Blocked field for All and
        // verify Reversal Error from Customer Ledger.
        Initialize();
        ReverseFromLedger(GenJournalLine."Document Type"::"Credit Memo", Customer.Blocked::All, -LibraryRandom.RandDec(100, 2));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure RefundBlockedTypeAll()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Create Customer and Post Refund with Random Amount from General Journal Line, update Customer Blocked field for All and
        // verify Reversal Error from Customer Ledger.
        Initialize();
        ReverseFromLedger(GenJournalLine."Document Type"::Refund, Customer.Blocked::All, LibraryRandom.RandDec(100, 2));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure FinChargeMemoBlockedTypeAll()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Create Customer and Post Finance Charge Memo with Random Amount from General Journal Line, update Customer Blocked field
        // for All and verify Reversal Error from Customer Ledger.
        Initialize();
        ReverseFromLedger(
          GenJournalLine."Document Type"::"Finance Charge Memo", Customer.Blocked::All, LibraryRandom.RandDec(100, 2));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ReminderBlockedTypeAll()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Create Customer and Post Reminder with Random Amount from General Journal Line, update Customer Blocked field for All and
        // verify Reversal Error from Customer Ledger.
        Initialize();
        ReverseFromLedger(GenJournalLine."Document Type"::Reminder, Customer.Blocked::All, LibraryRandom.RandDec(100, 2));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure InvoicePrivacyBlocked()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Create Customer and Post Invoice with Random Amount from General Journal Line, update Customer Blocked field for Privacy and
        // verify Reversal Error from Customer Ledger.
        Initialize();
        ReverseFromLedgerPrivacyBlocked(GenJournalLine."Document Type"::Invoice, Customer.Blocked::All, LibraryRandom.RandDec(100, 2));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PaymentPrivacyBlocked()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Create Customer and Post Payment with Random Amount from General Journal Line, update Customer Blocked field for Privacy and
        // verify Reversal Error from Customer Ledger.
        Initialize();
        ReverseFromLedgerPrivacyBlocked(GenJournalLine."Document Type"::Payment, Customer.Blocked::All, -LibraryRandom.RandDec(100, 2));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoPrivacyBlocked()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Create Customer and Post Credit Memo with Random Amount from General Journal Line, update Customer Blocked field for Privacy and
        // verify Reversal Error from Customer Ledger.
        Initialize();
        ReverseFromLedgerPrivacyBlocked(
          GenJournalLine."Document Type"::"Credit Memo", Customer.Blocked::All, -LibraryRandom.RandDec(100, 2));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure RefundPrivacyBlocked()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Create Customer and Post Refund with Random Amount from General Journal Line, update Customer Blocked field for Privacy and
        // verify Reversal Error from Customer Ledger.
        Initialize();
        ReverseFromLedgerPrivacyBlocked(GenJournalLine."Document Type"::Refund, Customer.Blocked::All, LibraryRandom.RandDec(100, 2));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure FinChargeMemoPrivacyBlocked()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Create Customer and Post Finance Charge Memo with Random Amount from General Journal Line, update Customer Blocked field
        // for Privacy and verify Reversal Error from Customer Ledger.
        Initialize();
        ReverseFromLedgerPrivacyBlocked(
          GenJournalLine."Document Type"::"Finance Charge Memo", Customer.Blocked::All, LibraryRandom.RandDec(100, 2));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ReminderPrivacyBlocked()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Create Customer and Post Reminder with Random Amount from General Journal Line, update Customer Blocked field for Privacy and
        // verify Reversal Error from Customer Ledger.
        Initialize();
        ReverseFromLedgerPrivacyBlocked(GenJournalLine."Document Type"::Reminder, Customer.Blocked::All, LibraryRandom.RandDec(100, 2));
    end;

    local procedure ReverseFromLedgerPrivacyBlocked(DocumentType: Enum "Gen. Journal Document Type"; BlockedType: Enum "Customer Blocked"; Amount: Decimal)
    var
        Customer: Record Customer;
        ReversalEntry: Record "Reversal Entry";
        TransactionNo: Integer;
    begin
        // Setup: Create Customer, Make document line and Post from General Journal and set "Privacy Blocked" := TRUE;
        TransactionNo := CommonReversalSetup(Customer, DocumentType, BlockedType, Amount);
        Customer.Validate("Privacy Blocked", true);
        Customer.Modify();

        // Exercise: Reverse Invoice entries for Blocked Customer.
        ReversalEntry.SetHideDialog(true);
        asserterror ReversalEntry.ReverseTransaction(TransactionNo);

        // Verify: Verifying Blocked Error Message.
        Assert.ExpectedError(StrSubstNo(ReversalFromLedgerPrivacyBlockedErr, Customer."No."));
    end;

    local procedure ReverseFromLedger(DocumentType: Enum "Gen. Journal Document Type"; BlockedType: Enum "Customer Blocked"; Amount: Decimal)
    var
        Customer: Record Customer;
        ReversalEntry: Record "Reversal Entry";
        TransactionNo: Integer;
    begin
        // Setup: Create Customer, Make document line and Post from General Journal and Block the same Customer.
        TransactionNo := CommonReversalSetup(Customer, DocumentType, BlockedType, Amount);

        // Exercise: Reverse Invoice entries for Blocked Customer.
        ReversalEntry.SetHideDialog(true);
        asserterror ReversalEntry.ReverseTransaction(TransactionNo);

        // Verify: Verifying Blocked Error Message.
        Assert.ExpectedError(StrSubstNo(ReversalFromLedgerErr, Customer."No.", Customer.Blocked));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ReverseFromRegister()
    var
        Customer: Record Customer;
        GLRegister: Record "G/L Register";
        GenJournalLine: Record "Gen. Journal Line";
        ReversalEntry: Record "Reversal Entry";
    begin
        // Create Customer and Post Invoice with Random Amount from General Journal Line, update Customer Blocked field for Invoice and
        // verify Reversal Error from GL Register.

        // Setup.
        Initialize();
        CommonReversalSetup(
          Customer, GenJournalLine."Document Type"::Invoice, Customer.Blocked::Invoice, LibraryRandom.RandDec(100, 2));

        // Exercise: Reverse Invoice entries for Blocked Customer.
        GLRegister.FindLast();
        ReversalEntry.SetHideDialog(true);
        asserterror ReversalEntry.ReverseRegister(GLRegister."No.");

        // Verify: Verifying Blocked Error Message.
        Assert.ExpectedError(StrSubstNo(ReversalFromLedgerErr, Customer."No.", Customer.Blocked));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure FullyAppliedInvoiceFrmLedger()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        ReversalEntry: Record "Reversal Entry";
    begin
        // Create Customer and Post Invoice from General Journal Line, Fully apply payment on Invoice and
        // verify Reversal Error from Customer Ledger.

        // Setup.
        Initialize();
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, CreateAndPostApplicationEntry());

        // Exercise: Reverse Fully Applied Invoice from Ledger.
        ReversalEntry.SetHideDialog(true);
        asserterror ReversalEntry.ReverseTransaction(CustLedgerEntry."Transaction No.");

        // Verify: Verify Reversal Error for Fully Applied Entries.
        Assert.ExpectedError(ReversalEntry.ReversalErrorForChangedEntry(CustLedgerEntry.TableCaption(), CustLedgerEntry."Entry No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FullyAppliedInvoiceFrmRegister()
    var
        GLRegister: Record "G/L Register";
        ReversalEntry: Record "Reversal Entry";
    begin
        // Create Customer and Post Invoice from General Journal Line, Fully apply payment on Invoice and
        // verify Reversal Error from GL Register.

        // Setup: Create Customer, Make Invoice and Post from General Journal and Block the same Customer.
        Initialize();
        CreateAndPostApplicationEntry();

        // Exercise: Reverse Fully Applied Invoice from Regiser.
        GLRegister.FindLast();
        ReversalEntry.SetHideDialog(true);
        asserterror ReversalEntry.ReverseRegister(GLRegister."No.");

        // Verify: Verify Reversal Error for Fully Applied Entries. Because of Error length too long verifying selected string in Error
        // message.
        Assert.ExpectedError(StrSubstNo(ReversalFromRegisterErr, GLRegister."No."));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CurrencyAdjustEntryFrmLedger()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        ReversalEntry: Record "Reversal Entry";
    begin
        // Create Customer and Post Credit entry using Currency from General Journal Line, Update Exchange Rate and Run Adjust
        // Exchange Rate batch job. Verify Reversal Error from Customer Ledger.

        // Setup: Create and Post General Journal Line with Random Amount and Modify Exchange Rate. Run Adjust Exchange Rate Batch Job
        // and calculate Realized Gain/Loss Amount.
        CreateGeneralJounalLine(GenJournalLine, GenJournalLine."Document Type"::" ", CreateCustomer(), -LibraryRandom.RandDec(100, 2));
        GenJournalLine.Validate("Currency Code", CreateCurrency());
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        UpdateExchangeRate(GenJournalLine."Currency Code");
        LibraryERM.RunExchRateAdjustment(
          GenJournalLine."Currency Code", 0D, WorkDate(), 'Test', WorkDate(), GenJournalLine."Document No.", false);

        // Exercise: Reverse Posted Entry from Customer Legder.
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::" ", GenJournalLine."Document No.");
        ReversalEntry.SetHideDialog(true);
        asserterror ReversalEntry.ReverseTransaction(CustLedgerEntry."Transaction No.");

        // Verify: Verify Detailed Ledger Entry for Unrealized Loss/Gain entry.
        Assert.ExpectedError(ReversalEntry.ReversalErrorForChangedEntry(CustLedgerEntry.TableCaption(), CustLedgerEntry."Entry No."));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure DateCompressForGLAccount()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Setup: Create General Ledger Account and Customer, Make Invoice and Post from General Journal and Close Fiscal Year.
        Initialize();
        LibraryFiscalYear.CreateClosedAccountingPeriods();
        CreateGenJnlLineForInvoice(
          GenJournalLine, GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), CreateCustomer());
        CreateAndPostApplnDateCompress(
          GenJournalLine."Document No.", GenJournalLine."Bal. Account Type"::"G/L Account", GenJournalLine."Bal. Account No.",
          GenJournalLine."Account No.", GenJournalLine.Amount);

        // Run Date Compress Batch job and Verify Reversal Error.
        DateCompressAndReverse(GenJournalLine."Account No.", GenJournalLine."Bal. Account No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure DateCompressForBankAccount()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Setup: Create Customer, Make Invoice and Post from General Journal and Close Fiscal Year.
        Initialize();
        LibraryFiscalYear.CreateClosedAccountingPeriods();
        CreateGenJnlLineForInvoice(
          GenJournalLine, GenJournalLine."Bal. Account Type"::"Bank Account", CreateBankAccount(), CreateCustomer());
        CreateAndPostApplnDateCompress(
          GenJournalLine."Document No.", GenJournalLine."Bal. Account Type"::"Bank Account", GenJournalLine."Bal. Account No.",
          GenJournalLine."Account No.", GenJournalLine.Amount);

        // Run Date Compress Batch job and Verify Reversal Error.
        DateCompressAndReverse(GenJournalLine."Account No.", GenJournalLine."Bal. Account No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckUnapplyWhenCustomerBlockedWithInvoice()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        ApplyUnapplyParameters: Record "Apply Unapply Parameters";
        CustEntryApplyPostedEntries: Codeunit "CustEntry-Apply Posted Entries";
        DocumentNo: Code[20];
        CustomerNo: Code[20];
    begin
        // Verify that Unapply work when customer is blocked with option Invoice.

        // Setup: Create and Post Invoice and apply Payment on Invoice.
        Initialize();
        DocumentNo := CreateAndPostApplicationEntry();
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, DocumentNo);
        CustomerNo := ModifyCustomerWithBlockStatus(CustLedgerEntry."Customer No.");
        FindDetailedCustLedgEntry(DetailedCustLedgEntry, CustomerNo);

        // Exercise: Unapplying Entries.
        ApplyUnapplyParameters."Document No." := DetailedCustLedgEntry."Document No.";
        ApplyUnapplyParameters."Posting Date" := WorkDate();
        CustEntryApplyPostedEntries.PostUnApplyCustomer(DetailedCustLedgEntry, ApplyUnapplyParameters);

        // Verify: Verifying that remaining amount again have some values.
        VerifyCustLedgerEntry(CustLedgerEntry."Entry No.", CustLedgerEntry.Amount);
    end;

    [Normal]
    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Customer Reversal Message");
        LibrarySetupStorage.Restore();
        // Lazy Setup.
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Customer Reversal Message");

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateLocalData();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        IsInitialized := true;
        Commit();
        LibrarySetupStorage.SaveGeneralLedgerSetup();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Customer Reversal Message");
    end;

    local procedure ReversalSetup(DocumentType: Enum "Gen. Journal Document Type"; BlockedType: Enum "Customer Blocked"; Amount: Decimal): Code[20]
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Create Customer, make Entries from General Journal Line and Update Customer Blocked field.
        LibrarySales.CreateCustomer(Customer);
        CreateGeneralJounalLine(GenJournalLine, DocumentType, Customer."No.", Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        Customer.Validate(Blocked, BlockedType);
        Customer.Modify(true);
        exit(GenJournalLine."Document No.")
    end;

    local procedure CommonReversalSetup(var Customer: Record Customer; DocumentType: Enum "Gen. Journal Document Type"; BlockedType: Enum "Customer Blocked"; Amount: Decimal): Integer
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocumentType, ReversalSetup(DocumentType, BlockedType, Amount));
        Customer.Get(CustLedgerEntry."Customer No.");
        exit(CustLedgerEntry."Transaction No.");
    end;

    local procedure CreateAndPostApplicationEntry() DocumentNo: Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Create and Post Invoice and apply Payment on Invoice.
        CreateGeneralJounalLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, CreateCustomer(), LibraryRandom.RandDec(100, 2));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        DocumentNo := GenJournalLine."Document No.";
        CreateGeneralJounalLine(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account No.", -GenJournalLine.Amount);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", DocumentNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
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

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        exit(Customer."No.");
    end;

    local procedure DateCompressAndReverse(AccountNo: Code[20]; BalAccountNo: Code[20])
    begin
        // Exercise: Run the Date Compress Customer Ledger Batch Report as per the option selected and Reverse the transaction.
        CustomerDateCompress(AccountNo);
        ReverseEntryBalancingAccount(BalAccountNo);

        // Verify: Verify Balancing Account in General Ledger Entry.
        Assert.ExpectedError(ReversalFromGLEntryErr);
    end;

    local procedure FindDetailedCustLedgEntry(var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; CustomerNo: Code[20])
    begin
        DetailedCustLedgEntry.SetRange("Entry Type", DetailedCustLedgEntry."Entry Type"::Application);
        DetailedCustLedgEntry.SetRange("Customer No.", CustomerNo);
        DetailedCustLedgEntry.FindFirst();
    end;

    local procedure ModifyCustomerWithBlockStatus(CustomerNo: Code[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustomerNo);
        Customer.Validate(Blocked, Customer.Blocked::Invoice);
        Customer.Modify(true);
        exit(Customer."No.")
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

    local procedure CreateGeneralJounalLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; CustomerNo: Code[20]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // Select Journal Batch Name and Template Name.
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
          GenJournalLine."Account Type"::Customer, CustomerNo, Amount);
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

    local procedure CreateGenJnlLineForBalAccount(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; BalAccountType: Enum "Gen. Journal Account Type"; BalAccountNo: Code[20]; AccountNo: Code[20]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
          GenJournalLine."Account Type"::Customer, AccountNo, Amount);
        GenJournalLine.Validate("Bal. Account Type", BalAccountType);
        GenJournalLine.Validate("Bal. Account No.", BalAccountNo);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateGenJnlLineForInvoice(var GenJournalLine: Record "Gen. Journal Line"; BalAccountType: Enum "Gen. Journal Account Type"; BalAccountNo: Code[20]; AccountNo: Code[20])
    begin
        CreateGenJnlLineForBalAccount(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, BalAccountType, BalAccountNo, AccountNo,
          LibraryRandom.RandInt(100));
        GenJournalLine.Validate("Posting Date", LibraryFiscalYear.GetFirstPostingDate(true));
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
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

    local procedure CustomerDateCompress(CustomerNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DateComprRegister: Record "Date Compr. Register";
        DateComprRetainFields: Record "Date Compr. Retain Fields";
        DateCompressCustomerLedger: Report "Date Compress Customer Ledger";
    begin
        // Run the Date Compress Customer Ledger Report. Take End Date a Day before Last Posted Entry's Posting Date.
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.FindFirst();
        DateCompressCustomerLedger.SetTableView(CustLedgerEntry);
        DateComprRetainFields."Retain Document No." := false;
        DateComprRetainFields."Retain Sell-to Customer No." := false;
        DateComprRetainFields."Retain Salesperson Code" := false;
        DateComprRetainFields."Retain Journal Template Name" := false;
        DateCompressCustomerLedger.InitializeRequest(
          LibraryFiscalYear.GetFirstPostingDate(true), LibraryFiscalYear.GetFirstPostingDate(true),
          DateComprRegister."Period Length"::Week, '', DateComprRetainFields, '', false);
        DateCompressCustomerLedger.UseRequestPage(false);
        DateCompressCustomerLedger.Run();
    end;

    local procedure VerifyCustLedgerEntry(CustLedgerEntryNo: Integer; RemainingAmount: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.Get(CustLedgerEntryNo);
        CustLedgerEntry.TestField(Open, true);
        CustLedgerEntry.TestField("Remaining Amount", RemainingAmount);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        // Handler for confirmation messages, always send positive reply.
        Reply := true;
    end;
}

