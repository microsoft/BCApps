// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

using System.PerformanceProfile;

/// <summary>
/// Embeddable list of Performance Analysis records, used inside the Performance Center hub.
/// </summary>
page 8421 "Perf. Analysis List Part"
{
    Caption = 'Performance Analyses';
    PageType = ListPart;
    ApplicationArea = All;
    SourceTable = "Performance Analysis";
    CardPageId = "Perf. Analysis Card";
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = true;
    Permissions = tabledata "Performance Analysis" = RIMD,
                  tabledata "Performance Analysis Line" = RIMD;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Title"; Rec."Title")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the title of the performance analysis.';
                }
                field("State"; Rec."State")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the current state of the performance analysis.';
                    StyleExpr = StateStyle;
                }
                field("Requested By User Name"; Rec."Target User Name")
                {
                    Caption = 'Monitored user';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the user being monitored by this performance analysis.';
                }
                field("Monitoring Starts At"; Rec."Monitoring Starts At")
                {
                    ApplicationArea = All;
                    Caption = 'Monitoring Start Time';
                    ToolTip = 'Specifies when the monitoring window starts.';
                }
                field(AnalysisReadyIn; MonitoringEndDisplayTxt)
                {
                    Caption = 'Monitoring end time';
                    Editable = false;
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the scheduled monitoring window finishes and the analysis becomes available.';
                }
                field(ProfilerScheduleLink; ProfilerScheduleLinkLbl)
                {
                    Caption = 'Profiler schedule';
                    Editable = false;
                    Style = StrongAccent;
                    ApplicationArea = All;
                    ToolTip = 'Specifies a link that opens the profiler schedule that backs this analysis.';

                    trigger OnDrillDown()
                    begin
                        OpenRelatedSchedule();
                    end;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(StopMonitoring)
            {
                Caption = 'Stop monitoring';
                ToolTip = 'Stop monitoring performance for the selected analysis immediately.';
                Image = Stop;
                ApplicationArea = All;
                Enabled = CanStopMonitoring;

                trigger OnAction()
                var
                    LocalAnalysis: Record "Performance Analysis";
                    Mgt: Codeunit "Perf. Analysis Mgt.";
                begin
                    // Operate on a fresh copy so the list part's bound record isn't
                    // modified through the page binding (which would raise
                    // "changes cannot be saved because some information on the page
                    // is not up-to-date").
                    if not LocalAnalysis.Get(Rec."Id") then
                        exit;
                    Mgt.StopCapture(LocalAnalysis);
                    CurrPage.Update(false);
                end;
            }
            action(DeleteAnalysis)
            {
                Caption = 'Delete';
                ToolTip = 'Delete the selected performance analysis.';
                Image = Delete;
                ApplicationArea = All;

                trigger OnAction()
                var
                    LocalAnalysis: Record "Performance Analysis";
                    ConfirmLbl: Label 'Delete the performance analysis "%1"?', Comment = '%1 = analysis title';
                begin
                    if IsNullGuid(Rec."Id") then
                        exit;
                    if not LocalAnalysis.Get(Rec."Id") then
                        exit;
                    if not Confirm(StrSubstNo(ConfirmLbl, LocalAnalysis."Title")) then
                        exit;
                    LocalAnalysis.Delete(true);
                    CurrPage.Update(false);
                end;
            }
        }
    }

    var
        StateStyle: Text;
        HasRelatedSchedule: Boolean;
        CanStopMonitoring: Boolean;
        MonitoringEndDisplayTxt: Text;
        ProfilerScheduleLinkLbl: Label 'Open schedule';
        AnyMomentLbl: Label 'Any moment now';
        UnknownReadyLbl: Label '—', Locked = true;
        InPrefixFmtLbl: Label 'in %1', Comment = '%1 = remaining duration, e.g. "2 hours and 15 minutes"';

    trigger OnOpenPage()
    var
        Monitor: Codeunit "Perf. Analysis Monitor";
    begin
        // Lazily advance the state machine so stale "Actively monitoring" rows catch up
        // without waiting for the background job queue.
        Monitor.TickAll();
    end;

    trigger OnAfterGetRecord()
    begin
        Rec.CalcFields("Target User Name");
        HasRelatedSchedule := not IsNullGuid(Rec."Related Schedule Id");
        MonitoringEndDisplayTxt := ComputeMonitoringEndDisplayText();
        CanStopMonitoring := Rec."State" in [Rec."State"::Scheduled, Rec."State"::Capturing];
        case Rec."State" of
            Rec."State"::Concluded:
                StateStyle := 'Favorable';
            Rec."State"::Failed,
            Rec."State"::Cancelled:
                StateStyle := 'Unfavorable';
            Rec."State"::Scheduled,
            Rec."State"::Capturing:
                StateStyle := 'Attention';
            Rec."State"::CaptureEnded,
            Rec."State"::AiFiltering,
            Rec."State"::AiAnalyzing:
                StateStyle := 'StrongAccent';
            else
                StateStyle := 'Standard';
        end;
    end;

    local procedure ComputeMonitoringEndDisplayText(): Text
    var
        RemainingMs: BigInteger;
    begin
        // While monitoring is actively running we show a relative "in X and Y" caption
        // because the absolute timestamp is less meaningful to the reader. Once the
        // window has elapsed or the analysis has moved on we fall back to the actual
        // end time (or a dash if we never knew it).
        if Rec."Monitoring Ends At" = 0DT then
            exit(UnknownReadyLbl);
        if Rec."State" in [Rec."State"::Scheduled, Rec."State"::Capturing] then begin
            RemainingMs := Rec."Monitoring Ends At" - CurrentDateTime();
            if RemainingMs <= 0 then
                exit(AnyMomentLbl);
            exit(StrSubstNo(InPrefixFmtLbl, FormatDuration(RemainingMs)));
        end;
        exit(Format(Rec."Monitoring Ends At"));
    end;

    local procedure FormatDuration(TotalMs: BigInteger): Text
    var
        UnitFmtLbl: Label '%1 %2', Comment = '%1 = number, %2 = unit (days/day, hours/hour, minutes/minute)';
        DaySingularLbl: Label 'day';
        DayPluralLbl: Label 'days';
        HourSingularLbl: Label 'hour';
        HourPluralLbl: Label 'hours';
        MinuteSingularLbl: Label 'minute';
        MinutePluralLbl: Label 'minutes';
        AndSepLbl: Label ' and ', Locked = true;
        CommaSepLbl: Label ', ', Locked = true;
        Parts: array[3] of Text;
        Count: Integer;
        Days: BigInteger;
        Hours: BigInteger;
        Minutes: BigInteger;
    begin
        Days := TotalMs div (24 * 60 * 60 * 1000);
        TotalMs := TotalMs mod (24 * 60 * 60 * 1000);
        Hours := TotalMs div (60 * 60 * 1000);
        TotalMs := TotalMs mod (60 * 60 * 1000);
        Minutes := TotalMs div (60 * 1000);
        if (Days = 0) and (Hours = 0) and (Minutes = 0) then
            Minutes := 1;
        if Days > 0 then begin
            Count += 1;
            Parts[Count] := StrSubstNo(UnitFmtLbl, Days, Unit(Days, DaySingularLbl, DayPluralLbl));
        end;
        if Hours > 0 then begin
            Count += 1;
            Parts[Count] := StrSubstNo(UnitFmtLbl, Hours, Unit(Hours, HourSingularLbl, HourPluralLbl));
        end;
        if Minutes > 0 then begin
            Count += 1;
            Parts[Count] := StrSubstNo(UnitFmtLbl, Minutes, Unit(Minutes, MinuteSingularLbl, MinutePluralLbl));
        end;
        case Count of
            1:
                exit(Parts[1]);
            2:
                exit(Parts[1] + AndSepLbl + Parts[2]);
            3:
                exit(Parts[1] + CommaSepLbl + Parts[2] + AndSepLbl + Parts[3]);
        end;
        exit('');
    end;

    local procedure Unit(Value: BigInteger; SingularLbl: Text; PluralLbl: Text): Text
    begin
        if Value = 1 then
            exit(SingularLbl);
        exit(PluralLbl);
    end;

    local procedure OpenRelatedSchedule()
    var
        ProfilerScheduler: Record "Performance Profile Scheduler";
    begin
        if not HasRelatedSchedule then
            exit;
        if not ProfilerScheduler.Get(Rec."Related Schedule Id") then
            exit;
        Page.Run(Page::"Perf. Profiler Schedule Card", ProfilerScheduler);
    end;
}
