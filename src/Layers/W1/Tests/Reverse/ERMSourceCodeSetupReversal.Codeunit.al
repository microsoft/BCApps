codeunit 134143 "ERM Source Code Setup Reversal"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Reverse] [G/L Register] [Source Code]
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SourceCodeReversal()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GLRegister: Record "G/L Register";
        ReversalEntry: Record "Reversal Entry";
        SourceCodeSetup: Record "Source Code Setup";
        SourceCode: Record "Source Code";
        OldSourceCode: Code[10];
    begin
        // Create and post General Journal Line using Random Values and Reversal of General Ledger Entries to test Source Code.

        // Setup: Modify Source Code Setup.
        LibraryERM.CreateSourceCode(SourceCode);
        OldSourceCode := ModifySourceCodeSetup(SourceCodeSetup, SourceCode.Code);

        // Create and Post General Journal Line using Random Values.
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        CreateGenJournalLine(
          GenJournalLine, GenJournalBatch, LibraryERM.CreateGLAccountNo(), LibraryRandom.RandDec(5, 2));
        CreateGenJournalLine(
          GenJournalLine, GenJournalBatch, LibraryERM.CreateGLAccountNo(), -LibraryRandom.RandDec(5, 2));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Exercise: Reversal of General Ledger Entries.
        GLRegister.FindLast();
        ReversalEntry.SetHideDialog(true);
        ReversalEntry.ReverseRegister(GLRegister."No.");

        // Verify: Verify GL Register Source Code.
        VerifySourceCode(SourceCodeSetup.Reversal);

        // Tear Down: Roll back the Previous Source Code Setup.
        ModifySourceCodeSetup(SourceCodeSetup, OldSourceCode);
        DeleteSourceCode(SourceCode.Code);
    end;

    local procedure CreateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; AccountNo: Code[20]; Amount: Decimal)
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account", AccountNo, Amount);
    end;

    local procedure DeleteSourceCode(SourceCodeNo: Code[10])
    var
        SourceCode: Record "Source Code";
    begin
        SourceCode.SetFilter(Code, SourceCodeNo);
        SourceCode.FindFirst();
        SourceCode.Delete(true);
    end;

    local procedure ModifySourceCodeSetup(var SourceCodeSetup: Record "Source Code Setup"; SourceCode: Code[10]) OldSourceCode: Code[10]
    begin
        SourceCodeSetup.Get();
        OldSourceCode := SourceCodeSetup.Reversal;
        SourceCodeSetup.Validate(Reversal, SourceCode);
        SourceCodeSetup.Modify(true);
    end;

    local procedure VerifySourceCode(Reversal: Code[10])
    var
        GLRegister: Record "G/L Register";
        Assert: Codeunit Assert;
    begin
        // Verify Source Code from Source Code Setup and GL Register must be Same.
        GLRegister.FindLast();
        Assert.AreEqual(Reversal, GLRegister."Source Code", 'Source Code Must be equal');
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

