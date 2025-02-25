// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.AI;

/// <summary>
/// The status and result of an operation.
/// </summary>
codeunit 7770 "AOAI Operation Response"
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
#if not CLEAN25
        LastAOAIFunctionResponse: Codeunit "AOAI Function Response";
#endif
        AOAIFunctionResponses: List of [Codeunit "AOAI Function Response"];
        StatusCode: Integer;
        Success: Boolean;
        Result: Text;
        Error: Text;
        IncorrectRoleErr: Label 'The last chat message must have a role of assistant.';
        IncorrectToolCallsErr: Label 'The last chat message does not contain any tool calls to respond to.';
        IncorrectToolCountsErr: Label 'The provided number of tool calls do not match the number of function calls. There may be unsupported tool call types.';
        FunctionCallDoesNotExistErr: Label 'The provided function response (%1 - %2) does not exist in the tool calls property', Comment = '%1 = the tool call id, e.g. call_1234567890, %2 = the function name, e.g. GetWeather';

    /// <summary>
    /// Check whether the operation was successful.
    /// </summary>
    /// <returns>True if the operation was successful.</returns>
    procedure IsSuccess(): Boolean
    begin
        exit(Success);
    end;

    /// <summary>
    /// Get the status code of the operation.
    /// </summary>
    /// <returns>The status code of the operation.</returns>
    procedure GetStatusCode(): Integer
    begin
        exit(StatusCode);
    end;

    /// <summary>
    /// Get the result of the operation.
    /// </summary>
    /// <returns>The result of the operation.</returns>
    procedure GetResult(): Text
    begin
        exit(Result);
    end;

    /// <summary>
    /// Get the error text of the operation.
    /// </summary>
    /// <returns>The error text of the operation.</returns>
    procedure GetError(): Text
    begin
        exit(Error);
    end;

    /// <summary>
    /// Get whether the operation was a function call.
    /// </summary>
    /// <returns>True if it was a function call, false otherwise.</returns>
    procedure IsFunctionCall(): Boolean
    var
        AOAIFunctionResponse: Codeunit "AOAI Function Response";
    begin
        if not AOAIFunctionResponses.Get(1, AOAIFunctionResponse) then
            exit(false);

        exit(AOAIFunctionResponse.IsFunctionCall());
    end;

    /// <summary>
    /// Get whether there are any function responses for a given function name.
    /// </summary>
    /// <param name="FunctionName">The case sensitive function name to search for.</param>
    /// <returns>True if any function responses were found</returns>
    procedure HasFunctionResponsesByName(FunctionName: Text): Boolean
    var
        MatchedAOAIFunctionResponses: List of [Codeunit "AOAI Function Response"];
    begin
        exit(TryGetFunctionReponsesByName(FunctionName, MatchedAOAIFunctionResponses));
    end;

    /// <summary>
    /// Get all the function responses for a specified function name.
    /// </summary>
    /// <param name="FunctionName">The case sensitive function name to search for.</param>
    /// <param name="MatchedAOAIFunctionResponses">The function responses that match the given function name</param>
    /// <returns>True if any function responses were found</returns>
    procedure TryGetFunctionReponsesByName(FunctionName: Text; var MatchedAOAIFunctionResponses: List of [Codeunit "AOAI Function Response"]): Boolean
    var
        AOAIFunctionResponse: Codeunit "AOAI Function Response";
    begin
        Clear(MatchedAOAIFunctionResponses);

        if FunctionName = '' then
            exit(false);

        if not IsFunctionCall() then
            exit(false);

        foreach AOAIFunctionResponse in AOAIFunctionResponses do
            if AOAIFunctionResponse.GetFunctionName() = FunctionName then
                MatchedAOAIFunctionResponses.Add(AOAIFunctionResponse);

        exit(MatchedAOAIFunctionResponses.Count() > 0);
    end;

#if not CLEAN25
    /// <summary>
    /// Get the function response codeunit which contains the response details.
    /// </summary>
    /// <returns>The codeunit which contains response details for the function call.</returns>
    [Obsolete('There could be multiple function responses, use GetFunctionResponses to iterate through them all. For compatibility, GetFunctionResponse will return the last function returned by the model', '25.0')]
    procedure GetFunctionResponse(): Codeunit "AOAI Function Response"
    var
        FunctionCount: Integer;
    begin
        FunctionCount := AOAIFunctionResponses.Count();

        if FunctionCount <= 0 then
            exit(LastAOAIFunctionResponse);

        AOAIFunctionResponses.Get(FunctionCount, LastAOAIFunctionResponse);
        exit(LastAOAIFunctionResponse);
    end;
#endif

    procedure GetFunctionResponses(): List of [Codeunit "AOAI Function Response"]
    begin
        exit(AOAIFunctionResponses);
    end;

    /// <summary>
    /// Appends all of the successful function results to the provided AOAIChatMessages instance.
    /// </summary>
    /// <remarks>The last chat message in the history must contain the tool calls from this operation.</remarks>
    /// <param name="AOAIChatMessages">The chat messages instance to append the result to.</param>
    procedure AppendFunctionResponsesToChatMessages(var AOAIChatMessages: Codeunit "AOAI Chat Messages")
    var
        AOAIFunctionResponse: Codeunit "AOAI Function Response";
        ToolCallType: JsonToken;
        ToolCallId: JsonToken;
        ToolCalls: JsonArray;
        ToolCall: JsonToken;
        ToolCallIds: List of [Text];
    begin
        if AOAIChatMessages.GetLastRole() <> ENum::"AOAI Chat Roles"::Assistant then
            Error(IncorrectRoleErr);

        ToolCalls := AOAIChatMessages.GetLastToolCalls();

        if ToolCalls.Count() <= 0 then
            Error(IncorrectToolCallsErr);

        // Build the set of ids
        foreach ToolCall in ToolCalls do
            if ToolCall.AsObject().Get('type', ToolCallType) and (ToolCallType.AsValue().AsText() = 'function') then
                if ToolCall.AsObject().Get('id', ToolCallId) then
                    ToolCallIds.Add(ToolCallId.AsValue().AsText());

        if (ToolCalls.Count() <> ToolCallIds.Count()) or (ToolCallIds.Count() <> AOAIFunctionResponses.Count()) then
            Error(IncorrectToolCountsErr);

        // append the tool call results, while validating that they exist in the tool calls
        foreach AOAIFunctionResponse in AOAIFunctionResponses do begin
            if not ToolCallIds.Contains(AOAIFunctionResponse.GetFunctionId()) then
                Error(FunctionCallDoesNotExistErr, AOAIFunctionResponse.GetFunctionId(), AOAIFunctionResponse.GetFunctionName());

            if AOAIFunctionResponse.IsSuccess() then
                AOAIFunctionResponse.AppendResultToChatMessages(AOAIChatMessages);
        end;
    end;

    internal procedure AddFunctionResponse(var AOAIFunctionResponse: Codeunit "AOAI Function Response")
    begin
        AOAIFunctionResponses.Add(AOAIFunctionResponse);
    end;

    internal procedure SetOperationResponse(NewSuccess: Boolean; NewStatusCode: Integer; NewResult: Text; NewError: Text)
    begin
        Clear(AOAIFunctionResponses);
#if not CLEAN25
        Clear(LastAOAIFunctionResponse);
#endif

        Success := NewSuccess;
        StatusCode := NewStatusCode;
        Result := NewResult;
        Error := NewError;
    end;
}