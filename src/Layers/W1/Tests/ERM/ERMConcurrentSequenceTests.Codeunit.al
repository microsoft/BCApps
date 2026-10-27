// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Test;

codeunit 134291 "ERM Concurrent Sequence Tests"
{
    Subtype = Test;
    TestType = UnitTest;
    RequiredTestIsolation = Disabled;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    [Scope('OnPrem')]
    procedure GLRegisterGetNextEntryNoIsUniqueAndGapFreeAcrossSessions()
    var
        ConcurrentSeqTestBuffer: Record "Concurrent Seq. Test Buffer";
        RunId: Guid;
        FirstSessionId: Integer;
        SecondSessionId: Integer;
        PreviousEntryNo: Integer;
        ExpectedResultCount: Integer;
        TimeoutAt: DateTime;
    begin
        // [FEATURE] [G/L Register] [Sequence] [Concurrent Posting]
        // [SCENARIO] Overlapping G/L Register entry number allocations from separate sessions are unique and gap-free.

        // [GIVEN] Two background sessions waiting at the same allocation barrier
        RunId := CreateGuid();
        CreateConcurrentSequenceSession(ConcurrentSeqTestBuffer, RunId, 1);
        CreateConcurrentSequenceSession(ConcurrentSeqTestBuffer, RunId, 2);
        Commit();

        ConcurrentSeqTestBuffer.Get(RunId, 1, 0);
        Assert.IsTrue(
            StartSession(FirstSessionId, Codeunit::"Concurrent Seq. No. Runner", CompanyName(), ConcurrentSeqTestBuffer),
            'The first concurrent sequence allocation session could not be started');
        ConcurrentSeqTestBuffer.Get(RunId, 2, 0);
        Assert.IsTrue(
            StartSession(SecondSessionId, Codeunit::"Concurrent Seq. No. Runner", CompanyName(), ConcurrentSeqTestBuffer),
            'The second concurrent sequence allocation session could not be started');

        // [WHEN] Both sessions allocate G/L Register numbers concurrently
        TimeoutAt := CurrentDateTime() + 30000;
        while (IsSessionActive(FirstSessionId) or IsSessionActive(SecondSessionId)) and (CurrentDateTime() < TimeoutAt) do
            Sleep(100);
        Assert.IsFalse(IsSessionActive(FirstSessionId), 'The first concurrent sequence allocation session timed out');
        Assert.IsFalse(IsSessionActive(SecondSessionId), 'The second concurrent sequence allocation session timed out');

        // [THEN] All allocated numbers are present, unique, and gap-free
        ExpectedResultCount := 2 * ConcurrentSeqTestBuffer.GetNoOfAllocationsPerSession();
        ConcurrentSeqTestBuffer.SetRange("Run ID", RunId);
        ConcurrentSeqTestBuffer.SetFilter("Allocation Index", '>0');
        Assert.AreEqual(ExpectedResultCount, ConcurrentSeqTestBuffer.Count(), 'Both sessions must persist every allocated G/L Register number');
        ConcurrentSeqTestBuffer.SetCurrentKey("Run ID", "Entry No.");
        ConcurrentSeqTestBuffer.FindSet();
        PreviousEntryNo := ConcurrentSeqTestBuffer."Entry No.";
        while ConcurrentSeqTestBuffer.Next() <> 0 do begin
            Assert.AreEqual(PreviousEntryNo + 1, ConcurrentSeqTestBuffer."Entry No.", 'Concurrent G/L Register numbers must be unique and gap-free');
            PreviousEntryNo := ConcurrentSeqTestBuffer."Entry No.";
        end;

        ConcurrentSeqTestBuffer.SetRange("Allocation Index");
        ConcurrentSeqTestBuffer.DeleteAll();
        Commit();
    end;

    local procedure CreateConcurrentSequenceSession(var ConcurrentSeqTestBuffer: Record "Concurrent Seq. Test Buffer"; RunId: Guid; SessionNo: Integer)
    begin
        ConcurrentSeqTestBuffer.Init();
        ConcurrentSeqTestBuffer."Run ID" := RunId;
        ConcurrentSeqTestBuffer."Session No." := SessionNo;
        ConcurrentSeqTestBuffer."Allocation Index" := 0;
        ConcurrentSeqTestBuffer.Insert();
    end;
}
