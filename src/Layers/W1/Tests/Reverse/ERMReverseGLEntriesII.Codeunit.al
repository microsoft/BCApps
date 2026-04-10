codeunit 134148 "ERM Reverse GL Entries-II"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Reverse] [Reverse Transaction]
        IsInitialized := false;
    end;

    var
        TempDocumentEntry: Record "Document Entry" temporary;
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        LibraryJournals: Codeunit "Library - Journals";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        PostingDate2: Date;
        DocumentNo2: Code[20];
        IsInitialized: Boolean;
        ReverseError: Label 'Reversal Entries Must be Same.';

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure GeneralJournalLineReverse()
    var
        GenJournalLine: Record "Gen. Journal Line";
        OldAdditionalReportingCurrency: Code[10];
    begin
        // [FEATURE] [ACY]
        // Create and post General Journal Line, Reverse Transaction and verify Additional Currency Amount is reversed correctly.

        // Setup: Create Additional Currency. Create and post General Journal Line.
        Initialize();
        UpdateAddnlReportingCurrency(OldAdditionalReportingCurrency, CreateCurrencyWithAccounts());
        CreateAndPostGeneralJournalLineWithGLAccounts(GenJournalLine, '');

        // Exercise: Reverse Transaction Entry.
        ReverseGLEntries(GenJournalLine."Document No.", GenJournalLine."Account No.");

        // Verify: Verify Additional Currency Amount is reversed correctly.
        VerifyReversedAdditionalCurrencyAmount(GenJournalLine."Document No.", GenJournalLine."Account No.");

        // Tear Down: Reset initial value of Additional Reporting Currency.
        UpdateAddnlReportingCurrency(OldAdditionalReportingCurrency, OldAdditionalReportingCurrency);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure GeneralJournalLineReverseACY()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CurrencyACY: Code[10];
        OldAdditionalReportingCurrency: Code[10];
    begin
        // [FEATURE] [ACY]
        // Create and post General Journal Line with ACY, Reverse Transaction and verify Additional Currency Amount is reversed correctly.

        // Setup: Create Additional Currency. Create and post General Journal Line.
        Initialize();
        CurrencyACY := CreateCurrencyWithAccounts();
        UpdateAddnlReportingCurrency(OldAdditionalReportingCurrency, CurrencyACY);
        CreateAndPostGeneralJournalLineWithGLAccounts(GenJournalLine, CurrencyACY);

        // Exercise: Reverse Transaction Entry.
        ReverseGLEntries(GenJournalLine."Document No.", GenJournalLine."Account No.");

        // Verify: Verify Additional Currency Amount is reversed correctly.
        VerifyReversedAdditionalCurrencyAmount(GenJournalLine."Document No.", GenJournalLine."Account No.");

        // Tear Down: Reset initial value of Additional Reporting Currency.
        UpdateAddnlReportingCurrency(OldAdditionalReportingCurrency, OldAdditionalReportingCurrency);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure GeneralJournalLineReverseFCY()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CurrencyACY: Code[10];
        CurrencyFCY: Code[10];
        OldAdditionalReportingCurrency: Code[10];
    begin
        // [FEATURE] [ACY] [FCY]
        // Create and post General Journal Line with FCY, Reverse Transaction and verify Additional Currency Amount is reversed correctly.

        // Setup: Create Additional Currency and Foreign Currency. Create and post General Journal Line.
        Initialize();
        CurrencyACY := CreateCurrencyWithAccounts();
        CurrencyFCY := CreateCurrencyWithAccounts();
        UpdateAddnlReportingCurrency(OldAdditionalReportingCurrency, CurrencyACY);
        CreateAndPostGeneralJournalLineWithGLAccounts(GenJournalLine, CurrencyFCY);

        // Exercise: Reverse Transaction Entry.
        ReverseGLEntries(GenJournalLine."Document No.", GenJournalLine."Account No.");

        // Verify: Verify Additional Currency Amount is reversed correctly.
        VerifyReversedAdditionalCurrencyAmount(GenJournalLine."Document No.", GenJournalLine."Account No.");

        // Tear Down: Reset initial value of Additional Reporting Currency.
        UpdateAddnlReportingCurrency(OldAdditionalReportingCurrency, OldAdditionalReportingCurrency);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,NavigatePageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure GeneralJournalLineReverseFCYNavigate()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CurrencyACY: Code[10];
        CurrencyFCY: Code[10];
        OldAdditionalReportingCurrency: Code[10];
        NoOfGLEntries: Integer;
        NoOfGLEntriesAfterReverse: Integer;
    begin
        // [FEATURE] [ACY] [FCY]
        // Create and post General Journal Line having Vendor with Balance Account number and post reverse transaction entry for same abd Verify GL Register for same.

        // Setup: Create Additional Currency and Foreign Currency. Create and post General Journal Line.
        Initialize();
        CurrencyACY := CreateCurrencyWithAccounts();
        CurrencyFCY := CreateCurrencyWithAccounts();
        UpdateAddnlReportingCurrency(OldAdditionalReportingCurrency, CurrencyACY);

        CreateAndPostGeneralJournalLineWithGLAccounts(GenJournalLine, CurrencyFCY);

        PostingDate2 := GenJournalLine."Posting Date";  // Set Global Variable for Navigate.
        DocumentNo2 := GenJournalLine."Document No.";   // Set Global Variable for Navigate.

        // Exercise: Navigate Posted Entries and reverse Transaction Entry.
        NoOfGLEntries := NavigateEntries();
        ReverseGLEntries(GenJournalLine."Document No.", GenJournalLine."Account No.");

        // Navigate entries after Reversing the Transaction.
        Clear(TempDocumentEntry);
        NoOfGLEntriesAfterReverse := NavigateEntries();

        // Verify: Verify No. Of entries after Reversing the Transaction.
        Assert.AreEqual(NoOfGLEntries * 2, NoOfGLEntriesAfterReverse, ReverseError);

        // Tear Down: Reset initial value of Additional Reporting Currency.
        UpdateAddnlReportingCurrency(OldAdditionalReportingCurrency, OldAdditionalReportingCurrency);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure GeneralJournalLineReverseResidualRounding()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLAccountNo: Code[20];
        CurrencyACY: Code[10];
        CurrencyFCY: Code[10];
        OldAdditionalReportingCurrency: Code[10];
        LCYRoundingAccount: Code[20];
    begin
        // [FEATURE] [ACY] [FCY]
        // Create and post General Journal Line with Residual Rounding Entry, Reverse Transaction and verify Additional Currency Amount is reversed correctly.

        // Setup: Create Additional Currency and Foreign Currency. Create and post General Journal Line with Residual Rounding Entry.
        Initialize();
        CurrencyACY := CreateCurrencyWithAccounts();
        CurrencyFCY := CreateCurrencyWithAccounts();
        LCYRoundingAccount := UpdateLCYRounding(CurrencyFCY);

        UpdateAddnlReportingCurrency(OldAdditionalReportingCurrency, CurrencyACY);

        GLAccountNo := CreateGeneralJournalLineForResidual(GenJournalLine, CurrencyFCY);

        // Exercise: Reverse Transaction Entry.
        ReverseGLEntries(GenJournalLine."Document No.", GLAccountNo);

        // Verify: Verify Additional Currency Amount for Residual Entry is Reversed .
        VerifyReversedAdditionalCurrencyAmount(GenJournalLine."Document No.", LCYRoundingAccount);

        // Tear Down: Reset initial value of Additional Reporting Currency.
        UpdateAddnlReportingCurrency(OldAdditionalReportingCurrency, OldAdditionalReportingCurrency);
    end;

    [Test]
    [HandlerFunctions('ReverseEntriesModalPageHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure GeneralJournalLineReverseWithUIAndDescription()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
        ReversalEntry: Record "Reversal Entry";
        ExpectedDescription: Text;
    begin
        // [SCENARIO 232568] The description from reversal entry is transfered to posted general ledger enty
        Initialize();

        ExpectedDescription := LibraryUtility.GenerateGUID();

        // [GIVEN] Posted "G/L Entry" "G100" with "Description" = "X"
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(), -LibraryRandom.RandIntInRange(100, 200));

        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        GLEntry.FindLast();

        // [GIVEN] Reversal entry for "G100" with Description "Y"
        LibraryVariableStorage.Enqueue(ExpectedDescription);

        // [WHEN] Post reversal entry
        ReversalEntry.SetHideDialog(false);
        ReversalEntry.ReverseTransaction(GLEntry."Transaction No.");

        GLEntry.FindLast();
        GLEntry.TestField(Description, ExpectedDescription);

        // [THEN] Created reversing "G/L Entry" has desciption "Y"
        LibraryVariableStorage.AssertEmpty();
        Assert.TableIsEmpty(DATABASE::"Reversal Entry");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure GeneralJournalLineReverseSetsBothRegistersReversed()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
        ReversalEntry: Record "Reversal Entry";
        GLRegister: array[2] of Record "G/L Register";
    begin
        // [SCENARIO 304710] When reversing entries with ReverseTransaction G/L Register that is reversed gets Reversed = TRUE
        Initialize();

        // [GIVEN] Posted "G/L Entry"
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(), -LibraryRandom.RandIntInRange(100, 200));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        GLEntry.FindLast();

        // [GIVEN] G/L Register "1" for this transaction
        GLRegister[1].FindLast();

        // [WHEN] Post reversal entry for this transaction
        ReversalEntry.SetHideDialog(true);
        ReversalEntry.ReverseTransaction(GLEntry."Transaction No.");

        // [THEN] G/L Register "2" for Reversal has Reversed = TRUE
        GLRegister[2].FindLast();
        GLRegister[2].TestField(Reversed, true);

        // [THEN] G/L Register "1" for original transaction has Reversed = TRUE
        GLRegister[1].Find();
        GLRegister[1].TestField(Reversed, true);
    end;

    [Test]
    [HandlerFunctions('ReverseEntriesCheckDateModalPageHandler')]
    [Scope('OnPrem')]
    procedure GeneralJournalLineReverseCheckClosingDate()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Closind Date] [UI]
        // [SCENARIO 327812] Reverse transaction for G/L Entry with closing date.

        // [GIVEN] General Journal Line with Closing Date was created and  posted.
        Initialize();
        CreateAndPostGeneralJournalLineWithGLAccountsWithClosingDate(GenJournalLine, '');

        // [WHEN] Reverse Transaction Entry.
        ReverseTransactionOnPage(GenJournalLine."Document No.", GenJournalLine."Account No.");

        // [THEN] Field "Posting Date" in page ReverseEntries shows closing date of G/L Entry
        Assert.AreEqual(
          Format(GenJournalLine."Posting Date", 0, '<Closing><Month,2>/<Day,2>/<Year4>'),
          LibraryVariableStorage.DequeueText(),
          LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Reverse GL Entries-II");
        // Lazy Setup.
        Clear(TempDocumentEntry);
        Clear(PostingDate2);
        Clear(DocumentNo2);
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Reverse GL Entries-II");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Reverse GL Entries-II");
    end;

    local procedure CreateAndUpdateGLAccount(var GLAccount: Record "G/L Account")
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        UpdateGLAccountVATPostingGroup(GLAccount);
    end;

    local procedure CreateCurrencyAndExchangeRate(): Code[10]
    var
        Currency: Record Currency;
    begin
        Currency.Get(LibraryERM.CreateCurrencyWithGLAccountSetup());
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateCurrencyWithAccounts() CurrencyCode: Code[10]
    begin
        CurrencyCode := CreateCurrencyAndExchangeRate();
        UpdateAccountsInCurrency(CurrencyCode);
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        SelectGeneralJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType, AccountType, AccountNo, Amount);
    end;

    local procedure CreateGeneralJournalLineForResidual(var GenJournalLine: Record "Gen. Journal Line"; CurrencyCode: Code[10]): Code[20]
    var
        GLAccount: Record "G/L Account";
        GLAccount2: Record "G/L Account";
        GenJournalBatch: Record "Gen. Journal Batch";
        GLAccountNo: Code[20];
        DocumentNo: Code[20];
    begin
        // Create and Post General Journal Line with Random values.
        CreateAndUpdateGLAccount(GLAccount);
        CreateAndUpdateGLAccount(GLAccount2);

        SelectGeneralJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", GLAccount."No.", LibraryRandom.RandDec(100, 2) + 100);
        DocumentNo := GenJournalLine."Document No.";
        GLAccountNo := GenJournalLine."Account No.";
        UpdateGeneralLineForResidual(GenJournalLine, CurrencyCode, DocumentNo, false);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", GLAccount2."No.", -GenJournalLine.Amount);
        UpdateGeneralLineForResidual(GenJournalLine, CurrencyCode, DocumentNo, true);

        // Insert Residual Rounding entry.
        CODEUNIT.Run(CODEUNIT::"Adjust Gen. Journal Balance", GenJournalLine);

        // Post General Journal Line.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        exit(GLAccountNo);
    end;

    local procedure CreateAndPostGeneralJournalLineWithGLAccounts(var GenJournalLine: Record "Gen. Journal Line"; CurrencyCode: Code[10])
    var
        GLAccount: Record "G/L Account";
        GLAccount2: Record "G/L Account";
    begin
        CreateAndUpdateGLAccount(GLAccount);
        CreateAndUpdateGLAccount(GLAccount2);

        // Create General Journal Line with Random Values.
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account", GLAccount."No.",
          -LibraryRandom.RandInt(100));
        ModifyGeneralJournalLine(GenJournalLine, GLAccount2."No.", CurrencyCode);

        // Post General Journal Line.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure FindGLEntryTransactionNo(DocumentNo: Code[20]; AccountNo: Code[20]): Integer
    var
        GLEntry: Record "G/L Entry";
    begin
        FilterGLEntry(GLEntry, DocumentNo, AccountNo);
        exit(GLEntry."Transaction No.");
    end;

    local procedure FilterGLEntry(var GLEntry: Record "G/L Entry"; DocumentNo: Code[20]; AccountNo: Code[20])
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", AccountNo);
        GLEntry.FindFirst();
    end;

    local procedure GetNoOfNavigateRecords(var DocumentEntry: Record "Document Entry"; TableID: Integer): Integer
    begin
        DocumentEntry.SetRange("Table ID", TableID);
        DocumentEntry.FindFirst();
        exit(DocumentEntry."No. of Records");
    end;

    local procedure NavigateEntries(): Integer
    var
        Navigate: Page Navigate;
    begin
        Navigate.SetDoc(PostingDate2, DocumentNo2);
        Navigate.Run();
        exit(GetNoOfNavigateRecords(TempDocumentEntry, DATABASE::"G/L Entry"));
    end;

    local procedure ReverseGLEntries(DocumentNo: Code[20]; AccountNo: Code[20])
    var
        ReversalEntry: Record "Reversal Entry";
    begin
        ReversalEntry.SetHideDialog(true);
        ReversalEntry.ReverseTransaction(FindGLEntryTransactionNo(DocumentNo, AccountNo));
    end;

    local procedure SelectGeneralJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
    end;

    local procedure UpdateAccountsInCurrency(CurrencyCode: Code[10])
    var
        Currency: Record Currency;
    begin
        Currency.Get(CurrencyCode);
        LibraryERM.SetCurrencyGainLossAccounts(Currency);
    end;

    local procedure UpdateAddnlReportingCurrency(var OldAdditionalReportingCurrency: Code[10]; AdditionalReportingCurrency: Code[10])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        OldAdditionalReportingCurrency := GeneralLedgerSetup."Additional Reporting Currency";
        GeneralLedgerSetup."Additional Reporting Currency" := AdditionalReportingCurrency;
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdateGeneralLineForResidual(var GenJournalLine: Record "Gen. Journal Line"; CurrencyCode: Code[10]; DocumentNo: Code[20]; IsResidual: Boolean)
    begin
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Validate("Document No.", DocumentNo);
        GenJournalLine.Validate("Gen. Posting Type", GenJournalLine."Gen. Posting Type"::Purchase);
        GenJournalLine.Validate("Bal. Gen. Posting Type", GenJournalLine."Bal. Gen. Posting Type"::Purchase);
        GenJournalLine.Validate("Bal. Account No.", '');
        if IsResidual then
            GenJournalLine.Validate("Amount (LCY)", GenJournalLine."Amount (LCY)" + LibraryRandom.RandDec(10, 2));
        GenJournalLine.Modify(true);
    end;

    local procedure UpdateGLAccountVATPostingGroup(var GLAccount: Record "G/L Account")
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
    end;

    local procedure UpdateLCYRounding(CurrencyCode: Code[20]): Code[20]
    var
        Currency: Record Currency;
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        Currency.Get(CurrencyCode);
        Currency.Validate("Conv. LCY Rndg. Debit Acc.", GLAccount."No.");
        Currency.Validate("Conv. LCY Rndg. Credit Acc.", GLAccount."No.");
        Currency.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure ModifyGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; BalanceAccountNo: Code[20]; CurrencyCode: Code[10])
    begin
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", BalanceAccountNo);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Validate("Gen. Posting Type", GenJournalLine."Gen. Posting Type"::Purchase);
        GenJournalLine.Validate("Bal. Gen. Posting Type", GenJournalLine."Bal. Gen. Posting Type"::Purchase);
        GenJournalLine.Modify(true);
    end;

    local procedure VerifyReversedAdditionalCurrencyAmount(DocumentNo: Code[20]; AccountNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
        GLEntry2: Record "G/L Entry";
    begin
        FilterGLEntry(GLEntry, DocumentNo, AccountNo);
        GLEntry2.Get(GLEntry."Reversed by Entry No.");  // GLEntry2 used to Get the Revarsal Entry.
        GLEntry2.TestField("Additional-Currency Amount", -GLEntry."Additional-Currency Amount");
    end;

    local procedure ReverseTransactionOnPage(DocumentNo: Code[20]; AccountNo: Code[20])
    var
        ReversalEntry: Record "Reversal Entry";
    begin
        ReversalEntry.SetHideDialog(false);
        ReversalEntry.ReverseTransaction(FindGLEntryTransactionNo(DocumentNo, AccountNo));
    end;

    local procedure CreateAndPostGeneralJournalLineWithGLAccountsWithClosingDate(var GenJournalLine: Record "Gen. Journal Line"; CurrencyCode: Code[10])
    var
        GLAccount: array[2] of Record "G/L Account";
    begin
        CreateAndUpdateGLAccount(GLAccount[1]);
        CreateAndUpdateGLAccount(GLAccount[2]);

        CreateGeneralJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account", GLAccount[1]."No.",
          -LibraryRandom.RandInt(100));
        ModifyGeneralJournalLine(GenJournalLine, GLAccount[2]."No.", CurrencyCode);
        GenJournalLine.Validate("Posting Date", ClosingDate(LibraryFiscalYear.GetFirstPostingDate(false) - 1));
        GenJournalLine.Modify(true);

        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReverseEntriesModalPageHandler(var ReverseTransactionEntries: TestPage "Reverse Transaction Entries")
    var
        NewDescription: Text;
    begin
        NewDescription := LibraryVariableStorage.DequeueText();

        ReverseTransactionEntries.First();
        ReverseTransactionEntries.Description.SetValue(NewDescription);
        while ReverseTransactionEntries.Next() do
            ReverseTransactionEntries.Description.SetValue(NewDescription);
        ReverseTransactionEntries.Reverse.Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        // Handler for confirmation messages, always send positive reply.
        Reply := true;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure NavigatePageHandler(var Navigate: Page Navigate)
    begin
        Navigate.SetDoc(PostingDate2, DocumentNo2);
        Navigate.UpdateNavigateForm(false);
        Navigate.FindRecordsOnOpen();

        TempDocumentEntry.DeleteAll();
        Navigate.ReturnDocumentEntry(TempDocumentEntry);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Message Handler.
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReverseEntriesCheckDateModalPageHandler(var ReverseTransactionEntries: TestPage "Reverse Transaction Entries")
    begin
        ReverseTransactionEntries.First();
        LibraryVariableStorage.Enqueue(ReverseTransactionEntries."Posting Date".Value);
        LibraryVariableStorage.Enqueue(ReverseTransactionEntries."Posting Date".Caption);
    end;
}

