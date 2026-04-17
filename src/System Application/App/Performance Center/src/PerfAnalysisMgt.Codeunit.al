// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

using System.PerformanceProfile;

/// <summary>
/// Public facade for the Performance Center. Use this codeunit to request, drive and
/// inspect Performance Analysis records from other apps.
/// </summary>
codeunit 5480 "Perf. Analysis Mgt."
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        Impl: Codeunit "Perf. Analysis Mgt. Impl.";

    /// <summary>
    /// Creates a Performance Analysis record and an associated Performance Profile Scheduler
    /// based on the answers captured from the user (typically the wizard).
    /// </summary>
    /// <param name="Analysis">The Performance Analysis record to create. Fields like
    /// Trigger, Frequency, Observed Duration etc. must be populated before calling.</param>
    procedure RequestAnalysis(var Analysis: Record "Performance Analysis")
    begin
        Impl.RequestAnalysis(Analysis);
    end;

    /// <summary>
    /// Stops the capture for the given analysis. Transitions the state to CaptureEnded
    /// regardless of whether the monitoring window has expired.
    /// </summary>
    procedure StopCapture(var Analysis: Record "Performance Analysis")
    begin
        Impl.StopCapture(Analysis);
    end;

    /// <summary>
    /// Cancels an analysis (including its profiler schedule, if still active).
    /// </summary>
    procedure CancelAnalysis(var Analysis: Record "Performance Analysis")
    begin
        Impl.CancelAnalysis(Analysis);
    end;

    /// <summary>
    /// Runs the AI filter step for the given analysis: loads captured profiles and asks
    /// the AI which are relevant (with score + reason).
    /// </summary>
    procedure RunAiFiltering(var Analysis: Record "Performance Analysis")
    begin
        Impl.RunAiFiltering(Analysis);
    end;

    /// <summary>
    /// Runs the AI analysis step: gathers signals and asks the AI for a conclusion.
    /// </summary>
    procedure RunAiAnalysis(var Analysis: Record "Performance Analysis")
    begin
        Impl.RunAiAnalysis(Analysis);
    end;

    /// <summary>
    /// Runs both AI filtering and AI analysis back-to-back.
    /// </summary>
    procedure RunFullAiPipeline(var Analysis: Record "Performance Analysis")
    begin
        Impl.RunFullAiPipeline(Analysis);
    end;

    /// <summary>
    /// Returns the current platform Performance Profile Scheduler record associated
    /// with the analysis, if any.
    /// </summary>
    procedure TryGetSchedule(var Analysis: Record "Performance Analysis"; var Scheduler: Record "Performance Profile Scheduler"): Boolean
    begin
        exit(Impl.TryGetSchedule(Analysis, Scheduler));
    end;

    /// <summary>
    /// Raised immediately before the Performance Profile Scheduler is created for an analysis.
    /// Subscribers can tweak the scheduler fields.
    /// </summary>
    [IntegrationEvent(false, false)]
    internal procedure OnBeforeCreateSchedule(var Analysis: Record "Performance Analysis"; var Scheduler: Record "Performance Profile Scheduler")
    begin
    end;

    /// <summary>
    /// Raised after the Performance Profile Scheduler has been created for an analysis.
    /// </summary>
    [IntegrationEvent(false, false)]
    internal procedure OnAfterCreateSchedule(var Analysis: Record "Performance Analysis"; var Scheduler: Record "Performance Profile Scheduler")
    begin
    end;

    /// <summary>
    /// Raised before the AI conclusion is generated. Subscribers can add extra context
    /// lines (signals or notes) that will be fed to the AI.
    /// </summary>
    [IntegrationEvent(false, false)]
    internal procedure OnBeforeRunAiAnalysis(var Analysis: Record "Performance Analysis")
    begin
    end;

    /// <summary>
    /// Raised after an analysis transitions to Concluded.
    /// </summary>
    [IntegrationEvent(false, false)]
    internal procedure OnAfterConcludeAnalysis(var Analysis: Record "Performance Analysis")
    begin
    end;
}
