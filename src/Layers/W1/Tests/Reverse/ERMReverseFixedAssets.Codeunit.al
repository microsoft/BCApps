codeunit 134135 "ERM Reverse Fixed Assets"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Reverse] [Fixed Asset]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryJournals: Codeunit "Library - Journals";
        isInitialized: Boolean;
        AmountErr: Label '%1 must be %2.';
        ReverseErr: Label 'Book Value must not be negative or less than Salvage Value on %1 for Fixed Asset No. = %2 in Depreciation Book Code = %3.';
        FAReverseErr: Label 'You cannot reverse the transaction because the %1 %2 = %3 in %4 %5 = %6 has been sold.';
        ReverseEntryErr: Label 'You can only reverse entries that were posted from a journal.';

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler,ReverseEntriesModalPageHandler')]
    [Scope('OnPrem')]
    procedure ReverseFixedAsset()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DepreciationBook: Record "Depreciation Book";
        GenJournalBatch: Record "Gen. Journal Batch";
        ExpectedDescription: Text;
    begin
        // [SCENARIO 252239] The description from reversal entry is transfered to posted FA Ledger Entry

        Initialize();
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        DepreciationBook.Validate("G/L Integration - Acq. Cost", true);
        DepreciationBook.Modify(true);
        SetupGenJournalBatch(GenJournalBatch);
        CreateAndPostGenJournalLine(
          GenJournalLine, LibraryRandom.RandDec(100, 2), GenJournalLine."FA Posting Type"::"Acquisition Cost",
          CreateFixedAssetWithFADepreciationBook(DepreciationBook.Code), DepreciationBook.Code, GenJournalBatch);
        ExpectedDescription := LibraryUtility.GenerateGUID();
        LibraryVariableStorage.Enqueue(ExpectedDescription);

        LibraryLowerPermissions.SetJournalsPost();
        LibraryLowerPermissions.AddO365FAEdit();
        ReverseFALedgerEntry(GenJournalLine."Document No.", false);

        VerifyGLRegister();
        VerifyFALedgerEntry(
          GenJournalLine."Document No.", -GenJournalLine."Debit Amount", GenJournalLine."Credit Amount", ExpectedDescription);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure ReverseDisposalFixedAsset()
    var
        DepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
    begin
        // Check Reverse Error when Fixed Asset is Acquisition and Disposal.

        // Create General Journal Line for Fixed Asset with Acquisition Cost and Disposal and Post them then Reverse.
        Initialize();
        // Setup: Create General Journal Line for Fixed Asset.
        DocumentNo := CreateFixedAssetWithJournalLine(
            GenJournalLine, GenJournalLine."FA Posting Type"::"Acquisition Cost", GenJournalLine."FA Posting Type"::Disposal);

        // Exercise: Reverse Fixed Asset Ledger Entry.
        LibraryLowerPermissions.SetO365FAEdit();
        LibraryLowerPermissions.AddJournalsPost();
        asserterror ReverseFALedgerEntry(DocumentNo, true);

        // Verify: Verify Reverse Error for Fixed Asset on Disposed.
        Assert.ExpectedError(
          StrSubstNo(FAReverseErr, FixedAsset.TableCaption(), FixedAsset.FieldCaption("No."), GenJournalLine."Account No.",
            DepreciationBook.TableCaption(), DepreciationBook.FieldCaption(Code), GenJournalLine."Depreciation Book Code"));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure ReverseDepreciationFixedAsset()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
    begin
        // Check Reverse Error when Fixed Asset is Acquisition and Depreciation.

        // Create General Journal Line for Fixed Asset with Acquisition Cost and Depreciation and Post them then Reverse.
        Initialize();
        // Setup: Create General Journal Line for Fixed Asset.
        DocumentNo := CreateFixedAssetWithJournalLine(
            GenJournalLine, GenJournalLine."FA Posting Type"::"Acquisition Cost", GenJournalLine."FA Posting Type"::Depreciation);

        // Exercise: Reverse Fixed Asset Ledger Entry.
        LibraryLowerPermissions.SetO365FAEdit();
        LibraryLowerPermissions.AddJournalsPost();
        asserterror ReverseFALedgerEntry(DocumentNo, true);

        // Verify: Verify Reverse Error for Deprecated Fixed Asset.
        Assert.ExpectedError(
          StrSubstNo(ReverseErr, GenJournalLine."Posting Date", GenJournalLine."Account No.", GenJournalLine."Depreciation Book Code"));
    end;

    local procedure CreateFixedAssetWithJournalLine(var GenJournalLine: Record "Gen. Journal Line"; FAPostingType: Enum "Gen. Journal Line FA Posting Type"; FAPostingType2: Enum "Gen. Journal Line FA Posting Type") DocumentNo: Code[20]
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        DepreciationBookCode: Code[10];
    begin
        DepreciationBookCode := CreateDepreciationBookWithAcqCostDeprDispGLIntegration();
        SetupGenJournalBatch(GenJournalBatch);
        CreateAndPostGenJournalLine(
          GenJournalLine, LibraryRandom.RandInt(100), FAPostingType, CreateFixedAssetWithFADepreciationBook(DepreciationBookCode),
          DepreciationBookCode, GenJournalBatch);
        DocumentNo := GenJournalLine."Document No.";
        CreateAndPostGenJournalLine(
          GenJournalLine, -GenJournalLine.Amount, FAPostingType2, GenJournalLine."Account No.", DepreciationBookCode, GenJournalBatch);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler,ReverseEntriesModalPageHandler')]
    [Scope('OnPrem')]
    procedure ReverseMaintenanceFixedAsset()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DepreciationBook: Record "Depreciation Book";
        GenJournalBatch: Record "Gen. Journal Batch";
        ExpectedDescription: Text;
    begin
        // [SCENARIO 252239] The description from reversal entry is transfered to posted Maintenance Ledger Entry

        // Create General Journal Line for Fixed Asset with Mainteancne with Random Value and Post.
        Initialize();
        CreateDepreciationBookWithMaintenanceGLIntegration(DepreciationBook);
        SetupGenJournalBatch(GenJournalBatch);
        CreateAndPostGenJournalLine(
          GenJournalLine, LibraryRandom.RandDec(100, 2), GenJournalLine."FA Posting Type"::Maintenance,
          CreateFixedAssetWithFADepreciationBook(DepreciationBook.Code), DepreciationBook.Code, GenJournalBatch);
        ExpectedDescription := LibraryUtility.GenerateGUID();
        LibraryVariableStorage.Enqueue(ExpectedDescription);

        // Exercise: Reverse Maintenance Ledger Entry.
        LibraryLowerPermissions.SetO365FAEdit();
        LibraryLowerPermissions.AddJournalsPost();
        ReverseMaintenanceLedgerEntry(GenJournalLine."Document No.", false);

        // Verify: Verify Reversed Maintenance Ledger Entry.
        VerifyMaintenanceLedgerEntry(
          GenJournalLine."Document No.", -GenJournalLine."Debit Amount", GenJournalLine."Credit Amount", ExpectedDescription);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure FAReversalError()
    var
        DepreciationBook: Record "Depreciation Book";
        DocumentNo: Code[20];
    begin
        // Verify error message while Reversing FA Entries posted through Purchase Document.

        // Setup: Create Depreciation Book.
        CreateDepreciationBookWithMaintenanceGLIntegration(DepreciationBook);
        DocumentNo := CreateAndPostPurchaseInvoice(DepreciationBook);

        // Exercise: Reverse Maintenance Ledger Entry.
        LibraryLowerPermissions.SetJournalsPost();
        LibraryLowerPermissions.AddO365FAEdit();
        asserterror ReverseMaintenanceLedgerEntry(DocumentNo, true);

        // Verify: Verify error message while Reversing FA Entries.
        Assert.ExpectedError(StrSubstNo(ReverseEntryErr));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MaintenanceFixedAsset()
    var
        DepreciationBook: Record "Depreciation Book";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        FixedAsset: Code[20];
    begin
        // Post FA Entries from General Journal Line and verify Maintenance Ledger Entry.
        Initialize();

        // Setup: Create Depreciation Book.
        CreateDepreciationBookWithMaintenanceGLIntegration(DepreciationBook);
        FixedAsset := CreateFixedAssetWithFADepreciationBook(DepreciationBook.Code);
        SetupGenJournalBatch(GenJournalBatch);
        CreateGenJournalLine(
          GenJournalLine, LibraryRandom.RandDec(100, 2), GenJournalLine."FA Posting Type"::Maintenance,
          FixedAsset, DepreciationBook.Code, GenJournalBatch);

        // Exercise: Post General Journal Line with Random values.
        LibraryLowerPermissions.SetO365FAEdit();
        LibraryLowerPermissions.AddJournalsPost();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify Maintenance Ledger Entry.
        VerifyMaintenanceLedgerEntry(
          GenJournalLine."Document No.", GenJournalLine."Debit Amount", -GenJournalLine."Credit Amount", GenJournalLine.Description);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure ReverseGLAfterDisposal_ZeroAmounts_BlankedBalance()
    var
        FALedgerEntry: Record "FA Ledger Entry";
        FANo: Code[20];
        DepreciationBookCode: Code[10];
    begin
        // [FEATURE] [Disposal]
        // [SCENARIO 258761] Reverse G/L Account transaction after FA Disposal in case of
        // [SCENARIO 258761] zero Acquisition and Disposal amounts, blanked balance G/L Account No. in FA Journal for Disposal/Cancel

        // [GIVEN] Fixed Asset
        // [GIVEN] Post Acquisition Cost using Amount = 0
        // [GIVEN] Post Disposal using Amount = 0, blanked balance G/L Account
        // [GIVEN] Disposal FA Ledger Entry has "Transaction No." = 100
        CreatePostFAAcqCostAndDisposal(FALedgerEntry, FANo, DepreciationBookCode, '', 0);

        // [GIVEN] Post G/L Account. Posted "Transaction No." = 100
        // [GIVEN] Reverse "Transaction No." = 100
        // [GIVEN] The transaction has been reversed
        // [GIVEN] Last G/L Entry "Transaction No." = 101
        CreatePostAndReverseGLAccount(FALedgerEntry."Transaction No.");

        // [GIVEN] Cancel Disposal FA Ledger Entry using blanked balance G/L Account
        CancelFALedgerEntry(FALedgerEntry."Entry No.", DepreciationBookCode, '');
        // [GIVEN] There are two FA Error Ledger Entries, both has "Transaction No." = 0
        VerifyCanceledFALedgerEntry(FANo, 0, 2);

        // [WHEN] Reverse "Transaction No." = 100
        asserterror LibraryERM.ReverseTransaction(FALedgerEntry."Transaction No.");

        // [THEN] System throws an error "You cannot reverse G/L Entry No. 2822 because the entry has already been involved in a reversal."
        VerifyAlreadyReversedTransactionError();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure ReverseGLAfterDisposal_ZeroAmounts_BlankedBalCancel()
    var
        FALedgerEntry: Record "FA Ledger Entry";
        FANo: Code[20];
        DepreciationBookCode: Code[10];
    begin
        // [FEATURE] [Disposal]
        // [SCENARIO 258761] Reverse G/L Account transaction after FA Disposal in case of
        // [SCENARIO 258761] zero Acquisition and Disposal amounts, balance G/L Account No. in FA Journal for Disposal,
        // [SCENARIO 258761] blanked balance G/L Account No. for Cancel

        // [GIVEN] Fixed Asset
        // [GIVEN] Post Acquisition Cost using Amount = 0
        // [GIVEN] Post Disposal using Amount = 0, balance G/L Account
        // [GIVEN] Disposal FA Ledger Entry has "Transaction No." = 100
        CreatePostFAAcqCostAndDisposal(FALedgerEntry, FANo, DepreciationBookCode, LibraryERM.CreateGLAccountNo(), 0);

        // [GIVEN] Post G/L Account. Posted "Transaction No." = 101
        // [GIVEN] Reverse "Transaction No." = 101
        // [GIVEN] The transaction has been reversed
        // [GIVEN] Last G/L Entry "Transaction No." = 102
        CreatePostAndReverseGLAccount(FALedgerEntry."Transaction No." + 1);

        // [GIVEN] Cancel Disposal FA Ledger Entry using blanked balance G/L Account
        CancelFALedgerEntry(FALedgerEntry."Entry No.", DepreciationBookCode, '');
        // [GIVEN] There are two FA Error Ledger Entries, both has "Transaction No." = 0
        VerifyCanceledFALedgerEntry(FANo, 0, 2);

        // [WHEN] Reverse "Transaction No." = 101
        asserterror LibraryERM.ReverseTransaction(FALedgerEntry."Transaction No." + 1);

        // [THEN] System throws an error "You cannot reverse G/L Entry No. 2822 because the entry has already been involved in a reversal."
        VerifyAlreadyReversedTransactionError();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure ReverseGLAfterDisposal_Amounts()
    var
        FALedgerEntry: Record "FA Ledger Entry";
        FANo: Code[20];
        DepreciationBookCode: Code[10];
    begin
        // [FEATURE] [Disposal]
        // [SCENARIO 258761] Reverse G/L Account transaction after FA Disposal in case of
        // [SCENARIO 258761] Acquisition and Disposal amounts, balance G/L Account No. in FA Journal for Disposal/Cancel

        // [GIVEN] Fixed Asset
        // [GIVEN] Post Acquisition Cost using Amount = 100
        // [GIVEN] Post Disposal using Amount = -100, balance G/L Account
        // [GIVEN] Disposal FA Ledger Entry has "Transaction No." = 100
        CreatePostFAAcqCostAndDisposal(
          FALedgerEntry, FANo, DepreciationBookCode, LibraryERM.CreateGLAccountNo(), LibraryRandom.RandDecInRange(1000, 2000, 2));

        // [GIVEN] Post G/L Account. Posted "Transaction No." = 101
        // [GIVEN] Reverse "Transaction No." = 101
        // [GIVEN] The transaction has been reversed
        // [GIVEN] Last G/L Entry "Transaction No." = 102
        CreatePostAndReverseGLAccount(FALedgerEntry."Transaction No." + 1);

        // [GIVEN] Cancel Disposal FA Ledger Entry using balance G/L Account
        CancelFALedgerEntry(FALedgerEntry."Entry No.", DepreciationBookCode, LibraryERM.CreateGLAccountNo());
        // [GIVEN] There are 4 FA Error Ledger Entries:
        // [GIVEN] A pair of Acquisition/Disposal with "Transaction No." = 100, a pair of Acquisition/Disposal with "Transaction No." = 103
        VerifyCanceledFALedgerEntry(FANo, FALedgerEntry."Transaction No.", 2);
        VerifyCanceledFALedgerEntry(FANo, FALedgerEntry."Transaction No." + 3, 2);

        // [WHEN] Reverse "Transaction No." = 101
        asserterror LibraryERM.ReverseTransaction(FALedgerEntry."Transaction No." + 1);

        // [THEN] System throws an error "You cannot reverse G/L Entry No. 2822 because the entry has already been involved in a reversal."
        VerifyAlreadyReversedTransactionError();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure ReverseGLAfterCancelDisposal_ZeroAmounts_BlankedBalance()
    var
        FALedgerEntry: Record "FA Ledger Entry";
        FANo: Code[20];
        DepreciationBookCode: Code[10];
    begin
        // [FEATURE] [Disposal]
        // [SCENARIO 258761] Reverse G/L Account transaction after Cancel FA Disposal in case of
        // [SCENARIO 258761] zero Acquisition and Disposal amounts, blanked balance G/L Account No. in FA Journal for Disposal/Cancel

        // [GIVEN] Fixed Asset
        // [GIVEN] Post Acquisition Cost using Amount = 0
        // [GIVEN] Post Disposal using Amount = 0, blanked balance G/L Account
        // [GIVEN] Disposal FA Ledger Entry has "Transaction No." = 100
        CreatePostFAAcqCostAndDisposal(FALedgerEntry, FANo, DepreciationBookCode, '', 0);

        // [GIVEN] Post G/L Account. Posted "Transaction No." = 100
        CreatePostGLAccount();
        VerifyLastGLTransactionNo(FALedgerEntry."Transaction No.");

        // [GIVEN] Cancel Disposal FA Ledger Entry using blanked balance G/L Account
        CancelFALedgerEntry(FALedgerEntry."Entry No.", DepreciationBookCode, '');
        // [GIVEN] There are two FA Error Ledger Entries, both has "Transaction No." = 0
        VerifyCanceledFALedgerEntry(FANo, 0, 2);

        // [WHEN] Reverse "Transaction No." = 100
        LibraryERM.ReverseTransaction(FALedgerEntry."Transaction No.");

        // [THEN] The transaction has been reversed
        // [THEN] Last G/L Entry "Transaction No." = 101
        VerifyLastGLTransactionNo(FALedgerEntry."Transaction No." + 1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure ReverseGLAfterCancelDisposal_ZeroAmounts_BlankedBalDisposal()
    var
        FALedgerEntry: Record "FA Ledger Entry";
        FANo: Code[20];
        DepreciationBookCode: Code[10];
    begin
        // [FEATURE] [Disposal]
        // [SCENARIO 258761] Reverse G/L Account transaction after Cancel FA Disposal in case of
        // [SCENARIO 258761] zero Acquisition and Disposal amounts, blanked balance G/L Account No. in FA Journal for Disposal,
        // [SCENARIO 258761] balance G/L Account No. for Cancel

        // [GIVEN] Fixed Asset
        // [GIVEN] Post Acquisition Cost using Amount = 0
        // [GIVEN] Post Disposal using Amount = 0, blanked balance G/L Account
        // [GIVEN] Disposal FA Ledger Entry has "Transaction No." = 100
        CreatePostFAAcqCostAndDisposal(FALedgerEntry, FANo, DepreciationBookCode, '', 0);

        // [GIVEN] Post G/L Account. Posted "Transaction No." = 100
        CreatePostGLAccount();
        VerifyLastGLTransactionNo(FALedgerEntry."Transaction No.");

        // [GIVEN] Cancel Disposal FA Ledger Entry using balance G/L Account
        CancelFALedgerEntry(FALedgerEntry."Entry No.", DepreciationBookCode, LibraryERM.CreateGLAccountNo());
        // [GIVEN] There are two FA Error Ledger Entries, both has "Transaction No." = 0
        VerifyCanceledFALedgerEntry(FANo, 0, 2);

        // [WHEN] Reverse "Transaction No." = 100
        LibraryERM.ReverseTransaction(FALedgerEntry."Transaction No.");

        // [THEN] The transaction has been reversed
        // [THEN] Last G/L Entry "Transaction No." = 102
        VerifyLastGLTransactionNo(FALedgerEntry."Transaction No." + 2);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure ReverseGLAfterCancelDisposal_ZeroAmounts_BlankedBalCancel()
    var
        FALedgerEntry: Record "FA Ledger Entry";
        FANo: Code[20];
        DepreciationBookCode: Code[10];
    begin
        // [FEATURE] [Disposal]
        // [SCENARIO 258761] Reverse G/L Account transaction after Cancel FA Disposal in case of
        // [SCENARIO 258761] zero Acquisition and Disposal amounts, balance G/L Account No. in FA Journal for Disposal,
        // [SCENARIO 258761] blanked balance G/L Account No. for Cancel

        // [GIVEN] Fixed Asset
        // [GIVEN] Post Acquisition Cost using Amount = 0
        // [GIVEN] Post Disposal using Amount = 0, balance G/L Account
        // [GIVEN] Disposal FA Ledger Entry has "Transaction No." = 100
        CreatePostFAAcqCostAndDisposal(FALedgerEntry, FANo, DepreciationBookCode, LibraryERM.CreateGLAccountNo(), 0);

        // [GIVEN] Post G/L Account. Posted "Transaction No." = 101
        CreatePostGLAccount();
        VerifyLastGLTransactionNo(FALedgerEntry."Transaction No." + 1);

        // [GIVEN] Cancel Disposal FA Ledger Entry using blanked balance G/L Account
        CancelFALedgerEntry(FALedgerEntry."Entry No.", DepreciationBookCode, '');
        // [GIVEN] There are two FA Error Ledger Entries, both has "Transaction No." = 0
        VerifyCanceledFALedgerEntry(FANo, 0, 2);

        // [WHEN] Reverse "Transaction No." = 101
        LibraryERM.ReverseTransaction(FALedgerEntry."Transaction No." + 1);

        // [THEN] The transaction has been reversed
        // [THEN] Last G/L Entry "Transaction No." = 102
        VerifyLastGLTransactionNo(FALedgerEntry."Transaction No." + 2);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure ReverseGLAfterCancelDisposal_ZeroAmounts_Balance()
    var
        FALedgerEntry: Record "FA Ledger Entry";
        FANo: Code[20];
        DepreciationBookCode: Code[10];
    begin
        // [FEATURE] [Disposal]
        // [SCENARIO 258761] Reverse G/L Account transaction after Cancel FA Disposal in case of
        // [SCENARIO 258761] zero Acquisition and Disposal amounts, balance G/L Account No. in FA Journal for Disposal/Cancel

        // [GIVEN] Fixed Asset
        // [GIVEN] Post Acquisition Cost using Amount = 0
        // [GIVEN] Post Disposal using Amount = 0, balance G/L Account
        // [GIVEN] Disposal FA Ledger Entry has "Transaction No." = 100
        CreatePostFAAcqCostAndDisposal(FALedgerEntry, FANo, DepreciationBookCode, LibraryERM.CreateGLAccountNo(), 0);

        // [GIVEN] Post G/L Account. Posted "Transaction No." = 101
        CreatePostGLAccount();
        VerifyLastGLTransactionNo(FALedgerEntry."Transaction No." + 1);

        // [GIVEN] Cancel Disposal FA Ledger Entry using balance G/L Account
        CancelFALedgerEntry(FALedgerEntry."Entry No.", DepreciationBookCode, LibraryERM.CreateGLAccountNo());
        // [GIVEN] There are two FA Error Ledger Entries, both has "Transaction No." = 0
        VerifyCanceledFALedgerEntry(FANo, 0, 2);

        // [WHEN] Reverse "Transaction No." = 101
        LibraryERM.ReverseTransaction(FALedgerEntry."Transaction No." + 1);

        // [THEN] The transaction has been reversed
        // [THEN] Last G/L Entry "Transaction No." = 103
        VerifyLastGLTransactionNo(FALedgerEntry."Transaction No." + 3);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure ReverseGLAfterCancelDisposal_Amounts()
    var
        FALedgerEntry: Record "FA Ledger Entry";
        FANo: Code[20];
        DepreciationBookCode: Code[10];
    begin
        // [FEATURE] [Disposal]
        // [SCENARIO 258761] Reverse G/L Account transaction after Cancel FA Disposal in case of
        // [SCENARIO 258761] Acquisition and Disposal amounts, balance G/L Account No. in FA Journal for Disposal/Cancel

        // [GIVEN] Fixed Asset
        // [GIVEN] Post Acquisition Cost using Amount = 100
        // [GIVEN] Post Disposal using Amount = -100, balance G/L Account
        // [GIVEN] Disposal FA Ledger Entry has "Transaction No." = 100
        CreatePostFAAcqCostAndDisposal(
          FALedgerEntry, FANo, DepreciationBookCode, LibraryERM.CreateGLAccountNo(), LibraryRandom.RandDecInRange(1000, 2000, 2));

        // [GIVEN] Post G/L Account. Posted "Transaction No." = 101
        CreatePostGLAccount();
        VerifyLastGLTransactionNo(FALedgerEntry."Transaction No." + 1);

        // [GIVEN] Cancel Disposal FA Ledger Entry using balance G/L Account
        CancelFALedgerEntry(FALedgerEntry."Entry No.", DepreciationBookCode, LibraryERM.CreateGLAccountNo());
        // [GIVEN] There are 4 FA Error Ledger Entries:
        // [GIVEN] A pair of Acquisition/Disposal with "Transaction No." = 100, a pair of Acquisition/Disposal with "Transaction No." = 102
        VerifyCanceledFALedgerEntry(FANo, FALedgerEntry."Transaction No.", 2);
        VerifyCanceledFALedgerEntry(FANo, FALedgerEntry."Transaction No." + 2, 2);

        // [WHEN] Reverse "Transaction No." = 101
        LibraryERM.ReverseTransaction(FALedgerEntry."Transaction No." + 1);

        // [THEN] The transaction has been reversed
        // [THEN] Last G/L Entry "Transaction No." = 103
        VerifyLastGLTransactionNo(FALedgerEntry."Transaction No." + 3);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Reverse Fixed Assets");
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Reverse Fixed Assets");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Reverse Fixed Assets");
    end;

    local procedure CreatePostFAAcqCostAndDisposal(var FALedgerEntry: Record "FA Ledger Entry"; var FANo: Code[20]; var DepreciationBookCode: Code[10]; DisposalBalanceAccNo: Code[20]; Amount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        Initialize();
        DepreciationBookCode := CreateDepreciationBookWithAcqCostDeprDispGLIntegration();
        CreateFAJournalSetup(DepreciationBookCode);
        FANo := CreateFixedAssetWithFADepreciationBook(DepreciationBookCode);

        CreatePostFAGLJournal(
          GenJournalLine."FA Posting Type"::"Acquisition Cost", FANo, DepreciationBookCode, LibraryERM.CreateGLAccountNo(), Amount);
        CreatePostFAGLJournal(GenJournalLine."FA Posting Type"::Disposal, FANo, DepreciationBookCode, DisposalBalanceAccNo, -Amount);
        FindFALedgerEntry(FALedgerEntry, FANo, FALedgerEntry."FA Posting Type"::"Proceeds on Disposal");
        FALedgerEntry.TestField("Transaction No.");
    end;

    local procedure CreateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; Amount: Decimal; FAPostingType: Enum "Gen. Journal Line FA Posting Type"; AccountNo: Code[20]; DepreciationBookCode: Code[10]; GenJournalBatch: Record "Gen. Journal Batch")
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"Fixed Asset", AccountNo, Amount);
        GenJournalLine.Validate("FA Posting Type", FAPostingType);
        GenJournalLine.Validate("Depreciation Book Code", DepreciationBookCode);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateAndPostGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; Amount: Decimal; FAPostingType: Enum "Gen. Journal Line FA Posting Type"; AccountNo: Code[20]; DepreciationBookCode: Code[10]; GenJournalBatch: Record "Gen. Journal Batch")
    begin
        CreateGenJournalLine(
          GenJournalLine, Amount, FAPostingType, AccountNo, DepreciationBookCode, GenJournalBatch);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateFixedAssetWithFADepreciationBook(DepreciationBookCode: Code[10]): Code[20]
    var
        FixedAsset: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        FAPostingGroup: Record "FA Posting Group";
    begin
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", DepreciationBookCode);
        FADepreciationBook.Validate("FA Posting Group", FAPostingGroup.Code);
        FADepreciationBook.Modify(true);
        exit(FixedAsset."No.");
    end;

    local procedure CreateAndPostPurchaseInvoice(DepreciationBook: Record "Depreciation Book"): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        PurchaseHeader.Validate("Vendor Invoice No.", Vendor."No.");
        PurchaseHeader.Modify(true);

        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Fixed Asset", CreateFixedAssetWithFADepreciationBook(DepreciationBook.Code),
          LibraryRandom.RandInt(10));  // Use Random Number Generator for Quantity.
        PurchaseLine.Validate("FA Posting Type", PurchaseLine."FA Posting Type"::Maintenance);
        PurchaseLine.Validate("Depreciation Book Code", DepreciationBook.Code);
        PurchaseLine.Modify(true);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreatePostFAGLJournal(FAPostingType: Enum "Gen. Journal Line FA Posting Type"; FANo: Code[20]; DepreciationBookCode: Code[10]; BalGLAccountNo: Code[20]; LineAmount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryJournals.CreateGenJournalBatchWithType(GenJournalBatch, GenJournalBatch."Template Type"::Assets);
        LibraryJournals.CreateGenJournalLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"Fixed Asset", FANo,
          GenJournalLine."Bal. Account Type"::"G/L Account", BalGLAccountNo, LineAmount);
        GenJournalLine.Validate("FA Posting Type", FAPostingType);
        GenJournalLine.Validate("Depreciation Book Code", DepreciationBookCode);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreatePostGLAccount()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account",
          LibraryERM.CreateGLAccountNo(), LibraryRandom.RandDecInDecimalRange(1000, 2000, 2));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreatePostAndReverseGLAccount(ExpectedTransactionNo: Integer)
    begin
        CreatePostGLAccount();
        VerifyLastGLTransactionNo(ExpectedTransactionNo);
        LibraryERM.ReverseTransaction(ExpectedTransactionNo);
        VerifyLastGLTransactionNo(ExpectedTransactionNo + 1);
    end;

    local procedure CreateDepreciationBookWithAcqCostDeprDispGLIntegration(): Code[10]
    var
        DepreciationBook: Record "Depreciation Book";
    begin
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        DepreciationBook.Validate("G/L Integration - Acq. Cost", true);
        DepreciationBook.Validate("G/L Integration - Maintenance", false);
        DepreciationBook.Validate("G/L Integration - Depreciation", true);
        DepreciationBook.Validate("G/L Integration - Disposal", true);
        DepreciationBook.Modify(true);
        exit(DepreciationBook.Code);
    end;

    local procedure CreateDepreciationBookWithMaintenanceGLIntegration(var DepreciationBook: Record "Depreciation Book")
    begin
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        DepreciationBook.Validate("G/L Integration - Maintenance", true);
        DepreciationBook.Modify(true);
    end;

    local procedure CreateFAJournalSetup(DepreciationBookCode: Code[10])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        FAJournalSetup: Record "FA Journal Setup";
    begin
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        LibraryFixedAsset.CreateFAJournalSetup(FAJournalSetup, DepreciationBookCode, '');
        FAJournalSetup.Validate("Gen. Jnl. Template Name", GenJournalBatch."Journal Template Name");
        FAJournalSetup.Validate("Gen. Jnl. Batch Name", GenJournalBatch.Name);
        FAJournalSetup.Modify(true);
    end;

    local procedure CancelFALedgerEntry(FALedgerEntryNo: Integer; DepreciationBookCode: Code[10]; BalGLAccountNo: Code[20])
    var
        FALedgerEntry: Record "FA Ledger Entry";
        FAJournalSetup: Record "FA Journal Setup";
        GenJournalLine: Record "Gen. Journal Line";
        CancelFALedgerEntries: Codeunit "Cancel FA Ledger Entries";
    begin
        FALedgerEntry.SetRange("Entry No.", FALedgerEntryNo);
        CancelFALedgerEntries.TransferLine(FALedgerEntry, false, 0D);
        FAJournalSetup.Get(DepreciationBookCode, '');
        GenJournalLine.SetRange("Journal Template Name", FAJournalSetup."Gen. Jnl. Template Name");
        GenJournalLine.SetRange("Journal Batch Name", FAJournalSetup."Gen. Jnl. Batch Name");
        GenJournalLine.SetFilter("FA Error Entry No.", '<>%1', FALedgerEntry."Entry No.");
        GenJournalLine.DeleteAll(true);
        GenJournalLine.SetRange("FA Error Entry No.");
        GenJournalLine.FindFirst();
        GenJournalLine.Validate("Document No.", LibraryUtility.GenerateGUID());
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", BalGLAccountNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure FindFALedgerEntry(var FALedgerEntry: Record "FA Ledger Entry"; FixedAssetNo: Code[20]; FAPostingType: Enum "FA Ledger Entry FA Posting Type")
    begin
        Clear(FALedgerEntry);
        FALedgerEntry.SetRange("FA No.", FixedAssetNo);
        FALedgerEntry.SetRange("FA Posting Type", FAPostingType);
        FALedgerEntry.FindFirst();
    end;

    local procedure SetupGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
    end;

    local procedure ReverseFALedgerEntry(DocumentNo: Code[20]; HideUI: Boolean)
    var
        FALedgerEntry: Record "FA Ledger Entry";
        ReversalEntry: Record "Reversal Entry";
    begin
        FALedgerEntry.SetRange("Document No.", DocumentNo);
        FALedgerEntry.FindFirst();

        ReversalEntry.SetHideDialog(HideUI);
        ReversalEntry.ReverseTransaction(FALedgerEntry."Transaction No.");
    end;

    local procedure ReverseMaintenanceLedgerEntry(DocumentNo: Code[20]; HideUI: Boolean)
    var
        MaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        ReversalEntry: Record "Reversal Entry";
    begin
        MaintenanceLedgerEntry.SetRange("Document No.", DocumentNo);
        MaintenanceLedgerEntry.FindFirst();
        ReversalEntry.SetHideDialog(HideUI);
        ReversalEntry.ReverseTransaction(MaintenanceLedgerEntry."Transaction No.");
    end;

    local procedure VerifyFALedgerEntry(DocumentNo: Code[20]; DebitAmount: Decimal; CreditAmount: Decimal; ExpectedDescription: Text)
    var
        FALedgerEntry: Record "FA Ledger Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        FALedgerEntry.SetRange("Document No.", DocumentNo);
        FALedgerEntry.FindLast();
        Assert.AreNearlyEqual(
          DebitAmount, FALedgerEntry."Debit Amount", GeneralLedgerSetup."Appln. Rounding Precision",
          StrSubstNo(AmountErr, FALedgerEntry.FieldCaption("Debit Amount"), DebitAmount));
        FALedgerEntry.TestField("Credit Amount", CreditAmount);
        FALedgerEntry.TestField(Description, ExpectedDescription);
    end;

    local procedure VerifyMaintenanceLedgerEntry(DocumentNo: Code[20]; DebitAmount: Decimal; CreditAmount: Decimal; ExpectedDescription: Text)
    var
        MaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        MaintenanceLedgerEntry.SetRange("Document No.", DocumentNo);
        MaintenanceLedgerEntry.FindLast();
        Assert.AreNearlyEqual(
          DebitAmount, MaintenanceLedgerEntry."Debit Amount", GeneralLedgerSetup."Appln. Rounding Precision",
          StrSubstNo(AmountErr, MaintenanceLedgerEntry.FieldCaption("Debit Amount"), DebitAmount));
        MaintenanceLedgerEntry.TestField("Credit Amount", CreditAmount);
        MaintenanceLedgerEntry.TestField(Description, ExpectedDescription);
    end;

    local procedure VerifyGLRegister()
    var
        GLRegister: Record "G/L Register";
    begin
        GLRegister.FindLast();
        GLRegister.TestField(Reversed, true);
    end;

    local procedure VerifyLastGLTransactionNo(ExpectedTransactionNo: Integer)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.FindLast();
        GLEntry.TestField("Transaction No.", ExpectedTransactionNo);
    end;

    local procedure VerifyCanceledFALedgerEntry(CanceledFromFANo: Code[20]; TransactionNo: Integer; ExpectedCount: Integer)
    var
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        FALedgerEntry.SetRange("Canceled from FA No.", CanceledFromFANo);
        FALedgerEntry.SetRange("Transaction No.", TransactionNo);
        Assert.RecordCount(FALedgerEntry, ExpectedCount);
    end;

    local procedure VerifyAlreadyReversedTransactionError()
    begin
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError('entry has already been involved in a reversal');
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Dummy Message Handler.
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
}

