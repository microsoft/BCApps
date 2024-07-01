// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.AI;

using System;
using System.Azure.Identity;
using System.Azure.KeyVault;
using System.Environment;
using System.Globalization;
using System.Privacy;
using System.Telemetry;

codeunit 7772 "Azure OpenAI Impl"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "Copilot Settings" = r;

    var
        CopilotSettings: Record "Copilot Settings";
        CopilotCapabilityCU: Codeunit "Copilot Capability";
        CopilotCapabilityImpl: Codeunit "Copilot Capability Impl";
        ChatCompletionsAOAIAuthorization: Codeunit "AOAI Authorization";
        TextCompletionsAOAIAuthorization: Codeunit "AOAI Authorization";
        EmbeddingsAOAIAuthorization: Codeunit "AOAI Authorization";
        AOAIToken: Codeunit "AOAI Token";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        Telemetry: Codeunit Telemetry;
        InvalidModelTypeErr: Label 'Selected model type is not supported.';
        GenerateRequestFailedErr: Label 'The request did not return a success status code.';
        CompletionsFailedWithCodeErr: Label 'Text completions failed to be generated';
        EmbeddingsFailedWithCodeErr: Label 'Embeddings failed to be generated.';
        ChatCompletionsFailedWithCodeErr: Label 'Chat completions failed to be generated.';
        AuthenticationNotConfiguredErr: Label 'The authentication was not configured.';
        CopilotNotEnabledErr: Label 'Copilot is not enabled. Please contact your system administrator.';
        CopilotCapabilityNotSetErr: Label 'Copilot capability has not been set.';
        CapabilityBackgroundErr: Label 'Microsoft Copilot Capabilities are not allowed in the background.';
        CopilotDisabledForTenantErr: Label 'Copilot is not enabled for the tenant. Please contact your system administrator.';
        CapabilityNotRegisteredErr: Label 'Copilot capability ''%1'' has not been registered by the module.', Comment = '%1 is the name of the Copilot Capability';
        CapabilityNotEnabledErr: Label 'Copilot capability ''%1'' has not been enabled. Please contact your system administrator.', Comment = '%1 is the name of the Copilot Capability';
        MessagesMustContainJsonWordWhenResponseFormatIsJsonErr: Label 'The messages must contain the word ''json'' in some form, to use ''response format'' of type ''json_object''.';
        EmptyMetapromptErr: Label 'The metaprompt has not been set, please provide a metaprompt.';
        MetapromptLoadingErr: Label 'Metaprompt not found.';
        EnabledKeyTok: Label 'AOAI-Enabled', Locked = true;
        FunctionCallingFunctionNotFoundErr: Label 'Function call not found, %1.', Comment = '%1 is the name of the function';
        AllowlistedTenantsAkvKeyTok: Label 'AOAI-Allow-1P-Auth', Locked = true;
        TelemetryGenerateTextCompletionLbl: Label 'Text completion generated.', Locked = true;
        TelemetryGenerateEmbeddingLbl: Label 'Embedding generated.', Locked = true;
        TelemetryGenerateChatCompletionLbl: Label 'Chat Completion generated.', Locked = true;
        TelemetryChatCompletionToolCallLbl: Label 'Tools called by chat completion.', Locked = true;
        TelemetryChatCompletionToolUsedLbl: Label 'Tools added to chat completion.', Locked = true;
        TelemetrySetCapabilityLbl: Label 'Set Capability', Locked = true;
        TelemetryCopilotCapabilityNotRegisteredLbl: Label 'Copilot capability not registered.', Locked = true;
        TelemetryIsEnabledLbl: Label 'Is Enabled', Locked = true;
        TelemetryUnableToCheckEnvironmentKVTxt: Label 'Unable to check if environment is allowed to run AOAI.', Locked = true;
        TelemetryEnvironmentNotAllowedtoRunCopilotTxt: Label 'Copilot is not allowed on this environment.', Locked = true;
        TelemetryProhibitedCharactersTxt: Label 'Prohibited characters removed from the prompt.', Locked = true;
        TelemetryTokenCountLbl: Label 'Metaprompt token count: %1, Prompt token count: %2, Total token count: %3', Comment = '%1 is the number of tokens in the metaprompt, %2 is the number of tokens in the prompt, %3 is the total number of tokens', Locked = true;
        TelemetryMetapromptRetrievalErr: Label 'Unable to retrieve metaprompt from Azure Key Vault.', Locked = true;
        TelemetryFunctionCallingFailedErr: Label 'Function calling failed for function: %1', Comment = '%1 is the name of the function', Locked = true;
        TelemetryEmptyTenantIdErr: Label 'Empty or malformed tenant ID.', Locked = true;
        TelemetryTenantAllowlistedMsg: Label 'Current tenant allowlisted for first party auth.', Locked = true;

    procedure IsEnabled(Capability: Enum "Copilot Capability"; CallerModuleInfo: ModuleInfo): Boolean
    begin
        exit(IsEnabled(Capability, false, CallerModuleInfo));
    end;

    procedure IsEnabled(Capability: Enum "Copilot Capability"; Silent: Boolean; CallerModuleInfo: ModuleInfo): Boolean
    var
        CoplilotNotAvailable: Page "Copilot Not Available";
    begin
        if not IsTenantAllowed() then begin
            if not Silent then
                Error(CopilotDisabledForTenantErr); // Copilot capabilities cannot be run on this environment.

            exit(false);
        end;

        if not CopilotCapabilityCU.IsCapabilityActive(Capability, CallerModuleInfo.Id()) then begin
            if not Silent then begin
                CoplilotNotAvailable.SetCopilotCapability(Capability);
                CoplilotNotAvailable.Run();
            end;

            exit(false);
        end;

        exit(CheckPrivacyNoticeState(Silent, Capability));
    end;

    [NonDebuggable]
    local procedure IsTenantAllowed(): Boolean
    var
        EnvironmentInformation: Codeunit "Environment Information";
        AzureKeyVault: Codeunit "Azure Key Vault";
        AzureAdTenant: Codeunit "Azure AD Tenant";
        BlockList: Text;
    begin
        if not EnvironmentInformation.IsSaaSInfrastructure() then
            exit(true);

        if (not AzureKeyVault.GetAzureKeyVaultSecret(EnabledKeyTok, BlockList)) or (BlockList.Trim() = '') then begin
            FeatureTelemetry.LogError('0000KYC', CopilotCapabilityImpl.GetAzureOpenAICategory(), TelemetryIsEnabledLbl, TelemetryUnableToCheckEnvironmentKVTxt);
            exit(false);
        end;

        if BlockList.Contains(AzureAdTenant.GetAadTenantId()) then begin
            FeatureTelemetry.LogError('0000LFP', CopilotCapabilityImpl.GetAzureOpenAICategory(), TelemetryIsEnabledLbl, TelemetryEnvironmentNotAllowedtoRunCopilotTxt);
            exit(false);
        end;

        exit(true);
    end;

    local procedure CheckPrivacyNoticeState(Silent: Boolean; Capability: Enum "Copilot Capability"): Boolean
    var
        PrivacyNotice: Codeunit "Privacy Notice";
        CopilotNotAvailable: Page "Copilot Not Available";
        WithinGeo: Boolean;
        WithinEuropeGeo: Boolean;
    begin
        case PrivacyNotice.GetPrivacyNoticeApprovalState(CopilotCapabilityImpl.GetAzureOpenAICategory(), false) of
            Enum::"Privacy Notice Approval State"::Agreed:
                exit(true);
            Enum::"Privacy Notice Approval State"::Disagreed:
                begin
                    if not Silent then begin
                        CopilotNotAvailable.SetCopilotCapability(Capability);
                        CopilotNotAvailable.Run();
                    end;

                    exit(false);
                end;
            else begin
                // Privacy notice not set, we will not cross geo-boundries
                CopilotCapabilityImpl.CheckGeo(WithinGeo, WithinEuropeGeo);
                WithinGeo := WithinGeo or WithinEuropeGeo;

                if not Silent then
                    if not WithinGeo then begin
                        CopilotNotAvailable.SetCopilotCapability(Capability);
                        CopilotNotAvailable.Run();
                    end;

                exit(WithinGeo);
            end;

        end;
    end;

    procedure IsAuthorizationConfigured(ModelType: Enum "AOAI Model Type"; CallerModule: ModuleInfo): Boolean
    begin
        case ModelType of
            Enum::"AOAI Model Type"::"Text Completions":
                exit(TextCompletionsAOAIAuthorization.IsConfigured(CallerModule));
            Enum::"AOAI Model Type"::Embeddings:
                exit(EmbeddingsAOAIAuthorization.IsConfigured(CallerModule));
            Enum::"AOAI Model Type"::"Chat Completions":
                exit(ChatCompletionsAOAIAuthorization.IsConfigured(CallerModule));
            else
                Error(InvalidModelTypeErr)
        end;
    end;

    procedure IsInitialized(Capability: Enum "Copilot Capability"; ModelType: Enum "AOAI Model Type"; CallerModuleInfo: ModuleInfo): Boolean
    begin
        exit(IsEnabled(Capability, CallerModuleInfo) and IsAuthorizationConfigured(ModelType, CallerModuleInfo));
    end;

    [NonDebuggable]
    procedure SetAuthorization(ModelType: Enum "AOAI Model Type"; Deployment: Text)
    begin
        case ModelType of
            Enum::"AOAI Model Type"::"Text Completions":
                TextCompletionsAOAIAuthorization.SetFirstPartyAuthorization(Deployment);
            Enum::"AOAI Model Type"::Embeddings:
                EmbeddingsAOAIAuthorization.SetFirstPartyAuthorization(Deployment);
            Enum::"AOAI Model Type"::"Chat Completions":
                ChatCompletionsAOAIAuthorization.SetFirstPartyAuthorization(Deployment);
            else
                Error(InvalidModelTypeErr);
        end;
    end;

    [NonDebuggable]
    procedure SetAuthorization(ModelType: Enum "AOAI Model Type"; Endpoint: Text; Deployment: Text; ApiKey: SecretText)
    begin
        case ModelType of
            Enum::"AOAI Model Type"::"Text Completions":
                TextCompletionsAOAIAuthorization.SetSelfManagedAuthorization(Endpoint, Deployment, ApiKey);
            Enum::"AOAI Model Type"::Embeddings:
                EmbeddingsAOAIAuthorization.SetSelfManagedAuthorization(Endpoint, Deployment, ApiKey);
            Enum::"AOAI Model Type"::"Chat Completions":
                ChatCompletionsAOAIAuthorization.SetSelfManagedAuthorization(Endpoint, Deployment, ApiKey);
            else
                Error(InvalidModelTypeErr);
        end;
    end;

    [NonDebuggable]
    procedure SetManagedResourceAuthorization(ModelType: Enum "AOAI Model Type"; Endpoint: Text; Deployment: Text; ApiKey: SecretText; ManagedResourceDeployment: Text)
    begin
        case ModelType of
            Enum::"AOAI Model Type"::"Text Completions":
                TextCompletionsAOAIAuthorization.SetMicrosoftManagedAuthorization(Endpoint, Deployment, ApiKey, ManagedResourceDeployment);
            Enum::"AOAI Model Type"::Embeddings:
                EmbeddingsAOAIAuthorization.SetMicrosoftManagedAuthorization(Endpoint, Deployment, ApiKey, ManagedResourceDeployment);
            Enum::"AOAI Model Type"::"Chat Completions":
                ChatCompletionsAOAIAuthorization.SetMicrosoftManagedAuthorization(Endpoint, Deployment, ApiKey, ManagedResourceDeployment);
            else
                Error(InvalidModelTypeErr);
        end;
    end;

    [NonDebuggable]
    procedure GenerateTextCompletion(Prompt: SecretText; var AOAIOperationResponse: Codeunit "AOAI Operation Response"; CallerModuleInfo: ModuleInfo): Text
    var
        AOAICompletionParameters: Codeunit "AOAI Text Completion Params";
    begin
        exit(GenerateTextCompletion(GetTextMetaprompt(), Prompt, AOAICompletionParameters, AOAIOperationResponse, CallerModuleInfo));
    end;

    [NonDebuggable]
    procedure GenerateTextCompletion(Prompt: SecretText; AOAICompletionParameters: Codeunit "AOAI Text Completion Params"; var AOAIOperationResponse: Codeunit "AOAI Operation Response"; CallerModuleInfo: ModuleInfo) Result: Text
    begin
        exit(GenerateTextCompletion(GetTextMetaprompt(), Prompt, AOAICompletionParameters, AOAIOperationResponse, CallerModuleInfo));
    end;

    [NonDebuggable]
    procedure GenerateTextCompletion(Metaprompt: SecretText; Prompt: SecretText; var AOAIOperationResponse: Codeunit "AOAI Operation Response"; CallerModuleInfo: ModuleInfo): Text
    var
        AOAICompletionParameters: Codeunit "AOAI Text Completion Params";
    begin
        exit(GenerateTextCompletion(Metaprompt, Prompt, AOAICompletionParameters, AOAIOperationResponse, CallerModuleInfo));
    end;

    [NonDebuggable]
    procedure GenerateTextCompletion(Metaprompt: SecretText; Prompt: SecretText; AOAICompletionParameters: Codeunit "AOAI Text Completion Params"; var AOAIOperationResponse: Codeunit "AOAI Operation Response"; CallerModuleInfo: ModuleInfo) Result: Text
    var
        CustomDimensions: Dictionary of [Text, Text];
        Payload: JsonObject;
        PayloadText: Text;
        UnwrappedPrompt: Text;
    begin
        GuiCheck(TextCompletionsAOAIAuthorization);

        CheckCapabilitySet();
        CheckEnabled(CallerModuleInfo);
        CheckAuthorizationEnabled(TextCompletionsAOAIAuthorization, CallerModuleInfo);

        AddTelemetryCustomDimensions(CustomDimensions, CallerModuleInfo);
        CheckTextCompletionMetaprompt(Metaprompt, CustomDimensions);

        UnwrappedPrompt := Metaprompt.Unwrap() + Prompt.Unwrap();
        UnwrappedPrompt := RemoveProhibitedCharacters(UnwrappedPrompt);

        AOAICompletionParameters.AddCompletionsParametersToPayload(Payload);
        Payload.Add('prompt', UnwrappedPrompt);
        Payload.WriteTo(PayloadText);

        SendTokenCountTelemetry(AOAIToken.GetGPT4TokenCount(Metaprompt), AOAIToken.GetGPT4TokenCount(Prompt), CustomDimensions);

        if not SendRequest(Enum::"AOAI Model Type"::"Text Completions", TextCompletionsAOAIAuthorization, PayloadText, AOAIOperationResponse, CallerModuleInfo) then begin
            FeatureTelemetry.LogError('0000KVD', CopilotCapabilityImpl.GetAzureOpenAICategory(), TelemetryGenerateTextCompletionLbl, CompletionsFailedWithCodeErr, '', Enum::"AL Telemetry Scope"::All, CustomDimensions);
            exit;
        end;

        FeatureTelemetry.LogUsage('0000KVL', CopilotCapabilityImpl.GetAzureOpenAICategory(), TelemetryGenerateTextCompletionLbl, Enum::"AL Telemetry Scope"::All, CustomDimensions);
        Result := AOAIOperationResponse.GetResult();
    end;

    [NonDebuggable]
    procedure GenerateEmbeddings(Input: SecretText; var AOAIOperationResponse: Codeunit "AOAI Operation Response"; CallerModuleInfo: ModuleInfo): List of [Decimal]
    var
        CustomDimensions: Dictionary of [Text, Text];
        Payload: JsonObject;
        PayloadText: Text;
    begin
        GuiCheck(EmbeddingsAOAIAuthorization);

        CheckCapabilitySet();
        CheckEnabled(CallerModuleInfo);
        CheckAuthorizationEnabled(EmbeddingsAOAIAuthorization, CallerModuleInfo);

        Payload.Add('input', Input.Unwrap());
        Payload.WriteTo(PayloadText);

        AddTelemetryCustomDimensions(CustomDimensions, CallerModuleInfo);
        SendTokenCountTelemetry(0, AOAIToken.GetAdaTokenCount(Input), CustomDimensions);
        if not SendRequest(Enum::"AOAI Model Type"::Embeddings, EmbeddingsAOAIAuthorization, PayloadText, AOAIOperationResponse, CallerModuleInfo) then begin
            FeatureTelemetry.LogError('0000KVE', CopilotCapabilityImpl.GetAzureOpenAICategory(), TelemetryGenerateEmbeddingLbl, EmbeddingsFailedWithCodeErr, '', Enum::"AL Telemetry Scope"::All, CustomDimensions);
            exit;
        end;

        FeatureTelemetry.LogUsage('0000KVM', CopilotCapabilityImpl.GetAzureOpenAICategory(), TelemetryGenerateEmbeddingLbl, Enum::"AL Telemetry Scope"::All, CustomDimensions);
        exit(ProcessEmbeddingResponse(AOAIOperationResponse));
    end;

    [NonDebuggable]
    local procedure ProcessEmbeddingResponse(AOAIOperationResponse: Codeunit "AOAI Operation Response") Result: List of [Decimal]
    var
        Response: JsonObject;
        CompletionToken: JsonToken;
        Counter: Integer;
        XPathLbl: Label '$.vector[%1]', Comment = '%1 = The n''th embedding. For more details on response, see https://aka.ms/AAlrrng', Locked = true;
    begin
        Response.ReadFrom(AOAIOperationResponse.GetResult());
        Counter := 0;
        while Response.SelectToken(StrSubstNo(XPathLbl, Counter), CompletionToken) do begin
            Counter := Counter + 1;
            Result.Add(CompletionToken.AsValue().AsDecimal());
        end;
    end;

    [NonDebuggable]
    procedure GenerateChatCompletion(var ChatMessages: Codeunit "AOAI Chat Messages"; var AOAIOperationResponse: Codeunit "AOAI Operation Response"; CallerModuleInfo: ModuleInfo)
    var
        AOAIChatCompletionParams: Codeunit "AOAI Chat Completion Params";
    begin
        GenerateChatCompletion(ChatMessages, AOAIChatCompletionParams, AOAIOperationResponse, CallerModuleInfo);
    end;

    [NonDebuggable]
    procedure GenerateChatCompletion(var ChatMessages: Codeunit "AOAI Chat Messages"; AOAIChatCompletionParams: Codeunit "AOAI Chat Completion Params"; var AOAIOperationResponse: Codeunit "AOAI Operation Response"; CallerModuleInfo: ModuleInfo)
    var
        CustomDimensions: Dictionary of [Text, Text];
        Payload, ToolChoicePayload : JsonObject;
        ToolsPayload: JsonArray;
        PayloadText, ToolChoice : Text;
        MetapromptTokenCount: Integer;
        PromptTokenCount: Integer;
    begin
        GuiCheck(ChatCompletionsAOAIAuthorization);

        CheckCapabilitySet();
        CheckEnabled(CallerModuleInfo);
        CheckAuthorizationEnabled(ChatCompletionsAOAIAuthorization, CallerModuleInfo);
        AddTelemetryCustomDimensions(CustomDimensions, CallerModuleInfo);

        AOAIChatCompletionParams.AddChatCompletionsParametersToPayload(Payload);
        Payload.Add('messages', ChatMessages.AssembleHistory(MetapromptTokenCount, PromptTokenCount));

        if ChatMessages.ToolsExists() then begin
            ToolsPayload := ChatMessages.AssembleTools();
            Payload.Add('tools', ToolsPayload);
            ToolChoice := ChatMessages.GetToolChoice();
            if ToolChoice = 'auto' then
                Payload.Add('tool_choice', ToolChoice)
            else begin
                ToolChoicePayload.ReadFrom(ToolChoice);
                Payload.Add('tool_choice', ToolChoicePayload);
            end;

            CustomDimensions.Add('ToolsCount', Format(ToolsPayload.Count));
            Telemetry.LogMessage('0000MFG', TelemetryChatCompletionToolUsedLbl, Verbosity::Normal, DataClassification::OrganizationIdentifiableInformation, Enum::"AL Telemetry Scope"::All, CustomDimensions);
        end;

        CheckJsonModeCompatibility(Payload);

        Payload.WriteTo(PayloadText);

        SendTokenCountTelemetry(MetapromptTokenCount, PromptTokenCount, CustomDimensions);
        if not SendRequest(Enum::"AOAI Model Type"::"Chat Completions", ChatCompletionsAOAIAuthorization, PayloadText, AOAIOperationResponse, CallerModuleInfo) then begin
            FeatureTelemetry.LogError('0000KVF', CopilotCapabilityImpl.GetAzureOpenAICategory(), TelemetryGenerateChatCompletionLbl, ChatCompletionsFailedWithCodeErr, '', Enum::"AL Telemetry Scope"::All, CustomDimensions);
            exit;
        end;

        ProcessChatCompletionResponse(ChatMessages, AOAIOperationResponse, CallerModuleInfo);

        FeatureTelemetry.LogUsage('0000KVN', CopilotCapabilityImpl.GetAzureOpenAICategory(), TelemetryGenerateChatCompletionLbl, Enum::"AL Telemetry Scope"::All, CustomDimensions);
    end;

    local procedure CheckJsonModeCompatibility(Payload: JsonObject)
    var
        ResponseFormatToken: JsonToken;
        MessagesToken: JsonToken;
        Messages: Text;
        TypeToken: JsonToken;
        XPathLbl: Label '$.type', Locked = true;
    begin
        if not Payload.Get('response_format', ResponseFormatToken) then
            exit;

        if not Payload.Get('messages', MessagesToken) then
            exit;

        if not ResponseFormatToken.SelectToken(XPathLbl, TypeToken) then
            exit;

        if TypeToken.AsValue().AsText() <> 'json_object' then
            exit;

        MessagesToken.WriteTo(Messages);
        if not LowerCase(Messages).Contains('json') then
            Error(MessagesMustContainJsonWordWhenResponseFormatIsJsonErr);
    end;

    [NonDebuggable]
    [TryFunction]
    local procedure ProcessChatCompletionResponse(var ChatMessages: Codeunit "AOAI Chat Messages"; var AOAIOperationResponse: Codeunit "AOAI Operation Response"; CallerModuleInfo: ModuleInfo)
    var
        AOAIFunctionResponse: Codeunit "AOAI Function Response";
        CustomDimensions: Dictionary of [Text, Text];
        ToolsCall: Text;
        Response: JsonObject;
        CompletionToken: JsonToken;
        XPathLbl: Label '$.content', Comment = 'For more details on response, see https://aka.ms/AAlrz36', Locked = true;
        XPathToolCallsLbl: Label '$.tool_calls', Comment = 'For more details on response, see https://aka.ms/AAlrz36', Locked = true;
    begin
        Response.ReadFrom(AOAIOperationResponse.GetResult());
        if Response.SelectToken(XPathLbl, CompletionToken) then
            if not CompletionToken.AsValue().IsNull() then
                ChatMessages.AddAssistantMessage(CompletionToken.AsValue().AsText());
        if Response.SelectToken(XPathToolCallsLbl, CompletionToken) then begin
            CompletionToken.AsArray().WriteTo(ToolsCall);
            ChatMessages.AddAssistantMessage(ToolsCall);

            AOAIFunctionResponse := AOAIOperationResponse.GetFunctionResponse();
            if not ProcessFunctionCall(CompletionToken.AsArray(), ChatMessages, AOAIFunctionResponse) then
                AOAIFunctionResponse.SetFunctionCallingResponse(true, false, '', '', '', '', '');

            AddTelemetryCustomDimensions(CustomDimensions, CallerModuleInfo);
            if not AOAIFunctionResponse.IsSuccess() then
                FeatureTelemetry.LogError('0000MTB', CopilotCapabilityImpl.GetAzureOpenAICategory(), StrSubstNo(TelemetryFunctionCallingFailedErr, AOAIFunctionResponse.GetFunctionName()), AOAIFunctionResponse.GetError(), AOAIFunctionResponse.GetErrorCallstack(), Enum::"AL Telemetry Scope"::All, CustomDimensions);

            Telemetry.LogMessage('0000MFH', TelemetryChatCompletionToolCallLbl, Verbosity::Normal, DataClassification::OrganizationIdentifiableInformation, Enum::"AL Telemetry Scope"::All, CustomDimensions);
        end;
    end;

    local procedure ProcessFunctionCall(Functions: JsonArray; var ChatMessages: Codeunit "AOAI Chat Messages"; var AOAIFunctionResponse: Codeunit "AOAI Function Response"): Boolean
    var
        Function: JsonObject;
        Arguments: JsonObject;
        Token: JsonToken;
        FunctionName: Text;
        FunctionId: Text;
        AOAIFunction: Interface "AOAI Function";
        FunctionResult: Variant;
    begin
        if Functions.Count = 0 then
            exit(false);

        Functions.Get(0, Token);
        Function := Token.AsObject();

        if Function.Get('type', Token) then begin
            if Token.AsValue().AsText() <> 'function' then
                exit(false);
        end else
            exit(false);

        if Function.Get('id', Token) then
            FunctionId := Token.AsValue().AsText()
        else
            exit(false);

        if Function.Get('function', Token) then
            Function := Token.AsObject()
        else
            exit(false);

        if Function.Get('name', Token) then
            FunctionName := Token.AsValue().AsText()
        else
            exit(false);

        if Function.Get('arguments', Token) then
            // Arguments are stored as a string in the JSON
            Arguments.ReadFrom(Token.AsValue().AsText());

        if ChatMessages.GetFunctionTool(FunctionName, AOAIFunction) then
            if TryExecuteFunction(AOAIFunction, Arguments, FunctionResult) then begin
                AOAIFunctionResponse.SetFunctionCallingResponse(true, true, AOAIFunction.GetName(), FunctionId, FunctionResult, '', '');
                exit(true);
            end else begin
                AOAIFunctionResponse.SetFunctionCallingResponse(true, false, AOAIFunction.GetName(), FunctionId, FunctionResult, GetLastErrorText(), GetLastErrorCallStack());
                exit(true);
            end
        else begin
            AOAIFunctionResponse.SetFunctionCallingResponse(true, false, FunctionName, FunctionId, FunctionResult, StrSubstNo(FunctionCallingFunctionNotFoundErr, FunctionName), '');
            exit(true);
        end;
    end;

    [TryFunction]
    local procedure TryExecuteFunction(AOAIFunction: Interface "AOAI Function"; Arguments: JsonObject; var Result: Variant)
    begin
        Result := AOAIFunction.Execute(Arguments);
    end;

    [TryFunction]
    [NonDebuggable]
    local procedure SendRequest(ModelType: Enum "AOAI Model Type"; AOAIAuthorization: Codeunit "AOAI Authorization"; Payload: Text; var AOAIOperationResponse: Codeunit "AOAI Operation Response"; CallerModuleInfo: ModuleInfo)
    var
        ALCopilotAuthorization: DotNet ALCopilotAuthorization;
        ALCopilotCapability: DotNet ALCopilotCapability;
        ALCopilotFunctions: DotNet ALCopilotFunctions;
        ALCopilotOperationResponse: DotNet ALCopilotOperationResponse;
        Error: Text;
        EmptySecretText: SecretText;
    begin
        ClearLastError();
        case AOAIAuthorization.GetResourceUtilization() of
            Enum::"AOAI Resource Utilization"::"Microsoft Managed":
                ALCopilotAuthorization := ALCopilotAuthorization.Create(EmptySecretText, AOAIAuthorization.GetManagedResourceDeployment(), EmptySecretText);
            Enum::"AOAI Resource Utilization"::"First Party":
                ALCopilotAuthorization := ALCopilotAuthorization.Create(EmptySecretText, AOAIAuthorization.GetManagedResourceDeployment(), EmptySecretText);
            else
                ALCopilotAuthorization := ALCopilotAuthorization.Create(AOAIAuthorization.GetEndpoint(), AOAIAuthorization.GetDeployment(), AOAIAuthorization.GetApiKey());
        end;

        ALCopilotCapability := ALCopilotCapability.ALCopilotCapability(CallerModuleInfo.Publisher(), CallerModuleInfo.Id(), Format(CallerModuleInfo.AppVersion()), GetCapabilityName());

        case ModelType of
            Enum::"AOAI Model Type"::"Text Completions":
                ALCopilotOperationResponse := ALCopilotFunctions.GenerateTextCompletion(Payload, ALCopilotAuthorization, ALCopilotCapability);
            Enum::"AOAI Model Type"::Embeddings:
                ALCopilotOperationResponse := ALCopilotFunctions.GenerateEmbedding(Payload, ALCopilotAuthorization, ALCopilotCapability);
            Enum::"AOAI Model Type"::"Chat Completions":
                ALCopilotOperationResponse := ALCopilotFunctions.GenerateChatCompletion(Payload, ALCopilotAuthorization, ALCopilotCapability);
            else
                Error(InvalidModelTypeErr)
        end;

        Error := ALCopilotOperationResponse.ErrorText();
        if Error = '' then
            Error := GetLastErrorText();
        AOAIOperationResponse.SetOperationResponse(ALCopilotOperationResponse.IsSuccess(), ALCopilotOperationResponse.StatusCode(), ALCopilotOperationResponse.Result(), Error);

        if not ALCopilotOperationResponse.IsSuccess() then
            Error(GenerateRequestFailedErr);
    end;

    local procedure GetCapabilityName(): Text
    var
        CapabilityIndex: Integer;
        CapabilityName: Text;
    begin
        CheckCapabilitySet();

        CapabilityIndex := CopilotSettings.Capability.Ordinals.IndexOf(CopilotSettings.Capability.AsInteger());
        CapabilityName := CopilotSettings.Capability.Names.Get(CapabilityIndex);

        if CapabilityName.Trim() = '' then
            exit(Format(CopilotSettings.Capability, 0, 9));

        exit(CapabilityName);
    end;

    local procedure SendTokenCountTelemetry(Metaprompt: Integer; Prompt: Integer; CustomDimensions: Dictionary of [Text, Text])
    begin
        Telemetry.LogMessage('0000LT4', StrSubstNo(TelemetryTokenCountLbl, Metaprompt, Prompt, Metaprompt + Prompt), Verbosity::Normal, DataClassification::OrganizationIdentifiableInformation, Enum::"AL Telemetry Scope"::All, CustomDimensions);
    end;

    local procedure GuiCheck(AOAIAuthorization: Codeunit "AOAI Authorization")
    begin
        if GuiAllowed() then
            exit;

        if AOAIAuthorization.GetResourceUtilization() = Enum::"AOAI Resource Utilization"::"Self-Managed" then
            exit;

        Error(CapabilityBackgroundErr);
    end;

    local procedure AddTelemetryCustomDimensions(var CustomDimensions: Dictionary of [Text, Text]; CallerModuleInfo: ModuleInfo)
    var
        Language: Codeunit Language;
        SavedGlobalLanguageId: Integer;
    begin
        SavedGlobalLanguageId := GlobalLanguage();
        GlobalLanguage(Language.GetDefaultApplicationLanguageId());

        CustomDimensions.Add('Capability', Format(CopilotSettings.Capability));
        CustomDimensions.Add('AppId', Format(CopilotSettings."App Id"));
        CustomDimensions.Add('Publisher', CallerModuleInfo.Publisher);
        CustomDimensions.Add('UserLanguage', Format(GlobalLanguage()));

        GlobalLanguage(SavedGlobalLanguageId);
    end;

    procedure SetCopilotCapability(Capability: Enum "Copilot Capability"; CallerModuleInfo: ModuleInfo)
    var
        CopilotTelemetry: Codeunit "Copilot Telemetry";
        Language: Codeunit Language;
        SavedGlobalLanguageId: Integer;
        CustomDimensions: Dictionary of [Text, Text];
        ErrorMessage: Text;
    begin
        if not CopilotCapabilityCU.IsCapabilityRegistered(Capability, CallerModuleInfo.Id()) then begin
            SavedGlobalLanguageId := GlobalLanguage();
            GlobalLanguage(Language.GetDefaultApplicationLanguageId());
            CustomDimensions.Add('Capability', Format(Capability));
            CustomDimensions.Add('AppId', Format(CallerModuleInfo.Id()));
            GlobalLanguage(SavedGlobalLanguageId);

            FeatureTelemetry.LogError('0000LFN', CopilotCapabilityImpl.GetAzureOpenAICategory(), TelemetrySetCapabilityLbl, TelemetryCopilotCapabilityNotRegisteredLbl, '', Enum::"AL Telemetry Scope"::All, CustomDimensions);
            ErrorMessage := StrSubstNo(CapabilityNotRegisteredErr, Capability);
            Error(ErrorMessage);
        end;

        CopilotSettings.ReadIsolation(IsolationLevel::ReadCommitted);
        CopilotSettings.SetLoadFields(Status);
        CopilotSettings.Get(Capability, CallerModuleInfo.Id());
        if CopilotSettings.Status = Enum::"Copilot Status"::Inactive then begin
            ErrorMessage := StrSubstNo(CapabilityNotEnabledErr, Capability);
            Error(ErrorMessage);
        end;
        CopilotTelemetry.SetCopilotCapability(Capability, CallerModuleInfo.Id());
    end;

    local procedure CheckEnabled(CallerModuleInfo: ModuleInfo)
    begin
        if not IsEnabled(CopilotSettings.Capability, true, CallerModuleInfo) then
            Error(CopilotNotEnabledErr);
    end;

    local procedure CheckAuthorizationEnabled(AOAIAuthorization: Codeunit "AOAI Authorization"; CallerModuleInfo: ModuleInfo)
    begin
        if not AOAIAuthorization.IsConfigured(CallerModuleInfo) then
            Error(AuthenticationNotConfiguredErr);
    end;

    local procedure CheckCapabilitySet()
    begin
        if CopilotSettings.Capability.AsInteger() = 0 then
            Error(CopilotCapabilityNotSetErr);
    end;

    [NonDebuggable]
    procedure RemoveProhibitedCharacters(Prompt: Text) Result: Text
    begin
        Result := Prompt.Replace('<|end>', '');
        Result := Result.Replace('<|start>', '');
        Result := Result.Replace('<|im_end|>', '');
        Result := Result.Replace('<|im_start|>', '');

        if Prompt <> Result then
            Telemetry.LogMessage('0000LOB', TelemetryProhibitedCharactersTxt, Verbosity::Warning, DataClassification::SystemMetadata);

        exit(Result);
    end;

    [NonDebuggable]
    internal procedure GetTextMetaprompt() Metaprompt: SecretText;
    var
        AzureKeyVault: Codeunit "Azure Key Vault";
        EnvironmentInformation: Codeunit "Environment Information";
        KVSecret: SecretText;
    begin
        if not EnvironmentInformation.IsSaaSInfrastructure() then
            exit;

        if not AzureKeyVault.GetAzureKeyVaultSecret('AOAI-Metaprompt-Text', KVSecret) then begin
            Telemetry.LogMessage('0000LX3', TelemetryMetapromptRetrievalErr, Verbosity::Error, DataClassification::SystemMetadata);
            Error(MetapromptLoadingErr);
        end;
        Metaprompt := KVSecret;
    end;

    [NonDebuggable]
    local procedure CheckTextCompletionMetaprompt(Metaprompt: SecretText; CustomDimensions: Dictionary of [Text, Text])
    begin
        if Metaprompt.Unwrap().Trim() = '' then begin
            FeatureTelemetry.LogError('0000LO8', CopilotCapabilityImpl.GetAzureOpenAICategory(), TelemetryGenerateTextCompletionLbl, EmptyMetapromptErr, '', Enum::"AL Telemetry Scope"::All, CustomDimensions);
            Error(EmptyMetapromptErr);
        end;
    end;
