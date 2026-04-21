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
        FilterInstructionLbl: Label 'For each captured profile, respond with a JSON array of objects with fields ProfileNo (integer), Relevance (0..1), Reason (short text). Mark profiles as relevant (>=0.5) only if they plausibly match the scenario. Respond with JSON only.';
        AnalysisInstructionLbl: Label 'You will receive a Markdown document describing the user''s slow scenario (title, activity, trigger, page/action, expected/observed duration, frequency, notes) followed by the captured profiles with their metrics (activity duration, AL execution duration, SQL statement count and duration, HTTP call count and duration). Analyze why the scenario is sometimes slow and produce a conclusion in Markdown. Do not include a top-level ''# '' heading - start directly with five ''## '' sections in this order: ''## Summary'', ''## Where time is spent'', ''## Most likely root cause'', ''## Why the scenario varies'', ''## Recommended next steps''. Within each section use short paragraphs and ''- '' bullet lists where appropriate, and use **bold** to emphasize key findings. Recommendations should be actionable for either an end user or a developer. Do not invent data that is not in the payload.';
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
        Messages.AddSystemMessage(SystemPromptLbl);
        Messages.AddSystemMessage(FilterInstructionLbl);
        Messages.AddUserMessage(Payload);

        if not TryChat(AzureOpenAI, Messages, Response, Reply, RawResponse, Success, StatusCode, Err, DurationMs) then begin
            LogLlmCall(Enum::"Perf. Analysis LLM Purpose"::Filter, Analysis, BuildRawRequest(SystemPromptLbl, FilterInstructionLbl, Payload), RawResponse, Reply, false, StatusCode, GetLastErrorText(), DurationMs);
            LastError := GetLastErrorText();
            exit(false);
        end;
        LogLlmCall(Enum::"Perf. Analysis LLM Purpose"::Filter, Analysis, BuildRawRequest(SystemPromptLbl, FilterInstructionLbl, Payload), RawResponse, Reply, Success, StatusCode, Err, DurationMs);
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
        Reply: Text;
        Payload: Text;
        RawResponse: Text;
        Err: Text;
        Success: Boolean;
        StatusCode: Integer;
        DurationMs: Integer;
    begin
        LastError := '';
        // Keep lines in sync with the latest captured profiles so the card's "Profiles
        // Captured" counter and the payload below see the same data.
        ClearProfileLines(Analysis);
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

        Analysis.SetConclusion(Reply);
        Analysis."Ai Model" := CopyStr('azure-openai-chat', 1, MaxStrLen(Analysis."Ai Model"));
        Analysis.Modify(true);
        exit(true);
    end;

    /// <summary>
    /// Returns the fully assembled LLM prompt (system messages + user payload) for the
    /// given analysis so a developer can inspect what is sent to AOAI.
    /// </summary>
    procedure BuildAnalysisPromptForDebug(var Analysis: Record "Performance Analysis"): Text
    var
        SystemHeaderLbl: Label '=== System message ===';
        InstructionHeaderLbl: Label '=== Instruction ===';
        UserHeaderLbl: Label '=== User payload ===';
        Newline: Text[2];
    begin
        Newline[1] := 13;
        Newline[2] := 10;
        ClearProfileLines(Analysis);
        if LoadProfilesToLines(Analysis) then;
        exit(
            SystemHeaderLbl + Newline + SystemPromptLbl + Newline + Newline +
            InstructionHeaderLbl + Newline + AnalysisInstructionLbl + Newline + Newline +
            UserHeaderLbl + Newline + BuildAnalysisPayload(Analysis));
    end;

    local procedure BuildRawRequest(SystemPrompt: Text; Instruction: Text; UserPayload: Text) Combined: Text
    var
        Newline: Text[2];
    begin
        Newline[1] := 13;
        Newline[2] := 10;
        Combined :=
            '--- System message ---' + Newline + SystemPrompt + Newline + Newline +
            '--- Instruction ---' + Newline + Instruction + Newline + Newline +
            '--- User message ---' + Newline + UserPayload;
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
            Line.Insert(true);
        until Profile.Next() = 0;
        Analysis."Profiles Captured" := LineNo;
        Analysis.Modify(true);
        exit(true);
    end;

    local procedure BuildFilterPayload(var Analysis: Record "Performance Analysis") Payload: Text
    var
        Line: Record "Performance Analysis Line";
        PayloadObj: JsonObject;
        Profiles: JsonArray;
        ProfileObj: JsonObject;
    begin
        PayloadObj.Add('scenario', BuildScenarioJson(Analysis));
        Line.SetRange("Analysis Id", Analysis."Id");
        if Line.FindSet() then
            repeat
                Clear(ProfileObj);
                ProfileObj.Add('profileNo', Line."Line No.");
                ProfileObj.Add('createdAt', Format(Line."Profile Created At", 0, 9));
                Profiles.Add(ProfileObj);
            until Line.Next() = 0;
        PayloadObj.Add('profiles', Profiles);
        PayloadObj.WriteTo(Payload);
    end;

    local procedure BuildAnalysisPayload(var Analysis: Record "Performance Analysis") Payload: Text
    var
        Profile: Record "Performance Profiles";
        Sb: TextBuilder;
        ProfileNo: Integer;
        NL: Text[2];
        ScenarioHeaderLbl: Label '## Scenario';
        ProfilesHeaderLbl: Label '## Captured profiles';
        NoProfilesLbl: Label '(no profiles were captured for this scenario)';
        ProfileHeaderLbl: Label 'Profile %1', Comment = '%1 is the profile number';
    begin
        NL[1] := 13;
        NL[2] := 10;

        Sb.Append(ScenarioHeaderLbl);
        Sb.Append(NL);
        AppendScenarioLines(Analysis, Sb, NL);
        Sb.Append(NL);

        Sb.Append(ProfilesHeaderLbl);
        Sb.Append(NL);

        if not IsNullGuid(Analysis."Related Schedule Id") then begin
            Profile.SetRange("Schedule ID", Analysis."Related Schedule Id");
            if Profile.FindSet() then
                repeat
                    ProfileNo += 1;
                    Sb.Append(NL);
                    Sb.Append(StrSubstNo(ProfileHeaderLbl, ProfileNo));
                    Sb.Append(NL);
                    AppendProfileLines(Profile, Sb, NL);
                until Profile.Next() = 0;
        end;

        if ProfileNo = 0 then begin
            Sb.Append(NoProfilesLbl);
            Sb.Append(NL);
        end;

        Payload := Sb.ToText();
    end;

    local procedure AppendScenarioLines(var Analysis: Record "Performance Analysis"; var Sb: TextBuilder; NL: Text[2])
    var
        TitleLbl: Label '- Title: %1', Comment = '%1 is the user-supplied title of the scenario';
        ActivityLbl: Label '- Activity: %1', Comment = '%1 is the activity type, e.g. OpenPage';
        TriggerLbl: Label '- Trigger: %1 on %2 %3 "%4"', Comment = '%1 is trigger kind, %2 object type, %3 object id, %4 object name';
        TriggerActionLbl: Label '- Trigger action: %1', Comment = '%1 is the action name, e.g. Post';
        FrequencyLbl: Label '- Frequency: %1', Comment = '%1 is how often the scenario is slow';
        ObservedLbl: Label '- Observed duration: %1 ms', Comment = '%1 is duration in milliseconds';
        ExpectedLbl: Label '- Expected duration: %1 ms', Comment = '%1 is duration in milliseconds';
        NotesHeaderLbl: Label '- Notes:';
    begin
        Sb.Append(StrSubstNo(TitleLbl, Analysis."Title"));
        Sb.Append(NL);
        Sb.Append(StrSubstNo(ActivityLbl, Format(Analysis."Scenario Activity Type")));
        Sb.Append(NL);
        Sb.Append(StrSubstNo(TriggerLbl, Format(Analysis."Trigger Kind"), Format(Analysis."Trigger Object Type"), Analysis."Trigger Object Id", Analysis."Trigger Object Name"));
        Sb.Append(NL);
        if Analysis."Trigger Action Name" <> '' then begin
            Sb.Append(StrSubstNo(TriggerActionLbl, Analysis."Trigger Action Name"));
            Sb.Append(NL);
        end;
        Sb.Append(StrSubstNo(FrequencyLbl, Format(Analysis."Frequency")));
        Sb.Append(NL);
        Sb.Append(StrSubstNo(ObservedLbl, Analysis."Observed Duration (ms)"));
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
        StartedAtLbl: Label '- Started at: %1', Comment = '%1 is the start date and time';
        UserLbl: Label '- User: %1', Comment = '%1 is the user name';
        ActivityLbl: Label '- Activity: %1', Comment = '%1 is the activity description';
        ActivityDurationLbl: Label '- Activity duration: %1 ms', Comment = '%1 is duration in ms';
        AlDurationLbl: Label '- AL execution duration: %1 ms', Comment = '%1 is duration in ms';
        SqlLbl: Label '- SQL statements: %1 (total duration %2 ms)', Comment = '%1 is count, %2 is duration in ms';
        HttpLbl: Label '- HTTP calls: %1 (total duration %2 ms)', Comment = '%1 is count, %2 is duration in ms';
    begin
        Sb.Append(StrSubstNo(StartedAtLbl, Format(Profile."Starting Date-Time", 0, 9)));
        Sb.Append(NL);
        Sb.Append(StrSubstNo(UserLbl, Profile."User Name"));
        Sb.Append(NL);
        Sb.Append(StrSubstNo(ActivityLbl, Profile."Activity Description"));
        Sb.Append(NL);
        Sb.Append(StrSubstNo(ActivityDurationLbl, Profile."Activity Duration"));
        Sb.Append(NL);
        Sb.Append(StrSubstNo(AlDurationLbl, Profile.Duration));
        Sb.Append(NL);
        Sb.Append(StrSubstNo(SqlLbl, Profile."Sql Statement Number", Profile."Sql Call Duration"));
        Sb.Append(NL);
        Sb.Append(StrSubstNo(HttpLbl, Profile."Http Call Number", Profile."Http Call Duration"));
        Sb.Append(NL);
    end;

    local procedure BuildScenarioJson(var Analysis: Record "Performance Analysis") Scenario: JsonObject
    begin
        Scenario.Add('title', Analysis."Title");
        Scenario.Add('activity', Format(Analysis."Scenario Activity Type"));
        Scenario.Add('trigger', Format(Analysis."Trigger Kind"));
        Scenario.Add('triggerObjectType', Format(Analysis."Trigger Object Type"));
        Scenario.Add('triggerObjectId', Analysis."Trigger Object Id");
        Scenario.Add('triggerObjectName', Analysis."Trigger Object Name");
        Scenario.Add('triggerActionName', Analysis."Trigger Action Name");
        Scenario.Add('frequency', Format(Analysis."Frequency"));
        Scenario.Add('observedMs', Analysis."Observed Duration (ms)");
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
        Relevance: Decimal;
        Reason: Text;
        Relevant: Integer;
        I: Integer;
    begin
        // The model is asked for JSON only. Be defensive.
        if not Arr.ReadFrom(ExtractJsonArray(Reply)) then
            exit;
        for I := 0 to Arr.Count() - 1 do begin
            Arr.Get(I, Tok);
            if not Tok.IsObject() then
                continue;
            Obj := Tok.AsObject();
            ProfileNo := ReadInt(Obj, 'profileNo');
            Relevance := ReadDec(Obj, 'relevance');
            Reason := ReadText(Obj, 'reason');
            if Line.Get(Analysis."Id", ProfileNo) then begin
                Line."Ai Relevance Score" := Relevance;
                Line."Ai Reason" := CopyStr(Reason, 1, MaxStrLen(Line."Ai Reason"));
                Line."Marked Relevant" := Relevance >= 0.5;
                if Line."Marked Relevant" then
                    Relevant += 1;
                Line.Modify(true);
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
