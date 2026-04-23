// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

using System.AI;
using System.PerformanceProfile;

/// <summary>
/// All AI entry points for the Performance Center: filter the captured profiles, analyze
/// the scenario, and back the chat on a concluded analysis. Every entry point checks that
/// the "AI-assisted performance analysis in Performance Center" Copilot capability is
/// active and hard-fails with a friendly message when it is not.
/// </summary>
codeunit 8416 "Perf. Analysis AI"
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "Performance Analysis" = RIM,
                  tabledata "Performance Analysis Line" = RIMD,
                  tabledata "Performance Profile Scheduler" = R,
                  tabledata "Performance Profiles" = R,
                  tabledata "Perf. Analysis LLM Log" = RIM;

    var
        LastError: Text;
        SystemPromptLbl: Label 'You are a Dynamics 365 Business Central performance expert. The user has reported a slow scenario and we have captured one or more sampling performance profiles while the user reproduced it. Your job is to explain why the scenario is sometimes slow, grounded in the captured profiles and the user''s description. Be specific, be concise, and give guidance that a Business Central end user or developer can act on. If the data is inconclusive, say so plainly.';
        FilterSystemPromptLbl: Label 'You are a Dynamics 365 Business Central performance expert. Profiler traces were captured for a user over a monitoring window. The user has told us exactly which scenario they want analyzed (the target user, the page, and the specific action or field they interacted with). Your job is to decide, for each captured profile, whether that profile captures the user actually performing that scenario. You are NOT judging whether a profile is "interesting" or "slow" - only whether it represents the requested scenario being reproduced. Profiles captured while the user was doing something else on the same page, navigating between pages, or idling, are not relevant even if they happened during the monitoring window.';
        FilterInstructionLbl: Label 'Decide relevance by comparing each profile''s description against the scenario the user described. All profiles belong to the same target user, so do not consider who captured them. A profile is relevant only if its description plausibly represents the scenario being reproduced. Do not base relevance on duration or any other performance characteristic - those are for the later analysis step. Respond with a JSON array of integers listing the ProfileNo values of the relevant profiles (for example [1,3,4]). Respond with JSON only, no explanation and no extra fields.';
        AnalysisInstructionLbl: Label 'You will receive a Markdown document describing a slow scenario under ''## Observations by the user'' (when it is slow, the expected duration, free-form notes) followed by the captured profiles under ''## Captured profiles''. Each profile is introduced by a ''Profile N'' header, followed by plain-text bullet lines with the profile''s metadata (starting time, activity description, activity and sampling durations, SQL and HTTP counts), followed by ''- Profile payload:'' and the raw JSON sampling profile captured while the user reproduced the scenario. IMPORTANT - how to read the payload: (1) The payload comes from a SAMPLING profiler. A function''s hit count is the number of samples observed inside that function, NOT the number of times the function was called. Treat hit counts as a measure of time spent in a code path, not as a call count. Do not say ''X was called N times'' based on hit counts. (2) Ignore IdleTime in the payload completely. IdleTime represents time the server was waiting outside the operation itself (between requests, waiting for the next user interaction, parked, etc.) and is never experienced by the user as slowness. Do not mention IdleTime anywhere in the conclusion. Focus only on SQL, HTTP, and CPU-bound work that happens between when the user triggered the action and when the response was returned. IMPORTANT - how to refer to profiles in the conclusion: The ''Profile N'' numbering is an internal detail and is not visible to the end user. Do not write ''Profile 1'', ''Profile 2'', ''Profiles 3 and 5'', etc. If you need to point to a specific captured profile, refer to it by its ''Starting at'' timestamp (for example ''the capture at 2026-04-22 09:35:12''). Analyze why the scenario is sometimes slow and produce a conclusion in Markdown. Do not include a top-level ''# '' heading - start directly with five ''## '' sections in this order: ''## Summary'', ''## Where time is spent'', ''## Most likely root cause'', ''## Why the scenario varies'', ''## Recommended next steps''. Within each section use short paragraphs and ''- '' bullet lists where appropriate, and use **bold** to emphasize key findings. Recommendations should be actionable for either an end user or a developer. Do not invent data that is not in the payload.';
        ChatInstructionLbl: Label 'You are now in follow-up mode. The user is asking a question about the scenario and conclusion above. Answer the question directly and in full, in Markdown, grounded in the scenario, the captured profiles, and your prior conclusion. If the question cannot be answered from that context, say so explicitly and explain what additional data would be needed. Do not restate the conclusion unless the user asks for it.';
        CapabilityNotActiveErr: Label 'The Copilot capability "AI-assisted performance analysis in Performance Center" is not active in this environment. Enable it in the Copilot & AI capabilities page to use AI-assisted analysis.';
        AuthNotConfiguredErr: Label 'Azure OpenAI is not configured for this environment.';

    /// <summary>
    /// Ensures the capability is active and (in SaaS) authorization is configured.
    /// </summary>
    procedure EnsureAvailable()
    var
        AzureOpenAI: Codeunit "Azure OpenAI";
        AOAIDeployments: Codeunit "AOAI Deployments";
    begin
        if not AzureOpenAI.IsEnabled(Enum::"Copilot Capability"::"Performance Center", true) then
            Error(CapabilityNotActiveErr);
        AzureOpenAI.SetAuthorization(Enum::"AOAI Model Type"::"Chat Completions", AOAIDeployments.GetGPT41Latest());
        if not AzureOpenAI.IsAuthorizationConfigured(Enum::"AOAI Model Type"::"Chat Completions") then
            Error(AuthNotConfiguredErr);
    end;

    /// <summary>
    /// Returns true if the capability is active (silent).
    /// </summary>
    procedure IsAvailable(): Boolean
    var
        AzureOpenAI: Codeunit "Azure OpenAI";
    begin
        exit(AzureOpenAI.IsEnabled(Enum::"Copilot Capability"::"Performance Center", true));
    end;

    /// <summary>
    /// Loads captured profiles into analysis lines and asks the AI which are relevant.
    /// </summary>
    /// <returns>True if the filter step completed; false sets LastError.</returns>
    procedure FilterProfiles(var Analysis: Record "Performance Analysis"): Boolean
    var
        Messages: Codeunit "AOAI Chat Messages";
        Response: Codeunit "AOAI Operation Response";
        AzureOpenAI: Codeunit "Azure OpenAI";
        Payload: Text;
        Reply: Text;
        RawResponse: Text;
        Err: Text;
        Success: Boolean;
        StatusCode: Integer;
        DurationMs: Integer;
    begin
        LastError := '';
        ClearProfileLines(Analysis);
        if not LoadProfilesToLines(Analysis) then begin
            Analysis."Profiles Captured" := 0;
            Analysis."Profiles Relevant" := 0;
            Analysis.Modify(true);
            exit(true); // No profiles captured - nothing to filter, still a valid completion.
        end;

        if not TryPrepareClient(AzureOpenAI) then
            exit(false);

        Payload := BuildFilterPayload(Analysis);
        Messages.AddSystemMessage(FilterSystemPromptLbl);
        Messages.AddSystemMessage(FilterInstructionLbl);
        Messages.AddUserMessage(Payload);

        if not TryChat(AzureOpenAI, Messages, Response, Reply, RawResponse, Success, StatusCode, Err, DurationMs) then begin
            LogLlmCall(Enum::"Perf. Analysis LLM Purpose"::Filter, Analysis, BuildRawRequest(FilterSystemPromptLbl, FilterInstructionLbl, Payload), RawResponse, Reply, false, StatusCode, GetLastErrorText(), DurationMs);
            LastError := GetLastErrorText();
            exit(false);
        end;
        LogLlmCall(Enum::"Perf. Analysis LLM Purpose"::Filter, Analysis, BuildRawRequest(FilterSystemPromptLbl, FilterInstructionLbl, Payload), RawResponse, Reply, Success, StatusCode, Err, DurationMs);
        if not Success then begin
            LastError := Err;
            exit(false);
        end;

        ApplyFilterReply(Analysis, Reply);
        exit(true);
    end;

    /// <summary>
    /// Produces the analysis conclusion and stores it on the analysis record. Loads the
    /// captured profiles from the associated profiler schedule into the analysis lines,
    /// builds an LLM prompt that includes the user's scenario details (expected duration,
    /// notes, trigger, frequency) and the captured profile metrics, and asks AOAI for a
    /// natural-language conclusion.
    /// </summary>
    procedure Analyze(var Analysis: Record "Performance Analysis"): Boolean
    var
        Messages: Codeunit "AOAI Chat Messages";
        Response: Codeunit "AOAI Operation Response";
        AzureOpenAI: Codeunit "Azure OpenAI";
        Line: Record "Performance Analysis Line";
        Reply: Text;
        Payload: Text;
        RawResponse: Text;
        Err: Text;
        Success: Boolean;
        StatusCode: Integer;
        DurationMs: Integer;
    begin
        LastError := '';
        // If lines have not been loaded yet (filter step was skipped) populate them so
        // BuildAnalysisPayload has something to work with. Do not wipe existing lines -
        // the filter step's "Marked Relevant" markings must survive into analysis.
        Line.SetRange("Analysis Id", Analysis."Id");
        if Line.IsEmpty() then
            if LoadProfilesToLines(Analysis) then;
        if not TryPrepareClient(AzureOpenAI) then
            exit(false);

        Payload := BuildAnalysisPayload(Analysis);
        Messages.AddSystemMessage(SystemPromptLbl);
        Messages.AddSystemMessage(AnalysisInstructionLbl);
        Messages.AddUserMessage(Payload);

        if not TryChat(AzureOpenAI, Messages, Response, Reply, RawResponse, Success, StatusCode, Err, DurationMs) then begin
            LogLlmCall(Enum::"Perf. Analysis LLM Purpose"::Analyze, Analysis, BuildRawRequest(SystemPromptLbl, AnalysisInstructionLbl, Payload), RawResponse, Reply, false, StatusCode, GetLastErrorText(), DurationMs);
            LastError := GetLastErrorText();
            exit(false);
        end;
        LogLlmCall(Enum::"Perf. Analysis LLM Purpose"::Analyze, Analysis, BuildRawRequest(SystemPromptLbl, AnalysisInstructionLbl, Payload), RawResponse, Reply, Success, StatusCode, Err, DurationMs);
        if not Success then begin
            LastError := Err;
            exit(false);
        end;

        Analysis.SetConclusion(BuildConclusionPreface(Analysis) + Reply);
        Analysis."Ai Model" := CopyStr('azure-openai-chat', 1, MaxStrLen(Analysis."Ai Model"));
        Analysis.Modify(true);
        exit(true);
    end;

    local procedure BuildConclusionPreface(var Analysis: Record "Performance Analysis"): Text
    var
        NL: Text[2];
        UserName: Text;
        ActionName: Text;
        StartText: Text;
        EndText: Text;
        WithUserAndActionLbl: Label 'Analyzed %1''s action "%2" between %3 and %4. Captured %5 profile(s), selected %6 as relevant.', Comment = '%1 target user name, %2 trigger action name, %3 monitoring start, %4 monitoring end, %5 profiles captured, %6 profiles relevant';
        WithUserLbl: Label 'Analyzed %1''s session between %2 and %3. Captured %4 profile(s), selected %5 as relevant.', Comment = '%1 target user name, %2 monitoring start, %3 monitoring end, %4 profiles captured, %5 profiles relevant';
        WithActionLbl: Label 'Analyzed action "%1" between %2 and %3. Captured %4 profile(s), selected %5 as relevant.', Comment = '%1 trigger action name, %2 monitoring start, %3 monitoring end, %4 profiles captured, %5 profiles relevant';
        FallbackLbl: Label 'Analyzed the scenario between %1 and %2. Captured %3 profile(s), selected %4 as relevant.', Comment = '%1 monitoring start, %2 monitoring end, %3 profiles captured, %4 profiles relevant';
    begin
        NL[1] := 13;
        NL[2] := 10;
        Analysis.CalcFields("Target User Name");
        UserName := Analysis."Target User Name";
        ActionName := Analysis."Trigger Action Name";
        StartText := FormatDateTimeForPreface(Analysis."Monitoring Starts At");
        EndText := FormatDateTimeForPreface(Analysis."Monitoring Ends At");

        case true of
            (UserName <> '') and (ActionName <> ''):
                exit(StrSubstNo(WithUserAndActionLbl, UserName, ActionName, StartText, EndText, Analysis."Profiles Captured", Analysis."Profiles Relevant") + NL + NL);
            UserName <> '':
                exit(StrSubstNo(WithUserLbl, UserName, StartText, EndText, Analysis."Profiles Captured", Analysis."Profiles Relevant") + NL + NL);
            ActionName <> '':
                exit(StrSubstNo(WithActionLbl, ActionName, StartText, EndText, Analysis."Profiles Captured", Analysis."Profiles Relevant") + NL + NL);
            else
                exit(StrSubstNo(FallbackLbl, StartText, EndText, Analysis."Profiles Captured", Analysis."Profiles Relevant") + NL + NL);
        end;
    end;

    local procedure FormatDateTimeForPreface(Dt: DateTime): Text
    var
        UnknownLbl: Label '(unknown)';
    begin
        if Dt = 0DT then
            exit(UnknownLbl);
        exit(Format(Dt));
    end;

    local procedure BuildRawRequest(SystemPrompt: Text; Instruction: Text; UserPayload: Text) Combined: Text
    var
        Newline: Text[2];
    begin
        Newline[1] := 13;
        Newline[2] := 10;
        Combined :=
            '# System message' + Newline + SystemPrompt + Newline + Newline +
            '# Instruction' + Newline + Instruction + Newline + Newline +
            '# User message' + Newline + UserPayload;
    end;

    /// <summary>
    /// Answers a follow-up question about a concluded analysis. Builds a fresh prompt
    /// identical in spirit to the original analysis prompt but with the prior conclusion
    /// and the user's question appended, so each turn is independent. The caller (chat
    /// page) only displays the question and the reply.
    /// </summary>
    procedure AskAboutAnalysis(var Analysis: Record "Performance Analysis"; UserQuestion: Text): Text
    var
        Messages: Codeunit "AOAI Chat Messages";
        Response: Codeunit "AOAI Operation Response";
        AzureOpenAI: Codeunit "Azure OpenAI";
        Reply: Text;
        ContextMessage: Text;
        RawResponse: Text;
        Err: Text;
        Success: Boolean;
        StatusCode: Integer;
        DurationMs: Integer;
        ContextHeaderLbl: Label '# Context for the follow-up question', Locked = true;
        ConclusionHeaderLbl: Label '## Prior conclusion', Locked = true;
        Newline: Text[2];
    begin
        LastError := '';
        if not TryPrepareClient(AzureOpenAI) then
            exit('');
        Newline[1] := 13;
        Newline[2] := 10;
        ClearProfileLines(Analysis);
        if LoadProfilesToLines(Analysis) then;
        ContextMessage :=
            ContextHeaderLbl + Newline + Newline +
            BuildAnalysisPayload(Analysis) + Newline + Newline +
            ConclusionHeaderLbl + Newline + Newline +
            Analysis.GetConclusion();
        Messages.AddSystemMessage(SystemPromptLbl);
        Messages.AddSystemMessage(ContextMessage);
        Messages.AddSystemMessage(ChatInstructionLbl);
        Messages.AddUserMessage(UserQuestion);
        if not TryChat(AzureOpenAI, Messages, Response, Reply, RawResponse, Success, StatusCode, Err, DurationMs) then begin
            LogLlmCall(Enum::"Perf. Analysis LLM Purpose"::Chat, Analysis, BuildRawRequest(SystemPromptLbl, ContextMessage + Newline + Newline + ChatInstructionLbl, UserQuestion), RawResponse, Reply, false, StatusCode, GetLastErrorText(), DurationMs);
            LastError := GetLastErrorText();
            exit('');
        end;
        LogLlmCall(Enum::"Perf. Analysis LLM Purpose"::Chat, Analysis, BuildRawRequest(SystemPromptLbl, ContextMessage + Newline + Newline + ChatInstructionLbl, UserQuestion), RawResponse, Reply, Success, StatusCode, Err, DurationMs);
        if not Success then begin
            LastError := Err;
            exit('');
        end;
        exit(Reply);
    end;

    procedure GetLastError(): Text
    begin
        exit(LastError);
    end;

    local procedure TryPrepareClient(var AzureOpenAI: Codeunit "Azure OpenAI"): Boolean
    var
        AOAIDeployments: Codeunit "AOAI Deployments";
    begin
        AzureOpenAI.SetCopilotCapability(Enum::"Copilot Capability"::"Performance Center");
        if not AzureOpenAI.IsEnabled(Enum::"Copilot Capability"::"Performance Center", true) then begin
            LastError := CapabilityNotActiveErr;
            exit(false);
        end;
        AzureOpenAI.SetAuthorization(Enum::"AOAI Model Type"::"Chat Completions", AOAIDeployments.GetGPT41Latest());
        if not AzureOpenAI.IsAuthorizationConfigured(Enum::"AOAI Model Type"::"Chat Completions") then begin
            LastError := AuthNotConfiguredErr;
            exit(false);
        end;
        exit(true);
    end;

    [TryFunction]
    local procedure TryChat(var AzureOpenAI: Codeunit "Azure OpenAI"; var Messages: Codeunit "AOAI Chat Messages"; var Response: Codeunit "AOAI Operation Response"; var Reply: Text; var RawResponse: Text; var Success: Boolean; var StatusCode: Integer; var Err: Text; var DurationMs: Integer)
    var
        StartedAt: DateTime;
    begin
        StartedAt := CurrentDateTime();
        AzureOpenAI.GenerateChatCompletion(Messages, Response);
        DurationMs := CurrentDateTime() - StartedAt;
        RawResponse := Response.GetResult();
        Success := Response.IsSuccess();
        StatusCode := Response.GetStatusCode();
        if Success then
            Reply := ExtractAssistantContent(RawResponse)
        else begin
            Reply := '';
            Err := Response.GetError();
        end;
    end;

    local procedure LogLlmCall(Purpose: Enum "Perf. Analysis LLM Purpose"; var Analysis: Record "Performance Analysis"; RawRequest: Text; RawResponse: Text; Reply: Text; Success: Boolean; StatusCode: Integer; ErrorText: Text; DurationMs: Integer)
    var
        Log: Record "Perf. Analysis LLM Log";
    begin
        Log.Init();
        Log."Analysis Id" := Analysis."Id";
        Log."Purpose" := Purpose;
        Log."Logged At" := CurrentDateTime();
        Log."Duration (ms)" := DurationMs;
        Log."Success" := Success;
        Log."Status Code" := StatusCode;
        Log."Error Text" := CopyStr(ErrorText, 1, MaxStrLen(Log."Error Text"));
        Log.Insert(true);
        Log.SetRawRequestText(RawRequest);
        Log.SetReplyText(Reply);
        Log.SetRawResponseText(RawResponse);
        Log.Modify();
    end;

    // GetResult() returns the assistant message as a JSON object, e.g.
    // {"role":"assistant","content":"...markdown with \u003E and \n escapes..."}.
    // Parse it and return the decoded "content" string so callers get plain text.
    local procedure ExtractAssistantContent(RawReply: Text): Text
    var
        Token: JsonToken;
        ContentToken: JsonToken;
    begin
        if RawReply = '' then
            exit('');
        if not Token.ReadFrom(RawReply) then
            exit(RawReply);
        if not Token.IsObject() then
            exit(RawReply);
        if not Token.AsObject().Get('content', ContentToken) then
            exit(RawReply);
        if not ContentToken.IsValue() then
            exit(RawReply);
        exit(ContentToken.AsValue().AsText());
    end;

    local procedure ClearProfileLines(var Analysis: Record "Performance Analysis")
    var
        Line: Record "Performance Analysis Line";
    begin
        Line.SetRange("Analysis Id", Analysis."Id");
        Line.DeleteAll(true);
    end;

    local procedure LoadProfilesToLines(var Analysis: Record "Performance Analysis"): Boolean
    var
        Profile: Record "Performance Profiles";
        Line: Record "Performance Analysis Line";
        LineNo: Integer;
    begin
        if IsNullGuid(Analysis."Related Schedule Id") then
            exit(false);
        Profile.SetRange("Schedule ID", Analysis."Related Schedule Id");
        if not Profile.FindSet() then
            exit(false);
        LineNo := 0;
        repeat
            LineNo += 1;
            Line.Init();
            Line."Analysis Id" := Analysis."Id";
            Line."Line No." := LineNo;
            Line."Profile Schedule Id" := Profile."Schedule ID";
            Line."Profile Created At" := Profile.SystemCreatedAt;
            Line."Profile ID" := Profile."Profile ID";
            Line.Insert(true);
        until Profile.Next() = 0;
        Analysis."Profiles Captured" := LineNo;
        Analysis.Modify(true);
        exit(true);
    end;

    local procedure BuildFilterPayload(var Analysis: Record "Performance Analysis") Payload: Text
    var
        Profile: Record "Performance Profiles";
        PayloadObj: JsonObject;
        Profiles: JsonArray;
        ProfileObj: JsonObject;
        ProfileNo: Integer;
    begin
        // For filtering we want the model to see everything the user entered in the
        // wizard (so it understands what scenario to match) and the minimum profile
        // metadata needed to identify a match: the profile number (for the reply),
        // a description of what was captured, and the duration. User name is omitted
        // because all captured profiles are for the same target user, and the raw
        // trigger object / action fields are omitted because the scenario title and
        // activity already describe the scenario in natural language.
        PayloadObj.Add('scenario', BuildFilterScenarioJson(Analysis));
        if not IsNullGuid(Analysis."Related Schedule Id") then begin
            Profile.SetRange("Schedule ID", Analysis."Related Schedule Id");
            if Profile.FindSet() then
                repeat
                    ProfileNo += 1;
                    Clear(ProfileObj);
                    ProfileObj.Add('profileNo', ProfileNo);
                    ProfileObj.Add('description', Profile."Activity Description");
                    ProfileObj.Add('durationMs', Profile."Activity Duration");
                    Profiles.Add(ProfileObj);
                until Profile.Next() = 0;
        end;
        PayloadObj.Add('profiles', Profiles);
        PayloadObj.WriteTo(Payload);
    end;

    local procedure BuildFilterScenarioJson(var Analysis: Record "Performance Analysis") Scenario: JsonObject
    begin
        Scenario.Add('title', Analysis."Title");
        Scenario.Add('triggerObjectSystemName', Analysis."Trigger Object System Name");
        Scenario.Add('triggerActionSystemName', Analysis."Trigger Action System Name");
        Scenario.Add('frequency', Format(Analysis."Frequency"));
        Scenario.Add('expectedMs', Analysis."Expected Duration (ms)");
        Scenario.Add('notes', Analysis."Notes");
    end;

    local procedure BuildAnalysisPayload(var Analysis: Record "Performance Analysis") Payload: Text
    var
        Profile: Record "Performance Profiles";
        Line: Record "Performance Analysis Line";
        Sb: TextBuilder;
        ProfileNo: Integer;
        NL: Text[2];
        ScenarioHeaderLbl: Label '## Observations by the user';
        ProfilesHeaderLbl: Label '## Captured profiles';
        NoProfilesLbl: Label '(no profiles were captured for this scenario)';
        NoRelevantLbl: Label '(no captured profiles were considered relevant)';
        ProfileHeaderLbl: Label 'Profile %1', Comment = '%1 is the profile number';
        HasAnyLines: Boolean;
        HasRelevantLines: Boolean;
    begin
        NL[1] := 13;
        NL[2] := 10;

        Sb.Append(ScenarioHeaderLbl);
        Sb.Append(NL);
        AppendScenarioLines(Analysis, Sb, NL);
        Sb.Append(NL);

        Sb.Append(ProfilesHeaderLbl);
        Sb.Append(NL);

        Line.SetRange("Analysis Id", Analysis."Id");
        HasAnyLines := not Line.IsEmpty();
        Line.SetRange("Marked Relevant", true);
        HasRelevantLines := not Line.IsEmpty();

        if not IsNullGuid(Analysis."Related Schedule Id") then begin
            Profile.SetRange("Schedule ID", Analysis."Related Schedule Id");
            if Profile.FindSet() then
                repeat
                    ProfileNo += 1;
                    // Only include profiles flagged relevant by the filter step. If the
                    // filter step never ran (no lines at all), fall back to including
                    // everything so the analysis still has data to reason about.
                    if (not HasAnyLines) or IsProfileRelevant(Analysis."Id", ProfileNo) then begin
                        Sb.Append(NL);
                        Sb.Append(StrSubstNo(ProfileHeaderLbl, ProfileNo));
                        Sb.Append(NL);
                        AppendProfileLines(Profile, Sb, NL);
                    end;
                until Profile.Next() = 0;
        end;

        if ProfileNo = 0 then begin
            Sb.Append(NoProfilesLbl);
            Sb.Append(NL);
        end else
            if HasAnyLines and (not HasRelevantLines) then begin
                Sb.Append(NoRelevantLbl);
                Sb.Append(NL);
            end;

        Payload := Sb.ToText();
    end;

    local procedure IsProfileRelevant(AnalysisId: Guid; LineNo: Integer): Boolean
    var
        Line: Record "Performance Analysis Line";
    begin
        if not Line.Get(AnalysisId, LineNo) then
            exit(false);
        exit(Line."Marked Relevant");
    end;

    local procedure AppendScenarioLines(var Analysis: Record "Performance Analysis"; var Sb: TextBuilder; NL: Text[2])
    var
        FrequencyLbl: Label '- When is it slow: %1', Comment = '%1 is how often the scenario is slow';
        ExpectedLbl: Label '- Duration expected to be less than: %1 ms', Comment = '%1 is duration in milliseconds';
        NotesHeaderLbl: Label '- Notes:';
    begin
        Sb.Append(StrSubstNo(FrequencyLbl, Format(Analysis."Frequency")));
        Sb.Append(NL);
        Sb.Append(StrSubstNo(ExpectedLbl, Analysis."Expected Duration (ms)"));
        Sb.Append(NL);
        if Analysis."Notes" <> '' then begin
            Sb.Append(NotesHeaderLbl);
            Sb.Append(NL);
            Sb.Append('  ');
            Sb.Append(Analysis."Notes");
            Sb.Append(NL);
        end;
    end;

    local procedure AppendProfileLines(var Profile: Record "Performance Profiles"; var Sb: TextBuilder; NL: Text[2])
    var
        ProfileInStream: InStream;
        LineText: Text;
        StartingAtLbl: Label '- Starting at: %1', Comment = '%1 is the starting date-time';
        ActivityDescLbl: Label '- Activity description: %1', Comment = '%1 is the profile activity description';
        ActivityDurationLbl: Label '- Activity duration (ms): %1', Comment = '%1 activity duration';
        SamplingDurationLbl: Label '- Sampling duration (ms): %1', Comment = '%1 sampling duration';
        SqlLbl: Label '- SQL: %1 statement(s), %2 ms', Comment = '%1 sql statement count, %2 sql call duration';
        HttpLbl: Label '- HTTP: %1 call(s), %2 ms', Comment = '%1 http call count, %2 http call duration';
        PayloadLbl: Label '- Profile payload:';
    begin
        Sb.Append(StrSubstNo(StartingAtLbl, Format(Profile."Starting Date-Time", 0, 9)));
        Sb.Append(NL);
        Sb.Append(StrSubstNo(ActivityDescLbl, Profile."Activity Description"));
        Sb.Append(NL);
        Sb.Append(StrSubstNo(ActivityDurationLbl, Profile."Activity Duration"));
        Sb.Append(NL);
        Sb.Append(StrSubstNo(SamplingDurationLbl, Profile.Duration));
        Sb.Append(NL);
        Sb.Append(StrSubstNo(SqlLbl, Profile."Sql Statement Number", Profile."Sql Call Duration"));
        Sb.Append(NL);
        Sb.Append(StrSubstNo(HttpLbl, Profile."Http Call Number", Profile."Http Call Duration"));
        Sb.Append(NL);
        Sb.Append(PayloadLbl);
        Sb.Append(NL);

        Profile.CalcFields(Profile);
        if Profile.Profile.HasValue() then begin
            Profile.Profile.CreateInStream(ProfileInStream, TextEncoding::UTF8);
            while not ProfileInStream.EOS() do begin
                ProfileInStream.ReadText(LineText);
                Sb.Append(LineText);
                Sb.Append(NL);
            end;
        end;
    end;

    local procedure BuildScenarioJson(var Analysis: Record "Performance Analysis") Scenario: JsonObject
    begin
        Analysis.CalcFields("Target User Name");
        Scenario.Add('title', Analysis."Title");
        Scenario.Add('targetUserName', Analysis."Target User Name");
        Scenario.Add('activity', Format(Analysis."Scenario Activity Type"));
        Scenario.Add('trigger', Format(Analysis."Trigger Kind"));
        Scenario.Add('triggerObjectType', Format(Analysis."Trigger Object Type"));
        Scenario.Add('triggerObjectId', Analysis."Trigger Object Id");
        Scenario.Add('triggerObjectName', Analysis."Trigger Object Name");
        Scenario.Add('triggerActionName', Analysis."Trigger Action Name");
        Scenario.Add('frequency', Format(Analysis."Frequency"));
        Scenario.Add('expectedMs', Analysis."Expected Duration (ms)");
        Scenario.Add('notes', Analysis."Notes");
    end;

    local procedure ApplyFilterReply(var Analysis: Record "Performance Analysis"; Reply: Text)
    var
        Line: Record "Performance Analysis Line";
        Arr: JsonArray;
        Tok: JsonToken;
        Obj: JsonObject;
        ProfileNo: Integer;
        Relevant: Integer;
        I: Integer;
    begin
        // The model is asked to reply with a JSON array of integer profile numbers,
        // e.g. [1,3,4]. Be defensive and also accept older-style arrays of objects
        // with a profileNo field in case the model produces them.
        if not Arr.ReadFrom(ExtractJsonArray(Reply)) then
            exit;
        for I := 0 to Arr.Count() - 1 do begin
            Arr.Get(I, Tok);
            ProfileNo := 0;
            if Tok.IsValue() then
                ProfileNo := Tok.AsValue().AsInteger()
            else
                if Tok.IsObject() then begin
                    Obj := Tok.AsObject();
                    ProfileNo := ReadInt(Obj, 'profileNo');
                end;
            if ProfileNo > 0 then
                if Line.Get(Analysis."Id", ProfileNo) then begin
                    Line."Marked Relevant" := true;
                    Line."Ai Relevance Score" := 1;
                    Line.Modify(true);
                    Relevant += 1;
                end;
        end;
        Analysis."Profiles Relevant" := Relevant;
        Analysis.Modify(true);
    end;

    local procedure ExtractJsonArray(Reply: Text): Text
    var
        StartPos: Integer;
        EndPos: Integer;
    begin
        StartPos := StrPos(Reply, '[');
        EndPos := LastStrPos(Reply, ']');
        if (StartPos > 0) and (EndPos > StartPos) then
            exit(CopyStr(Reply, StartPos, EndPos - StartPos + 1));
        exit('[]');
    end;

    local procedure LastStrPos(Source: Text; SubString: Text): Integer
    var
        I: Integer;
        Pos: Integer;
    begin
        I := 1;
        while I <= StrLen(Source) do begin
            if CopyStr(Source, I, StrLen(SubString)) = SubString then
                Pos := I;
            I += 1;
        end;
        exit(Pos);
    end;

    local procedure ReadInt(Obj: JsonObject; Name: Text) Result: Integer
    var
        Tok: JsonToken;
    begin
        if Obj.Get(Name, Tok) then
            if Tok.IsValue() then
                Result := Tok.AsValue().AsInteger();
    end;

    local procedure ReadDec(Obj: JsonObject; Name: Text) Result: Decimal
    var
        Tok: JsonToken;
    begin
        if Obj.Get(Name, Tok) then
            if Tok.IsValue() then
                Result := Tok.AsValue().AsDecimal();
    end;

    local procedure ReadText(Obj: JsonObject; Name: Text) Result: Text
    var
        Tok: JsonToken;
    begin
        if Obj.Get(Name, Tok) then
            if Tok.IsValue() then
                Result := Tok.AsValue().AsText();
    end;
}
