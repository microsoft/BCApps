// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.AI;

using System;
using System.Azure.KeyVault;
using System.Environment;
using System.Privacy;
using System.Telemetry;

codeunit 7772 "Azure OpenAI Impl" implements "AI Service Name"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "Copilot Settings" = r;

    var
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
        CapabilityBackgroundErr: Label 'Microsoft Copilot Capabilities are not allowed in the background.';
        CapabilityODataErr: Label 'Microsoft Copilot Capabilities are not allowed in API and OData Web Services sessions.';
        MessagesMustContainJsonWordWhenResponseFormatIsJsonErr: Label 'The messages must contain the word ''json'' in some form, to use ''response format'' of type ''json_object''.';
        EmptyMetapromptErr: Label 'The metaprompt has not been set, please provide a metaprompt.';
        MetapromptLoadingErr: Label 'Metaprompt not found.';
        FunctionCallingFunctionNotFoundErr: Label 'Function call not found, %1.', Comment = '%1 is the name of the function';
        TelemetryGenerateTextCompletionLbl: Label 'Text completion generated.', Locked = true;
        TelemetryGenerateEmbeddingLbl: Label 'Embedding generated.', Locked = true;
        TelemetryGenerateChatCompletionLbl: Label 'Chat Completion generated.', Locked = true;
        TelemetryChatCompletionToolCallLbl: Label 'Tools called by chat completion.', Locked = true;
        TelemetryChatCompletionToolUsedLbl: Label 'Tools added to chat completion.', Locked = true;
        TelemetryProhibitedCharactersTxt: Label 'Prohibited characters removed from the prompt.', Locked = true;
        TelemetryTokenCountLbl: Label 'Metaprompt token count: %1, Prompt token count: %2, Total token count: %3', Comment = '%1 is the number of tokens in the metaprompt, %2 is the number of tokens in the prompt, %3 is the total number of tokens', Locked = true;
        TelemetryMetapromptRetrievalErr: Label 'Unable to retrieve metaprompt from Azure Key Vault.', Locked = true;
        TelemetryFunctionCallingFailedErr: Label 'Function calling failed for function: %1', Comment = '%1 is the name of the function', Locked = true;
        AzureOpenAiTxt: Label 'Azure OpenAI', Locked = true;
        BillingTypeAuthorizationErr: Label 'Usage of AI resources not authorized with chosen billing type, Capability: %1, Billing Type: %2. Please contact your system administrator.', Comment = '%1 is the capability name, %2 is the billing type';

    procedure IsEnabled(Capability: Enum "Copilot Capability"; CallerModuleInfo: ModuleInfo): Boolean
    begin
        exit(CopilotCapabilityImpl.IsCapabilityEnabled(Capability, CallerModuleInfo));
    end;

    procedure IsEnabled(Capability: Enum "Copilot Capability"; Silent: Boolean; CallerModuleInfo: ModuleInfo): Boolean
    begin
        exit(CopilotCapabilityImpl.IsCapabilityEnabled(Capability, Silent, CallerModuleInfo));
    end;

    procedure SetCopilotCapability(Capability: Enum "Copilot Capability"; CallerModuleInfo: ModuleInfo)
    begin
        CopilotCapabilityImpl.SetCopilotCapability(Capability, CallerModuleInfo, Enum::"Azure AI Service Type"::"Azure OpenAI");
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

