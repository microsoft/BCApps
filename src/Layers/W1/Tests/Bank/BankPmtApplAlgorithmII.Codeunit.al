codeunit 134259 "Bank Pmt. Appl. Algorithm II"
{
    Permissions = TableData "Cust. Ledger Entry" = imd,
                  TableData "Vendor Ledger Entry" = imd;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Bank Payment Application]
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryJournals: Codeunit "Library - Journals";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MatchDirectDebitCollectionForCAMT()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        BankAccount: Record "Bank Account";
        TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary;
        DirectDebitCollection: Record "Direct Debit Collection";
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [CAMT] [Direct Debit]
        // [SCENARIO 282632] Match Direct Debit Collection Entry for CAMT.
        Initialize();

        // [GIVEN] Opened Customer Ledger Entry with "Entry No." = "E1".
        CreateAndPostSalesInvoice(
          GenJournalLine, LibrarySales.CreateCustomerNo(),
          LibraryUtility.GenerateGUID(), '', LibraryRandom.RandDecInRange(100, 200, 2));
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, GenJournalLine."Document No.");

        // [GIVEN] Bank Account with "Bank Statement Import Format" = "SEPA CAMT".
        CreateBankAccWithBankStatementImportFormat(BankAccount, CreateBankExportImportSetupCAMT());

        // [GIVEN] Direct Debit Collection with Status = "File Created".
        // [GIVEN] Direct Debit Collection Entry with "Applies-to Entry No." = "E1", "Transaction ID" = "T1", Status = "File Created".
        MockDirectDebitCollectionEntry(
          DirectDebitCollectionEntry, BankAccount."No.", CustLedgerEntry."Entry No.",
          DirectDebitCollection.Status::"File Created", DirectDebitCollectionEntry.Status::"File Created");

        // [GIVEN] Reconciliation Line with "Transaction ID" = "T1".
        CreateBankReconciliation(BankAccReconciliation, BankAccount."No.");
        CreateBankReconciliationLine(
          BankAccReconciliation, BankAccReconciliationLine,
          GenJournalLine.Amount / 2, '', '', DirectDebitCollectionEntry."Transaction ID");

        // [WHEN] Run matching procedure.
        RunMatch(BankAccReconciliation, TempBankStatementMatchingBuffer, true);

        // [THEN] A match is found for Ledger Entry "E1".
        SetRule(
          BankPmtApplRule, BankPmtApplRule."Related Party Matched"::"Not Considered",
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Not Considered",
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"Not Considered", BankPmtApplRule."Direct Debit Collect. Matched"::Yes);
        VerifyReconciliation(BankPmtApplRule, TempBankStatementMatchingBuffer, BankAccReconciliationLine."Statement Line No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MatchDirectDebitCollectWhenVendLedgerEntryWithTransactionIDExists()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccount: Record "Bank Account";
        TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary;
        DirectDebitCollection: Record "Direct Debit Collection";
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [CAMT] [Direct Debit]
        // [SCENARIO 282632] Match Direct Debit Collection Entry in case of Vendor Ledger Entry has "Transaction ID" from Direct Debit Collection Entry.
        Initialize();

        // [GIVEN] Opened Vendor Ledger Entry with "Entry No." = "E1".
        CreateAndPostPurchaseInvoice(
          GenJournalLine, LibraryPurchase.CreateVendorNo(),
          LibraryUtility.GenerateGUID(), LibraryUtility.GenerateGUID(), LibraryRandom.RandDecInRange(100, 200, 2));
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, GenJournalLine."Document No.");

        // [GIVEN] Bank Account with "Bank Statement Import Format" = "SEPA CAMT".
        CreateBankAccWithBankStatementImportFormat(BankAccount, CreateBankExportImportSetupCAMT());

        // [GIVEN] Direct Debit Collection with Status = "File Created".
        // [GIVEN] Direct Debit Collection Entry with "Applies-to Entry No." = "E1", "Transaction ID" = "T1", Status = "File Created".
        MockDirectDebitCollectionEntry(
          DirectDebitCollectionEntry, BankAccount."No.", VendorLedgerEntry."Entry No.",
          DirectDebitCollection.Status::"File Created", DirectDebitCollectionEntry.Status::"File Created");

        // [GIVEN] Reconciliation Line with "Transaction ID" = "T1".
        CreateBankReconciliation(BankAccReconciliation, BankAccount."No.");
        CreateBankReconciliationLine(
          BankAccReconciliation, BankAccReconciliationLine,
          GenJournalLine.Amount / 2, '', '', DirectDebitCollectionEntry."Transaction ID");

        // [WHEN] Run matching procedure.
        RunMatch(BankAccReconciliation, TempBankStatementMatchingBuffer, true);

        // [THEN] A match is not found.
        Assert.RecordIsEmpty(TempBankStatementMatchingBuffer);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MatchDirectDebitCollectWhenCollectionStatusCanceled()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccount: Record "Bank Account";
        TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary;
        DirectDebitCollection: Record "Direct Debit Collection";
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [CAMT] [Direct Debit]
        // [SCENARIO 282632] Match Direct Debit Collection Entry in case of Direct Debit Collection Status is Canceled.
        Initialize();

        // [GIVEN] Opened Customer Ledger Entry with "Entry No." = "E1".
        CreateAndPostSalesInvoice(
          GenJournalLine, LibrarySales.CreateCustomerNo(),
          LibraryUtility.GenerateGUID(), '', LibraryRandom.RandDecInRange(100, 200, 2));
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, GenJournalLine."Document No.");

        // [GIVEN] Bank Account with "Bank Statement Import Format" = "SEPA CAMT".
        CreateBankAccWithBankStatementImportFormat(BankAccount, CreateBankExportImportSetupCAMT());

        // [GIVEN] Direct Debit Collection with Status = "Canceled".
        // [GIVEN] Direct Debit Collection Entry with "Applies-to Entry No." = "E1", "Transaction ID" = "T1", Status = "File Created".
        MockDirectDebitCollectionEntry(
          DirectDebitCollectionEntry, BankAccount."No.", CustLedgerEntry."Entry No.",
          DirectDebitCollection.Status::Canceled, DirectDebitCollectionEntry.Status::"File Created");

        // [GIVEN] Reconciliation Line with "Transaction ID" = "T1".
        CreateBankReconciliation(BankAccReconciliation, BankAccount."No.");
        CreateBankReconciliationLine(
          BankAccReconciliation, BankAccReconciliationLine,
          GenJournalLine.Amount / 2, '', '', DirectDebitCollectionEntry."Transaction ID");

        // [WHEN] Run matching procedure.
        RunMatch(BankAccReconciliation, TempBankStatementMatchingBuffer, true);

        // [THEN] A match is not found.
        Assert.RecordIsEmpty(TempBankStatementMatchingBuffer);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MatchDirectDebitCollectWhenCollectionEntryStatusRejected()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccount: Record "Bank Account";
        TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary;
        DirectDebitCollection: Record "Direct Debit Collection";
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [CAMT] [Direct Debit]
        // [SCENARIO 282632] Match Direct Debit Collection Entry in case of Direct Debit Collection Entry Status is Rejected.
        Initialize();

        // [GIVEN] Opened Customer Ledger Entry with "Entry No." = "E1".
        CreateAndPostSalesInvoice(
          GenJournalLine, LibrarySales.CreateCustomerNo(),
          LibraryUtility.GenerateGUID(), '', LibraryRandom.RandDecInRange(100, 200, 2));
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, GenJournalLine."Document No.");

        // [GIVEN] Bank Account with "Bank Statement Import Format" = "SEPA CAMT".
        CreateBankAccWithBankStatementImportFormat(BankAccount, CreateBankExportImportSetupCAMT());

        // [GIVEN] Direct Debit Collection with Status = "File Created".
        // [GIVEN] Direct Debit Collection Entry with "Applies-to Entry No." = "E1", "Transaction ID" = "T1", Status = "Rejected".
        MockDirectDebitCollectionEntry(
          DirectDebitCollectionEntry, BankAccount."No.", CustLedgerEntry."Entry No.",
          DirectDebitCollection.Status::"File Created", DirectDebitCollectionEntry.Status::Rejected);

        // [GIVEN] Reconciliation Line with "Transaction ID" = "T1".
        CreateBankReconciliation(BankAccReconciliation, BankAccount."No.");
        CreateBankReconciliationLine(
          BankAccReconciliation, BankAccReconciliationLine,
          GenJournalLine.Amount / 2, '', '', DirectDebitCollectionEntry."Transaction ID");

        // [WHEN] Run matching procedure.
        RunMatch(BankAccReconciliation, TempBankStatementMatchingBuffer, true);

        // [THEN] A match is not found.
        Assert.RecordIsEmpty(TempBankStatementMatchingBuffer);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MatchDirectDebitCollectWhenCustLedgerEntryHasDifferentTransactionID()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccount: Record "Bank Account";
        TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary;
        DirectDebitCollection: Record "Direct Debit Collection";
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [CAMT] [Direct Debit]
        // [SCENARIO 282632] Match Direct Debit Collection Entry in case of Customer Ledger Entry has "Transaction ID", that is different from the Direct Debit Collection Entry's one.
        Initialize();

        // [GIVEN] Opened Customer Ledger Entry with "Entry No." = "E1".
        CreateAndPostSalesInvoice(
          GenJournalLine, LibrarySales.CreateCustomerNo(),
          LibraryUtility.GenerateGUID(), '', LibraryRandom.RandDecInRange(100, 200, 2));
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, GenJournalLine."Document No.");

        // [GIVEN] Bank Account with "Bank Statement Import Format" = "SEPA CAMT".
        CreateBankAccWithBankStatementImportFormat(BankAccount, CreateBankExportImportSetupCAMT());

        // [GIVEN] Direct Debit Collection with Status = "File Created".
        // [GIVEN] Direct Debit Collection Entry with "Applies-to Entry No." = "E1", "Transaction ID" = "T1", Status = "File Created".
        MockDirectDebitCollectionEntry(
          DirectDebitCollectionEntry, BankAccount."No.", CustLedgerEntry."Entry No.",
          DirectDebitCollection.Status::"File Created", DirectDebitCollectionEntry.Status::"File Created");

        // [GIVEN] Reconciliation Line with "Transaction ID" = "T2" <> "T1".
        CreateBankReconciliation(BankAccReconciliation, BankAccount."No.");
        CreateBankReconciliationLine(
          BankAccReconciliation, BankAccReconciliationLine,
          GenJournalLine.Amount / 2, '', '', LibraryUtility.GenerateGUID());

        // [WHEN] Run matching procedure.
        RunMatch(BankAccReconciliation, TempBankStatementMatchingBuffer, true);

        // [THEN] A match is not found.
        Assert.RecordIsEmpty(TempBankStatementMatchingBuffer);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MatchDirectDebitCollectWhenCustLedgerEntryIsClosed()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        BankAccount: Record "Bank Account";
        TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary;
        DirectDebitCollection: Record "Direct Debit Collection";
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GenJournalLine: array[2] of Record "Gen. Journal Line";
    begin
        // [FEATURE] [CAMT] [Direct Debit]
        // [SCENARIO 282632] Match Direct Debit Collection Entry in case of closed Customer Ledger Entry.
        Initialize();

        // [GIVEN] Opened Customer Ledger Entry with "Entry No." = "E1", Amount = "A1", "Document No." = "D1".
        // [GIVEN] Closed Customer Ledger Entry with "Entry No." = "E2".
        CreateAndPostSalesInvoice(
          GenJournalLine[1], LibrarySales.CreateCustomerNo(),
          LibraryUtility.GenerateGUID(), '', LibraryRandom.RandDecInRange(100, 200, 2));
        CreateAndPostSalesInvoice(
          GenJournalLine[2], LibrarySales.CreateCustomerNo(),
          LibraryUtility.GenerateGUID(), '', GenJournalLine[1].Amount + LibraryRandom.RandDecInRange(100, 200, 2));
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, GenJournalLine[2]."Document No.");
        CustLedgerEntry.Open := false;
        CustLedgerEntry.Modify();

        // [GIVEN] Bank Account with "Bank Statement Import Format" = "SEPA CAMT".
        CreateBankAccWithBankStatementImportFormat(BankAccount, CreateBankExportImportSetupCAMT());

        // [GIVEN] Direct Debit Collection with Status = "File Created".
        // [GIVEN] Direct Debit Collection Entry with "Applies-to Entry No." = "E2", "Transaction ID" = "T2", Status = "File Created".
        MockDirectDebitCollectionEntry(
          DirectDebitCollectionEntry, BankAccount."No.", CustLedgerEntry."Entry No.",
          DirectDebitCollection.Status::"File Created", DirectDebitCollectionEntry.Status::"File Created");

        // [GIVEN] Reconciliation Line with "Transaction ID" = "T2", Amount = "A1", "Additional Transaction Info" = "D1".
        CreateBankReconciliation(BankAccReconciliation, BankAccount."No.");
        CreateBankReconciliationLine(
          BankAccReconciliation, BankAccReconciliationLine,
          GenJournalLine[1].Amount, '', GenJournalLine[1]."Document No.", DirectDebitCollectionEntry."Transaction ID");

        // [WHEN] Run matching procedure.
        RunMatch(BankAccReconciliation, TempBankStatementMatchingBuffer, true);

        // [THEN] A match is found for Ledger Entry "E1".
        SetRule(
          BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes,
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered");
        VerifyReconciliation(BankPmtApplRule, TempBankStatementMatchingBuffer, BankAccReconciliationLine."Statement Line No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MatchDirectDebitCollectWhenCustLedgerEntryPostingDateGreaterTransactionDate()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        BankAccount: Record "Bank Account";
        TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary;
        DirectDebitCollection: Record "Direct Debit Collection";
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GenJournalLine: array[2] of Record "Gen. Journal Line";
    begin
        // [FEATURE] [CAMT] [Direct Debit]
        // [SCENARIO 282632] Match Direct Debit Collection Entry in case of Customer Ledger Entry "Posting Date" is greater than "Transaction Date" of Reconciliation Line.
        Initialize();

        // [GIVEN] Opened Customer Ledger Entry with "Entry No." = "E1", Amount = "A1", "Document No." = "D1", "Posting Date" = 01.01.20.
        // [GIVEN] Opened Customer Ledger Entry with "Entry No." = "E2", "Posting Date" = 02.01.20 .
        CreateAndPostSalesInvoice(
          GenJournalLine[1], LibrarySales.CreateCustomerNo(),
          LibraryUtility.GenerateGUID(), '', LibraryRandom.RandDecInRange(100, 200, 2));
        CreateAndPostSalesInvoice(
          GenJournalLine[2], LibrarySales.CreateCustomerNo(),
          LibraryUtility.GenerateGUID(), '', LibraryRandom.RandDecInRange(100, 200, 2));
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, GenJournalLine[2]."Document No.");
        CustLedgerEntry."Posting Date" := WorkDate() + 1;
        CustLedgerEntry.Modify();

        // [GIVEN] Bank Account with "Bank Statement Import Format" = "SEPA CAMT".
        CreateBankAccWithBankStatementImportFormat(BankAccount, CreateBankExportImportSetupCAMT());

        // [GIVEN] Direct Debit Collection with Status = "File Created".
        // [GIVEN] Direct Debit Collection Entry with "Applies-to Entry No." = "E2", "Transaction ID" = "T2", Status = "File Created".
        MockDirectDebitCollectionEntry(
          DirectDebitCollectionEntry, BankAccount."No.", CustLedgerEntry."Entry No.",
          DirectDebitCollection.Status::"File Created", DirectDebitCollectionEntry.Status::"File Created");

        // [GIVEN] Reconciliation Line with "Transaction Date" = 01.01.20, "Transaction ID" = "T2", Amount = "A1", "Additional Transaction Info" = "D1".
        CreateBankReconciliation(BankAccReconciliation, BankAccount."No.");
        CreateBankReconciliationLine(
          BankAccReconciliation, BankAccReconciliationLine,
          GenJournalLine[1].Amount, '', GenJournalLine[1]."Document No.", DirectDebitCollectionEntry."Transaction ID");

        // [WHEN] Run matching procedure.
        RunMatch(BankAccReconciliation, TempBankStatementMatchingBuffer, true);

        // [THEN] A match is found for Ledger Entry "E1".
        SetRule(
          BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes,
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered");
        VerifyReconciliation(BankPmtApplRule, TempBankStatementMatchingBuffer, BankAccReconciliationLine."Statement Line No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MatchDirectDebitCollectWhenApplyEntryIsFalse()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        BankAccount: Record "Bank Account";
        TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary;
        DirectDebitCollection: Record "Direct Debit Collection";
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GenJournalLine: array[2] of Record "Gen. Journal Line";
    begin
        // [FEATURE] [CAMT] [Direct Debit]
        // [SCENARIO 282632] Match Direct Debit Collection Entry in case of ApplyEntry parameter of "Match Bank Payments" codeunit is false.
        Initialize();

        // [GIVEN] Opened Customer Ledger Entry with Amount = "A1", "Document No." = "D1".
        // [GIVEN] Opened Customer Ledger Entry with "Entry No." = "E2".
        CreateAndPostSalesInvoice(
          GenJournalLine[1], LibrarySales.CreateCustomerNo(),
          LibraryUtility.GenerateGUID(), '', LibraryRandom.RandDecInRange(100, 200, 2));
        CreateAndPostSalesInvoice(
          GenJournalLine[2], LibrarySales.CreateCustomerNo(),
          LibraryUtility.GenerateGUID(), '', GenJournalLine[1].Amount + LibraryRandom.RandDecInRange(100, 200, 2));
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, GenJournalLine[2]."Document No.");

        // [GIVEN] Bank Account with "Bank Statement Import Format" = "SEPA CAMT".
        CreateBankAccWithBankStatementImportFormat(BankAccount, CreateBankExportImportSetupCAMT());

        // [GIVEN] Direct Debit Collection with Status = "File Created".
        // [GIVEN] Direct Debit Collection Entry with "Applies-to Entry No." = "E2", "Transaction ID" = "T2", Status = "File Created".
        MockDirectDebitCollectionEntry(
          DirectDebitCollectionEntry, BankAccount."No.", CustLedgerEntry."Entry No.",
          DirectDebitCollection.Status::"File Created", DirectDebitCollectionEntry.Status::"File Created");

        // [GIVEN] Reconciliation Line with "Transaction ID" = "T2", Amount = "A1", "Additional Transaction Info" = "D1".
        CreateBankReconciliation(BankAccReconciliation, BankAccount."No.");
        CreateBankReconciliationLine(
          BankAccReconciliation, BankAccReconciliationLine,
          GenJournalLine[1].Amount, '', GenJournalLine[1]."Document No.", DirectDebitCollectionEntry."Transaction ID");

        // [WHEN] Run matching procedure with ApplyEntry = FALSE.
        RunMatch(BankAccReconciliation, TempBankStatementMatchingBuffer, false);

        // [THEN] A match is found for Ledger Entry "E1".
        SetRule(
          BankPmtApplRule, BankPmtApplRule."Related Party Matched"::"Not Considered",
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Not Considered",
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"Not Considered",
          BankPmtApplRule."Direct Debit Collect. Matched"::Yes);
        VerifyReconciliation(BankPmtApplRule, TempBankStatementMatchingBuffer, BankAccReconciliationLine."Statement Line No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MatchDirectDebitCollectWhenTwoCollectionEntriesHaveSameTransactionID()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        BankAccount: Record "Bank Account";
        TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary;
        DirectDebitCollection: Record "Direct Debit Collection";
        DirectDebitCollectionEntry: array[2] of Record "Direct Debit Collection Entry";
        CustLedgerEntry: array[2] of Record "Cust. Ledger Entry";
        GenJournalLine: array[2] of Record "Gen. Journal Line";
    begin
        // [FEATURE] [CAMT] [Direct Debit]
        // [SCENARIO 282632] Match Direct Debit Collection Entry in case of two DD Collect. Entries have the same "Transaction ID".
        Initialize();

        // [GIVEN] Two opened Customer Ledger Entries with "Entry No." = "E1","E2", Amount = "A1","A2", "Document No." = "D1","D2".
        CreateAndPostSalesInvoice(
          GenJournalLine[1], LibrarySales.CreateCustomerNo(),
          LibraryUtility.GenerateGUID(), '', LibraryRandom.RandDecInRange(100, 200, 2));
        CreateAndPostSalesInvoice(
          GenJournalLine[2], LibrarySales.CreateCustomerNo(),
          LibraryUtility.GenerateGUID(), '', GenJournalLine[1].Amount + LibraryRandom.RandDecInRange(100, 200, 2));
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry[1], CustLedgerEntry[1]."Document Type"::Invoice, GenJournalLine[1]."Document No.");
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry[2], CustLedgerEntry[2]."Document Type"::Invoice, GenJournalLine[2]."Document No.");

        // [GIVEN] Bank Account with "Bank Statement Import Format" = "SEPA CAMT".
        CreateBankAccWithBankStatementImportFormat(BankAccount, CreateBankExportImportSetupCAMT());

        // [GIVEN] Two Direct Debit Collections with Status = "File Created".
        // [GIVEN] Two Direct Debit Collection Entries with "Applies-to Entry No." = "E1","E2", "Transaction ID" = "T1", Status = "File Created".
        MockDirectDebitCollectionEntry(
          DirectDebitCollectionEntry[1], BankAccount."No.", CustLedgerEntry[1]."Entry No.",
          DirectDebitCollection.Status::"File Created", DirectDebitCollectionEntry[1].Status::"File Created");
        MockDirectDebitCollectionEntry(
          DirectDebitCollectionEntry[2], BankAccount."No.", CustLedgerEntry[2]."Entry No.",
          DirectDebitCollection.Status::"File Created", DirectDebitCollectionEntry[2].Status::"File Created");
        DirectDebitCollectionEntry[2]."Transaction ID" := DirectDebitCollectionEntry[1]."Transaction ID";
        DirectDebitCollectionEntry[2].Modify();

        // [GIVEN] Reconciliation Line with "Transaction ID" = "T1", Amount = "A2", "Document No." = "D2".
        CreateBankReconciliation(BankAccReconciliation, BankAccount."No.");
        CreateBankReconciliationLine(
          BankAccReconciliation, BankAccReconciliationLine,
          GenJournalLine[2].Amount, '', GenJournalLine[2]."Document No.", DirectDebitCollectionEntry[1]."Transaction ID");

        // [WHEN] Run matching procedure.
        RunMatch(BankAccReconciliation, TempBankStatementMatchingBuffer, true);

        // [THEN] A match is found for Ledger Entry "E1".
        SetRule(
          BankPmtApplRule, BankPmtApplRule."Related Party Matched"::"Not Considered",
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Not Considered",
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"Not Considered",
          BankPmtApplRule."Direct Debit Collect. Matched"::Yes);
        VerifyReconciliation(BankPmtApplRule, TempBankStatementMatchingBuffer, BankAccReconciliationLine."Statement Line No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure MatchDDCollectWhenCustLedgerEntryTransactionIDLengthGreaterMaxLengthDDEntryTransactionID()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccount: Record "Bank Account";
        TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary;
        DirectDebitCollection: Record "Direct Debit Collection";
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        TransactionIDLengthsDifference: Integer;
    begin
        // [FEATURE] [CAMT] [Direct Debit]
        // [SCENARIO 400296] Match Direct Debit Collection Entry in case of Customer Ledger Entry has "Transaction ID" with length greater than maximum length of DD Collection Entry's "Transaction ID".
        Initialize();

        // [GIVEN] Opened Customer Ledger Entry with "Entry No." = "E1", Amount = "A1", "Document No." = "D1".
        CreateAndPostSalesInvoice(
            GenJournalLine, LibrarySales.CreateCustomerNo(), LibraryUtility.GenerateGUID(), '', LibraryRandom.RandDecInRange(100, 200, 2));
        LibraryERM.FindCustomerLedgerEntry(
            CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, GenJournalLine."Document No.");

        // [GIVEN] Bank Account with "Bank Statement Import Format" = "SEPA CAMT".
        CreateBankAccWithBankStatementImportFormat(BankAccount, CreateBankExportImportSetupCAMT());

        // [GIVEN] Direct Debit Collection with Status = "File Created".
        // [GIVEN] Direct Debit Collection Entry with "Applies-to Entry No." = "E1", "Transaction ID" = "abcd" (value has 35 chars - max length of the field), Status = "File Created".
        MockDirectDebitCollectionEntry(
            DirectDebitCollectionEntry, BankAccount."No.", CustLedgerEntry."Entry No.",
            DirectDebitCollection.Status::"File Created", DirectDebitCollectionEntry.Status::"File Created");
        DirectDebitCollectionEntry."Transaction ID" := LibraryUtility.GenerateRandomXMLText(MaxStrLen(DirectDebitCollectionEntry."Transaction ID"));
        DirectDebitCollectionEntry.Modify();

        // [GIVEN] Reconciliation Line with "Transaction ID" = "abcdXYZ" - the first 35 chars are from DD Collect. Entry "Transaction ID", the next 15 chars are random.
        // [GIVEN] Amount <> "A1", "Document No." <> "D1".
        TransactionIDLengthsDifference := MaxStrLen(BankAccReconciliationLine."Transaction ID") - MaxStrLen(DirectDebitCollectionEntry."Transaction ID");
        CreateBankReconciliation(BankAccReconciliation, BankAccount."No.");
        CreateBankReconciliationLine(
            BankAccReconciliation, BankAccReconciliationLine, GenJournalLine.Amount / 2, '', '',
            DirectDebitCollectionEntry."Transaction ID" + LibraryUtility.GenerateRandomXMLText(TransactionIDLengthsDifference));

        // [WHEN] Run matching procedure.
        RunMatch(BankAccReconciliation, TempBankStatementMatchingBuffer, true);

        // [THEN] A match was not found.
        Assert.RecordIsEmpty(TempBankStatementMatchingBuffer);
    end;

    local procedure Initialize()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Bank Pmt. Appl. Algorithm II");

        CustLedgerEntry.DeleteAll();
        VendorLedgerEntry.DeleteAll();
        InsertDefaultMatchingRules();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Bank Pmt. Appl. Algorithm II");

        LibraryERM.SetLCYCode(GetEURCurrency());
        Commit();

        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Bank Pmt. Appl. Algorithm II");
    end;

    local procedure GetEURCurrency(): Code[10]
    begin
        exit('EUR');
    end;

    local procedure GetCAMTDataExch(): Code[20]
    var
        DataExchLineDef: Record "Data Exch. Line Def";
    begin
        DataExchLineDef.SetFilter(Namespace, GetNamespace05302());
        DataExchLineDef.FindFirst();
        exit(DataExchLineDef."Data Exch. Def Code");
    end;

    local procedure GetCAMTProcCodID(): Integer
    begin
        exit(CODEUNIT::"Imp. SEPA CAMT Bank Rec. Lines");
    end;

    local procedure GetNamespace05302(): Text
    begin
        exit('urn:iso:std:iso:20022:tech:xsd:camt.053.001.02');
    end;

    local procedure CreateBankAccWithBankStatementImportFormat(var BankAccount: Record "Bank Account"; BankStatementImportFormat: Code[20])
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount."Bank Statement Import Format" := BankStatementImportFormat;
        BankAccount.Modify();
    end;

    local procedure CreateBankExportImportSetupCAMT(): Code[20]
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        BankExportImportSetup.Init();
        BankExportImportSetup.Code :=
          LibraryUtility.GenerateRandomCode(BankExportImportSetup.FieldNo(Code), DATABASE::"Bank Export/Import Setup");
        BankExportImportSetup.Direction := BankExportImportSetup.Direction::Import;
        BankExportImportSetup."Data Exch. Def. Code" := GetCAMTDataExch();
        BankExportImportSetup."Processing Codeunit ID" := GetCAMTProcCodID();
        BankExportImportSetup.Insert();
        exit(BankExportImportSetup.Code);
    end;

    local procedure CreateBankReconciliation(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; BankAccountNo: Code[20])
    begin
        LibraryERM.CreateBankAccReconciliation(
          BankAccReconciliation, BankAccountNo,
          BankAccReconciliation."Statement Type"::"Payment Application");
    end;

    local procedure CreateBankReconciliationLine(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; Amount: Decimal; TransactionText: Text[140]; AdditionalTransactionInfo: Text[100]; TransactionID: Text[50])
    begin
        LibraryERM.CreateBankAccReconciliationLn(BankAccReconciliationLine, BankAccReconciliation);
        BankAccReconciliationLine.Validate("Transaction Text", TransactionText);
        BankAccReconciliationLine.Validate("Additional Transaction Info", AdditionalTransactionInfo);
        BankAccReconciliationLine.Validate("Transaction ID", TransactionID);
        BankAccReconciliationLine.Validate("Transaction Date", WorkDate());
        BankAccReconciliationLine.Validate("Statement Amount", Amount);
        BankAccReconciliationLine.Modify(true);
    end;

    local procedure CreateAndPostSalesInvoice(var GenJournalLine: Record "Gen. Journal Line"; CustomerNo: Code[20]; DocNo: Code[20]; ExtDocNo: Code[20]; Amount: Decimal)
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Customer, CustomerNo, Amount);

        GenJournalLine."Document No." := DocNo;
        GenJournalLine."External Document No." := ExtDocNo;
        GenJournalLine.Modify();

        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndPostPurchaseInvoice(var GenJournalLine: Record "Gen. Journal Line"; VendorNo: Code[20]; DocNo: Code[20]; ExtDocNo: Code[20]; Amount: Decimal)
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Vendor, VendorNo, -Amount);

        GenJournalLine."Document No." := DocNo;
        GenJournalLine."External Document No." := ExtDocNo;
        GenJournalLine.Modify();

        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure MockDirectDebitCollectionEntry(var DirectDebitCollectionEntry: Record "Direct Debit Collection Entry"; BankAccountNo: Code[20]; CustLedgerEntryNo: Integer; DDCollectionStatus: Option; DDCollectionEntryStatus: Option)
    var
        DirectDebitCollection: Record "Direct Debit Collection";
    begin
        DirectDebitCollection.Init();
        DirectDebitCollection."No." := LibraryUtility.GetNewRecNo(DirectDebitCollection, DirectDebitCollection.FieldNo("No."));
        DirectDebitCollection.Identifier := LibraryUtility.GenerateGUID();
        DirectDebitCollection.Status := DDCollectionStatus;
        DirectDebitCollection."To Bank Account No." := BankAccountNo;
        DirectDebitCollection.Insert();

        DirectDebitCollectionEntry.Init();
        DirectDebitCollectionEntry."Direct Debit Collection No." := DirectDebitCollection."No.";
        DirectDebitCollectionEntry."Entry No." := LibraryUtility.GetNewRecNo(DirectDebitCollectionEntry, DirectDebitCollectionEntry.FieldNo("Entry No."));
        DirectDebitCollectionEntry."Applies-to Entry No." := CustLedgerEntryNo;
        DirectDebitCollectionEntry."Transaction ID" := DirectDebitCollection.Identifier + '/' + Format(DirectDebitCollectionEntry."Entry No.");
        DirectDebitCollectionEntry.Status := DDCollectionEntryStatus;
        DirectDebitCollectionEntry.Insert();
    end;

    local procedure InsertDefaultMatchingRules()
    var
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
    begin
        BankPmtApplRule.DeleteAll();
        BankPmtApplRule.InsertDefaultMatchingRules();
    end;

    local procedure SetRule(var BankPmtApplRule: Record "Bank Pmt. Appl. Rule"; RelatedPartyMatched: Option; DocNoMatched: Option; AmountInclToleranceMatched: Option; DirectDebitCollectMatched: Option)
    begin
        BankPmtApplRule.Init();
        BankPmtApplRule."Related Party Matched" := RelatedPartyMatched;
        BankPmtApplRule."Doc. No./Ext. Doc. No. Matched" := DocNoMatched;
        BankPmtApplRule."Amount Incl. Tolerance Matched" := AmountInclToleranceMatched;
        BankPmtApplRule."Direct Debit Collect. Matched" := DirectDebitCollectMatched;
    end;

    local procedure RunMatch(BankAccReconciliation: Record "Bank Acc. Reconciliation"; var TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary; ApplyEntries: Boolean)
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        MatchBankPayments: Codeunit "Match Bank Payments";
    begin
        if ApplyEntries then
            LibraryVariableStorage.Enqueue('are applied');

        BankAccReconciliationLine.SetRange("Statement Type", BankAccReconciliation."Statement Type");
        BankAccReconciliationLine.SetRange("Statement No.", BankAccReconciliation."Statement No.");
        BankAccReconciliationLine.SetRange("Bank Account No.", BankAccReconciliation."Bank Account No.");
        BankAccReconciliationLine.FindFirst();
        MatchBankPayments.SetApplyEntries(ApplyEntries);
        MatchBankPayments.Run(BankAccReconciliationLine);

        MatchBankPayments.GetBankStatementMatchingBuffer(TempBankStatementMatchingBuffer);
    end;

    local procedure VerifyReconciliation(ExpectedBankPmtApplRule: Record "Bank Pmt. Appl. Rule"; var TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary; StatementLineNo: Integer)
    var
        TempBankPmtApplRule: Record "Bank Pmt. Appl. Rule" temporary;
        Score: Integer;
    begin
        TempBankPmtApplRule.LoadRules();
        Score := TempBankPmtApplRule.GetBestMatchScore(ExpectedBankPmtApplRule);

        TempBankStatementMatchingBuffer.Reset();
        TempBankStatementMatchingBuffer.SetRange("Line No.", StatementLineNo);
        TempBankStatementMatchingBuffer.SetRange(Quality, Score);
        Assert.RecordIsNotEmpty(TempBankStatementMatchingBuffer);

        TempBankStatementMatchingBuffer.SetFilter(Quality, '>%1', Score);
        Assert.RecordIsEmpty(TempBankStatementMatchingBuffer);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    var
        ExpectedMsg: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMsg);
        Assert.IsTrue(StrPos(Message, ExpectedMsg) > 0, Message);
    end;
}

