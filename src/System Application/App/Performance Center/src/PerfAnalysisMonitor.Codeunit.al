// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

using System.PerformanceProfile;

/// <summary>
/// Drives the state machine by observing the platform Performance Profile Scheduler
/// records and the clock. Typically invoked from a job queue entry (created by the
/// installer) and from the Analysis card after the user stops the capture.
/// </summary>
codeunit 8415 "Perf. Analysis Monitor"
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "Performance Analysis" = RIM,
                  tabledata "Performance Profile Scheduler" = R;

    /// <summary>
    /// Tick the state machine for all live analyses. Safe to call from a job queue entry.
    /// </summary>
    procedure TickAll()
    var
        Analysis: Record "Performance Analysis";
    begin
        Analysis.SetFilter("State", '%1|%2|%3',
            Analysis."State"::Scheduled, Analysis."State"::Capturing, Analysis."State"::CaptureEnded);
        if Analysis.FindSet() then
            repeat
                Tick(Analysis);
            until Analysis.Next() = 0;
    end;

    /// <summary>
    /// Tick the state machine for a single analysis.
    /// </summary>
    procedure Tick(var Analysis: Record "Performance Analysis")
    var
        Scheduler: Record "Performance Profile Scheduler";
        MgtImpl: Codeunit "Perf. Analysis Mgt. Impl.";
        HasSchedule: Boolean;
        Now: DateTime;
        NeedsModify: Boolean;
        ScheduleActive: Boolean;
        ScheduleStarted: Boolean;
        ScheduleEnded: Boolean;
    begin
        Now := CurrentDateTime();
        HasSchedule := not IsNullGuid(Analysis."Related Schedule Id") and Scheduler.Get(Analysis."Related Schedule Id");
        // Keep persisted ending time in sync with the scheduler so the list column always
        // reflects the same value the profiler schedule would show.
        if HasSchedule and (Scheduler."Ending Date-Time" <> 0DT) and (Scheduler."Ending Date-Time" <> Analysis."Monitoring Ends At") then begin
            Analysis."Monitoring Ends At" := Scheduler."Ending Date-Time";
            NeedsModify := true;
        end;

        if HasSchedule then begin
            ScheduleStarted := (Scheduler."Starting Date-Time" = 0DT) or (Scheduler."Starting Date-Time" <= Now);
            ScheduleEnded := (Scheduler."Ending Date-Time" <> 0DT) and (Scheduler."Ending Date-Time" <= Now);
            // "Active" means: started, not yet ended, and the platform has not turned it off.
            ScheduleActive := Scheduler.Enabled and ScheduleStarted and (not ScheduleEnded);
        end;

        case Analysis."State" of
            Analysis."State"::Scheduled:
                if (not HasSchedule) or ScheduleEnded or ((not Scheduler.Enabled) and ScheduleStarted) then begin
                    // Schedule finished (or was disabled) before we ever observed it live —
                    // jump straight to CaptureEnded so the AI pipeline can proceed.
                    MgtImpl.SetState(Analysis, Analysis."State"::CaptureEnded);
                    NeedsModify := false;
                end else
                    if ScheduleActive then begin
                        MgtImpl.SetState(Analysis, Analysis."State"::Capturing);
                        NeedsModify := false;
                    end;
            Analysis."State"::Capturing:
                if (not HasSchedule) or (not Scheduler.Enabled) or ScheduleEnded then begin
                    MgtImpl.SetState(Analysis, Analysis."State"::CaptureEnded);
                    NeedsModify := false;
                end;
            Analysis."State"::CaptureEnded:
                ; // Waits for the user (or an auto-advance setup) to run AI filtering/analysis.
        end;

        if NeedsModify then
            Analysis.Modify(true);
    end;

    /// <summary>
    /// Convenience: transition the analysis all the way to Concluded using the AI pipeline.
    /// Noop if the capture hasn't ended yet.
    /// </summary>
    procedure CompleteWithAi(var Analysis: Record "Performance Analysis")
    var
        Mgt: Codeunit "Perf. Analysis Mgt.";
    begin
        Tick(Analysis);
        if Analysis."State" <> Analysis."State"::CaptureEnded then
            exit;
        Mgt.RunFullAiPipeline(Analysis);
    end;

    /// <summary>
    /// When the user (or anything else) modifies a Performance Profile Scheduler that backs
    /// an analysis — typically disabling it — immediately re-evaluate the related analysis
    /// state. This avoids waiting for the next job-queue tick.
    /// </summary>
    [EventSubscriber(ObjectType::Table, Database::"Performance Profile Scheduler", 'OnAfterModifyEvent', '', false, false)]
    local procedure OnAfterModifyProfileScheduler(var Rec: Record "Performance Profile Scheduler"; var xRec: Record "Performance Profile Scheduler"; RunTrigger: Boolean)
    var
        Analysis: Record "Performance Analysis";
    begin
        if IsNullGuid(Rec."Schedule ID") then
            exit;
        Analysis.SetRange("Related Schedule Id", Rec."Schedule ID");
        Analysis.SetFilter("State", '%1|%2', Analysis."State"::Scheduled, Analysis."State"::Capturing);
        if Analysis.FindFirst() then
            Tick(Analysis);
    end;
}
