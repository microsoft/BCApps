// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AIEvaluate;

using System.AI;

/// <summary>
/// Exposes functions that can be used by the AI tests.
/// </summary>
codeunit 50000 "AI Evaluate Impl."
{
    Access = Internal;

    procedure Evaluate(Input: JsonObject; Evaluator: Codeunit "AI Evaluator"): JsonObject
    var
        Result: JsonObject;
    begin
        // Todo: Read input and call below
        exit(Result);
    end;


    procedure Evaluate(Query: Text; Response: Text; Context: Text; GroundTruth: Text; Evaluator: Codeunit "AI Evaluator"): JsonObject
    begin
        exit(DoEvaluate(Query, Response, Context, GroundTruth, Evaluator));
    end;

    local procedure DoEvaluate(Query: Text; Response: Text; Context: Text; GroundTruth: Text; Evaluator: Codeunit "AI Evaluator"): JsonObject
    var
        AzureOpenAI: Codeunit "Azure OpenAI";
        AOAIDeployments: Codeunit "AOAI Deployments";
        AOAIOperationResponse: Codeunit "AOAI Operation Response";
        AOAIChatCompletionParams: Codeunit "AOAI Chat Completion Params";
        AOAIChatMessages: Codeunit "AOAI Chat Messages";
        Result: Text;
        ResultJson: JsonToken;
    begin
        // Todo: Somehow input query, response, context, groundtruth based on prompty file???

        AzureOpenAI.SetAuthorization(Enum::"AOAI Model Type"::"Chat Completions", AOAIDeployments.GetGPT4oLatest()); // Todo: Set deployment based on prompty input?
        AzureOpenAI.SetCopilotCapability(Enum::"Copilot Capability"::"AI Evaluate");
        AOAIChatCompletionParams.SetMaxTokens(2500);
        AOAIChatCompletionParams.SetTemperature(0);

        AOAIChatMessages.SetPrimarySystemMessage(Evaluator.GetSystemPrompt());
        AOAIChatMessages.AddUserMessage(Evaluator.GetUserMessage());
        AOAIChatMessages.AddAssistantMessage(Evaluator.GetAssistantMessage());
        AzureOpenAI.GenerateChatCompletion(AOAIChatMessages, AOAIChatCompletionParams, AOAIOperationResponse);
        if AOAIOperationResponse.IsSuccess() then
            Result := AOAIChatMessages.GetLastMessage()
        else
            Error('Evaluation was not succesful.');

        if not ResultJson.ReadFrom(Result) then
            Error('Evaluator did not return a valid JSON.');

        if not ResultJson.IsObject() then
            Error('Evaluator did not return a valid JSON object.');

        exit(ResultJson.AsObject());
    end;

    internal procedure RegisterCapability()
    var
        CopilotCapability: Codeunit "Copilot Capability";
    begin
        if not CopilotCapability.IsCapabilityRegistered(Enum::"Copilot Capability"::"AI Evaluate") then
            CopilotCapability.RegisterCapability(
            Enum::"Copilot Capability"::"AI Evaluate",
            Enum::"Copilot Availability"::"Early Preview", LearnMoreUrlTxt);
    end;

    var
        LearnMoreUrlTxt: Label 'https://go.microsoft.com/fwlink/?linkid=724011', Locked = true;

    [EventSubscriber(ObjectType::Page, Page::"Copilot AI Capabilities", 'OnRegisterCopilotCapability', '', false, false)]
    local procedure HandleOnRegisterCopilotCapability()
    begin
        RegisterCapability();
    end;
}