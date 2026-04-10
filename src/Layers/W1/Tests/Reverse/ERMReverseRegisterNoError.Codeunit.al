codeunit 134147 "ERM Reverse Register No Error"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Reverse] [Force Doc. Balance]
    end;

    var
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        AmountError: Label 'Debit Amount must be %1 in G/L Entry. Entry No.: %2.';
        BalanceError: Label 'Balance must be 0 for G/L Account: %1.';

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ReverseAfterForceDocBalFalse()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        GLAccount: Record "G/L Account";
        ReversalEntry: Record "Reversal Entry";
        GLRegister: Record "G/L Register";
        ForceDocBalance: Boolean;
    begin
        // Check Balance and Debit Amount after posting General Journal Lines and reversing the entries.

        // Setup: Find General Journal Template and update it, Create a new GL Account. Create and Post General Journal Lines
        // after removing Balance Account No.
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        ForceDocBalance := UpdateGenJournalTemplate(GenJournalBatch."Journal Template Name", false);
        LibraryERM.CreateGLAccount(GLAccount);
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, GLAccount."No.", GenJournalLine."Document No.", LibraryRandom.RandInt(100));
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Bal. Account No.", IncStr(GenJournalLine."Document No."), -GenJournalLine.Amount);
        RemoveBalanceAccountNo(GenJournalBatch."Journal Template Name", GenJournalBatch.Name);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Exercise: Reverse posted Transaction.
        GLRegister.FindLast();
        ReversalEntry.SetHideDialog(true);
        ReversalEntry.ReverseRegister(GLRegister."No.");

        // Verify: Verify the Balance on GL Account and Debit Amount in GL Entry.
        GLAccount.CalcFields(Balance);
        Assert.AreEqual(0, GLAccount.Balance, StrSubstNo(BalanceError, GLAccount."No."));
        VerifyDebitAmountInGLEntry(GLAccount."No.", GenJournalLine.Amount);

        // Tear Down: Update the General Journal Template and Block GL Account to clean up setup steps.
        UpdateGenJournalTemplate(GenJournalBatch."Journal Template Name", ForceDocBalance);
    end;

    local procedure UpdateGenJournalTemplate(GenJournalTemplateName: Code[10]; ForceDocBalance: Boolean) OriginalForceDocBal: Boolean
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.Get(GenJournalTemplateName);
        OriginalForceDocBal := GenJournalTemplate."Force Doc. Balance";
        GenJournalTemplate.Validate("Force Doc. Balance", ForceDocBalance);
        GenJournalTemplate.Modify(true);
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; AccountNo: Code[20]; DocumentNo: Code[20]; Amount: Decimal)
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", AccountNo, Amount);
        if DocumentNo = '' then
            exit;
        GenJournalLine.Validate("Document No.", DocumentNo);
        GenJournalLine.Modify(true);
    end;

    local procedure RemoveBalanceAccountNo(JournalTemplateName: Code[10]; JournalBatchName: Code[10])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetRange("Journal Template Name", JournalTemplateName);
        GenJournalLine.SetRange("Journal Batch Name", JournalBatchName);
        GenJournalLine.ModifyAll("Bal. Account No.", '', true);
    end;

    local procedure VerifyDebitAmountInGLEntry(GLAccountNo: Code[20]; DebitAmount: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GLRegister: Record "G/L Register";
        GLEntry: Record "G/L Entry";
    begin
        GeneralLedgerSetup.Get();
        GLRegister.FindLast();
        GLEntry.SetRange("Entry No.", GLRegister."From Entry No.", GLRegister."To Entry No.");
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindFirst();
        Assert.AreNearlyEqual(
          DebitAmount, GLEntry."Debit Amount", GeneralLedgerSetup."Inv. Rounding Precision (LCY)",
          StrSubstNo(AmountError, DebitAmount, GLEntry."Entry No."));
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