#if not CLEAN26
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
#endif

    [NonDebuggable]
    procedure SetManagedResourceAuthorization(ModelType: Enum "AOAI Model Type"; AOAIAccountName: Text; ApiKey: SecretText; ManagedResourceDeployment: Text)
    begin
        case ModelType of
            Enum::"AOAI Model Type"::"Text Completions":
                TextCompletionsAOAIAuthorization.SetMicrosoftManagedAuthorization(AOAIAccountName, ApiKey, ManagedResourceDeployment);
            Enum::"AOAI Model Type"::Embeddings:
                EmbeddingsAOAIAuthorization.SetMicrosoftManagedAuthorization(AOAIAccountName, ApiKey, ManagedResourceDeployment);
            Enum::"AOAI Model Type"::"Chat Completions":
                ChatCompletionsAOAIAuthorization.SetMicrosoftManagedAuthorization(AOAIAccountName, ApiKey, ManagedResourceDeployment);
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

        CopilotCapabilityImpl.CheckCapabilitySet();
        CopilotCapabilityImpl.CheckEnabled(CallerModuleInfo);
        CheckAuthorizationEnabled(TextCompletionsAOAIAuthorization, CallerModuleInfo);

        CopilotCapabilityImpl.AddTelemetryCustomDimensions(CustomDimensions, CallerModuleInfo);
        CheckTextCompletionMetaprompt(Metaprompt, CustomDimensions);

        UnwrappedPrompt := Metaprompt.Unwrap() + Prompt.Unwrap();
        UnwrappedPrompt := RemoveProhibitedCharacters(UnwrappedPrompt);

        AOAICompletionParameters.AddCompletionsParametersToPayload(Payload);
        Payload.Add('prompt', UnwrappedPrompt);
        Payload.WriteTo(PayloadText);

        SendTokenCountTelemetry(AOAIToken.GetGPT4TokenCount(Metaprompt), AOAIToken.GetGPT4TokenCount(Prompt), CustomDimensions);

        if not SendRequest(Enum::"AOAI Model Type"::"Text Completions", TextCompletionsAOAIAuthorization, PayloadText, AOAIOperationResponse, CallerModuleInfo) then begin
            FeatureTelemetry.LogError('0000KVD', GetAzureOpenAICategory(), TelemetryGenerateTextCompletionLbl, CompletionsFailedWithCodeErr, '', Enum::"AL Telemetry Scope"::All, CustomDimensions);
            exit;
        end;

        FeatureTelemetry.LogUsage('0000KVL', GetAzureOpenAICategory(), TelemetryGenerateTextCompletionLbl, Enum::"AL Telemetry Scope"::All, CustomDimensions);
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

        CopilotCapabilityImpl.CheckCapabilitySet();
        CopilotCapabilityImpl.CheckEnabled(CallerModuleInfo);
        CheckAuthorizationEnabled(EmbeddingsAOAIAuthorization, CallerModuleInfo);

        Payload.Add('input', Input.Unwrap());
        Payload.WriteTo(PayloadText);

        CopilotCapabilityImpl.AddTelemetryCustomDimensions(CustomDimensions, CallerModuleInfo);
        SendTokenCountTelemetry(0, AOAIToken.GetAdaTokenCount(Input), CustomDimensions);
        if not SendRequest(Enum::"AOAI Model Type"::Embeddings, EmbeddingsAOAIAuthorization, PayloadText, AOAIOperationResponse, CallerModuleInfo) then begin
            FeatureTelemetry.LogError('0000KVE', GetAzureOpenAICategory(), TelemetryGenerateEmbeddingLbl, EmbeddingsFailedWithCodeErr, '', Enum::"AL Telemetry Scope"::All, CustomDimensions);
            exit;
        end;

        FeatureTelemetry.LogUsage('0000KVM', GetAzureOpenAICategory(), TelemetryGenerateEmbeddingLbl, Enum::"AL Telemetry Scope"::All, CustomDimensions);
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

        CopilotCapabilityImpl.CheckCapabilitySet();
        CopilotCapabilityImpl.CheckEnabled(CallerModuleInfo);
        CheckAuthorizationEnabled(ChatCompletionsAOAIAuthorization, CallerModuleInfo);
        CopilotCapabilityImpl.AddTelemetryCustomDimensions(CustomDimensions, CallerModuleInfo);

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
            FeatureTelemetry.LogError('0000KVF', GetAzureOpenAICategory(), TelemetryGenerateChatCompletionLbl, ChatCompletionsFailedWithCodeErr, '', Enum::"AL Telemetry Scope"::All, CustomDimensions);
            exit;
        end;

        ProcessChatCompletionResponse(ChatMessages, AOAIOperationResponse, CallerModuleInfo);

        FeatureTelemetry.LogUsage('0000KVN', GetAzureOpenAICategory(), TelemetryGenerateChatCompletionLbl, Enum::"AL Telemetry Scope"::All, CustomDimensions);

        if (AOAIOperationResponse.GetFunctionResponses().Count() > 0) and (ChatMessages.GetToolInvokePreference() = Enum::"AOAI Tool Invoke Preference"::Automatic) then
            GenerateChatCompletion(ChatMessages, AOAIChatCompletionParams, AOAIOperationResponse, CallerModuleInfo);
    end;

    [NonDebuggable]
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
        Response: JsonObject;
        EmptyArguments: JsonObject;
        CompletionToken: JsonToken;
        XPathLbl: Label '$.content', Comment = 'For more details on response, see https://aka.ms/AAlrz36', Locked = true;
        XPathToolCallsLbl: Label '$.tool_calls', Comment = 'For more details on response, see https://aka.ms/AAlrz36', Locked = true;
    begin
        Response.ReadFrom(AOAIOperationResponse.GetResult());
        if Response.SelectToken(XPathLbl, CompletionToken) then
            if not CompletionToken.AsValue().IsNull() then
                ChatMessages.AddAssistantMessage(CompletionToken.AsValue().AsText());
        if Response.SelectToken(XPathToolCallsLbl, CompletionToken) then begin
            ChatMessages.AddToolCalls(CompletionToken.AsArray());

            if not ProcessToolCalls(CompletionToken.AsArray(), ChatMessages, AOAIOperationResponse) then begin
                AOAIFunctionResponse.SetFunctionCallingResponse(true, Enum::"AOAI Function Response Status"::"Function Invalid", '', '', EmptyArguments, '', '', '');
                AOAIOperationResponse.AddFunctionResponse(AOAIFunctionResponse);
            end;

            CopilotCapabilityImpl.AddTelemetryCustomDimensions(CustomDimensions, CallerModuleInfo);
            foreach AOAIFunctionResponse in AOAIOperationResponse.GetFunctionResponses() do
                if not AOAIFunctionResponse.IsSuccess() then
                    FeatureTelemetry.LogError('0000MTB', GetAzureOpenAICategory(), StrSubstNo(TelemetryFunctionCallingFailedErr, AOAIFunctionResponse.GetFunctionName()), AOAIFunctionResponse.GetError(), AOAIFunctionResponse.GetErrorCallstack(), Enum::"AL Telemetry Scope"::All, CustomDimensions);

            if ChatMessages.GetToolInvokePreference() in [Enum::"AOAI Tool Invoke Preference"::"Invoke Tools Only", Enum::"AOAI Tool Invoke Preference"::Automatic] then
                AOAIOperationResponse.AppendFunctionResponsesToChatMessages(ChatMessages);

            Telemetry.LogMessage('0000MFH', TelemetryChatCompletionToolCallLbl, Verbosity::Normal, DataClassification::OrganizationIdentifiableInformation, Enum::"AL Telemetry Scope"::All, CustomDimensions);
        end;
    end;

    local procedure ProcessToolCalls(Tools: JsonArray; var ChatMessages: Codeunit "AOAI Chat Messages"; var AOAIOperationResponse: Codeunit "AOAI Operation Response"): Boolean
    var
        Tool: JsonToken;
        ToolObject: JsonObject;
        ToolType: JsonToken;
    begin
        if Tools.Count = 0 then
            exit(false);

        foreach Tool in Tools do
            if Tool.IsObject() then begin
                ToolObject := Tool.AsObject();
                if ToolObject.Get('type', ToolType) then
                    if ToolType.AsValue().AsText() = 'function' then
                        if not ProcessFunctionCall(ToolObject, ChatMessages, AOAIOperationResponse) then
                            exit(false);
            end;

        exit(true);
    end;

    local procedure ProcessFunctionCall(Function: JsonObject; var ChatMessages: Codeunit "AOAI Chat Messages"; var AOAIOperationResponse: Codeunit "AOAI Operation Response"): Boolean
    var
        AOAIFunctionResponse: Codeunit "AOAI Function Response";
        Arguments: JsonObject;
        Token: JsonToken;
        FunctionName: Text;
        FunctionId: Text;
        AOAIFunction: Interface "AOAI Function";
        FunctionResult: Variant;
    begin
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
            if ChatMessages.GetToolInvokePreference() in [Enum::"AOAI Tool Invoke Preference"::"Invoke Tools Only", Enum::"AOAI Tool Invoke Preference"::Automatic] then
                if TryExecuteFunction(AOAIFunction, Arguments, FunctionResult) then begin
                    AOAIFunctionResponse.SetFunctionCallingResponse(true, Enum::"AOAI Function Response Status"::"Invoke Success", AOAIFunction.GetName(), FunctionId, Arguments, FunctionResult, '', '');
                    AOAIOperationResponse.AddFunctionResponse(AOAIFunctionResponse);
                    exit(true);
                end else begin
                    AOAIFunctionResponse.SetFunctionCallingResponse(true, Enum::"AOAI Function Response Status"::"Invoke Error", AOAIFunction.GetName(), FunctionId, Arguments, FunctionResult, GetLastErrorText(), GetLastErrorCallStack());
                    AOAIOperationResponse.AddFunctionResponse(AOAIFunctionResponse);
                    exit(true);
                end
            else begin
                AOAIFunctionResponse.SetFunctionCallingResponse(true, Enum::"AOAI Function Response Status"::"Not Invoked", AOAIFunction.GetName(), FunctionId, Arguments, FunctionResult, '', '');
                AOAIOperationResponse.AddFunctionResponse(AOAIFunctionResponse);
                exit(true);
            end
        else begin
            AOAIFunctionResponse.SetFunctionCallingResponse(true, Enum::"AOAI Function Response Status"::"Function Not Found", FunctionName, FunctionId, Arguments, FunctionResult, StrSubstNo(FunctionCallingFunctionNotFoundErr, FunctionName), '');
            AOAIOperationResponse.AddFunctionResponse(AOAIFunctionResponse);
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
        CopilotNotifications: Codeunit "Copilot Notifications";
        ALCopilotAuthorization: DotNet ALCopilotAuthorization;
        ALCopilotCapability: DotNet ALCopilotCapability;
        ALCopilotFunctions: DotNet ALCopilotFunctions;
        ALCopilotOperationResponse: DotNet ALCopilotOperationResponse;
        Error: Text;
        EmptySecretText: SecretText;
    begin
        ClearLastError();

        if not IsBillingTypeAuthorized(AOAIAuthorization, CallerModuleInfo) then begin
            Error := StrSubstNo(BillingTypeAuthorizationErr, CopilotCapabilityImpl.GetCapabilityName(), CopilotCapabilityImpl.GetCopilotBillingType());
            Error(Error);
        end;

        case AOAIAuthorization.GetResourceUtilization() of
            Enum::"AOAI Resource Utilization"::"Microsoft Managed":
                ALCopilotAuthorization := ALCopilotAuthorization.Create(EmptySecretText, AOAIAuthorization.GetManagedResourceDeployment(), EmptySecretText);
            Enum::"AOAI Resource Utilization"::"First Party":
                ALCopilotAuthorization := ALCopilotAuthorization.Create(EmptySecretText, AOAIAuthorization.GetManagedResourceDeployment(), EmptySecretText);
            else
                ALCopilotAuthorization := ALCopilotAuthorization.Create(AOAIAuthorization.GetEndpoint(), AOAIAuthorization.GetDeployment(), AOAIAuthorization.GetApiKey());
        end;

        ALCopilotCapability := ALCopilotCapability.ALCopilotCapability(CallerModuleInfo.Publisher(), CallerModuleInfo.Id(), Format(CallerModuleInfo.AppVersion()), CopilotCapabilityImpl.GetCapabilityName());

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

        if AOAIOperationResponse.GetStatusCode() = 402 then
            CopilotNotifications.CheckAIQuotaAndShowNotification();

        if not ALCopilotOperationResponse.IsSuccess() then
            Error(GenerateRequestFailedErr);
    end;

    local procedure SendTokenCountTelemetry(Metaprompt: Integer; Prompt: Integer; CustomDimensions: Dictionary of [Text, Text])
    begin
        Telemetry.LogMessage('0000LT4', StrSubstNo(TelemetryTokenCountLbl, Metaprompt, Prompt, Metaprompt + Prompt), Verbosity::Normal, DataClassification::OrganizationIdentifiableInformation, Enum::"AL Telemetry Scope"::All, CustomDimensions);
    end;

    local procedure GuiCheck(AOAIAuthorization: Codeunit "AOAI Authorization")
    var
        ClientTypeManagement: Codeunit "Client Type Management";
    begin
        if AOAIAuthorization.GetResourceUtilization() = Enum::"AOAI Resource Utilization"::"Self-Managed" then
            exit;

        if ClientTypeManagement.GetCurrentClientType() in [ClientType::Api, ClientType::OData, ClientType::ODataV4, ClientType::SOAP, ClientType::Management] then
            Error(CapabilityODataErr);

        if (not GuiAllowed()) and (AOAIAuthorization.GetResourceUtilization() = Enum::"AOAI Resource Utilization"::"Microsoft Managed") then
            Error(CapabilityBackgroundErr);
    end;

    local procedure CheckAuthorizationEnabled(AOAIAuthorization: Codeunit "AOAI Authorization"; CallerModuleInfo: ModuleInfo)
    begin
        if not AOAIAuthorization.IsConfigured(CallerModuleInfo) then
            Error(AuthenticationNotConfiguredErr);
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
        ModuleInfo: ModuleInfo;
        KVSecret: SecretText;
    begin
        if not EnvironmentInformation.IsSaaSInfrastructure() then
            exit;

        if not AzureKeyVault.GetAzureKeyVaultSecret('AOAI-Metaprompt-Text', KVSecret) then begin
            Telemetry.LogMessage('0000LX3', TelemetryMetapromptRetrievalErr, Verbosity::Error, DataClassification::SystemMetadata);
            NavApp.GetCurrentModuleInfo(ModuleInfo);
            if ModuleInfo.Publisher = 'Microsoft' then
                Error(MetapromptLoadingErr);
        end;
        Metaprompt := KVSecret;
    end;

    [NonDebuggable]
    local procedure CheckTextCompletionMetaprompt(Metaprompt: SecretText; CustomDimensions: Dictionary of [Text, Text])
    var
        ModuleInfo: ModuleInfo;
    begin
        if Metaprompt.Unwrap().Trim() = '' then begin
            FeatureTelemetry.LogError('0000LO8', GetAzureOpenAICategory(), TelemetryGenerateTextCompletionLbl, EmptyMetapromptErr, '', Enum::"AL Telemetry Scope"::All, CustomDimensions);

            NavApp.GetCurrentModuleInfo(ModuleInfo);
            if ModuleInfo.Publisher = 'Microsoft' then
                Error(EmptyMetapromptErr);
        end;
    end;

    procedure GetTokenCount(Input: SecretText; Encoding: Text) TokenCount: Integer
    var
        ALCopilotFunctions: DotNet ALCopilotFunctions;
    begin
        TokenCount := ALCopilotFunctions.GptTokenCount(Input, Encoding);
    end;

    procedure GetTotalServerSessionTokensConsumed(): Integer
    begin
        exit(SessionInformation.AITokensUsed);
    end;

    procedure GetAzureOpenAICategory(): Code[50]
    begin
        exit(AzureOpenAiTxt);
    end;

    procedure GetServiceName(): Text[250];
    begin
        exit(AzureOpenAiTxt);
    end;

    procedure GetServiceId(): Code[50];
    begin
        exit(AzureOpenAiTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Privacy Notice", 'OnRegisterPrivacyNotices', '', false, false)]
    local procedure CreatePrivacyNoticeRegistrations(var TempPrivacyNotice: Record "Privacy Notice" temporary)
    begin
        TempPrivacyNotice.Init();
        TempPrivacyNotice.ID := GetAzureOpenAICategory();
        TempPrivacyNotice."Integration Service Name" := GetServiceName();
        if not TempPrivacyNotice.Insert() then;
    end;

    procedure IsBillingTypeAuthorized(AOAIAuthorization: Codeunit "AOAI Authorization"; CallerModuleInfo: ModuleInfo): Boolean
    var
        BillingType: Enum "Copilot Billing Type";
    begin
        BillingType := CopilotCapabilityImpl.GetCopilotBillingType();
        if (CopilotCapabilityImpl.IsPublisherMicrosoft(CallerModuleInfo)) then begin
            if (AOAIAuthorization.GetResourceUtilization() = Enum::"AOAI Resource Utilization"::"First Party") then
                exit(BillingType <> Enum::"Copilot Billing Type"::"Custom Billed")
        end else
            case BillingType of
                Enum::"Copilot Billing Type"::"Custom Billed":
                    exit(AOAIAuthorization.GetResourceUtilization() = Enum::"AOAI Resource Utilization"::"Self-Managed");
                Enum::"Copilot Billing Type"::"Microsoft Billed":
                    case AOAIAuthorization.GetResourceUtilization() of
                        Enum::"AOAI Resource Utilization"::"Microsoft Managed":
                            exit(true);
                        Enum::"AOAI Resource Utilization"::"Self-Managed":
                            if CopilotCapabilityImpl.IsProductionEnvironment() then
                                exit(false)
                            else
                                exit(true);
                        else
                            exit(false);
                    end;
                Enum::"Copilot Billing Type"::"Not Billed":
                    exit(AOAIAuthorization.GetResourceUtilization() = Enum::"AOAI Resource Utilization"::"Self-Managed");
                else
                    exit(true);
            end;
    end;
}