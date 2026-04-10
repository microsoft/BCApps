codeunit 134251 "Match General Jnl Lines Test"
{
    Permissions = TableData "Cust. Ledger Entry" = imd,
                  TableData "Vendor Ledger Entry" = imd;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [General Journal] [Match]
    end;

    var
        LibraryRandom: Codeunit "Library - Random";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;
        MatchSummaryMsg: Label '%1 payment lines out of %2 are matched.\\';
        MissingMatchMsg: Label 'Text shorter than 4 characters cannot be matched.';

    local procedure MatchWithCustInvoice(CurrencyCode: Code[10])
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Amount: Decimal;
    begin
        Initialize();

        // Setup.
        Amount := LibraryRandom.RandDec(100, 2);
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Currency Code", CurrencyCode);
        Customer.Modify(true);
        SetupGeneralJournal(GenJournalLine, GenJournalLine."Account Type"::Customer, Customer."No.", Amount);
        FindCustLedgerEntry(CustLedgerEntry, Customer."No.");

        // Exercise.
        GenJournalLine.MatchSingleLedgerEntry();

        // Verify.
        VerifyGenJnlLine(GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Document No.",
          GenJournalLine."Account Type"::Customer, Customer."No.", true);
        VerifyCustLedgerEntry(CustLedgerEntry, true, GenJournalLine."Document No.", Amount);
        Assert.AreEqual(CustLedgerEntry."Payment Reference", GenJournalLine."Payment Reference", '');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MatchWithCustInvoiceNoCurrency()
    begin
        MatchWithCustInvoice('');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MatchWithCustInvoiceAddnlCurrency()
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateExchRate(CurrencyExchangeRate, Currency.Code, 0D);
        CurrencyExchangeRate.Validate("Exchange Rate Amount", LibraryRandom.RandDec(100, 2));
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", LibraryRandom.RandDec(100, 2));
        CurrencyExchangeRate.Modify(true);

        MatchWithCustInvoice(Currency.Code);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MatchWithCustInvoiceAndPost()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        Amount: Decimal;
    begin
        Initialize();

        // Setup.
        Amount := LibraryRandom.RandDec(100, 2);
        LibrarySales.CreateCustomer(Customer);
        SetupGeneralJournal(GenJournalLine, GenJournalLine."Account Type"::Customer, Customer."No.", Amount);
        FindCustLedgerEntry(CustLedgerEntry, Customer."No.");

        // Exercise.
        GenJournalLine.MatchSingleLedgerEntry();

        // Verify.
        VerifyGenJnlLine(GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Document No.",
          GenJournalLine."Account Type"::Customer, Customer."No.", true);

        // Exercise.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        FindCustLedgerEntry(CustLedgerEntry2, Customer."No.");

        // Verify.
        VerifyCustLedgerEntry(CustLedgerEntry, false, '', 0);
        CustLedgerEntry2.TestField(Open, false);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MatchWithCustCreditMemo()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GenJournalBatch: Record "Gen. Journal Batch";
        Amount: Decimal;
    begin
        Initialize();

        // Setup.
        Amount := LibraryRandom.RandDec(100, 2);
        LibrarySales.CreateCustomer(Customer);
        CreateLedgerEntry(GenJournalLine, GenJournalLine."Account Type"::Customer,
          GenJournalLine."Document Type"::"Credit Memo", Customer."No.", -Amount);

        CreateGenJnlBatchWithBalanceAccount(GenJournalBatch);
        CreateGenJnlLineForMatching(GenJournalLine2, GenJournalBatch, GenJournalLine."Document No.", -GenJournalLine.Amount);

        FindCustLedgerEntry(CustLedgerEntry, Customer."No.");

        // Exercise.
        GenJournalLine2.MatchSingleLedgerEntry();

        // Verify.
        VerifyGenJnlLine(GenJournalLine2, GenJournalLine2."Document Type"::Payment, GenJournalLine2."Document No.",
          GenJournalLine."Account Type"::Customer, Customer."No.", true);
        VerifyCustLedgerEntry(CustLedgerEntry, true, GenJournalLine2."Document No.", -Amount);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MatchWithVendorInvoice()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
    begin
        Initialize();

        // Setup.
        Amount := -LibraryRandom.RandDec(100, 2);
        LibraryPurchase.CreateVendor(Vendor);
        SetupGeneralJournal(GenJournalLine, GenJournalLine."Account Type"::Vendor, Vendor."No.", Amount);
        FindVendorLedgerEntry(VendorLedgerEntry, Vendor."No.");

        // Exercise.
        GenJournalLine.MatchSingleLedgerEntry();

        // Verify.
        VerifyGenJnlLine(GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Document No.",
          GenJournalLine."Account Type"::Vendor, Vendor."No.", true);
        VerifyVendorLedgerEntry(VendorLedgerEntry, true, GenJournalLine."Document No.", Amount);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MatchWithVendorInvoiceAndPost()
    var
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
        Amount: Decimal;
    begin
        Initialize();

        // Setup.
        Amount := -LibraryRandom.RandDec(100, 2);
        LibraryPurchase.CreateVendor(Vendor);
        SetupGeneralJournal(GenJournalLine, GenJournalLine."Account Type"::Vendor, Vendor."No.", Amount);
        FindVendorLedgerEntry(VendorLedgerEntry, Vendor."No.");

        // Exercise.
        GenJournalLine.MatchSingleLedgerEntry();

        // Verify.
        VerifyGenJnlLine(GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Document No.",
          GenJournalLine."Account Type"::Vendor, Vendor."No.", true);

        // Exercise.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        FindVendorLedgerEntry(VendorLedgerEntry2, Vendor."No.");

        // Verify.
        VerifyVendorLedgerEntry(VendorLedgerEntry, false, '', 0);
        VendorLedgerEntry2.TestField(Open, false);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MatchWithVendorCreditMemo()
    var
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GenJournalBatch: Record "Gen. Journal Batch";
        Amount: Decimal;
    begin
        Initialize();

        // Setup.
        Amount := LibraryRandom.RandDec(100, 2);
        LibraryPurchase.CreateVendor(Vendor);
        CreateLedgerEntry(GenJournalLine, GenJournalLine."Account Type"::Vendor,
          GenJournalLine."Document Type"::"Credit Memo", Vendor."No.", Amount);

        CreateGenJnlBatchWithBalanceAccount(GenJournalBatch);
        CreateGenJnlLineForMatching(GenJournalLine2, GenJournalBatch, GenJournalLine."Document No.", -GenJournalLine.Amount);

        FindVendorLedgerEntry(VendorLedgerEntry, Vendor."No.");

        // Exercise.
        GenJournalLine2.MatchSingleLedgerEntry();

        // Verify.
        VerifyGenJnlLine(GenJournalLine2, GenJournalLine2."Document Type"::Payment, GenJournalLine2."Document No.",
          GenJournalLine."Account Type"::Vendor, Vendor."No.", true);
        VerifyVendorLedgerEntry(VendorLedgerEntry, true, GenJournalLine2."Document No.", Amount);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MatchWithCustVendorInvoices()
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Amount: Decimal;
    begin
        Initialize();

        // Setup.
        Amount := LibraryRandom.RandDec(100, 2);
        LibrarySales.CreateCustomer(Customer);
        LibraryPurchase.CreateVendor(Vendor);
        CreateGenJnlBatchWithBalanceAccount(GenJournalBatch);
        CreateLedgerEntry(GenJournalLine, GenJournalLine."Account Type"::Customer, GenJournalLine."Document Type"::Invoice,
          Customer."No.", Amount);
        FindCustLedgerEntry(CustLedgerEntry, Customer."No.");
        CreateLedgerEntry(GenJournalLine, GenJournalLine."Account Type"::Vendor, GenJournalLine."Document Type"::Invoice,
          Vendor."No.", -Amount);
        FindVendorLedgerEntry(VendorLedgerEntry, Vendor."No.");
        CreateGenJnlLineForMatching(GenJournalLine2, GenJournalBatch, '', -Amount);

        // Exercise.
        GenJournalLine2.MatchSingleLedgerEntry();

        // Verify.
        VerifyGenJnlLine(GenJournalLine2, GenJournalLine2."Document Type"::Payment, GenJournalLine2."Document No.",
          GenJournalLine."Account Type"::Customer, Customer."No.", true);
        VerifyCustLedgerEntry(CustLedgerEntry, true, GenJournalLine2."Document No.", Amount);
        VerifyVendorLedgerEntry(VendorLedgerEntry, true, '', 0);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MatchWithCustVendorInvoicesCompetingCriteria()
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Amount: Decimal;
    begin
        Initialize();

        // Setup.
        Amount := LibraryRandom.RandDec(100, 2);
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate(Name, CopyStr(CreateGuid(), 1, 50));
        Customer.Modify(true);
        LibraryPurchase.CreateVendor(Vendor);
        CreateGenJnlBatchWithBalanceAccount(GenJournalBatch);
        CreateLedgerEntry(
          GenJournalLine, GenJournalLine."Account Type"::Customer, GenJournalLine."Document Type"::Invoice,
          Customer."No.", Amount + LibraryRandom.RandDec(100, 2));
        FindCustLedgerEntry(CustLedgerEntry, Customer."No.");
        CreateLedgerEntry(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, GenJournalLine."Document Type"::Invoice,
          Vendor."No.", -Amount - LibraryRandom.RandDec(100, 2));
        FindVendorLedgerEntry(VendorLedgerEntry, Vendor."No.");
        CreateGenJnlLineForMatching(GenJournalLine2, GenJournalBatch, Customer.Name + GenJournalLine."Document No.", -Amount);

        // Exercise.
        GenJournalLine2.MatchSingleLedgerEntry();

        // Verify.
        VerifyGenJnlLine(GenJournalLine2, GenJournalLine2."Document Type"::Payment, GenJournalLine2."Document No.",
          GenJournalLine."Account Type"::Customer, Customer."No.", true);
        VerifyCustLedgerEntry(CustLedgerEntry, true, GenJournalLine2."Document No.", Amount);
        VerifyVendorLedgerEntry(VendorLedgerEntry, true, '', 0);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MatchWithVendorCustInvoices()
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Amount: Decimal;
    begin
        Initialize();

        // Setup.
        Amount := LibraryRandom.RandDec(100, 2);
        LibrarySales.CreateCustomer(Customer);
        LibraryPurchase.CreateVendor(Vendor);
        CreateGenJnlBatchWithBalanceAccount(GenJournalBatch);
        CreateLedgerEntry(GenJournalLine, GenJournalLine."Account Type"::Customer, GenJournalLine."Document Type"::Invoice,
          Customer."No.", Amount);
        FindCustLedgerEntry(CustLedgerEntry, Customer."No.");
        CreateLedgerEntry(GenJournalLine, GenJournalLine."Account Type"::Vendor,
          GenJournalLine."Document Type"::Invoice, Vendor."No.", -Amount);
        CreateGenJnlLineForMatching(GenJournalLine2, GenJournalBatch, '', Amount);
        FindVendorLedgerEntry(VendorLedgerEntry, Vendor."No.");

        // Exercise.
        GenJournalLine2.MatchSingleLedgerEntry();

        // Verify.
        VerifyGenJnlLine(GenJournalLine2, GenJournalLine2."Document Type"::Payment, GenJournalLine2."Document No.",
          GenJournalLine."Account Type"::Vendor, Vendor."No.", true);
        VerifyCustLedgerEntry(CustLedgerEntry, true, '', 0);
        VerifyVendorLedgerEntry(VendorLedgerEntry, true, GenJournalLine2."Document No.", -Amount);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MatchWithConflictingInvoiceCriteria()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        GenJournalLine3: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        Amount: Decimal;
    begin
        Initialize();

        // Setup.
        Amount := LibraryRandom.RandDec(100, 2);
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate(Name, CopyStr(CreateGuid(), 1, 50));
        Customer.Modify(true);
        CreateLedgerEntry(GenJournalLine, GenJournalLine."Account Type"::Customer, GenJournalLine."Document Type"::Invoice,
          Customer."No.", Amount);
        FindCustLedgerEntry(CustLedgerEntry, Customer."No.");
        CreateLedgerEntry(GenJournalLine, GenJournalLine."Account Type"::Customer, GenJournalLine."Document Type"::Invoice,
          Customer."No.", Amount);
        FindCustLedgerEntry(CustLedgerEntry2, Customer."No.");

        CreateGenJnlBatchWithBalanceAccount(GenJournalBatch);
        CreateGenJnlLineForMatching(GenJournalLine2, GenJournalBatch, Customer.Name, -Amount);
        CreateGenJnlLineForMatching(GenJournalLine3, GenJournalBatch, GenJournalLine."Document No.", -Amount);

        // Exercise.
        GenJournalLine2.MatchSingleLedgerEntry();

        // Verify.
        VerifyGenJnlLine(GenJournalLine2, GenJournalLine2."Document Type"::Payment, GenJournalLine2."Document No.",
          GenJournalLine."Account Type"::Customer, Customer."No.", true);
        VerifyGenJnlLine(GenJournalLine3, GenJournalLine3."Document Type"::Payment, GenJournalLine3."Document No.",
          GenJournalLine."Account Type"::Customer, Customer."No.", true);
        VerifyCustLedgerEntry(CustLedgerEntry, true, GenJournalLine2."Document No.", Amount);
        VerifyCustLedgerEntry(CustLedgerEntry2, true, GenJournalLine3."Document No.", Amount);
    end;

    local procedure MatchWithPartialInvoiceApplication(InvoiceAmount: Decimal; PaidAmount: Decimal; AppliedAmount: Decimal)
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        Initialize();

        // Setup.
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate(Name, CopyStr(CreateGuid(), 1, 50));
        Customer.Modify(true);
        CreateLedgerEntry(GenJournalLine, GenJournalLine."Account Type"::Customer, GenJournalLine."Document Type"::Invoice,
          Customer."No.", InvoiceAmount);
        FindCustLedgerEntry(CustLedgerEntry, Customer."No.");

        CreateGenJnlBatchWithBalanceAccount(GenJournalBatch);
        CreateGenJnlLineForMatching(GenJournalLine2, GenJournalBatch, Customer.Name, PaidAmount);

        // Exercise.
        GenJournalLine2.MatchSingleLedgerEntry();

        // Verify.
        VerifyGenJnlLine(GenJournalLine2, GenJournalLine2."Document Type"::Payment, GenJournalLine2."Document No.",
          GenJournalLine."Account Type"::Customer, Customer."No.", true);
        VerifyCustLedgerEntry(CustLedgerEntry, true, GenJournalLine2."Document No.", AppliedAmount);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MatchInvoiceWithPartialPayment()
    var
        InvoiceAmount: Decimal;
        PaidAmount: Decimal;
    begin
        InvoiceAmount := LibraryRandom.RandDec(100, 2);
        PaidAmount := -InvoiceAmount - LibraryRandom.RandDecInDecimalRange(1, InvoiceAmount, 2);
        MatchWithPartialInvoiceApplication(InvoiceAmount, PaidAmount, InvoiceAmount);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MatchPartiallyInvoiceWithPayment()
    var
        InvoiceAmount: Decimal;
        PaidAmount: Decimal;
    begin
        InvoiceAmount := LibraryRandom.RandDec(100, 2);
        PaidAmount := -InvoiceAmount + LibraryRandom.RandDecInDecimalRange(1, InvoiceAmount, 2);
        MatchWithPartialInvoiceApplication(InvoiceAmount, PaidAmount, -PaidAmount);
    end;

    [Normal]
    local procedure MatchCustNamePartially(FirstCustomerName: Text[50]; SecondCustomerName: Text[50]; Description: Text[50])
    var
        Customer: Record Customer;
        Customer2: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Amount: Decimal;
    begin
        Initialize();

        // Setup.
        Amount := LibraryRandom.RandDec(100, 2);
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate(Name, FirstCustomerName);
        Customer.Modify(true);
        CreateLedgerEntry(GenJournalLine, GenJournalLine."Account Type"::Customer, GenJournalLine."Document Type"::Invoice,
          Customer."No.", Amount + LibraryRandom.RandDec(100, 2));
        FindCustLedgerEntry(CustLedgerEntry, Customer."No.");

        LibrarySales.CreateCustomer(Customer2);
        Customer2.Validate(Name, SecondCustomerName);
        Customer2.Modify(true);
        CreateLedgerEntry(GenJournalLine, GenJournalLine."Account Type"::Customer, GenJournalLine."Document Type"::Invoice,
          Customer2."No.", Amount + LibraryRandom.RandDec(100, 2));

        CreateGenJnlBatchWithBalanceAccount(GenJournalBatch);
        CreateGenJnlLineForMatching(GenJournalLine2, GenJournalBatch, Description, -Amount);

        // Exercise.
        GenJournalLine2.MatchSingleLedgerEntry();

        // Verify.
        VerifyGenJnlLine(GenJournalLine2, GenJournalLine2."Document Type"::Payment, GenJournalLine2."Document No.",
          GenJournalLine."Account Type"::Customer, Customer."No.", true);
        VerifyCustLedgerEntry(CustLedgerEntry, true, GenJournalLine2."Document No.", Amount);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MatchPartiallyTwoCustNames()
    var
        Name: Text[50];
    begin
        Name := CreateGuid();
        MatchCustNamePartially(CopyStr(Name, 1, 8), PadStr(CopyStr(Name, 1, 4), 8, '-'), Name);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MatchPartiallyOneCustName()
    var
        Name: Text[50];
    begin
        Name := CreateGuid();
        MatchCustNamePartially(CopyStr(Name, 1, 8), '', Name);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure DoNotMatchWithCustInvoice()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Amount: Decimal;
    begin
        Initialize();

        // Setup.
        Amount := LibraryRandom.RandDec(100, 2);
        LibrarySales.CreateCustomer(Customer);
        CreateLedgerEntry(GenJournalLine, GenJournalLine."Account Type"::Customer,
          GenJournalLine."Document Type"::Invoice, Customer."No.", Amount);

        CreateGenJnlBatchWithBalanceAccount(GenJournalBatch);
        CreateGenJnlLineForMatching(GenJournalLine2, GenJournalBatch, GenJournalLine."Document No.", GenJournalLine.Amount);

        FindCustLedgerEntry(CustLedgerEntry, Customer."No.");

        // Exercise.
        GenJournalLine2.MatchSingleLedgerEntry();

        // Verify.
        VerifyGenJnlLine(GenJournalLine2, GenJournalLine2."Document Type"::Payment, '', "Gen. Journal Account Type"::"G/L Account", '', false);
        VerifyCustLedgerEntry(CustLedgerEntry, true, '', 0);
    end;

    [Test]
    [HandlerFunctions('MatchSummaryMsgHandler')]
    [Scope('OnPrem')]
    procedure DoNotMatchWithVendorInvoice()
    var
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Amount: Decimal;
    begin
        Initialize();

        // Setup.
        Amount := LibraryRandom.RandDec(100, 2);
        LibraryPurchase.CreateVendor(Vendor);
        CreateLedgerEntry(GenJournalLine, GenJournalLine."Account Type"::Vendor,
          GenJournalLine."Document Type"::Invoice, Vendor."No.", -Amount);

        CreateGenJnlBatchWithBalanceAccount(GenJournalBatch);
        CreateGenJnlLineForMatching(GenJournalLine2, GenJournalBatch, GenJournalLine."Document No.", GenJournalLine.Amount);

        FindVendorLedgerEntry(VendorLedgerEntry, Vendor."No.");

        // Exercise.
        LibraryVariableStorage.Enqueue(0);
        LibraryVariableStorage.Enqueue(1);
        LibraryVariableStorage.Enqueue(MissingMatchMsg);
        GenJournalLine2.MatchSingleLedgerEntry();

        // Verify.
        VerifyGenJnlLine(GenJournalLine2, GenJournalLine2."Document Type"::Payment, '', "Gen. Journal Account Type"::"G/L Account", '', false);
        VerifyVendorLedgerEntry(VendorLedgerEntry, true, '', 0);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,TemplateListPageHandler')]
    [Scope('OnPrem')]
    procedure RemoveAccNoAfterMatching()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GenJnlLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        GeneralJournal: TestPage "General Journal";
        Amount: Decimal;
    begin
        Initialize();
        // Setup
        Amount := LibraryRandom.RandDec(100, 2);
        LibrarySales.CreateCustomer(Customer);
        SetupGeneralJournal(GenJnlLine, GenJnlLine."Account Type"::Customer, Customer."No.", Amount);
        FindCustLedgerEntry(CustLedgerEntry, Customer."No.");
        GenJnlLine.MatchSingleLedgerEntry();

        // Exercise.
        LibraryVariableStorage.Enqueue(GenJnlLine."Journal Template Name");
        GeneralJournal.OpenEdit();
        GeneralJournal.GotoRecord(GenJnlLine);
        GeneralJournal."Account No.".SetValue('');
        GeneralJournal.OK().Invoke();

        // Verify
        VerifyGenJnlLine(GenJnlLine, GenJnlLine."Document Type"::Payment,
          '', GenJnlLine."Account Type"::Customer, '', false);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MapGLAccountDebit()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TextToAccMapping: Record "Text-to-Account Mapping";
    begin
        Initialize();

        // Setup.
        SetupAccountMapping(TextToAccMapping, GenJournalLine, TextToAccMapping."Bal. Source Type"::"G/L Account", '', 1);

        // Exercise.
        GenJournalLine.MatchSingleLedgerEntry();

        // Verify.
        VerifyGenJnlLine(GenJournalLine, GenJournalLine."Document Type"::Payment, '',
          GenJournalLine."Account Type"::"G/L Account", TextToAccMapping."Debit Acc. No.", true);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MapGLAccountCredit()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TextToAccMapping: Record "Text-to-Account Mapping";
    begin
        Initialize();

        // Setup.
        SetupAccountMapping(TextToAccMapping, GenJournalLine, TextToAccMapping."Bal. Source Type"::"G/L Account", '', -1);

        // Exercise.
        GenJournalLine.MatchSingleLedgerEntry();

        // Verify.
        VerifyGenJnlLine(GenJournalLine, GenJournalLine."Document Type"::Payment, '',
          GenJournalLine."Account Type"::"G/L Account", TextToAccMapping."Credit Acc. No.", true);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MapVendorAccount()
    var
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        TextToAccMapping: Record "Text-to-Account Mapping";
    begin
        Initialize();

        // Setup.
        LibraryPurchase.CreateVendor(Vendor);
        SetupAccountMapping(TextToAccMapping, GenJournalLine, TextToAccMapping."Bal. Source Type"::Vendor, Vendor."No.", 1);

        // Exercise.
        GenJournalLine.MatchSingleLedgerEntry();

        // Verify.
        VerifyGenJnlLine(GenJournalLine, GenJournalLine."Document Type"::Payment, '',
          GenJournalLine."Account Type"::Vendor, Vendor."No.", true);
        VerifyAppliedDocLine(GenJournalLine, GenJournalLine."Document Type"::Invoice);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MapCustomerAccount()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        TextToAccMapping: Record "Text-to-Account Mapping";
    begin
        Initialize();

        // Setup.
        LibrarySales.CreateCustomer(Customer);
        SetupAccountMapping(TextToAccMapping, GenJournalLine, TextToAccMapping."Bal. Source Type"::Customer, Customer."No.", -1);

        // Exercise.
        GenJournalLine.MatchSingleLedgerEntry();

        // Verify.
        VerifyGenJnlLine(GenJournalLine, GenJournalLine."Document Type"::Payment, '',
          GenJournalLine."Account Type"::Customer, Customer."No.", true);
        VerifyAppliedDocLine(GenJournalLine, GenJournalLine."Document Type"::Invoice);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MapVendorAccountPost()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        TextToAccMapping: Record "Text-to-Account Mapping";
        DocNo: Code[20];
    begin
        Initialize();

        // Setup.
        LibraryPurchase.CreateVendor(Vendor);
        SetupAccountMapping(TextToAccMapping, GenJournalLine, TextToAccMapping."Bal. Source Type"::Vendor, Vendor."No.", 1);

        // Exercise.
        DocNo := GenJournalLine."Document No.";
        GenJournalLine.MatchSingleLedgerEntry();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify.
        FindVendorLedgerEntry(VendorLedgerEntry, Vendor."No.");
        VendorLedgerEntry.TestField("Document No.", DocNo);
        VendorLedgerEntry.TestField("Document Type", VendorLedgerEntry."Document Type"::Invoice);
        VerifyVendorLedgerEntry(VendorLedgerEntry, false, '', 0);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MapCustomerAccountPost()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        TextToAccMapping: Record "Text-to-Account Mapping";
        DocNo: Code[20];
    begin
        Initialize();

        // Setup.
        LibrarySales.CreateCustomer(Customer);
        SetupAccountMapping(TextToAccMapping, GenJournalLine, TextToAccMapping."Bal. Source Type"::Customer, Customer."No.", -1);

        // Exercise.
        DocNo := GenJournalLine."Document No.";
        GenJournalLine.MatchSingleLedgerEntry();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify.
        FindCustLedgerEntry(CustLedgerEntry, Customer."No.");
        CustLedgerEntry.TestField("Document No.", DocNo);
        CustLedgerEntry.TestField("Document Type", GenJournalLine."Document Type"::Invoice);
        VerifyCustLedgerEntry(CustLedgerEntry, false, '', 0);
    end;

    [Test]
    [HandlerFunctions('MatchSummaryMsgHandler')]
    [Scope('OnPrem')]
    procedure MatchCustomerWithMappingAndPost()
    var
        TextToAccMapping: Record "Text-to-Account Mapping";
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DocNo: Code[20];
        Amount: Decimal;
    begin
        Initialize();

        // Setup.
        Amount := LibraryRandom.RandDec(100, 2);
        LibrarySales.CreateCustomer(Customer);
        SetupGeneralJournal(GenJournalLine, GenJournalLine."Account Type"::Customer, Customer."No.", Amount);
        SetupAccountMapping(TextToAccMapping, GenJournalLine, TextToAccMapping."Bal. Source Type"::Customer, Customer."No.", -1);
        DocNo := GenJournalLine."Document No.";

        // Exercise.
        LibraryVariableStorage.Enqueue(1);
        LibraryVariableStorage.Enqueue(1);
        LibraryVariableStorage.Enqueue('');
        GenJournalLine.MatchSingleLedgerEntry();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        FindCustLedgerEntry(CustLedgerEntry, Customer."No.");

        // Verify.
        CustLedgerEntry.TestField(Open, false);
        CustLedgerEntry.TestField("Document No.", DocNo);
        CustLedgerEntry.TestField("Document Type", GenJournalLine."Document Type"::Invoice);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MapVendorAccountWRefund()
    var
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        TextToAccMapping: Record "Text-to-Account Mapping";
    begin
        Initialize();

        // Setup.
        LibraryPurchase.CreateVendor(Vendor);
        SetupAccountMapping(TextToAccMapping, GenJournalLine, TextToAccMapping."Bal. Source Type"::Vendor, Vendor."No.", -1);

        // Exercise.
        GenJournalLine.MatchSingleLedgerEntry();

        // Verify.
        VerifyGenJnlLine(GenJournalLine, GenJournalLine."Document Type"::Refund, '',
          GenJournalLine."Account Type"::Vendor, Vendor."No.", true);
        VerifyAppliedDocLine(GenJournalLine, GenJournalLine."Document Type"::"Credit Memo");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MapCustomerAccountWRefund()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        TextToAccMapping: Record "Text-to-Account Mapping";
    begin
        Initialize();

        // Setup.
        LibrarySales.CreateCustomer(Customer);
        SetupAccountMapping(TextToAccMapping, GenJournalLine, TextToAccMapping."Bal. Source Type"::Customer, Customer."No.", 1);

        // Exercise.
        GenJournalLine.MatchSingleLedgerEntry();

        // Verify.
        VerifyGenJnlLine(GenJournalLine, GenJournalLine."Document Type"::Refund, '',
          GenJournalLine."Account Type"::Customer, Customer."No.", true);
        VerifyAppliedDocLine(GenJournalLine, GenJournalLine."Document Type"::"Credit Memo");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MapVendorAccountPostRefund()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        TextToAccMapping: Record "Text-to-Account Mapping";
        DocNo: Code[20];
    begin
        Initialize();

        // Setup.
        LibraryPurchase.CreateVendor(Vendor);
        SetupAccountMapping(TextToAccMapping, GenJournalLine, TextToAccMapping."Bal. Source Type"::Vendor, Vendor."No.", -1);

        // Exercise.
        DocNo := GenJournalLine."Document No.";
        GenJournalLine.MatchSingleLedgerEntry();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify.
        FindVendorLedgerEntry(VendorLedgerEntry, Vendor."No.");
        VendorLedgerEntry.TestField("Document No.", DocNo);
        VendorLedgerEntry.TestField("Document Type", VendorLedgerEntry."Document Type"::"Credit Memo");
        VerifyVendorLedgerEntry(VendorLedgerEntry, false, '', 0);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MapCustomerAccountPostRefund()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        TextToAccMapping: Record "Text-to-Account Mapping";
        DocNo: Code[20];
    begin
        Initialize();

        // Setup.
        LibrarySales.CreateCustomer(Customer);
        SetupAccountMapping(TextToAccMapping, GenJournalLine, TextToAccMapping."Bal. Source Type"::Customer, Customer."No.", 1);

        // Exercise.
        DocNo := GenJournalLine."Document No.";
        GenJournalLine.MatchSingleLedgerEntry();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify.
        FindCustLedgerEntry(CustLedgerEntry, Customer."No.");
        CustLedgerEntry.TestField("Document No.", DocNo);
        CustLedgerEntry.TestField("Document Type", GenJournalLine."Document Type"::"Credit Memo");
        VerifyCustLedgerEntry(CustLedgerEntry, false, '', 0);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MapVsMatch()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        TextToAccMapping: Record "Text-to-Account Mapping";
    begin
        Initialize();

        // Setup.
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate(Name, CopyStr(CreateGuid(), 1, 50));
        Customer.Modify(true);
        SetupGeneralJournal(GenJournalLine, GenJournalLine."Account Type"::Customer, Customer."No.", LibraryRandom.RandDec(100, 2));
        CreateAccountMapping(TextToAccMapping, GenJournalLine."Document No.",
          TextToAccMapping."Bal. Source Type"::Customer, Customer."No.", '');

        // Exercise.
        GenJournalLine.MatchSingleLedgerEntry();

        // Verify.
        VerifyGenJnlLine(GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Document No.",
          GenJournalLine."Account Type"::Customer, Customer."No.", true);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MapResilience()
    var
        Customer: Record Customer;
        Customer2: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        TextToAccMapping: Record "Text-to-Account Mapping";
    begin
        Initialize();

        // Setup.
        LibrarySales.CreateCustomer(Customer);
        SetupAccountMapping(TextToAccMapping, GenJournalLine, TextToAccMapping."Bal. Source Type"::Customer, Customer."No.", -1);

        GenJournalLine.MatchSingleLedgerEntry();

        LibrarySales.CreateCustomer(Customer2);
        CreateLedgerEntry(GenJournalLine2, GenJournalLine."Account Type"::Customer, GenJournalLine."Document Type"::Invoice,
          Customer2."No.", -GenJournalLine.Amount);

        // Exercise.
        GenJournalLine.MatchSingleLedgerEntry();

        // Verify.
        VerifyGenJnlLine(GenJournalLine, GenJournalLine."Document Type"::Payment, '',
          GenJournalLine."Account Type"::Customer, Customer."No.", true);
        VerifyAppliedDocLine(GenJournalLine, GenJournalLine."Document Type"::Invoice);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MapMultipleRules()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        TextToAccMapping: Record "Text-to-Account Mapping";
        TextToAccMapping2: Record "Text-to-Account Mapping";
        Keyword: Text[50];
        Amount: Decimal;
    begin
        Initialize();

        // Setup.
        Amount := LibraryRandom.RandDec(100, 2);
        Keyword := CreateGuid();
        CreateAccountMapping(TextToAccMapping, CopyStr(Keyword, 1, 5), TextToAccMapping."Bal. Source Type"::"G/L Account", '', '');
        CreateAccountMapping(TextToAccMapping2, CopyStr(Keyword, 1, 10), TextToAccMapping."Bal. Source Type"::"G/L Account", '', '');

        CreateGenJnlBatchWithBalanceAccount(GenJournalBatch);
        CreateGenJnlLineForMatching(GenJournalLine, GenJournalBatch,
          CopyStr(Keyword, 1, 5) + ' ' + CopyStr(Keyword, 7, 1), Amount);
        CreateGenJnlLineForMatching(GenJournalLine2, GenJournalBatch, CopyStr(Keyword, 1, 10), Amount);

        // Exercise.
        GenJournalLine.MatchSingleLedgerEntry();

        // Verify.
        VerifyGenJnlLine(GenJournalLine, GenJournalLine."Document Type"::Payment, '',
          GenJournalLine."Account Type"::"G/L Account", TextToAccMapping."Debit Acc. No.", true);
        VerifyGenJnlLine(GenJournalLine2, GenJournalLine2."Document Type"::Payment, '',
          GenJournalLine."Account Type"::"G/L Account", TextToAccMapping2."Debit Acc. No.", true);
    end;

    local procedure AddMappingRule(AccountType: Enum "Gen. Journal Account Type")
    var
        GLAccount: Record "G/L Account";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        TextToAccMapping: Record "Text-to-Account Mapping";
        Customer: Record Customer;
        Vendor: Record Vendor;
        GeneralJournal: TestPage "General Journal";
        Keyword: Text[50];
        Amount: Decimal;
    begin
        Initialize();

        // Setup.
        Amount := LibraryRandom.RandDec(100, 2);
        Keyword :=
          LibraryUtility.GenerateRandomCode(
            TextToAccMapping.FieldNo("Mapping Text"), DATABASE::"Text-to-Account Mapping") + '{[(*)]} ';

        CreateGenJnlBatchWithBalanceAccount(GenJournalBatch);
        CreateGenJnlLineForMatching(GenJournalLine, GenJournalBatch, '', Amount);
        GenJournalLine.Validate("Account Type", AccountType);
        case AccountType of
            GenJournalLine."Account Type"::Customer:
                begin
                    LibrarySales.CreateCustomer(Customer);
                    GenJournalLine.Validate("Account No.", Customer."No.");
                end;
            GenJournalLine."Account Type"::Vendor:
                begin
                    LibraryPurchase.CreateVendor(Vendor);
                    GenJournalLine.Validate("Account No.", Vendor."No.");
                end;
        end;
        GenJournalLine.Validate(Description, Keyword);
        GenJournalLine.Modify(true);

        // Exercise.
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryVariableStorage.Enqueue(GenJournalBatch."Journal Template Name");
        LibraryVariableStorage.Enqueue(GLAccount."No.");

        GeneralJournal.OpenView();
        GeneralJournal.GotoRecord(GenJournalLine);
        GeneralJournal.AddMappingRule.Invoke();
        GeneralJournal.OK().Invoke();

        // Verify.
        TextToAccMapping.SetRange("Mapping Text", Keyword);
        TextToAccMapping.FindFirst();
        TextToAccMapping.TestField("Bal. Source Type", AccountType);
    end;

    [Test]
    [HandlerFunctions('TemplateListPageHandler,MappingPageHandler')]
    [Scope('OnPrem')]
    procedure AddRuleGLAccount()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        AddMappingRule(GenJournalLine."Account Type"::"G/L Account");
    end;

    [Test]
    [HandlerFunctions('TemplateListPageHandler,MappingPageHandler')]
    [Scope('OnPrem')]
    procedure AddRuleCustomer()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        AddMappingRule(GenJournalLine."Account Type"::Customer);
    end;

    [Test]
    [HandlerFunctions('TemplateListPageHandler,MappingPageHandler')]
    [Scope('OnPrem')]
    procedure AddRuleVendor()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        AddMappingRule(GenJournalLine."Account Type"::Vendor);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure NoMapFound()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        TextToAccMapping: Record "Text-to-Account Mapping";
    begin
        Initialize();

        // Setup.
        CreateGenJnlBatchWithBalanceAccount(GenJournalBatch);
        CreateGenJnlLineForMatching(GenJournalLine, GenJournalBatch, '', -LibraryRandom.RandDec(100, 2));
        CreateAccountMapping(TextToAccMapping,
          LibraryUtility.GenerateRandomCode(TextToAccMapping.FieldNo("Line No."), DATABASE::"Text-to-Account Mapping"),
          TextToAccMapping."Bal. Source Type"::"G/L Account", '', '');

        // Exercise.
        GenJournalLine.MatchSingleLedgerEntry();

        // Verify.
        VerifyGenJnlLine(GenJournalLine, GenJournalLine."Document Type"::Payment, '',
          GenJournalLine."Account Type"::"G/L Account", '', false);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Match General Jnl Lines Test");
        LibraryVariableStorage.Clear();
        CloseExistingEntries();
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Match General Jnl Lines Test");

        LibraryVariableStorage.Clear();
        LibraryERMCountryData.UpdateLocalData();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        isInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Match General Jnl Lines Test");
    end;

    local procedure FindCustLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; CustNo: Code[20])
    begin
        CustLedgerEntry.SetRange("Customer No.", CustNo);
        CustLedgerEntry.FindLast();
    end;

    local procedure FindVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; VendorNo: Code[20])
    begin
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.FindLast();
    end;

    local procedure CloseExistingEntries()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        CustLedgerEntry.SetRange(Open, true);
        CustLedgerEntry.ModifyAll(Open, false);
        VendorLedgerEntry.SetRange(Open, true);
        VendorLedgerEntry.ModifyAll(Open, false);
    end;

    local procedure CreateGenJnlLineForMatching(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; Description: Text[250]; Amount: Decimal)
    begin
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Payment, "Gen. Journal Account Type"::"G/L Account", '', Amount);
        GenJournalLine.Description :=
          CopyStr(Description, 1, LibraryUtility.GetFieldLength(DATABASE::"Gen. Journal Line", GenJournalLine.FieldNo(Description)));
        GenJournalLine.Modify(true);
    end;

    local procedure CreateGenJnlBatchWithBalanceAccount(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GLAccount: Record "G/L Account";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGLAccount(GLAccount);
        GenJournalBatch.Validate("Bal. Account Type", GenJournalBatch."Bal. Account Type"::"G/L Account");
        GenJournalBatch.Validate("Bal. Account No.", GLAccount."No.");
        GenJournalBatch.Modify(true);
    end;

    local procedure CreateLedgerEntry(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; DocumentType: Enum "Gen. Journal Document Type"; AccountNo: Code[20]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGenJnlBatchWithBalanceAccount(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          DocumentType, AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Document No.", CopyStr(CreateGuid(), 1, 15));
        GenJournalLine.Validate(Description, GenJournalLine."Document No.");
        GenJournalLine.Validate("Payment Reference", CopyStr(CreateGuid(), 1, 15));
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAccountMapping(var TextToAccMapping: Record "Text-to-Account Mapping"; Keyword: Text[50]; BalSourceType: Option; BalSourceNo: Code[20]; VendorNo: Code[20])
    var
        GLAccount: Record "G/L Account";
        LastLineNo: Integer;
    begin
        if TextToAccMapping.FindLast() then
            LastLineNo := TextToAccMapping."Line No.";

        TextToAccMapping.Init();
        TextToAccMapping.Validate("Line No.", LastLineNo + 1);
        TextToAccMapping.Validate("Mapping Text", Keyword);
        LibraryERM.CreateGLAccount(GLAccount);
        TextToAccMapping.Validate("Debit Acc. No.", GLAccount."No.");
        LibraryERM.CreateGLAccount(GLAccount);
        TextToAccMapping.Validate("Credit Acc. No.", GLAccount."No.");
        TextToAccMapping.Validate("Bal. Source Type", BalSourceType);
        TextToAccMapping.Validate("Bal. Source No.", BalSourceNo);
        TextToAccMapping.Validate("Vendor No.", VendorNo);
        TextToAccMapping.Insert(true);
    end;

    local procedure SetupGeneralJournal(var GenJournalLine2: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateLedgerEntry(GenJournalLine, AccountType, GenJournalLine."Document Type"::Invoice, AccountNo, Amount);
        CreateGenJnlBatchWithBalanceAccount(GenJournalBatch);
        CreateGenJnlLineForMatching(GenJournalLine2, GenJournalBatch, GenJournalLine."Document No.", -GenJournalLine.Amount);
        GenJournalLine2."Payment Reference" := GenJournalLine."Payment Reference";
        GenJournalLine2.Modify();
    end;

    local procedure SetupAccountMapping(var TextToAccMapping: Record "Text-to-Account Mapping"; var GenJournalLine: Record "Gen. Journal Line"; BalSourceType: Option; BalSourceNo: Code[20]; Sign: Integer)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        Amount: Decimal;
    begin
        Amount := Sign * LibraryRandom.RandDec(100, 2);
        CreateAccountMapping(TextToAccMapping, CopyStr(CreateGuid(), 1, 50), BalSourceType, BalSourceNo, '');
        CreateGenJnlBatchWithBalanceAccount(GenJournalBatch);
        CreateGenJnlLineForMatching(GenJournalLine, GenJournalBatch, TextToAccMapping."Mapping Text", Amount);
    end;

    local procedure VerifyGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; DocType: Enum "Gen. Journal Document Type"; DocNo: Code[50]; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Applied: Boolean)
    begin
        GenJnlLine.Find();
        GenJnlLine.TestField("Document Type", DocType);
        GenJnlLine.TestField("Applies-to ID", DocNo);
        GenJnlLine.TestField("Account Type", AccountType);
        GenJnlLine.TestField("Account No.", AccountNo);
        GenJnlLine.TestField("Applied Automatically", Applied);
    end;

    local procedure VerifyAppliedDocLine(GenJnlLine: Record "Gen. Journal Line"; DocType: Enum "Gen. Journal Document Type")
    var
        GenJnlLine2: Record "Gen. Journal Line";
    begin
        GenJnlLine2.SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
        GenJnlLine2.SetRange("Journal Batch Name", GenJnlLine."Journal Batch Name");
        GenJnlLine2.SetRange("Applies-to Doc. Type", GenJnlLine."Document Type");
        GenJnlLine2.SetRange("Applies-to Doc. No.", GenJnlLine."Document No.");
        GenJnlLine2.SetRange("Account Type", GenJnlLine."Account Type");
        GenJnlLine2.SetRange("Account No.", GenJnlLine."Account No.");
        Assert.AreEqual(1, GenJnlLine2.Count, GenJnlLine2.GetFilters);
        GenJnlLine2.FindFirst();
        GenJnlLine2.TestField("Document Type", DocType);
        GenJnlLine2.TestField("Applied Automatically", true);
    end;

    local procedure VerifyCustLedgerEntry(CustLedgerEntry: Record "Cust. Ledger Entry"; Open: Boolean; AppliesToID: Code[50]; AmountToApply: Decimal)
    begin
        CustLedgerEntry.Find();
        CustLedgerEntry.TestField(Open, Open);
        CustLedgerEntry.TestField("Applies-to ID", AppliesToID);
        CustLedgerEntry.TestField("Amount to Apply", AmountToApply);
    end;

    local procedure VerifyVendorLedgerEntry(VendorLedgerEntry: Record "Vendor Ledger Entry"; Open: Boolean; AppliesToID: Code[50]; AmountToApply: Decimal)
    begin
        VendorLedgerEntry.Find();
        VendorLedgerEntry.TestField(Open, Open);
        VendorLedgerEntry.TestField("Applies-to ID", AppliesToID);
        VendorLedgerEntry.TestField("Amount to Apply", AmountToApply);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Msg: Text[1024])
    begin
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MatchSummaryMsgHandler(Msg: Text[1024])
    var
        MatchedLinesCount: Variant;
        TotalLinesCount: Variant;
        AdditionalText: Variant;
    begin
        LibraryVariableStorage.Dequeue(MatchedLinesCount);
        LibraryVariableStorage.Dequeue(TotalLinesCount);
        LibraryVariableStorage.Dequeue(AdditionalText);
        Assert.AreEqual(Msg, StrSubstNo(MatchSummaryMsg, MatchedLinesCount, TotalLinesCount) + Format(AdditionalText), '');
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure MappingPageHandler(var TextToAccMappingPage: TestPage "Text-to-Account Mapping")
    var
        TextToAccMapping: Record "Text-to-Account Mapping";
        GLAccount: Variant;
    begin
        LibraryVariableStorage.Dequeue(GLAccount);
        Assert.AreEqual(TextToAccMappingPage."Bal. Source Type".Value <> Format(TextToAccMapping."Bal. Source Type"::"G/L Account"),
          TextToAccMappingPage."Bal. Source No.".Enabled(), 'Wrong Bal. Source No. enabled state.');
        TextToAccMappingPage."Debit Acc. No.".SetValue(GLAccount);
        TextToAccMappingPage."Credit Acc. No.".SetValue(GLAccount);
        TextToAccMappingPage.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure TemplateListPageHandler(var GeneralJournalTemplateList: TestPage "General Journal Template List")
    var
        TemplateName: Variant;
    begin
        LibraryVariableStorage.Dequeue(TemplateName);
        GeneralJournalTemplateList.FILTER.SetFilter(Name, TemplateName);
        GeneralJournalTemplateList.OK().Invoke();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SearchEnteriesInMappingTxtToAccountMatchExactText()
    var
        Vendor: Record Vendor;
        TextToAccMapping: Record "Text-to-Account Mapping";
        LibrarySmallBusiness: Codeunit "Library - Small Business";
        Term1: Text[50];
        Term2: Text[50];
        Term3: Text[50];
    begin
        Term1 := LibraryUtility.GenerateGUID();
        Term2 := LibraryUtility.GenerateGUID();
        Term3 := CopyStr(Term1 + Term2, 1, 45);
        LibrarySmallBusiness.CreateVendor(Vendor);
        TextToAccMapping.Reset();
        TextToAccMapping.DeleteAll();
        CreateAccountMapping(TextToAccMapping, Term1, TextToAccMapping."Bal. Source Type"::"G/L Account", '', Vendor."No.");
        CreateAccountMapping(TextToAccMapping, Term2, TextToAccMapping."Bal. Source Type"::"G/L Account", '', Vendor."No.");
        CreateAccountMapping(TextToAccMapping, Term3, TextToAccMapping."Bal. Source Type"::"G/L Account", '', Vendor."No.");

        Assert.AreEqual(0, TextToAccMapping.SearchEnteriesInText(TextToAccMapping, Term3, ''),
          'Expected that there is no result for this vendor');
        Assert.AreEqual(1, TextToAccMapping.SearchEnteriesInText(TextToAccMapping, Term3, Vendor."No."),
          'Expected that there is one match for this vendor');
        Assert.AreEqual(Term3, TextToAccMapping."Mapping Text", 'Expected that the mapping text and searched term are the same');
        TextToAccMapping.Reset();
        CreateAccountMapping(TextToAccMapping, Term1, TextToAccMapping."Bal. Source Type"::"G/L Account", '', '');
        CreateAccountMapping(TextToAccMapping, Term2, TextToAccMapping."Bal. Source Type"::"G/L Account", '', '');
        CreateAccountMapping(TextToAccMapping, Term3, TextToAccMapping."Bal. Source Type"::"G/L Account", '', '');

        Assert.AreEqual(1, TextToAccMapping.SearchEnteriesInText(TextToAccMapping, Term3, ''),
          'Expected that there is one match for this vendor');
        Assert.AreEqual(Term3, TextToAccMapping."Mapping Text",
          'Expected that the mapping text and searched term are the same');

        Vendor.Delete();
        TextToAccMapping.DeleteAll();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SearchEnteriesInMappingTxtToAccountReturns2()
    var
        TextToAccMapping: Record "Text-to-Account Mapping";
        Vendor: Record Vendor;
        LibrarySmallBusiness: Codeunit "Library - Small Business";
        CommonSubstring: Text;
        Term1: Text[50];
        Term2: Text[50];
    begin
        Term1 := CopyStr(CreateGuid(), 2, 15);
        Term2 := CopyStr(CreateGuid(), 2, 15);
        CommonSubstring := StrSubstNo('%1 %2', Term1, Term2);
        LibrarySmallBusiness.CreateVendor(Vendor);
        TextToAccMapping.Reset();
        TextToAccMapping.DeleteAll();
        CreateAccountMapping(TextToAccMapping, Term1, TextToAccMapping."Bal. Source Type"::"G/L Account", '', Vendor."No.");
        CreateAccountMapping(TextToAccMapping, Term2, TextToAccMapping."Bal. Source Type"::"G/L Account", '', Vendor."No.");

        Assert.AreEqual(2, TextToAccMapping.SearchEnteriesInText(TextToAccMapping, CommonSubstring, Vendor."No."),
          'Expected that returns and error');

        Vendor.Delete();
        TextToAccMapping.DeleteAll();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SearchEnteriesInMappingTxtToAccountMatchContainText()
    var
        Vendor: Record Vendor;
        TextToAccMapping: Record "Text-to-Account Mapping";
        LibrarySmallBusiness: Codeunit "Library - Small Business";
        MappingTxt: Text[50];
        LineTxt: Text;
    begin
        MappingTxt := CreateGuid();
        LineTxt := CopyStr(StrSubstNo('%1,%2', MappingTxt, Format(CreateGuid())), 1, 50);

        LibrarySmallBusiness.CreateVendor(Vendor);
        CreateAccountMapping(TextToAccMapping, MappingTxt, TextToAccMapping."Bal. Source Type"::"G/L Account", '', Vendor."No.");

        Assert.AreEqual(1, TextToAccMapping.SearchEnteriesInText(TextToAccMapping, LineTxt, Vendor."No."),
          'Expected that there is one match for this vendor');
        Assert.AreEqual(MappingTxt, TextToAccMapping."Mapping Text",
          'Expected that correct mapping is returned');

        Vendor.Delete();
        TextToAccMapping.DeleteAll();
    end;
}