#if not CLEAN24
    [NonDebuggable]
    [Obsolete('Use the function GetTokenCount() instead.', '24.0')]
    procedure ApproximateTokenCount(Input: Text): Decimal
    var
        AverageWordsPerToken: Decimal;
        TokenCount: Integer;
        WordsInInput: Integer;
    begin
        AverageWordsPerToken := 0.6; // Based on OpenAI estimate
        WordsInInput := Input.Split(' ', ',', '.', '!', '?', ';', ':', '/n').Count;
        TokenCount := Round(WordsInInput / AverageWordsPerToken, 1);
        exit(TokenCount);
    end;
#endif

    procedure GetTokenCount(Input: SecretText; Encoding: Text) TokenCount: Integer
    var
        ALCopilotFunctions: DotNet ALCopilotFunctions;
    begin
        TokenCount := ALCopilotFunctions.GptTokenCount(Input, Encoding);
    end;

    [NonDebuggable]
    internal procedure IsTenantAllowlistedForFirstPartyCopilotCalls(): Boolean
    var
        EnvironmentInformation: Codeunit "Environment Information";
        AzureKeyVault: Codeunit "Azure Key Vault";
        AzureAdTenant: Codeunit "Azure AD Tenant";
        AllowlistedTenants: Text;
        EntraTenantIdAsText: Text;
        EntraTenantIdAsGuid: Guid;
    begin
        if not EnvironmentInformation.IsSaaSInfrastructure() then
            exit(false);

        if (not AzureKeyVault.GetAzureKeyVaultSecret(AllowlistedTenantsAkvKeyTok, AllowlistedTenants)) or (AllowlistedTenants.Trim() = '') then
            exit(false);

        EntraTenantIdAsText := AzureAdTenant.GetAadTenantId();

        if (EntraTenantIdAsText = '') or not Evaluate(EntraTenantIdAsGuid, EntraTenantIdAsText) or IsNullGuid(EntraTenantIdAsGuid) then begin
            Session.LogMessage('0000MLN', TelemetryEmptyTenantIdErr, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CopilotCapabilityImpl.GetAzureOpenAICategory());
            exit(false);
        end;

        if not AllowlistedTenants.Contains(EntraTenantIdAsText) then
            exit(false);

        Session.LogMessage('0000MLE', TelemetryTenantAllowlistedMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CopilotCapabilityImpl.GetAzureOpenAICategory());
        exit(true);
    end;

}