codeunit 144067 "UT COD Source Code"
{
    // 1. Purpose of the test is to verify error OnRun trigger of Codeunit 11 - Gen. Jnl.-Check Line.
    // 
    // Covers Test Cases for WI - 345027.
    // ---------------------------------------------------
    // Test Function Name                    TFS ID
    // ---------------------------------------------------
    // OnRunGenJnlCheckLineError             151201,151202

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryUTUtility: Codeunit "Library UT Utility";

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnRunGenJnlCheckLineError()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Purpose of the test is to verify error OnRun trigger of Codeunit 11 - Gen. Jnl.-Check Line.

        // Setup.
        CreateGeneralJournalLine(GenJournalLine);

        // Exercise.
        asserterror CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Check Line", GenJournalLine);

        // Verify: Verify actual error Source Code must have a value in Gen. Journal Line: Journal Template Name=, Journal Batch Name=, Line No.=0. It cannot be zero or empty.
        Assert.ExpectedErrorCode('TestField');

        // BUG 394832: Source code is checked during posting
        Assert.ExpectedError('Source Code must have a value');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnRunGenJnlBatchCheckLineError()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO 394832] It is not possible to post general journal line with the blank "Source Code" through the codeunit 13 "Gen. Jnl.-Post Batch"

        CreateGeneralJournalLine(GenJournalLine);
        asserterror CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Post Batch", GenJournalLine);
        Assert.ExpectedErrorCode('TestField');
        Assert.ExpectedError('Source Code must have a value');
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalLine."Journal Template Name" := GenJournalBatch."Journal Template Name";
        GenJournalLine."Journal Batch Name" := GenJournalBatch.Name;
        GenJournalLine."Posting Date" := WorkDate();
        GenJournalLine."Account No." := LibraryUTUtility.GetNewCode();
        GenJournalLine.Insert();
    end;
}

