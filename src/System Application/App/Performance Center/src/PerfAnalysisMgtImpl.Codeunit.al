// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

using System.PerformanceProfile;
using System.Security.User;
using System.Telemetry;

/// <summary>
/// Implementation behind "Perf. Analysis Mgt." Contains the state machine and the
/// wizard-to-scheduler mapping.
/// </summary>
codeunit 8414 "Perf. Analysis Mgt. Impl."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "Performance Analysis" = RIMD,
                  tabledata "Performance Analysis Line" = RIMD,
                  tabledata "Performance Profile Scheduler" = RIMD;

    var
        CannotScheduleForOthersErr: Label 'Only administrators can request a performance analysis for another user.';
        AnalysisNotActiveErr: Label 'This action is not available in the current state (%1).', Comment = '%1 = current state caption';
        TelemetryCategoryTok: Label 'Performance Center', Locked = true;
        RequestedTelemetryLbl: Label 'Performance Analysis requested. State=%1, Activity=%2, Frequency=%3.', Locked = true;
        StateChangedTelemetryLbl: Label 'Performance Analysis state changed from %1 to %2.', Locked = true;

    procedure RequestAnalysis(var Analysis: Record "Performance Analysis")
    var
        Scheduler: Record "Performance Profile Scheduler";
        ScheduledPerfProfiler: Codeunit "Scheduled Perf. Profiler";
        PerfAnalysisMgt: Codeunit "Perf. Analysis Mgt.";
        TickTask: Codeunit "Perf. Analysis Tick Task";
        Telemetry: Codeunit Telemetry;
        Dimensions: Dictionary of [Text, Text];
    begin
        ValidateTarget(Analysis);

        if IsNullGuid(Analysis."Id") then
            Analysis."Id" := CreateGuid();
        if IsNullGuid(Analysis."Requested By") then
            Analysis."Requested By" := UserSecurityId();
        if Analysis."Requested At" = 0DT then
            Analysis."Requested At" := CurrentDateTime();
        if IsNullGuid(Analysis."Target User") then
            Analysis."Target User" := Analysis."Requested By";
        if Analysis."Title" = '' then
            Analysis."Title" := BuildAutoTitle(Analysis);

        Analysis."State" := Analysis."State"::Requested;
        Analysis.Insert(true);

        InitSchedulerFromAnalysis(Analysis, Scheduler);
        PerfAnalysisMgt.OnBeforeCreateSchedule(Analysis, Scheduler);
        ScheduledPerfProfiler.ValidatePerformanceProfileSchedulerRecord(Scheduler, Analysis."Scenario Activity Type");
        Scheduler.Insert(true);
        PerfAnalysisMgt.OnAfterCreateSchedule(Analysis, Scheduler);

        Analysis."Related Schedule Id" := Scheduler."Schedule ID";
        Analysis."Monitoring Starts At" := Scheduler."Starting Date-Time";
        Analysis."Monitoring Ends At" := Scheduler."Ending Date-Time";
        Analysis."Profile Threshold (ms)" := Scheduler."Profile Creation Threshold";
        SetState(Analysis, Analysis."State"::Scheduled);

        TickTask.ScheduleFirstTick(Analysis, Scheduler);

        Dimensions.Add('Category', TelemetryCategoryTok);
        Dimensions.Add('State', Format(Analysis."State"));
        Dimensions.Add('Activity', Format(Analysis."Scenario Activity Type"));
        Dimensions.Add('Frequency', Format(Analysis."Frequency"));
        Telemetry.LogMessage('PC-0001', StrSubstNo(RequestedTelemetryLbl, Analysis."State", Analysis."Scenario Activity Type", Analysis."Frequency"),
            Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, Dimensions);
    end;

    procedure StopCapture(var Analysis: Record "Performance Analysis")
    var
        Scheduler: Record "Performance Profile Scheduler";
    begin
        if not (Analysis."State" in [Analysis."State"::Scheduled, Analysis."State"::Capturing]) then
            Error(AnalysisNotActiveErr, Analysis."State");
        if TryGetSchedule(Analysis, Scheduler) then begin
            Scheduler."Ending Date-Time" := CurrentDateTime();
            Scheduler.Enabled := false;
            // Scheduler.Modify fires OnAfterModifyProfileScheduler, which in turn calls
            // Tick(Analysis) and may advance the analysis state in the database. Re-read
            // below so our local var has a matching xRec before we Modify again.
            Scheduler.Modify(true);
        end;
        if not Analysis.Get(Analysis."Id") then
            exit;
        if Analysis."State" in [Analysis."State"::Scheduled, Analysis."State"::Capturing] then begin
            Analysis."Monitoring Ends At" := CurrentDateTime();
            SetState(Analysis, Analysis."State"::CaptureEnded);
        end;

        // Kick straight into the AI analysis phase. The Ai pipeline owns its own
        // state transitions (CaptureEnded -> AiAnalyzing -> Concluded/Failed) so we
        // do not need to short-circuit here.
        if Analysis."State" = Analysis."State"::CaptureEnded then
            RunFullAiPipeline(Analysis);
    end;

    procedure CancelAnalysis(var Analysis: Record "Performance Analysis")
    var
        Scheduler: Record "Performance Profile Scheduler";
    begin
        if Analysis."State" in [Analysis."State"::Concluded, Analysis."State"::Cancelled, Analysis."State"::Failed] then
            exit;
        if TryGetSchedule(Analysis, Scheduler) then begin
            Scheduler.Enabled := false;
            Scheduler."Ending Date-Time" := CurrentDateTime();
            Scheduler.Modify(true);
        end;
        if not Analysis.Get(Analysis."Id") then
            exit;
        if Analysis."State" in [Analysis."State"::Concluded, Analysis."State"::Cancelled, Analysis."State"::Failed] then
            exit;
        SetState(Analysis, Analysis."State"::Cancelled);
    end;

    procedure RunAiFiltering(var Analysis: Record "Performance Analysis")
    var
        Ai: Codeunit "Perf. Analysis AI";
    begin
        if not (Analysis."State" in [Analysis."State"::CaptureEnded, Analysis."State"::AiFiltering]) then
            Error(AnalysisNotActiveErr, Analysis."State");
        SetState(Analysis, Analysis."State"::AiFiltering);
        if Ai.FilterProfiles(Analysis) then
            SetState(Analysis, Analysis."State"::CaptureEnded)
        else
            FailAnalysis(Analysis, Ai.GetLastError());
    end;

    procedure RunAiAnalysis(var Analysis: Record "Performance Analysis")
    var
        Ai: Codeunit "Perf. Analysis AI";
        PerfAnalysisMgt: Codeunit "Perf. Analysis Mgt.";
    begin
        if not (Analysis."State" in [Analysis."State"::CaptureEnded, Analysis."State"::AiAnalyzing]) then
            Error(AnalysisNotActiveErr, Analysis."State");
        SetState(Analysis, Analysis."State"::AiAnalyzing);

        PerfAnalysisMgt.OnBeforeRunAiAnalysis(Analysis);

        if Ai.Analyze(Analysis) then begin
            SetState(Analysis, Analysis."State"::Concluded);
            PerfAnalysisMgt.OnAfterConcludeAnalysis(Analysis);
        end else
            FailAnalysis(Analysis, Ai.GetLastError());
    end;

    procedure RunFullAiPipeline(var Analysis: Record "Performance Analysis")
    var
        Dialog: Dialog;
        FilteringStepLbl: Label 'Selecting relevant profiles...';
        AnalyzingStepLbl: Label 'Analyzing profiles...';
    begin
        if GuiAllowed() then
            Dialog.Open(FilteringStepLbl);
        RunAiFiltering(Analysis);
        if GuiAllowed() then
            Dialog.Close();
        if Analysis."State" = Analysis."State"::Failed then
            exit;

        if GuiAllowed() then
            Dialog.Open(AnalyzingStepLbl);
        RunAiAnalysis(Analysis);
        if GuiAllowed() then
            Dialog.Close();
    end;

    procedure Reanalyze(var Analysis: Record "Performance Analysis")
    var
        Dialog: Dialog;
        CleaningStepLbl: Label 'Cleaning previous results...';
        FilteringStepLbl: Label 'Selecting relevant profiles...';
        AnalyzingStepLbl: Label 'Analyzing profiles...';
    begin
        if not (Analysis."State" in [Analysis."State"::Concluded, Analysis."State"::Failed]) then
            Error(AnalysisNotActiveErr, Analysis."State");

        if GuiAllowed() then
            Dialog.Open(CleaningStepLbl);
        ResetAnalysisResults(Analysis);
        SetState(Analysis, Analysis."State"::CaptureEnded);
        if GuiAllowed() then begin
            Sleep(3000);
            Dialog.Close();
        end;

        if GuiAllowed() then
            Dialog.Open(FilteringStepLbl);
        RunAiFiltering(Analysis);
        if GuiAllowed() then
            Dialog.Close();
        if Analysis."State" = Analysis."State"::Failed then
            exit;

        if GuiAllowed() then
            Dialog.Open(AnalyzingStepLbl);
        RunAiAnalysis(Analysis);
        if GuiAllowed() then
            Dialog.Close();
    end;

    local procedure ResetAnalysisResults(var Analysis: Record "Performance Analysis")
    var
        Line: Record "Performance Analysis Line";
    begin
        Line.SetRange("Analysis Id", Analysis."Id");
        Line.DeleteAll(true);
        Clear(Analysis."Conclusion");
        Analysis."Last Error" := '';
        Analysis."Profiles Relevant" := 0;
        Analysis."Ai Model" := '';
        Analysis.Modify(true);
    end;

    procedure TryGetSchedule(var Analysis: Record "Performance Analysis"; var Scheduler: Record "Performance Profile Scheduler"): Boolean
    begin
        if IsNullGuid(Analysis."Related Schedule Id") then
            exit(false);
        exit(Scheduler.Get(Analysis."Related Schedule Id"));
    end;

    internal procedure SetState(var Analysis: Record "Performance Analysis"; NewState: Enum "Perf. Analysis State")
    var
        Telemetry: Codeunit Telemetry;
        Dimensions: Dictionary of [Text, Text];
        OldState: Enum "Perf. Analysis State";
    begin
        OldState := Analysis."State";
        if OldState = NewState then
            exit;
        Analysis."State" := NewState;
        Analysis.Modify(true);

        Dimensions.Add('Category', TelemetryCategoryTok);
        Dimensions.Add('AnalysisId', Format(Analysis."Id"));
        Dimensions.Add('From', Format(OldState));
        Dimensions.Add('To', Format(NewState));
        Telemetry.LogMessage('PC-0002', StrSubstNo(StateChangedTelemetryLbl, OldState, NewState),
            Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, Dimensions);
    end;

    internal procedure FailAnalysis(var Analysis: Record "Performance Analysis"; Reason: Text)
    begin
        Analysis."Last Error" := CopyStr(Reason, 1, MaxStrLen(Analysis."Last Error"));
        SetState(Analysis, Analysis."State"::Failed);
    end;

    local procedure ValidateTarget(var Analysis: Record "Performance Analysis")
    var
        UserPermissions: Codeunit "User Permissions";
    begin
        if IsNullGuid(Analysis."Target User") then
            exit;
        if Analysis."Target User" = UserSecurityId() then
            exit;
        if not UserPermissions.CanManageUsersOnTenant(UserSecurityId()) then
            Error(CannotScheduleForOthersErr);
    end;

    local procedure InitSchedulerFromAnalysis(var Analysis: Record "Performance Analysis"; var Scheduler: Record "Performance Profile Scheduler")
    var
        ScheduledPerfProfiler: Codeunit "Scheduled Perf. Profiler";
        ActivityType: Enum "Perf. Profile Activity Type";
        Window: Duration;
    begin
        ActivityType := Analysis."Scenario Activity Type";
        ScheduledPerfProfiler.InitializeFields(Scheduler, ActivityType);

        Scheduler."Schedule ID" := CreateGuid();
        Scheduler."User ID" := Analysis."Target User";
        Scheduler.Description := CopyStr(Analysis."Title", 1, MaxStrLen(Scheduler.Description));
        Scheduler."Starting Date-Time" := CurrentDateTime();

        Window := MonitoringWindowFor(Analysis."Frequency");
        Scheduler."Ending Date-Time" := Scheduler."Starting Date-Time" + Window;
        Scheduler."Profile Creation Threshold" := ThresholdFor(Analysis);

        ScheduledPerfProfiler.MapActivityTypeToRecord(Scheduler, ActivityType);
    end;

    local procedure MonitoringWindowFor(Frequency: Enum "Perf. Analysis Frequency") Window: Duration
    begin
        case Frequency of
            Frequency::Always:
                Window := 60 * 60 * 1000; // 1 hour
            Frequency::ComesAndGoes:
                Window := 8 * 60 * 60 * 1000; // 8 hours
            Frequency::Sometimes:
                Window := 24 * 60 * 60 * 1000; // 1 day
            Frequency::Unknown:
                Window := 24 * 60 * 60 * 1000; // 1 day
        end;
    end;

    local procedure ThresholdFor(Analysis: Record "Performance Analysis") Threshold: Integer
    begin
        // Set the threshold below the expected duration so we also capture runs at or near
        // the expected time, not just the outliers. This gives the AI a baseline to compare
        // the slow runs against. Modeled as 50% of the expected duration, clamped to a
        // sensible floor and ceiling.
        if Analysis."Expected Duration (ms)" > 0 then
            Threshold := Analysis."Expected Duration (ms)" div 2
        else
            Threshold := 200;
        if Threshold < 200 then
            Threshold := 200;
        if Threshold > 60000 then
            Threshold := 60000;
    end;

    local procedure BuildAutoTitle(Analysis: Record "Performance Analysis"): Text[250]
    var
        TitleTxt: Label 'Slow %1 (%2)', Comment = '%1 = trigger description, %2 = requested date';
        TriggerTxt: Text;
    begin
        if Analysis."Trigger Object Name" <> '' then
            TriggerTxt := Analysis."Trigger Object Name"
        else
            TriggerTxt := Format(Analysis."Trigger Kind");
        exit(CopyStr(StrSubstNo(TitleTxt, TriggerTxt, Format(Today())), 1, 250));
    end;
}
