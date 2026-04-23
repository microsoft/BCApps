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
                  tabledata "Performance Profile Scheduler" = R,
                  tabledata "Performance Profiles" = R;

    layout
    {
        area(Content)
        {
            group(Overview)
            {
                Caption = 'Overview';

                field("Title"; Rec."Title")
                {
                    Caption = 'Scenario';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the title of this performance analysis.';
                }
                field("State"; Rec."State")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the current state of the analysis.';
                }
                field(AnalysisReadyIn; MonitoringEndDisplayTxt)
                {
                    Caption = 'Monitoring end time';
                    Editable = false;
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the scheduled monitoring window finishes and the analysis becomes available.';
                }
                field(Detail; DetailText)
                {
                    Caption = 'Details';
                    Editable = false;
                    MultiLine = true;
                    ApplicationArea = All;
                    ToolTip = 'Explains in plain words what is happening for this analysis right now.';
                }
            }
            group(WhatIsSlow)
            {
                Caption = 'What is slow';
                field(WhatsSlow; WhatsSlowText)
                {
                    ShowCaption = false;
                    Editable = false;
                    MultiLine = true;
                    ExtendedDatatype = RichContent;
                    ApplicationArea = All;
                    ToolTip = 'Specifies the slow scenario described when this analysis was created.';
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
                    ExtendedDatatype = RichContent;
                    ApplicationArea = All;
                    ToolTip = 'Shows the AI-generated conclusion for this analysis.';
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
                    LocalAnalysis: Record "Performance Analysis";
                    Mgt: Codeunit "Perf. Analysis Mgt.";
                begin
                    if not LocalAnalysis.Get(Rec."Id") then
                        exit;
                    Mgt.StopCapture(LocalAnalysis);
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
                Caption = 'View relevant profiles';
                ToolTip = 'Show the performance profiles that the AI (or the user) has marked as relevant for this analysis.';
                Image = ViewDetails;
                ApplicationArea = All;

                trigger OnAction()
                begin
                    OpenRelevantProfiles();
                end;
            }
            action(ViewAllProfiles)
            {
                Caption = 'View all captured profiles';
                ToolTip = 'Show all the performance profiles that were captured for this analysis, whether marked as relevant or not.';
                Image = ViewDetails;
                ApplicationArea = All;

                trigger OnAction()
                begin
                    OpenAllCapturedProfiles();
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
            action(Reanalyze)
            {
                Caption = 'Reanalyze';
                ToolTip = 'Run the AI analysis again using the profiles that have already been captured.';
                Image = Refresh;
                ApplicationArea = All;
                Enabled = CanReanalyze;

                trigger OnAction()
                var
                    LocalAnalysis: Record "Performance Analysis";
                    Mgt: Codeunit "Perf. Analysis Mgt.";
                begin
                    if not LocalAnalysis.Get(Rec."Id") then
                        exit;
                    Mgt.Reanalyze(LocalAnalysis);
                    CurrPage.Update(false);
                end;
            }
            action(OpenLlmLog)
            {
                Caption = 'LLM debug log';
                ToolTip = 'Show the LLM calls made for this performance analysis, with the full prompt, response, and error for troubleshooting.';
                Image = Log;
                ApplicationArea = All;

                trigger OnAction()
                var
                    Log: Record "Perf. Analysis LLM Log";
                    LogsPage: Page "Perf. Analysis LLM Logs";
                begin
                    Log.SetRange("Analysis Id", Rec."Id");
                    LogsPage.SetTableView(Log);
                    LogsPage.Run();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';
                actionref(StopCapture_Promoted; StopCapture) { }
                actionref(RelatedSchedule_Promoted; RelatedSchedule) { }
                actionref(ChatWithReport_Promoted; ChatWithReport) { }
                actionref(Reanalyze_Promoted; Reanalyze) { }
            }
        }
    }

    var
        ConclusionText: Text;
        WhatsSlowText: Text;
        AnalysisReadyInTxt: Text;
        MonitoringEndDisplayTxt: Text;
        DetailText: Text;
        CanStopCapture: Boolean;
        CanChat: Boolean;
        CanReanalyze: Boolean;
        HasRelatedSchedule: Boolean;
        RelatedScheduleLinkLbl: Label '>> Click here to open the profiler schedule <<';
        ReadyLbl: Label '(monitoring done)';
        AnyMomentLbl: Label 'Any moment now';
        UnknownReadyLbl: Label '—', Locked = true;
        InPrefixFmtLbl: Label 'in %1', Comment = '%1 = remaining duration, e.g. "2 hours and 15 minutes"';

    trigger OnAfterGetCurrRecord()
    var
        Scheduler: Record "Performance Profile Scheduler";
        Ai: Codeunit "Perf. Analysis AI";
        AiAvailable: Boolean;
        ScheduleActive: Boolean;
    begin
        AiAvailable := Ai.IsAvailable();
        Rec.CalcFields("Requested By User Name", "Target User Name");
        ConclusionText := ConclusionToHtml(Rec.GetConclusion());
        WhatsSlowText := BuildWhatsSlow();
        AnalysisReadyInTxt := ComputeReadyInText();
        MonitoringEndDisplayTxt := ComputeMonitoringEndDisplayText();
        DetailText := BuildDetailText();
        HasRelatedSchedule := not IsNullGuid(Rec."Related Schedule Id");
        ScheduleActive := HasRelatedSchedule and Scheduler.Get(Rec."Related Schedule Id")
            and Scheduler.Enabled
            and ((Scheduler."Ending Date-Time" = 0DT) or (Scheduler."Ending Date-Time" > CurrentDateTime()));
        // Stopping monitoring only makes sense while the underlying profiler schedule is
        // still collecting. Once the schedule is disabled or its ending time has passed
        // there is nothing to stop - the monitor will transition the analysis to
        // CaptureEnded.
        CanStopCapture := (Rec."State" in [Rec."State"::Scheduled, Rec."State"::Capturing]) and ScheduleActive;
        CanChat := AiAvailable and (Rec."State" = Rec."State"::Concluded);
        CanReanalyze := AiAvailable and (Rec."State" in [Rec."State"::Concluded, Rec."State"::Failed]);
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

    local procedure OpenRelevantProfiles()
    var
        Line: Record "Performance Analysis Line";
        Profile: Record "Performance Profiles";
        FilterTxt: Text;
        NoRelevantProfilesErr: Label 'There are no profiles marked as relevant for this analysis yet.';
    begin
        Line.SetRange("Analysis Id", Rec."Id");
        Line.SetRange("Marked Relevant", true);
        if Line.FindSet() then
            repeat
                if Line."Profile ID" <> 0 then begin
                    if FilterTxt <> '' then
                        FilterTxt += '|';
                    FilterTxt += Format(Line."Profile ID", 0, 9);
                end;
            until Line.Next() = 0;
        if FilterTxt = '' then
            Error(NoRelevantProfilesErr);
        Profile.SetFilter("Profile ID", FilterTxt);
        Page.Run(Page::"Performance Profile List", Profile);
    end;

    local procedure OpenAllCapturedProfiles()
    var
        Line: Record "Performance Analysis Line";
        Profile: Record "Performance Profiles";
        FilterTxt: Text;
        NoCapturedProfilesErr: Label 'No profiles have been captured for this analysis yet.';
    begin
        Line.SetRange("Analysis Id", Rec."Id");
        if Line.FindSet() then
            repeat
                if Line."Profile ID" <> 0 then begin
                    if FilterTxt <> '' then
                        FilterTxt += '|';
                    FilterTxt += Format(Line."Profile ID", 0, 9);
                end;
            until Line.Next() = 0;
        if FilterTxt = '' then
            Error(NoCapturedProfilesErr);
        Profile.SetFilter("Profile ID", FilterTxt);
        Page.Run(Page::"Performance Profile List", Profile);
    end;

    local procedure BuildDetailText() Detail: Text
    var
        FocusLbl: Label 'action "%1" on page "%2"', Comment = '%1 = action/field name, %2 = page name';
        PageOnlyLbl: Label 'page "%1"', Comment = '%1 = page name';
        GenericFocusLbl: Label 'the reported scenario';
        MonitoringLbl: Label 'The system is monitoring %1''s actions for the next %2, with focus on %3. Hopefully, in this period, the performance problem will happen again, which enables us to analyze it.', Comment = '%1 = user name, %2 = remaining monitoring time, %3 = focus area';
        CaptureEndedLbl: Label 'Monitoring has finished. Captured profiles will be sent to the AI for analysis shortly.';
        AiFilteringLbl: Label 'The AI is reviewing captured profiles to pick the ones most relevant to the reported scenario.';
        AiAnalyzingLbl: Label 'The AI is analyzing the captured profiles and drafting a conclusion.';
        ConcludedLbl: Label 'The analysis is ready. See the Conclusion section below for the AI''s findings.';
        CancelledLbl: Label 'This analysis was cancelled before it could complete.';
        FailedLbl: Label 'The analysis failed. See the Error details section below for more information.';
        RequestedLbl: Label 'The analysis has been requested. Monitoring will start shortly.';
        Focus: Text;
        UserName: Text;
        ActionName: Text;
        ObjectName: Text;
    begin
        case Rec."State" of
            Rec."State"::Requested:
                Detail := RequestedLbl;
            Rec."State"::Scheduled, Rec."State"::Capturing:
                begin
                    ActionName := EscapeForDisplay(Rec."Trigger Action Name");
                    ObjectName := EscapeForDisplay(Rec."Trigger Object Name");
                    if (ActionName <> '') and (ObjectName <> '') then
                        Focus := StrSubstNo(FocusLbl, ActionName, ObjectName)
                    else
                        if ObjectName <> '' then
                            Focus := StrSubstNo(PageOnlyLbl, ObjectName)
                        else
                            Focus := GenericFocusLbl;
                    UserName := Rec."Target User Name";
                    if UserName = '' then
                        UserName := Rec."Requested By User Name";
                    UserName := EscapeForDisplay(UserName);
                    Detail := StrSubstNo(MonitoringLbl, UserName, AnalysisReadyInTxt, Focus);
                end;
            Rec."State"::CaptureEnded:
                Detail := CaptureEndedLbl;
            Rec."State"::AiFiltering:
                Detail := AiFilteringLbl;
            Rec."State"::AiAnalyzing:
                Detail := AiAnalyzingLbl;
            Rec."State"::Concluded:
                Detail := ConcludedLbl;
            Rec."State"::Cancelled:
                Detail := CancelledLbl;
            Rec."State"::Failed:
                Detail := FailedLbl;
        end;
    end;

    local procedure EscapeForDisplay(Value: Text): Text
    begin
        // The multiline text renderer in the web client interprets backslashes as
        // line breaks (and doubling them does not help). Swap each ASCII backslash
        // for the visually similar fullwidth reverse solidus (U+FF3C) so DOMAIN\user
        // displays on a single line as DOMAIN＼user.
        exit(Value.Replace('\', '＼'));
    end;

    local procedure BuildWhatsSlow(): Text
    var
        ActionLbl: Label 'Action: %1', Comment = '%1 = action, button or field name';
        OnPageLbl: Label 'While on page: %1', Comment = '%1 = name of the page or screen, in angle brackets';
        DurationLbl: Label 'It shouldn''t take more than %1 ms.', Comment = '%1 = expected duration in ms';
        FrequencyLbl: Label 'Frequency: This happens %1.', Comment = '%1 = frequency phrase lowercased, e.g. "every time I do the action"';
        NotesHeaderLbl: Label 'Notes:';
        Builder: TextBuilder;
        FreqText: Text;
        NotesText: Text;
    begin
        Builder.Append('<div>');
        if Rec."Trigger Action Name" <> '' then
            Builder.Append('<div>' + HtmlEscape(StrSubstNo(ActionLbl, EndWithPeriod(Rec."Trigger Action Name"))) + '</div>');
        if Rec."Trigger Object Name" <> '' then
            Builder.Append('<div>' + HtmlEscape(StrSubstNo(OnPageLbl, '<' + Rec."Trigger Object Name" + '>')) + '</div>');
        if Rec."Expected Duration (ms)" > 0 then
            Builder.Append('<div>' + HtmlEscape(StrSubstNo(DurationLbl, Rec."Expected Duration (ms)")) + '</div>');
        FreqText := LowerFirst(Format(Rec."Frequency"));
        Builder.Append('<div>' + HtmlEscape(StrSubstNo(FrequencyLbl, FreqText)) + '</div>');
        NotesText := Rec."Notes";
        if NotesText <> '' then begin
            Builder.Append('<div>&nbsp;</div>');
            Builder.Append('<div>' + HtmlEscape(NotesHeaderLbl) + '</div>');
            Builder.Append('<div>' + NotesToHtml(NotesText) + '</div>');
        end;
        Builder.Append('</div>');
        exit(Builder.ToText());
    end;

    local procedure NotesToHtml(Input: Text): Text
    var
        Crlf: Text[2];
        Lf: Text[1];
        Escaped: Text;
    begin
        Crlf[1] := 13;
        Crlf[2] := 10;
        Lf[1] := 10;
        Escaped := HtmlEscape(Input);
        Escaped := Escaped.Replace(Crlf, '<br>');
        Escaped := Escaped.Replace(Lf, '<br>');
        exit(Escaped);
    end;

    local procedure ConclusionToHtml(Input: Text): Text
    var
        Lines: List of [Text];
        Line: Text;
        Trim: Text;
        Rest: Text;
        Builder: TextBuilder;
        ParaBuffer: Text;
        Crlf: Text[2];
        Lf: Text[1];
        InList: Boolean;
    begin
        if Input = '' then
            exit('');
        Crlf[1] := 13;
        Crlf[2] := 10;
        Lf[1] := 10;
        Input := Input.Replace(Crlf, Lf);
        Lines := Input.Split(Lf);
        InList := false;

        foreach Line in Lines do begin
            Trim := Line.TrimStart();
            if StartsWithMarker(Trim, '- ', Rest) then begin
                if not InList then begin
                    FlushParagraph(Builder, ParaBuffer);
                    Builder.Append('<ul>');
                    InList := true;
                end;
                Builder.Append('<li>' + ApplyInlineMarkdown(Rest) + '</li>');
            end else begin
                if InList then begin
                    Builder.Append('</ul>');
                    InList := false;
                end;
                if StartsWithMarker(Trim, '#### ', Rest) then begin
                    FlushParagraph(Builder, ParaBuffer);
                    Builder.Append('<h4>' + ApplyInlineMarkdown(Rest) + '</h4>');
                end else
                    if StartsWithMarker(Trim, '### ', Rest) then begin
                        FlushParagraph(Builder, ParaBuffer);
                        Builder.Append('<h3>' + ApplyInlineMarkdown(Rest) + '</h3>');
                    end else
                        if StartsWithMarker(Trim, '## ', Rest) then begin
                            FlushParagraph(Builder, ParaBuffer);
                            Builder.Append('<h2>' + ApplyInlineMarkdown(Rest) + '</h2>');
                        end else
                            if StartsWithMarker(Trim, '# ', Rest) then
                                FlushParagraph(Builder, ParaBuffer)
                            else
                                if Trim = '' then
                                    FlushParagraph(Builder, ParaBuffer)
                                else begin
                                    if ParaBuffer <> '' then
                                        ParaBuffer += ' ';
                                    ParaBuffer += Trim;
                                end;
            end;
        end;
        if InList then
            Builder.Append('</ul>');
        FlushParagraph(Builder, ParaBuffer);
        exit(Builder.ToText());
    end;

    local procedure StartsWithMarker(Line: Text; Marker: Text; var Rest: Text): Boolean
    begin
        if StrLen(Line) <= StrLen(Marker) then
            exit(false);
        if CopyStr(Line, 1, StrLen(Marker)) <> Marker then
            exit(false);
        Rest := CopyStr(Line, StrLen(Marker) + 1);
        exit(true);
    end;

    local procedure FlushParagraph(var Builder: TextBuilder; var ParaBuffer: Text)
    begin
        if ParaBuffer = '' then
            exit;
        Builder.Append('<p>' + ApplyInlineMarkdown(ParaBuffer) + '</p>');
        ParaBuffer := '';
    end;

    local procedure ApplyInlineMarkdown(Input: Text): Text
    var
        Escaped: Text;
    begin
        Escaped := HtmlEscape(Input);
        Escaped := ToggleWrap(Escaped, '**', '<strong>', '</strong>');
        Escaped := ToggleWrap(Escaped, '`', '<code>', '</code>');
        exit(Escaped);
    end;

    local procedure ToggleWrap(Input: Text; Delim: Text; OpenTag: Text; CloseTag: Text) Output: Text
    var
        IdxInt: Integer;
        Open: Boolean;
    begin
        Output := Input;
        IdxInt := Output.IndexOf(Delim);
        while IdxInt > 0 do begin
            if Open then
                Output := CopyStr(Output, 1, IdxInt - 1) + CloseTag + CopyStr(Output, IdxInt + StrLen(Delim))
            else
                Output := CopyStr(Output, 1, IdxInt - 1) + OpenTag + CopyStr(Output, IdxInt + StrLen(Delim));
            Open := not Open;
            IdxInt := Output.IndexOf(Delim);
        end;
        // If we had an unmatched opening delimiter, we already swallowed it; reality of
        // LLM output is that delimiters are typically matched, so we accept the edge case.
    end;

    local procedure EndWithPeriod(Input: Text): Text
    begin
        if Input = '' then
            exit(Input);
        if Input.EndsWith('.') or Input.EndsWith('!') or Input.EndsWith('?') then
            exit(Input);
        exit(Input + '.');
    end;

    local procedure LowerFirst(Input: Text): Text
    begin
        if Input = '' then
            exit(Input);
        exit(LowerCase(CopyStr(Input, 1, 1)) + CopyStr(Input, 2));
    end;

    local procedure HtmlEscape(Input: Text): Text
    begin
        Input := Input.Replace('&', '&amp;');
        Input := Input.Replace('<', '&lt;');
        Input := Input.Replace('>', '&gt;');
        Input := Input.Replace('"', '&quot;');
        Input := Input.Replace('''', '&#39;');
        exit(Input);
    end;

    local procedure ComputeReadyInText(): Text
    var
        RemainingMs: BigInteger;
    begin
        if Rec."State" in [Rec."State"::Concluded, Rec."State"::Cancelled, Rec."State"::Failed] then
            exit(ReadyLbl);
        if Rec."State" in [Rec."State"::CaptureEnded, Rec."State"::AiFiltering, Rec."State"::AiAnalyzing] then
            exit(ReadyLbl);
        if Rec."Monitoring Ends At" = 0DT then
            exit(UnknownReadyLbl);
        RemainingMs := Rec."Monitoring Ends At" - CurrentDateTime();
        if RemainingMs <= 0 then
            exit(AnyMomentLbl);
        exit(FormatDuration(RemainingMs));
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
            Parts[Count] := StrSubstNo(UnitFmtLbl, Days, ReadyUnit(Days, DaySingularLbl, DayPluralLbl));
        end;
        if Hours > 0 then begin
            Count += 1;
            Parts[Count] := StrSubstNo(UnitFmtLbl, Hours, ReadyUnit(Hours, HourSingularLbl, HourPluralLbl));
        end;
        if Minutes > 0 then begin
            Count += 1;
            Parts[Count] := StrSubstNo(UnitFmtLbl, Minutes, ReadyUnit(Minutes, MinuteSingularLbl, MinutePluralLbl));
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

    local procedure ReadyUnit(Value: BigInteger; SingularLbl: Text; PluralLbl: Text): Text
    begin
        if Value = 1 then
            exit(SingularLbl);
        exit(PluralLbl);
    end;
}
