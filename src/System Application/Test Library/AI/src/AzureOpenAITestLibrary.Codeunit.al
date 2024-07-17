// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.TestLibraries.AI;

using System.AI;

codeunit 132933 "Azure OpenAI Test Library"
{
    EventSubscriberInstance = Manual;

    var
        DeploymentOverride: Option Latest,Preview;

    procedure GetAOAIHistory(HistoryLength: Integer; var AOAIChatMessages: Codeunit "AOAI Chat Messages"): JsonArray
    var
        SystemMessageTokenCount: Integer;
        MessagesTokenCount: Integer;
    begin
        AOAIChatMessages.SetHistoryLength(HistoryLength);
        exit(AOAIChatMessages.AssembleHistory(SystemMessageTokenCount, MessagesTokenCount));
    end;

    procedure GetAOAIAssembleTools(var AOAIChatMessages: Codeunit "AOAI Chat Messages"): JsonArray
    begin
        exit(AOAIChatMessages.AssembleTools());
    end;

    procedure GetAOAIChatCompletionParametersPayload(AOAIChatCompletionParams: Codeunit "AOAI Chat Completion Params"; var Payload: JsonObject)
    begin
        AOAIChatCompletionParams.AddChatCompletionsParametersToPayload(Payload);
    end;

    procedure SetAOAIFunctionResponse(var AOAIFunctionResponse: Codeunit "AOAI Function Response"; NewIsFunctionCall: Boolean; NewFunctionCallSuccess: Boolean; NewFunctionCalled: Text; NewFunctionId: Text; NewFunctionResult: Variant; NewFunctionError: Text; NewFunctionErrorCallStack: Text)
    begin
        AOAIFunctionResponse.SetFunctionCallingResponse(NewIsFunctionCall, NewFunctionCallSuccess, NewFunctionCalled, NewFunctionId, NewFunctionResult, NewFunctionError, NewFunctionErrorCallStack);
    end;

    procedure SetDeploymentOverride(OptionMembers: Option Latest,Preview)
    begin
        BindSubscription(this);
        this.DeploymentOverride := OptionMembers;
    end;

    procedure ClearSubscription()
    begin
        UnbindSubscription(this);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"AOAI Authorization", OnBeforeGetDeployment, '', false, false)]
    local procedure OverrideOnBeforeGetDeployment(var Deployment: Text)
    begin
        if DeploymentOverride = DeploymentOverride::Latest then
            Deployment := Deployment.Replace('preview', 'latest')
        else
            Deployment := Deployment.Replace('latest', 'preview');
    end;

}