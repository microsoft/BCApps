// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using Microsoft.eServices.EDocument.Processing.AI;
using System.AI;

codeunit 3329 "PA Draft Based Copilot Caller"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"E-Doc. AI Tool Processor", OnIsCopilotCapabilityActive, '', false, false)]
    local procedure IsPayablesAgentCapabilityActive(var IsActive: Boolean)
    var
        CopilotCapability: Codeunit "Copilot Capability";
    begin
        IsActive := CopilotCapability.IsCapabilityActive(Enum::"Copilot Capability"::"Payables Agent");
    end;

    [NonDebuggable]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"E-Doc. AI Tool Processor", OnGenerateChatCompletion, '', false, false)]
    local procedure GenerateChatCompletionUnderPayablesAgent(Deployment: Text; var ChatMessages: Codeunit "AOAI Chat Messages"; ChatCompletionParams: Codeunit "AOAI Chat Completion Params"; var AOAIOperationResponse: Codeunit "AOAI Operation Response")
    var
        AzureOpenAI: Codeunit "Azure OpenAI";
    begin
        AzureOpenAI.SetAuthorization(Enum::"AOAI Model Type"::"Chat Completions", Deployment);
        AzureOpenAI.SetCopilotCapability(Enum::"Copilot Capability"::"Payables Agent");
        AzureOpenAI.GenerateChatCompletion(ChatMessages, ChatCompletionParams, AOAIOperationResponse);
    end;
}
