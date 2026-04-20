// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

using System.PerformanceProfile;

/// <summary>
/// Card showing the details of a single performance analysis, with actions for the
/// lifecycle (stop capture, run AI, chat with the report).
/// </summary>
page 8426 "Perf. Analysis Card"
{
    Caption = 'Performance Analysis';
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "Performance Analysis";
    DataCaptionExpression = Rec."Title";
    Permissions = tabledata "Performance Analysis" = RIMD,
                  tabledata "Performance Analysis Line" = RIMD,
                  tabledata "Performance Profile Scheduler" = R;

    layout
    {
        area(Content)
        {
            group(Overview)
            {
                Caption = 'Overview';

                field("Title"; Rec."Title")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the title of this performance analysis.';
                }
                field("State"; Rec."State")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the current state of the analysis.';
                }
                field(WhatsSlow; WhatsSlowText)
                {
                    Caption = 'What is slow';
                    Editable = false;
                    MultiLine = true;
                    ApplicationArea = All;
                    ToolTip = 'Specifies the slow scenario described when this analysis was created.';
                }
                field("Notes"; Rec."Notes")
                {
                    ApplicationArea = All;
                    Editable = false;
                    MultiLine = true;
                    ToolTip = 'Specifies any extra details the user added.';
                }
            }
            group(Result)
            {
                Caption = 'Conclusion';
                Visible = Rec."State" = Rec."State"::Concluded;

                field(ConclusionText; ConclusionText)
                {
                    ShowCaption = false;
                    MultiLine = true;
                    Editable = false;
                    ApplicationArea = All;
                    ToolTip = 'Shows the AI-generated conclusion for this analysis.';
                }
                field(ChatEntryPoint; ChatEntryPointLbl)
                {
                    ShowCaption = false;
                    Editable = false;
                    Style = StrongAccent;
                    ApplicationArea = All;
                    ToolTip = 'Opens a chat with this analysis.';

                    trigger OnDrillDown()
                    begin
                        OpenChat();
                    end;
                }
            }
            group(Failure)
            {
                Caption = 'Error details';
                Visible = Rec."State" = Rec."State"::Failed;

                field("Last Error"; Rec."Last Error")
                {
                    ApplicationArea = All;
                    Editable = false;
                    MultiLine = true;
                    ToolTip = 'Specifies the last error encountered by the analysis.';
                }
            }
            group(ScenarioDetails)
            {
                Caption = 'Scenario details';

                field("Requested By User Name"; Rec."Requested By User Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies who requested this performance analysis.';
                }
                field("Requested At"; Rec."Requested At")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies when the analysis was requested.';
                }
                field("Target User Name"; Rec."Target User Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies which user the analysis is monitoring.';
                }
                field("Scenario Activity Type"; Rec."Scenario Activity Type")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the activity type the analysis covers.';
                }
                field("Trigger Kind"; Rec."Trigger Kind")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies what kind of trigger was identified.';
                }
                field("Trigger Object Id"; Rec."Trigger Object Id")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the ID of the object involved in the slow scenario.';
                }
                field("Trigger Object Name"; Rec."Trigger Object Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the object involved in the slow scenario.';
                }
                field("Trigger Action Name"; Rec."Trigger Action Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the specific action or field involved.';
                }
                field("Frequency"; Rec."Frequency")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies how often the scenario is slow.';
                }
                field("Observed Duration (ms)"; Rec."Observed Duration (ms)")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies how long the action takes when it is slow, in milliseconds.';
                }
                field("Expected Duration (ms)"; Rec."Expected Duration (ms)")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies how long the user expects the action to take, in milliseconds.';
                }
            }
            group(CaptureDetails)
            {
                Caption = 'Monitoring details';

                field("Monitoring Starts At"; Rec."Monitoring Starts At")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies when the monitoring window starts.';
                }
                field("Monitoring Ends At"; Rec."Monitoring Ends At")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies when the monitoring window is scheduled to end.';
                }
                field("Profile Threshold (ms)"; Rec."Profile Threshold (ms)")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the threshold used by the profiler schedule, in milliseconds.';
                }
                field("Profiles Captured"; Rec."Profiles Captured")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies how many profiles were captured.';
                }
                field("Profiles Relevant"; Rec."Profiles Relevant")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies how many profiles the AI flagged as relevant.';
                }
                field(RelatedScheduleLink; RelatedScheduleLinkLbl)
                {
                    Caption = 'Profiler schedule';
                    Editable = false;
                    Style = StrongAccent;
                    ApplicationArea = All;
                    Visible = HasRelatedSchedule;
                    ToolTip = 'Specifies a link to the profiler schedule that backs this analysis.';

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
            action(StopCapture)
            {
                Caption = 'Stop monitoring';
                ToolTip = 'Stop monitoring performance for this analysis immediately.';
                Image = Stop;
                ApplicationArea = All;
                Enabled = CanStopCapture;

                trigger OnAction()
                var
                    Mgt: Codeunit "Perf. Analysis Mgt.";
                begin
                    Mgt.StopCapture(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(RunFullAi)
            {
                Caption = 'Run AI analysis';
                ToolTip = 'Filter the captured profiles and produce a conclusion using AI.';
                Image = SparkleFilled;
                ApplicationArea = All;
                Enabled = CanRunAi;

                trigger OnAction()
                var
                    Mgt: Codeunit "Perf. Analysis Mgt.";
                begin
                    Mgt.RunFullAiPipeline(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(RunAiFilter)
            {
                Caption = 'Run AI filtering only';
                ToolTip = 'Use AI to filter captured profiles without producing the conclusion yet.';
                Image = AdjustEntries;
                ApplicationArea = All;
                Enabled = CanRunAi;

                trigger OnAction()
                var
                    Mgt: Codeunit "Perf. Analysis Mgt.";
                begin
                    Mgt.RunAiFiltering(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(ChatWithReport)
            {
                Caption = 'Click here to chat with the analysis report';
                ToolTip = 'Ask follow-up questions about the conclusion.';
                Image = Comment;
                ApplicationArea = All;
                Enabled = CanChat;

                trigger OnAction()
                begin
                    OpenChat();
                end;
            }
            action(Cancel)
            {
                Caption = 'Cancel analysis';
                ToolTip = 'Cancel this analysis and disable its profiler schedule.';
                Image = CancelApprovalRequest;
                ApplicationArea = All;
                Enabled = CanCancel;

                trigger OnAction()
                var
                    Mgt: Codeunit "Perf. Analysis Mgt.";
                begin
                    Mgt.CancelAnalysis(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(RelatedSchedule)
            {
                Caption = 'Profiler schedule';
                ToolTip = 'Open the profiler schedule that backs this analysis.';
                Image = Timesheet;
                ApplicationArea = All;
                Enabled = HasRelatedSchedule;

                trigger OnAction()
                begin
                    OpenRelatedSchedule();
                end;
            }
            action(ViewProfiles)
            {
                Caption = 'View captured profiles';
                ToolTip = 'Show the captured performance profiles for this analysis, with AI relevance scores.';
                Image = ViewDetails;
                ApplicationArea = All;

                trigger OnAction()
                var
                    ProfileList: Page "Perf. Analysis Profile List";
                begin
                    ProfileList.SetAnalysis(Rec);
                    ProfileList.Run();
                end;
            }
            action(ViewSignals)
            {
                Caption = 'View signals';
                ToolTip = 'Show gathered signal findings (profiler hotspots, missing indexes, telemetry).';
                Image = FilterLines;
                ApplicationArea = All;

                trigger OnAction()
                var
                    SignalsPage: Page "Perf. Analysis Signals";
                begin
                    SignalsPage.SetAnalysis(Rec);
                    SignalsPage.Run();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';
                actionref(RunFullAi_Promoted; RunFullAi) { }
                actionref(ChatWithReport_Promoted; ChatWithReport) { }
                actionref(StopCapture_Promoted; StopCapture) { }
                actionref(RelatedSchedule_Promoted; RelatedSchedule) { }
            }
        }
    }

    var
        ConclusionText: Text;
        WhatsSlowText: Text;
        CanStopCapture: Boolean;
        CanRunAi: Boolean;
        CanChat: Boolean;
        CanCancel: Boolean;
        HasRelatedSchedule: Boolean;
        ChatEntryPointLbl: Label '>> Click here to chat with the analysis <<';
        RelatedScheduleLinkLbl: Label '>> Click here to open the profiler schedule <<';

    trigger OnAfterGetCurrRecord()
    var
        Scheduler: Record "Performance Profile Scheduler";
        Ai: Codeunit "Perf. Analysis AI";
        AiAvailable: Boolean;
        ScheduleActive: Boolean;
    begin
        AiAvailable := Ai.IsAvailable();
        Rec.CalcFields("Requested By User Name", "Target User Name");
        ConclusionText := Rec.GetConclusion();
        WhatsSlowText := BuildWhatsSlow();
        HasRelatedSchedule := not IsNullGuid(Rec."Related Schedule Id");
        ScheduleActive := HasRelatedSchedule and Scheduler.Get(Rec."Related Schedule Id")
            and Scheduler.Enabled
            and ((Scheduler."Ending Date-Time" = 0DT) or (Scheduler."Ending Date-Time" > CurrentDateTime()));
        // Stopping monitoring only makes sense while the underlying profiler schedule is
        // still collecting. Once the schedule is disabled or its ending time has passed
        // there is nothing to stop - the monitor will transition the analysis to
        // CaptureEnded.
        CanStopCapture := (Rec."State" in [Rec."State"::Scheduled, Rec."State"::Capturing]) and ScheduleActive;
        CanRunAi := AiAvailable and (Rec."State" = Rec."State"::CaptureEnded);
        CanChat := AiAvailable and (Rec."State" = Rec."State"::Concluded);
        CanCancel := not (Rec."State" in [Rec."State"::Concluded, Rec."State"::Cancelled, Rec."State"::Failed]);
    end;

    local procedure OpenChat()
    var
        ChatPage: Page "Perf. Analysis Chat";
    begin
        ChatPage.SetAnalysis(Rec);
        ChatPage.RunModal();
    end;

    local procedure OpenRelatedSchedule()
    var
        ProfilerScheduler: Record "Performance Profile Scheduler";
    begin
        if IsNullGuid(Rec."Related Schedule Id") then
            exit;
        if not ProfilerScheduler.Get(Rec."Related Schedule Id") then
            exit;
        Page.Run(Page::"Perf. Profiler Schedule Card", ProfilerScheduler);
    end;

    local procedure BuildWhatsSlow(): Text
    var
        ScreenLbl: Label 'Screen: %1', Comment = '%1 = name of the page or screen';
        ActionLbl: Label 'Action: %1', Comment = '%1 = action, button or field name';
        ObservedLbl: Label 'Takes about %1 ms (expected %2 ms)', Comment = '%1 = observed duration in ms, %2 = expected duration in ms';
        FrequencyLbl: Label 'Frequency: %1', Comment = '%1 = frequency';
        Builder: TextBuilder;
    begin
        if Rec."Trigger Object Name" <> '' then
            Builder.AppendLine(StrSubstNo(ScreenLbl, Rec."Trigger Object Name"));
        if Rec."Trigger Action Name" <> '' then
            Builder.AppendLine(StrSubstNo(ActionLbl, Rec."Trigger Action Name"));
        if (Rec."Observed Duration (ms)" > 0) or (Rec."Expected Duration (ms)" > 0) then
            Builder.AppendLine(StrSubstNo(ObservedLbl, Rec."Observed Duration (ms)", Rec."Expected Duration (ms)"));
        Builder.AppendLine(StrSubstNo(FrequencyLbl, Rec."Frequency"));
        exit(Builder.ToText());
    end;
}
