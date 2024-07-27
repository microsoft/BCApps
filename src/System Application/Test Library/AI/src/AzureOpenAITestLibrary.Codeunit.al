// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.TestLibraries.AI;

using System.AI;

codeunit 132933 "Azure OpenAI Test Library"
{

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

    procedure AddAOAIFunctionResponse(var AOAIOperationResponse: Codeunit "AOAI Operation Response"; var AOAIFunctionResponse: Codeunit "AOAI Function Response"; NewIsFunctionCall: Boolean; NewFunctionCallSuccess: Boolean; NewFunctionCalled: Text; NewFunctionId: Text; NewFunctionResult: Variant; NewFunctionError: Text; NewFunctionErrorCallStack: Text)
    begin
        SetAOAIFunctionResponse(AOAIFunctionResponse, NewIsFunctionCall, NewFunctionCallSuccess, NewFunctionCalled, NewFunctionId, NewFunctionResult, NewFunctionError, NewFunctionErrorCallStack);
        AOAIOperationResponse.AddFunctionResponse(AOAIFunctionResponse);
    end;

    procedure SetToolCalls(AOAIChatMessages: Codeunit "AOAI Chat Messages"; ToolCallId: Text; FunctionName: Text)
    var
        ToolCalls: JsonArray;
        ToolSelectionResponseLbl: Label '[{"id":"%1","type":"function","function":{"name":"%2","arguments":"{}"}}]', Locked = true;
    begin
        ToolCalls.ReadFrom(StrSubstNo(ToolSelectionResponseLbl, ToolCallId, FunctionName));

        AOAIChatMessages.AddToolCalls(ToolCalls);
    end;

}