// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.Foundation.Reporting.FileNaming;

using Microsoft.EServices.EDocument;
using System.Threading;

codeunit 149548 "Filename Proof Log Mgt."
{
    Access = Internal;

    // Buffers proof lines in memory and writes them to Filename Proof Log only on Flush, so logging
    // adds no write transaction while a report runs.
    // SingleInstance keeps the buffer across the codeunits that log.

    SingleInstance = true;

    var
        TempFilenameProofLog: Record "Filename Proof Log" temporary;
        RunId: Integer;
        NextTempEntryNo: Integer;
        ProofTok: Label 'PROOF', Locked = true;
        ChunkLbl: Label '%1 (cont. %2)', Comment = '%1 item name, %2 continuation number', Locked = true;

    // A value longer than the field continues on further lines.
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

    procedure Flush() Written: Integer
    begin
        Written := WriteBuffered();
        if Written > 0 then begin
            TempFilenameProofLog.DeleteAll();
            NextTempEntryNo := 0;
        end;
    end;

    // Leaves the buffer intact, for callers inside a transaction: the written rows can be rolled
    // back, the temporary buffer is not, so it stays available to write from again.
    procedure WriteBuffered() Written: Integer
    var
        FilenameProofLog: Record "Filename Proof Log";
    begin
        if not TempFilenameProofLog.FindSet() then
            exit(0);

        repeat
            // Init() leaves the primary key alone; Clear resets it so AutoIncrement numbers the row.
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

    // In a job queue session nothing calls Flush; this event comes after the render, just before
    // Base Application inserts the Report Inbox row. The buffer is kept: if the entry fails, the
    // rows written here are rolled back with it.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Queue Start Report", 'OnRunReportOnBeforeReportInboxInsert', '', false, false)]
    local procedure FlushAfterScheduledRun(ReportInbox: Record "Report Inbox"; var JobQueueEntry: Record "Job Queue Entry"; var IsHandled: Boolean)
    begin
        WriteBuffered();
    end;

    procedure StartNewRun()
    begin
        Flush();
        RunId := NextRunIdSafe();
    end;

    local procedure NextRunIdSafe(): Integer
    var
        FilenameProofLog: Record "Filename Proof Log";
    begin
        exit(FilenameProofLog.NextRunId());
    end;
}
