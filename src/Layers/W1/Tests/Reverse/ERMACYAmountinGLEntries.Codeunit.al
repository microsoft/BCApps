codeunit 134144 "ERM ACY Amount in GL Entries"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Reverse] [FCY]
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ReverseEntriesWithFCYAmount()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GLRegister: Record "G/L Register";
        ReversalEntry: Record "Reversal Entry";
        Assert: Codeunit Assert;
        Amount: Decimal;
    begin
        // Create and post General Journal Line using Random Values and Reversal of General Ledger Entries to test FCY Amount.

        // Setup: Create General Journal Line.
        LibraryERM.SelectLastGenJnBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        CreateGenJournalLine(
          GenJournalLine, GenJournalBatch, LibraryERM.CreateGLAccountNo(), LibraryRandom.RandInt(5), CreateCurrency());
        CreateGenJournalLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Account No.", GenJournalLine.Amount, GenJournalLine."Currency Code");
        Amount := GenJournalLine.Amount * 2; // For both lines using the same Amount, So multiply by 2.
        CreateGenJournalLine(
          GenJournalLine, GenJournalBatch, LibraryERM.CreateGLAccountNo(), -Amount, GenJournalLine."Currency Code");
        Amount := FindBalanceAmount(GenJournalLine."Currency Code");

        // Create new line for Rounding in General Journal Line and Post General Journal Line.
        CODEUNIT.Run(CODEUNIT::"Adjust Gen. Journal Balance", GenJournalLine);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Exercise: Reverse GL Register for General Journal Line.
        GLRegister.FindLast();
        ReversalEntry.SetHideDialog(true);
        ReversalEntry.ReverseRegister(GLRegister."No.");

        // Verify: Verify GLAccount Balance must me same after Reversal.
        Assert.AreEqual(Amount, FindBalanceAmount(GenJournalLine."Currency Code"), 'GLAccount Balance Must be Equal');
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        Currency.Validate("Conv. LCY Rndg. Debit Acc.", LibraryERM.CreateGLAccountNo());
        Currency.Validate("Conv. LCY Rndg. Credit Acc.", Currency."Conv. LCY Rndg. Debit Acc.");
        Currency.Modify(true);
        UpdateExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; AccountNo: Code[20]; Amount: Decimal; CurrencyCode: Code[10])
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account", AccountNo, Amount);
        GenJournalLine.Validate("Bal. Account No.", '');
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Modify(true);
    end;

    local procedure UpdateExchangeRate(CurrencyCode: Code[10])
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        // Relational Exch. Rate Amount and Relational Adjmt Exch Rate Amount always one third of Exchange Rate Amount.
        LibraryERM.CreateRandomExchangeRate(CurrencyCode);
        CurrencyExchangeRate.SetRange("Currency Code", CurrencyCode);
        CurrencyExchangeRate.FindFirst();
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", CurrencyExchangeRate."Exchange Rate Amount" / 3);
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", CurrencyExchangeRate."Relational Exch. Rate Amount");
        CurrencyExchangeRate.Modify(true);
    end;

    local procedure FindBalanceAmount(CurrencyCode: Code[10]): Decimal
    var
        Currency: Record Currency;
        GLAccount: Record "G/L Account";
    begin
        Currency.Get(CurrencyCode);
        GLAccount.Get(Currency."Conv. LCY Rndg. Debit Acc.");
        GLAccount.CalcFields(Balance);
        exit(GLAccount.Balance);
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

