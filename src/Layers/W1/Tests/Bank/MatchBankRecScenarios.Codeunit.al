codeunit 134253 "Match Bank Rec. Scenarios"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Bank Reconciliation]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        FileMgt: Codeunit "File Management";
        isInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure AddToMatchPartialBRL()
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationPage: TestPage "Bank Acc. Reconciliation";
        Amount: Decimal;
    begin
        Initialize();

        // Setup.
        SetupManualMatch(BankAccReconciliation, BankAccReconciliationPage, Amount, 1.5);
        BankAccReconciliationPage.MatchManually.Invoke();
        BankAccReconciliationLine.SetRange("Statement Type", BankAccReconciliation."Statement Type");
        BankAccReconciliationLine.SetRange("Bank Account No.", BankAccReconciliation."Bank Account No.");
        BankAccReconciliationLine.SetRange("Statement No.", BankAccReconciliation."Statement No.");
        BankAccReconciliationLine.FindFirst();

        // Exercise: Add to Match.
        LibraryLowerPermissions.SetBanking();
        BankAccReconciliationPage.ApplyBankLedgerEntries.Last();
        BankAccReconciliationPage.MatchManually.Invoke();

        // Verify.
        VerifyOneToManyMatch(BankAccReconciliation, BankAccReconciliationLine."Statement Line No.", 2, 2 * Amount);
        BankAccReconciliationPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AddToMatchPartialBLE()
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationPage: TestPage "Bank Acc. Reconciliation";
        Amount: Decimal;
    begin
        Initialize();

        // Setup.
        SetupManualMatch(BankAccReconciliation, BankAccReconciliationPage, Amount, 2.5);
        BankAccReconciliationPage.MatchManually.Invoke();
        BankAccReconciliationLine.SetRange("Statement Type", BankAccReconciliation."Statement Type");
        BankAccReconciliationLine.SetRange("Bank Account No.", BankAccReconciliation."Bank Account No.");
        BankAccReconciliationLine.SetRange("Statement No.", BankAccReconciliation."Statement No.");
        BankAccReconciliationLine.FindFirst();

        // Exercise: Add to Match.
        LibraryLowerPermissions.SetBanking();
        BankAccReconciliationPage.ApplyBankLedgerEntries.Last();
        BankAccReconciliationPage.MatchManually.Invoke();

        // Verify.
        VerifyOneToManyMatch(BankAccReconciliation, BankAccReconciliationLine."Statement Line No.", 2, 2 * Amount);
        BankAccReconciliationPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReplaceMatch()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccReconciliationPage: TestPage "Bank Acc. Reconciliation";
        Amount: Decimal;
    begin
        Initialize();

        // Setup.
        SetupManualMatch(BankAccReconciliation, BankAccReconciliationPage, Amount, 1);
        BankAccReconciliationPage.MatchManually.Invoke();
        BankAccReconciliationLine.SetRange("Statement Type", BankAccReconciliation."Statement Type");
        BankAccReconciliationLine.SetRange("Bank Account No.", BankAccReconciliation."Bank Account No.");
        BankAccReconciliationLine.SetRange("Statement No.", BankAccReconciliation."Statement No.");
        BankAccReconciliationLine.FindLast();

        // Exercise: Replace Match.
        LibraryLowerPermissions.SetBanking();
        BankAccReconciliationPage.StmtLine.GotoRecord(BankAccReconciliationLine);
        BankAccReconciliationPage.ApplyBankLedgerEntries.First();
        BankAccReconciliationPage.MatchManually.Invoke();

        // Verify.
        VerifyOneToManyMatch(BankAccReconciliation, BankAccReconciliationLine."Statement Line No.", 1, Amount);
        BankAccReconciliationLine.FindFirst();
        VerifyOneToManyMatch(BankAccReconciliation, BankAccReconciliationLine."Statement Line No.", 0, 0);
        VerifyBalance(BankAccReconciliationPage, BankAccReconciliation."Bank Account No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RemoveManyToMany()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccReconciliationPage: TestPage "Bank Acc. Reconciliation";
        Amount: Decimal;
    begin
        Initialize();

        // Setup.
        SetupManualMatch(BankAccReconciliation, BankAccReconciliationPage, Amount, 1);
        BankAccReconciliationPage.MatchManually.Invoke();
        BankAccReconciliationPage.StmtLine.Last();
        BankAccReconciliationPage.ApplyBankLedgerEntries.Last();
        BankAccReconciliationPage.MatchManually.Invoke();

        // Exercise: Remove Match.
        LibraryLowerPermissions.SetBanking();
        BankAccReconciliationPage.StmtLine.First();
        BankAccReconciliationPage.ApplyBankLedgerEntries.Last();
        BankAccReconciliationPage.RemoveMatch.Invoke();

        // Verify.
        BankAccReconciliationLine.SetRange("Statement Type", BankAccReconciliation."Statement Type");
        BankAccReconciliationLine.SetRange("Bank Account No.", BankAccReconciliation."Bank Account No.");
        BankAccReconciliationLine.SetRange("Statement No.", BankAccReconciliation."Statement No.");
        BankAccReconciliationLine.FindLast();
        VerifyOneToManyMatch(BankAccReconciliation, BankAccReconciliationLine."Statement Line No.", 0, 0);
        BankAccReconciliationLine.FindFirst();
        VerifyOneToManyMatch(BankAccReconciliation, BankAccReconciliationLine."Statement Line No.", 0, 0);
        VerifyBalance(BankAccReconciliationPage, BankAccReconciliation."Bank Account No.");
    end;

    [Test]
    [HandlerFunctions('TransferToGenJnlReqPageHandler,GenJnlPageHandler')]
    [Scope('OnPrem')]
    procedure TransferToGenJnl()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationPage: TestPage "Bank Acc. Reconciliation";
        Amount: Decimal;
    begin
        Initialize();

        // Setup.
        SetupManualMatch(BankAccReconciliation, BankAccReconciliationPage, Amount, 1.5);
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);

        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch."Bal. Account Type" := GenJournalBatch."Bal. Account Type"::"Bank Account";
        GenJournalBatch."Bal. Account No." := BankAccReconciliation."Bank Account No.";
        GenJournalBatch.Modify();

        // For running the report:
        LibraryVariableStorage.Enqueue(GenJournalBatch."Journal Template Name");
        LibraryVariableStorage.Enqueue(GenJournalBatch.Name);
        // For page validation:
        LibraryVariableStorage.Enqueue(GenJournalBatch.Name);
        LibraryVariableStorage.Enqueue(BankAccReconciliation."Bank Account No.");

        // Exercise: Transfer to Gen Jnl.
        Commit();
        LibraryLowerPermissions.SetBanking();
        BankAccReconciliationPage."Transfer to General Journal".Invoke();

        // Verify: In the page handler.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FilterMatchedEntries()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationPage: TestPage "Bank Acc. Reconciliation";
        Amount: Decimal;
    begin
        Initialize();

        // Setup.
        SetupManualMatch(BankAccReconciliation, BankAccReconciliationPage, Amount, 1);

        // Exercise: Filter.
        LibraryLowerPermissions.SetBanking();
        BankAccReconciliationPage.NotMatched.Invoke();

        // Verify.
        Assert.AreEqual('<>0', BankAccReconciliationPage.StmtLine.FILTER.GetFilter(Difference), 'Wrong filter.');
        Assert.AreEqual('''''', BankAccReconciliationPage.ApplyBankLedgerEntries.FILTER.GetFilter("Statement No."), 'Wrong filter.');
        Assert.AreEqual('0', BankAccReconciliationPage.ApplyBankLedgerEntries.FILTER.GetFilter("Statement Line No."), 'Wrong filter.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RemoveFilters()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationPage: TestPage "Bank Acc. Reconciliation";
        Amount: Decimal;
    begin
        Initialize();

        // Setup.
        SetupManualMatch(BankAccReconciliation, BankAccReconciliationPage, Amount, 1);

        // Exercise: Filter.
        LibraryLowerPermissions.SetBanking();
        BankAccReconciliationPage.NotMatched.Invoke();
        BankAccReconciliationPage.All.Invoke();

        // Verify.
        Assert.AreEqual('', BankAccReconciliationPage.StmtLine.FILTER.GetFilter(Difference), 'Wrong filter.');
        Assert.AreEqual('', BankAccReconciliationPage.ApplyBankLedgerEntries.FILTER.GetFilter("Statement No."), 'Wrong filter.');
        Assert.AreEqual('', BankAccReconciliationPage.ApplyBankLedgerEntries.FILTER.GetFilter("Statement Line No."), 'Wrong filter.');
    end;

    [Test]
    [HandlerFunctions('MatchRecLinesReqPageHandler,MessageHandler,ConfirmHandler,BankStatementPagePostHandler')]
    [Scope('OnPrem')]
    procedure PostMatch()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationPage: TestPage "Bank Acc. Reconciliation";
        Amount: Decimal;
    begin
        Initialize();

        // Setup.
        SetupManualMatch(BankAccReconciliation, BankAccReconciliationPage, Amount, 1);
        LibraryVariableStorage.Enqueue(BankAccReconciliationPage.StatementNo.Value);
        Commit();
        BankAccReconciliationPage.MatchAutomatically.Invoke();
        BankAccReconciliationPage.StatementEndingBalance.SetValue(BankAccReconciliationPage.StmtLine.TotalBalance.AsDecimal());

        // Exercise: Add to Match.
        LibraryLowerPermissions.SetBanking();
        BankAccReconciliationPage.Post.Invoke();

        // Verify.
        VerifyPosting(BankAccReconciliation, 2);
    end;

    [Test]
    [HandlerFunctions('PostAndReconcilePageHandler,PostAndReconcilePageStatementDateHandler')]
    [Scope('OnPrem')]
    procedure GLEntryPaymentDocTypeAfterPostPmtReconJnlWithGLAccAndPositiveAmount()
    begin
        // [SCENARIO 374756] GLEntry."Document Type"=Payment after posting Payment Reconciliation Journal with GLAccount and positive Statement Amount
        // [GIVEN] Payment Reconciliation Journal with GLAccount and positive amount
        // [WHEN] Post Reconciliation Journal
        // [THEN] Posted GLEntry."Document Type" = Payment
        GLEntryPaymentDocTypeAfterPostPmtReconJnlWithGLAcc(0.01);
    end;

    [Test]
    [HandlerFunctions('PostAndReconcilePageHandler,PostAndReconcilePageStatementDateHandler')]
    [Scope('OnPrem')]
    procedure GLEntryPaymentDocTypeAfterPostPmtReconJnlWithGLAccAndNegativeAmount()
    begin
        // [SCENARIO 374756] GLEntry."Document Type"=Payment after posting Payment Reconciliation Journal with GLAccount and positive Statement Amount
        // [GIVEN] Payment Reconciliation Journal with GLAccount and negative amount
        // [WHEN] Post Reconciliation Journal
        // [THEN] Posted GLEntry."Document Type" = Payment
        GLEntryPaymentDocTypeAfterPostPmtReconJnlWithGLAcc(-0.01);
    end;

    [Test]
    [HandlerFunctions('CheckSaveAsPdfReportHandler')]
    [Scope('OnPrem')]
    procedure RemoveMatchOnChecks()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        TempBankAccReconciliationLine: Record "Bank Acc. Reconciliation Line" temporary;
        TempBankAccLedgerEntry: Record "Bank Account Ledger Entry" temporary;
        BankAccLedgerEntry: Record "Bank Account Ledger Entry";
        MatchBankRecLines: Codeunit "Match Bank Rec. Lines";
        BankAccountNo: Code[20];
        StatementLineNo: Integer;
        EntryNo: Integer;
        BankAccLedgerEntryNos: List of [Integer];
        BankAccReconStmtLineNos: List of [Integer];
        UnappliedBankAccLedgerEntries: List of [Integer];
        UnappliedCheckLedgerEntryNos: List of [Integer];
        CheckLedgerEntryNos: List of [Integer];
    begin
        // [FEATURE] [Check]
        // [SCENARIO 342941] Run RemoveMatch function of "Match Bank Rec. Lines" codeunit on Bank Account Reconciliation Lines and applied Bank Acc. Ledger Entries.
        Initialize();

        // [GIVEN] Three Bank Account Reconciliation Lines R1, R2, R3 with Type "Check Ledger Entry".
        // [GIVEN] Each Reconciliation Line has three applied Check Ledger Entries C1..C9.
        BankAccountNo := CreateBankAccount();
        LibraryERM.CreateBankAccReconciliation(BankAccReconciliation, BankAccountNo, BankAccReconciliation."Statement Type"::"Bank Reconciliation");
        CreateBankAccReconLinesWithCheckType(BankAccReconStmtLineNos, BankAccReconciliation, 3);
        foreach StatementLineNo in BankAccReconStmtLineNos do begin
            CreateBankAccLedgerEntriesWithCheckLedgerEntries(BankAccLedgerEntryNos, CheckLedgerEntryNos, BankAccountNo, 3);
            BankAccReconciliationLine.Get(
                BankAccReconciliation."Statement Type", BankAccountNo, BankAccReconciliation."Statement No.", StatementLineNo);
            ApplyCheckEntriesToBankAccReconLine(BankAccReconciliationLine, CheckLedgerEntryNos);

            UnappliedBankAccLedgerEntries.AddRange(BankAccLedgerEntryNos);
            UnappliedCheckLedgerEntryNos.AddRange(CheckLedgerEntryNos);
            TempBankAccReconciliationLine := BankAccReconciliationLine;
            TempBankAccReconciliationLine.Insert();
        end;
        foreach EntryNo in UnappliedBankAccLedgerEntries do begin
            BankAccLedgerEntry.Get(EntryNo);
            TempBankAccLedgerEntry := BankAccLedgerEntry;
            TempBankAccLedgerEntry.Insert();
        end;

        // [WHEN] Run RemoveMatch function of "Match Bank Rec. Lines" codeunit on Bank Account Reconciliation Lines R1, R2, R3.
        // [WHEN] Run RemoveMatch function of "Match Bank Rec. Lines" codeunit on Bank Account Ledger Entries C1..C9.
        MatchBankRecLines.RemoveMatch(TempBankAccReconciliationLine, TempBankAccLedgerEntry);

        // [THEN] Bank Account Reconciliation Lines R1, R2, R3 were unapplied from their Check Ledger Entries.
        VerifyEntriesUnapplied(TempBankAccReconciliationLine, UnappliedCheckLedgerEntryNos);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CheckSaveAsPdfReportHandler')]
    [Scope('OnPrem')]
    procedure RemoveMatchOnChecksWhenRunOnBankAccReconLines()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        TempBankAccReconciliationLine: Record "Bank Acc. Reconciliation Line" temporary;
        DummyTempBankAccLedgerEntry: Record "Bank Account Ledger Entry" temporary;
        MatchBankRecLines: Codeunit "Match Bank Rec. Lines";
        BankAccountNo: Code[20];
        StatementLineNo: Integer;
        BankAccLedgerEntryNos: List of [Integer];
        BankAccReconStmtLineNos: List of [Integer];
        UnappliedCheckLedgerEntryNos: List of [Integer];
        CheckLedgerEntryNos: List of [Integer];
    begin
        // [FEATURE] [Check]
        // [SCENARIO 342941] Run RemoveMatch function of "Match Bank Rec. Lines" codeunit on Bank Account Reconciliation Lines.
        Initialize();

        // [GIVEN] Three Bank Account Reconciliation Lines R1, R2, R3 with Type "Check Ledger Entry".
        // [GIVEN] Each Reconciliation Line has three applied Check Ledger Entries.
        BankAccountNo := CreateBankAccount();
        LibraryERM.CreateBankAccReconciliation(BankAccReconciliation, BankAccountNo, BankAccReconciliation."Statement Type"::"Bank Reconciliation");
        CreateBankAccReconLinesWithCheckType(BankAccReconStmtLineNos, BankAccReconciliation, 2);
        foreach StatementLineNo in BankAccReconStmtLineNos do begin
            CreateBankAccLedgerEntriesWithCheckLedgerEntries(BankAccLedgerEntryNos, CheckLedgerEntryNos, BankAccountNo, 3);
            BankAccReconciliationLine.Get(
                BankAccReconciliation."Statement Type", BankAccountNo, BankAccReconciliation."Statement No.", StatementLineNo);
            ApplyCheckEntriesToBankAccReconLine(BankAccReconciliationLine, CheckLedgerEntryNos);

            UnappliedCheckLedgerEntryNos.AddRange(CheckLedgerEntryNos);
            TempBankAccReconciliationLine := BankAccReconciliationLine;
            TempBankAccReconciliationLine.Insert();
        end;

        CreateBankAccReconLinesWithCheckType(BankAccReconStmtLineNos, BankAccReconciliation, 1);
        CreateBankAccLedgerEntriesWithCheckLedgerEntries(BankAccLedgerEntryNos, CheckLedgerEntryNos, BankAccountNo, 3);
        BankAccReconciliationLine.Get(
            BankAccReconciliation."Statement Type", BankAccountNo, BankAccReconciliation."Statement No.", BankAccReconStmtLineNos.Get(1));
        ApplyCheckEntriesToBankAccReconLine(BankAccReconciliationLine, CheckLedgerEntryNos);

        // [WHEN] Run RemoveMatch function of "Match Bank Rec. Lines" codeunit on Bank Account Reconciliation Lines R1 and R2.
        MatchBankRecLines.RemoveMatch(TempBankAccReconciliationLine, DummyTempBankAccLedgerEntry);

        // [THEN] Bank Account Reconciliation Lines R1 and R2 were unapplied from their Check Ledger Entries.
        // [THEN] Bank Account Reconciliation Line R3 is applied to its Check Ledger Entries.
        VerifyEntriesUnapplied(TempBankAccReconciliationLine, UnappliedCheckLedgerEntryNos);
        VerifyEntryApplied(BankAccReconciliationLine, CheckLedgerEntryNos);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CheckSaveAsPdfReportHandler')]
    [Scope('OnPrem')]
    procedure RemoveMatchOnChecksWhenRunOnBankAccLedgerEntries()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        DummyTempBankAccReconciliationLine: Record "Bank Acc. Reconciliation Line" temporary;
        TempBankAccLedgerEntry: Record "Bank Account Ledger Entry" temporary;
        BankAccLedgerEntry: Record "Bank Account Ledger Entry";
        MatchBankRecLines: Codeunit "Match Bank Rec. Lines";
        BankAccountNo: Code[20];
        EntryNo: Integer;
        BankAccLedgerEntryNos: List of [Integer];
        BankAccReconStmtLineNos: List of [Integer];
        CheckLedgerEntryNos: List of [Integer];
    begin
        // [FEATURE] [Check]
        // [SCENARIO 342941] Run RemoveMatch function of "Match Bank Rec. Lines" codeunit on Bank Account Ledger Entries.
        Initialize();

        // [GIVEN] Bank Account Reconciliation Line with Type "Check Ledger Entry", it has three applied Check Ledger Entries C1, C2, C3.
        // [GIVEN] Each Check Ledger Entry has linked Bank Account Ledger Entry B1, B2, B3.
        BankAccountNo := CreateBankAccount();
        LibraryERM.CreateBankAccReconciliation(BankAccReconciliation, BankAccountNo, BankAccReconciliation."Statement Type"::"Bank Reconciliation");
        CreateBankAccReconLinesWithCheckType(BankAccReconStmtLineNos, BankAccReconciliation, 1);
        CreateBankAccLedgerEntriesWithCheckLedgerEntries(BankAccLedgerEntryNos, CheckLedgerEntryNos, BankAccountNo, 3);
        BankAccReconciliationLine.Get(
            BankAccReconciliation."Statement Type", BankAccountNo, BankAccReconciliation."Statement No.", BankAccReconStmtLineNos.Get(1));
        ApplyCheckEntriesToBankAccReconLine(BankAccReconciliationLine, CheckLedgerEntryNos);

        foreach EntryNo in BankAccLedgerEntryNos.GetRange(1, 2) do begin
            BankAccLedgerEntry.Get(EntryNo);
            TempBankAccLedgerEntry := BankAccLedgerEntry;
            TempBankAccLedgerEntry.Insert();
        end;

        // [WHEN] Run RemoveMatch function of "Match Bank Rec. Lines" codeunit on Bank Account Ledger Entries B1 and B2.
        MatchBankRecLines.RemoveMatch(DummyTempBankAccReconciliationLine, TempBankAccLedgerEntry);

        // [THEN] Check Ledger Entries C1 and C2 were unapplied from Bank Account Reconciliation Line.
        // [THEN] Check Ledger Entry C3 is applied to Bank Account Reconciliation Line.
        VerifyEntryPartiallyApplied(BankAccReconciliationLine, CheckLedgerEntryNos.GetRange(3, 1), CheckLedgerEntryNos.GetRange(1, 2));

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CheckSaveAsPdfReportHandler')]
    [Scope('OnPrem')]
    procedure RemoveMatchOnChecksWhenRunOnBankAccReconLinesAndBankAccLedgerEntries()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        TempBankAccReconciliationLine: Record "Bank Acc. Reconciliation Line" temporary;
        TempBankAccLedgerEntry: Record "Bank Account Ledger Entry" temporary;
        BankAccLedgerEntry: Record "Bank Account Ledger Entry";
        MatchBankRecLines: Codeunit "Match Bank Rec. Lines";
        BankAccountNo: Code[20];
        StatementLineNo: Integer;
        EntryNo: Integer;
        BankAccLedgerEntryNos: List of [Integer];
        UnappliedBankAccLedgerEntry: List of [Integer];
        BankAccReconStmtLineNos: List of [Integer];
        CheckLedgerEntryNos: List of [Integer];
        UnappliedCheckLedgerEntryNos: List of [Integer];
    begin
        // [FEATURE] [Check]
        // [SCENARIO 342941] Run RemoveMatch function of "Match Bank Rec. Lines" codeunit on Bank Account Reconciliation Lines and Bank Account Ledger Entries.
        Initialize();

        // [GIVEN] Two Bank Account Reconciliation Lines R1, R2 with Type "Check Ledger Entry".
        // [GIVEN] Each Reconciliation Line has three applied Check Ledger Entries C1..C6.
        BankAccountNo := CreateBankAccount();
        LibraryERM.CreateBankAccReconciliation(BankAccReconciliation, BankAccountNo, BankAccReconciliation."Statement Type"::"Bank Reconciliation");
        CreateBankAccReconLinesWithCheckType(BankAccReconStmtLineNos, BankAccReconciliation, 2);
        foreach StatementLineNo in BankAccReconStmtLineNos do begin
            CreateBankAccLedgerEntriesWithCheckLedgerEntries(BankAccLedgerEntryNos, CheckLedgerEntryNos, BankAccountNo, 3);
            BankAccReconciliationLine.Get(
                BankAccReconciliation."Statement Type", BankAccountNo, BankAccReconciliation."Statement No.", StatementLineNo);
            ApplyCheckEntriesToBankAccReconLine(BankAccReconciliationLine, CheckLedgerEntryNos);

            UnappliedBankAccLedgerEntry.AddRange(BankAccLedgerEntryNos);
            UnappliedCheckLedgerEntryNos.AddRange(CheckLedgerEntryNos);
        end;
        foreach EntryNo in UnappliedBankAccLedgerEntry.GetRange(1, 2) do begin
            BankAccLedgerEntry.Get(EntryNo);
            TempBankAccLedgerEntry := BankAccLedgerEntry;
            TempBankAccLedgerEntry.Insert();
        end;
        TempBankAccReconciliationLine := BankAccReconciliationLine;
        TempBankAccReconciliationLine.Insert();

        // [WHEN] Run RemoveMatch codeunit of "Match Bank Rec. Lines" codeunit on Bank Account Reconciliation Line R2.
        // [WHEN] Run RemoveMatch on Bank Account Ledger Entries C1 and C2.
        MatchBankRecLines.RemoveMatch(TempBankAccReconciliationLine, TempBankAccLedgerEntry);

        // [THEN] Check Ledger Entries C1, C2 were unapplied from Bank Account Reconciliation Line R1.
        // [THEN] Check Ledger Entry C3 is applied to Bank Account Reconciliation Line R1.
        // [THEN] Bank Account Reconciliation Line R2 were unapplied from Check Ledger Entries C4..C6.
        BankAccReconciliationLine.Get(
            BankAccReconciliation."Statement Type", BankAccountNo, BankAccReconciliation."Statement No.", BankAccReconStmtLineNos.Get(1));
        VerifyEntryPartiallyApplied(
            BankAccReconciliationLine, UnappliedCheckLedgerEntryNos.GetRange(3, 1), UnappliedCheckLedgerEntryNos.GetRange(1, 2));
        VerifyEntriesUnapplied(TempBankAccReconciliationLine, UnappliedCheckLedgerEntryNos.GetRange(4, 3));

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CheckSaveAsPdfReportHandler')]
    [Scope('OnPrem')]
    procedure RemoveMatchOnChecksWhenRunOnBankAccReconLinesPaymentApplication()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        TempBankAccReconciliationLine: Record "Bank Acc. Reconciliation Line" temporary;
        TempBankAccLedgerEntry: Record "Bank Account Ledger Entry" temporary;
        BankAccLedgerEntry: Record "Bank Account Ledger Entry";
        MatchBankRecLines: Codeunit "Match Bank Rec. Lines";
        BankAccountNo: Code[20];
        EntryNo: Integer;
        BankAccLedgerEntryNos: List of [Integer];
        BankAccReconStmtLineNos: List of [Integer];
        CheckLedgerEntryNos: List of [Integer];
    begin
        // [FEATURE] [Check]
        // [SCENARIO 342941] Run RemoveMatch function of "Match Bank Rec. Lines" codeunit on Bank Account Reconciliation Lines with Statement Type "Payment Application".
        Initialize();

        // [GIVEN] Bank Account Reconciliation Line with Type "Check Ledger Entry" and Statement Type "Payment Application".
        // [GIVEN] Reconciliation Line has three applied Check Ledger Entries.
        BankAccountNo := CreateBankAccount();
        LibraryERM.CreateBankAccReconciliation(BankAccReconciliation, BankAccountNo, BankAccReconciliation."Statement Type"::"Payment Application");
        CreateBankAccReconLinesWithCheckType(BankAccReconStmtLineNos, BankAccReconciliation, 1);
        CreateBankAccLedgerEntriesWithCheckLedgerEntries(BankAccLedgerEntryNos, CheckLedgerEntryNos, BankAccountNo, 3);
        BankAccReconciliationLine.Get(
            BankAccReconciliation."Statement Type", BankAccountNo, BankAccReconciliation."Statement No.", BankAccReconStmtLineNos.Get(1));
        ApplyCheckEntriesToBankAccReconLine(BankAccReconciliationLine, CheckLedgerEntryNos);

        foreach EntryNo in BankAccLedgerEntryNos do begin
            BankAccLedgerEntry.Get(EntryNo);
            TempBankAccLedgerEntry := BankAccLedgerEntry;
            TempBankAccLedgerEntry.Insert();
        end;
        TempBankAccReconciliationLine := BankAccReconciliationLine;
        TempBankAccReconciliationLine.Insert();

        // [WHEN] Run RemoveMatch codeunit of "Match Bank Rec. Lines" codeunit on Bank Account Reconciliation Line.
        // [WHEN] Run RemoveMatch on Bank Account Ledger Entries.
        MatchBankRecLines.RemoveMatch(TempBankAccReconciliationLine, TempBankAccLedgerEntry);

        // [THEN] Bank Account Reconciliation Line is applied to Check Ledger Entries.
        VerifyEntryApplied(BankAccReconciliationLine, CheckLedgerEntryNos);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('TransferToGenJnlReqPageHandler,GenJnlPageHandlerUpdateAccountNo')]
    [Scope('OnPrem')]
    procedure TransferToGenJnlLineKeepDescription()
    var
        Vendor: Record Vendor;
        GenJnlLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationPage: TestPage "Bank Acc. Reconciliation";
        StatementDescription: Text[100];
    begin
        // [FEATURE] [UI]
        // [SCENARIO 306156] Gen. Journal Line Description is not changed when line created from bank reconciliation
        Initialize();

        // [GIVEN] Create bank reconciliation with bank satetement line Description = 'XYZ'
        StatementDescription := LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(StatementDescription), 0);
        CreateBankReconciliation(BankAccReconciliation, BankAccReconciliationPage, StatementDescription);
        LibraryVariableStorage.Clear(); //clear not needed value
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);

        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch."Bal. Account Type" := GenJournalBatch."Bal. Account Type"::"Bank Account";
        GenJournalBatch."Bal. Account No." := BankAccReconciliation."Bank Account No.";
        GenJournalBatch.Modify();

        LibraryVariableStorage.Enqueue(GenJournalBatch."Journal Template Name");
        LibraryVariableStorage.Enqueue(GenJournalBatch.Name);
        // [GIVEN] Create vendor "V"
        LibraryVariableStorage.Enqueue(GenJnlLine."Account Type"::Vendor.AsInteger());
        LibraryPurchase.CreateVendor(Vendor);
        LibraryVariableStorage.Enqueue(Vendor."No.");

        // [GIVEN] Run action Transfer to Gen Jnl.
        Commit();
        LibraryLowerPermissions.SetBanking();
        BankAccReconciliationPage."Transfer to General Journal".Invoke();

        // [WHEN] Change account type to Vendor and Account No. to "V" (GenJnlPageHandlerUpdateAccountNo)
        // [THEN] Gen. Journal Line has same description "XYZ"
        Assert.AreEqual(StatementDescription, LibraryVariableStorage.DequeueText(), 'Invalid Description');
    end;

    [Test]
    [HandlerFunctions('TransferToGenJnlReqPageHandler,GenJnlPageHandlerUpdateAccountNo')]
    [Scope('OnPrem')]
    procedure TransferToGenJnlLineTwoBankAccounts()
    var
        BankAccount: Record "Bank Account";
        GenJnlLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        BankAccReconciliationPage: TestPage "Bank Acc. Reconciliation";
    begin
        // [SCENARIO 416085] Posting gen. journal line created from reconsiliation applies bank entry only for bank account from reconciliation 
        Initialize();

        // [GIVEN] Create bank reconciliation with bank satetement line for bank "B1"
        CreateBankReconciliation(BankAccReconciliation, BankAccReconciliationPage,
            LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(GenJnlLine.Description), 0));
        LibraryVariableStorage.Clear();  //clear not needed value
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);

        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch."Bal. Account Type" := GenJournalBatch."Bal. Account Type"::"Bank Account";
        GenJournalBatch."Bal. Account No." := BankAccReconciliation."Bank Account No.";
        GenJournalBatch."No. Series" := LibraryERM.CreateNoSeriesCode();
        GenJournalBatch.Modify();

        LibraryVariableStorage.Enqueue(GenJournalBatch."Journal Template Name");
        LibraryVariableStorage.Enqueue(GenJournalBatch.Name);
        // [GIVEN] Create bank "B2"
        LibraryVariableStorage.Enqueue(GenJnlLine."Account Type"::"Bank Account".AsInteger());
        LibraryERM.CreateBankAccount(BankAccount);
        LibraryVariableStorage.Enqueue(BankAccount."No.");

        // [GIVEN] Run action Transfer to Gen Jnl. and set for created gen. journal line "Account Type" = "Bank", "Account No" = "B2"
        Commit();
        LibraryLowerPermissions.SetBanking();
        BankAccReconciliationPage."Transfer to General Journal".Invoke();

        // [WHEN] Post gen journal line
        GenJnlLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        GenJnlLine.FindFirst();
        LibraryERM.PostGeneralJnlLine(GenJnlLine);

        // [THEN] Bank ledger entry for bank "B2" is not applied to bank reconsiliation
        BankAccountLedgerEntry.SetRange("Bank Account No.", BankAccount."No.");
        BankAccountLedgerEntry.FindFirst();
        BankAccountLedgerEntry.TestField("Statement Status", BankAccountLedgerEntry."Statement Status"::Open);
        BankAccountLedgerEntry.TestField("Statement No.", '');
        BankAccountLedgerEntry.TestField("Statement Line No.", 0);
    end;

    [Test]
    [HandlerFunctions('TransferToGenJnlReqPageHandler,GenJnlPagePostHandler')]
    [Scope('OnPrem')]
    procedure BankAccReconciliationLineAppliedEntriesValueAfterPostGenJnlLine()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        GenJnlLine: Record "Gen. Journal Line";
        BankAccReconciliationPage: TestPage "Bank Acc. Reconciliation";
        CustomerNo: Variant;
    begin
        // [SCENARIO 417646] Bank Acc. Reconciliation Line field Applied Entries should be correct after posting linked Gen. Journal line
        Initialize();

        // [GIVEN] Bank Account Reconciliation 
        CreateBankReconciliation(BankAccReconciliation, BankAccReconciliationPage,
            LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(GenJnlLine.Description), 0));
        LibraryVariableStorage.Dequeue(CustomerNo);
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);

        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch."Bal. Account Type" := GenJournalBatch."Bal. Account Type"::"Bank Account";
        GenJournalBatch."Bal. Account No." := BankAccReconciliation."Bank Account No.";
        GenJournalBatch.Modify();

        // For running the report:
        LibraryVariableStorage.Enqueue(GenJournalBatch."Journal Template Name");
        LibraryVariableStorage.Enqueue(GenJournalBatch.Name);

        // [GIVEN] Transfer to General Journal is invoked
        Commit();
        LibraryLowerPermissions.SetBanking();
        BankAccReconciliationPage."Transfer to General Journal".Invoke();

        // [WHEN] Gen. Journal Line is posted
        GenJnlLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        GenJnlLine.SetRange("Bal. Account No.", BankAccReconciliation."Bank Account No.");
        GenJnlLine.FindFirst();
        GenJnlLine.Validate("Document No.", '1');
        GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::Customer);
        GenJnlLine.Validate("Account No.", CustomerNo);
        GenJnlLine.Modify();
        LibraryERM.PostGeneralJnlLine(GenJnlLine);

        // [THEN] Bank Acc. Reconciliation Line "Applied Entries" = 1
        BankAccReconciliationLine.SetRange("Statement Type", BankAccReconciliationLine."Statement Type"::"Bank Reconciliation");
        BankAccReconciliationLine.SetRange("Bank Account No.", BankAccReconciliation."Bank Account No.");
        BankAccReconciliationLine.SetRange("Statement No.", BankAccReconciliation."Statement No.");
        BankAccReconciliationLine.SetRange("Applied Amount", -GenJnlLine.Amount);
        BankAccReconciliationLine.FindFirst();
        BankAccReconciliationLine.TestField("Applied Entries", 1);
    end;

    [Test]
    [HandlerFunctions('TransferToGenJnlReqPageHandler,GenJnlPagePostHandler')]
    [Scope('OnPrem')]
    procedure BankAccReconLineAppliedEntriesValueAfterPostGenJnlLineForDifference()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        GenJnlLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        BankAccReconciliationPage: TestPage "Bank Acc. Reconciliation";
        CustomerNo: Variant;
        PaymentAmount: Decimal;
        OriginalAmount: Decimal;
        PostedAmount: Decimal;
        NumberOfEntries: Integer;
    begin
        // [SCENARIO] Transfer the difference of an applied Bank Acc. Recon. Line to a journal and after posting the new Bank Acc. L.E. should be
        // applied correctly to the bank statement line.
        Initialize();

        // [GIVEN] A Bank Account Reconciliation
        PaymentAmount := LibraryRandom.RandDec(100, 2);
        CreateBankReconciliation(BankAccReconciliation, BankAccReconciliationPage,
            LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(GenJnlLine.Description), 0), PaymentAmount);
        LibraryVariableStorage.Dequeue(CustomerNo);

        // [GIVEN] A Bank Account Reconciliation Line matched to 90% of the real amount
        BankAccReconciliationLine.SetRange("Statement Type", BankAccReconciliation."Statement Type");
        BankAccReconciliationLine.SetRange("Bank Account No.", BankAccReconciliation."Bank Account No.");
        BankAccReconciliationLine.SetRange("Statement No.", BankAccReconciliation."Statement No.");
        BankAccReconciliationLine.FindFirst();
        OriginalAmount := PaymentAmount - 10;
        PostedAmount := -10;
        BankAccReconciliationLine.Validate("Statement Amount", OriginalAmount);
        BankAccReconciliationLine.Modify(true);
        BankAccReconciliationPage.GotoRecord(BankAccReconciliation);
        BankAccReconciliationPage.StmtLine.First();
        BankAccReconciliationPage.ApplyBankLedgerEntries.First();
        BankAccReconciliationPage.MatchManually.Invoke();

        // [GIVEN] A Journal and Batch to use for transfer
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch."Bal. Account Type" := GenJournalBatch."Bal. Account Type"::"Bank Account";
        GenJournalBatch."Bal. Account No." := BankAccReconciliation."Bank Account No.";
        GenJournalBatch.Modify();

        // [GIVEN] Setup the report data for when the action is invoked
        LibraryVariableStorage.Enqueue(GenJournalBatch."Journal Template Name");
        LibraryVariableStorage.Enqueue(GenJournalBatch.Name);

        // [GIVEN] Transfer to General Journal is invoked
        Commit();
        LibraryLowerPermissions.SetBanking();
        BankAccReconciliationPage."Transfer to General Journal".Invoke();

        // [WHEN] Gen. Journal Line is posted
        GenJnlLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        GenJnlLine.SetRange("Bal. Account No.", BankAccReconciliation."Bank Account No.");
        GenJnlLine.FindFirst();
        GenJnlLine.Validate("Document No.", '1');
        GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::Customer);
        GenJnlLine.Validate("Account No.", CustomerNo);
        GenJnlLine.Modify();
        LibraryERM.PostGeneralJnlLine(GenJnlLine);

        // [THEN] Bank Acc. Reconciliation Line "Applied Entries" = 2
        BankAccReconciliationLine.SetRange("Statement Type", BankAccReconciliationLine."Statement Type"::"Bank Reconciliation");
        BankAccReconciliationLine.SetRange("Bank Account No.", BankAccReconciliation."Bank Account No.");
        BankAccReconciliationLine.SetRange("Statement No.", BankAccReconciliation."Statement No.");
        BankAccReconciliationLine.SetRange("Applied Amount", OriginalAmount);
        BankAccReconciliationLine.FindFirst();
        BankAccReconciliationLine.TestField("Applied Entries", 2);

        // [THEN] Two Bank Account Ledger Entries matched to the same Bank Acc. Reconciliation Line.
        BankAccountLedgerEntry.SetRange("Bank Account No.", BankAccReconciliation."Bank Account No.");
        BankAccountLedgerEntry.SetRange(Open, true);
        BankAccountLedgerEntry.SetRange("Statement No.", BankAccReconciliation."Statement No.");
        BankAccountLedgerEntry.SetRange("Statement Line No.", BankAccReconciliationLine."Statement Line No.");
        NumberOfEntries := BankAccountLedgerEntry.Count();
        if NumberOfEntries <> 2 then
            Assert.IsTrue(false, StrSubstNo('There should be two entries. Currently: %1 entries.', NumberOfEntries));

        BankAccountLedgerEntry.FindSet();
        repeat
            case BankAccountLedgerEntry.Amount of
                PaymentAmount:
                    Assert.IsTrue(BankAccountLedgerEntry."Statement Status" = BankAccountLedgerEntry."Statement Status"::"Bank Acc. Entry Applied", 'Entry must be applied');
                PostedAmount:
                    Assert.IsTrue(BankAccountLedgerEntry."Statement Status" = BankAccountLedgerEntry."Statement Status"::"Bank Acc. Entry Applied", 'Entry must be applied');
                else
                    Assert.IsTrue(false, StrSubstNo('There should be only two entries with "Applied Amounts" %1 and %2. Current "Applied Amount" = %3',
                                  PaymentAmount, PostedAmount, BankAccountLedgerEntry.Amount));
            end;
        until BankAccountLedgerEntry.Next() = 0;
    end;

    local procedure GLEntryPaymentDocTypeAfterPostPmtReconJnlWithGLAcc(AmountToApply: Decimal)
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        GLEntry: Record "G/L Entry";
        GLAccountNo: Code[20];
    begin
        Initialize();

        GLAccountNo := LibraryERM.CreateGLAccountNo();
        CreateBankAccReconLineWithGLAcc(BankAccReconciliation, BankAccReconciliationLine, GLAccountNo, AmountToApply);
        CreatePaymentApplication(BankAccReconciliationLine, AmountToApply);
        UpdateBankAccRecStmEndingBalance(BankAccReconciliation, BankAccReconciliation."Balance Last Statement" + BankAccReconciliationLine."Statement Amount");
        LibraryERM.PostBankAccReconciliation(BankAccReconciliation);
        VerifyGLEntryDocType(GLAccountNo, BankAccReconciliation."Statement No.", GLEntry."Document Type"::Payment);
    end;

    local procedure Initialize()
    var
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Match Bank Rec. Scenarios");
        LibraryApplicationArea.EnableFoundationSetup();
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Match Bank Rec. Scenarios");

        LibraryERMCountryData.UpdateLocalData();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateLocalPostingSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        isInitialized := true;
        Commit();

        LibrarySetupStorage.SaveGeneralLedgerSetup();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Match Bank Rec. Scenarios");
    end;

    local procedure ApplyCheckEntriesToBankAccReconLine(BankAccReconLine: Record "Bank Acc. Reconciliation Line"; CheckLedgerEntryNos: List of [Integer])
    var
        CheckLedgerEntry: Record "Check Ledger Entry";
        CheckEntrySetReconNo: Codeunit "Check Entry Set Recon.-No.";
        EntryNo: Integer;
    begin
        foreach EntryNo in CheckLedgerEntryNos do begin
            CheckLedgerEntry.Get(EntryNo);
            CheckEntrySetReconNo.ToggleReconNo(CheckLedgerEntry, BankAccReconLine, false);
        end;
    end;

    local procedure CreateBankAccount(): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount."Last Check No." := Format(LibraryUtility.GenerateGUID());
        BankAccount.Modify();
        exit(BankAccount."No.");
    end;

    local procedure CreatePaymentApplication(var BankAccReconLine: Record "Bank Acc. Reconciliation Line"; AmountToApply: Decimal)
    var
        AppliedPaymentEntry: Record "Applied Payment Entry";
    begin
        AppliedPaymentEntry.Init();
        AppliedPaymentEntry."Statement Type" := BankAccReconLine."Statement Type";
        AppliedPaymentEntry."Bank Account No." := BankAccReconLine."Bank Account No.";
        AppliedPaymentEntry."Statement No." := BankAccReconLine."Statement No.";
        AppliedPaymentEntry."Statement Line No." := BankAccReconLine."Statement Line No.";
        AppliedPaymentEntry."Account Type" := BankAccReconLine."Account Type";
        AppliedPaymentEntry."Account No." := BankAccReconLine."Account No.";
        AppliedPaymentEntry."Applied Amount" := AmountToApply;
        AppliedPaymentEntry.Insert();

        BankAccReconLine.Validate("Applied Amount", AmountToApply);
        BankAccReconLine.Modify();
    end;

    local procedure CreateBankAccReconLineWithGLAcc(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; GLAccountNo: Code[20]; StmtAmount: Decimal)
    var
        BankAccount: Record "Bank Account";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        LibraryERM.CreateBankAccReconciliation(
          BankAccReconciliation, BankAccount."No.", BankAccReconciliation."Statement Type"::"Payment Application");
        LibraryERM.CreateBankAccReconciliationLn(BankAccReconciliationLine, BankAccReconciliation);
        BankAccReconciliationLine.Validate("Transaction Date", WorkDate());
        BankAccReconciliationLine.Validate("Account Type", BankAccReconciliationLine."Account Type"::"G/L Account");
        BankAccReconciliationLine.Validate("Account No.", GLAccountNo);
        BankAccReconciliationLine.Validate(Description, BankAccReconciliationLine."Account No.");
        BankAccReconciliationLine.Validate("Statement Amount", StmtAmount);
        BankAccReconciliationLine.Modify();
    end;

    local procedure CreateAndPostVendorPaymentWithCheck(GenJournalBatch: Record "Gen. Journal Batch"; VendorNo: Code[20]; BankAccountNo: Code[20]; LineAmount: Decimal): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
        DocPrint: Codeunit "Document-Print";
    begin
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
            GenJournalLine."Account Type"::Vendor, VendorNo, GenJournalLine."Bal. Account Type"::"Bank Account", BankAccountNo, LineAmount);
        GenJournalLine.Validate("Bank Payment Type", GenJournalLine."Bank Payment Type"::"Computer Check");
        GenJournalLine.Modify(true);
        Commit();

        GenJournalLine.SetRecFilter();
        LibraryVariableStorage.Enqueue(BankAccountNo);
        LibraryVariableStorage.Enqueue(GenJournalLine.GetView());
        DocPrint.PrintCheck(GenJournalLine);

        GenJournalLine.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", GenJournalLine."Line No.");
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        GenJournalLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        GenJournalLine.DeleteAll();
        exit(GenJournalLine."Document No.");
    end;

    local procedure CreateBankAccLedgerEntriesWithCheckLedgerEntries(var BankAccLedgerEntryNos: List of [Integer]; var CheckLedgerEntryNos: List of [Integer]; BankAccountNo: Code[20]; EntryCount: Integer)
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        BankAccLedgerEntry: Record "Bank Account Ledger Entry";
        CheckLedgerEntry: Record "Check Ledger Entry";
        DummyGenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
        i: Integer;
    begin
        Clear(BankAccLedgerEntryNos);
        Clear(CheckLedgerEntryNos);
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        for i := 1 to EntryCount do begin
            DocumentNo :=
                CreateAndPostVendorPaymentWithCheck(
                    GenJournalBatch, LibraryPurchase.CreateVendorNo(), BankAccountNo, LibraryRandom.RandDecInRange(100, 200, 2));
            FindBankAccountLedgerEntry(BankAccLedgerEntry, BankAccountNo, DummyGenJournalLine."Document Type"::Payment, DocumentNo);
            BankAccLedgerEntryNos.Add(BankAccLedgerEntry."Entry No.");
            FindCheckLedgerEntry(CheckLedgerEntry, BankAccountNo, BankAccLedgerEntry."Entry No.");
            CheckLedgerEntryNos.Add(CheckLedgerEntry."Entry No.");
        end;
    end;

    local procedure CreateBankAccReconciliation(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; BankAccountNo: Code[20])
    begin
        BankAccReconciliation.Init();
        BankAccReconciliation.Validate("Bank Account No.", BankAccountNo);
        BankAccReconciliation.Validate("Statement No.",
          LibraryUtility.GenerateRandomCode(BankAccReconciliation.FieldNo("Statement No."), DATABASE::"Bank Acc. Reconciliation"));
        BankAccReconciliation.Validate("Statement Date", WorkDate());
        BankAccReconciliation.Insert(true);
    end;

    local procedure CreateBankAccReconLinesWithCheckType(var StatementLineNos: List of [Integer]; BankAccReconciliation: Record "Bank Acc. Reconciliation"; LineCount: Integer)
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        i: Integer;
    begin
        Clear(StatementLineNos);
        for i := 1 to LineCount do begin
            LibraryERM.CreateBankAccReconciliationLn(BankAccReconciliationLine, BankAccReconciliation);
            BankAccReconciliationLine.Validate("Statement Amount", LibraryRandom.RandDecInRange(100, 200, 2));
            BankAccReconciliationLine.Modify(true);
            StatementLineNos.Add(BankAccReconciliationLine."Statement Line No.");
        end;
    end;

    local procedure FindBankAccountLedgerEntry(var BankAccountLedgerEntry: Record "Bank Account Ledger Entry"; BankAccountNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    begin
        BankAccountLedgerEntry.SetRange("Bank Account No.", BankAccountNo);
        BankAccountLedgerEntry.SetRange("Document Type", DocumentType);
        BankAccountLedgerEntry.SetRange("Document No.", DocumentNo);
        BankAccountLedgerEntry.FindFirst();
    end;

    local procedure FindCheckLedgerEntry(var CheckLedgerEntry: Record "Check Ledger Entry"; BankAccountNo: Code[20]; BankAccLedgerEntryNo: Integer)
    begin
        CheckLedgerEntry.SetRange("Bank Account No.", BankAccountNo);
        CheckLedgerEntry.SetRange("Bank Account Ledger Entry No.", BankAccLedgerEntryNo);
        CheckLedgerEntry.FindFirst();
    end;

    local procedure SetupManualMatch(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; var BankAccReconciliationPage: TestPage "Bank Acc. Reconciliation"; var ExpectedAmount: Decimal; MatchFactor: Decimal)
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        Customer: Record Customer;
        "count": Integer;
    begin
        ExpectedAmount := LibraryRandom.RandDec(100, 2);

        LibraryERM.CreateBankAccount(BankAccount);
        LibrarySales.CreateCustomer(Customer);
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);

        for count := 1 to 2 do begin
            LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name,
              GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer, Customer."No.", -ExpectedAmount);
            GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
            GenJournalLine.Validate("Bal. Account No.", BankAccount."No.");
            GenJournalLine.Modify(true);
        end;
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        CreateBankAccReconciliation(BankAccReconciliation, BankAccount."No.");
        for count := 1 to 2 do begin
            LibraryERM.CreateBankAccReconciliationLn(BankAccReconciliationLine, BankAccReconciliation);
            BankAccReconciliationLine.Validate("Statement Amount", MatchFactor * ExpectedAmount);
            BankAccReconciliationLine.Modify(true);
        end;

        BankAccReconciliationPage.OpenEdit();
        BankAccReconciliationPage.GotoRecord(BankAccReconciliation);
        BankAccReconciliationPage.StmtLine.First();
        BankAccReconciliationPage.ApplyBankLedgerEntries.First();
    end;

    local procedure CreateBankReconciliation(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; var BankAccReconciliationPage: TestPage "Bank Acc. Reconciliation"; StatementDescription: Text[100])
    var
        PaymentAmount: Decimal;
    begin
        PaymentAmount := LibraryRandom.RandDec(100, 2);
        CreateBankReconciliation(BankAccReconciliation, BankAccReconciliationPage, StatementDescription, PaymentAmount);
    end;

    local procedure CreateBankReconciliation(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; var BankAccReconciliationPage: TestPage "Bank Acc. Reconciliation"; StatementDescription: Text[100]; PaymentAmount: Decimal)
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        Customer: Record Customer;
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        LibrarySales.CreateCustomer(Customer);
        LibraryVariableStorage.Enqueue(Customer."No.");
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);

        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name,
          GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer, Customer."No.", -PaymentAmount);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Bal. Account No.", BankAccount."No.");
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        CreateBankAccReconciliation(BankAccReconciliation, BankAccount."No.");
        LibraryERM.CreateBankAccReconciliationLn(BankAccReconciliationLine, BankAccReconciliation);
        BankAccReconciliationLine.Validate("Statement Amount", 2 * PaymentAmount);
        BankAccReconciliationLine.Description := StatementDescription;
        BankAccReconciliationLine.Modify(true);

        BankAccReconciliationPage.OpenEdit();
        BankAccReconciliationPage.GotoRecord(BankAccReconciliation);
        BankAccReconciliationPage.StmtLine.First();
        BankAccReconciliationPage.ApplyBankLedgerEntries.First();
    end;

    local procedure VerifyOneToManyMatch(BankAccReconciliation: Record "Bank Acc. Reconciliation"; ExpRecLineNo: Integer; ExpBankEntryMatches: Integer; ExpAmount: Decimal)
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        BankAccReconciliationLine.Get(
          BankAccReconciliation."Statement Type",
          BankAccReconciliation."Bank Account No.",
          BankAccReconciliation."Statement No.",
          ExpRecLineNo);
        Assert.AreEqual(ExpAmount, BankAccReconciliationLine."Applied Amount", 'Wrong applied amt.');
        Assert.AreEqual(ExpBankEntryMatches, BankAccReconciliationLine."Applied Entries", 'Wrong no. of applied entries.');

        BankAccountLedgerEntry.SetRange("Bank Account No.", BankAccReconciliation."Bank Account No.");
        BankAccountLedgerEntry.SetRange("Statement Status", BankAccountLedgerEntry."Statement Status"::"Bank Acc. Entry Applied");
        BankAccountLedgerEntry.SetRange("Statement No.", BankAccReconciliation."Statement No.");
        BankAccountLedgerEntry.SetRange("Statement Line No.", ExpRecLineNo);
        BankAccountLedgerEntry.SetRange(Open, true);
        Assert.AreEqual(ExpBankEntryMatches, BankAccountLedgerEntry.Count, 'Wrong no of applied entries.');
    end;

    local procedure VerifyBalance(var BankAccReconciliationPage: TestPage "Bank Acc. Reconciliation"; BankAccNo: Code[20])
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount.Get(BankAccNo);
        BankAccount.CalcFields(Balance, "Total on Checks");
        Assert.AreEqual(BankAccount.Balance, BankAccReconciliationPage.ApplyBankLedgerEntries.Balance.AsDecimal(), 'Wrong acc. balance');
        Assert.AreEqual(BankAccount."Total on Checks", BankAccReconciliationPage.ApplyBankLedgerEntries.CheckBalance.AsDecimal(),
          'Wrong check balance');
        Assert.AreEqual(BankAccount.Balance + BankAccount."Total on Checks",
          BankAccReconciliationPage.ApplyBankLedgerEntries.BalanceToReconcile.AsDecimal(), 'Wrong remaining balance');
    end;

    local procedure VerifyPosting(BankAccReconciliation: Record "Bank Acc. Reconciliation"; ExpEntriesNo: Integer)
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        BankAccountStatement: Record "Bank Account Statement";
    begin
        BankAccountStatement.Get(BankAccReconciliation."Bank Account No.", BankAccReconciliation."Statement No.");
        BankAccountLedgerEntry.SetRange("Bank Account No.", BankAccReconciliation."Bank Account No.");
        BankAccountLedgerEntry.SetRange("Statement Status", BankAccountLedgerEntry."Statement Status"::Closed);
        BankAccountLedgerEntry.SetRange("Statement No.", BankAccReconciliation."Statement No.");
        BankAccountLedgerEntry.SetRange("Remaining Amount", 0);
        BankAccountLedgerEntry.SetRange(Open, false);
        Assert.AreEqual(ExpEntriesNo, BankAccountLedgerEntry.Count, 'Wrong no of bank entries.');

        BankAccountLedgerEntry.Reset();
        BankAccountLedgerEntry.SetRange("Bank Account No.", BankAccReconciliation."Statement No.");
        BankAccountLedgerEntry.SetRange(Open, true);
        Assert.IsTrue(BankAccountLedgerEntry.IsEmpty, 'There should be no entries left.');

        asserterror BankAccReconciliation.Find();
    end;

    local procedure VerifyGLEntryDocType(GLAccountNo: Code[20]; DocumentNo: Code[20]; ExpectedDocType: Enum "Gen. Journal Document Type")
    var
        DummyGLEntry: Record "G/L Entry";
    begin
        DummyGLEntry.SetRange("G/L Account No.", GLAccountNo);
        DummyGLEntry.SetRange("Document No.", DocumentNo);
        DummyGLEntry.SetRange("Document Type", ExpectedDocType);
        Assert.RecordIsNotEmpty(DummyGLEntry);
    end;

    local procedure VerifyEntriesUnapplied(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; CheckLedgerEntryNos: List of [Integer])
    var
        CheckLedgerEntry: Record "Check Ledger Entry";
        EntryNo: Integer;
    begin
        BankAccReconciliationLine.FindSet();
        repeat
            BankAccReconciliationLine.TestField("Applied Amount", 0);
            BankAccReconciliationLine.TestField("Applied Entries", 0);
            BankAccReconciliationLine.TestField("Check No.", '');
        until BankAccReconciliationLine.Next() = 0;

        foreach EntryNo in CheckLedgerEntryNos do begin
            CheckLedgerEntry.Get(EntryNo);
            CheckLedgerEntry.TestField("Statement Status", CheckLedgerEntry."Statement Status"::Open);
            CheckLedgerEntry.TestField("Statement No.", '');
            CheckLedgerEntry.TestField("Statement Line No.", 0);
        end;
    end;

    local procedure VerifyEntryApplied(BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; CheckLedgerEntryNos: List of [Integer])
    var
        CheckLedgerEntry: Record "Check Ledger Entry";
        EntryNo: Integer;
        AppliedEntries: Integer;
        AppliedAmount: Decimal;
    begin
        BankAccReconciliationLine.Get(
            BankAccReconciliationLine."Statement Type", BankAccReconciliationLine."Bank Account No.",
            BankAccReconciliationLine."Statement No.", BankAccReconciliationLine."Statement Line No.");

        foreach EntryNo in CheckLedgerEntryNos do begin
            CheckLedgerEntry.Get(EntryNo);
            CheckLedgerEntry.TestField("Statement Status", CheckLedgerEntry."Statement Status"::"Check Entry Applied");
            CheckLedgerEntry.TestField("Statement No.", BankAccReconciliationLine."Statement No.");
            CheckLedgerEntry.TestField("Statement Line No.", BankAccReconciliationLine."Statement Line No.");
            AppliedEntries += 1;
            AppliedAmount += CheckLedgerEntry.Amount;
        end;

        BankAccReconciliationLine.TestField("Applied Amount", -AppliedAmount);
        BankAccReconciliationLine.TestField("Applied Entries", AppliedEntries);
        BankAccReconciliationLine.TestField("Check No.", '');
    end;

    local procedure VerifyEntryPartiallyApplied(BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; AppliedCheckLedgerEntryNos: List of [Integer]; UnppliedCheckLedgerEntryNos: List of [Integer])
    var
        CheckLedgerEntry: Record "Check Ledger Entry";
        EntryNo: Integer;
        AppliedEntries: Integer;
        AppliedAmount: Decimal;
    begin
        BankAccReconciliationLine.Get(
            BankAccReconciliationLine."Statement Type", BankAccReconciliationLine."Bank Account No.",
            BankAccReconciliationLine."Statement No.", BankAccReconciliationLine."Statement Line No.");

        foreach EntryNo in UnppliedCheckLedgerEntryNos do begin
            CheckLedgerEntry.Get(EntryNo);
            CheckLedgerEntry.TestField("Statement Status", CheckLedgerEntry."Statement Status"::Open);
            CheckLedgerEntry.TestField("Statement No.", '');
            CheckLedgerEntry.TestField("Statement Line No.", 0);
        end;

        foreach EntryNo in AppliedCheckLedgerEntryNos do begin
            CheckLedgerEntry.Get(EntryNo);
            CheckLedgerEntry.TestField("Statement Status", CheckLedgerEntry."Statement Status"::"Check Entry Applied");
            CheckLedgerEntry.TestField("Statement No.", BankAccReconciliationLine."Statement No.");
            CheckLedgerEntry.TestField("Statement Line No.", BankAccReconciliationLine."Statement Line No.");
            AppliedEntries += 1;
            AppliedAmount += CheckLedgerEntry.Amount;
        end;

        BankAccReconciliationLine.TestField("Applied Amount", -AppliedAmount);
        BankAccReconciliationLine.TestField("Applied Entries", AppliedEntries);
    end;

    local procedure UpdateBankAccRecStmEndingBalance(var BankAccRecon: Record "Bank Acc. Reconciliation"; NewStmEndingBalance: Decimal)
    begin
        BankAccRecon.Validate("Statement Ending Balance", NewStmEndingBalance);
        BankAccRecon.Modify();
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

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure TransferToGenJnlReqPageHandler(var TransBankRecToGenJnl: TestRequestPage "Trans. Bank Rec. to Gen. Jnl.")
    var
        TemplateName: Variant;
        BatchName: Variant;
    begin
        LibraryVariableStorage.Dequeue(TemplateName);
        LibraryVariableStorage.Dequeue(BatchName);
        TransBankRecToGenJnl."GenJnlLine.""Journal Template Name""".SetValue(TemplateName);
        TransBankRecToGenJnl."GenJnlLine.""Journal Batch Name""".SetValue(BatchName);
        TransBankRecToGenJnl.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure GenJnlPageHandler(var GeneralJournal: TestPage "General Journal")
    var
        GenJnlLine: Record "Gen. Journal Line";
        BatchName: Variant;
        BankAccNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(BatchName);
        LibraryVariableStorage.Dequeue(BankAccNo);
        GeneralJournal.CurrentJnlBatchName.AssertEquals(BatchName);
        GeneralJournal."Bal. Account Type".AssertEquals(GenJnlLine."Bal. Account Type"::"Bank Account");
        GeneralJournal."Bal. Account No.".AssertEquals(BankAccNo);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure GenJnlPagePostHandler(var GeneralJournal: TestPage "General Journal")
    begin
        GeneralJournal.Close();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure MatchRecLinesReqPageHandler(var MatchBankAccReconciliation: TestRequestPage "Match Bank Entries")
    begin
        MatchBankAccReconciliation.OK().Invoke();
    end;

    [ReportHandler]
    [Scope('OnPrem')]
    procedure CheckSaveAsPdfReportHandler(var Check: Report Check)
    var
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        BankAccount.Get(LibraryVariableStorage.DequeueText());
        GenJournalLine.SetView(LibraryVariableStorage.DequeueText());
        Check.InitializeRequest(BankAccount."No.", BankAccount."Last Check No.", false, false, false, false);
        Check.SetTableView(GenJournalLine);
        Check.SaveAsPdf(FileMgt.ServerTempFileName('.pdf'));
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure GenJnlPageHandlerUpdateAccountNo(var GeneralJournal: TestPage "General Journal")
    var
        AccountType: Integer;
        AccountNo: Code[20];
    begin
        AccountType := LibraryVariableStorage.DequeueInteger();
        AccountNo := LibraryVariableStorage.DequeueText();
        GeneralJournal."Account Type".SetValue(AccountType);
        GeneralJournal."Account No.".SetValue(AccountNo);
        LibraryVariableStorage.Enqueue(GeneralJournal.Description.Value());
    end;


    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure BankStatementPagePostHandler(var BankStatement: TestPage "Bank Account Statement")
    var
        BankStatementNo: Text;
    begin
        BankStatementNo := LibraryVariableStorage.DequeueText();
        Assert.AreEqual(BankStatementNo, BankStatement."Statement No.".Value, StrSubstNo('The opened statement is not the correct one. Opened: %1, Expected: %2', BankStatement."Statement No.".Value, BankStatementNo));
        BankStatement.Close();
    end;
}

