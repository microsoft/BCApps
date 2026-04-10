// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.AI;

/// <summary>
/// The status and result of an functions.
/// </summary>
codeunit 7758 "AOAI Function Response"
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        AOAIFunctionResponseStatus: Enum "AOAI Function Response Status";
        FunctionCall: Boolean;
        FunctionName: Text;
        FunctionId: Text;
        Error: Text;
        ErrorCallStack: Text;
        Arguments: JsonObject;
        Result: Variant;

    /// <summary>
    /// Get whether the function call was successful.
    /// </summary>
    /// <returns>True if the call was successful, false otherwise.</returns>
    procedure IsSuccess(): Boolean
    begin
        exit(AOAIFunctionResponseStatus = Enum::"AOAI Function Response Status"::"Invoke Success");
    end;

    /// <summary>
    /// Gets the function response status.
    /// </summary>
    /// <returns>The function response status</returns>
    procedure GetStatus(): Enum "AOAI Function Response Status"
    begin
        exit(AOAIFunctionResponseStatus);
    end;

    /// <summary>
    /// Get the return value of the function that was called.
    /// </summary>
    /// <returns>The return value from the function</returns>
    procedure GetResult(): Variant
    begin
        exit(Result);
    end;

    /// <summary>
    /// Get the arguments for the function call.
    /// </summary>
    /// <returns>The arguments for the function</returns>
    procedure GetArguments(): JsonObject
    begin
        exit(Arguments);
    end;

    /// <summary>
    /// Get the error message from the function that was called.
    /// </summary>
    /// <returns>The error message from the function.</returns>
    procedure GetError(): Text
    begin
        exit(Error);
    end;

    /// <summary>
    /// Get the name of the function that was called.
    /// </summary>
    /// <returns>The name of the function that was called.</returns>
    procedure GetFunctionName(): Text
    begin
        exit(FunctionName);
    end;

    /// <summary>
    /// Get the id of the function that was called.
    /// </summary>
    procedure GetFunctionId(): Text
    begin
        exit(FunctionId);
    end;

    /// <summary>
    /// Get the error call stack from the function that was called.
    /// </summary>
    /// <returns>The error call stack from the function.</returns>
    procedure GetErrorCallstack(): Text
    begin
        exit(ErrorCallStack);
    end;

    /// <summary>
    /// Appends the function result to the provided AOAIChatMessages instance.
    /// </summary>
    /// <param name="AOAIChatMessages">The chat messages instance to append the result to.</param>
    internal procedure AppendResultToChatMessages(var AOAIChatMessages: Codeunit "AOAI Chat Messages")
    begin
        AOAIChatMessages.AddToolMessage(GetFunctionId(), GetFunctionName(), Format(GetResult()));
    end;

    internal procedure IsFunctionCall(): Boolean
    begin
        exit(FunctionCall);
    end;

    internal procedure SetFunctionCallingResponse(NewIsFunctionCall: Boolean; NewAOAIFunctionResponseStatus: Enum "AOAI Function Response Status"; NewFunctionCalled: Text; NewFunctionId: Text; NewArguments: JsonObject; NewFunctionResult: Variant; NewFunctionError: Text; NewFunctionErrorCallStack: Text)
    begin
        FunctionCall := NewIsFunctionCall;
        AOAIFunctionResponseStatus := NewAOAIFunctionResponseStatus;
        FunctionName := NewFunctionCalled;
        FunctionId := NewFunctionId;
        Arguments := NewArguments;
        Result := NewFunctionResult;
        Error := NewFunctionError;
        ErrorCallStack := NewFunctionErrorCallStack;
    end;
}