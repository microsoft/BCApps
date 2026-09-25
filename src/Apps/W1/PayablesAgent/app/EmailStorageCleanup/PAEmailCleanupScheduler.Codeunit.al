// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using System.Threading;

/// <summary>
/// Lifecycle of the background Email Inbox duplicate cleanup Job Queue Entry.
/// </summary>
codeunit 3324 "PA Email Cleanup Scheduler"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "Job Queue Entry" = rimd;

    var
        JobDescriptionTxt: Label 'Payables Agent - Email Inbox duplicate cleanup';
        CategoryCodeTok: Label 'PAEMAILCLN', Locked = true, Comment = 'Max length 10.';
        NotScheduledTxt: Label 'Not scheduled';
        RunningTxt: Label 'Running now';
        ScheduledForTxt: Label 'Scheduled for %1', Comment = '%1 = date and time the cleanup starts';
        OnHoldTxt: Label 'On hold';
        FinishedTxt: Label 'Finished - see the Job Queue Log for the result';
        FailedTxt: Label 'Failed: %1', Comment = '%1 = the job queue error message';
        AlreadyRunningErr: Label 'The background cleanup is already running. Wait for it to finish before scheduling another run.';

    /// <summary>
    /// Schedules a single background cleanup run at the requested start time (or now, if that time is blank or in the past)
    /// </summary>
    procedure Activate(RequestedStartDateTime: DateTime)
    var
        Setup: Record "PA Email Cleanup Setup";
        JobQueueEntry: Record "Job Queue Entry";
        StartDateTime: DateTime;
    begin
        if IsRunning() then
            Error(AlreadyRunningErr);

        // Remove any previously scheduled entry, only one scheduled at a time.
        CancelCleanupJob();

        StartDateTime := RequestedStartDateTime;
        if (StartDateTime = 0DT) or (StartDateTime < CurrentDateTime()) then
            StartDateTime := CurrentDateTime();

        PrepareCleanupJobEntry(JobQueueEntry, StartDateTime);
        Codeunit.Run(Codeunit::"Job Queue - Enqueue", JobQueueEntry);

        Setup.GetSingleton();
        Setup."Job Queue Entry ID" := JobQueueEntry.ID;
        Setup.Modify();
    end;

    procedure CancelCleanupJob()
    var
        Setup: Record "PA Email Cleanup Setup";
        JobQueueEntry: Record "Job Queue Entry";
    begin
        if TryGetCleanupEntry(JobQueueEntry) then
            JobQueueEntry.Cancel();

        Setup.GetSingleton();
        Clear(Setup."Job Queue Entry ID");
        Setup.Modify();
    end;

    local procedure PrepareCleanupJobEntry(var JobQueueEntry: Record "Job Queue Entry"; StartDateTime: DateTime)
    begin
        JobQueueEntry.Init();
        Clear(JobQueueEntry.ID);
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := Codeunit::"PA Email Cleanup Runner";
        JobQueueEntry."Earliest Start Date/Time" := StartDateTime;
        JobQueueEntry."Run in User Session" := false;
        JobQueueEntry."Job Queue Category Code" := CategoryCodeTok;
        JobQueueEntry.Description := CopyStr(JobDescriptionTxt, 1, MaxStrLen(JobQueueEntry.Description));
        JobQueueEntry."Maximum No. of Attempts to Run" := 3;
        JobQueueEntry."Rerun Delay (sec.)" := 60;
        JobQueueEntry."Recurring Job" := false;
    end;

    procedure IsScheduled(): Boolean
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        if not TryGetCleanupEntry(JobQueueEntry) then
            exit(false);
        exit(JobQueueEntry.Status in [JobQueueEntry.Status::Ready, JobQueueEntry.Status::Waiting, JobQueueEntry.Status::"In Process"]);
    end;

    procedure IsRunning(): Boolean
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        if not TryGetCleanupEntry(JobQueueEntry) then
            exit(false);
        exit(JobQueueEntry.Status = JobQueueEntry.Status::"In Process");
    end;

    procedure GetLastError(): Text
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        if not TryGetCleanupEntry(JobQueueEntry) then
            exit('');
        if JobQueueEntry.Status <> JobQueueEntry.Status::Error then
            exit('');
        exit(JobQueueEntry."Error Message");
    end;

    /// <summary>
    /// The earliest start time the job queue will honour, or 0DT when nothing is scheduled.
    /// </summary>
    procedure GetScheduledAt(): DateTime
    var
        JobQueueEntry: Record "Job Queue Entry";
        NoDateTime: DateTime;
    begin
        if not TryGetCleanupEntry(JobQueueEntry) then
            exit(NoDateTime);
        exit(JobQueueEntry."Earliest Start Date/Time");
    end;

    procedure GetStatusText(): Text
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        if not TryGetCleanupEntry(JobQueueEntry) then
            exit(NotScheduledTxt);
        case JobQueueEntry.Status of
            JobQueueEntry.Status::"In Process":
                exit(RunningTxt);
            JobQueueEntry.Status::Ready, JobQueueEntry.Status::Waiting:
                exit(StrSubstNo(ScheduledForTxt, JobQueueEntry."Earliest Start Date/Time"));
            JobQueueEntry.Status::"On Hold", JobQueueEntry.Status::"On Hold with Inactivity Timeout":
                exit(OnHoldTxt);
            JobQueueEntry.Status::Error:
                exit(StrSubstNo(FailedTxt, JobQueueEntry."Error Message"));
            JobQueueEntry.Status::Finished:
                exit(FinishedTxt);
        end;

        exit(Format(JobQueueEntry.Status));
    end;

    procedure OpenJobQueueCard()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        if not TryGetCleanupEntry(JobQueueEntry) then
            exit;
        Page.Run(Page::"Job Queue Entry Card", JobQueueEntry);
    end;

    local procedure TryGetCleanupEntry(var JobQueueEntry: Record "Job Queue Entry"): Boolean
    var
        Setup: Record "PA Email Cleanup Setup";
    begin
        if not Setup.Get() then
            exit(false);
        if IsNullGuid(Setup."Job Queue Entry ID") then
            exit(false);
        exit(JobQueueEntry.Get(Setup."Job Queue Entry ID"));
    end;
}
