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
page 5493 "Perf. Analysis Card"
{
    Caption = 'Performance Analysis';
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "Performance Analysis";
    DataCaptionExpression = Rec."Title";
    Permissions = tabledata "Performance Analysis" = RIM,
                  tabledata "Performance Profile Scheduler" = R;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field("Title"; Rec."Title")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the title of the performance analysis.';
                }
                field("State"; Rec."State")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the current state of the performance analysis.';
                }
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
            }
            group(Scenario)
            {
                Caption = 'Scenario';

                field("Scenario Activity Type"; Rec."Scenario Activity Type")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the scenario the analysis covers.';
                }
                field("Trigger Kind"; Rec."Trigger Kind")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies what kind of trigger the user identified.';
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
                    ToolTip = 'Specifies how long the action takes when it is slow.';
                }
                field("Expected Duration (ms)"; Rec."Expected Duration (ms)")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies how long the user expects the action to take.';
                }
                field("Notes"; Rec."Notes")
                {
                    ApplicationArea = All;
                    Editable = false;
                    MultiLine = true;
                    ToolTip = 'Specifies extra details captured from the user.';
                }
            }
            group(Capture)
            {
                Caption = 'Capture';

                field("Monitoring Starts At"; Rec."Monitoring Starts At")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies when the capture started.';
                }
                field("Monitoring Ends At"; Rec."Monitoring Ends At")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies when the capture is scheduled to end.';
                }
                field("Profile Threshold (ms)"; Rec."Profile Threshold (ms)")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the threshold used by the profiler schedule.';
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
                    ToolTip = 'Opens a chat with the analysis report.';

                    trigger OnDrillDown()
                    begin
                        OpenChat();
                    end;
                }
            }
            group(Failure)
            {
                Caption = 'Details';
                Visible = Rec."State" = Rec."State"::Failed;

                field("Last Error"; Rec."Last Error")
                {
                    ApplicationArea = All;
                    Editable = false;
                    MultiLine = true;
                    ToolTip = 'Specifies the last error encountered by the analysis.';
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
                Caption = 'Stop capture';
                ToolTip = 'Stop the profiler capture for this analysis immediately.';
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
            }
        }
    }

    var
        ConclusionText: Text;
        CanStopCapture: Boolean;
        CanRunAi: Boolean;
        CanChat: Boolean;
        CanCancel: Boolean;
        ChatEntryPointLbl: Label '>> Click here to chat with the analysis report <<';

    trigger OnAfterGetCurrRecord()
    var
        Ai: Codeunit "Perf. Analysis AI";
        AiAvailable: Boolean;
    begin
        AiAvailable := Ai.IsAvailable();
        Rec.CalcFields("Requested By User Name", "Target User Name");
        ConclusionText := Rec.GetConclusion();
        CanStopCapture := Rec."State" in [Rec."State"::Scheduled, Rec."State"::Capturing];
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
}
