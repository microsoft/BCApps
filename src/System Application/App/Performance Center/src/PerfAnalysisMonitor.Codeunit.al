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
codeunit 5482 "Perf. Analysis Monitor"
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
    begin
        Now := CurrentDateTime();
        HasSchedule := not IsNullGuid(Analysis."Related Schedule Id") and Scheduler.Get(Analysis."Related Schedule Id");

        case Analysis."State" of
            Analysis."State"::Scheduled:
                if HasSchedule and (Scheduler."Starting Date-Time" <= Now) and
                   (Scheduler.Enabled or ((Scheduler."Ending Date-Time" = 0DT) or (Scheduler."Ending Date-Time" > Now))) then
                    MgtImpl.SetState(Analysis, Analysis."State"::Capturing);
            Analysis."State"::Capturing:
                if (not HasSchedule) or (not Scheduler.Enabled) or
                   ((Scheduler."Ending Date-Time" <> 0DT) and (Scheduler."Ending Date-Time" <= Now)) then
                    MgtImpl.SetState(Analysis, Analysis."State"::CaptureEnded);
            Analysis."State"::CaptureEnded:
                ; // Waits for the user (or an auto-advance setup) to run AI filtering/analysis.
        end;
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
}
