// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 50198 "Filename Proof Log Mgt."
{
    Access = Internal;

    // Writes the proofs' lines to Filename Proof Log, grouped by run. A proof starts a run, logs what
    // it found and flushes; Filename Proof Gate then reads that run's verdicts back.
    //
    // Lines are buffered in memory and written only on Flush, because a proof logs while a report is
    // running, and a write transaction opened then makes Base Application's own Report.RunModal call
    // fail. SingleInstance keeps the buffer for the whole session, across the codeunits that log.

    SingleInstance = true;

    var
        TempFilenameProofLog: Record "Filename Proof Log" temporary;
        RunId: Integer;
        NextTempEntryNo: Integer;
        ProofTok: Label 'PROOF', Locked = true;
        ChunkLbl: Label '%1 (cont. %2)', Comment = '%1 item name, %2 continuation number', Locked = true;

    /// <summary>
    /// Buffers one line under the current run. Values longer than the field continue on further
    /// buffered lines.
    /// </summary>
    /// <param name="ItemName">What is being reported.</param>
    /// <param name="ItemValue">The observed value.</param>
    procedure LogProofLine(ItemName: Text; ItemValue: Text)
    var
        Remaining: Text;
        ChunkNo: Integer;
    begin
        if RunId = 0 then
            RunId := NextRunIdSafe();

        Remaining := ItemValue;
        ChunkNo := 0;

        repeat
            NextTempEntryNo += 1;

            TempFilenameProofLog.Init();
            TempFilenameProofLog."Entry No." := NextTempEntryNo;
            TempFilenameProofLog."Run ID" := RunId;
            TempFilenameProofLog."Logged At" := CurrentDateTime();
            TempFilenameProofLog."Event Name" := ProofTok;

            if ChunkNo = 0 then
                TempFilenameProofLog.Item := CopyStr(ItemName, 1, MaxStrLen(TempFilenameProofLog.Item))
            else
                TempFilenameProofLog.Item := CopyStr(StrSubstNo(ChunkLbl, ItemName, ChunkNo), 1, MaxStrLen(TempFilenameProofLog.Item));

            TempFilenameProofLog.Value := CopyStr(Remaining, 1, MaxStrLen(TempFilenameProofLog.Value));
            TempFilenameProofLog.Insert();

            if StrLen(Remaining) > MaxStrLen(TempFilenameProofLog.Value) then
                Remaining := CopyStr(Remaining, MaxStrLen(TempFilenameProofLog.Value) + 1)
            else
                Remaining := '';

            ChunkNo += 1;
        until Remaining = '';
    end;

    /// <summary>
    /// Copies the buffered lines into the log table, then clears the buffer.
    /// </summary>
    /// <returns>How many lines were written.</returns>
    procedure Flush() Written: Integer
    begin
        // The buffer is cleared only where the write is safely committed. See WriteBuffered.
        Written := WriteBuffered();
        if Written > 0 then begin
            TempFilenameProofLog.DeleteAll();
            NextTempEntryNo := 0;
        end;
    end;

    /// <summary>
    /// Copies the buffered lines into the log table and leaves the buffer alone.
    ///
    /// This is what the in-transaction callers use. A temporary record lives in memory and is not
    /// rolled back, while the rows written here are - so clearing the buffer in the same call would
    /// mean that a failure later in the transaction takes the log rows with it and leaves nothing to
    /// write them from again.
    /// </summary>
    /// <returns>How many lines were written.</returns>
    procedure WriteBuffered() Written: Integer
    var
        FilenameProofLog: Record "Filename Proof Log";
    begin
        if not TempFilenameProofLog.FindSet() then
            exit(0);

        repeat
            // Init() leaves primary key fields alone, so Entry No. would survive from the previous
            // iteration and collide. Clear resets it to 0, which lets AutoIncrement number the row.
            Clear(FilenameProofLog);
            FilenameProofLog.Init();
            FilenameProofLog."Entry No." := 0;
            FilenameProofLog."Run ID" := TempFilenameProofLog."Run ID";
            FilenameProofLog."Logged At" := TempFilenameProofLog."Logged At";
            FilenameProofLog."Event Name" := TempFilenameProofLog."Event Name";
            FilenameProofLog."Report ID" := TempFilenameProofLog."Report ID";
            FilenameProofLog.Item := TempFilenameProofLog.Item;
            FilenameProofLog.Value := TempFilenameProofLog.Value;
            FilenameProofLog.Insert(true);
            Written += 1;
        until TempFilenameProofLog.Next() = 0;
    end;

    /// <summary>
    /// Writes the buffer as soon as a scheduled run reaches the point where Base Application is
    /// itself about to write, which is the only write-safe moment in a job queue session.
    /// </summary>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Queue Start Report", 'OnRunReportOnBeforeReportInboxInsert', '', false, false)]
    local procedure FlushAfterScheduledRun(ReportInbox: Record "Report Inbox"; var JobQueueEntry: Record "Job Queue Entry"; var IsHandled: Boolean)
    begin
        // A job queue entry that errors rolls its whole run back by design, so the buffer is left
        // intact here for the next writer.
        WriteBuffered();
    end;

    /// <summary>
    /// Starts a new run number, so the next proof's lines are separable in the log.
    /// </summary>
    procedure StartNewRun()
    begin
        Flush();
        RunId := NextRunIdSafe();
    end;

    local procedure NextRunIdSafe(): Integer
    var
        FilenameProofLog: Record "Filename Proof Log";
    begin
        // Reading is safe during a report run; only writing is not.
        exit(FilenameProofLog.NextRunId());
    end;
}
