codeunit 134145 "ERM Reverse Diff Amount Type"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Reverse]
    end;

    var
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        AmountError: Label '%1 must be %2 in %3 %4=%5.';
        EqualAmountError: Label 'Amount must be Zero.';

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ReverseDebitAmountLCY()
    begin
        // Create and Post General Journal Line for G/L Account. Reverse Transaction from G/L Entries and Verify Debit Amount
        // in G/L Entry and Balance for G/L Account.
        ReverseDebitAmount('');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ReverseDebitAmountFCY()
    begin
        // Create and Post General Journal Line for G/L Account with Currency. Reverse Transaction from G/L Entries and Verify Debit Amount
        // in G/L Entry and Balance for G/L Account.
        ReverseDebitAmount(CreateCurrency());
    end;

    local procedure ReverseDebitAmount(CurrencyCode: Code[10])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        ReverseDifferentAmount(GenJournalLine, LibraryRandom.RandDec(10, 2), CurrencyCode);

        // Verify: Verify Reversal Credit Entry in G/L Entry and Balance for G/L Account.
        VerifyBalanceAndDebitAmount(GenJournalLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ReverseCreditAmountLCY()
    begin
        // Create and Post General Journal Line for G/L Account. Reverse Transaction from G/L Entries and Verify Credit Amount
        // in G/L Entry and Balance for G/L Account.
        ReverseCreditAmount('');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ReverseCreditAmountFCY()
    begin
        // Create and Post General Journal Line for G/L Account with Currency. Reverse Transaction from G/L Entries and Verify Credit Amount
        // in G/L Entry and Balance for G/L Account.
        ReverseCreditAmount(CreateCurrency());
    end;

    local procedure ReverseCreditAmount(CurrencyCode: Code[10])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        ReverseDifferentAmount(GenJournalLine, -LibraryRandom.RandDec(10, 2), CurrencyCode);

        // Verify: Verify Reversal Credit Entry in G/L Entry and Balance for G/L Account.
        VerifyBalanceAndCreditAmount(GenJournalLine);
    end;

    local procedure ReverseDifferentAmount(var GenJournalLine: Record "Gen. Journal Line"; Amount: Decimal; CurrencyCode: Code[10])
    var
        GLEntry: Record "G/L Entry";
        ReversalEntry: Record "Reversal Entry";
    begin
        // Setup: Create and Post General Journal Line for G/L Account.
        CreateGeneralJournalLine(GenJournalLine, Amount);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        FindGLEntry(GLEntry, GenJournalLine."Document No.", GenJournalLine."Account No.");

        // Exercise: Reverse G/L Entry Transactions.
        ReversalEntry.SetHideDialog(true);
        ReversalEntry.ReverseTransaction(GLEntry."Transaction No.");
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), Amount);
    end;

    local procedure CalculateAccountBalance(GLAccountNo: Code[20]): Decimal
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.CalcSums(Amount);
        exit(GLEntry.Amount);
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure FindGLEntry(var GLEntry: Record "G/L Entry"; DocumentNo: Code[20]; AccountNo: Code[20])
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", AccountNo);
        GLEntry.FindLast();
    end;

    local procedure VerifyBalanceAndDebitAmount(GenJournalLine: Record "Gen. Journal Line")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GLEntry: Record "G/L Entry";
    begin
        GeneralLedgerSetup.Get();
        FindGLEntry(GLEntry, GenJournalLine."Document No.", GenJournalLine."Account No.");
        Assert.AreNearlyEqual(
          -GenJournalLine."Amount (LCY)", GLEntry."Debit Amount", GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(AmountError, GLEntry.FieldCaption("Debit Amount"), -GenJournalLine."Amount (LCY)",
            GLEntry.TableCaption(), GLEntry.FieldCaption("Entry No."), GLEntry."Entry No."));
        Assert.AreEqual(0, CalculateAccountBalance(GenJournalLine."Account No."), EqualAmountError);
    end;

    local procedure VerifyBalanceAndCreditAmount(GenJournalLine: Record "Gen. Journal Line")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GLEntry: Record "G/L Entry";
    begin
        GeneralLedgerSetup.Get();
        FindGLEntry(GLEntry, GenJournalLine."Document No.", GenJournalLine."Account No.");
        Assert.AreNearlyEqual(
          GenJournalLine."Amount (LCY)", GLEntry."Credit Amount", GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(AmountError, GLEntry.FieldCaption("Credit Amount"), GenJournalLine."Amount (LCY)",
            GLEntry.TableCaption(), GLEntry.FieldCaption("Entry No."), GLEntry."Entry No."));
        Assert.AreEqual(0, CalculateAccountBalance(GenJournalLine."Account No."), EqualAmountError);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        // Handler for confirmation messages, always send positive reply.
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Message Handler.
    end;
}

