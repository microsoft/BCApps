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
                field(AnalysisReadyIn; AnalysisReadyInTxt)
                {
                    Caption = 'Analysis Ready In';
                    ApplicationArea = All;
                    ToolTip = 'Specifies how long until the scheduled monitoring window finishes and the analysis becomes available.';
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
        }
    }

    var
        StateStyle: Text;
        HasRelatedSchedule: Boolean;
        CanStopMonitoring: Boolean;
        AnalysisReadyInTxt: Text;
        ProfilerScheduleLinkLbl: Label 'Open schedule';
        ReadyLbl: Label 'Now';
        AnyMomentLbl: Label 'Any moment now';
        UnknownLbl: Label '—', Locked = true;
        DaysFmtLbl: Label '%1 %2', Comment = '%1 = number, %2 = unit (days/day)';
        DaySingularLbl: Label 'day';
        DayPluralLbl: Label 'days';
        HourSingularLbl: Label 'hour';
        HourPluralLbl: Label 'hours';
        MinuteSingularLbl: Label 'minute';
        MinutePluralLbl: Label 'minutes';

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
        AnalysisReadyInTxt := ComputeReadyInText();
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

    local procedure ComputeReadyInText(): Text
    var
        RemainingMs: BigInteger;
    begin
        // Once the analysis has left the monitoring phase, the column no longer makes sense.
        if Rec."State" in [Rec."State"::Concluded, Rec."State"::Cancelled, Rec."State"::Failed] then
            exit(ReadyLbl);
        if Rec."State" in [Rec."State"::CaptureEnded, Rec."State"::AiFiltering, Rec."State"::AiAnalyzing] then
            exit(ReadyLbl);
        if Rec."Monitoring Ends At" = 0DT then
            exit(UnknownLbl);
        RemainingMs := Rec."Monitoring Ends At" - CurrentDateTime();
        if RemainingMs <= 0 then
            exit(AnyMomentLbl);
        exit(FormatDuration(RemainingMs));
    end;

    local procedure FormatDuration(TotalMs: BigInteger): Text
    var
        Parts: Text;
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
        if Days > 0 then
            Parts := StrSubstNo(DaysFmtLbl, Days, Unit(Days, DaySingularLbl, DayPluralLbl));
        if Hours > 0 then
            Parts := Join3(Parts, StrSubstNo(DaysFmtLbl, Hours, Unit(Hours, HourSingularLbl, HourPluralLbl)), Minutes > 0);
        if Minutes > 0 then
            Parts := Join3(Parts, StrSubstNo(DaysFmtLbl, Minutes, Unit(Minutes, MinuteSingularLbl, MinutePluralLbl)), false);
        exit(Parts);
    end;

    local procedure Unit(Value: BigInteger; SingularLbl: Text; PluralLbl: Text): Text
    begin
        if Value = 1 then
            exit(SingularLbl);
        exit(PluralLbl);
    end;

    local procedure Join3(Existing: Text; NewPart: Text; MoreToCome: Boolean): Text
    var
        AndSepLbl: Label ' and ', Locked = true;
        CommaSepLbl: Label ' ', Locked = true;
    begin
        if Existing = '' then
            exit(NewPart);
        if MoreToCome then
            exit(Existing + CommaSepLbl + NewPart);
        exit(Existing + AndSepLbl + NewPart);
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
