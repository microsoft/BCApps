codeunit 136401 "Create G/L Acc. Journal lines"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Create G/L Acc. Journal lines] [General Journal]
    end;

    var
        Assert: Codeunit Assert;
        UnknownError: Label 'Unexpected Error.';
        NoBatchError: Label 'Gen. Journal Batch name is blank.';
        NoTemplateError: Label 'Gen. Journal Template name is blank.';

    [Test]
    [HandlerFunctions('HandleMessage')]
    [Scope('OnPrem')]
    procedure CreateGLAccJnlLine()
    var
        GenJnlLine: Record "Gen. Journal Line";
        StandardGenJnlLine: Record "Standard General Journal Line";
        GLAcc: Code[20];
        JnlTemplate: Code[10];
        JnlBatch: Code[10];
        StandJnlCode: Code[20];
    begin
        PrepareParameter(GLAcc, JnlTemplate, JnlBatch, StandJnlCode);
        ClearGenJnlLine(GenJnlLine);
        RunCreateGLAccJnl(GenJnlLine, WorkDate(), JnlTemplate, JnlBatch, StandJnlCode, GLAcc);

        // Validate generated general journal line against standard journal line
        GenJnlLine.FindFirst();
        StandardGenJnlLine.SetRange("Standard Journal Code", StandJnlCode);
        StandardGenJnlLine.FindSet();
        repeat
            GenJnlLine.TestField("Journal Template Name", JnlTemplate);
            GenJnlLine.TestField("Journal Batch Name", JnlBatch);
            GenJnlLine.TestField("Posting Date", WorkDate());
            GenJnlLine.TestField("Document Type", GenJnlLine."Document Type"::Invoice);
            GenJnlLine.TestField("Account No.", GLAcc);
            GenJnlLine.TestField(Amount, StandardGenJnlLine.Amount);
            GenJnlLine.Next();
        until StandardGenJnlLine.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateGLAccJnlLineNoTemplate()
    var
        GenJnlLine: Record "Gen. Journal Line";
        GLAcc: Code[20];
        JnlTemplate: Code[10];
        JnlBatch: Code[10];
        StandJnlCode: Code[20];
    begin
        PrepareParameter(GLAcc, JnlTemplate, JnlBatch, StandJnlCode);
        RunBatchAndHandleError(GenJnlLine, WorkDate(), '', JnlBatch, StandJnlCode, GLAcc, NoTemplateError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateGLAccJnlLineNoBatch()
    var
        GenJnlLine: Record "Gen. Journal Line";
        GLAcc: Code[20];
        JnlTemplate: Code[10];
        JnlBatch: Code[10];
        StandJnlCode: Code[20];
    begin
        PrepareParameter(GLAcc, JnlTemplate, JnlBatch, StandJnlCode);
        RunBatchAndHandleError(GenJnlLine, WorkDate(), JnlTemplate, '', StandJnlCode, GLAcc, NoBatchError);
    end;

    local procedure ClearGenJnlLine(var GenJnlLine: Record "Gen. Journal Line")
    begin
        GenJnlLine.Init();
        GenJnlLine.DeleteAll();
        Commit();
    end;

    local procedure PrepareParameter(var GLAcc: Code[20]; var JnlTemplate: Code[10]; var JnlBatch: Code[10]; var StandJnlCode: Code[20])
    var
        StandardGenJnl: Record "Standard General Journal";
    begin
        GLAcc := FindGLAcc();
        StandardGenJnl.FindFirst();
        StandJnlCode := StandardGenJnl.Code;
        JnlTemplate := StandardGenJnl."Journal Template Name";
        JnlBatch := FindGenJnlBatch(JnlTemplate);
    end;

    local procedure RunBatchAndHandleError(var GenJnlLine: Record "Gen. Journal Line"; PostingDate: Date; JnlTemplate: Text[10]; JnlBatch: Code[10]; StandardJnlCode: Code[20]; GLAcc: Code[20]; ExpectError: Text[250])
    begin
        asserterror RunCreateGLAccJnl(GenJnlLine, PostingDate, JnlTemplate, JnlBatch, StandardJnlCode, GLAcc);
        Assert.AreEqual(ExpectError, GetLastErrorText, UnknownError);
    end;

    local procedure FindGenJnlBatch(TemplateName: Code[10]): Code[10]
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        LibraryERM: Codeunit "Library - ERM";
    begin
        LibraryERM.FindGenJournalBatch(GenJnlBatch, TemplateName);
        exit(GenJnlBatch.Name);
    end;

    local procedure FindGLAcc(): Code[20]
    var
        GLAccount: Record "G/L Account";
        LibraryERM: Codeunit "Library - ERM";
    begin
        LibraryERM.FindGLAccount(GLAccount);
        exit(GLAccount."No.");
    end;

    local procedure RunCreateGLAccJnl(var GenJnlLine: Record "Gen. Journal Line"; PostingDate: Date; JournalTemplate: Text[10]; BatchName: Code[10]; StandardTemplate: Code[20]; AccNo: Code[20])
    var
        GLAccount: Record "G/L Account";
        CreateGLAccJnlLines: Report "Create G/L Acc. Journal Lines";
    begin
        Clear(CreateGLAccJnlLines);
        GLAccount.SetRange("No.", AccNo);
        CreateGLAccJnlLines.SetTableView(GLAccount);
        // Invoice is used here since document type is not important.
        CreateGLAccJnlLines.InitializeRequest(
          GenJnlLine."Document Type"::Invoice.AsInteger(), PostingDate, JournalTemplate, BatchName, StandardTemplate);
        CreateGLAccJnlLines.UseRequestPage(false);
        CreateGLAccJnlLines.Run();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure HandleMessage(Message: Text[1024])
    begin
    end;
}

