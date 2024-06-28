// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Text;

using System;
using System.Utilities;
using System.AI;
using System.Telemetry;

/// <summary>
/// Implements functionality to handle text suggestions.
/// </summary>
codeunit 2012 "Entity Text Impl."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    /// <summary>
    /// Decides visibility on pages
    /// </summary>
    procedure IsEnabled(Silent: Boolean): Boolean
    var
        AzureOpenAI: Codeunit "Azure OpenAI";
    begin
        exit(AzureOpenAI.IsEnabled(Enum::"Copilot Capability"::"Entity Text", Silent));
    end;

    internal procedure GetFeatureName(): Text
    begin
        exit('Entity Text');
    end;

    procedure CanSuggest(): Boolean
    var
        EntityTextPrompts: Codeunit "Entity Text Prompts";
        EntityTextAOAISettings: Codeunit "Entity Text AOAI Settings";
    begin
        if not EntityTextAOAISettings.IsEnabled(true) then
            exit(false);

        exit(EntityTextPrompts.HasPromptInfo());
    end;

    [NonDebuggable]
    procedure GenerateSuggestion(Facts: Dictionary of [Text, Text]; Tone: Enum "Entity Text Tone"; TextFormat: Enum "Entity Text Format"; TextEmphasis: Enum "Entity Text Emphasis"; CallerModuleInfo: ModuleInfo): Text
    var
        EntityTextPrompts: Codeunit "Entity Text Prompts";
        SystemPrompt: Text;
        UserPrompt: Text;
        Suggestion: Text;
        FactsList: Text;
        Category: Text;
    begin
        if not IsEnabled(true) then
            Error(CapabilityDisabledErr);
        if not CanSuggest() then
            Error(CannotGenerateErr);

        FactsList := BuildFacts(Facts, Category, TextFormat);
        EntityTextPrompts.BuildPrompts(FactsList, Category, Tone, TextFormat, TextEmphasis, SystemPrompt, UserPrompt);

        Session.LogMessage('0000JVG', TelemetryGenerationRequestedTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', GetFeatureName());

        Suggestion := GenerateAndReviewCompletion(SystemPrompt, UserPrompt, TextFormat, Facts, CallerModuleInfo);

        exit(Suggestion);
    end;

    procedure InsertSuggestion(SourceTableId: Integer; SourceSystemId: Guid; SourceScenario: Enum "Entity Text Scenario"; SuggestedText: Text)
    var
        EntityText: Record "Entity Text";
    begin
        InsertSuggestion(SourceTableId, SourceSystemId, SourceScenario, SuggestedText, EntityText);
    end;

    procedure InsertSuggestion(SourceTableId: Integer; SourceSystemId: Guid; SourceScenario: Enum "Entity Text Scenario"; SuggestedText: Text; var EntityText: Record "Entity Text")
    begin
        EntityText.Init();
        EntityText.Company := CopyStr(CompanyName(), 1, MaxStrLen(EntityText.Company));
        EntityText."Source Table Id" := SourceTableId;
        EntityText."Source System Id" := SourceSystemId;
        EntityText.Scenario := SourceScenario;
        SetText(EntityText, SuggestedText);

        if not EntityText.Insert() then
            EntityText.Modify();

        Session.LogMessage('0000JVH', StrSubstNo(TelemetrySuggestionCreatedTxt, Format(SourceTableId), Format(SourceScenario)), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', GetFeatureName());
    end;

    procedure SetText(var EntityText: Record "Entity Text"; Content: Text)
    var
        Regex: Codeunit Regex;
        HttpUtility: DotNet HttpUtility;
        OutStr: OutStream;
        ContentNoTags: Text;
        ContentLines: List of [Text];
        ContentLine: Text;
    begin
        Clear(EntityText.Text);
        EntityText.Text.CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(Content);

        // naively remove tags
        ContentLines := Regex.Replace(Content, '<br */?>', '\').Split('\');
        foreach ContentLine in ContentLines do begin
            ContentLine := Regex.Replace(ContentLine, '<[^>]+>', '');
            ContentLine := HttpUtility.HtmlDecode(ContentLine);

            if ContentLine <> '' then
                ContentNoTags += ContentLine + '\';
        end;

        ContentNoTags := DelChr(ContentNoTags, '>', ' \');

        EntityText."Preview Text" := CopyStr(ContentNoTags, 1, MaxStrLen(EntityText."Preview Text"));
    end;

    procedure GetText(var EntityText: Record "Entity Text"): Text
    var
        InStr: InStream;
        Result: Text;
    begin
        EntityText.CalcFields(Text);
        EntityText.Text.CreateInStream(InStr, TextEncoding::UTF8);
        InStr.ReadText(Result);

        exit(Result);
    end;

    procedure GetText(TableId: Integer; SystemId: Guid; EntityTextScenario: Enum "Entity Text Scenario"): Text
    var
        EntityText: Record "Entity Text";
        Result: Text;
    begin
        if EntityText.Get(CompanyName(), TableId, SystemId, EntityTextScenario) then
            Result := GetText(EntityText);

        exit(Result);
    end;

    procedure SetEntityTextAuthorization(NewEndpoint: Text; NewDeployment: Text; NewApiKey: SecretText)
    begin
        Endpoint := NewEndpoint;
        Deployment := NewDeployment;
        ApiKey := NewApiKey;
    end;

    [NonDebuggable]
    local procedure BuildFacts(var Facts: Dictionary of [Text, Text]; var Category: Text; TextFormat: Enum "Entity Text Format"): Text
    var
        FactKey: Text;
        FactValue: Text;
        FactsList: Text;
        NewLineChar: Char;
        MaxFacts: Integer;
        TotalFacts: Integer;
        MaxFactLength: Integer;
    begin
        NewLineChar := 10;
        TotalFacts := Facts.Count();
        if TotalFacts = 0 then
            Error(NoFactsErr);

        if TotalFacts < 2 then
            Error(MinFactsErr);

        if (TotalFacts < 4) and (TextFormat <> TextFormat::Tagline) then
            Error(NotEnoughFactsForFormatErr);

        MaxFacts := 20;
        MaxFactLength := 250;
        if TotalFacts > MaxFacts then
            Session.LogMessage('0000JWA', StrSubstNo(TelemetryPromptManyFactsTxt, Format(Facts.Count()), MaxFacts), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', GetFeatureName());

        TotalFacts := 0;
        foreach FactKey in Facts.Keys() do begin
            if TotalFacts < MaxFacts then begin
                Facts.Get(FactKey, FactValue);
                FactKey := FactKey.Replace(NewLineChar, '').Trim();
                FactValue := FactValue.Replace(NewLineChar, '').Trim();
                if (Category = '') and FactKey.Contains('Category') then
                    Category := FactValue
                else
                    FactsList += StrSubstNo(FactTemplateTxt, CopyStr(FactKey, 1, MaxFactLength), CopyStr(FactValue, 1, MaxFactLength), NewLineChar);
            end;

            TotalFacts += 1;
        end;

        exit(FactsList);
    end;

    [NonDebuggable]
    local procedure GenerateAndReviewCompletion(SystemPrompt: Text; UserPrompt: Text; TextFormat: Enum "Entity Text Format"; Facts: Dictionary of [Text, Text]; CallerModuleInfo: ModuleInfo): Text
    var
        MagicFunction: Codeunit "Magic Function";
        EmptyArguments: JsonObject;
        Completion: Text;
        MaxAttempts: Integer;
        Attempt: Integer;
    begin
        MaxAttempts := 5;
        for Attempt := 0 to MaxAttempts do begin
            Completion := GenerateCompletion(TextFormat, SystemPrompt, UserPrompt, CallerModuleInfo);

            if (not CompletionContainsPrompt(Completion, SystemPrompt)) and IsGoodCompletion(Completion, TextFormat, Facts) then
                exit(Completion);

            Sleep(500);
            Session.LogMessage('0000LVP', StrSubstNo(TelemetryGenerationRetryTxt, Attempt + 1), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', GetFeatureName());
        end;

        // this completion is of low quality
        Session.LogMessage('0000JYB', TelemetryLowQualityCompletionTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', GetFeatureName());

        Error(MagicFunction.Execute(EmptyArguments));
    end;

    [NonDebuggable]
    local procedure CompletionContainsPrompt(Completion: Text; Prompt: Text): Boolean
    var
        PromptSentences: List of [Text];
        PromptSentence: Text;
    begin
        PromptSentences := Prompt.Split('.');

        Completion := Completion.ToLower();
        foreach PromptSentence in PromptSentences do begin
            PromptSentence := PromptSentence.Trim().ToLower();

            if PromptSentence <> '' then
                if Completion.Contains(PromptSentence) then begin
                    Session.LogMessage('0000JZG', StrSubstNo(TelemetryCompletionHasPromptTxt, PromptSentence), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', GetFeatureName());
                    exit(true);
                end;
        end;

        exit(false);
    end;

    [NonDebuggable]
    local procedure IsGoodCompletion(var Completion: Text; TextFormat: Enum "Entity Text Format"; Facts: Dictionary of [Text, Text]): Boolean
    var
        TempMatches: Record Matches temporary;
        Regex: Codeunit Regex;
        SplitCompletion: List of [Text];
        FactKey: Text;
        FactValue: Text;
        CandidateNumber: Text;
        FoundNumber: Boolean;
        FormatValid: Boolean;
    begin
        if Completion = '' then begin
            Session.LogMessage('0000JWJ', TelemetryCompletionEmptyTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', GetFeatureName());
            exit(false);
        end;

        if Completion.ToLower().StartsWith('tagline:') then begin
            Session.LogMessage('0000JYD', TelemetryTaglineCleanedTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', GetFeatureName());
            Completion := CopyStr(Completion, 9).Trim();
        end;
        FormatValid := true;
        case TextFormat of
            TextFormat::TaglineParagraph:
                begin
                    SplitCompletion := Completion.Split(EncodedNewlineTok + EncodedNewlineTok);
                    FormatValid := SplitCompletion.Count() = 2; // a tagline + paragraph must contain an empty line
                end;
            TextFormat::Paragraph:
                FormatValid := (not Completion.Contains(EncodedNewlineTok + EncodedNewlineTok)); // multiple paragraphs should be avoided
            TextFormat::Tagline:
                FormatValid := not Completion.Contains(EncodedNewlineTok); // a tagline should not have any newline
            TextFormat::Brief:
                FormatValid := Completion.Contains(EncodedNewlineTok + EncodedNewlineTok) and (Completion.Contains(EncodedNewlineTok + '-') or Completion.Contains(EncodedNewlineTok + '•') or Completion.Contains(EncodedNewlineTok + '*')); // the brief should contain a pargraph and a list
        end;

        if not FormatValid then begin
            Session.LogMessage('0000JYC', StrSubstNo(TelemetryCompletionInvalidFormatTxt, TextFormat), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', GetFeatureName());
            exit(false);
        end;

        // check the facts
        Regex.Match(Completion, '(?<!\S)(\d*\.?\d+)(?!\S)', TempMatches); // extract numbers
        if not TempMatches.FindSet() then
            exit(true); // no numbers to validate

        repeat
            CandidateNumber := TempMatches.ReadValue();
            FoundNumber := false;
            foreach FactKey in Facts.Keys() do
                if not FoundNumber then
                    if FactKey.Contains(CandidateNumber) then
                        FoundNumber := true
                    else begin
                        FactValue := Facts.Get(FactKey);
                        if FactValue.Contains(CandidateNumber) then
                            FoundNumber := true;
                    end;

            if not FoundNumber then begin
                Session.LogMessage('0000JYE', StrSubstNo(TelemetryCompletionInvalidNumberTxt, CandidateNumber), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', GetFeatureName());
                exit(false); // made up number
            end;
        until TempMatches.Next() = 0;

        if Completion.Contains(StrSubstNo(NoteParagraphTxt, EncodedNewlineTok)) or Completion.Contains(StrSubstNo(TranslationParagraphTxt, EncodedNewlineTok)) then begin
            Session.LogMessage('0000LHZ', TelemetryCompletionExtraTextTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', GetFeatureName());
            exit(false);
        end;

        exit(true);
    end;

    [NonDebuggable]
    local procedure GenerateCompletion(TextFormat: Enum "Entity Text Format"; SystemPrompt: Text; UserPrompt: Text; CallerModuleInfo: ModuleInfo): Text
    var
        AzureOpenAI: Codeunit "Azure OpenAI";
        EntityTextAOAISettings: Codeunit "Entity Text AOAI Settings";
        AOAIDeployments: Codeunit "AOAI Deployments";
        AOAIOperationResponse: Codeunit "AOAI Operation Response";
        AOAICompletionParams: Codeunit "AOAI Chat Completion Params";
        AOAIChatMessages: Codeunit "AOAI Chat Messages";
        MagicFunction: Codeunit "Magic Function";
        GenerateProdMktAdFunction: Codeunit "Generate Prod Mkt Ad Function";
        AOAIFunctionResponse: Codeunit "AOAI Function Response";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        TelemetryCD: Dictionary of [Text, Text];
        StartDateTime: DateTime;
        DurationAsBigInt: BigInteger;
        Result: Text;
        EntityTextModuleInfo: ModuleInfo;
        ResponseErr: Label 'AOAI Operation failed, response error code: %1', Comment = '%1 = Error code', Locked = true;
    begin
        NavApp.GetCurrentModuleInfo(EntityTextModuleInfo);
        if (not (Endpoint = '')) and (not (Deployment = ''))
        then
            AzureOpenAI.SetAuthorization(Enum::"AOAI Model Type"::"Chat Completions", Endpoint, Deployment, ApiKey)
        else
            if (not IsNullGuid(CallerModuleInfo.Id())) and (CallerModuleInfo.Publisher() = EntityTextModuleInfo.Publisher()) then
                AzureOpenAI.SetAuthorization(Enum::"AOAI Model Type"::"Chat Completions", AOAIDeployments.GetGPT4Preview())
            else begin
                TelemetryCD.Add('CallerModuleInfo', Format(CallerModuleInfo.Publisher()));
                TelemetryCD.Add('EntityTextModuleInfo', Format(EntityTextModuleInfo.Publisher()));
                FeatureTelemetry.LogError('0000LJB', GetFeatureName(), 'Entity Text Authorization', TelemetryNoAuthorizationHandlerTxt, '', TelemetryCD);
                Error(NoAuthorizationHandlerErr);
            end;

        AzureOpenAI.SetCopilotCapability(Enum::"Copilot Capability"::"Entity Text");

        AOAICompletionParams.SetMaxTokens(2500);
        AOAICompletionParams.SetTemperature(0.7);

        AOAIChatMessages.AddTool(MagicFunction);

        GenerateProdMktAdFunction.SetTextFormat(TextFormat);
        AOAIChatMessages.AddTool(GenerateProdMktAdFunction);
        AOAIChatMessages.SetToolChoice('auto');

        AOAIChatMessages.SetPrimarySystemMessage(SystemPrompt);
        AOAIChatMessages.AddUserMessage(UserPrompt);

        StartDateTime := CurrentDateTime();
        AzureOpenAI.GenerateChatCompletion(AOAIChatMessages, AOAICompletionParams, AOAIOperationResponse);
        DurationAsBigInt := CurrentDateTime() - StartDateTime;
        TelemetryCD.Add('Response time', Format(DurationAsBigInt));

        if AOAIOperationResponse.IsSuccess() then
            if AOAIOperationResponse.IsFunctionCall() then begin
                AOAIFunctionResponse := AOAIOperationResponse.GetFunctionResponse();
                FeatureTelemetry.LogUsage('0000N5C', GetFeatureName(), 'Call Chat Completion API', TelemetryCD);
                if AOAIFunctionResponse.IsSuccess() then begin
                    Result := AOAIFunctionResponse.GetResult();
                    if AOAIFunctionResponse.GetFunctionName() = MagicFunction.GetName() then
                        Error(Result)
                end else begin
                    Clear(Result);
                    FeatureTelemetry.LogError('0000N5Z', GetFeatureName(), 'Call Chat Completion API', 'AOAI Function response is not sucessfull', '', TelemetryCD);
                end;
            end else begin
                Clear(Result);
                FeatureTelemetry.LogError('0000N5A', GetFeatureName(), 'Call Chat Completion API', 'AOAI response is not a function call', '', TelemetryCD);
            end
        else begin
            Clear(Result);
            FeatureTelemetry.LogError('0000N5B', GetFeatureName(), 'Call Chat Completion API', StrSubstNo(ResponseErr, AOAIOperationResponse.GetStatusCode()), '', TelemetryCD);
        end;

        if EntityTextAOAISettings.ContainsWordsInDenyList(Result) then
            Clear(Result);
        exit(Result);
    end;

    var
        Endpoint: Text;
        Deployment: Text;
        ApiKey: SecretText;
        FactTemplateTxt: Label '- %1: %2%3', Locked = true;
        EncodedNewlineTok: Label '<br />', Locked = true;
        NoteParagraphTxt: Label '%1Note:%1', Locked = true, Comment = 'This constant is used to limit the cases when the model goes out of format and must stay in English only.';
        TranslationParagraphTxt: Label 'Translation:%1', Locked = true, Comment = 'This constant is used to limit the cases when the model goes out of format and must stay in English only.';
        NoFactsErr: Label 'There''s no information available to draft a text from.';
        CannotGenerateErr: Label 'Text cannot be generated. Please check your configuration and contact your partner.';
        CapabilityDisabledErr: Label 'Sorry, your Copilot isn''t activated for Entity Text. Contact the system administrator.';
        MinFactsErr: Label 'There''s not enough information available to draft a text. Please provide more.';
        NotEnoughFactsForFormatErr: Label 'There''s not enough information available to draft a text for the chosen format. Please provide more, or choose another format.';
        NoAuthorizationHandlerErr: Label 'There was no handler to provide authorization information for the suggestion. Contact your partner.';
        TelemetryGenerationRequestedTxt: Label 'New suggestion requested.', Locked = true;
        TelemetrySuggestionCreatedTxt: Label 'A new suggestion was generated for table %1, scenario %2', Locked = true;
        TelemetryCompletionEmptyTxt: Label 'The returned completion was empty.', Locked = true;
        TelemetryLowQualityCompletionTxt: Label 'Failed to generate a good quality completion, returning a low quality one.', Locked = true;
        TelemetryCompletionInvalidFormatTxt: Label 'The format %1 was requested, but the completion format did not pass validation.', Locked = true;
        TelemetryCompletionHasPromptTxt: Label 'The completion contains this sentence from the prompt: %1', Locked = true;
        TelemetryTaglineCleanedTxt: Label 'Trimmed a completion', Locked = true;
        TelemetryCompletionInvalidNumberTxt: Label 'A number was found in the completion (%1) that did not exist in the facts.', Locked = true;
        TelemetryCompletionExtraTextTxt: Label 'The completion contains a Translation or Note section.', Locked = true;
        TelemetryPromptManyFactsTxt: Label 'There are %1 facts defined, they will be limited to %2.', Locked = true;
        TelemetryNoAuthorizationHandlerTxt: Label 'Entity Text authorization was not set.', Locked = true;
        TelemetryGenerationRetryTxt: Label 'Retrying text generation, attempt: %1', Locked = true;
}