// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

using System.PerformanceProfile;

/// <summary>
/// Background task that advances the state machine for a single Performance Analysis
/// based on the live state of its associated Performance Profile Scheduler. Scheduled
/// via TaskScheduler when an analysis is created; re-schedules itself if the capture
/// hasn't completed yet. Acts as the "job queue" for the Performance Center.
/// </summary>
codeunit 8422 "Perf. Analysis Tick Task"
{
    Access = Internal;
    TableNo = "Performance Analysis";
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "Performance Analysis" = RIM,
                  tabledata "Performance Profile Scheduler" = R;

    trigger OnRun()
    var
        Monitor: Codeunit "Perf. Analysis Monitor";
    begin
        Monitor.Tick(Rec);
        RescheduleIfStillLive(Rec);
    end;

    /// <summary>
    /// Schedules the first tick for an analysis. The first run is queued at the
    /// scheduler's ending time so that the monitor transitions the analysis to
    /// CaptureEnded as soon as the profiler schedule's window closes.
    /// </summary>
    internal procedure ScheduleFirstTick(var Analysis: Record "Performance Analysis"; var Scheduler: Record "Performance Profile Scheduler")
    var
        NotBefore: DateTime;
    begin
        NotBefore := Scheduler."Ending Date-Time";
        if NotBefore = 0DT then
            NotBefore := CurrentDateTime() + TickIntervalMs();
        // Give the platform a small buffer past the scheduler's ending time so the
        // scheduler has actually gone inactive when the monitor ticks.
        NotBefore += PostEndBufferMs();
        ScheduleAt(Analysis, NotBefore);
    end;

    local procedure RescheduleIfStillLive(var Analysis: Record "Performance Analysis")
    begin
        // Re-queue another tick while the analysis is still in a live, schedule-driven state.
        // Concluded/Failed/Cancelled/CaptureEnded terminal-for-us states are not re-queued;
        // CaptureEnded waits for the user (or an auto-advance) to run AI.
        if not (Analysis."State" in [Analysis."State"::Scheduled, Analysis."State"::Capturing]) then
            exit;
        ScheduleAt(Analysis, CurrentDateTime() + TickIntervalMs());
    end;

    local procedure ScheduleAt(var Analysis: Record "Performance Analysis"; NotBefore: DateTime)
    begin
        if not TaskScheduler.CanCreateTask() then
            exit;
        TaskScheduler.CreateTask(Codeunit::"Perf. Analysis Tick Task", 0, true, CompanyName(), NotBefore, Analysis.RecordId());
    end;

    local procedure TickIntervalMs(): Integer
    begin
        exit(60 * 1000); // 1 minute
    end;

    local procedure PostEndBufferMs(): Integer
    begin
        exit(30 * 1000); // 30 seconds
    end;
}
