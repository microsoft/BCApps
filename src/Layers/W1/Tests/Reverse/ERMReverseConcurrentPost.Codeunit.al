codeunit 134149 "ERM Reverse Concurrent Post"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Reverse] [Concurrent Posting]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        IsInitialized: Boolean;
        ReverseSignErr: Label 'Reversed must be TRUE in G/L Entry for Document No. %1.';
        ReversalErr: Label 'You cannot reverse G/L Register No. %1 because the register has already been involved in a reversal.';

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ReverseGLTransactionUseConcurrentPost()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ReversalEntry: Record "Reversal Entry";
        GLAccount: Record "G/L Account";
    begin
        // [FEATURE] [Use Concurrent Posting]
        // [SCENARIO] Reverse a GL transaction while "Use Concurrent Posting" is enabled in General Ledger Setup.
        // [GIVEN] "Use Concurrent Posting" is enabled in General Ledger Setup.
        // [GIVEN] A posted general journal line for a G/L account.
        Initialize();
        LibraryERM.FindGLAccount(GLAccount);
        CreateAndPostGLJournalLine(GenJournalLine, GLAccount."No.");

        // [WHEN] The transaction is reversed.
        ReversalEntry.SetHideDialog(true);
        ReversalEntry.ReverseTransaction(GetGLEntryTransactionNo(GenJournalLine."Document No.", GenJournalLine."Account No."));

        // [THEN] G/L entries for the document are marked as reversed.
        VerifyGLEntriesReversed(GenJournalLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ReverseGLRegisterUseConcurrentPost()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLRegister: Record "G/L Register";
        ReversalEntry: Record "Reversal Entry";
        GLAccount: Record "G/L Account";
    begin
        // [FEATURE] [Use Concurrent Posting]
        // [SCENARIO] Reverse a GL register while "Use Concurrent Posting" is enabled in General Ledger Setup.
        // [GIVEN] "Use Concurrent Posting" is enabled in General Ledger Setup.
        // [GIVEN] A posted general journal line for a G/L account.
        Initialize();
        LibraryERM.FindGLAccount(GLAccount);
        CreateAndPostGLJournalLine(GenJournalLine, GLAccount."No.");

        // [WHEN] The GL register is reversed.
        GLRegister.FindLast();
        ReversalEntry.SetHideDialog(true);
        ReversalEntry.ReverseRegister(GLRegister."No.");

        // [THEN] G/L entries for the document are marked as reversed.
        VerifyGLEntriesReversed(GenJournalLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ReverseCustomerLedgerUseConcurrentPost()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        ReversalEntry: Record "Reversal Entry";
    begin
        // [FEATURE] [Use Concurrent Posting] [Customer]
        // [SCENARIO] Reverse a customer ledger entry while "Use Concurrent Posting" is enabled in General Ledger Setup.
        // [GIVEN] "Use Concurrent Posting" is enabled in General Ledger Setup.
        // [GIVEN] A posted general journal line for a customer account.
        Initialize();
        CreateAndPostCustomerJournalLine(GenJournalLine, LibrarySales.CreateCustomerNo());

        // [WHEN] The transaction is reversed.
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::" ", GenJournalLine."Document No.");
        ReversalEntry.SetHideDialog(true);
        ReversalEntry.ReverseTransaction(CustLedgerEntry."Transaction No.");

        // [THEN] Customer ledger entries for the document are marked as reversed.
        VerifyCustomerLedgerEntriesReversed(GenJournalLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ReverseVendorLedgerUseConcurrentPost()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        ReversalEntry: Record "Reversal Entry";
    begin
        // [FEATURE] [Use Concurrent Posting] [Vendor]
        // [SCENARIO] Reverse a vendor ledger entry while "Use Concurrent Posting" is enabled in General Ledger Setup.
        // [GIVEN] "Use Concurrent Posting" is enabled in General Ledger Setup.
        // [GIVEN] A posted general journal line for a vendor account.
        Initialize();
        CreateAndPostVendorJournalLine(GenJournalLine, LibraryPurchase.CreateVendorNo());

        // [WHEN] The transaction is reversed.
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::" ", GenJournalLine."Document No.");
        ReversalEntry.SetHideDialog(true);
        ReversalEntry.ReverseTransaction(VendorLedgerEntry."Transaction No.");

        // [THEN] Vendor ledger entries for the document are marked as reversed.
        VerifyVendorLedgerEntriesReversed(GenJournalLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure AlreadyReversedRegUseConcurrentPost()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLRegister: Record "G/L Register";
        ReversalEntry: Record "Reversal Entry";
        GLAccount: Record "G/L Account";
        GLRegisterNo: Integer;
    begin
        // [FEATURE] [Use Concurrent Posting]
        // [SCENARIO] Try to reverse a GL register that was already reversed while "Use Concurrent Posting" is enabled.
        // [GIVEN] "Use Concurrent Posting" is enabled in General Ledger Setup.
        // [GIVEN] A posted and already-reversed GL register entry.
        Initialize();
        LibraryERM.FindGLAccount(GLAccount);
        CreateAndPostGLJournalLine(GenJournalLine, GLAccount."No.");
        GLRegister.FindLast();
        GLRegisterNo := GLRegister."No.";
        ReversalEntry.SetHideDialog(true);
        ReversalEntry.ReverseRegister(GLRegisterNo);

        // [WHEN] The same GL register is reversed again.
        asserterror ReversalEntry.ReverseRegister(GLRegisterNo);

        // [THEN] An error is raised that the register has already been reversed.
        Assert.AreEqual(StrSubstNo(ReversalErr, GLRegisterNo), GetLastErrorText, 'Unexpected error message when reversing an already-reversed register.');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ReverseGLTransactionNoConcurrentPost()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ReversalEntry: Record "Reversal Entry";
        GLAccount: Record "G/L Account";
    begin
        // [FEATURE] [Use Concurrent Posting]
        // [SCENARIO] Reverse a GL transaction with "Use Concurrent Posting" = FALSE produces the same result.
        // [GIVEN] "Use Concurrent Posting" is disabled in General Ledger Setup.
        // [GIVEN] A posted general journal line for a G/L account.
        Initialize();
        EnableConcurrentPosting(false);
        LibraryERM.FindGLAccount(GLAccount);
        CreateAndPostGLJournalLine(GenJournalLine, GLAccount."No.");

        // [WHEN] The transaction is reversed with "Use Concurrent Posting" disabled.
        ReversalEntry.SetHideDialog(true);
        ReversalEntry.ReverseTransaction(GetGLEntryTransactionNo(GenJournalLine."Document No.", GenJournalLine."Account No."));

        // [THEN] G/L entries for the document are marked as reversed, same as when concurrent posting is enabled.
        VerifyGLEntriesReversed(GenJournalLine."Document No.");
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Reverse Concurrent Post");
        LibrarySetupStorage.Restore();
        if IsInitialized then begin
            EnableConcurrentPosting(true);
            Commit();
            exit;
        end;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Reverse Concurrent Post");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        IsInitialized := true;
        Commit();
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        EnableConcurrentPosting(true);
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Reverse Concurrent Post");
    end;

    local procedure EnableConcurrentPosting(Enable: Boolean)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Use Concurrent Posting" := Enable;
        GeneralLedgerSetup.Modify();
    end;

    local procedure CreateAndPostGLJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GLAccountNo: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
            GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account",
            GLAccountNo, LibraryRandom.RandInt(100));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndPostCustomerJournalLine(var GenJournalLine: Record "Gen. Journal Line"; CustomerNo: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
            GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::Customer,
            CustomerNo, -LibraryRandom.RandInt(100));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndPostVendorJournalLine(var GenJournalLine: Record "Gen. Journal Line"; VendorNo: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
            GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::Vendor,
            VendorNo, LibraryRandom.RandInt(100));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure GetGLEntryTransactionNo(DocumentNo: Code[20]; AccountNo: Code[20]): Integer
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", AccountNo);
        GLEntry.FindFirst();
        exit(GLEntry."Transaction No.");
    end;

    local procedure VerifyGLEntriesReversed(DocumentNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.FindSet();
        repeat
            Assert.AreEqual(true, GLEntry.Reversed, StrSubstNo(ReverseSignErr, DocumentNo));
        until GLEntry.Next() = 0;
    end;

    local procedure VerifyCustomerLedgerEntriesReversed(DocumentNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::" ", DocumentNo);
        CustLedgerEntry.FindSet();
        repeat
            Assert.AreEqual(true, CustLedgerEntry.Reversed, StrSubstNo(ReverseSignErr, DocumentNo));
        until CustLedgerEntry.Next() = 0;
    end;

    local procedure VerifyVendorLedgerEntriesReversed(DocumentNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::" ", DocumentNo);
        VendorLedgerEntry.FindSet();
        repeat
            Assert.AreEqual(true, VendorLedgerEntry.Reversed, StrSubstNo(ReverseSignErr, DocumentNo));
        until VendorLedgerEntry.Next() = 0;
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;
}
