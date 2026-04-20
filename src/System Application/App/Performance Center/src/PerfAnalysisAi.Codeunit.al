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
                  tabledata "Performance Profile Scheduler" = R;

    var
        LastError: Text;
        SystemPromptLbl: Label 'You are a Dynamics 365 Business Central performance expert. You help triage slow scenarios based on user descriptions, captured profiles and signal findings. Be concise and actionable. Always explain where time is spent, the most likely cause, and suggested next steps. If the data is inconclusive, say so.';
        FilterInstructionLbl: Label 'For each captured profile, respond with a JSON array of objects with fields ProfileNo (integer), Relevance (0..1), Reason (short text). Mark profiles as relevant (>=0.5) only if they plausibly match the scenario. Respond with JSON only.';
        AnalysisInstructionLbl: Label 'Given the user-described scenario, the filtered relevant profiles and the gathered signals, produce a concise conclusion in Markdown. Sections: 1. Summary. 2. Where time is spent. 3. Likely cause. 4. Why it varies (if applicable). 5. Recommended next steps.';
        ChatInstructionLbl: Label 'You can now answer follow-up questions about this analysis. Keep answers grounded in the provided context. If asked something you cannot answer from the context, say so.';
        CapabilityNotActiveErr: Label 'The Copilot capability "AI-assisted performance analysis in Performance Center" is not active in this environment. Enable it in the Copilot & AI capabilities page to use AI-assisted analysis.';
        AuthNotConfiguredErr: Label 'Azure OpenAI is not configured for this environment.';

    /// <summary>
    /// Ensures the capability is active and (in SaaS) authorization is configured.
    /// </summary>
    procedure EnsureAvailable()
    var
        AzureOpenAI: Codeunit "Azure OpenAI";
    begin
        if not AzureOpenAI.IsEnabled(Enum::"Copilot Capability"::"Performance Center", true) then
            Error(CapabilityNotActiveErr);
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

        if not TryChat(AzureOpenAI, Messages, Response, Reply) then
            exit(false);

        ApplyFilterReply(Analysis, Reply);
        exit(true);
    end;

    /// <summary>
    /// Produces the analysis conclusion and stores it on the analysis record.
    /// </summary>
    procedure Analyze(var Analysis: Record "Performance Analysis"): Boolean
    var
        Messages: Codeunit "AOAI Chat Messages";
        Response: Codeunit "AOAI Operation Response";
        AzureOpenAI: Codeunit "Azure OpenAI";
        Reply: Text;
    begin
        LastError := '';
        if not TryPrepareClient(AzureOpenAI) then
            exit(false);

        Messages.AddSystemMessage(SystemPromptLbl);
        Messages.AddSystemMessage(AnalysisInstructionLbl);
        Messages.AddUserMessage(BuildAnalysisPayload(Analysis));

        if not TryChat(AzureOpenAI, Messages, Response, Reply) then
            exit(false);

        Analysis.SetConclusion(Reply);
        Analysis."Ai Model" := CopyStr('azure-openai-chat', 1, MaxStrLen(Analysis."Ai Model"));
        Analysis.Modify(true);
        exit(true);
    end;

    /// <summary>
    /// Primes an AOAI Chat Messages codeunit with the analysis context so the chat page
    /// can send follow-up questions grounded in the conclusion + top findings.
    /// </summary>
    procedure PrimeChat(var Analysis: Record "Performance Analysis"; var Messages: Codeunit "AOAI Chat Messages")
    var
        PrimerLbl: Label 'Analysis context:\n%1', Comment = '%1 is the JSON payload describing the analysis';
    begin
        EnsureAvailable();
        Messages.AddSystemMessage(SystemPromptLbl);
        Messages.AddSystemMessage(ChatInstructionLbl);
        Messages.AddSystemMessage(StrSubstNo(PrimerLbl, BuildAnalysisPayload(Analysis)));
    end;

    /// <summary>
    /// Sends one turn of chat. Returns the reply text (empty on failure, with LastError set).
    /// </summary>
    procedure SendChat(var Messages: Codeunit "AOAI Chat Messages"; UserText: Text): Text
    var
        Response: Codeunit "AOAI Operation Response";
        AzureOpenAI: Codeunit "Azure OpenAI";
        Reply: Text;
    begin
        LastError := '';
        if not TryPrepareClient(AzureOpenAI) then
            exit('');
        Messages.AddUserMessage(UserText);
        if not TryChat(AzureOpenAI, Messages, Response, Reply) then
            exit('');
        exit(Reply);
    end;

    procedure GetLastError(): Text
    begin
        exit(LastError);
    end;

    local procedure TryPrepareClient(var AzureOpenAI: Codeunit "Azure OpenAI"): Boolean
    begin
        AzureOpenAI.SetCopilotCapability(Enum::"Copilot Capability"::"Performance Center");
        if not AzureOpenAI.IsEnabled(Enum::"Copilot Capability"::"Performance Center", true) then begin
            LastError := CapabilityNotActiveErr;
            exit(false);
        end;
        if not AzureOpenAI.IsAuthorizationConfigured(Enum::"AOAI Model Type"::"Chat Completions") then begin
            LastError := AuthNotConfiguredErr;
            exit(false);
        end;
        exit(true);
    end;

    [TryFunction]
    local procedure TryChat(var AzureOpenAI: Codeunit "Azure OpenAI"; var Messages: Codeunit "AOAI Chat Messages"; var Response: Codeunit "AOAI Operation Response"; var Reply: Text)
    begin
        AzureOpenAI.GenerateChatCompletion(Messages, Response);
        if Response.IsSuccess() then
            Reply := Response.GetResult()
        else
            Error(Response.GetError());
    end;

    local procedure ClearProfileLines(var Analysis: Record "Performance Analysis")
    var
        Line: Record "Performance Analysis Line";
    begin
        Line.SetRange("Analysis Id", Analysis."Id");
        Line.SetRange("Line Type", Line."Line Type"::Profile);
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
            Line."Line Type" := Line."Line Type"::Profile;
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
        Line.SetRange("Line Type", Line."Line Type"::Profile);
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
        Line: Record "Performance Analysis Line";
        Root: JsonObject;
        RelevantProfiles: JsonArray;
        Signals: JsonArray;
        ItemObj: JsonObject;
    begin
        Root.Add('scenario', BuildScenarioJson(Analysis));
        Root.Add('conclusionSoFar', Analysis.GetConclusion());

        Line.SetRange("Analysis Id", Analysis."Id");
        Line.SetRange("Line Type", Line."Line Type"::Profile);
        Line.SetRange("Marked Relevant", true);
        if Line.FindSet() then
            repeat
                Clear(ItemObj);
                ItemObj.Add('profileNo', Line."Line No.");
                ItemObj.Add('relevance', Line."Ai Relevance Score");
                ItemObj.Add('reason', Line."Ai Reason");
                RelevantProfiles.Add(ItemObj);
            until Line.Next() = 0;
        Root.Add('relevantProfiles', RelevantProfiles);

        Line.Reset();
        Line.SetRange("Analysis Id", Analysis."Id");
        Line.SetRange("Line Type", Line."Line Type"::Signal);
        if Line.FindSet() then
            repeat
                Clear(ItemObj);
                ItemObj.Add('source', Format(Line."Signal Source"));
                ItemObj.Add('severity', Format(Line."Severity"));
                ItemObj.Add('title', Line."Title");
                ItemObj.Add('description', Line."Description");
                Signals.Add(ItemObj);
            until Line.Next() = 0;
        Root.Add('signals', Signals);

        Root.WriteTo(Payload);
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
            if Line.Get(Analysis."Id", ProfileNo) and (Line."Line Type" = Line."Line Type"::Profile) then begin
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
