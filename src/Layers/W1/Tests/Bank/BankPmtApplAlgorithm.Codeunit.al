codeunit 134261 "Bank Pmt. Appl. Algorithm"
{
    Permissions = TableData "Cust. Ledger Entry" = imd,
                  TableData "Vendor Ledger Entry" = imd,
                  TableData "Bank Account Ledger Entry" = imd;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Bank Payment Application] [Match]
    end;

    var
        TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary;
        TempBankPmtApplRule: Record "Bank Pmt. Appl. Rule" temporary;
        ZeroVATPostingSetup: Record "VAT Posting Setup";
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;
        LinesAreAppliedTxt: Label 'are applied';
        RandomizeCount: Integer;
        AvailableCharacters: Label 'abcdefghijklmnopqrstuvwxyz0123456789', Locked = true;
        ShortNameToExcludFromMatching: Label 'aaa', Locked = true;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestNoMatchFoundCustomerEntries()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
        Amount: Decimal;
        ExtDocNo: Code[20];
    begin
        Initialize();

        // Setup
        CreateCustomer(Customer);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        ExtDocNo := '';
        CreateAndPostSalesInvoiceWithOneLine(Customer."No.", ExtDocNo, Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, Amount / 2, '', '');

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        VerifyNoMatch(BankAccReconciliationLine."Statement Line No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestNoMatchRulesAreIncludedInProposals()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
        ExtDocNo: Code[20];
    begin
        Initialize();

        // Setup
        CreateCustomer(Customer);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        ExtDocNo := '';
        CreateAndPostSalesInvoiceWithOneLine(Customer."No.", ExtDocNo, Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, Amount / 2, '', '');

        // Exercise
        RunMatch(BankAccReconciliation, false);

        // Verify
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No, BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");

        VerifyReconciliation(BankPmtApplRule, BankAccReconciliationLine."Statement Line No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCustNoMatchOutsideThreshold()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
        Amount: Decimal;
        Tolerance: Decimal;
        ExtDocNo: Code[20];
    begin
        Initialize();

        // Setup
        CreateCustomer(Customer);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        Tolerance := Round(Amount / 4, 0.01);
        ExtDocNo := '';
        CreateAndPostSalesInvoiceWithOneLine(Customer."No.", ExtDocNo, Amount + Tolerance + 0.01);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, Tolerance);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, Amount, '', '');

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        VerifyNoMatch(BankAccReconciliationLine."Statement Line No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,VerifyMatchDetailsOnPaymentApplicationsPage')]
    [Scope('OnPrem')]
    procedure TestCustSingleAmountMatch()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
        ExtDocNo: Code[20];
    begin
        Initialize();

        // Setup
        CreateCustomer(Customer);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        ExtDocNo := '';
        CreateAndPostSalesInvoiceWithOneLine(Customer."No.", ExtDocNo, Amount);
        CreateAndPostSalesInvoiceWithOneLine(Customer."No.", ExtDocNo, Amount + 1);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, Amount, '', '');

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No, BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match");
        VerifyReconciliation(BankPmtApplRule, BankAccReconciliationLine."Statement Line No.");
        VerifyMatchDetailsData(
          BankAccReconciliation, BankPmtApplRule, BankAccReconciliationLine."Account Type"::Customer, Amount, 0, 1, 1);
    end;


    [Test]
    [HandlerFunctions('MessageHandler,VerifyPaymentApplicationPageWithDisableSuggestions')]
    [Scope('OnPrem')]
    procedure TestCustNoMatchCustLegerEntriesDisabled()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
        BankPmtApplSettings: Record "Bank Pmt. Appl. Settings";
        PaymentReconciliationJournal: TestPage "Payment Reconciliation Journal";
        Amount: Decimal;
        ExtDocNo: Code[20];
    begin
        Initialize();

        // Setup
        BankPmtApplSettings.GetOrInsert();
        BankPmtApplSettings."Cust. Ledger Entries Matching" := false;
        BankPmtApplSettings.Modify();
        CreateCustomer(Customer);

        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        ExtDocNo := '';
        CreateAndPostSalesInvoiceWithOneLine(Customer."No.", ExtDocNo, Amount);
        CreateAndPostSalesInvoiceWithOneLine(Customer."No.", ExtDocNo, Amount + 1);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, Amount, '', '');

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        VerifyNoMatch(BankAccReconciliationLine."Statement Line No.");

        // Verify Apply manually still shows entries
        LibraryVariableStorage.Enqueue(Format(TempBankPmtApplRule."Match Confidence"::None));
        PaymentReconciliationJournal.OpenEdit();
        PaymentReconciliationJournal.GoToRecord(BankAccReconciliationLine);
        PaymentReconciliationJournal.ApplyEntries.Invoke();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,VerifyMatchDetailsOnPaymentApplicationsPage')]
    [Scope('OnPrem')]
    procedure TestCustSingleAmountMatchWithAmountToleranceLowerRange()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
        Tolerance: Decimal;
        ExtDocNo: Code[20];
    begin
        Initialize();

        // Setup
        CreateCustomer(Customer);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        ExtDocNo := '';
        Tolerance := Round(Amount / 4, 0.01);
        CreateAndPostSalesInvoiceWithOneLine(Customer."No.", ExtDocNo, Amount + Tolerance);
        CreateAndPostSalesInvoiceWithOneLine(Customer."No.", ExtDocNo, Amount + 5 * Tolerance);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, Tolerance);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, Amount, '', '');

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No, BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match");
        VerifyReconciliation(BankPmtApplRule, BankAccReconciliationLine."Statement Line No.");
        VerifyMatchDetailsData(
          BankAccReconciliation, BankPmtApplRule, BankAccReconciliationLine."Account Type"::Customer, Amount, Tolerance, 1, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,VerifyMatchDetailsOnPaymentApplicationsPage')]
    [Scope('OnPrem')]
    procedure TestCustSingleAmountMatchWithAmountToleranceHigherRange()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
        Tolerance: Decimal;
        ExtDocNo: Code[20];
    begin
        Initialize();

        // Setup
        CreateCustomer(Customer);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        ExtDocNo := '';
        Tolerance := Round(Amount / 4, 0.01);
        CreateAndPostSalesInvoiceWithOneLine(Customer."No.", ExtDocNo, Amount + Tolerance);
        CreateAndPostSalesInvoiceWithOneLine(Customer."No.", ExtDocNo, Amount + 5 * Tolerance);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, Tolerance);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, Amount + 2 * Tolerance, '', '');

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No, BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match");
        VerifyReconciliation(BankPmtApplRule, BankAccReconciliationLine."Statement Line No.");
        VerifyMatchDetailsData(
          BankAccReconciliation, BankPmtApplRule, BankAccReconciliationLine."Account Type"::Customer, Amount, Tolerance, 1, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,VerifyMatchDetailsOnPaymentApplicationsPage')]
    [Scope('OnPrem')]
    procedure TestCustSingleAmountMatchWithAmountPercentageTolerance()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        TempBankPmtApplRule: Record "Bank Pmt. Appl. Rule" temporary;
        BankAccount: Record "Bank Account";
        Amount: Decimal;
        Tolerance: Decimal;
        ExtDocNo: Code[20];
    begin
        Initialize();

        // Setup
        CreateCustomer(Customer);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        ExtDocNo := '';
        Tolerance := LibraryRandom.RandDecInRange(1, 99, 1);
        CreateAndPostSalesInvoiceWithOneLine(Customer."No.", ExtDocNo, Round(Amount / (1 + Tolerance / 100)));
        CreateAndPostSalesInvoiceWithOneLine(Customer."No.", ExtDocNo, Amount + 5 * Tolerance);

        CreateBankReconciliationPercentageTolerance(BankAccReconciliation, Tolerance);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, Amount, '', '');

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No, BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match");
        VerifyReconciliation(BankPmtApplRule, BankAccReconciliationLine."Statement Line No.");

        TempBankPmtApplRule.LoadRules();
        TempBankPmtApplRule.GetBestMatchScore(BankPmtApplRule);
        BankPmtApplRule."Match Confidence" := TempBankPmtApplRule."Match Confidence";

        VerifyMatchDetailsData2(
          BankAccReconciliation, BankPmtApplRule, BankAccReconciliationLine."Account Type"::Customer, Amount,
          Tolerance, BankAccount."Match Tolerance Type"::Percentage, 1, 1, false, -1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,VerifyMatchDetailsOnPaymentApplicationsPage')]
    [Scope('OnPrem')]
    procedure TestCustMultipleAmountMatch()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
        ExtDocNo: Code[20];
    begin
        Initialize();

        // Setup
        CreateCustomer(Customer);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        ExtDocNo := '';
        CreateAndPostSalesInvoiceWithOneLine(Customer."No.", ExtDocNo, Amount);
        CreateAndPostSalesInvoiceWithOneLine(Customer."No.", ExtDocNo, Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, Amount, '', '');

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No, BankPmtApplRule."Amount Incl. Tolerance Matched"::"Multiple Matches");
        VerifyReconciliation(BankPmtApplRule, BankAccReconciliationLine."Statement Line No.");
        VerifyMatchDetailsData(
          BankAccReconciliation, BankPmtApplRule, BankAccReconciliationLine."Account Type"::Customer, Amount, 0, 2, 0);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,VerifyMatchDetailsOnPaymentApplicationsPage')]
    [Scope('OnPrem')]
    procedure TestCustMultipleAmountMatchWithAmountTolerance()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
        Tolerance: Decimal;
        ExtDocNo: Code[20];
    begin
        Initialize();

        // Setup
        CreateCustomer(Customer);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        ExtDocNo := '';
        Tolerance := Round(Amount / 4, 0.01);
        CreateAndPostSalesInvoiceWithOneLine(Customer."No.", ExtDocNo, Amount + Tolerance);
        CreateAndPostSalesInvoiceWithOneLine(Customer."No.", ExtDocNo, Amount + Tolerance / 3);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, Tolerance);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, Amount, '', '');

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No, BankPmtApplRule."Amount Incl. Tolerance Matched"::"Multiple Matches");
        VerifyReconciliation(BankPmtApplRule, BankAccReconciliationLine."Statement Line No.");
        VerifyMatchDetailsData(BankAccReconciliation, BankPmtApplRule,
          BankAccReconciliationLine."Account Type"::Customer, Amount, Tolerance, 2, 0);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,VerifyMatchDetailsOnPaymentApplicationsPage')]
    [Scope('OnPrem')]
    procedure TestCustDoctInTransTextMatch()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
        DocumentNo: Code[20];
        ExtDocNo: Code[20];
    begin
        Initialize();

        // Setup
        CreateCustomer(Customer);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        ExtDocNo := '';
        DocumentNo := CreateAndPostSalesInvoiceWithOneLine(Customer."No.", ExtDocNo, Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, Amount / 2, DocumentNo, '');

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes, BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");
        VerifyReconciliation(BankPmtApplRule, BankAccReconciliationLine."Statement Line No.");
        VerifyMatchDetailsData(BankAccReconciliation, BankPmtApplRule,
          BankAccReconciliationLine."Account Type"::Customer, Amount / 2, 0, 0, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,VerifyMatchDetailsOnPaymentApplicationsPage')]
    [Scope('OnPrem')]
    procedure TestCustDocInAdditionalTextMatch()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
        DocumentNo: Code[20];
        ExtDocNo: Code[20];
    begin
        Initialize();

        // Setup
        CreateCustomer(Customer);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        ExtDocNo := '';
        DocumentNo := CreateAndPostSalesInvoiceWithOneLine(Customer."No.", ExtDocNo, Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, Amount / 2, '', DocumentNo);

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes, BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");
        VerifyReconciliation(BankPmtApplRule, BankAccReconciliationLine."Statement Line No.");
        VerifyMatchDetailsData(BankAccReconciliation, BankPmtApplRule,
          BankAccReconciliationLine."Account Type"::Customer, Amount / 2, 0, 0, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,VerifyMatchDetailsOnPaymentApplicationsPage')]
    [Scope('OnPrem')]
    procedure TestCustExtDocAndDocMatch()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
        DocumentNo: Code[20];
        ExtDocNo: Code[20];
    begin
        Initialize();

        // Setup
        CreateCustomer(Customer);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        ExtDocNo := GenerateExtDocNo();
        DocumentNo := CreateAndPostSalesInvoiceWithOneLine(Customer."No.", ExtDocNo, Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, Amount / 2, ExtDocNo, DocumentNo);

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes, BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");
        VerifyReconciliation(BankPmtApplRule, BankAccReconciliationLine."Statement Line No.");
        VerifyMatchDetailsData(
          BankAccReconciliation, BankPmtApplRule, BankAccReconciliationLine."Account Type"::Customer, Amount / 2, 0, 0, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCustNoMatchExtDocAndDocNoTrailingChar()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
        Amount: Decimal;
        DocumentNo: Code[20];
        ExtDocNo: Code[20];
    begin
        Initialize();

        // Setup
        CreateCustomer(Customer);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        ExtDocNo := GenerateExtDocNo();
        DocumentNo := CreateAndPostSalesInvoiceWithOneLine(Customer."No.", ExtDocNo, Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, Amount / 2,
          ExtDocNo + GenerateRandomSmallLetters(1), GenerateRandomSmallLetters(1) + DocumentNo);

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        VerifyNoMatch(BankAccReconciliationLine."Statement Line No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCustNoMatchExtDocAndDocNoTrailingDigit()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
        Amount: Decimal;
        DocumentNo: Code[20];
        ExtDocNo: Code[20];
    begin
        Initialize();

        // Setup
        CreateCustomer(Customer);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        ExtDocNo := GenerateExtDocNo();
        DocumentNo := CreateAndPostSalesInvoiceWithOneLine(Customer."No.", ExtDocNo, Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, Amount / 2,
          ExtDocNo + GenerateRandomSmallLetters(1), GenerateRandomSmallLetters(1) + DocumentNo);

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        VerifyNoMatch(BankAccReconciliationLine."Statement Line No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,VerifyMatchDetailsOnPaymentApplicationsPage')]
    [Scope('OnPrem')]
    procedure TestCustNoMatchExtDocAndDocTrailingWithNonAlphaAndChar()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
        DocumentNo: Code[20];
        ExtDocNo: Code[20];
    begin
        Initialize();

        // Setup
        CreateCustomer(Customer);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        ExtDocNo := GenerateExtDocNo();
        DocumentNo := CreateAndPostSalesInvoiceWithOneLine(Customer."No.", ExtDocNo, Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, Amount / 2,
          ExtDocNo + ',' + GenerateRandomSmallLetters(1), GenerateRandomSmallLetters(1) + ',' + DocumentNo);

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes, BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");
        VerifyReconciliation(BankPmtApplRule, BankAccReconciliationLine."Statement Line No.");
        VerifyMatchDetailsData(
          BankAccReconciliation, BankPmtApplRule, BankAccReconciliationLine."Account Type"::Customer, Amount / 2, 0, 0, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,VerifyMatchDetailsOnPaymentApplicationsPage')]
    [Scope('OnPrem')]
    procedure TestCustNoMatchExtDocAndDocTrailingWithNonAlphaAndDigit()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
        DocumentNo: Code[20];
        ExtDocNo: Code[20];
    begin
        Initialize();

        // Setup
        CreateCustomer(Customer);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        ExtDocNo := GenerateExtDocNo();
        DocumentNo := CreateAndPostSalesInvoiceWithOneLine(Customer."No.", ExtDocNo, Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, Amount / 2,
          ExtDocNo + ',' + Format(LibraryRandom.RandInt(9)),
          Format(LibraryRandom.RandInt(9)) + ',' + DocumentNo);

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes, BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");
        VerifyReconciliation(BankPmtApplRule, BankAccReconciliationLine."Statement Line No.");
        VerifyMatchDetailsData(
          BankAccReconciliation, BankPmtApplRule, BankAccReconciliationLine."Account Type"::Customer, Amount / 2, 0, 0, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCustNotMatchExtDocTooShort()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
        Amount: Decimal;
        ExtDocNo: Code[20];
    begin
        Initialize();

        // Setup
        CreateCustomer(Customer);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        ExtDocNo := CopyStr(GenerateExtDocNo(), 1, 3);
        CreateAndPostSalesInvoiceWithOneLine(Customer."No.", ExtDocNo, Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, Amount / 2, ExtDocNo, '');

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        VerifyNoMatch(BankAccReconciliationLine."Statement Line No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,VerifyMatchDetailsOnPaymentApplicationsPage')]
    [Scope('OnPrem')]
    procedure TestCustDocAndSingleAmountMatch()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
        DocumentNo: Code[20];
        ExtDocNo: Code[20];
    begin
        Initialize();

        // Setup
        CreateCustomer(Customer);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        ExtDocNo := GenerateExtDocNo();
        DocumentNo := CreateAndPostSalesInvoiceWithOneLine(Customer."No.", ExtDocNo, Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, Amount, ExtDocNo, DocumentNo);

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes, BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match");
        VerifyReconciliation(BankPmtApplRule, BankAccReconciliationLine."Statement Line No.");
        VerifyMatchDetailsData(
          BankAccReconciliation, BankPmtApplRule, BankAccReconciliationLine."Account Type"::Customer, Amount, 0, 1, 0);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,VerifyMatchDetailsOnPaymentApplicationsPage')]
    [Scope('OnPrem')]
    procedure TestCustDocAndMultipleAmountMatch()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
        DocumentNo: Code[20];
        ExtDocNo: Code[20];
    begin
        Initialize();

        // Setup
        CreateCustomer(Customer);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        ExtDocNo := GenerateExtDocNo();
        DocumentNo := CreateAndPostSalesInvoiceWithOneLine(Customer."No.", ExtDocNo, Amount);
        CreateAndPostSalesInvoiceWithOneLine(Customer."No.", ExtDocNo, Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, Amount, '', DocumentNo);

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes, BankPmtApplRule."Amount Incl. Tolerance Matched"::"Multiple Matches");
        VerifyReconciliation(BankPmtApplRule, BankAccReconciliationLine."Statement Line No.");
        VerifyMatchDetailsData(
          BankAccReconciliation, BankPmtApplRule, BankAccReconciliationLine."Account Type"::Customer, Amount, 0, 2, 0);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,VerifyMatchDetailsOnPaymentApplicationsPage')]
    [Scope('OnPrem')]
    procedure TestCustMatchOnBankAccountOnly()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        CustomerBankAccount: Record "Customer Bank Account";
        Amount: Decimal;
    begin
        Initialize();

        // Setup
        CreateCustomer(Customer);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        CreateAndPostSalesInvoiceWithOneLine(Customer."No.", GenerateExtDocNo(), Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, Amount / 2, '', '');
        UpdateBankReconciliationLine(BankAccReconciliationLine, BankAccReconciliation."Bank Account No.", '', '', '');
        CreateCustomerBankAccount(CustomerBankAccount, Customer."No.", BankAccReconciliation."Bank Account No.");

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No, BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");
        VerifyReconciliation(BankPmtApplRule, BankAccReconciliationLine."Statement Line No.");
        VerifyMatchDetailsData(
          BankAccReconciliation, BankPmtApplRule, BankAccReconciliationLine."Account Type"::Customer, Amount / 2, 0, 0, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,VerifyMatchDetailsOnPaymentApplicationsPage')]
    [Scope('OnPrem')]
    procedure TestCustExactMatchOnRelatedPartyNameSingle()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
    begin
        Initialize();

        // Setup
        CreateCustomer(Customer);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        CreateAndPostSalesInvoiceWithOneLine(Customer."No.", GenerateExtDocNo(), Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, Amount / 2, '', '');
        UpdateBankReconciliationLine(BankAccReconciliationLine, '', Customer.Name, '', '');

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No, BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");
        VerifyReconciliation(BankPmtApplRule, BankAccReconciliationLine."Statement Line No.");
        VerifyMatchDetailsData(
          BankAccReconciliation, BankPmtApplRule, BankAccReconciliationLine."Account Type"::Customer, Amount / 2, 0, 0, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,VerifyMatchDetailsOnPaymentApplicationsPage')]
    [Scope('OnPrem')]
    procedure TestCustExactMatchOnRelatedPartyNameReversed()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
        FirstName: Text[20];
        LastName: Text[20];
    begin
        Initialize();

        // Setup
        CreateCustomer(Customer);
        FirstName := CopyStr(GenerateRandomSmallLetters(20), 1, 20);
        LastName := CopyStr(GenerateRandomSmallLetters(20), 1, 20);
        Customer.Validate(Name, StrSubstNo('%1 %2', FirstName, LastName));
        Customer.Modify(true);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        CreateAndPostSalesInvoiceWithOneLine(Customer."No.", GenerateExtDocNo(), Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, Amount / 2, '', '');
        UpdateBankReconciliationLine(BankAccReconciliationLine, '', StrSubstNo('%1 %2', LastName, FirstName), '', '');

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No, BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");
        VerifyReconciliation(BankPmtApplRule, BankAccReconciliationLine."Statement Line No.");
        VerifyMatchDetailsData(
          BankAccReconciliation, BankPmtApplRule, BankAccReconciliationLine."Account Type"::Customer, Amount / 2, 0, 0, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,VerifyMatchDetailsOnPaymentApplicationsPage')]
    [Scope('OnPrem')]
    procedure TestCustExactMatchOnRelatedPartyNameMultiple()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
        Customer1: Record Customer;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
    begin
        Initialize();

        // Setup
        CreateCustomer(Customer);
        CreateCustomer(Customer1);
        Customer1.Validate(Name, Customer.Name);
        Customer1.Modify(true);

        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        CreateAndPostSalesInvoiceWithOneLine(Customer."No.", GenerateExtDocNo(), Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, Amount / 2, '', '');
        UpdateBankReconciliationLine(BankAccReconciliationLine, '', Customer.Name, '', '');

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::Partially,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No, BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");
        VerifyReconciliation(BankPmtApplRule, BankAccReconciliationLine."Statement Line No.");
        VerifyMatchDetailsData(
          BankAccReconciliation, BankPmtApplRule, BankAccReconciliationLine."Account Type"::Customer, Amount / 2, 0, 0, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,VerifyMatchDetailsOnPaymentApplicationsPage')]
    [Scope('OnPrem')]
    procedure TestCustExactMatchOnRelatedPartyNameMultipleExactMatchOnCity()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
        Customer1: Record Customer;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
    begin
        Initialize();

        // Setup
        CreateCustomer(Customer);
        CreateCustomer(Customer1);
        Customer1.Validate(Name, Customer.Name);
        Customer1.Modify(true);

        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        CreateAndPostSalesInvoiceWithOneLine(Customer."No.", GenerateExtDocNo(), Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, Amount / 2, '', '');
        UpdateBankReconciliationLine(BankAccReconciliationLine, '', Customer.Name, '', Customer.City);

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::Partially,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No, BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");
        VerifyReconciliation(BankPmtApplRule, BankAccReconciliationLine."Statement Line No.");
        VerifyMatchDetailsData(
          BankAccReconciliation, BankPmtApplRule, BankAccReconciliationLine."Account Type"::Customer, Amount / 2, 0, 0, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,VerifyMatchDetailsOnPaymentApplicationsPage')]
    [Scope('OnPrem')]
    procedure TestCustExactMatchOnRelatedPartyNameMultipleExactMatchOnCityAndAddress()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
        Customer1: Record Customer;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
    begin
        Initialize();

        // Setup
        CreateCustomer(Customer);
        CreateCustomer(Customer1);
        Customer1.Validate(Name, Customer.Name);
        Customer1.Modify(true);

        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        CreateAndPostSalesInvoiceWithOneLine(Customer."No.", GenerateExtDocNo(), Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, Amount / 2, '', '');
        UpdateBankReconciliationLine(BankAccReconciliationLine, '', Customer.Name, Customer.Address, Customer.City);

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No, BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");
        VerifyReconciliation(BankPmtApplRule, BankAccReconciliationLine."Statement Line No.");
        VerifyMatchDetailsData(
          BankAccReconciliation, BankPmtApplRule, BankAccReconciliationLine."Account Type"::Customer, Amount / 2, 0, 0, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,VerifyMatchDetailsOnPaymentApplicationsPage')]
    [Scope('OnPrem')]
    procedure TestCustWithSpecialCharsInRelatedPartyNameExactMatchSingle()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
    begin
        Initialize();

        // Setup
        CreateCustomer(Customer);
        Customer.Name := GenerateRandomSmallLettersWithSpaces(50);
        Customer.Modify();
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        CreateAndPostSalesInvoiceWithOneLine(Customer."No.", GenerateExtDocNo(), Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, Amount / 2, '', '');
        UpdateBankReconciliationLine(BankAccReconciliationLine, '', Customer.Name, '', '');

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No, BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");
        VerifyReconciliation(BankPmtApplRule, BankAccReconciliationLine."Statement Line No.");
        VerifyMatchDetailsData(
          BankAccReconciliation, BankPmtApplRule, BankAccReconciliationLine."Account Type"::Customer, Amount / 2, 0, 0, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,VerifyMatchDetailsOnPaymentApplicationsPage')]
    [Scope('OnPrem')]
    procedure TestCustExactMatchOnOtherNameSingle()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
    begin
        Initialize();

        // Setup
        CreateCustomer(Customer);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        CreateAndPostSalesInvoiceWithOneLine(Customer."No.", GenerateExtDocNo(), Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, Amount / 2, Customer.Name, '');

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No, BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");
        VerifyReconciliation(BankPmtApplRule, BankAccReconciliationLine."Statement Line No.");
        VerifyMatchDetailsData(
          BankAccReconciliation, BankPmtApplRule, BankAccReconciliationLine."Account Type"::Customer, Amount / 2, 0, 0, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,VerifyMatchDetailsOnPaymentApplicationsPage')]
    [Scope('OnPrem')]
    procedure TestCustExactMatchOnOtherNameMultiple()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
        Customer1: Record Customer;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
    begin
        Initialize();

        // Setup
        CreateCustomer(Customer);
        CreateCustomer(Customer1);
        Customer1.Validate(Name, Customer.Name);
        Customer1.Modify(true);

        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        CreateAndPostSalesInvoiceWithOneLine(Customer."No.", GenerateExtDocNo(), Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, Amount / 2, Customer.Name, '');

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::Partially,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No, BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");
        VerifyReconciliation(BankPmtApplRule, BankAccReconciliationLine."Statement Line No.");
        VerifyMatchDetailsData(
          BankAccReconciliation, BankPmtApplRule, BankAccReconciliationLine."Account Type"::Customer, Amount / 2, 0, 0, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,VerifyMatchDetailsOnPaymentApplicationsPage')]
    [Scope('OnPrem')]
    procedure TestCustCloseMatchOnOtherNameSingle()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
    begin
        Initialize();

        // Setup
        CreateCustomer(Customer);

        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        CreateAndPostSalesInvoiceWithOneLine(Customer."No.", GenerateExtDocNo(), Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, Amount / 2,
          CopyStr(Customer.Name, 1, StrLen(Customer.Name) - 1), '');

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No, BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");
        VerifyReconciliation(BankPmtApplRule, BankAccReconciliationLine."Statement Line No.");
        VerifyMatchDetailsData(
          BankAccReconciliation, BankPmtApplRule, BankAccReconciliationLine."Account Type"::Customer, Amount / 2, 0, 0, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,VerifyMatchDetailsOnPaymentApplicationsPage')]
    [Scope('OnPrem')]
    procedure TestCustCloseMatchOnOtherNameMultiple()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
        Customer1: Record Customer;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
    begin
        Initialize();

        // Setup
        CreateCustomer(Customer);
        CreateCustomer(Customer1);
        Customer1.Validate(Name, Customer.Name);
        Customer1.Modify(true);

        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        CreateAndPostSalesInvoiceWithOneLine(Customer."No.", GenerateExtDocNo(), Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, Amount / 2,
          CopyStr(Customer.Name, 1, StrLen(Customer.Name) - 1), '');

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::Partially,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No, BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");
        VerifyReconciliation(BankPmtApplRule, BankAccReconciliationLine."Statement Line No.");
        VerifyMatchDetailsData(
          BankAccReconciliation, BankPmtApplRule, BankAccReconciliationLine."Account Type"::Customer, Amount / 2, 0, 0, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,VerifyMatchDetailsOnPaymentApplicationsPage')]
    [Scope('OnPrem')]
    procedure TestCustPartialMatchOnOtherName()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        MatchBankPayments: Codeunit "Match Bank Payments";
        Amount: Decimal;
        Length: Integer;
    begin
        Initialize();

        // Setup
        CreateCustomer(Customer);

        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        CreateAndPostSalesInvoiceWithOneLine(Customer."No.", GenerateExtDocNo(), Amount);

        Length := Round(MatchBankPayments.GetExactMatchTreshold() / MatchBankPayments.GetNormalizingFactor() *
            StrLen(Customer.Name) + 1, 1);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, Amount / 2,
          GenerateRandomSmallLetters(StrLen(Customer.Name) - Length) + CopyStr(Customer.Name, 1, Length), '');

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No, BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");
        VerifyReconciliation(BankPmtApplRule, BankAccReconciliationLine."Statement Line No.");
        VerifyMatchDetailsData(
          BankAccReconciliation, BankPmtApplRule, BankAccReconciliationLine."Account Type"::Customer, Amount / 2, 0, 0, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,VerifyMatchDetailsOnPaymentApplicationsPage')]
    [Scope('OnPrem')]
    procedure TestCustomerMatchOnExactNameWithPermutations()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        BankPmtApplSettings: Record "Bank Pmt. Appl. Settings";
        Amount: Decimal;
    begin
        Initialize();

        // Setup
        BankPmtApplSettings.GetOrInsert();
        BankPmtApplSettings."RelatedParty Name Matching" := BankPmtApplSettings."RelatedParty Name Matching"::"Exact Match with Permutations";
        BankPmtApplSettings.Modify();

        CreateCustomer(Customer);
        Customer.Name := 'JohnName1 DoeName2 Name3John';
        Customer.Modify();

        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        CreateAndPostSalesInvoiceWithOneLine(Customer."No.", GenerateExtDocNo(), Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, Amount / 2,
          Customer.Name, '');

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No, BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");
        VerifyReconciliation(BankPmtApplRule, BankAccReconciliationLine."Statement Line No.");
        VerifyMatchDetailsData(
          BankAccReconciliation, BankPmtApplRule, BankAccReconciliationLine."Account Type"::Customer, Amount / 2, 0, 0, 1);
    end;


    [Test]
    [HandlerFunctions('MessageHandler,VerifyMatchDetailsOnPaymentApplicationsPage')]
    [Scope('OnPrem')]
    procedure TestCustomerMatchOnExactNameWithPermutationsNameFilpped()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        BankPmtApplSettings: Record "Bank Pmt. Appl. Settings";
        Amount: Decimal;
    begin
        Initialize();

        // Setup
        CreateCustomer(Customer);
        Customer.Name := 'FirstName1 MiddleName2 LastName3';
        Customer.Modify();

        BankPmtApplSettings.GetOrInsert();
        BankPmtApplSettings."RelatedParty Name Matching" := BankPmtApplSettings."RelatedParty Name Matching"::"Exact Match with Permutations";
        BankPmtApplSettings.Modify();

        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        CreateAndPostSalesInvoiceWithOneLine(Customer."No.", GenerateExtDocNo(), Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, Amount / 2,
          'MiddleName2 LastName3 FirstName1', '');

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No, BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");
        VerifyReconciliation(BankPmtApplRule, BankAccReconciliationLine."Statement Line No.");
        VerifyMatchDetailsData(
          BankAccReconciliation, BankPmtApplRule, BankAccReconciliationLine."Account Type"::Customer, Amount / 2, 0, 0, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,VerifyMatchDetailsOnPaymentApplicationsPage')]
    [Scope('OnPrem')]
    procedure TestCustomerMatchOnExactNameWithPermutationsNoMatch()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        BankPmtApplSettings: Record "Bank Pmt. Appl. Settings";
        Amount: Decimal;
    begin
        Initialize();

        // Setup
        BankPmtApplSettings.GetOrInsert();
        BankPmtApplSettings."RelatedParty Name Matching" := BankPmtApplSettings."RelatedParty Name Matching"::"Exact Match with Permutations";
        BankPmtApplSettings.Modify();

        CreateCustomer(Customer);

        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        CreateAndPostSalesInvoiceWithOneLine(Customer."No.", GenerateExtDocNo(), Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, Amount / 2,
          'Payment for invoice x', '');

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No, BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");
        VerifyMatchDetailsData(
          BankAccReconciliation, BankPmtApplRule, BankAccReconciliationLine."Account Type"::Customer, Amount / 2, 0, 0, 1);
    end;

    [Test]
    [HandlerFunctions('VerifyPaymentApplicationPageWithDisableSuggestions')]
    [Scope('OnPrem')]
    procedure TestVerifyApplyManuallyPageWithSuggestionsTurnedOff()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
        BankPmtApplSettings: Record "Bank Pmt. Appl. Settings";
        PaymentReconciliationJournal: TestPage "Payment Reconciliation Journal";
        Amount: Decimal;
    begin
        Initialize();

        // Setup
        BankPmtApplSettings.GetOrInsert();
        BankPmtApplSettings."Apply Man. Disable Suggestions" := true;
        BankPmtApplSettings.Modify();

        CreateCustomer(Customer);

        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        CreateAndPostSalesInvoiceWithOneLine(Customer."No.", GenerateExtDocNo(), Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, Amount,
          Customer.Name, '');

        PaymentReconciliationJournal.OpenEdit();
        PaymentReconciliationJournal.GoToRecord(BankAccReconciliationLine);

        // Exercise
        LibraryVariableStorage.Enqueue(Format(TempBankPmtApplRule."Match Confidence"::High));
        PaymentReconciliationJournal.ApplyEntries.Invoke();

        // Verify is done in the modal handler
    end;

    [Test]
    [HandlerFunctions('MessageHandler,VerifyMatchDetailsOnPaymentApplicationsPage')]
    [Scope('OnPrem')]
    procedure TestCustCertainAndMultipleAmountMatch()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        CustomerBankAccount: Record "Customer Bank Account";
        Amount: Decimal;
    begin
        Initialize();

        // Setup
        CreateCustomer(Customer);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        CreateAndPostSalesInvoiceWithOneLine(Customer."No.", GenerateExtDocNo(), Amount);
        CreateAndPostSalesInvoiceWithOneLine(Customer."No.", GenerateExtDocNo(), Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, Amount, '', '');
        UpdateBankReconciliationLine(BankAccReconciliationLine, BankAccReconciliation."Bank Account No.", '', '', '');
        CreateCustomerBankAccount(CustomerBankAccount, Customer."No.", BankAccReconciliation."Bank Account No.");

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No, BankPmtApplRule."Amount Incl. Tolerance Matched"::"Multiple Matches");
        VerifyReconciliation(BankPmtApplRule, BankAccReconciliationLine."Statement Line No.");
        VerifyMatchDetailsData(
          BankAccReconciliation, BankPmtApplRule, BankAccReconciliationLine."Account Type"::Customer, Amount, 0, 2, 0);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,VerifyMatchDetailsOnPaymentApplicationsPage')]
    [Scope('OnPrem')]
    procedure TestCustCertainAndSingleAmountMatch()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        CustomerBankAccount: Record "Customer Bank Account";
        Amount: Decimal;
    begin
        Initialize();

        // Setup
        CreateCustomer(Customer);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        CreateAndPostSalesInvoiceWithOneLine(Customer."No.", GenerateExtDocNo(), Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, Amount, '', '');
        UpdateBankReconciliationLine(BankAccReconciliationLine, BankAccReconciliation."Bank Account No.", '', '', '');
        CreateCustomerBankAccount(CustomerBankAccount, Customer."No.", BankAccReconciliation."Bank Account No.");

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No, BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match");
        VerifyReconciliation(BankPmtApplRule, BankAccReconciliationLine."Statement Line No.");
        VerifyMatchDetailsData(
          BankAccReconciliation, BankPmtApplRule, BankAccReconciliationLine."Account Type"::Customer, Amount, 0, 1, 0);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,VerifyMatchDetailsOnPaymentApplicationsPage')]
    [Scope('OnPrem')]
    procedure TestCustCertainMatchAndDocNo()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        DocumentNo: Code[20];
        Amount: Decimal;
    begin
        Initialize();

        // Setup
        CreateCustomer(Customer);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        DocumentNo := CreateAndPostSalesInvoiceWithOneLine(Customer."No.", GenerateExtDocNo(), Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, Amount / 2, DocumentNo, '');
        UpdateBankReconciliationLine(BankAccReconciliationLine, '', Customer.Name, '', '');

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes, BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");
        VerifyReconciliation(BankPmtApplRule, BankAccReconciliationLine."Statement Line No.");
        VerifyMatchDetailsData(
          BankAccReconciliation, BankPmtApplRule, BankAccReconciliationLine."Account Type"::Customer, Amount / 2, 0, 0, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,VerifyMatchDetailsOnPaymentApplicationsPage')]
    [Scope('OnPrem')]
    procedure TestCustCertainMatchAndExtDocNo()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
        ExtDocNo: Code[20];
    begin
        Initialize();

        // Setup
        CreateCustomer(Customer);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        ExtDocNo := GenerateExtDocNo();
        CreateAndPostSalesInvoiceWithOneLine(Customer."No.", ExtDocNo, Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, Amount / 2, '', ExtDocNo);
        UpdateBankReconciliationLine(BankAccReconciliationLine, '', Customer.Name, '', '');

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes, BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");
        VerifyReconciliation(BankPmtApplRule, BankAccReconciliationLine."Statement Line No.");
        VerifyMatchDetailsData(
          BankAccReconciliation, BankPmtApplRule, BankAccReconciliationLine."Account Type"::Customer, Amount / 2, 0, 0, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,VerifyMatchDetailsOnPaymentApplicationsPage')]
    [Scope('OnPrem')]
    procedure TestCustCertainMatchAndDocNoAndAmount()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
        DocumentNo: Code[20];
        ExtDocNo: Code[20];
    begin
        Initialize();

        // Setup
        CreateCustomer(Customer);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        ExtDocNo := GenerateExtDocNo();
        DocumentNo := CreateAndPostSalesInvoiceWithOneLine(Customer."No.", ExtDocNo, Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, Amount, ExtDocNo, DocumentNo);
        UpdateBankReconciliationLine(BankAccReconciliationLine, '', Customer.Name, '', '');

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes, BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match");
        VerifyReconciliation(BankPmtApplRule, BankAccReconciliationLine."Statement Line No.");
        VerifyMatchDetailsData(
          BankAccReconciliation, BankPmtApplRule, BankAccReconciliationLine."Account Type"::Customer, Amount, 0, 1, 0);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,VerifyMatchDetailsOnPaymentApplicationsPage')]
    [Scope('OnPrem')]
    procedure TestCustCertainMatchAndDocNoAndAmountWithAmountTolerance()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
        DocumentNo: Code[20];
        ExtDocNo: Code[20];
        Tolerance: Decimal;
    begin
        Initialize();

        // Setup
        CreateCustomer(Customer);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        Tolerance := Round(Amount / 4, 0.01);
        ExtDocNo := GenerateExtDocNo();
        DocumentNo := CreateAndPostSalesInvoiceWithOneLine(Customer."No.", ExtDocNo, Amount - Tolerance);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, Tolerance);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, Amount, ExtDocNo, DocumentNo);
        UpdateBankReconciliationLine(BankAccReconciliationLine, '', Customer.Name, '', '');

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes, BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match");
        VerifyReconciliation(BankPmtApplRule, BankAccReconciliationLine."Statement Line No.");
        VerifyMatchDetailsData(
          BankAccReconciliation, BankPmtApplRule, BankAccReconciliationLine."Account Type"::Customer, Amount, Tolerance, 1, 0);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCustMatchCheckApplicationPriorities()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine1: Record "Bank Acc. Reconciliation Line";
        BankAccReconciliationLine2: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
        DocumentNo: Code[20];
        Amount: Decimal;
    begin
        Initialize();

        // Setup
        CreateCustomer(Customer);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        DocumentNo := CreateAndPostSalesInvoiceWithOneLine(Customer."No.", GenerateExtDocNo(), Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine1, Amount / 2, DocumentNo, '');
        UpdateBankReconciliationLine(BankAccReconciliationLine1, '', Customer.Name, '', '');
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine2, Amount / 2, DocumentNo, '');

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        VerifyEntryApplied(BankAccReconciliationLine1, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCustMatchCheckNoApplication()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine1: Record "Bank Acc. Reconciliation Line";
        BankAccReconciliationLine2: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
        DocumentNo: Code[20];
        Amount: Decimal;
    begin
        Initialize();

        // Setup
        CreateCustomer(Customer);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        DocumentNo := CreateAndPostSalesInvoiceWithOneLine(Customer."No.", GenerateExtDocNo(), Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine1, Amount / 2, DocumentNo, '');
        UpdateBankReconciliationLine(BankAccReconciliationLine1, '', Customer.Name, '', '');
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine2, Amount / 2, DocumentNo, '');

        // Exercise
        RunMatch(BankAccReconciliation, false);

        // Verify
        VerifyEntriesNotAppliedForStatement(BankAccReconciliation);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCustTextMapper()
    var
        TextToAccMapping: Record "Text-to-Account Mapping";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
        Amount: Decimal;
        TextMapper: Text[140];
    begin
        Initialize();

        // Setup
        CreateCustomer(Customer);
        TextMapper := GenerateTextToAccountMapping();
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        CreateAndPostSalesInvoiceWithOneLine(Customer."No.", GenerateExtDocNo(), Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, Amount * 2, TextMapper, '');

        // Exercise
        LibraryERM.CreateAccountMappingGLAccount(TextToAccMapping, TextMapper, LibraryERM.CreateGLAccountNo(), '');

        RunMatch(BankAccReconciliation, true);

        // Verify
        VerifyEntryApplied(BankAccReconciliationLine, true);
        VerifyTextEntryApplied(BankAccReconciliationLine."Statement Line No.");
    end;

    local procedure CustRerunTextMapper(RunFirst: Boolean; OtherLinesInTheJournal: Boolean)
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccReconciliationLine2: Record "Bank Acc. Reconciliation Line";
        BankAccReconciliationLine3: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
        PaymentReconciliationJournal: TestPage "Payment Reconciliation Journal";
        Amount: Decimal;
        TextMapper: Text[140];
        SalesInvoiceNo: Code[20];
    begin
        Initialize();

        // Setup
        CreateCustomer(Customer);
        TextMapper := GenerateTextToAccountMapping();
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        SalesInvoiceNo := CreateAndPostSalesInvoiceWithOneLine(Customer."No.", GenerateExtDocNo(), Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, Amount * 2, TextMapper, '');
        if OtherLinesInTheJournal then begin
            CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine2, Amount, Customer.Name, '');
            CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine3, Amount, SalesInvoiceNo, '');
        end;
        if RunFirst then begin
            RunMatch(BankAccReconciliation, true);

            // Partial verify
            VerifyNoMatch(BankAccReconciliationLine."Statement Line No.");
        end;

        // Exercise
        PaymentReconciliationJournal.Trap();
        OpenPaymentRecJournal(BankAccReconciliation);
        PaymentReconciliationJournal.AddMappingRule.Invoke();

        // Verify
        VerifyEntryApplied(BankAccReconciliationLine, true);
    end;

    [Test]
    [HandlerFunctions('TextMapperModalPageHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestCustRerunOnlyTextMapper()
    begin
        CustRerunTextMapper(false, false);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,TextMapperModalPageHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestCustRunAndRerunTextMapper()
    begin
        CustRerunTextMapper(true, true);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCustTextMapperOverriden()
    var
        TextToAccMapping: Record "Text-to-Account Mapping";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
        DocumentNo: Code[20];
        Amount: Decimal;
        TextMapper: Text[140];
    begin
        Initialize();

        // Setup
        CreateCustomer(Customer);
        TextMapper := GenerateTextToAccountMapping();
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        DocumentNo := CreateAndPostSalesInvoiceWithOneLine(Customer."No.", GenerateExtDocNo(), Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, Amount, TextMapper, DocumentNo);
        UpdateBankReconciliationLine(BankAccReconciliationLine, '', Customer.Name, '', '');

        // Exercise
        LibraryERM.CreateAccountMappingGLAccount(TextToAccMapping, TextMapper, LibraryERM.CreateGLAccountNo(), '');

        RunMatch(BankAccReconciliation, true);

        // Verify
        VerifyEntryApplied(BankAccReconciliationLine, false);
        VerifyTextEntryConsidered(BankAccReconciliationLine."Statement Line No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCustTextMapperToCustomer()
    var
        TextToAccMapping: Record "Text-to-Account Mapping";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
        Amount: Decimal;
        TextMapper: Text[140];
    begin
        Initialize();

        // Setup
        CreateCustomer(Customer);
        TextMapper := GenerateTextToAccountMapping();
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        CreateAndPostSalesInvoiceWithOneLine(Customer."No.", GenerateExtDocNo(), Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, Amount * 2, TextMapper, '');

        // Exercise
        LibraryERM.CreateAccountMappingCustomer(TextToAccMapping, TextMapper, Customer."No.");

        RunMatch(BankAccReconciliation, true);

        // Verify
        VerifyEntryApplied(BankAccReconciliationLine, true);
        VerifyTextEntryApplied(BankAccReconciliationLine."Statement Line No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCustomerFirstMatchOnDocumentNoInsertsMultipleMatchLine()
    var
        TempBankStmtMultipleMatchLine: Record "Bank Stmt Multiple Match Line" temporary;
        TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary;
        OneToManyTempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary;
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        TempLedgerEntryMatchingBuffer: Record "Ledger Entry Matching Buffer" temporary;
        Amount: Decimal;
        DocumentNo: Code[20];
        UsePaymentDiscounts: Boolean;
    begin
        Initialize();

        // Setup
        CreateCustomer(Customer);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        DocumentNo := CreateAndPostSalesInvoiceWithOneLine(Customer."No.", GenerateExtDocNo(), Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, Amount, '', DocumentNo);
        UpdateBankReconciliationLine(BankAccReconciliationLine, '', Customer.Name, '', '');

        GetCustLedgerEntry(CustLedgerEntry, Customer, DocumentNo);

        TempLedgerEntryMatchingBuffer.InsertFromCustomerLedgerEntry(CustLedgerEntry, true, UsePaymentDiscounts);
        CreateOneToManyBankStatementMatchingBufferLine(
          TempBankStatementMatchingBuffer, TempBankStmtMultipleMatchLine, TempLedgerEntryMatchingBuffer, BankAccReconciliationLine,
          TempBankStatementMatchingBuffer."Account Type"::Customer);

        // Verify
        GetOneToManyBankStatementMatchingBuffer(OneToManyTempBankStatementMatchingBuffer, TempBankStatementMatchingBuffer);
        VerifyOneToOneBankStatementMatchingBufferLine(TempBankStatementMatchingBuffer, CustLedgerEntry."Entry No.");
        VerifyOneToManyTempBankStatementMatchingBufferLine(
          TempBankStmtMultipleMatchLine, OneToManyTempBankStatementMatchingBuffer, 1, CustLedgerEntry."Remaining Amount");
        Assert.AreEqual(
          CustLedgerEntry."Entry No.", TempBankStmtMultipleMatchLine."Entry No.",
          'Entry no. was not set correctly on TempBankStmtMultipleMatchLine');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCustomerSecondMatchOnDocumentNoUpdatesMultipleMatchLine()
    var
        TempBankStmtMultipleMatchLine: Record "Bank Stmt Multiple Match Line" temporary;
        TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary;
        TempLedgerEntryMatchingBuffer: Record "Ledger Entry Matching Buffer" temporary;
        OneToManyTempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary;
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        Amount: Decimal;
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
        ExpectedNoOfLines: Integer;
        ExpectedRemainingAmount: Decimal;
        UsePaymentDiscounts: Boolean;
    begin
        Initialize();

        // Setup
        CreateCustomer(Customer);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        DocumentNo := CreateAndPostSalesInvoiceWithOneLine(Customer."No.", GenerateExtDocNo(), Amount);
        DocumentNo2 := CreateAndPostSalesInvoiceWithOneLine(Customer."No.", GenerateExtDocNo(), Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, Amount, '', DocumentNo + ' ' + DocumentNo2);
        UpdateBankReconciliationLine(BankAccReconciliationLine, '', Customer.Name, '', '');

        GetCustLedgerEntry(CustLedgerEntry, Customer, DocumentNo);
        GetCustLedgerEntry(CustLedgerEntry2, Customer, DocumentNo2);

        // Execute
        TempLedgerEntryMatchingBuffer.InsertFromCustomerLedgerEntry(CustLedgerEntry, true, UsePaymentDiscounts);
        CreateOneToManyBankStatementMatchingBufferLine(
          TempBankStatementMatchingBuffer, TempBankStmtMultipleMatchLine, TempLedgerEntryMatchingBuffer, BankAccReconciliationLine,
          TempBankStatementMatchingBuffer."Account Type"::Customer);

        TempLedgerEntryMatchingBuffer.InsertFromCustomerLedgerEntry(CustLedgerEntry2, true, UsePaymentDiscounts);
        CreateOneToManyBankStatementMatchingBufferLine(
          TempBankStatementMatchingBuffer, TempBankStmtMultipleMatchLine, TempLedgerEntryMatchingBuffer, BankAccReconciliationLine,
          TempBankStatementMatchingBuffer."Account Type"::Customer);

        // Verify
        VerifyOneToOneBankStatementMatchingBufferLine(TempBankStatementMatchingBuffer, CustLedgerEntry2."Entry No.");

        GetOneToManyBankStatementMatchingBuffer(OneToManyTempBankStatementMatchingBuffer, TempBankStatementMatchingBuffer);
        ExpectedNoOfLines := 2;
        ExpectedRemainingAmount := CustLedgerEntry."Remaining Amount" + CustLedgerEntry2."Remaining Amount";
        VerifyOneToManyTempBankStatementMatchingBufferLine(
          TempBankStmtMultipleMatchLine, OneToManyTempBankStatementMatchingBuffer, ExpectedNoOfLines, ExpectedRemainingAmount);

        Assert.AreEqual(
          CustLedgerEntry."Entry No.", TempBankStmtMultipleMatchLine."Entry No.",
          'Entry no. was not set correctly on TempBankStmtMultipleMatchLine');
        TempBankStmtMultipleMatchLine.Next();
        Assert.AreEqual(
          CustLedgerEntry2."Entry No.", TempBankStmtMultipleMatchLine."Entry No.",
          'Entry no. was not set correctly on TempBankStmtMultipleMatchLine');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCustomerMultipleMatchRuleIsNotCreatedForDifferentCustomers()
    var
        TempBankStmtMultipleMatchLine: Record "Bank Stmt Multiple Match Line" temporary;
        TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary;
        TempLedgerEntryMatchingBuffer: Record "Ledger Entry Matching Buffer" temporary;
        OneToManyTempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary;
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
        Customer2: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        Amount: Decimal;
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
        UsePaymentDiscounts: Boolean;
    begin
        Initialize();

        // Setup
        CreateCustomer(Customer);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        DocumentNo := CreateAndPostSalesInvoiceWithOneLine(Customer."No.", GenerateExtDocNo(), Amount);

        CreateCustomer(Customer2);
        DocumentNo2 := CreateAndPostSalesInvoiceWithOneLine(Customer2."No.", GenerateExtDocNo(), Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, Amount, '', DocumentNo + ' ' + DocumentNo2);
        UpdateBankReconciliationLine(BankAccReconciliationLine, '', Customer.Name, '', '');

        GetCustLedgerEntry(CustLedgerEntry, Customer, DocumentNo);
        GetCustLedgerEntry(CustLedgerEntry2, Customer2, DocumentNo2);

        // Execute

        TempLedgerEntryMatchingBuffer.InsertFromCustomerLedgerEntry(CustLedgerEntry, true, UsePaymentDiscounts);
        CreateOneToManyBankStatementMatchingBufferLine(
          TempBankStatementMatchingBuffer, TempBankStmtMultipleMatchLine, TempLedgerEntryMatchingBuffer, BankAccReconciliationLine,
          TempBankStatementMatchingBuffer."Account Type"::Customer);

        TempLedgerEntryMatchingBuffer.InsertFromCustomerLedgerEntry(CustLedgerEntry2, true, UsePaymentDiscounts);
        CreateOneToManyBankStatementMatchingBufferLine(
          TempBankStatementMatchingBuffer, TempBankStmtMultipleMatchLine, TempLedgerEntryMatchingBuffer, BankAccReconciliationLine,
          TempBankStatementMatchingBuffer."Account Type"::Customer);

        // Verify First Entry
        GetOneToOneBankStatementMatchingBuffer(TempBankStatementMatchingBuffer, CustLedgerEntry."Entry No.");
        VerifyOneToOneBankStatementMatchingBufferLine(TempBankStatementMatchingBuffer, CustLedgerEntry."Entry No.");
        GetOneToManyBankStatementMatchingBuffer(OneToManyTempBankStatementMatchingBuffer, TempBankStatementMatchingBuffer);
        VerifyOneToManyTempBankStatementMatchingBufferLine(
          TempBankStmtMultipleMatchLine, OneToManyTempBankStatementMatchingBuffer, 1, CustLedgerEntry."Remaining Amount");
        Assert.AreEqual(
          CustLedgerEntry."Entry No.", TempBankStmtMultipleMatchLine."Entry No.",
          'Entry no. was not set correctly on TempBankStmtMultipleMatchLine');

        // Verify Second Entry
        GetOneToOneBankStatementMatchingBuffer(TempBankStatementMatchingBuffer, CustLedgerEntry2."Entry No.");
        GetOneToManyBankStatementMatchingBuffer(OneToManyTempBankStatementMatchingBuffer, TempBankStatementMatchingBuffer);
        VerifyOneToOneBankStatementMatchingBufferLine(TempBankStatementMatchingBuffer, CustLedgerEntry2."Entry No.");
        VerifyOneToManyTempBankStatementMatchingBufferLine(
          TempBankStmtMultipleMatchLine, OneToManyTempBankStatementMatchingBuffer, 1, CustLedgerEntry2."Remaining Amount");
        TempBankStmtMultipleMatchLine.Next();
        Assert.AreEqual(
          CustLedgerEntry2."Entry No.", TempBankStmtMultipleMatchLine."Entry No.",
          'Entry no. was not set correctly on TempBankStmtMultipleMatchLine');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCustomerMultipleMatchAllEntriesFullyApplied()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        AppliedPaymentEntry: Record "Applied Payment Entry";
        Amount: Decimal;
        Amount2: Decimal;
        AppliedAmount: Decimal;
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
        Difference: Decimal;
        ExpectedNoOfEntries: Integer;
        Quality: Integer;
    begin
        Initialize();

        // Setup
        CreateCustomer(Customer);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        DocumentNo := CreateAndPostSalesInvoiceWithOneLine(Customer."No.", GenerateExtDocNo(), Amount);

        Amount2 := LibraryRandom.RandDecInRange(1, 1000, 2);
        DocumentNo2 := CreateAndPostSalesInvoiceWithOneLine(Customer."No.", GenerateExtDocNo(), Amount2);

        AppliedAmount := Amount + Amount2;

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, AppliedAmount, '', DocumentNo + ' ' + DocumentNo2);
        UpdateBankReconciliationLine(BankAccReconciliationLine, '', Customer.Name, '', '');

        GetCustLedgerEntry(CustLedgerEntry, Customer, DocumentNo);
        GetCustLedgerEntry(CustLedgerEntry2, Customer, DocumentNo2);

        RunMatch(BankAccReconciliation, true);

        // Verify Bank Account ReconciliationLine
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Yes - Multiple",
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match");

        Difference := 0;
        ExpectedNoOfEntries := 2;

        Quality := TempBankPmtApplRule.GetBestMatchScore(BankPmtApplRule);
        VerifyMultipleApplicationsBankAccReconciliationLine(
          BankAccReconciliationLine, Quality, Difference, AppliedAmount, BankAccReconciliationLine."Account Type"::Customer, Customer."No.",
          ExpectedNoOfEntries);

        // Verify Applied Payment Entries
        GetAppliedPaymentEntries(AppliedPaymentEntry, BankAccReconciliationLine);
        Assert.AreEqual(AppliedPaymentEntry.Count, ExpectedNoOfEntries, 'Wrong number of Applied Payment Entries Found');
        AppliedPaymentEntry.FindFirst();
        VerifyMultipleApplicationsAppliedEntries(AppliedPaymentEntry, Quality, Amount, CustLedgerEntry."Entry No.");
        AppliedPaymentEntry.Next();
        VerifyMultipleApplicationsAppliedEntries(AppliedPaymentEntry, Quality, Amount2, CustLedgerEntry2."Entry No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCustomerMultipleMatchUserOverPaid()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        AppliedPaymentEntry: Record "Applied Payment Entry";
        Amount: Decimal;
        Amount2: Decimal;
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
        AppliedAmount: Decimal;
        StatementAmount: Decimal;
        Difference: Decimal;
        ExpectedNoOfEntries: Integer;
        Quality: Integer;
    begin
        Initialize();

        // Setup
        CreateCustomer(Customer);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        DocumentNo := CreateAndPostSalesInvoiceWithOneLine(Customer."No.", GenerateExtDocNo(), Amount);

        Amount2 := LibraryRandom.RandDecInRange(1, 1000, 2);
        DocumentNo2 := CreateAndPostSalesInvoiceWithOneLine(Customer."No.", GenerateExtDocNo(), Amount2);

        AppliedAmount := Amount + Amount2;
        StatementAmount := 2 * AppliedAmount;

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, StatementAmount, '', DocumentNo + ' ' + DocumentNo2);
        UpdateBankReconciliationLine(BankAccReconciliationLine, '', Customer.Name, '', '');

        GetCustLedgerEntry(CustLedgerEntry, Customer, DocumentNo);
        GetCustLedgerEntry(CustLedgerEntry2, Customer, DocumentNo2);

        RunMatch(BankAccReconciliation, true);

        // Verify Bank Account ReconciliationLine
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Yes - Multiple",
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");

        Difference := StatementAmount - AppliedAmount;
        ExpectedNoOfEntries := 2;
        Quality := TempBankPmtApplRule.GetBestMatchScore(BankPmtApplRule);

        VerifyMultipleApplicationsBankAccReconciliationLine(
          BankAccReconciliationLine, Quality, Difference, AppliedAmount, BankAccReconciliationLine."Account Type"::Customer, Customer."No.",
          ExpectedNoOfEntries);

        // Verify Applied Payment Entries
        GetAppliedPaymentEntries(AppliedPaymentEntry, BankAccReconciliationLine);
        Assert.AreEqual(AppliedPaymentEntry.Count, ExpectedNoOfEntries, 'Wrong number of Applied Payment Entries Found');
        AppliedPaymentEntry.FindFirst();
        VerifyMultipleApplicationsAppliedEntries(AppliedPaymentEntry, Quality, Amount, CustLedgerEntry."Entry No.");
        AppliedPaymentEntry.Next();
        VerifyMultipleApplicationsAppliedEntries(AppliedPaymentEntry, Quality, Amount2, CustLedgerEntry2."Entry No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCustomerMultipleMatchAllEntriesAppliedOneUnderPaid()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        AppliedPaymentEntry: Record "Applied Payment Entry";
        Amount: Decimal;
        Amount2: Decimal;
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
        AppliedAmount: Decimal;
        Difference: Decimal;
        ExpectedNoOfEntries: Integer;
        Quality: Integer;
    begin
        Initialize();

        // Setup
        CreateCustomer(Customer);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        DocumentNo := CreateAndPostSalesInvoiceWithOneLine(Customer."No.", GenerateExtDocNo(), Amount);

        Amount2 := LibraryRandom.RandDecInRange(1, 1000, 2);
        DocumentNo2 := CreateAndPostSalesInvoiceWithOneLine(Customer."No.", GenerateExtDocNo(), Amount2);

        AppliedAmount := Amount + Amount2 - Round(Amount2 / 2, LibraryERM.GetAmountRoundingPrecision());

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, AppliedAmount, '', DocumentNo + ' ' + DocumentNo2);
        UpdateBankReconciliationLine(BankAccReconciliationLine, '', Customer.Name, '', '');

        GetCustLedgerEntry(CustLedgerEntry, Customer, DocumentNo);
        GetCustLedgerEntry(CustLedgerEntry2, Customer, DocumentNo2);

        RunMatch(BankAccReconciliation, true);

        // Verify Bank Account ReconciliationLine
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Yes - Multiple",
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");

        Difference := 0;
        ExpectedNoOfEntries := 2;
        Quality := TempBankPmtApplRule.GetBestMatchScore(BankPmtApplRule);

        VerifyMultipleApplicationsBankAccReconciliationLine(
          BankAccReconciliationLine, Quality, Difference, AppliedAmount, BankAccReconciliationLine."Account Type"::Customer, Customer."No.",
          ExpectedNoOfEntries);

        // Verify Applied Payment Entries
        GetAppliedPaymentEntries(AppliedPaymentEntry, BankAccReconciliationLine);
        Assert.AreEqual(AppliedPaymentEntry.Count, ExpectedNoOfEntries, 'Wrong number of Applied Payment Entries Found');
        AppliedPaymentEntry.FindFirst();
        VerifyMultipleApplicationsAppliedEntries(AppliedPaymentEntry, Quality, Amount, CustLedgerEntry."Entry No.");
        AppliedPaymentEntry.Next();
        VerifyMultipleApplicationsAppliedEntries(
          AppliedPaymentEntry, Quality, Amount2 - Round(Amount2 / 2, LibraryERM.GetAmountRoundingPrecision()), CustLedgerEntry2."Entry No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCustomerMultipleMatchGetOverridenByHigherConfidenceOneToOneMatch()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        AppliedPaymentEntry: Record "Applied Payment Entry";
        Amount: Decimal;
        Amount2: Decimal;
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
        AppliedAmount: Decimal;
        Difference: Decimal;
        ExpectedNoOfEntries: Integer;
        Quality: Integer;
    begin
        Initialize();

        // Setup
        CreateCustomer(Customer);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        DocumentNo := CreateAndPostSalesInvoiceWithOneLine(Customer."No.", GenerateExtDocNo(), Amount);

        Amount2 := LibraryRandom.RandDecInRange(1, 1000, 2);
        DocumentNo2 := CreateAndPostSalesInvoiceWithOneLine(Customer."No.", GenerateExtDocNo(), Amount2);

        AppliedAmount := Amount;

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, AppliedAmount, '', DocumentNo + ' ' + DocumentNo2);
        UpdateBankReconciliationLine(BankAccReconciliationLine, '', Customer.Name, '', '');

        GetCustLedgerEntry(CustLedgerEntry, Customer, DocumentNo);

        RunMatch(BankAccReconciliation, true);

        // Verify Bank Account ReconciliationLine
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes, BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match");

        Difference := 0;
        ExpectedNoOfEntries := 1;
        Quality := TempBankPmtApplRule.GetBestMatchScore(BankPmtApplRule);

        VerifyMultipleApplicationsBankAccReconciliationLine(
          BankAccReconciliationLine, TempBankPmtApplRule.GetBestMatchScore(BankPmtApplRule), Difference, AppliedAmount,
          BankAccReconciliationLine."Account Type"::Customer, Customer."No.", ExpectedNoOfEntries);

        // Verify Applied Payment Entries
        GetAppliedPaymentEntries(AppliedPaymentEntry, BankAccReconciliationLine);
        Assert.AreEqual(AppliedPaymentEntry.Count, ExpectedNoOfEntries, 'Wrong number of Applied Payment Entries Found');

        AppliedPaymentEntry.FindFirst();
        VerifyMultipleApplicationsAppliedEntries(AppliedPaymentEntry, Quality, Amount, CustLedgerEntry."Entry No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCustomerMultipleMatchAllEntriesAppliedOneNotPaidOneUnderPaid()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        AppliedPaymentEntry: Record "Applied Payment Entry";
        Amount: Decimal;
        Amount2: Decimal;
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
        AppliedAmount: Decimal;
        Difference: Decimal;
        ExpectedNoOfEntries: Integer;
        Quality: Integer;
    begin
        Initialize();

        // Setup
        CreateCustomer(Customer);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        DocumentNo := CreateAndPostSalesInvoiceWithOneLine(Customer."No.", GenerateExtDocNo(), Amount);

        Amount2 := LibraryRandom.RandDecInRange(1, 1000, 2);
        DocumentNo2 := CreateAndPostSalesInvoiceWithOneLine(Customer."No.", GenerateExtDocNo(), Amount2);

        AppliedAmount := Round(Amount / 2, LibraryERM.GetAmountRoundingPrecision());

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, AppliedAmount, '', DocumentNo + ' ' + DocumentNo2);
        UpdateBankReconciliationLine(BankAccReconciliationLine, '', Customer.Name, '', '');

        GetCustLedgerEntry(CustLedgerEntry, Customer, DocumentNo);

        RunMatch(BankAccReconciliation, true);

        // Verify Bank Account ReconciliationLine
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Yes - Multiple",
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");

        Difference := 0;
        ExpectedNoOfEntries := 1;
        Quality := TempBankPmtApplRule.GetBestMatchScore(BankPmtApplRule);

        VerifyMultipleApplicationsBankAccReconciliationLine(
          BankAccReconciliationLine, TempBankPmtApplRule.GetBestMatchScore(BankPmtApplRule), Difference, AppliedAmount,
          BankAccReconciliationLine."Account Type"::Customer, Customer."No.", ExpectedNoOfEntries);

        // Verify Applied Payment Entries
        GetAppliedPaymentEntries(AppliedPaymentEntry, BankAccReconciliationLine);
        Assert.AreEqual(AppliedPaymentEntry.Count, ExpectedNoOfEntries, 'Wrong number of Applied Payment Entries Found');
        AppliedPaymentEntry.FindFirst();
        VerifyMultipleApplicationsAppliedEntries(
          AppliedPaymentEntry, Quality, AppliedAmount, CustLedgerEntry."Entry No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCustomerMultipleMatchWhenCannotApplyEntriesOldestGetAppliedFirst()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        CustLedgerEntry3: Record "Cust. Ledger Entry";
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        AppliedPaymentEntry: Record "Applied Payment Entry";
        Amount: Decimal;
        Amount2: Decimal;
        Amount3: Decimal;
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
        DocumentNo3: Code[20];
        AppliedAmount: Decimal;
        Difference: Decimal;
        ExpectedNoOfEntries: Integer;
        Quality: Integer;
        DueDate: Date;
        DueDate2: Date;
        DueDate3: Date;
    begin
        Initialize();

        // Setup
        CreateCustomer(Customer);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        Amount2 := LibraryRandom.RandDecInRange(1, 1000, 2);
        Amount3 := LibraryRandom.RandDecInRange(1, 1000, 2);

        DueDate := WorkDate();
        DueDate2 := CalcDate('<-3D>', DueDate);
        DueDate3 := CalcDate('<1D>', DueDate2);

        DocumentNo := CreateAndPostSalesInvoiceWithOneLine2(Customer."No.", GenerateExtDocNo(), Amount, DueDate);
        DocumentNo2 := CreateAndPostSalesInvoiceWithOneLine2(Customer."No.", GenerateExtDocNo(), Amount2, DueDate2);
        DocumentNo3 := CreateAndPostSalesInvoiceWithOneLine2(Customer."No.", GenerateExtDocNo(), Amount3, DueDate3);

        AppliedAmount := Amount2 + Round(Amount3 / 2, LibraryERM.GetAmountRoundingPrecision());

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(
          BankAccReconciliation, BankAccReconciliationLine, AppliedAmount, DocumentNo + ' ' + DocumentNo2 + ' ' + DocumentNo3, '');
        UpdateBankReconciliationLine(BankAccReconciliationLine, '', Customer.Name, '', '');

        GetCustLedgerEntry(CustLedgerEntry, Customer, DocumentNo);
        GetCustLedgerEntry(CustLedgerEntry2, Customer, DocumentNo2);
        GetCustLedgerEntry(CustLedgerEntry3, Customer, DocumentNo3);

        RunMatch(BankAccReconciliation, true);

        // Verify Bank Account ReconciliationLine
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Yes - Multiple",
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");

        Difference := 0;
        ExpectedNoOfEntries := 2;
        Quality := TempBankPmtApplRule.GetBestMatchScore(BankPmtApplRule);

        VerifyMultipleApplicationsBankAccReconciliationLine(
          BankAccReconciliationLine, TempBankPmtApplRule.GetBestMatchScore(BankPmtApplRule), Difference, AppliedAmount,
          BankAccReconciliationLine."Account Type"::Customer, Customer."No.", ExpectedNoOfEntries);

        // Verify Applied Payment Entries
        GetAppliedPaymentEntries(AppliedPaymentEntry, BankAccReconciliationLine);
        Assert.AreEqual(AppliedPaymentEntry.Count, ExpectedNoOfEntries, 'Wrong number of Applied Payment Entries Found');
        AppliedPaymentEntry.FindFirst();
        VerifyMultipleApplicationsAppliedEntries(AppliedPaymentEntry, Quality, Amount2, CustLedgerEntry2."Entry No.");

        AppliedPaymentEntry.Next();
        VerifyMultipleApplicationsAppliedEntries(AppliedPaymentEntry, Quality, AppliedAmount - Amount2, CustLedgerEntry3."Entry No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCustomerMultipleMatchTextMapperOverridesMediumConfidenceRule()
    var
        TextToAccMapping: Record "Text-to-Account Mapping";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
        AppliedPaymentEntry: Record "Applied Payment Entry";
        Amount: Decimal;
        DocumentNo: Code[20];
        TextMapper: Code[20];
        Difference: Decimal;
        ExpectedNoOfEntries: Integer;
        Quality: Integer;
    begin
        Initialize();

        // Setup
        CreateCustomer(Customer);
        TextMapper := GenerateTextToAccountMapping();
        LibraryERM.CreateAccountMappingGLAccount(TextToAccMapping, TextMapper, LibraryERM.CreateGLAccountNo(), '');

        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        DocumentNo := CreateAndPostSalesInvoiceWithOneLine(Customer."No.", GenerateExtDocNo(), Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, Amount, TextMapper, DocumentNo);
        UpdateBankReconciliationLine(BankAccReconciliationLine, '', '', '', '');

        // Execute
        RunMatch(BankAccReconciliation, true);

        // Verify
        Difference := 0;
        ExpectedNoOfEntries := 1;
        Quality := TempBankPmtApplRule.GetTextMapperScore();

        VerifyMultipleApplicationsBankAccReconciliationLine(
          BankAccReconciliationLine, Quality, Difference, Amount, BankAccReconciliationLine."Account Type"::"G/L Account",
          TextToAccMapping."Debit Acc. No.", ExpectedNoOfEntries);
        GetAppliedPaymentEntries(AppliedPaymentEntry, BankAccReconciliationLine);
        AppliedPaymentEntry.FindFirst();
        VerifyMultipleApplicationsAppliedEntries(AppliedPaymentEntry, Quality, Amount, 0);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCustomerMultipleMatchTextMapperDoesntOveriddeHighConfidenceRule()
    var
        TextToAccMapping: Record "Text-to-Account Mapping";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        AppliedPaymentEntry: Record "Applied Payment Entry";
        Amount: Decimal;
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
        TextMapper: Code[20];
        Difference: Decimal;
        ExpectedNoOfEntries: Integer;
        Quality: Integer;
    begin
        Initialize();

        // Setup
        CreateCustomer(Customer);
        TextMapper := GenerateTextToAccountMapping();
        LibraryERM.CreateAccountMappingGLAccount(TextToAccMapping, TextMapper, LibraryERM.CreateGLAccountNo(), '');

        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        DocumentNo := CreateAndPostSalesInvoiceWithOneLine(Customer."No.", GenerateExtDocNo(), Amount);
        DocumentNo2 := CreateAndPostSalesInvoiceWithOneLine(Customer."No.", GenerateExtDocNo(), Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(
          BankAccReconciliation, BankAccReconciliationLine, 2 * Amount, TextMapper, DocumentNo + ' ' + DocumentNo2);
        UpdateBankReconciliationLine(BankAccReconciliationLine, '', Customer.Name, '', '');

        GetCustLedgerEntry(CustLedgerEntry, Customer, DocumentNo);
        GetCustLedgerEntry(CustLedgerEntry2, Customer, DocumentNo2);

        // Execute
        RunMatch(BankAccReconciliation, true);

        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Yes - Multiple",
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match");

        // Verify
        Difference := 0;
        ExpectedNoOfEntries := 2;
        Quality := TempBankPmtApplRule.GetBestMatchScore(BankPmtApplRule);

        VerifyMultipleApplicationsBankAccReconciliationLine(
          BankAccReconciliationLine, Quality, Difference, 2 * Amount, BankAccReconciliationLine."Account Type"::Customer, Customer."No.",
          ExpectedNoOfEntries);
        GetAppliedPaymentEntries(AppliedPaymentEntry, BankAccReconciliationLine);
        AppliedPaymentEntry.FindFirst();
        VerifyMultipleApplicationsAppliedEntries(AppliedPaymentEntry, Quality, Amount, CustLedgerEntry."Entry No.");
        AppliedPaymentEntry.Next();
        VerifyMultipleApplicationsAppliedEntries(AppliedPaymentEntry, Quality, Amount, CustLedgerEntry2."Entry No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCustomerMultipleMatchOneHitMultipleMatchesAreRemoved()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
        Amount: Decimal;
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
    begin
        Initialize();

        // Setup
        CreateCustomer(Customer);

        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        DocumentNo := CreateAndPostSalesInvoiceWithOneLine(Customer."No.", GenerateExtDocNo(), Amount);
        DocumentNo2 := CreateAndPostSalesInvoiceWithOneLine(Customer."No.", GenerateExtDocNo(), Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, 2 * Amount, '', DocumentNo + ' ' + DocumentNo2);
        UpdateBankReconciliationLine(BankAccReconciliationLine, '', Customer.Name, '', '');

        // Execute
        RunMatch(BankAccReconciliation, true);
        TempBankStatementMatchingBuffer.Reset();
        Assert.AreEqual(
          3, TempBankStatementMatchingBuffer.Count, 'There should be two single mach entries and one multiple match entry present');

        Assert.AreEqual(
          3, TempBankStatementMatchingBuffer.Count, 'There should be two single mach entries and one multiple match entry present');
        TempBankStatementMatchingBuffer.SetRange("One to Many Match", true);
        Assert.AreEqual(1, TempBankStatementMatchingBuffer.Count, 'There should be one multiple match entry present');

        TempBankStatementMatchingBuffer.SetRange("No. of Entries", 1);
        Assert.IsTrue(TempBankStatementMatchingBuffer.IsEmpty, 'All temporary multiple match entries must be removed');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCustomerMultipleMatchSingleMatchLinesAreIncludedInAmountInclToleranceMatch()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccReconciliationLine2: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        BankPmtApplRule2: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
        DocumentNo3: Code[20];
        Difference: Decimal;
        ExpectedNoOfEntries: Integer;
        Quality: Integer;
    begin
        Initialize();

        // Setup
        CreateCustomer(Customer);

        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        DocumentNo := CreateAndPostSalesInvoiceWithOneLine(Customer."No.", GenerateExtDocNo(), Amount);
        DocumentNo2 := CreateAndPostSalesInvoiceWithOneLine(Customer."No.", GenerateExtDocNo(), Amount);
        DocumentNo3 := CreateAndPostSalesInvoiceWithOneLine(Customer."No.", GenerateExtDocNo(), 2 * Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, 2 * Amount, '', DocumentNo + ' ' + DocumentNo2);
        UpdateBankReconciliationLine(BankAccReconciliationLine, '', Customer.Name, '', '');

        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine2, 2 * Amount, '', DocumentNo3);
        UpdateBankReconciliationLine(BankAccReconciliationLine2, '', Customer.Name, '', '');

        RunMatch(BankAccReconciliation, true);
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Yes - Multiple",
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"Multiple Matches");

        SetRule(BankPmtApplRule2, BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes, BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match");

        // Verify
        Difference := 0;
        ExpectedNoOfEntries := 2;
        Quality := TempBankPmtApplRule.GetBestMatchScore(BankPmtApplRule);
        VerifyMultipleApplicationsBankAccReconciliationLine(
          BankAccReconciliationLine, Quality, Difference, 2 * Amount, BankAccReconciliationLine."Account Type"::Customer, Customer."No.",
          ExpectedNoOfEntries);

        ExpectedNoOfEntries := 1;
        Quality := TempBankPmtApplRule.GetBestMatchScore(BankPmtApplRule2);
        VerifyMultipleApplicationsBankAccReconciliationLine(
          BankAccReconciliationLine2, Quality, Difference, 2 * Amount, BankAccReconciliationLine."Account Type"::Customer, Customer."No.",
          ExpectedNoOfEntries);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCustomerMultipleMatchOneToManyMatchesAreIncludedInAmountInclToleranceMatch()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccReconciliationLine2: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
        DocumentNo3: Code[20];
        DocumentNo4: Code[20];
        Difference: Decimal;
        ExpectedNoOfEntries: Integer;
        Quality: Integer;
    begin
        Initialize();

        // Setup
        CreateCustomer(Customer);

        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        DocumentNo := CreateAndPostSalesInvoiceWithOneLine(Customer."No.", GenerateExtDocNo(), Amount);
        DocumentNo2 := CreateAndPostSalesInvoiceWithOneLine(Customer."No.", GenerateExtDocNo(), Amount);
        DocumentNo3 := CreateAndPostSalesInvoiceWithOneLine(Customer."No.", GenerateExtDocNo(), Amount);
        DocumentNo4 := CreateAndPostSalesInvoiceWithOneLine(Customer."No.", GenerateExtDocNo(), Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, 2 * Amount, '', DocumentNo + ' ' + DocumentNo2);
        UpdateBankReconciliationLine(BankAccReconciliationLine, '', Customer.Name, '', '');

        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine2, 2 * Amount, '', DocumentNo3 + ' ' + DocumentNo4);
        UpdateBankReconciliationLine(BankAccReconciliationLine2, '', Customer.Name, '', '');

        RunMatch(BankAccReconciliation, true);
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Yes - Multiple",
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"Multiple Matches");

        // Verify
        Difference := 0;
        ExpectedNoOfEntries := 2;
        Quality := TempBankPmtApplRule.GetBestMatchScore(BankPmtApplRule);
        VerifyMultipleApplicationsBankAccReconciliationLine(
          BankAccReconciliationLine, Quality, Difference, 2 * Amount, BankAccReconciliationLine."Account Type"::Customer, Customer."No.",
          ExpectedNoOfEntries);
        VerifyMultipleApplicationsBankAccReconciliationLine(
          BankAccReconciliationLine2, Quality, Difference, 2 * Amount, BankAccReconciliationLine."Account Type"::Customer, Customer."No.",
          ExpectedNoOfEntries);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCustomerMultipleMatchTwoOneToManyLines()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccReconciliationLine2: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        CustLedgerEntry3: Record "Cust. Ledger Entry";
        CustLedgerEntry4: Record "Cust. Ledger Entry";
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        BankPmtApplRule2: Record "Bank Pmt. Appl. Rule";
        AppliedPaymentEntry: Record "Applied Payment Entry";
        Amount: Decimal;
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
        DocumentNo3: Code[20];
        DocumentNo4: Code[20];
        Difference: Decimal;
        ExpectedNoOfEntries: Integer;
        Quality: Integer;
        Quality2: Integer;
    begin
        Initialize();

        // Setup
        CreateCustomer(Customer);

        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        DocumentNo := CreateAndPostSalesInvoiceWithOneLine(Customer."No.", GenerateExtDocNo(), Amount);
        DocumentNo2 := CreateAndPostSalesInvoiceWithOneLine(Customer."No.", GenerateExtDocNo(), Amount);
        DocumentNo3 := CreateAndPostSalesInvoiceWithOneLine(Customer."No.", GenerateExtDocNo(), 2 * Amount);
        DocumentNo4 := CreateAndPostSalesInvoiceWithOneLine(Customer."No.", GenerateExtDocNo(), Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, 2 * Amount, '', DocumentNo + ' ' + DocumentNo2);
        UpdateBankReconciliationLine(BankAccReconciliationLine, '', Customer.Name, '', '');

        CreateBankReconciliationLine(
          BankAccReconciliation, BankAccReconciliationLine2, 3 * Amount, DocumentNo + ' ' + DocumentNo3 + ' ' + DocumentNo4, '');
        UpdateBankReconciliationLine(BankAccReconciliationLine2, '', Customer.Name, '', '');

        GetCustLedgerEntry(CustLedgerEntry, Customer, DocumentNo);
        GetCustLedgerEntry(CustLedgerEntry2, Customer, DocumentNo2);
        GetCustLedgerEntry(CustLedgerEntry3, Customer, DocumentNo3);
        GetCustLedgerEntry(CustLedgerEntry4, Customer, DocumentNo4);

        RunMatch(BankAccReconciliation, true);
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Yes - Multiple",
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"Multiple Matches");

        SetRule(BankPmtApplRule2, BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Yes - Multiple",
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");

        // Verify
        Difference := 0;
        ExpectedNoOfEntries := 2;
        Quality := TempBankPmtApplRule.GetBestMatchScore(BankPmtApplRule);
        Quality2 := TempBankPmtApplRule.GetBestMatchScore(BankPmtApplRule2);

        VerifyMultipleApplicationsBankAccReconciliationLine(
          BankAccReconciliationLine, Quality, Difference, 2 * Amount, BankAccReconciliationLine."Account Type"::Customer, Customer."No.",
          ExpectedNoOfEntries);
        VerifyMultipleApplicationsBankAccReconciliationLine(
          BankAccReconciliationLine2, Quality2, Difference, 3 * Amount, BankAccReconciliationLine."Account Type"::Customer, Customer."No.",
          ExpectedNoOfEntries);

        // Verify Applied Payment Entries Line 1
        GetAppliedPaymentEntries(AppliedPaymentEntry, BankAccReconciliationLine);
        Assert.AreEqual(AppliedPaymentEntry.Count, ExpectedNoOfEntries, 'Wrong number of Applied Payment Entries Found');
        AppliedPaymentEntry.FindFirst();
        VerifyMultipleApplicationsAppliedEntries(AppliedPaymentEntry, Quality, Amount, CustLedgerEntry."Entry No.");

        AppliedPaymentEntry.Next();
        VerifyMultipleApplicationsAppliedEntries(AppliedPaymentEntry, Quality, Amount, CustLedgerEntry2."Entry No.");

        // Verify Applied Payment Entries Line 2
        GetAppliedPaymentEntries(AppliedPaymentEntry, BankAccReconciliationLine2);
        Assert.AreEqual(AppliedPaymentEntry.Count, ExpectedNoOfEntries, 'Wrong number of Applied Payment Entries Found');
        AppliedPaymentEntry.FindFirst();
        VerifyMultipleApplicationsAppliedEntries(
          AppliedPaymentEntry, Quality2, CustLedgerEntry3."Remaining Amount", CustLedgerEntry3."Entry No.");

        AppliedPaymentEntry.Next();
        VerifyMultipleApplicationsAppliedEntries(
          AppliedPaymentEntry, Quality2, CustLedgerEntry4."Remaining Amount", CustLedgerEntry4."Entry No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCustomerMultipleMatchBuildFromNoMatchEntries()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        AppliedPaymentEntry: Record "Applied Payment Entry";
        Amount: Decimal;
        Amount2: Decimal;
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
        AppliedAmount: Decimal;
        StatementAmount: Decimal;
        Difference: Decimal;
        ExpectedNoOfEntries: Integer;
        Quality: Integer;
    begin
        Initialize();

        // Setup
        // Remove all rules except multiple match rules, so they will be scored with 0
        BankPmtApplRule.SetFilter(
          "Doc. No./Ext. Doc. No. Matched", '<>%1', BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Yes - Multiple");
        BankPmtApplRule.DeleteAll();
        BankPmtApplRule.Reset();

        CreateCustomer(Customer);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        DocumentNo := CreateAndPostSalesInvoiceWithOneLine(Customer."No.", GenerateExtDocNo(), Amount);

        Amount2 := LibraryRandom.RandDecInRange(1, 1000, 2);
        DocumentNo2 := CreateAndPostSalesInvoiceWithOneLine(Customer."No.", GenerateExtDocNo(), Amount2);

        AppliedAmount := Amount + Amount2;
        StatementAmount := 2 * AppliedAmount;

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, StatementAmount, '', DocumentNo + ' ' + DocumentNo2);
        UpdateBankReconciliationLine(BankAccReconciliationLine, '', Customer.Name, '', '');

        GetCustLedgerEntry(CustLedgerEntry, Customer, DocumentNo);
        GetCustLedgerEntry(CustLedgerEntry2, Customer, DocumentNo2);

        RunMatch(BankAccReconciliation, true);

        // Verify Bank Account ReconciliationLine
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Yes - Multiple",
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");

        Difference := StatementAmount - AppliedAmount;
        ExpectedNoOfEntries := 2;
        Quality := TempBankPmtApplRule.GetBestMatchScore(BankPmtApplRule);

        VerifyMultipleApplicationsBankAccReconciliationLine(
          BankAccReconciliationLine, Quality, Difference, AppliedAmount, BankAccReconciliationLine."Account Type"::Customer, Customer."No.",
          ExpectedNoOfEntries);

        // Verify Applied Payment Entries
        GetAppliedPaymentEntries(AppliedPaymentEntry, BankAccReconciliationLine);
        Assert.AreEqual(AppliedPaymentEntry.Count, ExpectedNoOfEntries, 'Wrong number of Applied Payment Entries Found');
        AppliedPaymentEntry.FindFirst();
        VerifyMultipleApplicationsAppliedEntries(AppliedPaymentEntry, Quality, Amount, CustLedgerEntry."Entry No.");
        AppliedPaymentEntry.Next();
        VerifyMultipleApplicationsAppliedEntries(AppliedPaymentEntry, Quality, Amount2, CustLedgerEntry2."Entry No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCustomerRunningWithoutApplicationIncludesNegativeEntries()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        TempBankPmtApplRule: Record "Bank Pmt. Appl. Rule" temporary;
        Amount: Decimal;
        DocumentNo: Code[20];
        Quality: Integer;
    begin
        Initialize();

        // Setup
        CreateCustomer(Customer);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        DocumentNo := CreateAndPostSalesInvoiceWithOneLine(Customer."No.", GenerateExtDocNo(), Amount);

        GetCustLedgerEntry(CustLedgerEntry, Customer, DocumentNo);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, -Amount, '', DocumentNo);
        UpdateBankReconciliationLine(BankAccReconciliationLine, '', Customer.Name, '', '');

        // Execute
        RunMatch(BankAccReconciliation, false);

        // Verify positive entry is present and was scored
        Assert.AreEqual(1, TempBankStatementMatchingBuffer.Count, 'There should be one entry present');
        TempBankStatementMatchingBuffer.FindFirst();
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes,
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");

        TempBankPmtApplRule.LoadRules();
        Quality := TempBankPmtApplRule.GetBestMatchScore(BankPmtApplRule);

        Assert.AreEqual(Quality, TempBankStatementMatchingBuffer.Quality, 'Score should be assigned to the line');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCustomerRunningWithApplicationExcludesNegativeEntries()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Amount: Decimal;
        DocumentNo: Code[20];
    begin
        Initialize();

        // Setup
        CreateCustomer(Customer);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        DocumentNo := CreateAndPostSalesInvoiceWithOneLine(Customer."No.", GenerateExtDocNo(), Amount);

        GetCustLedgerEntry(CustLedgerEntry, Customer, DocumentNo);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, -Amount, '', DocumentNo);
        UpdateBankReconciliationLine(BankAccReconciliationLine, '', Customer.Name, '', '');

        // Execute
        RunMatch(BankAccReconciliation, true);

        // Verify positive entry is not present
        Assert.AreEqual(0, TempBankStatementMatchingBuffer.Count, 'There should be no entries present');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCustomerRunningWithoutApplicationIncludesEntriesAfterStatementDate()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        TempBankPmtApplRule: Record "Bank Pmt. Appl. Rule" temporary;
        Amount: Decimal;
        DocumentNo: Code[20];
        Quality: Integer;
    begin
        Initialize();

        // Setup
        CreateCustomer(Customer);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        DocumentNo := CreateAndPostSalesInvoiceWithOneLine(Customer."No.", GenerateExtDocNo(), Amount);

        GetCustLedgerEntry(CustLedgerEntry, Customer, DocumentNo);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, Amount, '', DocumentNo);
        UpdateBankReconciliationLine(BankAccReconciliationLine, '', Customer.Name, '', '');
        BankAccReconciliationLine.Validate("Transaction Date", CalcDate('<-1M>', CustLedgerEntry."Posting Date"));
        BankAccReconciliationLine.Modify(true);

        // Execute
        RunMatch(BankAccReconciliation, false);

        // Verify positive entry is present and was scored
        Assert.AreEqual(1, TempBankStatementMatchingBuffer.Count, 'There should be one entry present');
        TempBankStatementMatchingBuffer.FindFirst();
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes,
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match");

        TempBankPmtApplRule.LoadRules();
        Quality := TempBankPmtApplRule.GetBestMatchScore(BankPmtApplRule);

        Assert.AreEqual(Quality, TempBankStatementMatchingBuffer.Quality, 'Score should be assigned to the line');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCustomerRunningWithoutApplicationDoesNotIncludeEntriesAfterStatementDate()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Amount: Decimal;
        DocumentNo: Code[20];
    begin
        Initialize();

        // Setup
        CreateCustomer(Customer);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        DocumentNo := CreateAndPostSalesInvoiceWithOneLine(Customer."No.", GenerateExtDocNo(), Amount);

        GetCustLedgerEntry(CustLedgerEntry, Customer, DocumentNo);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, Amount, '', DocumentNo);
        UpdateBankReconciliationLine(BankAccReconciliationLine, '', Customer.Name, '', '');
        BankAccReconciliationLine.Validate("Transaction Date", CalcDate('<-1M>', CustLedgerEntry."Posting Date"));
        BankAccReconciliationLine.Modify(true);

        // Execute
        RunMatch(BankAccReconciliation, true);

        // Verify positive entry is present and was scored
        Assert.AreEqual(0, TempBankStatementMatchingBuffer.Count, 'There should be one entry present');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestNoMatchFoundVendorEntries()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Vendor: Record Vendor;
        Amount: Decimal;
        ExtDocNo: Code[20];
    begin
        Initialize();

        CreateVendor(Vendor);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        ExtDocNo := GenerateExtDocNo();
        CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", ExtDocNo, Amount);
        // Setup

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, -Amount / 2, '', '');

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        VerifyNoMatch(BankAccReconciliationLine."Statement Line No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestVendNoMatchOutsideTolerance()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Vendor: Record Vendor;
        Amount: Decimal;
        Tolerance: Decimal;
        ExtDocNo: Code[20];
    begin
        Initialize();

        // Setup
        CreateVendor(Vendor);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        Tolerance := Round(Amount / 4, 0.01);
        ExtDocNo := GenerateExtDocNo();
        CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", ExtDocNo, Amount + Tolerance + 0.01);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, Tolerance);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, -Amount, '', '');

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        // VerifyMatchBufferEmpty;
    end;

    [Test]
    [HandlerFunctions('MessageHandler,VerifyMatchDetailsOnPaymentApplicationsPage')]
    [Scope('OnPrem')]
    procedure TestVendSingleAmountMatch()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Vendor: Record Vendor;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
        ExtDocNo: Code[20];
    begin
        Initialize();

        // Setup
        CreateVendor(Vendor);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        ExtDocNo := GenerateExtDocNo();
        CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", ExtDocNo, Amount);
        ExtDocNo := GenerateExtDocNo();
        CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", ExtDocNo, Amount + 1);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, -Amount, '', '');

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No, BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match");
        VerifyReconciliation(BankPmtApplRule, BankAccReconciliationLine."Statement Line No.");
        VerifyMatchDetailsData(
          BankAccReconciliation, BankPmtApplRule, BankAccReconciliationLine."Account Type"::Vendor, -Amount, 0, 1, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,VerifyMatchDetailsOnPaymentApplicationsPage')]
    [Scope('OnPrem')]
    procedure TestVendSingleAmountMatchWithAmountToleranceLowerRange()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Vendor: Record Vendor;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
        Tolerance: Decimal;
        ExtDocNo: Code[20];
    begin
        Initialize();

        // Setup
        CreateVendor(Vendor);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        ExtDocNo := GenerateExtDocNo();
        Tolerance := Round(Amount / 4, 0.01);
        CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", ExtDocNo, Amount + Tolerance);
        ExtDocNo := GenerateExtDocNo();
        CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", ExtDocNo, Amount + 5 * Tolerance);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, Tolerance);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, -Amount, '', '');

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No, BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match");
        VerifyReconciliation(BankPmtApplRule, BankAccReconciliationLine."Statement Line No.");
        VerifyMatchDetailsData(
          BankAccReconciliation, BankPmtApplRule, BankAccReconciliationLine."Account Type"::Vendor, -Amount, Tolerance, 1, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,VerifyMatchDetailsOnPaymentApplicationsPage')]
    [Scope('OnPrem')]
    procedure TestVendSingleAmountMatchWithAmountToleranceHigherRange()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Vendor: Record Vendor;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
        Tolerance: Decimal;
        ExtDocNo: Code[20];
    begin
        Initialize();

        // Setup
        CreateVendor(Vendor);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        ExtDocNo := GenerateExtDocNo();
        Tolerance := Round(Amount / 4, 0.01);
        CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", ExtDocNo, Amount + Tolerance);
        ExtDocNo := GenerateExtDocNo();
        CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", ExtDocNo, Amount + 5 * Tolerance);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, Tolerance);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, -(Amount + 2 * Tolerance), '', '');

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No, BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match");
        VerifyReconciliation(BankPmtApplRule, BankAccReconciliationLine."Statement Line No.");
        VerifyMatchDetailsData(BankAccReconciliation, BankPmtApplRule,
          BankAccReconciliationLine."Account Type"::Vendor, -Amount, Tolerance, 1, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,VerifyMatchDetailsOnPaymentApplicationsPage')]
    [Scope('OnPrem')]
    procedure TestVendSingleAmountMatchWithAmountPercentageTolerance()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Vendor: Record Vendor;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
        Tolerance: Decimal;
        ExtDocNo: Code[20];
    begin
        Initialize();

        // Setup
        CreateVendor(Vendor);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        ExtDocNo := GenerateExtDocNo();
        Tolerance := LibraryRandom.RandDecInRange(1, 99, 1);
        CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", ExtDocNo, Amount * (1 + Tolerance / 100));
        ExtDocNo := GenerateExtDocNo();
        CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", ExtDocNo, Amount + 5 * Tolerance);

        CreateBankReconciliationPercentageTolerance(BankAccReconciliation, Tolerance);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, -Amount, '', '');

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No, BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match");
        VerifyReconciliation(BankPmtApplRule, BankAccReconciliationLine."Statement Line No.");
        VerifyMatchDetailsData(BankAccReconciliation, BankPmtApplRule,
          BankAccReconciliationLine."Account Type"::Vendor, -Amount, Tolerance, 1, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,VerifyMatchDetailsOnPaymentApplicationsPage')]
    [Scope('OnPrem')]
    procedure TestVendMultipleAmountMatch()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Vendor: Record Vendor;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
        ExtDocNo: Code[20];
    begin
        Initialize();

        // Setup
        CreateVendor(Vendor);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        ExtDocNo := GenerateExtDocNo();
        CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", ExtDocNo, Amount);
        ExtDocNo := GenerateExtDocNo();
        CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", ExtDocNo, Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, -Amount, '', '');

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No, BankPmtApplRule."Amount Incl. Tolerance Matched"::"Multiple Matches");
        VerifyReconciliation(BankPmtApplRule, BankAccReconciliationLine."Statement Line No.");
        VerifyMatchDetailsData(BankAccReconciliation, BankPmtApplRule,
          BankAccReconciliationLine."Account Type"::Vendor, -Amount, 0, 2, 0);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,VerifyMatchDetailsOnPaymentApplicationsPage')]
    [Scope('OnPrem')]
    procedure TestVendMultipleAmountMatchWithAmountTolerance()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Vendor: Record Vendor;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
        Tolerance: Decimal;
        ExtDocNo: Code[20];
    begin
        Initialize();

        // Setup
        CreateVendor(Vendor);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        Tolerance := Round(Amount / 4, 0.01);
        ExtDocNo := GenerateExtDocNo();
        CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", ExtDocNo, Amount + Tolerance);
        ExtDocNo := GenerateExtDocNo();
        CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", ExtDocNo, Amount + Tolerance / 3);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, Tolerance);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, -Amount, '', '');

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No, BankPmtApplRule."Amount Incl. Tolerance Matched"::"Multiple Matches");
        VerifyReconciliation(BankPmtApplRule, BankAccReconciliationLine."Statement Line No.");
        VerifyMatchDetailsData(BankAccReconciliation, BankPmtApplRule,
          BankAccReconciliationLine."Account Type"::Vendor, -Amount, Tolerance, 2, 0);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,VerifyMatchDetailsOnPaymentApplicationsPage')]
    [Scope('OnPrem')]
    procedure TestVendDoctInTransTextMatch()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Vendor: Record Vendor;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
        DocumentNo: Code[20];
        ExtDocNo: Code[20];
    begin
        Initialize();

        // Setup
        CreateVendor(Vendor);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        ExtDocNo := GenerateExtDocNo();
        DocumentNo := CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", ExtDocNo, Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, -Amount / 2, DocumentNo, '');

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes, BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");
        VerifyReconciliation(BankPmtApplRule, BankAccReconciliationLine."Statement Line No.");
        VerifyMatchDetailsData(BankAccReconciliation, BankPmtApplRule,
          BankAccReconciliationLine."Account Type"::Vendor, -Amount / 2, 0, 0, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,VerifyMatchDetailsOnPaymentApplicationsPage')]
    [Scope('OnPrem')]
    procedure TestVendDocInAdditionalTextMatch()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Vendor: Record Vendor;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
        DocumentNo: Code[20];
        ExtDocNo: Code[20];
    begin
        Initialize();

        // Setup
        CreateVendor(Vendor);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        ExtDocNo := GenerateExtDocNo();
        DocumentNo := CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", ExtDocNo, Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, -Amount / 2, '', DocumentNo);

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes, BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");
        VerifyReconciliation(BankPmtApplRule, BankAccReconciliationLine."Statement Line No.");
        VerifyMatchDetailsData(BankAccReconciliation, BankPmtApplRule,
          BankAccReconciliationLine."Account Type"::Vendor, -Amount / 2, 0, 0, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,VerifyMatchDetailsOnPaymentApplicationsPage')]
    [Scope('OnPrem')]
    procedure TestVendExtDocAndDocNoMatch()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Vendor: Record Vendor;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
        DocumentNo: Code[20];
        ExtDocNo: Code[20];
    begin
        Initialize();

        // Setup
        CreateVendor(Vendor);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        ExtDocNo := GenerateExtDocNo();
        DocumentNo := CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", ExtDocNo, Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, -Amount / 2, ExtDocNo, DocumentNo);

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes, BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");
        VerifyReconciliation(BankPmtApplRule, BankAccReconciliationLine."Statement Line No.");
        VerifyMatchDetailsData(BankAccReconciliation, BankPmtApplRule,
          BankAccReconciliationLine."Account Type"::Vendor, -Amount / 2, 0, 0, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestVendNoMatchExtDocAndDocNoTrailingChar()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Vendor: Record Vendor;
        Amount: Decimal;
        DocumentNo: Code[20];
        ExtDocNo: Code[20];
    begin
        Initialize();

        // Setup
        CreateVendor(Vendor);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        ExtDocNo := GenerateExtDocNo();
        DocumentNo := CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", ExtDocNo, Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, -Amount / 2,
          ExtDocNo + GenerateRandomSmallLetters(1), GenerateRandomSmallLetters(1) + DocumentNo);

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        VerifyNoMatch(BankAccReconciliationLine."Statement Line No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestVendNoMatchExtDocAndDocNoTrailingDigit()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Vendor: Record Vendor;
        Amount: Decimal;
        DocumentNo: Code[20];
        ExtDocNo: Code[20];
    begin
        Initialize();

        // Setup
        CreateVendor(Vendor);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        ExtDocNo := GenerateExtDocNo();
        DocumentNo := CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", ExtDocNo, Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, -Amount / 2,
          ExtDocNo + GenerateRandomSmallLetters(1), GenerateRandomSmallLetters(1) + DocumentNo);

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        VerifyNoMatch(BankAccReconciliationLine."Statement Line No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,VerifyMatchDetailsOnPaymentApplicationsPage')]
    [Scope('OnPrem')]
    procedure TestVendNoMatchExtDocAndDocTrailingWithNonAlphaAndChar()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Vendor: Record Vendor;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
        DocumentNo: Code[20];
        ExtDocNo: Code[20];
    begin
        Initialize();

        // Setup
        CreateVendor(Vendor);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        ExtDocNo := GenerateExtDocNo();
        DocumentNo := CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", ExtDocNo, Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, -Amount / 2,
          ExtDocNo + ',' + GenerateRandomSmallLetters(1), GenerateRandomSmallLetters(1) + ',' + DocumentNo);

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes, BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");
        VerifyReconciliation(BankPmtApplRule, BankAccReconciliationLine."Statement Line No.");
        VerifyMatchDetailsData(
          BankAccReconciliation, BankPmtApplRule, BankAccReconciliationLine."Account Type"::Vendor, Amount / 2, 0, 0, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,VerifyMatchDetailsOnPaymentApplicationsPage')]
    [Scope('OnPrem')]
    procedure TestVendNoMatchExtDocAndDocTrailingWithNonAlphaAndDigit()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Vendor: Record Vendor;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
        DocumentNo: Code[20];
        ExtDocNo: Code[20];
    begin
        Initialize();

        // Setup
        CreateVendor(Vendor);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        ExtDocNo := GenerateExtDocNo();
        DocumentNo := CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", ExtDocNo, Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, -Amount / 2,
          ExtDocNo + ',' + Format(LibraryRandom.RandInt(9)),
          Format(LibraryRandom.RandInt(9)) + ',' + DocumentNo);

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes, BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");
        VerifyReconciliation(BankPmtApplRule, BankAccReconciliationLine."Statement Line No.");
        VerifyMatchDetailsData(
          BankAccReconciliation, BankPmtApplRule, BankAccReconciliationLine."Account Type"::Vendor, Amount / 2, 0, 0, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestVendNotMatchExtDocTooShort()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Vendor: Record Vendor;
        Amount: Decimal;
        ExtDocNo: Code[20];
    begin
        Initialize();

        // Setup
        CreateVendor(Vendor);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        ExtDocNo := CopyStr(GenerateExtDocNo(), 1, 3);
        CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", ExtDocNo, Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, -Amount / 2, ExtDocNo, '');

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        VerifyNoMatch(BankAccReconciliationLine."Statement Line No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,VerifyMatchDetailsOnPaymentApplicationsPage')]
    [Scope('OnPrem')]
    procedure TestVendDocAndSingleAmountMatch()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Vendor: Record Vendor;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
        DocumentNo: Code[20];
        ExtDocNo: Code[20];
    begin
        Initialize();

        // Setup
        CreateVendor(Vendor);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        ExtDocNo := GenerateExtDocNo();
        DocumentNo := CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", ExtDocNo, Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, -Amount, ExtDocNo, DocumentNo);

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes, BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match");
        VerifyReconciliation(BankPmtApplRule, BankAccReconciliationLine."Statement Line No.");
        VerifyMatchDetailsData(BankAccReconciliation, BankPmtApplRule,
          BankAccReconciliationLine."Account Type"::Vendor, -Amount, 0, 1, 0);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,VerifyMatchDetailsOnPaymentApplicationsPage')]
    [Scope('OnPrem')]
    procedure TestVendDocAndMultipleAmountMatch()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Vendor: Record Vendor;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
        DocumentNo: Code[20];
        ExtDocNo: Code[20];
    begin
        Initialize();

        // Setup
        CreateVendor(Vendor);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        ExtDocNo := GenerateExtDocNo();
        DocumentNo := CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", ExtDocNo, Amount);
        CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", GenerateExtDocNo(), Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, -Amount, '', DocumentNo);

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes, BankPmtApplRule."Amount Incl. Tolerance Matched"::"Multiple Matches");
        VerifyReconciliation(BankPmtApplRule, BankAccReconciliationLine."Statement Line No.");
        VerifyMatchDetailsData(BankAccReconciliation, BankPmtApplRule,
          BankAccReconciliationLine."Account Type"::Vendor, -Amount, 0, 2, 0);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,VerifyMatchDetailsOnPaymentApplicationsPage')]
    [Scope('OnPrem')]
    procedure TestVendMatchOnBankAccountOnly()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Vendor: Record Vendor;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        VendorBankAccount: Record "Vendor Bank Account";
        Amount: Decimal;
    begin
        Initialize();

        // Setup
        CreateVendor(Vendor);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", GenerateExtDocNo(), Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, -Amount / 2, '', '');
        UpdateBankReconciliationLine(BankAccReconciliationLine, BankAccReconciliation."Bank Account No.", '', '', '');
        CreateVendorBankAccount(VendorBankAccount, Vendor."No.", BankAccReconciliation."Bank Account No.");

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No, BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");
        VerifyReconciliation(BankPmtApplRule, BankAccReconciliationLine."Statement Line No.");
        VerifyMatchDetailsData(BankAccReconciliation, BankPmtApplRule,
          BankAccReconciliationLine."Account Type"::Vendor, -Amount / 2, 0, 0, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,VerifyMatchDetailsOnPaymentApplicationsPage')]
    [Scope('OnPrem')]
    procedure TestVendExactMatchOnRelatedPartyNameSingle()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Vendor: Record Vendor;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
    begin
        Initialize();

        // Setup
        CreateVendor(Vendor);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", GenerateExtDocNo(), Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, -Amount / 2, '', '');
        UpdateBankReconciliationLine(BankAccReconciliationLine, '', Vendor.Name, '', '');

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No, BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");
        VerifyReconciliation(BankPmtApplRule, BankAccReconciliationLine."Statement Line No.");
        VerifyMatchDetailsData(
          BankAccReconciliation, BankPmtApplRule, BankAccReconciliationLine."Account Type"::Vendor, -Amount / 2, 0, 0, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,VerifyMatchDetailsOnPaymentApplicationsPage')]
    [Scope('OnPrem')]
    procedure TestVendExactMatchOnRelatedPartyNameReversed()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Vendor: Record Vendor;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
        FirstName: Text[20];
        LastName: Text[20];
    begin
        Initialize();

        // Setup
        CreateVendor(Vendor);
        FirstName := CopyStr(GenerateRandomSmallLetters(20), 1, 20);
        LastName := CopyStr(GenerateRandomSmallLetters(20), 1, 20);
        Vendor.Validate(Name, StrSubstNo('%1 %2', FirstName, LastName));
        Vendor.Modify(true);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", GenerateExtDocNo(), Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, -Amount / 2, '', '');
        UpdateBankReconciliationLine(BankAccReconciliationLine, '', StrSubstNo('%1 %2', LastName, FirstName), '', '');

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No, BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");
        VerifyReconciliation(BankPmtApplRule, BankAccReconciliationLine."Statement Line No.");
        VerifyMatchDetailsData(
          BankAccReconciliation, BankPmtApplRule, BankAccReconciliationLine."Account Type"::Vendor, Amount / 2, 0, 0, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,VerifyMatchDetailsOnPaymentApplicationsPage')]
    [Scope('OnPrem')]
    procedure TestVendExactMatchOnRelatedPartyNameMultiple()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Vendor: Record Vendor;
        Vendor1: Record Vendor;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
    begin
        Initialize();

        // Setup
        CreateVendor(Vendor);
        CreateVendor(Vendor1);
        Vendor1.Validate(Name, Vendor.Name);
        Vendor1.Modify(true);

        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", GenerateExtDocNo(), Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, -Amount / 2, '', '');
        UpdateBankReconciliationLine(BankAccReconciliationLine, '', Vendor.Name, '', '');

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::Partially,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No, BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");
        VerifyReconciliation(BankPmtApplRule, BankAccReconciliationLine."Statement Line No.");
        VerifyMatchDetailsData(
          BankAccReconciliation, BankPmtApplRule, BankAccReconciliationLine."Account Type"::Vendor, -Amount / 2, 0, 0, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,VerifyMatchDetailsOnPaymentApplicationsPage')]
    [Scope('OnPrem')]
    procedure TestVendExactMatchOnRelatedPartyNameMultipleExactMatchOnCity()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Vendor: Record Vendor;
        Vendor1: Record Vendor;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
    begin
        Initialize();

        // Setup
        CreateVendor(Vendor);
        CreateVendor(Vendor1);
        Vendor1.Validate(Name, Vendor.Name);
        Vendor1.Modify(true);

        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", GenerateExtDocNo(), Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, -Amount / 2, '', '');
        UpdateBankReconciliationLine(BankAccReconciliationLine, '', Vendor.Name, '', Vendor.City);

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::Partially,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No, BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");
        VerifyReconciliation(BankPmtApplRule, BankAccReconciliationLine."Statement Line No.");
        VerifyMatchDetailsData(
          BankAccReconciliation, BankPmtApplRule, BankAccReconciliationLine."Account Type"::Vendor, -Amount / 2, 0, 0, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,VerifyMatchDetailsOnPaymentApplicationsPage')]
    [Scope('OnPrem')]
    procedure TestVendExactMatchOnRelatedPartyNameMultipleExactMatchOnCityAndAddress()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Vendor: Record Vendor;
        Vendor1: Record Vendor;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
    begin
        Initialize();

        // Setup
        CreateVendor(Vendor);
        CreateVendor(Vendor1);
        Vendor1.Validate(Name, Vendor.Name);
        Vendor1.Modify(true);

        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", GenerateExtDocNo(), Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, -Amount / 2, '', '');
        UpdateBankReconciliationLine(BankAccReconciliationLine, '', Vendor.Name, Vendor.Address, Vendor.City);

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No, BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");
        VerifyReconciliation(BankPmtApplRule, BankAccReconciliationLine."Statement Line No.");
        VerifyMatchDetailsData(
          BankAccReconciliation, BankPmtApplRule, BankAccReconciliationLine."Account Type"::Vendor, -Amount / 2, 0, 0, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,VerifyMatchDetailsOnPaymentApplicationsPage')]
    [Scope('OnPrem')]
    procedure TestVendWithSpecialCharsInRelatedPartyNameExactMatchSingle()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Vendor: Record Vendor;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
    begin
        Initialize();

        // Setup
        CreateVendor(Vendor);
        Vendor.Name := GenerateRandomSmallLettersWithSpaces(50);
        Vendor.Modify();
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", GenerateExtDocNo(), Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, -Amount / 2, '', '');
        UpdateBankReconciliationLine(BankAccReconciliationLine, '', Vendor.Name, '', '');

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No, BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");
        VerifyReconciliation(BankPmtApplRule, BankAccReconciliationLine."Statement Line No.");
        VerifyMatchDetailsData(
          BankAccReconciliation, BankPmtApplRule, BankAccReconciliationLine."Account Type"::Vendor, -Amount / 2, 0, 0, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,VerifyMatchDetailsOnPaymentApplicationsPage')]
    [Scope('OnPrem')]
    procedure TestVendExactMatchOnOtherNameSingle()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Vendor: Record Vendor;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
    begin
        Initialize();

        // Setup
        CreateVendor(Vendor);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", GenerateExtDocNo(), Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, -Amount / 2, Vendor.Name, '');

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No, BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");
        VerifyReconciliation(BankPmtApplRule, BankAccReconciliationLine."Statement Line No.");
        VerifyMatchDetailsData(
          BankAccReconciliation, BankPmtApplRule, BankAccReconciliationLine."Account Type"::Vendor, -Amount / 2, 0, 0, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,VerifyMatchDetailsOnPaymentApplicationsPage')]
    [Scope('OnPrem')]
    procedure TestVendExactMatchOnOtherNameMultiple()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Vendor: Record Vendor;
        Vendor1: Record Vendor;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
    begin
        Initialize();

        // Setup
        CreateVendor(Vendor);
        CreateVendor(Vendor1);
        Vendor1.Validate(Name, Vendor.Name);
        Vendor1.Modify(true);

        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", GenerateExtDocNo(), Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, -Amount / 2, Vendor.Name, '');

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::Partially,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No, BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");
        VerifyReconciliation(BankPmtApplRule, BankAccReconciliationLine."Statement Line No.");
        VerifyMatchDetailsData(
          BankAccReconciliation, BankPmtApplRule, BankAccReconciliationLine."Account Type"::Vendor, -Amount / 2, 0, 0, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,VerifyMatchDetailsOnPaymentApplicationsPage')]
    [Scope('OnPrem')]
    procedure TestVendorMatchOnExactNameWithPermutations()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Vendor: Record Vendor;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        BankPmtApplSettings: Record "Bank Pmt. Appl. Settings";
        Amount: Decimal;
    begin
        Initialize();

        // Setup
        BankPmtApplSettings.GetOrInsert();
        BankPmtApplSettings."RelatedParty Name Matching" := BankPmtApplSettings."RelatedParty Name Matching"::"Exact Match with Permutations";
        BankPmtApplSettings.Modify();

        CreateVendor(Vendor);
        Vendor.Name := 'JohnName1 DoeName2 Name3John';
        Vendor.Modify();

        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", GenerateExtDocNo(), Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, -Amount / 2,
          Vendor.Name, '');

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No, BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");
        VerifyReconciliation(BankPmtApplRule, BankAccReconciliationLine."Statement Line No.");
        VerifyMatchDetailsData(
          BankAccReconciliation, BankPmtApplRule, BankAccReconciliationLine."Account Type"::Vendor, -Amount / 2, 0, 0, 1);
    end;


    [Test]
    [HandlerFunctions('MessageHandler,VerifyMatchDetailsOnPaymentApplicationsPage')]
    [Scope('OnPrem')]
    procedure TestVendorMatchOnExactNameWithPermutationsNameFilpped()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Vendor: Record Vendor;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        BankPmtApplSettings: Record "Bank Pmt. Appl. Settings";
        Amount: Decimal;
    begin
        Initialize();

        // Setup
        CreateVendor(Vendor);
        Vendor.Name := 'FirstName1 MiddleName2 LastName3';
        Vendor.Modify();

        BankPmtApplSettings.GetOrInsert();
        BankPmtApplSettings."RelatedParty Name Matching" := BankPmtApplSettings."RelatedParty Name Matching"::"Exact Match with Permutations";
        BankPmtApplSettings.Modify();

        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", GenerateExtDocNo(), Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, -Amount / 2,
          'MiddleName2 LastName3 FirstName1', '');

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No, BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");
        VerifyReconciliation(BankPmtApplRule, BankAccReconciliationLine."Statement Line No.");
        VerifyMatchDetailsData(
          BankAccReconciliation, BankPmtApplRule, BankAccReconciliationLine."Account Type"::Vendor, -Amount / 2, 0, 0, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,VerifyMatchDetailsOnPaymentApplicationsPage')]
    [Scope('OnPrem')]
    procedure TestVendorMatchOnExactNameWithPermutationsNoMatch()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Vendor: Record Vendor;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        BankPmtApplSettings: Record "Bank Pmt. Appl. Settings";
        Amount: Decimal;
    begin
        Initialize();

        // Setup
        BankPmtApplSettings.GetOrInsert();
        BankPmtApplSettings."RelatedParty Name Matching" := BankPmtApplSettings."RelatedParty Name Matching"::"Exact Match with Permutations";
        BankPmtApplSettings.Modify();

        CreateVendor(Vendor);

        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", GenerateExtDocNo(), Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, -Amount / 2,
          'Payment for invoice x', '');

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No, BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");
        VerifyMatchDetailsData(
          BankAccReconciliation, BankPmtApplRule, BankAccReconciliationLine."Account Type"::Vendor, -Amount / 2, 0, 0, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,VerifyMatchDetailsOnPaymentApplicationsPage')]
    [Scope('OnPrem')]
    procedure TestVendCloseMatchOnOtherNameSingle()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Vendor: Record Vendor;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
    begin
        Initialize();

        // Setup
        CreateVendor(Vendor);

        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", GenerateExtDocNo(), Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, -Amount / 2,
          CopyStr(Vendor.Name, 1, StrLen(Vendor.Name) - 1), '');

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No, BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");
        VerifyReconciliation(BankPmtApplRule, BankAccReconciliationLine."Statement Line No.");
        VerifyMatchDetailsData(
          BankAccReconciliation, BankPmtApplRule, BankAccReconciliationLine."Account Type"::Vendor, -Amount / 2, 0, 0, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,VerifyMatchDetailsOnPaymentApplicationsPage')]
    [Scope('OnPrem')]
    procedure TestVendCloseMatchOnOtherNameMultiple()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Vendor: Record Vendor;
        Vendor1: Record Vendor;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
    begin
        Initialize();

        // Setup
        CreateVendor(Vendor);
        CreateVendor(Vendor1);
        Vendor1.Validate(Name, Vendor.Name);
        Vendor1.Modify(true);

        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", GenerateExtDocNo(), Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, -Amount / 2,
          CopyStr(Vendor.Name, 1, StrLen(Vendor.Name) - 1), '');

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::Partially,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No, BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");
        VerifyReconciliation(BankPmtApplRule, BankAccReconciliationLine."Statement Line No.");
        VerifyMatchDetailsData(
          BankAccReconciliation, BankPmtApplRule, BankAccReconciliationLine."Account Type"::Vendor, -Amount / 2, 0, 0, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,VerifyMatchDetailsOnPaymentApplicationsPage')]
    [Scope('OnPrem')]
    procedure TestVendPartialMatchOnOtherName()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Vendor: Record Vendor;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        MatchBankPayments: Codeunit "Match Bank Payments";
        Amount: Decimal;
        Length: Integer;
    begin
        Initialize();

        // Setup
        CreateVendor(Vendor);

        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", GenerateExtDocNo(), Amount);

        Length := Round(MatchBankPayments.GetExactMatchTreshold() / MatchBankPayments.GetNormalizingFactor() *
            StrLen(Vendor.Name) + 1, 1);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, -Amount / 2,
          GenerateRandomSmallLetters(StrLen(Vendor.Name) - Length) + CopyStr(Vendor.Name, 1, Length), '');

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No, BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");
        VerifyReconciliation(BankPmtApplRule, BankAccReconciliationLine."Statement Line No.");
        VerifyMatchDetailsData(
          BankAccReconciliation, BankPmtApplRule, BankAccReconciliationLine."Account Type"::Vendor, -Amount / 2, 0, 0, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,VerifyMatchDetailsOnPaymentApplicationsPage')]
    [Scope('OnPrem')]
    procedure TestVendCertainAndMultipleAmountMatch()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Vendor: Record Vendor;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        VendorBankAccount: Record "Vendor Bank Account";
        Amount: Decimal;
    begin
        Initialize();

        // Setup
        CreateVendor(Vendor);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", GenerateExtDocNo(), Amount);
        CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", GenerateExtDocNo(), Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, -Amount, '', '');
        UpdateBankReconciliationLine(BankAccReconciliationLine, BankAccReconciliation."Bank Account No.", '', '', '');
        CreateVendorBankAccount(VendorBankAccount, Vendor."No.", BankAccReconciliation."Bank Account No.");

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No, BankPmtApplRule."Amount Incl. Tolerance Matched"::"Multiple Matches");
        VerifyReconciliation(BankPmtApplRule, BankAccReconciliationLine."Statement Line No.");
        VerifyMatchDetailsData(BankAccReconciliation, BankPmtApplRule,
          BankAccReconciliationLine."Account Type"::Vendor, -Amount, 0, 2, 0);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,VerifyMatchDetailsOnPaymentApplicationsPage')]
    [Scope('OnPrem')]
    procedure TestVendCertainAndSingleAmountMatch()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Vendor: Record Vendor;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        VendorBankAccount: Record "Vendor Bank Account";
        Amount: Decimal;
    begin
        Initialize();

        // Setup
        CreateVendor(Vendor);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", GenerateExtDocNo(), Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, -Amount, '', '');
        UpdateBankReconciliationLine(BankAccReconciliationLine, BankAccReconciliation."Bank Account No.", '', '', '');
        CreateVendorBankAccount(VendorBankAccount, Vendor."No.", BankAccReconciliation."Bank Account No.");

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No, BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match");
        VerifyReconciliation(BankPmtApplRule, BankAccReconciliationLine."Statement Line No.");
        VerifyMatchDetailsData(BankAccReconciliation, BankPmtApplRule,
          BankAccReconciliationLine."Account Type"::Vendor, -Amount, 0, 1, 0);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,VerifyMatchDetailsOnPaymentApplicationsPage')]
    [Scope('OnPrem')]
    procedure TestVendCertainMatchAndDocNo()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Vendor: Record Vendor;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
        DocumentNo: Code[20];
    begin
        Initialize();

        // Setup
        CreateVendor(Vendor);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        DocumentNo := CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", GenerateExtDocNo(), Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, -Amount / 2, DocumentNo, '');
        UpdateBankReconciliationLine(BankAccReconciliationLine, '', Vendor.Name, '', '');

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes, BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");
        VerifyReconciliation(BankPmtApplRule, BankAccReconciliationLine."Statement Line No.");
        VerifyMatchDetailsData(BankAccReconciliation, BankPmtApplRule,
          BankAccReconciliationLine."Account Type"::Vendor, -Amount / 2, 0, 0, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,VerifyMatchDetailsOnPaymentApplicationsPage')]
    [Scope('OnPrem')]
    procedure TestVendCertainMatchAndExtDocNo()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Vendor: Record Vendor;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
        ExtDocNo: Code[20];
    begin
        Initialize();

        // Setup
        CreateVendor(Vendor);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        ExtDocNo := GenerateExtDocNo();
        CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", ExtDocNo, Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, -Amount / 2, '', ExtDocNo);
        UpdateBankReconciliationLine(BankAccReconciliationLine, '', Vendor.Name, '', '');

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes, BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");
        VerifyReconciliation(BankPmtApplRule, BankAccReconciliationLine."Statement Line No.");
        VerifyMatchDetailsData(BankAccReconciliation, BankPmtApplRule,
          BankAccReconciliationLine."Account Type"::Vendor, -Amount / 2, 0, 0, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,VerifyMatchDetailsOnPaymentApplicationsPage')]
    [Scope('OnPrem')]
    procedure TestVenCertainMatchAndDocNoAndAmount()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Vendor: Record Vendor;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
        DocumentNo: Code[20];
        ExtDocNo: Code[20];
    begin
        Initialize();

        // Setup
        CreateVendor(Vendor);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        ExtDocNo := GenerateExtDocNo();
        DocumentNo := CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", ExtDocNo, Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, -Amount, ExtDocNo, DocumentNo);
        UpdateBankReconciliationLine(BankAccReconciliationLine, '', Vendor.Name, '', '');

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes, BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match");
        VerifyReconciliation(BankPmtApplRule, BankAccReconciliationLine."Statement Line No.");
        VerifyMatchDetailsData(BankAccReconciliation, BankPmtApplRule,
          BankAccReconciliationLine."Account Type"::Vendor, -Amount, 0, 1, 0);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,VerifyMatchDetailsOnPaymentApplicationsPage')]
    [Scope('OnPrem')]
    procedure TestVendCertainMatchAndDocNoAndAmountWithAmountTolerance()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Vendor: Record Vendor;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
        DocumentNo: Code[20];
        ExtDocNo: Code[20];
        Tolerance: Decimal;
    begin
        Initialize();

        // Setup
        CreateVendor(Vendor);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        Tolerance := Round(Amount / 4, 0.01);
        ExtDocNo := GenerateExtDocNo();
        DocumentNo := CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", ExtDocNo, Amount - Tolerance);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, Tolerance);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, -Amount, ExtDocNo, DocumentNo);
        UpdateBankReconciliationLine(BankAccReconciliationLine, '', Vendor.Name, '', '');

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes, BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match");
        VerifyReconciliation(BankPmtApplRule, BankAccReconciliationLine."Statement Line No.");
        VerifyMatchDetailsData(BankAccReconciliation, BankPmtApplRule,
          BankAccReconciliationLine."Account Type"::Vendor, -Amount, Tolerance, 1, 0);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestVendMatchCheckApplicationPriorities()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine1: Record "Bank Acc. Reconciliation Line";
        BankAccReconciliationLine2: Record "Bank Acc. Reconciliation Line";
        Vendor: Record Vendor;
        DocumentNo: Code[20];
        Amount: Decimal;
    begin
        Initialize();

        // Setup
        CreateVendor(Vendor);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        DocumentNo := CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", GenerateExtDocNo(), Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine1, -Amount / 2, DocumentNo, '');
        UpdateBankReconciliationLine(BankAccReconciliationLine1, '', Vendor.Name, '', '');
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine2, -Amount / 2, DocumentNo, '');

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        VerifyEntryApplied(BankAccReconciliationLine1, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestVendMatchCheckNoApplication()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine1: Record "Bank Acc. Reconciliation Line";
        BankAccReconciliationLine2: Record "Bank Acc. Reconciliation Line";
        Vendor: Record Vendor;
        DocumentNo: Code[20];
        Amount: Decimal;
    begin
        Initialize();

        // Setup
        CreateVendor(Vendor);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        DocumentNo := CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", GenerateExtDocNo(), Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine1, -Amount / 2, DocumentNo, '');
        UpdateBankReconciliationLine(BankAccReconciliationLine1, '', Vendor.Name, '', '');
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine2, -Amount / 2, DocumentNo, '');

        // Exercise
        RunMatch(BankAccReconciliation, false);

        // Verify
        VerifyEntriesNotAppliedForStatement(BankAccReconciliation);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestVendTextMapper()
    var
        TextToAccMapping: Record "Text-to-Account Mapping";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Vendor: Record Vendor;
        Amount: Decimal;
        TextMapper: Text[140];
    begin
        Initialize();

        // Setup
        CreateVendor(Vendor);
        TextMapper := GenerateTextToAccountMapping();
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", GenerateExtDocNo(), Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, -Amount * 2, TextMapper, '');

        // Exercise
        LibraryERM.CreateAccountMappingGLAccount(TextToAccMapping, TextMapper, LibraryERM.CreateGLAccountNo(), '');

        RunMatch(BankAccReconciliation, true);

        // Verify
        VerifyEntryApplied(BankAccReconciliationLine, true);
        VerifyTextEntryApplied(BankAccReconciliationLine."Statement Line No.");
    end;

    local procedure VendRerunTextMapper(RunFirst: Boolean)
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Vendor: Record Vendor;
        PaymentReconciliationJournal: TestPage "Payment Reconciliation Journal";
        Amount: Decimal;
        TextMapper: Text[140];
    begin
        Initialize();

        // Setup
        CreateVendor(Vendor);
        TextMapper := GenerateTextToAccountMapping();
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", GenerateExtDocNo(), Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, -Amount * 2, TextMapper, '');

        if RunFirst then begin
            RunMatch(BankAccReconciliation, true);

            // Partial verify
            VerifyNoMatch(BankAccReconciliationLine."Statement Line No.");
        end;

        // Exercise
        PaymentReconciliationJournal.Trap();
        OpenPaymentRecJournal(BankAccReconciliation);
        PaymentReconciliationJournal.AddMappingRule.Invoke();

        // Verify
        VerifyEntryApplied(BankAccReconciliationLine, true);
    end;

    [Test]
    [HandlerFunctions('TextMapperModalPageHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestVendRerunOnlyTextMapper()
    begin
        VendRerunTextMapper(false);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,TextMapperModalPageHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestVendRunAndRerunTextMapper()
    begin
        VendRerunTextMapper(true);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestVendTextMapperOverriden()
    var
        TextToAccMapping: Record "Text-to-Account Mapping";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Vendor: Record Vendor;
        DocumentNo: Code[20];
        Amount: Decimal;
        TextMapper: Text[140];
    begin
        Initialize();

        // Setup
        CreateVendor(Vendor);
        TextMapper := GenerateTextToAccountMapping();
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        DocumentNo := CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", GenerateExtDocNo(), Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, -Amount, TextMapper, DocumentNo);
        UpdateBankReconciliationLine(BankAccReconciliationLine, '', Vendor.Name, '', '');

        // Exercise
        LibraryERM.CreateAccountMappingGLAccount(TextToAccMapping, TextMapper, LibraryERM.CreateGLAccountNo(), '');

        RunMatch(BankAccReconciliation, true);

        // Verify
        VerifyEntryApplied(BankAccReconciliationLine, false);
        VerifyTextEntryConsidered(BankAccReconciliationLine."Statement Line No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestVendTextMapperToVendor()
    var
        TextToAccMapping: Record "Text-to-Account Mapping";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Vendor: Record Vendor;
        Amount: Decimal;
        TextMapper: Text[140];
    begin
        Initialize();

        // Setup
        CreateVendor(Vendor);
        TextMapper := GenerateTextToAccountMapping();
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", GenerateExtDocNo(), Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, -Amount * 2, TextMapper, '');

        // Exercise
        LibraryERM.CreateAccountMappingVendor(TextToAccMapping, TextMapper, Vendor."No.");

        RunMatch(BankAccReconciliation, true);

        // Verify
        VerifyEntryApplied(BankAccReconciliationLine, true);
        VerifyTextEntryApplied(BankAccReconciliationLine."Statement Line No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestVendorFirstMatchOnDocumentNoInsertsMultipleMatchLine()
    var
        TempBankStmtMultipleMatchLine: Record "Bank Stmt Multiple Match Line" temporary;
        TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary;
        TempLedgerEntryMatchingBuffer: Record "Ledger Entry Matching Buffer" temporary;
        OneToManyTempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary;
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Amount: Decimal;
        DocumentNo: Code[20];
        UsePaymentDiscounts: Boolean;
    begin
        Initialize();

        // Setup
        CreateVendor(Vendor);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        DocumentNo := CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", GenerateExtDocNo(), Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, -Amount, '', DocumentNo);
        UpdateBankReconciliationLine(BankAccReconciliationLine, '', Vendor.Name, '', '');

        GetVendorLedgerEntry(VendorLedgerEntry, Vendor, DocumentNo);

        TempLedgerEntryMatchingBuffer.InsertFromVendorLedgerEntry(VendorLedgerEntry, true, UsePaymentDiscounts);
        CreateOneToManyBankStatementMatchingBufferLine(
          TempBankStatementMatchingBuffer, TempBankStmtMultipleMatchLine, TempLedgerEntryMatchingBuffer,
          BankAccReconciliationLine, TempBankStatementMatchingBuffer."Account Type"::Vendor);

        // Verify
        GetOneToManyBankStatementMatchingBuffer(OneToManyTempBankStatementMatchingBuffer, TempBankStatementMatchingBuffer);
        VerifyOneToOneBankStatementMatchingBufferLine(TempBankStatementMatchingBuffer, VendorLedgerEntry."Entry No.");
        VerifyOneToManyTempBankStatementMatchingBufferLine(
          TempBankStmtMultipleMatchLine, OneToManyTempBankStatementMatchingBuffer, 1, VendorLedgerEntry."Remaining Amount");
        Assert.AreEqual(
          VendorLedgerEntry."Entry No.", TempBankStmtMultipleMatchLine."Entry No.",
          'Entry no. was not set correctly on TempBankStmtMultipleMatchLine');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestVendorSecondMatchOnDocumentNoUpdatesMultipleMatchLine()
    var
        TempBankStmtMultipleMatchLine: Record "Bank Stmt Multiple Match Line" temporary;
        TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary;
        TempLedgerEntryMatchingBuffer: Record "Ledger Entry Matching Buffer" temporary;
        OneToManyTempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary;
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
        Amount: Decimal;
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
        ExpectedNoOfLines: Integer;
        ExpectedRemainingAmount: Decimal;
        UsePaymentDiscounts: Boolean;
    begin
        Initialize();

        // Setup
        CreateVendor(Vendor);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        DocumentNo := CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", GenerateExtDocNo(), Amount);
        DocumentNo2 := CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", GenerateExtDocNo(), Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, -Amount, '', DocumentNo + ' ' + DocumentNo2);
        UpdateBankReconciliationLine(BankAccReconciliationLine, '', Vendor.Name, '', '');

        GetVendorLedgerEntry(VendorLedgerEntry, Vendor, DocumentNo);
        GetVendorLedgerEntry(VendorLedgerEntry2, Vendor, DocumentNo2);

        // Execute
        TempLedgerEntryMatchingBuffer.InsertFromVendorLedgerEntry(VendorLedgerEntry, true, UsePaymentDiscounts);
        CreateOneToManyBankStatementMatchingBufferLine(
          TempBankStatementMatchingBuffer, TempBankStmtMultipleMatchLine, TempLedgerEntryMatchingBuffer,
          BankAccReconciliationLine, TempBankStatementMatchingBuffer."Account Type"::Vendor);

        TempLedgerEntryMatchingBuffer.InsertFromVendorLedgerEntry(VendorLedgerEntry2, true, UsePaymentDiscounts);
        CreateOneToManyBankStatementMatchingBufferLine(
          TempBankStatementMatchingBuffer, TempBankStmtMultipleMatchLine, TempLedgerEntryMatchingBuffer,
          BankAccReconciliationLine, TempBankStatementMatchingBuffer."Account Type"::Vendor);

        // Verify
        VerifyOneToOneBankStatementMatchingBufferLine(TempBankStatementMatchingBuffer, VendorLedgerEntry2."Entry No.");

        GetOneToManyBankStatementMatchingBuffer(OneToManyTempBankStatementMatchingBuffer, TempBankStatementMatchingBuffer);
        ExpectedNoOfLines := 2;
        ExpectedRemainingAmount := VendorLedgerEntry."Remaining Amount" + VendorLedgerEntry2."Remaining Amount";
        VerifyOneToManyTempBankStatementMatchingBufferLine(
          TempBankStmtMultipleMatchLine, OneToManyTempBankStatementMatchingBuffer, ExpectedNoOfLines, ExpectedRemainingAmount);

        Assert.AreEqual(
          VendorLedgerEntry."Entry No.", TempBankStmtMultipleMatchLine."Entry No.",
          'Entry no. was not set correctly on TempBankStmtMultipleMatchLine');
        TempBankStmtMultipleMatchLine.Next();
        Assert.AreEqual(
          VendorLedgerEntry2."Entry No.", TempBankStmtMultipleMatchLine."Entry No.",
          'Entry no. was not set correctly on TempBankStmtMultipleMatchLine');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestVendorMultipleMatchRuleIsNotCreatedForDifferentVendors()
    var
        TempBankStmtMultipleMatchLine: Record "Bank Stmt Multiple Match Line" temporary;
        TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary;
        TempLedgerEntryMatchingBuffer: Record "Ledger Entry Matching Buffer" temporary;
        OneToManyTempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary;
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Vendor: Record Vendor;
        Vendor2: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
        Amount: Decimal;
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
        UsePaymentDiscounts: Boolean;
    begin
        Initialize();

        // Setup
        CreateVendor(Vendor);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        DocumentNo := CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", GenerateExtDocNo(), Amount);

        CreateVendor(Vendor2);
        DocumentNo2 := CreateAndPostPurchaseInvoiceWithOneLine(Vendor2."No.", GenerateExtDocNo(), Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, -Amount, '', DocumentNo + ' ' + DocumentNo2);
        UpdateBankReconciliationLine(BankAccReconciliationLine, '', Vendor.Name, '', '');

        GetVendorLedgerEntry(VendorLedgerEntry, Vendor, DocumentNo);
        GetVendorLedgerEntry(VendorLedgerEntry2, Vendor2, DocumentNo2);

        // Execute
        TempLedgerEntryMatchingBuffer.InsertFromVendorLedgerEntry(VendorLedgerEntry, true, UsePaymentDiscounts);
        CreateOneToManyBankStatementMatchingBufferLine(
          TempBankStatementMatchingBuffer, TempBankStmtMultipleMatchLine, TempLedgerEntryMatchingBuffer,
          BankAccReconciliationLine, TempBankStatementMatchingBuffer."Account Type"::Vendor);

        TempLedgerEntryMatchingBuffer.InsertFromVendorLedgerEntry(VendorLedgerEntry2, true, UsePaymentDiscounts);
        CreateOneToManyBankStatementMatchingBufferLine(
          TempBankStatementMatchingBuffer, TempBankStmtMultipleMatchLine, TempLedgerEntryMatchingBuffer,
          BankAccReconciliationLine, TempBankStatementMatchingBuffer."Account Type"::Vendor);

        // Verify First Entry
        GetOneToOneBankStatementMatchingBuffer(TempBankStatementMatchingBuffer, VendorLedgerEntry."Entry No.");
        VerifyOneToOneBankStatementMatchingBufferLine(TempBankStatementMatchingBuffer, VendorLedgerEntry."Entry No.");
        GetOneToManyBankStatementMatchingBuffer(OneToManyTempBankStatementMatchingBuffer, TempBankStatementMatchingBuffer);
        VerifyOneToManyTempBankStatementMatchingBufferLine(
          TempBankStmtMultipleMatchLine, OneToManyTempBankStatementMatchingBuffer, 1, VendorLedgerEntry."Remaining Amount");
        Assert.AreEqual(
          VendorLedgerEntry."Entry No.", TempBankStmtMultipleMatchLine."Entry No.",
          'Entry no. was not set correctly on TempBankStmtMultipleMatchLine');

        // Verify Second Entry
        GetOneToOneBankStatementMatchingBuffer(TempBankStatementMatchingBuffer, VendorLedgerEntry2."Entry No.");
        GetOneToManyBankStatementMatchingBuffer(OneToManyTempBankStatementMatchingBuffer, TempBankStatementMatchingBuffer);
        VerifyOneToOneBankStatementMatchingBufferLine(TempBankStatementMatchingBuffer, VendorLedgerEntry2."Entry No.");
        VerifyOneToManyTempBankStatementMatchingBufferLine(
          TempBankStmtMultipleMatchLine, OneToManyTempBankStatementMatchingBuffer, 1, VendorLedgerEntry2."Remaining Amount");
        TempBankStmtMultipleMatchLine.Next();
        Assert.AreEqual(
          VendorLedgerEntry2."Entry No.", TempBankStmtMultipleMatchLine."Entry No.",
          'Entry no. was not set correctly on TempBankStmtMultipleMatchLine');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestVendorMultipleMatchAllEntriesFullyApplied()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        AppliedPaymentEntry: Record "Applied Payment Entry";
        Amount: Decimal;
        Amount2: Decimal;
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
        AppliedAmount: Decimal;
        Difference: Decimal;
        ExpectedNoOfEntries: Integer;
        Quality: Integer;
    begin
        Initialize();

        // Setup
        CreateVendor(Vendor);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        DocumentNo := CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", GenerateExtDocNo(), Amount);

        Amount2 := LibraryRandom.RandDecInRange(1, 1000, 2);
        DocumentNo2 := CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", GenerateExtDocNo(), Amount2);

        AppliedAmount := -Amount - Amount2;

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, AppliedAmount, '', DocumentNo + ' ' + DocumentNo2);
        UpdateBankReconciliationLine(BankAccReconciliationLine, '', Vendor.Name, '', '');

        GetVendorLedgerEntry(VendorLedgerEntry, Vendor, DocumentNo);
        GetVendorLedgerEntry(VendorLedgerEntry2, Vendor, DocumentNo2);

        RunMatch(BankAccReconciliation, true);

        // Verify Bank Account ReconciliationLine
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Yes - Multiple",
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match");

        Difference := 0;
        ExpectedNoOfEntries := 2;

        Quality := TempBankPmtApplRule.GetBestMatchScore(BankPmtApplRule);
        VerifyMultipleApplicationsBankAccReconciliationLine(
          BankAccReconciliationLine, Quality, Difference, AppliedAmount, BankAccReconciliationLine."Account Type"::Vendor, Vendor."No.",
          ExpectedNoOfEntries);

        // Verify Applied Payment Entries
        GetAppliedPaymentEntries(AppliedPaymentEntry, BankAccReconciliationLine);
        Assert.AreEqual(AppliedPaymentEntry.Count, ExpectedNoOfEntries, 'Wrong number of Applied Payment Entries Found');
        AppliedPaymentEntry.FindFirst();
        VerifyMultipleApplicationsAppliedEntries(AppliedPaymentEntry, Quality, -Amount, VendorLedgerEntry."Entry No.");
        AppliedPaymentEntry.Next();
        VerifyMultipleApplicationsAppliedEntries(AppliedPaymentEntry, Quality, -Amount2, VendorLedgerEntry2."Entry No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestVendorMultipleMatchUserOverPaid()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        AppliedPaymentEntry: Record "Applied Payment Entry";
        Amount: Decimal;
        Amount2: Decimal;
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
        AppliedAmount: Decimal;
        StatementAmount: Decimal;
        Difference: Decimal;
        ExpectedNoOfEntries: Integer;
        Quality: Integer;
    begin
        Initialize();

        // Setup
        CreateVendor(Vendor);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        DocumentNo := CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", GenerateExtDocNo(), Amount);

        Amount2 := LibraryRandom.RandDecInRange(1, 1000, 2);
        DocumentNo2 := CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", GenerateExtDocNo(), Amount2);

        AppliedAmount := -Amount - Amount2;
        StatementAmount := 2 * AppliedAmount;

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, StatementAmount, '', DocumentNo + ' ' + DocumentNo2);
        UpdateBankReconciliationLine(BankAccReconciliationLine, '', Vendor.Name, '', '');

        GetVendorLedgerEntry(VendorLedgerEntry, Vendor, DocumentNo);
        GetVendorLedgerEntry(VendorLedgerEntry2, Vendor, DocumentNo2);

        RunMatch(BankAccReconciliation, true);

        // Verify Bank Account ReconciliationLine
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Yes - Multiple",
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");

        Difference := StatementAmount - AppliedAmount;
        ExpectedNoOfEntries := 2;
        Quality := TempBankPmtApplRule.GetBestMatchScore(BankPmtApplRule);

        VerifyMultipleApplicationsBankAccReconciliationLine(
          BankAccReconciliationLine, Quality, Difference, AppliedAmount, BankAccReconciliationLine."Account Type"::Vendor, Vendor."No.",
          ExpectedNoOfEntries);

        // Verify Applied Payment Entries
        GetAppliedPaymentEntries(AppliedPaymentEntry, BankAccReconciliationLine);
        Assert.AreEqual(AppliedPaymentEntry.Count, ExpectedNoOfEntries, 'Wrong number of Applied Payment Entries Found');
        AppliedPaymentEntry.FindFirst();
        VerifyMultipleApplicationsAppliedEntries(AppliedPaymentEntry, Quality, -Amount, VendorLedgerEntry."Entry No.");
        AppliedPaymentEntry.Next();
        VerifyMultipleApplicationsAppliedEntries(AppliedPaymentEntry, Quality, -Amount2, VendorLedgerEntry2."Entry No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestVendorMultipleMatchAllEntriesAppliedOneUnderPaid()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        AppliedPaymentEntry: Record "Applied Payment Entry";
        Amount: Decimal;
        Amount2: Decimal;
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
        AppliedAmount: Decimal;
        Difference: Decimal;
        ExpectedNoOfEntries: Integer;
        Quality: Integer;
    begin
        Initialize();

        // Setup
        CreateVendor(Vendor);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        DocumentNo := CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", GenerateExtDocNo(), Amount);

        Amount2 := LibraryRandom.RandDecInRange(1, 1000, 2);
        DocumentNo2 := CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", GenerateExtDocNo(), Amount2);

        AppliedAmount := -Amount - Amount2 + Round(Amount2 / 2, LibraryERM.GetAmountRoundingPrecision());

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, AppliedAmount, '', DocumentNo + ' ' + DocumentNo2);
        UpdateBankReconciliationLine(BankAccReconciliationLine, '', Vendor.Name, '', '');

        GetVendorLedgerEntry(VendorLedgerEntry, Vendor, DocumentNo);
        GetVendorLedgerEntry(VendorLedgerEntry2, Vendor, DocumentNo2);

        RunMatch(BankAccReconciliation, true);

        // Verify Bank Account ReconciliationLine
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Yes - Multiple",
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");

        Difference := 0;
        ExpectedNoOfEntries := 2;
        Quality := TempBankPmtApplRule.GetBestMatchScore(BankPmtApplRule);

        VerifyMultipleApplicationsBankAccReconciliationLine(
          BankAccReconciliationLine, Quality, Difference, AppliedAmount, BankAccReconciliationLine."Account Type"::Vendor, Vendor."No.",
          ExpectedNoOfEntries);

        // Verify Applied Payment Entries
        GetAppliedPaymentEntries(AppliedPaymentEntry, BankAccReconciliationLine);
        Assert.AreEqual(AppliedPaymentEntry.Count, ExpectedNoOfEntries, 'Wrong number of Applied Payment Entries Found');
        AppliedPaymentEntry.FindFirst();
        VerifyMultipleApplicationsAppliedEntries(AppliedPaymentEntry, Quality, -Amount, VendorLedgerEntry."Entry No.");
        AppliedPaymentEntry.Next();
        VerifyMultipleApplicationsAppliedEntries(
          AppliedPaymentEntry, Quality, -Amount2 + Round(Amount2 / 2, LibraryERM.GetAmountRoundingPrecision()),
          VendorLedgerEntry2."Entry No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestVendorMultipleMatchGetOverridenByHigherConfidenceOneToOneMatch()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        AppliedPaymentEntry: Record "Applied Payment Entry";
        Amount: Decimal;
        Amount2: Decimal;
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
        AppliedAmount: Decimal;
        Difference: Decimal;
        ExpectedNoOfEntries: Integer;
        Quality: Integer;
    begin
        Initialize();

        // Setup
        CreateVendor(Vendor);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        DocumentNo := CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", GenerateExtDocNo(), Amount);

        Amount2 := LibraryRandom.RandDecInRange(1, 1000, 2);
        DocumentNo2 := CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", GenerateExtDocNo(), Amount2);

        AppliedAmount := -Amount;

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, AppliedAmount, '', DocumentNo + ' ' + DocumentNo2);
        UpdateBankReconciliationLine(BankAccReconciliationLine, '', Vendor.Name, '', '');

        GetVendorLedgerEntry(VendorLedgerEntry, Vendor, DocumentNo);

        RunMatch(BankAccReconciliation, true);

        // Verify Bank Account ReconciliationLine
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes, BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match");

        Difference := 0;
        ExpectedNoOfEntries := 1;
        Quality := TempBankPmtApplRule.GetBestMatchScore(BankPmtApplRule);

        VerifyMultipleApplicationsBankAccReconciliationLine(
          BankAccReconciliationLine, TempBankPmtApplRule.GetBestMatchScore(BankPmtApplRule), Difference, AppliedAmount,
          BankAccReconciliationLine."Account Type"::Vendor, Vendor."No.", ExpectedNoOfEntries);

        // Verify Applied Payment Entries
        GetAppliedPaymentEntries(AppliedPaymentEntry, BankAccReconciliationLine);
        Assert.AreEqual(AppliedPaymentEntry.Count, ExpectedNoOfEntries, 'Wrong number of Applied Payment Entries Found');

        AppliedPaymentEntry.FindFirst();
        VerifyMultipleApplicationsAppliedEntries(AppliedPaymentEntry, Quality, -Amount, VendorLedgerEntry."Entry No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestVendorMultipleMatchAllEntriesAppliedOneNotPaidOneUnderPaid()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        AppliedPaymentEntry: Record "Applied Payment Entry";
        Amount: Decimal;
        Amount2: Decimal;
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
        AppliedAmount: Decimal;
        Difference: Decimal;
        ExpectedNoOfEntries: Integer;
        Quality: Integer;
    begin
        Initialize();

        // Setup
        CreateVendor(Vendor);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        DocumentNo := CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", GenerateExtDocNo(), Amount);

        Amount2 := LibraryRandom.RandDecInRange(1, 1000, 2);
        DocumentNo2 := CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", GenerateExtDocNo(), Amount2);

        AppliedAmount := Round(-Amount / 2, LibraryERM.GetAmountRoundingPrecision());

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, AppliedAmount, '', DocumentNo + ' ' + DocumentNo2);
        UpdateBankReconciliationLine(BankAccReconciliationLine, '', Vendor.Name, '', '');

        GetVendorLedgerEntry(VendorLedgerEntry, Vendor, DocumentNo);

        RunMatch(BankAccReconciliation, true);

        // Verify Bank Account ReconciliationLine
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Yes - Multiple",
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");

        Difference := 0;
        ExpectedNoOfEntries := 1;
        Quality := TempBankPmtApplRule.GetBestMatchScore(BankPmtApplRule);

        VerifyMultipleApplicationsBankAccReconciliationLine(
          BankAccReconciliationLine, TempBankPmtApplRule.GetBestMatchScore(BankPmtApplRule), Difference, AppliedAmount,
          BankAccReconciliationLine."Account Type"::Vendor, Vendor."No.", ExpectedNoOfEntries);

        // Verify Applied Payment Entries
        GetAppliedPaymentEntries(AppliedPaymentEntry, BankAccReconciliationLine);
        Assert.AreEqual(AppliedPaymentEntry.Count, ExpectedNoOfEntries, 'Wrong number of Applied Payment Entries Found');
        AppliedPaymentEntry.FindFirst();
        VerifyMultipleApplicationsAppliedEntries(
          AppliedPaymentEntry, Quality, AppliedAmount, VendorLedgerEntry."Entry No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestVendorMultipleMatchWhenCannotApplyEntriesOldestGetAppliedFirst()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
        VendorLedgerEntry3: Record "Vendor Ledger Entry";
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        AppliedPaymentEntry: Record "Applied Payment Entry";
        Amount: Decimal;
        Amount2: Decimal;
        Amount3: Decimal;
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
        DocumentNo3: Code[20];
        AppliedAmount: Decimal;
        Difference: Decimal;
        ExpectedNoOfEntries: Integer;
        DueDate: Date;
        DueDate2: Date;
        DueDate3: Date;
        Quality: Integer;
    begin
        Initialize();

        // Setup
        CreateVendor(Vendor);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        Amount2 := LibraryRandom.RandDecInRange(1, 1000, 2);
        Amount3 := LibraryRandom.RandDecInRange(1, 1000, 2);

        DueDate := WorkDate();
        DueDate2 := CalcDate('<-3D>', DueDate);
        DueDate3 := CalcDate('<1D>', DueDate2);

        DocumentNo := CreateAndPostPurchaseInvoiceWithOneLine2(Vendor."No.", GenerateExtDocNo(), Amount, DueDate);
        DocumentNo2 := CreateAndPostPurchaseInvoiceWithOneLine2(Vendor."No.", GenerateExtDocNo(), Amount2, DueDate2);
        DocumentNo3 := CreateAndPostPurchaseInvoiceWithOneLine2(Vendor."No.", GenerateExtDocNo(), Amount3, DueDate3);

        AppliedAmount := -Amount2 - Round(Amount3 / 2, LibraryERM.GetAmountRoundingPrecision());

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(
          BankAccReconciliation, BankAccReconciliationLine, AppliedAmount, DocumentNo + ' ' + DocumentNo2 + ' ' + DocumentNo3, '');
        UpdateBankReconciliationLine(BankAccReconciliationLine, '', Vendor.Name, '', '');

        GetVendorLedgerEntry(VendorLedgerEntry, Vendor, DocumentNo);
        GetVendorLedgerEntry(VendorLedgerEntry2, Vendor, DocumentNo2);
        GetVendorLedgerEntry(VendorLedgerEntry3, Vendor, DocumentNo3);

        RunMatch(BankAccReconciliation, true);

        // Verify Bank Account ReconciliationLine
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Yes - Multiple",
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");

        Difference := 0;
        ExpectedNoOfEntries := 2;
        Quality := TempBankPmtApplRule.GetBestMatchScore(BankPmtApplRule);

        VerifyMultipleApplicationsBankAccReconciliationLine(
          BankAccReconciliationLine, TempBankPmtApplRule.GetBestMatchScore(BankPmtApplRule), Difference, AppliedAmount,
          BankAccReconciliationLine."Account Type"::Vendor, Vendor."No.", ExpectedNoOfEntries);

        // Verify Applied Payment Entries
        GetAppliedPaymentEntries(AppliedPaymentEntry, BankAccReconciliationLine);
        Assert.AreEqual(AppliedPaymentEntry.Count, ExpectedNoOfEntries, 'Wrong number of Applied Payment Entries Found');
        AppliedPaymentEntry.FindFirst();
        VerifyMultipleApplicationsAppliedEntries(AppliedPaymentEntry, Quality, -Amount2, VendorLedgerEntry2."Entry No.");

        AppliedPaymentEntry.Next();
        VerifyMultipleApplicationsAppliedEntries(AppliedPaymentEntry, Quality, AppliedAmount + Amount2, VendorLedgerEntry3."Entry No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestVendorMultipleMatchTextMapperOverridesMediumConfidenceRule()
    var
        TextToAccMapping: Record "Text-to-Account Mapping";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Vendor: Record Vendor;
        AppliedPaymentEntry: Record "Applied Payment Entry";
        Amount: Decimal;
        DocumentNo: Code[20];
        TextMapper: Code[20];
        Difference: Decimal;
        ExpectedNoOfEntries: Integer;
        Quality: Integer;
    begin
        Initialize();

        // Setup
        CreateVendor(Vendor);
        TextMapper := GenerateTextToAccountMapping();
        LibraryERM.CreateAccountMappingGLAccount(TextToAccMapping, TextMapper, LibraryERM.CreateGLAccountNo(), '');

        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        DocumentNo := CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", GenerateExtDocNo(), Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, -Amount, TextMapper, DocumentNo);
        UpdateBankReconciliationLine(BankAccReconciliationLine, '', '', '', '');

        // Execute
        RunMatch(BankAccReconciliation, true);

        // Verify
        Difference := 0;
        ExpectedNoOfEntries := 1;
        Quality := TempBankPmtApplRule.GetTextMapperScore();

        VerifyMultipleApplicationsBankAccReconciliationLine(
          BankAccReconciliationLine, Quality, Difference, -Amount, BankAccReconciliationLine."Account Type"::"G/L Account",
          TextToAccMapping."Credit Acc. No.", ExpectedNoOfEntries);
        GetAppliedPaymentEntries(AppliedPaymentEntry, BankAccReconciliationLine);
        AppliedPaymentEntry.FindFirst();
        VerifyMultipleApplicationsAppliedEntries(AppliedPaymentEntry, Quality, -Amount, 0);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestVendorMultipleMatchTextMapperDoesntOveriddeHighConfidenceRule()
    var
        TextToAccMapping: Record "Text-to-Account Mapping";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        AppliedPaymentEntry: Record "Applied Payment Entry";
        Amount: Decimal;
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
        TextMapper: Code[20];
        Difference: Decimal;
        ExpectedNoOfEntries: Integer;
        Quality: Integer;
    begin
        Initialize();

        // Setup
        CreateVendor(Vendor);
        TextMapper := GenerateTextToAccountMapping();
        LibraryERM.CreateAccountMappingGLAccount(TextToAccMapping, TextMapper, LibraryERM.CreateGLAccountNo(), '');

        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        DocumentNo := CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", GenerateExtDocNo(), Amount);
        DocumentNo2 := CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", GenerateExtDocNo(), Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(
          BankAccReconciliation, BankAccReconciliationLine, -2 * Amount, TextMapper, DocumentNo + ' ' + DocumentNo2);
        UpdateBankReconciliationLine(BankAccReconciliationLine, '', Vendor.Name, '', '');

        GetVendorLedgerEntry(VendorLedgerEntry, Vendor, DocumentNo);
        GetVendorLedgerEntry(VendorLedgerEntry2, Vendor, DocumentNo2);

        // Execute
        RunMatch(BankAccReconciliation, true);

        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Yes - Multiple",
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match");

        // Verify
        Difference := 0;
        ExpectedNoOfEntries := 2;
        Quality := TempBankPmtApplRule.GetBestMatchScore(BankPmtApplRule);

        VerifyMultipleApplicationsBankAccReconciliationLine(
          BankAccReconciliationLine, Quality, Difference, -2 * Amount, BankAccReconciliationLine."Account Type"::Vendor, Vendor."No.",
          ExpectedNoOfEntries);
        GetAppliedPaymentEntries(AppliedPaymentEntry, BankAccReconciliationLine);
        AppliedPaymentEntry.FindFirst();
        VerifyMultipleApplicationsAppliedEntries(AppliedPaymentEntry, Quality, -Amount, VendorLedgerEntry."Entry No.");
        AppliedPaymentEntry.Next();
        VerifyMultipleApplicationsAppliedEntries(AppliedPaymentEntry, Quality, -Amount, VendorLedgerEntry2."Entry No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestVendorMultipleMatchOneHitMultipleMatchesAreRemoved()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Vendor: Record Vendor;
        Amount: Decimal;
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
    begin
        Initialize();

        // Setup
        CreateVendor(Vendor);

        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        DocumentNo := CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", GenerateExtDocNo(), Amount);
        DocumentNo2 := CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", GenerateExtDocNo(), Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, -2 * Amount, '', DocumentNo + ' ' + DocumentNo2);
        UpdateBankReconciliationLine(BankAccReconciliationLine, '', Vendor.Name, '', '');

        // Execute
        RunMatch(BankAccReconciliation, true);
        TempBankStatementMatchingBuffer.Reset();
        Assert.AreEqual(
          3, TempBankStatementMatchingBuffer.Count, 'There should be two single mach entries and one multiple match entry present');

        Assert.AreEqual(
          3, TempBankStatementMatchingBuffer.Count, 'There should be two single mach entries and one multiple match entry present');
        TempBankStatementMatchingBuffer.SetRange("One to Many Match", true);
        Assert.AreEqual(1, TempBankStatementMatchingBuffer.Count, 'There should be one multiple match entry present');

        TempBankStatementMatchingBuffer.SetRange("No. of Entries", 1);
        Assert.IsTrue(TempBankStatementMatchingBuffer.IsEmpty, 'All temporary multiple match entries must be removed');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestVendorMultipleMatchSingleMatchLinesAreIncludedInAmountInclToleranceMatch()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccReconciliationLine2: Record "Bank Acc. Reconciliation Line";
        Vendor: Record Vendor;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        BankPmtApplRule2: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
        DocumentNo3: Code[20];
        Difference: Decimal;
        ExpectedNoOfEntries: Integer;
        Quality: Integer;
    begin
        Initialize();

        // Setup
        CreateVendor(Vendor);

        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        DocumentNo := CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", GenerateExtDocNo(), Amount);
        DocumentNo2 := CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", GenerateExtDocNo(), Amount);
        DocumentNo3 := CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", GenerateExtDocNo(), 2 * Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, -2 * Amount, '', DocumentNo + ' ' + DocumentNo2);
        UpdateBankReconciliationLine(BankAccReconciliationLine, '', Vendor.Name, '', '');

        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine2, -2 * Amount, '', DocumentNo3);
        UpdateBankReconciliationLine(BankAccReconciliationLine2, '', Vendor.Name, '', '');

        RunMatch(BankAccReconciliation, true);
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Yes - Multiple",
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"Multiple Matches");

        SetRule(BankPmtApplRule2, BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes, BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match");

        // Verify
        Difference := 0;
        ExpectedNoOfEntries := 2;
        Quality := TempBankPmtApplRule.GetBestMatchScore(BankPmtApplRule);
        VerifyMultipleApplicationsBankAccReconciliationLine(
          BankAccReconciliationLine, Quality, Difference, -2 * Amount, BankAccReconciliationLine."Account Type"::Vendor, Vendor."No.",
          ExpectedNoOfEntries);

        ExpectedNoOfEntries := 1;
        Quality := TempBankPmtApplRule.GetBestMatchScore(BankPmtApplRule2);
        VerifyMultipleApplicationsBankAccReconciliationLine(
          BankAccReconciliationLine2, Quality, Difference, -2 * Amount, BankAccReconciliationLine."Account Type"::Vendor, Vendor."No.",
          ExpectedNoOfEntries);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestVendorMultipleMatchOneToManyMatchesAreIncludedInAmountInclToleranceMatch()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccReconciliationLine2: Record "Bank Acc. Reconciliation Line";
        Vendor: Record Vendor;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
        DocumentNo3: Code[20];
        DocumentNo4: Code[20];
        Difference: Decimal;
        ExpectedNoOfEntries: Integer;
        Quality: Integer;
    begin
        Initialize();

        // Setup
        CreateVendor(Vendor);

        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        DocumentNo := CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", GenerateExtDocNo(), Amount);
        DocumentNo2 := CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", GenerateExtDocNo(), Amount);
        DocumentNo3 := CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", GenerateExtDocNo(), Amount);
        DocumentNo4 := CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", GenerateExtDocNo(), Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, -2 * Amount, '', DocumentNo + ' ' + DocumentNo2);
        UpdateBankReconciliationLine(BankAccReconciliationLine, '', Vendor.Name, '', '');

        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine2, -2 * Amount, '', DocumentNo3 + ' ' + DocumentNo4);
        UpdateBankReconciliationLine(BankAccReconciliationLine2, '', Vendor.Name, '', '');

        RunMatch(BankAccReconciliation, true);
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Yes - Multiple",
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"Multiple Matches");

        // Verify
        Difference := 0;
        ExpectedNoOfEntries := 2;
        Quality := TempBankPmtApplRule.GetBestMatchScore(BankPmtApplRule);
        VerifyMultipleApplicationsBankAccReconciliationLine(
          BankAccReconciliationLine, Quality, Difference, -2 * Amount, BankAccReconciliationLine."Account Type"::Vendor, Vendor."No.",
          ExpectedNoOfEntries);
        VerifyMultipleApplicationsBankAccReconciliationLine(
          BankAccReconciliationLine2, Quality, Difference, -2 * Amount, BankAccReconciliationLine."Account Type"::Vendor, Vendor."No.",
          ExpectedNoOfEntries);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,VerifyPaymentApplicationPageWithDisableSuggestions')]
    [Scope('OnPrem')]
    procedure TestVendorNoMatchVendorLegerEntriesDisabled()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Vendor: Record Vendor;
        BankPmtApplSettings: Record "Bank Pmt. Appl. Settings";
        PaymentReconciliationJournal: TestPage "Payment Reconciliation Journal";
        Amount: Decimal;
        ExtDocNo: Code[20];
    begin
        Initialize();

        // Setup
        BankPmtApplSettings.GetOrInsert();
        BankPmtApplSettings."Vendor Ledger Entries Matching" := false;
        BankPmtApplSettings.Modify();
        CreateVendor(Vendor);

        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        ExtDocNo := GenerateExtDocNo();
        CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", ExtDocNo, Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, -Amount, '', '');

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        VerifyNoMatch(BankAccReconciliationLine."Statement Line No.");

        // Verify Apply manually still shows entries
        LibraryVariableStorage.Enqueue(Format(TempBankPmtApplRule."Match Confidence"::None));
        PaymentReconciliationJournal.OpenEdit();
        PaymentReconciliationJournal.GoToRecord(BankAccReconciliationLine);
        PaymentReconciliationJournal.ApplyEntries.Invoke();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestVendorMultipleMatchTwoOneToManyLines()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccReconciliationLine2: Record "Bank Acc. Reconciliation Line";
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
        VendorLedgerEntry3: Record "Vendor Ledger Entry";
        VendorLedgerEntry4: Record "Vendor Ledger Entry";
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        BankPmtApplRule2: Record "Bank Pmt. Appl. Rule";
        AppliedPaymentEntry: Record "Applied Payment Entry";
        Amount: Decimal;
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
        DocumentNo3: Code[20];
        DocumentNo4: Code[20];
        Difference: Decimal;
        ExpectedNoOfEntries: Integer;
        Quality: Integer;
        Quality2: Integer;
    begin
        Initialize();

        // Setup
        CreateVendor(Vendor);

        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        DocumentNo := CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", GenerateExtDocNo(), Amount);
        DocumentNo2 := CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", GenerateExtDocNo(), Amount);
        DocumentNo3 := CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", GenerateExtDocNo(), 2 * Amount);
        DocumentNo4 := CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", GenerateExtDocNo(), Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, -2 * Amount, '', DocumentNo + ' ' + DocumentNo2);
        UpdateBankReconciliationLine(BankAccReconciliationLine, '', Vendor.Name, '', '');

        CreateBankReconciliationLine(
          BankAccReconciliation, BankAccReconciliationLine2, -3 * Amount, DocumentNo + ' ' + DocumentNo3 + ' ' + DocumentNo4, '');
        UpdateBankReconciliationLine(BankAccReconciliationLine2, '', Vendor.Name, '', '');

        GetVendorLedgerEntry(VendorLedgerEntry, Vendor, DocumentNo);
        GetVendorLedgerEntry(VendorLedgerEntry2, Vendor, DocumentNo2);
        GetVendorLedgerEntry(VendorLedgerEntry3, Vendor, DocumentNo3);
        GetVendorLedgerEntry(VendorLedgerEntry4, Vendor, DocumentNo4);

        RunMatch(BankAccReconciliation, true);
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Yes - Multiple",
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"Multiple Matches");

        SetRule(BankPmtApplRule2, BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Yes - Multiple",
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");

        // Verify
        Difference := 0;
        ExpectedNoOfEntries := 2;
        Quality := TempBankPmtApplRule.GetBestMatchScore(BankPmtApplRule);
        Quality2 := TempBankPmtApplRule.GetBestMatchScore(BankPmtApplRule2);

        VerifyMultipleApplicationsBankAccReconciliationLine(
          BankAccReconciliationLine, Quality, Difference, -2 * Amount, BankAccReconciliationLine."Account Type"::Vendor, Vendor."No.",
          ExpectedNoOfEntries);
        VerifyMultipleApplicationsBankAccReconciliationLine(
          BankAccReconciliationLine2, Quality2, Difference, -3 * Amount, BankAccReconciliationLine."Account Type"::Vendor, Vendor."No.",
          ExpectedNoOfEntries);

        // Verify Applied Payment Entries Line 1
        GetAppliedPaymentEntries(AppliedPaymentEntry, BankAccReconciliationLine);
        Assert.AreEqual(AppliedPaymentEntry.Count, ExpectedNoOfEntries, 'Wrong number of Applied Payment Entries Found');
        AppliedPaymentEntry.FindFirst();
        VerifyMultipleApplicationsAppliedEntries(AppliedPaymentEntry, Quality, -Amount, VendorLedgerEntry."Entry No.");

        AppliedPaymentEntry.Next();
        VerifyMultipleApplicationsAppliedEntries(AppliedPaymentEntry, Quality, -Amount, VendorLedgerEntry2."Entry No.");

        // Verify Applied Payment Entries Line 2
        GetAppliedPaymentEntries(AppliedPaymentEntry, BankAccReconciliationLine2);
        Assert.AreEqual(AppliedPaymentEntry.Count, ExpectedNoOfEntries, 'Wrong number of Applied Payment Entries Found');
        AppliedPaymentEntry.FindFirst();
        VerifyMultipleApplicationsAppliedEntries(
          AppliedPaymentEntry, Quality2, VendorLedgerEntry3."Remaining Amount", VendorLedgerEntry3."Entry No.");

        AppliedPaymentEntry.Next();
        VerifyMultipleApplicationsAppliedEntries(
          AppliedPaymentEntry, Quality2, VendorLedgerEntry4."Remaining Amount", VendorLedgerEntry4."Entry No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestVendorMultipleMatchBuildFromNoMatchEntries()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        AppliedPaymentEntry: Record "Applied Payment Entry";
        Amount: Decimal;
        Amount2: Decimal;
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
        AppliedAmount: Decimal;
        StatementAmount: Decimal;
        Difference: Decimal;
        ExpectedNoOfEntries: Integer;
        Quality: Integer;
    begin
        Initialize();

        // Setup
        // Remove all rules except multiple match rules, so they will be scored with 0
        BankPmtApplRule.SetFilter(
          "Doc. No./Ext. Doc. No. Matched", '<>%1', BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Yes - Multiple");
        BankPmtApplRule.DeleteAll();
        BankPmtApplRule.Reset();

        CreateVendor(Vendor);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        DocumentNo := CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", GenerateExtDocNo(), Amount);

        Amount2 := LibraryRandom.RandDecInRange(1, 1000, 2);
        DocumentNo2 := CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", GenerateExtDocNo(), Amount2);

        AppliedAmount := -Amount - Amount2;
        StatementAmount := 2 * AppliedAmount;

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, StatementAmount, '', DocumentNo + ' ' + DocumentNo2);
        UpdateBankReconciliationLine(BankAccReconciliationLine, '', Vendor.Name, '', '');

        GetVendorLedgerEntry(VendorLedgerEntry, Vendor, DocumentNo);
        GetVendorLedgerEntry(VendorLedgerEntry2, Vendor, DocumentNo2);

        RunMatch(BankAccReconciliation, true);

        // Verify Bank Account ReconciliationLine
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Yes - Multiple",
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");

        Difference := StatementAmount - AppliedAmount;
        ExpectedNoOfEntries := 2;
        Quality := TempBankPmtApplRule.GetBestMatchScore(BankPmtApplRule);

        VerifyMultipleApplicationsBankAccReconciliationLine(
          BankAccReconciliationLine, Quality, Difference, AppliedAmount, BankAccReconciliationLine."Account Type"::Vendor, Vendor."No.",
          ExpectedNoOfEntries);

        // Verify Applied Payment Entries
        GetAppliedPaymentEntries(AppliedPaymentEntry, BankAccReconciliationLine);
        Assert.AreEqual(AppliedPaymentEntry.Count, ExpectedNoOfEntries, 'Wrong number of Applied Payment Entries Found');
        AppliedPaymentEntry.FindFirst();
        VerifyMultipleApplicationsAppliedEntries(AppliedPaymentEntry, Quality, -Amount, VendorLedgerEntry."Entry No.");
        AppliedPaymentEntry.Next();
        VerifyMultipleApplicationsAppliedEntries(AppliedPaymentEntry, Quality, -Amount2, VendorLedgerEntry2."Entry No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestVendorRunningWithoutApplicationIncludesPositiveEntries()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        TempBankPmtApplRule: Record "Bank Pmt. Appl. Rule" temporary;
        Amount: Decimal;
        DocumentNo: Code[20];
        Quality: Integer;
    begin
        Initialize();

        // Setup
        CreateVendor(Vendor);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        DocumentNo := CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", GenerateExtDocNo(), Amount);

        GetVendorLedgerEntry(VendorLedgerEntry, Vendor, DocumentNo);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, Amount, '', DocumentNo);
        UpdateBankReconciliationLine(BankAccReconciliationLine, '', Vendor.Name, '', '');

        // Execute
        RunMatch(BankAccReconciliation, false);

        // Verify positive entry is present and was scored
        Assert.AreEqual(1, TempBankStatementMatchingBuffer.Count, 'There should be one entry present');
        TempBankStatementMatchingBuffer.FindFirst();
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes,
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");

        TempBankPmtApplRule.LoadRules();
        Quality := TempBankPmtApplRule.GetBestMatchScore(BankPmtApplRule);

        Assert.AreEqual(Quality, TempBankStatementMatchingBuffer.Quality, 'Score should be assigned to the line');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestVendorRunningWithApplicationExcludesPositiveEntries()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Amount: Decimal;
        DocumentNo: Code[20];
    begin
        Initialize();

        // Setup
        CreateVendor(Vendor);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        DocumentNo := CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", GenerateExtDocNo(), Amount);

        GetVendorLedgerEntry(VendorLedgerEntry, Vendor, DocumentNo);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, Amount, '', DocumentNo);
        UpdateBankReconciliationLine(BankAccReconciliationLine, '', Vendor.Name, '', '');

        // Execute
        RunMatch(BankAccReconciliation, true);

        // Verify positive entry is not present
        Assert.AreEqual(0, TempBankStatementMatchingBuffer.Count, 'There should be no entries present');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestVendorRunningWithoutApplicationIncludesEntriesAfterStatementDate()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        TempBankPmtApplRule: Record "Bank Pmt. Appl. Rule" temporary;
        Amount: Decimal;
        DocumentNo: Code[20];
        Quality: Integer;
    begin
        Initialize();

        // Setup
        CreateVendor(Vendor);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        DocumentNo := CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", GenerateExtDocNo(), Amount);

        GetVendorLedgerEntry(VendorLedgerEntry, Vendor, DocumentNo);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, -Amount, '', DocumentNo);
        UpdateBankReconciliationLine(BankAccReconciliationLine, '', Vendor.Name, '', '');
        BankAccReconciliationLine.Validate("Transaction Date", CalcDate('<-1M>', VendorLedgerEntry."Posting Date"));
        BankAccReconciliationLine.Modify(true);

        // Execute
        RunMatch(BankAccReconciliation, false);

        // Verify positive entry is present and was scored
        Assert.AreEqual(1, TempBankStatementMatchingBuffer.Count, 'There should be one entry present');
        TempBankStatementMatchingBuffer.FindFirst();
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes,
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match");

        TempBankPmtApplRule.LoadRules();
        Quality := TempBankPmtApplRule.GetBestMatchScore(BankPmtApplRule);

        Assert.AreEqual(Quality, TempBankStatementMatchingBuffer.Quality, 'Score should be assigned to the line');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestVendorRunningWithoutApplicationDoesNotIncludeEntriesAfterStatementDate()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Amount: Decimal;
        DocumentNo: Code[20];
    begin
        Initialize();

        // Setup
        CreateVendor(Vendor);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        DocumentNo := CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", GenerateExtDocNo(), Amount);

        GetVendorLedgerEntry(VendorLedgerEntry, Vendor, DocumentNo);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, -Amount, '', DocumentNo);
        UpdateBankReconciliationLine(BankAccReconciliationLine, '', Vendor.Name, '', '');
        BankAccReconciliationLine.Validate("Transaction Date", CalcDate('<-1M>', VendorLedgerEntry."Posting Date"));
        BankAccReconciliationLine.Modify(true);

        // Execute
        RunMatch(BankAccReconciliation, true);

        // Verify positive entry is present and was scored
        Assert.AreEqual(0, TempBankStatementMatchingBuffer.Count, 'There should be one entry present');
    end;

    [Test]
    [HandlerFunctions('MessageHandler,VerifyMatchDetailsOnPaymentApplicationsPage')]
    [Scope('OnPrem')]
    procedure TestSalesBankAccLedgerEntrySingleAmountMatch()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        Amount: Decimal;
        ExtDocNo: Code[20];
        InvoiceNo: Code[20];
        InvoiceNo2: Code[20];
    begin
        Initialize();

        // Setup
        CreateCustomer(Customer);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        ExtDocNo := '';
        InvoiceNo := CreateAndPostSalesInvoiceWithOneLine(Customer."No.", ExtDocNo, Amount);
        InvoiceNo2 := CreateAndPostSalesInvoiceWithOneLine(Customer."No.", ExtDocNo, Amount + 1);
        CustLedgerEntry.SetRange("Document No.", InvoiceNo);
        CustLedgerEntry.FindFirst();
        CustLedgerEntry2.SetRange("Document No.", InvoiceNo2);
        CustLedgerEntry2.FindFirst();

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, Amount, '', '');
        PostCustPayment(CustLedgerEntry, BankAccReconciliation."Bank Account No.");
        PostCustPayment(CustLedgerEntry2, BankAccReconciliation."Bank Account No.");

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No, BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match");
        VerifyReconciliation(BankPmtApplRule, BankAccReconciliationLine."Statement Line No.");
        VerifyMatchDetailsData(
          BankAccReconciliation, BankPmtApplRule, BankAccReconciliationLine."Account Type"::"Bank Account", Amount, 0, 1, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,VerifyMatchDetailsOnPaymentApplicationsPage')]
    [Scope('OnPrem')]
    procedure TestSalesBankAccLedgerEntryMultipleAmountMatchWithAmountTolerance()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        Amount: Decimal;
        Tolerance: Decimal;
        ExtDocNo: Code[20];
        InvoiceNo: Code[20];
        InvoiceNo2: Code[20];
    begin
        Initialize();

        // Setup
        CreateCustomer(Customer);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        ExtDocNo := '';
        Tolerance := Round(Amount / 4, 0.01);
        InvoiceNo := CreateAndPostSalesInvoiceWithOneLine(Customer."No.", ExtDocNo, Amount + Tolerance);
        InvoiceNo2 := CreateAndPostSalesInvoiceWithOneLine(Customer."No.", ExtDocNo, Amount + Tolerance / 3);
        CustLedgerEntry.SetRange("Document No.", InvoiceNo);
        CustLedgerEntry.FindFirst();
        CustLedgerEntry2.SetRange("Document No.", InvoiceNo2);
        CustLedgerEntry2.FindFirst();

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, Tolerance);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, Amount, '', '');
        PostCustPayment(CustLedgerEntry, BankAccReconciliation."Bank Account No.");
        PostCustPayment(CustLedgerEntry2, BankAccReconciliation."Bank Account No.");

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No, BankPmtApplRule."Amount Incl. Tolerance Matched"::"Multiple Matches");
        VerifyReconciliation(BankPmtApplRule, BankAccReconciliationLine."Statement Line No.");
        VerifyMatchDetailsData(BankAccReconciliation, BankPmtApplRule,
          BankAccReconciliationLine."Account Type"::"Bank Account", Amount, Tolerance, 2, 0);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,VerifyMatchDetailsOnPaymentApplicationsPage')]
    [Scope('OnPrem')]
    procedure TestPurchBankAccLedgerEntrySingleAmountMatch()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Vendor: Record Vendor;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
        Amount: Decimal;
        InvoiceNo: Code[20];
        InvoiceNo2: Code[20];
    begin
        Initialize();

        // Setup
        CreateVendor(Vendor);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        InvoiceNo := CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", LibraryUtility.GenerateGUID(), Amount);
        InvoiceNo2 := CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", LibraryUtility.GenerateGUID(), Amount + 1);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, -Amount, '', '');
        VendorLedgerEntry.SetRange("Document No.", InvoiceNo);
        VendorLedgerEntry.FindFirst();
        PostVendPayment(VendorLedgerEntry, BankAccReconciliation."Bank Account No.");
        VendorLedgerEntry2.SetRange("Document No.", InvoiceNo2);
        VendorLedgerEntry2.FindFirst();
        PostVendPayment(VendorLedgerEntry2, BankAccReconciliation."Bank Account No.");

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No, BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match");
        VerifyReconciliation(BankPmtApplRule, BankAccReconciliationLine."Statement Line No.");
        VerifyMatchDetailsData(
          BankAccReconciliation, BankPmtApplRule, BankAccReconciliationLine."Account Type"::"Bank Account", -Amount, 0, 1, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,VerifyMatchDetailsOnPaymentApplicationsPage')]
    [Scope('OnPrem')]
    procedure TestPurchBankAccLedgerEntryMultipleAmountMatchWithAmountTolerance()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Vendor: Record Vendor;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
        Amount: Decimal;
        Tolerance: Decimal;
        InvoiceNo: Code[20];
        InvoiceNo2: Code[20];
    begin
        Initialize();

        // Setup
        CreateVendor(Vendor);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        Tolerance := Round(Amount / 4, 0.01);
        InvoiceNo := CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", LibraryUtility.GenerateGUID(), Amount + Tolerance);
        InvoiceNo2 := CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", LibraryUtility.GenerateGUID(), Amount + Tolerance / 3);
        VendorLedgerEntry.SetRange("Document No.", InvoiceNo);
        VendorLedgerEntry.FindFirst();
        VendorLedgerEntry2.SetRange("Document No.", InvoiceNo2);
        VendorLedgerEntry2.FindFirst();

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, Tolerance);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, -Amount, '', '');
        PostVendPayment(VendorLedgerEntry, BankAccReconciliation."Bank Account No.");
        PostVendPayment(VendorLedgerEntry2, BankAccReconciliation."Bank Account No.");

        // Exercise
        RunMatch(BankAccReconciliation, true);

        // Verify
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No, BankPmtApplRule."Amount Incl. Tolerance Matched"::"Multiple Matches");
        VerifyReconciliation(BankPmtApplRule, BankAccReconciliationLine."Statement Line No.");
        VerifyMatchDetailsData(BankAccReconciliation, BankPmtApplRule,
          BankAccReconciliationLine."Account Type"::"Bank Account", -Amount, Tolerance, 2, 0);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,AmountInclToleranceIsNotConsideredModalPageHandler')]
    [Scope('OnPrem')]
    procedure UI_AmountInclToleranceMatchedNotConsideredOnPaymentToEntryMatchPage()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
        DocumentNo: Code[20];
    begin
        // [FEATURE] [UI]
        // [SCENARIO 380975] "Amount Incl. Tolerance" is "Not Considered" on "Payment-to-Entry Match" page when no rule considered for "Amount Incl. Tolerance"

        Initialize();

        // [GIVEN] Sales Invoice with "Document No." = "X" and Amount = 100
        CreateCustomer(Customer);
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        DocumentNo := CreateAndPostSalesInvoiceWithOneLine(Customer."No.", '', Amount);

        // [GIVEN] Bank Account Reconciliation Line with "Document No." = "X" and "Statement Amount" = 50
        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, Amount / 2, DocumentNo, '');

        // [WHEN] Run automatching and open "Payment Application" page
        RunMatch(BankAccReconciliation, true);

        // [THEN] "Amount Incl. Tolerance" is "Not Considered" on "Payment-to-Entry Match" page (subpage located on "Payment Application" page)
        // Verified by AmountInclToleranceIsNotConsideredModalPageHandler
        SetRule(
          BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes, BankPmtApplRule."Amount Incl. Tolerance Matched"::"Not Considered");
        VerifyMatchDetailsData(
          BankAccReconciliation, BankPmtApplRule, BankAccReconciliationLine."Account Type"::Customer, Amount / 2, 0, 0, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ClearAppliesToIDFromCustLedgEntryAfterApplicationRemoval()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        AppliedPaymentEntry: Record "Applied Payment Entry";
        StatementNo: Code[20];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 381519] After Applied Payment Entry is deleted, "Applies-To ID" should be cleared in Customer Ledger Entries

        Initialize();

        // [GIVEN] Customer Ledger Entry "CCC"
        CustLedgerEntry.Init();
        CustLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(CustLedgerEntry, CustLedgerEntry.FieldNo("Entry No."));
        CustLedgerEntry.Open := true;
        CustLedgerEntry.Insert();

        // [GIVEN] Applied Payment Entry related to "CCC"
        MockAppliedPaymentEntry(AppliedPaymentEntry, CustLedgerEntry."Entry No.", AppliedPaymentEntry."Account Type"::Customer);
        MockBankAccReconciliation(AppliedPaymentEntry."Statement No.");
        StatementNo := AppliedPaymentEntry."Statement No.";
        CustLedgerEntry."Applies-to ID" := AppliedPaymentEntry."Statement No.";
        CustLedgerEntry.Modify();

        // [WHEN] Applied Payment Entry deleted
        AppliedPaymentEntry.Delete(true);

        // [THEN] "Applies-to ID" in Customer Ledger Entry is blank
        CustLedgerEntry.Find();
        CustLedgerEntry.TestField("Applies-to ID", '');

        // Tear-down
        RemoveBankAccReconciliation(StatementNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ClearAppliesToIDFromVendLedgEntryAfterApplicationRemoval()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        AppliedPaymentEntry: Record "Applied Payment Entry";
        StatementNo: Code[20];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 381519] After Applied Payment Entry is deleted, "Applies-To ID" should be cleared in Vendor Ledger Entries

        Initialize();

        // [GIVEN] Vendor Ledger Entry "VVV"
        VendorLedgerEntry.Init();
        VendorLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(VendorLedgerEntry, VendorLedgerEntry.FieldNo("Entry No."));
        VendorLedgerEntry.Open := true;
        VendorLedgerEntry.Insert();

        // [GIVEN] Applied Payment Entry related to "VVV"
        MockAppliedPaymentEntry(AppliedPaymentEntry, VendorLedgerEntry."Entry No.", AppliedPaymentEntry."Account Type"::Vendor);
        MockBankAccReconciliation(AppliedPaymentEntry."Statement No.");
        StatementNo := AppliedPaymentEntry."Statement No.";
        VendorLedgerEntry."Applies-to ID" := AppliedPaymentEntry."Statement No.";
        VendorLedgerEntry.Modify();

        // [WHEN] Applied Payment Entry deleted
        AppliedPaymentEntry.Delete(true);

        // [THEN] "Applies-to ID" in Vendor Ledger Entry is blank
        VendorLedgerEntry.Find();
        VendorLedgerEntry.TestField("Applies-to ID", '');

        // Tear-down
        RemoveBankAccReconciliation(StatementNo);
    end;

    [Test]
    [HandlerFunctions('TextMapperBankAccModalPageHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure MapTextToAccountForBankAccountTypeOnPaymentReonciliationJournal()
    var
        BankAccount: Record "Bank Account";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        PaymentReconciliationJournal: TestPage "Payment Reconciliation Journal";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 351885] Text-to-Account Mapping page is opened from Payment Reconciliation Journal for Bank Account Reconciliation Line with Account Type set to Bank Account.
        Initialize();

        // [GIVEN] Bank Account Reconciliation Line with Account No. = "AN", Account Type = "Bank Account", "Transaction Text" = "TT".
        LibraryERM.CreateBankAccount(BankAccount);
        LibraryERM.CreateBankAccReconciliation(BankAccReconciliation, BankAccount."No.",
          BankAccReconciliation."Statement Type"::"Payment Application");
        LibraryERM.CreateBankAccReconciliationLn(BankAccReconciliationLine, BankAccReconciliation);
        BankAccReconciliationLine.Validate("Account Type", BankAccReconciliationLine."Account Type"::"Bank Account");
        BankAccReconciliationLine.Validate("Account No.", BankAccount."No.");
        BankAccReconciliationLine.Validate("Transaction Text", BankAccount."No.");
        BankAccReconciliationLine.Modify(true);

        // [WHEN] Text-to-Account Mapping page is opened for Bank Account Reconciliation Line from Payment Reconciliation Journal using Map Text To Account action.
        PaymentReconciliationJournal.Trap();
        OpenPaymentRecJournal(BankAccReconciliation);
        PaymentReconciliationJournal.AddMappingRule.Invoke();

        // [THEN] On opened page "Mapping Text" = "TT", "Debit Acc. No." = '', "Credit Acc. No." = '', "Bal. Source Type" = "Bank Account", "Bal. Source No." = ''.
        Assert.AreEqual(BankAccReconciliationLine."Transaction Text", LibraryVariableStorage.DequeueText(), '');
        Assert.AreEqual('', LibraryVariableStorage.DequeueText(), '');
        Assert.AreEqual('', LibraryVariableStorage.DequeueText(), '');
        Assert.AreEqual(Format(BankAccReconciliationLine."Account Type"::"Bank Account"), LibraryVariableStorage.DequeueText(), '');
        Assert.AreEqual('', LibraryVariableStorage.DequeueText(), '');
    end;

    [Test]
    [HandlerFunctions('PaymentApplicationShouldBeEmptyHandler')]
    procedure ExcludeCustomerEntriesFromApplyManually()
    var
        Customer: Record Customer;
        BankPmtApplSettings: Record "Bank Pmt. Appl. Settings";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Amount: Decimal;
        ExtDocNo: Code[20];
    begin
        Initialize();
        BankPmtApplSettings.GetOrInsert();
        BankPmtApplSettings."Apply Man. Disable Suggestions" := true;
        BankPmtApplSettings."Cust Ledg Hidden In Apply Man" := true;
        BankPmtApplSettings.Modify();
        CreateCustomer(Customer);

        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        ExtDocNo := '';
        CreateAndPostSalesInvoiceWithOneLine(Customer."No.", ExtDocNo, Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, Amount, '', '');

        BankAccReconciliationLine.DisplayApplication();
    end;

    [Test]
    [HandlerFunctions('PaymentApplicationShouldNotBeEmptyHandler')]
    procedure IncludeCustomerEntriesFromApplyManually()
    var
        Customer: Record Customer;
        BankPmtApplSettings: Record "Bank Pmt. Appl. Settings";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Amount: Decimal;
        ExtDocNo: Code[20];
    begin
        Initialize();
        BankPmtApplSettings.GetOrInsert();
        BankPmtApplSettings."Apply Man. Disable Suggestions" := true;
        BankPmtApplSettings."Cust Ledg Hidden In Apply Man" := false;
        BankPmtApplSettings.Modify();
        CreateCustomer(Customer);

        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        ExtDocNo := '';
        CreateAndPostSalesInvoiceWithOneLine(Customer."No.", ExtDocNo, Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, Amount, '', '');

        BankAccReconciliationLine.DisplayApplication();
    end;

    [Test]
    [HandlerFunctions('PaymentApplicationShouldBeEmptyHandler')]
    procedure ExcludeVendorEntriesFromApplyManually()
    var
        Vendor: Record Vendor;
        BankPmtApplSettings: Record "Bank Pmt. Appl. Settings";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Amount: Decimal;
        ExtDocNo: Code[20];
    begin
        Initialize();
        BankPmtApplSettings.GetOrInsert();
        BankPmtApplSettings."Apply Man. Disable Suggestions" := true;
        BankPmtApplSettings."Vend Ledg Hidden In Apply Man" := true;
        BankPmtApplSettings.Modify();
        CreateVendor(Vendor);

        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        ExtDocNo := LibraryRandom.RandText(20);
        CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", ExtDocNo, Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, Amount, '', '');

        BankAccReconciliationLine.DisplayApplication();
    end;

    [Test]
    [HandlerFunctions('PaymentApplicationShouldNotBeEmptyHandler')]
    procedure IncludeVendorEntriesFromApplyManually()
    var
        Vendor: Record Vendor;
        BankPmtApplSettings: Record "Bank Pmt. Appl. Settings";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Amount: Decimal;
        ExtDocNo: Code[20];
    begin
        Initialize();
        BankPmtApplSettings.GetOrInsert();
        BankPmtApplSettings."Apply Man. Disable Suggestions" := true;
        BankPmtApplSettings."Vend Ledg Hidden In Apply Man" := false;
        BankPmtApplSettings.Modify();
        CreateVendor(Vendor);

        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        ExtDocNo := LibraryRandom.RandText(20);
        CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", ExtDocNo, Amount);

        CreateBankReconciliationAmountTolerance(BankAccReconciliation, 0);
        CreateBankReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, Amount, '', '');

        BankAccReconciliationLine.DisplayApplication();
    end;


    local procedure Initialize()
    var
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        BankPmtApplSettings: Record "Bank Pmt. Appl. Settings";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Bank Pmt. Appl. Algorithm");
        CleanupPreviousTestData();
        ClearGlobals();
        LibraryVariableStorage.Clear();
        BankPmtApplRule.DeleteAll();
        BankPmtApplRule.InsertDefaultMatchingRules();
        BankPmtApplSettings.DeleteAll();

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Bank Pmt. Appl. Algorithm");

        LibraryApplicationArea.EnableFoundationSetup();
        TempBankPmtApplRule.LoadRules();
        LibraryERMCountryData.UpdateLocalData();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERM.FindZeroVATPostingSetup(ZeroVATPostingSetup, ZeroVATPostingSetup."VAT Calculation Type"::"Normal VAT");

        isInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Bank Pmt. Appl. Algorithm");
    end;

    local procedure CleanupPreviousTestData()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        Customer: Record "Customer";
        Vendor: Record "Vendor";
        TextToAccountMapping: Record "Text-to-Account Mapping";
    begin
        CustLedgerEntry.SetRange(Open, true);
        CustLedgerEntry.ModifyAll(Open, false);

        VendorLedgerEntry.SetRange(Open, true);
        VendorLedgerEntry.ModifyAll(Open, false);

        BankAccountLedgerEntry.SetRange(Open, true);
        BankAccountLedgerEntry.ModifyAll(Open, false);

        Customer.ModifyAll(Name, ShortNameToExcludFromMatching);
        Vendor.ModifyAll(Name, ShortNameToExcludFromMatching);

        TextToAccountMapping.DeleteAll();
    end;

    local procedure ClearGlobals()
    begin
        Clear(TempBankStatementMatchingBuffer);
        TempBankStatementMatchingBuffer.DeleteAll();
    end;

    local procedure MockAppliedPaymentEntry(var AppliedPaymentEntry: Record "Applied Payment Entry"; EntryNo: Integer; AccountType: Enum "Gen. Journal Account Type")
    begin
        AppliedPaymentEntry.Init();
        AppliedPaymentEntry."Statement No." :=
          Format(LibraryUtility.GetNewRecNo(AppliedPaymentEntry, AppliedPaymentEntry.FieldNo("Statement No.")));
        AppliedPaymentEntry."Applies-to Entry No." := EntryNo;
        AppliedPaymentEntry."Account Type" := AccountType;
        AppliedPaymentEntry.Insert();
    end;

    local procedure MockBankAccReconciliation(StatementNo: Code[20])
    var
        BankAccount: Record "Bank Account";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        BankAccReconciliation.Init();
        BankAccReconciliation."Statement No." := StatementNo;
        BankAccount.SetRange("No.", '');
        if not BankAccount.FindFirst() then begin
            BankAccount.Init();
            BankAccount.Insert();
        end;
        BankAccReconciliation."Bank Account No." := BankAccount."No.";
        BankAccReconciliation.Insert();
        BankAccReconciliationLine.Init();
        BankAccReconciliationLine."Statement No." := StatementNo;
        BankAccReconciliationLine.Insert();
    end;

    local procedure CreateCustomer(var Customer: Record Customer)
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", ZeroVATPostingSetup."VAT Bus. Posting Group");
        Customer.Validate(Name, GenerateRandomSmallLettersWithSpaces(50));
        Customer.Validate(Address, GenerateRandomSmallLettersWithSpaces(50));
        Customer.Validate("Address 2", GenerateRandomSmallLettersWithSpaces(50));
        Customer.Validate("Country/Region Code", '');
        Customer.Validate(City, GenerateRandomSmallLettersWithSpaces(30));
        Customer.Modify(true);
    end;

    local procedure CreateVendor(var Vendor: Record Vendor)
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", ZeroVATPostingSetup."VAT Bus. Posting Group");
        Vendor.Validate(Name, GenerateRandomSmallLettersWithSpaces(50));
        Vendor.Validate(Address, GenerateRandomSmallLettersWithSpaces(50));
        Vendor.Validate("Address 2", GenerateRandomSmallLettersWithSpaces(50));
        Vendor.Validate("Country/Region Code", '');
        Vendor.Validate(City, GenerateRandomSmallLettersWithSpaces(30));
        Vendor.Modify(true);
    end;

    local procedure CreateItem(var Item: Record Item; Amount: Decimal)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", ZeroVATPostingSetup."VAT Prod. Posting Group");
        Item.Validate("Unit Price", Amount);
        Item.Validate("Last Direct Cost", Amount);
        Item.Modify(true);
    end;

    local procedure CreateCustomerBankAccount(var CustomerBankAccount: Record "Customer Bank Account"; CustomerNo: Code[20]; BankAccountNo: Code[20])
    begin
        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount, CustomerNo);
        CustomerBankAccount.IBAN := '';
        CustomerBankAccount."Bank Account No." := BankAccountNo;
        CustomerBankAccount.Modify(true);
    end;

    local procedure CreateVendorBankAccount(var VendorBankAccount: Record "Vendor Bank Account"; VendorNo: Code[20]; BankAccountNo: Code[20])
    begin
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, VendorNo);
        VendorBankAccount.IBAN := '';
        VendorBankAccount."Bank Account No." := BankAccountNo;
        VendorBankAccount.Modify(true);
    end;

    local procedure CreateAndPostSalesInvoiceWithOneLine(CustomerNo: Code[20]; ExtDocNo: Code[20]; Amount: Decimal): Code[20]
    begin
        exit(CreateAndPostSalesInvoiceWithOneLine2(CustomerNo, ExtDocNo, Amount, 0D));
    end;

    local procedure CreateAndPostSalesInvoiceWithOneLine2(CustomerNo: Code[20]; ExtDocNo: Code[20]; Amount: Decimal; DueDate: Date): Code[20]
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        CreateItem(Item, Amount);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        SalesHeader.Validate("External Document No.", ExtDocNo);

        if DueDate <> 0D then
            SalesHeader.Validate("Due Date", DueDate);

        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);

        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateAndPostPurchaseInvoiceWithOneLine(VendorNo: Code[20]; ExtDocNo: Code[20]; Amount: Decimal): Code[20]
    begin
        exit(CreateAndPostPurchaseInvoiceWithOneLine2(VendorNo, ExtDocNo, Amount, 0D));
    end;

    local procedure CreateAndPostPurchaseInvoiceWithOneLine2(VendorNo: Code[20]; ExtDocNo: Code[20]; Amount: Decimal; DueDate: Date): Code[20]
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        CreateItem(Item, Amount);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        PurchaseHeader.Validate("Vendor Invoice No.", ExtDocNo);
        if DueDate <> 0D then
            PurchaseHeader.Validate("Due Date", DueDate);

        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 1);

        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateBankReconciliationAmountTolerance(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; ToleranceValue: Decimal)
    var
        BankAccount: Record "Bank Account";
    begin
        CreateBankReconciliation(BankAccReconciliation, BankAccount."Match Tolerance Type"::Amount, ToleranceValue);
    end;

    local procedure CreateBankReconciliationPercentageTolerance(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; ToleranceValue: Decimal)
    var
        BankAccount: Record "Bank Account";
    begin
        CreateBankReconciliation(BankAccReconciliation, BankAccount."Match Tolerance Type"::Percentage, ToleranceValue);
    end;

    local procedure CreateBankReconciliation(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; ToleranceType: Option; ToleranceValue: Decimal)
    var
        BankAccount: Record "Bank Account";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Match Tolerance Type", ToleranceType);
        BankAccount.Validate("Match Tolerance Value", ToleranceValue);
        BankAccount.Modify(true);
        LibraryERM.CreateBankAccReconciliation(BankAccReconciliation, BankAccount."No.",
          BankAccReconciliation."Statement Type"::"Payment Application");
    end;

    local procedure CreateBankReconciliationLine(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; Amount: Decimal; TransactionText: Text[140]; AdditionalTransactionInfo: Text[100])
    begin
        LibraryERM.CreateBankAccReconciliationLn(BankAccReconciliationLine, BankAccReconciliation);
        BankAccReconciliationLine.Validate("Transaction Text", TransactionText);
        BankAccReconciliationLine.Validate("Additional Transaction Info", AdditionalTransactionInfo);
        BankAccReconciliationLine.Validate("Transaction Date", WorkDate());
        BankAccReconciliationLine.Validate("Statement Amount", Amount);
        BankAccReconciliationLine.Modify(true);
    end;

    local procedure CreateOneToManyBankStatementMatchingBufferLine(var TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary; var TempBankStmtMultipleMatchLine: Record "Bank Stmt Multiple Match Line" temporary; TempLedgerEntryMatchingBuffer: Record "Ledger Entry Matching Buffer" temporary; BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; AccountType: Enum "Gen. Journal Account Type")
    var
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
    begin
        TempBankStatementMatchingBuffer.AddMatchCandidate(
          BankAccReconciliationLine."Statement Line No.", TempLedgerEntryMatchingBuffer."Entry No.",
          LibraryRandom.RandIntInRange(1, BankPmtApplRule.GetHighestPossibleScore() - 1), AccountType,
          TempLedgerEntryMatchingBuffer."Account No.");

        TempBankStatementMatchingBuffer.InsertOrUpdateOneToManyRule(
          TempLedgerEntryMatchingBuffer,
          BankAccReconciliationLine."Statement Line No.",
          BankPmtApplRule."Related Party Matched"::Fully,
          AccountType, TempLedgerEntryMatchingBuffer.GetApplicableRemainingAmount(BankAccReconciliationLine, false));

        TempBankStmtMultipleMatchLine.InsertLine(
          TempLedgerEntryMatchingBuffer,
          BankAccReconciliationLine."Statement Line No.",
          AccountType);
    end;

    local procedure RemoveBankAccReconciliation(StatementNo: Code[20])
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
    begin
        BankAccReconciliation.SetRange("Statement Type", BankAccReconciliation."Statement Type"::"Bank Reconciliation");
        BankAccReconciliation.SetRange("Statement No.", StatementNo);
        BankAccReconciliation.FindFirst();
        BankAccReconciliation.Delete(true);
    end;

    local procedure UpdateBankReconciliationLine(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; BankAccountNo: Text[50]; Name: Text[100]; Address: Text[100]; City: Text[50])
    begin
        BankAccReconciliationLine.Validate("Related-Party Bank Acc. No.", BankAccountNo);
        BankAccReconciliationLine.Validate("Related-Party Name", Name);
        BankAccReconciliationLine.Validate("Related-Party Address", Address);
        BankAccReconciliationLine.Validate("Related-Party City", City);
        BankAccReconciliationLine.Modify(true);
    end;

    local procedure PostCustPayment(var CustLedgEntry: Record "Cust. Ledger Entry"; BankAccNo: Code[20])
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CustLedgEntry.CalcFields(Amount, "Remaining Amount");
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
          GenJournalLine,
          GenJournalTemplate.Name,
          GenJournalBatch.Name,
          GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Customer,
          CustLedgEntry."Customer No.",
          GenJournalLine."Bal. Account Type"::"Bank Account",
          BankAccNo,
          -CustLedgEntry."Remaining Amount");
        GenJournalLine.Validate("Applies-to Doc. Type", CustLedgEntry."Document Type");
        GenJournalLine.Validate("Applies-to Doc. No.", CustLedgEntry."Document No.");
        GenJournalLine.Modify();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure PostVendPayment(var VendLedgerEntry: Record "Vendor Ledger Entry"; BankAccNo: Code[20])
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VendLedgerEntry.CalcFields(Amount, "Remaining Amount");
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
          GenJournalLine,
          GenJournalTemplate.Name,
          GenJournalBatch.Name,
          GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Vendor,
          VendLedgerEntry."Vendor No.",
          GenJournalLine."Bal. Account Type"::"Bank Account",
          BankAccNo,
          -VendLedgerEntry."Remaining Amount");
        GenJournalLine.Validate("External Document No.", VendLedgerEntry."External Document No.");
        GenJournalLine.Validate("Applies-to Doc. Type", VendLedgerEntry."Document Type");
        GenJournalLine.Validate("Applies-to Doc. No.", VendLedgerEntry."Document No.");
        GenJournalLine.Modify();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure GenerateExtDocNo(): Code[20]
    begin
        exit(LibraryUtility.GenerateGUID() + GenerateRandomSmallLetters(10));
    end;

    local procedure GenerateTextToAccountMapping(): Code[20]
    begin
        exit(GenerateRandomSmallLetters(10) + LibraryUtility.GenerateGUID());
    end;

    local procedure GenerateRandomSmallLettersWithSpaces(Length: Integer): Text
    var
        TextWithSpaces: Text;
        SpacePosition: Integer;
    begin
        TextWithSpaces := GenerateRandomSmallLetters(Length);
        repeat
            RandomizeCount += 1;
            Randomize(RandomizeCount);
            SpacePosition += 5 + Random(15);
            if SpacePosition < Length - 5 then
                TextWithSpaces[SpacePosition] := ' ';
        until SpacePosition > Length;

        exit(TextWithSpaces);
    end;

    local procedure GenerateRandomSmallLetters(Length: Integer) String: Text
    var
        i: Integer;
        AvailableCharactersText: Text;
    begin
        AvailableCharactersText := AvailableCharacters;
        for i := 1 to Length do begin
            RandomizeCount += 1;
            Randomize(RandomizeCount);
            String[i] := AvailableCharactersText[Random(StrLen(AvailableCharactersText))];
        end;

        exit(String);
    end;

    local procedure OpenPaymentRecJournal(BankAccReconciliation: Record "Bank Acc. Reconciliation")
    var
        PmtReconciliationJournals: TestPage "Pmt. Reconciliation Journals";
    begin
        PmtReconciliationJournals.OpenView();
        PmtReconciliationJournals.GotoRecord(BankAccReconciliation);
        PmtReconciliationJournals.EditJournal.Invoke();
    end;

    local procedure GetVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; Vendor: Record Vendor; DocumentNo: Code[20])
    begin
        VendorLedgerEntry.SetRange("Document No.", DocumentNo);
        VendorLedgerEntry.SetRange("Vendor No.", Vendor."No.");
        VendorLedgerEntry.FindFirst();
        VendorLedgerEntry.CalcFields("Remaining Amount", "Remaining Amt. (LCY)");
    end;

    local procedure GetCustLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; Customer: Record Customer; DocumentNo: Code[20])
    begin
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        CustLedgerEntry.SetRange("Customer No.", Customer."No.");
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.CalcFields("Remaining Amount", "Remaining Amt. (LCY)");
    end;

    local procedure GetAppliedPaymentEntries(var AppliedPaymentEntry: Record "Applied Payment Entry"; BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    begin
        AppliedPaymentEntry.SetRange("Statement Type", BankAccReconciliationLine."Statement Type");
        AppliedPaymentEntry.SetRange("Bank Account No.", BankAccReconciliationLine."Bank Account No.");
        AppliedPaymentEntry.SetRange("Statement No.", BankAccReconciliationLine."Statement No.");
        AppliedPaymentEntry.SetRange("Statement Line No.", BankAccReconciliationLine."Statement Line No.");
    end;

    local procedure GetOneToOneBankStatementMatchingBuffer(var TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary; EntryNo: Integer)
    begin
        TempBankStatementMatchingBuffer.Reset();
        TempBankStatementMatchingBuffer.SetRange("Account Type", TempBankStatementMatchingBuffer."Account Type");
        TempBankStatementMatchingBuffer.SetRange("Entry No.", EntryNo);
        TempBankStatementMatchingBuffer.FindFirst();
    end;

    local procedure GetOneToManyBankStatementMatchingBuffer(var OneToManyTempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary; var TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary)
    begin
        OneToManyTempBankStatementMatchingBuffer.Copy(TempBankStatementMatchingBuffer, true);
        OneToManyTempBankStatementMatchingBuffer.SetRange("Line No.", TempBankStatementMatchingBuffer."Line No.");
        OneToManyTempBankStatementMatchingBuffer.SetRange("Entry No.", -1);
        OneToManyTempBankStatementMatchingBuffer.SetRange("Account Type", TempBankStatementMatchingBuffer."Account Type");
        OneToManyTempBankStatementMatchingBuffer.SetRange("Account No.", TempBankStatementMatchingBuffer."Account No.");
        OneToManyTempBankStatementMatchingBuffer.FindFirst();
    end;

    local procedure VerifyReconciliation(ExpectedBankPmtApplRule: Record "Bank Pmt. Appl. Rule"; StatementLineNo: Integer)
    begin
        TempBankStatementMatchingBuffer.Reset();
        TempBankStatementMatchingBuffer.SetRange("Line No.", StatementLineNo);
        TempBankStatementMatchingBuffer.FindFirst();

        Assert.AreEqual(TempBankPmtApplRule.GetBestMatchScore(ExpectedBankPmtApplRule),
          TempBankStatementMatchingBuffer.Quality, 'Matching is wrong for statement line ' + Format(StatementLineNo))
    end;

    local procedure VerifyTextEntryApplied(StatementLineNo: Integer)
    begin
        TempBankStatementMatchingBuffer.Reset();
        TempBankStatementMatchingBuffer.SetCurrentKey(Quality);
        TempBankStatementMatchingBuffer.Ascending(false);
        TempBankStatementMatchingBuffer.SetRange("Line No.", StatementLineNo);
        TempBankStatementMatchingBuffer.FindFirst();

        Assert.IsTrue((TempBankStatementMatchingBuffer.Quality >= TempBankPmtApplRule.GetTextMapperScore()) and (TempBankStatementMatchingBuffer.Quality <= TempBankPmtApplRule.GetMaxTextMapperScore()), 'Matching is wrong for statement line ' + Format(StatementLineNo));
    end;

    local procedure VerifyTextEntryConsidered(StatementLineNo: Integer)
    begin
        TempBankStatementMatchingBuffer.Reset();
        TempBankStatementMatchingBuffer.SetRange("Line No.", StatementLineNo);
        TempBankStatementMatchingBuffer.SetRange(Quality, TempBankPmtApplRule.GetTextMapperScore(), TempBankPmtApplRule.GetMaxTextMapperScore());

        Assert.IsTrue(TempBankStatementMatchingBuffer.FindFirst(), 'Text mapper should have been considered.');
    end;

    local procedure VerifyNoMatch(LineNo: Integer)
    var
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
    begin
        SetRule(BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No, BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");

        TempBankStatementMatchingBuffer.Reset();
        TempBankStatementMatchingBuffer.SetRange("Line No.", LineNo);
        Assert.IsFalse(TempBankStatementMatchingBuffer.FindFirst(), 'Temp statement matching buffer should be empty in case of No Match');
    end;

    local procedure VerifyEntryApplied(BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; TextMapperMatch: Boolean)
    var
        AppliedPaymentEntry: Record "Applied Payment Entry";
    begin
        AppliedPaymentEntry.SetRange("Statement Type", BankAccReconciliationLine."Statement Type");
        AppliedPaymentEntry.SetRange("Bank Account No.", BankAccReconciliationLine."Bank Account No.");
        AppliedPaymentEntry.SetRange("Statement No.", BankAccReconciliationLine."Statement No.");
        AppliedPaymentEntry.SetRange("Statement Line No.", BankAccReconciliationLine."Statement Line No.");

        Assert.IsTrue(AppliedPaymentEntry.FindFirst(), 'Wrong application. Filters: ' + AppliedPaymentEntry.GetFilters);

        if TextMapperMatch then begin
            Assert.AreEqual(0, AppliedPaymentEntry."Applies-to Entry No.", 'Applies-to Entry No.  should be 0 for Text Mapper ' +
              'match. Filters: ' + AppliedPaymentEntry.GetFilters);
            Assert.AreEqual(BankAccReconciliationLine."Statement Amount", AppliedPaymentEntry."Applied Amount",
              'Is a text mapper match so appied amount should be statement amount: ' +
              Format(BankAccReconciliationLine."Statement Amount") + '. Filters: ' + AppliedPaymentEntry.GetFilters);
        end;
    end;

    local procedure VerifyEntriesNotAppliedForStatement(BankAccReconciliation: Record "Bank Acc. Reconciliation")
    var
        AppliedPaymentEntry: Record "Applied Payment Entry";
    begin
        AppliedPaymentEntry.SetRange("Statement Type", BankAccReconciliation."Statement Type");
        AppliedPaymentEntry.SetRange("Bank Account No.", BankAccReconciliation."Bank Account No.");
        AppliedPaymentEntry.SetRange("Statement No.", BankAccReconciliation."Statement No.");

        Assert.AreEqual(0, AppliedPaymentEntry.Count, 'No applications should be made. Filters: ' + AppliedPaymentEntry.GetFilters);
    end;

    local procedure VerifyMatchDetailsData(BankAccReconciliation: Record "Bank Acc. Reconciliation"; BankPmtApplRule: Record "Bank Pmt. Appl. Rule"; AccountType: Enum "Gen. Journal Account Type"; Amount: Decimal; Tolerance: Decimal; ExpectedNumberOfEntriesWithinTolerance: Integer; ExpectedNumberOfEntriesOutsideTolerance: Integer)
    var
        BankAccount: Record "Bank Account";
        TempBankPmtApplRule: Record "Bank Pmt. Appl. Rule" temporary;
    begin
        TempBankPmtApplRule.LoadRules();
        TempBankPmtApplRule.GetBestMatchScore(BankPmtApplRule);
        BankPmtApplRule."Match Confidence" := TempBankPmtApplRule."Match Confidence";

        VerifyMatchDetailsData2(BankAccReconciliation, BankPmtApplRule, AccountType,
          Amount, Tolerance, BankAccount."Match Tolerance Type"::Amount, ExpectedNumberOfEntriesWithinTolerance,
          ExpectedNumberOfEntriesOutsideTolerance,
          false, -1);
    end;

    local procedure VerifyMatchDetailsData2(BankAccReconciliation: Record "Bank Acc. Reconciliation"; BankPmtApplRule: Record "Bank Pmt. Appl. Rule"; AccountType: Enum "Gen. Journal Account Type"; Amount: Decimal; Tolerance: Decimal; ToleranceType: Option; ExpectedNumberOfEntriesWithinTolerance: Integer; ExpectedNumberOfEntriesOutsideTolerance: Integer; GoToEntroNo: Boolean; EntryNo: Integer)
    var
        PaymentReconciliationJournal: TestPage "Payment Reconciliation Journal";
    begin
        PaymentReconciliationJournal.Trap();
        OpenPaymentRecJournal(BankAccReconciliation);

        LibraryVariableStorage.Enqueue(Format(BankPmtApplRule."Match Confidence"));
        LibraryVariableStorage.Enqueue(BankPmtApplRule."Related Party Matched");
        LibraryVariableStorage.Enqueue(BankPmtApplRule."Doc. No./Ext. Doc. No. Matched");
        LibraryVariableStorage.Enqueue(ExpectedNumberOfEntriesWithinTolerance);
        LibraryVariableStorage.Enqueue(ExpectedNumberOfEntriesOutsideTolerance);
        LibraryVariableStorage.Enqueue(AccountType);
        LibraryVariableStorage.Enqueue(Amount);
        LibraryVariableStorage.Enqueue(Tolerance);
        LibraryVariableStorage.Enqueue(ToleranceType);
        LibraryVariableStorage.Enqueue(GoToEntroNo);

        if GoToEntroNo then
            LibraryVariableStorage.Enqueue(EntryNo);

        PaymentReconciliationJournal.First();
        PaymentReconciliationJournal.ApplyEntries.Invoke();

        PaymentReconciliationJournal.Close();
    end;

    local procedure VerifyNoOfCustomerLedgerEntriesOnMatchDetailsLookup(PaymentApplication: TestPage "Payment Application"; Tolerance: Decimal; ToleranceType: Option; Amount: Decimal)
    var
        CustomerLedgerEntries: TestPage "Customer Ledger Entries";
        EntryRemainingAmount: Decimal;
    begin
        CustomerLedgerEntries.Trap();
        PaymentApplication.Control2.NoOfLedgerEntriesWithinAmount.DrillDown();
        if CustomerLedgerEntries.First() then
            repeat
                Evaluate(EntryRemainingAmount, CustomerLedgerEntries."Remaining Amount".Value);
                Assert.IsTrue(IsEntryAmountWithinToleranceRange(EntryRemainingAmount, Amount, Tolerance, ToleranceType),
                  'Entry is not within tolerance range');
            until not CustomerLedgerEntries.Next();
        CustomerLedgerEntries.Close();

        CustomerLedgerEntries.Trap();
        PaymentApplication.Control2.NoOfLedgerEntriesOutsideAmount.DrillDown();
        if CustomerLedgerEntries.First() then
            repeat
                Evaluate(EntryRemainingAmount, CustomerLedgerEntries."Remaining Amount".Value);
                Assert.IsFalse(IsEntryAmountWithinToleranceRange(EntryRemainingAmount, Amount, Tolerance, ToleranceType),
                  'Entry is within tolerance range');
            until not CustomerLedgerEntries.Next();
        CustomerLedgerEntries.Close();
    end;

    local procedure VerifyNoOfVendorLedgerEntriesOnMatchDetailsLookup(PaymentApplication: TestPage "Payment Application"; Tolerance: Decimal; ToleranceType: Option; Amount: Decimal)
    var
        VendorLedgerEntries: TestPage "Vendor Ledger Entries";
        EntryRemainingAmount: Decimal;
    begin
        VendorLedgerEntries.Trap();
        PaymentApplication.Control2.NoOfLedgerEntriesWithinAmount.DrillDown();
        if VendorLedgerEntries.First() then
            repeat
                Evaluate(EntryRemainingAmount, VendorLedgerEntries."Remaining Amount".Value);
                Assert.IsTrue(IsEntryAmountWithinToleranceRange(EntryRemainingAmount, Amount, Tolerance, ToleranceType),
                  'Entry is not within tolerance range');
            until not VendorLedgerEntries.Next();

        VendorLedgerEntries.Close();
        VendorLedgerEntries.Trap();
        PaymentApplication.Control2.NoOfLedgerEntriesOutsideAmount.DrillDown();
        if VendorLedgerEntries.First() then
            repeat
                Evaluate(EntryRemainingAmount, VendorLedgerEntries."Remaining Amount".Value);
                Assert.IsFalse(IsEntryAmountWithinToleranceRange(EntryRemainingAmount, Amount, Tolerance, ToleranceType),
                  'Entry is within tolerance range');
            until not VendorLedgerEntries.Next();
        VendorLedgerEntries.Close();
    end;

    local procedure VerifyNoOfBankAccountLedgerEntriesOnMatchDetailsLookup(PaymentApplication: TestPage "Payment Application"; Tolerance: Decimal; ToleranceType: Option; Amount: Decimal)
    var
        BankAccountLedgerEntries: TestPage "Bank Account Ledger Entries";
        EntryRemainingAmount: Decimal;
    begin
        BankAccountLedgerEntries.Trap();
        PaymentApplication.Control2.NoOfLedgerEntriesWithinAmount.DrillDown();
        if BankAccountLedgerEntries.First() then
            repeat
                EntryRemainingAmount := LibraryERMCountryData.AmountOnBankAccountLedgerEntriesPage(BankAccountLedgerEntries);
                Assert.IsTrue(IsEntryAmountWithinToleranceRange(EntryRemainingAmount, Amount, Tolerance, ToleranceType),
                  'Entry is not within tolerance range');
            until not BankAccountLedgerEntries.Next();

        BankAccountLedgerEntries.Close();
        BankAccountLedgerEntries.Trap();
        PaymentApplication.Control2.NoOfLedgerEntriesOutsideAmount.DrillDown();
        if BankAccountLedgerEntries.First() then
            repeat
                EntryRemainingAmount := LibraryERMCountryData.AmountOnBankAccountLedgerEntriesPage(BankAccountLedgerEntries);
                Assert.IsFalse(IsEntryAmountWithinToleranceRange(EntryRemainingAmount, Amount, Tolerance, ToleranceType),
                  'Entry is within tolerance range');
            until not BankAccountLedgerEntries.Next();
        BankAccountLedgerEntries.Close();
    end;

    local procedure IsEntryAmountWithinToleranceRange(EntryRemainingAmount: Decimal; Amount: Decimal; Tolerance: Decimal; ToleranceType: Option): Boolean
    var
        BankAccount: Record "Bank Account";
        MinAmount: Decimal;
        MaxAmount: Decimal;
        TempAmount: Decimal;
    begin
        if ToleranceType = BankAccount."Match Tolerance Type"::Percentage then begin
            MinAmount := EntryRemainingAmount - Round(EntryRemainingAmount * Tolerance / 100);
            MaxAmount := EntryRemainingAmount + Round(EntryRemainingAmount * Tolerance / 100);

            if EntryRemainingAmount < 0 then begin
                TempAmount := MinAmount;
                MinAmount := MaxAmount;
                MaxAmount := TempAmount;
            end;
        end else begin
            MinAmount := EntryRemainingAmount - Tolerance;
            MaxAmount := EntryRemainingAmount + Tolerance;
        end;

        exit((MinAmount <= Amount) and (MaxAmount >= Amount));
    end;

    local procedure SetRule(var BankPmtApplRule: Record "Bank Pmt. Appl. Rule"; RelatedPartyMatched: Option; DocNoMatched: Option; AmountInclToleranceMatched: Option)
    begin
        Clear(BankPmtApplRule);

        BankPmtApplRule."Related Party Matched" := RelatedPartyMatched;
        BankPmtApplRule."Doc. No./Ext. Doc. No. Matched" := DocNoMatched;
        BankPmtApplRule."Amount Incl. Tolerance Matched" := AmountInclToleranceMatched;
    end;

    local procedure RunMatch(BankAccReconciliation: Record "Bank Acc. Reconciliation"; ApplyEntries: Boolean)
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        MatchBankPayments: Codeunit "Match Bank Payments";
    begin
        if ApplyEntries then
            LibraryVariableStorage.Enqueue(LinesAreAppliedTxt);

        BankAccReconciliationLine.SetRange("Statement Type", BankAccReconciliation."Statement Type");
        BankAccReconciliationLine.SetRange("Statement No.", BankAccReconciliation."Statement No.");
        BankAccReconciliationLine.SetRange("Bank Account No.", BankAccReconciliation."Bank Account No.");
        MatchBankPayments.SetApplyEntries(ApplyEntries);
        MatchBankPayments.Code(BankAccReconciliationLine);

        MatchBankPayments.GetBankStatementMatchingBuffer(TempBankStatementMatchingBuffer);
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

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure TextMapperModalPageHandler(var TexttoAccountMapping: TestPage "Text-to-Account Mapping")
    begin
        TexttoAccountMapping."Debit Acc. No.".SetValue(LibraryERM.CreateGLAccountNo());
        TexttoAccountMapping."Credit Acc. No.".SetValue(LibraryERM.CreateGLAccountNo());
        TexttoAccountMapping.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure TextMapperBankAccModalPageHandler(var TexttoAccountMapping: TestPage "Text-to-Account Mapping")
    begin
        LibraryVariableStorage.Enqueue(TexttoAccountMapping."Mapping Text".Value);
        LibraryVariableStorage.Enqueue(TexttoAccountMapping."Debit Acc. No.".Value);
        LibraryVariableStorage.Enqueue(TexttoAccountMapping."Credit Acc. No.".Value);
        LibraryVariableStorage.Enqueue(TexttoAccountMapping."Bal. Source Type".Value);
        LibraryVariableStorage.Enqueue(TexttoAccountMapping."Bal. Source No.".Value);
        TexttoAccountMapping.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VerifyPaymentApplicationPageWithDisableSuggestions(var PaymentApplication: TestPage "Payment Application")
    begin
        Assert.IsTrue(PaymentApplication.First(), 'Page must not be empty, suggestions should have been loaded');
        Assert.AreEqual(PaymentApplication."Match Confidence".Value(), Format(TempBankPmtApplRule."Match Confidence"::None), 'No confidence should be set on the line');

        PaymentApplication.SortEntriesBasedOnProbability.Invoke();
        Assert.IsTrue(PaymentApplication.First(), 'Page must not be empty, suggestions should have been loaded');
        Assert.AreEqual(PaymentApplication."Match Confidence".Value(), LibraryVariableStorage.DequeueText(), 'No confidence should be set on the line');
    end;

    [ModalPageHandler]
    procedure PaymentApplicationShouldBeEmptyHandler(var PaymentApplication: TestPage "Payment Application")
    begin
        Assert.IsFalse(PaymentApplication.First(), 'Page must be empty, no suggestions should have been loaded');
    end;

    [ModalPageHandler]
    procedure PaymentApplicationShouldNotBeEmptyHandler(var PaymentApplication: TestPage "Payment Application")
    begin
        Assert.IsTrue(PaymentApplication.First(), 'Page should not be empty, suggestions should have been loaded');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VerifyMatchDetailsOnPaymentApplicationsPage(var PaymentApplication: TestPage "Payment Application")
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        MatchConfidenceVariant: Variant;
        RelatedPartyMatchedVariant: Variant;
        DocExtDocNoMatchedVariant: Variant;
        ExpectedNumberOfEntriesWithinToleranceVariant: Variant;
        ExpectedNumberOfEntriesOutsideToleranceVariant: Variant;
        AccountTypeVariant: Variant;
        AmountVariant: Variant;
        ToleranceVariant: Variant;
        ToleranceTypeVariant: Variant;
        GoToEntryNoVariant: Variant;
        EntryNoVariant: Variant;
        AccountType: Enum "Gen. Journal Account Type";
        AccountTypeInt: Integer;
        GoToEntryNo: Boolean;
    begin
        LibraryVariableStorage.Dequeue(MatchConfidenceVariant);
        LibraryVariableStorage.Dequeue(RelatedPartyMatchedVariant);
        LibraryVariableStorage.Dequeue(DocExtDocNoMatchedVariant);
        LibraryVariableStorage.Dequeue(ExpectedNumberOfEntriesWithinToleranceVariant);
        LibraryVariableStorage.Dequeue(ExpectedNumberOfEntriesOutsideToleranceVariant);
        LibraryVariableStorage.Dequeue(AccountTypeVariant);
        LibraryVariableStorage.Dequeue(AmountVariant);
        LibraryVariableStorage.Dequeue(ToleranceVariant);
        LibraryVariableStorage.Dequeue(ToleranceTypeVariant);
        LibraryVariableStorage.Dequeue(GoToEntryNoVariant);

        GoToEntryNo := GoToEntryNoVariant;
        if GoToEntryNo then begin
            LibraryVariableStorage.Dequeue(EntryNoVariant);
            Assert.IsTrue(PaymentApplication.FindFirstField("Applies-to Entry No.", EntryNoVariant), 'Cannot find row on the page');
        end;

        AccountTypeInt := AccountTypeVariant;
        AccountType := "Gen. Journal Account Type".FromInteger(AccountTypeInt);

        // Verify Overall Confidence matches
        Assert.AreEqual(
          MatchConfidenceVariant,
          PaymentApplication.Control2.MatchConfidence.Value,
          'Unexpected value of ''Match Confidence''');
        Assert.AreEqual(
          Format(RelatedPartyMatchedVariant),
          PaymentApplication.Control2.RelatedPatryMatchedOverview.Value,
          'Unexpected value of ''Related Party Matched''');
        Assert.AreEqual(
          Format(DocExtDocNoMatchedVariant),
          PaymentApplication.Control2.DocExtDocNoMatchedOverview.Value,
          'Unexpected value of ''Doc. No./Ext. Doc. No. Matched''');

        // Verify No. Of Entries within tolerance and lookups
        Assert.AreEqual(
          Format(ExpectedNumberOfEntriesWithinToleranceVariant),
          PaymentApplication.Control2.NoOfLedgerEntriesWithinAmount.Value,
          'Unexpected value of ''Number of Ledger Entries Within Amount Tolerance''');
        Assert.AreEqual(
          Format(ExpectedNumberOfEntriesOutsideToleranceVariant),
          PaymentApplication.Control2.NoOfLedgerEntriesOutsideAmount.Value,
          'Unexpected value of ''Number of Ledger Entries Outside Amount Tolerance''');

        case AccountType of
            BankAccReconciliationLine."Account Type"::Customer:
                VerifyNoOfCustomerLedgerEntriesOnMatchDetailsLookup(PaymentApplication, ToleranceVariant, ToleranceTypeVariant, AmountVariant);
            BankAccReconciliationLine."Account Type"::Vendor:
                VerifyNoOfVendorLedgerEntriesOnMatchDetailsLookup(PaymentApplication, ToleranceVariant, ToleranceTypeVariant, AmountVariant);
            BankAccReconciliationLine."Account Type"::"Bank Account":
                VerifyNoOfBankAccountLedgerEntriesOnMatchDetailsLookup(
                  PaymentApplication, ToleranceVariant, ToleranceTypeVariant, AmountVariant);
            else
                Assert.Fail('Wrong Account Type found');
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AmountInclToleranceIsNotConsideredModalPageHandler(var PaymentApplication: TestPage "Payment Application")
    begin
        PaymentApplication.Control2.AmountMatchText.AssertEquals('Not Considered');
    end;

    local procedure VerifyOneToManyTempBankStatementMatchingBufferLine(var TempBankStmtMultipleMatchLine: Record "Bank Stmt Multiple Match Line" temporary; OneToManyTempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary; ExpectedNoOfLines: Integer; ExpectedRemainingAmount: Decimal)
    var
        BankStmtMultipleMatchLine: Record "Bank Stmt Multiple Match Line";
        BankStatementMatchingBuffer: Record "Bank Statement Matching Buffer";
    begin
        Assert.AreEqual(
          true, OneToManyTempBankStatementMatchingBuffer."One to Many Match",
          'OneToManyTempBankStatementMatchingBuffer line was not created correctly');
        Assert.AreEqual(
          -1, OneToManyTempBankStatementMatchingBuffer."Entry No.",
          'OneToManyTempBankStatementMatchingBuffer line was not created correctly');
        Assert.AreEqual(
          ExpectedNoOfLines, OneToManyTempBankStatementMatchingBuffer."No. of Entries",
          'OneToManyTempBankStatementMatchingBuffer line was not created correctly');
        Assert.AreEqual(
          ExpectedRemainingAmount, OneToManyTempBankStatementMatchingBuffer."Total Remaining Amount",
          'OneToManyTempBankStatementMatchingBuffer line was not created correctly');

        // Verify BankStatementMatchingBuffer Lines
        TempBankStmtMultipleMatchLine.Reset();
        TempBankStmtMultipleMatchLine.SetRange("Line No.", OneToManyTempBankStatementMatchingBuffer."Line No.");
        TempBankStmtMultipleMatchLine.SetRange("Account Type", OneToManyTempBankStatementMatchingBuffer."Account Type");
        TempBankStmtMultipleMatchLine.SetRange("Account No.", OneToManyTempBankStatementMatchingBuffer."Account No.");

        Assert.AreEqual(ExpectedNoOfLines, TempBankStmtMultipleMatchLine.Count, 'There should be only one TempBankStmtMultipleMatchLine');
        TempBankStmtMultipleMatchLine.FindFirst();

        Assert.IsTrue(BankStatementMatchingBuffer.IsEmpty, 'No permanent lines should be inserted in BankStatementMatchingBuffer table');
        Assert.IsTrue(BankStmtMultipleMatchLine.IsEmpty, 'No permanent lines should be inserted in BankStmtMultipleMatchLine table');
    end;

    local procedure VerifyOneToOneBankStatementMatchingBufferLine(var TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary; EntryNo: Integer)
    begin
        TempBankStatementMatchingBuffer.SetRange("Entry No.", EntryNo);
        TempBankStatementMatchingBuffer.SetRange("One to Many Match", false);

        Assert.IsTrue(TempBankStatementMatchingBuffer.FindFirst(),
          'Single Match TempBankStatementMatchingBuffer was removed by calling Insert One to Many rule');
        Assert.AreEqual(
          0, TempBankStatementMatchingBuffer."No. of Entries",
          'Current TempBankStatementMatchingBuffer was modified by calling Insert One to Many rule');

        TempBankStatementMatchingBuffer.Reset();
    end;

    local procedure VerifyMultipleApplicationsBankAccReconciliationLine(BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; Quality: Integer; ExpectedDifference: Decimal; ExpectedAppliedAmount: Decimal; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; ExpectedNoOfEntries: Integer)
    begin
        BankAccReconciliationLine.Get(
          BankAccReconciliationLine."Statement Type", BankAccReconciliationLine."Bank Account No.",
          BankAccReconciliationLine."Statement No.", BankAccReconciliationLine."Statement Line No.");
        BankAccReconciliationLine.CalcFields("Match Quality");

        Assert.AreEqual(
          BankAccReconciliationLine.Difference, ExpectedDifference, 'Difference was not set on the BankAccReconciliationLine correctly');
        Assert.AreEqual(
          BankAccReconciliationLine."Applied Amount", ExpectedAppliedAmount,
          'Applied Amount was not set on the BankAccReconciliationLine correctly');
        Assert.AreEqual(
          BankAccReconciliationLine."Account Type", AccountType, 'Account Type was not set on the BankAccReconciliationLine correctly');
        Assert.AreEqual(
          BankAccReconciliationLine."Account No.", AccountNo, 'Account Type was not set on the BankAccReconciliationLine correctly');
        Assert.AreEqual(
          BankAccReconciliationLine."Applied Entries", ExpectedNoOfEntries, 'Applied Entries are not set to a correct value');
        if Quality = TempBankPmtApplRule.GetTextMapperScore() then
            Assert.IsTrue((BankAccReconciliationLine."Match Quality" >= Quality) and (BankAccReconciliationLine."Match Quality" <= TempBankPmtApplRule.GetMaxTextMapperScore()), 'Match Quality is not set correctly')
        else
            Assert.AreEqual(BankAccReconciliationLine."Match Quality", Quality, 'Match Quality is not set correctly')
    end;

    local procedure VerifyMultipleApplicationsAppliedEntries(AppliedPaymentEntry: Record "Applied Payment Entry"; Quality: Integer; ExpectedAppliedAmount: Decimal; ExpectedAppliesToEntryNo: Integer)
    begin
        Assert.AreEqual(AppliedPaymentEntry."Applied Amount", ExpectedAppliedAmount, 'Wrong amount set');
        Assert.AreEqual(AppliedPaymentEntry."Applies-to Entry No.", ExpectedAppliesToEntryNo, 'Wrong Applies-to Entry No. value is set');
        if Quality = TempBankPmtApplRule.GetTextMapperScore() then
            Assert.IsTrue((AppliedPaymentEntry.Quality >= Quality) and (AppliedPaymentEntry.Quality <= TempBankPmtApplRule.GetMaxTextMapperScore()), 'Wrong quality is set')
        else
            Assert.AreEqual(AppliedPaymentEntry.Quality, Quality, 'Wrong quality is set')
    end;
}
