// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

codeunit 134085 "Concurrent Seq. No. Runner"
{
    TableNo = "Concurrent Seq. Test Buffer";

    trigger OnRun()
    var
        ConcurrentSeqTestBuffer: Record "Concurrent Seq. Test Buffer";
        GLRegister: Record "G/L Register";
        AllocationIndex: Integer;
        TimeoutAt: DateTime;
    begin
        Rec.Ready := true;
        Rec.Modify();
        Commit();

        ConcurrentSeqTestBuffer.SetRange("Run ID", Rec."Run ID");
        ConcurrentSeqTestBuffer.SetRange("Allocation Index", 0);
        ConcurrentSeqTestBuffer.SetRange(Ready, true);
        TimeoutAt := CurrentDateTime() + 30000;
        while (ConcurrentSeqTestBuffer.Count() < 2) and (CurrentDateTime() < TimeoutAt) do
            Sleep(100);
        if ConcurrentSeqTestBuffer.Count() < 2 then
            Error('The concurrent sequence allocation barrier timed out.');

        for AllocationIndex := 1 to Rec.GetNoOfAllocationsPerSession() do begin
            ConcurrentSeqTestBuffer.Init();
            ConcurrentSeqTestBuffer."Run ID" := Rec."Run ID";
            ConcurrentSeqTestBuffer."Session No." := Rec."Session No.";
            ConcurrentSeqTestBuffer."Allocation Index" := AllocationIndex;
            ConcurrentSeqTestBuffer."Entry No." := GLRegister.GetNextRegisterNo(false);
            ConcurrentSeqTestBuffer.Insert();
            Commit();
        end;
    end;
}