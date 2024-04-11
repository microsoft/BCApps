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
        Success: Boolean;
        FunctionCall: Boolean;
        FunctionName: Text;
        Result: Variant;
        Error: Text;
        ErrorCallStack: Text;

    /// <summary>
    /// Get whether the function call was successful.
    /// </summary>
    /// <returns>True if the call was successful, false otherwise.</returns>
    procedure IsSuccess(): Boolean
    begin
        exit(Success);
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
    /// Get the error call stack from the function that was called.
    /// </summary>
    /// <returns>The error call stack from the function.</returns>
    procedure GetErrorCallstack(): Text
    begin
        exit(ErrorCallStack);
    end;

    /// <summary>
    /// Get whether the operation was a function call.
    /// </summary>
    /// <returns>True if it was a function call, false otherwise.</returns>
    internal procedure IsFunctionCall(): Boolean
    begin
        exit(FunctionCall);
    end;

    internal procedure SetIsFunctionCall(NewIsFunctionCall: Boolean)
    begin
        FunctionCall := NewIsFunctionCall;
    end;

    internal procedure SetFunctionCallingResponse(NewFunctionCallSuccess: Boolean; NewFunctionCalled: Text; NewFunctionResult: Variant; NewFunctionError: Text; NewFunctionErrorCallStack: Text)
    begin
        Success := NewFunctionCallSuccess;
        FunctionName := NewFunctionCalled;
        Result := NewFunctionResult;
        Error := NewFunctionError;
        ErrorCallStack := NewFunctionErrorCallStack;
    end;
}