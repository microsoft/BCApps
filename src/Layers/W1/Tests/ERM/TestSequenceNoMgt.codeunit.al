codeunit 134899 "Test Sequence No. Mgt."
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    var
        Assert: Codeunit "Assert";

    [Test]
    procedure VerifyInitSequence()
    var
        GLEntry: Record "G/L Entry";
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
        SequenceName: Text;
        NextNo: Integer;
        CurrentNo: Integer;
    begin
        // First time we use GetNextSequenceNo the sequence should be created automatically
        SequenceName := SequenceNoMgt.GetTableSequenceName(Database::"G/L Entry");
        if NumberSequence.Exists(SequenceName) then
            NumberSequence.Delete(SequenceName);
        if GLEntry.FindLast() then;
        CurrentNo := SequenceNoMgt.GetCurrentSeqNo(Database::"G/L Entry");
        NextNo := SequenceNoMgt.GetNextSeqNo(Database::"G/L Entry");
        Assert.IsTrue(NumberSequence.Exists(SequenceName), 'Sequence not created');
        Assert.AreEqual(GLEntry."Entry No.", CurrentNo, 'Wrong current number generated');
        Assert.AreEqual(GLEntry."Entry No." + 1, NextNo, 'Wrong next number generated');
        Assert.AreEqual('', GetLastErrorText(), 'Error not cleared after TryFunction');
    end;

    [Test]
    procedure VerifyRebase()
    var
        InteractionLogEntry: Record "Interaction Log Entry";
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
        NextNo: Integer;
        LastNo: Integer;
    begin
        // For resiliency, some tables will have a special InsertRec function that handles out-of-sync sequences
        if InteractionLogEntry.FindLast() then;
        LastNo := InteractionLogEntry."Entry No.";
        NextNo := SequenceNoMgt.GetNextSeqNo(Database::"Interaction Log Entry");
        Assert.IsTrue(NumberSequence.Exists(SequenceNoMgt.GetTableSequenceName(Database::"Interaction Log Entry")), 'Sequence not created');
        InteractionLogEntry."Entry No." := NextNo;
        InteractionLogEntry.Insert();
        InteractionLogEntry."Entry No." += 1;
        InteractionLogEntry.Insert(); // now the sequence is out of sync
        LastNo := InteractionLogEntry."Entry No.";
        InteractionLogEntry.InsertRecord(); // should trigger rebase and renewed Entry No.
        Assert.IsTrue(InteractionLogEntry."Entry No." > LastNo, 'Wrong number generated');
    end;

    [Test]
    procedure VerifyRanges()
    var
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
        ExpectedNo: Integer;
        FirstNo: Integer;
        EntryNo: Integer;
        ManualEntryNo1: Integer;
        ManualEntryNo2: Integer;
        i: Integer;
    begin
        Clear(SequenceNoMgt);
        SequenceNoMgt.ClearState();
        SequenceNoMgt.ValidateSeqNo(32); // Item Ledger Entry

        // Sunshine scenaro - allocate 100 entry nos.
        ExpectedNo := SequenceNoMgt.GetCurrentSeqNo(32) + 1; // Item Ledger Entry
        SequenceNoMgt.AllocateSeqNoBuffer(32, 100);
        FirstNo := SequenceNoMgt.GetNextSeqNo(32);
        Assert.AreEqual(ExpectedNo, FirstNo, 'Unexpected first entry no.');

        ExpectedNo := FirstNo + 1;
        EntryNo := SequenceNoMgt.GetNextSeqNo(32);
        Assert.AreEqual(ExpectedNo, EntryNo, 'Unexpected next entry no. from buffer');

        ExpectedNo := FirstNo + 100;
        ManualEntryNo1 := NumberSequence.Next(SequenceNoMgt.GetTableSequenceName(32));
        Assert.AreEqual(ExpectedNo, ManualEntryNo1, 'Unexpected next entry no.');

        SequenceNoMgt.AllocateSeqNoBuffer(32, 100); // will update the list

        ExpectedNo := FirstNo + 2;
        EntryNo := SequenceNoMgt.GetNextSeqNo(32);
        Assert.AreEqual(ExpectedNo, EntryNo, 'Unexpected next entry no. from buffer 2');

        ExpectedNo += 99;
        ManualEntryNo2 := NumberSequence.Next(SequenceNoMgt.GetTableSequenceName(32));
        Assert.AreEqual(ExpectedNo, ManualEntryNo2, 'Unexpected next entry no. 2');

        for i := 1 to 200 do begin
            EntryNo := SequenceNoMgt.GetNextSeqNo(32);
            Assert.AreNotEqual(ManualEntryNo1, EntryNo, 'We got an already used entry no. 1');
            Assert.AreNotEqual(ManualEntryNo2, EntryNo, 'We got an already used entry no. 2');
        end;
    end;

    [Test]
    procedure VerifySequenceName()
    var
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
        SeqNameLbl: Label 'TableSeq%1', Comment = '%1 - Table No.', Locked = true;
        PreviewSeqNameLbl: Label 'PreviewTableSeq%1', Comment = '%1 - Table No.', Locked = true;
    begin
        // We distinguish between posting and preview, and for preview; whether it is previewable, which e.g. Warehouse entry is and G/L Entry is not.
        // Regular sequence name:
        Assert.AreEqual(StrSubstNo(SeqNameLbl, Database::"Warehouse Entry"), SequenceNoMgt.GetTableSequenceName(false, Database::"Warehouse Entry"), 'wrong sequence name for Warehouse Entry');
        // Preview name:
        Assert.AreEqual(StrSubstNo(PreviewSeqNameLbl, Database::"Warehouse Entry"), SequenceNoMgt.GetTableSequenceName(true, Database::"Warehouse Entry"), 'wrong sequence name for preview for Warehouse Entry');
        // Regular sequence name for G/L Entry:
        Assert.AreEqual(StrSubstNo(SeqNameLbl, Database::"G/L Entry"), SequenceNoMgt.GetTableSequenceName(false, Database::"G/L Entry"), 'wrong sequence name for G/L Entry');
        // There is no preview name for G/L Entry (which does not support preview), so it should just return the normal name
        Assert.AreEqual(StrSubstNo(SeqNameLbl, Database::"G/L Entry"), SequenceNoMgt.GetTableSequenceName(true, Database::"G/L Entry"), 'wrong sequence name for preview for G/L Entry');
    end;

    [Test]
    [HandlerFunctions('ErrorMassagesHandler')]
    procedure VerifyPreviewSequenceName()
    begin
        PreviewPosting();
    end;

    local procedure PreviewPosting()
    var
        JobQueueEntry: Record "Job Queue Entry";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        NoSequencePreviewTest: Codeunit "No Sequence Preview Test";
    begin
        BindSubscription(NoSequencePreviewTest);
        asserterror GenJnlPostPreview.Preview(NoSequencePreviewTest, JobQueueEntry);
        UnBindSubscription(NoSequencePreviewTest);
    end;

    [PageHandler]
    procedure ErrorMassagesHandler(var ErrorMessages: TestPage "Error Messages")
    begin
        ErrorMessages.OK().Invoke();
    end;

}