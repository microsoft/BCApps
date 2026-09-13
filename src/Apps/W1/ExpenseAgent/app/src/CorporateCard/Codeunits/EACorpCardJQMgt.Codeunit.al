// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using System.Threading;

/// <summary>
/// Manages Job Queue entry creation and scheduling for corporate card imports.
/// Provides helper methods to schedule provider imports with configurable frequency.
/// </summary>
codeunit 7215 "EA Corp Card JQ Mgt"
{
    Access = Internal;

    var
        CorpCardImportTxt: Label 'Corp Card import - %1', Comment = '%1 = Provider code';
        JobQueueAlreadyExistsErr: Label 'Job Queue entry for provider %1 already exists.', Comment = '%1 = Provider code';
        NoProviderErr: Label 'Provider %1 not found.', Comment = '%1 = Provider code';

    internal procedure ScheduleProviderImport(ProviderCode: Code[20]; MinutesBetweenRuns: Integer; StartTime: Time; StartDate: Date): Guid
    var
        CorpCardProvider: Record "EA Corp Card Provider";
        JobQueueEntry: Record "Job Queue Entry";
        AuditSubscribers: Codeunit "EA Corp Card Audit Subscribers";
    begin
        if not CorpCardProvider.Get(ProviderCode) then
            Error(NoProviderErr, ProviderCode);

        if JobQueueEntryExists(CorpCardProvider.RecordId) then
            Error(JobQueueAlreadyExistsErr, ProviderCode);

        JobQueueEntry.Init();
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := Codeunit::"EA Corp Card JQ Runner";
        JobQueueEntry.Description := StrSubstNo(CorpCardImportTxt, ProviderCode);
        JobQueueEntry."Record ID to Process" := CorpCardProvider.RecordId;
        JobQueueEntry."Maximum No. of Attempts to Run" := 3;
        JobQueueEntry."No. of Minutes between Runs" := MinutesBetweenRuns;
        JobQueueEntry."Earliest Start Date/Time" := CreateDateTime(StartDate, StartTime);
        JobQueueEntry."Recurring Job" := (MinutesBetweenRuns > 0);
        JobQueueEntry.Status := JobQueueEntry.Status::"On Hold";
        JobQueueEntry.Insert(true);

        AuditSubscribers.LogJobQueueScheduled(ProviderCode, Format(MinutesBetweenRuns) + ' minutes');

        exit(JobQueueEntry.ID);
    end;

    internal procedure UnscheduleProviderImport(ProviderCode: Code[20])
    var
        CorpCardProvider: Record "EA Corp Card Provider";
        JobQueueEntry: Record "Job Queue Entry";
    begin
        if not CorpCardProvider.Get(ProviderCode) then
            Error(NoProviderErr, ProviderCode);

        JobQueueEntry.SetRange("Record ID to Process", CorpCardProvider.RecordId);
        JobQueueEntry.DeleteAll();
    end;

    internal procedure UpdateJobQueueFrequency(ProviderCode: Code[20]; NewMinutesBetweenRuns: Integer)
    var
        CorpCardProvider: Record "EA Corp Card Provider";
        JobQueueEntry: Record "Job Queue Entry";
    begin
        if not CorpCardProvider.Get(ProviderCode) then
            Error(NoProviderErr, ProviderCode);

        JobQueueEntry.SetRange("Record ID to Process", CorpCardProvider.RecordId);
        if JobQueueEntry.FindFirst() then begin
            JobQueueEntry."No. of Minutes between Runs" := NewMinutesBetweenRuns;
            JobQueueEntry."Recurring Job" := (NewMinutesBetweenRuns > 0);
            JobQueueEntry.Modify();
        end;
    end;

    local procedure JobQueueEntryExists(RecordId: RecordId): Boolean
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Record ID to Process", RecordId);
        exit(not JobQueueEntry.IsEmpty());
    end;
}
