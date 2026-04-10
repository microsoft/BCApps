codeunit 134141 "ERM Bank Reconciliation"
{
    Permissions = TableData "Bank Account Ledger Entry" = rid,
                  TableData "Bank Account Statement" = rimd;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Bank Reconciliation]
        isInitialized := false;
    end;

    var
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        LibraryRandom: Codeunit "Library - Random";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryDimension: Codeunit "Library - Dimension";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryHumanResource: Codeunit "Library - Human Resource";
        LibraryInventory: Codeunit "Library - Inventory";
        isInitialized: Boolean;
        TimesSuggestLinesRun: Integer;
        StatementNoEditableErr: Label '%1 should not be editable.', Comment = '%1 - "Statement No." field caption';
        TransactionAmountReducedMsg: Label 'The value in the Transaction Amount field has been reduced';
        ICPartnerAccountTypeQst: Label 'The resulting entry will be of type IC Transaction, but no Intercompany Outbox transaction will be created. \\Do you want to use the IC Partner account type anyway?';
        StatementAlreadyExistsErr: Label 'A bank account reconciliation with statement number %1 already exists.', Comment = '%1 - statement number';
        PaymentLineAppliedMsg: Label '%1 payment lines out of 1 are applied.\\', Comment = '%1 - number';
        WrongAmountErr: Label '%1 must be %2.', Locked = true;
        HasBankEntriesMsg: Label 'When you use action Delete the bank statement will be deleted';
        AnalysisViewErr: Label 'Last Entry No. must be %1 in %2.', Comment = '%1= Field Value ,%2= Table Name.';
        StatementEndingBalanceErr: Label '%1 must be %2 in %3', Comment = '%1 = Statement Ending Balance, %2 = Amount, %3 = Bank Acc. Reconciliation';
        AccountNoMustBeEqualToErr: Label 'Account No. must equal to %1.', Comment = '%1= Field Value';

    [Test]
    [HandlerFunctions('GenJnlPageHandler')]
    [Scope('OnPrem')]
    procedure TransferToGenJnlLineWithBalAcc()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        Initialize();

        // Setup: Create a bank rec. and add a line to it
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        SetupBankAccReconciliation(BankAccReconciliation, BankAccReconciliationLine);

        // Exercise: Execute Batch Job Transfer to GL Journal
        LibraryLowerPermissions.AddAccountReceivables();
        TransferToGenJnlReport(BankAccReconciliation, GenJournalBatch);

        // Verify: Check that the line was transfered to the GL Journal
        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        Assert.IsTrue(GenJournalLine.FindFirst(), 'Failed to find transfered journal line');
        Assert.AreEqual(BankAccReconciliationLine."Statement Amount", GenJournalLine.Amount,
          'Amount on transfered journal line is not correct');
        GenJournalLine.TestField("Bal. Account Type", GenJournalBatch."Bal. Account Type");
        GenJournalLine.TestField("Bal. Account No.", GenJournalBatch."Bal. Account No.");
    end;

    [Test]
    [HandlerFunctions('GenJnlPageHandler')]
    [Scope('OnPrem')]
    procedure TransferToGenJnlLineWithBalAccAndPostWithoutGettingApplyUpdated()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        Initialize();

        // Setup: Create a bank rec. and add a line to it
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        SetupBankAccReconciliation(BankAccReconciliation, BankAccReconciliationLine);

        // Exercise: Execute Batch Job Transfer to GL Journal
        LibraryLowerPermissions.AddAccountReceivables();
        TransferToGenJnlReport(BankAccReconciliation, GenJournalBatch);
        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.FindFirst();
        GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::"G/L Account");
        GenJournalLine.Validate("Account No.", LibraryERM.CreateGLAccountNoWithDirectPosting());
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Bal. Account No.", BankAccReconciliation."Bank Account No.");
        GenJournalLine.Modify();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Check that the line was transfered to the GL Journal
        BankAccReconciliationLine.get(BankAccReconciliation."Statement Type", BankAccReconciliationLine."Bank Account No.", BankAccReconciliationLine."Statement No.", BankAccReconciliationLine."Statement Line No.");
        Assert.IsTrue(BankAccReconciliationLine."Applied Amount" = 0, 'Statement most not get applied as signed have changed');

    end;

    [Test]
    [HandlerFunctions('GenJnlPageHandler')]
    [Scope('OnPrem')]
    procedure TransferToGenJnlAndPostPlusGetApplyUpdated()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        Initialize();

        // Setup: Create a bank rec. and add a line to it
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);

        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        SetupBankAccReconciliation(BankAccReconciliation, BankAccReconciliationLine);
        GenJournalBatch.Validate("Bal. Account Type", GenJournalBatch."Bal. Account Type"::"Bank Account");
        GenJournalBatch.Validate("Bal. Account No.", BankAccReconciliation."Bank Account No.");
        GenJournalBatch.Modify();

        // Exercise: Execute Batch Job Transfer to GL Journal
        LibraryLowerPermissions.AddAccountReceivables();
        TransferToGenJnlReport(BankAccReconciliation, GenJournalBatch);
        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.FindFirst();
        GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::"G/L Account");
        GenJournalLine.Validate("Account No.", LibraryERM.CreateGLAccountNoWithDirectPosting());
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Bal. Account No.", BankAccReconciliation."Bank Account No.");
        GenJournalLine.Modify();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Check that the line was transfered to the GL Journal
        BankAccReconciliationLine.get(BankAccReconciliation."Statement Type", BankAccReconciliationLine."Bank Account No.", BankAccReconciliationLine."Statement No.", BankAccReconciliationLine."Statement Line No.");
        Assert.IsTrue(BankAccReconciliationLine."Statement Amount" = BankAccReconciliationLine."Applied Amount", 'Statement Amount most match applied amount');

    end;

    [Test]
    [HandlerFunctions('GenJnlPageHandler')]
    [Scope('OnPrem')]
    procedure TransferToGenJnlLineWithoutBalAcc()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        Initialize();

        // Setup: Create a bank rec. and add a line to it
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, LibraryERM.SelectGenJnlTemplate());
        SetupBankAccReconciliation(BankAccReconciliation, BankAccReconciliationLine);

        // Exercise: Execute Batch Job Transfer to GL Journal
        LibraryLowerPermissions.AddAccountReceivables();
        TransferToGenJnlReport(BankAccReconciliation, GenJournalBatch);
        // Verify: Check that the line was transfered to the GL Journal
        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        Assert.IsTrue(GenJournalLine.FindFirst(), 'Failed to find transfered journal line');
        Assert.AreEqual(-BankAccReconciliationLine."Statement Amount", GenJournalLine.Amount,
          'Amount on transfered journal line is not correct');
        GenJournalLine.TestField("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.TestField("Bal. Account No.", BankAccReconciliation."Bank Account No.");
    end;

    [Test]

    [Scope('OnPrem')]
    procedure DateCompressCheckLedgerEntries()
    var
        BankAccount: Record "Bank Account";
        CheckLedgerEntry: Record "Check Ledger Entry";
        DeleteCheckLedgerEntries: Report "Delete Check Ledger Entries";
        SaveWorkDate: Date;
        CurrentYear: Integer;
    begin
        Initialize();

        // Date compress check ledger entries
        // Close fiscal year
        LibraryFiscalYear.CreateClosedAccountingPeriods();
        SaveWorkDate := WorkDate();
        WorkDate(LibraryFiscalYear.GetFirstPostingDate(true));
        CurrentYear := Date2DMY(WorkDate(), 3);

        // Create check ledger entries
        PostCheck(BankAccount, CreateBankAccount(), LibraryRandom.RandInt(1000));

        // Run delete check batch job
        CheckLedgerEntry.SetRange("Bank Account No.", BankAccount."No.");
        DeleteCheckLedgerEntries.InitializeRequest(WorkDate(), DMY2Date(31, 12, CurrentYear));
        DeleteCheckLedgerEntries.UseRequestPage := false;
        DeleteCheckLedgerEntries.SetTableView(CheckLedgerEntry);
        DeleteCheckLedgerEntries.Run();
        WorkDate(SaveWorkDate);

        // Verify check ledger entries are deleted
        CheckLedgerEntry.Reset();
        CheckLedgerEntry.SetRange("Bank Account No.", BankAccount."No.");
        CheckLedgerEntry.SetRange("Entry Status", CheckLedgerEntry."Entry Status"::Posted);
        Assert.AreEqual(CheckLedgerEntry.Count, 0, 'Expected no posted check ledger entries to exist');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckBankAccReconsiliation()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccount: Record "Bank Account";
        DocumentNo: Code[20];
    begin
        Initialize();

        // Setup
        DocumentNo := PostCheck(BankAccount, CreateBankAccount(), LibraryRandom.RandInt(1000));

        // Exercise: Bank Account Reconciliation.
        LibraryLowerPermissions.AddAccountReceivables();
        CreateSuggestedBankReconc(BankAccReconciliation, BankAccount."No.", false);  // FALSE for 'Include Checks'.

        // Post the Bank Account Reconciliation
        LibraryERM.PostBankAccReconciliation(BankAccReconciliation);

        // Verify: Verify Bank Ledger Entries closed
        VerifyBankRecLedgerEntry(BankAccount."No.", DocumentNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ReversalBankAccReconciliation()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        GenJournalLine: Record "Gen. Journal Line";
        GLRegister: Record "G/L Register";
        ReversalEntry: Record "Reversal Entry";
    begin
        // Create and post General Journal Line using Random Values and Reversal of Bank Ledger Entries for Bank Reconciliation.

        // Setup: Create General Journal Line and Reverse Bank Ledger Entries for Bank Reconciliation.
        Initialize();
        CreateAndPostGenJournalLine(GenJournalLine, CreateBankAccount());
        GLRegister.FindLast();
        ReversalEntry.SetHideDialog(true);
        ReversalEntry.ReverseRegister(GLRegister."No.");

        // Exercise: Bank Account Reconciliation.
        LibraryLowerPermissions.AddAccountReceivables();
        CreateSuggestedBankReconc(BankAccReconciliation, GenJournalLine."Bal. Account No.", false);  // FALSE for 'Include Checks'.

        // Post the Bank Account Reconciliation
        LibraryERM.PostBankAccReconciliation(BankAccReconciliation);

        // Verify: Verify Bank Ledger Entry.
        VerifyReversedBankLedgerEntry(GenJournalLine."Bal. Account No.", GenJournalLine."Document No.", GenJournalLine.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestBankReconcIncludeCheckTrue()
    var
        BankAccount: Record "Bank Account";
        DocumentNo: Code[20];
    begin
        // Verify Bank Reconciliation Lines for Check Ledger entries ,when Include Check is True on Suggest Bank Account Reconciliation Lines.

        // Setup: Create Bank Account, create Check Ledger Entries.
        Initialize();
        DocumentNo := PostCheck(BankAccount, CreateBankAccount(), LibraryRandom.RandInt(1000));  // Take random Amount.

        // Exercise and Verification.
        LibraryLowerPermissions.AddAccountReceivables();
        SuggestAndVerifyBankReconcLine(BankAccount, DocumentNo, true);  // '' for DocumentNo, TRUE for 'Include Checks'.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestBankReconcIncludeCheckFalse()
    var
        BankAccount: Record "Bank Account";
        DocumentNo: Code[20];
    begin
        // Verify Bank Reconciliation Lines for Bank Account ledger entries ,when Include Check is False on Suggest Bank Account Reconciliation Lines.

        // Setup: Create Bank Account, create Check Ledger Entries.
        Initialize();
        DocumentNo := PostCheck(BankAccount, CreateBankAccount(), LibraryRandom.RandInt(1000));  // Take random Amount.

        // Exercise and Verification.
        LibraryLowerPermissions.AddAccountReceivables();
        SuggestAndVerifyBankReconcLine(BankAccount, DocumentNo, false);  // '' for CheckNo, FALSE for 'Include Checks'.
    end;

    [Test]
    [HandlerFunctions('DeleteStatementConfirmHandler')]
    [Scope('OnPrem')]
    procedure DeleteBankStatementConfirmed()
    var
        BankAccountStatement: Record "Bank Account Statement";
    begin
        // Setup.
        Initialize();
        CreateBankReconciliationWithLedgerEntries(BankAccountStatement);

        // Exercise.
        LibraryLowerPermissions.AddAccountReceivables();
        LibraryVariableStorage.Enqueue(true);
        BankAccountStatement.Delete(true);

        // Verify.
        asserterror
          BankAccountStatement.Get(BankAccountStatement."Bank Account No.",
            BankAccountStatement."Statement No.");
        Assert.AssertRecordNotFound();
    end;

    [Test]
    [HandlerFunctions('DeleteStatementConfirmHandler')]
    [Scope('OnPrem')]
    procedure DeleteBankStatementNotConfirmed()
    var
        BankAccountStatement: Record "Bank Account Statement";
    begin
        // Setup.
        Initialize();
        CreateBankReconciliationWithLedgerEntries(BankAccountStatement);

        // Exercise.
        LibraryLowerPermissions.AddAccountReceivables();
        LibraryVariableStorage.Enqueue(false);
        asserterror BankAccountStatement.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyTotalOutstandingChecks()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccount: Record "Bank Account";
        OutstandingAmt: Decimal;
    begin
        Initialize();

        // Setup.
        PostCheck(BankAccount, CreateBankAccount(), LibraryRandom.RandDec(1000, 2));
        CreateSuggestedBankReconc(BankAccReconciliation, BankAccount."No.", true);
        LibraryERM.PostBankAccReconciliation(BankAccReconciliation);

        OutstandingAmt := LibraryRandom.RandDec(1000, 2);
        PostCheck(BankAccount, BankAccount."No.", OutstandingAmt);
        CreateSuggestedBankReconc(BankAccReconciliation, BankAccount."No.", true);

        // Exercise.
        BankAccount.CalcFields("Total on Checks");

        // Verify.
        BankAccount.TestField("Total on Checks", OutstandingAmt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetStatementNoFromBankAccount()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccount: Record "Bank Account";
    begin
        Initialize();

        // Setup.
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount."Last Statement No." := '';
        BankAccount.Modify();

        // Exercise.
        LibraryLowerPermissions.AddAccountReceivables();
        BankAccReconciliation.Init();
        BankAccReconciliation.Validate("Statement Type", BankAccReconciliation."Statement Type"::"Bank Reconciliation");
        BankAccReconciliation.Validate("Bank Account No.", BankAccount."No.");
        BankAccReconciliation.Insert(true);

        // Verify.
        BankAccReconciliation.TestField("Statement No.", Format(1));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BankAccReconciliationBalanceToReconcile()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        GenJournalLine: Record "Gen. Journal Line";
        BankAccReconciliationPage: TestPage "Bank Acc. Reconciliation";
        BalanceToReconcile: Decimal;
        i: Integer;
    begin
        // [SCENARIO 363054] "Balance to Reconcile" does not include amounts from Posted Bank Reconciliations
        Initialize();

        // [GIVEN] Posted Bank Reconciliation A with Amount X
        CreateAndPostGenJournalLine(GenJournalLine, CreateBankAccount());
        CreateSuggestedBankReconc(BankAccReconciliation, GenJournalLine."Bal. Account No.", false);
        LibraryERM.PostBankAccReconciliation(BankAccReconciliation);

        // [GIVEN] Bank Reconciliation B with Amount Y
        for i := 1 to LibraryRandom.RandInt(5) do begin
            CreateAndPostGenJournalLine(GenJournalLine, GenJournalLine."Bal. Account No.");
            BalanceToReconcile += GenJournalLine.Amount;
        end;
        Clear(BankAccReconciliation);
        CreateSuggestedBankReconc(BankAccReconciliation, GenJournalLine."Bal. Account No.", false);

        // [WHEN] Bank Reconciliation B page is opened
        LibraryLowerPermissions.AddAccountReceivables();
        BankAccReconciliationPage.OpenView();
        BankAccReconciliationPage.GotoRecord(BankAccReconciliation);

        // [THEN] "Balance To Reconcile" = Y.
        Assert.AreEqual(
          -BalanceToReconcile,
          BankAccReconciliationPage.ApplyBankLedgerEntries.BalanceToReconcile.AsDecimal(),
          StrSubstNo(
            WrongAmountErr, BankAccReconciliationPage.ApplyBankLedgerEntries.BalanceToReconcile.Caption,
            -BalanceToReconcile));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AccountTypeChangeClearsAccountNo()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
    begin
        Initialize();

        SetupBankAccReconciliation(BankAccReconciliation, BankAccReconciliationLine);
        Customer.FindFirst();
        BankAccReconciliationLine.Validate("Account Type", BankAccReconciliationLine."Account Type"::Customer);
        BankAccReconciliationLine.Validate("Account No.", Customer."No.");
        BankAccReconciliationLine.Validate("Account Type", BankAccReconciliationLine."Account Type"::"G/L Account");
        Assert.AreEqual('', BankAccReconciliationLine."Account No.", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShortcutDimsOnPaymentReconJournalLine()
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        DimensionValue: array[8] of Record "Dimension Value";
        i: Integer;
    begin
        // [FEATURE] [Dimension] [UT]
        // [SCENARIO 379516] Payment Reconciliation Journal correctly updates shortcut dimensions
        Initialize();
        UpdateGeneralShortcutDimensionSetup();

        // [GIVEN] Dimension 'D' with value 'V'. GLSetup."Shortcut Dimension 1 Code" = 'D'.
        // [GIVEN] Payment Reconciliation Journal Line.
        // [WHEN] Update journal line "Shortcut Dimension 1 Code" = 'V'
        BankAccReconciliationLine.Init();
        for i := 1 to ArrayLen(DimensionValue) do begin
            LibraryDimension.FindDimensionValue(DimensionValue[i], LibraryERM.GetShortcutDimensionCode(i));
            BankAccReconciliationLine.ValidateShortcutDimCode(i, DimensionValue[i].Code);
        end;

        // [THEN] Journal line Dimension Set Entry ("Dimension Set ID") contains Dimension 'D' with value 'V' record.
        for i := 1 to ArrayLen(DimensionValue) do
            Assert.AreEqual(
              DimensionValue[i].Code,
              GetDimensionValueCodeFromSetEntry(BankAccReconciliationLine."Dimension Set ID", DimensionValue[i]."Dimension Code"),
              DimensionValue[i].FieldCaption(Code));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SourceCodeSetupForReconPmtJnl()
    var
        SourceCode: Record "Source Code";
        SourceCodeSetup: Record "Source Code Setup";
        SourceCodeSetupPage: TestPage "Source Code Setup";
    begin
        // [FEATURE] [Source Code] [UT] [UI]
        // [SCENARIO 379544] Page field "Payment Reconciliation Journal" is available from "Source Code Setup"
        Initialize();

        // [GIVEN] Open Source Code Setup page
        LibraryERM.CreateSourceCode(SourceCode);
        SourceCodeSetupPage.OpenEdit();

        // [WHEN] Validate "Payment Reconciliation Journal" = "X"
        SourceCodeSetupPage."Payment Reconciliation Journal".SetValue(SourceCode.Code);
        SourceCodeSetupPage.Close();

        // [THEN] Record SourceCodeSetup."Payment Reconciliation Journal" = "X"
        SourceCodeSetup.Get();
        Assert.AreEqual(
          SourceCode.Code,
          SourceCodeSetup."Payment Reconciliation Journal",
          SourceCodeSetup.FieldCaption("Payment Reconciliation Journal"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreditDebitAmountsAddToTotalTransactionOnPaymReconJournal()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        ExpectedDocumentNo: array[2] of Code[20];
    begin
        // [SCENARIO] A Bank Account Reconciliation with both credit and debit amount is posted
        // [GIVEN] A bank account
        Initialize();
        LibraryERM.CreateBankAccount(BankAccount);
        // [GIVEN] Credit entries
        PostPaymentJournalLineWithDateAndSource(GenJournalLine, WorkDate(), LibraryPurchase.CreateVendorNo(), BankAccount."No.");
        // [GIVEN] Debit entries
        PostTwoPaymentJournalLinesWithDocNoAndBalAccount(ExpectedDocumentNo, BankAccount."No.");
        // [GIVEN] A Bank Account Reconciliation
        CreateSuggestedBankReconc(BankAccReconciliation, BankAccount."No.", false);
        Commit();

        // [WHEN] Consulting the credit and debit totals
        BankAccReconciliation.CalcFields("Total Transaction Amount", "Total Paid Amount", "Total Received Amount");

        // [THEN] The total transaction amount should be the addition of both credit and debit totals.
        Assert.AreEqual(
            BankAccReconciliation."Total Received Amount" + BankAccReconciliation."Total Paid Amount",
            BankAccReconciliation."Total Transaction Amount",
            'The transaction amount should be the sum of the credit and debit totals'
        );
    end;


    [Test]
    [HandlerFunctions('PostAndReconcilePageHandler,PostAndReconcilePageStatementDateHandler')]
    [Scope('OnPrem')]
    procedure VerifyDimSetIDOfCustLedgerEntryAfterPostingBankAccReconLine()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        StatementAmount: Decimal;
        CustomerNo: Code[20];
        CustLedgerEntryNo: Integer;
        DimSetID: Integer;
    begin
        // [FEATURE] [Customer]
        // [SCENARIO 169462] "Dimension set ID" of Cust. Ledger Entry should be equal "Dimension Set ID" of Bank Acc. Reconcilation Line after posting
        Initialize();

        // [GIVEN] Posted sales invoice for a customer
        CreateAndPostSalesInvoice(CustomerNo, CustLedgerEntryNo, StatementAmount);

        // [GIVEN] Default dimension for the customer
        CreateDefaultDimension(CustomerNo, DATABASE::Customer);

        // [GIVEN] Bank Acc. Reconcilation Line with "Dimension Set ID" = "X" and "Account No." = the customer
        CreateApplyBankAccReconcilationLine(
          BankAccReconciliation, BankAccReconciliationLine,
          BankAccReconciliationLine."Account Type"::Customer,
          CustomerNo, StatementAmount, LibraryERM.CreateBankAccountNo());
        DimSetID := ApplyBankAccReconcilationLine(
            BankAccReconciliationLine, CustLedgerEntryNo, BankAccReconciliationLine."Account Type"::Customer, '');

        // [WHEN] Post Bank Acc. Reconcilation Line
        UpdateBankAccRecStmEndingBalance(BankAccReconciliation, BankAccReconciliation."Balance Last Statement" + BankAccReconciliationLine."Statement Amount");
        LibraryERM.PostBankAccReconciliation(BankAccReconciliation);

        // [THEN] "Cust. Ledger Entry"."Dimension Set ID" = "X"
        VerifyCustLedgerEntry(CustomerNo, BankAccReconciliation."Statement No.", DimSetID);
    end;

    [Test]
    [HandlerFunctions('PostAndReconcilePageHandler,PostAndReconcilePageStatementDateHandler')]
    [Scope('OnPrem')]
    procedure VerifyDimSetIDOfVendLedgerEntryAfterPostingBankAccReconLine()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        StatementAmount: Decimal;
        VendorNo: Code[20];
        VendLedgerEntryNo: Integer;
        DimSetID: Integer;
    begin
        // [FEATURE] [Vendor]
        // [SCENARIO 169462] "Dimension set ID" of Vendor Ledger Entry should be equal "Dimension Set ID" of Bank Acc. Reconcilation Line after posting
        Initialize();

        // [GIVEN] Posted purchase invoice for a vendor
        CreateAndPostPurchaseInvoice(VendorNo, VendLedgerEntryNo, StatementAmount);

        // [GIVEN] Default dimension for the vendor
        CreateDefaultDimension(VendorNo, DATABASE::Vendor);

        // [GIVEN] Bank Acc. Reconcilation Line with "Dimension Set ID" = "X" and "Account No." = the vendor
        CreateApplyBankAccReconcilationLine(
          BankAccReconciliation, BankAccReconciliationLine,
          BankAccReconciliationLine."Account Type"::Vendor,
          VendorNo, StatementAmount, LibraryERM.CreateBankAccountNo());
        DimSetID := ApplyBankAccReconcilationLine(
            BankAccReconciliationLine, VendLedgerEntryNo, BankAccReconciliationLine."Account Type"::Vendor, '');

        // [WHEN] Post Bank Acc. Reconcilation Line
        UpdateBankAccRecStmEndingBalance(BankAccReconciliation, BankAccReconciliation."Balance Last Statement" + BankAccReconciliationLine."Statement Amount");
        LibraryERM.PostBankAccReconciliation(BankAccReconciliation);

        // [THEN] "Vendor Ledger Entry"."Dimension Set ID" = "X"
        VerifyVendLedgerEntry(VendorNo, BankAccReconciliation."Statement No.", DimSetID);
    end;

    [Test]
    [HandlerFunctions('PostAndReconcilePageHandler,PostAndReconcilePageStatementDateHandler')]
    [Scope('OnPrem')]
    procedure VerifyVATEntryAfterPostingBankAccReconLineForGLAccount()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        VATEntry: Record "VAT Entry";
        GLAccountNo: Code[20];
        BankAccountNo: Code[20];
        VATRate: Decimal;
    begin
        // [FEATURE] [G/L Account]
        // [SCENARIO 380298] VAT Entry shoud be created after posting Bank Acc. Reconcilation Line with G/L Account with VAT
        Initialize();

        // [GIVEN] G/L Account with VAT = 10%
        GLAccountNo := CreateGLAccountWithVATPostingSetup(VATRate);
        BankAccountNo := LibraryERM.CreateBankAccountNo();

        // [GIVEN] Bank Account Reconciliation for G/L Account with Amount = 100 (including VAT)
        CreateApplyBankAccReconcilationLine(BankAccReconciliation, BankAccReconciliationLine,
          BankAccReconciliationLine."Account Type"::"G/L Account",
          GLAccountNo, LibraryRandom.RandIntInRange(50, 100), BankAccountNo);
        BankAccReconciliationLine.TransferRemainingAmountToAccount();

        // [WHEN] Post Bank Acc. Reconcilation Line
        UpdateBankAccRecStmEndingBalance(BankAccReconciliation, BankAccReconciliation."Balance Last Statement" + BankAccReconciliationLine."Statement Amount");
        LibraryERM.PostBankAccReconciliation(BankAccReconciliation);

        // [THEN] VAT Entry created with "Amount" = 9,09
        VATEntry.SetRange("Document No.", BankAccReconciliation."Statement No.");
        VATEntry.FindFirst();
        VATEntry.TestField(Amount, -Round(((BankAccReconciliationLine."Statement Amount" / (1 + (VATRate / 100))) * (VATRate / 100))));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifySalespersonInDimSetOfBankAccReconLine()
    var
        Customer: Record Customer;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        // [FEATURE] [UT] [Customer]
        // [SCENARIO 175792] Salesperson code as default dimension should be in dimension set of Bank Account Reconcilation Line after validation of Customer
        Initialize();

        // [GIVEN] Customer with Salesperson Code as default dimension = "X"
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        Customer."Salesperson Code" := SalespersonPurchaser.Code;
        Customer.Modify();
        CreateDefaultDimensionWithSpecCode(SalespersonPurchaser.Code, DATABASE::"Salesperson/Purchaser");

        // [GIVEN] Record of Bank Account Reconcilation Line
        MockBankAccReconLine(BankAccReconciliationLine, BankAccReconciliationLine."Account Type"::Customer);

        // [WHEN] Validate Customer to "Account No." of Bank Account Reconcilation Line
        BankAccReconciliationLine.Validate("Account No.", Customer."No.");

        // [THEN] Dimension set of Bank Account Reconcilation Line contains Salesperson Code = "X"
        VerifyDimSetEntryValue(BankAccReconciliationLine."Dimension Set ID", Customer."Salesperson Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyPurchaserInDimSetOfBankAccReconLine()
    var
        Vendor: Record Vendor;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        // [FEATURE] [UT] [Vendor]
        // [SCENARIO 175792] Purchaser code as default dimension should be in dimension set of Bank Account Reconcilation Line after validation of Vendor
        Initialize();

        // [GIVEN] Vendor with Purhaser Code as default dimension = "X"
        LibraryPurchase.CreateVendor(Vendor);
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        Vendor."Purchaser Code" := SalespersonPurchaser.Code;
        Vendor.Modify();
        CreateDefaultDimensionWithSpecCode(SalespersonPurchaser.Code, DATABASE::"Salesperson/Purchaser");

        // [GIVEN] Record of Bank Account Reconcilation Line
        MockBankAccReconLine(BankAccReconciliationLine, BankAccReconciliationLine."Account Type"::Vendor);

        // [WHEN] Validate Vendor to "Vendor No." of Bank Account Reconcilation Line
        BankAccReconciliationLine.Validate("Account No.", Vendor."No.");

        // [THEN] Dimension set of Bank Account Reconcilation Line contains Purchaser Code = "X"
        VerifyDimSetEntryValue(BankAccReconciliationLine."Dimension Set ID", Vendor."Purchaser Code");
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('VerifyNotificationIsSend')]
    procedure BankAccReconciliationNotificationShownOnNew()
    var
        BankAccReconciliation: TestPage "Bank Acc. Reconciliation";
    begin
        // [FEATURE] [UI]
        Initialize();

        // [GIVEN] Open new Bank Account Reconciliation page
        // [WHEN] On Open New
        // [THEN] A notification should be send to import bank data
        BankAccReconciliation.OpenNew();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BankAccReconciliationStatementNoIsNotEditable()
    var
        BankAccReconciliation: TestPage "Bank Acc. Reconciliation";
    begin
        // [FEATURE] [UT] [UI]
        // [SCENARIO 381659] "Statement No." should not be editable in Bank Account Reconciliation
        Initialize();

        BankAccReconciliation.OpenEdit();
        Assert.IsFalse(
          BankAccReconciliation.StatementNo.Editable(), StrSubstNo(StatementNoEditableErr, BankAccReconciliation.StatementNo.Caption));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LastStatementOfReconciliationIsUpdatedOnlyOnInsertion()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccount: array[2] of Record "Bank Account";
    begin
        // [SCENARIO 381659] "Last Statement No." should be updated in Bank Account only on Bank Account Reconciliation insertion
        Initialize();

        // [GIVEN] Bank Account Reconciliation "BA"
        BankAccReconciliation.Init();
        BankAccReconciliation."Statement Type" := BankAccReconciliation."Statement Type"::"Bank Reconciliation";

        // [GIVEN] Bank Account "Bank1" is set for "BA" having "Last Statement No." = "X01"
        LibraryERM.CreateBankAccount(BankAccount[1]);
        BankAccount[1]."Last Statement No." := 'X01';
        BankAccount[1].Modify();
        BankAccReconciliation.Validate("Bank Account No.", BankAccount[1]."No.");

        // [GIVEN] Bank Account "Bank2" is set for "BA" (instead of "Bank1") having "Last Statement No." = "Y01"
        LibraryERM.CreateBankAccount(BankAccount[2]);
        BankAccount[2]."Last Statement No." := 'Y01';
        BankAccount[2].Modify();
        BankAccReconciliation.Validate("Bank Account No.", BankAccount[2]."No.");
        BankAccount[2].TestField("Last Statement No.", 'Y01');

        // [WHEN] Bank Account Reconciliation "BA" is inserted with "Statement No." "1"
        BankAccReconciliation.Insert(true);

        // [THEN] Bank Account "Bank1" has "Last Statement No." = "X01"
        BankAccount[1].Find();
        BankAccount[1].TestField("Last Statement No.", 'X01');

        // [THEN] Bank Account "Bank2" has "Last Statement No." = "Y02"
        BankAccount[2].Find();
        BankAccount[2].TestField("Last Statement No.", BankAccReconciliation."Statement No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LastStatementOfPaymentApplicationIsUpdatedOnlyOnInsertion()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccount: array[2] of Record "Bank Account";
    begin
        // [SCENARIO 381659] "Last Payment Statement No." should be updated in Bank Account only on Bank Account Reconciliation insertion
        Initialize();

        // [GIVEN] Bank Account Reconciliation "BA"
        BankAccReconciliation.Init();
        BankAccReconciliation."Statement Type" := BankAccReconciliation."Statement Type"::"Payment Application";

        // [GIVEN] Bank Account "Bank1" is set for "BA" having "Last Payment Statement No." = "X01"
        LibraryERM.CreateBankAccount(BankAccount[1]);
        BankAccount[1]."Last Payment Statement No." := 'X01';
        BankAccount[1].Modify();
        BankAccReconciliation.Validate("Bank Account No.", BankAccount[1]."No.");

        // [GIVEN] Bank Account "Bank2" is set for "BA" (instead of "Bank1") having "Last Payment Statement No." = "Y01"
        LibraryERM.CreateBankAccount(BankAccount[2]);
        BankAccount[2]."Last Payment Statement No." := 'Y01';
        BankAccount[2].Modify();
        BankAccReconciliation.Validate("Bank Account No.", BankAccount[2]."No.");
        BankAccount[2].TestField("Last Payment Statement No.", 'Y01');

        // [WHEN] Bank Account Reconciliation "BA" is inserted with "Statement No." "1"
        BankAccReconciliation.Insert(true);

        // [THEN] Bank Account "Bank1" has "Last Payment Statement No." = "X01"
        BankAccount[1].Find();
        BankAccount[1].TestField("Last Payment Statement No.", 'X01');

        // [THEN] Bank Account "Bank2" has "Last Payment Statement No." = "Y02"
        BankAccount[2].Find();
        BankAccount[2].TestField("Last Payment Statement No.", BankAccReconciliation."Statement No.");
    end;

    [Test]
    [HandlerFunctions('PostAndReconcilePageHandler,PostAndReconcilePageStatementDateHandler')]
    [Scope('OnPrem')]
    procedure GlobalDimensionInheritsFromDimensionSetIDOfBankAccReconLineOnPosting()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        GLAccount: Record "G/L Account";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        // [FEATURE] [Dimension]
        // [SCENARIO 202526] Global Dimension codes inherites from "Dimension Set ID" specified in Bank Acc. Reconciliation Line on posting

        Initialize();

        // [GIVEN] G/L Account "X" with Default dimension "DEPARTMENT - ADM"
        GeneralLedgerSetup.Get();
        LibraryDimension.CreateDimensionValue(DimensionValue, GeneralLedgerSetup."Global Dimension 1 Code");
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, DATABASE::"G/L Account", GLAccount."No.", GeneralLedgerSetup."Global Dimension 1 Code", DimensionValue.Code);

        // [GIVEN] Bank Acc. Reconcilation Line with G/L Account "X"
        CreateBankReconciliationWithGLAccount(BankAccReconciliation, BankAccReconciliationLine, GLAccount."No.");

        // [GIVEN] Set "Dimension Set ID" = 'Y' with dimension "DEPARTMENT - VW" for Bank Acc. Reconcilation Line
        LibraryDimension.CreateDimensionValue(DimensionValue, GeneralLedgerSetup."Global Dimension 1 Code");
        BankAccReconciliationLine.Validate(
          "Dimension Set ID", LibraryDimension.CreateDimSet(0, GeneralLedgerSetup."Global Dimension 1 Code", DimensionValue.Code));
        BankAccReconciliationLine.Modify(true);

        // [WHEN] Post Bank Acc. Reconcilation Line
        UpdateBankAccRecStmEndingBalance(BankAccReconciliation, BankAccReconciliation."Balance Last Statement" + BankAccReconciliationLine."Statement Amount");
        LibraryERM.PostBankAccReconciliation(BankAccReconciliation);

        // [THEN] G/L Entry with G/L Account "X" is posted. "Dimension Set ID" is 'Y', "Global Dimension 1 Code" is "DEPARTMENT - VW"
        VerifyGlobalDimensionCodeAndSetInGLEntry(GLAccount."No.", DimensionValue.Code, BankAccReconciliationLine."Dimension Set ID");
    end;

    [Test]
    [HandlerFunctions('GenJnlPageHandler')]
    [Scope('OnPrem')]
    procedure TransferToGenJnlLineWithReconcilBankAsBatchBalAcc()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO 201538] The gen. journal line for reconciliation Bank Account is created with a correct sign when transferred from Bank Acc. Reconclication.
        Initialize();

        // [GIVEN] Bank Acc. Reconclication "BR" with Difference "D"
        SetupBankAccReconciliation(BankAccReconciliation, BankAccReconciliationLine);

        // [GIVEN] Gen Journal Batch "JB" for "BR"."Bank Account No." as Bal. Account
        SetupGenJournalBatch(
          GenJournalBatch, GenJournalBatch."Bal. Account Type"::"Bank Account", BankAccReconciliation."Bank Account No.");

        // [WHEN] Transfer to Gen. Journal is invoked from "BR"
        TransferToGenJnlReport(BankAccReconciliation, GenJournalBatch);

        // [THEN] Created Gen. Journal Line with Bal. Account = "BR"."Bal. Account"; Amount = -"D"
        VerifyGenJournalLine(
          GenJournalBatch."Journal Template Name", GenJournalBatch.Name, -BankAccReconciliationLine.Difference,
          GenJournalLine."Bal. Account Type"::"Bank Account", BankAccReconciliation."Bank Account No.");
    end;

    [Test]
    [HandlerFunctions('GenJnlPageHandler')]
    [Scope('OnPrem')]
    procedure TransferToGenJnlLineWithNotReconcilBankAsBatchBalAcc()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        GenJournalLine: Record "Gen. Journal Line";
        BalAccountNo: Code[20];
    begin
        // [SCENARIO 201538] The gen. journal line for not reconciliation Bank Account is created with a correct sign when transferred from Bank Acc. Reconclication.
        Initialize();

        // [GIVEN] Bank Acc. Reconclication "BR" with Difference "D"
        SetupBankAccReconciliation(BankAccReconciliation, BankAccReconciliationLine);

        // [GIVEN] Bank Account "BA"
        BalAccountNo := LibraryERM.CreateBankAccountNo();
        // [GIVEN] Gen Journal Batch "JB" with Bal. type Bank Account and "JB"."Bal. Account No." = "BA"
        SetupGenJournalBatch(
          GenJournalBatch, GenJournalBatch."Bal. Account Type"::"Bank Account", BalAccountNo);

        // [WHEN] Transfer to Gen. Journal is invoked from "BR"
        TransferToGenJnlReport(BankAccReconciliation, GenJournalBatch);

        // [THEN] Created Gen. Journal Line with Bal. Account = "BA"; Amount = "D"
        VerifyGenJournalLine(
          GenJournalBatch."Journal Template Name", GenJournalBatch.Name, BankAccReconciliationLine.Difference,
          GenJournalLine."Bal. Account Type"::"Bank Account", BalAccountNo);
    end;

    [Test]
    [HandlerFunctions('GenJnlPageHandler')]
    [Scope('OnPrem')]
    procedure TransferToGenJnlLineWithGLAsBatchBalAcc()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        GenJournalLine: Record "Gen. Journal Line";
        BalAccountNo: Code[20];
    begin
        // [SCENARIO 201538] The gen. journal line for G/L Account is created with a correct sign when transferred from Bank Acc. Reconclication.
        Initialize();

        // [GIVEN] Bank Acc. Reconclication "BR" with Difference "D"
        SetupBankAccReconciliation(BankAccReconciliation, BankAccReconciliationLine);

        // [GIVEN] G/L Account "GLAcc"
        BalAccountNo := LibraryERM.CreateGLAccountNo();
        // [GIVEN] Gen Journal Batch "JB" for "GLAcc" as Bal. Account
        SetupGenJournalBatch(
          GenJournalBatch, GenJournalBatch."Bal. Account Type"::"G/L Account", BalAccountNo);

        // [WHEN] Transfer to Gen. Journal is invoked from "BR"
        TransferToGenJnlReport(BankAccReconciliation, GenJournalBatch);

        // [THEN] Created Gen. Journal Line with Bal. Account = "GLAcc"; Amount = "D"
        VerifyGenJournalLine(
          GenJournalBatch."Journal Template Name", GenJournalBatch.Name, BankAccReconciliationLine.Difference,
          GenJournalLine."Bal. Account Type"::"G/L Account", BalAccountNo);
    end;

    [Test]
    [HandlerFunctions('GenJnlPageHandler')]
    [Scope('OnPrem')]
    procedure TransferToGenJnlLineWithEmptyBankAsBatchBalAcc()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO 201538] The gen. journal line for empty Bank Account is created with a correct sign when transferred from Bank Acc. Reconclication.
        Initialize();

        // [GIVEN] Bank Acc. Reconclication "BR" with Difference "D"
        SetupBankAccReconciliation(BankAccReconciliation, BankAccReconciliationLine);

        // [GIVEN] Gen Journal Batch "JB" for empty Bank Account as Bal. Account
        SetupGenJournalBatch(
          GenJournalBatch, GenJournalBatch."Bal. Account Type"::"Bank Account", '');

        // [WHEN] Transfer to Gen. Journal is invoked from "BR"
        TransferToGenJnlReport(BankAccReconciliation, GenJournalBatch);

        // [THEN] Created Gen. Journal Line with Bal. Account = "BR"."Bal. Account"; Amount = -"D"
        VerifyGenJournalLine(
          GenJournalBatch."Journal Template Name", GenJournalBatch.Name, -BankAccReconciliationLine.Difference,
          GenJournalLine."Bal. Account Type"::"Bank Account", BankAccReconciliation."Bank Account No.");
    end;

    [Test]
    [HandlerFunctions('GenJnlPageHandler')]
    [Scope('OnPrem')]
    procedure TransferToGenJnlLineWithEmptyGLAsBatchBalAcc()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO 201538] The gen. journal line for empty G/L Account is created with a correct sign when transferred from Bank Acc. Reconclication.
        Initialize();

        // [GIVEN] Bank Acc. Reconclication "BR" with Difference "D"
        SetupBankAccReconciliation(BankAccReconciliation, BankAccReconciliationLine);

        // [GIVEN] Gen Journal Batch "JB" for empty G/L Account as Bal. Account
        SetupGenJournalBatch(
          GenJournalBatch, GenJournalBatch."Bal. Account Type"::"G/L Account", '');

        // [WHEN] Transfer to Gen. Journal is invoked from "BR"
        TransferToGenJnlReport(BankAccReconciliation, GenJournalBatch);

        // [THEN] Created Gen. Journal Line Bal. with Account = "BR"."Bal. Account"; Amount = -"D"
        VerifyGenJournalLine(
          GenJournalBatch."Journal Template Name", GenJournalBatch.Name, -BankAccReconciliationLine.Difference,
          GenJournalLine."Bal. Account Type"::"Bank Account", BankAccReconciliation."Bank Account No.");
    end;

    [Test]
    [HandlerFunctions('TransToDiffAccModalPageHandler,PostAndReconcilePageHandler')]
    [Scope('OnPrem')]
    procedure PmtReconLineForCurrencyBankAccount()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        GenJournalLine: Record "Gen. Journal Line";
        MatchBankPayments: Codeunit "Match Bank Payments";
        CurrencyCode: Code[10];
        GLAccNo: Code[20];
        ExchRateAmount: Decimal;
    begin
        // [FEATURE] [Currency]
        // [SCENARIO 211312] G/L Entry with LCY creates when post Bank Acc. Reconciliation Line with FCY Bank Account
        Initialize();

        // [GIVEN] Currency "X" with "Exchange Rate" = 1:5
        ExchRateAmount := LibraryRandom.RandIntInRange(5, 10);
        CurrencyCode :=
          LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), ExchRateAmount, LibraryRandom.RandIntInRange(5, 10));

        // [GIVEN] Bank Account Reconciliation Line with Bank Account with Currency "X" and FCY Amount = 100
        CreateBankReconciliation(
          BankAccReconciliation, CreateBankAccountWithCurrencyCode(CurrencyCode),
          BankAccReconciliation."Statement Type"::"Payment Application");
        CreateBankAccReconLine(BankAccReconciliationLine, BankAccReconciliation);
        GLAccNo := LibraryERM.CreateGLAccountNo();
        LibraryVariableStorage.Enqueue(GLAccNo); // for TransToDiffAccModalPageHandler
        MatchBankPayments.TransferDiffToAccount(BankAccReconciliationLine, GenJournalLine);
        LibraryLowerPermissions.SetAccountReceivables();

        // [WHEN] Post Bank Acc. Reconciliation
        UpdateBankAccRecStmEndingBalance(BankAccReconciliation, BankAccReconciliation."Balance Last Statement" + BankAccReconciliationLine."Statement Amount");
        LibraryERM.PostBankAccReconciliation(BankAccReconciliation);

        // [THEN] G/L Entry created with Amount = 20
        VerifyGLEntryAmount(
          BankAccReconciliation."Statement No.", GLAccNo, -Round(BankAccReconciliationLine."Statement Amount" / ExchRateAmount));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,BankAccReconTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ReversedEntriesAreNotShownInBankAccReconTest()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        ExpectedDocumentNo: array[2] of Code[20];
        BankAccountNo: Code[20];
        RequestPageXML: Text;
    begin
        // [FEATURE] [Reverse] [Payment] [Report] [Bank Acc. Recon. - Test]
        // [SCENARIO 231426] Reversed Bank Account Ledger Entries are not shown when report "Bank Acc. Recon. - Test" is printed
        Initialize();

        // [GIVEN] Bank Account = "B"
        BankAccountNo := LibraryERM.CreateBankAccountNo();

        // [GIVEN] Two posted vendor payments "P1" and "P2" with balancing bank account "B"
        PostTwoPaymentJournalLinesWithDocNoAndBalAccount(ExpectedDocumentNo, BankAccountNo);

        // [GIVEN] Payment "P2" is reversed
        ReverseTransactionGenJournalLine(ExpectedDocumentNo[2], BankAccountNo);

        // [GIVEN] Bank Account Reconciliation for "B"
        LibraryERM.CreateBankAccReconciliation(
          BankAccReconciliation, BankAccountNo, BankAccReconciliation."Statement Type"::"Bank Reconciliation");
        BankAccReconciliation.SetRecFilter();

        Commit();

        // [WHEN] Run report "Bank Acc. Recon. - Test" with enabled "Print outstanding transactions" for "B".
        LibraryVariableStorage.Enqueue(true);
        RequestPageXML := REPORT.RunRequestPage(REPORT::"Bank Acc. Recon. - Test", RequestPageXML);
        LibraryReportDataset.RunReportAndLoad(REPORT::"Bank Acc. Recon. - Test", BankAccReconciliation, RequestPageXML);

        // [THEN] Payment "P1" exists in export XML.
        LibraryReportDataset.AssertElementWithValueExists('Outstd_Bank_Transac_Doc_No_', ExpectedDocumentNo[1]);

        // [THEN] Payment "P2" doesn't exist in export XML.
        LibraryReportDataset.AssertElementWithValueNotExist('Outstd_Bank_Transac_Doc_No_', ExpectedDocumentNo[2]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BankAccReconciliationLine_GetDescription()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Description: Text[50];
    begin
        // [FEATURE] [Bank Acc. Reconciliation Line] [UT] [Description]
        // [SCENARIO 233511] TAB 274 "Bank Acc. Reconciliation Line".GetDescription() returns "Description" field value if not blanked
        // [SCENARIO 233511] and applied description info in case of blanked "Description" field
        Initialize();
        SetupBankAccReconciliation(BankAccReconciliation, BankAccReconciliationLine);

        // Blanked "Description", no applied entry
        UpdateBankAccReconciliationLineDescription(BankAccReconciliationLine, '');
        Assert.AreEqual('', BankAccReconciliationLine.GetDescription(), '');

        // Typed "Description", no applied entry
        Description := LibraryUtility.GenerateGUID();
        UpdateBankAccReconciliationLineDescription(BankAccReconciliationLine, Description);
        Assert.AreEqual(Description, BankAccReconciliationLine.GetDescription(), '');

        // Blanked "Description", single applied entry
        Description := LibraryUtility.GenerateGUID();
        MockAppliedPmtEntry(BankAccReconciliationLine, 1, Description);
        UpdateBankAccReconciliationLineDescription(BankAccReconciliationLine, '');
        Assert.AreEqual(Description, BankAccReconciliationLine.GetDescription(), '');

        // Typed "Description", single applied entry
        Description := LibraryUtility.GenerateGUID();
        UpdateBankAccReconciliationLineDescription(BankAccReconciliationLine, Description);
        Assert.AreEqual(Description, BankAccReconciliationLine.GetDescription(), '');

        // Blanked "Description", multiple applied entries
        MockAppliedPmtEntry(BankAccReconciliationLine, 2, LibraryUtility.GenerateGUID());
        UpdateBankAccReconciliationLineDescription(BankAccReconciliationLine, '');
        Assert.AreEqual('', BankAccReconciliationLine.GetDescription(), '');

        // Typed "Description", multiple applied entries
        Description := LibraryUtility.GenerateGUID();
        UpdateBankAccReconciliationLineDescription(BankAccReconciliationLine, Description);
        Assert.AreEqual(Description, BankAccReconciliationLine.GetDescription(), '');
    end;

    [Test]
    [HandlerFunctions('PostAndReconcilePageHandler,PostAndReconcilePageStatementDateHandler')]
    [Scope('OnPrem')]
    procedure PostBankAccRecon_Description_OnlyInLine()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        GLEntry: Record "G/L Entry";
        Description: Text[50];
    begin
        // [FEATURE] [Description]
        // [SCENARIO 233511] Post bank account reconciliation in case of typed line's "Description" and blanked applied description
        Initialize();

        // [GIVEN]
        Description := LibraryUtility.GenerateGUID();
        CreateApplyBankReconWithDescription(BankAccReconciliation, '', Description);

        // [WHEN]
        GLEntry.FindLast();
        LibraryERM.PostBankAccReconciliation(BankAccReconciliation);

        // [THEN]
        VerifyGLEntryWithDescriptionExists(GLEntry."Entry No.", Description);
    end;

    [Test]
    [HandlerFunctions('PostAndReconcilePageHandler,PostAndReconcilePageStatementDateHandler')]
    [Scope('OnPrem')]
    procedure PostBankAccRecon_Description_OnlyInAppliesEntry()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        GLEntry: Record "G/L Entry";
        Description: Text[50];
    begin
        // [FEATURE] [Description]
        // [SCENARIO 233511] Post bank account reconciliation in case of blanked line's "Description" and typed applied description
        Initialize();

        // [GIVEN]
        Description := LibraryUtility.GenerateGUID();
        CreateApplyBankReconWithDescription(BankAccReconciliation, Description, '');

        // [WHEN]
        GLEntry.FindLast();
        LibraryERM.PostBankAccReconciliation(BankAccReconciliation);

        // [THEN]
        VerifyGLEntryWithDescriptionExists(GLEntry."Entry No.", Description);
    end;

    [Test]
    [HandlerFunctions('PostAndReconcilePageHandler,PostAndReconcilePageStatementDateHandler')]
    [Scope('OnPrem')]
    procedure PostBankAccRecon_Description_Both()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        GLEntry: Record "G/L Entry";
        Description: Text[50];
    begin
        // [FEATURE] [Description]
        // [SCENARIO 233511] Post bank account reconciliation in case of typed line's "Description" and typed applied description
        Initialize();

        // [GIVEN]
        Description := LibraryUtility.GenerateGUID();
        CreateApplyBankReconWithDescription(BankAccReconciliation, LibraryUtility.GenerateGUID(), Description);

        // [WHEN]
        GLEntry.FindLast();
        LibraryERM.PostBankAccReconciliation(BankAccReconciliation);

        // [THEN]
        VerifyGLEntryWithDescriptionExists(GLEntry."Entry No.", Description);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPmtOnlyBankAccReconLastStatementFields()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccountNo: Code[20];
    begin
        // [SCENARIO 265955] When Payment Application Bank Acc. Reconciliation is posted without reconciliation, then Bank Account "Last Statement No." and "Balance Last Statement" are not changed,
        // [SCENARIO 265955] whereas field "Last Payment Statement No." equals to Bank Acc. Reconciliation "Statement No."
        Initialize();

        // [GIVEN] Bank Account with "Last Statement No." = <blank>, "Last Payment Statement No." = <blank> and "Balance Last Statement" = 0
        BankAccountNo := LibraryERM.CreateBankAccountNo();

        // [GIVEN] Create Bank Acc. Reconciliation with Statement Type = "Payment Application" and "Post Payments Only" = TRUE, Reconciliation Line has Statement Amount <> 0
        PrepareBankAccReconciliationWithPostPaymentsOnly(BankAccReconciliation, BankAccountNo, true);

        // [WHEN] Post Bank Acc. Reconciliation
        LibraryERM.PostBankAccReconciliation(BankAccReconciliation);

        // [THEN] Bank Account "Last Statement No." = <blank> and "Balance Last Statement" = 0
        // [THEN] Bank Account "Last Payment Statement No." equals to "Statement No." from Bank Acc. Reconciliation
        VerifyBankAccountLastStatementFields(BankAccountNo, BankAccReconciliation."Statement No.", '', 0);
    end;

    [Test]
    [HandlerFunctions('PostAndReconcilePageHandler,PostAndReconcilePageStatementDateHandler')]
    [Scope('OnPrem')]
    procedure PostBankAccReconLastStatementFields()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccountNo: Code[20];
    begin
        // [SCENARIO 265955] When Payment Application Bank Acc. Reconciliation is posted with reconciliation, then Bank Account "Last Statement No." and "Last Payment Statement No." are both equal to "Statement No." from Bank Acc. Reconciliation
        // [SCENARIO 265955] "Balance Last Statement" is increased by Posted Payment Recon. Line "Statement Amount" value
        Initialize();

        // [GIVEN] Bank Account with "Last Statement No." = <blank>, "Last Payment Statement No." = <blank> and "Balance Last Statement" = 0
        BankAccountNo := LibraryERM.CreateBankAccountNo();

        // [GIVEN] Create Bank Acc. Reconciliation with Statement Type = "Payment Application" and "Post Payments Only" = FALSE, Reconciliation line has Statement Amount = 1000.0
        PrepareBankAccReconciliationWithPostPaymentsOnly(BankAccReconciliation, BankAccountNo, false);

        // [WHEN] Post Bank Acc. Reconciliation
        LibraryERM.PostBankAccReconciliation(BankAccReconciliation);

        // [THEN] Bank Account "Last Statement No." and "Last Payment Statement No." are both equal to Bank Acc. Reconciliation "Statement No."
        // [THEN] Bank Account "Balance Last Statement" = 1000.0
        VerifyBankAccountLastStatementFields(
          BankAccountNo, BankAccReconciliation."Statement No.", BankAccReconciliation."Statement No.",
          GetStatementAmountFromBankAccRecon(BankAccountNo));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostPmtReconciliationJournalWhenPostingDateOf2ndLineIsBefore1st()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccount: Record "Bank Account";
        BankAccReconPostYesNo: Codeunit "Bank Acc. Recon. Post (Yes/No)";
        Amount: Decimal;
        BankAccountNo: Code[20];
        PostingDate: Date;
        VendorLedgerEntryNo: Integer;
        VendorNo: Code[20];
    begin
        // [SCENARIO 268197] When Posting Date of the 2nd Payment Line is before the 1st line, Payment Reconciliation must be able to post
        Initialize();

        // [GIVEN] Payment Reconciliation line for 01.04.18
        BankAccountNo := CreateBankAccount(BankAccount);
        UpdateLastStatementNoOnBankAccount(BankAccount, '');
        CreateAndPostPurchaseInvoice(VendorNo, VendorLedgerEntryNo, Amount);

        LibraryERM.CreateBankAccReconciliation(
          BankAccReconciliation, BankAccountNo, BankAccReconciliation."Statement Type"::"Payment Application");
        CreateBankAccReconciliationLine(
            BankAccReconciliation, BankAccReconciliationLine, BankAccReconciliationLine."Account Type"::Vendor, VendorNo, Amount, WorkDate());

        BankAccReconciliation.Validate("Post Payments Only", true);
        BankAccReconciliationLine.Modify(true);

        // [GIVEN] Payment Reconciliation line for 01.03.18
        PostingDate := CalcDate('<-1M>', WorkDate());
        CreatePurchaseInvoice(PostingDate);
        CreateBankAccReconciliationLine(
            BankAccReconciliation, BankAccReconciliationLine, BankAccReconciliationLine."Account Type"::Vendor, VendorNo, 0, PostingDate);

        CODEUNIT.Run(CODEUNIT::"Match Bank Pmt. Appl.", BankAccReconciliation);

        // [WHEN] Post payments
        Assert.IsTrue(BankAccReconPostYesNo.BankAccReconPostYesNo(BankAccReconciliation), 'Not all payments posted.');

        // [THEN] Bank Acc. Reconciliation Lines are posted
        VerifyBankAccountLastStatementFields(
          BankAccountNo, BankAccReconciliation."Statement No.", '', 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BankAccountStatementLinesDrillDown()
    var
        BankAccountStatement: Record "Bank Account Statement";
        BankAccountStatementLine: Record "Bank Account Statement Line";
        BankAccountStatementPage: TestPage "Bank Account Statement";
        BankAccountLedgerEntries: TestPage "Bank Account Ledger Entries";
    begin
        // [FEATURE] [UT] [UI]
        // [SCENARIO 274506] Drill Down on "Appled Amount" in Bank Statement Lines opens relevant Bank Account Ledger Entries
        Initialize();
        LibraryApplicationArea.EnableBasicSetup();
        CreateBankReconciliationWithLedgerEntries(BankAccountStatement);
        BankAccountStatementLine.SetRange("Bank Account No.", BankAccountStatement."Bank Account No.");
        BankAccountStatementLine.SetRange("Statement No.", BankAccountStatement."Statement No.");
        BankAccountStatementLine.FindFirst();

        BankAccountStatementPage.OpenView();
        BankAccountStatementPage.GotoRecord(BankAccountStatement);
        BankAccountLedgerEntries.Trap();
        BankAccountStatementPage.Control11."Applied Amount".DrillDown();
        if BankAccountLedgerEntries.Amount.Visible() then
            BankAccountLedgerEntries.Amount.AssertEquals(BankAccountStatementLine."Applied Amount")
        else
            if BankAccountLedgerEntries."Credit Amount".Visible() and BankAccountLedgerEntries."Debit Amount".Visible() then
                if BankAccountStatementLine."Applied Amount" >= 0 then
                    BankAccountLedgerEntries."Debit Amount".AssertEquals(BankAccountStatementLine."Applied Amount")
                else
                    BankAccountLedgerEntries."Credit Amount".AssertEquals(BankAccountStatementLine."Applied Amount");
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [HandlerFunctions('PaymentApplicationModalPageHandler,PostAndReconcilePageHandler')]
    [Scope('OnPrem')]
    procedure PostBankAccRecononciliationVendCrMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        DocumentNo: Code[20];
        BankAccountNo: Code[20];
        Amount: Decimal;
    begin
        // [FEATURE] [Purchase] [Refund] [Credit Memo]
        // [SCENARIO 287960] Refund bank account ledger entry is closed after posting of bank reconciliation matched with credit memo
        Initialize();

        // [GIVEN] Create and post purchase credit memo
        LibraryPurchase.CreatePurchaseCreditMemo(PurchaseHeader);
        PurchaseHeader.CalcFields("Amount Including VAT");
        Amount := PurchaseHeader."Amount Including VAT";
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Create bank reconciliation
        LibraryLowerPermissions.AddAccountReceivables();
        BankAccountNo := CreateBankAccount();
        CreateBankReconciliation(BankAccReconciliation, BankAccountNo, BankAccReconciliation."Statement Type"::"Payment Application");

        // [GIVEN] Create bank reconciliation line and make manual match with posted credit memo
        CreateBankAccReconciliationLine(
            BankAccReconciliation, BankAccReconciliationLine, BankAccReconciliationLine."Account Type"::Vendor, PurchaseHeader."Buy-from Vendor No.", Amount, WorkDate());
        LibraryVariableStorage.Enqueue(PurchaseHeader."Buy-from Vendor No.");
        LibraryVariableStorage.Enqueue(DocumentNo);
        MatchBankReconLineManually(BankAccReconciliationLine);

        // [WHEN] Reconciliation is being posted
        UpdateBankAccRecStmEndingBalance(BankAccReconciliation, BankAccReconciliation."Balance Last Statement" + BankAccReconciliationLine."Statement Amount");
        LibraryERM.PostBankAccReconciliation(BankAccReconciliation);

        // [THEN] Bank Ledger Entry closed
        VerifyBankRecLedgerEntry(BankAccountNo, BankAccReconciliation."Statement No.");
    end;

    [Test]
    [HandlerFunctions('PaymentApplicationWithReducedAmtModalPageHandler,TransToDiffAccModalPageHandler,MessageWithVerificationHandler')]
    [Scope('OnPrem')]
    procedure TransferDifferenceAppliedToVendorToGLAccount()
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        GenJournalLine: Record "Gen. Journal Line";
        MatchBankPayments: Codeunit "Match Bank Payments";
        GLAccNo: Code[20];
        LoweredAppliedAmount: Decimal;
        DiffAmount: Decimal;
    begin
        // [FEATURE] [Application] [UI]
        // [SCENARIO 290815] Stan can transfer difference previously applied to vendor account to G/L Account

        Initialize();

        LibraryLowerPermissions.AddAccountReceivables();

        // [GIVEN] Create Payment Reconciliation Line and transfer amount of 100 to vendor account
        CreateBankAccReconLineWithAmountTransferredToAcc(BankAccReconciliationLine);
        LibraryVariableStorage.Enqueue(BankAccReconciliationLine."Account No.");
        LoweredAppliedAmount := Round(BankAccReconciliationLine."Statement Amount" / 3);
        LibraryVariableStorage.Enqueue(LoweredAppliedAmount);
        DiffAmount := BankAccReconciliationLine."Statement Amount" - LoweredAppliedAmount;

        // [GIVEN] Applied amount changed to 75 so now there is difference of 25
        MatchBankReconLineManually(BankAccReconciliationLine);
        BankAccReconciliationLine.Find();

        // [WHEN] Transfer difference of 25 to account
        GLAccNo := LibraryERM.CreateGLAccountNo();
        LibraryVariableStorage.Enqueue(GLAccNo);
        BankAccReconciliationLine.Find();
        LibraryVariableStorage.Enqueue(TransactionAmountReducedMsg);
        MatchBankPayments.TransferDiffToAccount(BankAccReconciliationLine, GenJournalLine);

        // [THEN] New Payment Reconciliation Line created with amount of 25
        BankAccReconciliationLine.SetRange("Statement Type", BankAccReconciliationLine."Statement Type");
        BankAccReconciliationLine.SetRange("Bank Account No.", BankAccReconciliationLine."Bank Account No.");
        BankAccReconciliationLine.SetRange("Statement No.", BankAccReconciliationLine."Statement No.");
        BankAccReconciliationLine.SetFilter("Statement Line No.", '<>%1', BankAccReconciliationLine."Statement Line No.");
        Assert.RecordCount(BankAccReconciliationLine, 1);
        BankAccReconciliationLine.FindFirst();
        BankAccReconciliationLine.TestField("Statement Amount", DiffAmount);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PaymentApplicationWithReducedAmtModalPageHandler')]
    [Scope('OnPrem')]
    procedure ChangeAppliedAmountTransferredToVendor()
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        AppliedPaymentEntry: Record "Applied Payment Entry";
        LoweredAppliedAmount: Decimal;
    begin
        // [FEATURE] [Application] [UI]
        // [SCENARIO 290815] Stan can change "Applied Amount" on "Payment Application" page if remaining amount already transferred to vendor account

        Initialize();

        // [GIVEN] Create Payment Reconciliation
        LibraryLowerPermissions.AddAccountReceivables();

        // [GIVEN] Create Payment Reconciliation Line and transfer amount of 100 to vendor account
        CreateBankAccReconLineWithAmountTransferredToAcc(BankAccReconciliationLine);
        LibraryVariableStorage.Enqueue(BankAccReconciliationLine."Account No.");
        LoweredAppliedAmount := Round(BankAccReconciliationLine."Statement Amount" / 3);
        LibraryVariableStorage.Enqueue(LoweredAppliedAmount);

        // [GIVEN] Opened "Payment Application" page

        // [WHEN] Change "Applied Amount" to 75 on "Payment Application" page
        MatchBankReconLineManually(BankAccReconciliationLine);

        // [THEN] One Applied Payment Entry exists for Bank Reconciliation Line
        BankAccReconciliationLine.Find();
        AppliedPaymentEntry.FilterAppliedPmtEntry(BankAccReconciliationLine);
        Assert.RecordCount(AppliedPaymentEntry, 1);

        // [THEN] "Applied Amount" is 75 in Applied Payment Entry
        AppliedPaymentEntry.FindFirst();
        AppliedPaymentEntry.TestField("Applied Amount", LoweredAppliedAmount);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostAndReconcilePageHandler,PostAndReconcilePageStatementDateHandler')]
    [Scope('OnPrem')]
    procedure BankAccReconciliationCanBePostedWhenStatementWithStatementNoAlreadyExists()
    var
        BankAccount: Record "Bank Account";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccountStatement: Record "Bank Account Statement";
    begin
        // [SCENARIO 302967] Bank Acc. Reconciliation can be posted when Bank Account Statement with the same Statement No. already exists
        Initialize();

        // [GIVEN] A Bank Account with Last Statement No. = '1'
        LibraryERM.CreateBankAccount(BankAccount);
        InitLastStatementNo(BankAccount, '1');

        // [GIVEN] A Bank Account Statement was created for this Bank Account with Statement No. = '1'
        CreateBankAccountStatement(BankAccount);

        // [GIVEN] A Bank Acc. Reconciliation with type = Payment was created with Statement No. = '1' and valid Line setup to be posted
        CreateApplyBankAccReconcilationLine(BankAccReconciliation, BankAccReconciliationLine,
          BankAccReconciliationLine."Account Type"::"G/L Account",
          LibraryERM.CreateGLAccountNo(), LibraryRandom.RandIntInRange(50, 100), BankAccount."No.");
        BankAccReconciliationLine.TransferRemainingAmountToAccount();

        // [WHEN] Posting Bank Acc. Reconciliation
        UpdateBankAccRecStmEndingBalance(BankAccReconciliation, BankAccReconciliation."Balance Last Statement" + BankAccReconciliationLine."Statement Amount");
        LibraryERM.PostBankAccReconciliation(BankAccReconciliation);

        // [THEN] Bank Account Statement for this Reconciliation was created with Statement No. = '2'
        BankAccountStatement.Get(BankAccount."No.", '2');
    end;

    [Test]
    [HandlerFunctions('PostAndReconcilePageHandler,PostAndReconcilePageStatementDateHandler')]
    [Scope('OnPrem')]
    procedure BankAccReconciliationStatementNoTransfersToStatementWhenPostedAndNoStatementWithThisNoExists()
    var
        BankAccount: Record "Bank Account";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccountStatement: Record "Bank Account Statement";
    begin
        // [SCENARIO 302967] When Bank Acc. Reconciliation is posted and there is no Bank Account Statement with same Statement No. exists the resulting Statement has that Statement No.
        Initialize();

        // [GIVEN] A Bank Account
        LibraryERM.CreateBankAccount(BankAccount);

        // [GIVEN] A Bank Acc. Reconciliation with type = Payment was created with Statement No. = '1' and valid Line setup to be posted
        CreateApplyBankAccReconcilationLine(BankAccReconciliation, BankAccReconciliationLine,
          BankAccReconciliationLine."Account Type"::"G/L Account",
          LibraryERM.CreateGLAccountNo(), LibraryRandom.RandIntInRange(50, 100), BankAccount."No.");
        BankAccReconciliationLine.TransferRemainingAmountToAccount();

        // [WHEN] Posting Bank Acc. Reconciliation
        UpdateBankAccRecStmEndingBalance(BankAccReconciliation, BankAccReconciliation."Balance Last Statement" + BankAccReconciliationLine."Statement Amount");
        LibraryERM.PostBankAccReconciliation(BankAccReconciliation);

        // [THEN] Bank Account Statement for this Reconciliation was created with Statement No. = '1'
        BankAccountStatement.Get(BankAccount."No.", '1');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BankAccountReconciliationLinesDrillDown()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccReconciliationPage: TestPage "Bank Acc. Reconciliation";
        BankAccountLedgerEntryPage: TestPage "Bank Account Ledger Entries";
    begin
        // [FEATURE] [UT] [UI]
        // [SCENARIO 307867] Drill Down on "Applied Amount" in Bank Acc. Reconciliation Lines opens relevant Bank Account Ledger Entries.
        Initialize();

        // [GIVEN] Bank Acc. Reconciliation with manually matched Bank Acc. Reconciliation Line and Bank Account Ledger Entry.
        CreateBankAccountReconciliationWithMatchedLineAndLedgerEntry(BankAccReconciliation, BankAccReconciliationLine);
        BankAccReconciliationPage.OpenView();
        BankAccReconciliationPage.FILTER.SetFilter("Statement Type", Format(BankAccReconciliation."Statement Type"));
        BankAccReconciliationPage.FILTER.SetFilter("Bank Account No.", Format(BankAccReconciliation."Bank Account No."));
        BankAccReconciliationPage.FILTER.SetFilter("Statement No.", Format(BankAccReconciliation."Statement No."));
        BankAccountLedgerEntryPage.Trap();

        // [WHEN] Drill down to "Applied Amount".
        BankAccReconciliationPage.StmtLine."Applied Amount".DrillDown();

        // [THEN] "Amount" at opened page equals to "Applied Amount" of Bank Acc. Reconciliation Line.
        BankAccountLedgerEntryPage."Bank Account No.".AssertEquals(BankAccReconciliationLine."Bank Account No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmEnqueueQuestionHandler')]
    [Scope('OnPrem')]
    procedure BankAccReconciliationLineAccountTypeICPartnerConfirmMessage()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 328682] When Stan chooses "Account Type" equal to "IC Partner" confirm message is shown.
        Initialize();

        // [GIVEN] Bank Account field.
        LibraryERM.CreateBankAccReconciliation(
          BankAccReconciliation, CreateBankAccount(), BankAccReconciliation."Statement Type"::"Bank Reconciliation");
        LibraryERM.CreateBankAccReconciliationLn(BankAccReconciliationLine, BankAccReconciliation);

        // [WHEN] "Account Type" field is validated with "IC Partner".
        BankAccReconciliationLine.Validate("Account Type", BankAccReconciliationLine."Account Type"::"IC Partner");

        // [THEN] Confirm with text ICPartnerAccountTypeQst is shown.
        Assert.AreEqual(ICPartnerAccountTypeQst, LibraryVariableStorage.DequeueText(), '');
    end;

    [Test]
    [HandlerFunctions('BankAccReconTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure GLBalanceFieldsOfBanAccReconTestReportConsiderStatementDateWhenDefined()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
        BankAccountNo: Code[20];
        AccountNo: Code[20];
        RequestPageXML: Text;
    begin
        // [FEATURE] [Report] [Bank Acc. Recon. - Test]
        // [SCENARIO 335898] G/L Balance and G/L Balance (LCY) fields of "Bank Acc. Recon. - Test" report considers the "Statement Date" when it is defined in Bank Acc. Reconciliation.
        Initialize();

        // [GIVEN] GL Account without any previous entry
        LibraryERM.CreateGLAccount(GLAccount);

        // [GIVEN] Two posted vendor payments
        // [GIVEN] "Posting Date" = 02.01 and Amount 100
        // [GIVEN] "Posting Date" = 01.01 and Amount 200
        BankAccountNo := LibraryERM.CreateBankAccountNoWithNewPostingGroup(GLAccount);
        AccountNo := LibraryPurchase.CreateVendorNo();
        PostPaymentJournalLineWithDateAndSource(GenJournalLine, WorkDate() + 1, AccountNo, BankAccountNo);
        PostPaymentJournalLineWithDateAndSource(GenJournalLine, WorkDate(), AccountNo, BankAccountNo);

        // [GIVEN] Bank Account Reconciliation with "Statement Date" = 01.01
        LibraryERM.CreateBankAccReconciliation(
          BankAccReconciliation, BankAccountNo, BankAccReconciliation."Statement Type"::"Bank Reconciliation");
        BankAccReconciliation.Validate("Statement Date", WorkDate());
        BankAccReconciliation.Modify(true);
        Commit();

        BankAccReconciliation.SetRecFilter();

        // [WHEN] Run report "Bank Acc. Recon. - Test"
        LibraryVariableStorage.Enqueue(true);
        RequestPageXML := REPORT.RunRequestPage(REPORT::"Bank Acc. Recon. - Test", RequestPageXML);
        LibraryReportDataset.RunReportAndLoad(REPORT::"Bank Acc. Recon. - Test", BankAccReconciliation, RequestPageXML);

        // [THEN] TotalBalOnBankAccount has value 200
        LibraryReportDataset.AssertElementWithValueExists('Bank_Acc__Reconciliation___TotalBalOnGLAccount', -GenJournalLine.Amount);

        // [THEN] TotalBalOnBankAccountLCY has value 200
        LibraryReportDataset.AssertElementWithValueExists('Bank_Acc__Reconciliation___TotalBalOnGLAccountLCY', -GenJournalLine.Amount);

        // [THEN] GLSubtotal has value 200
        LibraryReportDataset.AssertElementWithValueExists('GL_Subtotal', -GenJournalLine.Amount);

        // [THEN] EndingGLBalance has value 200
        LibraryReportDataset.AssertElementWithValueExists('Ending_GL_Balance', -GenJournalLine.Amount);
    end;

    [Test]
    [HandlerFunctions('BankAccReconTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure GLBalanceFieldsOfBanAccReconTestReportDoesNotConsiderStatementDateWhenNotDefined()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
        BankAccountNo: Code[20];
        AccountNo: Code[20];
        TotalAmount: Decimal;
        RequestPageXML: Text;
    begin
        // [FEATURE] [Report] [Bank Acc. Recon. - Test]
        // [SCENARIO 335898] G/L Balance and G/L Balance (LCY) fields of "Bank Acc. Recon. - Test" report does not consider the "Statement Date" when it is not defined in Bank Acc. Reconciliation.
        Initialize();

        // [GIVEN] GL Account without any previous entry
        LibraryERM.CreateGLAccount(GLAccount);

        // [GIVEN] Two posted vendor payments
        // [GIVEN] "Posting Date" = 02.01 and Amount 100
        // [GIVEN] "Posting Date" = 01.01 and Amount 200
        BankAccountNo := LibraryERM.CreateBankAccountNoWithNewPostingGroup(GLAccount);
        AccountNo := LibraryPurchase.CreateVendorNo();
        PostPaymentJournalLineWithDateAndSource(GenJournalLine, WorkDate(), AccountNo, BankAccountNo);
        TotalAmount += GenJournalLine.Amount;
        PostPaymentJournalLineWithDateAndSource(GenJournalLine, WorkDate() + 1, AccountNo, BankAccountNo);
        TotalAmount += GenJournalLine.Amount;

        // [GIVEN] Bank Account Reconciliation with no "Statement Date" specified
        LibraryERM.CreateBankAccReconciliation(
          BankAccReconciliation, BankAccountNo, BankAccReconciliation."Statement Type"::"Bank Reconciliation");
        BankAccReconciliation.Validate("Statement Date", 0D);
        BankAccReconciliation.Modify(true);
        Commit();

        BankAccReconciliation.SetRecFilter();

        // [WHEN] Run report "Bank Acc. Recon. - Test"
        LibraryVariableStorage.Enqueue(true);
        RequestPageXML := REPORT.RunRequestPage(REPORT::"Bank Acc. Recon. - Test", RequestPageXML);
        LibraryReportDataset.RunReportAndLoad(REPORT::"Bank Acc. Recon. - Test", BankAccReconciliation, RequestPageXML);

        // [THEN] TotalBalOnBankAccount has value 300
        LibraryReportDataset.AssertElementWithValueExists('Bank_Acc__Reconciliation___TotalBalOnGLAccount', -TotalAmount);

        // [THEN] TotalBalOnBankAccountLCY has value 300
        LibraryReportDataset.AssertElementWithValueExists('Bank_Acc__Reconciliation___TotalBalOnGLAccountLCY', -TotalAmount);

        // [THEN] GLSubtotal has value 300
        LibraryReportDataset.AssertElementWithValueExists('GL_Subtotal', -TotalAmount);

        // [THEN] EndingGLBalance has value 300
        LibraryReportDataset.AssertElementWithValueExists('Ending_GL_Balance', -TotalAmount);

        // [THEN] Difference has value 0
        LibraryReportDataset.AssertElementWithValueExists('Sum_Of_Differences', 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TheFieldExternalDocumentNoAddedToApplyBankAccLedgerEntries()
    var
        ApplyBankAccLedgerEntries: TestPage "Apply Bank Acc. Ledger Entries";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 361628] Open page "Apply Bank Acc. Ledger Entries" and ckeck visibility of "External Document No." variable
        Initialize();

        // [GIVEN] Enabled foundation setup
        LibraryApplicationArea.EnableFoundationSetup();

        // [WHEN] Page "Apply Bank Acc. Ledger Entries" is opened
        ApplyBankAccLedgerEntries.OpenEdit();

        // [THEN] The variable "External Document No." is visible
        Assert.IsTrue(ApplyBankAccLedgerEntries."External Document No.".Visible(), '');
        ApplyBankAccLedgerEntries.Close();
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [HandlerFunctions('GenJnlPageHandler')]
    [Scope('OnPrem')]
    procedure TransferToGenJnlLineWithEmptyDocNo()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        // [SCENARIO 369129] Report "Trans. Bank Rec. To Gen. Jnl." creates Gen. Journal lines with sequential numbers according to No. series.
        Initialize();

        // [GIVEN] 2 Bank Account reconciliation lines with empty Document No.
        CreateBankReconciliation(BankAccReconciliation, CreateBankAccount(), BankAccReconciliation."Statement Type"::"Bank Reconciliation");
        CreateBankAccReconciliationLineWithDocNo(BankAccReconciliation, BankAccReconciliationLine, '');
        CreateBankAccReconciliationLineWithDocNo(BankAccReconciliation, BankAccReconciliationLine, '');

        // [GIVEN] Gen. Journal Template and Gen. Journal Batch with No. series.
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch.Validate("No. Series", LibraryERM.CreateNoSeriesCode());
        GenJournalBatch.Modify(true);

        // [WHEN] Report "Trans. Bank Rec. To Gen. Jnl." is run for Gen. Journal batch.
        TransferToGenJnlReport(BankAccReconciliation, GenJournalBatch);

        // [THEN] Reconciliation lines are transfered to Gen. Journal with sequential numbers according to No. series.
        VerifyGenJournalLineDocNosSequential(GenJournalTemplate.Name, GenJournalBatch.Name);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UndoBankAccStatementSunShine()
    var
        BankAccount: Record "Bank Account";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccountStatement: Record "Bank Account Statement";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        UndoBankStatementYesNo: Codeunit "Undo Bank Statement (Yes/No)";
        StatementNo: Code[20];
    begin
        // [FEATURE] [Undo Bank Account Statement]
        // [SCENARIO 277781] Bank Account statement undo makes bank account reconciliation and restore bank ledger entry fields
        Initialize();

        // [GIVEN] Posted vendor payment Amount = 100
        LibraryERM.CreateBankAccount(BankAccount);
        PostPaymentJournalLineWithDateAndSource(GenJournalLine, WorkDate(), LibraryPurchase.CreateVendorNo(), BankAccount."No.");

        // [GIVEN] Create and post bank reconciliation "Statement No." = 1
        CreateSuggestedBankReconc(BankAccReconciliation, BankAccount."No.", false);

        LibraryERM.PostBankAccReconciliation(BankAccReconciliation);
        BankAccountStatement.Get(BankAccount."No.", BankAccReconciliation."Statement No.");

        // [WHEN] Undo bank statement
        StatementNo := UndoBankStatementYesNo.UndoBankAccountStatement(BankAccountStatement);

        // [THEN] Bank statetment "Statement No." = 1 deleted
        Assert.IsFalse(BankAccountStatement.Find(), 'Bank account statement must be deleted.');

        // [THEN] Bank reconciliation "Statement No." = 2 created
        BankAccReconciliation.Get(BankAccReconciliation."Statement Type"::"Bank Reconciliation", BankAccount."No.", StatementNo);
        BankAccReconciliation.TestField("Balance Last Statement", 0);
        BankAccReconciliation.TestField("Statement Ending Balance", -GenJournalLine.Amount);
        // [THEN] Bank reconciliation line created with Statement Amount = -100 and Applied Amount = -100
        BankAccReconciliationLine.SetRange("Bank Account No.", BankAccount."No.");
        BankAccReconciliationLine.SetRange("Statement Type", BankAccReconciliation."Statement Type");
        BankAccReconciliationLine.SetRange("Statement No.", BankAccReconciliation."Statement No.");
        BankAccReconciliationLine.FindFirst();
        BankAccReconciliationLine.TestField("Statement Amount", -GenJournalLine.Amount);
        BankAccReconciliationLine.TestField("Applied Amount", -GenJournalLine.Amount);
        // [THEN] Bank ledger entry has Statement Status = Bank Acc. Entry Applied, Statement No.
        BankAccountLedgerEntry.SetRange("Bank Account No.", BankAccount."No.");
        BankAccountLedgerEntry.FindFirst();
        BankAccountLedgerEntry.TestField("Statement Status", BankAccountLedgerEntry."Statement Status"::"Bank Acc. Entry Applied");
        BankAccountLedgerEntry.TestField("Statement No.", BankAccReconciliation."Statement No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UndoBankAccountStatementBalanceLastStatement()
    var
        BankAccount: Record "Bank Account";
        BankAccountStatement: array[2] of Record "Bank Account Statement";
        UndoBankStatementYesNo: Codeunit "Undo Bank Statement (Yes/No)";
    begin
        // [FEATURE] [Undo Bank Account Statement]
        // [SCENARIO 277781] Undo bank account statement updates bank "Balance Last Statement"
        Initialize();

        // [GIVEN] Bank account "B"
        LibraryERM.CreateBankAccount(BankAccount);
        // [GIVEN] Create an post bank reconciliation "Statement No." = 1 with Statement Amount = 100
        BankAccountStatement[1].Get(BankAccount."No.", CreatePostBankReconciliation(BankAccount));
        // [GIVEN] Create an post bank reconciliation "Statement No." = 2 with Statement Amount = 200
        BankAccountStatement[2].Get(BankAccount."No.", CreatePostBankReconciliation(BankAccount));
        BankAccount.Find();
        // [WHEN] Undo bank statement 2
        UndoBankStatementYesNo.UndoBankAccountStatement(BankAccountStatement[2]);

        // [THEN] Bank "Balance Last Statement" = 100
        BankAccount.Find();
        BankAccount.TestField("Balance Last Statement", BankAccountStatement[2]."Balance Last Statement");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UndoBankStatementWithPartlyAppliedEntries()
    var
        GenJournalLine: array[2] of Record "Gen. Journal Line";
        BankAccount: Record "Bank Account";
        Vendor: Record Vendor;
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccountStatement: Record "Bank Account Statement";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        UndoBankStatementYesNo: Codeunit "Undo Bank Statement (Yes/No)";
        MatchBankRecLines: Codeunit "Match Bank Rec. Lines";
    begin
        // [FEATURE] [Undo Bank Account Statement]
        // [SCENARIO 277781] Bank Account statement undo for partly applied bank ledger entries
        Initialize();

        // [GIVEN] Bank account "B"
        LibraryERM.CreateBankAccount(BankAccount);
        // [GIVEN] Vendor "V"
        LibraryPurchase.CreateVendor(Vendor);
        // [GIVEN] Create and post payment 1 with Amount = 100
        PostPaymentJournalLineWithDateAndSource(GenJournalLine[1], WorkDate(), Vendor."No.", BankAccount."No.");
        // [GIVEN] Create and post payment 2 with Amount = 200
        PostPaymentJournalLineWithDateAndSource(GenJournalLine[2], WorkDate(), Vendor."No.", BankAccount."No.");

        // [GIVEN] Create and post bank reconciliation with 1 line applied to 2 payments
        CreateBankReconciliation(BankAccReconciliation, BankAccount."No.", BankAccReconciliation."Statement Type"::"Bank Reconciliation");
        CreateBankAccReconciliationLine(
            BankAccReconciliation, BankAccReconciliationLine, BankAccReconciliationLine."Account Type"::Vendor, Vendor."No.", -(GenJournalLine[1].Amount + GenJournalLine[2].Amount), WorkDate());
        BankAccountLedgerEntry.SetRange("Bank Account No.", BankAccount."No.");
        BankAccReconciliationLine.SetRecFilter();
        MatchBankRecLines.MatchManually(BankAccReconciliationLine, BankAccountLedgerEntry);
        BankAccReconciliation."Statement Ending Balance" := BankAccReconciliationLine."Statement Amount";
        BankAccReconciliation.Modify();
        LibraryERM.PostBankAccReconciliation(BankAccReconciliation);
        BankAccountStatement.Get(BankAccount."No.", BankAccReconciliation."Statement No.");

        // [WHEN] Undo bank statement
        UndoBankStatementYesNo.UndoBankAccountStatement(BankAccountStatement);

        // [THEN] Bank account entry 1 has Remaning Amount = 100
        VerifyBankLedgerEntryRemainingAmount(BankAccount."No.", GenJournalLine[1]."Document No.", -GenJournalLine[1].Amount);
        // [THEN] Bank account entry 2 has Remaning Amount = 200
        VerifyBankLedgerEntryRemainingAmount(BankAccount."No.", GenJournalLine[2]."Document No.", -GenJournalLine[2].Amount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoBankAccountStatementOpenCreatedReconciliation()
    var
        BankAccount: Record "Bank Account";
        BankAccountStatement: Record "Bank Account Statement";
        BankAccountStatementPage: TestPage "Bank Account Statement";
        BankAccReconciliationPage: TestPage "Bank Acc. Reconciliation";
    begin
        // [FEATURE] [Undo Bank Account Statement] [UI]
        // [SCENARIO 277781] Created bank reconciliation opened after statement undone
        Initialize();

        // [GIVEN] Bank account "B"
        LibraryERM.CreateBankAccount(BankAccount);
        // [GIVEN] Create an post bank reconciliation
        BankAccountStatement.Get(BankAccount."No.", CreatePostBankReconciliation(BankAccount));
        // [GIVEN] Open bank statement page
        BankAccountStatementPage.OpenEdit();
        BankAccountStatementPage.Filter.SetFilter("Bank Account No.", BankAccount."No.");

        // [WHEN] Undo bank statement
        BankAccReconciliationPage.Trap();
        BankAccountStatementPage.Undo.Invoke();

        // [THEN] Bank Acc. Reconciliation page opened
        BankAccReconciliationPage.BankAccountNo.AssertEquals(BankAccount."No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure UndoBankAccountStatementNotConfirm()
    var
        BankAccount: Record "Bank Account";
        BankAccountStatement: Record "Bank Account Statement";
        BankAccountStatementPage: TestPage "Bank Account Statement";
        BankAccReconciliationPage: TestPage "Bank Acc. Reconciliation";
    begin
        // [FEATURE] [Undo Bank Account Statement] [UI]
        // [SCENARIO 277781] User is able to not confirm undo bank statement
        Initialize();

        // [GIVEN] Bank account "B"
        LibraryERM.CreateBankAccount(BankAccount);
        // [GIVEN] Create an post bank reconciliation
        BankAccountStatement.Get(BankAccount."No.", CreatePostBankReconciliation(BankAccount));
        // [GIVEN] Open bank statement page
        BankAccountStatementPage.OpenEdit();
        BankAccountStatementPage.Filter.SetFilter("Bank Account No.", BankAccount."No.");

        // [WHEN] Run Undo bank statement action and answer "No"
        BankAccReconciliationPage.Trap();
        BankAccountStatementPage.Undo.Invoke();

        // [THEN] Bank Account Statement is not deleted
        Assert.IsTrue(BankAccountStatement.Find(), 'Bank statement must not be deleted.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UndoBankStatementWithDifferences()
    var
        GenJournalLine: array[2] of Record "Gen. Journal Line";
        BankAccount: Record "Bank Account";
        Vendor: Record Vendor;
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccountStatement: Record "Bank Account Statement";
        UndoBankStatementYesNo: Codeunit "Undo Bank Statement (Yes/No)";
        DifferenceAmount: Decimal;
        StatementNo: Code[20];
    begin
        // [FEATURE] [Undo Bank Account Statement]
        // [SCENARIO 277781] Bank Account statement with differences undo
        Initialize();

        // [GIVEN] Bank account "B"
        LibraryERM.CreateBankAccount(BankAccount);
        // [GIVEN] Vendor "V"
        LibraryPurchase.CreateVendor(Vendor);
        // [GIVEN] Create and post payment 1 with Amount = 100
        PostPaymentJournalLineWithDateAndSource(GenJournalLine[1], WorkDate(), Vendor."No.", BankAccount."No.");
        // [GIVEN] Create and post payment 2 with Amount = 200
        PostPaymentJournalLineWithDateAndSource(GenJournalLine[2], WorkDate(), Vendor."No.", BankAccount."No.");

        // [GIVEN] Create bank reconciliation
        CreateSuggestedBankReconc(BankAccReconciliation, BankAccount."No.", false);
        // [GIVEN] Set for first reconciliation Difference = 50
        DifferenceAmount := LibraryRandom.RandDec(50, 2);
        BankAccReconciliationLine.Get(BankAccReconciliationLine."Statement Type"::"Bank Reconciliation", BankAccount."No.", BankAccReconciliation."Statement No.", 10000);
        BankAccReconciliationLine.Validate(Difference, DifferenceAmount);
        BankAccReconciliationLine.Modify();
        // [GIVEN] Set for first reconciliation Difference = -50
        BankAccReconciliationLine.Get(BankAccReconciliationLine."Statement Type"::"Bank Reconciliation", BankAccount."No.", BankAccReconciliation."Statement No.", 20000);
        BankAccReconciliationLine.Validate(Difference, -DifferenceAmount);
        BankAccReconciliationLine.Modify();
        // [GIVEN] Post bank reconciliation
        LibraryERM.PostBankAccReconciliation(BankAccReconciliation);

        // [WHEN] Undo bank statement
        BankAccountStatement.Get(BankAccount."No.", BankAccReconciliation."Statement No.");
        StatementNo := UndoBankStatementYesNo.UndoBankAccountStatement(BankAccountStatement);

        // [THEN] New first bank reconciliation line has Difference = 50
        BankAccReconciliationLine.Get(BankAccReconciliationLine."Statement Type"::"Bank Reconciliation", BankAccount."No.", StatementNo, 10000);
        BankAccReconciliationLine.TestField(Difference, DifferenceAmount);
        // [THEN] New second bank reconciliation line has Difference = -50
        BankAccReconciliationLine.Get(BankAccReconciliationLine."Statement Type"::"Bank Reconciliation", BankAccount."No.", StatementNo, 20000);
        BankAccReconciliationLine.TestField(Difference, -DifferenceAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UndoBankStatementWithCheckLedgerEntry()
    var
        BankAccount: Record "Bank Account";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccountStatement: Record "Bank Account Statement";
        UndoBankStatementYesNo: Codeunit "Undo Bank Statement (Yes/No)";
        DocumentNo: Code[20];
        NewStatementNo: Code[20];
    begin
        // [FEATURE] [Undo Bank Account Statement]
        // [SCENARIO 277781] Undo Bank Account statement with check ledger entry
        Initialize();

        // [GIVEN] Create and post check payment
        DocumentNo := PostCheck(BankAccount, CreateBankAccount(), LibraryRandom.RandDec(1000, 2));

        // [GIVEN] Create and post bank reconciliation
        CreateSuggestedBankReconc(BankAccReconciliation, BankAccount."No.", true);
        LibraryERM.PostBankAccReconciliation(BankAccReconciliation);

        // [WHEN] Undo bank statement
        BankAccountStatement.Get(BankAccount."No.", BankAccReconciliation."Statement No.");
        NewStatementNo := UndoBankStatementYesNo.UndoBankAccountStatement(BankAccountStatement);

        // [THEN] Check account entry has "Statement Status" = "Check Entry Applied" and "Open" = "true"
        VerifyUndoneCheckLedgerEntry(BankAccount."No.", DocumentNo, NewStatementNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoBankAccountStatementFromList()
    var
        BankAccount: Record "Bank Account";
        BankAccountStatement: Record "Bank Account Statement";
        BankAccountStatementListPage: TestPage "Bank Account Statement List";
        BankAccReconciliationPage: TestPage "Bank Acc. Reconciliation";
    begin
        // [FEATURE] [Undo Bank Account Statement] [UI]
        // [SCENARIO 372511] User is able to undo statement from statements list page
        Initialize();

        // [GIVEN] Bank account "B"
        LibraryERM.CreateBankAccount(BankAccount);
        // [GIVEN] Create an post bank reconciliation
        BankAccountStatement.Get(BankAccount."No.", CreatePostBankReconciliation(BankAccount));
        // [GIVEN] Open bank statement page
        BankAccountStatementListPage.OpenEdit();
        BankAccountStatementListPage.Filter.SetFilter("Bank Account No.", BankAccount."No.");

        // [WHEN] Undo bank statement
        BankAccReconciliationPage.Trap();
        BankAccountStatementListPage.Undo.Invoke();

        // [THEN] Bank Acc. Reconciliation page opened
        BankAccReconciliationPage.BankAccountNo.AssertEquals(BankAccount."No.");
    end;

    [Test]
    [HandlerFunctions('ChangeStatementNoModalPageHandler')]
    [Scope('OnPrem')]
    procedure ChangeBankReconciliationStatementNo()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        NewStatementNo: Code[20];
    begin
        // [SCENARIO 376737] User is able to change bank account reconciliation Statement No.
        Initialize();

        // [GIVEN] Create bank reconciliation with "Statement No." = 1
        PrepareBankAccReconciliation(BankAccReconciliation, LibraryERM.CreateBankAccountNo());

        // [WHEN] Run change Statement No. and set "New Statement No." = 2
        NewStatementNo := IncStr(BankAccReconciliation."Statement No.");
        RunChangeStatementNo(BankAccReconciliation, NewStatementNo);

        // [THEN] Bank Acc. Reconciliation has "Statement No." = 2
        BankAccReconciliation.TestField("Statement No.", NewStatementNo);
        // [THEN] Bank Acc. Reconciliation Line has "Statement No." = 2
        BankAccReconciliationLine.SetRange("Statement Type", BankAccReconciliation."Statement Type");
        BankAccReconciliationLine.SetRange("Bank Account No.", BankAccReconciliation."Bank Account No.");
        BankAccReconciliationLine.SetRange("Statement No.", NewStatementNo);
        BankAccReconciliationLine.FindFirst();

        // [THEN] Applied Bank Account Ledger Entry has "Statement No." = 2
        BankAccountLedgerEntry.SetRange("Bank Account No.", BankAccReconciliation."Bank Account No.");
        BankAccountLedgerEntry.SetRange("Statement Status", BankAccountLedgerEntry."Statement Status"::"Bank Acc. Entry Applied");
        BankAccountLedgerEntry.FindFirst();
        BankAccountLedgerEntry.TestField("Statement No.", NewStatementNo);
    end;

    [Test]
    [HandlerFunctions('ChangeStatementNoModalPageHandler')]
    [Scope('OnPrem')]
    procedure ChangeBankReconciliationStatementNoWithCheckLE()
    var
        BankAccount: Record "Bank Account";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        NewStatementNo: Code[20];
    begin
        // [SCENARIO 376737] User is able to change bank account reconciliation Statement No. with applied check ledger entry
        Initialize();

        // [GIVEN] Create and post check payment
        PostCheck(BankAccount, CreateBankAccount(), LibraryRandom.RandDec(1000, 2));

        // [GIVEN] Create bank reconciliation with "Statement No." = 1
        CreateSuggestedBankReconc(BankAccReconciliation, BankAccount."No.", true);

        // [WHEN] Run change Statement No. and set "New Statement No." = 2
        NewStatementNo := IncStr(BankAccReconciliation."Statement No.");
        RunChangeStatementNo(BankAccReconciliation, NewStatementNo);

        // [THEN] Bank Acc. Reconciliation has "Statement No." = 2
        BankAccReconciliation.TestField("Statement No.", NewStatementNo);
        // [THEN] Bank Acc. Reconciliation Line has "Statement No." = 2
        BankAccReconciliationLine.SetRange("Statement Type", BankAccReconciliation."Statement Type");
        BankAccReconciliationLine.SetRange("Bank Account No.", BankAccReconciliation."Bank Account No.");
        BankAccReconciliationLine.SetRange("Statement No.", NewStatementNo);
        BankAccReconciliationLine.FindFirst();

        // [THEN] Applied Check Ledger Entry has "Statement No." = 2
        BankAccountLedgerEntry.SetRange("Bank Account No.", BankAccount."No.");
        BankAccountLedgerEntry.SetRange("Statement No.", NewStatementNo);
        Assert.IsTrue(BankAccountLedgerEntry.FindFirst(), '');
    end;

    [Test]
    [HandlerFunctions('ChangeStatementNoModalPageHandler')]
    [Scope('OnPrem')]
    procedure ChangeBankReconciliationStatementNoExistingStatementNo()
    var
        BankAccount: Record "Bank Account";
        BankAccReconciliation: array[2] of Record "Bank Acc. Reconciliation";
    begin
        // [SCENARIO 376737] Change bank account reconciliation Statement No. with existing Statement No. leads to error "Statement No. XXX already exists."
        Initialize();

        // [GIVEN] Create bank account "B"
        LibraryERM.CreateBankAccount(BankAccount);
        // [GIVEN] Create bank reconciliation with "Statement No." = 1
        PrepareBankAccReconciliation(BankAccReconciliation[1], BankAccount."No.");
        // [GIVEN] Create bank reconciliation with "Statement No." = 2
        PrepareBankAccReconciliation(BankAccReconciliation[2], BankAccount."No.");

        // [WHEN] Run change Statement No. for 2 and try to set "New Statement No." = 1
        asserterror RunChangeStatementNo(BankAccReconciliation[2], BankAccReconciliation[1]."Statement No.");

        // [THEN] Error "Statement No. 1 already exists."
        Assert.ExpectedError(StrSubstNo(StatementAlreadyExistsErr, BankAccReconciliation[1]."Statement No."));
    end;

    [Test]
    [HandlerFunctions('PostAndReconcilePageHandler,PostAndReconcilePageStatementDateHandler')]
    [Scope('OnPrem')]
    procedure PostPaymentReconciliationJournalEmployee()
    var
        Employee: Record Employee;

        GenJnlLine: Record "Gen. Journal Line";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        EntryNo: Integer;
    begin
        // [FEATURE] [Employee]
        // [SCENARIO 325315] User is able to use Employee for payment reconciliation journal
        Initialize();

        // [GIVEN] Employee "E"
        CreateEmployee(Employee);
        // [GIVEN] Post general journal line with Employee "E" and Amount -100
        EntryNo := CreateAndPostGenJournalLineEmployee(GenJnlLine, Employee."No.");

        // [GIVEN] Create payment reconciliation "R" for employee "E"
        CreateBankReconciliationWithEmployee(BankAccReconciliation, BankAccReconciliationLine, Employee."No.", GenJnlLine.Amount);
        ApplyBankAccReconLineToEmployee(BankAccReconciliationLine, Employee."No.", EntryNo);

        // [WHEN] Post payment reconciliation "R"
        UpdateBankAccRecStmEndingBalance(BankAccReconciliation, BankAccReconciliation."Balance Last Statement" + BankAccReconciliationLine."Statement Amount");
        LibraryERM.PostBankAccReconciliation(BankAccReconciliation);

        // [THEN] Payment for employee "E" with Amount 100 created
        VerifyEmployeeLedgerEntry(Employee."No.", BankAccReconciliation."Statement No.", -GenJnlLine.Amount, "Gen. Journal Document Type"::Payment);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('PaymentApplicationPageWithEmployeeApply,ConfirmHandler')]
    procedure PaymentReconciliationJournalEmployeeApplyPostUI()
    var
        Employee: Record Employee;
        GenJnlLine: Record "Gen. Journal Line";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        PaymentReconciliationJournal: TestPage "Payment Reconciliation Journal";
    begin
        // [FEATURE] [Employee] [UI]
        // [SCENARIO 325315] UI scenario of apply and post payment reconciliation journal with employee
        Initialize();

        // [GIVEN] Employee "E"
        CreateEmployee(Employee);
        // [GIVEN] Post general journal line with Employee "E" and Amount -100
        CreateAndPostGenJournalLineEmployee(GenJnlLine, Employee."No.");

        // [GIVEN] Create payment reconciliation "R" for employee "E"
        CreateBankReconciliationWithEmployee(BankAccReconciliation, BankAccReconciliationLine, Employee."No.", GenJnlLine.Amount);

        // [WHEN] Run action Apply Manualy from Payment Reconciliation Journal
        LibraryVariableStorage.Enqueue(Employee."No.");
        LibraryVariableStorage.Enqueue(GenJnlLine.Amount);
        PaymentReconciliationJournal.OpenEdit();
        PaymentReconciliationJournal.GoToRecord(BankAccReconciliationLine);
        PaymentReconciliationJournal.ApplyEntries.Invoke();
        PaymentReconciliationJournal.PostPaymentsOnly.Invoke();

        // [THEN] Payment for employee "E" with Amount 100 created
        VerifyEmployeeLedgerEntry(Employee."No.", BankAccReconciliation."Statement No.", -GenJnlLine.Amount, "Gen. Journal Document Type"::Payment);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentReconciliationJournalEmployeeUI()
    var
        Employee: Record Employee;
        GenJnlLine: Record "Gen. Journal Line";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        PaymentReconciliationJournal: TestPage "Payment Reconciliation Journal";
    begin
        // [FEATURE] [Employee] [UI]
        // [SCENARIO 325315] Employee ledger entry can be processed on Payment Application page
        Initialize();

        // [GIVEN] Employee "E"
        CreateEmployee(Employee);
        // [GIVEN] Post general journal line with Employee "E" and Amount -100
        CreateAndPostGenJournalLineEmployee(GenJnlLine, Employee."No.");

        // [GIVEN] Create payment reconciliation "R" for employee "E"
        CreateBankReconciliationWithEmployee(BankAccReconciliation, BankAccReconciliationLine, Employee."No.", GenJnlLine.Amount);

        // [WHEN] Open Payment Reconciliation Journal
        PaymentReconciliationJournal.OpenEdit();
        PaymentReconciliationJournal.GoToRecord(BankAccReconciliationLine);

        // [THEN] Page Payment Reconciliation Journal has record with Account Type Employee, Account No. = "E", Account Name = "E"
        Assert.AreEqual(Employee."No.", PaymentReconciliationJournal."Account No.".Value, 'Invalid Account No.');
        Assert.AreEqual(Employee.FullName(), PaymentReconciliationJournal.AccountName.Value, 'Invalid Account Name');
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('PaymentApplicationPageWithEmployee')]
    procedure PaymentApplicationEmployeeApplyManually()
    var
        Employee: Record Employee;
        GenJnlLine: Record "Gen. Journal Line";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        PaymentReconciliationJournal: TestPage "Payment Reconciliation Journal";
    begin
        // [FEATURE] [Employee] [UI]
        // [SCENARIO 325315] Employee ledger entry can be processed on Payment Application page
        Initialize();

        // [GIVEN] Employee "E"
        CreateEmployee(Employee);
        // [GIVEN] Post general journal line with Employee "E" and Amount -100
        CreateAndPostGenJournalLineEmployee(GenJnlLine, Employee."No.");

        // [GIVEN] Create payment reconciliation "R" for employee "E"
        CreateBankReconciliationWithEmployee(BankAccReconciliation, BankAccReconciliationLine, Employee."No.", GenJnlLine.Amount);

        // [WHEN] Run action Apply Manualy from Payment Reconciliation Journal
        LibraryVariableStorage.Enqueue(Employee."No.");
        PaymentReconciliationJournal.OpenEdit();
        PaymentReconciliationJournal.GoToRecord(BankAccReconciliationLine);
        PaymentReconciliationJournal.ApplyEntries.Invoke();

        // [THEN] Page Payment Application has record with Account Type Employee, Account No. = "E", Remaining Amount = -100
        VerifyPaymentApplicationEmployee(Employee, GenJnlLine.Amount);
    end;

    [Test]
    [HandlerFunctions('MessageWithVerificationHandler')]
    [Scope('OnPrem')]
    procedure PaymentApplicationEmployeeApplyAutomatically()
    var
        Employee: Record Employee;
        GenJnlLine: Record "Gen. Journal Line";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        PaymentReconciliationJournal: TestPage "Payment Reconciliation Journal";
    begin
        // [FEATURE] [Employee] [UI]
        // [SCENARIO 325315] Employee ledger entry can be applied automatically from Payment Reconciliation Journal
        Initialize();

        // [GIVEN] Employee "E"
        CreateEmployee(Employee);
        // [GIVEN] Post general journal line with Employee "E" and Amount -100
        CreateAndPostGenJournalLineEmployee(GenJnlLine, Employee."No.");

        // [GIVEN] Create payment reconciliation "R" for employee "E"
        CreateBankReconciliationWithEmployee(BankAccReconciliation, BankAccReconciliationLine, '', GenJnlLine.Amount);

        // [WHEN] Run action Apply Automatically from Payment Reconciliation Journal
        PaymentReconciliationJournal.OpenEdit();
        PaymentReconciliationJournal.GoToRecord(BankAccReconciliationLine);
        LibraryVariableStorage.Enqueue(StrSubstNo(PaymentLineAppliedMsg, 1));
        PaymentReconciliationJournal.ApplyAutomatically.Invoke();

        // [THEN] Applied Amount = -100
        PaymentReconciliationJournal."Applied Amount".AssertEquals(GenJnlLine.Amount);
    end;

    [Test]
    [HandlerFunctions('MessageWithVerificationHandler')]
    [Scope('OnPrem')]
    procedure PaymentApplicationEmployeeApplyAutomaticallyMatchingDisabled()
    var
        Employee: Record Employee;
        GenJnlLine: Record "Gen. Journal Line";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankPmtApplSettings: Record "Bank Pmt. Appl. Settings";
        PaymentReconciliationJournal: TestPage "Payment Reconciliation Journal";
    begin
        // [FEATURE] [Employee] [UI]
        // [SCENARIO 325315] Automatic application disabled when "Bank Pmt. Appl. Settings"."Empl. Ledger Entries Matching" = false
        Initialize();

        // [GIVEN] Employee "E"
        CreateEmployee(Employee);
        // [GIVEN] Post general journal line with Employee "E" and Amount -100
        CreateAndPostGenJournalLineEmployee(GenJnlLine, Employee."No.");

        // [GIVEN] Create payment reconciliation "R" for employee "E"
        CreateBankReconciliationWithEmployee(BankAccReconciliation, BankAccReconciliationLine, '', GenJnlLine.Amount);

        // [GIVEN] Set "Bank Pmt. Appl. Settings"."Empl. Ledger Entries Matching" = false
        BankPmtApplSettings.GetOrInsert();
        BankPmtApplSettings."Empl. Ledger Entries Matching" := false;
        BankPmtApplSettings.Modify();

        // [WHEN] Run action Apply Automatically from Payment Reconciliation Journal
        PaymentReconciliationJournal.OpenEdit();
        PaymentReconciliationJournal.GoToRecord(BankAccReconciliationLine);
        LibraryVariableStorage.Enqueue(StrSubstNo(PaymentLineAppliedMsg, 0));
        PaymentReconciliationJournal.ApplyAutomatically.Invoke();

        // [THEN] Applied Amount = 0
        PaymentReconciliationJournal."Applied Amount".AssertEquals(0);
    end;

    [Test]
    [HandlerFunctions('MessageWithVerificationHandler')]
    [Scope('OnPrem')]
    procedure PaymentApplicationEmployeeApplyAutomaticallyEmployeeName()
    var
        Employee: array[3] of Record Employee;
        GenJnlLine: Record "Gen. Journal Line";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        PaymentReconciliationJournal: TestPage "Payment Reconciliation Journal";
        Amount: Decimal;
        i: Integer;
    begin
        // [FEATURE] [Employee] [UI]
        // [SCENARIO 325315] Apply Automatically from Payment Reconciliation Journal with employee name in the transaction text
        Initialize();

        // [GIVEN] Create and post general journal lines for Employee "E1", "E2" and "E3" with same amount -100
        Amount := -LibraryRandom.RandDec(100, 2);
        for i := 1 to 3 do begin
            CreateEmployee(Employee[i]);
            CreateAndPostGenJournalLineEmployee(GenJnlLine, Employee[i]."No.", Amount);
        end;
        // [GIVEN] Create payment reconciliation
        CreateBankReconciliationWithEmployee(BankAccReconciliation, BankAccReconciliationLine, '', Amount);
        // [GIVEN] Set transaction text = name of employee "E2"
        BankAccReconciliationLine."Transaction Text" := Employee[2].FullName();
        BankAccReconciliationLine.Modify();

        // [WHEN] Run action Apply Automatically from Payment Reconciliation Journal
        PaymentReconciliationJournal.OpenEdit();
        PaymentReconciliationJournal.GoToRecord(BankAccReconciliationLine);
        LibraryVariableStorage.Enqueue(StrSubstNo(PaymentLineAppliedMsg, 1));
        PaymentReconciliationJournal.ApplyAutomatically.Invoke();

        // [THEN] Bank reconciliation line applied to entry with employee "E2"
        PaymentReconciliationJournal."Account No.".AssertEquals(Employee[2]."No.");
    end;

    procedure PostPaymentReconciliationJournalEmployeePositiveAmount()
    var
        Employee: Record Employee;

        GenJnlLine: Record "Gen. Journal Line";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        EntryNo: Integer;
        Amount: Decimal;
    begin
        // [FEATURE] [Employee]
        // [SCENARIO 325315] User is able to apply and post positive amount for Employee in payment reconciliation journal
        Initialize();

        // [GIVEN] Employee "E"
        CreateEmployee(Employee);
        // [GIVEN] Post general journal line with Employee "E" and Amount 100
        Amount := LibraryRandom.RandDec(100, 2);
        EntryNo := CreateAndPostGenJournalLineEmployee(GenJnlLine, Employee."No.", Amount);

        // [GIVEN] Create payment reconciliation "R" for employee "E"
        CreateBankReconciliationWithEmployee(BankAccReconciliation, BankAccReconciliationLine, Employee."No.", Amount);
        ApplyBankAccReconLineToEmployee(BankAccReconciliationLine, Employee."No.", EntryNo);

        // [WHEN] Post payment reconciliation "R"
        LibraryERM.PostBankAccReconciliation(BankAccReconciliation);

        // [THEN] Empty type entry created for employee "E" with Amount -100
        VerifyEmployeeLedgerEntry(Employee."No.", BankAccReconciliation."Statement No.", -Amount, "Gen. Journal Document Type"::" ");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InitReportSelectionPostedPaymentReconciliation()
    var
        ReportSelections: Record "Report Selections";
        ReportSelectionMgt: Codeunit "Report Selection Mgt.";
    begin
        // [FEATURE] [Posted Payment Reconciliation] [UT]
        // [SCENARIO 315205] Report "Posted Payment Reconciliation" defined for bank report selection with option "Posted Payment Reconciliation"
        Initialize();

        // [WHEN] Run InitReportSelectionBank
        ReportSelections.DeleteAll();
        ReportSelectionMgt.InitReportSelectionBank();

        // [THEN] Record created for report "Posted Payment Reconciliation"
        ReportSelections.Get("Report Selection Usage"::"Posted Payment Reconciliation", '1');
        ReportSelections.TestField("Report ID", Report::"Posted Payment Reconciliation");
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('PostedPaymentReconciliationReportRequestPageHandler,PostAndReconcilePageHandler,PostAndReconcilePageStatementDateHandler')]
    procedure PrintPostedPaymentReconciliation()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        PostedPaymentReconHdr: Record "Posted Payment Recon. Hdr";
        DocPrint: Codeunit "Document-Print";
    begin
        // [FEATURE] [Posted Payment Reconciliation] [UT]
        // [SCENARIO 315205] Print report "Posted Payment Reconciliation"
        Initialize();
        Clear(LibraryReportDataset);

        // [GIVEN] Create and post payment reconciliation journal for "Bank Account" = "B", "Statement No."= "S", "G/L Account" = "A", Amount = 100
        CreateBankReconciliationWithGLAccount(BankAccReconciliation, BankAccReconciliationLine, LibraryERM.CreateGLAccountNo());
        UpdateBankAccRecStmEndingBalance(BankAccReconciliation, BankAccReconciliation."Balance Last Statement" + BankAccReconciliationLine."Statement Amount");
        LibraryERM.PostBankAccReconciliation(BankAccReconciliation);
        PostedPaymentReconHdr.Get(BankAccReconciliation."Bank Account No.", BankAccReconciliation."Statement No.");

        // [WHEN] Report "Posted Payment Reconciliation" is being printed
        DocPrint.PrintPostedPaymentReconciliation(PostedPaymentReconHdr);

        // [THEN] Report printed with  "Bank Account" = "B", "Statement No."= "S", "Description" = "A", Amount = 100
        VerifyPostedPaymentReconciliationReport(BankAccReconciliationLine);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('PostedPaymentReconciliationReportRequestPageHandler,PostAndReconcilePageHandler,PostAndReconcilePageStatementDateHandler')]
    procedure PrintPostedPaymentReconciliationFromCard()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        PostedPaymentReconciliation: TestPage "Posted Payment Reconciliation";
    begin
        // [FEATURE] [Posted Payment Reconciliation] [UI]
        // [SCENARIO 315205] Report "Posted Payment Reconciliation" can be printed from pate "Posted Payment Reconciliation"
        Initialize();
        Clear(LibraryReportDataset);

        // [GIVEN] Create and post payment reconciliation journal for "Bank Account" = "B", "Statement No."= "S", "G/L Account" = "A", Amount = 100
        CreateBankReconciliationWithGLAccount(BankAccReconciliation, BankAccReconciliationLine, LibraryERM.CreateGLAccountNo());
        UpdateBankAccRecStmEndingBalance(BankAccReconciliation, BankAccReconciliation."Balance Last Statement" + BankAccReconciliationLine."Statement Amount");
        LibraryERM.PostBankAccReconciliation(BankAccReconciliation);

        // [WHEN] Report "Posted Payment Reconciliation" is being printed
        PostedPaymentReconciliation.OpenView();
        PostedPaymentReconciliation.Filter.SetFilter("Statement No.", BankAccReconciliation."Statement No.");
        PostedPaymentReconciliation.Filter.SetFilter("Bank Account No.", BankAccReconciliation."Bank Account No.");
        PostedPaymentReconciliation.Print.Invoke();

        // [THEN] Report printed with  "Bank Account" = "B", "Statement No."= "S", "Description" = "A", Amount = 100
        VerifyPostedPaymentReconciliationReport(BankAccReconciliationLine);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,PostAndReconcilePageHandler')]
    procedure BalanceLastStatementAndStatementEndingBalanceWhenOneBankAccStatement()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        AccountTypes: array[2] of Enum "Gen. Journal Account Type";
        AccountNos: array[2] of Code[20];
        TransactionAmounts: array[2] of Decimal;
        CustLedgerEntryNo: Integer;
        VendLedgerEntryNo: Integer;
    begin
        // [FEATURE] [Bank Account Statement]
        // [SCENARIO 395469] "Balance Last Statement" and "Statement Ending Balance" of Bank Account Statement when post one Reconciliation Journal with two lines.
        Initialize();

        // [GIVEN] Posted Sales Invoice "SI" with Amount "A1" and Posted Purchase Invoice "PI" with Amount "A2".
        CreateAndPostSalesInvoice(AccountNos[1], CustLedgerEntryNo, TransactionAmounts[1]);
        CreateAndPostPurchaseInvoice(AccountNos[2], VendLedgerEntryNo, TransactionAmounts[2]);

        // [GIVEN] Two Reconciliation Lines that are fully applied to "SI" and "PI".
        AccountTypes[1] := BankAccReconciliationLine."Account Type"::Customer;
        AccountTypes[2] := BankAccReconciliationLine."Account Type"::Vendor;
        CreateAndAutoApplyTwoBankAccReconLines(BankAccReconciliation, CreateBankAccount(), AccountTypes, AccountNos, TransactionAmounts);

        // [WHEN] Post Reconciliation Lines.
        LibraryERM.PostBankAccReconciliation(BankAccReconciliation);

        // [THEN] Bank Account Statement is created. "Balance Last Statement" = 0 and "Statement Ending Balance" = "A1" + "A2".
        VerifyLastBankAccountStatementAmounts(BankAccReconciliation."Bank Account No.", 0, TransactionAmounts[1] + TransactionAmounts[2]);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,PostAndReconcileWithEndingBalanceModalPageHandler')]
    procedure BalanceLastStatementAndStatementEndingBalanceWhenMultipleBankAccStatements()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccount: Record "Bank Account";
        AccountTypes: array[2] of Enum "Gen. Journal Account Type";
        AccountNos: array[2] of Code[20];
        TransactionAmounts: array[2] of Decimal;
        StatementEndingBalance: Decimal;
        CustLedgerEntryNo: Integer;
        VendLedgerEntryNo: Integer;
    begin
        // [FEATURE] [Bank Account Statement] [Payment Reconciliation Journal]
        // [SCENARIO 395469] Stan can specify statement's ending balance when he post payment reconciliation journal
        Initialize();
        LibraryERM.CreateBankAccount(BankAccount);

        CreateAndPostSalesInvoice(AccountNos[1], CustLedgerEntryNo, TransactionAmounts[1]);
        CreateAndPostPurchaseInvoice(AccountNos[2], VendLedgerEntryNo, TransactionAmounts[2]);

        AccountTypes[1] := BankAccReconciliationLine."Account Type"::Customer;
        AccountTypes[2] := BankAccReconciliationLine."Account Type"::Vendor;

        CreateBankReconciliation(BankAccReconciliation, BankAccount."No.", BankAccReconciliation."Statement Type"::"Payment Application");
        CreateBankAccReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, AccountTypes[1], AccountNos[1], TransactionAmounts[1], WorkDate());
        CreateBankAccReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, AccountTypes[2], AccountNos[2], TransactionAmounts[2], WorkDate());
        BankAccReconciliation."Post Payments Only" := false;
        Codeunit.Run(Codeunit::"Match Bank Pmt. Appl.", BankAccReconciliation);

        StatementEndingBalance := TransactionAmounts[2] + TransactionAmounts[1];
        LibraryVariableStorage.Enqueue(StatementEndingBalance);

        LibraryERM.PostBankAccReconciliation(BankAccReconciliation);

        VerifyLastBankAccountStatementAmounts(BankAccReconciliation."Bank Account No.", 0, StatementEndingBalance);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure SequenceOfBankAccReconciliationOnDifferentDays()
    var
        BankAccountStatement: Record "Bank Account Statement";
        Vendor: Record Vendor;
        BankAccount: Record "Bank Account";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: array[5] of Record "Gen. Journal Line";
        LastStatementNo: array[5] of Code[20];
        StatementNo: Code[20];
        EndingBalance: Decimal;
        EndingBalanceBefore: Decimal;
        Index: Integer;
    begin
        // [FEATURE] [Bank Account Statement] [Bank Account Reconciliation]
        // [SCENARIO 395469] System get last statement's amount reffered in bank account card when it posts bank account reconciliation
        Initialize();
        LibraryERM.CreateBankAccount(BankAccount);
        LibraryPurchase.CreateVendor(Vendor);

        LastStatementNo[1] := '0';
        LastStatementNo[2] := '1';
        LastStatementNo[3] := '2';
        LastStatementNo[4] := '22';
        LastStatementNo[5] := '32';

        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        GenJournalBatch.Validate("Bal. Account Type", GenJournalBatch."Bal. Account Type"::"Bank Account");
        GenJournalBatch.Validate("Bal. Account No.", BankAccount."No.");
        GenJournalBatch.Modify(true);

        for Index := 1 to ArrayLen(GenJournalLine) do begin
            LibraryERM.CreateGeneralJnlLine(
                GenJournalLine[Index],
                GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine[Index]."Document Type"::Payment,
                GenJournalLine[Index]."Account Type"::Vendor, Vendor."No.",
                LibraryRandom.RandIntInRange(100, 200));
            GenJournalLine[Index].Validate("Posting Date", DMY2Date(1, Index, 2021));
            GenJournalLine[Index].Modify(true);
            LibraryERM.PostGeneralJnlLine(GenJournalLine[Index]);
        end;

        EndingBalance := 0;
        for Index := 1 to ArrayLen(GenJournalLine) do begin
            EndingBalanceBefore := EndingBalance;
            ManualApplyAndPostBankAccountReconciliation(BankAccount, LastStatementNo[Index], Vendor, GenJournalLine[Index], EndingBalance);
            BankAccount.Find();
            StatementNo := LastStatementNo[Index];
            StatementNo := IncStr(StatementNo);
            BankAccount.TestField("Last Statement No.", StatementNo);
            BankAccount.TestField("Balance Last Statement", -EndingBalance);

            BankAccountStatement.Get(BankAccount."No.", StatementNo);
            BankAccountStatement.TestField("Balance Last Statement", -EndingBalanceBefore);
            BankAccountStatement.TestField("Statement Ending Balance", -EndingBalance);
        end;
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UndoBankStatementWithCheckLedgerEntryIncludeChecksNo()
    var
        BankAccount: Record "Bank Account";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccountStatement: Record "Bank Account Statement";
        UndoBankStatementYesNo: Codeunit "Undo Bank Statement (Yes/No)";
        DocumentNo: Code[20];
        NewStatementNo: Code[20];
    begin
        // [FEATURE] [Undo Bank Account Statement]
        // [SCENARIO 414381] Undo Bank Account statement which was suggested with "Include Checks" = No and with check ledger entry
        Initialize();

        // [GIVEN] Create and post check payment
        DocumentNo := PostCheck(BankAccount, CreateBankAccount(), LibraryRandom.RandDec(1000, 2));

        // [GIVEN] Create and post bank reconciliation which was suggested with "Include Checks" = No (Bank Rec Line.Type = Bank Ledger Entry)
        CreateSuggestedBankReconc(BankAccReconciliation, BankAccount."No.", false);
        LibraryERM.PostBankAccReconciliation(BankAccReconciliation);

        // [WHEN] Undo bank statement
        BankAccountStatement.Get(BankAccount."No.", BankAccReconciliation."Statement No.");
        NewStatementNo := UndoBankStatementYesNo.UndoBankAccountStatement(BankAccountStatement);

        // [THEN] Check account entry has "Statement Status" = "Bank Acc. Entry Applied"
        VerifyUndoneCheckLedgerEntry(BankAccount."No.", DocumentNo, NewStatementNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UndoBankStatementManyToOneWithCheckLedgerEntry()
    var
        BankAccount: Record "Bank Account";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccountStatement: Record "Bank Account Statement";
        UndoBankStatementYesNo: Codeunit "Undo Bank Statement (Yes/No)";
        DocumentNo: Code[20];
        NewStatementNo: Code[20];
        PaymentAmount: Decimal;
    begin
        // [FEATURE] [Undo Bank Account Statement] [Match]
        // [SCENARIO 414381] Undo Bank Account statement with several lines applied to one bank account entry which has check ledger entry
        Initialize();

        // [GIVEN] Create and post check payment
        PaymentAmount := 2 * LibraryRandom.RandDec(1000, 2);
        DocumentNo := PostCheck(BankAccount, CreateBankAccount(), PaymentAmount);

        // [GIVEN] Create and post bank reconciliation which was suggested with "Include Checks" = No (Bank Rec Line.Type = Bank Ledger Entry)
        CreateBankReconciliationManyToOne(BankAccReconciliation, BankAccount."No.", PaymentAmount);
        MatchBankReconciliationManyToOne(BankAccReconciliation);
        LibraryERM.PostBankAccReconciliation(BankAccReconciliation);

        // [WHEN] Undo bank statement
        BankAccountStatement.Get(BankAccount."No.", BankAccReconciliation."Statement No.");
        NewStatementNo := UndoBankStatementYesNo.UndoBankAccountStatement(BankAccountStatement);

        // [THEN] Check account entry has "Statement Status" = "Bank Acc. Entry Applied"
        VerifyUndoneCheckLedgerEntryManyToOne(BankAccount."No.", DocumentNo, NewStatementNo);
    end;

    [Test]
    [HandlerFunctions('PaymentApplicationModalPageHandler,PostAndReconcilePageHandler')]
    [Scope('OnPrem')]
    procedure PostBankReconciliationWhenSatementNoExist()
    var
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseHeader: Record "Purchase Header";
        BankAccReconciliation: array[2] of Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccountStatement: Record "Bank Account Statement";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        CheckLedgerEntry: Record "Check Ledger Entry";
        DocumentNo: array[2] of Code[20];
        InvoiceNo: Code[20];
        BankPaymentAmount: Decimal;
        CheckPaymentAmount: Decimal;
        InvoiceAmount: Decimal;
    begin
        // [SCENARIO 420266] Bank account ledger entry has proper Statement No. while posting when same Statement No. already exist
        Initialize();

        // [GIVEN] Create bank account
        LibraryERM.CreateBankAccount(BankAccount);
        // [GIVEN] Create and post check payment "CP"
        DocumentNo[1] := CreatePaymentJournalLineWithVendorAndBank(GenJournalLine, LibraryPurchase.CreateVendorNo(), BankAccount."No.");
        GenJournalLine.Validate("Bank Payment Type", GenJournalLine."Bank Payment Type"::"Manual Check");
        GenJournalLine.Modify();
        CheckPaymentAmount := GenJournalLine.Amount;
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        // [GIVEN] Create and post bank payment "BP"
        DocumentNo[2] := CreatePaymentJournalLineWithVendorAndBank(GenJournalLine, LibraryPurchase.CreateVendorNo(), BankAccount."No.");
        BankPaymentAmount := GenJournalLine.Amount;
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Create and post invoice "I"
        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);
        PurchaseHeader.CalcFields("Amount Including VAT");
        InvoiceAmount := PurchaseHeader."Amount Including VAT";
        InvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Create bank reconciliation 1 for payments "CP" and "BP"
        CreateBankReconciliation(BankAccReconciliation[1], BankAccount."No.", BankAccReconciliation[1]."Statement Type"::"Bank Reconciliation");
        SuggestBankRecLines(BankAccReconciliation[1], true);

        // [GIVEN] Create Payment Application to invoice "I" and post it
        CreateBankReconciliation(BankAccReconciliation[2], BankAccount."No.", BankAccReconciliation[2]."Statement Type"::"Payment Application");
        CreateBankAccReconciliationLine(
            BankAccReconciliation[2], BankAccReconciliationLine, BankAccReconciliationLine."Account Type"::Vendor,
            PurchaseHeader."Buy-from Vendor No.", -InvoiceAmount, WorkDate());
        LibraryVariableStorage.Enqueue(PurchaseHeader."Buy-from Vendor No.");
        LibraryVariableStorage.Enqueue(InvoiceNo);
        MatchBankReconLineManually(BankAccReconciliationLine);
        UpdateBankAccRecStmEndingBalance(BankAccReconciliation[2], BankAccReconciliationLine."Statement Amount");
        LibraryERM.PostBankAccReconciliation(BankAccReconciliation[2]);

        // [WHEN] Bank reconciliation 1 is being posted and created statement 2
        UpdateBankAccRecStmEndingBalance(BankAccReconciliation[1], -(CheckPaymentAmount + BankPaymentAmount));
        LibraryERM.PostBankAccReconciliation(BankAccReconciliation[1]);

        // [THEN] Bank and check ledger entries "CP" applied to statement 2
        BankAccountStatement.SetRange("Bank Account No.", BankAccount."No.");
        BankAccountStatement.FindLast();

        FindBankLedgerEntry(BankAccountLedgerEntry, BankAccount."No.", DocumentNo[1]);
        BankAccountLedgerEntry.TestField("Statement No.", BankAccountStatement."Statement No.");
        FindCheckLedgerEntry(CheckLedgerEntry, BankAccount."No.", DocumentNo[1]);
        CheckLedgerEntry.TestField("Statement Status", CheckLedgerEntry."Statement Status"::"Closed");

        // [THEN] Bank ledger entry "BP" applied to statement 2
        FindBankLedgerEntry(BankAccountLedgerEntry, BankAccount."No.", DocumentNo[2]);
        BankAccountLedgerEntry.TestField("Statement No.", BankAccountStatement."Statement No.");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('BankAccountStatementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CheckingOustandingPaymentsInBankAccStatementsReport_TransactionClosedOnPostingDay()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccountStatement: Record "Bank Account Statement";
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        RequestPageXML: Text;
        CheckPaymentAmount: Decimal;
        BankPaymentAmount: Decimal;
    begin
        // [FEATURE] [Bank Account Statement Report]
        // [SCENARIO 341166] Bank and Check payments were open and closed on posting day
        Initialize();

        // [GIVEN] Create a Bank Account
        LibraryERM.CreateBankAccount(BankAccount);

        // [GIVEN] Create and post check payment "CP"
        CreatePaymentJournalLineWithVendorAndBank(GenJournalLine, LibraryPurchase.CreateVendorNo(), BankAccount."No.", WorkDate());
        GenJournalLine.Validate("Bank Payment Type", GenJournalLine."Bank Payment Type"::"Manual Check");
        GenJournalLine.Modify();
        CheckPaymentAmount := GenJournalLine.Amount;
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Create and post bank payment "BP"
        CreatePaymentJournalLineWithVendorAndBank(GenJournalLine, LibraryPurchase.CreateVendorNo(), BankAccount."No.", WorkDate());
        BankPaymentAmount := GenJournalLine.Amount;
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Create and post bank reconciliation for payments "CP" and "BP"
        CreateBankReconciliation(BankAccReconciliation, BankAccount."No.", BankAccReconciliation."Statement Type"::"Bank Reconciliation");
        SuggestBankRecLines(BankAccReconciliation, true);
        UpdateBankAccRecStmEndingBalance(BankAccReconciliation, -(CheckPaymentAmount + BankPaymentAmount));
        LibraryERM.PostBankAccReconciliation(BankAccReconciliation);

        // [WHEN] Bank Statement report is visited, Print outstanding transactions = true
        LibraryVariableStorage.Enqueue(true);
        BankAccountStatement.SetRange("Bank Account No.", BankAccount."No.");
        RequestPageXML := REPORT.RunRequestPage(REPORT::"Bank Account Statement", RequestPageXML);
        LibraryReportDataset.RunReportAndLoad(REPORT::"Bank Account Statement", BankAccountStatement, RequestPageXML);

        // [THEN] "CP" and "BP" appear as completed payments
        LibraryReportDataset.AssertElementWithValueExists('Amt1_BankAccStmtLineStmt', -BankPaymentAmount);
        LibraryReportDataset.AssertElementWithValueExists('Amt1_BankAccStmtLineStmt', -CheckPaymentAmount);
        LibraryReportDataset.AssertElementWithValueNotExist('Outstanding_BankTransaction_Amount', -BankPaymentAmount);
        LibraryReportDataset.AssertElementWithValueNotExist('Outstanding_Check_Amount', -CheckPaymentAmount);
    end;

    [Test]
    [HandlerFunctions('BankAccountStatementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure NoOustandingTransactionsVisibleInBankAccStatementsReport()
    var
        GLAccount: Record "G/L Account";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccountStatement: Record "Bank Account Statement";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        GenJournalLine: array[3] of Record "Gen. Journal Line";
        MatchBankRecLines: Codeunit "Match Bank Rec. Lines";
        VendorNo: Code[20];
        BankAccountNo: Code[20];
        RequestPageXML: Text;
        ClosedBankPaymentAmount: Decimal;
        OutstandingCheckAmount: Decimal;
        OutstandingBankPaymentAmount: Decimal;
    begin
        // [FEATURE] [Bank Account Statement Report]
        // [SCENARIO 341166] Bank Account Statement report doesn't show outstanding transactions when "Print outstanding transactions" = false
        Initialize();

        // [GIVEN] GL Account without any previous entry
        LibraryERM.CreateGLAccount(GLAccount);
        // [GIVEN] Bank account X
        BankAccountNo := LibraryERM.CreateBankAccountNoWithNewPostingGroup(GLAccount);
        // [GIVEN] Vendor X
        VendorNo := LibraryPurchase.CreateVendorNo();
        // [GIVEN] Create and post what will be the closed payment "CP"
        PostPaymentJournalLineWithDateAndSource(GenJournalLine[1], WorkDate() - 1, VendorNo, BankAccountNo);
        ClosedBankPaymentAmount := GenJournalLine[1].Amount;
        // [GIVEN] Create and post what will be the outstanding payment "OP"
        PostPaymentJournalLineWithDateAndSource(GenJournalLine[2], WorkDate() - 1, VendorNo, BankAccountNo);
        OutstandingBankPaymentAmount := GenJournalLine[2].Amount;
        // [GIVEN] Create and post what will be the outstanding check "OC"
        CreatePaymentJournalLineWithVendorAndBank(GenJournalLine[3], VendorNo, BankAccountNo, WorkDate() - 1);
        GenJournalLine[3].Validate("Bank Payment Type", GenJournalLine[3]."Bank Payment Type"::"Manual Check");
        GenJournalLine[3].Modify();
        OutstandingCheckAmount := GenJournalLine[3].Amount;
        LibraryERM.PostGeneralJnlLine(GenJournalLine[3]);

        // [GIVEN] Create bank reconciliation for "CP"
        CreateBankReconciliation(BankAccReconciliation, BankAccountNo, BankAccReconciliation."Statement Type"::"Bank Reconciliation");
        CreateBankAccReconciliationLine(BankAccReconciliation, BankAccReconciliationLine,
            BankAccReconciliationLine."Account Type"::Vendor, VendorNo, -ClosedBankPaymentAmount, WorkDate());

        // [GIVEN] Match bank reconciliation line for "CP"
        BankAccountLedgerEntry.SetRange("Bank Account No.", BankAccountNo);
        BankAccountLedgerEntry.SetRange("Journal Templ. Name", GenJournalLine[1]."Journal Template Name");
        BankAccReconciliationLine.SetRecFilter();
        MatchBankRecLines.MatchManually(BankAccReconciliationLine, BankAccountLedgerEntry);

        // [GIVEN] Post bank reconciliation
        BankAccReconciliation."Statement Ending Balance" := BankAccReconciliationLine."Statement Amount";
        BankAccReconciliation.Modify();
        LibraryERM.PostBankAccReconciliation(BankAccReconciliation);

        // [GIVEN] Print outstanding transactions = false
        LibraryVariableStorage.Enqueue(false);

        // [WHEN] Run Bank Account Statement report
        BankAccountStatement.SetRange("Bank Account No.", BankAccountNo);
        RequestPageXML := REPORT.RunRequestPage(REPORT::"Bank Account Statement", RequestPageXML);
        LibraryReportDataset.RunReportAndLoad(REPORT::"Bank Account Statement", BankAccountStatement, RequestPageXML);

        // [THEN] Outstanding transaction fields are not visible
        LibraryReportDataset.AssertElementWithValueNotExist('Outstanding_BankTransaction_Amount', -OutstandingBankPaymentAmount);
        LibraryReportDataset.AssertElementWithValueNotExist('Outstanding_Check_Amount', -OutstandingCheckAmount);

        // [THEN] "CP" appears as completed payment
        LibraryReportDataset.AssertElementWithValueExists('Amt1_BankAccStmtLineStmt', -ClosedBankPaymentAmount);
    end;

    [Test]
    [HandlerFunctions('BankAccountStatementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CheckingOustandingPaymentsInBankAccStatementsReport_TransactionStillOpenAfterPostingDay()
    var
        GLAccount: Record "G/L Account";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccountStatement: Record "Bank Account Statement";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        GenJournalLine: array[3] of Record "Gen. Journal Line";
        MatchBankRecLines: Codeunit "Match Bank Rec. Lines";
        BankAccRecTest: Codeunit "Bank Acc. Recon. Test";
        VendorNo: Code[20];
        BankAccountNo: Code[20];
        RequestPageXML: Text;
        ClosedBankPaymentAmount: Decimal;
        OutstandingCheckAmount: Decimal;
        OutstandingBankPaymentAmount: Decimal;
    begin
        // [FEATURE] [Bank Account Statement Report]
        // [SCENARIO 341166] Bank and Check payments were open before posting day and not closed afterwards.
        Initialize();
        BankAccountLedgerEntry.DeleteAll();

        // [GIVEN] GL Account without any previous entry
        LibraryERM.CreateGLAccount(GLAccount);
        // [GIVEN] Bank account
        BankAccountNo := LibraryERM.CreateBankAccountNoWithNewPostingGroup(GLAccount);
        // [GIVEN] Vendor
        VendorNo := LibraryPurchase.CreateVendorNo();
        // [WHEN] Create and post what will be the closed payment "CP"
        PostPaymentJournalLineWithDateAndSource(GenJournalLine[1], WorkDate() - 1, VendorNo, BankAccountNo);
        ClosedBankPaymentAmount := GenJournalLine[1].Amount;
        // [WHEN] Create and post what will be the outstanding payment "OP"
        PostPaymentJournalLineWithDateAndSource(GenJournalLine[2], WorkDate() - 1, VendorNo, BankAccountNo);
        // [WHEN] Create and post what will be the outstanding check "OC"
        CreatePaymentJournalLineWithVendorAndBank(GenJournalLine[3], VendorNo, BankAccountNo, WorkDate() - 1);
        GenJournalLine[3].Validate("Bank Payment Type", GenJournalLine[3]."Bank Payment Type"::"Manual Check");
        GenJournalLine[3].Modify();
        LibraryERM.PostGeneralJnlLine(GenJournalLine[3]);

        // [WHEN] Create bank reconciliation for "CP"
        CreateBankReconciliation(BankAccReconciliation, BankAccountNo, BankAccReconciliation."Statement Type"::"Bank Reconciliation");
        CreateBankAccReconciliationLine(BankAccReconciliation, BankAccReconciliationLine,
            BankAccReconciliationLine."Account Type"::Vendor, VendorNo, -ClosedBankPaymentAmount, WorkDate());

        // [WHEN] Match bank reconciliation line for "CP"
        BankAccountLedgerEntry.SetRange("Bank Account No.", BankAccountNo);
        BankAccountLedgerEntry.SetRange("Journal Templ. Name", GenJournalLine[1]."Journal Template Name");
        BankAccReconciliationLine.SetRecFilter();
        MatchBankRecLines.MatchManually(BankAccReconciliationLine, BankAccountLedgerEntry);

        // [WHEN] Post bank reconciliation
        BankAccReconciliation."Statement Ending Balance" := BankAccReconciliationLine."Statement Amount";
        BankAccReconciliation.Modify();
        OutstandingBankPaymentAmount := BankAccRecTest.TotalOutstandingBankTransactions(BankAccReconciliation);
        OutstandingCheckAmount := BankAccRecTest.TotalOutstandingPayments(BankAccReconciliation);
        LibraryERM.PostBankAccReconciliation(BankAccReconciliation);

        // [WHEN] Bank Statement report is visited, Print outstanding transactions = true
        LibraryVariableStorage.Enqueue(true);
        BankAccountStatement.SetRange("Bank Account No.", BankAccountNo);
        RequestPageXML := REPORT.RunRequestPage(REPORT::"Bank Account Statement", RequestPageXML);
        LibraryReportDataset.RunReportAndLoad(REPORT::"Bank Account Statement", BankAccountStatement, RequestPageXML);

        // [THEN] "CP" appears as completed payment
        LibraryReportDataset.AssertElementWithValueExists('Amt1_BankAccStmtLineStmt', -ClosedBankPaymentAmount);

        // [THEN] "OP" and "OC" appear as outstanding
        LibraryReportDataset.AssertElementWithValueExists('Outstanding_BankTransaction_Amount', OutstandingBankPaymentAmount);
        LibraryReportDataset.AssertElementWithValueExists('Outstanding_Check_Amount', OutstandingCheckAmount);
    end;

    [Test]
    [HandlerFunctions('BankAccountStatementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CheckingOustandingPaymentsInBankAccStatementsReport_TransactionClosedAfterPostingDay()
    var
        GLAccount: Record "G/L Account";
        BankAccReconciliation: array[2] of Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccountStatement: Record "Bank Account Statement";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        GenJournalLine: array[3] of Record "Gen. Journal Line";
        MatchBankRecLines: Codeunit "Match Bank Rec. Lines";
        BankAccRecTest: Codeunit "Bank Acc. Recon. Test";
        VendorNo: Code[20];
        BankAccountNo: Code[20];
        RequestPageXML: Text;
        ClosedBankPaymentAmount: Decimal;
        ClosedAfterwardsCheckAmount: Decimal;
        ClosedAfterwardsBankPaymentAmount: Decimal;
        OutstandingCheckAmount: Decimal;
        OutstandingBankPaymentAmount: Decimal;
    begin
        // [FEATURE] [Bank Account Statement Report]
        // [SCENARIO 341166] Bank and Check payments were open before posting day and closed afterwards.
        Initialize();
        BankAccountLedgerEntry.DeleteAll();

        // [GIVEN] GL Account without any previous entry
        LibraryERM.CreateGLAccount(GLAccount);
        // [GIVEN] Bank account
        BankAccountNo := LibraryERM.CreateBankAccountNoWithNewPostingGroup(GLAccount);
        // [GIVEN] Vendor
        VendorNo := LibraryPurchase.CreateVendorNo();
        // [WHEN] Create and post what will be the closed payment "CP"
        PostPaymentJournalLineWithDateAndSource(GenJournalLine[1], WorkDate() - 1, VendorNo, BankAccountNo);
        ClosedBankPaymentAmount := GenJournalLine[1].Amount;
        // [WHEN] Create and post what will be the closed afterwards payment "CAP"
        PostPaymentJournalLineWithDateAndSource(GenJournalLine[2], WorkDate() - 1, VendorNo, BankAccountNo);
        ClosedAfterwardsBankPaymentAmount := GenJournalLine[2].Amount;
        // [WHEN] Create and post what will be the closed afterwards check "CAC"
        CreatePaymentJournalLineWithVendorAndBank(GenJournalLine[3], VendorNo, BankAccountNo, WorkDate() - 1);
        GenJournalLine[3].Validate("Bank Payment Type", GenJournalLine[3]."Bank Payment Type"::"Manual Check");
        GenJournalLine[3].Modify();
        ClosedAfterwardsCheckAmount := GenJournalLine[3].Amount;
        LibraryERM.PostGeneralJnlLine(GenJournalLine[3]);

        // [WHEN] Create bank reconciliation for "CP"
        CreateBankReconciliation(BankAccReconciliation[1], BankAccountNo, BankAccReconciliation[1]."Statement Type"::"Bank Reconciliation");
        CreateBankAccReconciliationLine(BankAccReconciliation[1], BankAccReconciliationLine,
            BankAccReconciliationLine."Account Type"::Vendor, VendorNo, -ClosedBankPaymentAmount, WorkDate());

        // [WHEN] Match bank reconciliation line for "CP"
        BankAccountLedgerEntry.SetRange("Bank Account No.", BankAccountNo);
        BankAccountLedgerEntry.SetRange("Journal Templ. Name", GenJournalLine[1]."Journal Template Name");
        BankAccReconciliationLine.SetRecFilter();
        MatchBankRecLines.MatchManually(BankAccReconciliationLine, BankAccountLedgerEntry);

        // [WHEN] Post bank reconciliation
        BankAccReconciliation[1]."Statement Ending Balance" := BankAccReconciliationLine."Statement Amount";
        BankAccReconciliation[1].Modify();
        OutstandingBankPaymentAmount := BankAccRecTest.TotalOutstandingBankTransactions(BankAccReconciliation[1]);
        OutstandingCheckAmount := BankAccRecTest.TotalOutstandingPayments(BankAccReconciliation[1]);

        LibraryERM.PostBankAccReconciliation(BankAccReconciliation[1]);

        // [WHEN] Create bank reconciliation for "CAP" and "CAC" and suggest lines
        CreateBankReconciliation(BankAccReconciliation[2], BankAccountNo, BankAccReconciliation[2]."Statement Type"::"Bank Reconciliation");
        BankAccReconciliation[2]."Statement Date" := WorkDate() + 1;
        SuggestBankRecLines(BankAccReconciliation[2], true, WorkDate() - 1, WorkDate() + 1);

        // [WHEN] Post bank reconciliation for "CAP" and "CAC"
        UpdateBankAccRecStmEndingBalance(BankAccReconciliation[2],
            -(ClosedBankPaymentAmount + ClosedAfterwardsBankPaymentAmount + ClosedAfterwardsCheckAmount));

        // [WHEN] Bank Statement report is visited, Print outstanding transactions = true
        Commit();
        LibraryVariableStorage.Enqueue(true);
        BankAccountStatement.SetRange("Bank Account No.", BankAccountNo);
        BankAccountStatement.FindFirst();
        RequestPageXML := REPORT.RunRequestPage(REPORT::"Bank Account Statement", RequestPageXML);
        LibraryReportDataset.RunReportAndLoad(REPORT::"Bank Account Statement", BankAccountStatement, RequestPageXML);

        // [THEN] "CP" appears as completed payment
        LibraryReportDataset.AssertElementWithValueExists('Amt1_BankAccStmtLineStmt', -ClosedBankPaymentAmount);

        // [THEN] "OP" and "OC" appear as outstanding
        LibraryReportDataset.AssertElementWithValueExists('Bank_Acc__Reconciliation___TotalOutstdBankTransactions', OutstandingBankPaymentAmount);
        LibraryReportDataset.AssertElementWithValueExists('Bank_Acc__Reconciliation___TotalOutstdPayments', OutstandingCheckAmount);
        LibraryReportDataset.AssertElementWithValueExists('Outstanding_BankTransaction_Amount', OutstandingBankPaymentAmount);
        LibraryReportDataset.AssertElementWithValueExists('Outstanding_Check_Amount', OutstandingCheckAmount);
    end;

    [HandlerFunctions('CorruptSuggestLinesHandler')]
    [Test()]
    procedure CorruptDataWhenSuggestingLinesShouldHaveOptionForYesToAll()
    var
        BankAccount: Record "Bank Account";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        CheckLedgerEntry: Record "Check Ledger Entry";
        SuggestBankAccReconLines: Report "Suggest Bank Acc. Recon. Lines";
        GenJournalLines: array[10] of Record "Gen. Journal Line";
        VendorNo: Code[20];
        I: Integer;
    begin
        // [SCENARIO] When a user has a corrupt state in its Bank Ledger Entries, they will be warned when matching (for example when using Suggest Lines)
        // They should have the option to choose "Yes to  all" for all the entries in this state

        // [GIVEN] A bank account with several corrupt check entries: A corrupt entry is one with Bank Account Ledger Entry Statement Status open, but Check Ledger Entry with different Statement Status
        Initialize();
        TimesSuggestLinesRun := 0;
        LibraryERM.CreateBankAccount(BankAccount);
        VendorNo := LibraryPurchase.CreateVendorNo();
        for I := 1 to ArrayLen(GenJournalLines) do begin
            CreatePaymentJournalLineWithVendorAndBank(GenJournalLines[i], VendorNo, BankAccount."No.");
            GenJournalLines[I].Validate("Bank Payment Type", GenJournalLines[i]."Bank Payment Type"::"Manual Check");
            GenJournalLines[I].Modify();
            LibraryERM.PostGeneralJnlLine(GenJournalLines[I]);
        end;
        // We corrupt all the Check Entries for this bank
        CheckLedgerEntry.SetRange("Bank Account No.", BankAccount."No.");
        CheckLedgerEntry.FindSet();
        repeat
            CheckLedgerEntry."Statement Status" := CheckLedgerEntry."Statement Status"::"Check Entry Applied";
            CheckLedgerEntry.Modify();
        until CheckLedgerEntry.Next() = 0;

        // [WHEN] The user Runs Suggest lines for a bank reconciliation of this bank
        LibraryERM.CreateBankAccReconciliation(BankAccReconciliation, BankAccount."No.", BankAccReconciliation."Statement Type"::"Bank Reconciliation");
        BankAccReconciliation.Validate("Statement Date", WorkDate());
        BankAccReconciliation.Modify(true);

        SuggestBankAccReconLines.SetTableView(BankAccount);
        SuggestBankAccReconLines.InitializeRequest(WorkDate(), WorkDate(), false);
        SuggestBankAccReconLines.UseRequestPage(false);
        SuggestBankAccReconLines.SetStmt(BankAccReconciliation);
        SuggestBankAccReconLines.Run();
        // [THEN] In Handler
    end;

    [Test]
    procedure BankAccReconciliationPageHidesReversedByDefault()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLRegister: Record "G/L Register";
        ReversalEntry: Record "Reversal Entry";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationPage: TestPage "Bank Acc. Reconciliation";
        BankAccountNo: Code[20];
        VendorNo: Code[20];
        FirstAmount: Decimal;
        VisibleAmount: Decimal;
        NEntries: Integer;
    begin
        // [SCENARIO] A user posts some payments to a bank and reverts one of them. When opening a reconciliation the Bank Ledger shouldn't be empty, but they shoudln't see the reversed entry
        Initialize();
        // [GIVEN] Bank account
        BankAccountNo := CreateBankAccount();
        // [GIVEN] Vendor
        VendorNo := LibraryPurchase.CreateVendorNo();
        // [GIVEN] First payment
        PostPaymentJournalLineWithDateAndSource(GenJournalLine, WorkDate() - 1, VendorNo, BankAccountNo);
        FirstAmount := GenJournalLine.Amount;
        // [GIVEN] Second payment
        PostPaymentJournalLineWithDateAndSource(GenJournalLine, WorkDate() - 1, VendorNo, BankAccountNo);
        // [GIVEN] Second payment is reversed
        GLRegister.FindLast();
        ReversalEntry.SetHideWarningDialogs();
        ReversalEntry.ReverseRegister(GLRegister."No.");
        // [WHEN] Opening the Bank Reconciliation page for this bank
        LibraryERM.CreateBankAccReconciliation(BankAccReconciliation, BankAccountNo, BankAccReconciliation."Statement Type"::"Bank Reconciliation");
        BankAccReconciliationPage.OpenView();
        BankAccReconciliationPage.GoToRecord(BankAccReconciliation);
        // [THEN] There should only be one payment visible in the Bank Ledger Entries subpage
        if not BankAccReconciliationPage.ApplyBankLedgerEntries.First() then
            Error('No visible bank ledger entries found');
        repeat
            NEntries += 1;
            Evaluate(VisibleAmount, BankAccReconciliationPage.ApplyBankLedgerEntries.Amount.Value());
        until not BankAccReconciliationPage.ApplyBankLedgerEntries.Next();
        Assert.AreEqual(1, NEntries, 'Only one bank ledger entry should be visible');
        Assert.AreEqual(FirstAmount, -VisibleAmount, 'The visible entry should be the non-reversed one');
    end;

    [Test]
    procedure BankAccReconciliationPageTogglesReversed()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLRegister: Record "G/L Register";
        ReversalEntry: Record "Reversal Entry";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationPage: TestPage "Bank Acc. Reconciliation";
        BankAccountNo: Code[20];
        VendorNo: Code[20];
        FirstAmount: Decimal;
        VisibleAmount: Decimal;
        NEntries: Integer;
    begin
        // [SCENARIO] A user posts some payments to a bank and reverts one of them. By using the actions "Show/Hide Reversed" the user should be able to change the entries they are looking at.
        Initialize();
        // [GIVEN] Bank account
        BankAccountNo := CreateBankAccount();
        // [GIVEN] Vendor
        VendorNo := LibraryPurchase.CreateVendorNo();
        // [GIVEN] First payment
        PostPaymentJournalLineWithDateAndSource(GenJournalLine, WorkDate() - 1, VendorNo, BankAccountNo);
        FirstAmount := GenJournalLine.Amount;
        // [GIVEN] Second payment
        PostPaymentJournalLineWithDateAndSource(GenJournalLine, WorkDate() - 1, VendorNo, BankAccountNo);
        // [GIVEN] Second payment is reversed
        GLRegister.FindLast();
        ReversalEntry.SetHideWarningDialogs();
        ReversalEntry.ReverseRegister(GLRegister."No.");
        // [WHEN] Opening the Bank Reconciliation page for this bank
        LibraryERM.CreateBankAccReconciliation(BankAccReconciliation, BankAccountNo, BankAccReconciliation."Statement Type"::"Bank Reconciliation");
        BankAccReconciliationPage.OpenView();
        BankAccReconciliationPage.GoToRecord(BankAccReconciliation);
        // [WHEN] Using the action "Show Reversed Entries"
        BankAccReconciliationPage.ShowReversedEntries.Invoke();
        // [THEN] There should be two payments visible in the Bank Ledger Entries subpage
        if not BankAccReconciliationPage.ApplyBankLedgerEntries.First() then
            Error('No visible bank ledger entries found');
        repeat
            NEntries += 1;
        until not BankAccReconciliationPage.ApplyBankLedgerEntries.Next();
        Assert.AreEqual(3, NEntries, 'Both bank ledger entries should be visible, and one reversal');
        NEntries := 0;
        // [WHEN] Using the action "Hide Reversed Entries"
        BankAccReconciliationPage.HideReversedEntries.Invoke();
        // [THEN] There should only the first payment visible
        if not BankAccReconciliationPage.ApplyBankLedgerEntries.First() then
            Error('No visible bank ledger entries found');
        repeat
            NEntries += 1;
            Evaluate(VisibleAmount, BankAccReconciliationPage.ApplyBankLedgerEntries.Amount.Value());
        until not BankAccReconciliationPage.ApplyBankLedgerEntries.Next();
        Assert.AreEqual(1, NEntries, 'Only one bank ledger entry should be visible');
        Assert.AreEqual(FirstAmount, -VisibleAmount, 'The visible entry should be the non-reversed one');
    end;

    [Test]
    procedure DeleteAMatchedBankRecLineFromPageShouldUnmatchIt()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        BankAccReconciliationPage: TestPage "Bank Acc. Reconciliation";
        BankAccountNo: Code[20];
    begin
        // [SCENARIO] A user deletes a reconciliation line created from the Bank Reconciliation page that was matched to an open bank entry. The Bank Ledger Entry should be unmatched.
        // [GIVEN] A bank reconciliation with a matched Bank Account Reconciliation Line
        BankAccountNo := CreateBankAccount();
        CreateAndPostGenJournalLine(GenJournalLine, BankAccountNo);
        LibraryERM.CreateBankAccReconciliation(BankAccReconciliation, BankAccountNo, BankAccReconciliation."Statement Type"::"Bank Reconciliation");
        BankAccReconciliationLine.Init();
        BankAccReconciliationLine."Statement Type" := BankAccReconciliationLine."Statement Type"::"Bank Reconciliation";
        BankAccReconciliationLine."Bank Account No." := BankAccountNo;
        BankAccReconciliationLine."Statement No." := BankAccReconciliation."Statement No.";
        BankAccReconciliationLine."Statement Line No." := 1000;
        BankAccReconciliationLine.Validate("Statement Amount", -GenJournalLine.Amount);
        BankAccReconciliationLine.Insert();
        BankAccReconciliationPage.OpenView();
        BankAccReconciliationPage.GoToRecord(BankAccReconciliation);
        BankAccReconciliationPage.ApplyBankLedgerEntries.First();
        BankAccReconciliationPage.StmtLine.First();
        BankAccReconciliationPage.MatchManually.Invoke();
        BankAccountLedgerEntry.SetRange("Bank Account No.", BankAccountNo);
        BankAccountLedgerEntry.FindFirst();
        Assert.AreEqual(BankAccountLedgerEntry."Statement Status"::"Bank Acc. Entry Applied", BankAccountLedgerEntry."Statement Status", 'Bank entry should be applied');
        Assert.AreEqual(BankAccReconciliation."Statement No.", BankAccountLedgerEntry."Statement No.", 'Statement No. should be the current statement');
        Assert.AreEqual(BankAccReconciliationLine."Statement Line No.", BankAccountLedgerEntry."Statement Line No.", 'Statement Line No. should be the current line');
        // [WHEN] The matched line gets deleted
        BankAccReconciliationLine.Delete(true);
        // [THEN] The bank ledger entry should be unmatched
        BankAccReconciliationPage.ApplyBankLedgerEntries.First();
        BankAccountLedgerEntry.SetRecFilter();
        BankAccountLedgerEntry.FindFirst();
        Assert.AreEqual(BankAccountLedgerEntry."Statement Status"::Open, BankAccountLedgerEntry."Statement Status", 'Bank entry should be open');
        Assert.AreEqual('', BankAccountLedgerEntry."Statement No.", 'Statement No. should be empty');
        Assert.AreEqual(0, BankAccountLedgerEntry."Statement Line No.", 'Statement Line No. should be empty');
    end;

    [Test]
    procedure AddingABankRecLineBeforeAnExistingLineShouldHaveASmallerLineNumber()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccReconciliationPage: TestPage "Bank Acc. Reconciliation";
        BankAccountNo: Code[20];
        LineNo1: Integer;
        LineNo2: Integer;
    begin
        Initialize();
        // [SCENARIO] A user adds a line, and then another before this. The statement line number of the new line should be smaller and the field "Balance" should accumulate with respect to the Statement Line No.
        // [GIVEN] A bank reconciliation
        BankAccountNo := CreateBankAccount();
        LibraryERM.CreateBankAccReconciliation(BankAccReconciliation, BankAccountNo, BankAccReconciliation."Statement Type"::"Bank Reconciliation");
        BankAccReconciliationPage.OpenEdit();
        BankAccReconciliationPage.GoToRecord(BankAccReconciliation);
        // [GIVEN] A reconciliation line A
        BankAccReconciliationPage.StmtLine.New();
        BankAccReconciliationPage.StmtLine.Description.Value := 'empty';
        BankAccReconciliationPage.StmtLine.New();
        BankAccReconciliationPage.StmtLine.Description.Value('001');
        BankAccReconciliationPage.StmtLine."Statement Amount".Value('1000');
        // [WHEN] A reconciliation line B inserted above A
        BankAccReconciliationPage.StmtLine.Previous();
        BankAccReconciliationPage.StmtLine.Description.Value('002');
        BankAccReconciliationPage.StmtLine."Statement Amount".Value('500');
        // [THEN] The Balance field is just the value of the current line
        Assert.AreEqual(500, BankAccReconciliationPage.StmtLine.Balance.AsDecimal(), 'The new line should update the Balance field with just its value');
        BankAccReconciliationPage.Close();
        BankAccReconciliationLine.SetRange("Statement No.", BankAccReconciliation."Statement No.");
        BankAccReconciliationLine.SetRange("Statement Type", BankAccReconciliationLine."Statement Type"::"Bank Reconciliation");
        BankAccReconciliationLine.SetRange("Bank Account No.", BankAccountNo);
        BankAccReconciliationLine.SetRange(Description, '001');
        BankAccReconciliationLine.FindFirst();
        LineNo1 := BankAccReconciliationLine."Statement Line No.";
        BankAccReconciliationLine.SetRange(Description, '002');
        BankAccReconciliationLine.FindFirst();
        LineNo2 := BankAccReconciliationLine."Statement Line No.";
        // [THEN] the line above should have a smaller Statement Line No
        Assert.IsTrue(LineNo2 < LineNo1, 'A line inserted above should have a smaller statement line no.');
    end;

    [Test]
    procedure BankReconciliationPageChangingStatementDateShouldNotRemoveOrUnmatchEntriesAndCanBePosted()
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationPage: TestPage "Bank Acc. Reconciliation";
        BankAccountNo: Code[20];
    begin
        // [SCENARIO] A user has entries matched on a future date, and then changes the statement date to a date before the entries.
        // [GIVEN] A bank reconciliation with a matched entry
        BankAccountNo := CreateBankAccount();
        CreateAndPostGenJournalLine(GenJournalLine, BankAccountNo);
        LibraryERM.CreateBankAccReconciliation(BankAccReconciliation, BankAccountNo, BankAccReconciliation."Statement Type"::"Bank Reconciliation");
        BankAccReconciliation."Statement Date" := WorkDate() + 5;
        SuggestLines(BankAccReconciliation);
        BankAccReconciliation.Validate("Statement Ending Balance", BankAccReconciliation."Balance Last Statement" + BankAccRecSum(BankAccReconciliation));
        BankAccReconciliation.Modify(true);
        // [WHEN] Changing the statement date from the Bank Reconciliation page
        BankAccReconciliationPage.OpenView();
        BankAccReconciliationPage.GoToRecord(BankAccReconciliation);
        BankAccReconciliationPage.StatementDate.Value(Format(WorkDate() - 10));
        BankAccReconciliationPage.Close();
        // [THEN] There should be no warning
        // [THEN] Entries should still be matched
        BankAccountLedgerEntry.SetRange("Bank Account No.", BankAccountNo);
        BankAccountLedgerEntry.SetRange("Statement No.", '');
        Assert.IsTrue(BankAccountLedgerEntry.IsEmpty(), 'There should be no open entries');
        // [THEN] It should be possible to post
        LibraryERM.PostBankAccReconciliation(BankAccReconciliation);
    end;

    [Test]
    [HandlerFunctions('SuggestLinesRequestPageHandler')]
    procedure SuggestLinesActionForBankWithAutomatchingDisabled()
    var
        BankAccount: Record "Bank Account";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        GenJournalLine: Record "Gen. Journal Line";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        BankAccReconciliationPage: TestPage "Bank Acc. Reconciliation";
        NEntries: Integer;
    begin
        Initialize();
        // [SCENARIO] Suggest lines is run from the bank reconciliation page for a bank with automatch disabled should not apply entries and have the difference values computed accordingly
        // [GIVEN] A bank account with automatching disabled
        CreateBankAccount(BankAccount);
        BankAccount."Disable Automatic Pmt Matching" := true;
        BankAccount.Modify(true);
        // [GIVEN] 5 Bank Account Ledger Entries made on this bank account
        CreateAndPostGenJournalLine(GenJournalLine, BankAccount."No.");
        CreateAndPostGenJournalLine(GenJournalLine, BankAccount."No.");
        CreateAndPostGenJournalLine(GenJournalLine, BankAccount."No.");
        CreateAndPostGenJournalLine(GenJournalLine, BankAccount."No.");
        CreateAndPostGenJournalLine(GenJournalLine, BankAccount."No.");
        // [WHEN] Running suggest lines in the Bank Account Reconciliation page
        LibraryERM.CreateBankAccReconciliation(BankAccReconciliation, BankAccount."No.", BankAccReconciliation."Statement Type"::"Bank Reconciliation");
        BankAccReconciliation."Statement Date" := WorkDate() + 5;
        BankAccReconciliation.Modify();
        Commit();
        BankAccReconciliationPage.OpenView();
        BankAccReconciliationPage.GoToRecord(BankAccReconciliation);
        BankAccReconciliationPage.SuggestLines.Invoke();
        // [THEN] The entries suggested are not applied
        BankAccReconciliationLine.SetRange("Statement No.", BankAccReconciliation."Statement No.");
        BankAccReconciliationLine.SetRange("Statement Type", BankAccReconciliation."Statement Type"::"Bank Reconciliation");
        BankAccReconciliationLine.SetRange("Bank Account No.", BankAccount."No.");
        BankAccReconciliationLine.FindSet();
        repeat
            Assert.AreEqual(0, BankAccReconciliationLine."Applied Amount", 'Lines should have 0 as amount applied');
            Assert.AreEqual(BankAccReconciliationLine."Statement Amount", BankAccReconciliationLine.Difference, 'The difference should be the same as the statement amount');
            Assert.AreNotEqual(0, BankAccReconciliationLine."Statement Amount", 'Amounts should not be zero');
            NEntries += 1;
        until BankAccReconciliationLine.Next() = 0;
        Assert.AreEqual(NEntries, 5, 'All the payments should be suggested.');
        BankAccountLedgerEntry.SetRange("Bank Account No.", BankAccount."No.");
        BankAccountLedgerEntry.SetFilter("Statement Status", '<>%1', BankAccountLedgerEntry."Statement Status"::Open);
        Assert.IsTrue(BankAccountLedgerEntry.IsEmpty(), 'There should be no Bank Ledger Entry applied');
    end;

    [Test]
    procedure TransferingToGLEntryForMatchedBankRecLineShouldError()
    var
        GenJournalLine: Record "Gen. Journal Line";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationPage: TestPage "Bank Acc. Reconciliation";
        BankAccountNo: Code[20];
    begin
        // [SCENARIO] Running Tranfer Difference to GL Entry on a matched line should fail
        Initialize();
        // [GIVEN] A bank reconciliation with a line matched
        BankAccountNo := CreateBankAccount();
        CreateAndPostGenJournalLine(GenJournalLine, BankAccountNo);
        LibraryERM.CreateBankAccReconciliation(BankAccReconciliation, BankAccountNo, BankAccReconciliation."Statement Type"::"Bank Reconciliation");
        BankAccReconciliation."Statement Date" := WorkDate() + 5;
        SuggestLines(BankAccReconciliation);
        // [WHEN] Attempting to tranfer difference to G/L entry
        BankAccReconciliationPage.OpenView();
        BankAccReconciliationPage.GoToRecord(BankAccReconciliation);
        // [THEN] The user should be blocked
        asserterror BankAccReconciliationPage.SuggestLines.Invoke();
    end;

    [Test]
    [HandlerFunctions('ChangeStatementNoModalPageHandler')]
    procedure ChangeStatementNoForAReconciliationWithCheckEntriesCanBePosted()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        CheckLedgerEntry: Record "Check Ledger Entry";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        Vendor: Record Vendor;
        BankAccReconciliationPage: TestPage "Bank Acc. Reconciliation";
        BankAccReconciliationPage2: TestPage "Bank Acc. Reconciliation";
        BankAccountNo: Code[20];
    begin
        Initialize();
        // [SCENARIO] A bank reconciliation with matched lines to Check entries can use the action "Change Statement No" and post afterwards
        // [GIVEN] A bank
        BankAccountNo := CreateBankAccount();
        // [GIVEN] A posted check for that bank
        LibraryPurchase.CreateVendor(Vendor);
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        GenJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        GenJournalBatch.Validate("Bal. Account Type", GenJournalBatch."Bal. Account Type"::"Bank Account");
        GenJournalBatch.Validate("Bal. Account No.", BankAccountNo);
        GenJournalBatch.Modify(true);
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Vendor, Vendor."No.", LibraryRandom.RandDec(500, 2));
        GenJournalLine.Validate("Bank Payment Type", GenJournalLine."Bank Payment Type"::"Manual Check");
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        // [GIVEN] A bank reconciliation for this bank with entries matched
        LibraryERM.CreateBankAccReconciliation(BankAccReconciliation, BankAccountNo, BankAccReconciliation."Statement Type"::"Bank Reconciliation");
        BankAccReconciliation."Statement Date" := WorkDate() + 5;
        SuggestLines(BankAccReconciliation);
        // [WHEN] Running "Change Statement No."
        BankAccReconciliationPage.OpenView();
        BankAccReconciliationPage.GoToRecord(BankAccReconciliation);
        LibraryVariableStorage.Enqueue('NEWNO');
        BankAccReconciliationPage2.Trap();
        BankAccReconciliationPage.ChangeStatementNo.Invoke();
        // [THEN] Bank and Check Entries should change
        BankAccountLedgerEntry.SetRange("Bank Account No.", BankAccountNo);
        BankAccountLedgerEntry.FindFirst();
        Assert.AreEqual(-GenJournalLine.Amount, BankAccountLedgerEntry.Amount, 'Amounts should be the same as posted');
        Assert.AreEqual(BankAccountLedgerEntry."Statement Status"::"Bank Acc. Entry Applied", BankAccountLedgerEntry."Statement Status", 'Statement Status of Bank Entry should be Bank Applied');
        Assert.AreEqual(BankAccountLedgerEntry."Statement No.", 'NEWNO', 'Statement No of Bank Entry should be updated');
        CheckLedgerEntry.SetRange("Bank Account Ledger Entry No.", BankAccountLedgerEntry."Entry No.");
        CheckLedgerEntry.FindFirst();
        Assert.AreEqual(CheckLedgerEntry."Statement No.", 'NEWNO', 'Statement No of Check Entry should be updated');
        Assert.AreEqual(CheckLedgerEntry."Statement Status", CheckLedgerEntry."Statement Status"::"Bank Acc. Entry Applied", 'Statement Status of Check Entry should be Bank Applied');
    end;

    [Test]
    [HandlerFunctions('SameBankReconciliationConfirmHandler')]
    procedure TwoBankReconciliationsFromSameBankWarnsAndDeletesIfConfirmed()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationPage: TestPage "Bank Acc. Reconciliation";
        BankAccountNo: Code[20];
    begin
        Initialize();
        // [SCENARIO] A user creates a bank reconciliation, they then open to create another reconciliation for the same bank. They should be warned about an ongoing bank reconciliation and if they decide to, delete the new one
        // [GIVEN] A bank
        BankAccountNo := CreateBankAccount();
        // [GIVEN] A bank reconciliation for the bank
        LibraryERM.CreateBankAccReconciliation(BankAccReconciliation, BankAccountNo, BankAccReconciliation."Statement Type"::"Bank Reconciliation");
        // [WHEN] The user tries to create a new bank reconciliation for that bank
        BankAccReconciliationPage.OpenNew();
        BankAccReconciliationPage.BankAccountNo.SetValue(BankAccountNo);
        BankAccReconciliationPage.Close();
        // [THEN] A confirmation is asked to continue
        // [WHEN] The user decides not to continue (message handler)
        // [THEN] There is only one bank rec. for this bank
        BankAccReconciliation.Reset();
        BankAccReconciliation.SetRange("Bank Account No.", BankAccountNo);
        Assert.AreEqual(1, BankAccReconciliation.Count(), 'There should only be one bank reconciliation if the user doesn''t continue');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure TwoBankReconciliationsFromSameBankWarnsDoesntDeletesIfNotConfirmed()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationPage: TestPage "Bank Acc. Reconciliation";
        BankAccountNo: Code[20];
    begin
        Initialize();
        // [SCENARIO] A user creates a bank reconciliation, they then open to create another reconciliation for the same bank. They should be warned about an ongoing bank reconciliation but if they continue they should not be deleted
        // [GIVEN] A bank
        BankAccountNo := CreateBankAccount();
        // [GIVEN] A bank reconciliation for the bank
        LibraryERM.CreateBankAccReconciliation(BankAccReconciliation, BankAccountNo, BankAccReconciliation."Statement Type"::"Bank Reconciliation");
        // [WHEN] The user tries to create a new bank reconciliation for that bank
        BankAccReconciliationPage.OpenNew();
        BankAccReconciliationPage.BankAccountNo.Value(BankAccountNo);
        // [THEN] A confirmation is asked to continue
        // [WHEN] The user decides to continue (message handler)
        // [THEN] There is only one bank rec. for this bank
        BankAccReconciliationPage.Close();
        BankAccReconciliation.Reset();
        BankAccReconciliation.SetRange("Bank Account No.", BankAccountNo);
        Assert.AreEqual(2, BankAccReconciliation.Count(), 'There should be two bank reconciliations if the user continues');
    end;

    [Test]
    procedure TwoBankReconciliationsFromDifferentBanksShouldntWarn()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationPage: TestPage "Bank Acc. Reconciliation";
        BankAccountNo: Code[20];
    begin
        Initialize();
        // [SCENARIO] A user creates a bank reconciliation, they then open to create another reconciliation for the same bank. They should be warned about an ongoing bank reconciliation but if they continue they should not be deleted
        // [GIVEN] A bank
        BankAccountNo := CreateBankAccount();
        // [GIVEN] A bank reconciliation for that bank
        LibraryERM.CreateBankAccReconciliation(BankAccReconciliation, BankAccountNo, BankAccReconciliation."Statement Type"::"Bank Reconciliation");
        // [GIVEN] Another bank
        BankAccountNo := CreateBankAccount();

        // [WHEN] The user tries to create a new bank reconciliation for the second bank
        BankAccReconciliationPage.OpenNew();
        BankAccReconciliationPage.BankAccountNo.Value(BankAccountNo);
        // [THEN] No message should occur (No MessageHandler)
    end;

    [Test]
    procedure BankReconciliationAndPaymentRecJournalFromSameBankShouldNotWarn()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationPage: TestPage "Bank Acc. Reconciliation";
        BankAccountNo: Code[20];
    begin
        Initialize();
        // [SCENARIO] A user creates a payment rec. journal, and a bank reconciliation. Both for the same bank. No warning should show
        // [GIVEN] A Payment Rec. Journal
        BankAccountNo := CreateBankAccount();
        LibraryERM.CreateBankAccReconciliation(BankAccReconciliation, BankAccountNo, BankAccReconciliation."Statement Type"::"Payment Application");
        // [WHEN] The user tries to create a new bank reconciliation
        BankAccReconciliationPage.OpenNew();
        BankAccReconciliationPage.BankAccountNo.Value(BankAccountNo);
        // [THEN] No message should occur (No MessageHandler)
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    procedure RemovingMatchesForADifferentReconciliationOfTheSameBankShouldWarn()
    var
        GenJournalLine: Record "Gen. Journal Line";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        BankAccReconciliationPage: TestPage "Bank Acc. Reconciliation";
        BankAccountNo: Code[20];
    begin
        // [SCENARIO] After a bank rec with matched lines is created, another bank rec for the same bank is created. Unmatch is run selecting the bank ledger entries. A warning should occur
        // [GIVEN] A bank rec with matched lines
        // [SCENARIO] Running Tranfer Difference to GL Entry on a matched line should fail
        Initialize();
        // [GIVEN] A bank reconciliation with a line matched
        BankAccountNo := CreateBankAccount();
        CreateAndPostGenJournalLine(GenJournalLine, BankAccountNo);
        LibraryERM.CreateBankAccReconciliation(BankAccReconciliation, BankAccountNo, BankAccReconciliation."Statement Type"::"Bank Reconciliation");
        BankAccReconciliation."Statement Date" := WorkDate() + 5;
        SuggestLines(BankAccReconciliation);
        // [GIVEN] Another bank reconciliation for the same bank
        BankAccReconciliation."Statement No." := IncStr(BankAccReconciliation."Statement No.");
        LibraryERM.CreateBankAccReconciliation(BankAccReconciliation, BankAccountNo, BankAccReconciliation."Statement Type"::"Bank Reconciliation");
        // [WHEN] Running RemoveMatch
        BankAccReconciliationPage.OpenView();
        BankAccReconciliationPage.GoToRecord(BankAccReconciliation);
        BankAccReconciliationPage.ApplyBankLedgerEntries.First();
        BankAccReconciliationPage.RemoveMatch.Invoke();
        // [THEN] The user should be warned (MessageHandler)
        // [WHEN] User decides not to continue (MessageHandler)
        // [THEN] No entries should be unmatched
        BankAccountLedgerEntry.SetRange("Bank Account No.", BankAccountNo);
        BankAccountLedgerEntry.SetRange("Statement No.", '');
        Assert.IsTrue(BankAccountLedgerEntry.IsEmpty(), 'No entries should be unmatched');
    end;

    [Test]
    [HandlerFunctions('ChangeStatementNoModalPageHandler')]
    procedure ChangeStatementNoShouldPreserveMatchesForBankReconciliationsWithManyToOne()
    var
        BankAccount: Record "Bank Account";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        BankAccRecMatchBuffer: Record "Bank Acc. Rec. Match Buffer";
        CheckLedgerEntry: Record "Check Ledger Entry";
        BankAccReconciliationPage: TestPage "Bank Acc. Reconciliation";
        BankAccReconciliationPage2: TestPage "Bank Acc. Reconciliation";
        PaymentAmount: Decimal;
    begin
        Initialize();
        // [SCENARIO] Change statement no. is run on a bank reconciliation with a Many to one match
        // [GIVEN] A bank rec with a many to one match to a Check entry
        PaymentAmount := 2 * LibraryRandom.RandDec(1000, 2);
        PostCheck(BankAccount, CreateBankAccount(), PaymentAmount);
        CreateBankReconciliationManyToOne(BankAccReconciliation, BankAccount."No.", PaymentAmount);
        MatchBankReconciliationManyToOne(BankAccReconciliation);
        // [WHEN] Running ChangeStatementNo
        BankAccReconciliationPage.OpenView();
        BankAccReconciliationPage.GoToRecord(BankAccReconciliation);
        LibraryVariableStorage.Enqueue('NEWNO');
        BankAccReconciliationPage2.Trap();
        BankAccReconciliationPage.ChangeStatementNo.Invoke();
        // [THEN] The ManyToOne match should be kept
        BankAccountLedgerEntry.SetRange("Bank Account No.", BankAccount."No.");
        BankAccountLedgerEntry.FindFirst();
        Assert.AreEqual(BankAccountLedgerEntry."Statement No.", 'NEWNO', 'Statement No. of Bank entry not updated');
        Assert.AreEqual(BankAccountLedgerEntry."Statement Line No.", -1, 'Statement Line No. should be set to Many-One default');
        Assert.AreEqual(BankAccountLedgerEntry."Statement Status", BankAccountLedgerEntry."Statement Status"::"Bank Acc. Entry Applied", 'Invalid Statement Status of Bank Ledger Entry');
        CheckLedgerEntry.SetRange("Bank Account No.", BankAccount."No.");
        CheckLedgerEntry.FindFirst();
        Assert.AreEqual(CheckLedgerEntry."Statement Status", CheckLedgerEntry."Statement Status"::"Bank Acc. Entry Applied", 'Invalid Statement Status of Check Ledger Entry');
        Assert.AreEqual(CheckLedgerEntry."Statement No.", 'NEWNO', 'Statement No. of Check entry not updated');
        BankAccRecMatchBuffer.SetRange("Statement No.", 'NEWNO');
        BankAccRecMatchBuffer.SetRange("Bank Account No.", BankAccount."No.");
        Assert.AreEqual(2, BankAccRecMatchBuffer.Count(), 'Entries for the Many to One buffer table should be 2');
    end;

    [Test]
    procedure ManyToManyMatchIsNotSupported()
    var
        BankAccount: Record "Bank Account";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        GenJournalLine: Record "Gen. Journal Line";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        TempBankAccReconciliationLine: Record "Bank Acc. Reconciliation Line" temporary;
        TempBankAccountLedgerEntry: Record "Bank Account Ledger Entry" temporary;
        MatchBankRecLines: Codeunit "Match Bank Rec. Lines";
        BankAccountNo: Code[20];
    begin
        Initialize();
        // [SCENARIO] A user attempts to do a Many to Many match in Bank Reconciliations
        // [GIVEN] A bank account
        BankAccountNo := CreateBankAccount(BankAccount);
        BankAccount."Disable Automatic Pmt Matching" := true;
        BankAccount.Modify();
        // [GIVEN] 2 Bank Account Ledger Entries
        CreateAndPostGenJournalLine(GenJournalLine, BankAccountNo);
        CreateAndPostGenJournalLine(GenJournalLine, BankAccountNo);
        // [GIVEN] A bank reconciliation with two unmatched suggested lines
        LibraryERM.CreateBankAccReconciliation(BankAccReconciliation, BankAccountNo, BankAccReconciliation."Statement Type"::"Bank Reconciliation");
        BankAccReconciliation."Statement Date" := WorkDate() + 5;
        SuggestLines(BankAccReconciliation);
        // [WHEN] Attempting to do a Many to Many match
        BankAccountLedgerEntry.SetRange("Bank Account No.", BankAccountNo);
        BankAccountLedgerEntry.FindSet();
        repeat
            TempBankAccountLedgerEntry.Copy(BankAccountLedgerEntry);
            TempBankAccountLedgerEntry.Insert();
        until BankAccountLedgerEntry.Next() = 0;
        BankAccReconciliationLine.SetRange("Bank Account No.", BankAccountNo);
        BankAccReconciliationLine.SetRange("Statement No.", BankAccReconciliation."Statement No.");
        BankAccReconciliationLine.FindSet();
        repeat
            TempBankAccReconciliationLine.Copy(BankAccReconciliationLine);
            TempBankAccReconciliationLine.Insert();
        until BankAccReconciliationLine.Next() = 0;
        // [THEN] The user should see an error message
        asserterror MatchBankRecLines.MatchManually(TempBankAccReconciliationLine, TempBankAccountLedgerEntry);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo,MessageHandler')]
    procedure RunningAutomatchWithoutOverwriteShouldKeepManualMatch()
    var
        BankAccount: Record "Bank Account";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        TempBankAccountLedgerEntry: Record "Bank Account Ledger Entry" temporary;
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        TempBankAccReconciliationLine: Record "Bank Acc. Reconciliation Line" temporary;
        GenJournalLine: Record "Gen. Journal Line";
        MatchBankRecLines: Codeunit "Match Bank Rec. Lines";
        BankAccountNo: Code[20];
    begin
        // [SCENARIO] Two different Bank entries B_a, B_b, they correspond respectively to Bank Rec Lines R_a, R_b in description and amount (they would be matched by automatch).
        //            the user however decides to match manually B_a with R_b (which wouldn't be done by automatch). The user decides to run automatch without overwriting.
        Initialize();
        // [GIVEN] A bank account
        BankAccountNo := CreateBankAccount(BankAccount);
        BankAccount."Disable Automatic Pmt Matching" := true; // to suggest unmatched lines
        BankAccount.Modify();
        // [GIVEN] 2 Bank ledger entries
        CreateAndPostGenJournalLineWithAmount(GenJournalLine, BankAccountNo, LibraryRandom.RandDecInRange(1000, 2000, 2));
        CreateAndPostGenJournalLineWithAmount(GenJournalLine, BankAccountNo, LibraryRandom.RandDecInRange(9000, 10000, 2));
        // [GIVEN] A bank reconciliation with two unmatched suggested lines
        LibraryERM.CreateBankAccReconciliation(BankAccReconciliation, BankAccountNo, BankAccReconciliation."Statement Type"::"Bank Reconciliation");
        BankAccReconciliation."Statement Date" := WorkDate() + 5;
        SuggestLines(BankAccReconciliation);
        BankAccount."Disable Automatic Pmt Matching" := false;
        BankAccount.Modify();
        // [GIVEN] B_a is matched with R_b
        BankAccountLedgerEntry.SetRange("Bank Account No.", BankAccountNo);
        BankAccountLedgerEntry.SetAscending("Entry No.", true);
        BankAccountLedgerEntry.FindFirst();
        TempBankAccountLedgerEntry.Copy(BankAccountLedgerEntry);
        TempBankAccountLedgerEntry.Insert();
        BankAccReconciliationLine.SetRange("Bank Account No.", BankAccountNo);
        BankAccReconciliationLine.SetRange("Statement No.", BankAccReconciliation."Statement No.");
        BankAccReconciliationLine.SetAscending("Statement Line No.", true);
        BankAccReconciliationLine.FindLast();
        TempBankAccReconciliationLine.Copy(BankAccReconciliationLine);
        TempBankAccReconciliationLine.Insert();
        MatchBankRecLines.MatchManually(TempBankAccReconciliationLine, TempBankAccountLedgerEntry);
        // [WHEN] Running Automatch without overwriting (message handler)
        MatchBankRecLines.BankAccReconciliationAutoMatch(BankAccReconciliation, 0);
        // [THEN] The manual entries should still be matched (B_a with R_b)
        BankAccountLedgerEntry.Reset();
        BankAccountLedgerEntry.SetRange("Bank Account No.", BankAccountNo);
        BankAccountLedgerEntry.SetAscending("Entry No.", true);
        BankAccountLedgerEntry.FindFirst();
        BankAccReconciliationLine.FindFirst();
        BankAccReconciliationLine.SetRange("Bank Account No.", BankAccountNo);
        BankAccReconciliationLine.SetRange("Statement No.", BankAccReconciliation."Statement No.");
        BankAccReconciliationLine.SetAscending("Statement Line No.", true);
        BankAccReconciliationLine.FindLast();
        Assert.AreEqual(BankAccReconciliationLine."Statement Line No.", BankAccountLedgerEntry."Statement Line No.", 'Manual match should be preserved');
        Assert.AreEqual(BankAccountLedgerEntry."Statement Status"::"Bank Acc. Entry Applied", BankAccountLedgerEntry."Statement Status", 'Manual match should be preserved');
        // [THEN] The unmatched entries were not matched by the automatch
        BankAccountLedgerEntry.Reset();
        BankAccountLedgerEntry.SetRange("Bank Account No.", BankAccountNo);
        BankAccountLedgerEntry.SetRange("Statement Status", BankAccountLedgerEntry."Statement Status"::Open);
        Assert.IsFalse(BankAccountLedgerEntry.IsEmpty(), 'There should be an open/unmatched bank ledger entry that was not captured by automatch');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    procedure RunningAutomatchWithOverwriteShouldRemoveManualMatches()
    var
        BankAccount: Record "Bank Account";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        TempBankAccountLedgerEntry: Record "Bank Account Ledger Entry" temporary;
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        TempBankAccReconciliationLine: Record "Bank Acc. Reconciliation Line" temporary;
        GenJournalLine: Record "Gen. Journal Line";
        MatchBankRecLines: Codeunit "Match Bank Rec. Lines";
        BankAccountNo: Code[20];
    begin
        // [SCENARIO] Two different Bank entries B_a, B_b, they correspond respectively to Bank Rec Lines R_a, R_b in description and amount (they would be matched by automatch).
        //            the user however decides to match manually B_a with R_b (which wouldn't be done by automatch). The user decides to run automatch with overwriting.
        Initialize();
        // [GIVEN] A bank account
        BankAccountNo := CreateBankAccount(BankAccount);
        BankAccount."Disable Automatic Pmt Matching" := true; // to suggest unmatched lines
        BankAccount.Modify();
        // [GIVEN] 2 Bank ledger entries
        CreateAndPostGenJournalLineWithAmount(GenJournalLine, BankAccountNo, LibraryRandom.RandDecInRange(1000, 2000, 2));
        CreateAndPostGenJournalLineWithAmount(GenJournalLine, BankAccountNo, LibraryRandom.RandDecInRange(9000, 10000, 2));
        // [GIVEN] A bank reconciliation with two unmatched suggested lines
        LibraryERM.CreateBankAccReconciliation(BankAccReconciliation, BankAccountNo, BankAccReconciliation."Statement Type"::"Bank Reconciliation");
        BankAccReconciliation."Statement Date" := WorkDate() + 5;
        SuggestLines(BankAccReconciliation);
        BankAccount."Disable Automatic Pmt Matching" := false;
        BankAccount.Modify();
        // [GIVEN] B_a is matched with R_b
        BankAccountLedgerEntry.SetRange("Bank Account No.", BankAccountNo);
        BankAccountLedgerEntry.SetAscending("Entry No.", true);
        BankAccountLedgerEntry.FindFirst();
        TempBankAccountLedgerEntry.Copy(BankAccountLedgerEntry);
        TempBankAccountLedgerEntry.Insert();
        BankAccReconciliationLine.SetRange("Bank Account No.", BankAccountNo);
        BankAccReconciliationLine.SetRange("Statement No.", BankAccReconciliation."Statement No.");
        BankAccReconciliationLine.SetAscending("Statement Line No.", true);
        BankAccReconciliationLine.FindLast();
        TempBankAccReconciliationLine.Copy(BankAccReconciliationLine);
        TempBankAccReconciliationLine.Insert();
        MatchBankRecLines.MatchManually(TempBankAccReconciliationLine, TempBankAccountLedgerEntry);
        // [WHEN] Running Automatch with overwriting (message handler)
        MatchBankRecLines.BankAccReconciliationAutoMatch(BankAccReconciliation, 0);
        // [THEN] The right entries should instead be matched
        BankAccountLedgerEntry.Reset();
        BankAccountLedgerEntry.SetRange("Bank Account No.", BankAccountNo);
        BankAccountLedgerEntry.SetAscending("Entry No.", true);
        BankAccountLedgerEntry.FindFirst();
        BankAccReconciliationLine.FindFirst();
        BankAccReconciliationLine.SetRange("Bank Account No.", BankAccountNo);
        BankAccReconciliationLine.SetRange("Statement No.", BankAccReconciliation."Statement No.");
        BankAccReconciliationLine.SetAscending("Statement Line No.", true);
        BankAccReconciliationLine.FindFirst();
        Assert.AreEqual(BankAccReconciliationLine."Statement Line No.", BankAccountLedgerEntry."Statement Line No.", 'Manual match should not be preserved');
        Assert.AreEqual(BankAccountLedgerEntry."Statement Status"::"Bank Acc. Entry Applied", BankAccountLedgerEntry."Statement Status", 'Manual match should not be preserved');
        BankAccountLedgerEntry.Reset();
        BankAccountLedgerEntry.SetRange("Bank Account No.", BankAccountNo);
        BankAccountLedgerEntry.SetRange("Statement Status", BankAccountLedgerEntry."Statement Status"::Open);
        Assert.IsTrue(BankAccountLedgerEntry.IsEmpty(), 'All entries should be matched');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure AutomatchShouldPreferCloseAmountsAfterItInitiallyProposesMatches()
    var
        BankAccount: Record "Bank Account";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        GenJournalLine: Record "Gen. Journal Line";
        MatchBankRecLines: Codeunit "Match Bank Rec. Lines";
        BankAccountNo: Code[20];
    begin
        // [SCENARIO 537300] An acceptable match for a Bank Ledger Entry A is found, afterwards a very good match is found for a different Bank Ledger Entry B is found, a better match for BLE A is in the end. The algorithm should prefer the last BLE match.
        Initialize();
        // [GIVEN] Two different Bank Ledger Entries.
        BankAccountNo := CreateBankAccount(BankAccount);
        CreateAndPostGenJournalLineWithAmount(GenJournalLine, BankAccountNo, 73600);
        CreateAndPostGenJournalLineWithAmount(GenJournalLine, BankAccountNo, 600);
        // [GIVEN] A Bank Reconciliation with the first line close to the first BLE, the second line matching exactly the second BLE, and a better match for the first BLE.
        LibraryERM.CreateBankAccReconciliation(BankAccReconciliation, BankAccountNo, BankAccReconciliation."Statement Type"::"Bank Reconciliation");
        BankAccReconciliation."Statement Date" := WorkDate();
        BankAccReconciliation.Modify();
        LibraryERM.CreateBankAccReconciliationLn(BankAccReconciliationLine, BankAccReconciliation);
        BankAccReconciliationLine.Validate("Statement Amount", -73590);
        BankAccReconciliationLine.Description := CopyStr(GenJournalLine."Document No.", 1, 5);
        BankAccReconciliationLine.Modify();
        LibraryERM.CreateBankAccReconciliationLn(BankAccReconciliationLine, BankAccReconciliation);
        BankAccReconciliationLine.Validate("Statement Amount", -600);
        BankAccReconciliationLine.Description := GenJournalLine."Document No.";
        BankAccReconciliationLine.Modify();
        LibraryERM.CreateBankAccReconciliationLn(BankAccReconciliationLine, BankAccReconciliation);
        BankAccReconciliationLine.Validate("Statement Amount", -73600);
        BankAccReconciliationLine.Modify();
        // [WHEN] Running the automatch.
        MatchBankRecLines.BankAccReconciliationAutoMatch(BankAccReconciliation, 1);
        BankAccountLedgerEntry.SetRange("Bank Account No.", BankAccountNo);
        BankAccountLedgerEntry.SetFilter("Statement No.", '<>%1', '');
        Assert.AreEqual(2, BankAccountLedgerEntry.Count(), 'There should be two entries matched');
        BankAccountLedgerEntry.FindSet();
        BankAccReconciliationLine.Get(BankAccReconciliation."Statement Type", BankAccountNo, BankAccReconciliation."Statement No.", BankAccountLedgerEntry."Statement Line No.");
        // [THEN]  The best matches should be suggested.
        Assert.AreEqual(0, BankAccReconciliationLine.Difference, 'The difference should be 0');
        BankAccountLedgerEntry.Next();
        BankAccReconciliationLine.Get(BankAccReconciliation."Statement Type", BankAccountNo, BankAccReconciliation."Statement No.", BankAccountLedgerEntry."Statement Line No.");
        Assert.AreEqual(0, BankAccReconciliationLine.Difference, 'The difference should be 0');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure AutomatchShouldPreferLeastDifferenceInAmountForEntriesWithSameDescription()
    var
        BankAccount: Record "Bank Account";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        GenJournalLine: Record "Gen. Journal Line";
        MatchBankRecLines: Codeunit "Match Bank Rec. Lines";
        BankAccountNo: Code[20];
        CloseAmountLineNo: Integer;
    begin
        // [SCENARIO] When running automatch on lines that have the same description, and the same description as a BLE Document No. Least difference with the amount should be suggested
        Initialize();
        // [GIVEN] A Bank Account
        BankAccountNo := CreateBankAccount(BankAccount);
        // [GIVEN] A bank ledger entry of value 600
        CreateAndPostGenJournalLineWithAmount(GenJournalLine, BankAccountNo, -600);
        // [GIVEN] A bank reconciliation
        LibraryERM.CreateBankAccReconciliation(BankAccReconciliation, BankAccountNo, BankAccReconciliation."Statement Type"::"Bank Reconciliation");
        BankAccReconciliation."Statement Date" := WorkDate();
        BankAccReconciliation.Modify();
        // [GIVEN] A bank reconciliation line with statement amount further to 600: 3550 and description as DocumentNo to produce an acceptable match
        LibraryERM.CreateBankAccReconciliationLn(BankAccReconciliationLine, BankAccReconciliation);
        BankAccReconciliationLine.Validate("Statement Amount", 3550);
        BankAccReconciliationLine.Description := GenJournalLine."Document No.";
        BankAccReconciliationLine.Modify();
        // [GIVEN] A bank reconciliation line with statement amount close to 600: 550 and description as DocumentNo to produce an acceptable match
        LibraryERM.CreateBankAccReconciliationLn(BankAccReconciliationLine, BankAccReconciliation);
        BankAccReconciliationLine.Validate("Statement Amount", 550);
        BankAccReconciliationLine.Description := GenJournalLine."Document No.";
        BankAccReconciliationLine.Modify();
        CloseAmountLineNo := BankAccReconciliationLine."Statement Line No.";
        // [GIVEN] A bank reconciliation line with statement amount further to 600: 1550 and description as DocumentNo to produce an acceptable match
        LibraryERM.CreateBankAccReconciliationLn(BankAccReconciliationLine, BankAccReconciliation);
        BankAccReconciliationLine.Validate("Statement Amount", 1550);
        BankAccReconciliationLine.Description := GenJournalLine."Document No.";
        BankAccReconciliationLine.Modify();
        // [WHEN] Running automatch for this statement
        MatchBankRecLines.BankAccReconciliationAutoMatch(BankAccReconciliation, 0);
        // [THEN] The line matched should be the one with 550
        BankAccountLedgerEntry.SetRange("Bank Account No.", BankAccountNo);
        BankAccountLedgerEntry.FindFirst();
        Assert.AreEqual(BankAccountLedgerEntry."Statement Status"::"Bank Acc. Entry Applied", BankAccountLedgerEntry."Statement Status", 'Entry should have been matched');
        Assert.AreEqual(CloseAmountLineNo, BankAccountLedgerEntry."Statement Line No.", 'Bank entry should be matched to the entry with amount closest to it''s own');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure AutomatchForCheckEntriesConsidersDocNo()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        Vendor: Record Vendor;
        MatchBankRecLines: Codeunit "Match Bank Rec. Lines";
        BankAccountNo: Code[20];
        Amount: Decimal;
        StatementLineNoC01: Integer;
        StatementLineNoC02: Integer;
        StatementLineNoC03: Integer;
        StatementLineNoC04: Integer;
    begin
        Initialize();
        // [SCENARIO] A bank with 4 check ledger entries with same amount and statement date. Automatch should consider Doc. No. to match these
        // [GIVEN] A bank
        BankAccountNo := CreateBankAccount();
        LibraryPurchase.CreateVendor(Vendor);
        Amount := LibraryRandom.RandDec(500, 2);
        // [GIVEN] 4 checks for this bank, same date, vendor, amount. Different Doc. Nos
        PostCheck(Vendor, BankAccountNo, Amount, 'C001');
        PostCheck(Vendor, BankAccountNo, Amount, 'C002');
        PostCheck(Vendor, BankAccountNo, Amount, 'C003');
        PostCheck(Vendor, BankAccountNo, Amount, 'C004');
        // [GIVEN] A bank reconciliation with 4 lines with this amount, and description with similar text as the document no.s (revert order to test it actually find them)
        LibraryERM.CreateBankAccReconciliation(BankAccReconciliation, BankAccountNo, BankAccReconciliation."Statement Type"::"Bank Reconciliation");
        LibraryERM.CreateBankAccReconciliationLn(BankAccReconciliationLine, BankAccReconciliation);
        BankAccReconciliationLine.Validate("Statement Amount", -Amount);
        BankAccReconciliationLine.Description := 'Check C004';
        BankAccReconciliationLine.Modify();
        StatementLineNoC04 := BankAccReconciliationLine."Statement Line No.";
        LibraryERM.CreateBankAccReconciliationLn(BankAccReconciliationLine, BankAccReconciliation);
        BankAccReconciliationLine.Validate("Statement Amount", -Amount);
        BankAccReconciliationLine.Description := 'Check C003';
        BankAccReconciliationLine.Modify();
        StatementLineNoC03 := BankAccReconciliationLine."Statement Line No.";
        LibraryERM.CreateBankAccReconciliationLn(BankAccReconciliationLine, BankAccReconciliation);
        BankAccReconciliationLine.Validate("Statement Amount", -Amount);
        BankAccReconciliationLine.Description := 'Check C002';
        BankAccReconciliationLine.Modify();
        StatementLineNoC02 := BankAccReconciliationLine."Statement Line No.";
        LibraryERM.CreateBankAccReconciliationLn(BankAccReconciliationLine, BankAccReconciliation);
        BankAccReconciliationLine.Validate("Statement Amount", -Amount);
        BankAccReconciliationLine.Description := 'Check C001';
        BankAccReconciliationLine.Modify();
        StatementLineNoC01 := BankAccReconciliationLine."Statement Line No.";
        // [WHEN] Running automatch
        MatchBankRecLines.BankAccReconciliationAutoMatch(BankAccReconciliation, 0);
        // [THEN] The entries should be matched based on the Doc. No
        BankAccountLedgerEntry.SetRange("Bank Account No.", BankAccountNo);
        BankAccountLedgerEntry.SetRange("Document No.", 'C001');
        BankAccountLedgerEntry.FindFirst();
        Assert.AreEqual(BankAccountLedgerEntry."Statement Status"::"Bank Acc. Entry Applied", BankAccountLedgerEntry."Statement Status", 'BLE should be applied');
        Assert.AreEqual(BankAccountLedgerEntry."Statement No.", BankAccReconciliation."Statement No.", 'BLE should be applied in this statement no');
        Assert.AreEqual(StatementLineNoC01, BankAccountLedgerEntry."Statement Line No.", 'Automatched to the wrong entry');
        BankAccountLedgerEntry.SetRange("Document No.", 'C002');
        BankAccountLedgerEntry.FindFirst();
        Assert.AreEqual(BankAccountLedgerEntry."Statement Status"::"Bank Acc. Entry Applied", BankAccountLedgerEntry."Statement Status", 'BLE should be applied');
        Assert.AreEqual(BankAccountLedgerEntry."Statement No.", BankAccReconciliation."Statement No.", 'BLE should be applied in this statement no');
        Assert.AreEqual(StatementLineNoC02, BankAccountLedgerEntry."Statement Line No.", 'Automatched to the wrong entry');
        BankAccountLedgerEntry.SetRange("Document No.", 'C003');
        BankAccountLedgerEntry.FindFirst();
        Assert.AreEqual(BankAccountLedgerEntry."Statement Status"::"Bank Acc. Entry Applied", BankAccountLedgerEntry."Statement Status", 'BLE should be applied');
        Assert.AreEqual(BankAccountLedgerEntry."Statement No.", BankAccReconciliation."Statement No.", 'BLE should be applied in this statement no');
        Assert.AreEqual(StatementLineNoC03, BankAccountLedgerEntry."Statement Line No.", 'Automatched to the wrong entry');
        BankAccountLedgerEntry.SetRange("Document No.", 'C004');
        BankAccountLedgerEntry.FindFirst();
        Assert.AreEqual(BankAccountLedgerEntry."Statement Status"::"Bank Acc. Entry Applied", BankAccountLedgerEntry."Statement Status", 'BLE should be applied');
        Assert.AreEqual(BankAccountLedgerEntry."Statement No.", BankAccReconciliation."Statement No.", 'BLE should be applied in this statement no');
        Assert.AreEqual(StatementLineNoC04, BankAccountLedgerEntry."Statement Line No.", 'Automatched to the wrong entry');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure AutomatchWithTwoSimilarBankEntriesShouldPreferClosestAmount()
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        GenJournalLine: Record "Gen. Journal Line";
        MatchBankRecLines: Codeunit "Match Bank Rec. Lines";
        BankAccountNo: Code[20];
    begin
        Initialize();
        // [SCENARIO] Two bank ledger entries from the same bank, amounts close. Automatch is run for a similar line
        // [GIVEN] A bank with two payments
        BankAccountNo := CreateBankAccount();
        CreateGenJournalLineWithAmount(GenJournalLine, BankAccountNo, 710);
        GenJournalLine."Document No." := 'BANKSN000000000532';
        GenJournalLine.Modify();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        CreateGenJournalLineWithAmount(GenJournalLine, BankAccountNo, 720);
        GenJournalLine."Document No." := 'BANKSN000000000533';
        GenJournalLine.Modify();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        // [GIVEN] A bank reconciliation with a line with similar amount (slightly above 720)
        LibraryERM.CreateBankAccReconciliation(BankAccReconciliation, BankAccountNo, BankAccReconciliation."Statement Type"::"Bank Reconciliation");
        LibraryERM.CreateBankAccReconciliationLn(BankAccReconciliationLine, BankAccReconciliation);
        BankAccReconciliationLine.Validate("Statement Amount", -730);
        BankAccReconciliationLine.Description := 'BANKSN00000000053';
        BankAccReconciliationLine.Modify();
        // [WHEN] Running automatch
        MatchBankRecLines.BankAccReconciliationAutoMatch(BankAccReconciliation, 0);
        // [THEN] The line should be matched to the entry
        BankAccountLedgerEntry.SetRange(Amount, -720);
        BankAccountLedgerEntry.SetRange("Bank Account No.", BankAccountNo);
        BankAccountLedgerEntry.FindFirst();
        Assert.AreEqual(BankAccountLedgerEntry."Statement Status"::"Bank Acc. Entry Applied", BankAccountLedgerEntry."Statement Status", 'BLE should be applied');
        Assert.AreEqual(BankAccReconciliation."Statement No.", BankAccountLedgerEntry."Statement No.", 'Applied in the wrong statement');
        Assert.AreEqual(BankAccReconciliationLine."Statement Line No.", BankAccountLedgerEntry."Statement Line No.", 'Applied to the wrong line no.');
    end;

    local procedure PostCheck(var Vendor: Record Vendor; BankAccountNo: Code[20]; Amount: Decimal; DocNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        GenJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        GenJournalBatch.Validate("Bal. Account Type", GenJournalBatch."Bal. Account Type"::"Bank Account");
        GenJournalBatch.Validate("Bal. Account No.", BankAccountNo);
        GenJournalBatch.Modify(true);
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Vendor, Vendor."No.", Amount);
        GenJournalLine.Validate("Bank Payment Type", GenJournalLine."Bank Payment Type"::"Manual Check");
        GenJournalLine.Validate("Document No.", DocNo);

        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    procedure VerifyRemainingAmountOnPaymentReco()
    var
        BankAccountStatement: Record "Bank Account Statement";
        Vendor: Record Vendor;
        BankAccount: Record "Bank Account";
        GenJournalBatch: Record "Gen. Journal Batch";
        BankAccLedgEntry: Record "Bank Account Ledger Entry";
        GenJournalLine: array[5] of Record "Gen. Journal Line";
        LastStatementNo: array[5] of Code[20];
        StatementNo: Code[20];
        EndingBalance: Decimal;
        EndingBalanceBefore: Decimal;
        Index: Integer;
    begin
        // [SCENARIO 439203] Ensure that Remining amount of Bank ledger entry when it is applied from reconciliation journal
        Initialize();

        // [GIVEN] Create a new vendor, bank
        LibraryERM.CreateBankAccount(BankAccount);
        LibraryPurchase.CreateVendor(Vendor);

        LastStatementNo[1] := '0';
        LastStatementNo[2] := '1';
        LastStatementNo[3] := '2';
        LastStatementNo[4] := '22';
        LastStatementNo[5] := '32';

        // [GIVEN] Create and post a journal
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        GenJournalBatch.Validate("Bal. Account Type", GenJournalBatch."Bal. Account Type"::"Bank Account");
        GenJournalBatch.Validate("Bal. Account No.", BankAccount."No.");
        GenJournalBatch.Modify(true);

        for Index := 1 to ArrayLen(GenJournalLine) do begin
            LibraryERM.CreateGeneralJnlLine(
                GenJournalLine[Index],
                GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine[Index]."Document Type"::Payment,
                GenJournalLine[Index]."Account Type"::Vendor, Vendor."No.",
                LibraryRandom.RandIntInRange(100, 200));
            GenJournalLine[Index].Validate("Posting Date", DMY2Date(1, Index, 2021));
            GenJournalLine[Index].Modify(true);
            LibraryERM.PostGeneralJnlLine(GenJournalLine[Index]);
        end;

        // [WHEN] Apply and post payment reconciliation journal
        EndingBalance := 0;
        for Index := 1 to ArrayLen(GenJournalLine) do begin
            EndingBalanceBefore := EndingBalance;
            ManualApplyAndPostBankAccountReconciliation(BankAccount, LastStatementNo[Index], Vendor, GenJournalLine[Index], EndingBalance);
            BankAccount.Find();
            StatementNo := LastStatementNo[Index];
            StatementNo := IncStr(StatementNo);
            BankAccount.TestField("Last Statement No.", StatementNo);
            BankAccount.TestField("Balance Last Statement", -EndingBalance);

            BankAccountStatement.Get(BankAccount."No.", StatementNo);
            BankAccountStatement.TestField("Balance Last Statement", -EndingBalanceBefore);
            BankAccountStatement.TestField("Statement Ending Balance", -EndingBalance);
        end;

        // [THEN] Remaining amountof Bank ledger entry must be zero.
        BankAccLedgEntry.SetRange("Bank Account No.", BankAccount."No.");
        BankAccLedgEntry.SetFilter("Remaining Amount", '<>%1', 0);
        Assert.RecordIsEmpty(BankAccLedgEntry);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure ImportDuplicatedTransactionsWhenNotAllowed()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
        TempBankAccReconLine: Record "Bank Acc. Reconciliation Line" temporary;
        ProcessBankAccRecLines: Codeunit "Process Bank Acc. Rec Lines";
        TransactionIDList: List of [Text[50]];
        NumberOfLinesImported: Integer;
    begin
        // [SCENARIO 458159] Import transactions with the same Transaction ID when "Allow Duplicated Transactions" not set.
        Initialize();

        // [GIVEN] Bank Account Reconciliation with Allow Duplicated Transactions = false (default).
        LibraryERM.CreateBankAccReconciliation(
            BankAccReconciliation, CreateBankAccount(), BankAccReconciliation."Statement Type"::"Bank Reconciliation");

        // [GIVEN] Three transactions to import. Two of them has the same Transaction ID.
        TransactionIDList.Add('Transaction A');
        TransactionIDList.Add('Transaction B');
        TransactionIDList.Add('Transaction A');
        MockTransactionsToImport(TempBankAccReconLine, BankAccReconciliation, TransactionIDList);

        // [WHEN] Import transactions.
        ProcessBankAccRecLines.InsertNonReconciledOrImportedLines(
            TempBankAccReconLine, ProcessBankAccRecLines.GetLastStatementLineNo(BankAccReconciliation), NumberOfLinesImported);

        // [THEN] Two transactions were imported.
        Assert.AreEqual(2, NumberOfLinesImported, '');
        BankAccReconLine.FilterBankRecLines(BankAccReconciliation);
        Assert.RecordCount(BankAccReconLine, 2);
    end;

    [Test]
    procedure ImportDuplicatedTransactionsWhenAllowed()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
        TempBankAccReconLine: Record "Bank Acc. Reconciliation Line" temporary;
        ProcessBankAccRecLines: Codeunit "Process Bank Acc. Rec Lines";
        TransactionIDList: List of [Text[50]];
        NumberOfLinesImported: Integer;
    begin
        // [SCENARIO 458159] Import transactions with the same Transaction ID when "Allow Duplicated Transactions" set.
        Initialize();

        // [GIVEN] Bank Account Reconciliation with Allow Duplicated Transactions = true.
        LibraryERM.CreateBankAccReconciliation(
            BankAccReconciliation, CreateBankAccount(), BankAccReconciliation."Statement Type"::"Bank Reconciliation");
        BankAccReconciliation.Validate("Allow Duplicated Transactions", true);
        BankAccReconciliation.Modify(true);

        // [GIVEN] Three transactions to import. Two of them has the same Transaction ID.
        TransactionIDList.Add('Transaction A');
        TransactionIDList.Add('Transaction B');
        TransactionIDList.Add('Transaction A');
        MockTransactionsToImport(TempBankAccReconLine, BankAccReconciliation, TransactionIDList);

        // [WHEN] Import transactions.
        ProcessBankAccRecLines.InsertNonReconciledOrImportedLines(
            TempBankAccReconLine, ProcessBankAccRecLines.GetLastStatementLineNo(BankAccReconciliation), NumberOfLinesImported);

        // [THEN] Three transactions were imported.
        Assert.AreEqual(3, NumberOfLinesImported, '');
        BankAccReconLine.FilterBankRecLines(BankAccReconciliation);
        Assert.RecordCount(BankAccReconLine, 3);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    procedure ImportDuplicatedTransactionsWhenAllowedAndPosted()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
        TempBankAccReconLine: Record "Bank Acc. Reconciliation Line" temporary;
        ProcessBankAccRecLines: Codeunit "Process Bank Acc. Rec Lines";
        TransactionIDList: List of [Text[50]];
        NumberOfLinesImported: Integer;
    begin
        // [SCENARIO 458159] Import transactions when "Allow Duplicated Transactions" set and posted transactions with the same Transaction ID exist.
        Initialize();

        // [GIVEN] Bank Account Reconciliation with Allow Duplicated Transactions = true.
        LibraryERM.CreateBankAccReconciliation(
            BankAccReconciliation, CreateBankAccount(), BankAccReconciliation."Statement Type"::"Bank Reconciliation");
        BankAccReconciliation.Validate("Allow Duplicated Transactions", true);
        BankAccReconciliation.Modify(true);

        TransactionIDList.Add('Transaction A');
        TransactionIDList.Add('Transaction B');
        TransactionIDList.Add('Transaction A');

        // [GIVEN] Posted transaction with Transaction ID "A".
        MockPostedNotReconciledTransaction(BankAccReconciliation, TransactionIDList.Get(1));

        // [GIVEN] Three transactions to import. Two of them has the same Transaction ID "A" and one has "B".
        MockTransactionsToImport(TempBankAccReconLine, BankAccReconciliation, TransactionIDList);

        // [GIVEN] Bank Acc. Reconciliation Line with Transaction ID "A".
        CreateBankAccReconLine(BankAccReconLine, BankAccReconciliation);
        BankAccReconLine."Transaction ID" := TransactionIDList.Get(1);
        BankAccReconLine.Modify();

        // [WHEN] Import transactions. Reply No when asked if transaction should be imported when posted transaction already exists.
        ProcessBankAccRecLines.InsertNonReconciledOrImportedLines(
            TempBankAccReconLine, ProcessBankAccRecLines.GetLastStatementLineNo(BankAccReconciliation), NumberOfLinesImported);

        // [THEN] One transaction with Transaction ID "B" was imported. Two transactions "A" and "B" are in Bank Acc. Reconciliation.
        Assert.AreEqual(1, NumberOfLinesImported, '');
        BankAccReconLine.FilterBankRecLines(BankAccReconciliation);
        Assert.RecordCount(BankAccReconLine, 2);

        BankAccReconLine.SetFilter("Transaction ID", TransactionIDList.Get(1));
        Assert.RecordCount(BankAccReconLine, 1);

        BankAccReconLine.SetFilter("Transaction ID", TransactionIDList.Get(2));
        Assert.RecordCount(BankAccReconLine, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckBankAccRecAutocompletesBankAccountNo()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccount: Record "Bank Account";
        BankAccReconciliationCard: TestPage "Bank Acc. Reconciliation";
        ExpectedStatementNo: Code[20];
    begin
        // [SCENARIO] Autocomplete Bank Account No. when creating a new Bank Acc. Recon. when there is only one Bank Account.
        Initialize();

        // [GIVEN] No bank acc. reconciliations or bank accounts.
        BankAccReconciliation.DeleteAll();
        BankAccount.DeleteAll();

        // [WHEN] Created a new bank account and opened a new bank acc. reconciliation.
        LibraryERM.CreateBankAccount(BankAccount);
        ExpectedStatementNo := '1';
        BankAccReconciliationCard.OpenNew();

        // [THEN] Bank Account No. autocompletes to the only available bank account number
        Assert.AreEqual(BankAccount."No.", BankAccReconciliationCard.BankAccountNo.Value(), '');
        // [THEN] Statement No. autocompletes to the corresponding value.
        Assert.AreEqual(ExpectedStatementNo, BankAccReconciliationCard.StatementNo.Value(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckBankAccRecDoesNotAutocompletesBankAccountNo()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccount: Record "Bank Account";
        BankAccReconciliationCard: TestPage "Bank Acc. Reconciliation";
        ExpectedBankAccountNo: Code[20];
        ExpectedStatementNo: Code[20];
    begin
        // [SCENARIO] Autocomplete Bank Account No. does not work when creating a new Bank Acc. Recon. when there are more than one Bank Account.
        Initialize();

        // [GIVEN] No bank acc. reconciliations or bank accounts.
        BankAccReconciliation.DeleteAll();
        BankAccount.DeleteAll();

        // [WHEN] Created two new bank accounts and opened a new bank acc. reconciliation.
        LibraryERM.CreateBankAccount(BankAccount);
        LibraryERM.CreateBankAccount(BankAccount);
        ExpectedBankAccountNo := '';
        ExpectedStatementNo := '';
        BankAccReconciliationCard.OpenNew();

        // [THEN] Bank Account No. does not autocomplete.
        Assert.AreEqual(ExpectedBankAccountNo, BankAccReconciliationCard.BankAccountNo.Value(), '');
        // [THEN] Statement No. does not autocomplete.
        Assert.AreEqual(ExpectedStatementNo, BankAccReconciliationCard.StatementNo.Value(), '');
    end;

    [Test]
    [HandlerFunctions('BankAccountStatementRequestPageHandler')]
    procedure BankAccountStatementReportDoesNotConsiderEntriesClosedAfterAsClosed()
    var
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        BankAccountStatement: Record "Bank Account Statement";
        MatchBankRecLines: Codeunit "Match Bank Rec. Lines";
        UndoBankStatementYesNo: Codeunit "Undo Bank Statement (Yes/No)";
        RequestPageXML: Text;
        PostingDateOfPayments, FirstReconciliationDate, SecondReconciliationDate : Date;
        BankAccountNo, AccountNo, FirstReconciliationNo : Code[20];
        FirstReconciliationAmount, SecondReconciliationAmount : Decimal;
    begin
        Initialize();
        LibraryERM.CreateGLAccount(GLAccount);
        BankAccountNo := LibraryERM.CreateBankAccountNoWithNewPostingGroup(GLAccount);
        AccountNo := LibraryPurchase.CreateVendorNo();
        // [GIVEN] Two payments recorded 10 days ago.
        PostingDateOfPayments := WorkDate() - 10;
        PostPaymentJournalLineWithDateAndSource(GenJournalLine, PostingDateOfPayments, AccountNo, BankAccountNo);
        PostPaymentJournalLineWithDateAndSource(GenJournalLine, PostingDateOfPayments, AccountNo, BankAccountNo);
        // [GIVEN] A reconciliation posted 5 days ago with one of this payments.
        FirstReconciliationDate := WorkDate() - 5;
        LibraryERM.CreateBankAccReconciliation(BankAccReconciliation, BankAccountNo, BankAccReconciliation."Statement Type"::"Bank Reconciliation");
        BankAccReconciliation.Validate("Statement Date", FirstReconciliationDate);
        CreateBankAccReconLine(BankAccReconciliationLine, BankAccReconciliation);
        BankAccReconciliationLine.Validate("Statement Amount", -GenJournalLine.Amount);
        BankAccReconciliationLine.Modify();
        BankAccReconciliationLine.SetRecFilter();
        BankAccountLedgerEntry.SetRange("Bank Account No.", BankAccountNo);
        BankAccountLedgerEntry.SetRange(Amount, -GenJournalLine.Amount);
        BankAccountLedgerEntry.SetRange(Open, true);
        BankAccountLedgerEntry.FindFirst();
        BankAccountLedgerEntry.SetRecFilter();
        FirstReconciliationAmount := BankAccountLedgerEntry.Amount;
        MatchBankRecLines.MatchManually(BankAccReconciliationLine, BankAccountLedgerEntry);
        BankAccReconciliation."Statement Ending Balance" := BankAccReconciliation."Balance Last Statement" + FirstReconciliationAmount;
        BankAccReconciliation.Modify();
        LibraryERM.PostBankAccReconciliation(BankAccReconciliation);
        Commit();
        FirstReconciliationNo := BankAccReconciliation."Statement No.";
        // [GIVEN] A second reconciliation posted today with the other payment.
        SecondReconciliationDate := WorkDate();
        BankAccReconciliation."Statement No." := IncStr(BankAccReconciliation."Statement No.");
        LibraryERM.CreateBankAccReconciliation(BankAccReconciliation, BankAccountNo, BankAccReconciliation."Statement Type"::"Bank Reconciliation");
        BankAccReconciliation.Validate("Statement Date", SecondReconciliationDate);
        Clear(BankAccountLedgerEntry);
        BankAccountLedgerEntry.SetRange("Bank Account No.", BankAccountNo);
        BankAccountLedgerEntry.SetRange(Open, true);
        BankAccountLedgerEntry.FindFirst();
        BankAccountLedgerEntry.SetRecFilter();
        SecondReconciliationAmount := BankAccountLedgerEntry.Amount;
        CreateBankAccReconLine(BankAccReconciliationLine, BankAccReconciliation);
        BankAccReconciliationLine.Validate("Statement Amount", BankAccountLedgerEntry.Amount);
        BankAccReconciliationLine.Modify();
        BankAccReconciliationLine.SetRecFilter();
        MatchBankRecLines.MatchManually(BankAccReconciliationLine, BankAccountLedgerEntry);
        BankAccReconciliation."Statement Ending Balance" := BankAccReconciliation."Balance Last Statement" + SecondReconciliationAmount;
        BankAccReconciliation.Modify();
        LibraryERM.PostBankAccReconciliation(BankAccReconciliation);
        Commit();
        // [GIVEN] Print outstanding transactions = false
        LibraryVariableStorage.Enqueue(false);
        // [WHEN] Undoing the first reconciliation and posting it again.
        BankAccountStatement.Get(BankAccountNo, FirstReconciliationNo);
        UndoBankStatementYesNo.UndoBankAccountStatement(BankAccountStatement);
        Commit();
        BankAccReconciliation.SetRange("Statement Type", BankAccReconciliation."Statement Type"::"Bank Reconciliation");
        BankAccReconciliation.SetRange("Bank Account No.", BankAccountNo);
        BankAccReconciliation.FindFirst();
        LibraryERM.PostBankAccReconciliation(BankAccReconciliation);
        Commit();
        // [THEN] The total outstanding amount shouldn't include the already closed amount from the second reconciliation.
        RequestPageXML := Report.RunRequestPage(Report::"Bank Account Statement", RequestPageXML);
        LibraryReportDataset.RunReportAndLoad(Report::"Bank Account Statement", BankAccountStatement, RequestPageXML);
        LibraryReportDataset.AssertElementWithValueExists('Bank_Acc__Reconciliation___TotalOutstdBankTransactions', 0);
    end;

    [Test]
    [HandlerFunctions('BankAccReconTestRequestPageHandler')]
    procedure BankAccountTestReportShouldNotConsiderCorruptedEntriesAsOutstanding()
    var
        GLAccount: Record "G/L Account";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        RequestPageXML: Text;
        BankAccountNo: Code[20];
    begin
        // [SCENARIO 538667] Bank Ledger Entries posted from old NA's Bank Rec. Worksheets are not considered as outstanding by the report.
        // [GIVEN] A Bank Account with a Bank Ledger Entry previously closed by a Bank Rec. Worksheet (ClosedAt date 0D).
        Initialize();
        LibraryERM.CreateGLAccount(GLAccount);
        BankAccountNo := LibraryERM.CreateBankAccountNoWithNewPostingGroup(GLAccount);
        BankAccountLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(BankAccountLedgerEntry, BankAccountLedgerEntry.FieldNo("Entry No."));
        BankAccountLedgerEntry."Bank Account No." := BankAccountNo;
        BankAccountLedgerEntry.Open := false;
        BankAccountLedgerEntry."Remaining Amount" := 0;
        BankAccountLedgerEntry."Closed at Date" := 0D;
        BankAccountLedgerEntry.Amount := 1000;
        BankAccountLedgerEntry.Insert();
        // [GIVEN] A bank reconciliation for this bank.
        LibraryERM.CreateBankAccReconciliation(BankAccReconciliation, BankAccountNo, BankAccReconciliation."Statement Type"::"Bank Reconciliation");
        Commit();
        // [WHEN] The test report is run.
        LibraryVariableStorage.Enqueue(true);
        RequestPageXML := Report.RunRequestPage(Report::"Bank Acc. Recon. - Test", RequestPageXML);
        LibraryReportDataset.RunReportAndLoad(Report::"Bank Acc. Recon. - Test", BankAccReconciliation, RequestPageXML);
        // [THEN] The total outstanding transactions should be zero.
        LibraryReportDataset.AssertElementWithValueExists('Bank_Acc__Reconciliation___TotalOutstdBankTransactions', 0);
    end;

    [Test]
    [HandlerFunctions('BankAccReconTestRequestPageHandler')]
    procedure OutstandingTransactionsOnBankAccountTestReport()
    var
        GLAccount: Record "G/L Account";
        BankAccReconciliation: array[2] of Record "Bank Acc. Reconciliation";
        BankAccountLedgerEntry: array[4] of Record "Bank Account Ledger Entry";
        Amount: array[4] of Decimal;
        RequestPageXML: Text;
        BankAccountNo: Code[20];
        i: Integer;
    begin
        // [SCENARIO 543178] Show outstanding bank transactions on bank account reconsiliation test report
        // [GIVEN] Bank Account X
        Initialize();
        BankAccReconciliation[1].DeleteAll();
        BankAccountLedgerEntry[1].DeleteAll();
        LibraryERM.CreateGLAccount(GLAccount);
        BankAccountNo := LibraryERM.CreateBankAccountNoWithNewPostingGroup(GLAccount);

        for i := 1 to ArrayLen(Amount) do
            Amount[i] := LibraryRandom.RandDec(100, 2);

        // [GIVEN] Bank Acc. Ledger Entry 1, posting date 20.1.2000.
        // [GIVEN] Bank Acc. Ledger Entry 2, posting date 20.2.2000.
        CreateBankAccountLedgerEntry(BankAccountLedgerEntry[1], BankAccountNo, WorkDate() - 30, 0D, Amount[1], true);
        CreateBankAccountLedgerEntry(BankAccountLedgerEntry[2], BankAccountNo, WorkDate(), 0D, Amount[2], true);

        // [GIVEN] A bank reconciliation X for this bank, statement date = 31.1.2000.
        LibraryERM.CreateBankAccReconciliation(BankAccReconciliation[1], BankAccountNo, BankAccReconciliation[1]."Statement Type"::"Bank Reconciliation");
        BankAccReconciliation[1].Validate("Statement Date", WorkDate() - 29);
        BankAccReconciliation[1].Modify(true);

        SuggestBankRecLines(BankAccReconciliation[1], true, 0D, BankAccReconciliation[1]."Statement Date");

        // [GIVEN] A bank reconciliation Y for this bank, statement date = 28.2.2000.
        LibraryERM.CreateBankAccReconciliation(BankAccReconciliation[2], BankAccountNo, BankAccReconciliation[2]."Statement Type"::"Bank Reconciliation");
        BankAccReconciliation[2].Validate("Statement Date", WorkDate() + 1);
        BankAccReconciliation[2].Modify(true);

        Commit();
        SuggestBankRecLines(BankAccReconciliation[2], true, 0D, BankAccReconciliation[2]."Statement Date");

        // [GIVEN] Bank Acc. Ledger Entry 3, posting date 20.1.2000.
        // [GIVEN] Bank Acc. Ledger Entry 4, posting date 20.2.2000.
        CreateBankAccountLedgerEntry(BankAccountLedgerEntry[3], BankAccountNo, WorkDate() - 30, 0D, Amount[3], true);
        CreateBankAccountLedgerEntry(BankAccountLedgerEntry[4], BankAccountNo, WorkDate(), 0D, Amount[4], true);

        // [WHEN] The test report is run for bank reconciliation Y, print outstanding transactions = true
        Commit();
        LibraryVariableStorage.Enqueue(true);
        RequestPageXML := Report.RunRequestPage(Report::"Bank Acc. Recon. - Test", RequestPageXML);
        LibraryReportDataset.RunReportAndLoad(Report::"Bank Acc. Recon. - Test", BankAccReconciliation[2], RequestPageXML);

        // [THEN] The total outstanding transactions includes amounts from Bank Acc. Ledger Entry 3 and Bank Acc. Ledger Entry 4
        LibraryReportDataset.AssertElementWithValueExists('Outstd_Bank_Transac_Amount', Amount[3]);
        LibraryReportDataset.AssertElementWithValueExists('Outstd_Bank_Transac_Amount', Amount[4]);
        LibraryReportDataset.AssertElementWithValueNotExist('Outstd_Bank_Transac_Amount', Amount[2]);
        LibraryReportDataset.AssertElementWithValueExists('Bank_Acc__Reconciliation___TotalOutstdBankTransactions', Amount[3] + Amount[4]);
    end;

    [Test]
    [HandlerFunctions('BankAccountStatementRequestPageHandler')]
    procedure OutstandingTransactionsOnBankAccountStatementReport()
    var
        GLAccount: Record "G/L Account";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccountStatement: Record "Bank Account Statement";
        BankAccountLedgerEntry: array[4] of Record "Bank Account Ledger Entry";
        BankAccRecTest: Codeunit "Bank Acc. Recon. Test";
        Amount: array[4] of Decimal;
        TotalOutstandingTransactionAmount: Decimal;
        RequestPageXML: Text;
        BankAccountNo: Code[20];
        i: Integer;
    begin
        // [SCENARIO 543178] Show outstanding bank transactions on bank account statement report
        // [GIVEN] Bank Account X
        Initialize();
        BankAccountLedgerEntry[1].DeleteAll();
        LibraryERM.CreateGLAccount(GLAccount);
        BankAccountNo := LibraryERM.CreateBankAccountNoWithNewPostingGroup(GLAccount);

        for i := 1 to ArrayLen(Amount) do
            Amount[i] := LibraryRandom.RandDec(100, 2);

        // [GIVEN] Bank Acc. Ledger Entry 1, posting date 20.1.2000.
        // [GIVEN] Bank Acc. Ledger Entry 2, posting date 20.2.2000.
        CreateBankAccountLedgerEntry(BankAccountLedgerEntry[1], BankAccountNo, WorkDate() - 30, 0D, Amount[1], true);
        CreateBankAccountLedgerEntry(BankAccountLedgerEntry[2], BankAccountNo, WorkDate(), 0D, Amount[2], true);

        // [GIVEN] A bank reconciliation X for this bank, statement date = 31.1.2000.
        LibraryERM.CreateBankAccReconciliation(BankAccReconciliation, BankAccountNo, BankAccReconciliation."Statement Type"::"Bank Reconciliation");
        BankAccReconciliation.Validate("Statement Date", WorkDate() - 29);
        BankAccReconciliation.Modify(true);
        SuggestBankRecLines(BankAccReconciliation, true, 0D, BankAccReconciliation."Statement Date");

        // [GIVEN] Bank Acc. Ledger Entry 3, posting date 20.1.2000.
        CreateBankAccountLedgerEntry(BankAccountLedgerEntry[3], BankAccountNo, WorkDate() - 30, 0D, Amount[3], true);

        TotalOutstandingTransactionAmount := BankAccRecTest.TotalOutstandingBankTransactions(BankAccReconciliation);
        // [GIVEN] Post bank reconsiliation X
        LibraryERM.PostBankAccReconciliation(BankAccReconciliation);

        // [GIVEN] Bank Acc. Ledger Entry 4, posting date 20.1.2000.
        CreateBankAccountLedgerEntry(BankAccountLedgerEntry[4], BankAccountNo, WorkDate() - 30, 0D, Amount[4], true);

        // [WHEN] The statement report is run for bank statement X, print outstanding transactions = true
        Commit();
        BankAccountStatement.SetRange("Bank Account No.", BankAccountNo);
        LibraryVariableStorage.Enqueue(true);
        RequestPageXML := Report.RunRequestPage(Report::"Bank Account Statement", RequestPageXML);
        LibraryReportDataset.RunReportAndLoad(Report::"Bank Account Statement", BankAccountStatement, RequestPageXML);

        // [THEN] Outstanding transaction includes Bank Acc. Ledger Entry 3; total outstanding bank transactions amount is transferred from bank acc. reconsiliation
        LibraryReportDataset.AssertElementWithValueExists('Outstanding_BankTransaction_Amount', Amount[3]);
        LibraryReportDataset.AssertElementWithValueNotExist('Outstanding_BankTransaction_Amount', Amount[2]);
        LibraryReportDataset.AssertElementWithValueNotExist('Outstanding_BankTransaction_Amount', Amount[4]);
        LibraryReportDataset.AssertElementWithValueExists('Bank_Acc__Reconciliation___TotalOutstdBankTransactions', TotalOutstandingTransactionAmount);
    end;

    [Test]
    [HandlerFunctions('PostAndReconcilePageHandler,PostAndReconcilePageStatementDateHandler')]
    procedure PostingGeneralReconciliationUpdatesAnalysisView()
    var
        AnalysisView: Record "Analysis View";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
    begin
        // [SCENARIO 554706] Payment Reconciliation Journal does not update in Analysis View
        Initialize();

        // [GIVEN] Create Analysis View.
        LibraryERM.CreateAnalysisView(AnalysisView);

        // [GIVEN] Create and Get GL Account.
        GLAccount.Get(LibraryERM.CreateGLAccountNo());

        // [GIVEN] Validate Update On Posting, Account Source and Account Filter in Analysis View.
        AnalysisView.Validate("Update on Posting", true);
        AnalysisView.Validate("Account Source", AnalysisView."Account Source"::"G/L Account");
        AnalysisView.Validate("Account Filter", GLAccount."No.");
        AnalysisView.Modify(true);

        // [GIVEN] Create Bank Reconciliation With GLAccount.
        CreateBankReconciliationWithGLAccount(BankAccReconciliation, BankAccReconciliationLine, GLAccount."No.");

        // [GIVEN] Update Bank Account Statement Ending Balance.
        UpdateBankAccRecStmEndingBalance(
            BankAccReconciliation,
            BankAccReconciliation."Balance Last Statement" + BankAccReconciliationLine."Statement Amount");

        // [WHEN] Post Bank Account Reconciliation.
        LibraryERM.PostBankAccReconciliation(BankAccReconciliation);

        // [THEN] Last Entry No. on Analysis View is updated with GL Entry created by Reconciliation.
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Payment);
        GLEntry.SetRange("Bal. Account No.", GLAccount."No.");
        GLEntry.FindLast();
        AnalysisView.Get(AnalysisView.Code);
        Assert.AreEqual(
            GLEntry."Entry No.",
            AnalysisView."Last Entry No.",
            StrSubstNo(
                AnalysisViewErr,
                GLEntry."Entry No.",
                AnalysisView.TableCaption()));
    end;

    [Test]
    procedure StatmtEndingBalInBankAccReconAcceptsDecimalValuesDefinedInUnitAmtDecimalPlacesOfBankAccCurrency()
    var
        BankAccount: Record "Bank Account";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationPage: TestPage "Bank Acc. Reconciliation";
        Amount: Decimal;
    begin
        // [SCENARIO 555882] Statement Ending Balance in Bank Acc. Reconciliation accepts decimal values
        // Defined in Unit-Amount Rounding Precision of Currency of Bank Account.
        Initialize();

        // [GIVEN] Create a Vendor.
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Create a Bank Account and Validate Currency Code.
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Currency Code", CreateCurrencyCode());
        BankAccount.Modify(true);

        // [GIVEN] Create an Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Generate Amount and save it in a Variable.
        Amount := LibraryRandom.RandDecInDecimalRange(100.123, 100.123, 3);

        // [GIVEN] Create a Purchase Header.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");

        // [GIVEN] Create a Purchase Line and Validate Direct Unit Cost.
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandInt(0));
        PurchaseLine.Validate("Direct Unit Cost", Amount);
        PurchaseLine.Modify(true);

        // [GIVEN] Post Purchase Document.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Create a Bank Account Reconciliation.
        CreateBankReconciliation(BankAccReconciliation, BankAccount."No.", BankAccReconciliation."Statement Type"::"Bank Reconciliation");

        // [GIVEN] Open Bank Account Reconciliation page and Set value in Statement Ending Balance.
        BankAccReconciliationPage.OpenEdit();
        BankAccReconciliationPage.GoToRecord(BankAccReconciliation);
        BankAccReconciliationPage.StatementEndingBalance.SetValue(Amount);
        BankAccReconciliationPage.Close();

        // [WHEN] Find Bank Account Reconciliation.
        BankAccReconciliation.Get(BankAccReconciliation."Statement Type", BankAccReconciliation."Bank Account No.", BankAccReconciliation."Statement No.");

        // [THEN] Statement Ending Balance value is equal to Amount.
        Assert.AreEqual(
            Amount,
            BankAccReconciliation."Statement Ending Balance",
            StrSubstNo(
                StatementEndingBalanceErr,
                BankAccReconciliation.FieldCaption("Statement Ending Balance"),
                Amount,
                BankAccReconciliation.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('GeneralJournalPageHandler')]
    procedure SourceCodeRelatedToGenJnltemplateTypeIsPopulatedToGenJnlLineWhenTransferToGenJnl()
    var
        BankAccount: Record "Bank Account";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        DeferralTemplate: Record "Deferral Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GLAccount: Record "G/L Account";
        SourceCode: array[2] of Record "Source Code";
        SourceCodeSetup: Record "Source Code Setup";
    begin
        // [SCENARIO 560604] Source Code related to Gen. Journal Template Type is populated
        // To Gen. Journal Line when Stan runs Transfer To General Journal from Bank Acc. Reconciliation.
        Initialize();

        // [GIVEN] Create a Bank Account.
        LibraryERM.CreateBankAccount(BankAccount);

        // [GIVEN] Create Source Code [1].
        LibraryERM.CreateSourceCode(SourceCode[1]);

        // [GIVEN] Create Source Code [2].
        LibraryERM.CreateSourceCode(SourceCode[2]);

        // [GIVEN] Validate "General Deferral" and "Trans. Bank Rec. to Gen. Jnl." in Source Code setup.
        SourceCodeSetup.Get();
        SourceCodeSetup.Validate("General Deferral", SourceCode[1].Code);
        SourceCodeSetup.Validate("Trans. Bank Rec. to Gen. Jnl.", SourceCode[2].Code);
        SourceCodeSetup.Modify(true);

        // [GIVEN] Create a Deferral Template.
        LibraryERM.CreateDeferralTemplate(
            DeferralTemplate,
            DeferralTemplate."Calc. Method"::"Straight-Line",
            DeferralTemplate."Start Date"::"Posting Date",
            LibraryRandom.RandInt(0));

        // [GIVEN] Validate "Deferral %" and "Deferral Account" in Deferral Template.
        DeferralTemplate.Validate("Deferral %", LibraryRandom.RandIntInRange(100, 100));
        DeferralTemplate.Validate("Deferral Account", LibraryERM.CreateGLAccountNo());
        DeferralTemplate.Modify(true);

        // [GIVEN] Create a GL Account and Validate "Default Deferral Template Code".
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Default Deferral Template Code", DeferralTemplate."Deferral Code");
        GLAccount.Modify(true);

        // [GIVEN] Find and clear Gen. Journal Batch.
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);

        // [GIVEN] Setup Bank Acc. Reconciliation.
        SetupBankAccReconciliation(BankAccReconciliation, BankAccReconciliationLine);

        // [WHEN] Run Transfer To Gen. Jnl. Report.
        LibraryVariableStorage.Enqueue(Format(GLAccount."No."));
        TransferToGenJnlReport(BankAccReconciliation, GenJournalBatch);

        // [THEN] "Account No." in Gen. Journal Line is not blank in GeneralJournalPageHandler.
    end;

    local procedure Initialize()
    var
        BankPmtApplSettings: Record "Bank Pmt. Appl. Settings";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Bank Reconciliation");
        LibrarySetupStorage.Restore();
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Bank Reconciliation");
        LibraryVariableStorage.Clear();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateLocalPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Source Code Setup");
        BankPmtApplSettings.GetOrInsert();
        LibrarySetupStorage.Save(DATABASE::"Bank Pmt. Appl. Settings");
        Commit();
        isInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Bank Reconciliation");
    end;

    local procedure CreateBankAccountLedgerEntry(var BankAccountLedgerEntry: Record "Bank Account Ledger Entry"; BankAccountNo: Code[20]; PostingDate: Date; ClosedAtDate: Date; Amount: Decimal; Open: Boolean)
    begin
        BankAccountLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(BankAccountLedgerEntry, BankAccountLedgerEntry.FieldNo("Entry No."));
        BankAccountLedgerEntry."Posting Date" := PostingDate;
        BankAccountLedgerEntry."Bank Account No." := BankAccountNo;
        BankAccountLedgerEntry."Closed at Date" := ClosedAtDate;
        BankAccountLedgerEntry.Amount := Amount;
        BankAccountLedgerEntry.Open := Open;
        BankAccountLedgerEntry.Insert();
    end;

    local procedure ManualApplyAndPostBankAccountReconciliation(var BankAccount: Record "Bank Account"; StatementNo: Code[20]; Vendor: Record Vendor; var GenJournalLine: Record "Gen. Journal Line"; var EndingBalance: Decimal)
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccReconciliationTestPage: TestPage "Bank Acc. Reconciliation";
    begin
        BankAccount.Find();
        UpdateLastStatementNoOnBankAccount(BankAccount, StatementNo);

        CreateBankReconciliation(BankAccReconciliation, BankAccount."No.", BankAccReconciliation."Statement Type"::"Bank Reconciliation");

        CreateBankAccReconciliationLine(
            BankAccReconciliation, BankAccReconciliationLine,
            BankAccReconciliationLine."Account Type"::Vendor, Vendor."No.",
            GenJournalLine.Amount, GenJournalLine."Posting Date");

        BankAccReconciliationTestPage.OpenEdit();
        BankAccReconciliationTestPage.Filter.SetFilter("Bank Account No.", BankAccount."No.");
        BankAccReconciliationTestPage.Filter.SetFilter("Statement No.", BankAccReconciliation."Statement No.");
        BankAccReconciliationTestPage.StmtLine."Applied Amount".SetValue(-GenJournalLine.Amount);
        BankAccReconciliationTestPage.StmtLine."Statement Amount".SetValue(-GenJournalLine.Amount);
        BankAccReconciliationTestPage.MatchManually.Invoke();

        EndingBalance += GenJournalLine.Amount;
        BankAccReconciliationTestPage.StatementEndingBalance.SetValue(-EndingBalance);
        BankAccReconciliationTestPage.Close();

        BankAccReconciliation.Find();

        LibraryERM.PostBankAccReconciliation(BankAccReconciliation);
    end;

    local procedure PostCheck(var BankAccount: Record "Bank Account"; AccountNo: Code[20]; JnlAmount: Decimal): Code[20]
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Create General Journal Template and Batch for posting checks.
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate(Type, GenJournalTemplate.Type::Payments);
        GenJournalTemplate.Validate(Recurring, false);
        GenJournalTemplate.Modify(true);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch.Validate("Bal. Account Type", GenJournalBatch."Bal. Account Type"::"Bank Account");
        GenJournalBatch.Validate("Bal. Account No.", CreateBankAccount());
        GenJournalBatch.Modify(true);
        BankAccount.Get(GenJournalBatch."Bal. Account No.");

        // Generate a journal line.
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::"Bank Account",
          AccountNo, JnlAmount);
        GenJournalLine.Validate("Document No.", LibraryUtility.GenerateRandomCode(GenJournalLine.FieldNo("Document No."), DATABASE::"Gen. Journal Line"));
        GenJournalLine.Validate("Currency Code", BankAccount."Currency Code");
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Bal. Account No.", BankAccount."No.");
        GenJournalLine.Validate("Bank Payment Type", GenJournalLine."Bank Payment Type"::"Manual Check");
        GenJournalLine.Modify(true);

        // Post the check.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine."Document No.");
    end;

    local procedure PrepareBankAccReconciliation(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; BankAccountNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        PostPaymentJournalLineWithDateAndSource(GenJournalLine, WorkDate(), LibraryPurchase.CreateVendorNo(), BankAccountNo);

        // [GIVEN] Create bank reconciliation with "Statement No." = 1
        CreateSuggestedBankReconc(BankAccReconciliation, BankAccountNo, false);
    end;

    local procedure PrepareBankAccReconciliationWithPostPaymentsOnly(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; BankAccountNo: Code[20]; PostPaymentsOnly: Boolean)
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        CustLedgerEntryNo: Integer;
        CustNo: Code[20];
        StatementAmount: Decimal;
    begin
        StatementAmount := LibraryRandom.RandDecInRange(1000, 2000, 2);
        CreateAndPostSalesInvoice(CustNo, CustLedgerEntryNo, StatementAmount);
        CreateApplyBankAccReconcilationLine(
          BankAccReconciliation, BankAccReconciliationLine, BankAccReconciliationLine."Account Type"::Customer, CustNo, StatementAmount,
          BankAccountNo);
        ApplyBankAccReconcilationLine(BankAccReconciliationLine, CustLedgerEntryNo, BankAccReconciliationLine."Account Type"::Customer, '');
        BankAccReconciliation.Validate("Post Payments Only", PostPaymentsOnly);
        if (not PostPaymentsOnly) then
            UpdateBankAccRecStmEndingBalance(BankAccReconciliation, BankAccReconciliation."Balance Last Statement" + BankAccReconciliationLine."Statement Amount");
    end;

    local procedure PostTwoPaymentJournalLinesWithDocNoAndBalAccount(var DocumentNo: array[2] of Code[20]; BankAccountNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
        AccountNo: Code[20];
        I: Integer;
    begin
        AccountNo := LibraryPurchase.CreateVendorNo();

        for I := 1 to ArrayLen(DocumentNo) do begin
            DocumentNo[I] := CreatePaymentJournalLineWithVendorAndBank(GenJournalLine, AccountNo, BankAccountNo);
            LibraryERM.PostGeneralJnlLine(GenJournalLine);
        end;
    end;

    local procedure PostPaymentJournalLineWithDateAndSource(var GenJournalLine: Record "Gen. Journal Line"; PostingDate: Date; AccountNo: Code[20]; BankAccountNo: Code[20])
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, "Gen. Journal Document Type"::" ", GenJournalLine."Account Type"::Vendor, AccountNo,
          -LibraryRandom.RandIntInRange(1000, 2000));
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Bal. Account No.", BankAccountNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure ReverseTransactionGenJournalLine(DocumentNo: Code[20]; BankAccountNo: Code[20])
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
    begin
        BankAccountLedgerEntry.SetRange("Bank Account No.", BankAccountNo);
        BankAccountLedgerEntry.SetRange("Document No.", DocumentNo);
        BankAccountLedgerEntry.FindFirst();
        LibraryERM.ReverseTransaction(BankAccountLedgerEntry."Transaction No.");
    end;

    local procedure RunChangeStatementNo(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; NewStatementNo: Code[20])
    begin
        LibraryVariableStorage.Enqueue(NewStatementNo);
        Codeunit.Run(Codeunit::"Change Bank Rec. Statement No.", BankAccReconciliation);
    end;

    local procedure CreatePaymentJournalLineWithVendorAndBank(var GenJournalLine: Record "Gen. Journal Line"; AccountNo: Code[20]; BankAccountNo: Code[20]): Code[20]
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, AccountNo,
          LibraryRandom.RandDecInRange(1000, 2000, 2));
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Bal. Account No.", BankAccountNo);
        GenJournalLine.Modify(true);

        exit(GenJournalLine."Document No.");
    end;

    local procedure CreateAndPostGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; BankAccountNo: Code[20])
    begin
        CreateAndPostGenJournalLineWithAmount(GenJournalLine, BankAccountNo, -LibraryRandom.RandDec(5, 2));
    end;

    local procedure CreateGenJournalLineWithAmount(var GenJournalLine: Record "Gen. Journal Line"; BankAccountNo: Code[20]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.DeleteAll(true);

        LibraryERM.CreateGeneralJnlLineWithBalAcc(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(),
          GenJournalLine."Bal. Account Type"::"Bank Account", BankAccountNo, Amount);
    end;

    local procedure CreateAndPostGenJournalLineWithAmount(var GenJournalLine: Record "Gen. Journal Line"; BankAccountNo: Code[20]; Amount: Decimal)
    begin
        CreateGenJournalLineWithAmount(GenJournalLine, BankAccountNo, Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndPostGenJournalLineEmployee(var GenJournalLine: Record "Gen. Journal Line"; EmployeeNo: Code[20]): Integer
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.DeleteAll(true);

        // Use Random because value is not important.
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, "Gen. Journal Document Type"::" ",
          GenJournalLine."Account Type"::Employee, EmployeeNo,
          GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNoWithDirectPosting(), -LibraryRandom.RandDec(100, 2));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        EmployeeLedgerEntry.SetRange("Employee No.", EmployeeNo);
        EmployeeLedgerEntry.FindLast();
        exit(EmployeeLedgerEntry."Entry No.");
    end;

    local procedure CreateAndPostGenJournalLineEmployee(var GenJournalLine: Record "Gen. Journal Line"; EmployeeNo: Code[20]; Amount: Decimal): Integer
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.DeleteAll(true);

        // Use Random because value is not important.
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, "Gen. Journal Document Type"::" ",
          GenJournalLine."Account Type"::Employee, EmployeeNo,
          GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNoWithDirectPosting(), Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        EmployeeLedgerEntry.SetRange("Employee No.", EmployeeNo);
        EmployeeLedgerEntry.FindLast();
        exit(EmployeeLedgerEntry."Entry No.");
    end;

    local procedure CreateEmployee(var Employee: Record Employee)
    var
        EmployeePostingGroup: Record "Employee Posting Group";
    begin
        LibraryHumanResource.CreateEmployee(Employee);
        EmployeePostingGroup.Init();
        EmployeePostingGroup.Validate(Code, LibraryUtility.GenerateGUID());
        EmployeePostingGroup.Validate("Payables Account", LibraryERM.CreateGLAccountNoWithDirectPosting());
        EmployeePostingGroup.Insert(true);
        Employee.Validate("Employee Posting Group", EmployeePostingGroup.Code);
        Employee.Validate("Application Method", Employee."Application Method"::Manual);
        Employee.Validate("Last Name", Employee."First Name");
        Employee.Modify(true);
    end;

    local procedure CreateAndPostSalesInvoice(var CustomerNo: Code[20]; var CustLedgerEntryNo: Integer; var RemainingAmount: Decimal)
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        LibrarySales.CreateSalesInvoice(SalesHeader);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        CustLedgerEntry.SetRange("Customer No.", SalesHeader."Sell-to Customer No.");
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.CalcFields("Remaining Amount");
        CustomerNo := CustLedgerEntry."Customer No.";
        CustLedgerEntryNo := CustLedgerEntry."Entry No.";
        RemainingAmount := CustLedgerEntry."Remaining Amount";
    end;

    local procedure CreateAndPostPurchaseInvoice(var VendorNo: Code[20]; var VendLedgerEntryNo: Integer; var RemainingAmount: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        VendorLedgerEntry.SetRange("Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        VendorLedgerEntry.FindFirst();
        VendorLedgerEntry.CalcFields("Remaining Amount");
        VendorNo := VendorLedgerEntry."Vendor No.";
        VendLedgerEntryNo := VendorLedgerEntry."Entry No.";
        RemainingAmount := VendorLedgerEntry."Remaining Amount";
    end;

    local procedure CreateGLAccountWithVATPostingSetup(var VATRate: Decimal) GLAccountNo: Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATRate := LibraryRandom.RandIntInRange(2, 5);
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup,
          VATPostingSetup."VAT Calculation Type"::"Normal VAT", VATRate);
        GLAccountNo := VATPostingSetup."Purchase VAT Account";
        UpdateGLAccountPostingGroups(GLAccountNo,
          VATPostingSetup."VAT Prod. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
    end;

    local procedure UpdateGLAccountPostingGroups(GLAccountNo: Code[20]; VATProdPostingGroup: Code[20]; VATBusPostingGroup: Code[20])
    var
        GLAccount: Record "G/L Account";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
    begin
        GLAccount.Get(GLAccountNo);
        LibraryERM.CreateGenProdPostingGroup(GenProductPostingGroup);
        GLAccount."Gen. Posting Type" := GLAccount."Gen. Posting Type"::Purchase;
        GLAccount."Gen. Prod. Posting Group" := GenProductPostingGroup.Code;
        GLAccount."VAT Prod. Posting Group" := VATProdPostingGroup;
        GLAccount."VAT Bus. Posting Group" := VATBusPostingGroup;
        GLAccount.Modify(true);
    end;

    local procedure CreateDefaultDimension(AccountNo: Code[20]; TableID: Integer)
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDefaultDimension(DefaultDimension, TableID, AccountNo, Dimension.Code, DimensionValue.Code);
    end;

    local procedure CreateDefaultDimensionWithSpecCode(AccountNo: Code[20]; TableID: Integer)
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
    begin
        LibraryDimension.CreateDimension(Dimension);
        CreateDimensionValueWithSpecCode(DimensionValue, AccountNo, Dimension.Code);
        LibraryDimension.CreateDefaultDimension(DefaultDimension, TableID, AccountNo, Dimension.Code, DimensionValue.Code);
    end;

    local procedure CreateDimensionValueWithSpecCode(var DimensionValue: Record "Dimension Value"; DimensionValueCode: Code[20]; DimensionCode: Code[20])
    begin
        DimensionValue.Init();
        DimensionValue.Validate("Dimension Code", DimensionCode);
        DimensionValue.Validate(Code, DimensionValueCode);
        DimensionValue.Insert(true);
    end;

    local procedure CreateBankAccount(): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        exit(CreateBankAccount(BankAccount));
    end;

    local procedure CreateBankAccount(var BankAccount: Record "Bank Account"): Code[20]
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Last Statement No.", Format(LibraryRandom.RandInt(10)));  // Take Random Value.
        BankAccount.Modify(true);
        exit(BankAccount."No.");
    end;

    local procedure UpdateLastStatementNoOnBankAccount(var BankAccount: Record "Bank Account"; NewStatementNo: Code[20])
    begin
        BankAccount.Validate("Last Statement No.", NewStatementNo);
        BankAccount.Modify(true);
    end;

    local procedure CreateBankAccountWithCurrencyCode(CurrencyCode: Code[10]): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount.Get(CreateBankAccount());
        BankAccount.Validate("Currency Code", CurrencyCode);
        BankAccount.Modify(true);
        exit(BankAccount."No.");
    end;

    local procedure CreateBankAccountReconciliationWithMatchedLineAndLedgerEntry(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateAndPostGenJournalLine(GenJournalLine, CreateBankAccount());
        CreateSuggestedBankReconc(BankAccReconciliation, GenJournalLine."Bal. Account No.", false);

        BankAccReconciliationLine.SetRange("Statement Type", BankAccReconciliation."Statement Type");
        BankAccReconciliationLine.SetRange("Bank Account No.", BankAccReconciliation."Bank Account No.");
        BankAccReconciliationLine.SetRange("Statement No.", BankAccReconciliation."Statement No.");
        BankAccReconciliationLine.FindFirst();
    end;

    local procedure CreateBankAccountStatement(BankAccount: Record "Bank Account")
    var
        BankAccountStatement: Record "Bank Account Statement";
    begin
        BankAccountStatement.Init();
        BankAccountStatement."Bank Account No." := BankAccount."No.";
        BankAccountStatement."Statement No." := BankAccount."Last Statement No.";
        BankAccountStatement."Statement Date" := WorkDate();
        BankAccountStatement.Insert();
    end;

    local procedure CreateBankReconciliation(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; BankAccountNo: Code[20]; BankReconType: Enum "Bank Acc. Rec. Stmt. Type")
    begin
        LibraryERM.CreateBankAccReconciliation(BankAccReconciliation, BankAccountNo, BankReconType);
        BankAccReconciliation.Validate("Statement Date", WorkDate());
        BankAccReconciliation.Modify(true);
    end;

    [Normal]
    local procedure CreateBankReconciliationWithLedgerEntries(var BankAccountStatement: Record "Bank Account Statement")
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateAndPostGenJournalLine(GenJournalLine, CreateBankAccount());
        CreateSuggestedBankReconc(BankAccReconciliation, GenJournalLine."Bal. Account No.", false);
        LibraryERM.PostBankAccReconciliation(BankAccReconciliation);
        BankAccountStatement.Get(BankAccReconciliation."Bank Account No.", BankAccReconciliation."Statement No.");
    end;

    local procedure CreateBankReconciliationWithGLAccount(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; GLAccNo: Code[20])
    begin
        LibraryERM.CreateBankAccReconciliation(
          BankAccReconciliation, CreateBankAccount(), BankAccReconciliation."Statement Type"::"Payment Application");
        LibraryERM.CreateBankAccReconciliationLn(BankAccReconciliationLine, BankAccReconciliation);
        BankAccReconciliationLine.Validate("Account Type", BankAccReconciliationLine."Account Type"::"G/L Account");
        BankAccReconciliationLine.Validate("Account No.", GLAccNo);
        BankAccReconciliationLine.Validate("Statement Amount", LibraryRandom.RandDec(100, 2));
        BankAccReconciliationLine.Validate("Transaction Date", WorkDate());
        BankAccReconciliationLine.Validate(Description, GLAccNo);
        BankAccReconciliationLine.Modify(true);
        ApplyBankAccReconLineToGLAccount(BankAccReconciliationLine, GLAccNo, BankAccReconciliationLine."Statement Amount");
    end;

    local procedure CreateBankReconciliationWithEmployee(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; EmployeeNo: Code[20]; StatementAmount: Decimal)
    begin
        LibraryERM.CreateBankAccReconciliation(
          BankAccReconciliation, CreateBankAccount(), BankAccReconciliation."Statement Type"::"Payment Application");
        LibraryERM.CreateBankAccReconciliationLn(BankAccReconciliationLine, BankAccReconciliation);
        BankAccReconciliationLine.Validate("Account Type", "Gen. Journal Account Type"::Employee);
        BankAccReconciliationLine.Validate("Account No.", EmployeeNo);
        BankAccReconciliationLine.Validate("Statement Amount", StatementAmount);
        BankAccReconciliationLine.Validate("Transaction Date", WorkDate());
        BankAccReconciliationLine.Validate(Description, EmployeeNo);
        BankAccReconciliationLine.Modify(true);
    end;

    local procedure CreateBankAccReconciliationLine(BankAccReconciliation: Record "Bank Acc. Reconciliation"; var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal; Date: Date)
    begin
        LibraryERM.CreateBankAccReconciliationLn(BankAccReconciliationLine, BankAccReconciliation);
        BankAccReconciliationLine.Validate("Account Type", AccountType);
        BankAccReconciliationLine.Validate("Account No.", AccountNo);
        BankAccReconciliationLine.Validate("Document No.", LibraryUtility.GenerateGUID());
        BankAccReconciliationLine.Validate("Statement Amount", Amount);
        BankAccReconciliationLine.Validate("Transaction Date", Date);
        BankAccReconciliationLine.Validate(Description, AccountNo);
        BankAccReconciliationLine.Modify(true);
    end;

    local procedure CreateBankAccReconciliationLineWithDocNo(BankAccReconciliation: Record "Bank Acc. Reconciliation"; BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; DocumentNo: Code[20])
    begin
        CreateBankAccReconLine(BankAccReconciliationLine, BankAccReconciliation);
        BankAccReconciliationLine.Validate("Document No.", DocumentNo);
        BankAccReconciliationLine.Modify(true);
    end;

    local procedure CreateApplyBankAccReconcilationLine(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; StatementAmount: Decimal; BankAccountNo: Code[20])
    begin
        LibraryERM.CreateBankAccReconciliation(
          BankAccReconciliation, BankAccountNo, BankAccReconciliation."Statement Type"::"Payment Application");
        LibraryERM.CreateBankAccReconciliationLn(BankAccReconciliationLine, BankAccReconciliation);
        BankAccReconciliationLine.Validate("Account Type", AccountType);
        BankAccReconciliationLine.Validate("Account No.", AccountNo);
        BankAccReconciliationLine.Validate("Document No.",
          LibraryUtility.GenerateRandomCode(BankAccReconciliationLine.FieldNo("Document No."), DATABASE::"Bank Acc. Reconciliation Line"));
        BankAccReconciliationLine.Validate("Statement Amount", StatementAmount);
        BankAccReconciliationLine.Validate("Dimension Set ID", CreateDimSet(BankAccReconciliationLine."Dimension Set ID"));
        BankAccReconciliationLine.Validate("Transaction Date", WorkDate());
        BankAccReconciliationLine.Validate(Description, AccountNo);
        BankAccReconciliationLine.Modify(true);
    end;

    local procedure CreateApplyBankReconWithDescription(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; AppliesEntryDescription: Text[50]; BankAccRecLineDescription: Text[50])
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        CustomerNo: Code[20];
        StatementAmount: Decimal;
        CustLedgerEntryNo: Integer;
    begin
        CreateAndPostSalesInvoice(CustomerNo, CustLedgerEntryNo, StatementAmount);
        CreateApplyBankAccReconcilationLine(
          BankAccReconciliation, BankAccReconciliationLine,
          BankAccReconciliationLine."Account Type"::Customer,
          CustomerNo, StatementAmount, LibraryERM.CreateBankAccountNo());
        ApplyBankAccReconcilationLine(
          BankAccReconciliationLine, CustLedgerEntryNo,
          BankAccReconciliationLine."Account Type"::Customer, AppliesEntryDescription);
        UpdateBankAccReconciliationLineDescription(BankAccReconciliationLine, BankAccRecLineDescription);
        UpdateBankAccRecStmEndingBalance(BankAccReconciliation, BankAccReconciliation."Balance Last Statement" + BankAccReconciliationLine."Statement Amount");
    end;

    local procedure CreateAndAutoApplyTwoBankAccReconLines(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; BankAccountNo: Code[20]; AccountType: array[2] of Enum "Gen. Journal Account Type"; AccountNo: array[2] of Code[20]; TransactionAmount: array[2] of Decimal)
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        CreateBankReconciliation(BankAccReconciliation, BankAccountNo, BankAccReconciliation."Statement Type"::"Payment Application");
        CreateBankAccReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, AccountType[1], AccountNo[1], TransactionAmount[1], WorkDate());
        CreateBankAccReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, AccountType[2], AccountNo[2], TransactionAmount[2], WorkDate());
        Codeunit.Run(Codeunit::"Match Bank Pmt. Appl.", BankAccReconciliation);
        UpdateBankAccRecStmEndingBalance(BankAccReconciliation, BankAccReconciliation."Balance Last Statement" + TransactionAmount[1] + TransactionAmount[2]);
    end;

    local procedure CreatePurchaseInvoice(Date: Date)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);
        PurchaseHeader.Validate("Posting Date", Date);
        PurchaseHeader.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreateBankAccReconLineWithAmountTransferredToAcc(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccountNo: Code[20];
    begin
        BankAccountNo := CreateBankAccount();
        CreateBankReconciliation(BankAccReconciliation, BankAccountNo, BankAccReconciliation."Statement Type"::"Payment Application");
        CreateBankAccReconciliationLine(
            BankAccReconciliation, BankAccReconciliationLine, BankAccReconciliationLine."Account Type"::Vendor, LibraryPurchase.CreateVendorNo(), -LibraryRandom.RandDec(100, 2), WorkDate());
        BankAccReconciliationLine.TransferRemainingAmountToAccount();
        BankAccReconciliationLine.Find();
    end;

    local procedure MockBankAccReconLine(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; AccountType: Enum "Gen. Journal Account Type")
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
    begin
        LibraryERM.CreateBankAccReconciliation(
          BankAccReconciliation, LibraryERM.CreateBankAccountNo(), BankAccReconciliation."Statement Type"::"Payment Application");
        LibraryERM.CreateBankAccReconciliationLn(BankAccReconciliationLine, BankAccReconciliation);
        BankAccReconciliationLine.Validate("Account Type", AccountType);
    end;

    local procedure MockAppliedPmtEntry(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; AppliesToEntryNo: Integer; NewDescription: Text[50])
    var
        AppliedPaymentEntry: Record "Applied Payment Entry";
    begin
        AppliedPaymentEntry.Init();
        AppliedPaymentEntry.TransferFromBankAccReconLine(BankAccReconciliationLine);
        AppliedPaymentEntry."Applies-to Entry No." := AppliesToEntryNo;
        AppliedPaymentEntry.Description := NewDescription;
        AppliedPaymentEntry.Insert();
    end;

    local procedure MockTransactionsToImport(var TempBankAccReconLine: Record "Bank Acc. Reconciliation Line" temporary; BankAccReconciliation: Record "Bank Acc. Reconciliation"; TransactionIDList: List of [Text[50]])
    var
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
        TransactionID: Text[50];
    begin
        foreach TransactionID in TransactionIDList do begin
            CreateBankAccReconLine(BankAccReconLine, BankAccReconciliation);
            BankAccReconLine.Validate("Transaction ID", TransactionID);
            BankAccReconLine.Modify(true);

            TempBankAccReconLine := BankAccReconLine;
            TempBankAccReconLine.Insert();
        end;
        BankAccReconLine.FilterBankRecLines(BankAccReconciliation);
        BankAccReconLine.DeleteAll();
    end;

    local procedure MockPostedNotReconciledTransaction(BankAccReconciliation: Record "Bank Acc. Reconciliation"; TransactionID: Text[50])
    var
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
        PostedPaymentReconLine: Record "Posted Payment Recon. Line";
    begin
        CreateBankAccReconLine(BankAccReconLine, BankAccReconciliation);
        PostedPaymentReconLine.TransferFields(BankAccReconLine);
        PostedPaymentReconLine."Transaction ID" := TransactionID;
        PostedPaymentReconLine.Reconciled := false;
        PostedPaymentReconLine.Insert();
    end;

    local procedure CreateDimSet(DimSetID: Integer): Integer
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        exit(LibraryDimension.CreateDimSet(DimSetID, Dimension.Code, DimensionValue.Code));
    end;

    local procedure ApplyBankAccReconcilationLine(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; LedgerEntryNo: Integer; AccountType: Enum "Gen. Journal Account Type"; Description: Text[50]): Integer
    var
        AppliedPaymentEntry: Record "Applied Payment Entry";
    begin
        AppliedPaymentEntry.Init();
        AppliedPaymentEntry.TransferFromBankAccReconLine(BankAccReconciliationLine);
        AppliedPaymentEntry.Validate("Account Type", AccountType);
        AppliedPaymentEntry.Validate("Account No.", BankAccReconciliationLine."Account No.");
        AppliedPaymentEntry.Validate("Applies-to Entry No.", LedgerEntryNo);
        AppliedPaymentEntry.Description := Description;
        AppliedPaymentEntry.Insert(true);
        BankAccReconciliationLine.Find();
        exit(BankAccReconciliationLine."Dimension Set ID");
    end;

    local procedure ApplyBankAccReconLineToGLAccount(var BankAccReconLine: Record "Bank Acc. Reconciliation Line"; AccountNo: Code[20]; StatementAmount: Decimal)
    var
        AppliedPaymentEntry: Record "Applied Payment Entry";
    begin
        AppliedPaymentEntry.Init();
        AppliedPaymentEntry.TransferFromBankAccReconLine(BankAccReconLine);
        AppliedPaymentEntry.Validate("Account Type", AppliedPaymentEntry."Account Type"::"G/L Account");
        AppliedPaymentEntry.Validate("Account No.", AccountNo);
        AppliedPaymentEntry.Validate("Applied Amount", StatementAmount);
        AppliedPaymentEntry.Validate("Match Confidence", AppliedPaymentEntry."Match Confidence"::Manual);
        AppliedPaymentEntry.Insert(true);
        BankAccReconLine.Find();
    end;

    local procedure ApplyBankAccReconLineToEmployee(var BankAccReconLine: Record "Bank Acc. Reconciliation Line"; AccountNo: Code[20]; LedgerEntryNo: Integer)
    var
        AppliedPaymentEntry: Record "Applied Payment Entry";
    begin
        AppliedPaymentEntry.Init();
        AppliedPaymentEntry.TransferFromBankAccReconLine(BankAccReconLine);
        AppliedPaymentEntry.Validate("Account Type", "Gen. Journal Account Type"::Employee);
        AppliedPaymentEntry.Validate("Account No.", AccountNo);
        AppliedPaymentEntry.Validate("Applies-to Entry No.", LedgerEntryNo);
        AppliedPaymentEntry.Validate("Match Confidence", AppliedPaymentEntry."Match Confidence"::Manual);
        AppliedPaymentEntry.Insert(true);
        BankAccReconLine.Find();
    end;

    local procedure CreateSuggestedBankReconc(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; BankAccountNo: Code[20]; IncludeChecks: Boolean)
    begin
        CreateBankReconciliation(BankAccReconciliation, BankAccountNo, BankAccReconciliation."Statement Type"::"Bank Reconciliation");
        SuggestBankRecLines(BankAccReconciliation, IncludeChecks);

        // Balance Bank Account Reconciliation.
        BankAccReconciliation.Validate("Statement Ending Balance",
          BankAccReconciliation."Balance Last Statement" + BankAccRecSum(BankAccReconciliation));
        BankAccReconciliation.Modify(true);
    end;

    local procedure CreateBankReconciliationManyToOne(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; BankAccountNo: Code[20]; PaymentAmount: Decimal)
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        CreateBankReconciliation(BankAccReconciliation, BankAccountNo, BankAccReconciliation."Statement Type"::"Bank Reconciliation");

        LibraryERM.CreateBankAccReconciliationLn(BankAccReconciliationLine, BankAccReconciliation);
        BankAccReconciliationLine.Validate("Statement Amount", -PaymentAmount / 2);
        BankAccReconciliationLine.Modify();

        LibraryERM.CreateBankAccReconciliationLn(BankAccReconciliationLine, BankAccReconciliation);
        BankAccReconciliationLine.Validate("Statement Amount", -PaymentAmount / 2);
        BankAccReconciliationLine.Modify();

        BankAccReconciliation.Validate("Statement Ending Balance",
            BankAccReconciliation."Balance Last Statement" + BankAccRecSum(BankAccReconciliation));
        BankAccReconciliation.Modify(true);
    end;

    local procedure MatchBankReconciliationManyToOne(BankAccReconciliation: Record "Bank Acc. Reconciliation")
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccLedgerEntry: Record "Bank Account Ledger Entry";
        TempBankAccReconciliationLine: Record "Bank Acc. Reconciliation Line" temporary;
        TempBankAccLedgerEntry: Record "Bank Account Ledger Entry" temporary;
        MatchBankRecLines: Codeunit "Match Bank Rec. Lines";
    begin
        BankAccLedgerEntry.SetRange("Bank Account No.", BankAccReconciliation."Bank Account No.");
        BankAccLedgerEntry.FindFirst();
        TempBankAccLedgerEntry := BankAccLedgerEntry;
        TempBankAccLedgerEntry.Insert();

        BankAccReconciliationLine.SetRange("Bank Account No.", BankAccReconciliation."Bank Account No.");
        BankAccReconciliationLine.SetRange("Statement No.", BankAccReconciliation."Statement No.");
        BankAccReconciliationLine.FindSet();
        repeat
            TempBankAccReconciliationLine := BankAccReconciliationLine;
            TempBankAccReconciliationLine.Insert();
        until BankAccReconciliationLine.Next() = 0;

        MatchBankRecLines.MatchManually(TempBankAccReconciliationLine, TempBankAccLedgerEntry);
    end;

    local procedure CreatePostBankReconciliation(BankAccount: Record "Bank Account"): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
    begin
        PostPaymentJournalLineWithDateAndSource(GenJournalLine, WorkDate(), LibraryPurchase.CreateVendorNo(), BankAccount."No.");

        CreateSuggestedBankReconc(BankAccReconciliation, BankAccount."No.", false);

        LibraryERM.PostBankAccReconciliation(BankAccReconciliation);
        exit(BankAccReconciliation."Statement No.");
    end;

    local procedure UpdateGeneralShortcutDimensionSetup()
    var
        DimensionValue: Record "Dimension Value";
        i: Integer;
    begin
        for i := 1 to 8 do begin
            LibraryDimension.CreateDimWithDimValue(DimensionValue);
            LibraryERM.SetShortcutDimensionCode(i, DimensionValue."Dimension Code");
        end;
    end;

    local procedure UpdateBankAccReconciliationLineDescription(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; Description: Text[50])
    begin
        BankAccReconciliationLine.Validate(Description, Description);
        BankAccReconciliationLine.Modify(true);
    end;

    local procedure GetDimensionValueCodeFromSetEntry(DimensionSetID: Integer; ShortcutDimensionCode: Code[20]): Code[20]
    var
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        DimensionSetEntry.SetRange("Dimension Code", ShortcutDimensionCode);
        LibraryDimension.FindDimensionSetEntry(DimensionSetEntry, DimensionSetID);
        exit(DimensionSetEntry."Dimension Value Code");
    end;

    local procedure GetStatementAmountFromBankAccRecon(BankAccountNo: Code[20]): Decimal
    var
        PostedPaymentReconLine: Record "Posted Payment Recon. Line";
    begin
        PostedPaymentReconLine.SetRange("Bank Account No.", BankAccountNo);
        PostedPaymentReconLine.FindFirst();
        exit(PostedPaymentReconLine."Statement Amount");
    end;

    local procedure BankAccRecSum(BankAccReconciliation: Record "Bank Acc. Reconciliation"): Decimal
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        BankAccReconciliationLine.FilterBankRecLines(BankAccReconciliation);
        BankAccReconciliationLine.CalcSums("Statement Amount");
        exit(BankAccReconciliationLine."Statement Amount");
    end;

    local procedure MatchBankReconLineManually(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    var
        PaymentReconciliationJournal: TestPage "Payment Reconciliation Journal";
    begin
        PaymentReconciliationJournal.OpenEdit();
        PaymentReconciliationJournal.GotoRecord(BankAccReconciliationLine);
        PaymentReconciliationJournal.ApplyEntries.Invoke();
    end;

    local procedure SuggestBankRecLines(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; IncludeChecks: Boolean)
    begin
        SuggestBankRecLines(BankAccReconciliation, IncludeChecks, WorkDate(), WorkDate());
    end;

    local procedure SuggestBankRecLines(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; IncludeChecks: Boolean; NewStartDate: Date; NewEndDate: Date)
    var
        BankAccount: Record "Bank Account";
        SuggestBankAccReconLines: Report "Suggest Bank Acc. Recon. Lines";
    begin
        SuggestBankAccReconLines.SetStmt(BankAccReconciliation);
        SuggestBankAccReconLines.SetTableView(BankAccount);
        SuggestBankAccReconLines.InitializeRequest(NewStartDate, NewEndDate, IncludeChecks);
        SuggestBankAccReconLines.UseRequestPage(false);
        SuggestBankAccReconLines.Run();
    end;

    local procedure SuggestAndVerifyBankReconcLine(BankAccount: Record "Bank Account"; DocumentNo: Code[20]; IncludeChecks: Boolean)
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
    begin
        // Exercise: Suggest lines on Bank Account Reconciliation.
        CreateSuggestedBankReconc(BankAccReconciliation, BankAccount."No.", IncludeChecks);

        // Verify: Verify Check No., type on Bank Account Reconciliation Line.
        BankAccount.CalcFields(Balance);
        VerifyBankAccReconcLine(BankAccount."No.", DocumentNo, BankAccount.Balance);
    end;

    local procedure SetupBankAccReconciliation(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    begin
        CreateBankReconciliation(BankAccReconciliation, CreateBankAccount(), BankAccReconciliation."Statement Type"::"Bank Reconciliation");
        CreateBankAccReconLine(BankAccReconciliationLine, BankAccReconciliation);
    end;

    local procedure CreateBankAccReconLine(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; BankAccReconciliation: Record "Bank Acc. Reconciliation")
    begin
        LibraryERM.CreateBankAccReconciliationLn(BankAccReconciliationLine, BankAccReconciliation);
        BankAccReconciliationLine.Validate("Transaction Date", WorkDate());
        BankAccReconciliationLine.Validate("Document No.",
          LibraryUtility.GenerateRandomCode(BankAccReconciliationLine.FieldNo("Document No."), DATABASE::"Bank Acc. Reconciliation Line"));
        BankAccReconciliationLine.Validate("Statement Amount", LibraryRandom.RandDec(1000, 2));
        BankAccReconciliationLine.Validate(Description, BankAccReconciliationLine."Document No."); // required for APAC
        BankAccReconciliationLine.Modify(true);
    end;

    local procedure TransferToGenJnlReport(BankAccReconciliation: Record "Bank Acc. Reconciliation"; GenJournalBatch: Record "Gen. Journal Batch")
    var
        TransBankRecToGenJnl: Report "Trans. Bank Rec. to Gen. Jnl.";
    begin
        TransBankRecToGenJnl.SetBankAccRecon(BankAccReconciliation);
        TransBankRecToGenJnl.InitializeRequest(GenJournalBatch."Journal Template Name", GenJournalBatch.Name);
        TransBankRecToGenJnl.UseRequestPage := false;
        TransBankRecToGenJnl.Run();
    end;

    local procedure InitLastStatementNo(var BankAccount: Record "Bank Account"; NewLastStatementNo: Code[20])
    begin
        BankAccount."Last Statement No." := NewLastStatementNo;
        BankAccount.Modify();
    end;

    local procedure SetupGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch"; BalAccountType: Enum "Gen. Journal Account Type"; BankAccountNo: Code[20])
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch.Validate("Bal. Account Type", BalAccountType);
        GenJournalBatch.Validate("Bal. Account No.", BankAccountNo);
        GenJournalBatch.Modify(true);
    end;

    local procedure VerifyReversedBankLedgerEntry(BankAccountNo: Code[20]; DocumentNo: Code[20]; Amount: Decimal)
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        BankAccountLedgerEntry.SetRange("Bank Account No.", BankAccountNo);
        BankAccountLedgerEntry.SetRange("Document No.", DocumentNo);
        BankAccountLedgerEntry.SetRange(Reversed, true);
        BankAccountLedgerEntry.SetFilter("Reversed Entry No.", '<>0');
        BankAccountLedgerEntry.FindFirst();
        Assert.AreNearlyEqual(
          Amount, BankAccountLedgerEntry.Amount, GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(WrongAmountErr, BankAccountLedgerEntry.Amount, Amount));
    end;

    local procedure VerifyBankRecLedgerEntry(AccountNo: Code[20]; DocumentNo: Code[20])
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
    begin
        BankAccountLedgerEntry.SetRange("Bank Account No.", AccountNo);
        BankAccountLedgerEntry.SetRange("Document No.", DocumentNo);
        BankAccountLedgerEntry.FindSet();

        repeat
            Assert.IsFalse(BankAccountLedgerEntry.Open, 'Bank ledger entry did not close:');
        until BankAccountLedgerEntry.Next() = 0;
    end;

    local procedure VerifyBankAccReconcLine(BankAccountNo: Code[20]; DocumentNo: Code[20]; Amount: Decimal)
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        BankAccReconciliationLine.SetRange("Bank Account No.", BankAccountNo);
        BankAccReconciliationLine.FindFirst();
        BankAccReconciliationLine.TestField("Document No.", DocumentNo);
        BankAccReconciliationLine.TestField("Statement Amount", Amount);
        BankAccReconciliationLine.TestField("Applied Amount", Amount);
    end;

    local procedure VerifyBankAccountLastStatementFields(BankAccountNo: Code[20]; LastPaymentStatementNo: Code[20]; LastStatementNo: Code[20]; BalanceLastStatement: Decimal)
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount.Get(BankAccountNo);
        BankAccount.TestField("Last Payment Statement No.", LastPaymentStatementNo);
        BankAccount.TestField("Last Statement No.", LastStatementNo);
        BankAccount.TestField("Balance Last Statement", BalanceLastStatement);
    end;

    local procedure VerifyBankLedgerEntryRemainingAmount(BankAccountNo: Code[20]; DocumentNo: Code[20]; ExpectedRemainingAmount: Decimal)
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
    begin
        FindBankLedgerEntry(BankAccountLedgerEntry, BankAccountNo, DocumentNo);
        BankAccountLedgerEntry.TestField("Remaining Amount", ExpectedRemainingAmount);
    end;

    local procedure FindBankLedgerEntry(var BankAccountLedgerEntry: Record "Bank Account Ledger Entry"; BankAccountNo: Code[20]; DocumentNo: Code[20])
    begin
        BankAccountLedgerEntry.SetRange("Bank Account No.", BankAccountNo);
        BankAccountLedgerEntry.SetRange("Document No.", DocumentNo);
        BankAccountLedgerEntry.FindFirst();
    end;

    local procedure FindCheckLedgerEntry(var CheckLedgerEntry: Record "Check Ledger Entry"; BankAccountNo: Code[20]; DocumentNo: Code[20])
    begin
        CheckLedgerEntry.SetRange("Bank Account No.", BankAccountNo);
        CheckLedgerEntry.SetRange("Document No.", DocumentNo);
        CheckLedgerEntry.FindFirst();
    end;

    local procedure VerifyUndoneCheckLedgerEntry(BankAccountNo: Code[20]; DocumentNo: Code[20]; NewStatementNo: Code[20])
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        CheckLedgerEntry: Record "Check Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        BankAccReconciliationLine.SetRange("Bank Account No.", BankAccountNo);
        BankAccReconciliationLine.SetRange("Statement No.", NewStatementNo);
        BankAccReconciliationLine.FindFirst();

        CheckLedgerEntry.SetRange("Bank Account No.", BankAccountNo);
        CheckLedgerEntry.SetRange("Document No.", DocumentNo);
        CheckLedgerEntry.FindFirst();
        case CheckLedgerEntry."Statement Status" of
            CheckLedgerEntry."Statement Status"::"Check Entry Applied":
                begin
                    CheckLedgerEntry.TestField(Open, true);
                    CheckLedgerEntry.TestField("Statement No.", NewStatementNo);
                    CheckLedgerEntry.TestField("Statement Line No.", BankAccReconciliationLine."Statement Line No.");
                end;
            CheckLedgerEntry."Statement Status"::"Bank Acc. Entry Applied":
                begin
                    CheckLedgerEntry.TestField("Statement No.", NewStatementNo);
                    CheckLedgerEntry.TestField("Statement Line No.", BankAccReconciliationLine."Statement Line No.");
                end;
        end;

        BankAccountLedgerEntry.SetRange("Bank Account No.", BankAccountNo);
        BankAccountLedgerEntry.SetRange("Document No.", DocumentNo);
        BankAccountLedgerEntry.FindFirst();
        case BankAccountLedgerEntry."Statement Status" of
            BankAccountLedgerEntry."Statement Status"::"Check Entry Applied":
                begin
                    BankAccountLedgerEntry.TestField("Statement No.", NewStatementNo);
                    BankAccountLedgerEntry.TestField("Statement Line No.", BankAccReconciliationLine."Statement Line No.");
                end;
            BankAccountLedgerEntry."Statement Status"::"Bank Acc. Entry Applied":
                begin
                    BankAccountLedgerEntry.TestField("Statement No.", NewStatementNo);
                    BankAccountLedgerEntry.TestField("Statement Line No.", BankAccReconciliationLine."Statement Line No.");
                end;
        end;
    end;

    local procedure VerifyUndoneCheckLedgerEntryManyToOne(BankAccountNo: Code[20]; DocumentNo: Code[20]; NewStatementNo: Code[20])
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        CheckLedgerEntry: Record "Check Ledger Entry";
    begin
        CheckLedgerEntry.SetRange("Bank Account No.", BankAccountNo);
        CheckLedgerEntry.SetRange("Document No.", DocumentNo);
        CheckLedgerEntry.FindFirst();
        CheckLedgerEntry.TestField("Statement Status", CheckLedgerEntry."Statement Status"::"Bank Acc. Entry Applied");
        CheckLedgerEntry.TestField("Statement No.", NewStatementNo);

        BankAccountLedgerEntry.SetRange("Bank Account No.", BankAccountNo);
        BankAccountLedgerEntry.SetRange("Document No.", DocumentNo);
        BankAccountLedgerEntry.FindFirst();
        BankAccountLedgerEntry.TestField("Statement Status", BankAccountLedgerEntry."Statement Status"::"Bank Acc. Entry Applied");
        BankAccountLedgerEntry.TestField("Statement No.", NewStatementNo);
        BankAccountLedgerEntry.TestField("Statement Line No.", -1);
    end;

    local procedure VerifyCustLedgerEntry(CustomerNo: Code[20]; DocumentNo: Code[20]; DimSetID: Integer)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.TestField("Dimension Set ID", DimSetID);
    end;

    local procedure VerifyVendLedgerEntry(VendorNo: Code[20]; DocumentNo: Code[20]; DimSetID: Integer)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.SetRange("Document No.", DocumentNo);
        VendorLedgerEntry.FindFirst();
        VendorLedgerEntry.TestField("Dimension Set ID", DimSetID);
    end;

    local procedure VerifyDimSetEntryValue(DimSetID: Integer; DimValueCode: Code[20])
    var
        DummyDimensionSetEntry: Record "Dimension Set Entry";
    begin
        DummyDimensionSetEntry.SetRange("Dimension Set ID", DimSetID);
        DummyDimensionSetEntry.SetRange("Dimension Value Code", DimValueCode);
        DummyDimensionSetEntry.FindFirst();
        Assert.RecordIsNotEmpty(DummyDimensionSetEntry);
    end;

    local procedure VerifyGlobalDimensionCodeAndSetInGLEntry(GLAccNo: Code[20]; ExpectedGlobal1DimensionCode: Code[20]; ExpectedDimSetID: Integer)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("G/L Account No.", GLAccNo);
        GLEntry.FindFirst();
        GLEntry.TestField("Global Dimension 1 Code", ExpectedGlobal1DimensionCode);
        GLEntry.TestField("Dimension Set ID", ExpectedDimSetID);
    end;

    local procedure VerifyGenJournalLine(GenJournalTemplateNo: Code[50]; GenJournalBatchNo: Code[50]; ExpectedAmount: Decimal; BalAccountType: Enum "Gen. Journal Account Type"; BAlAccountNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetRange("Journal Template Name", GenJournalTemplateNo);
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatchNo);
        GenJournalLine.FindFirst();
        GenJournalLine.TestField("Bal. Account Type", BalAccountType);
        GenJournalLine.TestField("Bal. Account No.", BAlAccountNo);
        GenJournalLine.TestField(Amount, ExpectedAmount);
    end;

    local procedure VerifyGenJournalLineDocNosSequential(GenJournalTemplateName: Code[10]; GenJournalBatchName: Code[10])
    var
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
    begin
        GenJournalLine.SetRange("Journal Template Name", GenJournalTemplateName);
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatchName);
        GenJournalLine.FindSet();
        DocumentNo := GenJournalLine."Document No.";
        DocumentNo := IncStr(DocumentNo);
        GenJournalLine.Next();
        GenJournalLine.TestField("Document No.", DocumentNo);
    end;

    local procedure VerifyGLEntryAmount(DocNo: Code[20]; AccNo: Code[20]; ExpectedAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Payment);
        GLEntry.SetRange("Document No.", DocNo);
        GLEntry.SetRange("G/L Account No.", AccNo);
        GLEntry.FindFirst();
        GLEntry.TestField(Amount, ExpectedAmount);
    end;

    local procedure VerifyGLEntryWithDescriptionExists(LastEntryNo: Integer; Description: Text[50])
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetFilter("Entry No.", '>%1', LastEntryNo);
        GLEntry.SetRange(Description, Description);
        Assert.RecordIsNotEmpty(GLEntry);
    end;

    local procedure VerifyEmployeeLedgerEntry(EmployeeNo: Code[20]; StatementNo: Code[20]; Amount: Decimal; DocumentType: Enum "Gen. Journal Document Type")
    var
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
    begin
        EmployeeLedgerEntry.SetRange("Employee No.", EmployeeNo);
        EmployeeLedgerEntry.SetRange("Document Type", DocumentType);
        EmployeeLedgerEntry.SetRange("Document No.", StatementNo);
        EmployeeLedgerEntry.FindFirst();
        EmployeeLedgerEntry.CalcFields(Amount);
        EmployeeLedgerEntry.TestField(Amount, Amount);
        EmployeeLedgerEntry.TestField(Open, false);
    end;

    local procedure VerifyPaymentApplicationEmployee(Employee: Record Employee; ExpectedAmount: Decimal)
    begin
        Assert.AreEqual(Employee.FullName(), LibraryVariableStorage.DequeueText(), 'Invalid Account Name');
        Assert.AreEqual(Employee.FullName(), LibraryVariableStorage.DequeueText(), 'Invalid Description');
        Assert.AreEqual(Format(ExpectedAmount), LibraryVariableStorage.DequeueText(), 'Invalid Remaining Amt. Incl. Discount');
        Assert.AreEqual(Format(ExpectedAmount), LibraryVariableStorage.DequeueText(), 'Invalid Remaining Amount After Posting');
    end;

    local procedure VerifyPostedPaymentReconciliationReport(BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('BankAccNo_PostedPaymentReconciliation', BankAccReconciliationLine."Bank Account No.");
        LibraryReportDataset.AssertElementWithValueExists('StmtNo_PostedPaymentReconciliation', BankAccReconciliationLine."Statement No.");
        LibraryReportDataset.AssertElementWithValueExists('Desc_PostedPaymentReconciliationLine', BankAccReconciliationLine.Description);
        LibraryReportDataset.AssertElementWithValueExists('AppliedAmt1_PostedPaymentReconciliationLine', BankAccReconciliationLine."Applied Amount");
    end;

    local procedure VerifyLastBankAccountStatementAmounts(BankAccountNo: Code[20]; BalanceLastStatement: Decimal; StatementEndingBalance: Decimal)
    var
        BankAccountStatement: Record "Bank Account Statement";
    begin
        BankAccountStatement.SetRange("Bank Account No.", BankAccountNo);
        BankAccountStatement.FindLast();
        BankAccountStatement.TestField("Balance Last Statement", BalanceLastStatement);
        BankAccountStatement.TestField("Statement Ending Balance", StatementEndingBalance);
    end;

    local procedure CreatePaymentJournalLineWithVendorAndBank(var GenJournalLine: Record "Gen. Journal Line"; AccountNo: Code[20]; BankAccountNo: Code[20]; PostingDate: Date): Code[20]
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, AccountNo,
          LibraryRandom.RandDecInRange(1000, 2000, 2));
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Bal. Account No.", BankAccountNo);
        GenJournalLine.Modify(true);

        exit(GenJournalLine."Document No.");
    end;

    local procedure SuggestLines(BankAccReconciliation: Record "Bank Acc. Reconciliation")
    var
        BankAccount: Record "Bank Account";
        SuggestBankAccReconLines: Report "Suggest Bank Acc. Recon. Lines";
    begin
        Clear(SuggestBankAccReconLines);
        BankAccount.SetRange("No.", BankAccReconciliation."Bank Account No.");
        SuggestBankAccReconLines.SetTableView(BankAccount);
        SuggestBankAccReconLines.InitializeRequest(WorkDate(), WorkDate(), false);
        SuggestBankAccReconLines.UseRequestPage(false);
        SuggestBankAccReconLines.SetStmt(BankAccReconciliation);
        SuggestBankAccReconLines.Run();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        // Handler for confirmation messages, always send positive reply.
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerNo(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmEnqueueQuestionHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        LibraryVariableStorage.Enqueue(Question);
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
    procedure MessageWithVerificationHandler(Message: Text[1024])
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Message);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure DeleteStatementConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    var
        Confirm: Variant;
    begin
        LibraryVariableStorage.Dequeue(Confirm);

        Assert.IsTrue(StrPos(Question, HasBankEntriesMsg) > 0, 'Unexpected message.');
        Reply := Confirm;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure GenJnlPageHandler(var GeneralJournal: TestPage "General Journal")
    begin
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure GeneralJournalPageHandler(var GeneralJournal: TestPage "General Journal")
    begin
        GeneralJournal."Account No.".SetValue(LibraryVariableStorage.DequeueText());
        Assert.IsTrue(Format(GeneralJournal."Account No.") <> '', StrSubstNo(AccountNoMustBeEqualToErr, GeneralJournal."Account No."));
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure TransToDiffAccModalPageHandler(var TransferDifferencetoAccount: TestPage "Transfer Difference to Account")
    begin
        TransferDifferencetoAccount."Account No.".SetValue(LibraryVariableStorage.DequeueText());
        TransferDifferencetoAccount.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BankAccReconTestRequestPageHandler(var BankAccReconTest: TestRequestPage "Bank Acc. Recon. - Test")
    begin
        BankAccReconTest.PrintOutstdTransac.SetValue(LibraryVariableStorage.DequeueBoolean());
        BankAccReconTest.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BankAccountStatementRequestPageHandler(var BankAccountStatement: TestRequestPage "Bank Account Statement")
    begin
        BankAccountStatement.PrintOutstandingTransaction.SetValue(LibraryVariableStorage.DequeueBoolean());
        BankAccountStatement.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PaymentApplicationModalPageHandler(var PaymentApplication: TestPage "Payment Application")
    begin
        PaymentApplication.FILTER.SetFilter("Account No.", LibraryVariableStorage.DequeueText());
        PaymentApplication.FILTER.SetFilter("Document No.", LibraryVariableStorage.DequeueText());
        PaymentApplication.Applied.SetValue(true);
        PaymentApplication.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PaymentApplicationWithReducedAmtModalPageHandler(var PaymentApplication: TestPage "Payment Application")
    begin
        PaymentApplication.FILTER.SetFilter("Account No.", LibraryVariableStorage.DequeueText());
        PaymentApplication.AppliedAmount.SetValue(LibraryVariableStorage.DequeueDecimal());
        PaymentApplication.Accept.Invoke();
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure VerifyNotificationIsSend(var Notification: Notification): Boolean;
    begin
        Assert.AreEqual('No bank statement lines exist. Choose the Import Bank Statement action to fill in the lines from a file, or enter lines manually.',
          Notification.Message,
          'A notification should have been shown with the expected text');
    end;

    local procedure UpdateBankAccRecStmEndingBalance(var BankAccRecon: Record "Bank Acc. Reconciliation"; NewStmEndingBalance: Decimal)
    begin
        BankAccRecon.Validate("Statement Ending Balance", NewStmEndingBalance);
        BankAccRecon.Modify();
    end;

    local procedure CreateCurrencyCode(): Code[10]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        Currency: Record Currency;
    begin
        GeneralLedgerSetup.Get();

        LibraryERM.CreateCurrency(Currency);
        LibraryERM.SetCurrencyGainLossAccounts(Currency);
        Currency.Validate("Invoice Rounding Precision", GeneralLedgerSetup."Inv. Rounding Precision (LCY)");
        Currency.Validate("EMU Currency", true);
        Currency.Validate("Amount Rounding Precision", 0.0001);
        Currency.Validate("Invoice Rounding Precision", 0.0001);
        Currency.Validate("Amount Decimal Places", '2:2');
        Currency.Validate("Unit-Amount Decimal Places", '2:5');
        Currency.Modify(true);

        LibraryERM.CreateRandomExchangeRate(Currency.Code);

        exit(Currency.Code);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ChangeStatementNoModalPageHandler(var ChangeBankRecStatementNo: TestPage "Change Bank Rec. Statement No.")
    begin
        ChangeBankRecStatementNo.NewStatementNumber.SetValue(LibraryVariableStorage.DequeueText());
        ChangeBankRecStatementNo.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PaymentApplicationPageWithEmployee(var PaymentApplication: TestPage "Payment Application")
    var
        Employee: Record Employee;
    begin
        Employee.Get(LibraryVariableStorage.DequeueText());
        PaymentApplication.Filter.SetFilter("Account No.", Employee."No.");
        Assert.IsTrue(PaymentApplication.First(), 'Employee entry not found');
        LibraryVariableStorage.Enqueue(PaymentApplication.AccountName.Value);
        LibraryVariableStorage.Enqueue(PaymentApplication.Description.Value);
        LibraryVariableStorage.Enqueue(PaymentApplication."Remaining Amt. Incl. Discount".Value);
        LibraryVariableStorage.Enqueue(PaymentApplication.RemainingAmountAfterPosting.Value);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PaymentApplicationPageWithEmployeeApply(var PaymentApplication: TestPage "Payment Application")
    begin
        PaymentApplication.Filter.SetFilter("Account No.", LibraryVariableStorage.DequeueText());
        Assert.IsTrue(PaymentApplication.First(), 'Employee entry not found');
        PaymentApplication.AppliedAmount.SetValue(LibraryVariableStorage.DequeueDecimal());
        PaymentApplication.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PostedPaymentReconciliationReportRequestPageHandler(var PostedPaymentReconciliation: TestRequestPage "Posted Payment Reconciliation")
    begin
        PostedPaymentReconciliation.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName())
    end;

    [RequestPageHandler]
    procedure SuggestLinesRequestPageHandler(var SuggestBankAccReconLines: TestRequestPage "Suggest Bank Acc. Recon. Lines")
    begin
        SuggestBankAccReconLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostAndReconcilePageHandler(var PostPmtsAndRecBankAcc: TestPage "Post Pmts and Rec. Bank Acc.")
    begin
        PostPmtsAndRecBankAcc.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure PostAndReconcilePageStatementDateHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    procedure SameBankReconciliationConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostAndReconcileWithEndingBalanceModalPageHandler(var PostPmtsAndRecBankAcc: TestPage "Post Pmts and Rec. Bank Acc.")
    begin
        PostPmtsAndRecBankAcc."Statement Ending Balance".SetValue(LibraryVariableStorage.DequeueDecimal());
        PostPmtsAndRecBankAcc.OK().Invoke();
    end;

    [StrMenuHandler]
    procedure CorruptSuggestLinesHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        case TimesSuggestLinesRun of
            0:
                // [THEN] When User says "Yes" (2) the first time it should ask again for the next entry
                Choice := 2;
            1:
                // [THEN] When User says "Yes" (2) the second time it should ask again for the next entry
                Choice := 2;
            2:
                // [THEN] When User says  "Yes to all" (1) the third time it should skip the confirmation for the next entries
                Choice := 1;
            else
                Error('Suggest Lines shouldn''t keep asking to confirm for these entries');
        end;
        TimesSuggestLinesRun += 1;
    end;


}
