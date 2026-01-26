codeunit 144114 "UT Fiscal Year"
{
    // 1. Purpose of the test is to validate on run code of Codeunit ID 366 Exchange Acc. G/L Journal Line without currency.
    // 2. Purpose of the test is to validate on run code of Codeunit ID 366 Exchange Acc. G/L Journal Line with currency.
    // 
    // Covers Test Cases for WI - 347527.
    // ------------------------------------------------------------
    // Test Function Name                                    TFS ID
    // ------------------------------------------------------------
    // OnRunExchangeAccGLJournalLineWithoutCurrency
    // OnRunExchangeAccGLJournalLineWithCurrency

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryRandom: Codeunit "Library - Random";

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnRunExchangeAccGLJournalLineWithoutCurrency()
    begin
        // Purpose of the test is to validate on run code of Codeunit ID 366 Exchange Acc. G/L Journal Line without currency.
        OnRunExchangeAccGLJournalLine('');  // Using blank for currency.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnRunExchangeAccGLJournalLineWithCurrency()
    begin
        // Purpose of the test is to validate on run code of Codeunit ID 366 Exchange Acc. G/L Journal Line with currency.
        OnRunExchangeAccGLJournalLine(LibraryUTUtility.GetNewCode10());
    end;

    local procedure OnRunExchangeAccGLJournalLine(CurrencyCode: Code[10])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Purpose of the test is to validate on run code of Codeunit ID 366 Exchange Acc. G/L Journal Line with currency.

        // Setup.
        CreateGenJournalLine(GenJournalLine, CurrencyCode);

        // Exercise.
        CODEUNIT.Run(CODEUNIT::"Exchange Acc. G/L Journal Line", GenJournalLine);

        // Verfiy.
        GenJournalLine.SetRange("Document No.", GenJournalLine."Document No.");
        GenJournalLine.FindFirst();
        GenJournalLine.TestField("Source Currency Amount", 0);  // Amount is 0 since field is uneditable.
    end;

    local procedure CreateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; CurrencyCode: Code[10])
    begin
        GenJournalLine."Account Type" := GenJournalLine."Account Type"::Customer;
        GenJournalLine."Account No." := LibraryUTUtility.GetNewCode();
        GenJournalLine."Document No." := LibraryUTUtility.GetNewCode();
        GenJournalLine.Amount := LibraryRandom.RandDec(100, 2);
        GenJournalLine."Currency Code" := CurrencyCode;
        GenJournalLine.Insert();
    end;
}

